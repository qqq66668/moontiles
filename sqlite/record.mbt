///|
/// SQLite 变长整数：value 是数值，next 是下一个字节位置。
pub struct Varint {
  value : Int64
  next : Int32
}

///|
/// 一条记录中某一列的 serial type 与它占用的字节数。
pub struct SerialType {
  serial_type : Int32
  kind : Int32
  byte_length : Int32
}

///|
/// 记录头：每列的 serial type、头长度与正文起点。
pub struct RecordHeader {
  types : Array[SerialType]
  header_length : Int32
  payload_offset : Int32
}

///|
/// 记录中一列的值：kind 0 空值、1 整数、2 浮点、3 文本、4 二进制。
pub struct RecordValue {
  kind : Int32
  int_value : Int64
  real_value : Double
  bytes : Bytes
}

///|
/// serial type 对应的内容类别：0 空值、1 整数、2 浮点、3 文本、4 二进制。
pub fn serial_kind(serial_type : Int32) -> Int32 {
  if serial_type == 0 {
    0
  } else if serial_type >= 1 && serial_type <= 6 {
    1
  } else if serial_type == 7 {
    2
  } else if serial_type == 8 || serial_type == 9 {
    1
  } else if serial_type >= 12 && serial_type % 2 == 0 {
    4
  } else if serial_type >= 13 && serial_type % 2 == 1 {
    3
  } else {
    0 - 1
  }
}

///|
/// serial type 对应的字节长度；保留类型 10 与 11 返回 -1。
pub fn serial_byte_length(serial_type : Int32) -> Int32 {
  if serial_type == 0 || serial_type == 8 || serial_type == 9 {
    0
  } else if serial_type >= 1 && serial_type <= 4 {
    serial_type
  } else if serial_type == 5 {
    6
  } else if serial_type == 6 || serial_type == 7 {
    8
  } else if serial_type == 10 || serial_type == 11 {
    0 - 1
  } else if serial_type >= 12 && serial_type % 2 == 0 {
    (serial_type - 12) / 2
  } else if serial_type >= 13 {
    (serial_type - 13) / 2
  } else {
    0 - 1
  }
}

///|
/// 读取一个 SQLite 变长整数；越界、截断时返回错误说明。
pub fn read_varint(data : Bytes, start : Int32) -> Result[Varint, String] {
  if start < 0 || start > data.length() {
    return Err("sqlite: varint start is out of range")
  }
  let mut value = Int64::from_int(0)
  let mut index = start
  let mut count = 0
  let mut done = false
  while done == false && index < data.length() {
    let byte = data.unsafe_get(index).to_int()
    index = index + 1
    count = count + 1
    if count == 9 {
      value = (value << 8) + Int64::from_int(byte)
      done = true
    } else {
      value = (value << 7) + Int64::from_int(byte % 128)
      if byte < 128 {
        done = true
      }
    }
  }
  if done == false {
    return Err("sqlite: varint is truncated")
  }
  Ok({ value, next: index, })
}

///|
/// 解析记录头：先读头长度，再逐列读 serial type；头长度与列不自洽时报错。
pub fn parse_record_header(data : Bytes) -> Result[RecordHeader, String] {
  let head = match read_varint(data, 0) {
    Ok(v) => v
    Err(msg) => return Err(msg)
  }
  let header_length = head.value.to_int()
  if header_length < 1 || header_length > data.length() {
    return Err("sqlite: record header length is out of range")
  }
  let types : Array[SerialType] = []
  let mut pos = head.next
  while pos < header_length {
    let item = match read_varint(data, pos) {
      Ok(v) => v
      Err(msg) => return Err(msg)
    }
    let serial_type = item.value.to_int()
    let length = serial_byte_length(serial_type)
    if length < 0 {
      return Err("sqlite: reserved serial type in record header")
    }
    types.push({
      serial_type,
      kind: serial_kind(serial_type),
      byte_length: length,
    })
    pos = item.next
  }
  if pos != header_length {
    return Err("sqlite: record header length does not match its serial types")
  }
  Ok({ types, header_length, payload_offset: header_length, })
}

///|
/// 复制一段字节，供文本与二进制列取值使用。
pub fn copy_bytes(data : Bytes, start : Int32, len : Int32) -> Bytes {
  let buf = Buffer()
  let mut i = 0
  while i < len {
    buf.write_byte(data.unsafe_get(start + i))
    i = i + 1
  }
  buf.to_bytes()
}

///|
/// 按大端读取 IEEE754 双精度浮点。
fn read_double_be(data : Bytes, start : Int32) -> Double {
  let mut bits = (0).to_uint64()
  let mut i = 0
  while i < 8 {
    bits = bits * (256).to_uint64() +
      data.unsafe_get(start + i).to_int().to_uint64()
    i = i + 1
  }
  bits.reinterpret_as_double()
}

///|
/// 按大端补码读取有符号整数，length 最大 8 字节。
fn read_signed_be(data : Bytes, start : Int32, len : Int32) -> Int64 {
  let mut value = Int64::from_int(0)
  let mut i = 0
  while i < len {
    value = value * Int64::from_int(256) +
      Int64::from_int(data.unsafe_get(start + i).to_int())
    i = i + 1
  }
  if len > 0 && len < 8 {
    if data.unsafe_get(start).to_int() >= 128 {
      let mut power = Int64::from_int(1)
      let mut k = 0
      while k < len {
        power = power * Int64::from_int(256)
        k = k + 1
      }
      value = value - power
    }
  }
  value
}

///|
/// 按记录头逐列取值；整数按补码还原，浮点按 IEEE754 还原，
/// 文本与二进制取出原始字节。
pub fn decode_record(data : Bytes) -> Result[Array[RecordValue], String] {
  let header = match parse_record_header(data) {
    Ok(h) => h
    Err(msg) => return Err(msg)
  }
  let types = header.types
  let values : Array[RecordValue] = []
  let mut pos = header.payload_offset
  let mut i = 0
  while i < types.length() {
    let t = types[i]
    let kind = t.kind
    let mut int_value = Int64::from_int(0)
    let mut real_value = 0.0
    let mut raw : Bytes = b""
    if kind == 1 {
      if t.serial_type == 8 {
        int_value = Int64::from_int(0)
      } else if t.serial_type == 9 {
        int_value = Int64::from_int(1)
      } else {
        if pos + t.byte_length > data.length() {
          return Err("sqlite: integer value is truncated")
        }
        int_value = read_signed_be(data, pos, t.byte_length)
      }
    } else if kind == 2 {
      if pos + 8 > data.length() {
        return Err("sqlite: real value is truncated")
      }
      real_value = read_double_be(data, pos)
    } else if kind == 3 || kind == 4 {
      if pos + t.byte_length > data.length() {
        return Err("sqlite: text or blob value is truncated")
      }
      raw = copy_bytes(data, pos, t.byte_length)
    }
    values.push({ kind, int_value, real_value, bytes: raw, })
    pos = pos + t.byte_length
    i = i + 1
  }
  Ok(values)
}

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
  let out : Varint = { value, next: index, }
  Ok(out)
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
    let entry : SerialType = {
      serial_type,
      kind: serial_kind(serial_type),
      byte_length: length,
    }
    types.push(entry)
    pos = item.next
  }
  if pos != header_length {
    return Err("sqlite: record header length does not match its serial types")
  }
  let header : RecordHeader = {
    types,
    header_length,
    payload_offset: header_length,
  }
  Ok(header)
}

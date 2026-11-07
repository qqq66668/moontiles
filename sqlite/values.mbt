///|
/// 记录中一列的值：kind 0 空值、1 整数、2 浮点、3 文本、4 二进制。
pub struct RecordValue {
  kind : Int32
  int_value : Int64
  bytes : Bytes
}

///|
/// 复制一段字节，供文本与二进制列取值使用。
fn copy_bytes(data : Bytes, start : Int32, len : Int32) -> Bytes {
  let buf = Buffer()
  let mut i = 0
  while i < len {
    buf.write_byte(data.unsafe_get(start + i))
    i = i + 1
  }
  buf.to_bytes()
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
    let first = data.unsafe_get(start).to_int()
    if first >= 128 {
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
/// 按记录头逐列取值；整数按大端补码还原，文本与二进制取出原始字节。
///
/// 浮点列暂未实现，遇到时返回错误而不是给出错误数值。
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
      return Err("sqlite: real values are not decoded yet")
    } else if kind == 3 || kind == 4 {
      if pos + t.byte_length > data.length() {
        return Err("sqlite: text or blob value is truncated")
      }
      raw = copy_bytes(data, pos, t.byte_length)
    }
    let value : RecordValue = { kind, int_value, bytes: raw, }
    values.push(value)
    pos = pos + t.byte_length
    i = i + 1
  }
  Ok(values)
}

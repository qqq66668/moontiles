///|
/// SQLite 数据库文件头长度。
pub fn header_size() -> Int32 {
  100
}

///|
/// SQLite 数据库文件头中只读访问所需的字段。
pub struct DbHeader {
  page_size : Int32
  write_version : Int32
  read_version : Int32
  reserved_bytes : Int32
  max_payload_fraction : Int32
  min_payload_fraction : Int32
  leaf_payload_fraction : Int32
  page_count : Int32
  freelist_trunk_page : Int32
  freelist_page_count : Int32
  schema_cookie : Int32
  schema_format : Int32
  default_cache_size : Int32
  largest_root_page : Int32
  text_encoding : Int32
  user_version : Int32
  incremental_vacuum : Int32
  application_id : Int32
}

///|
fn byte_at(data : Bytes, off : Int32) -> Int32 {
  data.unsafe_get(off).to_int()
}

///|
fn read_u16_be(data : Bytes, off : Int32) -> Int32 {
  (byte_at(data, off) << 8) | byte_at(data, off + 1)
}

///|
fn read_u32_be(data : Bytes, off : Int32) -> Int32 {
  (byte_at(data, off) << 24) |
  (byte_at(data, off + 1) << 16) |
  (byte_at(data, off + 2) << 8) |
  byte_at(data, off + 3)
}

///|
/// 校验 SQLite format 3 魔数与结尾零字节。
fn magic_ok(data : Bytes) -> Bool {
  let expected : Array[Int32] = [
    0x53, 0x51, 0x4C, 0x69, 0x74, 0x65, 0x20, 0x66, 0x6F, 0x72, 0x6D, 0x61, 0x74,
    0x20, 0x33, 0x00,
  ]
  let mut i = 0
  while i < 16 {
    if byte_at(data, i) != expected[i] {
      return false
    }
    i = i + 1
  }
  true
}

///|
/// 解析数据库文件头；长度不足、魔数不符、页大小或编码非法时返回错误说明。
pub fn parse_db_header(data : Bytes) -> Result[DbHeader, String] {
  if data.length() < header_size() {
    return Err("sqlite: header is shorter than 100 bytes")
  }
  if magic_ok(data) == false {
    return Err("sqlite: magic is not SQLite format 3")
  }
  let raw_page_size = read_u16_be(data, 16)
  let page_size = if raw_page_size == 1 { 65536 } else { raw_page_size }
  if page_size < 512 {
    return Err("sqlite: page size is smaller than 512")
  }
  let encoding = read_u32_be(data, 56)
  if encoding != 1 && encoding != 2 && encoding != 3 {
    return Err("sqlite: text encoding is unknown")
  }
  let header : DbHeader = {
    page_size,
    write_version: byte_at(data, 18),
    read_version: byte_at(data, 19),
    reserved_bytes: byte_at(data, 20),
    max_payload_fraction: byte_at(data, 21),
    min_payload_fraction: byte_at(data, 22),
    leaf_payload_fraction: byte_at(data, 23),
    page_count: read_u32_be(data, 28),
    freelist_trunk_page: read_u32_be(data, 32),
    freelist_page_count: read_u32_be(data, 36),
    schema_cookie: read_u32_be(data, 40),
    schema_format: read_u32_be(data, 44),
    default_cache_size: read_u32_be(data, 48),
    largest_root_page: read_u32_be(data, 52),
    text_encoding: encoding,
    user_version: read_u32_be(data, 60),
    incremental_vacuum: read_u32_be(data, 64),
    application_id: read_u32_be(data, 68),
  }
  Ok(header)
}

///|
/// 按页号读取一页；页号从 1 开始，越界或数据被截断时返回错误而不是 panic。
pub fn read_page(
  data : Bytes,
  header : DbHeader,
  page_no : Int32,
) -> Result[Bytes, String] {
  if page_no < 1 {
    return Err("sqlite: page number starts at 1")
  }
  if page_no > header.page_count {
    return Err("sqlite: page number is beyond page count")
  }
  let start = (page_no - 1) * header.page_size
  if start + header.page_size > data.length() {
    return Err("sqlite: page is truncated")
  }
  let buf = Buffer()
  let mut i = 0
  while i < header.page_size {
    buf.write_byte(data.unsafe_get(start + i))
    i = i + 1
  }
  Ok(buf.to_bytes())
}

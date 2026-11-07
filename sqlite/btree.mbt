///|
/// B 树页头的固定字段；页类型 13 是叶子表页，5 是内部表页。
pub struct PageHeader {
  page_type : Int32
  first_freeblock : Int32
  cell_count : Int32
  cell_content_start : Int32
  fragmented_free_bytes : Int32
  header_size : Int32
}

///|
fn is_known_page_type(value : Int32) -> Bool {
  value == 1 || value == 2 || value == 5 || value == 10 || value == 13
}

///|
fn is_interior_page(value : Int32) -> Bool {
  value == 2 || value == 5
}

///|
/// B 树页头在文件中的偏移：第 1 页的头紧跟在 100 字节数据库文件头之后。
pub fn page_header_start(page_no : Int32, db : DbHeader) -> Int32 {
  if page_no <= 1 {
    header_size()
  } else {
    (page_no - 1) * db.page_size
  }
}

///|
/// 解析指定偏移处的 B 树页头；偏移越界或页类型未知时返回错误说明。
pub fn parse_page_header(
  data : Bytes,
  start : Int32,
) -> Result[PageHeader, String] {
  if start < 0 || start + 8 > data.length() {
    return Err("sqlite: page header is out of range")
  }
  let page_type = byte_at(data, start)
  if is_known_page_type(page_type) == false {
    return Err("sqlite: unknown b-tree page type")
  }
  let header_len = if is_interior_page(page_type) { 12 } else { 8 }
  if start + header_len > data.length() {
    return Err("sqlite: page header is out of range")
  }
  let mut content_start = read_u16_be(data, start + 5)
  if content_start == 0 {
    content_start = 65536
  }
  let page : PageHeader = {
    page_type,
    first_freeblock: read_u16_be(data, start + 1),
    cell_count: read_u16_be(data, start + 3),
    cell_content_start: content_start,
    fragmented_free_bytes: byte_at(data, start + 7),
    header_size: header_len,
  }
  Ok(page)
}

///|
/// 单元指针数组：每个元素是某个单元相对页首的偏移。
pub fn cell_pointers(
  data : Bytes,
  start : Int32,
  page : PageHeader,
) -> Result[Array[Int32], String] {
  if page.cell_count < 0 {
    return Err("sqlite: negative cell count")
  }
  let begin = start + page.header_size
  if begin + page.cell_count * 2 > data.length() {
    return Err("sqlite: cell pointer array is out of range")
  }
  let pointers : Array[Int32] = []
  let mut i = 0
  while i < page.cell_count {
    pointers.push(read_u16_be(data, begin + i * 2))
    i = i + 1
  }
  Ok(pointers)
}

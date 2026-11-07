///|
/// 叶子表页中的一个单元：行号与记录正文的位置。
pub struct TableCell {
  row_id : Int64
  payload_offset : Int32
  payload_length : Int32
}

///|
/// 解析叶子表页中的一个单元：先读记录正文长度，再读行号，正文紧随其后。
///
/// 单页内正文不跨页，因此这里只处理 payload 完整落在本页的情况。
pub fn parse_table_cell(
  data : Bytes,
  page_start : Int32,
  cell_offset : Int32,
  page_end : Int32,
) -> Result[TableCell, String] {
  let start = page_start + cell_offset
  if start < 0 || start >= page_end || page_end > data.length() {
    return Err("sqlite: table cell offset is out of range")
  }
  let length_varint = match read_varint(data, start) {
    Ok(v) => v
    Err(msg) => return Err(msg)
  }
  let payload_length = length_varint.value.to_int()
  let row_varint = match read_varint(data, length_varint.next) {
    Ok(v) => v
    Err(msg) => return Err(msg)
  }
  let payload_offset = row_varint.next
  if payload_length < 0 || payload_offset + payload_length > page_end {
    return Err("sqlite: table cell payload overflows the page")
  }
  let cell : TableCell = {
    row_id: row_varint.value,
    payload_offset,
    payload_length,
  }
  Ok(cell)
}

///|
/// 遍历一个叶子表页的全部单元，按页内顺序返回。
///
/// 要求页类型为 13（叶子表页）；其它类型返回错误。
pub fn read_leaf_table_cells(
  data : Bytes,
  page_start : Int32,
  page_size : Int32,
) -> Result[Array[TableCell], String] {
  let header = match parse_page_header(data, page_start) {
    Ok(h) => h
    Err(msg) => return Err(msg)
  }
  if header.page_type != 13 {
    return Err("sqlite: page is not a leaf table page")
  }
  let pointers = match cell_pointers(data, page_start, header) {
    Ok(p) => p
    Err(msg) => return Err(msg)
  }
  let page_end = page_start + page_size
  let cells : Array[TableCell] = []
  let mut i = 0
  while i < pointers.length() {
    let cell = match parse_table_cell(data, page_start, pointers[i], page_end) {
      Ok(c) => c
      Err(msg) => return Err(msg)
    }
    cells.push(cell)
    i = i + 1
  }
  Ok(cells)
}

///|
/// 取出单元的记录正文副本。
pub fn cell_payload(data : Bytes, cell : TableCell) -> Bytes {
  copy_bytes(data, cell.payload_offset, cell.payload_length)
}

///|
/// 叶子表页中的一个单元：行号、记录正文位置、本地长度与溢出页。
pub struct TableCell {
  row_id : Int64
  payload_offset : Int32
  payload_length : Int32
  local_length : Int32
  overflow_page : Int32
}

///|
/// 记录正文的本地长度：超出页内可放部分时按规范公式折回。
fn local_payload_size(payload_length : Int32, usable : Int32) -> Int32 {
  let x = usable - 35
  if payload_length <= x {
    return payload_length
  }
  let m = (usable - 12) * 32 / 255 - 23
  let k = m + (payload_length - m) % (usable - 4)
  if k <= x {
    k
  } else {
    m
  }
}

///|
/// 解析叶子表页中的一个单元：先读正文长度，再读行号，正文紧随其后。
///
/// 正文超出本页时按规范折算出本地长度，并在其后读出 4 字节溢出页号。
pub fn parse_table_cell(
  data : Bytes,
  page_start : Int32,
  cell_offset : Int32,
  page_end : Int32,
  usable : Int32,
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
  let mut local_length = payload_length
  let mut overflow_page = 0
  if payload_offset + payload_length > page_end {
    local_length = local_payload_size(payload_length, usable)
    if local_length < 0 || payload_offset + local_length + 4 > page_end {
      return Err("sqlite: table cell payload overflows the page")
    }
    overflow_page = (byte_at(data, payload_offset + local_length) << 24) |
      (byte_at(data, payload_offset + local_length + 1) << 16) |
      (byte_at(data, payload_offset + local_length + 2) << 8) |
      byte_at(data, payload_offset + local_length + 3)
  }
  Ok({
    row_id: row_varint.value,
    payload_offset,
    payload_length,
    local_length,
    overflow_page,
  })
}

///|
/// 遍历一个叶子表页的全部单元，按页内顺序返回。
///
/// 要求页类型为 13（叶子表页）；其它类型返回错误。
pub fn read_leaf_table_cells(
  data : Bytes,
  page_start : Int32,
  page_size : Int32,
  reserved~ : Int32 = 0,
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
  let usable = page_size - reserved
  let cells : Array[TableCell] = []
  let mut i = 0
  while i < pointers.length() {
    let cell = match
      parse_table_cell(data, page_start, pointers[i], page_end, usable) {
      Ok(c) => c
      Err(msg) => return Err(msg)
    }
    cells.push(cell)
    i = i + 1
  }
  Ok(cells)
}

///|
/// 取出单元的本地正文副本（不含溢出页）。
pub fn cell_payload(data : Bytes, cell : TableCell) -> Bytes {
  copy_bytes(data, cell.payload_offset, cell.local_length)
}

///|
/// 读取单元完整正文：本地部分加上按 4 字节链指针串起来的溢出页。
pub fn read_cell_payload(
  data : Bytes,
  db : DbHeader,
  cell : TableCell,
) -> Result[Bytes, String] {
  let buf = Buffer()
  let mut i = 0
  while i < cell.local_length {
    buf.write_byte(data.unsafe_get(cell.payload_offset + i))
    i = i + 1
  }
  let usable = db.page_size - db.reserved_bytes
  let mut next = cell.overflow_page
  let mut steps = 0
  while next != 0 && buf.length() < cell.payload_length {
    steps = steps + 1
    if steps > 4096 {
      return Err("sqlite: overflow chain is too long")
    }
    if next < 1 || next > db.page_count {
      return Err("sqlite: overflow page number is out of range")
    }
    let page_start = (next - 1) * db.page_size
    if page_start + db.page_size > data.length() {
      return Err("sqlite: overflow page is truncated")
    }
    let follow = (byte_at(data, page_start) << 24) |
      (byte_at(data, page_start + 1) << 16) |
      (byte_at(data, page_start + 2) << 8) |
      byte_at(data, page_start + 3)
    let mut left = usable - 4
    if left > cell.payload_length - buf.length() {
      left = cell.payload_length - buf.length()
    }
    let mut k = 0
    while k < left {
      buf.write_byte(data.unsafe_get(page_start + 4 + k))
      k = k + 1
    }
    next = follow
  }
  if buf.length() != cell.payload_length {
    return Err("sqlite: overflow chain ends before the payload is complete")
  }
  Ok(buf.to_bytes())
}

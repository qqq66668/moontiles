///|
/// 从指定根页遍历一张表，按页序返回全部行的记录正文。
///
/// 支持内部页（类型 5）与叶子页（类型 13）的递归；深度上限 32，超出报错。
/// 记录正文超出单页时按溢出页链拼接。
pub fn read_table_rows(
  data : Bytes,
  db : DbHeader,
  root_page : Int32,
) -> Result[Array[Bytes], String] {
  let rows : Array[Bytes] = []
  let stack : Array[Int32] = [root_page]
  let mut depth = 0
  while stack.length() > 0 {
    if depth > 32 {
      return Err("sqlite: table traversal is too deep")
    }
    let page_no = match stack.pop() {
      Some(p) => p
      None => break
    }
    if page_no < 1 || page_no > db.page_count {
      return Err("sqlite: child page number is out of range")
    }
    let page_start = (page_no - 1) * db.page_size
    if page_start + db.page_size > data.length() {
      return Err("sqlite: page is truncated")
    }
    let header_offset = page_header_start(page_no, db)
    let header = match parse_page_header(data, header_offset) {
      Ok(h) => h
      Err(msg) => return Err(msg)
    }
    let pointers = match cell_pointers(data, header_offset, header) {
      Ok(p) => p
      Err(msg) => return Err(msg)
    }
    let page_end = page_start + db.page_size
    if header.page_type == 13 {
      let mut i = 0
      while i < pointers.length() {
        let cell = match
          parse_table_cell(
            data,
            page_start,
            pointers[i],
            page_end,
            db.page_size - db.reserved_bytes,
          ) {
          Ok(c) => c
          Err(msg) => return Err(msg)
        }
        let payload = match read_cell_payload(data, db, cell) {
          Ok(b) => b
          Err(msg) => return Err(msg)
        }
        rows.push(payload)
        i = i + 1
      }
    } else if header.page_type == 5 {
      let mut i = 0
      while i < pointers.length() {
        let cell_start = page_start + pointers[i]
        if cell_start + 4 > page_end {
          return Err("sqlite: interior cell offset is out of range")
        }
        let child = (byte_at(data, cell_start) << 24) |
          (byte_at(data, cell_start + 1) << 16) |
          (byte_at(data, cell_start + 2) << 8) |
          byte_at(data, cell_start + 3)
        stack.push(child)
        i = i + 1
      }
    } else {
      return Err(
        "sqlite: page is neither a table leaf nor a table interior page",
      )
    }
    depth = depth + 1
  }
  Ok(rows)
}

///|
/// 从根页遍历一张表并解析每行的列值。
pub fn read_table_values(
  data : Bytes,
  db : DbHeader,
  root_page : Int32,
) -> Result[Array[Array[RecordValue]], String] {
  let payloads = match read_table_rows(data, db, root_page) {
    Ok(rows) => rows
    Err(msg) => return Err(msg)
  }
  let out : Array[Array[RecordValue]] = []
  let mut i = 0
  while i < payloads.length() {
    let values = match decode_record(payloads[i]) {
      Ok(v) => v
      Err(msg) => return Err(msg)
    }
    out.push(values)
    i = i + 1
  }
  Ok(out)
}

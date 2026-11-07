///|
/// 真实 .mbtiles 文件的前 100 字节，由 Python 标准库 sqlite3 写出。
fn header_fixture() -> Bytes {
  b"\x53\x51\x4c\x69\x74\x65\x20\x66\x6f\x72\x6d\x61\x74\x20\x33\x00\x02\x00\x01\x01\x00\x40\x20\x20\x00\x00\x00\x03\x00\x00\x00\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x03\x00\x2e\x8a\x14"
}

///|
fn take(data : Bytes, n : Int32) -> Bytes {
  let buf = Buffer()
  let mut i = 0
  while i < n && i < data.length() {
    buf.write_byte(data.unsafe_get(i))
    i = i + 1
  }
  buf.to_bytes()
}

///|
fn pad_to(data : Bytes, total : Int32) -> Bytes {
  let buf = Buffer()
  let mut i = 0
  while i < data.length() {
    buf.write_byte(data.unsafe_get(i))
    i = i + 1
  }
  while i < total {
    buf.write_byte(b'\x00')
    i = i + 1
  }
  buf.to_bytes()
}

///|
fn with_byte(data : Bytes, at : Int32, value : Byte) -> Bytes {
  let buf = Buffer()
  let mut i = 0
  while i < data.length() {
    if i == at {
      buf.write_byte(value)
    } else {
      buf.write_byte(data.unsafe_get(i))
    }
    i = i + 1
  }
  buf.to_bytes()
}

///|
test "parses a real sqlite header" {
  match @sqlite.parse_db_header(header_fixture()) {
    Err(_) => assert_true(false)
    Ok(h) => {
      assert_eq(h.page_size, 512)
      assert_eq(h.page_count, 3)
      assert_eq(h.text_encoding, 1)
      assert_eq(h.write_version, 1)
      assert_eq(h.read_version, 1)
      assert_eq(h.reserved_bytes, 0)
      assert_eq(h.max_payload_fraction, 64)
      assert_eq(h.min_payload_fraction, 32)
      assert_eq(h.leaf_payload_fraction, 32)
      assert_eq(h.schema_format, 4)
      assert_eq(h.user_version, 0)
    }
  }
}

///|
test "rejects a truncated header" {
  match @sqlite.parse_db_header(take(header_fixture(), 40)) {
    Ok(_) => assert_true(false)
    Err(_) => assert_true(true)
  }
}

///|
test "rejects a wrong magic string" {
  let data = with_byte(header_fixture(), 0, b'\x51')
  match @sqlite.parse_db_header(data) {
    Ok(_) => assert_true(false)
    Err(_) => assert_true(true)
  }
}

///|
test "rejects an unknown text encoding" {
  let data = with_byte(header_fixture(), 59, b'\x09')
  match @sqlite.parse_db_header(data) {
    Ok(_) => assert_true(false)
    Err(_) => assert_true(true)
  }
}

///|
test "rejects a page size below 512" {
  let data = with_byte(header_fixture(), 16, b'\x00')
  match @sqlite.parse_db_header(data) {
    Ok(_) => assert_true(false)
    Err(_) => assert_true(true)
  }
}

///|
test "reads pages of a padded database" {
  match @sqlite.parse_db_header(header_fixture()) {
    Err(_) => assert_true(false)
    Ok(header) => {
      let data = pad_to(header_fixture(), header.page_size * header.page_count)
      assert_eq(data.length(), header.page_size * header.page_count)
      match @sqlite.read_page(data, header, 1) {
        Err(_) => assert_true(false)
        Ok(page) => {
          assert_eq(page.length(), header.page_size)
          assert_eq(page.unsafe_get(0).to_int(), 0x53)
          assert_eq(page.unsafe_get(1).to_int(), 0x51)
        }
      }
      match @sqlite.read_page(data, header, header.page_count) {
        Err(_) => assert_true(false)
        Ok(last) => assert_eq(last.length(), header.page_size)
      }
    }
  }
}

///|
test "rejects page numbers outside the file" {
  match @sqlite.parse_db_header(header_fixture()) {
    Err(_) => assert_true(false)
    Ok(header) => {
      let data = pad_to(header_fixture(), header.page_size * header.page_count)
      match @sqlite.read_page(data, header, 0) {
        Ok(_) => assert_true(false)
        Err(_) => assert_true(true)
      }
      match @sqlite.read_page(data, header, header.page_count + 1) {
        Ok(_) => assert_true(false)
        Err(_) => assert_true(true)
      }
      match @sqlite.read_page(header_fixture(), header, 1) {
        Ok(_) => assert_true(false)
        Err(_) => assert_true(true)
      }
    }
  }
}

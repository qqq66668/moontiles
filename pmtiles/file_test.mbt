///|
fn file_fixture() -> Bytes {
  b"\x50\x4d\x54\x69\x6c\x65\x73\x03\x7f\x00\x00\x00\x00\x00\x00\x00\x19\x00\x00\x00\x00\x00\x00\x00\x98\x00\x00\x00\x00\x00\x00\x00\x18\x00\x00\x00\x00\x00\x00\x00\xb0\x00\x00\x00\x00\x00\x00\x00\x22\x00\x00\x00\x00\x00\x00\x00\xd2\x00\x00\x00\x00\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x01\x02\x01\x01\x00\x01\x00\x2e\xb6\x94\x48\x3a\x4e\xcd\x00\xd2\x49\x6b\xb8\xc5\xb1\x32\x00\x00\x00\x00\x00\x00\x00\x00\x00\x1f\x8b\x08\x00\x00\x00\x00\x00\x02\xff\x63\x64\x60\x50\x62\x04\x00\x1b\xa8\xf7\x2b\x05\x00\x00\x00\x1f\x8b\x08\x00\x00\x00\x00\x00\x02\xff\xcb\x4d\x2d\x49\x04\x00\x35\x14\xf2\xd7\x04\x00\x00\x00\x1f\x8b\x08\x00\x00\x00\x00\x00\x02\xff\x63\x61\x60\x64\x64\x62\x04\x02\x26\x20\x60\x64\x60\x60\x00\x00\x2f\x36\xd3\x06\x11\x00\x00\x00\x7a\x30\x61\x61\x62\x62\x63\x63"
}

///|
fn bytes_eq(a : Bytes, b : Bytes) -> Bool {
  if a.length() != b.length() {
    return false
  }
  let mut i = 0
  while i < a.length() {
    if a.unsafe_get(i).to_int() != b.unsafe_get(i).to_int() {
      return false
    }
    i = i + 1
  }
  true
}

///|
fn head(data : Bytes, n : Int32) -> Bytes {
  match @pmtiles.slice_bytes(data, 0, n) {
    Ok(b) => b
    Err(_) => b""
  }
}

///|
test "parses a two level pmtiles file" {
  match @pmtiles.PmtilesFile::from_bytes(file_fixture()) {
    Ok(file) => {
      assert_eq(file.root_entry_count(), 1)
      let header = file.header()
      assert_eq(header.spec_version, 3)
      assert_eq(header.min_zoom, 0)
      assert_eq(header.max_zoom, 1)
      assert_eq(header.tile_type, 1)
    }
    Err(_) => assert_true(false)
  }
}

///|
test "reads tile z0 0 0" {
  match @pmtiles.PmtilesFile::from_bytes(file_fixture()) {
    Ok(file) =>
      match file.tile(0, 0, 0) {
        Ok(value) =>
          match value {
            Some(bytes) => assert_true(bytes_eq(bytes, b"\x7a\x30"))
            None => assert_true(false)
          }
        Err(_) => assert_true(false)
      }
    Err(_) => assert_true(false)
  }
}

///|
test "reads tile z1 0 0" {
  match @pmtiles.PmtilesFile::from_bytes(file_fixture()) {
    Ok(file) =>
      match file.tile(1, 0, 0) {
        Ok(value) =>
          match value {
            Some(bytes) => assert_true(bytes_eq(bytes, b"\x61\x61"))
            None => assert_true(false)
          }
        Err(_) => assert_true(false)
      }
    Err(_) => assert_true(false)
  }
}

///|
test "reads tile z1 0 1" {
  match @pmtiles.PmtilesFile::from_bytes(file_fixture()) {
    Ok(file) =>
      match file.tile(1, 0, 1) {
        Ok(value) =>
          match value {
            Some(bytes) => assert_true(bytes_eq(bytes, b"\x62\x62"))
            None => assert_true(false)
          }
        Err(_) => assert_true(false)
      }
    Err(_) => assert_true(false)
  }
}

///|
test "reads tile z1 1 0" {
  match @pmtiles.PmtilesFile::from_bytes(file_fixture()) {
    Ok(file) =>
      match file.tile(1, 1, 0) {
        Ok(value) =>
          match value {
            Some(bytes) => assert_true(bytes_eq(bytes, b"\x63\x63"))
            None => assert_true(false)
          }
        Err(_) => assert_true(false)
      }
    Err(_) => assert_true(false)
  }
}

///|
test "missing tile returns none" {
  match @pmtiles.PmtilesFile::from_bytes(file_fixture()) {
    Ok(file) =>
      match file.tile(1, 1, 1) {
        Ok(value) =>
          match value {
            Some(_) => assert_true(false)
            None => assert_true(true)
          }
        Err(_) => assert_true(true)
      }
    Err(_) => assert_true(false)
  }
}

///|
test "rejects a truncated file" {
  let short = head(file_fixture(), 20)
  assert_eq(short.length(), 20)
  match @pmtiles.PmtilesFile::from_bytes(short) {
    Ok(_) => assert_true(false)
    Err(_) => assert_true(true)
  }
}

///|
test "rejects a slice beyond the end" {
  match @pmtiles.slice_bytes(file_fixture(), 5000, 10) {
    Ok(_) => assert_true(false)
    Err(_) => assert_true(true)
  }
}

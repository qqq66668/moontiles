///|
/// 真实 .mbtiles 中一条记录的正文，由 Python 标准库 sqlite3 写出。
fn record_payload() -> Bytes {
  b"\x05\x01\x11\x10\x00\x2a\x68\x69\x01\x02"
}

///|
test "decodes varint 0" {
  match @sqlite.read_varint(b"\x00", 0) {
    Err(_) => assert_true(false)
    Ok(value) => {
      assert_eq(value.value.to_int(), 0)
      assert_eq(value.next, 1)
    }
  }
}

///|
test "decodes varint 1" {
  match @sqlite.read_varint(b"\x01", 0) {
    Err(_) => assert_true(false)
    Ok(value) => {
      assert_eq(value.value.to_int(), 1)
      assert_eq(value.next, 1)
    }
  }
}

///|
test "decodes varint 127" {
  match @sqlite.read_varint(b"\x7f", 0) {
    Err(_) => assert_true(false)
    Ok(value) => {
      assert_eq(value.value.to_int(), 127)
      assert_eq(value.next, 1)
    }
  }
}

///|
test "decodes varint 128" {
  match @sqlite.read_varint(b"\x81\x00", 0) {
    Err(_) => assert_true(false)
    Ok(value) => {
      assert_eq(value.value.to_int(), 128)
      assert_eq(value.next, 2)
    }
  }
}

///|
test "decodes varint 16383" {
  match @sqlite.read_varint(b"\xff\x7f", 0) {
    Err(_) => assert_true(false)
    Ok(value) => {
      assert_eq(value.value.to_int(), 16383)
      assert_eq(value.next, 2)
    }
  }
}

///|
test "decodes varint 16384" {
  match @sqlite.read_varint(b"\x81\x80\x00", 0) {
    Err(_) => assert_true(false)
    Ok(value) => {
      assert_eq(value.value.to_int(), 16384)
      assert_eq(value.next, 3)
    }
  }
}

///|
test "decodes varint 1000000" {
  match @sqlite.read_varint(b"\xbd\x84\x40", 0) {
    Err(_) => assert_true(false)
    Ok(value) => {
      assert_eq(value.value.to_int(), 1000000)
      assert_eq(value.next, 3)
    }
  }
}

///|
test "decodes varint 2147483647" {
  match @sqlite.read_varint(b"\x87\xff\xff\xff\x7f", 0) {
    Err(_) => assert_true(false)
    Ok(value) => {
      assert_eq(value.value.to_int(), 2147483647)
      assert_eq(value.next, 5)
    }
  }
}

///|
test "parses a real record header" {
  match @sqlite.parse_record_header(record_payload()) {
    Err(_) => assert_true(false)
    Ok(header) => {
      assert_eq(header.header_length, 5)
      assert_eq(header.payload_offset, 5)
      assert_eq(header.types.length(), 4)
      assert_eq(header.types[0].serial_type, 1)
      assert_eq(header.types[0].kind, 1)
      assert_eq(header.types[0].byte_length, 1)
      assert_eq(header.types[1].serial_type, 17)
      assert_eq(header.types[1].kind, 3)
      assert_eq(header.types[1].byte_length, 2)
      assert_eq(header.types[2].serial_type, 16)
      assert_eq(header.types[2].kind, 4)
      assert_eq(header.types[2].byte_length, 2)
      assert_eq(header.types[3].serial_type, 0)
      assert_eq(header.types[3].kind, 0)
      assert_eq(header.types[3].byte_length, 0)
    }
  }
}

///|
test "maps serial types to kinds and lengths" {
  assert_eq(@sqlite.serial_kind(0), 0)
  assert_eq(@sqlite.serial_kind(1), 1)
  assert_eq(@sqlite.serial_kind(6), 1)
  assert_eq(@sqlite.serial_kind(7), 2)
  assert_eq(@sqlite.serial_kind(8), 1)
  assert_eq(@sqlite.serial_kind(9), 1)
  assert_eq(@sqlite.serial_kind(16), 4)
  assert_eq(@sqlite.serial_kind(17), 3)
  assert_eq(@sqlite.serial_kind(10), 0 - 1)
  assert_eq(@sqlite.serial_byte_length(0), 0)
  assert_eq(@sqlite.serial_byte_length(3), 3)
  assert_eq(@sqlite.serial_byte_length(5), 6)
  assert_eq(@sqlite.serial_byte_length(7), 8)
  assert_eq(@sqlite.serial_byte_length(8), 0)
  assert_eq(@sqlite.serial_byte_length(16), 2)
  assert_eq(@sqlite.serial_byte_length(17), 2)
  assert_eq(@sqlite.serial_byte_length(11), 0 - 1)
}

///|
test "rejects a truncated varint" {
  match @sqlite.read_varint(b"\x80", 0) {
    Ok(_) => assert_true(false)
    Err(_) => assert_true(true)
  }
}

///|
test "rejects an empty record" {
  match @sqlite.parse_record_header(b"") {
    Ok(_) => assert_true(false)
    Err(_) => assert_true(true)
  }
}

///|
test "rejects a header longer than the payload" {
  match @sqlite.parse_record_header(b"\x7f\x00") {
    Ok(_) => assert_true(false)
    Err(_) => assert_true(true)
  }
}

///|
test "rejects a reserved serial type" {
  match @sqlite.parse_record_header(b"\x02\x0a") {
    Ok(_) => assert_true(false)
    Err(_) => assert_true(true)
  }
}

///|
test "text column carries its byte length" {
  match @sqlite.parse_record_header(b"\x02\x11") {
    Err(_) => assert_true(false)
    Ok(header) => {
      assert_eq(header.types.length(), 1)
      assert_eq(header.types[0].kind, 3)
      assert_eq(header.types[0].byte_length, 2)
    }
  }
}

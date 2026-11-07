///|
test "decodes a real record" {
  match @sqlite.decode_record(record_payload()) {
    Err(_) => assert_true(false)
    Ok(values) => {
      assert_eq(values.length(), 4)
      assert_eq(values[0].kind, 1)
      assert_eq(values[0].int_value.to_int(), 42)
      assert_eq(values[1].kind, 3)
      assert_eq(values[1].bytes.length(), 2)
      assert_eq(values[1].bytes.unsafe_get(0).to_int(), 0x68)
      assert_eq(values[1].bytes.unsafe_get(1).to_int(), 0x69)
      assert_eq(values[2].kind, 4)
      assert_eq(values[2].bytes.length(), 2)
      assert_eq(values[2].bytes.unsafe_get(0).to_int(), 0x01)
      assert_eq(values[2].bytes.unsafe_get(1).to_int(), 0x02)
      assert_eq(values[3].kind, 0)
    }
  }
}

///|
test "decodes a negative integer" {
  match @sqlite.decode_record(b"\x02\x01\xff") {
    Err(_) => assert_true(false)
    Ok(values) => {
      assert_eq(values.length(), 1)
      assert_eq(values[0].kind, 1)
      assert_eq(values[0].int_value.to_int(), 0 - 1)
    }
  }
}

///|
test "decodes constant integer serial types" {
  match @sqlite.decode_record(b"\x03\x08\x09") {
    Err(_) => assert_true(false)
    Ok(values) => {
      assert_eq(values.length(), 2)
      assert_eq(values[0].kind, 1)
      assert_eq(values[0].int_value.to_int(), 0)
      assert_eq(values[1].int_value.to_int(), 1)
    }
  }
}

///|
test "decodes an empty text value" {
  match @sqlite.decode_record(b"\x02\x0d") {
    Err(_) => assert_true(false)
    Ok(values) => {
      assert_eq(values.length(), 1)
      assert_eq(values[0].kind, 3)
      assert_eq(values[0].bytes.length(), 0)
    }
  }
}

///|
test "decodes a null value" {
  match @sqlite.decode_record(b"\x02\x00") {
    Err(_) => assert_true(false)
    Ok(values) => {
      assert_eq(values.length(), 1)
      assert_eq(values[0].kind, 0)
    }
  }
}

///|
test "rejects a truncated integer value" {
  match @sqlite.decode_record(b"\x03\x01\x00") {
    Ok(_) => assert_true(false)
    Err(_) => assert_true(true)
  }
}

///|
test "rejects real values until they are implemented" {
  match @sqlite.decode_record(b"\x02\x07") {
    Ok(_) => assert_true(false)
    Err(_) => assert_true(true)
  }
}

///|
fn leaf_page() -> Bytes {
  b"\x0d\x00\x00\x00\x01\x00\x16\x00\x00\x0a\x0a\x01\x05\x01\x11\x10\x00\x2a\x68\x69\x01\x02"
}

///|
test "reads the only cell of a leaf table page" {
  match @sqlite.read_leaf_table_cells(leaf_page(), 0, 22) {
    Err(_) => assert_true(false)
    Ok(cells) => {
      assert_eq(cells.length(), 1)
      assert_eq(cells[0].row_id.to_int(), 1)
      assert_eq(cells[0].payload_offset, 12)
      assert_eq(cells[0].payload_length, 10)
    }
  }
}

///|
test "cell payload decodes to the original row" {
  match @sqlite.read_leaf_table_cells(leaf_page(), 0, 22) {
    Err(_) => assert_true(false)
    Ok(cells) => {
      let payload = @sqlite.cell_payload(leaf_page(), cells[0])
      assert_eq(payload.length(), 10)
      match @sqlite.decode_record(payload) {
        Err(_) => assert_true(false)
        Ok(values) => {
          assert_eq(values.length(), 4)
          assert_eq(values[0].int_value.to_int(), 42)
          assert_eq(values[1].bytes.length(), 2)
          assert_eq(values[1].bytes.unsafe_get(0).to_int(), 0x68)
          assert_eq(values[3].kind, 0)
        }
      }
    }
  }
}

///|
test "rejects a non leaf page" {
  let page = with_byte(leaf_page(), 0, b"\x05".unsafe_get(0))
  match @sqlite.read_leaf_table_cells(page, 0, 22) {
    Ok(_) => assert_true(false)
    Err(_) => assert_true(true)
  }
}

///|
test "rejects a cell pointer beyond the page" {
  let page = with_byte(
    with_byte(leaf_page(), 8, b"\x00".unsafe_get(0)),
    9,
    b"\xff".unsafe_get(0),
  )
  match @sqlite.read_leaf_table_cells(page, 0, 22) {
    Ok(_) => assert_true(false)
    Err(_) => assert_true(true)
  }
}

///|
test "rejects a payload that overflows the page" {
  let page = with_byte(leaf_page(), 10, b"\x7f".unsafe_get(0))
  match @sqlite.read_leaf_table_cells(page, 0, 22) {
    Ok(_) => assert_true(false)
    Err(_) => assert_true(true)
  }
}

///|
fn fixture() -> Bytes {
  b"\x04\x00\x01\x7f\x05\x01\x02\x01\x03\x64\x32\x14\x08\x01\x00\xe5\x80\x01\xad\x82\x01"
}

///|
test "decodes columnar directory entries (reference pmtiles)" {
  match @pmtiles.decode_entries(fixture()) {
    Ok(entries) => {
      assert_eq(entries.length(), 4)
      assert_eq(entries[0].tile_id, @pmtiles.u64_from_int(0))
      assert_eq(entries[0].offset, @pmtiles.u64_from_int(0))
      assert_eq(entries[0].length, @pmtiles.u64_from_int(100))
      assert_eq(entries[0].run_length, @pmtiles.u64_from_int(1))
      assert_eq(entries[1].tile_id, @pmtiles.u64_from_int(1))
      assert_eq(entries[1].offset, @pmtiles.u64_from_int(100))
      assert_eq(entries[1].length, @pmtiles.u64_from_int(50))
      assert_eq(entries[1].run_length, @pmtiles.u64_from_int(2))
      assert_eq(entries[2].tile_id, @pmtiles.u64_from_int(128))
      assert_eq(entries[2].offset, @pmtiles.u64_from_int(16484))
      assert_eq(entries[2].length, @pmtiles.u64_from_int(20))
      assert_eq(entries[2].run_length, @pmtiles.u64_from_int(1))
      assert_eq(entries[3].tile_id, @pmtiles.u64_from_int(133))
      assert_eq(entries[3].offset, @pmtiles.u64_from_int(16684))
      assert_eq(entries[3].length, @pmtiles.u64_from_int(8))
      assert_eq(entries[3].run_length, @pmtiles.u64_from_int(3))
    }
    Err(_) => assert_true(false)
  }
}

///|
test "expands run length into tile refs" {
  match @pmtiles.decode_entries(fixture()) {
    Ok(entries) => {
      let tiles = @pmtiles.expand_runs(entries)
      assert_eq(tiles.length(), 7)
      assert_eq(tiles[0].tile_id, @pmtiles.u64_from_int(0))
      assert_eq(tiles[3].offset, @pmtiles.u64_from_int(16484))
      assert_eq(tiles[4].offset, @pmtiles.u64_from_int(16684))
      assert_eq(tiles[tiles.length() - 1].tile_id, @pmtiles.u64_from_int(135))
    }
    Err(_) => assert_true(false)
  }
}

///|
test "decodes a contiguous offset as zero" {
  match @pmtiles.decode_entries(b"\x02\x00\x01\x01\x01\x0a\x05\x01\x00") {
    Ok(entries) => {
      assert_eq(entries.length(), 2)
      assert_eq(entries[0].offset, @pmtiles.u64_from_int(0))
      assert_eq(entries[1].offset, @pmtiles.u64_from_int(10))
    }
    Err(_) => assert_true(false)
  }
}

///|
test "decodes a single entry directory" {
  match @pmtiles.decode_entries(b"\x01\x00\x01\x0a\x01") {
    Ok(entries) => {
      assert_eq(entries.length(), 1)
      assert_eq(entries[0].tile_id, @pmtiles.u64_from_int(0))
      assert_eq(entries[0].offset, @pmtiles.u64_from_int(0))
      assert_eq(entries[0].length, @pmtiles.u64_from_int(10))
      assert_eq(entries[0].run_length, @pmtiles.u64_from_int(1))
    }
    Err(_) => assert_true(false)
  }
}

///|
test "rejects an empty directory" {
  match @pmtiles.decode_entries(b"") {
    Ok(_) => assert_true(false)
    Err(_) => assert_true(true)
  }
}

///|
test "rejects a truncated entry column" {
  match @pmtiles.decode_entries(b"\x01\x00") {
    Ok(_) => assert_true(false)
    Err(_) => assert_true(true)
  }
}

///|
test "rejects an overlong count varint" {
  match @pmtiles.decode_entries(b"\x80\x80\x80\x80\x80\x80") {
    Ok(_) => assert_true(false)
    Err(_) => assert_true(true)
  }
}

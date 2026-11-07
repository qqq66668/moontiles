///|
fn fixture() -> Bytes {
  b"\x00\x01\x64\x00\x01\x02\x32\x64\x7f\x01\x14\x80\x80\x01\x05\x03\x08\xc8\x01"
}

///|
test "decodes directory entries (spec deltas)" {
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
      assert_eq(tiles[tiles.length() - 1].tile_id, @pmtiles.u64_from_int(135))
    }
    Err(_) => assert_true(false)
  }
}

///|
test "empty directory yields no entries" {
  match @pmtiles.decode_entries(b"") {
    Ok(entries) => assert_eq(entries.length(), 0)
    Err(_) => assert_true(false)
  }
}

///|
test "rejects a truncated varint" {
  match @pmtiles.decode_entries(b"\x80") {
    Ok(_) => assert_true(false)
    Err(_) => assert_true(true)
  }
}

///|
test "rejects an overlong varint" {
  let data : Bytes = b"\x80\x80\x80\x80\x80\x80\x80\x80\x80\x80\x80"
  match @pmtiles.decode_entries(data) {
    Ok(_) => assert_true(false)
    Err(_) => assert_true(true)
  }
}

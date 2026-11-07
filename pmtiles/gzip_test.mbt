///|
test "decodes a gzip compressed directory (reference decoder fixture)" {
  let compressed : Bytes = b"\x1f\x8b\x08\x00\x00\x00\x00\x00\x02\xff\x63\x61\x60\xac\x67\x65\x64\x62\x64\x4e\x31\x12\xe1\x60\x64\x78\xda\xc0\xb8\xb6\x89\x11\x00\x68\x4f\x29\x8b\x15\x00\x00\x00"
  match @pmtiles.decode_directory(compressed) {
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
test "rejects bytes that are not gzip" {
  let raw : Bytes = b"\x04\x00\x01"
  match @pmtiles.decode_directory(raw) {
    Ok(_) => assert_true(false)
    Err(_) => assert_true(true)
  }
}

///|
test "rejects a truncated gzip stream" {
  let truncated : Bytes = b"\x1f\x8b\x08\x00\x00\x00\x00\x00\x02\xff\x63\x61"
  match @pmtiles.decode_directory(truncated) {
    Ok(_) => assert_true(false)
    Err(_) => assert_true(true)
  }
}

///|
test "gunzip round trips plain entries" {
  let plain : Bytes = b"\x04\x00\x01\x7f\x05\x01\x02\x01\x03\x64\x32\x14\x08\x01\x00\xe5\x80\x01\xad\x82\x01"
  match @pmtiles.decode_entries(plain) {
    Ok(entries) => assert_eq(entries.length(), 4)
    Err(_) => assert_true(false)
  }
}

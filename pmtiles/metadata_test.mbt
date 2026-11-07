///|
test "reads metadata of a two level file" {
  match @pmtiles.PmtilesFile::from_bytes(file_fixture()) {
    Err(_) => assert_true(false)
    Ok(file) =>
      match file.metadata() {
        Err(_) => assert_true(false)
        Ok(bytes) => {
          assert_eq(bytes.length(), 4)
          assert_eq(bytes.unsafe_get(0).to_int(), 0x6d)
          assert_eq(bytes.unsafe_get(1).to_int(), 0x65)
          assert_eq(bytes.unsafe_get(2).to_int(), 0x74)
          assert_eq(bytes.unsafe_get(3).to_int(), 0x61)
        }
      }
  }
}

///|
test "reads metadata as text" {
  match @pmtiles.PmtilesFile::from_bytes(file_fixture()) {
    Err(_) => assert_true(false)
    Ok(file) =>
      match file.metadata_text() {
        Err(_) => assert_true(false)
        Ok(text) => assert_eq(text, "meta")
      }
  }
}

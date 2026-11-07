///|
fn entry(
  id : Int32,
  offset : Int32,
  length : Int32,
  run : Int32,
) -> @pmtiles.Entry {
  @pmtiles.Entry::new(
    @pmtiles.u64_from_int(id),
    @pmtiles.u64_from_int(offset),
    @pmtiles.u64_from_int(length),
    @pmtiles.u64_from_int(run),
  )
}

///|
test "finds an exact entry" {
  let entries = [entry(10, 500, 120, 1), entry(20, 700, 80, 1)]
  match @pmtiles.find_entry(entries, @pmtiles.u64_from_int(10)) {
    Some(hit) => {
      assert_eq(hit.offset, @pmtiles.u64_from_int(500))
      assert_eq(hit.length, @pmtiles.u64_from_int(120))
      assert_true(hit.is_leaf == false)
    }
    None => assert_true(false)
  }
}

///|
test "finds a tile inside a run" {
  let entries = [entry(10, 500, 120, 4), entry(20, 700, 80, 1)]
  match @pmtiles.find_entry(entries, @pmtiles.u64_from_int(13)) {
    Some(hit) => assert_eq(hit.offset, @pmtiles.u64_from_int(500))
    None => assert_true(false)
  }
}

///|
test "misses past the end of a run" {
  let entries = [entry(10, 500, 120, 2), entry(20, 700, 80, 1)]
  match @pmtiles.find_entry(entries, @pmtiles.u64_from_int(15)) {
    Some(_) => assert_true(false)
    None => assert_true(true)
  }
}

///|
test "misses before the first id" {
  let entries = [entry(10, 500, 120, 1)]
  match @pmtiles.find_entry(entries, @pmtiles.u64_from_int(3)) {
    Some(_) => assert_true(false)
    None => assert_true(true)
  }
}

///|
test "reports a leaf directory" {
  let entries = [entry(10, 4096, 300, 0)]
  match @pmtiles.find_entry(entries, @pmtiles.u64_from_int(10)) {
    Some(hit) => {
      assert_true(hit.is_leaf)
      assert_eq(hit.offset, @pmtiles.u64_from_int(4096))
      assert_eq(hit.length, @pmtiles.u64_from_int(300))
    }
    None => assert_true(false)
  }
}

///|
test "binary search over many entries" {
  let entries : Array[@pmtiles.Entry] = []
  for i = 0; i < 100; i = i + 1 {
    entries.push(entry(i * 2, i * 10, 5, 1))
  }
  for i = 0; i < 100; i = i + 1 {
    match @pmtiles.find_entry(entries, @pmtiles.u64_from_int(i * 2)) {
      Some(hit) => assert_eq(hit.offset, @pmtiles.u64_from_int(i * 10))
      None => assert_true(false)
    }
  }
}

///|
test "empty directory has no entries" {
  let entries : Array[@pmtiles.Entry] = []
  match @pmtiles.find_entry(entries, @pmtiles.u64_from_int(0)) {
    Some(_) => assert_true(false)
    None => assert_true(true)
  }
}

///|
test "tile_count: common zoom levels" {
  assert_eq(@tilemath.tile_count(0), 1)
  assert_eq(@tilemath.tile_count(1), 2)
  assert_eq(@tilemath.tile_count(10), 1024)
  assert_eq(@tilemath.tile_count(20), 1048576)
  assert_eq(@tilemath.tile_count(30), 1073741824)
}

///|
test "tile_count: doubles every zoom level" {
  for z = 1; z <= 30; z = z + 1 {
    assert_eq(@tilemath.tile_count(z), @tilemath.tile_count(z - 1) * 2)
  }
}

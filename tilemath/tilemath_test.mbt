///|
fn check_tile(
  z : Int32,
  lng : Double,
  lat : Double,
  ex : Int32,
  ey : Int32,
) -> Unit raise {
  let t = @tilemath.lnglat_to_tile(z, @tilemath.LngLat::new(lng, lat))
  assert_eq(t.z, z)
  assert_eq(t.x, ex)
  assert_eq(t.y, ey)
}

///|
test "tile_count: common zoom levels" {
  assert_eq(@tilemath.tile_count(0), 1)
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

///|
test "differential: mercantile" {
  check_tile(0, 116.3975, 39.9087, 0, 0)
  check_tile(1, -179.9, 85.0, 0, 0)
  check_tile(5, 0.0, 0.0, 16, 16)
  check_tile(12, 116.3975, 39.9087, 3372, 1552)
  check_tile(12, -122.4194, 37.7749, 655, 1583)
  check_tile(14, 179.999, -85.0, 16383, 16357)
  check_tile(18, 121.4737, 31.2304, 219526, 107113)
  check_tile(21, -73.9857, 40.7484, 617578, 788215)
}

///|
test "latitude is clamped to web mercator range" {
  let north = @tilemath.lnglat_to_tile(5, @tilemath.LngLat::new(10.0, 89.0))
  let south = @tilemath.lnglat_to_tile(5, @tilemath.LngLat::new(10.0, -89.0))
  assert_eq(north.y, 0)
  assert_eq(south.y, 31)
  assert_true(@tilemath.max_latitude() > 85.0)
  assert_true(@tilemath.max_latitude() < 85.1)
}

///|
test "longitude is normalized" {
  let a = @tilemath.lnglat_to_tile(4, @tilemath.LngLat::new(185.0, 0.0))
  let b = @tilemath.lnglat_to_tile(4, @tilemath.LngLat::new(-175.0, 0.0))
  assert_eq(a.x, b.x)
  assert_eq(a.y, b.y)
}

///|
test "world tile bounds at zoom 0" {
  let nw = @tilemath.tile_north_west(@tilemath.TileXYZ::new(0, 0, 0))
  let se = @tilemath.tile_south_east(@tilemath.TileXYZ::new(0, 0, 0))
  assert_eq(nw.lng, -180.0)
  assert_eq(se.lng, 180.0)
  assert_true(nw.lat > 85.0)
  assert_true(nw.lat < 85.1)
  assert_true(se.lat < -85.0)
  assert_true(se.lat > -85.1)
}

///|
test "tile center round trips" {
  let z = 12
  let n = @tilemath.tile_count(z)
  for x = 0; x < n; x = x + 1024 {
    for y = 0; y < n; y = y + 1024 {
      let c = @tilemath.tile_center(@tilemath.TileXYZ::new(z, x, y))
      let t = @tilemath.lnglat_to_tile(z, c)
      assert_eq(t.x, x)
      assert_eq(t.y, y)
    }
  }
}

///|
test "neighbor tiles share edges" {
  let a = @tilemath.TileXYZ::new(12, 3372, 1552)
  let east = @tilemath.TileXYZ::new(12, 3373, 1552)
  let south = @tilemath.TileXYZ::new(12, 3372, 1553)
  assert_eq(
    @tilemath.tile_south_east(a).lng,
    @tilemath.tile_north_west(east).lng,
  )
  assert_eq(
    @tilemath.tile_south_east(a).lat,
    @tilemath.tile_north_west(south).lat,
  )
}

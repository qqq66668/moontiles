///|
/// 用两段小整数拼出超过 Int 上限的期望编号，避免字面量越界。
fn big(hi : Int32, lo : Int32) -> UInt64 {
  @tilemath.u64_from_int(hi) * @tilemath.u64_from_int(1000000000) +
  @tilemath.u64_from_int(lo)
}

///|
test "world tile has id zero" {
  assert_eq(@tilemath.tile_id(0, 0, 0), @tilemath.u64_from_int(0))
}

///|
test "differential: reference pmtiles zxy_to_tileid" {
  assert_eq(@tilemath.tile_id(0, 0, 0), @tilemath.u64_from_int(0))
  assert_eq(@tilemath.tile_id(1, 0, 0), @tilemath.u64_from_int(1))
  assert_eq(@tilemath.tile_id(1, 0, 1), @tilemath.u64_from_int(2))
  assert_eq(@tilemath.tile_id(1, 1, 0), @tilemath.u64_from_int(4))
  assert_eq(@tilemath.tile_id(1, 1, 1), @tilemath.u64_from_int(3))
  assert_eq(@tilemath.tile_id(2, 0, 0), @tilemath.u64_from_int(5))
  assert_eq(@tilemath.tile_id(2, 0, 1), @tilemath.u64_from_int(8))
  assert_eq(@tilemath.tile_id(2, 0, 2), @tilemath.u64_from_int(9))
  assert_eq(@tilemath.tile_id(2, 0, 3), @tilemath.u64_from_int(10))
  assert_eq(@tilemath.tile_id(2, 1, 0), @tilemath.u64_from_int(6))
  assert_eq(@tilemath.tile_id(2, 1, 1), @tilemath.u64_from_int(7))
  assert_eq(@tilemath.tile_id(2, 1, 2), @tilemath.u64_from_int(12))
  assert_eq(@tilemath.tile_id(2, 1, 3), @tilemath.u64_from_int(11))
  assert_eq(@tilemath.tile_id(2, 2, 0), @tilemath.u64_from_int(19))
  assert_eq(@tilemath.tile_id(2, 2, 1), @tilemath.u64_from_int(18))
  assert_eq(@tilemath.tile_id(2, 2, 2), @tilemath.u64_from_int(13))
  assert_eq(@tilemath.tile_id(2, 2, 3), @tilemath.u64_from_int(14))
  assert_eq(@tilemath.tile_id(2, 3, 0), @tilemath.u64_from_int(20))
  assert_eq(@tilemath.tile_id(2, 3, 1), @tilemath.u64_from_int(17))
  assert_eq(@tilemath.tile_id(2, 3, 2), @tilemath.u64_from_int(16))
  assert_eq(@tilemath.tile_id(2, 3, 3), @tilemath.u64_from_int(15))
  assert_eq(@tilemath.tile_id(3, 0, 0), @tilemath.u64_from_int(21))
  assert_eq(@tilemath.tile_id(3, 0, 1), @tilemath.u64_from_int(22))
  assert_eq(@tilemath.tile_id(3, 0, 2), @tilemath.u64_from_int(35))
  assert_eq(@tilemath.tile_id(3, 0, 3), @tilemath.u64_from_int(36))
  assert_eq(@tilemath.tile_id(3, 0, 4), @tilemath.u64_from_int(37))
  assert_eq(@tilemath.tile_id(3, 0, 5), @tilemath.u64_from_int(40))
  assert_eq(@tilemath.tile_id(3, 0, 6), @tilemath.u64_from_int(41))
  assert_eq(@tilemath.tile_id(3, 0, 7), @tilemath.u64_from_int(42))
  assert_eq(@tilemath.tile_id(3, 1, 0), @tilemath.u64_from_int(24))
  assert_eq(@tilemath.tile_id(3, 1, 1), @tilemath.u64_from_int(23))
  assert_eq(@tilemath.tile_id(3, 1, 2), @tilemath.u64_from_int(34))
  assert_eq(@tilemath.tile_id(3, 1, 3), @tilemath.u64_from_int(33))
  assert_eq(@tilemath.tile_id(3, 1, 4), @tilemath.u64_from_int(38))
  assert_eq(@tilemath.tile_id(3, 1, 5), @tilemath.u64_from_int(39))
  assert_eq(@tilemath.tile_id(3, 1, 6), @tilemath.u64_from_int(44))
  assert_eq(@tilemath.tile_id(3, 1, 7), @tilemath.u64_from_int(43))
  assert_eq(@tilemath.tile_id(3, 2, 0), @tilemath.u64_from_int(25))
  assert_eq(@tilemath.tile_id(3, 2, 1), @tilemath.u64_from_int(28))
  assert_eq(@tilemath.tile_id(3, 2, 2), @tilemath.u64_from_int(29))
  assert_eq(@tilemath.tile_id(3, 2, 3), @tilemath.u64_from_int(32))
  assert_eq(@tilemath.tile_id(3, 2, 4), @tilemath.u64_from_int(51))
  assert_eq(@tilemath.tile_id(3, 2, 5), @tilemath.u64_from_int(50))
  assert_eq(@tilemath.tile_id(3, 2, 6), @tilemath.u64_from_int(45))
  assert_eq(@tilemath.tile_id(3, 2, 7), @tilemath.u64_from_int(46))
  assert_eq(@tilemath.tile_id(3, 3, 0), @tilemath.u64_from_int(26))
  assert_eq(@tilemath.tile_id(3, 3, 1), @tilemath.u64_from_int(27))
  assert_eq(@tilemath.tile_id(3, 3, 2), @tilemath.u64_from_int(30))
  assert_eq(@tilemath.tile_id(3, 3, 3), @tilemath.u64_from_int(31))
  assert_eq(@tilemath.tile_id(3, 3, 4), @tilemath.u64_from_int(52))
  assert_eq(@tilemath.tile_id(3, 3, 5), @tilemath.u64_from_int(49))
  assert_eq(@tilemath.tile_id(3, 3, 6), @tilemath.u64_from_int(48))
  assert_eq(@tilemath.tile_id(3, 3, 7), @tilemath.u64_from_int(47))
  assert_eq(@tilemath.tile_id(3, 4, 0), @tilemath.u64_from_int(79))
  assert_eq(@tilemath.tile_id(3, 4, 1), @tilemath.u64_from_int(78))
  assert_eq(@tilemath.tile_id(3, 4, 2), @tilemath.u64_from_int(75))
  assert_eq(@tilemath.tile_id(3, 4, 3), @tilemath.u64_from_int(74))
  assert_eq(@tilemath.tile_id(3, 4, 4), @tilemath.u64_from_int(53))
  assert_eq(@tilemath.tile_id(3, 4, 5), @tilemath.u64_from_int(56))
  assert_eq(@tilemath.tile_id(3, 4, 6), @tilemath.u64_from_int(57))
  assert_eq(@tilemath.tile_id(3, 4, 7), @tilemath.u64_from_int(58))
  assert_eq(@tilemath.tile_id(3, 5, 0), @tilemath.u64_from_int(80))
  assert_eq(@tilemath.tile_id(3, 5, 1), @tilemath.u64_from_int(77))
  assert_eq(@tilemath.tile_id(3, 5, 2), @tilemath.u64_from_int(76))
  assert_eq(@tilemath.tile_id(3, 5, 3), @tilemath.u64_from_int(73))
  assert_eq(@tilemath.tile_id(3, 5, 4), @tilemath.u64_from_int(54))
  assert_eq(@tilemath.tile_id(3, 5, 5), @tilemath.u64_from_int(55))
  assert_eq(@tilemath.tile_id(3, 5, 6), @tilemath.u64_from_int(60))
  assert_eq(@tilemath.tile_id(3, 5, 7), @tilemath.u64_from_int(59))
  assert_eq(@tilemath.tile_id(3, 6, 0), @tilemath.u64_from_int(81))
  assert_eq(@tilemath.tile_id(3, 6, 1), @tilemath.u64_from_int(82))
  assert_eq(@tilemath.tile_id(3, 6, 2), @tilemath.u64_from_int(71))
  assert_eq(@tilemath.tile_id(3, 6, 3), @tilemath.u64_from_int(72))
  assert_eq(@tilemath.tile_id(3, 6, 4), @tilemath.u64_from_int(67))
  assert_eq(@tilemath.tile_id(3, 6, 5), @tilemath.u64_from_int(66))
  assert_eq(@tilemath.tile_id(3, 6, 6), @tilemath.u64_from_int(61))
  assert_eq(@tilemath.tile_id(3, 6, 7), @tilemath.u64_from_int(62))
  assert_eq(@tilemath.tile_id(3, 7, 0), @tilemath.u64_from_int(84))
  assert_eq(@tilemath.tile_id(3, 7, 1), @tilemath.u64_from_int(83))
  assert_eq(@tilemath.tile_id(3, 7, 2), @tilemath.u64_from_int(70))
  assert_eq(@tilemath.tile_id(3, 7, 3), @tilemath.u64_from_int(69))
  assert_eq(@tilemath.tile_id(3, 7, 4), @tilemath.u64_from_int(68))
  assert_eq(@tilemath.tile_id(3, 7, 5), @tilemath.u64_from_int(65))
  assert_eq(@tilemath.tile_id(3, 7, 6), @tilemath.u64_from_int(64))
  assert_eq(@tilemath.tile_id(3, 7, 7), @tilemath.u64_from_int(63))
  assert_eq(@tilemath.tile_id(4, 0, 0), @tilemath.u64_from_int(85))
  assert_eq(@tilemath.tile_id(4, 15, 15), @tilemath.u64_from_int(255))
  assert_eq(@tilemath.tile_id(5, 1, 0), @tilemath.u64_from_int(344))
  assert_eq(@tilemath.tile_id(6, 32, 31), @tilemath.u64_from_int(4778))
  assert_eq(@tilemath.tile_id(8, 255, 0), @tilemath.u64_from_int(87380))
  assert_eq(@tilemath.tile_id(10, 512, 511), @tilemath.u64_from_int(1223338))
  assert_eq(@tilemath.tile_id(12, 3372, 1552), @tilemath.u64_from_int(19029167))
  assert_eq(@tilemath.tile_id(14, 0, 16383), @tilemath.u64_from_int(178956970))
  assert_eq(@tilemath.tile_id(16, 40000, 20000), big(5, 116627967))
  assert_eq(@tilemath.tile_id(18, 131072, 100000), big(80, 529308671))
  assert_eq(@tilemath.tile_id(20, 1048575, 0), big(1466, 15503700))
  assert_eq(@tilemath.tile_id(22, 4194303, 4194303), big(17592, 186044415))
}

///|
test "zoom 3 ids form a consecutive range" {
  let base = @tilemath.tile_id(3, 0, 0)
  assert_eq(base, @tilemath.u64_from_int(21))
  let mut sum = @tilemath.u64_from_int(0)
  let mut count = 0
  for x = 0; x < 8; x = x + 1 {
    for y = 0; y < 8; y = y + 1 {
      let id = @tilemath.tile_id(3, x, y)
      assert_true(id >= base)
      assert_true(id < base + @tilemath.u64_from_int(64))
      sum = sum + (id - base)
      count = count + 1
    }
  }
  assert_eq(count, 64)
  assert_eq(sum, @tilemath.u64_from_int(2016))
}

///|
test "tile_id_of agrees with tile_id" {
  let tile = @tilemath.TileXYZ::new(12, 3372, 1552)
  assert_eq(@tilemath.tile_id_of(tile), @tilemath.tile_id(12, 3372, 1552))
}

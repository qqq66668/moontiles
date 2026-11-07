///|
/// 把 Int 提升为 64 位无符号整数。
pub fn u64_from_int(n : Int32) -> UInt64 {
  n.to_uint64()
}

///|
/// 缩放级别 z 下的网格边长，即 2^z。
fn side(z : Int32) -> Int32 {
  1 << z
}

///|
/// Hilbert 曲线在 2^z × 2^z 网格上的序号；采用标准 xy2d 递推。
fn hilbert_index(z : Int32, x_in : Int32, y_in : Int32) -> UInt64 {
  let mut d = u64_from_int(0)
  let mut x = x_in
  let mut y = y_in
  let mut s = side(z) / 2
  while s > 0 {
    let mut rx = 0
    let mut ry = 0
    if (x & s) > 0 {
      rx = 1
    }
    if (y & s) > 0 {
      ry = 1
    }
    let mut weight = 0
    if rx == 0 {
      weight = ry
    } else if ry == 0 {
      weight = 3
    } else {
      weight = 2
    }
    let su = u64_from_int(s)
    d = d + su * su * u64_from_int(weight)
    if ry == 0 {
      if rx == 1 {
        x = s - 1 - x
        y = s - 1 - y
      }
      let t = x
      x = y
      y = t
    }
    s = s / 2
  }
  d
}

///|
/// 该级别之前所有级别的瓦片总数，(4^z - 1) / 3。
fn tiles_before(z : Int32) -> UInt64 {
  let mut total = u64_from_int(0)
  let mut i = 0
  while i < z {
    total = total * u64_from_int(4) + u64_from_int(1)
    i = i + 1
  }
  total
}

///|
/// PMTiles v3 的瓦片编号：之前所有级别的瓦片数加上本级别的 Hilbert 序号。
pub fn tile_id(z : Int32, x : Int32, y : Int32) -> UInt64 {
  tiles_before(z) + hilbert_index(z, x, y)
}

///|
/// 与 tile_id 等价，直接接受瓦片坐标。
pub fn tile_id_of(tile : TileXYZ) -> UInt64 {
  tile_id(tile.z, tile.x, tile.y)
}

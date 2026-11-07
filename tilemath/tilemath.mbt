///|
/// Web Mercator（EPSG:3857）瓦片坐标换算，采用 slippy map 编号约定：
/// 原点位于左上角，x 自西向东递增，y 自北向南递增。
///
/// 经纬度使用 WGS84 十进制度。

///|
fn pi() -> Double {
  3.141592653589793
}

///|
/// 缩放级别 z 下单轴的瓦片数量，即 2^z。
pub fn tile_count(z : Int32) -> Int32 {
  1 << z
}

///|
/// Web Mercator 可表示的纬度上限，单位度。
pub fn max_latitude() -> Double {
  85.05112877980659
}

///|
/// 经纬度坐标，单位度。
pub struct LngLat {
  lng : Double
  lat : Double
}

///|
/// 瓦片坐标：z 为缩放级别，x 自西向东，y 自北向南。
pub struct TileXYZ {
  z : Int32
  x : Int32
  y : Int32
}

///|
pub fn LngLat::new(lng : Double, lat : Double) -> LngLat {
  { lng, lat, }
}

///|
pub fn TileXYZ::new(z : Int32, x : Int32, y : Int32) -> TileXYZ {
  { z, x, y, }
}

///|
/// 自然对数：先按 2 的幂把参数归一到 [1, 2)，再用 atanh 级数展开。
fn ln(x : Double) -> Double {
  let mut m = x
  let mut k = 0
  while m >= 2.0 {
    m = m / 2.0
    k = k + 1
  }
  while m < 1.0 {
    m = m * 2.0
    k = k - 1
  }
  let z = (m - 1.0) / (m + 1.0)
  let z2 = z * z
  let mut item = z
  let mut sum = 0.0
  let mut j = 1
  while j <= 80 {
    sum = sum + item / Double::from_int(j)
    item = item * z2
    j = j + 2
  }
  2.0 * sum + Double::from_int(k) * 0.6931471805599453
}

///|
/// 墨卡托纵坐标：asinh(tan φ) = ln((sin φ + 1) / cos φ)。
fn mercator_value(lat : Double) -> Double {
  let rad = lat * pi() / 180.0
  let s = @math.cos(pi() / 2.0 - rad)
  let c = @math.cos(rad)
  ln((s + 1.0) / c)
}

///|
fn lat_from_mercator(value : Double) -> Double {
  let e = @math.exp(value)
  let sh = (e - 1.0 / e) / 2.0
  @math.atan(sh) * 180.0 / pi()
}

///|
/// 把经度规范化到 [-180, 180)。
fn normalize_lng(lng : Double) -> Double {
  lng - 360.0 * ((lng + 180.0) / 360.0).floor()
}

///|
/// 把纬度裁剪到 Web Mercator 可表示范围。
fn clamp_lat(lat : Double) -> Double {
  let limit = max_latitude()
  if lat > limit {
    limit
  } else if lat < 0.0 - limit {
    0.0 - limit
  } else {
    lat
  }
}

///|
/// 经纬度换算为瓦片坐标。
pub fn lnglat_to_tile(z : Int32, pos : LngLat) -> TileXYZ {
  let n = tile_count(z)
  let nf = Double::from_int(n)
  let lng = normalize_lng(pos.lng)
  let lat = clamp_lat(pos.lat)
  let mut x = ((lng + 180.0) / 360.0 * nf).floor().to_int()
  if x < 0 {
    x = 0
  }
  if x > n - 1 {
    x = n - 1
  }
  let mut y = ((1.0 - mercator_value(lat) / pi()) / 2.0 * nf).floor().to_int()
  if y < 0 {
    y = 0
  }
  if y > n - 1 {
    y = n - 1
  }
  { z, x, y, }
}

///|
fn row_lat(row : Double, nf : Double) -> Double {
  lat_from_mercator(pi() * (1.0 - 2.0 * row / nf))
}

///|
/// 瓦片左上角（西北角）经纬度。
pub fn tile_north_west(tile : TileXYZ) -> LngLat {
  let nf = Double::from_int(tile_count(tile.z))
  let lng = Double::from_int(tile.x) / nf * 360.0 - 180.0
  let lat = row_lat(Double::from_int(tile.y), nf)
  { lng, lat, }
}

///|
/// 瓦片右下角（东南角）经纬度。
pub fn tile_south_east(tile : TileXYZ) -> LngLat {
  let nf = Double::from_int(tile_count(tile.z))
  let lng = Double::from_int(tile.x + 1) / nf * 360.0 - 180.0
  let lat = row_lat(Double::from_int(tile.y) + 1.0, nf)
  { lng, lat, }
}

///|
/// 瓦片中心点经纬度。
pub fn tile_center(tile : TileXYZ) -> LngLat {
  let nf = Double::from_int(tile_count(tile.z))
  let lng = (Double::from_int(tile.x) + 0.5) / nf * 360.0 - 180.0
  let lat = row_lat(Double::from_int(tile.y) + 0.5, nf)
  { lng, lat, }
}

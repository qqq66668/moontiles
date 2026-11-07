///|
/// MBTiles 容器：数据库文件头、schema 中两张表的根页号。
pub struct Mbtiles {
  data : Bytes
  db : @sqlite.DbHeader
  metadata_root : Int32
  tiles_root : Int32
}

///|
/// 把一段字节解码为 UTF-8 文本，失败返回 None。
fn text_of(bytes : Bytes) -> String? {
  Some(@utf8.decode(bytes.exact_view())) catch {
    _ => None
  }
}

///|
/// 读取 schema 表（根页 1），找出 metadata 与 tiles 的根页号。
pub fn Mbtiles::from_bytes(data : Bytes) -> Result[Mbtiles, String] {
  let db = match @sqlite.parse_db_header(data) {
    Ok(h) => h
    Err(msg) => return Err(msg)
  }
  let schema = match @sqlite.read_table_values(data, db, 1) {
    Ok(rows) => rows
    Err(msg) => return Err(msg)
  }
  let mut metadata_root = 0 - 1
  let mut tiles_root = 0 - 1
  let mut i = 0
  while i < schema.length() {
    let values = schema[i]
    if values.length() >= 4 {
      let name = match text_of(values[1].bytes) {
        Some(t) => t
        None => ""
      }
      if name == "metadata" {
        metadata_root = values[3].int_value.to_int()
      } else if name == "tiles" {
        tiles_root = values[3].int_value.to_int()
      }
    }
    i = i + 1
  }
  if metadata_root < 1 {
    return Err("mbtiles: metadata table is missing")
  }
  if tiles_root < 1 {
    return Err("mbtiles: tiles table is missing")
  }
  let file : Mbtiles = { data, db, metadata_root, tiles_root, }
  Ok(file)
}

///|
/// 元数据表根页号。
pub fn Mbtiles::metadata_root(self : Mbtiles) -> Int32 {
  self.metadata_root
}

///|
/// 瓦片表根页号。
pub fn Mbtiles::tiles_root(self : Mbtiles) -> Int32 {
  self.tiles_root
}

///|
/// 读出元数据表的全部键值对；无法解码的文本列跳过。
pub fn Mbtiles::metadata_pairs(
  self : Mbtiles,
) -> Result[Array[(String, String)], String] {
  let rows = match
    @sqlite.read_table_values(self.data, self.db, self.metadata_root) {
    Ok(r) => r
    Err(msg) => return Err(msg)
  }
  let pairs : Array[(String, String)] = []
  let mut i = 0
  while i < rows.length() {
    let values = rows[i]
    if values.length() >= 2 {
      let key = text_of(values[0].bytes)
      let value = text_of(values[1].bytes)
      match (key, value) {
        (Some(k), Some(v)) => pairs.push((k, v))
        _ => ()
      }
    }
    i = i + 1
  }
  Ok(pairs)
}

///|
/// 按键取元数据值。
pub fn Mbtiles::metadata(
  self : Mbtiles,
  key : String,
) -> Result[String?, String] {
  let pairs = match self.metadata_pairs() {
    Ok(p) => p
    Err(msg) => return Err(msg)
  }
  let mut i = 0
  while i < pairs.length() {
    let (k, v) = pairs[i]
    if k == key {
      return Ok(Some(v))
    }
    i = i + 1
  }
  Ok(None)
}

///|
/// 按 z/x/y 取瓦片；MBTiles 的行号是 TMS 约定，需要用 2^z - 1 - y 换算。
///
/// 找不到对应瓦片时返回 None，表结构不符时返回错误说明。
pub fn Mbtiles::tile(
  self : Mbtiles,
  z : Int32,
  x : Int32,
  y : Int32,
) -> Result[Bytes?, String] {
  let rows = match
    @sqlite.read_table_values(self.data, self.db, self.tiles_root) {
    Ok(r) => r
    Err(msg) => return Err(msg)
  }
  let n = 1 << z
  let tms_row = n - 1 - y
  let mut i = 0
  while i < rows.length() {
    let values = rows[i]
    if values.length() >= 4 {
      let zz = values[0].int_value.to_int()
      let xx = values[1].int_value.to_int()
      let yy = values[2].int_value.to_int()
      if zz == z && xx == x && yy == tms_row {
        return Ok(Some(values[3].bytes))
      }
    }
    i = i + 1
  }
  Ok(None)
}

///|
/// 瓦片表中的行数。
pub fn Mbtiles::tile_row_count(self : Mbtiles) -> Result[Int32, String] {
  let rows = match
    @sqlite.read_table_values(self.data, self.db, self.tiles_root) {
    Ok(r) => r
    Err(msg) => return Err(msg)
  }
  Ok(rows.length())
}

///|
/// 把 64 位无符号整数转成 Int，用于把文件内偏移换算成下标。
pub fn u64_to_int(value : UInt64) -> Int32 {
  value.to_int()
}

///|
/// 从整个文件中截取一段字节；越界时返回错误而不是 panic。
pub fn slice_bytes(
  data : Bytes,
  start : Int32,
  len : Int32,
) -> Result[Bytes, String] {
  if start < 0 || len < 0 || start + len > data.length() {
    return Err("pmtiles: section is out of range")
  }
  let buf = Buffer()
  let mut i = 0
  while i < len {
    buf.write_byte(data.unsafe_get(start + i))
    i = i + 1
  }
  Ok(buf.to_bytes())
}

///|
/// 已解析的 PMTiles 文件：保留原始字节、头部与根目录。
pub struct PmtilesFile {
  data : Bytes
  header : Header
  root : Array[Entry]
}

///|
/// 从完整文件字节构造；头部非法或根目录无法解压时返回错误说明。
pub fn PmtilesFile::from_bytes(data : Bytes) -> Result[PmtilesFile, String] {
  let header = match parse_header(data) {
    Ok(h) => h
    Err(msg) => return Err(msg)
  }
  let root_start = u64_to_int(header.root_dir_offset)
  let root_len = u64_to_int(header.root_dir_length)
  let root_raw = match slice_bytes(data, root_start, root_len) {
    Ok(b) => b
    Err(msg) => return Err(msg)
  }
  let root_plain = match gunzip(root_raw) {
    Ok(b) => b
    Err(msg) => return Err(msg)
  }
  let root = match decode_entries(root_plain) {
    Ok(e) => e
    Err(msg) => return Err(msg)
  }
  let file : PmtilesFile = { data, header, root, }
  Ok(file)
}

///|
/// 头部摘要。
pub fn PmtilesFile::header(self : PmtilesFile) -> Header {
  self.header
}

///|
/// 根目录条目数。
pub fn PmtilesFile::root_entry_count(self : PmtilesFile) -> Int32 {
  self.root.length()
}

///|
/// 读取一层叶目录：按 header.leaf_dir_offset 定位后解压并解码。
fn PmtilesFile::read_leaf(
  self : PmtilesFile,
  hit : FoundTile,
) -> Result[Array[Entry], String] {
  let base = u64_to_int(self.header.leaf_dir_offset)
  let start = base + u64_to_int(hit.offset)
  let raw = match slice_bytes(self.data, start, u64_to_int(hit.length)) {
    Ok(b) => b
    Err(msg) => return Err(msg)
  }
  let plain = match gunzip(raw) {
    Ok(b) => b
    Err(msg) => return Err(msg)
  }
  decode_entries(plain)
}

///|
/// 按 z/x/y 取瓦片原始字节；文件内不存在该瓦片时返回 None。
pub fn PmtilesFile::tile(
  self : PmtilesFile,
  z : Int32,
  x : Int32,
  y : Int32,
) -> Result[Bytes?, String] {
  let id = @tilemath.tile_id(z, x, y)
  let mut dir = self.root
  let mut depth = 0
  while depth <= 4 {
    let hit = match find_entry(dir, id) {
      Some(found) => found
      None => return Ok(None)
    }
    if hit.is_leaf {
      dir = match self.read_leaf(hit) {
        Ok(entries) => entries
        Err(msg) => return Err(msg)
      }
      depth = depth + 1
    } else {
      let start = u64_to_int(self.header.tile_data_offset) +
        u64_to_int(hit.offset)
      let payload = match
        slice_bytes(self.data, start, u64_to_int(hit.length)) {
        Ok(b) => b
        Err(msg) => return Err(msg)
      }
      return Ok(Some(payload))
    }
  }
  Err("pmtiles: directory depth exceeded")
}

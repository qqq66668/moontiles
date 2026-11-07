///|
/// PMTiles v3 文件头长度，固定 127 字节。
pub fn header_size() -> Int32 {
  127
}

///|
/// 把 Int 提升为 64 位无符号整数。
pub fn u64_from_int(n : Int32) -> UInt64 {
  n.to_uint64()
}

///|
/// PMTiles v3 文件头，字段顺序与规范保持一致。
///
/// 偏移量以文件起始处为原点；E7 后缀表示按 1e7 缩放后的整数角度。
pub struct Header {
  spec_version : Int32
  root_dir_offset : UInt64
  root_dir_length : UInt64
  metadata_offset : UInt64
  metadata_length : UInt64
  leaf_dir_offset : UInt64
  leaf_dir_length : UInt64
  tile_data_offset : UInt64
  tile_data_length : UInt64
  addressed_tiles_count : UInt64
  tile_entries_count : UInt64
  tile_contents_count : UInt64
  clustered : Bool
  internal_compression : Int32
  tile_compression : Int32
  tile_type : Int32
  min_zoom : Int32
  max_zoom : Int32
  min_lon_e7 : Int32
  min_lat_e7 : Int32
  max_lon_e7 : Int32
  max_lat_e7 : Int32
  center_zoom : Int32
  center_lon_e7 : Int32
  center_lat_e7 : Int32
}

///|
fn read_byte(data : Bytes, off : Int32) -> Int32 {
  data.unsafe_get(off).to_int()
}

///|
/// 小端四字节有符号整数，按 32 位补码解释。
fn read_i32_le(data : Bytes, off : Int32) -> Int32 {
  let b0 = read_byte(data, off)
  let b1 = read_byte(data, off + 1)
  let b2 = read_byte(data, off + 2)
  let b3 = read_byte(data, off + 3)
  b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)
}

///|
/// 小端八字节整数，按字节由低向高累积。
fn read_u64_le(data : Bytes, off : Int32) -> UInt64 {
  let mut value = u64_from_int(0)
  let mut index = 7
  while index >= 0 {
    let byte = u64_from_int(read_byte(data, off + index))
    value = value * u64_from_int(256) + byte
    index = index - 1
  }
  value
}

///|
fn has_pmtiles_magic(data : Bytes) -> Bool {
  read_byte(data, 0) == 0x50 &&
  read_byte(data, 1) == 0x4D &&
  read_byte(data, 2) == 0x54 &&
  read_byte(data, 3) == 0x69 &&
  read_byte(data, 4) == 0x6C &&
  read_byte(data, 5) == 0x65 &&
  read_byte(data, 6) == 0x73
}

///|
fn is_known_compression(value : Int32) -> Bool {
  value >= 0 && value <= 4
}

///|
fn is_known_tile_type(value : Int32) -> Bool {
  value >= 0 && value <= 5
}

///|
/// 压缩算法编号对应的名字：1 不压缩、2 gzip、3 brotli、4 zstd。
pub fn compression_name(value : Int32) -> String {
  match value {
    1 => "none"
    2 => "gzip"
    3 => "brotli"
    4 => "zstd"
    _ => "unknown"
  }
}

///|
/// 瓦片类型编号对应的名字：1 mvt、2 png、3 jpeg、4 webp、5 avif。
pub fn tile_type_name(value : Int32) -> String {
  match value {
    1 => "mvt"
    2 => "png"
    3 => "jpeg"
    4 => "webp"
    5 => "avif"
    _ => "unknown"
  }
}

///|
/// 解析 PMTiles v3 文件头；长度不足或字段越界时返回错误说明。
pub fn parse_header(data : Bytes) -> Result[Header, String] {
  if data.length() < header_size() {
    return Err("pmtiles: header is shorter than 127 bytes")
  }
  if has_pmtiles_magic(data) == false {
    return Err("pmtiles: magic is not PMTiles")
  }
  let version = read_byte(data, 7)
  if version != 3 {
    return Err("pmtiles: spec version is not 3")
  }
  let clustered = read_byte(data, 96) == 1
  let internal_compression = read_byte(data, 97)
  let tile_compression = read_byte(data, 98)
  let tile_type = read_byte(data, 99)
  let min_zoom = read_byte(data, 100)
  let max_zoom = read_byte(data, 101)
  if is_known_compression(internal_compression) == false {
    return Err("pmtiles: unknown internal compression")
  }
  if is_known_compression(tile_compression) == false {
    return Err("pmtiles: unknown tile compression")
  }
  if is_known_tile_type(tile_type) == false {
    return Err("pmtiles: unknown tile type")
  }
  if min_zoom > max_zoom {
    return Err("pmtiles: min zoom is greater than max zoom")
  }
  let header : Header = {
    spec_version: version,
    root_dir_offset: read_u64_le(data, 8),
    root_dir_length: read_u64_le(data, 16),
    metadata_offset: read_u64_le(data, 24),
    metadata_length: read_u64_le(data, 32),
    leaf_dir_offset: read_u64_le(data, 40),
    leaf_dir_length: read_u64_le(data, 48),
    tile_data_offset: read_u64_le(data, 56),
    tile_data_length: read_u64_le(data, 64),
    addressed_tiles_count: read_u64_le(data, 72),
    tile_entries_count: read_u64_le(data, 80),
    tile_contents_count: read_u64_le(data, 88),
    clustered,
    internal_compression,
    tile_compression,
    tile_type,
    min_zoom,
    max_zoom,
    min_lon_e7: read_i32_le(data, 102),
    min_lat_e7: read_i32_le(data, 106),
    max_lon_e7: read_i32_le(data, 110),
    max_lat_e7: read_i32_le(data, 114),
    center_zoom: read_byte(data, 118),
    center_lon_e7: read_i32_le(data, 119),
    center_lat_e7: read_i32_le(data, 123),
  }
  Ok(header)
}

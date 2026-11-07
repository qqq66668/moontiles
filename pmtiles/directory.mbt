///|
/// 变长整数（LEB128）解码结果：数值与下一个字节位置。
pub struct Varint {
  value : UInt64
  next : Int32
}

///|
/// 目录项：tile_id 与 offset 存的是相对前一项的增量。
pub struct Entry {
  tile_id : UInt64
  offset : UInt64
  length : UInt64
  run_length : UInt64
}

///|
/// 展开 run-length 之后的瓦片引用。
pub struct TileRef {
  tile_id : UInt64
  offset : UInt64
  length : UInt64
}

///|
/// 从 start 起读一个无符号变长整数；截断或超过 10 字节时返回错误。
fn read_varint(data : Bytes, start : Int32) -> Result[Varint, String] {
  let mut value = u64_from_int(0)
  let mut scale = u64_from_int(1)
  let mut index = start
  let mut count = 0
  let mut done = false
  let mut too_long = false
  while done == false && index < data.length() {
    if count >= 10 {
      too_long = true
      done = true
    } else {
      let byte = u64_from_int(data.unsafe_get(index).to_int())
      index = index + 1
      let high = byte / u64_from_int(128)
      let low = byte - high * u64_from_int(128)
      value = value + low * scale
      scale = scale * u64_from_int(128)
      count = count + 1
      if high == u64_from_int(0) {
        done = true
      }
    }
  }
  if too_long {
    return Err("pmtiles: varint is longer than 10 bytes")
  }
  if done == false {
    return Err("pmtiles: truncated varint in directory")
  }
  let result : Varint = { value, next: index, }
  Ok(result)
}

///|
/// 解析已解压的目录字节；每项依次是 tile_id 增量、run_length、length、offset 增量。
pub fn decode_entries(data : Bytes) -> Result[Array[Entry], String] {
  let entries : Array[Entry] = []
  let mut index = 0
  let mut last_id = u64_from_int(0)
  let mut last_offset = u64_from_int(0)
  let total = data.length()
  while index < total {
    let id_r = match read_varint(data, index) {
      Ok(r) => r
      Err(msg) => return Err(msg)
    }
    let run_r = match read_varint(data, id_r.next) {
      Ok(r) => r
      Err(msg) => return Err(msg)
    }
    let len_r = match read_varint(data, run_r.next) {
      Ok(r) => r
      Err(msg) => return Err(msg)
    }
    let off_r = match read_varint(data, len_r.next) {
      Ok(r) => r
      Err(msg) => return Err(msg)
    }
    last_id = last_id + id_r.value
    last_offset = last_offset + off_r.value
    let entry : Entry = {
      tile_id: last_id,
      offset: last_offset,
      length: len_r.value,
      run_length: run_r.value,
    }
    entries.push(entry)
    index = off_r.next
  }
  Ok(entries)
}

///|
/// 把 run-length 展开成逐瓦片引用，供按 tile_id 查询。
pub fn expand_runs(entries : Array[Entry]) -> Array[TileRef] {
  let tiles : Array[TileRef] = []
  let mut i = 0
  while i < entries.length() {
    let entry = entries[i]
    let mut left = entry.run_length
    let mut id = entry.tile_id
    while left > u64_from_int(0) {
      let tile_ref : TileRef = {
        tile_id: id,
        offset: entry.offset,
        length: entry.length,
      }
      tiles.push(tile_ref)
      id = id + u64_from_int(1)
      left = left - u64_from_int(1)
    }
    i = i + 1
  }
  tiles
}

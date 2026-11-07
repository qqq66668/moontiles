///|
/// 变长整数（LEB128）解码结果：数值与下一个字节位置。
pub struct Varint {
  value : UInt64
  next : Int32
}

///|
/// 条目数这类小整数使用 32 位读取。
pub struct CountVarint {
  value : Int32
  next : Int32
}

///|
/// 目录项：tile_id 与 offset 均为绝对值。
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
/// 读取条目数：最多 5 字节，负值视为非法。
fn read_count_varint(
  data : Bytes,
  start : Int32,
) -> Result[CountVarint, String] {
  let mut value = 0
  let mut index = start
  let mut count = 0
  let mut done = false
  let mut too_long = false
  while done == false && index < data.length() {
    if count >= 5 {
      too_long = true
      done = true
    } else {
      let byte = data.unsafe_get(index).to_int()
      index = index + 1
      let high = byte / 128
      let low = byte - high * 128
      value = value + (low << (7 * count))
      count = count + 1
      if high == 0 {
        done = true
      }
    }
  }
  if too_long {
    return Err("pmtiles: entry count varint is longer than 5 bytes")
  }
  if done == false {
    return Err("pmtiles: truncated entry count")
  }
  if value < 0 {
    return Err("pmtiles: entry count is negative")
  }
  let result : CountVarint = { value, next: index, }
  Ok(result)
}

///|
/// 解析已解压的目录字节。规范为列式布局：
/// 条目数、tile_id 增量列、run_length 列、length 列、offset 列。
///
/// offset 列：0 表示与上一项数据紧邻（上一项 offset + length），
/// 非 0 表示该值是绝对偏移加一。
pub fn decode_entries(data : Bytes) -> Result[Array[Entry], String] {
  let count_r = match read_count_varint(data, 0) {
    Ok(r) => r
    Err(msg) => return Err(msg)
  }
  let count = count_r.value
  let ids : Array[UInt64] = []
  let runs : Array[UInt64] = []
  let lengths : Array[UInt64] = []
  let offsets : Array[UInt64] = []
  let mut pos = count_r.next
  let mut last_id = u64_from_int(0)
  let mut i = 0
  while i < count {
    let r = match read_varint(data, pos) {
      Ok(v) => v
      Err(msg) => return Err(msg)
    }
    last_id = last_id + r.value
    ids.push(last_id)
    pos = r.next
    i = i + 1
  }
  let mut j = 0
  while j < count {
    let r = match read_varint(data, pos) {
      Ok(v) => v
      Err(msg) => return Err(msg)
    }
    runs.push(r.value)
    pos = r.next
    j = j + 1
  }
  let mut k = 0
  while k < count {
    let r = match read_varint(data, pos) {
      Ok(v) => v
      Err(msg) => return Err(msg)
    }
    lengths.push(r.value)
    pos = r.next
    k = k + 1
  }
  let mut last_offset = u64_from_int(0)
  let mut last_length = u64_from_int(0)
  let mut m = 0
  while m < count {
    let r = match read_varint(data, pos) {
      Ok(v) => v
      Err(msg) => return Err(msg)
    }
    let mut value = r.value
    if m > 0 && value == u64_from_int(0) {
      value = last_offset + last_length
    } else if value > u64_from_int(0) {
      value = value - u64_from_int(1)
    }
    offsets.push(value)
    last_offset = value
    last_length = lengths[m]
    pos = r.next
    m = m + 1
  }
  let entries : Array[Entry] = []
  let mut n = 0
  while n < count {
    let entry : Entry = {
      tile_id: ids[n],
      offset: offsets[n],
      length: lengths[n],
      run_length: runs[n],
    }
    entries.push(entry)
    n = n + 1
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

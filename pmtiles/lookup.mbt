///|
/// 目录查找结果：命中的瓦片数据位置。
pub struct FoundTile {
  offset : UInt64
  length : UInt64
  is_leaf : Bool
}

///|
/// 构造目录项。
pub fn Entry::new(
  tile_id : UInt64,
  offset : UInt64,
  length : UInt64,
  run_length : UInt64,
) -> Entry {
  { tile_id, offset, length, run_length, }
}

///|
/// 在已解压目录上按 tile_id 二分查找。
///
/// run_length 为 0 表示该条目指向叶目录，调用方需读取并解压后递归查找；
/// 目标超出区间或目录为空时返回 None。
pub fn find_entry(entries : Array[Entry], target : UInt64) -> FoundTile? {
  let count = entries.length()
  if count == 0 {
    return None
  }
  if target < entries[0].tile_id {
    return None
  }
  let mut low = 0
  let mut high = count - 1
  while low < high {
    let mid = (low + high + 1) / 2
    if entries[mid].tile_id <= target {
      low = mid
    } else {
      high = mid - 1
    }
  }
  let entry = entries[low]
  if entry.run_length == u64_from_int(0) {
    let leaf : FoundTile = {
      offset: entry.offset,
      length: entry.length,
      is_leaf: true,
    }
    return Some(leaf)
  }
  if target < entry.tile_id + entry.run_length {
    let hit : FoundTile = {
      offset: entry.offset,
      length: entry.length,
      is_leaf: false,
    }
    return Some(hit)
  }
  None
}

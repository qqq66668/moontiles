///|
/// 解压 PMTiles 内部的 gzip 数据：目录块与元数据块都按 gzip 压缩。
pub fn gunzip(data : Bytes) -> Result[Bytes, String] {
  let plain = Some(@gzip.decompress(data.exact_view())) catch { _ => None }
  match plain {
    None => Err("pmtiles: gzip decompression failed")
    Some(bytes) => Ok(bytes)
  }
}

///|
/// 解码一段已压缩目录：先 gzip 解压，再按列式布局解析。
pub fn decode_directory(data : Bytes) -> Result[Array[Entry], String] {
  match gunzip(data) {
    Err(msg) => Err(msg)
    Ok(plain) => decode_entries(plain)
  }
}

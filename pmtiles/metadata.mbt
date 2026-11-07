///|
/// 读取文件内的元数据块：按 header 给出的偏移与长度截取，再解 gzip。
///
/// 返回的是 JSON 文本的原始字节，调用方自行决定是否解析。
pub fn PmtilesFile::metadata(self : PmtilesFile) -> Result[Bytes, String] {
  let start = u64_to_int(self.header.metadata_offset)
  let len = u64_to_int(self.header.metadata_length)
  if len == 0 {
    return Err("pmtiles: metadata section is empty")
  }
  let raw = match slice_bytes(self.data, start, len) {
    Ok(b) => b
    Err(msg) => return Err(msg)
  }
  gunzip(raw)
}

///|
/// 读取元数据并解码为 UTF-8 文本；非法 UTF-8 返回错误说明。
pub fn PmtilesFile::metadata_text(self : PmtilesFile) -> Result[String, String] {
  let bytes = match self.metadata() {
    Ok(b) => b
    Err(msg) => return Err(msg)
  }
  let decoded = Some(@utf8.decode(bytes.exact_view())) catch { _ => None }
  match decoded {
    Some(text) => Ok(text)
    None => Err("pmtiles: metadata is not valid utf-8")
  }
}

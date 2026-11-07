# moontiles

纯 MoonBit 实现的地图瓦片容器工具集，用于读取、检查与转换离线地图数据。

## 解决的痛点

离线地图、无人机底图与 GIS 数据交付依赖瓦片容器格式。MoonBit 现有生态已有矢量瓦片单张解析、GeoJSON/WKB 编解码与大地线计算，但缺少瓦片容器层：无法读取 PMTiles 单文件包、MBTiles 数据库或 GeoPackage 瓦片表。

本库补齐这一层，并提供统一的命令行入口。

## 计划覆盖的容器

| 容器 | 规范 | 定位 |
| --- | --- | --- |
| PMTiles v3 | https://github.com/protomaps/PMTiles/blob/main/spec/v3/spec.md | 单文件分发，Hilbert 目录 |
| MBTiles 1.3 | https://github.com/mapbox/mbtiles-spec/blob/master/1.3/spec.md | SQLite 瓦片库，生态成熟 |
| GeoPackage 1.4 | https://www.geopackage.org/spec/ | OGC 标准，矢量与栅格通用 |

## 非目标

- 瓦片渲染与栅格化
- 投影变换与大地线计算（由 moongeodesy 等库负责）
- 矢量瓦片内容解码（容器层原样透传）
- 完整 SQLite 引擎实现（仅只读子集）

## 包结构

| 包 | 职责 |
| --- | --- |
| tilemath | 瓦片金字塔换算、Hilbert id、varint 编解码 |
| pmtiles | PMTiles v3 header 解析、目录解码、按坐标取瓦片 |
| mbtiles | 只读 SQLite 子集与 MBTiles 查询 |
| gpkg | GeoPackage 瓦片表读取 |
| cmd/moontiles | 命令行入口 |

## 状态

0.1.0 开发中，尚未发布到 mooncakes.io。

## 安装（发布后）

moon add qqq66668/moontiles

## 许可

Apache-2.0

## 已实现 API

tilemath 包：

| 函数 | 说明 |
| --- | --- |
| tile_count(z) | 单轴瓦片数 2^z |
| max_latitude() | Web Mercator 纬度上限 |
| lnglat_to_tile(z, LngLat) | 经纬度换算为 TileXYZ |
| tile_north_west / tile_south_east / tile_center | 瓦片角点与中心 |

示例：

```moonbit
let t = @tilemath.lnglat_to_tile(12, @tilemath.LngLat::new(116.3975, 39.9087))
// t.x = 3372, t.y = 1552
```

## pmtiles 包

| 函数 | 说明 |
| --- | --- |
| header_size() | 头部长度，固定 127 |
| parse_header(Bytes) | 解析并校验 v3 头部，返回 Result |
| compression_name / tile_type_name | 枚举编号转名字 |
| u64_from_int(Int) | 整数提升为 64 位 |

示例：

```moonbit
match @pmtiles.parse_header(bytes) {
  Ok(h) => println(h.tile_data_offset)
  Err(e) => println(e)
}
```

## 目录解码

| 函数 | 说明 |
| --- | --- |
| decode_entries(Bytes) | 解析已解压目录，返回 Result[Array[Entry], String] |
| expand_runs(Array[Entry]) | 展开 run-length 得到逐瓦片引用 |

目录项字段均为 LEB128 变长整数：tile_id 增量、run_length、length、offset 增量。
## 与参考实现对拍

目录解码与参考实现 pmtiles 3.8.1 对拍：fixture 按规范编码后交给参考实现解码，四列（tile_id / offset / length / run_length）逐项一致。

offset 列规则：值为 0 表示与上一项数据紧邻（上一项 offset + length）；非 0 表示该值为绝对偏移加一。

## tile_id

PMTiles v3 的瓦片编号 = 之前所有级别的瓦片数 + 本级别 Hilbert 曲线序号：

moonbit
let id = @tilemath.tile_id(12, 3372, 1552)

97 组 (z, x, y) 的编号与参考实现 pmtiles 3.8.1 的 zxy_to_tileid 逐项一致。
## 目录查找

| 函数 | 说明 |
| --- | --- |
| find_entry(entries, target) | 二分查找；命中返回 offset/length |
| is_leaf = true | 该条目指向叶目录，需解压后递归查找 |
| None | 目录为空或目标超出区间 |

## 压缩目录

PMTiles 的目录块与元数据块按 gzip 压缩，读取时需先解压。

| 函数 | 说明 |
| --- | --- |
| gunzip(Bytes) | 解压 gzip 数据，失败返回错误说明 |
| decode_directory(Bytes) | 解压后按列式布局解析目录 |

解压复用 moonbit-community/flate 的 gzip 包，不在本库重复实现 DEFLATE。

## 运行示例

命令行示例内置一段真实结构的 v3 样例数据，直接解析并打印头部、根目录与瓦片摘要：

```bash
moon run cmd/moontiles --target wasm-gc
```

wasm-gc 与 native 均可运行，不依赖任何外部文件。

## B 树页

SQLite 把表与索引存成 B 树页；读取单元前需要先解析页头与单元指针数组。

| 函数 | 说明 |
| --- | --- |
| page_header_start(page_no, db) | 页头在文件中的偏移，第 1 页在 100 字节头之后 |
| parse_page_header(data, start) | 解析页类型、单元数、内容区起点、碎片字节 |
| cell_pointers(data, start, page) | 读出单元指针数组，越界返回错误 |

```moonbit
let start = @sqlite.page_header_start(1, db)
let page = @sqlite.parse_page_header(bytes, start)
```

## 记录头

SQLite 把一行存成一条记录：先是变长整数的头长度，再是每列的 serial type，随后是各列正文。

| 函数 | 说明 |
| --- | --- |
| read_varint(data, start) | 读取 1 到 9 字节的变长整数 |
| serial_kind / serial_byte_length | serial type 对应的类别与字节数 |
| parse_record_header(data) | 解析每列 serial type、头长度与正文起点 |

```moonbit
let header = @sqlite.parse_record_header(payload)
```

## 记录取值

解析记录头之后即可逐列取值：整数按大端补码还原，文本与二进制取出原始字节，空值为 kind 0。

| 函数 | 说明 |
| --- | --- |
| decode_record(payload) | 返回 Array[RecordValue]，kind 表示空值/整数/文本/二进制 |

```moonbit
match @sqlite.decode_record(payload) {
  Ok(values) => println(values.length())
  Err(msg) => println(msg)
}
```

浮点列暂未解码，遇到时返回明确错误而不是给出错误数值。

## 元数据

PMTiles 的元数据块按 gzip 压缩，读取时按 header 的偏移与长度截取后解压。

| 函数 | 说明 |
| --- | --- |
| metadata() | 返回元数据 JSON 的原始字节 |
| metadata_text() | 解码为 UTF-8 文本，非法编码返回错误 |

```moonbit
match file.metadata_text() {
  Ok(json) => println(json)
  Err(msg) => println(msg)
}
```

## 表页读取

叶子表页里每个单元是「记录正文长度 + 行号 + 记录正文」；读出单元即可拿到整行。

| 函数 | 说明 |
| --- | --- |
| read_leaf_table_cells(data, page_start, page_size) | 遍历叶子表页的全部单元 |
| cell_payload(data, cell) | 取出单元的记录正文副本 |
| parse_table_cell(...) | 解析单个单元，越界返回错误 |

```moonbit
let cells = @sqlite.read_leaf_table_cells(bytes, 100, 512)
```

## 表遍历

从根页递归遍历内部页与叶子页，读出整表；配合记录解析即可拿到每行每列。

| 函数 | 说明 |
| --- | --- |
| read_table_rows(data, db, root_page) | 返回每行的记录正文 |
| read_table_values(data, db, root_page) | 返回每行解析后的列值 |

```moonbit
let db = @sqlite.parse_db_header(bytes)
let rows = @sqlite.read_table_rows(bytes, db, 2)
```

## MBTiles

MBTiles 是 SQLite 数据库：schema 里记录两张表的根页号，元数据表存键值对，瓦片表存瓦片。

| 函数 | 说明 |
| --- | --- |
| Mbtiles::from_bytes(bytes) | 解析数据库并定位 metadata 与 tiles 根页 |
| metadata_pairs() | 读出全部元数据键值对 |
| metadata(key) | 按键取值，缺失返回 None |

```moonbit
match @mbtiles.Mbtiles::from_bytes(bytes) {
  Ok(file) => println(file.metadata_root())
  Err(msg) => println(msg)
}
```

## 取瓦片（MBTiles）

MBTiles 的行号是 TMS 约定（自南向北），换取时用 2^z - 1 - y 换算。

| 函数 | 说明 |
| --- | --- |
| tile(z, x, y) | 返回瓦片字节，缺失返回 None |
| tile_row_count() | 瓦片表行数 |

```moonbit
match file.tile(0, 0, 0) {
  Ok(found) => println(found)
  Err(msg) => println(msg)
}
```

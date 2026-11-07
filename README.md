# moontiles

纯 MoonBit 实现的地图瓦片容器工具集：读取 PMTiles v3 与 MBTiles 1.3，并提供访问 SQLite 存储所需的只读基础层。

## 解决的痛点

离线地图、无人机底图与 GIS 数据交付都依赖瓦片容器。MoonBit 生态已有矢量瓦片单张解析、GeoJSON/WKB 编解码与大地线计算，但缺少容器层：无法读取 PMTiles 单文件包，也无法从 MBTiles 的 SQLite 数据库里取出瓦片。

本库补齐这一层，全部为纯 MoonBit，无 FFI，走 wasm-gc、js、native 同一套代码。

## 已支持

| 能力 | 状态 | 说明 |
| --- | --- | --- |
| PMTiles v3 文件头 | 已完成 | 127 字节头部，字段与枚举校验 |
| PMTiles 目录 | 已完成 | 列式变长整数解码、run-length 展开、二分查找、叶目录 |
| PMTiles 取瓦片 | 已完成 | 按 z/x/y 定位，支持叶目录递归 |
| PMTiles 元数据 | 已完成 | gzip 解压后返回 JSON 字节或 UTF-8 文本 |
| 瓦片编号 | 已完成 | Hilbert tile_id，与参考实现逐项一致 |
| 瓦片坐标 | 已完成 | 经纬度与 z/x/y 互转、瓦片边界与中心 |
| SQLite 只读层 | 已完成 | 文件头、按页读取、B 树页头与单元、记录头与列值、表遍历 |
| MBTiles | 已完成 | 元数据键值对、按 z/x/y 取瓦片（自动处理 TMS 行号） |
| GeoPackage | 未实现 | 规划中，复用同一 SQLite 层 |

## 安装

```bash
moon add qqq66668/moontiles
```

## 快速开始

读 PMTiles：

```moonbit
let file = @pmtiles.PmtilesFile::from_bytes(bytes)
let header = file.header()
let tile = file.tile(12, 3372, 1552)
let meta = file.metadata_text()
```

读 MBTiles：

```moonbit
let db = @mbtiles.Mbtiles::from_bytes(bytes)
let format = db.metadata("format")
let tile = db.tile(0, 0, 0)
```

命令行示例内置一段真实结构的 PMTiles 数据，直接解析并打印摘要：

```bash
moon run cmd/moontiles --target wasm-gc
```

## 包结构

| 包 | 职责 |
| --- | --- |
| tilemath | 瓦片金字塔换算、经纬度与瓦片坐标互转、Hilbert tile_id |
| pmtiles | PMTiles v3 头部、目录、gzip、取瓦片、元数据 |
| sqlite | SQLite 只读层：文件头、页、B 树、记录、表遍历 |
| mbtiles | MBTiles 元数据与瓦片 |
| cmd/moontiles | 命令行示例 |

## 与参考实现对拍

- 瓦片编号：97 组 (z, x, y) 与参考实现 pmtiles 3.8.1 的 zxy_to_tileid 逐项一致。
- 目录解码：按规范编码的 fixture 交给参考实现解码，tile_id / offset / length / run_length 四列逐项一致。
- SQLite 与 MBTiles：fixture 由 Python 标准库 sqlite3 写出，文件头、页头、记录头与元数据键值对逐项断言。

## 测试

```bash
moon check --target wasm-gc --deny-warn
moon test --target wasm-gc
moon test --target js
```

当前 97 个用例，覆盖头部校验、目录解码、tile_id、取瓦片、gzip 错误、SQLite 页与记录、MBTiles 元数据与瓦片。

## 已知限制

- 只读：不写 PMTiles、MBTiles 或 SQLite 文件。
- 记录中浮点列尚未解码，遇到时返回明确错误而不是给出错误数值。
- 溢出页（记录正文跨页）暂不支持。
- 不做瓦片渲染、投影变换与矢量瓦片内容解码。

## 许可

Apache-2.0。

## 参考项目

- PMTiles 规范：https://github.com/protomaps/PMTiles/blob/main/spec/v3/spec.md
- MBTiles 1.3 规范：https://github.com/mapbox/mbtiles-spec/blob/master/1.3/spec.md
- SQLite 文件格式：https://www.sqlite.org/fileformat2.html
- gzip 解压复用 moonbit-community/flate（Apache-2.0），未在本库重复实现 DEFLATE。

本库按公开规范自行实现，未移植上述项目的源代码；参考实现仅用于测试期对拍。

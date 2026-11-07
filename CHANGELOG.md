# CHANGELOG

## 0.1.0

首个版本，只读。

- PMTiles v3：127 字节头部解析与校验、列式目录解码与 run-length 展开、二分查找与叶目录、按 z/x/y 取瓦片、gzip 元数据读取。
- 瓦片编号：Hilbert tile_id，97 组与参考实现 pmtiles 3.8.1 逐项一致。
- 瓦片坐标：经纬度与 z/x/y 互转、瓦片四角与中心。
- SQLite 只读层：文件头、按页读取、B 树页头与单元指针、记录头与列值（含浮点）、溢出页、表遍历。
- MBTiles 1.3：元数据键值对、按 z/x/y 取瓦片（自动处理 TMS 行号）。
- 命令行示例：`moon run cmd/moontiles` 解析内置样例并打印摘要。
- 工具：`tools/mutation_check.py` 对四处关键判据做变异验证。

未实现：GeoPackage、写入能力。

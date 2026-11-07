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

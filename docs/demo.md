# 演示视频

视频文件：[demo.mp4](demo.mp4)（37.7 秒，1280×720，30fps，约 0.3 MB）。

画面全部由真实命令输出渲染而成：`tools/render_demo.py` 先运行下列命令并捕获输出，再把输出逐行渲染成终端画面、用 ffmpeg 合成视频。没有摆拍，也没有手工编造的输出。

## 时间轴

| 时间 | 内容 | 命令 |
| --- | --- | --- |
| 0:00–0:03 | 开场：项目定位与已发布状态 | — |
| 0:03–0:18 | 读 PMTiles 与 MBTiles：头部、根目录、逐张取瓦片、元数据键值对 | `moon run cmd/moontiles --target wasm-gc` |
| 0:18–0:22 | 测试（wasm-gc 后端） | `moon test --target wasm-gc` |
| 0:22–0:26 | 测试（js 后端） | `moon test --target js` |
| 0:26–0:34 | 变异测试：把实现改错，确认测试变红 | `python tools/mutation_check.py` |
| 0:34–0:38 | 收尾：安装方式与仓库地址 | — |

## 每段在证明什么

1. **读容器**：`moontiles demo` 打印 PMTiles 的 spec 版本、缩放范围、根目录条目数与逐个瓦片长度；`moontiles mbtiles demo` 打印元数据键值对、format 值、瓦片行数与瓦片长度。两段样例都是真实结构的数据。
2. **双后端测试**：wasm-gc 与 js 各 101 个用例通过，说明实现没绑死某个后端。
3. **变异测试**：把 `tile_count`、魔数判断、BLOB 长度计算、溢出页拷贝长度分别改错，四处都会让测试变红，输出 `all 4 mutations were detected`。变异测试实际耗时约 4 分钟，视频里折叠展示输出。

## 复现

```bash
python tools/render_demo.py
```

依赖 Pillow 与 ffmpeg（默认使用工作区 `_ffmpeg` 下的构建，可用环境变量 `FFMPEG` 覆盖）。脚本会把采集到的命令输出写到 `_build/demo/capture.json`，帧序列写到 `_build/demo/frames/`，最终视频写到 `docs/demo.mp4`。

## 与仓库状态的一致性

视频里的用例数与仓库测试一致（101）；若后续测试数量变化，重新运行 `python tools/render_demo.py` 即可刷新视频，不要手工改数字。

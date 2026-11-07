#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""生成 demo 视频：真实运行命令、捕获输出、渲染终端画面、用 ffmpeg 合成。

用法：
    python tools/render_demo.py              # 采集 + 渲染 + 编码
    python tools/render_demo.py --capture-only

依赖：Pillow、ffmpeg（默认用工作区 _ffmpeg 下的构建，可用环境变量 FFMPEG 覆盖）。
产物：docs/demo.mp4（1280x720, 30fps）。
"""
import json
import os
import pathlib
import subprocess
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = pathlib.Path(__file__).resolve().parent.parent
WORK = ROOT / "_build" / "demo"
FRAMES = WORK / "frames"
OUT = ROOT / "docs" / "demo.mp4"
W, H = 1280, 720
FPS = 30
FONT_MONO = "C:/Windows/Fonts/consola.ttf"
FONT_CJK = "C:/Windows/Fonts/msyh.ttc"
FFMPEG = os.environ.get(
    "FFMPEG",
    "C:/Users/1510/Desktop/moon/_ffmpeg/_bin/imageio_ffmpeg/binaries/ffmpeg-win-x86_64-v7.1.exe",
)
NL = chr(10)


def sh(cmd, cwd, timeout=900):
    proc = subprocess.run(
        cmd,
        cwd=str(cwd),
        shell=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=timeout,
    )
    return proc.returncode, proc.stdout


def capture():
    steps = [
        ("1/4 读 PMTiles 与 MBTiles", "moon run cmd/moontiles --target wasm-gc", ROOT, False),
        ("2/4 测试（wasm-gc 后端）", "moon test --target wasm-gc", ROOT, False),
        ("3/4 测试（js 后端）", "moon test --target js", ROOT, False),
        ("4/4 变异测试：改错实现必须变红", "python tools/mutation_check.py", ROOT, True),
    ]
    segments = []
    for title, cmd, cwd, folded in steps:
        print("[capture] " + cmd, flush=True)
        code, out = sh(cmd, cwd)
        lines = [l.rstrip() for l in out.splitlines() if l.strip()]
        segments.append(
            {"title": title, "cmd": cmd, "code": code, "lines": lines, "folded": folded}
        )
        print("  exit=" + str(code) + " lines=" + str(len(lines)), flush=True)
    return segments


def base(title, f_title):
    img = Image.new("RGB", (W, H), (12, 12, 14))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, W, 46], fill=(32, 32, 38))
    d.ellipse([16, 16, 30, 30], fill=(255, 95, 86))
    d.ellipse([40, 16, 54, 30], fill=(255, 189, 46))
    d.ellipse([64, 16, 78, 30], fill=(39, 201, 63))
    d.text((96, 12), "moontiles demo  ·  " + title, font=f_title, fill=(220, 220, 226))
    return img, d


def wrap(text, font, width):
    out, cur = [], ""
    for ch in text:
        if font.getlength(cur + ch) > width:
            out.append(cur)
            cur = ch
        else:
            cur = cur + ch
    out.append(cur)
    return out


def build_frames(segments):
    FRAMES.mkdir(parents=True, exist_ok=True)
    for old in FRAMES.glob("*.png"):
        old.unlink()
    f_title = ImageFont.truetype(FONT_CJK, 28)
    f_big = ImageFont.truetype(FONT_CJK, 60)
    f_sub = ImageFont.truetype(FONT_CJK, 22)
    f_mono = ImageFont.truetype(FONT_MONO, 22)
    f_note = ImageFont.truetype(FONT_CJK, 18)
    frames = []

    img, d = base("开场", f_title)
    d.text((80, 200), "moontiles 0.1.0", font=f_big, fill=(255, 255, 255))
    d.text((80, 290), "纯 MoonBit 地图瓦片容器：PMTiles v3 / MBTiles 1.3 / SQLite 只读层", font=f_sub, fill=(160, 200, 255))
    d.text((80, 340), "已发布 mooncakes.io · Apache-2.0 · 101 个测试 · CI 含 native 与变异检查", font=f_sub, fill=(150, 150, 158))
    d.text((80, 460), "以下画面全部来自真实命令运行，无后期拼接", font=f_sub, fill=(120, 200, 140))
    for _ in range(90):
        frames.append(img.copy())

    for seg in segments:
        prompt = "PS> " + seg["cmd"]
        step = max(1, len(prompt) // 26)
        for i in range(0, len(prompt) + step, step):
            canvas, dc = base(seg["title"], f_title)
            dc.text((24, 66), prompt[:i], font=f_mono, fill=(140, 220, 160))
            frames.append(canvas)

        rendered = []
        if seg["folded"]:
            rendered.append(("（该步实测约 4 分钟，视频折叠展示输出）", (150, 150, 158), f_note))
        for line in seg["lines"][:18]:
            color = (210, 210, 216)
            low = line.lower()
            if ("passed" in low) or line.startswith("ok   ") or ("all 4 mutations" in low):
                color = (120, 220, 140)
            if seg["code"] != 0:
                color = (255, 140, 140)
            rendered.append(("  " + line, color, f_mono))

        shown = []
        for item in rendered:
            shown.append(item)
            canvas, dc = base(seg["title"], f_title)
            dc.text((24, 66), prompt, font=f_mono, fill=(140, 220, 160))
            yy = 104
            for text, color, font in shown:
                for piece in wrap(text, font, W - 60):
                    dc.text((24, yy), piece, font=font, fill=color)
                    yy = yy + 28
            frames.append(canvas)
            for _ in range(20):
                frames.append(canvas)
        for _ in range(70):
            frames.append(frames[-1])

    img, d = base("收尾", f_title)
    d.text((80, 230), "moon add qqq66668/moontiles", font=f_mono, fill=(140, 220, 160))
    d.text((80, 290), "https://github.com/qqq66668/moontiles", font=f_sub, fill=(160, 200, 255))
    d.text((80, 340), "Apache-2.0 · 101 tests · CI: check / build / test / native / mutation", font=f_sub, fill=(150, 150, 158))
    d.text((80, 400), "tools/render_demo.py 可复现本视频", font=f_note, fill=(120, 200, 140))
    for _ in range(120):
        frames.append(img.copy())

    for i, frame in enumerate(frames):
        frame.save(FRAMES / ("f" + str(i).zfill(5) + ".png"))
    return len(frames)


def encode(count):
    OUT.parent.mkdir(parents=True, exist_ok=True)
    cmd = [
        FFMPEG, "-y", "-loglevel", "error",
        "-framerate", str(FPS),
        "-i", str(FRAMES / "f%05d.png"),
        "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "23",
        "-movflags", "+faststart",
        str(OUT),
    ]
    subprocess.run(cmd, check=True)
    print("encoded " + str(OUT) + " frames=" + str(count) + " seconds=" + str(round(count / FPS, 1)))


def main():
    segments = capture()
    WORK.mkdir(parents=True, exist_ok=True)
    (WORK / "capture.json").write_text(json.dumps(segments, ensure_ascii=False, indent=2), encoding="utf-8")
    if "--capture-only" in sys.argv:
        print("capture only")
        return
    count = build_frames(segments)
    encode(count)


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""Generate Bingo Send's bilingual, monochrome SVG hero and social cards.

SVG files are self-contained vector illustrations, not product screenshots.
PNG export uses offline macOS WebKit and sips, without third-party dependencies.
Usage: python3 scripts/make-marketing-assets.py [marketing-output-directory]
"""
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets"
MARKETING = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else ROOT / "dist" / "marketing"


def hero(chinese=False):
    locale = "zh-CN" if chinese else "en"
    title = "Bingo Send — 说完 Bingo，自动发送。" if chinese else "Bingo Send — Say Bingo. Send it."
    description = ("流程示意：通过自己的输入法输入消息，句尾的 Bingo 触发发送；口令可保留，也可选择在发送前移除，此图展示移除口令的模式。macOS 13+，MIT 开源。" if chinese else
                   "Workflow illustration: use your own input method and finish a message with Bingo to send. Choose to keep the keyword or remove it before sending; keyword removal is shown here. Free and open source for macOS 13+, MIT licensed.")
    headline = ('''<text x="64" y="224" class="headline zh">说完 <tspan fill="#111111">Bingo</tspan>，</text>
  <text x="64" y="306" class="headline zh">自动发送。</text>''' if chinese else
                '''<text x="64" y="224" class="headline">Say <tspan fill="#111111">Bingo.</tspan></text>
  <text x="64" y="306" class="headline">Send it.</text>''')
    subtitle = "继续用你喜欢的输入法。" if chinese else "Keep your input method."
    mode = "流程示意" if chinese else "WORKFLOW ILLUSTRATION"
    first = "01  /  用自己的输入法" if chinese else "01  /  YOUR INPUT METHOD"
    second = "02  /  自动发送" if chinese else "02  /  SENT AUTOMATICALLY"
    input_message = "帮我检查这个页面。" if chinese else "Review this page."
    input_keyword = "Bingo。" if chinese else "Bingo."
    sent_mode = "示例：发送前移除口令" if chinese else "Keyword removal example"
    footnote = "口令可保留，也可在发送前移除。" if chinese else "Keep the keyword, or remove it before sending."
    metadata = "macOS 13+ · 免费开源 · MIT" if chinese else "macOS 13+ · Free &amp; open source · MIT"
    status = "句尾口令" if chinese else "FINAL KEYWORD"
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="640" viewBox="0 0 1280 640" role="img" aria-labelledby="title desc" xml:lang="{locale}">
  <title id="title">{title}</title>
  <desc id="desc">{description}</desc>
  <defs>
    <filter id="shadow" x="-20%" y="-30%" width="140%" height="170%"><feDropShadow dx="0" dy="9" stdDeviation="14" flood-color="#000000" flood-opacity="0.06"/></filter>
  </defs>
  <style>
    text {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Helvetica Neue', Arial, 'PingFang SC', 'Microsoft YaHei', sans-serif; }}
    .headline {{ fill:#171717; font-size:76px; font-weight:700; letter-spacing:-3px; }}
    .headline.zh {{ font-size:66px; letter-spacing:-2px; }}
    .label {{ fill:#626262; font-size:13px; font-weight:650; letter-spacing:1.25px; }}
    .message {{ fill:#303030; font-size:27px; font-weight:500; }}
  </style>
  <rect width="1280" height="640" fill="#FAFAFA"/>
  <path d="M643 114V534" stroke="#E1E1E1" stroke-width="1"/>
  <g transform="translate(64 44) scale(.0625)">
    <rect x="80" y="80" width="864" height="864" rx="192" fill="#111111"/>
    <path d="M248 504L778 260L586 778L472 586Z" fill="white"/>
    <path d="M472 586L778 260" fill="none" stroke="#111111" stroke-width="21" stroke-linecap="round"/>
  </g>
  <text x="142" y="87" fill="#171717" font-size="30" font-weight="650" letter-spacing="-.7">Bingo Send</text>
  <rect x="1099" y="59" width="117" height="27" rx="13.5" fill="#EAEAEA"/>
  <text x="1157.5" y="77.5" text-anchor="middle" fill="#4A4A4A" font-size="11" font-weight="650" letter-spacing=".7">OPEN SOURCE</text>
  {headline}
  <text x="66" y="366" fill="#676767" font-size="26" font-weight="400">{subtitle}</text>
  <g transform="translate(66 418)">
    <rect width="156" height="32" rx="16" fill="#EAEAEA"/>
    <circle cx="18" cy="16" r="4" fill="#111111"/>
    <text x="32" y="21" fill="#4F4F4F" font-size="12" font-weight="650" letter-spacing=".55">{status}</text>
    <rect x="164" width="88" height="32" rx="16" fill="#FFFFFF" stroke="#DADADA"/>
    <text x="208" y="22" text-anchor="middle" fill="#111111" font-size="17" font-weight="650">Bingo</text>
  </g>
  <text x="704" y="140" class="label">{mode}</text>
  <rect x="704" y="161" width="512" height="148" rx="20" fill="#FFFFFF" stroke="#E2E2E2" filter="url(#shadow)"/>
  <text x="729" y="194" class="label">{first}</text>
  <text x="729" y="238" class="message">{input_message}</text>
  <rect x="725" y="252" width="102" height="37" rx="9" fill="#EDEDED"/>
  <text x="735" y="279" fill="#111111" font-size="27" font-weight="650">{input_keyword}</text>
  <path d="M959 324V347M950 339L959 348L968 339" fill="none" stroke="#111111" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
  <rect x="704" y="366" width="512" height="148" rx="20" fill="#111111" filter="url(#shadow)"/>
  <text x="729" y="399" fill="#D6D6D6" font-size="13" font-weight="650" letter-spacing="1.15">{second}</text>
  <text x="729" y="443" fill="#FFFFFF" font-size="27" font-weight="500">{input_message}</text>
  <text x="729" y="484" fill="#D6D6D6" font-size="16" font-weight="400">{sent_mode}</text>
  <circle cx="1178" cy="400" r="12" fill="#FFFFFF" fill-opacity=".13"/>
  <path d="M1172 400L1176 404L1184 395" fill="none" stroke="#FFFFFF" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  <text x="704" y="545" fill="#6B6B6B" font-size="16">{footnote}</text>
  <text x="66" y="564" fill="#656565" font-size="17" font-weight="500">{metadata}</text>
  <text x="66" y="601" fill="#111111" font-size="20" font-weight="600" letter-spacing="-.2">github.com/yangyang2049/bingo-send</text>
</svg>
'''


def main():
    ASSETS.mkdir(parents=True, exist_ok=True)
    MARKETING.mkdir(parents=True, exist_ok=True)
    for chinese in (False, True):
        suffix = ".zh-CN" if chinese else ""
        lang = "zh-CN" if chinese else "en"
        svg = ASSETS / f"hero{suffix}.svg"
        svg.write_text(hero(chinese), encoding="utf-8")
        target = MARKETING / f"x-card-{lang}.png"
        subprocess.run(["swift", str(ROOT / "scripts" / "render-marketing-svg.swift"), str(svg), str(target)], check=True)
        # WebKit snapshots follow the display scale; normalize final exports.
        subprocess.run(["sips", "-z", "640", "1280", str(target)], check=True, stdout=subprocess.DEVNULL)
        shutil.copyfile(target, ASSETS / f"social-preview{suffix}.png")
        print(f"{svg.relative_to(ROOT)}; {target}; PNG {target.stat().st_size:,} bytes")


if __name__ == "__main__":
    main()

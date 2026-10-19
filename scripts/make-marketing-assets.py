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
    description = ("聊天流程示意：下方输入框含完整正文和句尾 Bingo，上方已发送消息不含最后的口令；可选择保留口令或发送前移除。macOS 13+，MIT 开源。" if chinese else
                   "Illustrated chat: the lower composer contains the message and final Bingo; the sent bubble above omits the final keyword. Choose to keep the keyword or remove it before sending. Free and open source for macOS 13+, MIT licensed.")
    headline = ('''<text x="64" y="224" class="headline zh">说完 Bingo，</text>
  <text x="64" y="306" class="headline zh">自动发送。</text>''' if chinese else
                '''<text x="64" y="224" class="headline">Say Bingo.</text>
  <text x="64" y="306" class="headline">Send it.</text>''')
    subtitle = "继续用你喜欢的输入法。" if chinese else "Keep your input method."
    input_message = "帮我检查这个页面。" if chinese else "Review this page."
    input_keyword = "Bingo。" if chinese else "Bingo."
    keyword_space = "" if chinese else " "
    sent_status = "已发送" if chinese else "Sent"
    footnote = "口令可保留，也可在发送前移除。" if chinese else "Keep the keyword, or remove it before sending."
    metadata = "macOS 13+ · 免费开源 · MIT" if chinese else "macOS 13+ · Free &amp; open source · MIT"
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="640" viewBox="0 0 1280 640" role="img" aria-labelledby="title desc" xml:lang="{locale}">
  <title id="title">{title}</title>
  <desc id="desc">{description}</desc>
  <style>
    text {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Helvetica Neue', Arial, 'PingFang SC', 'Microsoft YaHei', sans-serif; }}
    .headline {{ fill:#000000; font-size:76px; font-weight:700; letter-spacing:-3px; }}
    .headline.zh {{ font-size:66px; letter-spacing:-2px; }}
    .message {{ font-size:27px; font-weight:500; }}
  </style>
  <rect width="1280" height="640" fill="#FFFFFF"/>
  <g transform="translate(64 44) scale(.0625)">
    <rect x="80" y="80" width="864" height="864" rx="192" fill="#000000"/>
    <path d="M248 504L778 260L586 778L472 586Z" fill="#FFFFFF"/>
    <path d="M472 586L778 260" fill="none" stroke="#000000" stroke-width="21" stroke-linecap="round"/>
  </g>
  <text x="142" y="87" fill="#000000" font-size="30" font-weight="650" letter-spacing="-.7">Bingo Send</text>
  {headline}
  <text x="66" y="366" fill="#000000" font-size="26" font-weight="400">{subtitle}</text>
  <rect x="742" y="155" width="474" height="146" rx="24" fill="#000000"/>
  <text x="770" y="213" fill="#FFFFFF" class="message">{input_message}</text>
  <text x="1162" y="271" text-anchor="end" fill="#FFFFFF" font-size="14" font-weight="500">{sent_status}</text>
  <path d="M1177 265L1182 270L1191 259" fill="none" stroke="#FFFFFF" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M960 350V322M952 330L960 322L968 330" fill="none" stroke="#000000" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"/>
  <rect x="704" y="371" width="512" height="159" rx="28" fill="#FFFFFF" stroke="#000000" stroke-width="2"/>
  <text x="730" y="416" fill="#000000" class="message">{input_message}<tspan font-weight="650">{keyword_space}{input_keyword}</tspan></text>
  <path d="M733 482H749M741 474V490" fill="none" stroke="#000000" stroke-width="1.75" stroke-linecap="round"/>
  <circle cx="1170" cy="484" r="24" fill="#000000"/>
  <path d="M1170 494V474M1162 482L1170 474L1178 482" fill="none" stroke="#FFFFFF" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
  <text x="704" y="565" fill="#000000" font-size="16">{footnote}</text>
  <text x="66" y="564" fill="#000000" font-size="17" font-weight="500">{metadata}</text>
  <text x="66" y="601" fill="#000000" font-size="20" font-weight="600" letter-spacing="-.2">github.com/yangyang2049/bingo-send</text>
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

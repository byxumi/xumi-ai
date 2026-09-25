#!/usr/bin/env python3
"""把 Android applicationId 改为 com.xumitech.ai（用户要求的包名）。
只改 applicationId，namespace 保持 flutter create 生成的 com.xumitech.xumi_ai，
这样 MainActivity 的 Kotlin 路径/包声明无需改动；设备上显示应用包名即 com.xumitech.ai。"""
import pathlib
import sys

p = pathlib.Path('android/app/build.gradle.kts')
if not p.exists():
    print('ERROR: build.gradle.kts missing')
    sys.exit(1)
s = p.read_text(encoding='utf-8')

old = 'com.xumitech.xumi_ai'
new = 'com.xumitech.ai'

# 只替换 applicationId = "..." 那一处
if 'applicationId' in s:
    s = s.replace('applicationId = "%s"' % old, 'applicationId = "%s"' % new)
    print('applicationId ->', new)
else:
    # flutter 生成格式
    s = s.replace('applicationId "%s"' % old, 'applicationId "%s"' % new)
    print('applicationId ->', new)

p.write_text(s, encoding='utf-8')
print('package id patched OK')
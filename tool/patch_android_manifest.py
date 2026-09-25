#!/usr/bin/env python3
"""在 flutter create 生成的 AndroidManifest.xml 中注入必要配置，保持 XML 合法：
1. INTERNET 权限（插在 <manifest ...> 开标签之后）
2. usesCleartextTraffic（允许 http 源）
3. 应用名改为「须弥AI」
"""
import re
import pathlib
import sys

APP_LABEL = '须弥AI'

p = pathlib.Path('android/app/src/main/AndroidManifest.xml')
s = p.read_text(encoding='utf-8')

# 1. INTERNET 权限：插在 <manifest ...> 开标签的 > 之后（子元素，必须位于标签外）
perm = '<uses-permission android:name="android.permission.INTERNET"/>'
if perm not in s:
    m = re.search(r'<manifest\b[^>]*>', s)
    if not m:
        print('ERROR: 未找到 <manifest> 开标签'); sys.exit(1)
    s = s[:m.end()] + '\n    ' + perm + s[m.end():]
    print('INTERNET permission inserted')

# 2. cleartext：<application 标签内加属性
if 'usesCleartextTraffic' not in s:
    if '<application' in s:
        s = s.replace('<application', '<application\n        android:usesCleartextTraffic="true"', 1)
        print('usesCleartextTraffic inserted')

# 3. 应用名
if 'android:label="' in s:
    s = re.sub(r'android:label="[^"]*"', 'android:label="%s"' % APP_LABEL, s, count=1)
    print('label ->', APP_LABEL)

p.write_text(s, encoding='utf-8')
print('AndroidManifest patched OK')
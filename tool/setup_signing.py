#!/usr/bin/env python3
"""固定签名：每次构建用同一把 release 密钥，保证覆盖安装不报“签名不一致”。
在 build.gradle.kts 中创建/填充 release signingConfig，并把 release buildType 指向它。"""
import pathlib
import re
import shutil
import sys

KS_SRC = 'android-keys/release.jks'
KS_DST = 'android/app/release.jks'
STORE_PASS = 'xumitv2026'
KEY_ALIAS = 'xumi'
KEY_PASS = 'xumitv2026'

RELEASE_CONFIG = '''        create("release") {
            storeFile = file("release.jks")
            storePassword = "%s"
            keyAlias = "%s"
            keyPassword = "%s"
        }''' % (STORE_PASS, KEY_ALIAS, KEY_PASS)


def main():
    if pathlib.Path(KS_SRC).exists():
        shutil.copy(KS_SRC, KS_DST)
        print('keystore copied ->', KS_DST)
    else:
        print('WARN: keystore missing, abort')
        sys.exit(1)

    p = pathlib.Path('android/app/build.gradle.kts')
    if not p.exists():
        print('ERROR: build.gradle.kts missing')
        sys.exit(1)
    s = p.read_text(encoding='utf-8')

    # 1) 确保存在 create("release") 签名配置
    if 'create("release")' not in s:
        m = re.search(r'signingConfigs\s*\{', s)
        if m:
            s = s[:m.end()] + '\n' + RELEASE_CONFIG + s[m.end():]
            print('create("release") inserted into signingConfigs')
        else:
            m2 = re.search(r'buildTypes\s*\{', s)
            if not m2:
                print('ERROR: no signingConfigs/buildTypes found')
                sys.exit(1)
            block = '    signingConfigs {\n' + RELEASE_CONFIG + '\n    }\n\n'
            s = s[:m2.start()] + block + s[m2.start():]
            print('signingConfigs block created')
    elif 'storeFile = file("release.jks")' not in s:
        s = s.replace('create("release") {', RELEASE_CONFIG, 1)
        print('create("release") filled')

    # 2) release buildType 使用 release 签名
    s = s.replace('signingConfigs.getByName("debug")',
                  'signingConfigs.getByName("release")')
    print('release buildType -> release signing')

    p.write_text(s, encoding='utf-8')
    print('signing setup done')


if __name__ == '__main__':
    main()
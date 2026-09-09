#!/usr/bin/env python3
"""Create one local Android release signing identity; never overwrite an existing key."""
import os
from pathlib import Path
import secrets
import shutil
import subprocess

root = Path(__file__).resolve().parents[1]
key = root / 'android' / 'luma-release.jks'
properties = root / 'android' / 'key.properties'
if key.exists() or properties.exists():
    raise SystemExit('Signing files already exist. Keep them for future app updates; nothing was changed.')
keytool = shutil.which('keytool') or '/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool'
password = secrets.token_urlsafe(32)
env = os.environ.copy()
env['LUMA_SIGNING_PASSWORD'] = password
subprocess.run([keytool, '-genkeypair', '-v', '-keystore', str(key), '-storetype', 'JKS',
    '-keyalg', 'RSA', '-keysize', '2048', '-validity', '10000', '-alias', 'luma-release',
    '-dname', 'CN=Luma Ledger, OU=Mobile, O=Luma Ledger, C=ID',
    '-storepass:env', 'LUMA_SIGNING_PASSWORD', '-keypass:env', 'LUMA_SIGNING_PASSWORD'],
    env=env, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
properties.write_text(f'storePassword={password}\nkeyPassword={password}\nkeyAlias=luma-release\nstoreFile=../luma-release.jks\n')
key.chmod(0o600)
properties.chmod(0o600)
print('Created local release signing files. Back up android/luma-release.jks and android/key.properties privately. Never include them in a source archive.')

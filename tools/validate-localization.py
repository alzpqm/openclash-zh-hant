#!/usr/bin/env python3
"""Validate catalog coverage and every translation through LuCI's LMO reader."""
import ctypes
import json
import re
import struct
import subprocess
import tempfile
from pathlib import Path

import polib

ROOT = Path(__file__).resolve().parents[1]
PO = ROOT / 'luci-app-openclash/po/zh_Hant/openclash.zh_Hant.po'
SOURCES = ROOT / 'luci-app-openclash/tools/po2lmo/src'

def validate():
    catalog = polib.pofile(str(PO))
    assert len(catalog) == len({e.msgid for e in catalog}), 'Duplicate message IDs'
    assert all(e.msgstr and 'fuzzy' not in e.flags for e in catalog), 'Incomplete translations'
    upstream_text = (ROOT / 'luci-app-openclash/po/zh-cn/openclash.zh-cn.po').read_text()
    if upstream_text.startswith('"'):
        upstream_text = 'msgid ""\nmsgstr ""\n' + upstream_text
    upstream = polib.pofile(upstream_text)
    assert {e.msgid for e in upstream} <= {e.msgid for e in catalog}, 'Missing upstream translations'
    placeholders = re.compile(r'%(?:\d+\$)?[-+#0]*(?:\d+|\*)?(?:\.(?:\d+|\*))?[hlL]*[diouxXeEfFgGaAcsp]')
    for entry in catalog:
        assert sorted(placeholders.findall(entry.msgid)) == sorted(placeholders.findall(entry.msgstr)), f'Format mismatch: {entry.msgid}'

    with tempfile.TemporaryDirectory(prefix='openclash-lmo-') as tmp:
        work = Path(tmp)
        compiler = work / 'po2lmo'
        runtime = work / 'liblmo.so'
        subprocess.run(['cc', '-O2', '-I', str(SOURCES), '-o', str(compiler), str(SOURCES/'po2lmo.c'), str(SOURCES/'template_lmo.c')], check=True)
        subprocess.run(['cc', '-O2', '-fPIC', '-shared', '-I', str(SOURCES), '-o', str(runtime), str(SOURCES/'template_lmo.c')], check=True)
        lmo = work / 'openclash.zh-tw.lmo'
        subprocess.run([str(compiler), str(PO), str(lmo)], check=True)
        lib = ctypes.CDLL(str(runtime))
        lib.lmo_load_catalog.argtypes = [ctypes.c_char_p, ctypes.c_char_p]
        lib.lmo_change_catalog.argtypes = [ctypes.c_char_p]
        lib.lmo_translate.argtypes = [ctypes.c_char_p, ctypes.c_int, ctypes.POINTER(ctypes.c_void_p), ctypes.POINTER(ctypes.c_int)]
        assert lib.lmo_load_catalog(b'zh-tw', str(work).encode()) == 0
        assert lib.lmo_change_catalog(b'zh-tw') == 0
        hits = 0
        for entry in catalog:
            out, length = ctypes.c_void_p(), ctypes.c_int()
            key = entry.msgid.encode()
            result = lib.lmo_translate(key, len(key), ctypes.byref(out), ctypes.byref(length))
            actual = ctypes.string_at(out.value, length.value).decode() if result == 0 else entry.msgid
            assert re.sub(r'\s+', ' ', actual).strip() == re.sub(r'\s+', ' ', entry.msgstr).strip(), f'LMO lookup mismatch: {entry.msgid}'
            hits += result == 0
        data = lmo.read_bytes()
        offset = struct.unpack('>I', data[-4:])[0]
        index_count = (len(data) - offset - 4) // 16
        assert hits == index_count
        return {'catalog_messages': len(catalog), 'upstream_messages': len(upstream), 'lmo_index_entries': index_count, 'translation_lookups': hits, 'unchanged_text_fallbacks': len(catalog)-hits, 'placeholder_validation': 'passed'}

if __name__ == '__main__':
    print(json.dumps(validate(), ensure_ascii=False, indent=2))

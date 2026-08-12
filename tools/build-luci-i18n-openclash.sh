#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
OUTPUT_DIR=${1:-"$ROOT_DIR/dist"}
VERSION=$(sed -n 's/^PKG_VERSION:=//p' "$ROOT_DIR/luci-app-openclash/Makefile" | head -n 1)
RELEASE=$(sed -n 's/^PKG_RELEASE:=//p' "$ROOT_DIR/luci-i18n-openclash-zh-hant/Makefile" | head -n 1)
PACKAGE_NAME="luci-i18n-openclash-zh-hant_${VERSION}-${RELEASE}_all.ipk"
APK_PACKAGE_NAME="luci-i18n-openclash-zh-hant-${VERSION}-r${RELEASE}.apk"
APK_BIN=${APK_BIN:-}
FAKEROOT_BIN=${FAKEROOT_BIN:-}
WORK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/openclash-i18n.XXXXXX")

cleanup() {
	rm -rf "$WORK_DIR"
}
trap cleanup EXIT INT TERM

mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR/$APK_PACKAGE_NAME" "$OUTPUT_DIR/$APK_PACKAGE_NAME.sha256"

cc -I"$ROOT_DIR/luci-app-openclash/tools/po2lmo/src" \
	-o "$WORK_DIR/po2lmo" \
	"$ROOT_DIR/luci-app-openclash/tools/po2lmo/src/po2lmo.c" \
	"$ROOT_DIR/luci-app-openclash/tools/po2lmo/src/template_lmo.c"

mkdir -p "$WORK_DIR/control" \
	"$WORK_DIR/data/etc/uci-defaults" \
	"$WORK_DIR/data/lib/apk/packages" \
	"$WORK_DIR/data/usr/lib/lua/luci/i18n" \
	"$WORK_DIR/scripts"

if command -v xattr >/dev/null 2>&1; then
	xattr -rc "$WORK_DIR" 2>/dev/null || true
fi

"$WORK_DIR/po2lmo" \
	"$ROOT_DIR/luci-app-openclash/po/zh_Hant/openclash.zh_Hant.po" \
	"$WORK_DIR/data/usr/lib/lua/luci/i18n/openclash.zh-tw.lmo"

ln -s openclash.zh-tw.lmo \
	"$WORK_DIR/data/usr/lib/lua/luci/i18n/openclash.zh-hant.lmo"
ln -s openclash.zh-tw.lmo \
	"$WORK_DIR/data/usr/lib/lua/luci/i18n/openclash.zh_Hant.lmo"

cat > "$WORK_DIR/data/etc/uci-defaults/luci-i18n-openclash-zh-hant" <<'EOF'
uci set luci.languages.zh_tw='正體中文'; uci commit luci
EOF

(
	cd "$WORK_DIR/data"
	find etc usr -type f -o -type l | sed 's#^#/#' | sort
) > "$WORK_DIR/data/lib/apk/packages/luci-i18n-openclash-zh-hant.list"

cat > "$WORK_DIR/scripts/post-install" <<'EOF'
#!/bin/sh
[ "${IPKG_NO_SCRIPT}" = "1" ] && exit 0
[ -s "${IPKG_INSTROOT}/lib/functions.sh" ] || exit 0
. "${IPKG_INSTROOT}/lib/functions.sh"
export root="${IPKG_INSTROOT}"
export pkgname="luci-i18n-openclash-zh-hant"
add_group_and_user
default_postinst
EOF

cat > "$WORK_DIR/scripts/post-upgrade" <<'EOF'
#!/bin/sh
export PKG_UPGRADE=1
[ "${IPKG_NO_SCRIPT}" = "1" ] && exit 0
[ -s "${IPKG_INSTROOT}/lib/functions.sh" ] || exit 0
. "${IPKG_INSTROOT}/lib/functions.sh"
export root="${IPKG_INSTROOT}"
export pkgname="luci-i18n-openclash-zh-hant"
add_group_and_user
default_postinst
EOF

cat > "$WORK_DIR/scripts/pre-deinstall" <<'EOF'
#!/bin/sh
[ -s "${IPKG_INSTROOT}/lib/functions.sh" ] || exit 0
. "${IPKG_INSTROOT}/lib/functions.sh"
export root="${IPKG_INSTROOT}"
export pkgname="luci-i18n-openclash-zh-hant"
default_prerm
EOF

chmod 0755 "$WORK_DIR/scripts/post-install" \
	"$WORK_DIR/scripts/post-upgrade" \
	"$WORK_DIR/scripts/pre-deinstall"

cat > "$WORK_DIR/control/control" <<EOF
Package: luci-i18n-openclash-zh-hant
Version: ${VERSION}-${RELEASE}
Architecture: all
Section: luci
Priority: optional
Maintainer: OpenClash 正體中文化維護者
Depends: luci-app-openclash
Description: OpenClash LuCI 正體中文語言包（zh_Hant）
EOF

printf '2.0\n' > "$WORK_DIR/debian-binary"
cp "$WORK_DIR/scripts/post-install" "$WORK_DIR/control/postinst"
cp "$WORK_DIR/scripts/pre-deinstall" "$WORK_DIR/control/prerm"
chmod 0755 "$WORK_DIR/control/postinst" "$WORK_DIR/control/prerm"

COPYFILE_DISABLE=1 tar --no-xattrs --owner=root --group=root --numeric-owner \
	-czf "$WORK_DIR/control.tar.gz" -C "$WORK_DIR/control" .
COPYFILE_DISABLE=1 tar --no-xattrs --owner=root --group=root --numeric-owner \
	-czf "$WORK_DIR/data.tar.gz" -C "$WORK_DIR/data" .

python3 - "$OUTPUT_DIR/$PACKAGE_NAME" \
	"$WORK_DIR/debian-binary" \
	"$WORK_DIR/control.tar.gz" \
	"$WORK_DIR/data.tar.gz" <<'PY'
from pathlib import Path
import sys

output, *members = sys.argv[1:]
with open(output, 'wb') as archive:
    archive.write(b'!<arch>\n')
    for member in members:
        path = Path(member)
        data = path.read_bytes()
        name = path.name + '/'
        header = (
            f'{name:<16}'
            f'{0:<12}'
            f'{0:<6}'
            f'{0:<6}'
            f'{0o100644:<8o}'
            f'{len(data):<10}'
            '`\n'
        ).encode('ascii')
        archive.write(header)
        archive.write(data)
        if len(data) % 2:
            archive.write(b'\n')
PY

if [ -z "$APK_BIN" ]; then
	APK_BIN=$(command -v apk 2>/dev/null || true)
fi

if [ -z "$FAKEROOT_BIN" ] && [ -n "$APK_BIN" ]; then
	FAKEROOT_BIN=$(dirname "$APK_BIN")/fakeroot
	[ -x "$FAKEROOT_BIN" ] || FAKEROOT_BIN=""
fi

if [ -z "$FAKEROOT_BIN" ]; then
	FAKEROOT_BIN=$(command -v fakeroot 2>/dev/null || true)
fi

if [ -n "$APK_BIN" ] && [ -x "$APK_BIN" ] && [ -n "$FAKEROOT_BIN" ] && [ -x "$FAKEROOT_BIN" ]; then
	cat > "$WORK_DIR/mkpkg.sh" <<EOF
#!/bin/sh
exec "$APK_BIN" mkpkg \\
	--info 'name:luci-i18n-openclash-zh-hant' \\
	--info 'version:${VERSION}-r${RELEASE}' \\
	--info 'description:OpenClash LuCI 正體中文語言包（zh_Hant）' \\
	--info 'arch:noarch' \\
	--info 'license:MIT' \\
	--info 'origin:openclash-zh-hant' \\
	--info 'url:https://github.com/alzpqm/openclash-zh-hant' \\
	--info 'maintainer:OpenClash 正體中文化維護者' \\
	--info 'depends:luci-app-openclash' \\
	--info 'provides:luci-i18n-openclash-zh-hant-any' \\
	--info 'tags:openwrt:section=luci' \\
	--script 'post-install:$WORK_DIR/scripts/post-install' \\
	--script 'post-upgrade:$WORK_DIR/scripts/post-upgrade' \\
	--script 'pre-deinstall:$WORK_DIR/scripts/pre-deinstall' \\
	--no-xattrs \\
	--files '$WORK_DIR/data' \\
	--output '$OUTPUT_DIR/$APK_PACKAGE_NAME'
EOF
	chmod 0755 "$WORK_DIR/mkpkg.sh"
	"$FAKEROOT_BIN" "$WORK_DIR/mkpkg.sh"
else
	printf 'APK skipped: apk-tools v3 and fakeroot are required to build %s\n' "$APK_PACKAGE_NAME"
fi

write_checksum() {
	file=$1
	directory=$(dirname "$file")
	name=$(basename "$file")
	if command -v sha256sum >/dev/null 2>&1; then
		(cd "$directory" && sha256sum "$name") > "$file.sha256"
	else
		(cd "$directory" && shasum -a 256 "$name") > "$file.sha256"
	fi
}

write_checksum "$OUTPUT_DIR/$PACKAGE_NAME"
[ -f "$OUTPUT_DIR/$APK_PACKAGE_NAME" ] && write_checksum "$OUTPUT_DIR/$APK_PACKAGE_NAME"

printf 'Built %s\n' "$OUTPUT_DIR/$PACKAGE_NAME"
[ -f "$OUTPUT_DIR/$APK_PACKAGE_NAME" ] && printf 'Built %s\n' "$OUTPUT_DIR/$APK_PACKAGE_NAME"

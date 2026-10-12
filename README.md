<h1 align="center">
  <img src="https://raw.githubusercontent.com/vernesong/OpenClash/dev/img/logo.png" alt="Clash" width="200">
  <br>OpenClash 正體中文化版<br>
</h1>
  
<p align="center">
本外掛是一個可執行在 OpenWrt 上的<a href="https://github.com/MetaCubeX/mihomo" target="_blank"> Mihomo(Clash) </a>用戶端
</p>
<p align="center">
相容 Shadowsocks、ShadowsocksR、Vmess、Trojan、Snell 等通訊協定，依據彈性的規則設定實作策略代理
</p>

本專案是 OpenClash 的正體中文化版本，使用 OpenWrt LuCI 的 `zh_Hant` 語系，固定稱呼為「正體中文」，適用於中國大陸、臺灣、香港及澳門等使用正體中文介面的環境。

上游專案：[vernesong/OpenClash](https://github.com/vernesong/OpenClash)。本儲存庫為獨立發佈的正體中文化版本。

使用手冊
---


* [功能指南](https://github.com/alzpqm/openclash-zh-hant/blob/main/.github/skills/openclash-user-guide/SKILL.md)


下載連結
---


* 含正體中文的 OpenClash 主程式 IPK & APK [前往本儲存庫下載](https://github.com/alzpqm/openclash-zh-hant/releases)
* 上游 OpenClash 主程式 [前往上游下載](https://github.com/vernesong/OpenClash/releases)
* 正體中文語言包 IPK & APK [前往本儲存庫下載](https://github.com/alzpqm/openclash-zh-hant/releases)


正體中文語言包
---

目前版本為 **0.48.002-r1**，同步上游穩定版 [`v0.48.002`](https://github.com/vernesong/OpenClash/releases/tag/v0.48.002)（`e553e82e01c697aefbe1555261a503f425e00ccd`）。包含 2,017 則字串，涵蓋上游全部 1,812 則、153 則舊版相容字串，以及上游目錄遺漏的 52 個介面標籤。

請先安裝 OpenClash 主程式，再安裝語言包。本次發布也提供含正體中文的主程式 IPK／APK。所有下載都使用 HTTPS，安裝前必須通過 SHA-256 驗證。

APK 使用本次建置環境的**開發簽章**，不是 OpenWrt 官方或正式發布簽章。以下 APK 指令會先驗證公開金鑰的固定 SHA-256，再將它加入本機信任；只有選擇信任此開發金鑰時才執行。套件簽章驗證失敗會停止安裝。

```sh
# OpenClash 正體中文語言包：IPK
(
set -eu
work=$(mktemp -d /tmp/openclash-i18n.XXXXXX)
trap 'rm -rf "$work"' EXIT
base=https://github.com/alzpqm/openclash-zh-hant/releases/download/v0.48.002-zh-hant-r1
name=luci-i18n-openclash-zh-hant_0.48.002-1_all.ipk
curl -fL --retry 2 "$base/$name" -o "$work/$name"
curl -fL --retry 2 "$base/$name.sha256" -o "$work/$name.sha256"
(cd "$work" && sha256sum -c "$name.sha256")
opkg update
opkg install luci luci-base luci-compat
opkg install "$work/$name"
)
```

```sh
# OpenClash 正體中文語言包：APK（需明確信任本版開發金鑰）
(
set -eu
work=$(mktemp -d /tmp/openclash-i18n.XXXXXX)
trap 'rm -rf "$work"' EXIT
base=https://github.com/alzpqm/openclash-zh-hant/releases/download/v0.48.002-zh-hant-r1
name=luci-i18n-openclash-zh-hant-0.48.002-r1.apk
key=openclash-zh-hant-development-20261012.pem.pub
curl -fL --retry 2 "$base/$key" -o "$work/$key"
printf '3fb967dd68d972b041112af4502ec955a7f6b3d98e151bac35c4d2a04366900a  %s\n' "$key" > "$work/key.sha256"
(cd "$work" && sha256sum -c key.sha256)
curl -fL --retry 2 "$base/$name" -o "$work/$name"
curl -fL --retry 2 "$base/$name.sha256" -o "$work/$name.sha256"
(cd "$work" && sha256sum -c "$name.sha256")
mkdir -p /etc/apk/keys
cp "$work/$key" "/etc/apk/keys/$key"
apk verify "$work/$name"
apk update
apk add luci luci-base luci-compat
apk add --force-overwrite --clean-protected --no-chown "$work/$name"
)
```

安裝後，將 LuCI 語言切換為「正體中文」。套件使用 OpenWrt 標準語系 `zh_tw`（翻譯檔名 `zh-tw`），並保留 `zh-hant` 與 `zh_Hant` 相容別名；中國大陸、臺灣、香港及澳門均可使用。

* [語言包 IPK](https://github.com/alzpqm/openclash-zh-hant/releases/download/v0.48.002-zh-hant-r1/luci-i18n-openclash-zh-hant_0.48.002-1_all.ipk)
* [語言包 APK](https://github.com/alzpqm/openclash-zh-hant/releases/download/v0.48.002-zh-hant-r1/luci-i18n-openclash-zh-hant-0.48.002-r1.apk)
* [含正體中文的主程式 IPK](https://github.com/alzpqm/openclash-zh-hant/releases/download/v0.48.002-zh-hant-r1/luci-app-openclash_0.48.002-r1_all.ipk)
* [含正體中文的主程式 APK](https://github.com/alzpqm/openclash-zh-hant/releases/download/v0.48.002-zh-hant-r1/luci-app-openclash-0.48.002-r1.apk)

主程式 APK 也需要上方開發金鑰。內建 APK 更新流程要求可信簽章，遇到未簽署的上游套件會拒絕安裝；可改用已驗證的本專案發布檔案。

獨立封裝 APK 時必須提供簽章金鑰；SDK 的 fakeroot 也需要正確的 `STAGING_DIR_HOST`：

```sh
STAGING_DIR_HOST=/path/to/openwrt/staging_dir/host \
APK_BIN=/path/to/openwrt/staging_dir/host/bin/apk \
FAKEROOT_BIN=/path/to/openwrt/staging_dir/host/bin/fakeroot \
APK_SIGN_KEY=/path/to/development.pem \
tools/build-luci-i18n-openclash.sh
```

[建置與驗證紀錄](docs/BUILD.md) 說明 SDK、驗證範圍及可重建的工具環境。未在實體 OpenWrt 路由器上驗證；建置與封裝檢查不代表路由器執行測試。


相依套件
---

* luci
* luci-base
* dnsmasq-full
* bash
* curl
* ca-bundle
* ipset
* ip-full
* ruby
* ruby-yaml
* unzip
* iptables(iptables)
* kmod-ipt-nat(iptables)
* iptables-mod-tproxy(iptables)
* iptables-mod-extra(iptables)
* kmod-tun(TUN模式)
* luci-compat(Luci >= 19.07)
* ip6tables-mod-nat(iptables-ipv6)
* kmod-inet-diag(PROCESS-NAME)
* kmod-nft-tproxy(Firewall4)


編譯
---

本版使用 OpenWrt 25.12.5 x86-64 SDK（GCC 14.3.0／musl 1.2.5），固定官方映像：

```text
ghcr.io/openwrt/sdk@sha256:e916b7cc555890bdc4725c926e139b888294f0c8f56561b88d8da3a6348616a2
```

完整步驟見 [docs/BUILD.md](docs/BUILD.md)。可將 `luci-app-openclash` 與 `luci-i18n-openclash-zh-hant` 複製為 SDK 的相鄰套件目錄。建置會編譯正體中文 LMO，並保留上游的前端版本快取替換。原始碼已包含編譯完成的 CodeMirror 資源。


許可
---


* [MIT License](https://github.com/vernesong/OpenClash/blob/master/LICENSE)
* 核心 [Mihomo](https://github.com/MetaCubeX/mihomo) by [MetaCubeX](https://github.com/MetaCubeX)
* 本專案程式碼基於 [Luci For Clash](https://github.com/frainzy1477/luci-app-clash) by [frainzy1477](https://github.com/frainzy1477)
* IP檢查 [IP](https://ip.skk.moe/) by [SukkaW](https://ip.skk.moe/)
* 控制面板 [zashboard](https://github.com/Zephyruso/zashboard) by [Zephyruso](https://github.com/Zephyruso)
* 控制面板 [yacd](https://github.com/haishanh/yacd) by [haishanh](https://github.com/haishanh)
* 流媒體解鎖檢測 [RegionRestrictionCheck](https://github.com/lmc999/RegionRestrictionCheck) by [lmc999](https://github.com/lmc999)

請作者喝杯咖啡
---

* PayPal
<p align="left">
    <a href='https://ko-fi.com/H2H41G5LS' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://storage.ko-fi.com/cdn/kofi6.png?v=6' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>
</p>

* USDT-BSC
<p align="left">
    <img width="300" src="https://github.com/vernesong/OpenClash/raw/master/img/USDT-Wallet.png">
</p>

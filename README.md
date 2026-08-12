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

本專案是 OpenClash 的正體中文化版本，使用 OpenWrt LuCI 的 `zh_Hant` 語系，固定稱呼為「正體中文」，適用於臺灣、香港與澳門等使用正體中文介面的環境。

上游專案：[vernesong/OpenClash](https://github.com/vernesong/OpenClash)。本儲存庫為獨立發佈的正體中文化版本。

使用手冊
---


* [功能指南](https://github.com/alzpqm/openclash-zh-hant/blob/main/.github/skills/openclash-user-guide/SKILL.md)


下載連結
---


* OpenClash 主程式 IPK & APK [前往上游下載](https://github.com/vernesong/OpenClash/releases)
* 正體中文語言包 IPK & APK [前往本儲存庫下載](https://github.com/alzpqm/openclash-zh-hant/releases)


正體中文語言包
---

請先安裝 OpenClash 主程式，再依照路由器的套件格式，整段複製並貼上以下其中一組指令。指令會自動從本儲存庫的最新 Release 下載正確語言套件，避免手動輸入版本號或檔名造成安裝失敗。

Release 頁也提供同樣的完整安裝指令，方便直接從發布頁複製使用。

```sh
# [OpenClash 正體中文語言包 for ipk]
opkg update
opkg install luci luci-base luci-compat
curl -L --retry 2 https://api.github.com/repos/alzpqm/openclash-zh-hant/releases/latest -o /tmp/openclash_zh_hant_version
[ -f "/tmp/openclash_zh_hant_version" ] && download_url=$(cat /tmp/openclash_zh_hant_version | jsonfilter -e '@.assets[*].browser_download_url' | grep 'luci-i18n-openclash-zh-hant.*\.ipk$') && curl -L --retry 2 "$download_url" -o /tmp/openclash_zh_hant.ipk || echo "OpenClash 正體中文語言包 latest version get failed"
[ -f "/tmp/openclash_zh_hant.ipk" ] && opkg install /tmp/openclash_zh_hant.ipk || echo "OpenClash 正體中文語言包 download failed"
```

```sh
# [OpenClash 正體中文語言包 for apk]
apk update
apk add luci luci-base luci-compat
curl -L --retry 2 https://api.github.com/repos/alzpqm/openclash-zh-hant/releases/latest -o /tmp/openclash_zh_hant_version
[ -f "/tmp/openclash_zh_hant_version" ] && download_url=$(cat /tmp/openclash_zh_hant_version | jsonfilter -e '@.assets[*].browser_download_url' | grep 'luci-i18n-openclash-zh-hant.*\.apk$') && curl -L --retry 2 "$download_url" -o /tmp/openclash_zh_hant.apk || echo "OpenClash 正體中文語言包 latest version get failed"
[ -f "/tmp/openclash_zh_hant.apk" ] && apk add --force-overwrite --clean-protected --allow-untrusted --no-chown /tmp/openclash_zh_hant.apk || echo "OpenClash 正體中文語言包 download failed"
```

安裝後，將 LuCI 語言切換為「正體中文」。OpenWrt 標準語系識別為 `zh_tw`（翻譯檔為 `zh-tw`）；套件同時保留 `zh-hant` 與 `zh_Hant` 相容別名，臺灣、香港及澳門均可使用。

APK 為未簽署的本機安裝套件；若使用 OpenWrt 25.12 及更新版本，請保留 `--allow-untrusted`。也可以直接下載以下安裝檔：

* [下載 `luci-i18n-openclash-zh-hant_0.47.156-3_all.ipk`](https://github.com/alzpqm/openclash-zh-hant/releases/download/v0.47.156-zh-hant-r3/luci-i18n-openclash-zh-hant_0.47.156-3_all.ipk)
* [下載 `luci-i18n-openclash-zh-hant-0.47.156-r3.apk`](https://github.com/alzpqm/openclash-zh-hant/releases/download/v0.47.156-zh-hant-r3/luci-i18n-openclash-zh-hant-0.47.156-r3.apk)

重新產生封裝時，可使用 OpenWrt SDK 提供的 apk-tools v3：

```sh
APK_BIN=/path/to/openwrt/staging_dir/host/bin/apk tools/build-luci-i18n-openclash.sh
```


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


從 OpenWrt 的 [SDK](https://archive.openwrt.org/chaos_calmer/15.05.1/ar71xx/generic/OpenWrt-SDK-15.05.1-ar71xx-generic_gcc-4.8-linaro_uClibc-0.9.33.2.Linux-x86_64.tar.bz2) 編譯
```bash
# 解壓下載好的 SDK
curl -SLk --connect-timeout 30 --retry 2 "https://archive.openwrt.org/chaos_calmer/15.05.1/ar71xx/generic/OpenWrt-SDK-15.05.1-ar71xx-generic_gcc-4.8-linaro_uClibc-0.9.33.2.Linux-x86_64.tar.bz2" -o "/tmp/SDK.tar.bz2"
cd \tmp
tar xjf SDK.tar.bz2
cd OpenWrt-SDK-15.05.1-*

# Clone 專案
mkdir package/luci-app-openclash
cd package/luci-app-openclash
git init
git remote add -f origin https://github.com/vernesong/OpenClash.git
git config core.sparsecheckout true
echo "luci-app-openclash" >> .git/info/sparse-checkout
git pull --depth 1 origin master
git branch --set-upstream-to=origin/master master

# 編譯 po2lmo (如果有po2lmo可跳過)
pushd luci-app-openclash/tools/po2lmo
make && sudo make install
popd

# 編譯最新 CodeMirror 6 (外掛內建，可跳過)
pushd luci-app-openclash/tools/codemirror
npm install
npx esbuild entry.js --bundle --format=iife --global-name=CM6 --minify --target=es2019 --outfile=../../root/www/luci-static/resources/openclash/js/cm6.min.js --legal-comments=none --loader:.css=text
rm -rf node_modules
popd

# 開始編譯

# 先回退到SDK主目錄
cd ../..
make package/luci-app-openclash/luci-app-openclash/compile V=99

# IPK檔案位置
./bin/ar71xx/packages/base/luci-app-openclash_*-beta_all.ipk
```

```bash
# 同步原始碼
cd package/luci-app-openclash/luci-app-openclash
git pull

# 您也可以直接複製 `luci-app-openclash` 資料夾至其他 `OpenWrt` 專案的 `Package` 目錄下隨韌體編譯

make menuconfig
# 選擇要編譯的包 LuCI -> Applications -> luci-app-openclash

```


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

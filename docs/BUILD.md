# 0.48.002-r1 建置與驗證

本版同步 `vernesong/OpenClash` 的穩定版 `v0.48.002`，來源 SHA 為
`e553e82e01c697aefbe1555261a503f425e00ccd`。沒有使用開發分支 `0.48.003`。
原有正體中文翻譯及未變更的控制面板在地化保留；上游刪除或改寫的功能以穩定版實作為準。

翻譯目錄包含 2,017 則字串：1,812 則上游字串、153 則舊版相容字串、52 個上游目錄未收錄的介面標籤。
使用 OpenWrt 的 `zh_tw`／`zh-tw` 名稱，同時提供 `zh-hant`、`zh_Hant` 別名。

## 工具環境

外層為 Debian 13 x86_64，SDK 為 OpenWrt 25.12.5 x86-64，GCC 14.3.0／musl 1.2.5。
固定官方映像：

```text
ghcr.io/openwrt/sdk@sha256:e916b7cc555890bdc4725c926e139b888294f0c8f56561b88d8da3a6348616a2
```

SDK 自帶的 feed 固定於以下提交，未改用浮動分支：

| Feed | SHA |
| --- | --- |
| base | `f0a60eee2fe051741c643ea6118718aae1ef17fb` |
| packages | `5caa62e0bc9f7fb9b0c12a23267bceb7724214dd` |
| luci | `128a7812f4be233c5dd7f7466f534fd888785caf` |

驗證工具使用 Debian 13、Ruby 3.3、Lua 5.1、GNU gettext、Python、Node.js，以及本專案的 po2lmo 與 LMO 查詢函式。
Python 套件固定為 `polib==1.2.0`、`opencc-python-reimplemented==0.1.7`。

Release 的 `openclash-build-environment-0.48.002-r1.tar.gz` 包含重建與驗證腳本，沒有私鑰、憑證、SDK 映像或 Python 套件快取。
在新的受管理雲端環境中，先 clone 本儲存庫至 `/workspace/openclash-zh-hant`，checkout `v0.48.002-zh-hant-r1` 標籤，再驗證環境封存檔的 SHA-256 並解壓至 `/workspace/openclash-env`：

```sh
mkdir -p /workspace/openclash-env
tar -xzf openclash-build-environment-0.48.002-r1.tar.gz -C /workspace/openclash-env
bash /workspace/openclash-env/install.sh
source /workspace/openclash-env/activate.sh
bash /workspace/openclash-env/sdk-build.sh
python3 /workspace/openclash-env/validate.py
```

腳本使用本機 Docker socket、繼承的代理設定，以及 `CODEX_PROXY_CERT` 提供的代理 CA。
保持 HTTPS 憑證驗證；新容器以唯讀掛載取得 CA。環境初始化已連續執行兩次成功，並保留現有金鑰及容器。新環境會產生新的開發金鑰，因此重建產物的簽章與 checksum 不保證與本次 Release 相同。

## 建置方式

主程式與語言包是架構無關的 LuCI 套件。先完成 SDK 的固定 feed 與 `make defconfig`，再直接執行兩個套件的 SDK Makefile。
此方式建置套件本身，不會重新編譯韌體依賴的 Rust／LLVM 或原生核心。

```sh
export STAGING_DIR_HOST=/builder/staging_dir/host
export PATH="$STAGING_DIR_HOST/bin:$PATH"
make -C /builder/package/local/luci-app-openclash TOPDIR=/builder clean compile V=s
make -C /builder/package/local/luci-i18n-openclash-zh-hant TOPDIR=/builder clean compile V=s
```

重建腳本會在 SDK 的 APK 產生步驟加入 `--sign-key`，於封裝時直接簽章，然後使用公開金鑰驗證。
IPK 透過 SDK 的 `CONFIG_USE_APK=` 封裝流程產生；Release 語言包的 IPK／APK 另以 `tools/build-luci-i18n-openclash.sh` 獨立建置。
主程式的前端 `@OPENCLASH_VERSION@` 快取標記會替換為實際版本。

## 簽章及安裝

本版 APK 使用本地開發金鑰，不能視為正式發布簽章或 OpenWrt 官方信任。
公開金鑰檔名為 `openclash-zh-hant-development-20261012.pem.pub`，SHA-256：

```text
3fb967dd68d972b041112af4502ec955a7f6b3d98e151bac35c4d2a04366900a
```

只有選擇信任這個開發金鑰時，才依 README 的指令將公開金鑰加入 `/etc/apk/keys`。
主程式內建 APK 更新也要求可信簽章；未簽署的上游 APK 會被拒絕。
每個發布檔案皆附 SHA-256；私鑰留在建置工作區，不包含在儲存庫或 Release 中。

## 驗證範圍

- gettext 目錄完整性、格式參數，以及全部翻譯的 LuCI LMO 查詢：2,000 筆索引查詢，17 則與英文相同的字串使用原文回退。
- 25 個 Lua、2 個 Ruby、19 個前端 JavaScript 檔案的語法，以及 Shell 腳本語法。
- 專案 3 個 YAML 檔案的 Ruby 讀寫往返，另驗證正體中文節點名稱與帶前導零的 Reality short-id。這些純 YAML 測試關閉了可選的路由器 UCI／Age 設定。
- SDK 主程式及語言包、獨立語言包的 IPK／APK，檢查版本、架構、root 檔案擁有者、三種語系別名及 LMO 內容。
- APK 可信金鑰驗證成功；缺少可信金鑰與資料損毀時均拒絕套件。
- SDK 主程式封裝內的 220 個來源檔案逐一比對，僅允許前端版本標記的預期替換。

詳細機器可讀結果見 Release 的 `validation.json`。
未在實體 OpenWrt 路由器上測試服務啟動、DNS、防火牆、代理核心或 Age 加解密；本次沒有重新編譯韌體依賴或原生核心。

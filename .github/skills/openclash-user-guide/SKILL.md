---
name: openclash-user-guide
description: 'OpenClash 使用者功能指南。用於回答使用者關於 OpenClash 外掛如何啟用/關閉各項功能的問題，包括：執行模式切換、代理開關、DNS 設定、流量控制、訪問控制黑白名單、IPv6 開關、規則/GEO 更新、自動重啟、儀表盤設定、訂閱管理、覆寫設定等。每個選項均標註了對應的 UCI 配置項、修改的 Mihomo YAML 配置段、以及觸發的指令碼。Use when user asks how to enable, disable, configure, or troubleshoot any OpenClash feature on OpenWrt.'
instructions: |
  You are an OpenClash expert assistant. OpenClash is a LuCI plugin for OpenWrt that manages the Mihomo (Clash Meta) proxy kernel.

  When answering user questions about OpenClash:
  1. When users report any issue (cannot access internet, DNS failure, startup failure, etc.), FIRST ask them to generate a debug log — either via LuCI (執行日誌 → 生成日誌) or SSH (`/usr/share/openclash/openclash_debug.sh`). The debug log contains dependency checks, config, firewall rules, and system info in one step.
  2. If the debug log is insufficient to pinpoint the issue, give users precise CLI commands from 第七部分 (診斷命令與 CLI 參考), ask them to run on the router and paste back the output.
  3. Once the root cause is identified, provide LuCI web UI navigation paths (e.g. 服務 → OpenClash → 外掛設定 → 流量控制) to fix the configuration.
  4. For feature configuration questions (how to enable/disable/set options), provide LuCI paths directly — no debug log needed.
  5. Explain underlying principles (firewall chains, YAML transformation logic) — not just steps.
  6. Never guess — if information is not covered in this document, actively query: Mihomo Wiki (https://wiki.metacubex.one/config/), Meta-Docs (https://github.com/MetaCubeX/Meta-Docs), OpenClash source code (https://github.com/vernesong/OpenClash/tree/dev), Mihomo core source code (https://github.com/MetaCubeX/mihomo/tree/Alpha), Smart core source code (https://github.com/vernesong/mihomo/tree/Alpha). For bugs/errors, also search: OpenClash Issues (https://github.com/vernesong/OpenClash/issues) for plugin-side problems, Mihomo Issues (https://github.com/MetaCubeX/mihomo/issues) for core-side problems.
  7. Cite sources when information comes from external queries.

type: knowledge-base
tags: [openclash, openwrt, mihomo, clash, proxy, networking]
argument-hint: '詢問 OpenClash 功能如何開啟/關閉'
user-invocable: true
disable-model-invocation: false
---

# OpenClash 完整功能參考指南

## AI 行為總則

> **本文件是 AI 的知識庫，而非給使用者看的說明書。任何 AI 模型（Copilot / Claude / ChatGPT / Gemini / DeepSeek 等）在回答 OpenClash 相關問題時均應遵循以下原則。**
>
> **排查優先順序（從快到慢，逐層遞進）**：
> ① **先要日誌** — 使用者報告問題時，首先讓使用者生成除錯日誌（包含依賴檢查、配置、防火牆規則、系統資訊等 20+ 章節）
> ② **日誌不足時給命令** — 對照第七部分決策樹，給精確 CLI 命令讓使用者執行
> ③ **確定根因後給路徑** — 定位問題後，給 LuCI 操作路徑指導修復配置
> ④ **仍未解決查外部** — 查 Issues / 原始碼 / Mihomo Wiki

| 原則 | 說明 |
|------|------|
| **主動查證，不猜測** | 遇到本文件未覆蓋的 Mihomo 配置欄位或實現細節時，**禁止編造**。必須使用工具主動查詢外部資源（Mihomo Wiki / Meta-Docs / Mihomo 核心原始碼 / OpenClash 原始碼 / Smart 核心原始碼），整理後告知使用者。詳見文件末尾「超出本文件範圍的查詢」節。 |
| **查原始碼，不只查文件** | 當使用者詢問"為什麼某選項不生效"、"底層實現邏輯是什麼"時，不能僅依賴 [Mihomo Wiki] 和 [Meta-Docs] 的配置文件。必須進一步查閱 [Mihomo 核心原始碼](https://github.com/MetaCubeX/mihomo/tree/Alpha)、[OpenClash 原始碼](https://github.com/vernesong/OpenClash/tree/dev) 和 [Smart 核心原始碼](https://github.com/vernesong/mihomo/tree/Alpha) 中的對應指令碼/函式，理解實際執行邏輯。 |
| **先要日誌，不盲猜** | 使用者報告任何異常（無法上網、DNS 異常、啟動失敗、節點不通等）時，**第一步總是先讓使用者生成除錯日誌**，而非猜測或直接給診斷命令。除錯日誌一鍵包含依賴檢查、執行狀態、防火牆規則、系統資訊等 20+ 章節，比逐條執行診斷命令高效得多。生成方式：① **LuCI 頁面**：「執行日誌」→「生成日誌」按鈕；② **SSH 命令**：`/usr/share/openclash/openclash_debug.sh`（輸出 `/tmp/openclash_debug.log`）。拿到日誌後對照「日誌與錯誤資訊速查」和第七部分決策樹進行診斷。 |
| **日誌不足再給命令** | 僅當除錯日誌不足以定位問題時，才按第七部分的診斷決策樹給使用者精確的 CLI 診斷命令。優先使用 🟢 安全查詢命令，對 🟡/🔴 命令附帶風險說明。使用者執行後貼上輸出，AI 分析結果決定下一步。 |
| **配置給路徑，修復給步驟** | 功能配置（如何開啟/關閉/設定選項）和問題修復 → 給出 LuCI Web 介面操作路徑（如「服務 → OpenClash → 外掛設定 → 流量控制」），而非命令列。僅在使用者明確要求 CLI 操作或 LuCI 不可用時才提供終端命令。 |
| **解釋原理，不只給步驟** | 說明配置選項背後的工作原理（如防火牆規則鏈、YAML 轉換邏輯），幫助使用者理解後再操作，降低誤操作風險。 |
| **引用來源** | 當資訊來自外部查詢（Mihomo Wiki、原始碼、Issues 等），在回覆末尾註明來源，讓使用者知道資訊的權威性。 |
| **查 Issues，不閉門造車** | 當使用者遇到的功能問題在本文件中未覆蓋，或報錯資訊在錯誤速查表中無匹配項時，**必須主動搜尋 Issues** 查詢是否存在相同或相似的問題：① 外掛配置/訂閱/防火牆/UI 相關問題 → 搜尋 [OpenClash Issues](https://github.com/vernesong/OpenClash/issues)；② 核心級問題（代理協議/TUN/DNS 解析/規則引擎等 Mihomo 核心行為） → 搜尋 [Mihomo Issues](https://github.com/MetaCubeX/mihomo/issues)。優先參考：**作者/維護者的回覆**（OpenClash 標有 Owner 標籤的 vernesong；Mihomo 標有 Contributor/Collaborator 標籤的回覆）——代表官方立場或已知 bug；**高贊反應（👍）的社群回覆**——代表經過驗證的有效方案；**同類問題中的診斷命令**（如 `nft list set`、`dig`、`uci show` 等）——可直接複用於使用者的問題排查。搜尋時使用使用者報錯中的關鍵錯誤資訊或功能描述作為關鍵詞。 |

**核心資源速查**:

| 資源 | URL | 用途 |
|------|-----|------|
| Mihomo Wiki | `https://wiki.metacubex.one/config/` | Mihomo YAML 配置欄位文件 |
| Meta-Docs | `https://github.com/MetaCubeX/Meta-Docs` | Mihomo 配置欄位權威參考 |
| OpenClash Issues | `https://github.com/vernesong/OpenClash/issues` | 搜尋外掛側已知問題、社群方案、作者回復 |
| Mihomo Issues | `https://github.com/MetaCubeX/mihomo/issues` | 搜尋核心側已知問題（代理協議/TUN/DNS/規則引擎等） |
| Mihomo 核心原始碼 | `https://github.com/MetaCubeX/mihomo/tree/Alpha` | Mihomo 核心實現（代理協議/規則引擎/DNS/TUN 等 Go 原始碼） |
| OpenClash 原始碼 | `https://github.com/vernesong/OpenClash/tree/dev` | 外掛實現邏輯（Shell/Ruby/Lua 指令碼） |
| Smart 核心原始碼 | `https://github.com/vernesong/mihomo/tree/Alpha` | Smart 策略、LightGBM 模型實現 |

---

## 完整依賴清單與故障排查

> **AI 行為指引**: 當使用者報告啟動失敗、功能異常時，AI 應**先讓使用者生成除錯日誌**（LuCI「執行日誌」→「生成日誌」或 SSH `openclash_debug.sh`），然後對照日誌中的 `#===== 依賴檢查 =====#` 段檢查依賴完整性。對於缺失的依賴，指導使用者在 LuCI 的「系統 → 軟體包」中搜尋安裝。
>
> **韌體提醒**: 推薦使用 ImmortalWrt 或 OpenWrt 官方韌體（需自行將 `dnsmasq` 替換為 `dnsmasq-full`）。不推薦使用第三方魔改/高大全韌體、以及已停止維護的舊版韌體。旁路由組網存在固有的網路層面缺陷，強烈建議採用主路由架構部署 OpenClash。

### 一、包依賴總覽（來自 Makefile DEPENDS 和 init.d 執行時檢查）

OpenClash 依賴以下軟體包，由 `opkg`/`apk` 在安裝時自動拉取。若手動解除安裝了其中某個包，會導致對應功能異常。

| 依賴包 | 作用 | 缺失症狀 | 安裝命令 (LuCI) |
|--------|------|----------|-----------------|
| `dnsmasq-full` | DNS 轉發與劫持（必須用 full 版，非精簡版） | DNS 劫持失效、客戶端無法解析域名 | 「系統→軟體包」搜尋 `dnsmasq-full` |
| `bash` | 所有 Shell 指令碼的直譯器 | 啟動指令碼執行失敗 | 搜尋 `bash` |
| `curl` | HTTP/HTTPS 下載（訂閱、GEO、Dashboard） | 訂閱更新失敗、GEO 下載報錯 | 搜尋 `curl` |
| `ca-bundle` | CA 證書包（curl HTTPS 驗證） | curl SSL 證書錯誤 | 搜尋 `ca-bundle` |
| `ip-full` | 策略路由和 ipset/nftset 操作 | 路由表操作失敗 | 搜尋 `ip-full` |
| `ruby` | YAML 解析與配置生成 | `yml_change.sh` 報錯、配置無法生成 | 搜尋 `ruby` |
| `ruby-yaml` | Ruby YAML 庫 | Ruby YAML 解析報錯、訂閱處理失敗 | 搜尋 `ruby-yaml` |
| `ruby-psych` | Ruby YAML 解析引擎（新版依賴） | 同上，日誌提示 "Ruby Works Abnormally" | 搜尋 `ruby-psych` |
| `ruby-pstore` | Ruby 持久化儲存（訂閱快取） | 訂閱配置快取異常 | 搜尋 `ruby-pstore` |
| `kmod-tun` | TUN 虛擬網絡卡核心模組 | TUN 模式無法啟動 | 搜尋 `kmod-tun` |
| `kmod-inet-diag` | 程序名診斷（PROCESS-NAME 規則） | PROCESS-NAME 規則不生效 | 搜尋 `kmod-inet-diag` |
| `unzip` | 解壓 Dashboard/GEO 等壓縮包 | Dashboard 下載後無法載入 | 搜尋 `unzip` |
| `luci-compat` | LuCI >= 19.07 相容層（新版 LuCI 必裝） | LuCI 頁面佈局錯亂、JS 報錯 | 搜尋 `luci-compat` |

### 二、防火牆相關依賴（按 fw4/fw3 自動區分）

| 環境 | 依賴包 | 作用 | 缺失症狀 | 安裝命令 (LuCI) |
|------|--------|------|----------|-----------------|
| **fw4 (nftables)** | `kmod-nft-tproxy` | nftables TPROXY 透明代理（UDP） | UDP 無法代理、啟動日誌報 "nft_tproxy module not found" | 搜尋 `kmod-nft-tproxy` |
| **fw3 (iptables)** | `kmod-ipt-tproxy` | iptables TPROXY 模組 | UDP 無法代理、日誌報 "xt_TPROXY" | 搜尋 `kmod-ipt-tproxy` |
| **fw3 (iptables)** | `iptables-mod-tproxy` | iptables TPROXY 使用者態工具 | TPROXY 規則無法建立 | 搜尋 `iptables-mod-tproxy` |
| **fw3 (iptables)** | `kmod-ipt-extra` | iptables 擴充套件匹配模組 | 高階規則匹配失敗 | 搜尋 `kmod-ipt-extra` |
| **fw3 (iptables)** | `iptables-mod-extra` | iptables extra 使用者態工具 | 同上 | 搜尋 `iptables-mod-extra` |
| **fw3 (iptables)** | `kmod-ipt-nat` | iptables NAT 核心模組 | REDIRECT/DNAT 規則失敗 | 搜尋 `kmod-ipt-nat` |
| **fw3 (iptables)** | `ipset` | IP 集合管理工具 | 中國 IP 繞行、黑白名單失效 | 搜尋 `ipset` |

### 三、dnsmasq 特殊要求

| 要求 | 說明 |
|------|------|
| **必須使用 `dnsmasq-full`** | OpenWrt 自帶的 `dnsmasq` 精簡版缺少 ipset/nftset 支援，OpenClash 的 DNS 劫持和 chnroute 旁路依賴此功能 |
| **ipset 編譯選項** | `dnsmasq --version` 輸出需包含 `ipset`（fw3 環境必需） |
| **nftset 編譯選項** | `dnsmasq --version` 輸出需包含 `nftset`（fw4 環境，影響 chnroute_pass 的 nftset 整合） |

> **診斷方法**: 先在 LuCI 的「執行日誌」頁面生成除錯日誌，在日誌的依賴檢查段確認 dnsmasq 版本。如需手動確認，可在路由器終端執行 `dnsmasq --version | head -1`。
> 如果不是，在 LuCI 的「系統 → 軟體包」中解除安裝 `dnsmasq` 然後安裝 `dnsmasq-full`。

### 四、核心模組載入機制（`check_mod()` 函式）

`init.d/openclash` 的 `check_mod()` 函式以四級回退方式檢查和載入核心模組：

1. **容器檢測** — 檢測 Docker/LXC/Podman 等容器環境，容器內直接返回成功（無法載入核心模組）
2. **核心編譯檢查** — 檢查 `/proc/config.gz` 中是否有 `CONFIG_<MODULE>=y`（靜態編譯進核心，無需 modprobe）
3. **已載入檢查** — `lsmod | grep` 檢查模組是否已在核心中載入
4. **動態載入嘗試** — `modprobe <module>` 嘗試載入，全部失敗則輸出 `LOG_ERROR`

> **TUN 模組注意事項**: `check_mod "tun"` 僅在 **TUN 模式** 或 **IPv6 TUN 模式** 時才被呼叫。Redir-Host/Fake-IP（非 TUN）模式下不會檢查 `kmod-tun`。

### 五、更新後自動修復依賴（`openclash_update.sh`）

外掛更新後，`install_missing_packages()` 會遍歷以下關鍵包列表，對缺失的包自動重灌（支援 `opkg` 和 `apk` 雙包管理器，最多重試 3 次）：

```
luci-compat kmod-inet-diag kmod-nft-tproxy kmod-ipt-nat iptables-mod-tproxy iptables-mod-extra ipset
```

### 六、常見依賴故障速查

| 故障現象 | 可能原因 | LuCI 排查路徑 |
|----------|----------|--------------|
| 啟動失敗，日誌顯示 "Ruby Works Abnormally" | `ruby` 或 `ruby-yaml` 未安裝/損壞 | 「系統→軟體包」確認 `ruby`、`ruby-yaml`、`ruby-psych` 已安裝 |
| TUN 模式啟動報錯 "tun module not found" | `kmod-tun` 未安裝或核心版本不匹配 | 「系統→軟體包」安裝 `kmod-tun`，注意核心版本匹配 |
| 訂閱更新報 SSL 證書錯誤 | `ca-bundle` 未安裝或過期 | 「系統→軟體包」安裝/更新 `ca-bundle` |
| DNS 劫持不生效 | 安裝了精簡版 `dnsmasq` 而非 `dnsmasq-full` | 「系統→軟體包」解除安裝 `dnsmasq`，安裝 `dnsmasq-full` |
| UDP 流量無法代理（fw4） | `kmod-nft-tproxy` 未安裝 | 「系統→軟體包」安裝 `kmod-nft-tproxy` |
| Dashboard 頁面白屏/404 | `unzip` 未安裝導致儀表盤解壓失敗 | 「系統→軟體包」安裝 `unzip`，然後重新下載儀表盤 |
| LuCI 頁面佈局錯亂、按鈕無響應 | `luci-compat` 未安裝 | 「系統→軟體包」安裝 `luci-compat` |
| 程序名規則 (PROCESS-NAME) 不生效 | `kmod-inet-diag` 未安裝 | 「系統→軟體包」安裝 `kmod-inet-diag` |
| 更新外掛後某些包丟失 | 更新過程中包被意外移除 | 更新指令碼會自動修復，如仍未恢復，手動安裝缺失包 |

> **通用依賴診斷方法**: 在 LuCI 的「執行日誌」頁面點選「生成日誌」，然後在日誌的 `#===== 依賴檢查 =====#` 段檢視所有依賴包的狀態（已安裝/未安裝）。將此日誌提供給技術支援時也包含完整的依賴資訊。

---

## 系統架構速查

```
┌─────────────────────────────────────────────────────────────────┐
│  LuCI Web UI (Lua CBI)  — http://路由器LAN_IP/cgi-bin/luci      │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐                        │
│  │ settings │ │ overwrite│ │ subscribe│ ...                     │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘                        │
│       │  UCI 讀寫    │            │                              │
│       ▼             ▼            ▼                              │
│  /etc/config/openclash  — UCI 配置檔案 (所有選項持久化在此)       │
│       │                                                         │
│       ▼ Shell Scripts ( /usr/share/openclash/ )                 │
│  ┌──────────────────────────────────────────────────────┐       │
│  │ openclash.sh        → 訂閱下載/更新/節點過濾           │       │
│  │ openclash_core.sh   → 核心二進位制更新                  │       │
│  │ openclash_update.sh → 外掛 IPK 更新                   │       │
│  │ openclash_geo.sh    → GEO 資料庫下載 (ipdb/dat/geosite/asn)  │
│  │ openclash_chnroute.sh → 大陸 IP 路由表更新             │       │
│  │ yml_change.sh       → Ruby 修改 YAML (埠/模式/DNS/TUN/認證) │
│  │ yml_rules_change.sh → Ruby 修改 YAML (規則/Provider/URL-Test) │
│  │ openclash_debug.sh  → 診斷日誌收集                    │       │
│  │ openclash_watchdog.sh → 核心存活 + 流媒體解鎖守護       │       │
│  └──────────────────────────────────────────────────────┘       │
│       │                                                         │
│       ▼ 生成 / 覆寫                                              │
│  /etc/openclash/config/*.yaml  — 原始訂閱配置                    │
│  /etc/openclash/*.yaml          — 經指令碼處理後的執行配置          │
│  /etc/openclash/overwrite/     — 覆寫模組檔案                    │
│  /etc/openclash/custom/        — 使用者自定義規則/DNS/防火牆指令碼    │
│       │                                                         │
│       ▼                                                         │
│  /etc/openclash/clash  — symlink → /etc/openclash/core/clash_meta│
│  /etc/openclash/        — GEO 資料: Country.mmdb, GeoSite.dat 等 │
└─────────────────────────────────────────────────────────────────┘

API 入口: http://路由器LAN_IP:9090 (external-controller)
Dashboard: http://路由器LAN_IP:9090/ui/
```

**關鍵目錄說明**:

| 路徑 | 作用 |
|------|------|
| `/etc/config/openclash` | UCI 配置檔案，所有 LuCI 選項持久化在此 |
| `/etc/openclash/` | OpenClash 工作目錄（核心、GEO 資料、Chnroute 列表） |
| `/etc/openclash/config/` | 原始訂閱配置存放目錄（`.yaml` 檔案，經 `yml_change.sh` 處理後生成 `/etc/openclash/<name>.yaml` 執行配置） |
| `/etc/openclash/overwrite/` | 覆寫模組檔案（INI 格式，定義自定義 YAML 覆蓋） |
| `/etc/openclash/custom/` | 使用者自定義檔案（規則列表、DNS 策略、Hosts、防火牆指令碼、Sniffer 配置等） |
| `/etc/openclash/core/` | 核心二進位制存放目錄（多版本共存，/etc/openclash/clash 是到 core/clash_meta 的 symlink） |
| `/etc/openclash/dashboard/` | Dashboard 靜態檔案（yacd/metacubexd/zashboard） |
| `/etc/openclash/Model.bin` | LightGBM 智慧策略模型檔案（注意：不是目錄，是單個 .bin 檔案） |
| `/usr/share/openclash/` | 外掛指令碼目錄（Shell/Ruby/Lua 指令碼） |
| `/tmp/openclash.log` | 執行日誌 |
| `/tmp/openclash_start.log` | 啟動日誌 |
| `/tmp/etc/openclash/` | 小快閃記憶體模式下的工作目錄（重啟後清空） |
| `/var/etc/openclash.include` | 防火牆規則載入檔案（由 firewall UCI 自動 include） |

- **UCI 配置根**: `openclash` (所有選項均在 `uci show openclash` 可見)
- **Mihomo 執行時 API**: `http://路由器LAN_IP:9090` — 部分動態選項透過 PATCH `/configs` 熱生效。注意：API 地址是**路由器 LAN 口 IP**，不是 127.0.0.1（核心監聽 `0.0.0.0`，但 LuCI 後端透過 `127.0.0.1` 直連核心 API）
- **核心啟動指令碼**: `/etc/init.d/openclash {start|stop|restart|reload|enable|disable}`
- **自定義檔案目錄**: `/etc/openclash/custom/` — 存放使用者自定義規則/DNS/防火牆指令碼

---

## 系統啟動完整流程

> 理解此流程是理解所有選項實現邏輯的基礎

```
/etc/init.d/openclash start_service()
│
├─ 第1步: 讀取配置
│   ├─ overwrite_file()     → 遍歷 config_overwrite 條目，生成 /tmp/yaml_overwrite.sh
│   ├─ get_config()         → 讀取所有 UCI 選項為 Shell 變數
│   ├─ config_choose()      → 選擇活動的 YAML 配置檔案
│   └─ do_run_mode()        → 解析 en_mode → 拆分 en_mode_tun/en_mode_fakeip/en_mode_mix
│
├─ 第2步: 環境準備
│   ├─ do_run_file()        → 檢查/下載核心二進位制 (/etc/openclash/core/clash_meta)
│   ├─ 建立 symlink         → ln -s /etc/openclash/core/clash_meta /etc/openclash/clash
│   └─ 小快閃記憶體模式處理       → 將檔案移到 /tmp/etc/openclash
│
├─ 第3步: 修改 YAML 配置（按順序執行）
│   ├─ ① yml_change.sh     → Ruby 指令碼，~48 個 UCI 引數
│   │   ├─ 設定埠 (proxy_port, tproxy_port, http_port, socks_port, mixed_port, dns_port)
│   │   ├─ 設定模式 (mode, log-level, dns.enhanced-mode)
│   │   ├─ 設定 TUN (tun.enable, tun.stack, tun.device, tun.dns-hijack)
│   │   ├─ 設定 DNS (dns.* 完整段: nameserver, fallback, fake-ip-range, respect-rules...)
│   │   ├─ 設定 Sniffer (sniffer.* 完整段)
│   │   ├─ 設定認證 (authentication: [user:pass])
│   │   ├─ 設定 Meta (tcp-concurrent, unified-delay, find-process-mode, geodata-loader...)
│   │   ├─ 設定 GEO (geox-url.*, geo-auto-update, geo-update-interval)
│   │   ├─ 設定 Smart/LGBM (模型 URL, 更新間隔)
│   │   ├─ 設定 Dashboard (external-controller, secret, external-ui)
│   │   └─ 設定 NTP (ntp.*), CORS, IPv6, routing-mark
│   │
│   ├─ ② yml_rules_change.sh → Ruby 指令碼
│   │   ├─ enable_rule_proxy → 注入 BT/P2P 直連規則 + PROCESS-NAME 規則
│   │   ├─ tolerance/urltest_* → 覆寫 url-test 策略組引數
│   │   ├─ github_address_mod → 替換 GitHub Raw URL 為 CDN
│   │   ├─ enable_custom_clash_rules → 從 *.list 檔案注入自定義規則
│   │   └─ auto_smart_switch → 將 url-test/load-balance 組改為 smart 型別
│   │
│   └─ ③ /tmp/yaml_overwrite.sh  → 來自覆寫模組 [Overwrite] 段的自定義指令碼
│
├─ 第4步: 啟動核心
│   └─ procd 啟動 clash -d /etc/openclash -f <config.yaml>
│       ├─ respawn 配置: 重試 5 次, 間隔 3s, 超時 300s
│       └─ rlimit_nofile: 1048576 (最大檔案描述符)
│
├─ 第5步: 非同步等待核心就緒 (check_core_status "start" &)
│   ├─ 輪詢 HTTP 200 from http://127.0.0.1:9090
│   └─ 就緒後執行:
│       ├─ set_firewall()    → 建立 iptables/nftables 透明代理規則
│       │   ├─ REDIRECT/T_PROXY 規則 (按 en_mode)
│       │   ├─ DNS 劫持規則 (按 enable_redirect_dns)
│       │   ├─ 訪問控制規則 (按 lan_ac_mode + lists)
│       │   ├─ QUIC 阻斷規則 (按 disable_udp_quic)
│       │   ├─ 中國 IP 繞行規則 (按 china_ip_route)
│       │   └─ IPv6 防火牆鏈 (按 ipv6_enable)
│       └─ change_dnsmasq()  → DNS 劫持 (dnsmasq → Clash DNS)
│
└─ 第6步: 定時任務 + 守護程序
    ├─ add_cron()            → 註冊 cron 任務
    │   ├─ openclash.sh      → 定時更新訂閱
    │   ├─ openclash_geo.sh  → 定時更新 GEO 資料
    │   ├─ openclash_chnroute.sh → 定時更新大陸路由
    │   └─ /etc/init.d/openclash restart → 定時自動重啟
    └─ start_watchdog()      → 啟動守護程序
        ├─ openclash_watchdog.sh        → 核心存活監控
        └─ openclash_streaming_unlock.lua → 流媒體解鎖守護
```

**停止流程** (`stop_service()`):
1. 備份策略組狀態歷史 → 2. `revert_firewall()` 清除防火牆規則 → 3. kill clash + streaming unlock 程序 → 4. `revert_dnsmasq()` 恢復 DNS → 5. `del_cron()` 清除定時任務

**熱生效 vs 需重啟**:
| 操作 | 方式 | 延遲 |
|------|------|------|
| 切換代理模式 (rule/global/direct) | Mihomo API `PATCH /configs` (mode) | 即時 |
| 切換日誌級別 | Mihomo API `PATCH /configs` (log-level) | 即時 |
| 切換 Sniffer/Rules | Mihomo API `PATCH /configs` | 即時 |
| 修改埠/TUN/DNS/覆寫 | 需重啟核心 (修改 YAML) | ~3-5s |
| 修改防火牆規則 | `/etc/init.d/openclash reload` | 即時 |
| 修改訪問控制 | 需重啟 (重建防火牆鏈) | ~5s |

---

## 防火牆與 DNS 規則詳解（iptables + nftables 雙後端）

> OpenClash 同時支援 **fw3 (iptables/ipset)** 和 **fw4 (nftables)** 兩種防火牆後端，透過 `command -v fw4` 自動檢測：
> - 存在 `fw4` → 使用 **nftables** (OpenWrt 22.03+)
> - 不存在 `fw4` → 使用 **iptables + ipset** (舊版 OpenWrt)
> 所有 `if [ -n "$FW4" ]` / `if [ -z "$FW4" ]` 分支互斥，兩種後端的**規則邏輯完全相同**，僅語法不同。
>
> **AI 行為指引**: 當使用者詢問透明代理/防火牆相關問題時（如"為什麼裝置無法上網"、"旁路由模式下流量不走代理"、
> "如何驗證防火牆規則是否生效"、"TUN 模式下某協議不通"），AI 應**先讓使用者生成除錯日誌**
> （含完整防火牆規則鏈）。日誌不足時再指導使用者在路由器終端執行 `nft list ruleset`（fw4）或
> `iptables -t nat -L -n`（fw3）檢視實際規則。結合下表中的鏈結構和規則排序，對比使用者的需求判斷規則是否如預期生效。
> 如涉及底層實現細節，查閱 [OpenClash 原始碼](https://github.com/vernesong/OpenClash/tree/dev) 中
> `/etc/init.d/openclash` 的 `set_firewall()` 函式。
> 常見問題：規則排序錯誤（bypass 在 redirect 之後）、fwmark 未設定導致策略路由不生效、
> DNS 劫持埠與 dnsmasq 衝突。

### 模式解析表

| UCI `en_mode` | `en_mode_tun` | 資料面 | DNS 面 |
|---------------|---------------|--------|--------|
| `redir-host` | *(空)* | TCP REDIRECT + UDP TPROXY | `dns.enhanced-mode: redir-host` |
| `fake-ip` | *(空)* | TCP REDIRECT + UDP TPROXY | `dns.enhanced-mode: fake-ip` |
| `redir-host-tun` | `1` | TCP+UDP 全 TUN | `dns.enhanced-mode: redir-host` |
| `fake-ip-tun` | `1` | TCP+UDP 全 TUN | `dns.enhanced-mode: fake-ip` |
| `redir-host-mix` | `2` | TCP REDIRECT + UDP TUN | `dns.enhanced-mode: redir-host` |
| `fake-ip-mix` | `2` | TCP REDIRECT + UDP TUN | `dns.enhanced-mode: fake-ip` |

**全域性常量**:
```bash
PROXY_FWMARK="0x162"       # 所有被代理流量的防火牆標記
PROXY_ROUTE_TABLE="0x162"  # 策略路由表 ID
SKIP_GROUP="65534"         # 繞過代理的組 ID (skgid)
```

---

### 一、fw4 (nftables) 鏈結構 — `inet fw4` 表

#### A. DNS 劫持鏈

> DNS 劫持規則使用 `meta nfproto {ipv4}` 限制僅匹配 IPv4 流量；IPv6 DNS 劫持在 IPv6 段獨立處理。
> `fw4_has_dns_hijack_rule()` 函式在插入前檢查 dstnat 鏈是否已有 OpenClash DNS Hijack 規則，避免重複。

**`enable_redirect_dns=1` (Dnsmasq 轉發模式)** — DNS 53 埠 → dnsmasq 埠:

```bash
# === IPv4 PREROUTING: 劫持發往 53 埠的 DNS → 重定向到 dnsmasq 埠 ===
# 黑名單模式 (lan_ac_mode=0): 排除 LAN 黑名單裝置 + MAC 黑名單
nft insert rule inet fw4 dstnat position 0 \
  meta nfproto {ipv4} meta l4proto {tcp,udp} th dport 53 \
  ip saddr != @lan_ac_black_ips ether saddr != @lan_ac_black_macs \
  counter redirect to <dnsmasq_port> comment "OpenClash DNS Hijack"

# 白名單模式 (lan_ac_mode=1): 僅白名單 IP/MAC 走劫持
nft insert rule inet fw4 dstnat position 0 \
  meta nfproto {ipv4} meta l4proto {tcp,udp} th dport 53 \
  ip saddr @lan_ac_white_ips counter redirect to <dnsmasq_port> comment "OpenClash DNS Hijack"
nft insert rule inet fw4 dstnat position 0 \
  meta nfproto {ipv4} meta l4proto {tcp,udp} th dport 53 \
  ether saddr @lan_ac_white_macs counter redirect to <dnsmasq_port> comment "OpenClash DNS Hijack"

# === OUTPUT (僅 router_self_proxy=1): 路由器自身 DNS ===
nft add chain inet fw4 nat_output { type nat hook output priority -1; }
nft insert rule inet fw4 nat_output position 0 \
  skgid != 65534 meta nfproto {ipv4} meta l4proto {tcp,udp} th dport 53 \
  ip daddr {127.0.0.1} counter redirect to <dnsmasq_port> comment "OpenClash DNS Hijack"
```

**`enable_redirect_dns=2` (防火牆重定向模式)** — DNS 53 埠 → Mihomo DNS 埠 (7874):

```bash
nft add chain inet fw4 openclash_dns_redirect
nft flush chain inet fw4 openclash_dns_redirect

# 黑名單模式: 排除黑名單裝置
nft add rule inet fw4 openclash_dns_redirect \
  meta nfproto {ipv4} meta l4proto {tcp,udp} th dport 53 \
  ip saddr != @lan_ac_black_ips ether saddr != @lan_ac_black_macs \
  counter redirect to <dns_port> comment "OpenClash DNS Hijack"

# 白名單模式: 僅白名單裝置走劫持
nft add rule inet fw4 openclash_dns_redirect \
  meta nfproto {ipv4} meta l4proto {tcp,udp} th dport 53 \
  ip saddr @lan_ac_white_ips counter redirect to <dns_port> comment "OpenClash DNS Hijack"
nft add rule inet fw4 openclash_dns_redirect \
  meta nfproto {ipv4} meta l4proto {tcp,udp} th dport 53 \
  ether saddr @lan_ac_white_macs counter redirect to <dns_port> comment "OpenClash DNS Hijack"

nft insert rule inet fw4 dstnat position 0 \
  meta nfproto {ipv4} meta l4proto {tcp,udp} th dport 53 counter jump openclash_dns_redirect

# === OUTPUT (僅 router_self_proxy=1): 路由器自身 DNS 直接到 dns_port ===
nft add chain inet fw4 nat_output { type nat hook output priority -1; }
nft insert rule inet fw4 nat_output position 0 \
  meta nfproto {ipv4} meta l4proto {tcp,udp} th dport 53 \
  ip daddr {127.0.0.1} meta skgid != 65534 counter redirect to <dns_port> comment "OpenClash DNS Hijack"
```

> **DNS 劫持模式對比**: 模式 1 (Dnsmasq) 將 DNS 先轉到 dnsmasq 再轉發到 Mihomo DNS，支援 chnroute_pass 的 dnsmasq ipset/nftset 整合；模式 2 (防火牆) 直接將 DNS 流量 DNAT 到 Mihomo DNS 埠，繞過 dnsmasq，效能更高但失去 chnroute_pass 的 dnsmasq 整合。兩種模式均可配合 AC 黑白名單進行裝置級 DNS 劫持控制。

#### B. 非 TUN 模式鏈 (`en_mode_tun` 為空或 `2`)

| 鏈名 | 鉤子來源 | 協議 | 動作 | 觸發條件 |
|------|----------|------|------|----------|
| `openclash` | `dstnat` jump | TCP | REDIRECT → `$proxy_port`(7892) | 始終 |
| `openclash_mangle` | `mangle_prerouting` jump | UDP | TPROXY → `:$tproxy_port`(7895), mark `0x162` | `enable_udp_proxy=1` 或 Fake-IP 模式 |
| `openclash_upnp` | `openclash_mangle` jump | UDP | UPNP 埠排除 (RETURN) | 自動檢測 upnpd |
| `openclash_output` | `nat_output` jump | TCP | 路由器自身 TCP REDIRECT | `router_self_proxy=1` 或 Fake-IP 模式 |
| `openclash_mangle_output` | `mangle_output` jump | UDP | 路由器自身 UDP 標記 | `router_self_proxy=1`+`enable_udp_proxy=1` 或 Fake-IP |

**`openclash` 鏈規則排序 (TCP REDIRECT)** — 與 init.d 實際程式碼一致:

```bash
# 1. 本地網路繞過
nft add rule inet fw4 openclash ip daddr @localnetwork counter return

# 2. 回覆方向繞過
nft add rule inet fw4 openclash ct direction reply counter return

# 3. LAN 白名單非匹配 RETURN (lan_ac_mode=1, 同時有 IP+MAC 白名單時兩者均不匹配才 RETURN)
nft add rule inet fw4 openclash ether saddr != @lan_ac_white_macs \
  ip saddr != @lan_ac_white_ips counter return
# 3b. 單獨白名單 RETURN (僅有 IP 或僅有 MAC 白名單時獨立判斷)
nft add rule inet fw4 openclash ether saddr != @lan_ac_white_macs counter return
nft add rule inet fw4 openclash ip saddr != @lan_ac_white_ips counter return

# 4. LAN 黑名單匹配 RETURN
nft add rule inet fw4 openclash ip saddr @lan_ac_black_ips counter return
nft add rule inet fw4 openclash ether saddr @lan_ac_black_macs counter return

# 5. Fake-IP 範圍 REDIRECT (僅 fake-ip 模式)
nft add rule inet fw4 openclash ip protocol tcp \
  ip daddr {<fakeip_range>} counter redirect to $proxy_port

# 6. WAN 黑名單 IP (WAN-AC)
nft add rule inet fw4 openclash ip daddr @wan_ac_black_ips counter return
# 7. WAN 黑名單埠
nft add rule inet fw4 openclash th dport @wan_ac_black_ports counter return

# 8. 非標準埠繞過 (僅 redir-host 模式, common_ports != 0)
nft add rule inet fw4 openclash th dport != @common_ports counter return

# 9. 中國 IP 繞行 (china_ip_route)
#   mode=1: ip daddr @china_ip_route [ip daddr != @china_ip_route_pass] counter return
#   mode=2: ip daddr != @china_ip_route [ip daddr != @china_ip_route_pass] counter return
#   (china_ip_route_pass 僅在 enable_redirect_dns != 2 時附加)

# 10. 最終代理: 所有剩餘 TCP → REDIRECT
nft add rule inet fw4 openclash ip protocol tcp counter redirect to $proxy_port

# === 跳轉規則 ===
nft add rule inet fw4 dstnat meta nfproto {ipv4} ip protocol tcp counter jump openclash

# === DNAT Accept (當 zone input 策略為 REJECT 時需要) ===
nft insert rule inet fw4 input position 0 ct status dnat accept comment "OpenClash Redirect Accept"
```

**`openclash_mangle` 鏈規則排序 (UDP TPROXY)** — 僅在 `enable_udp_proxy=1` 或 Fake-IP 模式時建立:

```bash
# 1. 本地網路繞過
nft add rule inet fw4 openclash_mangle ip daddr @localnetwork counter return
# 2. 回覆方向繞過
nft add rule inet fw4 openclash_mangle ct direction reply counter return

# 3. Fake-IP UDP TPROXY (僅 fake-ip 模式)
nft add rule inet fw4 openclash_mangle meta l4proto {udp} \
  ip daddr {<fakeip_range>} mark set $PROXY_FWMARK \
  tproxy ip to 127.0.0.1:$tproxy_port counter accept

# 4. WAN/LAN AC bypass (同 TCP 鏈順序)
# 5. common_ports 繞過 (僅 redir-host 模式)
# 6. china_ip_route 繞行

# 7. UPNP 排除
nft add rule inet fw4 openclash_mangle ip protocol udp counter jump openclash_upnp

# 8. TPROXY 最終規則
nft add rule inet fw4 openclash_mangle meta l4proto {udp} \
  mark set $PROXY_FWMARK tproxy ip to 127.0.0.1:$tproxy_port counter accept

# === 跳轉規則 ===
nft add rule inet fw4 mangle_prerouting meta nfproto {ipv4} ip protocol udp counter jump openclash_mangle

# === TPROXY Accept (當 zone input 策略為 REJECT 時需要) ===
nft insert rule inet fw4 input position 0 meta mark $PROXY_FWMARK accept comment "OpenClash TPROXY Accept"
```

> **注意**: 當 `enable_udp_proxy != 1` 但 `en_mode = fake-ip` 時，仍會建立簡化的 `openclash_mangle` 鏈僅處理 Fake-IP UDP 流量（無 common_ports/china_ip_route/UPNP 檢查）。`ip rule add fwmark $PROXY_FWMARK table $PROXY_ROUTE_TABLE` + `ip route add local 0.0.0.0/0 dev lo table $PROXY_ROUTE_TABLE` 在 UDP TPROXY 啟用時建立策略路由。

#### C. TUN 模式鏈 (`en_mode_tun=1` 或 `2`)

> TUN 模式使用 `meta nfproto {ipv4}` 限制僅處理 IPv4 流量，IPv6 由獨立鏈處理。
> 全 TUN 模式 (`en_mode_tun=1`) 標記 tcp+udp；混合模式 (`en_mode_tun=2`) 僅標記 udp（TCP 仍走 REDIRECT）。

| 鏈名 | 鉤子來源 | 協議 | 動作 | 觸發條件 |
|------|----------|------|------|----------|
| `openclash_mangle` | `mangle_prerouting` jump | TCP+UDP | 設定 fwmark `0x162` | 始終 |
| `openclash_mangle_output` | `mangle_output` jump | TCP+UDP | 路由器自身 fwmark | `router_self_proxy=1` 或 Fake-IP |
| `openclash_upnp` | `openclash_mangle` jump | UDP | UPNP 埠排除 (RETURN) | 自動檢測 |

**`openclash_mangle` 規則排序 (TUN 模式)** — 與 init.d 實際程式碼一致:

```bash
# 1. 跳過 TUN 介面自身流量 (防止迴環)
nft add rule inet fw4 openclash_mangle meta l4proto {tcp,udp} \
  iifname utun counter return

# 2. 本地網路繞過
nft add rule inet fw4 openclash_mangle ip daddr @localnetwork counter return
# 3. 回覆方向繞過
nft add rule inet fw4 openclash_mangle ct direction reply counter return

# 4. LAN 白名單非匹配 RETURN
nft add rule inet fw4 openclash_mangle ether saddr != @lan_ac_white_macs \
  ip saddr != @lan_ac_white_ips counter return

# 5. LAN 黑名單匹配 RETURN
nft add rule inet fw4 openclash_mangle ip saddr @lan_ac_black_ips counter return
nft add rule inet fw4 openclash_mangle ether saddr @lan_ac_black_macs counter return

# 6. Fake-IP TUN 標記 (全TUN標記tcp+udp, 混合僅標記udp)
nft add rule inet fw4 openclash_mangle \
  meta l4proto {tcp,udp} ip daddr {<fakeip_range>} mark set $PROXY_FWMARK counter

# 7. WAN 黑名單 IP/埠
nft add rule inet fw4 openclash_mangle ip daddr @wan_ac_black_ips counter return
nft add rule inet fw4 openclash_mangle th dport @wan_ac_black_ports counter return

# 8. 非標準埠繞過 (僅 redir-host 模式)
nft add rule inet fw4 openclash_mangle th dport != @common_ports counter return

# 9. 中國 IP 繞行 (含 china_ip_route_pass 整合)
#   mode=1: ip daddr @china_ip_route [ip daddr != @china_ip_route_pass] counter return
#   mode=2: ip daddr != @china_ip_route [ip daddr != @china_ip_route_pass] counter return

# 10. ICMP 標記 (meta nfproto {ipv4})
nft add rule inet fw4 openclash_mangle meta nfproto {ipv4} \
  ip protocol icmp icmp type echo-request mark set $PROXY_FWMARK counter accept \
  comment "OpenClash ICMP Mark"

# 11. UPNP 排除 (UDP)
nft add rule inet fw4 openclash_mangle ip protocol udp counter jump openclash_upnp

# 12. 最終標記 — 全 TUN 模式標記所有剩餘流量，混合模式僅標記 udp
#     全TUN: mark set $PROXY_FWMARK counter
#     混合:  meta l4proto {udp} mark set $PROXY_FWMARK counter
nft add rule inet fw4 openclash_mangle mark set $PROXY_FWMARK counter

# === 跳轉規則 (meta nfproto {ipv4}) ===
nft add rule inet fw4 mangle_prerouting meta nfproto {ipv4} counter jump openclash_mangle
```

**TUN 轉發規則** (utun 允許透過，同樣使用 `meta nfproto {ipv4}`):

```bash
nft insert rule inet fw4 forward position 0 meta nfproto {ipv4} oifname utun counter accept \
  comment "OpenClash TUN Forward"
nft insert rule inet fw4 forward position 0 meta nfproto {ipv4} iifname utun counter accept \
  comment "OpenClash TUN Forward"
nft insert rule inet fw4 input position 0 meta nfproto {ipv4} iifname utun counter accept \
  comment "OpenClash TUN Input"
nft insert rule inet fw4 srcnat position 0 meta nfproto {ipv4} oifname utun counter return \
  comment "OpenClash TUN Postrouting"
```

**TUN 模式 QUIC 阻斷** (僅 `disable_udp_quic=1`):

```bash
# TUN 模式 extras: forward 鏈額外匹配 oifname utun 覆蓋經 TUN 轉發的流量
nft insert rule inet fw4 forward position 0 oifname utun udp dport 443 \
  ip daddr != @china_ip_route counter reject comment "OpenClash QUIC REJECT"
# 標準: input 鏈 REJECT (同非TUN)
nft insert rule inet fw4 input position 0 udp dport 443 \
  ip daddr != @china_ip_route counter reject comment "OpenClash QUIC REJECT"
```

#### D. IPv6 鏈 (獨立於 IPv4)

> IPv6 防火牆鏈僅在 `ipv6_enable=1` 時建立。`ipv6_mode` 決定資料面處理方式。
> IPv6 DNS 劫持使用 `meta nfproto {ipv6}` + `ip6 nexthdr {tcp,udp}`，與 IPv4 規則結構對稱。

**IPv6 模式詳解**:

| `ipv6_mode` | TCP 處理 | UDP 處理 | 策略路由 |
|-------------|---------|---------|----------|
| `0` (TProxy) | TPROXY → `:$tproxy_port` | TPROXY → `:$tproxy_port` | `ip -6 rule/route` |
| `1` (Redirect) | REDIRECT → `$proxy_port` | TPROXY → `:$tproxy_port` (需 `enable_v6_udp_proxy=1`) | `ip -6 rule/route` |
| `2` (TUN) | fwmark → utun | fwmark → utun | 無 (TUN 處理) |
| `3` (Mix) | REDIRECT → `$proxy_port` | fwmark → utun | 無 (TUN 處理 UDP) |

**IPv6 鏈總覽**:

| nftables 鏈 | 功能 | 觸發條件 |
|-------------|------|----------|
| `openclash_v6` | IPv6 TCP REDIRECT | `ipv6_mode=1` 或 `3` |
| `openclash_mangle_v6` | IPv6 TPROXY / TUN fwmark | `enable_v6_udp_proxy=1` 或 `ipv6_mode≠1` |
| `openclash_output_v6` | 路由器自身 IPv6 TCP | `router_self_proxy=1` + (`ipv6_mode=1` 或 `3`) |
| `openclash_mangle_output_v6` | 路由器自身 IPv6 fwmark | `router_self_proxy=1` |
| `openclash_post_v6` | 旁路由 SNAT/MASQUERADE | `bypass_gateway_compatible=1` |
| `openclash_wan6_input` | 僅內網 IPv6 WAN 防護 | `intranet_allowed=1` |

**IPv6 鏈規則結構** (以 `openclash_mangle_v6` 為例，包含 TProxy/TUN/Mix 所有模式的綜合處理):

```bash
# 1. IPv6 本地網路繞過 (localnetwork6: ::/128, ::1/128, fe80::/10, ff00::/8 等)
nft add rule inet fw4 openclash_mangle_v6 ip6 daddr @localnetwork6 counter return

# 2. 回覆方向繞過
nft add rule inet fw4 openclash_mangle_v6 ct direction reply counter return

# 3. LAN AC 規則 (黑白名單，同 IPv4 邏輯，使用 lan_ac_black_ipv6s/lan_ac_white_ipv6s)
# 4. Fake-IP 範圍標記 (根據 ipv6_mode 不同: TProxy 或 fwmark)

# 5. WAN AC / common_ports / china_ip6_route 繞行

# 6. ICMPv6 標記 (僅 ipv6_mode=2 或 3，即 TUN/Mix 模式)
nft add rule inet fw4 openclash_mangle_v6 meta nfproto {ipv6} \
  ip6 nexthdr icmpv6 icmpv6 type echo-request mark set $PROXY_FWMARK counter accept \
  comment "OpenClash ICMPv6 Redirect"

# 7. 最終代理規則 (根據 ipv6_mode 不同組合 TCP/UDP TPROXY 或 fwmark)

# === 跳轉規則 ===
nft add rule inet fw4 mangle_prerouting meta nfproto {ipv6} counter jump openclash_mangle_v6
```

**IPv6 TUN 轉發規則** (僅 `ipv6_mode=2` 或 `3`):

```bash
nft insert rule inet fw4 forward position 0 meta nfproto {ipv6} oifname utun counter accept
nft insert rule inet fw4 forward position 0 meta nfproto {ipv6} iifname utun counter accept
nft insert rule inet fw4 input position 0 meta nfproto {ipv6} iifname utun counter accept
nft insert rule inet fw4 srcnat position 0 meta nfproto {ipv6} oifname utun counter return
```

**IPv6 DNS 劫持** (與 IPv4 對稱，使用 `ip6 nexthdr` 和 `ip6 saddr`):

```bash
# enable_redirect_dns=1 (Dnsmasq 模式): 劫持 IPv6 DNS 到 dnsmasq 埠
nft insert rule inet fw4 dstnat position 0 \
  meta nfproto {ipv6} ip6 nexthdr {tcp,udp} th dport 53 \
  counter redirect to <dnsmasq_port> comment "OpenClash DNS Hijack"

# enable_redirect_dns=2 (防火牆模式): 劫持 IPv6 DNS 到 Mihomo DNS 埠
nft add rule inet fw4 openclash_dns_redirect \
  meta nfproto {ipv6} ip6 nexthdr {tcp,udp} th dport 53 \
  counter redirect to <dns_port> comment "OpenClash DNS Hijack"
```

**IPv6 QUIC 阻斷** (僅 `disable_udp_quic=1`):

```bash
# 根據 china_ip6_route 選擇繞行方向
# TUN/Mix 模式 extra: forward + oifname utun
nft insert rule inet fw4 input position 0 udp dport 443 \
  ip6 daddr != @china_ip6_route counter reject comment "OpenClash QUIC REJECT"
nft insert rule inet fw4 forward position 0 [oifname utun] udp dport 443 \
  ip6 daddr != @china_ip6_route counter reject comment "OpenClash QUIC REJECT"
```

**IPv6 `localnetwork6` 預設元素**:
```
::/128, ::1/128, ::ffff:0:0/96, ::ffff:0:0:0/96, 64:ff9b::/96,
100::/64, 2001::/32, 2001:20::/28, 2001:db8::/32, 2002::/16,
fe80::/10, ff00::/8
```

#### E. ICMP/Ping 處理詳解

> **AI 行為指引**: 當使用者詢問「為什麼 ping 不走代理」、「ping 通但 TCP 不通」、「Fake-IP 模式下 ping 198.18.x.x 被拒絕」等問題時，AI 應結合本節解釋 ICMP 在非 TUN 和 TUN 模式下的不同處理方式。

OpenClash 對 ICMP（ping）請求的處理**取決於執行模式**：

**1. 非 TUN 模式（Redir-Host / Fake-IP，`en_mode_tun` 為空）**:

ICMP echo-request 在 `openclash_mangle` 鏈中被**僅標記 fwmark（0x162）但不重定向**：

```bash
nft add rule inet fw4 openclash_mangle ip protocol icmp \
  icmp type echo-request mark set "$PROXY_FWMARK" counter accept comment "OpenClash ICMP Mark"
```

- **ICMP 不會被代理**：非 TUN 模式下只有 TCP（REDIRECT）和 UDP（TPROXY）被重定向到 Mihomo 核心，ICMP 僅被標記 fwmark 後直接放行（`accept`）。這意味著 ping 請求走的是系統原始路由表，不會經過代理節點。
- **fwmark 的作用**：標記 0x162 僅影響策略路由選擇（如旁路由迴流），不影響代理行為本身。
- **繞過檢查仍然生效**：ICMP 規則之前的 localnetwork/WAN-AC/LAN-AC/china_ip_route 等 RETURN 規則同樣適用於 ICMP——被匹配的 ICMP 包會跳過標記規則。
- **路由器自身 ICMP**：當 `router_self_proxy=1` 時，路由器發出的 ping 在 `openclash_mangle_output` 鏈中同樣被標記。

**2. TUN 模式（`en_mode_tun=1`）**:

ICMP echo-request 在 `openclash_mangle` 鏈中被標記 fwmark，隨後透過策略路由進入 TUN 虛擬網絡卡：

```bash
# 步驟1: 標記 ICMP
nft add rule inet fw4 openclash_mangle ip protocol icmp \
  icmp type echo-request mark set "$PROXY_FWMARK" counter accept

# 步驟2: 策略路由（系統層面）— 所有標記 0x162 的流量路由到 TUN
ip rule add fwmark 0x162 table 0x162
ip route add default dev utun table 0x162
```

- **ICMP 被代理**：TUN 模式下所有標記 fwmark 的流量（包括 ICMP）被策略路由導向 `utun` 虛擬網絡卡，由 Mihomo 核心的 TUN 協議棧處理。
- **Mihomo 核心配置**：TUN 模式下 Mihomo 支援兩個 ICMP 相關選項：
  - `icmp-timeout`（預設自動）：ICMP 連線超時時間（秒）
  - `disable-icmp-forwarding`（預設 false）：設為 `true` 可禁用 TUN 的 ICMP 轉發（ping 將不被代理）

**3. Fake-IP 非 TUN 模式的 Ping 阻斷**:

**僅在 Fake-IP 非 TUN 模式下**（`en_mode=fake-ip`, `en_mode_tun` 為空），對 Fake-IP 地址段（預設 `198.18.0.0/16`）的 ping 會被防火牆**顯式 REJECT**：

```bash
# INPUT 鏈 — 阻止路由器自身收到發往 Fake-IP 的 ping
nft insert rule inet fw4 input position 0 ip protocol icmp \
  icmp type echo-request ip daddr { 198.18.0.0/16 } counter reject

# FORWARD 鏈 — 阻止區域網裝置間轉發 Fake-IP 的 ping
nft insert rule inet fw4 forward position 0 ip protocol icmp \
  icmp type echo-request ip daddr { 198.18.0.0/16 } counter reject

# OUTPUT 鏈 — 阻止路由器發出對 Fake-IP 的 ping（排除 OpenClash 自身程序 skgid=65534）
nft insert rule inet fw4 output position 0 ip protocol icmp \
  icmp type echo-request ip daddr { 198.18.0.0/16 } \
  skgid != 65534 counter reject
```

這是因為在非 TUN 模式下，Fake-IP 地址沒有對應的 TCP/UDP 重定向路徑（TCP 走 REDIRECT、UDP 走 TPROXY，但 ICMP 都不到達核心），發往這些地址的 ping 無意義且會干擾網路診斷。OUTPUT 鏈排除 `skgid=65534` 是為了避免影響 OpenClash 自身程序的內部通訊。

> **TUN 模式下的區別**：Fake-IP **TUN 模式不新增這些 REJECT 規則**。因為 ICMP 經策略路由進入 TUN 虛擬網絡卡後，由核心的 `skipPingForwardingByAddr()` 判斷——若目標是 Fake-IP，核心返回偽造 echo-reply（~0ms 虛假延遲），不產生實際網路流量。

**4. IPv6 ICMP（ICMPv6）**:

僅在 IPv6 TUN/混合模式（`ipv6_mode=2` 或 `3`）下標記：

```bash
nft add rule inet fw4 openclash_mangle_v6 ip6 nexthdr icmpv6 \
  icmpv6 type echo-request mark set "$PROXY_FWMARK" counter accept
```

IPv6 非 TUN 模式下 ICMPv6 **不被標記也不被代理**。IPv6 Fake-IP 地址範圍的 ping 在**非 TUN 的 IPv6 模式下**被 REJECT（返回 `icmpv6 admin-prohibited`），條件為 `$ipv6_mode -ne 2 -a $ipv6_mode -ne 3`。TUN/Mix 模式下的 IPv6 Fake-IP ping 同樣由核心的 `skipPingForwardingByAddr()` 處理（偽造回覆）。

**總結**:

| 執行模式 | ICMP 進入 TUN | ICMP fwmark | 實際處理 |
|----------|-------------|-------------|----------|
| Redir-Host (非TUN) | ❌ | ✅ 標記 0x162 | 僅標記後放行，不經核心處理 |
| Fake-IP (非TUN) | ❌ | ✅ 標記 0x162 | 防火牆 REJECT Fake-IP 範圍的 ping |
| Redir-Host TUN | ✅ | ✅ 標記 0x162 | 真實 IP → DIRECT 直連延遲 |
| Fake-IP TUN | ✅ | ✅ 標記 0x162 | 真實 IP → DIRECT 直連；Fake-IP → 偽造回覆（~0ms 虛假延遲） |
| Redir-Host Mix | ✅ | ✅ 標記 0x162 | 同 Redir-Host TUN：ICMP 標記後經策略路由進入 TUN，DIRECT 直連 |
| Fake-IP Mix | ✅ | ✅ 標記 0x162 | 同 Fake-IP TUN：真實 IP → DIRECT 直連；Fake-IP → 核心偽造回覆 |

> **實用提示**：如果使用者發現 ping 不通但網頁正常，首先確認不是 Fake-IP **非 TUN** 模式下在 ping 被代理的域名（Fake-IP 返回 `198.18.x.x`，防火牆直接 REJECT）。Fake-IP TUN/Mix 模式下 ping Fake-IP 地址會返回虛假 ~0ms 延遲。非 Fake-IP 的真實 IP ping 在 TUN/Mix 模式下走 DIRECT 直連，延遲反映的是本地網路質量。

**核心側 ICMP 處理機制**（`listener/sing_tun/prepare.go` — Mihomo TUN 監聽器）:

當 ICMP echo-request 經策略路由進入 TUN 虛擬網絡卡後，Mihomo 核心按以下優先順序處理：

1. **目標是 Fake-IP 地址**（`resolver.IsFakeIP(addr)`） → 返回 `nil, nil`，核心用**偽造的 echo-reply** 回覆。上層看到 "ping 成功" 但實際未經過網路，延遲顯示為虛假的 ~0ms
2. **目標是 TUN 介面自身 IP**（`inet4_address` / `inet6_address` 範圍內） → 同上，偽造回覆
3. **`disable-icmp-forwarding: true`** → 所有 ICMP 均偽造回覆
4. **以上均不滿足**（真實 IP 且未禁用轉發） → 透過 `ping.ConnectDestination()` 以 **DIRECT 模式**發出真實 ICMP 包，等待真實 reply。延遲為本地網路到目標的實際 RTT
5. **ICMP 超時**: 預設 10 秒（`sing.go` 常量），可透過 `icmp-timeout` 自定義

> **關鍵結論**: TUN 模式下 ping 的處理分兩種情況——目標是 Fake-IP → 虛假 0ms 延遲；目標是真實 IP → DIRECT 直連延遲。ping **始終不經過代理節點**，這與 TCP/UDP 流量（經代理轉發）的行為不同。

---

#### F. 高階流量控制 (`firewall_lan_ac_traffic`) — 按裝置/協議/埠/DSCP 精確控制

> **UCI 配置路徑**: `config firewall_lan_ac_traffic` 段，透過「外掛設定 → 黑白名單 → 高階流量控制」配置。
> 每條規則作為一個獨立的 UCI section，在 `set_firewall()` 中透過 `config_foreach firewall_lan_ac_traffic` 遍歷插入到已有防火牆鏈的最前面（`position 0`），因此**優先順序高於**所有其他 bypass/redirect 規則。

**UCI 配置欄位**:

| 欄位 | 型別 | 可選值 | 說明 |
|------|------|--------|------|
| `enabled` | bool | `0`/`1` | 是否啟用此規則 |
| `src_ip` | string | IP/CIDR 或 `localnetwork` | 源 IP 地址（`localnetwork` 表示匹配所有本地網路裝置） |
| `src_port` | string | 埠範圍 (如 `0-65535`) | 源埠範圍 |
| `proto` | string | `tcp`/`udp`/`both` | 匹配的協議 |
| `target` | string | `return`/`accept`/`drop` | 動作：`return`=跳過代理(預設)/`accept`=放行/`drop`=丟棄(等效return) |
| `dscp` | string | DSCP 值 (如 `46`) | DSCP 標記匹配（需 iptables DSCP 模組，fw4 無需額外模組） |
| `family` | string | `ipv4`/`ipv6`/`both` | IP 協議族 |
| `interface` | string | 介面名 (如 `br-lan`) | 入介面匹配 |
| `user` | string | UID | 按使用者 ID 匹配（僅 OUTPUT 鏈） |
| `comment` | string | 描述文字 | 規則註釋/標識 |

**規則插入位置** (fw4):

每條規則根據協議和模式被插入到以下鏈的最前面：

| 流量方向 | IPv4 TCP 鏈 | IPv4 UDP 鏈 | IPv6 TCP 鏈 | IPv6 UDP 鏈 |
|----------|------------|------------|------------|------------|
| **入站** (LAN→路由器) | `openclash` (非TUN) / `openclash_mangle` (TUN) | `openclash_mangle` | `openclash_v6` / `openclash_mangle_v6` | `openclash_mangle_v6` |
| **出站** (路由器自身) | `openclash_output` (非TUN) / `openclash_mangle_output` (TUN) | `openclash_mangle_output` | `openclash_output_v6` / `openclash_mangle_output_v6` | `openclash_mangle_output_v6` |
| **旁路由 SNAT** | `openclash_post` | `openclash_post` | `openclash_post_v6` | `openclash_post_v6` |

**規則格式示例** (fw4 nftables):

```bash
# 入站規則: 跳過代理
nft insert rule inet fw4 openclash position 0 tcp \
  sport 0-65535 meta nfproto {ipv4} ip daddr != {<fakeip_range>} \
  ip saddr {192.168.1.100} counter return comment "my_device_bypass"

# OUTPUT 規則: 含 user 匹配
nft insert rule inet fw4 openclash_output position 0 tcp \
  sport 0-65535 meta skuid 1000 ip daddr != {<fakeip_range>} \
  ip saddr {192.168.1.100} counter return comment "my_user_rule"
```

> **注意事項**:
> - 所有規則自動排除 Fake-IP 地址範圍（`ip daddr != {<fakeip_range>}`），確保 Fake-IP 流量不受影響。
> - `target=drop` 在防火牆規則中實際執行為 `return`（跳過代理），區別在於 `drop` 在策略路由/旁路由鏈中也執行 `return`。
> - `user` 欄位僅對 OUTPUT 鏈生效（路由器自身出站流量），入站流量不支援 UID 匹配。
> - DSCP 匹配在 fw3 (iptables) 環境下需要 `iptables-mod-extra`（提供 DSCP 模組），如不可用會輸出警告並跳過 DSCP 規則。

---

### 二、fw3 (iptables/ipset) 等效鏈

| iptables 鏈 | 表 | 等效 nftables 鏈 |
|-------------|-----|-----------------|
| `openclash` | `nat` | `inet fw4 openclash` (TCP) |
| `openclash` | `mangle` | `inet fw4 openclash_mangle` (UDP) |
| `openclash_output` | `nat` | `inet fw4 openclash_output` (TCP) |
| `openclash_output` | `mangle` | `inet fw4 openclash_mangle_output` (UDP) |
| `openclash_post` | `nat` | `inet fw4 openclash_post` |
| `openclash_wan_input` | `filter` | `inet fw4 openclash_wan_input` |
| `openclash_dns_redirect` | `nat` | `inet fw4 openclash_dns_redirect` |
| `openclash_upnp` | `mangle` | `inet fw4 openclash_upnp` |

**fw3 相容性層** — 自動檢測 iptables 是否支援 owner/gid 模組:
```bash
if iptables 不支援 owner 模組; then
    owner="-m mark --mark 0x1a0a"     # 回退: 按 fwmark 匹配
    noowner="-m mark ! --mark 0x1a0a"
else
    owner="-m owner --gid-owner 65534" # 標準: owner 模組
    noowner="-m owner ! --gid-owner 65534"
fi
```

**示例 fw3 REDIRECT (TCP)**:
```bash
iptables -t nat -N openclash
iptables -t nat -A openclash -m set --match-set localnetwork dst -j RETURN
iptables -t nat -A openclash -p tcp -d 198.18.0.0/16 -j REDIRECT --to-ports 7892
iptables -t nat -A openclash -p tcp -m set ! --match-set common_ports dst -j RETURN
iptables -t nat -A openclash -p tcp -j REDIRECT --to-ports 7892
iptables -t nat -A PREROUTING -p tcp -j openclash
```

**示例 fw3 TPROXY (UDP)**:
```bash
iptables -t mangle -N openclash
iptables -t mangle -A openclash -p udp -m set --match-set localnetwork dst -j RETURN
iptables -t mangle -A openclash -p udp -j TPROXY --on-port 7895 --tproxy-mark 0x162
iptables -t mangle -A PREROUTING -p udp -j openclash
```

---

### 三、各選項對防火牆規則的具體影響

| 選項 | 值 | 防火牆規則變化 |
|------|---|---------------|
| **`china_ip_route`** (實驗性：繞過指定區域 IP / China IP Route) | `1` (繞過大陸) | 在代理規則前插入 `ip daddr @china_ip_route [ip daddr != @china_ip_route_pass] counter return` — 目標為國內 IP 的流量跳過代理（若 `enable_redirect_dns != 2` 則附加 chnroute_pass 排除） |
| | `2` (繞過海外) | 插入 `ip daddr != @china_ip_route [ip daddr != @china_ip_route_pass] counter return` — 目標非國內 IP 的流量跳過代理 |
| **`china_ip6_route`** (實驗性：繞過指定區域 IPv6 / China IPv6 Route) | `1` (繞過大陸) | IPv6 等效規則：`ip6 daddr @china_ip6_route [ip6 daddr != @china_ip6_route_pass] counter return` |
| | `2` (繞過海外) | IPv6 等效規則：`ip6 daddr != @china_ip6_route [ip6 daddr != @china_ip6_route_pass] counter return` |
| **`disable_udp_quic`** (禁用 QUIC / Disable QUIC) | `1` | 全部模式在 INPUT/FORWARD 鏈插入 QUIC REJECT 規則 (`udp dport 443`，根據 `china_ip_route`/`china_ip6_route` 匹配或排除中國 IP)。TUN 模式額外在 `forward oifname utun` 插入同規則以覆蓋經 utun 轉發的流量。IPv6 同樣處理。規則觸發僅依賴 `disable_udp_quic`，與 `enable_udp_proxy`/`enable_v6_udp_proxy` 無關。Mihomo 核心自身 QUIC（如 Hysteria 節點、DNS h3）不受影響——核心出站走 OUTPUT 鏈，不在規則範圍內 |
| **`lan_ac_mode`** (區域網訪問控制模式 / LAN Access Control Mode) | `0` (黑名單) | 建立 `lan_ac_black_ips`/`lan_ac_black_macs`/`lan_ac_black_ipv6s` set，匹配到的 RETURN 跳過代理。DNS 劫持規則同步過濾黑名單裝置 |
| | `1` (白名單) | 建立 `lan_ac_white_ips`/`lan_ac_white_macs`/`lan_ac_white_ipv6s` set，**不匹配**的 RETURN 跳過代理（反邏輯）。DNS 劫持規則僅對白名單裝置生效 |
| **`common_ports`** (僅允許常用埠流量 / Common Ports Proxy Mode) | `非0` | 插入 `th dport != @common_ports counter return` — 僅代理指定埠，P2P/BT 埠被繞過。僅 redir-host 模式生效。預設常用埠: 21-23,53,80,123,143,194,443,465,587,853,993,995,998,2052-2053,2082-2083,2086,2095-2096,2197,5222-5223,5228-5230,8080,8443,8880,8888-8889 |
| **`router_self_proxy`** (路由本機代理 / Router-Self Proxy) | `1` | 建立 OUTPUT 鏈 (`openclash_output` + `openclash_mangle_output`)，路由器自身流量被重定向/標記。非 TUN 模式額外對 Fake-IP 模式始終建立 OUTPUT 鏈（即使使用者關閉 router_self_proxy） |
| | `0` | 刪除 OUTPUT 鏈，路由器自身流量走原始路由 |
| **`intranet_allowed`** (僅允許內網 / Only Intranet Allowed) | `1` | IPv4: 建立 `openclash_wan_input` 鏈，REJECT 來自 WAN 口對全部服務埠的訪問。IPv6: 建立 `openclash_wan6_input` 鏈。服務埠: `$proxy_port`(7892)、`$tproxy_port`(7895)、`$cn_port`(9090)、`$http_port`(7890)、`$socks_port`(7891)、`$mixed_port`(7893)、`$dns_port`(7874) |
| **`bypass_gateway_compatible`** (旁路閘道器（旁路由）相容 / Bypass Gateway Compatible) | `1` | IPv4: 建立 `openclash_post` 鏈 (srcnat jump)，對已標記流量執行 MASQUERADE SNAT。規則: skgid return → mark accept → localnetwork return → ct reply return → fib saddr 非 local masquerade。IPv6: 對應建立 `openclash_post_v6` 鏈 |
| **`skip_proxy_address`** (繞過伺服器地址 / Skip Proxy Address) | `1` | 看門狗定時呼叫 `skip_proxies_address()` 透過核心 API 解析代理節點 `server` 地址並加入 `localnetwork` nft set，複用鏈首 RETURN 規則跳過代理，防止代理巢狀 |
| **`enable_redirect_dns`** (本地 DNS 劫持 / Redirect Local DNS Setting) | `1` | IPv4+IPv6 在 `dstnat` 插入 DNS 53 埠 REDIRECT 規則到 dnsmasq 埠。AC 黑白名單裝置過濾。`router_self_proxy=1` 時新增 OUTPUT DNS 劫持 |
| | `2` | 建立 `openclash_dns_redirect` 鏈，IPv4+IPv6 DNS 流量直接 DNAT 到 `dns_port`(7874)。同樣支援 AC 過濾和 OUTPUT 劫持 |
| **`local_network_pass`** (本地 IPv4 繞過地址 / Local IPv4 Network Bypassed List) | 已配置 | 建立 `localnetwork` nft set (預設: 0.0.0.0/8, 127.0.0.0/8, 10.0.0.0/8, 169.254.0.0/16, 192.168.0.0/16, 224.0.0.0/4, 240.0.0.0/4, 172.16.0.0/12, 100.64.0.0/10)，在所有鏈規則首位匹配 RETURN。自定義檔案可覆蓋預設值。WAN 介面 IP 自動加入 |
| **`chnroute_pass`** (繞過指定區域 IPv4 黑名單 / Chnroute Bypassed List) | 已配置 | 建立 `china_ip_route_pass` nft set / ipset，配合 dnsmasq 將指定域名解析的 IP 加入 set。防火牆規則中作為 `china_ip_route` 的排除條件（確保這些 IP 不被繞行規則跳過）。僅在 `enable_redirect_dns != 2` 時生效（依賴 dnsmasq） |
| **UPNP 流量排除**（無 UCI 選項，自動檢測 `/etc/config/upnpd` 租約檔案） | 系統已安裝 upnpd | 建立 `openclash_upnp` 鏈，`upnp_exclude()` 遍歷 upnpd 租約檔案，按 `saddr + sport + protocol` 三元組為每個對映新增 RETURN 規則。看門狗自動同步變更 |
| **`ipv6_enable`** (IPv6 流量代理 / Proxy IPv6 Traffic) | `1` | 建立完整 IPv6 防火牆鏈：`openclash_v6`(TCP REDIRECT, ipv6_mode=1/3)、`openclash_mangle_v6`(UDP TPROXY/TUN fwmark)、`openclash_output_v6`/`openclash_mangle_output_v6`(路由自身)、`openclash_post_v6`(旁路由 SNAT)、`openclash_wan6_input`(僅內網防護) |
| **`local_network6_pass`** (本地 IPv6 繞過地址 / Local IPv6 Network Bypassed List) | 已配置 | 建立 IPv6 `localnetwork6` nft set (預設包含 ::/128, ::1/128, fe80::/10, ff00::/8 等)，IPv6 鏈中匹配本地 IPv6 段 RETURN。WAN IPv6 介面地址自動加入 |
| **ICMP/Ping 處理**（無 UCI 選項，由執行模式決定） | Redir-Host / Fake-IP（非 TUN） | ICMP echo-request 僅標記 fwmark `0x162` 後 accept，**不被代理**（只有 TCP/UDP 被重定向到核心）；Fake-IP 非 TUN 模式下對 `198.18.0.0/16` 的 ping 被防火牆 REJECT（INPUT/FORWARD/OUTPUT 三鏈阻斷，OUTPUT 排除 skgid≠65534） |
| | TUN 模式 / Mix 模式 | ICMP 標記 fwmark 後經策略路由進入 TUN 虛擬網絡卡，由 TUN 核心處理（真實 IP → DIRECT 直連延遲，Fake-IP → 偽造回覆 ~0ms）；可透過 Mihomo 的 `disable-icmp-forwarding` 禁用 |
| **`firewall_lan_ac_traffic`** (高階流量控制 / Advanced Traffic Control) | 已配置 (UCI section) | 透過 `lan_ac_traffic` UCI sections 按裝置/協議/埠/DSCP 精確控制，每條規則插入到對應鏈的最前面 (position 0)，優先順序高於所有其他規則。支援 `return`(跳過代理)/`accept`(放行)/`drop`。詳見上文 F 節 |

---

### 四、Dnsmasq 修改詳解 (`change_dnsmasq` / `revert_dnsmasq`)

**修改流程** (`change_dnsmasq()`, 僅在 `enable_redirect_dns=1` 時執行):

```bash
# 1. 備份原始配置到 openclash.config.*
save_dnsmasq_server() → uci add_list openclash.config.dnsmasq_server="<原始server>"
uci set openclash.config.dnsmasq_noresolv="$(uci get dhcp.@dnsmasq[0].noresolv)"
uci set openclash.config.dnsmasq_resolvfile="$(uci get dhcp.@dnsmasq[0].resolvfile)"
uci set openclash.config.dnsmasq_cachesize="$(uci get dhcp.@dnsmasq[0].cachesize)"

# 2. 重定向 DNS
uci del dhcp.@dnsmasq[-1].server
uci add_list dhcp.@dnsmasq[0].server="127.0.0.1#$dns_port"
uci delete dhcp.@dnsmasq[0].resolvfile
uci set dhcp.@dnsmasq[0].noresolv=1
uci set dhcp.@dnsmasq[0].localuse=1
uci set dhcp.@dnsmasq[0].cachesize=0

# 3. IPv6 DNS (ipv6_dns=1 時)
uci set dhcp.@dnsmasq[0].filter_aaaa=0  # 允許 AAAA 記錄

# 4. chnroute_pass 處理 — 載入 ipset/nftset
load_ip_route_pass()
# 建立 china_ip_route_pass ipset/nftset
# 將 openclash_custom_chnroute_pass.list 中的域名加入 set
# 對 china_ip_route_pass UCI 列表中的域名加入 set

# 5. 自定義域名 DNS
/usr/share/openclash/openclash_custom_domain_dns.sh

# 6. 重啟 dnsmasq
/etc/init.d/dnsmasq restart
```

**恢復流程** (`revert_dnsmasq()`):
```bash
# 1. 刪除 OpenClash 注入的 server
uci del dhcp.@dnsmasq[-1].server

# 2. 恢復原始 server 列表
for server in $(uci get openclash.config.dnsmasq_server); do
    uci add_list dhcp.@dnsmasq[0].server="$server"
done

# 3. 恢復 resolvfile / noresolv / cachesize / filter_aaaa
uci set dhcp.@dnsmasq[0].noresolv="$saved_noresolv"
uci set dhcp.@dnsmasq[0].resolvfile="$saved_resolvfile"
uci set dhcp.@dnsmasq[0].cachesize="$saved_cachesize"

# 4. DNS 驗證 — 測試修改後的 DNS 是否可用
if nslookup www.apple.com 127.0.0.1:<dnsmasq_port> 失敗; then
    # 建立 fallback resolv.conf (114.114.114.114, 8.8.8.8)
fi
```

**chnroute_pass 的 dnsmasq 整合**:
- 建立 `china_ip_route_pass` ipset/nftset
- 將 chnroute_pass 域名加入 set: `ipset=/domain.com/china_ip_route_pass` 或 `nftset=/domain.com/4#inet#fw4#china_ip_route_pass`
- 效果: DNS 解析這些域名時加入 set 便於在匹配時繞過（而非被 chnroute 影響）

---

## 日誌與錯誤資訊速查

> **AI 行為指引**: 當使用者提供日誌報錯資訊時，AI 應首先在以下表格中查詢匹配的錯誤關鍵字，
> 根據「原因」列判斷問題根源，然後按「排查方法」列指導使用者在 LuCI 中操作。
> **若表中未覆蓋該錯誤**，應主動搜尋 [OpenClash GitHub Issues](https://github.com/vernesong/OpenClash/issues) 查詢是否存在相同或相似的問題，
> 優先參考高贊反應的社群回覆和作者（vernesong）給出的解決方案。搜尋時可使用錯誤關鍵字作為搜尋詞。
>
> **兩類日誌說明**:
> - **外掛日誌**（前九類）：由 OpenClash 的 Shell/Ruby/Lua 指令碼產生，含 `[Info]`/`[Tip]`/`[Warning]`/`[Error]` 字首，寫入 `/tmp/openclash.log`。可在 LuCI「執行日誌」頁面檢視。
> - **核心日誌**（第十、十一類）：由 Mihomo 核心（Go 程式）產生，含 `level=debug/info/warning/error/fatal` 標記，同樣寫入 `/tmp/openclash.log`。`level=fatal` 會導致核心程序退出。可在 LuCI「執行日誌」頁面檢視，或在「執行狀態」頁面看到 `OpenClash Start Failed` 提示。

### 一、核心啟動與執行錯誤

| 錯誤關鍵字 | 問題位置 | 原因 | 排查方法 |
|-----------|---------|------|----------|
| `Ruby Works Abnormally, Please Check The Ruby Library Depends!` (Ruby 依賴異常) | 「執行狀態」啟動流程 | `ruby` 或 `ruby-yaml` 包未安裝/損壞 | 「系統→軟體包」安裝 `ruby`、`ruby-yaml`、`ruby-psych` |
| `Unable To Parse Config File` (配置檔案校驗失敗) | 「執行狀態」啟動流程 | YAML 配置檔案語法錯誤或 age 解密失敗 | 「配置管理」頁面點選 Edit 檢查 YAML 語法 |
| `Core Start Failed, Please Check The Log Infos!` (核心啟動失敗) | 「執行狀態」啟動流程 | 核心程序未能啟動 | 「執行狀態」檢視核心版本是否正確；「執行日誌」生成除錯日誌 |
| `Core Initial Configuration Timeout` (核心初始化超時) | 「執行狀態」啟動流程 | 核心 API 在 300 秒內未就緒 | 檢查 `/tmp/openclash.log` 中核心日誌；確認「覆寫設定→常規」的 cn_port 未被佔用 |
| `TUN Interface Start Failed` (TUN 介面啟動失敗) | 「執行狀態」啟動流程 | TUN 虛擬網絡卡建立失敗 | 「系統→軟體包」確認 `kmod-tun` 已安裝 |
| `【{module}】module not found` (核心模組未找到) | 「執行狀態」啟動流程 | 核心模組未安裝/未載入（tun/tproxy 等） | 「系統→軟體包」安裝對應的 kmod 包 |
| `LAN IP Address Get Error` (LAN IP 獲取失敗) | 「執行狀態」啟動流程 | LAN 介面 IP 無效或 `ip-full` 包缺失（舊核心 4.4.x 常見 br-lan 網橋無 IP） | 「外掛設定→流量控制」選擇正確的 LAN 介面名稱（如 `br-lan`）；「系統→軟體包」安裝 `ip-full`；終端 `ip address show br-lan` 確認存在 IPv4 地址；嘗試切換執行模式為混合模式 |
| `OpenClash Now Disabled, Need Start From Luci Page` (外掛未啟用) | 「執行狀態」啟動流程 | 外掛被禁用（enable=0） | 「執行狀態」頁面點選啟動開關 |

### 二、訂閱與配置更新錯誤

| 錯誤關鍵字 | 問題位置 | 原因 | 排查方法 |
|-----------|---------|------|----------|
| `Config File Subscribed Failed` (訂閱配置下載失敗) | 「配置訂閱」更新流程 | 訂閱 URL 下載失敗（curl 錯誤） | 「配置訂閱」檢查訂閱 URL 是否正確；確認網路連通性 |
| `Config File Tested Faild` (配置檔案測試失敗) | 「配置訂閱」更新流程 | 下載的 YAML 未透過 `clash -t` 驗證 | 「配置管理」頁面 Edit 檢查 YAML 語法；檢視 `/tmp/openclash.log` |
| `Updated Config Has No Proxy Field` (配置無節點欄位) | 「配置訂閱」更新流程 | 訂閱配置中無 `proxies` 和 `proxy-providers` 欄位 | 檢查訂閱源是否有效；可能訂閱已過期 |
| `Filter Proxies Failed` (節點篩選失敗) | 「配置訂閱」更新流程 | 節點關鍵字過濾正則異常 | 「配置訂閱」檢查 keyword/ex_keyword 格式 |
| `Ruby Works Abnormally` (Ruby 異常) | 「配置訂閱」更新流程 | Ruby 環境異常導致訂閱處理失敗 | 「系統→軟體包」重灌 `ruby`、`ruby-yaml` |
| `Config File Format Validation Failed` (配置檔案格式校驗失敗) | 「執行狀態」啟動流程 | YAML 解析後檔案為空/丟失 | 「配置管理」檢查配置目錄許可權和磁碟空間 |

### 三、GEO 與規則更新錯誤

| 錯誤關鍵字 | 問題位置 | 原因 | 排查方法 |
|-----------|---------|------|----------|
| `Download Failed: HTML Response Detected` (下載失敗：檢測到 HTML 響應) | 「外掛設定→GEO 資料庫訂閱」 | CDN 返回的是 HTML 錯誤頁而非 GEO 檔案 | 「覆寫設定→常規」檢查 Github 地址修改 CDN 選項 |
| `Download Failed: File Size Too Small` (下載失敗：檔案過小) | 「外掛設定→GEO 資料庫訂閱」 | 下載檔案 <1KB，內容不完整 | 「外掛設定→GEO 資料庫訂閱」檢查 GEO 自定義 URL 是否正確 |
| `Update Error, Please Try Again Later` (更新失敗，請稍後再試) | 「外掛設定→GEO 資料庫訂閱」 | 網路下載失敗 | 「執行狀態」檢查網路連通性；若使用代理下載，新增直連規則 |
| `Control Panel Unzip Error!` (控制面板解壓失敗) | 「執行狀態」儀表盤切換 | Dashboard 壓縮包解壓失敗 | 「系統→軟體包」確認 `unzip` 已安裝 |
| `LightGBM Model Update Error` (LGBM 模型更新失敗) | 「覆寫設定→智慧設定」 | LGBM 模型下載失敗 | 「覆寫設定→智慧設定」檢查模型 URL |

### 四、核心與外掛版本更新錯誤

| 錯誤關鍵字 | 問題位置 | 原因 | 排查方法 |
|-----------|---------|------|----------|
| `Core Version Check Error` (核心版本檢測失敗) | 「版本更新」 | GitHub 不可達，無法獲取最新版本資訊 | 「執行狀態」檢查網路連通性；如在大陸，設定 CDN |
| `Core Update Failed` (核心更新失敗，重試 3 次後) | 「版本更新」 | 核心下載/解壓/替換失敗 | 「版本更新」確認快閃記憶體空間和 CPU 架構選擇；「系統 → 軟體包」檢查磁碟空間 |
| `No Compiled Version Selected` (未選擇編譯版本) | 「版本更新」 | CPU 架構未選擇（core_version=0） | 「版本更新」標籤頁選擇對應的 CPU 架構 |
| `Pre update test failed` (更新前測試失敗，3 次後) | 「版本更新」 | 外掛 IPK/APK 安裝測試失敗 | 手動在「系統→軟體包」中更新或重灌 luci-app-openclash |
| `OpenClash update failed` (OpenClash 更新失敗) | 「版本更新」 | 外掛安裝徹底失敗 | 包已儲存在 `/tmp/`，手動使用 `opkg install` 或 `apk add` 安裝 |
| `Failed to get version information` (獲取版本資訊失敗) | 「版本更新」 | GitHub 版本檢查失敗 | 檢查網路；「覆寫設定→常規」設定 CDN |

### 五、防火牆與 DNS 錯誤

| 錯誤關鍵字 | 問題位置 | 原因 | 排查方法 |
|-----------|---------|------|----------|
| `Dnsmasq not Support nftset, Use ipset` (Dnsmasq 不支援 nftset) | 「執行狀態」啟動流程 | dnsmasq-full 未編譯 nftset 支援 | 警告，非致命；如 chnroute 旁路異常則重灌 dnsmasq-full |
| `iptables DSCP module not available` (iptables DSCP 模組不可用) | 「執行狀態」啟動流程 | iptables 缺少 DSCP 模組 | 警告，DSCP 規則被跳過；或改用核心側 DSCP |
| `Can't Setting Only Intranet Allowed Function` (無法設定僅允許內網) | 「執行狀態」啟動流程 | 無法識別 WAN 介面 | 「外掛設定→流量控制」檢查 WAN 介面名稱設定 |
| `Nameserver Option Must Be Setted, Stop Customing DNS Servers` (Nameserver 未設定) | 「覆寫設定→DNS」 | 自定義 DNS 啟用但未配置任何 nameserver | 「覆寫設定→DNS」新增至少一個 DNS 伺服器 |
| `Fallback-Filter Need fallback of DNS Been Setted` (Fallback-Filter 需要 Fallback DNS) | 「覆寫設定→DNS」 | fallback-filter 需要先配置 fallback DNS | 「覆寫設定→DNS」先新增 fallback 分組的 DNS 伺服器 |
| `DNS Loop Check` (DNS 迴環檢查) | 「覆寫設定→DNS」 | DNS 配置存在迴環風險 | 「覆寫設定→DNS」檢查伺服器列表，避免將 Clash DNS 埠設為其上游 |

### 六、覆寫模組錯誤

| 錯誤關鍵字 | 問題位置 | 原因 | 排查方法 |
|-----------|---------|------|----------|
| `skip General key not allowed` (覆寫 key 不允許) | 「覆寫設定」覆寫模組 | 覆寫 [General] 中的 key 不在允許列表中 | 檢查 key 拼寫；參考覆寫模組 8.2.1 節的允許 key 列表 |
| `skip invalid Overwrite command` (無效覆寫命令) | 「覆寫設定」覆寫模組 | [Overwrite] 段命令不以 `ruby_` 開頭 | 修正命令語法，使用 `ruby_method_name` 格式 |
| `Invalid YAML Override format` (無效 YAML 覆寫格式) | 「覆寫設定」覆寫模組 | [YAML] 段不是有效的 Hash 結構 | 檢查 YAML 縮排和格式 |
| `Parse YAML Override failed` (YAML 覆寫解析失敗) | 「覆寫設定」覆寫模組 | [YAML] 段 Ruby 解析異常 | 逐行檢查 YAML 語法 |
| `Config File Overwrite Failed` (配置檔案覆寫失敗) | 「覆寫設定」覆寫模組 | 覆寫應用整體失敗 | 檢查所有覆寫設定的語法 |
| `DOWNLOAD FILE failed` (檔案下載失敗) | 「覆寫設定」覆寫模組 | 覆寫模組 DOWNLOAD_FILE 下載失敗 | 檢查下載 URL 和網路連通性 |

### 七、流媒體解鎖錯誤

| 錯誤關鍵字 | 問題位置 | 原因 | 排查方法 |
|-----------|---------|------|----------|
| `Streaming Unlock Could not Work Because of Router-Self Proxy Disabled` (流媒體解鎖失效：本機代理關閉) | 「執行狀態」看門狗 | 路由器自代理關閉導致流媒體解鎖無法工作 | 「外掛設定→流量控制」開啟本機代理 |
| `Something Wrong While Testing` (流媒體測試失敗) | 「外掛設定→流媒體增強」 | 流媒體測試指令碼執行失敗 | 「執行狀態」確認核心執行中；「外掛設定→流媒體增強」檢查策略組配置 |

### 八、LuCI Web 介面錯誤

| 錯誤提示 | 問題位置 | 原因 | 排查方法 |
|----------|---------|------|----------|
| `Switch Faild` (切換失敗) | 「執行狀態」快捷設定 | API 不可達或核心未執行 | 「執行狀態」確認核心狀態；重新整理頁面後重試 |
| `Config file does not exist` (配置檔案不存在) | 「配置管理」 | 配置檔案路徑無效 | 「配置管理」檢查檔名；確認檔案存在於配置列表中 |
| `File size exceeds 10MB limit` (檔案超過 10MB 限制) | 「配置管理」上傳 | 上傳檔案超過 10MB | 減小檔案或拆分上傳 |
| `Cannot delete the last remaining dashboard` (無法刪除最後一個儀表盤) | 「執行狀態」儀表盤切換 | 只剩一個儀表盤時不允許刪除 | 「執行狀態」先下載新的儀表盤再刪除舊的 |
| `Failed to generate age key` (生成 Age 金鑰失敗) | 「配置訂閱」Age 金鑰 | 核心不支援 age keygen | 「版本更新」檢查核心版本；手動生成 age 金鑰 |
| `Failed to calculate public key` (計算公鑰失敗) | 「配置訂閱」Age 金鑰 | 金鑰格式無效 | 驗證 age 金鑰格式（應以 `AGE-SECRET-KEY-` 開頭） |
| `Bad address specified!` (地址無效) | 「執行狀態」連線診斷 | 輸入地址為空或無效 | 輸入有效的主機名或 IP 地址 |
| `OpenClash Start Failed: {msg}` (OpenClash 啟動失敗) | 「執行狀態」 | 核心日誌中出現 fatal/error 級別日誌 | 檢視完整錯誤訊息；「執行日誌」生成除錯日誌 |
| `Access Denied` (無法訪問) / `Access Timed Out` (連線超時) | 「執行狀態」IP 檢測 | 網路連線問題 | 檢查路由器網路連線 |

### 九、YAML 配置處理錯誤

| 錯誤關鍵字 | 問題位置 | 原因 | 排查方法 |
|-----------|---------|------|----------|
| `Load File Failed` (載入檔案失敗) | 「配置管理」配置載入 | Ruby 無法載入配置檔案 | 確認配置檔案存在且許可權正確 |
| `Set Custom DNS Failed` (自定義 DNS 設定失敗) | 「覆寫設定→DNS」 | DNS 覆寫處理失敗 | 檢查「覆寫設定→DNS」中的 DNS 伺服器配置 |
| `Set Fake-IP-Filter Failed` (Fake-IP-Filter 設定失敗) | 「覆寫設定→DNS」 | Fake-IP 過濾器配置異常 | 「覆寫設定→DNS」檢查 Fake-IP-Filter 檔案和模式 |
| `Set Hosts Rules Failed` (Hosts 規則設定失敗) | 「覆寫設定→DNS」 | 自定義 Hosts 格式錯誤 | 「覆寫設定→DNS」檢查 hosts 檔案每行格式 |
| `Set Custom Rules Failed` (自定義規則設定失敗) | 「覆寫設定→規則」 | 自定義規則注入異常 | 「覆寫設定→規則」檢查規則檔案語法 |
| `Skiped The Custom Rule Because Group & Proxy Not Found` (規則跳過：策略組/代理不存在) | 「覆寫設定→規則」 | 規則引用了不存在的策略組/代理 | 「覆寫設定→規則」檢查規則中 MATCH/Proxy/策略組名稱是否存在 |
| `Set BT/P2P DIRECT Rules Failed` (BT/P2P 直連規則設定失敗) | 「覆寫設定→規則」 | BT 直連規則注入失敗 | 「覆寫設定→規則」關閉再重新開啟「僅代理命中規則流量 (Rule Match Proxy Mode)」選項 |
| `proxy-groups Get Failed` (策略組獲取失敗) | 「配置管理」策略組 | 配置中策略組解析異常 | 「配置管理」頁面 Edit 檢查 proxy-groups 段 |

### 十、Ruby YAML 模組錯誤

| 錯誤關鍵字 | 問題位置 | 原因 | 排查方法 |
|-----------|---------|------|----------|
| `Fix short-id values type failed` (short-id 型別修復失敗) | 「配置管理」YAML 處理 | YAML 中 `short-id` 欄位值型別修復時 Psych 解析異常 | 「配置管理」Edit 檢查配置中 `short-id` 欄位的值格式 |
| `YAML overwrite failed:【key: ...】` (YAML 覆寫失敗) | 「覆寫設定」覆寫模組 | 覆寫模組 YAML 合併時發生異常 | 「覆寫設定」檢查 `[YAML]` 段的語法和運算子使用 |
| `YAML overwrite failed:【(match value) => ...】` (YAML 條件覆寫匹配失敗) | 「覆寫設定」覆寫模組 | 批次條件更新的 where 匹配邏輯異常 | 「覆寫設定」檢查 `key*` 運算子的 where 條件格式和正則 |
| `YAML overwrite failed:【(batch update) => ...】` (YAML 批次更新失敗) | 「覆寫設定」覆寫模組 | 批次條件更新執行時異常 | 「覆寫設定」檢查 `key*` 運算子的 set 子句語法 |
| `Write file failed` (寫檔案失敗) | 「配置管理」YAML 寫入 | YAML 寫入檔案時 I/O 異常 | 檢查磁碟空間和檔案許可權 |
| `Decrypt attempt failed` (解密嘗試失敗) | 「配置訂閱」Age 解密 | Age 加密檔案解密失敗 | 「配置訂閱」檢查 age 金鑰是否正確；驗證加密檔案完整性 |
| `Decrypted content empty or still encrypted` (解密後為空或仍加密) | 「配置訂閱」Age 解密 | Age 解密後內容為空或仍為加密格式 | 「配置訂閱」確認 age 金鑰與加密時使用的金鑰匹配 |
| `Encrypt attempt failed` (加密嘗試失敗) | 「配置訂閱」Age 加密 | Age 加密寫入時失敗 | 「配置訂閱」檢查 age 公鑰格式；驗證核心年齡功能 |
| `Encrypted file: decryption failed` (加密檔案解密失敗) | 「配置訂閱」Age 解密 | 所有 age 金鑰嘗試均解密失敗 | 「配置訂閱」檢查所有訂閱的 age 金鑰；可能金鑰不匹配 |

### 十一、Mihomo 核心配置解析錯誤（`level=fatal` / `level=error`）

> 以下為 Mihomo 核心在**載入/解析 YAML 配置檔案**時產生的錯誤。`level=fatal` 會導致核心程序退出。
> 日誌檢視：LuCI「執行日誌」頁面或「執行狀態」頁面（若啟動失敗會顯示 `OpenClash Start Failed`）。

`Parse config error` 的具體子型別及修復方法：

| 錯誤詳情 | 配置段 | 修復方法 |
|---------|--------|----------|
| `proxy <N>: missing type` | `proxies` | 在「配置管理」Edit 中給第 N 個代理節點新增 `type:` 欄位（如 `ss`, `vmess`, `trojan` 等） |
| `proxy <N>: unsupport proxy type: <type>` | `proxies` | 代理型別名稱拼寫錯誤或不支援，檢查 `type:` 值是否在 Mihomo 支援列表中 |
| `proxy <name> is the duplicate name` | `proxies` | 兩個代理節點同名，在「配置管理」Edit 中修改其中一個的名稱 |
| `proxy group <N>: missing name` | `proxy-groups` | 第 N 個策略組缺少 `name:` 欄位，Edit 中補充 |
| `<groupName>: unsupported type` | `proxy-groups` | 策略組 `type:` 值無效，改為 `select`, `url-test`, `fallback`, `load-balance` 或 `smart` |
| `loop is detected in ProxyGroup` | `proxy-groups` | 策略組之間存在迴圈引用（A 引用 B，B 又引用 A），打破迴圈鏈 |
| `<groupName>: use or proxies missing` | `proxy-groups` | 策略組沒有配置 `proxies:` 或 `use:`，至少新增一個 |
| `'<name>' not found` | `proxy-groups` | 策略組引用了不存在的代理節點或 provider 名稱，檢查拼寫 |
| `can not defined a provider called 'default'` | `proxy-providers` | provider 使用了保留名 `default`，改用其他名稱 |
| `unsupport vehicle type: <type>` | `proxy-providers` / `rule-providers` | provider 的 `type:` 值無效，應為 `file`, `http` 或 `inline` |
| `file must have a payload field` | `rule-providers` | 規則集檔案缺少 `payload:` 欄位，檢查檔案內容格式 |
| `rules[<N>] [<line>] error: format invalid` | `rules` | 第 N 條規則格式錯誤，檢查規則語法：`TYPE,payload,target,no-resolve` |
| `rules[<N>] [<line>] error: proxy [<name>] not found` | `rules` | 規則目標引用了不存在的策略組/代理名稱 |
| `rules[<N>] [<line>] error: rule set [<name>] not found` | `rules` | 規則使用了 `RULE-SET,<name>` 但未在 `rule-providers` 中定義該名稱 |
| `sub-rule error: circular references` | `sub-rules` | 子規則之間形成迴圈引用鏈，打破迴圈 |
| `decrypt config error` | 全域性 | Age 加密的配置檔案解密失敗，在「配置訂閱」中檢查 age 金鑰 |
| `configuration file ... is empty` | 全域性 | 配置檔案為空，在「配置管理」中檢查配置是否正常下載 |
| `[Smart] Invalid policy-priority rule: must be in 'pattern:factor' format` | `smart` 策略組 | 「覆寫設定→智慧設定」中 `smart_policy_priority` 格式錯誤，改為 `名稱:係數` |
| `DNS [addr] config with invalid ecs` | `dns` | DNS 伺服器的 ECS 配置格式無效，「覆寫設定→DNS」檢查 DNS 伺服器設定 |
| `[Smart] Model.bin invalid, remove and download` | Smart 模型 | 「覆寫設定→智慧設定」點選手動更新模型按鈕重新下載 |
| `[CacheFile] remove invalid cache file error` | 執行快取 | 「執行狀態」停止 OpenClash，手動刪除 `/etc/openclash/cache.db` 後重啟 |

> **通用排查**: 在「配置管理」頁面點選 **Download Run** 下載經指令碼處理後的執行時配置，對比原始訂閱檢查 `yml_change.sh` 和覆寫模組生成的 YAML 是否正確。

### 十二、DNS 洩露排查

> **核心驗證方法**：在客戶端執行 `nslookup www.google.com`，應返回：① DNS 伺服器為 OpenWrt 路由器 IP；② 解析結果為 Fake-IP 範圍地址（`198.18.x.x`）。若返回真實 IP 或上游 DNS 非路由器，說明 DNS 解析鏈路異常。正確鏈路應為：`裝置 → Dnsmasq(53埠) → OpenClash(7874埠)`。

| 錯誤關鍵字 | 問題位置 | 原因 | 排查方法 | 來源 |
|-----------|---------|------|----------|------|
| DNS 洩露（ipleak / `ipleak.net` 檢測到國內 DNS） | 「覆寫設定→DNS」 | Redir-Host/Fake-IP 下 nameserver 和 fallback 併發請求，國內 DNS 結果可能被優先採納 | ① Meta 核心建議**放棄 fallback**，僅用 `nameserver-policy` 做 DNS 分流（國內域名→國內 DNS，國外域名→國外 DNS）；② 境外 DNS 地址後加 `#PROXY` 強制走代理（如 `https://1.1.1.1/dns-query#PROXY`）；③ 刪除原配置 YAML 的 `dns:` 段，僅透過「覆寫設定→DNS」管理 DNS 配置避免衝突；④ 將 `proxy-server-nameserver` 設為國內 DNS 避免代理節點域名解析走境外 | [#3843](https://github.com/vernesong/OpenClash/issues/3843) |
| `nameserver-policy` 未生效，DNS 仍走 nameserver | 「覆寫設定→DNS」 | OpenClash 的「覆寫設定→DNS」選項會與訂閱配置的 `dns:` 段合併，可能導致預期外的 DNS 行為 | ① 在「覆寫設定→DNS」啟用「自定義 DNS 設定 (Custom DNS Setting)」後重新配置所有 DNS 規則；② 在「執行日誌」中開啟 Debug 等級觀察實際 DNS 查詢路徑；③ 確認 `default-nameserver` 組的 DNS 伺服器開啟了「節點域名解析」選項 | 同上 |
| DNS 洩露（開啟 IPv6 後出現） | 「覆寫設定→DNS」+「IPv6 設定」 | 運營商下發的 IPv6 DNS 繞過了 OpenClash 的 DNS 劫持，直接響應客戶端請求（"搶答"） | ① 在 LuCI 的「網路→DHCP/DNS→高階設定」中取消 `過濾 IPv6 AAAA 記錄`；② 在 LAN 介面 DHCP 伺服器 IPv6 設定中**取消「本地 IPv6 DNS 伺服器」**，強制裝置使用路由器 IPv4 地址進行 DNS 解析；③ DHCPv6 服務設為已禁用，RA 設為伺服器模式。原理：DNS 請求走 IPv4 通道，流量走 IPv6 通道——IPv4 DNS 同樣可以查詢 AAAA 記錄返回 IPv6 地址 | — |
| 旁路由環境下 DNS 洩露 | 「執行狀態」 | 旁路由裝置未正確指定上游 DNS 為 OpenWrt IP（尤其是 IPv6 DNS 留空） | ① 旁路由裝置必須**手動指定 IPv4 DNS 為 OpenWrt 路由器 IP**；② **IPv6 DNS 必須留空**；③ 若使用 DHCP 分配，確保 DHCP 伺服器不下發 IPv6 DNS 地址 | — |

### 十三、版本更新與下載失敗

| 錯誤關鍵字 | 問題位置 | 原因 | 排查方法 | 來源 |
|-----------|---------|------|----------|------|
| `/tmp/openclash_last_version` 下載失敗 | 「執行日誌」/ 啟動流程 | ① curl SSL 證書驗證失敗（`BADCERT_CN_MISMATCH` / `self signed certificate`）；② GitHub Raw 域名被 DNS 汙染或不可達；③ curl 超時（`Operation timed out`）；④ 缺少 `libmbedtls` 庫 | ①「覆寫設定→常規」設定 **Github 地址修改 (github_address_mod)** 為 CDN（推薦 `https://fastly.jsdelivr.net/` 或 `https://testingcf.jsdelivr.net/`）；②「系統→軟體包」確認 `ca-bundle` 已安裝；③ Fake-IP 模式在「覆寫設定→DNS」的 fake-ip-filter 中排除 `raw.githubusercontent.com`；④ 修改 `/usr/share/openclash/openclash_core.sh` 中 curl 的超時引數 `-m 60` 改為 `-m 300`；⑤ 終端執行 `opkg install libmbedtls` 修復 curl 庫依賴 | [#2791](https://github.com/vernesong/OpenClash/issues/2791) |
| **更新核心 (Update Core)** 點選後重啟失敗 | 「執行狀態」頁面 | v0.47.052 重啟流程中 stop→start 間隔不足，舊核心程序未完全退出即啟動新核心，觸發「核心啟動失敗」 | ① 更新到 v0.47.054+（已在 Developer 分支修復）；② 臨時解決：編輯 `/etc/init.d/openclash`，在 restart 函式的 stop 和 start 之間加 `sleep 5`；③ 如更新後仍失敗，檢查記憶體是否不足（小型裝置建議增加 swap） | [#4969](https://github.com/vernesong/OpenClash/issues/4969) |
| 升級後依賴檢查異常，無法啟動 | 「執行日誌」啟動流程 | 更新後 `check_mod()` 或依賴檢測邏輯誤報 | ①「執行日誌」生成除錯日誌檢查依賴段；②「系統→軟體包」確認 `kmod-nft-tproxy`/`kmod-ipt-tproxy` 已安裝；③ 切換 Dev 分支獲取最新修復；④ 重灌 `luci-app-openclash` | [#4807](https://github.com/vernesong/OpenClash/issues/4807) |
| v0.47.052/055 無法開機自啟 | 「執行狀態」啟動流程 | 啟動時序競爭條件，procd respawn 在某些韌體上觸發過快 | ① 更新到最新 Dev 版本；②「外掛設定→模式設定」設定 `delay_start` (啟動延遲) 30-60 秒；③ 確保路由器有足夠記憶體供啟動時使用 | [#4973](https://github.com/vernesong/OpenClash/issues/4973) |

### 十四、功能異常類

| 錯誤關鍵字 | 問題位置 | 原因 | 排查方法 | 來源 |
|-----------|---------|------|----------|------|
| **向日葵/AnyDesk 等遠端軟體無法連線** | 區域網客戶端 | 遠端軟體域名/QUIC 流量被代理或阻斷 | ①「覆寫設定→規則」新增直連規則：`DOMAIN-SUFFIX,oray.com,DIRECT`、`DOMAIN-SUFFIX,sunlogin.net,DIRECT` 等；② 確認 sniffer `skip-domain` 已包含 `oray.com` 和 `sunlogin.net`（預設已含）；③ 嘗試關閉「外掛設定→流量控制」的 `disable_udp_quic` (禁用 QUIC) | [#3229](https://github.com/vernesong/OpenClash/issues/3229) |
| **小米攝像機/智慧家居外網無法訪問** | 區域網 IoT 裝置 | IoT 裝置流量被代理導致 NAT 穿透失敗 | ①「外掛設定→黑白名單」新增攝像機 IP 到「不走代理的區域網裝置 IP (LAN Bypassed Host List)」列表；② 確認 sniffer `skip-domain` 包含 `Mijia Cloud`（預設已含）；③「覆寫設定→規則」新增 IoT 域名直連規則：`DOMAIN-SUFFIX,xiaomi.com,DIRECT` | [#2431](https://github.com/vernesong/OpenClash/issues/2431) |
| **繞過中國大陸IP (China IP Route) 功能突然失效** | 升級後 / 「執行狀態」 | 版本升級後 `china_ip_route` 的 nftables/ipset 重建失敗或 chnroute 列表未更新 | ①「外掛設定→大陸白名單訂閱」手動更新一次大陸 IP 列表；②「執行狀態」頁面 Area Bypass 先切到關閉再切回「繞過中國大陸 (Bypass Mainland China)」重新觸發；③ 終端執行 `nft list set inet fw4 china_ip_route | head` 檢查 nft set 是否存在且非空 | [#4031](https://github.com/vernesong/OpenClash/issues/4031) |
| **自定義防火牆規則（開發者選項）不生效** | 「外掛設定→開發者設定」 | 編輯後未重啟或指令碼語法錯誤 | ① 修改 `openclash_custom_firewall_rules.sh` 後需**重啟 OpenClash**（不是過載防火牆）；② 用 `bash -n` 檢查指令碼語法；③「執行日誌」生成除錯日誌檢查是否成功執行（日誌中含自定義指令碼內容） | [#4005](https://github.com/vernesong/OpenClash/issues/4005) |
| **DDNS 服務（如 DDNS-GO）工作異常** | 路由器 DDNS 外掛 | DDNS 服務商 API 域名被錯誤分配 Fake-IP，導致 IP 檢測失敗 | ① 將 DDNS 服務商的 API 域名加入「覆寫設定→DNS」的 Fake-IP-Filter 中（填入域名使其返回真實 IP）；② 常見需排除的域名如 `ddns.oray.com`、`api.cloudflare.com` 等，具體根據所用服務商填寫 | — |
| **Cloudflare Tunnel (Cloudflared) 連線不穩定** | 路由器/內網裝置 | Cloudflared 預設使用 QUIC 連線，而海外 QUIC 流量預設被 OpenClash 阻斷 | ① 規則中已指定 Cloudflare Tunnel 相關域名直連；② 在 Cloudflared 啟動引數中顯式指定 `--protocol http2` 強制使用 HTTP/2（Docker 版：`command: [tunnel, --no-autoupdate, --protocol, http2, run, --token, ${CF_TOKEN}]`） | — |
| **BT/PT 下載流量進入核心** | 下載裝置 | 下載裝置流量未正確分流 | ① 若下載裝置為獨立裝置（如 NAS），在「覆寫設定→規則→自定義規則」中新增 `SRC-IP-CIDR,192.168.1.x/32,DIRECT`；② 若同時啟用了 IPv6，還需新增 IPv6 字尾規則 `SRC-IP-SUFFIX,::a1b2:c3d4,DIRECT`（字尾由 EUI-64 生成，可在裝置上檢視）；③ 非獨立裝置可設定「非標埠」策略組直連來規避 80/443 以外的下載流量 | — |
| **直連網站/APP/小程式打不開** | 區域網客戶端 | 小眾域名未被 geosite:cn 收錄，被誤判為非直連走代理 | ① 臨時方案：將「漏網之魚」策略組設為直連；② 永久方案：在「覆寫設定→規則→自定義規則」中為對應域名新增 `DOMAIN-SUFFIX,xxx.com,DIRECT` 規則；③ 觀察 zashboard 中命中策略組確認分流是否正確 | — |
| **開啟 IPv6 後某些直連訪問卡頓** | 區域網客戶端 | IPv6 DNS 搶答或運營商 IPv6 DNS 不穩定導致解析異常 | ① 禁用「覆寫設定→DNS」的「追加上游 DNS」，改為在 NameServer 中手動新增 DoH 伺服器（如 AliDNS）；② 確保 LAN 口未下發 IPv6 DNS 地址 | — |
| **非直連站點打不開且核心日誌無記錄** | 「執行狀態」 | WAN 介面名稱填寫錯誤或 DNS 重定向未關閉 | ①「外掛設定→流量控制」清空 WAN 介面名稱；② 確認「網路→DHCP/DNS」中 DNS 重定向功能已關閉；③ 兩者均正確時，檢查 OpenWrt 中是否有其他劫持 53 埠或修改 Dnsmasq 的外掛 | — |
| **Hysteria / Hysteria2 / TUIC 節點連線失敗、斷流、握手超時** | 核心日誌 `level=error` | ① Linux 核心 ≥6.6 的 quic-go GSO 相容性問題（最常見）；② Hysteria 協議對 `server`/`auth`/`tls`/`password` 欄位配置敏感 | ① **優先嚐試**：「外掛設定→模式設定」開啟**「禁用 quic-go GSO (Disable QUIC Go GSO)」**後重啟 OpenClash；② 確認 YAML 中 `type: hysteria` 或 `type: hysteria2` 拼寫正確、埠號正確；③ 檢查節點的 `auth`/`password` 及 TLS 證書配置是否完整 | — |
| **開啟「繞過中國大陸 IP」後 Google Play 商店無法下載/更新** | 客戶端（Android 裝置） | `services.googleapis.cn` 等 Google 域名被國內 DNS 解析到中國大陸 IP（`220.181.x.x`），被 `china_ip_route` 規則匹配後走直連；但 Google 中國伺服器禁止境外 IP（代理節點）訪問，導致死迴圈 | **從 DNS 和規則兩方面同時入手**：<br><br>**① DNS 層面** — 在「覆寫設定→DNS→自定義 DNS 設定」中配置 `nameserver-policy` 強制 Google 域名走境外 DNS 解析，寫入 YAML 的 `dns.nameserver-policy` 段：<br>```yaml<br>dns:<br>  nameserver-policy:<br>    '+.services.googleapis.cn': 'https://dns.google/dns-query'<br>    '+.googleapis.cn': 'https://dns.google/dns-query'<br>    '+.xn--ngstr-lra8j.com': 'https://dns.google/dns-query'<br>```<br>也可用 `8.8.8.8` 或 `1.1.1.1` 替代 `https://dns.google/dns-query`。效果：域名解析到 Google 境外 IP（如 `142.250.x.x`），而非國內 `220.181.x.x`。<br><br>**② 規則層面** — 在「覆寫設定→規則→自定義規則」中新增，寫入 YAML 的 `rules` 段：<br>```yaml<br>rules:<br>  - DOMAIN-SUFFIX,services.googleapis.cn,Proxy<br>  - DOMAIN-SUFFIX,googleapis.cn,Proxy<br>  - DOMAIN-SUFFIX,xn--ngstr-lra8j.com,Proxy<br>```<br>其中 `Proxy` 替換為你的代理策略組名。更徹底的方式：`GEOSITE,google,Proxy` 將全部 Google 流量走代理。<br><br>**驗證**：終端執行 `dig services.googleapis.cn @127.0.0.1 -p 7874` 應返回境外 IP；在 zashboard 連線日誌中確認域名命中代理規則。 | [#5074](https://github.com/vernesong/OpenClash/issues/5074) |

### 十五、執行時狀態異常

| 錯誤關鍵字 | 問題位置 | 原因 | 排查方法 | 來源 |
|-----------|---------|------|----------|------|
| **節點正常，突然無法訪問外網** | 「執行狀態」一切正常但客戶端無網路 | DNS 劫持失效（dnsmasq 被其他外掛修改）、防火牆規則亂序、TUN 路由表丟失 | ①「執行狀態」確認核心和 DNS 埠正常；② 在「執行日誌」中檢查最近的錯誤；③「執行狀態」點選「Reload Firewall (重置防火牆)」重建規則；④ 檢查是否同時執行其他代理/DNS 外掛（如 AdGuard Home、PassWall、SSR-Plus 等），OpenClash 不能與這些外掛共存 | [#3516](https://github.com/vernesong/OpenClash/issues/3516) |
| **防火牆 DNS 劫持規則不停被還原** | 「執行日誌」反覆出現防火牆過載記錄 | 看門狗檢測到規則異常後自動過載，形成迴圈（v0.46.001-beta 已知問題） | ① 更新到最新版本（已在後續版本修復）；② 臨時關閉看門狗自動修復（編輯 `openclash_watchdog.sh` 註釋掉防火牆過載部分）；③ 檢查是否有其他程式在修改防火牆規則（如 Docker、UPnP 服務） | [#3765](https://github.com/vernesong/OpenClash/issues/3765) |

### 十六、旁路由 / 特定裝置異常

| 錯誤關鍵字 | 問題位置 | 原因 | 排查方法 | 來源 |
|-----------|---------|------|----------|------|
| 旁路由 R2S 等 ARM 裝置 iPhone 待機耗電嚴重 | 區域網 | 代理模式下 ARP 代理或 TUN 模式的 keepalive 導致 iPhone 頻繁被喚醒 | ① 嘗試切換為 Fake-IP 模式；② 關閉「僅允許內網 (Only Intranet Allowed)」以外的 WAN 口訪問；③ 主路由 DHCP 下發的閘道器和 DNS 指向旁路由 IP | [#2614](https://github.com/vernesong/OpenClash/issues/2614) |
| 在 Fake-IP 模式下無法使用 UU 加速器等遊戲加速軟體 | 「執行狀態」 | 遊戲加速器需要真實 DNS 解析來最佳化連線，Fake-IP 返回虛擬 IP 導致失效 | ① 在「覆寫設定→DNS」的 fake-ip-filter 中新增加速器相關域名（如 `+.leigod.com`、`+.vivox.com`）；② 將加速器所在裝置的 IP 加入「不走代理的區域網裝置 IP (LAN Bypassed Host List)」 | [#1751](https://github.com/vernesong/OpenClash/issues/1751) |

---

# 第一部分：執行狀態頁面 (Overviews / client)

> LuCI 路徑: `服務` → `OpenClash` → `執行狀態`
> 資料來源: 前端 JS 同時請求多個後端端點：`/status` (執行狀態、儀表盤設定)、`/toolbar_show` (流量統計)、`/update` (本機配置與已裝版本)、`/last_version` (遠端最新版本)、`/oc_settings` (快捷設定)、`/rule_mode` (代理模式)、`/config_file_list` (配置檔案列表) 等。**版本資訊拆分為兩個端點**：`/update` (action_update) 返回本機配置（corever/release_branch/smart_enable 等）與已裝版本（coremetacv/opcv），**不含遠端最新**；遠端最新版本 `corelv`/`oplv` 由獨立 `/last_version` 端點 (action_last_version) 返回（status 頁「新版本可用」紅點據此顯示），均非 `/status` 端點。`/status` 僅返回執行狀態布林值、儀表盤可用性和 core_type，不包含版本號。

## 1.1 核心控制卡片

| 元素 | 功能 | 後端操作 |
|------|------|----------|
| **啟動/停止開關** | 切換核心執行狀態 | 呼叫 `action_oc_action` → `/etc/init.d/openclash start/stop` |
| **重啟按鈕** | 重啟核心 | 呼叫 `/etc/init.d/openclash restart` |
| **覆寫模組按鈕** | 在執行狀態頁彈出覆寫編輯器（與選單「服務→OpenClash→覆寫設定」獨立） | 呼叫 `editOverwrite()` → 在執行狀態頁彈出覆寫編輯模態框 |
| **外掛/核心版本** | 顯示當前版本號 + 更新紅點 | 已裝版本: 核心執行 `/etc/openclash/core/clash_meta -v` 解析輸出、外掛讀取 opkg/apk 包資料庫，經 `/update` 端點展示; 遠端最新: Lua `fetch_version_history` 拉取並快取（核心 `/tmp/clash_last_version` / 外掛 `/tmp/openclash_last_version`，Lua 側另有 `/tmp/openclash_version_history_<branch>.json` JSON 快取），經獨立 `/last_version` 端點 (action_last_version) 獲取並據此顯示「新版本可用」紅點，均非 `/status` 端點 |
| **主題切換** | Light(太陽)/Dark(月亮)/Auto(自動) 三檔切換 | 前端 CSS 變數 + localStorage |
| **公告橫幅** | 滾動顯示專案公告 (24h 快取) | `/announcement` 端點 |
| **社交連結** | Wiki / Tutorials / Star / Telegram / Sponsor / Mihomo 圖示 | 外部連結 `window.open()` |
| **開發者頭像** | 13 位貢獻者頭像網格 (懸停顯示名稱) | 來自 GitHub 頭像 URL |

## 1.2 執行模式卡片 (Running Mode)

| 模式 | UCI `en_mode` 值 | 說明 |
|------|-----------------|------|
| **相容 (Compat)** | `redir-host` | Redir-Host 模式，使用 iptables redirect 轉發流量 |
| **TUN 模式** | `redir-host-tun` / `fake-ip-tun` | 使用 TUN 虛擬網絡卡接管所有流量 |
| **混合 (Mix)** | `redir-host-mix` / `fake-ip-mix` | TUN + Redirect 混合，TCP 走 system 棧、UDP 走 gvisor 棧 |

> 切換觸發: `action_switch_run_mode` → 修改 UCI `en_mode`，若執行中則自動重啟

## 1.3 代理模式卡片 (Proxy Mode)

| 模式 | Mihomo `mode` 值 | 效果 |
|------|-----------------|------|
| **策略代理 (Rule)** | `rule` | 按 YAML 中 `rules:` 規則集合分流 |
| **全域性代理 (Global)** | `global` | 所有流量走 GLOBAL 策略組所選代理 |
| **全域性直連 (Direct)** | `direct` | 所有流量直連，不經過任何代理 |

> 切換觸發: `action_switch_rule_mode` → PATCH Mihomo API `/configs` 的 `mode` 欄位，同時更新 UCI `proxy_mode`

## 1.4 快捷設定網格

| 設定項 | 功能 | UCI 選項 | 觸發函式 |
|--------|------|----------|----------|
| **地區繞行 (Area Bypass)** | 切換中國 IP/海外繞行 | `china_ip_route` (0/1/2) | `action_switch_oc_setting` → 修改 UCI + 重啟 |
| **域名嗅探 (Sniffer)** | 是否啟用 Mihomo 域名嗅探 | `enable_meta_sniffer` | `action_switch_oc_setting` → 動態修改執行時 YAML `sniffer.enable` |
| **DNS 尊重規則 (DNS Proxy)** | DNS 查詢是否遵守路由規則 | `enable_respect_rules` | `action_switch_oc_setting` → 動態修改 YAML `dns.respect-rules` |
| **流媒體解鎖 (Stream Unlock)** | 一鍵啟用流媒體解鎖 | `stream_auto_select` | `action_switch_oc_setting` → 設定 `stream_auto_select=1` 及 Netflix/Disney/HBO 預設引數 |

## 1.5 配置檔案卡片

| 操作 | 功能 | 後端路由 |
|------|------|----------|
| **配置檔案選擇器** | 下拉切換當前使用的 YAML 配置 | `action_switch_config` → 更新 `config_path` + 自動重啟 |
| **切換 (Switch)** | 切換到選中的配置 | 同上 |
| **更新配置** | 重新下載訂閱並更新 | `action_update_config` → 呼叫 `openclash.sh` |
| **編輯 (Edit)** | 線上編輯 YAML 配置檔案 | 彈出 `config_edit` 模態框 (基於 CodeMirror，支援原始/執行時檢視切換、合併檢視對比、覆寫卡片欄) |
| **編輯訂閱** | 修改該配置的訂閱引數 | 跳轉到 `config-subscribe-edit` |
| **上傳** | 上傳新的 YAML 配置檔案 | 彈出 `config_upload` 模態框 (支援檔案上傳 + 訂閱連結兩個標籤頁) |
| **重新整理訂閱按鈕** | 手動重新整理當前配置的訂閱資訊 | `/sub_info_get` 端點 |
| **指定 URL 按鈕** | 設定訂閱資訊查詢 URL | `/set_subinfo_url` 端點 |
| **訂閱進度條** | 顯示訂閱流量使用情況 (已用/總量/百分比) | `/sub_info_get` 自動輪詢 |

## 1.6 控制面板卡片

顯示當前 Dashboard 訪問地址及 Secret 密碼。對應 UCI:
- `cn_port` — API 埠 (預設 9090)，對應 Mihomo `external-controller`
- `dashboard_password` — API 金鑰，對應 Mihomo `secret`
- `dashboard_forward_domain` / `dashboard_forward_port` / `dashboard_forward_ssl` — 公網訪問設定
- 提供 **複製 IP** 和 **複製金鑰** 按鈕

## 1.7 混合代理卡片

顯示 SOCKS5/HTTP 代理地址，可複製或生成 PAC 檔案：
- `mixed_port` (預設 7893), `http_port` (7890), `socks_port` (7891)
- 使用者認證: `authentication` TypedSection 中的 `username`/`password`，對應 Mihomo `authentication` 配置
- 提供 **複製代理地址**、**複製認證資訊**、**生成 PAC 配置** 按鈕

## 1.8 儀表盤入口 (Control Panel)

4 種可選儀表盤：**Dashboard** (Yacd)、**Yacd**、**Metacubexd**、**Zashboard**
- 對應 Mihomo `external-ui` 配置
- 切換觸發: `action_switch_dashboard` → `openclash_download_dashboard.sh`
- 預設儀表盤: UCI `default_dashboard`
- **前端訪問地址**（`status.htm` JS 按 3 種場景構造）：
  - **本地訪問**（瀏覽器 hostname 匹配 LAN IP）：`http://<lan_ip>:<cn_port>/ui/<dashboard>/`
  - **公網訪問**（設定了 `dashboard_forward_domain` + `dashboard_forward_port`）：`http[s]://<domain>:<port>/ui/<dashboard>/`（協議由 `dashboard_forward_ssl` 決定）
  - **其他情況**：取當前頁面協議 + `lan_ip` + `cn_port`
- 各儀表盤子路徑：`/ui/dashboard/`、`/ui/yacd/`、`/ui/metacubexd/`、`/ui/zashboard/`

## 1.9 快捷操作按鈕 (Quick Action)

| 操作 | 功能 | 後端 |
|------|------|------|
| **關閉連結 (Close Connect)** | 斷開所有代理連線 | `openclash_history_get.sh 'close_all_conection'` |
| **重置防火牆 (Reload Firewall)** | 重新應用 iptables/nftables 規則 | `/etc/init.d/openclash reload 'manual'` |
| **清空 DNS 快取** | 重新整理 Fake-IP 和 DNS 快取 | POST `/cache/fakeip/flush` + `/cache/dns/flush` |
| **檢查更新 (Check Update)** | 同時更新外掛 + 核心 + 訂閱 + GEO | `openclash_update.sh 'one_key_update'` |

## 1.10 統計資訊

頁面底部顯示 8 項實時統計指標，透過 WebSocket 和 XHR 輪詢更新：

| 指標 | 說明 |
|------|------|
| 上行速率 | 當前上傳速率 |
| 下行速率 | 當前下載速率 |
| 上行總量 | 累計上傳流量 |
| 下行總量 | 累計下載流量 |
| 連線數 | 當前活動連線數 |
| 記憶體 | 核心記憶體佔用 |
| CPU | 核心 CPU 佔用 |
| 平均負載 | 系統平均負載 |

## 1.11 IP 檢測頁 (IP Address / 訪問檢查)

**IP 地址部分 (IP Address)**：
- 並行查詢 4 個 IP 源：UpaiYun、IPIP.NET、IP.SB、IPIFY，每個顯示 IP 地址 + 地理資訊
- 隱私切換按鈕（眼睛圖示）：點選後用 `***.***.***.***` 隱藏所有 IP 顯示（狀態持久化到 localStorage）

**訪問檢測部分 (Access Check)**：
- 兩種檢測模式：路由器模式（後端 XHR 代理檢測）和瀏覽器模式（前端 fetch 直接檢測），透過模式切換圖示切換
- 4 個網站可達性檢測：**Baidu Search** (百度搜尋)、**NetEase Music** (網易雲音樂)、GitHub、YouTube，各顯示 HTTP 狀態碼和載入延遲（ms）
- 重新整理按鈕：重新執行所有 IP 查詢和 HTTP 檢測

**輪詢間隔**: HTTP 檢測 5-20 秒，IP 檢測 15-40 秒。

## 1.12 oixCloud 面板 (oixCloud)

僅在設定了 `oix_token` 時顯示，展示 oixCloud 訂閱服務資訊：

- **Logo + 標語**（隨機變化）
- **公告橫幅**（60 秒後自動消失）
- **計劃資訊**：計劃型別、到期時間、賬戶餘額、推廣餘額、積分
- **流量統計**：今日已用、計劃已用、剩餘流量、總流量
- **簽到按鈕**：每日簽到獲取流量
- **底部連結**："Powered by oixcloud.com"

> 登入入口：在「外掛設定 → oixCloud」標籤頁中透過 Login Account 按鈕登入。

---

# 第二部分：外掛設定頁面 (Plugin Settings / settings)

> UCI Section: `openclash` (anonymous section)
> 所有選項透過 `uci set openclash.@openclash[0].<option>=<value>` 設定

## 實現總覽

外掛設定頁的選項透過以下路徑生效：

```
 UCI 寫入 → init.d start_service() → get_config() 讀取所有 UCI 變數
                                            │
                    ┌───────────────────────┼───────────────────────┐
                    ▼                       ▼                       ▼
            yml_change.sh           set_firewall()          change_dnsmasq()
         (修改 YAML 配置)         (iptables/nftables)      (DNS 劫持轉發)
                    │                       │                       │
                    ▼                       ▼                       ▼
              Mihomo 核心              系統防火牆規則            Dnsmasq → Clash DNS
```

| 指令碼 | 輸入 | 輸出 | 負責的設定 |
|------|------|------|-----------|
| `yml_change.sh` | ~48 個 UCI 引數 | 修改執行 YAML | 埠、模式、DNS、TUN、Sniffer、認證、Meta、GEO、Smart |
| `yml_rules_change.sh` | UCI 覆寫 + 自定義規則 | 修改執行 YAML | URL-Test 覆寫、GitHub CDN、自定義規則注入、BT 直連規則 |
| `set_firewall()` | 所有流量控制 UCI | iptables/nftables 規則 | 透明代理、黑白名單訪問控制、中國 IP 繞行、QUIC 阻斷、UPNP 排除 |
| `change_dnsmasq()` | DNS 相關 UCI | dnsmasq 配置修改 | DNS 劫持轉發、自定義域名 DNS、chnroute 旁路 |

### 外掛強制覆蓋/禁用的設定（使用者不可修改）

> **重要**：以下設定由 `yml_change.sh` 在每次啟動時**無條件硬編碼**寫入 YAML，使用者在 LuCI 中**無法修改或關閉**。但可以透過覆寫模組的 `[YAML]` 段和 `[Overwrite]` 段嘗試覆蓋，外掛不保證覆寫後的效果及工作邏輯正常。

| 強制設定 | 硬編碼值 | 說明 |
|----------|----------|------|
| `allow-lan` | `true` | 始終允許區域網裝置使用代理埠 |
| `bind-address` | `*` | 始終監聽所有網路介面 |
| `external-controller` | `0.0.0.0:<cn_port>` | API 始終監聽所有介面 (非僅 127.0.0.1) |
| `external-ui` | `/usr/share/openclash/ui` | Dashboard 路徑不可更改 |
| `dns.listen` | `0.0.0.0:<dns_port>` | DNS 始終監聽所有介面 |
| `profile.store-selected` | `true` | 始終儲存策略組選擇狀態 |
| `sniffer.sniff` | HTTP:80,8080-8880 / TLS:443,8443 / QUIC:443 | 嗅探埠不可修改 |
| `sniffer.override-destination` | `true` | 始終用嗅探結果覆蓋連線目標 |
| `sniffer.force-domain` | `netflix, nflxvideo, amazonaws, media.dssott.com` | 強制嗅探的流媒體域名 |
| `sniffer.skip-domain` | `Mijia Cloud, dlg.io.mi.com, +.oray.com, +.sunlogin.net, +.push.apple.com` | 跳過嗅探的智慧家居/推送域名 |
| `sniffer.force-dns-mapping` | `true` (Redir-Host 時) | Redir-Host 模式下強制 DNS 對映嗅探 |
| `iptables` | **刪除** | 強制移除 iptables 相關配置 |
| `ebpf` | **刪除** | 強制移除 eBPF 相關配置 |
| `auto-redir` | **刪除** | 強制移除 auto-redir（由 OpenClash 防火牆管理） |
| `routing-mark` | `6666` (非自定義標記時) | 固定路由標記值 |
| `external-controller-cors.allow-private-network` | `true` (有 CORS origin 時) | 允許私有網路訪問 API |

**有條件預設設定**（僅在使用者未配置時自動新增）：

| 設定 | 預設值 | 條件 |
|------|--------|------|
| `keep-alive-interval` | `15` | 僅當配置中未設定 |
| `keep-alive-idle` | `600` | 僅當配置中未設定 |
| `ntp.enable` | `true` | 僅當配置中未設定 |
| `ntp.server` | `time.apple.com` | 僅當配置中未設定 |
| `ntp.port` | `123` | 僅當配置中未設定 |
| `ntp.interval` | `30` (分鐘) | 僅當配置中未設定 |
| `ntp.write-to-system` | `true` | 僅當配置中未設定 |

**防火牆固定值**（硬編碼在 `init.d/openclash` 中）：

| 常量 | 值 | 說明 |
|------|-----|------|
| `PROXY_FWMARK` | `0x162` | 所有被代理流量的防火牆標記，不可修改 |
| `PROXY_ROUTE_TABLE` | `0x162` | 策略路由表 ID，不可修改 |
| `SKIP_GROUP` | `65534` | 繞過代理的組 ID (skgid) |

**核心模組依賴**（缺少時會導致啟動報錯）：

| 執行模式 | fw4 (nftables) 需要的 kmod | fw3 (iptables) 需要的 kmod |
|----------|---------------------------|---------------------------|
| Redir-Host / Fake-IP (非TUN) | `kmod-nft-tproxy` | `kmod-ipt-tproxy` |
| TUN 模式 | `kmod-tun` + `kmod-nft-tproxy` | `kmod-tun` + `kmod-ipt-tproxy` |
| 混合模式 (Mix) | `kmod-tun` + `kmod-nft-tproxy` | `kmod-tun` + `kmod-ipt-tproxy` |

> **故障排查**：如果啟動日誌提示 "nft_tproxy module not found"，請在 LuCI 的「系統 → 軟體包」中搜尋安裝 `kmod-nft-tproxy`；提示 "xt_TPROXY module not found"，安裝 `kmod-ipt-tproxy`。TUN 模式還需 `kmod-tun`（同樣在 LuCI 軟體包頁面安裝）。注意 fw4 環境下應檢查 `nft_tproxy` 而非 `xt_TPROXY`。

## 2.1 模式設定標籤頁 (op_mode)

### en_mode — 選擇執行模式 (Select Mode)
- **UCI 選項**: `openclash.@openclash[0].en_mode`
- **可選值**:
  - `redir-host` — 相容模式 (Redir-Host)
  - `redir-host-tun` — 相容模式 (TUN)
  - `redir-host-mix` — 相容模式 (混合)
  - `fake-ip` — Fake-IP 模式
  - `fake-ip-tun` — Fake-IP (TUN)
  - `fake-ip-mix` — Fake-IP (混合)
- **Mihomo 對應配置**: `dns.enhanced-mode` (fake-ip / redir-host)
- **Redir-Host 模式**: DNS 解析在客戶端完成，核心根據 IP 規則分流。適合 BT/PT 下載
- **Fake-IP 模式**: DNS 解析在核心完成，返回虛假 IP (198.18.x.x)，效能更高。規則基於域名匹配。**推薦作為日常使用首選**：Fake-IP（增強）模式下 TCP/UDP 均走系統協議棧，效能最優；若出現 NAT 問題可切換為 Fake-IP（混合）模式；若韌體含 Docker 則直接選用 Fake-IP（TUN）模式
- **TUN 模式**: 建立虛擬網絡卡，以網路層接管所有流量。對應 Mihomo `tun.enable=true`。需要 `kmod-tun` 核心模組
- **混合模式**: TCP 使用 system 棧 (redirect)，UDP 使用 gvisor 棧 (TUN)。對應 Mihomo `tun.stack=mixed`。適合非直連遊戲等對 NAT 型別有要求的場景

### stack_type — TUN 堆疊型別 (Stack Type)
- **UCI 選項**: `openclash.@openclash[0].stack_type`
- **可選值**: `system` / `gvisor` / `mixed`
- **Mihomo 對應配置**: `tun.stack`
- **system**: 使用 Linux 系統協議棧，效能和穩定性最好
- **gvisor**: 使用者空間網路協議棧，隔離性更好，避免核心態/使用者態切換
- **mixed**: TCP 用 system、UDP 用 gvisor
- **依賴**: 僅在 TUN/混合模式下顯示

### proxy_mode — 代理模式 (Proxy Mode)
- **UCI 選項**: `openclash.@openclash[0].proxy_mode`
- **可選值**: `rule` / `global` / `direct`
- **Mihomo 對應配置**: `mode`
- **預設**: `rule`
- 此選項等同一鍵切換全域性/規則/直連模式

### enable_udp_proxy — UDP 流量轉發 (Proxy UDP Traffics)
- **UCI 選項**: `openclash.@openclash[0].enable_udp_proxy`
- **預設**: 1 (開啟)
- **說明**: 節點需支援 UDP 轉發。Docker 環境可能導致 UDP 異常
- **依賴**: 僅 Redir-Host 模式顯示
- **注意**: Fake-IP 模式即使關閉此選項，域名類 UDP 連線仍會經過核心

### delay_start — 延遲啟動（秒） (Delay Start)
- **UCI 選項**: `openclash.@openclash[0].delay_start`
- **預設**: 0 (不延遲)
- **說明**: 開機後延遲指定秒數再啟動 OpenClash

### log_size — 日誌大小（KB） (Log Size)
- **UCI 選項**: `openclash.@openclash[0].log_size`
- **預設**: 1024 (1MB)
- **說明**: 核心日誌檔案 `/tmp/openclash.log` 的最大大小

### bypass_gateway_compatible — 旁路閘道器（旁路由）相容 (Bypass Gateway Compatible)
- **UCI 選項**: `openclash.@openclash[0].bypass_gateway_compatible`
- **預設**: 0 (關閉)
- **說明**: 旁路由 (旁路閘道器) 模式下無法上網時嘗試開啟。如果裝置沒有 WLAN，建議禁用 LAN 介面的橋接選項

### disable_quic_go_gso — 禁用 quic-go GSO (Disable QUIC Go GSO)
- **UCI 選項**: `openclash.@openclash[0].disable_quic_go_gso`
- **預設**: 0 (關閉)
- **說明**: Linux 核心 6.6 以上版本遇到 QUIC UDP 問題時嘗試開啟。**Hysteria / Hysteria2 / TUIC 等基於 QUIC 協議的節點出現連線超時、斷流、握手失敗時，優先嚐試開啟此選項**
- **Mihomo 對應配置**: `disable-quic-go-gso` (全域性 experimental 選項，寫入 YAML 的 `experimental.disable-quic-go-gso: true`)

### small_flash_memory — 小快閃記憶體模式 (Small Flash Memory)
- **UCI 選項**: `openclash.@openclash[0].small_flash_memory`
- **預設**: 0 (關閉)
- **說明**: 將核心和 GEOIP 資料檔案移到 `/tmp/etc/openclash`，節省快閃記憶體空間。路由重啟後需重新下載

> **AI 行為指引 — QUIC 類節點（Hysteria / Hysteria2 / TUIC）故障排查**: 當使用者報告 Hysteria、Hysteria2、TUIC 等基於 QUIC 協議的節點無法連線、頻繁斷流或握手超時時，AI 應先讓使用者生成除錯日誌檢視核心日誌中的 QUIC 相關錯誤。如日誌含 `quic-go` / `GSO` / `timeout` 等關鍵字，**優先建議**使用者在「外掛設定→模式設定」中開啟「禁用 quic-go GSO (Disable QUIC Go GSO)」選項並重啟 OpenClash。這是 Linux 核心 ≥6.6 上最常見的 QUIC 相容性問題。
>
> **關於 `disable_udp_quic`（禁用 QUIC）**：此選項**不會**影響 Mihomo 核心自身的 Hysteria/Hysteria2/TUIC 等 QUIC 出站連線，無需因使用此類節點而關閉該選項。原因：所有模式（TUN/非TUN）下 QUIC REJECT 規則均在 filter INPUT 鏈 + IPv6 TUN 模式下額外在 FORWARD -o utun 鏈，Mihomo 核心自身出站 QUIC 走 OUTPUT 鏈，回覆包的目標埠為臨時埠（非 443），均不命中攔截規則。`disable_udp_quic` 的目的是讓 LAN 客戶端的 YouTube 等 QUIC 流量降級到 TCP 以便代理，與核心節點通訊無關。
>
> 若 GSO 選項開啟後問題仍存在，建議查閱 [Mihomo Wiki Hysteria 配置](https://wiki.metacubex.one/config/proxies/hysteria/) 或 [Hysteria2 配置](https://wiki.metacubex.one/config/proxies/hysteria2/) 驗證節點欄位是否正確。

### 執行模式切換按鈕 (switch_mode)
- **模板**: `openclash/switch_mode`
- **功能**: 一鍵在 Redir-Host 和 Fake-IP 之間切換當前頁面顯示
- **觸發**: `action_switch_mode` → 修改 UCI `operation_mode`

### 執行模式實現詳解

**啟動流程中的關鍵變數傳遞** (來自 `init.d start_service()`):
1. `get_config()` 讀取 UCI `en_mode`，解析出 `en_mode_tun`（TUN 標記）、`en_mode_fakeip`（Fake-IP 標記）、`en_mode_mix`（混合標記）
2. 將這些傳遞給 `yml_change.sh` 作為位置引數：
   - `$1` = DNS enhanced-mode 值（`fake-ip` 或 `redir-host`）
   - `$11` = en_mode_tun（0/1/2，決定是否啟用 TUN）
   - `$12` = stack_type 或 `$30`（TUN 堆疊型別回退）

**yml_change.sh 中 `en_mode` 的 YAML 影響鏈**:
- **dns.enhanced-mode**: 根據 Fake-IP / Redir-Host 設定 → 影響 Mihomo 的 DNS 解析策略：
  - `fake-ip`: 所有 DNS 查詢返回 198.18.x.x 假 IP，規則基於域名匹配，效能最優
  - `redir-host`: DNS 在客戶端完成，規則基於真實 IP 匹配，適合 BT/PT
- **tun.enable**: `en_mode_tun != 0` 時設為 `true` → Mihomo 建立 `utun` 虛擬網絡卡接管流量
- **tun.stack**: `system`(系統協議棧)/`gvisor`(使用者態協議棧)/`mixed`(TCP system + UDP gvisor)
  - `system`: 效能最好，走 Linux 核心 TUN 驅動
  - `gvisor`: 隔離性好，UDP NAT 支援更完善
  - `mixed`: TCP 用 system 棧 (REDIRECT)，UDP 用 gvisor 棧 (TUN)

**防火牆層面的影響** (`set_firewall()`):
- **Redir-Host (非 TUN)**: TCP 透過 REDIRECT 到 `proxy_port`(7892)，UDP 透過 TPROXY 到 `tproxy_port`(7895)，標記 fwmark 0x162
- **Fake-IP (非 TUN)**: 同上 + 額外匹配 `fakeip_range`(198.18.0.1/16) 的路由
- **TUN 模式**: 所有流量標記 0x162，路由到 `utun` 裝置（策略路由），TUN 內部處理分流
- **混合模式 (Mix)**: TUN 裝置處理 UDP（走 gvisor），TCP 走 REDIRECT（system 棧）

---

## 2.2 流量控制標籤頁 (traffic_control)

> **生效路徑**: 絕大多數流量控制選項不修改 YAML，而是影響 `set_firewall()` 生成的 iptables/nftables 規則鏈。
>
> **AI 行為指引**: 當使用者詢問流量路由問題時（如"TUN 和 TPROXY 有什麼區別"、"如何讓某裝置不走代理"、
> "旁路由/閘道器模式下如何配置"、"IPv6 流量如何控制"），AI 應結合本章節的防火牆規則詳解
> 和 [Mihomo 監聽器文件](https://wiki.metacubex.one/config/listeners/) 回答，說明不同模式
> 的工作原理（而非僅給出操作步驟），幫助使用者理解後做出選擇。
> 涉及防火牆實現細節時，查閱 [OpenClash 原始碼](https://github.com/vernesong/OpenClash/tree/dev) 中
> `init.d/openclash` 和 `yml_change.sh` 的相關邏輯。
> `set_firewall()` 透過 UCI `firewall.openclash` 註冊為 `/var/etc/openclash.include`，由 OpenWrt firewall3/firewall4 框架載入。
> 支援 fw4 (nftables) 和 fw3 (iptables) 雙後端自動檢測。
> **注意**：如需按介面/使用者/DSCP 等維度精細繞過，請使用「外掛設定頁面底部 → 來源流量訪問控制 (2.10)」。黑白名單裝置級繞過使用「外掛設定 → 黑白名單 (2.4)」。

### router_self_proxy — 路由本機代理 (Router-Self Proxy)
- **UCI 選項**: `openclash.@openclash[0].router_self_proxy`
- **預設**: 1 (開啟)
- **說明**: 開啟後，路由器本身發出的流量也會經過代理核心。僅在規則模式下生效。關閉後流媒體增強標籤頁所有功能將失效
- **實現細節**: 控制 OUTPUT 鏈規則是否生成。開啟時建立 `openclash_output` 鏈（fw4）或 OUTPUT 規則（fw3），將路由器自身出站流量重定向到 Clash。關閉時刪除 OUTPUT 鏈規則，路由器自身流量走原始路由表。

### disable_udp_quic — 禁用 QUIC (Disable QUIC)
- **UCI 選項**: `openclash.@openclash[0].disable_udp_quic`
- **預設**: 1 (開啟)
- **效果**: 對 UDP 443 埠的流量執行 REJECT，阻止 YouTube 等使用 QUIC 協議傳輸 (降級到 TCP)
- **執行方式**: 透過 iptables/nftables 規則阻斷 UDP 443，排除中國大陸 IP 段
- **實現細節**: 在 `set_firewall()` 的 `openclash_mangle` 鏈中插入規則：`meta l4proto udp th dport 443 counter reject`。但繞過 `china_ip_route_pass` ipset 中的中國 IP（透過 `ip daddr @china_ip_route_pass counter return`）。同時配合 dnsmasq 的 ipset/nftset 標記確保國內 QUIC 不受影響。

### skip_proxy_address — 繞過伺服器地址 (Skip Proxy Address)
- **UCI 選項**: `openclash.@openclash[0].skip_proxy_address`
- **預設**: 0 (關閉)
- **說明**: 繞過配置中伺服器地址的代理，防止重複代理 (代理巢狀)
- **實現細節**: 開啟後看門狗指令碼 `openclash_watchdog.sh` 中的 `skip_proxies_address()` 函式（每 30 個看門狗週期執行一次）解析 YAML 中所有代理節點（`proxies` 和 `proxy-providers`）的 `server` 地址，域名透過 `openclash_debug_dns.lua` 呼叫 Mihomo 核心 API（`/dns/query`）解析為 IP 後，加入已存在的 `localnetwork` nft set（或 ipset）。由於 `openclash` 鏈首條規則為 `ip daddr @localnetwork counter return`，這些代理伺服器 IP 自動被跳過代理，防止代理巢狀。

### common_ports — 僅允許常用埠流量 (Common Ports Proxy Mode)
- **UCI 選項**: `openclash.@openclash[0].common_ports`
- **預設**: 0 (禁用)
- **說明**: 僅對常用埠 (HTTP/HTTPS/郵件等) 進行代理，防止 BT/P2P 流量經過代理
- **預設值**: `21 22 23 53 80 123 143 194 443 465 587 853 993 995 998 2052 2053 2082 2083 2086 2095 2096 5222 5228 5229 5230 8080 8443 8880 8888 8889`
- **自定義格式**: 空格分隔的埠號，如 `443 80` 或範圍 `20-443`
- **依賴**: 僅 Redir-Host 系列模式
- **實現細節**: 非 0 時在 `openclash` redirect 鏈的埠檢查規則中使用自定義埠列表（而非預設的允許所有埠）。格式 `{tcp, udp} th dport {80, 443, ...} counter redirect to proxy_port`。禁用時規則不含埠限制，所有 TCP 都重定向。

### china_ip_route — 實驗性：繞過指定區域 IP (China IP Route)
- **UCI 選項**: `openclash.@openclash[0].china_ip_route`
- **可選值**:
  - `0` — 關閉
  - `1` — 繞過中國大陸 IP (將國內 IP 直連，提升效能)
  - `2` — 繞過海外 IP
- **說明**: 強烈推薦啟用「繞過中國大陸」。啟用後，會在 `fake-ip-filter` 新增 `rule-set:oc-cn-domain` 規則集 (舊版本為 GeoSite 資料庫中分類為 `CN` 的域名)，且解析 IP 位於大陸 IP 段範圍內的流量將不進入核心，顯著降低核心效能開銷。旁路由模式下如果遇到大陸域名無法訪問可嘗試開啟"旁路由相容"選項
- **Mihomo 對應**: 透過 `dns.fake-ip-filter` 新增 `rule-set:oc-cn-domain` 規則集，使中國大陸域名返回真實 IP 而非 Fake-IP；同時自動註冊對應的 `rule-providers` 條目指向 MetaCubeX geosite CN MRS 檔案
- **實現細節（雙重機制）**: 1) **YAML 層面**: `yml_change.sh` 修改 `dns.fake-ip-filter`——blacklist 模式（預設）追加 `rule-set:oc-cn-domain`，whitelist 模式移除 CN 相關過濾器，rule 模式前置 `RULE-SET,oc-cn-domain,real-ip`。效果：匹配的中國大陸域名返回真實 IP，繞過 Fake-IP 機制。2) **防火牆層面**: `set_firewall()` 使用 chnroute IP 列表構建 nftables set（`china_ip_route` 或者 `china_ip6_route`），在 redirect/TPROXY 鏈中匹配國內真實 IP 直連 return。兩層面互為補充——YAML fake-ip-filter 確保大陸域名獲得真實 IP，防火牆 nft set 匹配這些真實 IP 使其跳過代理。

### intranet_allowed — 僅允許內網 (Only Intranet Allowed)
- **UCI 選項**: `openclash.@openclash[0].intranet_allowed`
- **預設**: 1 (開啟)
- **說明**: 開啟後控制面板和連線代理埠僅能從內網訪問，不暴露到公網
- **Mihomo 對應**: `allow-lan: true` + `bind-address: "*"`
- **實現細節**: 雙重保護——1) YAML 層面：`yml_change.sh` 設定 `allow-lan: true` + `bind-address: "*"` 使核心監聽所有介面。2) 防火牆層面：建立 `openclash_wan_input` 鏈，匹配來自 WAN 口（非 `@localnetwork` 源 IP）的流量，REJECT 全部 7 個服務埠（`$proxy_port`/`$tproxy_port`/`$cn_port`/`$http_port`/`$socks_port`/`$mixed_port`/`$dns_port`）。關閉時 `allow-lan: false`，核心僅監聽 `127.0.0.1`，同時不建立 `openclash_wan_input` 鏈。

### intranet_allowed_wan_name — WAN 介面名稱 (WAN Interface Name)
- **UCI 選項**: `openclash.@openclash[0].intranet_allowed_wan_name`
- **說明**: 指定哪個介面被識別為 WAN。用於僅允許內網功能區分內外網
- **依賴**: `intranet_allowed=1`

### lan_interface_name — LAN 介面名稱 (LAN Interface Name)
- **UCI 選項**: `openclash.@openclash[0].lan_interface_name`
- **可選值**: 系統中所有網路介面名
- **預設**: 0 (禁用)
- **說明**: 指定 LAN 介面名稱，用於透過 `ip address show <介面>` 獲取路由器 LAN IP 地址（供控制面板地址顯示、API 呼叫、除錯日誌等使用）。設為 0 則自動檢測

### local_network_pass — 本地 IPv4 網路繞過列表 (Local Network Pass)
- **UCI 選項**: `openclash.@openclash[0].local_network_pass`
- **儲存檔案**: `/etc/openclash/custom/openclash_custom_localnetwork_ipv4.list`
- **說明**: 目標地址為列表中 IP 的流量不經過核心

### chnroute_pass — 繞過指定區域 IPv4 黑名單 (Chnroute Bypassed List)
- **UCI 選項**: `openclash.@openclash[0].chnroute_pass`
- **儲存檔案**: `/etc/openclash/custom/openclash_custom_chnroute_pass.list`
- **說明**: 列表中的域名/IP 不受中國 IP 繞行選項影響，依賴 Dnsmasq。**預設已預置** `services.googleapis.cn`、`googleapis.cn`、`xn--ngstr-lra8j.com` 以解決 Google Play 下載問題
- **依賴**: `enable_redirect_dns != 2`
- **注意**: chnroute_pass 僅在 DNS 解析層面將域名解析 IP 加入 `china_ip_route_pass` nft set 使其跳過繞行規則，但若上游 DNS 本身將這些域名解析到國內 IP，加入 set 後仍會被 `china_ip_route` 規則誤判為國內 IP 而繞行。**僅靠 chnroute_pass 不足以解決 Google Play 下載問題**——必須同時從 DNS 解析（`nameserver-policy` 強制走境外 DNS）和規則匹配（自定義規則走代理）兩方面入手，詳見錯誤速查表 §十四

### UPNP 流量排除（無 UCI 選項，自動生效）
- **觸發條件**: 系統已安裝並執行 `upnpd`（`/etc/config/upnpd` 存在且 `upnp_lease_file` 指向有效租約檔案）
- **說明**: 自動讀取 upnpd 租約檔案，為 UPnP 埠對映建立防火牆繞過規則，防止 BT/PT 下載、遊戲主機等 UDP UPnP 流量被 TPROXY 錯誤代理
- **實現細節**: 防火牆初始化階段 `set_firewall()` 建立 `openclash_upnp` 鏈並在 `openclash_mangle` 鏈中透過 `jump openclash_upnp`（規則位置在最終 TPROXY 之前）。`upnp_exclude()` 函式讀取 upnpd 租約檔案（格式 `UDP:<ext_port>:<int_ip>:<int_port>`），為每條租約在 `openclash_upnp` 鏈中新增 `ip saddr <int_ip> <proto> sport <int_port> counter return` 規則。看門狗 `openclash_watchdog.sh` 每 30 個週期（首週期立即執行，之後每 `UPNP_INTERVAL=30` 即約 30 分鐘）執行 UPNP 規則同步：① **清理過期規則**——遍歷 `openclash_upnp` 鏈現有規則，刪除租約檔案中已不存在的條目；② **新增新規則**——讀取租約檔案，為新增的 UPnP 對映補充 RETURN 規則。

---

## 2.3 DNS 設定標籤頁 (dns)

> **生效路徑**: DNS 選項透過三條路徑生效：
> 1. `yml_change.sh` 修改 YAML `dns:` 段 → Mihomo 核心使用
> 2. `change_dnsmasq()` 修改系統 dnsmasq → LAN 客戶端 DNS 被劫持到 Clash
> 3. `openclash_custom_domain_dns.sh` 為自定義域名配置獨立 DNS
>
> **AI 行為指引**: 當使用者詢問 DNS 劫持相關問題時（如"DNS 重定向模式選哪個"、"自定義上游 DNS 伺服器怎麼寫"、
> "Fake-IP 和 Redir-Host 的 DNS 行為有何不同"、"如何讓特定域名不走 Fake-IP"），AI 應結合本文件的
> 「防火牆與 DNS 規則詳解」章節和 [Mihomo DNS 配置文件](https://wiki.metacubex.one/config/dns/)
> 解釋底層原理，然後告知使用者在 LuCI 中的操作路徑。
> 涉及 dnsmasq 劫持實現時可查閱 [OpenClash 原始碼](https://github.com/vernesong/OpenClash/tree/dev) 中
> `init.d/openclash` 的 `change_dnsmasq()` 函式。對於 DNS 劫持失敗的排查，首先讓使用者檢查
> 「執行狀態」頁面檢視 DNS 埠是否在監聽。

### enable_redirect_dns — 本地 DNS 劫持 (Redirect Local DNS Setting)
- **UCI 選項**: `openclash.@openclash[0].enable_redirect_dns`
- **可選值**:
  - `0` — 禁用
  - `1` — Dnsmasq 轉發 (將 LAN 的 DNS 請求轉發給核心)
  - `2` — 防火牆重定向 (透過 iptables/nftables 劫持 53 埠)
- **預設**: 1
- **說明**:
  - **Dnsmasq 轉發** (值1): 修改 `/tmp/etc/dnsmasq.conf.*`，將上游 DNS 指向核心 DNS 埠 (`dns_port=7874`)
  - **防火牆重定向** (值2): 透過 iptables/nftables 將發往 53 埠的 UDP/TCP 流量 DNAT 到核心 DNS 埠。Fake-IP 模式下使用 LAN 訪問控制必須選此項
- **Mihomo 對應**: DNS 監聽配置 `dns.listen: 0.0.0.0:7874`
- **實現詳解**:
  - **值1 (Dnsmasq)**: `change_dnsmasq()` 函式先備份 dnsmasq 原有配置到 `openclash.config.*`，然後設定 `dhcp.@dnsmasq[0].server=127.0.0.1#<dns_port>`，`noresolv=1`，`cachesize=0`。效果：所有 LAN 客戶端的 DNS 查詢 → dnsmasq → 轉發到 Clash DNS (7874) → Clash 根據 `enhanced-mode` 處理。
  - **值2 (防火牆)**: 建立 `openclash_dns_redirect` nftables 鏈，對目標埠 53 的 UDP/TCP 流量 DNAT 到 `dns_port`。同時保留 dnsmasq 處理本地 DNS 快取。此模式允許 `lan_ac_*` 訪問控制（需要 Fake-IP 模式）。
  - **恢復**: `revert_dnsmasq()` 還原所有原始 dnsmasq 配置（servers、noresolv、resolvfile、cachesize）。

### flush_dns_cache — 清空 DNS 快取按鈕 (Flush DNS Cache)
- **模板**: `openclash/flush_dns_cache`
- **功能**: 透過 POST `/cache/fakeip/flush` + `/cache/dns/flush` API 清空 Fake-IP 和 DNS 快取

### dnsmasq_fix — Dnsmasq 修復按鈕 (Dnsmasq Fix)
- **功能**: 停止 OpenClash 後 DNS 異常時使用。恢復 Dnsmasq 預設配置:
  1. 設定 `noresolv=0`, `localuse=1`
  2. 恢復 `resolvfile` 為有效的 DNS 配置檔案
  3. 若無有效配置則建立 `/tmp/resolv.conf.d/resolv.conf.auto` (114.114.114.114, 8.8.8.8)
  4. 重啟 dnsmasq

### enable_custom_domain_dns_server — 啟用第二 DNS 伺服器 (Enable Specify DNS Server)
- **UCI 選項**: `openclash.@openclash[0].enable_custom_domain_dns_server`
- **預設**: 0
- **說明**: 為自定義域名列表指定專用 DNS 伺服器，完全獨立於核心 DNS 查詢

### custom_domain_dns_server — 指定伺服器 (Specify DNS Server)
- **UCI 選項**: `openclash.@openclash[0].custom_domain_dns_server`
- **預設**: `114.114.114.114`
- **格式**: `IP地址` 或 `IP地址#埠` (如 `127.0.0.1#5300`)

### custom_domain_dns — 自定義域名列表 (Custom Domain DNS)
- **儲存檔案**: `/etc/openclash/custom/openclash_custom_domain_dns.list`
- **格式**: 每行一個域名
- **說明**: 列表中的域名不返回 Fake-IP，使用指定的上游 DNS 伺服器解析

---

## 2.4 黑白名單標籤頁 (Black&White / lan_ac)

> **生效路徑**: 訪問控制完全在防火牆層面實現，不修改 YAML。
>
> **AI 行為指引**: 當使用者詢問訪問控制問題時（如"如何讓某個裝置不走代理"、"如何讓內網某裝置全域性代理"、
> "代理黑名單和白名單的區別"），AI 應結合本章節的防火牆規則詳解
> （特別是「各選項對防火牆規則的具體影響」表格）告知使用者各選項組合的效果。
> 涉及黑白名單匹配邏輯時，查閱 [OpenClash 原始碼](https://github.com/vernesong/OpenClash/tree/dev) 中
> `init.d/openclash` 的 `firewall_lan_ac_traffic()` 函式和 `set_firewall()` 中的 `ipset`/`nft set` 建立邏輯。
> 對於 IP 段/CIDR 的寫法問題，解釋 `192.168.1.0/24` 等標準 CIDR 格式。
> **注意**：如需按介面/使用者/DSCP 等維度精細繞過，請使用「外掛設定頁面底部 → 來源流量訪問控制 (2.10)」。
> **依賴**: `enable_redirect_dns=2`（防火牆重定向模式）僅在 **Fake-IP 模式**下強制要求——因為 Fake-IP 返回虛擬 IP，客戶端不知道真實目標，
> 必須透過防火牆重定向 DNS 才能實現基於真實目標的訪問控制。Redir-Host 模式下此依賴為可選（LuCI UI 中同樣要求，但底層機制不同）。

### lan_ac_mode — 區域網訪問控制模式 (LAN Access Control Mode)
- **UCI 選項**: `openclash.@openclash[0].lan_ac_mode`
- **可選值**: `0` (黑名單模式) / `1` (白名單模式)
- **預設**: 0
- **說明**:
  - **黑名單模式**: 列表中的裝置/主機不走代理 (直連)
  - **白名單模式**: 只有列表中的裝置/主機走代理
- **依賴**: `enable_redirect_dns=2` (僅防火牆重定向模式) + Redir-Host 系列模式
- **實現細節**: 系統使用 `ebtables` 或 `nft` 在二層網橋層面匹配 MAC 地址，使用 `nftables` 在三層匹配 IP。黑白名單決定規則的 return 行為取反（黑名單=匹配到return直連，白名單=不匹配則return直連）。

### lan_ac_black_ips — 不走代理的區域網裝置 IP (LAN Bypassed Host List)
- **UCI 選項**: `openclash.@openclash[0].lan_ac_black_ips` (DynamicList)
- **格式**: IP 地址或 CIDR 網段
- **依賴**: `lan_ac_mode=0`
- **實現細節**: 生成 nftables set `openclash_lan_black_ip` / `openclash_lan_black_ip6`，在 `openclash` redirect 鏈中插入 `ip saddr @openclash_lan_black_ip counter return` 跳過規則。

### lan_ac_black_macs — 不走代理的區域網裝置 Mac (LAN Bypassed Mac List)
- **UCI 選項**: `openclash.@openclash[0].lan_ac_black_macs` (DynamicList)
- **格式**: MAC 地址
- **實現細節**: 透過 `ebtables`（fw3）或 `nft add rule bridge`（fw4）在 br-lan 網橋上匹配源 MAC，匹配到的流量不進入 Clash 代理鏈。

### lan_ac_white_ips — 走代理的區域網裝置 IP (LAN Proxied Host List)
- **UCI 選項**: `openclash.@openclash[0].lan_ac_white_ips`
- **依賴**: `lan_ac_mode=1`

### lan_ac_white_macs — 走代理的區域網裝置 Mac (LAN Proxied Mac List)
- **UCI 選項**: `openclash.@openclash[0].lan_ac_white_macs`

### wan_ac_black_ips — 不走代理的 WAN IP (WAN Bypassed Host List)
- **UCI 選項**: `openclash.@openclash[0].wan_ac_black_ips`
- **說明**: Fake-IP 模式下僅支援純 IP 請求，域名請求需先設定 Fake-IP-Filter

### wan_ac_black_ports — 不走代理的 WAN 埠 (WAN Bypassed Port List)
- **UCI 選項**: `openclash.@openclash[0].wan_ac_black_ports`
- **格式**: 埠號或埠範圍

---

## 2.5 流媒體增強標籤頁 (stream_enhance)

> **生效路徑**: `openclash_streaming_unlock.lua` 指令碼在核心啟動後被守護程序呼叫，
> 定期測試各流媒體服務的解鎖情況，自動將策略組切換到支援該服務的節點。
>
> **AI 行為指引**: 當使用者詢問流媒體相關問題時（如"如何解鎖 Netflix/Disney+"、"Bilibili 地區選項代表什麼"、
> "如何新增新的流媒體服務"、"Group Filter 正則怎麼寫"），AI 應查閱 [Mihomo 規則文件](https://wiki.metacubex.one/config/rules/)
> 瞭解 GEOSITE/RULE-SET 等規則型別，並結合 OpenClash 的流媒體增強設定告知使用者具體配置步驟。
> 涉及流媒體解鎖檢測邏輯時，查閱 [OpenClash 原始碼](https://github.com/vernesong/OpenClash/tree/dev) 中
> `openclash_streaming_unlock.lua` 指令碼。
> 注意：`openclash_streaming_unlock.lua` 僅負責已配置服務的節點測試和自動切換，不負責 Smart 策略。

所有子選項依賴 `stream_auto_select=1`。每個流媒體服務有一組獨立配置：

| 服務 | 啟用 UCI | 預設 | 說明 |
|------|----------|------|------|
| Netflix | `stream_auto_select_netflix` | 0 | 啟用後自動選擇支援 Netflix 的節點 |
| Disney Plus | `stream_auto_select_disney_plus` | 0 | |
| HBO Max | `stream_auto_select_hbo_max` | 0 | |
| YouTube | `stream_auto_select_youtube` | 0 | |
| Prime Video | `stream_auto_select_prime_video` | 0 | |
| Paramount Plus | `stream_auto_select_paramount_plus` | 0 | |
| Discovery Plus | `stream_auto_select_discovery_plus` | 0 | |
| Bilibili | `stream_auto_select_bilibili` | 0 | 解鎖地區選項：CN(僅大陸)/HK/MO/TW/TW(僅臺灣) |
| Google Not CN | `stream_auto_select_google_not_cn` | 0 | 自動選擇非中國 Google 節點 |
| OpenAI | `stream_auto_select_openai` | 0 | |
| Claude | `stream_auto_select_claude` | 0 | |
| Gemini | `stream_auto_select_gemini` | 0 | |

每個服務配置項：
- **策略組篩選 (Group Filter)**: `stream_auto_select_group_key_<service>` — 匹配策略組的正規表示式
- **解鎖區域篩選 (Unlock Region Filter)**: `stream_auto_select_region_key_<service>` — 解鎖地區國家縮寫
- **解鎖節點篩選 (Unlock Nodes Filter)**: `stream_auto_select_node_key_<service>` — 節點名稱正則過濾
- **手動測試按鈕**: 呼叫 `openclash_streaming_unlock.lua` 執行解鎖測試
- **實現詳解**: `openclash_streaming_unlock.lua` 是一個獨立 Lua 指令碼，被 `/etc/init.d/openclash` 以 `procd` 服務形式啟動（與核心並列）。工作流程：
  1. 讀取 YAML 中所有策略組和節點，構建節點-策略組對映
  2. 對每個啟用的流媒體服務，嘗試用各節點連線服務域名（如 `netflix.com`）
  3. 檢查 HTTP 響應碼或頁面內容判斷是否解鎖（如 Netflix 返回 200 且不含地區限制頁面則解鎖）
  4. 找到能解鎖的節點後，透過 Mihomo API `PUT /proxies/{group}` 自動切換策略組到該節點
  5. 定期重新測試（間隔可配置），節點失效時自動切換

---

## 2.6 外部控制標籤頁 (Dashboard Settings / dashboard)

> **生效路徑**: 儀表盤選項寫入 YAML 的 `external-controller`、`secret`、`external-ui` 等欄位，
> 由 Mihomo 核心直接讀取並提供 HTTP API。下載/切換透過 `openclash_download_dashboard.sh` 執行。

| 選項 | UCI Key | 預設 | 說明 |
|------|---------|------|------|
| 管理頁面埠 (Dashboard Port) | `cn_port` | 9090 | 對應 Mihomo `external-controller: 0.0.0.0:9090` |
| 管理頁面登入金鑰 (Dashboard Secret) | `dashboard_password` | 空 | 對應 Mihomo `secret`，留空則不驗證 |
| 管理頁面公網域名 (Public Dashboard Address) | `dashboard_forward_domain` | 空 | 用於公網訪問面板 |
| 管理頁面對映埠 (Public Dashboard Port) | `dashboard_forward_port` | 空 | |
| 管理頁面公網 SSL 訪問 (Public Dashboard SSL enabled) | `dashboard_forward_ssl` | 0 | |

儀表盤版本管理透過 `action_switch_dashboard` → `openclash_download_dashboard.sh` 自動下載切換。
- **實現細節**: `yml_change.sh` 將 `cn_port`、`dashboard_password` 寫入 YAML → Mihomo 核心啟動 HTTP API。`openclash_download_dashboard.sh` 從 GitHub Releases 下載 Dashboard 靜態檔案 (yacd/metacubexd/zashboard)，解壓到 `/usr/share/openclash/ui`。前端 `status.htm` 中的 JS 根據以下邏輯構造儀表盤 URL：1) 若當前瀏覽器 hostname 與路由器 LAN IP 相同 → `http://<lan_ip>:<cn_port>/ui/<dashboard>/`；2) 若設定了 `dashboard_forward_domain` + `dashboard_forward_port`（公網訪問）→ 協議由 `dashboard_forward_ssl` 決定（0=http, 1=https），地址為 `<protocol>://<domain>:<port>/ui/<dashboard>/`；3) 其他情況 → 取當前頁面協議 + LAN IP + cn_port。四個儀表盤的子路徑分別為 `/ui/dashboard/`、`/ui/yacd/`、`/ui/metacubexd/`、`/ui/zashboard/`。

---

## 2.7 IPv6 設定標籤頁 (ipv6)

> **注意：** 不建議為路由器開啟 IPv6 及相關服務。IPv6 方案僅適用於**主路由撥號環境**（需運營商支援 IPv6-PD 字首下發），旁路由環境不適用
> **生效路徑**: IPv6 選項透過 `yml_change.sh` 寫入 YAML（`ipv6`、`dns.ipv6`、`dns.fake-ip-range6`），
> 同時 `set_firewall()` 生成獨立的 IPv6 防火牆規則鏈（`openclash_v6`、`openclash_mangle_v6` 等）。
> IPv6 使用單獨的 TProxy/Redirect/TUN 規則鏈，與 IPv4 互不影響。
>
> **IPv6 DNS 核心最佳實踐**：DNS 解析請求（包括 AAAA 記錄查詢）可以透過 IPv4 鏈路傳送，無需 IPv6 DNS 伺服器。推薦策略：① LAN 介面 DHCP 伺服器中**不分配 IPv6 DNS**，強制裝置用路由器 IPv4 地址做 DNS 解析；② 取消 `過濾 IPv6 AAAA 記錄`（Dnsmasq 高階設定）；③ 開啟 OpenClash 的「允許 IPv6 型別 DNS 解析」選項。效果：DNS 走 IPv4 通道查詢（經過 OpenClash 分流），流量走 IPv6 通道傳輸——既防止 IPv6 DNS 搶答導致的洩露，又保證 IPv6 站點可訪問

| 選項 | UCI Key | 預設 | 說明 |
|------|---------|------|------|
| IPv6 代理 (Proxy IPv6 Traffic) | `ipv6_enable` | 0 | 開啟 IPv6 流量代理。閘道器和 DNS 須為路由器 IP |
| IPv6 代理模式 (IPv6 Proxy Mode) | `ipv6_mode` | TProxy(0) | TProxy/Redirect/TUN/Mix |
| IPv6 堆疊型別 (Select Stack Type) | `stack_type_v6` | system | system/gvisor/mixed。僅 TUN/Mix 模式 |
| IPv6 UDP 代理 (Proxy UDP Traffics) | `enable_v6_udp_proxy` | 1 | 僅 TProxy/Redirect 模式 |
| 允許 IPv6 型別 DNS 解析 (IPv6 DNS Resolve) | `ipv6_dns` | 0 | 對應 Mihomo `dns.ipv6` — 控制 Clash DNS 是否返回 AAAA 記錄 |
| IPv6 Fake-IP 範圍 (Fake-IP Range) | `fakeip_range6` | 禁用 | 僅 Fake-IP 模式。對應 `dns.fake-ip-range6` |
| 實驗性：繞過指定區域 IPv6 (China IPv6 Route) | `china_ip6_route` | 0 | 0=關閉, 1=繞過大陸, 2=繞過海外 |
| 本地 IPv6 繞過地址 (Local IPv6 Network Bypassed List) | `local_network6_pass` | — | 檔案: `/etc/openclash/custom/openclash_custom_localnetwork_ipv6.list` |
| 繞過指定區域 IPv6 黑名單 (Chnroute6 Bypassed List) | `chnroute6_pass` | — | 檔案: `/etc/openclash/custom/openclash_custom_chnroute6_pass.list`。將列表中域名/IP 加入 `china_ip6_route_pass` nft set，不受 IPv6 繞行選項影響。依賴: `ipv6_enable=1` + `enable_redirect_dns=1` |

---

#### 2.8 GEO 資料庫訂閱 / 大陸白名單訂閱標籤頁

### GEO 資料庫訂閱 (GEO Update / geo_update)

| 資料型別 | 啟用 UCI | 更新指令碼 | 更新星期 UCI | 更新時間 UCI | 自定義 URL UCI |
|----------|----------|----------|-------------|-------------|---------------|
| 自動更新 GeoIP MMDB 資料庫 (Auto Update GeoIP MMDB) | `geo_auto_update` | `openclash_geo.sh ipdb` | `geo_update_week_time` | `geo_update_day_time` | `geo_custom_url` |
| 自動更新 GeoIP Dat 資料庫 (Auto Update GeoIP Dat) | `geoip_auto_update` | `openclash_geo.sh geoip` | `geoip_update_week_time` | `geoip_update_day_time` | `geoip_custom_url` |
| 自動更新 GeoSite 資料庫 (Auto Update GeoSite) | `geosite_auto_update` | `openclash_geo.sh geosite` | `geosite_update_week_time` | `geosite_update_day_time` | `geosite_custom_url` |
| 自動更新 Geo ASN 資料庫 (Auto Update Geo ASN) | `geoasn_auto_update` | `openclash_geo.sh geoasn` | `geoasn_update_week_time` | `geoasn_update_day_time` | `geoasn_custom_url` |

**共享配置項**：`*_update_week_time` (周幾): `*`=每天, `1`=週一, `2`=週二, …, `0`=週日; `*_update_day_time` (小時): `0`-`23`; `*_custom_url` (自定義下載地址，留空使用預設)

**Mihomo 對應**: `geox-url` 中的各欄位 + `geo-auto-update` + `geo-update-interval`
- **實現細節**:
  - **Cron 觸發**: `add_cron()` 在 `openclash_geo.sh` 中為每種 GEO 型別註冊 cron 任務
  - **下載流程**: `openclash_geo.sh` 使用自定義 URL（`*_custom_url`）或預設地址下載，儲存到 `/etc/openclash/` 目錄
  - **Mihomo 使用**: MMDB 用於 `GEOIP` 規則匹配（IP→國家），Dat 用於 `GEOSITE` 規則匹配（域名→類別），ASN 用於 Smart 策略
  - **執行時熱載入**: GEO 檔案更新後 Mihomo 自動重新載入（`geo-auto-update: true` + `geo-update-interval`），無需重啟

### 大陸白名單訂閱 (Chnroute Update / chnr_update)

| 選項 | UCI Key | 預設 | 說明 |
|------|---------|------|------|
| 自動更新 (Auto Update) | `chnr_auto_update` | 0 | 啟用定時更新大陸 IP 路由表 |
| 更新時間/每週 (Update Time (Every Week)) | `chnr_update_week_time` | `1`(週一) | `*`=每天, `1`=週一, …, `0`=週日 |
| 更新時間/每天 (Update time (every day)) | `chnr_update_day_time` | `0`(0:00) | `0`-`23`，每小時一個選項 |
| 大陸 IP 段更新 URL (Custom Chnroute Lists URL) | `chnr_custom_url` | `https://ispip.clang.cn/all_cn.txt` | 中國 IPv4 CIDR 列表下載地址 |
| 大陸 IPv6 段更新 URL (Custom Chnroute6 Lists URL) | `chnr6_custom_url` | `https://ispip.clang.cn/all_cn_ipv6.txt` | 中國 IPv6 CIDR 列表下載地址 |

**更新指令碼**: `openclash_chnroute.sh`

---

## 2.9 其他標籤頁

### 定時重啟 (Auto Restart / auto_restart)

此標籤頁用於設定 OpenClash 定時自動重啟。

| 選項 | UCI Key | 型別 | 預設 | 說明 |
|------|---------|------|------|------|
| **定時重啟 (Auto Restart)** | `auto_restart` | Flag | 0 | `0`=關閉, `1`=開啟。開啟後將在指定時間自動重啟 OpenClash 服務 |
| **重啟時間/每週 (Restart Time (Every Week))** | `auto_restart_week_time` | ListValue | `1`(週一) | `*`=每天 (Every Day), `1`=週一 (Every Monday), `2`=週二 (Every Tuesday), `3`=週三 (Every Wednesday), `4`=週四 (Every Thursday), `5`=週五 (Every Friday), `6`=週六 (Every Saturday), `0`=週日 (Every Sunday) |
| **重啟時間/每天 (Restart time (every day))** | `auto_restart_day_time` | ListValue | `0`(0:00) | `0`-`23`，每小時一個選項 |

- **實現細節**: `add_cron()` 在 `/etc/crontabs/root` 中新增 `/etc/init.d/openclash restart` 的 cron 條目，按使用者選擇的時間和星期執行。

### 版本更新 (Version Update / version_update)

此標籤頁內嵌「檢查更新」面板（update 模板的 version_tab 模式），以 **CDN 地址列表** 為核心，提供核心/外掛版本選擇、下載和更新操作。頁面載入時透過 `/update`（action_update，本機配置與已裝版本）、`/version_history`（版本歷史）、`/addr_info`（CDN 地址列表）API 動態填充。遠端最新版本（corelv/oplv，status 頁紅點用）由獨立 `/last_version` 端點提供，本面板不使用。

**頂部配置區（4 列，修改後自動儲存）**:

| 選項 | UCI Key | 型別 | 預設 | 說明 |
|------|---------|------|------|------|
| **處理器架構 (CPU Arch)** | —（只讀展示） | 文字 | — | 當前裝置 CPU 架構，來自後端 `coremodel`（優先讀 `/etc/openwrt_release` 的 DISTRIB_ARCH，opkg/apk 包資料庫 libc 架構兜底），僅展示不可選 |
| **編譯版本 (Compiled Version)** | `core_version` | Select | `0`(未設定) | 選擇與 CPU 匹配的編譯版本：`linux-amd64-v1/v2/v3`(x86-64)、`linux-arm64`(armv8)、`linux-armv7`、`linux-mips64` 等 ~18 種架構。**未選擇（0/空）時核心無法下載**，點選會提示 "No Compiled Version Selected" |
| **更新分支 (Release Branch)** | `release_branch` | Select | `master` | `master`(穩定版) / `dev`(開發版)，決定外掛/核心的下載分支 |
| **Smart 核心 (Smart Core)** | `smart_enable` | Select | `0` | `0`=禁用(使用 Meta 核心) / `1`=啟用(使用 Smart 核心)，決定核心下載的 meta/smart 子路徑 |

**版本卡片（Installed / Select Version）**:

| 要素 | 顯示內容 | 說明 |
|------|---------|------|
| **Installed（外掛）** | 已安裝外掛版本 | 只讀，從 opkg/apk 包資料庫讀取（`opcv`） |
| **Select Version（外掛）** | 外掛版本下拉 | 來自 `/version_history`（package 分支的 CI commit），選項值為對應 commit 的 sha，`Latest`=最新版 |
| **Installed（核心）** | 已安裝核心版本 | 只讀，執行 `clash_meta -v` 獲取（`coremetacv`） |
| **Select Version（核心）** | 核心版本下拉 | 來自 `/version_history`（core 分支的 CI commit），`Latest`=最新版 |

**hint 提示區**：預設顯示隨機提示（自動輪換）/ 操作錯誤提示 / 更新過程中的**流式日誌**——點選更新後直接在提示區顯示 `startlog` 日誌（剝離時間戳，`[Info]`/`[Warning]`/`[Error]` 著色，固定高度滾動）。

**CDN 地址列表**（Address / Latency / Plugin / Core 四列）:

- 預設 CDN：`raw.githubusercontent.com`（RAW 直連）、`fastly.jsdelivr.net`、`testingcf.jsdelivr.net`、`cdn.jsdelivr.net`；也可在底部「Custom Your CDN URL」新增自定義 CDN（如 `https://ghfast.top/`，新增後只拉取新增 CDN）
- 每行 Latency 列顯示測速延遲（`xxx ms`，按快/中/慢著色）或「Access Timed Out / Access Denied」；Plugin/Core 列顯示該 CDN 獲取到的外掛/核心版本號
- **點選版本號連結** = 只安裝該元件（外掛→`one_key_update?update_type=plugin`，核心→`core_download`）；**點選右側下載圖示按鈕** = 直接下載對應 .ipk/.apk 或 .tar.gz
- **點選行其他區域** = 一鍵更新外掛 + 核心，根據兩個 Select Version 下拉決定更新到歷史版本還是 Latest
- 更新後面板保持開啟，日誌在 hint 區流式顯示

**底部操作區**:

| 操作 | 功能 |
|------|------|
| **備份 (Backup File)** | 先選備份範圍下拉（Backup File 完整 / Backup Exclude Cores 排除核心 / Backup Core 僅核心 / Backup Config 僅配置 / Backup Rule Provider 僅規則提供者 / Backup Proxy Provider 僅代理提供者），再點按鈕下載備份 |
| **還原預設 (Restore Default)** | 恢復 OpenClash 為預設出廠配置（確認後跳回設定頁） |
| **刪除核心 (Remove Core)** | 刪除所有核心二進位制檔案（紅色危險按鈕） |

- **實現細節**:
  - 所有配置修改（編譯版本/分支/Smart）透過 `/save_corever_branch` API 即時儲存到 UCI。
  - 核心下載：`core_download` 路由呼叫 `openclash_core.sh`，前端始終傳入完整下載 URL（`download_url`）。檔名 `clash-{arch}.tar.gz`（arch 即 `core_version`，已帶 `linux-` 字首）；oix 核心為 `mihomo-{arch}-{version}.gz`（走 github release / dl.dler.io）。
  - 外掛下載：`openclash_update.sh`，檔名 `luci-app-openclash_{ver}_all.ipk`（opkg）或 `luci-app-openclash-{ver}.apk`（apk）。
  - **下載 URL 結構**：`package`/`core` 是倉庫**分支**（非目錄）。Latest（無歷史 sha）：`package/{branch}/luci-app-openclash_{ver}_all.ipk`、`core/{branch}/{meta|smart}/clash-{arch}.tar.gz`（把分支名作為 ref 段）；選擇歷史版本（帶 sha，為對應分支的 CI commit）：`{sha}/{branch}/luci-app-openclash_{ver}_all.ipk`、`{sha}/{branch}/{meta|smart}/clash-{arch}.tar.gz`。jsdelivr CDN 字首為 `gh/vernesong/OpenClash@{ref}/...`，自定義 CDN 字首直接拼接 raw URL。
  - **下載失敗不會觸發 OpenClash 重啟**（`openclash_core.sh` 僅在核心真正更新成功後才置重啟標誌）。
  - 外掛更新透過 ubus 後臺安裝以避免 Web 介面斷連。

### 開發者選項 (Developer Settings / developer)
- **自定義防火牆規則** (`firewall_custom`): 在 LuCI 的「開發者設定」標籤頁中直接編輯的文字框，內容儲存到 `/etc/openclash/custom/openclash_custom_firewall_rules.sh`。該指令碼**不需要定義任何函式**——它是一個命令式 Shell 指令碼，在所有 OpenClash 內建防火牆規則新增完畢後被直接執行（`chmod +x` 後執行）。可以在指令碼中直接寫 `iptables -I ...` 或 `nft add rule ...` 命令來追加自定義防火牆規則。
- **實現細節**: `set_firewall()` 函式在所有內建的 REDIRECT/TPROXY/TUN/IPv6/訪問控制規則建立完畢後，檢查此檔案是否存在，若存在則 `chmod +x` 並執行。由於它在所有內建規則之後執行，自定義規則可以引用 OpenClash 已建立的 nftables 鏈和 set。每次 OpenClash 啟動或防火牆過載時都會重新執行此指令碼。

### 核心測試 (Core Test / debug)

此標籤頁提供二種獨立的診斷工具，位於「核心測試」標籤頁：

| 工具 | 功能 | 觸發方式 | 後端路由 |
|------|------|---------|----------|
| **連線測試 (Connection Test)** | 測試指定域名是否可達 | 輸入域名 + 點選「Click to Test」(點選測試) 按鈕 | `/diag_connection` |
| **DNS 測試 (DNS Test)** | 測試 DNS 解析結果 | 輸入域名 + 點選「Click to Test」(點選測試) 按鈕 | `/diag_dns` |

**連線測試實現細節**: 前端先嚐試 `Image` 載入 `https://{domain}/favicon.ico` 作為快速預檢，若失敗則回退到後端 `/diag_connection` 呼叫。

### oixCloud (oixcloud)
- 第三方雲服務，需賬號密碼登入
- `oix_email` / `oix_passwd` → `oix_login` 獲取 token
- `oix_checkin` — 自動簽到 (需 token)
- 登入後自動獲取 Oix 專屬核心和訂閱

---

## 2.10 來源流量訪問控制 (Source Traffic Bypass / lan_ac_traffic)

> **頁面位置**：外掛設定頁面底部（不屬於任何標籤頁，以獨立的 TypedSection 形式存在）
> **生效路徑**：透過 `init.d/openclash` 的 `firewall_lan_ac_traffic()` 函式在代理鏈 **position 0** 插入規則，
> 優先順序高於所有其他代理規則。配置透過 `config_foreach firewall_lan_ac_traffic "lan_ac_traffic"` 遍歷執行。
>
> **AI 行為指引**：當使用者詢問「如何讓某個介面（如 WireGuard/Docker 網橋）的流量完全繞過核心」、
> 「如何按使用者 UID 繞過代理」、「如何精細控制特定來源流量」時，AI 應告知使用者使用此功能，
> 並結合下方欄位表和防火牆邏輯給出具體配置方案。涉及底層實現時查閱
> [OpenClash 原始碼](https://github.com/vernesong/OpenClash/tree/dev) 中
> `init.d/openclash` 的 `firewall_lan_ac_traffic()` 函式。

### lan_ac_traffic TypedSection

支援按七維度組合匹配流量，匹配後執行 target 動作：

| 欄位 | UCI Key | 型別 | 說明 |
|------|---------|------|------|
| 備註 | `comment` | Value | 規則說明 |
| 啟用 | `enabled` | Flag | 預設 1 |
| 內部地址 | `src_ip` | Value | IP/CIDR/`localnetwork`（匹配本地網路地址集 @localnetwork） |
| 內部埠 | `src_port` | Value | 埠或範圍，如 `5000` 或 `1234-2345` |
| 協議 | `proto` | ListValue | `both`(預設)/`tcp`/`udp` |
| 地址族 | `family` | ListValue | `both`(預設)/`ipv4`/`ipv6` |
| 介面 | `interface` | ListValue | 網路介面名（如 `eth1`、`wg0`、`docker0`），匹配從該介面進入的流量 |
| 使用者 | `user` | ListValue | Linux UID，匹配該使用者程序發出的流量（僅 OUTPUT 鏈生效） |
| DSCP | `dscp` | Value | 0-63，匹配 IP 頭 DSCP 標記值 |
| 目標 | `target` | ListValue | `RETURN`(預設，跳過代理走直連) / `ACCEPT`(放行) / `DROP`(靜默丟棄) |

### 防火牆工作邏輯（基於 `init.d/openclash` → `firewall_lan_ac_traffic()` 原始碼）

**規則生成流程**：

```
config_foreach firewall_lan_ac_traffic "lan_ac_traffic"
  → 讀取每個啟用的 section 的 UCI 欄位
  → 構建 nftables/iptables 匹配條件
  → 按執行模式 + 協議 + 地址族插入對應鏈的 position 0
```

**fw4 (nftables) 規則插入的目標鏈**（按執行模式區分）：

| 執行模式 | TCP 進入 | TCP 發出 | UDP 進入 | UDP 發出 | 旁路由 SNAT |
|----------|----------|----------|----------|----------|-------------|
| 非 TUN（redir-host/fake-ip） | `openclash` | `openclash_output` | `openclash_mangle` | `openclash_mangle_output` | `openclash_post` |
| TUN 模式 | `openclash_mangle` | `openclash_mangle_output` | `openclash_mangle` | `openclash_mangle_output` | `openclash_post` |
| IPv6（ipv6_enable=1） | `openclash_v6` | `openclash_output_v6` | `openclash_mangle_v6` | `openclash_mangle_output_v6` | `openclash_post_v6` |

**關鍵匹配邏輯**：

- **`src_ip=localnetwork`**：特殊值，nftables 端展開為 `ip saddr @localnetwork`（匹配整個本地網路地址集），iptables 端使用 `-m set --match-set localnetwork src`
- **介面匹配**：nftables 用 `iifname "介面名"`，iptables 用 `-i 介面名`
- **使用者匹配**：nftables 用 `meta skuid UID`（僅 OUTPUT 鏈生效），iptables 用 `-m owner --uid-owner UID`
- **DSCP 匹配**：nftables 用 `ip dscp 值`，iptables 需 `dscp` 模組（不可用時跳過並輸出警告：`iptables DSCP module not available`）
- **Fake-IP 排除**：所有規則自動排除 Fake-IP 地址段 `ip daddr != {198.18.0.0/16}`，避免影響 Fake-IP 內部對映
- **drop→return 轉換**：當 `target=DROP` 時，nftables 實際動作為 `return`（因 mangle 鏈不支援 drop），iptables 保持 `DROP`

**常見場景示例**：

| 需求 | 規則配置 |
|------|----------|
| 某介面（如 WireGuard）流量不走代理 | `interface=wg0`, `target=RETURN` |
| Docker 網橋流量繞過核心 | `interface=docker0`, `target=RETURN` |
| 某裝置所有流量不走代理 | `src_ip=192.168.1.100/32`, `target=RETURN` |
| 某埠範圍的 TCP 流量不走代理（BT 埠） | `src_port=6881-6889`, `proto=tcp`, `target=RETURN` |
| 某使用者程序流量完全丟棄 | `user=65534`, `target=DROP` |
| 本地網路所有 UDP 流量直連 | `src_ip=localnetwork`, `proto=udp`, `target=RETURN` |

---

# 第三部分：覆寫設定頁面 (Overwrite Settings / config-overwrite)

> UCI Section: `openclash.config_overwrite`
> 此頁面用於覆寫訂閱配置中的特定欄位，設定後透過 openclash.sh 指令碼注入到生成的 YAML 中

## 實現總覽

```
 UCI config_overwrite 寫入
        │
        ▼
 yml_change.sh (優先順序最高)         yml_rules_change.sh
 ├─ 埠、模式、DNS、TUN            ├─ tolerance / url-test 覆寫
 ├─ Sniffer、認證、Meta             ├─ GitHub CDN 替換
 ├─ GEO、Smart、NTP                 ├─ enable_rule_proxy → BT/P2P 直連
 └─ 自定義 DNS servers              └─ 自定義規則注入
```

**關鍵機制**: `yml_change.sh` 以 YAML 深度合併 + 覆蓋的方式修改配置，覆寫優先順序高於訂閱原始值。
`yml_rules_change.sh` 使用 Ruby YAML 庫操作策略組、規則、URL-Test 引數和規則提供者地址。
兩個指令碼在 `start_service()` 流程中先於核心啟動執行。

## 3.1 常規設定標籤頁 (General Settings / settings)

### interface_name — 繫結網路介面 (Bind Network Interface)
- **UCI**: `openclash.@config_overwrite[0].interface_name`
- **預設**: 0 (禁用)
- **說明**: 繫結核心出站流量到指定網路介面
- **Mihomo 對應**: `interface-name`
- **實現細節**: `yml_change.sh` 將值寫入 YAML `interface-name`。Mihomo 核心所有出站連線（代理節點連線、DNS 查詢、GEO 下載）都透過此介面傳送。用於多 WAN 環境指定出口。

### tolerance — URL-Test 策略組切換靈敏度 (URL-Test Group Tolerance)
- **UCI**: `openclash.@config_overwrite[0].tolerance`
- **預設**: 0 (禁用)
- **說明**: 當前代理與新最快代理的延遲差值大於此值時自動切換。0 表示關閉
- **Mihomo 對應**: proxy-groups 中 url-test 型別的 `tolerance` 欄位
- **實現細節**: `yml_rules_change.sh` 遍歷所有 `type: url-test` 的策略組，設定其 `tolerance` 值。Mihomo 核心定期測試組內所有節點延遲，噹噹前選中節點的延遲與新最快節點的延遲差 > tolerance 時自動切換。設為 0 則每次測試都切換到最快節點。

### urltest_address_mod — 測速（連通性）地址修改 (URL-Test Address Modify)
- **UCI**: `openclash.@config_overwrite[0].urltest_address_mod`
- **預設**: 0 (禁用)
- **預設**: `http://www.gstatic.com/generate_204` / `http://cp.cloudflare.com/` / `https://cp.cloudflare.com/` / `http://captive.apple.com/`
- **Mihomo 對應**: proxy-groups 中 url-test 型別的 `url` 欄位
- **實現細節**: `yml_rules_change.sh` 替換所有 url-test 策略組的測試 URL。Mihomo 核心週期性向此 URL 傳送 HTTP HEAD/GET 請求測量延遲，作為節點選擇的依據。

### github_address_mod — Github 地址修改 (Github Address Proxy)
- **UCI**: `openclash.@config_overwrite[0].github_address_mod`
- **說明**: 透過代理/CDN 加速 GitHub 檔案下載。**強烈推薦在 OpenClash 啟動前就設定好此項**，因為外掛和核心更新、GEO 資料庫下載、Dashboard 下載均依賴 GitHub 連通性。推薦優先嚐試 `https://testingcf.jsdelivr.net/`（jsDelivr 的 Cloudflare CDN），如不可用再切換其他 CDN
- **預設**: 多個 jsdelivr CDN 地址（testingcf / fastly 等）
- **實現細節**: `yml_rules_change.sh` 用 Ruby 正則 `/raw\.githubusercontent\.com/` 匹配所有 rule-providers 和 proxy-providers 的 `url` 欄位，將域名替換為 CDN 地址。解決中國大陸無法訪問 GitHub 的問題。
- **已知限制**: `github_address_mod` 僅對 rule-providers 和 proxy-providers 的 URL 生效。`openclash_download_dashboard.sh`（Dashboard 下載）和 `openclash_geo.sh`（GEO 更新）**不使用此變數**，這些指令碼的下載 URL 為硬編碼的 GitHub 直連地址。如需對 Dashboard/GEO 下載使用 CDN，可透過覆寫模組的 `[General]` 段設定 `DOWNLOAD_FILE` 或使用自定義規則使相關域名直連。

### log_level — 日誌等級 (Log Level)
- **UCI**: `openclash.@config_overwrite[0].log_level`
- **可選值**: `0`(禁用) / `info` / `warning` / `error` / `debug` / `silent`
- **Mihomo 對應**: `log-level`
- 0 表示不覆寫，使用訂閱原有設定
- **實現細節**: `yml_change.sh` 將值寫入 YAML `log-level`。Mihomo 核心根據級別過濾日誌輸出：`silent`(無輸出) → `error`(僅錯誤) → `warning`(+警告) → `info`(+一般資訊) → `debug`(+除錯詳情)。

### 埠設定
| 埠用途 | UCI Key | 預設 | Mihomo 對應 |
|----------|---------|------|-------------|
| **DNS 埠 (DNS Port)** | `dns_port` | 7874 | `dns.listen` |
| **流量轉發埠 (Redir Port)** | `proxy_port` | 7892 | `listeners.redirect` (僅 TCP) |
| **TProxy 埠 (TProxy Port)** | `tproxy_port` | 7895 | `listeners.tproxy` (TCP+UDP) |
| **HTTP(S) 代理埠 (HTTP(S) Port)** | `http_port` | 7890 | `listeners.http` |
| **SOCKS5 代理埠 (SOCKS5 Port)** | `socks_port` | 7891 | `listeners.socks` |
| **HTTP(S)&SOCKS5 混合代理埠 (Mixed Port)** | `mixed_port` | 7893 | `listeners.mixed` (HTTP+SOCKS) |

- **埠實現細節**: `yml_change.sh` 將所有埠寫入 YAML 對應欄位。Mihomo 核心啟動時在這些埠上建立監聽器，接受來自 iptables/nftables 重定向的流量或客戶端直連的代理請求。修改後需重啟核心。

## 3.2 DNS 設定標籤頁 (DNS Settings / dns)

> **生效路徑**: DNS 覆寫透過 `yml_change.sh` 的 `yml_dns_custom()` 函式處理，
> 構建完整的 `dns:` YAML 段併合併到執行配置。
>
> **AI 行為指引**: 當使用者詢問 DNS 配置問題時（如"如何配置 DoH/DoT"、"nameserver-policy 怎麼寫"、"hosts 格式是什麼"、
> "fallback-filter 各欄位含義"等），AI 應查閱 [Mihomo DNS 配置文件](https://wiki.metacubex.one/config/dns/)
> 瞭解各欄位的詳細含義和用法，涉及 OpenClash 側 DNS 覆寫實現時查閱
> [OpenClash 原始碼](https://github.com/vernesong/OpenClash/tree/dev) 中 `yml_change.sh` 的 `yml_dns_custom()` 函式，
> 然後**結合 OpenClash 覆寫模組的操作方式**告知使用者如何配置，而非僅給出文件連結。

### enable_custom_dns — 自定義上游 DNS 伺服器 (Custom DNS Setting)
- **UCI**: `openclash.@config_overwrite[0].enable_custom_dns`
- **預設**: 0
- **說明**: 開啟後將透過 TypedSection `dns_servers` 中的配置覆寫 YAML 的 `dns` 段
- **最佳實踐**: 在 Fake-IP 模式下推薦以下配置策略：① Nameserver 僅負責直連類域名的解析（使用運營商 DNS 或國內 DoH 如 AliDNS/DNSPod）；② **取消所有 Fallback 伺服器**——Fake-IP 模式下若無 Fallback，非直連域名的解析請求將交由遠端（代理節點側）完成，解析結果與實際出站鏈路一致，可獲得更一致的 CDN 命中並防止 DNS 洩露；③ 若出站側解析不可用（罕見），可啟用 Fallback 作為兜底並同時開啟「遵循規則」功能。**不建議套娃其他 DNS 外掛**（如 MosDNS/SmartDNS/AdGuardHome），多外掛疊加會引入快取一致性問題、增加內網解析延遲，且破壞 Mihomo 向客戶端傳遞的 TTL 值
- **實現細節**: 開啟後 `yml_dns_custom()` 遍歷所有 `dns_servers` 條目，按 group 分類（nameserver/fallback/default）構建 DNS 伺服器列表，透過 Ruby YAML 合併寫入 `dns.nameserver`、`dns.fallback`、`dns.default-nameserver`。

### enable_respect_rules — 遵守路由規則 (Enable Respect Rules)
- **UCI**: `openclash.@config_overwrite[0].enable_respect_rules`
- **預設**: 0
- **Mihomo 對應**: `dns.respect-rules`
- **說明**: DNS 連線是否遵守 YAML 中的路由規則
- **實現細節**: 寫入 YAML `dns.respect-rules: true`。Mihomo 核心的 DNS 解析器發出的連線將經過 `rules` 規則引擎匹配——意味著 DNS 查詢本身也會被代理（透過匹配的代理節點發出），防止 DNS 洩露。需要配合 `proxy-server-nameserver` 防止雞生蛋問題。

### append_wan_dns — 附加上游 DNS (Append WAN DNS)
- **UCI**: `openclash.@config_overwrite[0].append_wan_dns`
- **預設**: 1
- **說明**: 將 WAN 口自動分配的運營商 DNS 和閘道器 IP 追加到 nameserver 列表。**主路由撥號環境推薦啟用**：運營商 DNS 對直連類域名的解析延遲通常最低（1-2ms），CDN 命中更接近實際鏈路，省去手動配置的麻煩。若使用第三方加密 DNS（如 DoH/DoT），則需禁用此項並在 NameServer 中手動新增伺服器
- **實現細節**: `sys_dns_append()` 呼叫 `openclash_get_network.lua` 獲取 WAN 口的 DNS 和閘道器地址，追加到 `/tmp/yaml_config.namedns.yaml`，後續被合併到 YAML `dns.nameserver`。支援 dhcp:// 協議直接從 DHCP 介面獲取 DNS。

### fakeip_range — Fake-IP 範圍 (IPv4) (Fake-IP Range)
- **UCI**: `openclash.@config_overwrite[0].fakeip_range`
- **預設**: 0 (禁用)
- **預設**: `198.18.0.1/16` (標準 Fake-IP 段)
- **Mihomo 對應**: `dns.fake-ip-range`
- **僅**: Fake-IP 模式顯示
- **實現細節**: 寫入 YAML `dns.fake-ip-range`。Mihomo 在 Fake-IP 模式下，將 DNS 查詢的域名對映到此 CIDR 段中的虛擬 IP。應用連線到虛擬 IP 時核心透過路由表將流量導向 Clash，Clash 根據對映表還原真實域名後進行規則匹配。

### store_fakeip — 持久化 Fake-IP (Store Fake-IP)
- **UCI**: `openclash.@config_overwrite[0].store_fakeip`
- **預設**: 1
- **Mihomo 對應**: `profile.store-fake-ip`
- **說明**: 快取 Fake-IP DNS 解析記錄到檔案，啟動後加速響應
- **實現細節**: 寫入 YAML `profile.store-fake-ip: true`。Mihomo 將域名→Fake-IP 對映持久化到 `cache.db` 檔案，重啟後恢復對映，避免重啟後所有域名需要重新解析。

### custom_fallback_filter — 自定義 Fallback-Filter (Custom Fallback Filter)
- **UCI**: `openclash.@config_overwrite[0].custom_fallback_filter`
- **預設**: 0
- **說明**: 配置 DNS 防汙染回退過濾器
- **配置檔案**: `/etc/openclash/custom/openclash_custom_fallback_filter.yaml`
- **Mihomo 對應**: `dns.fallback-filter` 段

> Fallback-Filter 格式示例:
> ```yaml
> geoip: true
> geoip-code: CN
> geosite:
>   - gfw
> domain:
>   - '+.google.com'
> ```

### custom_fakeip_filter — 自定義 Fake-IP-Filter (Custom Fake-IP Filter)
- **UCI**: `openclash.@config_overwrite[0].custom_fakeip_filter`
- **預設**: 0
- **僅**: Fake-IP 模式顯示
- **Mihomo 對應**: `dns.fake-ip-filter`

### custom_fakeip_filter_mode — Fake-IP-Filter 模式 (Custom Fake-IP Filter Mode)
- **UCI**: `openclash.@config_overwrite[0].custom_fakeip_filter_mode`
- **可選**: `blacklist` / `whitelist` / `rule`
- **預設**: `blacklist`
- **說明**:
  - `blacklist`: 匹配成功的域名不返回 Fake-IP (黑名單)
  - `whitelist`: 只有匹配成功的域名返回 Fake-IP (白名單)
  - `rule`: 規則模式，支援 GEOSITE、RuleSet、DOMAIN* 等語法
- **Mihomo 對應**: `dns.fake-ip-filter-mode`

### 域名過濾檔案 (custom_fake_filter)
- **檔案**: `/etc/openclash/custom/openclash_custom_fake_filter.list`
- **格式**: 每行一個域名萬用字元，如 `*.lan`, `+.example.com`

### custom_name_policy — 自定義 Nameserver-Policy (Custom Name Policy)
- **UCI**: `openclash.@config_overwrite[0].custom_name_policy`
- **檔案**: `/etc/openclash/custom/openclash_custom_domain_dns_policy.list`
- **Mihomo 對應**: `dns.nameserver-policy`
- **格式**: 每行 `域名=DNS伺服器組` 或使用 geosite/rule-set

### custom_proxy_server_policy — 自定義 Proxy-Server-Nameserver-Policy (Custom Proxy Server Policy)
- **UCI**: `openclash.@config_overwrite[0].custom_proxy_server_policy`
- **檔案**: `/etc/openclash/custom/openclash_custom_proxy_server_dns_policy.list`
- **Mihomo 對應**: `dns.proxy-server-nameserver-policy`
- **說明**: 僅用於解析代理節點域名的 DNS 策略

### custom_host — 自定義 Hosts (Custom Hosts)
- **UCI**: `openclash.@config_overwrite[0].custom_host`
- **檔案**: `/etc/openclash/custom/openclash_custom_hosts.list`
- **Mihomo 對應**: `dns.hosts`

### DNS 伺服器列表 (dns_servers TypedSection)

> **AI 行為指引**: 當使用者詢問 DNS 伺服器型別（如"DoH 和 DoT 有什麼區別"、"quic 型別怎麼用"、
> "dns 伺服器的 `#proxy` 和 `#RULES` 字尾是什麼意思"）時，AI 應查閱
> [Mihomo DNS 型別文件](https://wiki.metacubex.one/config/dns/type/) 瞭解每種 DNS 協議的使用方法和引數，
> 涉及 OpenClash 側實現時查閱 [OpenClash 原始碼](https://github.com/vernesong/OpenClash/tree/dev) 中
> `yml_change.sh` 的 DNS 相關邏輯，然後告知使用者具體的配置寫法。

使用者可以新增多條 DNS 伺服器記錄，每條包含：

| 欄位 | UCI Key | 說明 |
|------|---------|------|
| 啟用 | `enabled` | Flag，預設 1 |
| 分組 | `group` | `nameserver`(預設DNS) / `fallback`(後備DNS) / `default`(預設DNS) |
| 地址 | `ip` | DNS 伺服器 IP |
| 埠 | `port` | 埠號 |
| 型別 | `type` | `udp` / `tcp` / `tls` / `https` / `quic` |
| 禁用 IPv6 | `disable_ipv6` | 丟棄 AAAA 記錄 |

**Mihomo YAML 格式示例**:
```yaml
dns:
  nameserver:
    - 223.5.5.5
    - tls://8.8.4.4
  fallback:
    - tls://1.1.1.1
```

## 3.3 Meta 設定標籤頁 (Meta Settings / meta)

> **生效路徑**: Meta 選項透過 `yml_change.sh` 寫入 YAML，所有選項在 Mihomo 啟動時載入生效。
> 部分選項（sniffer）支援執行時透過 API 熱修改。
>
> **AI 行為指引**: 當使用者詢問 Meta 相關問題（如"tcp-concurrent 和 unified-delay 有什麼區別"、
> "find-process-mode 各模式的含義"、"sniffer 如何自定義"、"geodata-loader 選哪個"），
> AI 應查閱 [Mihomo 全域性配置文件](https://wiki.metacubex.one/config/general/) 和
> [Mihomo Sniffer 文件](https://wiki.metacubex.one/config/sniff/) 瞭解各選項的詳細含義，
> 涉及 OpenClash 側 Meta 選項注入實現時查閱 [OpenClash 原始碼](https://github.com/vernesong/OpenClash/tree/dev) 中
> `yml_change.sh` 的 sniffer/Meta 相關段，然後結合 OpenClash 的覆寫設定操作路徑告知使用者。

### enable_tcp_concurrent — 啟用 TCP 併發 (Enable Tcp Concurrent)
- **UCI**: `openclash.@config_overwrite[0].enable_tcp_concurrent`
- **預設**: 0
- **Mihomo 對應**: `tcp-concurrent: true`
- **說明**: 同時使用 DNS 解析的所有 IP 地址發起連線，使用最先成功的連線
- **實現細節**: `yml_change.sh` 寫入 YAML `tcp-concurrent: true`。Mihomo 對每個目標域名解析出所有 IP 後，同時向所有 IP 發起 TCP 連線，使用第一個 TCP 握手成功的連線，丟棄其餘。可大幅降低首次連線延遲，但會增加併發連線數。

### enable_unified_delay — 啟用統一延遲 (Enable Unified Delay)
- **UCI**: `openclash.@config_overwrite[0].enable_unified_delay`
- **預設**: 0
- **Mihomo 對應**: `unified-delay: true`
- **說明**: 消除連線握手等帶來的不同型別節點延遲差異
- **實現細節**: 寫入 YAML `unified-delay: true`。Mihomo 在 URL-Test 延遲測量時計算 RTT（Round-Trip Time），而非簡單的 TCP 握手時間 + HTTP 響應時間。這樣 Shadowsocks、Trojan、VMess 等不同協議的節點延遲可公平比較。

### find_process_mode — 啟用程序規則 (Find Process Mode)
- **UCI**: `openclash.@config_overwrite[0].find_process_mode`
- **可選值**: `0`(禁用) / `off` / `always` / `strict`
- **預設**: 0
- **Mihomo 對應**: `find-process-mode`
- **說明**: 依賴 `kmod-inet-diag` 核心模組。路由器上推薦 `off` 以提升效能
- **實現細節**: 寫入 YAML `find-process-mode`。控制 Mihomo 是否透過 Netlink INET_DIAG 匹配每個連線的發起程序名（用於 PROCESS-NAME 規則）。路由器上設為 `off` 可避免核心模組依賴和效能開銷。

### enable_meta_sniffer — 啟用流量（域名）探測 (Enable Sniffer)
- **UCI**: `openclash.@config_overwrite[0].enable_meta_sniffer`
- **預設**: 1
- **Mihomo 對應**: `sniffer.enable: true`
- **說明**: 防止域名代理和 DNS 劫持失敗。透過嗅探 TLS/HTTP/QUIC 握手獲取真實目標域名
- **實現細節**: `yml_change.sh` 寫入完整的 `sniffer:` YAML 段：
  - `sniff.TLS.ports: [443, 8443]` — 解析 TLS ClientHello 中的 SNI 欄位獲取域名
  - `sniff.HTTP.ports: [80, 8080-8880]` — 解析 HTTP Host 頭獲取域名
  - `sniff.QUIC.ports: [443]` — 解析 QUIC Initial 包中的 SNI
  - `force-dns-mapping: true` (僅 Redir-Host) — 對 DNS 解析過的 IP 強制嗅探
  - `override-destination: true` — 用嗅探到的域名覆蓋連線目標，確保規則基於域名匹配
  - 預置 `force-domain: [netflix, nflxvideo, amazonaws, media.dssott.com]` — 強制嗅探流媒體
  - 預置 `skip-domain: [Mijia Cloud, dlg.io.mi.com, oray.com, sunlogin.net, push.apple.com]` — 跳過智慧家居/推送

### enable_meta_sniffer_pure_ip — 探測（嗅探）純 IP 連線 (Forced Sniff Pure IP)
- **UCI**: `openclash.@config_overwrite[0].enable_meta_sniffer_pure_ip`
- **預設**: 1
- **Mihomo 對應**: `sniffer.parse-pure-ip: true`
- **說明**: 對所有未獲取到域名的流量進行強制嗅探（如直接 IP 連線）

### enable_meta_sniffer_custom — 自定義流量探測（嗅探）設定 (Custom Sniffer Settings)
- **UCI**: `openclash.@config_overwrite[0].enable_meta_sniffer_custom`
- **預設**: 0
- **說明**: 啟用後將使用下方文字框中的自定義 sniffer YAML 配置替代預設嗅探設定

### sniffer_custom — 自定義 Sniffer 文字框 (Sniffer Custom)
- **UCI**: `openclash.@config_overwrite[0].sniffer_custom`
- **儲存**: `/etc/openclash/custom/openclash_custom_sniffer.yaml`
- **說明**: 多行 YAML 文字框，可自定義完整的 `sniffer:` 配置段。僅在 `enable_meta_sniffer_custom=1` 時生效

### geodata_loader — Geodata 資料載入方式 (Geodata Loader)
- **UCI**: `openclash.@config_overwrite[0].geodata_loader`
- **可選值**: `0`(禁用) / `memconservative` / `standard`
- **預設**: `memconservative`
- **Mihomo 對應**: `geodata-loader`
- **說明**: `memconservative` 專為小記憶體裝置最佳化的載入器（逐段讀取），`standard` 為標準載入器（一次性載入到記憶體，速度快但佔記憶體）

### enable_geoip_dat — 啟用 GeoIP Dat 版資料庫 (Enable GeoIP Dat)
- **UCI**: `openclash.@config_overwrite[0].enable_geoip_dat`
- **預設**: 0
- **Mihomo 對應**: `geodata-mode: true`
- **說明**: 使用 Dat 格式替換 MMDB 格式 GeoIP 檔案。Dat 檔案較大需單獨下載，可透過「GEO 資料庫訂閱」頁面獲取

### global_ua — 全域性 User-Agent (Global UA)
- **UCI**: `openclash.@config_overwrite[0].global_ua`
- **預設**: 0 (禁用，使用系統預設 `clash.meta`)
- **Mihomo 對應**: `global-ua`
- **預設**: `clash-verge/v2.4.5` / `clash.meta/1.19.20` / `Clash`
- **說明**: 設定 Mihomo 下載外部資源（GEO 檔案、規則集等）時使用的 User-Agent

> Sniffer YAML 格式示例:
> ```yaml
> sniffer:
>   enable: true
>   force-dns-mapping: true
>   parse-pure-ip: true
>   override-destination: false
>   sniff:
>     HTTP:
>       ports: [80, 8080-8880]
>     TLS:
>       ports: [443, 8443]
>     QUIC:
>       ports: [443, 8443]
>   force-domain:
>     - +.v2ex.com
>   skip-domain:
>     - Mijia Cloud
> ```

## 3.4 智慧設定標籤頁 (Smart Settings / smart)

> **生效路徑**: Smart 策略是智慧代理選擇引擎，基於 LightGBM 機器學習模型。
> `yml_change.sh` 將 Smart 訓練資料收集配置寫入 YAML（`profile.smart-collector-size`），
> `yml_rules_change.sh` 負責將 url-test/load-balance 策略組型別轉換為 `type: smart` 並設定 Smart 相關引數（uselightgbm、collectdata、sample-rate、policy-priority、prefer-asn）。
> Smart 策略的執行時節點選擇由 **Mihomo 核心 Smart 模組內部處理**，無需外部指令碼干預。
>
> **AI 行為指引**: 當使用者詢問 Smart 策略相關問題時（如"Smart 和 url-test 有什麼區別"、"如何訓練 Smart 模型"、
> "prefer-asn 是什麼"、"sample-rate 怎麼設定"、"LGBM 模型如何自定義下載"），AI 應：
> 1. 首先查閱下方「智慧設定標籤頁」中對應 UCI 選項的說明，給出 LuCI 操作路徑（覆寫設定 → Smart 設定）
> 2. Smart 策略組是 **Smart 核心原始碼獨有的功能**（上游 Mihomo 核心無此特性），所有實現細節均應查閱
>    [Smart 核心原始碼](https://github.com/vernesong/mihomo/tree/Alpha)：
>    - 策略組節點選擇邏輯 → `adapter/outboundgroup/smart.go`（`selectProxies()`、`Unwrap()`、`InitSmart()`）
>    - LightGBM 模型載入/推理/資料收集 → `component/smart/lightgbm/`（`lightgbm.go`、`collector.go`、`transform.go`）
>    - Smart 持久化儲存與權重計算 → `component/smart/cachefile.go`、`component/smart/weight.go`
> 3. **Smart 節點選擇邏輯簡述**（`adapter/outboundgroup/smart.go` → `selectProxies()`）：
>    ① 獲取目標 IP/域名的 ASN 資訊 → ② 優先檢查使用者手動選擇的節點 → ③ 查持久化快取
>    （boltDB 儲存的歷史最優結果）→ ④ 查預取快取（週期性後臺預計算）→ ⑤ 實時呼叫
>    `store.GetBestProxyForTarget()` 綜合歷史延遲、抖動、丟包率及 LightGBM 模型預測權重
>    計算最優節點 → ⑥ `filterProxies()` 按權重排序過濾。後臺定時任務持續維護排名
>    （`updateNodeRanking`）、預取（`runPrefetch`）、穩定性檢查（`checkNodesStable`）、
>    被封節點恢復檢測（`checkBlockedNodes`）、主機狀態檢查（`checkHostStatus`）。
> 4. **關於"如何訓練 Smart 模型"**：使用者如需自行訓練模型（而非使用預訓練模型），AI 應主動讀取
>    [Smart 核心原始碼](https://github.com/vernesong/mihomo/tree/Alpha) 中 `component/smart/lightgbm/` 目錄，
>    瞭解並告知使用者以下資訊：
>    - **資料來源**：`component/smart/lightgbm/collector.go` — 開啟 `smart_collect` 後核心會在 `/etc/openclash/` 下生成 CSV 訓練資料檔案（含延遲、抖動、丟包率等特徵；特徵工程見 `transform.go`）
>    - **LightGBM 版本**：查閱 `go.mod` 中 `vernesong/leaves` 依賴確認支援的 LightGBM 版本
>    - **環境搭建**：在 PC/伺服器上安裝對應版本的 LightGBM Python 包，準備訓練環境
>    - **訓練指令碼**：參考 `component/smart/lightgbm/` 中的特徵處理與模型結構，為使用者建立可執行的示例訓練指令碼（讀取 CSV → 特徵變換 → 訓練 LightGBM → 匯出 Model.bin）
>    - **模型部署**：訓練完成後將 `Model.bin` 上傳到可訪問的 URL，透過 `lgbm_custom_url` 指定；或替換 `/etc/openclash/Model.bin`；模型載入與推理見 `lightgbm.go` 中的 `WeightModel`
>    - **日常使用**：大多數使用者無需自行訓練，開啟 `lgbm_auto_update` 即可自動下載預訓練模型
> **關鍵提醒**：Smart 策略使用 LightGBM 模型進行節點質量預測，需要在配置檔案中將策略組型別設為 `smart`
> 才能啟用（透過 `auto_smart_switch` 自動轉換或手動修改 YAML）。Smart 核心在執行時根據模型預測結果
> 和實時延遲資料綜合選擇最優節點，無需外部指令碼干預。

### auto_smart_switch — Smart 策略自動切換 (Smart Auto Switch)
- **UCI**: `openclash.@config_overwrite[0].auto_smart_switch`
- **預設**: 0
- **說明**: 自動將 url-test/load-balance 型別的策略組切換為 Smart 智慧策略組
- **實現細節**: `yml_rules_change.sh` 遍歷所有策略組，將 `type: url-test` 或 `type: load-balance` 替換為 `type: smart`。Smart 策略組綜合延遲、丟包率、歷史表現等多維指標選擇最優節點。

### smart_policy_priority — 策略優先順序 (Policy Priority)
- **UCI**: `openclash.@config_overwrite[0].smart_policy_priority`
- **格式**: `策略名:係數;策略名:係數`，如 `Premium:0.9;SG:1.3`
- **說明**: `<1` 降低優先順序，`>1` 提高優先順序，預設權重為 1。支援正則和字串匹配策略組名稱

### smart_prefer_asn — 優先 ASN 查詢 (Smart Prefer ASN)
- **UCI**: `openclash.@config_overwrite[0].smart_prefer_asn`
- **預設**: 0
- **說明**: 強制查詢並使用目標 ASN（自治系統號）資訊，優先選擇同一 ASN 的更穩定節點

### smart_enable_lgbm — 啟用 LightGBM 模型 (Enable LightGBM Model)
- **UCI**: `openclash.@config_overwrite[0].smart_enable_lgbm`
- **預設**: 0
- **說明**: 使用 LightGBM 機器學習模型預測節點權重
- **實現細節**: `yml_change.sh` 配置 YAML 中的模型下載 URL 和更新間隔。`openclash_lgbm.sh` 定期下載訓練好的 LightGBM 模型檔案到 `/etc/openclash/Model.bin`（小快閃記憶體模式下為 `/tmp/etc/openclash/Model.bin`）。Mihomo Smart 模組載入模型後，根據節點歷史延遲、抖動、丟包率等特徵預測最優節點。

### smart_tolerance — Smart 組延遲容差 (Smart Group Tolerance)
- **UCI**: `openclash.@config_overwrite[0].smart_tolerance`
- **預設**: 0 (禁用)
- **可選值**: `0`(禁用) / `100` / `150` (ms)
- **Mihomo YAML 對映**: `proxy-groups[].tolerance: <value>` (單位 ms, 僅對 smart 型別策略組設定)
- **說明**: 當多個代理節點延遲在容差範圍內時視為等效，按權重排序而非嚴格按延遲排序，防止因網路抖動導致頻繁切換節點
- **實現細節**: `yml_rules_change.sh` 在 smart auto switch 處理中，對每個 `type: smart` 的策略組設定 `group['tolerance']`

### smart_collect — 收集訓練資料 (Collectdata)
- **UCI**: `openclash.@config_overwrite[0].smart_collect`
- **預設**: 0
- **Mihomo YAML 對映**: `proxy-groups[].collectdata: true`, `proxy-groups[].sample-rate: <rate>`
- **說明**: 在節點選擇過程中收集延遲/抖動等資料供 LightGBM 模型訓練。全域性開關，會對所有 smart 型別策略組生效

### smart_collect_size — 資料收集檔案大小 (Smart Collect Size)
- **UCI**: `openclash.@config_overwrite[0].smart_collect_size`
- **預設**: 100 (MB)
- **Mihomo YAML 對映**: `profile.smart-collector-size: <size>` (全域性配置)
- **依賴**: `smart_collect=1`
- **實現細節**: `yml_change.sh` 透過 `Value['profile']['smart-collector-size'] = <size>` 寫入 YAML

### smart_collect_rate — 資料取樣率 (Smart Collect Rate)
- **UCI**: `openclash.@config_overwrite[0].smart_collect_rate`
- **預設**: 1 (範圍 0-1)
- **Mihomo YAML 對映**: `proxy-groups[].sample-rate: <rate>`
- **依賴**: `smart_collect=1`

### lgbm_auto_update — 自動更新 LightGBM 模型 (LGBM Auto Update)
- **UCI**: `openclash.@config_overwrite[0].lgbm_auto_update`
- **預設**: 0
- **Mihomo YAML 對映**: `lgbm-auto-update: true`, `lgbm-url: <url>`, `lgbm-update-interval: <hours>`
- **實現細節**: `yml_change.sh` 設定為 1 時寫入 `lgbm-auto-update: true` 及對應 URL 和間隔

### lgbm_update_interval — 模型更新間隔 (LGBM Update Interval)
- **UCI**: `openclash.@config_overwrite[0].lgbm_update_interval`
- **預設**: 72 (小時)
- **依賴**: `lgbm_auto_update=1`

### lgbm_custom_url — 自定義模型下載地址 (LGBM Custom URL)
- **UCI**: `openclash.@config_overwrite[0].lgbm_custom_url`
- **預設**: `https://github.com/vernesong/mihomo/releases/download/LightGBM-Model/Model.bin`（輕量版）
- **可選**: 中量版 (`Model-middle.bin`)、重量版 (`Model-large.bin`) — 模型越大預測越準確但佔用更多記憶體
- **依賴**: `lgbm_auto_update=1`

### 手動更新模型按鈕
- **功能**: 點選觸發 `openclash_lgbm.sh` 立即下載最新模型並顯示當前模型檔案時間戳

### 重新整理 Smart 快取按鈕
- **功能**: 透過 Mihomo API `POST /cache/smart/flush` 清空 Smart 策略快取，強制重新評估所有節點

### 按策略組的 Smart 設定 (Per-Group Smart Settings)

> **LuCI 路徑**: 服務 → OpenClash → 配置管理 → 節點管理 → 編輯按鈕 (groups-config)
> **注意**: groups-config 不是主選單頁面，而是透過「配置管理 → 節點 & 策略組管理」頁面中的編輯按鈕載入進入的隱藏子頁面（controller 中註冊為 `nil` 顯示名）。
> **UCI Section**: `openclash.groups_config` (多條，每條對應一個策略組)
> 以下為 `type=smart` 策略組獨有的配置選項，用於**覆蓋**全域性 Smart 設定中的對應值。

| 選項 | UCI Key | 預設值 | Mihomo YAML 對映 | 說明 |
|------|---------|--------|-----------------|------|
| **啟用 LightGBM** (Uselightgbm) | `uselightgbm` | `false` | `proxy-groups[].uselightgbm: true/false` | 是否為此策略組啟用 LightGBM 模型預測權重。優先順序高於全域性 `smart_enable_lgbm` |
| **收集訓練資料** (Collectdata) | `collectdata` | `false` | `proxy-groups[].collectdata: true/false` | 是否為此策略組收集訓練資料。優先順序高於全域性 `smart_collect` |
| **策略優先順序** (Policy Priority) | `policy_priority` | *(空)* | `proxy-groups[].policy-priority: "<pattern>"` | 此策略組內節點的權重優先順序，格式同全域性 `smart_policy_priority`（如 `Premium:0.9;SG:1.3`）。支援正則匹配節點名稱 |
| **延遲容差** (Tolerance) | `tolerance` | *(空)* | `proxy-groups[].tolerance: <ms>` | 此策略組的延遲容差（ms），覆蓋全域性 `smart_tolerance`。注意：該欄位在 groups-config.lua 中存在但不直接寫入 YAML——`yml_rules_change.sh` 的 smart 段**不讀取** per-group tolerance，僅使用全域性 `smart_tolerance` 統一設定所有 smart 策略組 |

> **注意**: Per-group 的 `tolerance` 欄位在 LuCI 介面中可配置，但實際 YAML 生成指令碼（`yml_rules_change.sh`）在 smart auto switch 處理中統一使用全域性 `smart_tolerance` 值應用到**所有** smart 型別策略組。如需對不同策略組設定不同 tolerance，需透過覆寫模組的 `[YAML]` 段手動指定。
>
> **Per-group Smart 設定的生效方式**: 這些欄位直接寫入策略組的 YAML 配置中（如 `proxy-groups[0].uselightgbm: true`），由 Mihomo Smart 核心在執行時讀取。它們與全域性 Smart 設定（覆寫設定 → Smart 設定）的關係是：**per-group 設定覆蓋全域性設定，但僅影響該策略組**。
>
> **Smart 策略組通用選項** (與 url-test/fallback/load-balance 共享):
> - `test_url` — 延遲測試 URL
> - `test_interval` — 延遲測試間隔 (秒)

---

## 3.5 規則設定標籤頁 (Rules Settings / rules)

> 此標籤頁用於管理自定義 Clash/Mihomo 路由規則。Mihomo 支援多種規則型別，
> 使用者在 LuCI 文字框中編寫規則時需遵循特定格式。

### enable_rule_proxy — 僅代理命中規則流量 (Rule Match Proxy Mode)
- **UCI**: `openclash.@config_overwrite[0].enable_rule_proxy`
- **預設**: 0
- **說明**: 開啟後向配置追加 PROCESS-NAME 和 DST-PORT 規則，僅允許匹配規則的流量走代理，其餘流量（如 BT/P2P）直連

### enable_custom_clash_rules — 自定義規則 (Custom Clash Rules)
- **UCI**: `openclash.@config_overwrite[0].enable_custom_clash_rules`
- **預設**: 0
- **說明**: 開啟後將在執行配置的 `rules:` 段注入自定義規則檔案中的內容

### custom_rules — 優先規則編輯框 (Custom Rules Priority)
- **UCI**: `openclash.@config_overwrite[0].custom_rules`
- **儲存**: `/etc/openclash/custom/openclash_custom_rules.list`
- **格式**: 每行一條 Mihomo 規則，插入到規則列表頂部（優先匹配）
- **依賴**: `enable_custom_clash_rules=1`

### custom_rules_2 — 擴充套件規則編輯框 (Custom Rules Extended)
- **UCI**: `openclash.@config_overwrite[0].custom_rules_2`
- **儲存**: `/etc/openclash/custom/openclash_custom_rules_2.list`
- **格式**: 每行一條 Mihomo 規則，插入到規則列表底部
- **依賴**: `enable_custom_clash_rules=1`

### 規則編寫指南

> **當使用者描述需求（如"我想讓某個域名走代理"、"禁止某個 IP 走代理"）時，AI 應查閱 [Mihomo 路由規則文件](https://wiki.metacubex.one/config/rules/) 瞭解各規則型別的作用，涉及規則注入實現時查閱 [OpenClash 原始碼](https://github.com/vernesong/OpenClash/tree/dev) 中 `yml_rules_change.sh` 和 `custom_rules*.list` 的處理邏輯，然後告知使用者具體的規則寫法。**

**Mihomo 支援的規則型別速查**:

| 規則型別 | 格式 | 用途 | 示例 |
|---------|------|------|------|
| `DOMAIN` | `DOMAIN,域名,策略` | 精確匹配域名 | `DOMAIN,www.google.com,Proxy` |
| `DOMAIN-SUFFIX` | `DOMAIN-SUFFIX,域名字尾,策略` | 匹配域名字尾（含所有子域名） | `DOMAIN-SUFFIX,google.com,Proxy` |
| `DOMAIN-KEYWORD` | `DOMAIN-KEYWORD,關鍵詞,策略` | 匹配域名含關鍵詞 | `DOMAIN-KEYWORD,youtube,Proxy` |
| `DOMAIN-REGEX` | `DOMAIN-REGEX,正則,策略` | 域名正則匹配 | `DOMAIN-REGEX,^api\.example\.com$,Proxy` |
| `GEOSITE` | `GEOSITE,類別,策略` | 按 GeoSite 類別匹配域名 | `GEOSITE,netflix,NETFLIX` |
| `GEOIP` | `GEOIP,國家程式碼,策略` | 按 GeoIP 國家匹配 IP | `GEOIP,CN,DIRECT` |
| `IP-CIDR` | `IP-CIDR,IP/掩碼,策略` | IP 段匹配 | `IP-CIDR,10.0.0.0/8,DIRECT` |
| `IP-CIDR6` | `IP-CIDR6,IPv6/掩碼,策略` | IPv6 段匹配 | `IP-CIDR6,::1/128,DIRECT` |
| `IP-ASN` | `IP-ASN,ASN號,策略` | 自治系統號匹配 | `IP-ASN,13335,Proxy` |
| `RULE-SET` | `RULE-SET,規則集名,策略` | 引用 rule-provider 規則集 | `RULE-SET,reject,REJECT` |
| `PROCESS-NAME` | `PROCESS-NAME,程序名,策略` | 按程序名匹配 | `PROCESS-NAME,aria2c,DIRECT` |
| `DST-PORT` | `DST-PORT,埠,策略` | 目標埠匹配 | `DST-PORT,80,Proxy` |
| `SRC-PORT` | `SRC-PORT,埠,策略` | 源埠匹配 | `SRC-PORT,8080,DIRECT` |
| `SRC-IP-CIDR` | `SRC-IP-CIDR,IP/掩碼,策略` | 源 IP 段匹配 | `SRC-IP-CIDR,192.168.1.0/24,DIRECT` |
| `MATCH` | `MATCH,策略` | 兜底匹配所有流量 | `MATCH,Proxy` |

**可用策略目標**: `DIRECT`(直連)、`Proxy`(走預設代理組)、`REJECT`(拒絕)、`REJECT-DROP`(靜默丟棄)、`GLOBAL`(走全域性組)、任意自定義策略組名稱

**編寫格式**: 不區分大小寫，逗號分隔。每行一條規則。規則按順序從上到下匹配，命中後不再繼續。

**常見需求 → 規則示例**:

| 使用者需求 | 規則寫法 |
|---------|---------|
| Google 走代理 | `DOMAIN-SUFFIX,google.com,Proxy` |
| 國內域名直連 | `GEOSITE,cn,DIRECT` |
| Netflix 走專用策略組 | `GEOSITE,netflix,NETFLIX` |
| 禁止訪問某域名 | `DOMAIN-SUFFIX,badsite.com,REJECT` |
| BT 下載直連 | `PROCESS-NAME,qbittorrent,DIRECT` |
| 特定 IP 段直連 | `IP-CIDR,192.168.0.0/16,DIRECT` |
| GitHub 直連加速 | `DOMAIN-SUFFIX,github.com,DIRECT` |
| 所有流量走代理 | `MATCH,Proxy` |
| 排除某裝置走代理 | `SRC-IP-CIDR,192.168.1.100/32,DIRECT` |

> **進階規則型別**（如 `AND`/`OR`/`NOT` 邏輯規則、`SUB-RULE` 子規則等）請查閱 [Mihomo 路由規則文件](https://wiki.metacubex.one/config/rules/)。

---

## 3.6 認證設定 (Authentication)

位於常規設定標籤頁中，為 SOCKS/HTTP/Mixed 代理新增使用者認證：

| 欄位 | UCI Key | 說明 |
|------|---------|------|
| 啟用 | `enabled` | Flag, 預設 1 |
| 使用者名稱 | `username` | 代理認證使用者名稱 |
| 密碼 | `password` | 代理認證密碼 |

**Mihomo 對應**: `authentication` 列表，格式 `["user:pass"]`

---

# 第四部分：配置訂閱頁面 (Config Subscribe / config-subscribe)

> UCI Section: `openclash.config_subscribe` (多條)

> **AI 行為指引**: 當使用者詢問訂閱相關問題（如"如何過濾節點"、"訂閱轉換怎麼用"、"訂閱 URL 格式不對怎麼辦"、
> "keyword 和 ex_keyword 的區別"、"Age 加密是什麼"），AI 應查閱 [Mihomo 代理協議文件](https://wiki.metacubex.one/config/proxies/)
> 瞭解節點名稱的命名規範和常見格式，涉及訂閱處理實現細節時查閱
> [OpenClash 原始碼](https://github.com/vernesong/OpenClash/tree/dev) 中 `openclash.sh` 的
> `sub_info_get()`、`config_cus_up()`、`server_key_match()` 等函式，
> 然後告知使用者具體的配置方法。對於訂閱轉換後端問題，
> 告知使用者轉換後端的地址格式和模板 URL 的作用。

## 實現總覽

```
 Cron / Web UI「更新配置」
        │
        ▼
 openclash.sh (訂閱更新主指令碼)
        │
        ├─ config_download()     → curl 下載訂閱 URL (支援代理/直連回退)
        ├─ sub_convert           → 可選: 傳送到訂閱轉換後端
        ├─ config_cus_up()       → Ruby YAML 解析 + 節點關鍵字過濾/排除
        ├─ config_test()         → clash -t 驗證 YAML 語法
        └─ config_su_check()     → 新舊對比，有更新則替換 + 標記重啟
```

**核心流程** (`openclash.sh` 中的 `sub_info_get()`):
1. 遍歷所有啟用的 `config_subscribe` 條目
2. 對每條訂閱構建下載 URL（新增 `custom_params`、設定 `sub_ua`）
3. 如果設定了 `sub_convert`，將 URL 發到轉換後端獲取處理後的配置
4. 如果設定了 `secret_key` (Age 加密)，先用 age 解密
5. 用 Ruby YAML 解析訂閱配置 → 獲取所有代理節點
6. 根據 `keyword` / `ex_keyword` 正則匹配過濾節點：
   - `&` = AND: 節點名必須同時包含所有關鍵字
   - `|` = OR: 節點名包含任一關鍵字即保留
7. 將過濾後的節點合併到當前配置的 `proxies` 和 `proxy-groups` 中
8. 寫入 `/etc/openclash/config/<name>.yaml`，標記核心需重啟

**關鍵字匹配實現** (`server_key_match()`):
將使用者輸入的關鍵字轉換為 Ruby 正規表示式。`&` 分隔的轉為正向預查鏈 `(?=.*kw1)(?=.*kw2)`，`|` 分隔的轉為擇一匹配 `(kw1|kw2)`。

### 自動更新 (Auto Update)

| 選項 | UCI Key | 說明 |
|------|---------|------|
| 自動更新 (Auto Update) | `auto_update` | Flag，預設 0 |
| 更新模式 | `config_auto_update_mode` | `0`=預約模式(指定周几几點), `1`=迴圈模式(每隔N分鐘) |
| 更新日 (Update Time Every Week) | `config_update_week_time` | `*`=每天 (Every Day), `1`=週一, …, `0`=週日 |
| 更新時間 (Update time every day) | `auto_update_time` | 0-23 點 |
| 更新間隔/分鐘 (Update Interval min) | `config_update_interval` | 僅迴圈模式，預設 60 |

### 每條訂閱 (`config_subscribe` TypedSection)

| 欄位 | 用途 |
|------|------|
| 訂閱名稱 (Config Alias) | `name` | 用於區分，請勿重名 |
| 訂閱地址 (Subscribe Address) | `address` | 訂閱 URL |
| **User-Agent** (UA) | `sub_ua` | 預設 clash-verge/clash.meta/clash |
| **線上訂閱轉換 (Subscribe Convert Online)** | `sub_convert` | 訂閱轉換後端地址 |
| **訂閱轉換模板 (Template Name)** | `sub_template` | 轉換模板 URL |
| **篩選節點 (Keyword Match)** | `keyword` | 節點關鍵字匹配 (保留匹配的節點) |
| **排除節點 (Exclude Keyword Match)** | `ex_keyword` | 排除關鍵字 (排除匹配的節點) |
| **自定義引數 (Custom Params)** | `custom_params` | 自定義訂閱 URL 引數 |
| **Age 加密金鑰 (Secret Key)** | `secret_key` | Age 加密金鑰 |

**關鍵字格式**: 使用 `&` 表示 AND (同時滿足)，使用 `|` 表示 OR
- 例：`香港&01` → 節點名同時包含"香港"和"01"
- 例：`香港|臺灣` → 節點名包含"香港"或"臺灣"

---

# 第五部分：配置管理頁面 (Config Manage / config)

> LuCI 路徑: `服務` → `OpenClash` → `配置管理` (順序第 80)
> UCI 對映: `openclash.config.config_path`

## 實現總覽

配置管理頁面是一個多功能綜合頁面，提供配置檔案的上傳、切換、編輯、重新命名、刪除以及提供商檔案管理功能。

**核心功能區塊**:

| 區塊 | 功能 | 後端路由 |
|------|------|----------|
| 檔案上傳 (Upload) | 上傳配置檔案、代理/規則提供商、核心二進位制、備份恢復 | `/upload_config` + `file_type` 引數區分 |
| **配置檔案列表** | 檢視/切換/編輯/重新命名/複製/下載/刪除配置 | `/switch_config`、`/config_file_list`、`/config_file_save` 等 |
| **提供商檔案管理** | 跳轉到代理提供商和規則提供商管理子頁 | 跳轉連結 |
| **配置檔案編輯器** | 雙欄 YAML 編輯器（左側可編輯使用者配置，右側只讀預設模板） | `/config_file_read` + `/config_file_save` |

## 5.1 檔案上傳

| 上傳型別 | `file_type` 值 | 目標目錄 | 說明 |
|----------|---------------|----------|------|
| 配置檔案 (Config) | `config` | `/etc/openclash/config/` | `.yaml`/`.yml` 格式，上傳後自動設為當前啟用配置 |
| 代理集檔案 (Proxy Provider File) | `proxy-provider` | `/etc/openclash/proxy_provider/` | 訂閱中 `proxy-providers` 的節點檔案 |
| 規則集檔案 (Rule Provider File) | `rule-provider` | `/etc/openclash/rule_provider/` | 訂閱中 `rule-providers` 的規則檔案 |
| 核心檔案 (Core File) | `clash_meta` | `/etc/openclash/core/` | 支援 `.tar.gz`/`.gz` 格式自動解壓，`chmod 4755` |
| 備份恢復 | `backup-file` | 恢復到 `/etc/config/openclash` | 上傳備份並恢復 UCI 配置 |

## 5.2 配置檔案列表

| 操作 | 功能 | 說明 |
|------|------|------|
| **SwiTch** (切換) | 切換啟用配置 | 修改 `config_path` UCI + commit，自動重啟核心 |
| **Edit** (編輯) | 線上編輯配置 | 跳轉到雙欄 YAML 編輯器 |
| **Rename** (重新命名) | 重新命名 | 輸入新名稱，`mv` 重新命名檔案 |
| **Copy** (複製配置) | 複製配置 | 生成 `<檔名>(N).yaml` 副本 |
| **Download** (下載配置) | 下載配置檔案 | HTTP 下載原始配置檔案 |
| **Download Run** (下載執行配置) | 下載執行時配置 | 下載 `/etc/openclash/<name>`（經指令碼處理後的實際執行配置） |
| **Remove** (移除) | 刪除配置 | 刪除 YAML 檔案 + 歷史快取 `/etc/openclash/history/<name>.db` + 執行時配置，自動切換到其他配置 |

## 5.3 配置檔案編輯器

雙欄 YAML 編輯器：
- **左欄 (可編輯)**: 讀寫當前 `config_path` 指向的配置，儲存時自動 `\r\n` → `\n` 轉換
- **右欄 (只讀)**: 展示執行時配置 `/etc/openclash/<name>` 或預設模板 `/usr/share/openclash/res/default.yaml`
- **操作按鈕**: Commit (儲存配置 (Commit Settings))、Create (新建配置)、Apply (應用配置 (Apply Settings))
- **快捷鍵**: F10 diff 控制、F11 全屏模式

## 5.4 提供商子頁面

透過配置管理頁面可跳轉到以下子頁面（獨立 CBI 頁面）：
- **servers** — 代理節點管理（編輯/新增/刪除節點）
- **servers-config** — 節點配置編輯器
- **groups-config** — 策略組配置編輯器
- **proxy-provider-config** — 代理提供商配置
- **proxy-provider-file-manage** — 代理提供商檔案管理
- **rule-providers-file-manage** — 規則提供商檔案管理

---

# 第六部分：執行日誌頁面 (Server Logs / log)

> LuCI 路徑: `服務` → `OpenClash` → `執行日誌` (順序第 90)
> UCI 對映: `openclash.openclash.clog`

## 實現總覽

執行日誌頁面是一個雙標籤頁的日誌檢視器。頁面佈局包含以下區域：

**標籤頁 1 — Plugin Logs** (預設啟用)：展示 OpenClash 外掛自身日誌（Shell/Ruby/Lua 指令碼輸出），透過 XHR 輪詢 (`/refresh_log`) 每秒重新整理。

**標籤頁 2 — Core Logs** (可切換)：展示 Mihomo 核心實時日誌，透過 WebSocket 連線到核心 API (`/logs?token=...&level=...`)。該標籤頁內嵌 **5 個日誌等級單選按鈕**：

| 按鈕 | 功能 | 後端操作 |
|------|------|----------|
| **Info** (資訊) | 預設等級，顯示一般資訊及以上 | GET `/log_level` → 設定 WebSocket level |
| **Warning** (警告) | 只顯示警告及以上 | GET `/switch_log` + WebSocket 重連 |
| **Error** (錯誤) | 只顯示錯誤及以上 | 同上 |
| **Debug** (除錯) | 顯示所有除錯資訊 | 同上 |
| **Silent** (靜默) | 靜默模式，不顯示核心日誌 | 同上 |

**標籤頁 3 — Debug Logs** (可切換)：展示外掛的除錯日誌，內容由 `openclash_debug.sh` 生成，包含系統資訊、依賴包檢查、核心執行狀態、外掛設定、覆寫模組設定、自定義規則檔案內容、當前 Mihomo YAML 配置、自定義覆寫/防火牆指令碼內容、完整的 iptables-save dump、完整的 nftables 規則、ipset 狀態、路由表、TUN 裝置狀態、埠占用、DNS 解析測試、網路連通性測試、最近執行日誌、活動連線列表及隱私處理等。

**底部操作按鈕欄**（兩個標籤頁共用）：

| 按鈕 | 功能 | 後端操作 |
|------|------|----------|
| **Stop Refresh** (停止重新整理) | 暫停日誌重新整理（XHR 輪詢 + WebSocket 均停止） | 停止 `poll_log()` 和 `coreLogWebSocketStop()` |
| **Start Refresh** (開始重新整理) | 恢復日誌重新整理 | 重新啟動輪詢和 WebSocket |
| **Clean** (清理日誌) | 清空日誌文字框 | GET `/del_log` |
| **Download Log** (下載日誌) | 下載完整日誌檔案（OC 日誌 + Core 日誌合併） | 除錯日誌會單獨下載不會進行拼接 | 其他兩個標籤的內容前端進行拼接下載 |
| **Generate Logs** (生成除錯日誌) | 點選生成除錯日誌並展示 | 前端下載時不拼接 |

**OpenClash|Mihomo 日誌來源**: OpenClash 日誌由後端將 UCI `clog` 欄位內容寫入 CodeMirror 日誌編輯器。核心日誌透過 WebSocket 實時推送到前端 `textarea#core_log`。

**除錯日誌來源|實現細節**: `openclash_debug.sh` 使用檔案鎖防止併發，收集以下 20+ 個章節並輸出到 `/tmp/openclash_debug.log`：
  1) 系統資訊（韌體版本、核心版本、CPU 架構）
  2) 依賴包檢查（dnsmasq-full、bash、curl、ruby、ruby-yaml、kmod-tun、kmod-inet-diag、kmod-nft-tproxy 或 kmod-ipt-tproxy 等）
  3) 核心執行狀態（PID、執行使用者、Meta 核心版本 `clash_meta -v`）
  4) 外掛設定（所有 UCI 執行模式/代理/DNS/IPv6 配置值）
  5) 覆寫模組設定（`uci show openclash.@overwrite[0]`）
  6) 自定義規則檔案內容
  7) 當前 Mihomo YAML 配置（過濾掉 proxies/proxy-providers/secret 保護隱私）
  8) 自定義覆寫/防火牆指令碼內容
  9) 完整的 iptables-save dump（nat/mangle/filter 表，含 IPv6）
  10) 完整的 nftables 規則（inet fw4 中所有鏈）
  11) ipset 狀態
  12) 路由表（IPv4/IPv6 route、策略路由表 354、ip rule）
  13) TUN 裝置狀態
  14) 埠占用（netstat）
  15) DNS 解析測試（nslookup + Mihomo 核心 DNS 測試）
  16) 網路連通性測試（curl www.baidu.com + GitHub）
  17) 最近執行日誌（臨時切換日誌級別到 debug 後採集 100 行）
  18) 活動連線列表（透過 Mihomo API 獲取）
  19) 隱私處理（IPv4 最後一位元組和 IPv6 後半部分模糊化）

**附加元件**: 頁面同時載入 `openclash/toolbar_show`（**配置切換工具欄**：下拉選擇當前配置檔案 + Switch 按鈕）和 `openclash/config_editor`（**頁面內嵌 CodeMirror 編輯器**，預載入 CodeMirror CSS/JS 資源並透過全域性 `merge_editor()` 函式對外開放合併檢視功能，非日誌渲染用途，僅作檔案編輯功能複用）。

> **注意**: 如需修改 OpenClash 自身日誌級別，請在「覆寫設定 → 常規設定」中調整 `log_level`。核心日誌標籤頁內可直接切換核心日誌等級。

---

# 第七部分：診斷命令與 CLI 參考

> **用途**: 當使用者描述問題但缺少關鍵資訊時，AI 應給出精確的 SSH 命令讓使用者在路由器上執行，
> 然後根據使用者返回的輸出結果進行診斷。
>
> **互動模式**: AI 給出命令 → 使用者複製到路由器終端執行 → 使用者貼上輸出 → AI 分析並決定下一步。
> 命令按安全等級標註：🟢 安全查詢 / 🟡 有副作用 / 🔴 高風險。AI 應優先推薦 🟢 命令，
> 對 🟡/🔴 命令應附帶風險說明。

## 7.0 使用方法

AI 會將以下格式的命令發給使用者：

```bash
# 複製此命令到路由器終端執行
<命令>
```

使用者執行後把輸出貼上回對話，AI 根據輸出判斷問題並給出下一步指令。

> **路由器終端接入方式**: SSH 登入 (`ssh root@<router_ip>`) 或 LuCI 自帶的「系統→終端」頁面。
> 如使用者不確定如何登入，AI 應告知上述兩種方式供選擇。

## 7.1 診斷決策樹

> AI 根據使用者症狀選擇對應子節，按步驟順序執行命令，每步根據輸出決定下一步。

### 7.1.1 無法訪問外網

| 步驟 | 命令 | 安全 | 期望輸出 | 異常處理 |
|------|------|------|----------|----------|
| 1. 核心執行 | `pidof clash` | 🟢 | 返回 PID | 無→跳 7.1.6 |
| 2. 代理模式 | `curl -s http://127.0.0.1:9090/configs \| grep '"mode"'` | 🟢 | `"mode": "rule"` | `"direct"`→切換為 rule |
| 3. TCP 代理鏈 | `nft list chain inet fw4 openclash 2>/dev/null \| head -20` | 🟢 | 含 `redirect to 7892` | 鏈不存在→`/etc/init.d/openclash reload` |
| 4. 策略路由 | `ip rule show \| grep 0x162` | 🟢 | `fwmark 0x162 lookup 0x162` | TUN 模式必須；無→重啟核心 |
| 5. 錯誤日誌 | `tail -30 /tmp/openclash.log \| grep -E 'level=(error\|fatal)'` | 🟢 | 無輸出 | 有→對照「日誌與錯誤資訊速查」 |

### 7.1.2 DNS 解析異常

| 步驟 | 命令 | 安全 | 期望輸出 | 異常處理 |
|------|------|------|----------|----------|
| 1. DNS 埠 | `netstat -tlnp \| grep 7874` | 🟢 | `0.0.0.0:7874` 在監聽 | 無→核心未正常啟動 DNS |
| 2. DNS 劫持 | `nft list chain inet fw4 dstnat 2>/dev/null \| grep 'OpenClash DNS'` | 🟢 | 含 `redirect` 規則 | 無→檢查 `enable_redirect_dns` UCI |
| 3. dnsmasq 配置 | `uci show dhcp.@dnsmasq[0] \| grep -E 'server\|noresolv'` | 🟢 | `server=127.0.0.1#7874` | 非此→DNS 轉發鏈路斷開 |
| 4. 解析測試 | `nslookup www.google.com 127.0.0.1` | 🟢 | Fake-IP 模式返回 `198.18.x.x` | 返回真實IP→Fake-IP 未生效；無響應→服務異常 |
| 5. dnsmasq | `dnsmasq --version \| head -1` | 🟢 | 含 `full` 或 ipset/nftset | 精簡版→換 `dnsmasq-full` |

### 7.1.3 訪問控制問題（某裝置不走/走了代理）

| 步驟 | 命令 | 安全 | 期望輸出 | 異常處理 |
|------|------|------|----------|----------|
| 1. AC 模式 | `uci get openclash.@openclash[0].lan_ac_mode` | 🟢 | `0`(黑名單) 或 `1`(白名單) | 確認與使用者預期一致 |
| 2. 黑名單 set | `nft list set inet fw4 lan_ac_black_ips 2>/dev/null` | 🟢 | 含目標裝置 IP | set 為空→未新增 |
| 3. 白名單 set | `nft list set inet fw4 lan_ac_white_ips 2>/dev/null` | 🟢 | 含目標裝置 IP | 白名單模式非白名單裝置全部 RETURN |
| 4. 規則確認 | `nft list chain inet fw4 openclash \| grep -E 'saddr\|ether saddr'` | 🟢 | AC 規則在代理規則之前 | 順序異常→過載防火牆 |

### 7.1.4 TUN 模式啟動失敗

| 步驟 | 命令 | 安全 | 期望輸出 | 異常處理 |
|------|------|------|----------|----------|
| 1. 核心模組 | `lsmod \| grep tun` | 🟢 | `tun` 模組已載入 | 無→安裝 `kmod-tun` |
| 2. TUN 裝置 | `ip link show utun` | 🟢 | `utun: <POINTOPOINT>` | 不存在→檢查啟動日誌 |
| 3. 策略路由 | `ip rule show \| grep 0x162` | 🟢 | `fwmark 0x162 lookup 0x162` | 無→TUN 模式必須 |
| 4. 路由表 | `ip route show table 0x162` | 🟢 | `default dev utun` | 空表→TUN 裝置未關聯路由 |
| 5. TUN 轉發 | `nft list chain inet fw4 forward \| grep utun` | 🟢 | `oifname utun accept` | 無→過載防火牆 |

### 7.1.5 節點連線問題

| 步驟 | 命令 | 安全 | 期望輸出 | 異常處理 |
|------|------|------|----------|----------|
| 1. 節點狀態 | `curl -s http://127.0.0.1:9090/proxies \| grep -E '"name"\|"history"' \| head -20` | 🟢 | 含延遲資料 | 全部超時→檢查網路/節點可用性 |
| 2. 代理模式 | `curl -s http://127.0.0.1:9090/configs \| grep '"mode"'` | 🟢 | `rule` 或 `global` | `direct`→所有流量直連 |
| 3. 連線列表 | `curl -s http://127.0.0.1:9090/connections \| head -30` | 🟢 | 含 `chains` 代理鏈 | 無連線→確認有流量經過 |
| 4. QUIC(GSO) | `nft list chain inet fw4 input \| grep 'QUIC REJECT'` | 🟢 | 含 `udp dport 443 reject` | Hysteria 節點問題→先試 `disable_quic_go_gso` |
| 5. 錯誤日誌 | `tail -30 /tmp/openclash.log \| grep -iE 'error\|timeout\|refused\|reset\|fatal'` | 🟢 | 無輸出 | 有→對照「日誌與錯誤資訊速查」 |

### 7.1.6 配置/啟動失敗

| 步驟 | 命令 | 安全 | 期望輸出 | 異常處理 |
|------|------|------|----------|----------|
| 1. 啟動日誌 | `tail -30 /tmp/openclash_start.log` | 🟢 | 含 `Start Successful` | `Core Start Failed`→跳步驟3 |
| 2. UCI enable | `uci get openclash.@openclash[0].enable` | 🟢 | `1` | `0`→外掛被禁用 |
| 3. YAML 驗證 | `/etc/openclash/clash -t -d /etc/openclash -f $(uci get openclash.@openclash[0].config_path)` | 🟡 | `configuration is ok` | 報錯→對照「日誌與錯誤資訊速查」 |
| 4. Ruby 檢查 | `ruby -ryaml -e 'puts "ok"'` | 🟢 | `ok` | 報錯→安裝 `ruby` `ruby-yaml` `ruby-psych` |
| 5. 依賴檢查 | `opkg list-installed \| grep -E 'ruby\|dnsmasq-full\|kmod-tun\|kmod-nft-tproxy\|curl\|ca-bundle\|ip-full\|unzip'` | 🟢 | 8 個包均已安裝 | 缺失→安裝對應包 |
| 6. 除錯日誌 | `/usr/share/openclash/openclash_debug.sh` | 🟡 | 生成 `/tmp/openclash_debug.log` | 日誌含 `#===== 依賴檢查 =====#` 段 |

## 7.2 通用診斷命令

> 不限於特定症狀的快速檢查命令。

**🟢 安全查詢（純查詢，零副作用）：**

| 命令 | 用途 |
|------|------|
| `pidof clash` | 核心是否執行 |
| `/etc/openclash/clash -v` | 核心版本 |
| `uci show openclash \| grep <key>` | 查特定 UCI 配置 |
| `tail -50 /tmp/openclash.log` | 執行日誌 |
| `nft list chain inet fw4 openclash` | TCP 透明代理規則鏈 |
| `nft list chain inet fw4 openclash_mangle` | UDP TPROXY 規則鏈 |
| `nft list chain inet fw4 dstnat \| grep 'OpenClash DNS'` | DNS 劫持規則 |
| `nft list set inet fw4 china_ip_route \| head -5` | 大陸 IP set |
| `ip rule show \| grep 0x162` | 策略路由 |
| `lsmod \| grep -E 'tun\|nft_tproxy\|inet_diag'` | 核心模組 |
| `dnsmasq --version \| head -1` | dnsmasq 版本（需 full 版） |
| `netstat -tlnp \| grep -E '7874\|7892\|7895\|9090'` | 埠監聽 |
| `df -h /etc/openclash` | 磁碟空間 |
| `free -m` | 記憶體使用 |

**🟡 有副作用（可逆或影響較小）：**

| 命令 | 用途 | 副作用 |
|------|------|--------|
| `/etc/init.d/openclash reload` | 過載防火牆 | 不影響已有連線 |
| `/usr/share/openclash/openclash_debug.sh` | 生成除錯日誌 | 寫 `/tmp/openclash_debug.log` |
| `/usr/share/openclash/openclash_geo.sh <type>` | 更新 GEO | 替換檔案；type=`ipdb\|geoip\|geosite\|geoasn\|all` |
| `/usr/share/openclash/openclash_chnroute.sh` | 更新大陸路由 | 替換 ipset/nft set |
| `/usr/share/openclash/openclash_history_get.sh close_all_conection` | 斷開所有連線 | 中斷活躍代理連線 |
| `curl -X POST http://127.0.0.1:9090/cache/fakeip/flush` | 清空 Fake-IP | DNS 重新解析 |
| `curl -X POST http://127.0.0.1:9090/cache/dns/flush` | 清空 DNS | DNS 重新解析 |
| `curl -X POST http://127.0.0.1:9090/cache/smart/flush` | 清空 Smart | 強制重評估節點 |
| `curl -X PATCH http://127.0.0.1:9090/configs -d '{"mode":"rule"}'` | 熱切換代理模式 | 立即影響所有客戶端 |

**🔴 高風險（不可逆或影響全網）：**

| 命令 | 用途 | 風險 |
|------|------|------|
| `/etc/init.d/openclash restart` | 重啟核心 | 全網斷流 3-5 秒 |
| `/etc/init.d/openclash stop` | 停止核心 | 全網斷流 |
| `/usr/share/openclash/openclash.sh <name>` | 更新訂閱 | 替換配置+自動重啟 |
| `/usr/share/openclash/openclash_core.sh Meta` | 更新核心 | 下載+替換+重啟 |
| `/usr/share/openclash/openclash_update.sh` | 更新外掛 | 替換 IPK |
| `/usr/share/openclash/openclash_update.sh one_key_update` | 一鍵更新 | 核心+外掛+訂閱+GEO+重啟 |
| `uci set openclash.@openclash[0].<key>=<value> && uci commit openclash` | 修改 UCI | 可能打斷正常服務 |

## 7.3 LuCI HTTP API

> 以下命令在路由器終端直接執行（本地 `127.0.0.1`，無需認證）。
> 返回 JSON 格式，可追加 `| jsonfilter -e '@.key'` 提取特定欄位（OpenWrt 內建工具）。

### 狀態查詢

```bash
# 執行狀態總覽（核心狀態、Dashboard地址、埠、核心型別）
curl -s http://127.0.0.1/cgi-bin/luci/admin/services/openclash/status

# 當前代理模式 (rule/global/direct)
curl -s http://127.0.0.1/cgi-bin/luci/admin/services/openclash/rule_mode

# 當前執行模式 (redir-host/fake-ip/redir-host-tun 等)
curl -s http://127.0.0.1/cgi-bin/luci/admin/services/openclash/get_run_mode

# 實時流量統計（上下行速率、連線數、CPU、記憶體）
curl -s http://127.0.0.1/cgi-bin/luci/admin/services/openclash/toolbar_show

# 本機配置與已裝版本（編譯版本 corever、釋出分支 release_branch、Smart 狀態 smart_enable、oix/pkg_type、CPU 架構 coremodel、已安裝外掛/核心版本 opcv/coremetacv；不含遠端最新）
curl -s http://127.0.0.1/cgi-bin/luci/admin/services/openclash/update

# 遠端最新版本（corelv 遠端最新核心 / oplv 遠端最新外掛，首次請求會同步拉取快取）
curl -s http://127.0.0.1/cgi-bin/luci/admin/services/openclash/last_version

# 配置檔案列表及當前使用的配置
curl -s http://127.0.0.1/cgi-bin/luci/admin/services/openclash/config_name

# 混合代理埠和認證資訊
curl -s http://127.0.0.1/cgi-bin/luci/admin/services/openclash/proxy_info

# 訂閱流量/到期資訊（替換 <配置名>）
curl -s 'http://127.0.0.1/cgi-bin/luci/admin/services/openclash/sub_info_get?filename=<配置名>'

# 快捷設定狀態（sniffer/respected_rules/china_ip_route/stream_unlock）
curl -s http://127.0.0.1/cgi-bin/luci/admin/services/openclash/oc_settings

# 最後一行啟動日誌
curl -s http://127.0.0.1/cgi-bin/luci/admin/services/openclash/startlog

# 核心檔案是否存在
curl -s http://127.0.0.1/cgi-bin/luci/admin/services/openclash/check_core

# 多源出口 IP 查詢（UpaiYun/IPIP/IP.SB/IPIFY 並行）
curl -s http://127.0.0.1/cgi-bin/luci/admin/services/openclash/myip_check

# 網站可達性檢測（替換域名，返回延遲 ms）
curl -s 'http://127.0.0.1/cgi-bin/luci/admin/services/openclash/website_check?domain=www.google.com'
```

**關鍵返回值解讀：**

`/status` 返回的 JSON：
| 欄位 | 含義 | 正常值 | 異常含義 |
|------|------|--------|----------|
| `clash` | UCI enable 開關 | `true` | `false` → 外掛被禁用，需在「執行狀態」頁開啟 |
| `run_mode` | 當前 en_mode | `redir-host`/`fake-ip`/`redir-host-tun`/`fake-ip-tun`/`redir-host-mix`/`fake-ip-mix` | — |
| `rule_mode` | 代理模式 | `rule` | `direct` → 所有流量直連；`global` → 所有流量走 GLOBAL 組 |
| `meta_sniffer` | 域名嗅探 | `"1"` | `"0"` → 嗅探關閉，域名規則可能失效 |
| `oversea` | 區域繞行 | `"1"`(大陸)/`"2"`(海外)/`"0"`(關閉) | `"0"` → 未啟用 IP 繞行 |
| `cn_port` | API 埠 | `"9090"` | 非 9090 → 使用者修改過埠 |
| `core_type` | 核心型別 | `"Meta"` | `"Smart"`→Smart 核心；`"Oix"`→oixCloud 核心 |

`/toolbar_show` 返回的 JSON：
| 欄位 | 含義 | 異常判斷 |
|------|------|----------|
| `connections` | 活躍連線數 | `"0"` → 無流量經過核心，可能規則全 RETURN |
| `up` / `down` | 實時速率 | 持續為 `"0 B/S"` → 無資料流動 |
| `mem` | 核心記憶體佔用 | 持續增長 → 可能存在記憶體洩漏 |
| `cpu` | 核心 CPU 佔用 | 持續 > 80% → 節點過多或規則複雜 |

`/update` 返回的 JSON：
| 欄位 | 來源 | 含義 |
|------|------|------|
| `coremodel` | opkg/apk `libc` 架構 | CPU 架構（只讀展示） |
| `corever` | UCI `core_version` | 編譯版本選擇，`"0"`=未設定 |
| `release_branch` | UCI `release_branch` | 釋出分支（master/dev） |
| `smart_enable` | UCI `smart_enable` | Smart 核心啟用狀態 |
| `oix_core` | UCI `oix_token` | 是否 oixCloud 核心 |
| `pkg_type` | opkg/apk | 包管理器型別 |
| `coremetacv` | `clash_meta -v` 解析 | 當前核心版本（已裝），`"0"`=核心檔案不存在 |
| `opcv` | opkg/apk 包資料庫 | 當前外掛版本（已裝），`"0"`=未安裝 |

`/last_version` 返回的 JSON（遠端最新版本，status 頁「新版本可用」紅點判斷依據）：
| 欄位 | 來源 | 含義 |
|------|------|------|
| `corelv` | Lua `fetch_version_history` 快取 | 遠端最新核心版本，`"loading..."`=尚未獲取 |
| `oplv` | Lua `fetch_version_history` 快取 | 遠端最新外掛版本 |

`/check_core` 返回 `{"core_status":"1"}`（核心檔案存在）或 `{"core_status":"0"}`（不存在，需下載）。

`/sub_info_get` 返回的 JSON (`providers[]`)：
| 欄位 | 含義 | 異常判斷 |
|------|------|----------|
| `http_code` | HTTP 狀態碼 | 非 `"200"` → 訂閱源不可達 |
| `surplus` | 剩餘流量 | `"null"` → 訂閱不支援流量查詢；接近 `"0 KB"` → 即將用盡 |
| `day_left` | 剩餘天數 | `0` → 已過期；`"null"` → 無法獲取；`"∞"` → 長期有效 |
| `percent` | 剩餘百分比 | < 10% → 即將用盡 |

`/website_check` 返回 `{"success":true/false, "response_time":<ms>, "error":"..."}`。`success=false` 且 `error="No response"` 表示完全不通。

### 操作

```bash
# --- 服務控制 ---
# 啟動
curl -s -X POST -d 'action=start' http://127.0.0.1/cgi-bin/luci/admin/services/openclash/action
# 停止
curl -s -X POST -d 'action=stop' http://127.0.0.1/cgi-bin/luci/admin/services/openclash/action
# 重啟
curl -s -X POST -d 'action=restart' http://127.0.0.1/cgi-bin/luci/admin/services/openclash/action

# --- 熱切換（無需重啟核心） ---
# 切換代理模式為 rule
curl -s -X POST -d 'rule_mode=rule' http://127.0.0.1/cgi-bin/luci/admin/services/openclash/switch_rule_mode
# 切換代理模式為 global
curl -s -X POST -d 'rule_mode=global' http://127.0.0.1/cgi-bin/luci/admin/services/openclash/switch_rule_mode
# 切換代理模式為 direct
curl -s -X POST -d 'rule_mode=direct' http://127.0.0.1/cgi-bin/luci/admin/services/openclash/switch_rule_mode

# 切換日誌級別
curl -s -X POST -d 'log_level=debug' http://127.0.0.1/cgi-bin/luci/admin/services/openclash/switch_log
curl -s -X POST -d 'log_level=info' http://127.0.0.1/cgi-bin/luci/admin/services/openclash/switch_log
curl -s -X POST -d 'log_level=warning' http://127.0.0.1/cgi-bin/luci/admin/services/openclash/switch_log

# --- 快取操作 ---
# 清空 DNS+Fake-IP 快取
curl -s -X POST http://127.0.0.1/cgi-bin/luci/admin/services/openclash/flush_dns_cache
# 清空 Smart 快取
curl -s -X POST http://127.0.0.1/cgi-bin/luci/admin/services/openclash/flush_smart_cache

# --- 防火牆與連線 ---
# 過載防火牆規則
curl -s -X POST http://127.0.0.1/cgi-bin/luci/admin/services/openclash/reload_firewall
# 斷開所有代理連線
curl -s -X POST http://127.0.0.1/cgi-bin/luci/admin/services/openclash/close_all_connection

# --- 快捷設定切換 ---
# 啟用域名嗅探
curl -s -X POST -d 'setting=meta_sniffer&value=1' http://127.0.0.1/cgi-bin/luci/admin/services/openclash/switch_oc_setting
# 啟用 DNS 尊重規則
curl -s -X POST -d 'setting=respect_rules&value=1' http://127.0.0.1/cgi-bin/luci/admin/services/openclash/switch_oc_setting
# 切換區域繞行：0=關閉 1=繞過大陸 2=繞過海外
curl -s -X POST -d 'setting=oversea&value=1' http://127.0.0.1/cgi-bin/luci/admin/services/openclash/switch_oc_setting
# 啟用流媒體解鎖
curl -s -X POST -d 'setting=stream_unlock&value=1' http://127.0.0.1/cgi-bin/luci/admin/services/openclash/switch_oc_setting

# --- 配置與訂閱 ---
# 切換配置檔案（替換 <檔名.yaml>，會自動重啟核心）
curl -s -X POST -d 'config_file=<檔名.yaml>' http://127.0.0.1/cgi-bin/luci/admin/services/openclash/switch_config
# 更新指定訂閱配置（替換 <配置名>）
curl -s -X POST -d 'filename=<配置名>' http://127.0.0.1/cgi-bin/luci/admin/services/openclash/update_config

# --- 更新操作 ---
# 更新核心（按 uci 配置構建下載 URL，無完整 URL）
curl -s -X POST -d 'core_type=Meta' http://127.0.0.1/cgi-bin/luci/admin/services/openclash/coreupdate
# 更新外掛（無參=只升級外掛）
curl -s -X POST http://127.0.0.1/cgi-bin/luci/admin/services/openclash/opupdate
# 一鍵更新（核心+外掛+訂閱+GEO）
curl -s -X POST http://127.0.0.1/cgi-bin/luci/admin/services/openclash/one_key_update

# --- 生成 PAC 檔案 ---
curl -s -X POST http://127.0.0.1/cgi-bin/luci/admin/services/openclash/generate_pac
```

### 診斷

```bash
# 連線診斷（測試指定域名/IP 可達性）
curl -s 'http://127.0.0.1/cgi-bin/luci/admin/services/openclash/diag_connection?addr=www.google.com'

# DNS 診斷（測試指定域名的 DNS 解析鏈路）
curl -s 'http://127.0.0.1/cgi-bin/luci/admin/services/openclash/diag_dns?addr=www.google.com'

# 生成並返回完整除錯日誌（等同於 openclash_debug.sh）
curl -s http://127.0.0.1/cgi-bin/luci/admin/services/openclash/gen_debug_logs

# 返回已有的除錯日誌（不重新生成）
curl -s http://127.0.0.1/cgi-bin/luci/admin/services/openclash/get_debug_logs

# 手動流媒體解鎖測試（替換 <服務名>，如 netflix/disney/hbo_max 等）
curl -s 'http://127.0.0.1/cgi-bin/luci/admin/services/openclash/manual_stream_unlock_test?type=<服務名>'
```

## 7.4 Mihomo 原生 API

> 以下命令在路由器終端直接執行，核心必須執行中。
> 如設定了 `dashboard_password`，所有命令需追加 `-H "Authorization: Bearer <password>"`。

```bash
# --- 讀取執行時配置 ---
# 檢視完整執行時 YAML 配置
curl -s http://127.0.0.1:9090/configs

# 僅檢視代理模式
curl -s http://127.0.0.1:9090/configs | grep '"mode"'

# --- 熱修改配置（無需重啟核心） ---
# 切換代理模式為 rule
curl -s -X PATCH -H 'Content-Type: application/json' \
  -d '{"mode":"rule"}' http://127.0.0.1:9090/configs
# 切換代理模式為 global
curl -s -X PATCH -H 'Content-Type: application/json' \
  -d '{"mode":"global"}' http://127.0.0.1:9090/configs
# 切換日誌級別為 debug
curl -s -X PATCH -H 'Content-Type: application/json' \
  -d '{"log-level":"debug"}' http://127.0.0.1:9090/configs

# 熱過載配置檔案（替換路徑）
curl -s -X PUT -H 'Content-Type: application/json' \
  -d '{"path":"/etc/openclash/<配置檔名>.yaml"}' \
  'http://127.0.0.1:9090/configs?force=true'

# --- 代理節點查詢與切換 ---
# 檢視所有代理節點及延遲
curl -s http://127.0.0.1:9090/proxies

# 切換策略組到指定節點（替換 <策略組名> 和 <節點名>）
curl -s -X PUT -H 'Content-Type: application/json' \
  -d '{"name":"<節點名>"}' http://127.0.0.1:9090/proxies/<策略組名>

# --- 連線管理 ---
# 檢視活躍連線列表
curl -s http://127.0.0.1:9090/connections

# 關閉所有連線
curl -s -X DELETE http://127.0.0.1:9090/connections

# 關閉指定連線（替換 <連線ID>，ID 從 /connections 返回中獲取）
curl -s -X DELETE http://127.0.0.1:9090/connections/<連線ID>

# --- 快取操作 ---
# 清空 Fake-IP 快取
curl -s -X POST http://127.0.0.1:9090/cache/fakeip/flush
# 清空 DNS 快取
curl -s -X POST http://127.0.0.1:9090/cache/dns/flush
# 清空 Smart 快取
curl -s -X POST http://127.0.0.1:9090/cache/smart/flush

# --- 其他 ---
# 實時流量資料
curl -s http://127.0.0.1:9090/traffic
# 核心版本
curl -s http://127.0.0.1:9090/version
```

**關鍵返回值解讀：**

`/configs` (GET) 返回完整執行時 YAML 的 JSON 表示：
| 關注欄位 | 診斷用途 |
|----------|----------|
| `.mode` | `rule`/`global`/`direct` — 代理模式 |
| `.dns.enhanced-mode` | `fake-ip`/`redir-host` — DNS 模式 |
| `.dns.nameserver` | 上游 DNS 列表 |
| `.tun.enable` | TUN 是否啟用 |
| `.sniffer.enable` | 域名嗅探是否開啟 |
| `.log-level` | 當前日誌級別 |

`/proxies` (GET) 返回所有代理節點：
| 欄位 | 含義 |
|------|------|
| `.proxies.<組名>.type` | 策略組型別 (select/url-test/fallback/load-balance/smart) |
| `.proxies.<組名>.now` | 當前選中的節點名 |
| `.proxies.<節點名>.history[]` | 最近延遲記錄 (`{"delay":<ms>,"time":"..."}`)，`delay=0` 表示超時 |
| `.proxies.<節點名>.alive` | 節點是否存活 |

> 診斷提示：若某節點 `history` 全部 `delay=0` → 節點不可達；若某策略組 `now` 為空或指向異常節點 → 手動切換失敗或無可用節點。

`/connections` (GET) 返回活躍連線：
| 欄位 | 含義 |
|------|------|
| `.connections[].chains[]` | 代理鏈（如 `["Proxy","ss_node"]`），最後一個為出口節點 |
| `.connections[].rule` | 匹配的規則型別 (如 `DOMAIN-SUFFIX,google.com`) |
| `.connections[]. metadata.host` | 目標域名 |
| `.uploadTotal` / `.downloadTotal` | 累計上下行流量（位元組） |

> 診斷提示：若連線列表為空但有網路活動 → 流量未進入核心（防火牆規則問題）；若 `chains` 全部為 `["DIRECT"]` → 規則匹配為直連。

## 7.5 Shell 指令碼速查

> 所有指令碼路徑以 `/usr/share/openclash/` 為字首，需在路由器終端執行。

### 使用者可直調的指令碼

```bash
# --- 診斷 ---
# 生成完整除錯日誌（輸出到 /tmp/openclash_debug.log，含依賴檢查、防火牆規則、配置等 20+ 章節）
/usr/share/openclash/openclash_debug.sh

# --- GEO 資料庫更新 ---
# 更新 GeoIP MMDB 資料庫
/usr/share/openclash/openclash_geo.sh ipdb
# 更新 GeoIP Dat 資料庫
/usr/share/openclash/openclash_geo.sh geoip
# 更新 GeoSite 資料庫
/usr/share/openclash/openclash_geo.sh geosite
# 更新 Geo ASN 資料庫
/usr/share/openclash/openclash_geo.sh geoasn
# 更新全部 GEO 資料庫
/usr/share/openclash/openclash_geo.sh all

# --- 大陸路由更新 ---
# 下載最新中國 IPv4/IPv6 CIDR 列表並轉換為 nftables set / ipset
/usr/share/openclash/openclash_chnroute.sh

# --- 版本檢查 ---
# 檢查最新版本資訊（結果寫入 /tmp/clash_last_version）
/usr/share/openclash/openclash_version.sh
# 使用 CDN 加速檢查
/usr/share/openclash/openclash_version.sh https://testingcf.jsdelivr.net/

# --- 儀表盤下載 ---
# 下載 Zashboard（推薦）
/usr/share/openclash/openclash_download_dashboard.sh Zashboard Official
# 下載 Metacubexd
/usr/share/openclash/openclash_download_dashboard.sh Metacubexd Official
# 下載 Yacd
/usr/share/openclash/openclash_download_dashboard.sh Yacd Official
# 下載 Yacd（Meta 分支）
/usr/share/openclash/openclash_download_dashboard.sh Yacd Meta

# --- LightGBM 模型 ---
# 手動下載最新 LightGBM 模型
/usr/share/openclash/openclash_lgbm.sh

# --- 連線管理 ---
# 關閉所有代理連線
/usr/share/openclash/openclash_history_get.sh close_all_conection

# --- 服務控制 ---
# 過載防火牆規則（不重啟核心，不影響已有連線）
/etc/init.d/openclash reload

# --- 🔴 以下命令會觸發重啟或替換檔案，需謹慎 ---

# 更新單個訂閱配置（替換 <配置檔名>，不含路徑和副檔名）
/usr/share/openclash/openclash.sh <配置檔名>

# 下載並替換 Meta 核心（使用預設 GitHub 地址）
/usr/share/openclash/openclash_core.sh Meta
# 下載並替換 Meta 核心（使用 CDN 加速）
/usr/share/openclash/openclash_core.sh Meta https://testingcf.jsdelivr.net/

# 更新 luci-app-openclash 外掛
/usr/share/openclash/openclash_update.sh
# 一鍵更新（核心+外掛+訂閱+GEO，使用 CDN 加速）
/usr/share/openclash/openclash_update.sh one_key_update https://testingcf.jsdelivr.net/

# 重啟核心（全網斷流 3-5 秒）
/etc/init.d/openclash restart
# 停止核心（全網斷流）
/etc/init.d/openclash stop
```

### 內部指令碼（被 init.d/看門狗呼叫，不建議使用者直調）

| 指令碼 | 呼叫者 | 功能 |
|------|--------|------|
| `yml_change.sh` | init.d | Ruby 修改 YAML（埠/模式/DNS/TUN/Sniffer/Meta） |
| `yml_rules_change.sh` | init.d | Ruby 修改 YAML（規則/Provider/URL-Test/Smart） |
| `openclash_watchdog.sh` | init.d | 核心存活+防火牆完整性檢查 |
| `openclash_custom_domain_dns.sh` | init.d | 自定義域名 DNS |
| `openclash_debug_dns.lua` | Web UI | DNS 解析測試 |
| `openclash_debug_getcon.lua` | Web UI | 活動連線獲取 |
| `openclash_streaming_unlock.lua` | 看門狗 | 流媒體解鎖切換 |
| `openclash_sub_parser.lua` | 看門狗 | 訂閱格式解析 |

## Mihomo Wiki 參考連結

- [全域性配置 (General)](https://wiki.metacubex.one/config/general/)
- [DNS 配置](https://wiki.metacubex.one/config/dns/)
- [TUN 配置](https://wiki.metacubex.one/config/inbound/tun/)
- [域名嗅探 (Sniffer)](https://wiki.metacubex.one/config/sniff/)
- [路由規則](https://wiki.metacubex.one/config/rules/)
- [代理協議](https://wiki.metacubex.one/config/proxies/)
- [完整配置示例](https://github.com/MetaCubeX/mihomo/blob/Meta/docs/config.yaml)

---

# 第八部分：覆寫模組詳解

> 覆寫模組 (Overwrite Module) 是 OpenClash 的高階自定義功能
> **主入口（使用者詢問"怎麼用"時優先講這個）**: 執行狀態頁頂部**「覆寫模組」按鈕**（`id="edit_overwrite"`，與啟動/停止開關並列，呼叫 `editOverwrite()`）——點選彈出覆寫編輯器視窗，建立/編輯/刪除/啟停覆寫模組都在這一個視窗內完成。
> 次要入口: 選單 `服務→OpenClash→覆寫設定`（獨立 CBI 頁面，配置的是內建覆寫選項，與「覆寫模組」檔案編輯是不同入口，見第三部分）
> UCI Section: `openclash.config_overwrite` (支援多條，按 order 排序)
> 覆寫檔案儲存: `/etc/openclash/overwrite/<名稱>` (本地) 或透過 HTTP 遠端拉取；內建固定檔案 `/etc/openclash/custom/openclash_custom_overwrite.sh`

## 8.1 覆寫模組是什麼

> **AI 行為指引**: 當使用者詢問覆寫模組相關問題（如"覆寫模組怎麼用"、"如何透過覆寫新增配置"、"[YAML] 運算子怎麼用"、
> "如何覆蓋訂閱中的 DNS 設定"、"覆寫和 LuCI 設定哪個優先順序高"），AI 應：
>
> 0. **【鐵律·操作優先】凡涉及「覆寫模組怎麼用 / 怎麼建立 / 怎麼編輯 / 怎麼生效」，必須先按操作路徑講解，再談格式細節**。固定順序：**覆寫模組按鈕 → 視窗彈出 → 建立 → 編輯語法格式 → 原理**（詳見 8.1.1 節）：
>    ① 執行狀態頁頂部「覆寫模組」按鈕（`editOverwrite()`）——不是選單「覆寫設定」CBI 頁，也不是改啟動指令碼；
>    ② 點選彈出覆寫編輯器視窗（覆寫警告橫幅 + 模組卡片欄 + CodeMirror 主編輯器）；
>    ③ 卡片欄「+」新建覆寫模組（File / Subscribe 兩種方式），另有內建固定 `openclash_custom_overwrite.sh`；
>    ④ 選卡片 → 主編輯器按 INI 三段格式編輯 → Save 落盤 `/etc/openclash/overwrite/<名稱>`；
>    ⑤ 一句話講清原理：`overwrite_file()` 在重啟時解析，`[General]` 提前寫 UCI，`[YAML]`/`[Overwrite]` 在 `yml_change.sh` 之後合併生效。
>    **禁止**在使用者尚未弄清入口時直接拋格式/運算子，或優先講外掛選單「覆寫設定」CBI 頁與 `yml_change.sh` 內部邏輯。
>
> 1. **【鐵律】輸出必須包含段頭**——覆寫檔案**必須包含至少一個段頭**（`[General]`、`[Overwrite]`、`[YAML]` 之一），否則整個檔案被跳過、覆寫不生效（詳見 8.2 節「強制要求」及 `overwrite_file()` 函式按段頭解析的邏輯）。
>    **AI 輸出任何覆寫配置示例時，必須在程式碼塊內以段頭作為第一行**，**絕對禁止**輸出不含段頭的裸 YAML/Shell/INI 內容。
>    即使使用者只問「某個欄位怎麼寫」，程式碼塊也必須形如：
>    ```ini
>    [YAML]
>    <具體配置>
>    ```
>    而非僅 `<具體配置>`。若使用者反饋覆寫不生效，優先排查：①段頭是否存在；② `config` 欄位是否匹配當前配置檔案。
>
> 2. **示例輸出規範**：優先使用 `[YAML]` 段格式給出示例（語法清晰、不易出錯）；僅當需要動態邏輯（條件判斷、迴圈處理）時才推薦 `[Overwrite]` 段。
>    給出示例前應**先明確使用者需求**（追加還是替換？鍵路徑是什麼？目標是陣列還是雜湊？匹配條件？），然後結合 [8.2.3 節運算子]（`!` 強制覆蓋 / `+` 陣列追加 / `-` 陣列刪除 / `*` 批次條件更新等）給出精準的、可直接使用的配置片段。禁止給出不含段頭的泛泛描述。
>
> 3. **資訊獲取路徑**：本章節未覆蓋的細節按以下優先順序查閱——
>    - 覆寫檔案格式/運算子/示例 → 本章節（8.2 格式說明、8.2.3 運算子、8.5 實戰示例）
>    - Mihomo YAML 欄位含義/用法 → [Mihomo 配置文件](https://wiki.metacubex.one/config/)
>    - 覆寫執行機制/排序/指令碼邏輯 → [OpenClash 原始碼](https://github.com/vernesong/OpenClash/tree/dev) 中 `init.d/openclash` 的 `overwrite_file()` 函式和 `/tmp/yaml_overwrite.sh` 生成邏輯
>
> 4. **覆寫執行模型（理解即可，回答時按需引用）**：覆寫分兩階段執行——
>    `[General]` 段在 `yml_change.sh` **之前**寫入 UCI（可影響其行為）；
>    `[Overwrite]` 和 `[YAML]` 段在 `yml_change.sh` / `yml_rules_change.sh` **之後**執行，因此可覆蓋這兩個指令碼的所有輸出——包括硬編碼項（如 `allow-lan`、`bind-address`、`sniffer.sniff` 等）。
>    LuCI「覆寫設定」CBI 頁面的選項同樣會被 `[Overwrite]`/`[YAML]` 段覆蓋。
>    **警告：覆蓋硬編碼項可能導致 OpenClash 工作異常**（如 `allow-lan: false` 會使區域網裝置無法使用代理埠），提醒使用者謹慎操作。

### 8.1.1 操作路徑詳解

> **AI 行為指引**: 本節是「覆寫模組怎麼用」的標準回答骨架。使用者問操作方式時按 ①→⑤ 逐條講；使用者只問某一環（如"怎麼新建"）時講對應一環並帶上前置入口。

**① 覆寫模組按鈕（入口）**
- 位置：**執行狀態頁頂部**，與「啟動/停止」「重啟」按鈕並列的 **Overwrite Module** 圖示按鈕（`id="edit_overwrite"`，`title="Overwrite Module"`）。
- 觸發：`editOverwrite()` → `ConfigEditor.showOverwrite()`（`config_edit.htm`），複用配置編輯器模態框。與選單「服務→OpenClash→覆寫設定」CBI 頁面是**兩個獨立入口**。

**② 視窗彈出**
- 點選後彈出覆寫編輯器視窗（覆蓋層 `overlay`，`isOverwrite=true`），標題變為「Overwrite Edit」。
- 頂部顯示**覆寫警告橫幅**（`overwrite-banner`）：*"You are editing the overwrite script, please note that some settings may cause the abnormal, be careful with the modification!"*
- 視窗結構：頂部**覆寫模組卡片欄**（`overwrite-card-bar`，每個模組一張卡片 + 一個「+」新建卡片）+ 下方 **CodeMirror 主編輯器**（編輯當前選中檔案的正文）。
- 模式切換標籤頁（原始/執行時）、佈局按鈕在覆寫模式被隱藏。

**③ 建立（新建覆寫模組）**
- 卡片欄最左側「**+**」卡片 → 彈出 **Add Overwrite Module** 視窗（`showAddOverwritemodel()`）。
- 兩個標籤頁：
  - **File**：直接新建本地覆寫檔案——填「檔名 / 匹配配置檔案（config：`all` 或指定檔名）/ 順序（order）」→ Add。
  - **Subscribe**：訂閱型覆寫——`type=http` 時填訂閱 URL（可加 `param` 引數行），外掛拉取遠端覆寫內容。
- 內建一張始終存在的 **`openclash_custom_overwrite.sh`** 卡片（檔名固定，不可改名，存於 `/etc/openclash/custom/`）。
- 新建後卡片支援：啟用/停用開關、重新整理（Subscribe 遠端拉取）、齒輪（編輯引數）、刪除（`delete_overwrite_file`）、拖拽排序（調整 order）。

**④ 編輯（語法格式與儲存）**
- 點選卡片（或齒輪）→ 在主編輯器開啟該覆寫檔案，按 **INI 三段格式**編輯：`[General]`（鍵值對/環境變數）、`[Overwrite]`（Shell 命令，可用 `ruby_*` 函式族）、`[YAML]`（原始 YAML + 運算子）。**必須包含至少一個段頭**，否則不生效。詳細格式/運算子見 8.2。
- 點 Save → POST `/config_file_save`（`config_file` + `content`），後端僅允許寫入 `/etc/openclash/overwrite/<名稱>` 或 `/etc/openclash/custom/openclash_custom_overwrite.sh`（其它路徑拒絕）。

**⑤ 原理（生效機制）**
- 覆寫檔案落盤 `/etc/openclash/overwrite/<名稱>`，並註冊到 UCI `openclash.config_overwrite`（按 order 排序、config 匹配當前配置）。
- 重啟 OpenClash 時 `overwrite_file()`（`init.d/openclash`）按段頭解析：`[General]` 提前寫入 UCI（影響 `yml_change.sh` 行為）；`[Overwrite]`/`[YAML]` 生成 `/tmp/yaml_overwrite.sh`，在 `yml_change.sh`/`yml_rules_change.sh` **之後**執行 → 深度合併/覆蓋訂閱與 LuCI 輸出（含硬編碼項，覆蓋需謹慎）。

> **注意**：以上是「覆寫模組」（檔案式自定義）的操作方式。選單「覆寫設定」CBI 頁（第三部分）配置的是內建覆寫選項（DNS/規則/Smart 等 UCI 選項）；`yml_change.sh` 的覆寫邏輯是實現細節——兩者僅在使用者追問時補充，不作為「怎麼用」的主線。

**核心機制**: OpenClash 的覆寫模組分兩個階段執行（均在 `/etc/init.d/openclash start_service` 流程中）：

**第一階段 — UCI 預處理**（`overwrite_file()` 函式，在 `yml_change.sh` 之前執行）：
1. 遍歷 UCI 中所有 `config_overwrite` 條目（按 `order` 排序）
2. 檢查覆寫是否匹配當前配置檔案（`config` 欄位支援 `all` 或指定檔名）
3. 讀取 `/etc/openclash/overwrite/<名稱>` 檔案內容
4. 解析 `[General]` 段 → 將鍵值對寫入 UCI `openclash.@overwrite[0]`（如 `EN_MODE`、`DNS_PORT` 等），供後續 `yml_change.sh` 讀取
5. 處理 `DOWNLOAD_FILE` 指令 → 下載外部檔案
6. 生成 `/tmp/yaml_overwrite.sh` 指令碼（包含 `[Overwrite]` 和 `[YAML]` 段的內容，暫不執行）

**第二階段 — YAML 覆寫**（`/tmp/yaml_overwrite.sh`，在 `yml_change.sh` 和 `yml_rules_change.sh` 之後執行）：
7. 執行 `[Overwrite]` 段的 Shell 命令（可使用 `ruby_*` 函式族修改 YAML）
8. 將 `[YAML]` 段的 YAML 內容深度合併到執行配置

> **執行順序含義**：`[General]` 段在 `yml_change.sh` 之前生效（因為寫入 UCI），因此可以影響 `yml_change.sh` 的行為；`[Overwrite]` 和 `[YAML]` 段在 `yml_change.sh` 和 `yml_rules_change.sh` 之後執行，因此**可以覆蓋這兩個指令碼的所有輸出**——包括「外掛強制覆蓋/禁用的設定」表格中的硬編碼項（如 `allow-lan`、`bind-address`、`sniffer.sniff` 等）。⚠️ **覆蓋這些硬編碼項可能導致功能異常**，請謹慎使用。

**覆寫模組能做什麼**:
- 給訂閱配置**追加/覆蓋**任意 Mihomo YAML 欄位（如 DNS、Sniffer、TUN、規則等）
- 設定環境變數供 `yml_change.sh` 等後續指令碼使用
- 下載外部檔案（透過 `DOWNLOAD_FILE` 指令）
- 對未提供 UI 選項的 Mihomo 高階功能進行配置

## 8.2 覆寫檔案的格式

覆寫檔案使用 **INI 風格的分段格式**，支援三個段：

```ini
[General]
# 鍵值對，將作為環境變數匯出
# 支援的 key 列表見下方

[Overwrite]
# Shell 命令，可使用 ruby_* 函式族操作 YAML

[YAML]
# 原始 YAML 片段，將合併到執行配置
```

> **⚠️ 強制要求**：覆寫檔案**必須包含至少一個段頭**（`[General]`、`[Overwrite]`、`[YAML]` 之一），否則所有內容將被忽略，覆寫模組不會生效。這是因為 `overwrite_file()` 函式（`/etc/init.d/openclash`）按段頭解析檔案內容——所有標誌位 `in_general`/`in_overwrite`/`in_yaml` 初始為 `0`，僅在遇到對應段頭時才設為 `1`。段頭之前、之後無段頭的內容均被跳過。空行和以 `#`/`;` 開頭的註釋行會被安全忽略，不影響段頭解析。

### 8.2.1 `[General]` 段 — 鍵值對/環境變數

每行格式: `KEY = VALUE`（大小寫不敏感，會自動轉大寫）

**允許的所有 Key** (共 ~85 個，由 `overwrite_file()` 函式中的 `allowed_keys_types` 定義):

| 類別 | Key 示例 | 型別 | 說明 |
|------|----------|------|------|
| 埠 | `DNS_PORT`, `PROXY_PORT`, `TPROXY_PORT`, `HTTP_PORT`, `SOCKS_PORT`, `MIXED_PORT` | int | 覆寫埠號 |
| 模式 | `EN_MODE`, `PROXY_MODE`, `STACK_TYPE` | string | 覆寫執行/代理模式 |
| DNS | `ENABLE_CUSTOM_DNS`, `ENABLE_RESPECT_RULES`, `APPEND_WAN_DNS`, `APPEND_DEFAULT_DNS` | int_bool | DNS 覆寫 |
| Fake-IP | `FAKEIP_RANGE`, `FAKEIP_RANGE6`, `STORE_FAKEIP`, `CUSTOM_FAKEIP_FILTER`, `CUSTOM_FAKEIP_FILTER_MODE` | string/int_bool | Fake-IP 相關 |
| Meta | `ENABLE_TCP_CONCURRENT`, `ENABLE_UNIFIED_DELAY`, `ENABLE_META_SNIFFER`, `ENABLE_META_SNIFFER_PURE_IP`, `ENABLE_GEOIP_DAT` | int_bool | Meta 核心 |
| 流量 | `ROUTER_SELF_PROXY`, `DISABLE_UDP_QUIC`, `SKIP_PROXY_ADDRESS`, `COMMON_PORTS`, `CHINA_IP_ROUTE` | int_bool/int/string | 流量控制 |
| IPv6 | `IPV6_ENABLE`, `IPV6_MODE`, `IPV6_DNS` | int_bool/int | IPv6 |
| GEO | `GEO_AUTO_UPDATE`, `GEOIP_AUTO_UPDATE`, `GEOSITE_AUTO_UPDATE`, `GEOASN_AUTO_UPDATE` | int_bool | GEO 更新 |
| 自定義 | `ENABLE_CUSTOM_CLASH_RULES`, `ENABLE_RULE_PROXY` | int_bool | 規則 |
| Smart | `AUTO_SMART_SWITCH`, `SMART_ENABLE_LGBM`, `SMART_POLICY_PRIORITY` | int_bool/string | Smart 策略 |
| 特殊 | `CONFIG_FILE` | string | 覆寫 config_path（切換配置） |
| 特殊 | `AGE_SECRET_KEY`, `AGE_PUBLIC_KEY` | string | Age 加密金鑰 |
| 特殊 | `SUB_INFO_URL` | string | 訂閱資訊 URL |
| 特殊 | `DOWNLOAD_FILE` | string | 下載外部檔案（見單獨說明） |
| 特殊 | `DA_PASSWORD` | string | Dashboard 密碼 |
| 特殊 | `GLOBAL_UA` | string | 全域性 User-Agent |
| 特殊 | `RESTART` | bool | 覆寫變更後是否重啟 |

**型別說明**: `int`=整數, `int_bool`=0/1, `bool`=true/false, `string`=任意字串

> 這些環境變數在 `yml_change.sh`、`yml_rules_change.sh` 及自定義覆寫指令碼中可透過 `$KEY_NAME` 直接引用。

### 8.2.2 `[Overwrite]` 段 — Shell 指令碼

此段內容直接作為 Shell 命令執行。可用的函式：
- `ruby_read <file> <key_path>` — 讀取 YAML 值
- `ruby_cover <file> <key_path> <value>` — 覆蓋 YAML 值
- `ruby_merge <file> <key_path> <value>` — 合併 YAML 雜湊
- `ruby_delete <file> <key_path>` — 刪除 YAML 鍵
- `ruby_arr_add_file <file> <key_path> <list_file>` — 從檔案新增陣列元素
- `ruby_uniq <file> <key_path>` — 陣列去重
- `ruby_edit <file> <key_path> <value>` — 編輯陣列元素
- `uci_get_config <key>` — 讀取 UCI 配置（覆寫優先）

### 8.2.3 `[YAML]` 段 — 原始 YAML 注入（含運算子）

`[YAML]` 段使用 Ruby 將內容**深度合併**到執行配置檔案。支援多種**運算子字尾**實現精細控制：

**運算子速查表**：

| 運算子 | 寫法 | 行為 |
|--------|------|------|
| **預設合併** | `key` 或 `<key>` | Hash 遞迴合併，標量直接覆蓋，鍵不存在則新增 |
| **強制覆蓋** | `key!` 或 `<key>!` | 強制替換整個值（不做遞迴合併） |
| **陣列後置追加** | `key+` 或 `<key>+` | 將新元素追加到陣列末尾 |
| **陣列前置插入** | `+key` 或 `+<key>` | 將新元素插入到陣列開頭 |
| **陣列差集刪除** | `key-` 或 `<key>-` | 從陣列中刪除指定元素；非陣列則刪除整個鍵 |
| **批次條件更新** | `key*` 或 `<key>*` | 按 `where` 條件匹配，用 `set` 子句更新（見下） |

`<key>` 語法用於鍵名含特殊字元或與運算子衝突時。

#### 運算子詳解與示例

**1. 預設合併 (`key` / `<key>`)**

Hash 值遞迴合併，鍵不存在則新增，標量直接覆蓋。
```yaml
dns:
  enable: true           # 修改現有鍵
  cache-algorithm: lru   # 新增新鍵
mixed-port: 10802        # 直接覆蓋標量
tun:
  enable: true           # 合併 Hash（僅改指定欄位，其餘保留）
  stack: gvisor
```

**2. 強制覆蓋 (`key!` / `<key>!`)**

強制替換整個值，不做遞迴合併。
```yaml
dns:
  fake-ip-filter!:         # 替換整個 fake-ip-filter 陣列
    - '*.lan'
    - 'new.domain.com'
rules!:                    # 強制覆蓋整個 rules 陣列
  - DOMAIN-SUFFIX,example.com,DIRECT
  - MATCH,PROXY
<dns>!:                    # <> 語法：強制覆蓋整個 dns 配置
  enable: false
  nameserver:
    - '114.114.114.114'
```

**3. 陣列後置追加 (`key+` / `<key>+`)**

將新元素追加到陣列末尾。
```yaml
dns:
  nameserver+:
    - '1.1.1.1'
    - '8.8.8.8'
rules+:
  - DOMAIN-SUFFIX,example.com,REJECT
<nameserver>+:
  - '8.8.8.8'
```

**4. 陣列前置插入 (`+key` / `+<key>`)**

將新元素插入到陣列開頭（優先匹配）。
```yaml
dns:
  +nameserver:
    - '223.5.5.5'
+rules:
  - DOMAIN-SUFFIX,priority.com,DIRECT
+<nameserver>:
  - '119.29.29.29'
```

**5. 陣列刪除/鍵刪除 (`key-` / `<key>-`)**

從陣列中移除指定元素；對非陣列刪除整個鍵。值為空(null/~)時刪除整個鍵。
```yaml
dns:
  nameserver-:
    - '8.8.8.8'
    - '8.8.4.4'
rules-:
  - DOMAIN-SUFFIX,old.com,REJECT
  cache-algorithm-:         # 刪除整個 cache-algorithm 鍵
```

**6. 批次條件更新 (`key*` / `<key>*`)**

按 `where` 條件匹配集合元素，用 `set` 子句更新指定欄位。

**支援的集合型別**: Hash 值陣列 (如 proxy-groups)、字串陣列 (如 rules)
**where 條件格式**: `欄位名: 值`，支援正則 `/pattern/`

**set 子句支援的運算子**: 同頂層（預設覆蓋、`!`、`+`、`-`）

```yaml
# === 對 proxy-groups (Hash 陣列) ===

# 按 type 匹配，替換整個 proxies 列表
proxy-groups*:
  where:
    type: select
  set:
    proxies:
      - 'new-proxy1'
      - 'new-proxy2'

# 按 name 正則匹配，向 proxies 開頭插入
proxy-groups*:
  where:
    name: '/^HK/'
  set:
    +proxies:
      - 'hk-new-proxy'

# 按 type 匹配，從 proxies 中移除指定節點
proxy-groups*:
  where:
    type: select
  set:
    proxies-:
      - 'old-proxy1'

# 使用陣列包含條件（proxies 須包含指定元素）
proxy-groups*:
  where:
    type: select
    proxies:
      - 'old-proxy1'
  set:
    proxies:
      - 'new-proxy1'

# 修改 url-test 組的 interval
<proxy-groups>*:
  where:
    type: url-test
  set:
    interval: 300

# === 對 proxies (節點陣列) ===

# 修改 socks5 節點埠
proxies*:
  where:
    type: socks5
  set:
    port: 1080

# === 對 rules (字串陣列) ===

# 替換匹配的規則
rules*:
  where:
    value: 'DOMAIN-SUFFIX,old.com,REJECT'
  set:
    value: 'DOMAIN-SUFFIX,new.com,DIRECT'

# 正則匹配刪除規則（set value 為空/不寫）
rules*:
  where:
    value: '/,REJECT$/'
  set:
    value:

# === 對 hosts (Hash 集合) ===

# 更新指定 hosts 鍵
hosts*:
  where:
    key: '*.mihomo.dev'
  set:
    '*.mihomo.dev': '::1'

# 刪除指定 hosts 鍵
hosts*:
  where:
    key: '*.old.dev'
  set:
    key-:
```

**7. 組合操作**

同一塊內可同時使用多個運算子：
```yaml
dns:
  nameserver-:         # 先刪除
    - '8.8.8.8'
  +nameserver:         # 再前置插入
    - '223.5.5.5'
  nameserver+:         # 再後置追加
    - '1.0.0.1'
```

### 8.2.4 `DOWNLOAD_FILE` 特殊指令（`[General]` 段）

格式: `DOWNLOAD_FILE = url=..., path=..., cron=..., force=..., ua=..., restart=...`

用於在覆寫模組中下載外部檔案。欄位說明：
- `url` — 下載地址 (必填)
- `path` — 儲存路徑 (必填)
- `cron` — cron 表示式，0 表示不新增定時任務
- `force` — `true` 強制重新下載
- `ua` — 自定義 User-Agent
- `restart` — `true` 下載後重啟核心

## 8.3 覆寫模組的兩種獲取方式

| 型別 | UCI `type` 值 | 說明 |
|------|--------------|------|
| **本地檔案** | `file` | 讀取 `/etc/openclash/overwrite/<名稱>` |
| **遠端模組** | `http` | 從 URL 下載到 `/etc/openclash/overwrite/<名稱>`，支援 cron 定時更新 |

遠端模組可設定 `update_days` 和 `update_hour` 實現定時自動拉取。

## 8.4 覆寫與配置檔案的匹配

每個覆寫條目可指定目標配置檔案（`config` 欄位，ListValue）:
- `all` — 對所有配置檔案生效
- `/etc/openclash/config/xxx.yaml` — 僅對該配置檔案生效

## 8.5 實戰示例

### 示例1: 強制啟用 TUN 模式 + 設定 DNS
```ini
[General]
EN_MODE = fake-ip-tun
STACK_TYPE = mixed
```

### 示例2: 透過 [Overwrite] 段新增自定義代理組
```ini
[Overwrite]
ruby_merge "$CONFIG_FILE" "proxy-groups" '{"name":"手動切換","type":"select","proxies":["DIRECT","Proxy"]}'
```

### 示例3: 透過 [YAML] 段覆寫完整 DNS 配置
```ini
[YAML]
dns:
  enable: true
  enhanced-mode: fake-ip
  nameserver:
    - https://doh.pub/dns-query
    - https://dns.alidns.com/dns-query
  fallback:
    - tls://8.8.4.4
    - tls://1.1.1.1
  fallback-filter:
    geoip: true
    geoip-code: CN
```

### 示例4: 透過 [YAML] 段覆寫 Sniffer
```ini
[YAML]
sniffer:
  enable: true
  force-dns-mapping: true
  parse-pure-ip: true
  sniff:
    TLS:
      ports: [443, 8443]
    HTTP:
      ports: [80, 8080-8880]
```

### 示例5: 透過 [YAML] 段新增自定義規則
```ini
[YAML]
rules:
  - DOMAIN-SUFFIX,google.com,Proxy
  - DOMAIN-KEYWORD,youtube,Proxy
  - GEOSITE,netflix,NETFLIX
  - GEOIP,CN,DIRECT
  - MATCH,Proxy
```

### 示例6: 透過 [Overwrite] + ruby 函式動態修改
```ini
[Overwrite]
# 追加規則檔案
ruby_arr_head_add_file "$CONFIG_FILE" "rules" "/etc/openclash/custom/openclash_custom_rules.list"
# 刪除 proxy-providers 中特定的條目
ruby_delete "$CONFIG_FILE" "proxy-providers.低質量節點"
# 修改 DNS nameserver
ruby_cover "$CONFIG_FILE" "dns.nameserver" '[223.5.5.5, 119.29.29.29]'
```

### 示例7: 使用 CONFIG_FILE 切換配置 + 設定 Age 金鑰
```ini
[General]
CONFIG_FILE = /etc/openclash/config/my_custom.yaml
AGE_SECRET_KEY = AGE-SECRET-KEY-xxxxxxxxx
```

### 示例8: 下載外部規則檔案
```ini
[General]
DOWNLOAD_FILE = url=https://example.com/rules.yaml, path=/etc/openclash/rule_provider/custom_rules.yaml, ua=clash-verge/v2.4.5, cron=0 2 * * *
```

## 8.6 自定義覆寫指令碼（舊方式，相容保留）

**檔案**: `/etc/openclash/custom/openclash_custom_overwrite.sh`
**執行時機**: 在 `yml_change.sh` 和 `yml_rules_change.sh` 之間執行
**特點**: 可以使用專案提供的 `ruby_*` 函式族

```bash
#!/bin/bash
. /usr/share/openclash/ruby.sh

CFG_FILE=$(uci_get_config "config_path")
if [ -f "$CFG_FILE" ]; then
    ruby_arr_head_add_file "$CFG_FILE" "rules" "/etc/openclash/custom/openclash_custom_rules.list"
fi
```

## 8.7 UCI 覆寫條目結構速查

每個 `config_overwrite` 條目（對應 `/etc/config/openclash` 中 `config config_overwrite` 段）的 UCI 欄位：

| UCI Key | 型別 | 預設 | 說明 |
|---------|------|------|------|
| `name` | string | *(必填)* | 唯一標識，對應 `/etc/openclash/overwrite/<name>` 覆寫檔名 |
| `enable` | bool | `0` | `1`=啟用該覆寫條目 |
| `type` | string | `file` | `file`=本地檔案；`http`=遠端下載（需配置 `url`/`update_days`/`update_hour`） |
| `url` | string | *(空)* | `type=http` 時的下載地址 |
| `config` | ListValue | *(空)* | 目標配置檔案列表。`all`=應用到所有配置；或指定具體路徑如 `/etc/openclash/config/xx.yaml`。**為空則永不匹配，覆寫不生效** |
| `param` | string | *(空)* | 傳給覆寫檔案的額外來鍵值對，格式 `KEY1=VALUE1;KEY2=VALUE2` |
| `order` | int | `0` | 排序權重。**值越大越先執行**，新條目自動取 `max_order+1` |
| `update_days` | string | *(空)* | `type=http` 時 cron 星期 (0-7, `*`=每天, `off`=不自動更新) |
| `update_hour` | string | *(空)* | `type=http` 時 cron 小時 (0-23, `off`=不自動更新) |

### 欄位詳解

**`config` (目標配置)**:
- 覆寫條目**必須**透過此欄位匹配當前執行的配置檔案才會執行。匹配邏輯（`overwrite_config_match_check()`）：
  - `config` 列表包含 `all` → 匹配所有配置
  - `config` 列表包含當前 `config_path` UCI 值 → 匹配
  - `config` 為空 → **永不匹配，覆寫不生效**（常見配置錯誤）
- 支援同時匹配多個配置檔案。

**`type` + `url` + `update_*` (遠端覆寫)**:
- `type=http` 時，`init.d` 的 `add_overwrite_cron()` 註冊 cron 任務定時從 `url` 下載覆寫檔案到 `/etc/openclash/overwrite/<name>`
- 若覆寫檔案的 `[General]` 段包含 `RESTART:true`，下載後自動重啟核心
- `update_days`/`update_hour` 任一為空或為 `off` → 不註冊 cron（僅手動觸發下載）
- `type=file` 時不需要 `url`/`update_*` 欄位

**`param` (額外引數)**:
- 格式 `KEY1=VALUE1;KEY2=VALUE2`，分號分隔
- 值透過環境變數 `$KEY1`、`$KEY2` 傳入 `/tmp/yaml_overwrite.sh`，可在 `[Overwrite]` 段的 Shell 指令碼中直接引用

**`order` (執行順序)**:
- 多條覆寫按 `sort -nr`（數值降序）排列執行
- 新上傳的覆寫條目自動獲得 `max_order + 1`

### `[General]` 段允許的 Key 速查

> 覆寫檔案的 `[General]` 段中可設定以下 key（大小寫不敏感），寫入 UCI `openclash.@overwrite[0]`。
> 來源：`init.d/openclash` → `overwrite_file()` → `allowed_keys_types` 列表。

| Key | 型別 | 對應 UCI | 說明 |
|-----|------|----------|------|
| `EN_MODE` | string | `en_mode` | 執行模式 |
| `PROXY_MODE` | string | `proxy_mode` | 代理模式 |
| `DNS_PORT` | int | `dns_port` | DNS 埠 |
| `PROXY_PORT` | int | `proxy_port` | 流量轉發埠 |
| `TPROXY_PORT` | int | `tproxy_port` | TProxy 埠 |
| `HTTP_PORT` | int | `http_port` | HTTP 代理埠 |
| `SOCKS_PORT` | int | `socks_port` | SOCKS5 埠 |
| `MIXED_PORT` | int | `mixed_port` | 混合代理埠 |
| `CN_PORT` | int | `cn_port` | API 埠 |
| `DA_PASSWORD` | string | `dashboard_password` | Dashboard 金鑰 |
| `TOLERANCE` | int | `tolerance` | URL-Test 容差 |
| `URLTEST_ADDRESS_MOD` | string | `urltest_address_mod` | 測速地址 |
| `URLTEST_INTERVAL_MOD` | int | `urltest_interval_mod` | 測速間隔 |
| `GITHUB_ADDRESS_MOD` | string | `github_address_mod` | GitHub CDN 地址 |
| `ENABLE_REDIRECT_DNS` | int_bool | `enable_redirect_dns` | DNS 劫持模式 |
| `ENABLE_CUSTOM_DNS` | int_bool | `enable_custom_dns` | 自定義 DNS |
| `ENABLE_RESPECT_RULES` | int_bool | `enable_respect_rules` | DNS 尊重規則 |
| `ENABLE_META_SNIFFER` | int_bool | `enable_meta_sniffer` | 域名嗅探 |
| `ENABLE_META_SNIFFER_PURE_IP` | int_bool | `enable_meta_sniffer_pure_ip` | 純 IP 嗅探 |
| `ENABLE_META_SNIFFER_CUSTOM` | int_bool | `enable_meta_sniffer_custom` | 自定義嗅探 |
| `ENABLE_TCP_CONCURRENT` | int_bool | `enable_tcp_concurrent` | TCP 併發 |
| `ENABLE_UNIFIED_DELAY` | int_bool | `enable_unified_delay` | 統一延遲 |
| `ENABLE_UDP_PROXY` | int_bool | `enable_udp_proxy` | UDP 代理 |
| `ENABLE_V6_UDP_PROXY` | int_bool | `enable_v6_udp_proxy` | IPv6 UDP 代理 |
| `DISABLE_UDP_QUIC` | int_bool | `disable_udp_quic` | 禁用 QUIC |
| `DISABLE_QUIC_GO_GSO` | int_bool | `disable_quic_go_gso` | 禁用 quic-go GSO |
| `FIND_PROCESS_MODE` | string | `find_process_mode` | 程序匹配模式 |
| `GEODATA_LOADER` | string | `geodata_loader` | GEO 載入方式 |
| `ENABLE_GEOIP_DAT` | int_bool | `enable_geoip_dat` | 啟用 GeoIP Dat |
| `GLOBAL_UA` | string | `global_ua` | 全域性 User-Agent |
| `INTERFACE_NAME` | string | `interface_name` | 繫結網路介面 |
| `STACK_TYPE` | string | `stack_type` | TUN 堆疊型別 |
| `DELAY_START` | int | `delay_start` | 延遲啟動（秒） |
| `ROUTER_SELF_PROXY` | int_bool | `router_self_proxy` | 本機代理 |
| `CHINA_IP_ROUTE` | int | `china_ip_route` | 區域繞行 |
| `CHINA_IP6_ROUTE` | int | `china_ip6_route` | IPv6 區域繞行 |
| `COMMON_PORTS` | string | `common_ports` | 常用埠 |
| `INTRANET_ALLOWED` | int_bool | `intranet_allowed` | 僅內網 |
| `SMALL_FLASH_MEMORY` | int_bool | `small_flash_memory` | 小快閃記憶體模式 |
| `STORE_FAKEIP` | int_bool | `store_fakeip` | 持久化 Fake-IP |
| `BYPASS_GATEWAY_COMPATIBLE` | int_bool | `bypass_gateway_compatible` | 旁路由相容 |
| `SKIP_PROXY_ADDRESS` | int_bool | `skip_proxy_address` | 繞過伺服器地址 |
| `IPV6_ENABLE` | int_bool | `ipv6_enable` | IPv6 代理 |
| `IPV6_MODE` | int | `ipv6_mode` | IPv6 代理模式 |
| `IPV6_DNS` | int_bool | `ipv6_dns` | IPv6 DNS 解析 |
| `FAKEIP_RANGE` | string | `fakeip_range` | Fake-IP 範圍 |
| `FAKEIP_RANGE6` | string | `fakeip_range6` | IPv6 Fake-IP 範圍 |
| `CUSTOM_FALLBACK_FILTER` | int_bool | `custom_fallback_filter` | Fallback-Filter |
| `CUSTOM_FAKEIP_FILTER` | int_bool | `custom_fakeip_filter` | Fake-IP-Filter |
| `CUSTOM_FAKEIP_FILTER_MODE` | string | `custom_fakeip_filter_mode` | Filter 模式 |
| `CUSTOM_HOST` | int_bool | `custom_host` | 自定義 Hosts |
| `CUSTOM_NAME_POLICY` | int_bool | `custom_name_policy` | Nameserver-Policy |
| `APPEND_WAN_DNS` | int_bool | `append_wan_dns` | 追加 WAN DNS |
| `APPEND_DEFAULT_DNS` | int_bool | — | 追加預設 DNS |
| `AGE_SECRET_KEY` | string | — | Age 加密私鑰 |
| `AGE_PUBLIC_KEY` | string | — | Age 加密公鑰 |
| `CONFIG_FILE` | string | — | 覆寫指定配置檔案路徑 |
| `SUB_INFO_URL` | string | — | 訂閱資訊查詢 URL |
| `DOWNLOAD_FILE` | string | — | 下載外部檔案（格式見 8.2.4） |
| `RESTART` | bool | — | `true`=覆寫後重啟核心（僅 `type=http` cron 更新時） |
| `LAN_INTERFACE_NAME` | string | `lan_interface_name` | LAN 介面名稱 |
| `INTRANET_ALLOWED_WAN_NAME` | string | `intranet_allowed_wan_name` | WAN 介面名稱 |
| `CORE_TYPE` | string | `core_type` | 核心型別 |
| `OIX_TOKEN` | string | `oix_token` | oixCloud Token |
| `OIX_PARAMS` | string | `oix_params` | oixCloud 引數 |
| **GEO 訂閱類** | | | |
| `GEO_AUTO_UPDATE` | int_bool | `geo_auto_update` | 自動更新 GeoIP MMDB |
| `GEO_CUSTOM_URL` | string | `geo_custom_url` | MMDB 自定義 URL |
| `GEO_UPDATE_DAY_TIME` | string | `geo_update_day_time` | MMDB 更新時間 |
| `GEO_UPDATE_WEEK_TIME` | int | `geo_update_week_time` | MMDB 更新星期 |
| `GEOIP_AUTO_UPDATE` | int_bool | `geoip_auto_update` | 自動更新 GeoIP Dat |
| `GEOIP_CUSTOM_URL` | string | `geoip_custom_url` | Dat 自定義 URL |
| `GEOIP_UPDATE_DAY_TIME` | int | `geoip_update_day_time` | Dat 更新時間 |
| `GEOIP_UPDATE_WEEK_TIME` | int | `geoip_update_week_time` | Dat 更新星期 |
| `GEOSITE_AUTO_UPDATE` | int_bool | `geosite_auto_update` | 自動更新 GeoSite |
| `GEOSITE_CUSTOM_URL` | string | `geosite_custom_url` | GeoSite 自定義 URL |
| `GEOSITE_UPDATE_DAY_TIME` | string | `geosite_update_day_time` | GeoSite 更新時間 |
| `GEOSITE_UPDATE_WEEK_TIME` | int | `geosite_update_week_time` | GeoSite 更新星期 |
| `GEOASN_AUTO_UPDATE` | int_bool | `geoasn_auto_update` | 自動更新 GeoASN |
| `GEOASN_CUSTOM_URL` | string | `geoasn_custom_url` | ASN 自定義 URL |
| `GEOASN_UPDATE_DAY_TIME` | string | `geoasn_update_day_time` | ASN 更新時間 |
| `GEOASN_UPDATE_WEEK_TIME` | int | `geoasn_update_week_time` | ASN 更新星期 |
| **大陸路由類** | | | |
| `CHNR_AUTO_UPDATE` | int_bool | `chnr_auto_update` | 大陸路由自動更新 |
| `CHNR_CUSTOM_URL` | string | `chnr_custom_url` | 大陸 IPv4 URL |
| `CHNR6_CUSTOM_URL` | string | `chnr6_custom_url` | 大陸 IPv6 URL |
| `CHNR_UPDATE_DAY_TIME` | string | `chnr_update_day_time` | 路由更新時間 |
| `CHNR_UPDATE_WEEK_TIME` | string | `chnr_update_week_time` | 路由更新星期 |
| `CHINA_IP_ROUTE_PASS` | string | — | 大陸路由繞過列表 |
| `CHINA_IP6_ROUTE_PASS` | string | — | 大陸 IPv6 路由繞過列表 |
| **Smart 類** | | | |
| `AUTO_SMART_SWITCH` | int_bool | `auto_smart_switch` | Smart 自動切換 |
| `SMART_ENABLE_LGBM` | int_bool | `smart_enable_lgbm` | 啟用 LightGBM |
| `SMART_POLICY_PRIORITY` | string | `smart_policy_priority` | 策略優先順序 |
| `SMART_PREFER_ASN` | int_bool | `smart_prefer_asn` | 優先 ASN |
| `SMART_TOLERANCE` | int | `smart_tolerance` | Smart 容差 |
| `SMART_COLLECT` | int_bool | `smart_collect` | 收集訓練資料 |
| `SMART_COLLECT_RATE` | string | `smart_collect_rate` | 資料取樣率 |
| `SMART_COLLECT_SIZE` | int | `smart_collect_size` | 資料檔案大小 |
| `LGBM_AUTO_UPDATE` | int_bool | `lgbm_auto_update` | LGBM 自動更新 |
| `LGBM_CUSTOM_URL` | string | `lgbm_custom_url` | LGBM 自定義 URL |
| `LGBM_UPDATE_INTERVAL` | int | `lgbm_update_interval` | LGBM 更新間隔 |
| **規則類** | | | |
| `ENABLE_CUSTOM_CLASH_RULES` | int_bool | `enable_custom_clash_rules` | 自定義規則 |
| `ENABLE_RULE_PROXY` | int_bool | `enable_rule_proxy` | 僅代理命中規則 |

> **型別說明**: `int_bool`=值為 `0` 或 `1`；`bool`=值為 `true` 或 `false`；`int`=純整數；`string`=任意字串。
> 所有 key **大小寫不敏感**，寫入 UCI 時自動轉換為小寫。不在上表中的 key 會被 `check_type()` 校驗攔截並輸出 `skip General key not allowed` 警告。

---

# 超出本文件範圍的查詢

> **強制規則：當使用者詢問本文件未覆蓋的 Mihomo/OpenClash 配置或實現細節時，禁止自行猜測或編造回答。
> AI 必須主動查詢外部資源獲取準確資訊後回覆使用者。**

本文件僅覆蓋 OpenClash LuCI 外掛 UI 中可直接配置的選項及其實現。當遇到本文件未覆蓋的問題時，AI 必須**主動**使用以下資源查詢答案，而非讓使用者自己去查閱文件：

**AI 必須主動查詢的外部資源**：

| 優先順序 | 資源 | 查詢方式 | 適用場景 |
|--------|------|----------|----------|
| 1 | **Mihomo Wiki** `https://wiki.metacubex.one/config/` | 使用 `fetch_webpage` 抓取相關頁面 | Mihomo YAML 配置欄位的含義、可選值、用法 |
| 2 | **Meta-Docs 倉庫** `github.com/MetaCubeX/Meta-Docs` | 使用 `github_text_search` 搜尋 `docs/config/` 目錄 | 需要精確的欄位型別、預設值、完整配置示例 |
| 3 | **OpenClash Issues** `https://github.com/vernesong/OpenClash/issues` | 使用 `fetch_webpage` 開啟 Issue 搜尋頁面或具體 Issue 頁面 | 外掛側功能異常/報錯（配置/訂閱/防火牆/UI等），搜尋已知問題和社群方案（優先作者 vernesong 回覆和高贊回答） |
| 4 | **Mihomo Issues** `https://github.com/MetaCubeX/mihomo/issues` | 使用 `fetch_webpage` 開啟 Issue 搜尋頁面或具體 Issue 頁面 | 核心側功能異常/報錯（代理協議/TUN/DNS解析/規則引擎等），搜尋已知問題和社群方案 |
| 5 | **OpenClash 原始碼** `github.com/vernesong/OpenClash/tree/dev` | 使用 `github_text_search` 搜尋對應指令碼/函式 | 需要了解外掛側的實現邏輯、UCI 到 YAML 的轉換細節 |
| 6 | **Mihomo 核心原始碼** `github.com/MetaCubeX/mihomo/tree/Alpha` | 使用 `github_text_search` 搜尋核心程式碼 | 代理協議實現、規則引擎、DNS 解析、TUN 棧等核心底層邏輯 |
| 7 | **Smart 核心原始碼** `github.com/vernesong/mihomo/tree/Alpha` | 使用 `github_text_search` 搜尋核心程式碼 | Smart 策略、LightGBM 模型的底層實現 |

**具體觸發條件**（滿足任一即主動查詢）：
- 使用者詢問的配置欄位在本文件任何章節中均未出現
- 使用者詢問特定代理協議的詳細引數（Hysteria2/TUIC/WireGuard/SSH/MASQUE 等的完整 TLS/傳輸層選項）
- 使用者詢問 `experimental`、`tunnel`、`sub-rule` 等外掛 UI 中無直接對應選項的 Mihomo 頂級配置段
- 使用者需要編寫超出覆寫模組 8.2 節示例範圍的自定義指令碼或 YAML 配置
- 使用者詢問 Mihomo 最新版本引入的新特性（本文件基於 Mihomo v1.19.x）
- 使用者詢問 OpenClash 外掛本身的開發、編譯、打包相關問題
- 使用者詢問本文件各選項中「實現細節」的更深層邏輯

**AI 工作流程**：
1. 確認問題超出本文件覆蓋範圍
2. 根據問題型別選擇對應的外部資源
3. **優先搜尋 Issues**：如果使用者遇到的是功能異常/報錯類問題（而非配置欄位查詢），應先搜尋 Issues 查詢類似問題。根據問題型別選擇：外掛側（配置/訂閱/防火牆/UI）→ [OpenClash Issues](https://github.com/vernesong/OpenClash/issues)；核心側（代理協議/TUN/DNS/規則引擎）→ [Mihomo Issues](https://github.com/MetaCubeX/mihomo/issues)。讀取 Issue 時重點關注：① 維護者的診斷命令和結論；② 👍 反應數高的社群回覆；③ Issue 最終是否被關閉及關閉原因（`completed`=已修復，`not planned`=不在計劃內）
4. **主動查詢**：使用 `fetch_webpage` 抓取 Mihomo Wiki 頁面，或使用 `github_text_search` 搜尋 Meta-Docs/OpenClash/Mihomo 核心/Smart 核心原始碼
5. 將查詢到的資訊**翻譯、整理**後告知使用者，而非直接丟連結
6. 在回覆末尾註明資訊來源（如「以上資訊來自 OpenClash Issues #xxx / Mihomo Wiki」），讓使用者知道資訊的權威來源

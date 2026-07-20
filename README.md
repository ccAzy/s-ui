# S-UI
**An Advanced Web Panel • Built on SagerNet/Sing-Box**

![](https://img.shields.io/github/v/release/alireza0/s-ui.svg)
![S-UI Docker pull](https://img.shields.io/docker/pulls/alireza7/s-ui.svg)
[![Go Report Card](https://goreportcard.com/badge/github.com/alireza0/s-ui)](https://goreportcard.com/report/github.com/alireza0/s-ui)
[![Downloads](https://img.shields.io/github/downloads/alireza0/s-ui/total.svg)](https://img.shields.io/github/downloads/alireza0/s-ui/total.svg)
[![License](https://img.shields.io/badge/license-GPL%20V3-blue.svg?longCache=true)](https://www.gnu.org/licenses/gpl-3.0.en.html)

> **Disclaimer:** This project is only for personal learning and communication, please do not use it for illegal purposes, please do not use it in a production environment

**If you think this project is helpful to you, you may wish to give a**:star2:

**Want to contribute?** See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, coding conventions, testing, and the pull request process.

[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/alireza7)

<a href="https://nowpayments.io/donation/alireza7" target="_blank" rel="noreferrer noopener">
   <img src="https://nowpayments.io/images/embeds/donation-button-white.svg" alt="Crypto donation button by NOWPayments">
</a>

## Quick Overview
| Features                               |      Enable?       |
| -------------------------------------- | :----------------: |
| Multi-Protocol                         | :heavy_check_mark: |
| Multi-Language                         | :heavy_check_mark: |
| Multi-Client/Inbound                   | :heavy_check_mark: |
| Advanced Traffic Routing Interface     | :heavy_check_mark: |
| Client & Traffic & System Status       | :heavy_check_mark: |
| Subscription Link (link/json/clash + info)| :heavy_check_mark: |
| Dark/Light Theme                       | :heavy_check_mark: |
| API Interface                          | :heavy_check_mark: |
| 📡 System Optimization (YGVPN Tuning)  | :heavy_check_mark: |
| 🏥 Health Check                        | :heavy_check_mark: |
| 🌐 Domain Split Presets                | :heavy_check_mark: |

## Supported Platforms
| Platform | Architecture | Status |
|----------|--------------|---------|
| Linux    | amd64, arm64, armv7, armv6, armv5, 386, s390x | ✅ Supported |
| Windows  | amd64, 386, arm64 | ✅ Supported |
| macOS    | amd64, arm64 | 🚧 Experimental |

## Screenshots

!["Main"](https://github.com/alireza0/s-ui-frontend/raw/main/media/main.png)

[Other UI Screenshots](https://github.com/alireza0/s-ui-frontend/blob/main/screenshots.md)

## API Documentation

[API-Documentation Wiki](https://github.com/alireza0/s-ui/wiki/API-Documentation)

## Default Installation Information
- Panel Port: 2095
- Panel Path: /app/
- Subscription Port: 2096
- Subscription Path: /sub/
- User/Password: admin

## Install & Upgrade to Latest Version

### Linux/macOS
```sh
# Install latest release (upstream)
bash <(curl -Ls https://raw.githubusercontent.com/alireza0/s-ui/master/install.sh)

# Install ygvpn-optimize branch (with system optimization)
# Builds from source — requires ~2min for Go compilation
bash <(curl -Ls https://raw.githubusercontent.com/ccAzy/s-ui/ygvpn-optimize/install.sh)
```

#### Installer language

The installer is available in the same six languages as the panel: `en` (default), `fa`, `ru`, `vi`, `zhcn`, `zhtw`. Choose one with the `SUI_LANG` environment variable (when unset, your system `$LANG` is used as a hint):

```sh
SUI_LANG=fa bash <(curl -Ls https://raw.githubusercontent.com/alireza0/s-ui/master/install.sh)
```

### Alpine Linux
Alpine uses `apk` and OpenRC instead of `apt`/systemd. The install script detects Alpine automatically and sets up an OpenRC service. Since Alpine has no `bash` by default, install it first:

```sh
apk add bash
bash <(curl -Ls https://raw.githubusercontent.com/alireza0/s-ui/master/install.sh)
```

Manage the service with OpenRC: `rc-service s-ui start|stop|restart` and `rc-update add s-ui default`.

### Windows
1. Download the latest Windows release from [GitHub Releases](https://github.com/alireza0/s-ui/releases/latest)
2. Extract the ZIP file
3. Run `install-windows.bat` as Administrator
4. Follow the installation wizard

## Install legacy Version

**Step 1:** To install your desired legacy version, add the version to the end of the installation command. e.g., ver `v1.5.0`:

```sh
VERSION=v1.5.0 && bash <(curl -Ls https://raw.githubusercontent.com/alireza0/s-ui/$VERSION/install.sh) $VERSION
```

## Manual installation

### Linux/macOS
1. Get the latest version of S-UI based on your OS/Architecture from GitHub: [https://github.com/alireza0/s-ui/releases/latest](https://github.com/alireza0/s-ui/releases/latest)
2. **OPTIONAL** Get the latest version of `s-ui.sh` [https://raw.githubusercontent.com/alireza0/s-ui/master/s-ui.sh](https://raw.githubusercontent.com/alireza0/s-ui/master/s-ui.sh)
3. **OPTIONAL** Copy `s-ui.sh` to /usr/bin/ and run `chmod +x /usr/bin/s-ui`.
4. Extract s-ui tar.gz file to a directory of your choice and navigate to the directory where you extracted the tar.gz file.
5. Copy *.service files to /etc/systemd/system/ and run `systemctl daemon-reload`.
6. Enable autostart and start S-UI service using `systemctl enable s-ui --now`
7. Start sing-box service using `systemctl enable sing-box --now`

### Windows
1. Get the latest Windows version from GitHub: [https://github.com/alireza0/s-ui/releases/latest](https://github.com/alireza0/s-ui/releases/latest)
2. Download the appropriate Windows package (e.g., `s-ui-windows-amd64.zip`)
3. Extract the ZIP file to a directory of your choice
4. Run `install-windows.bat` as Administrator
5. Follow the installation wizard
6. Access the panel at http://localhost:2095/app

## Uninstall S-UI

### systemd
```sh
sudo -i

systemctl disable s-ui  --now

rm -f /etc/systemd/system/sing-box.service
systemctl daemon-reload

rm -fr /usr/local/s-ui
rm /usr/bin/s-ui
```

### Alpine (OpenRC)
```sh
rc-service s-ui stop
rc-update del s-ui default
rm -f /etc/init.d/s-ui

rm -fr /usr/local/s-ui
rm /usr/bin/s-ui
```

## Install using Docker

<details>
   <summary>Click for details</summary>

### Usage

**Step 1:** Install Docker

```shell
curl -fsSL https://get.docker.com | sh
```

**Step 2:** Install S-UI

> Docker compose method

```shell
mkdir s-ui && cd s-ui
wget -q https://raw.githubusercontent.com/alireza0/s-ui/master/docker-compose.yml
docker compose up -d
```

> Use docker

```shell
mkdir s-ui && cd s-ui
docker run -itd \
    -p 2095:2095 -p 2096:2096 -p 443:443 -p 80:80 \
    -v $PWD/db/:/app/db/ \
    -v $PWD/cert/:/root/cert/ \
    --name s-ui --restart=unless-stopped \
    alireza7/s-ui:latest
```

> Build your own image

```shell
git clone https://github.com/alireza0/s-ui
git submodule update --init --recursive
docker build -t s-ui .
```

</details>

## Manual run ( contribution )

<details>
   <summary>Click for details</summary>

### Build and run whole project
```shell
./runSUI.sh
```

### Clone the repository
```shell
# clone repository
git clone https://github.com/alireza0/s-ui
# clone submodules
git submodule update --init --recursive
```


### - Frontend

Visit [s-ui-frontend](https://github.com/alireza0/s-ui-frontend) for frontend code

### - Backend
> Please build frontend once before!

To build backend:
```shell
# remove old frontend compiled files
rm -fr web/html/*
# apply new frontend compiled files
cp -R frontend/dist/ web/html/
# build
go build -o sui main.go
```

To run backend (from root folder of repository):
```shell
./sui
```

</details>

## Languages

- English
- Farsi
- Vietnamese
- Chinese (Simplified)
- Chinese (Traditional)
- Russian

## Features

- Supported protocols:
  - General:  Mixed, SOCKS, HTTP, HTTPS, Direct, Redirect, TProxy
  - V2Ray based: VLESS, VMess, Trojan, Shadowsocks
  - Other protocols: ShadowTLS, Hysteria, Hysteria2, Naive, TUIC
- Supports XTLS protocols
- An advanced interface for routing traffic, incorporating PROXY Protocol, External, and Transparent Proxy, SSL Certificate, and Port
- An advanced interface for inbound and outbound configuration
- Clients’ traffic cap and expiration date
- Displays online clients, inbounds and outbounds with traffic statistics, and system status monitoring
- Subscription service with ability to add external links and subscription
- HTTPS for secure access to the web panel and subscription service (self-provided domain + SSL certificate)
- Dark/Light theme

## ⚡ YGVPN System Optimization (ygvpn-optimize branch)

> Merged from [YGVPN](https://github.com/ccAzy/YGVPN) — 80+ system-level tuning parameters for maximum proxy performance.

This branch extends s-ui with **deep system tuning** capabilities originally developed in YGVPN. All features are accessible via both the Web API and the CLI menu (`s-ui.sh`).

### 🖥️ CLI Menu (options 21–25)

| Option | Function | Description |
|--------|----------|-------------|
| `21` | ⚡ Apply System Optimization | Apply 80+ TCP/UDP/NIC/CPU/Kernel tuning params |
| `22` | 🏥 Health Check | Comprehensive system health + connectivity check |
| `23` | 📊 Optimization Status | View current sysctl parameter values |
| `24` | 🔄 Toggle Busy Polling | Enable/disable CPU-based low-latency polling |
| `25` | 🌐 Toggle IPv6 | Enable/disable IPv6 system-wide |

### 🌐 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET`  | `/api/optimizeStatus` | Get current system tuning status (BBR, params, kernel) |
| `POST` | `/api/applyOptimize` | Apply YGVPN extreme optimization |
| `POST` | `/api/toggleBBR` | Enable or disable BBR congestion control |
| `POST` | `/api/healthCheck` | Full system health check (DNS, conntrack, disk, load) |
| `GET`  | `/api/splitDomains` | Get built-in domain split presets |

### 📦 Optimization Parameters (80+)

| Category | Key Parameters |
|:---------|:---------------|
| **TCP** | BBRv3 + ECN, tcp_fastopen=3, rmem/wmem 64MB, tcp_tw_reuse, SACK/Timestamps, tcp_limit_output_bytes=256K, RTO 50ms (aggressive mode), tcp_autocorking, Challenge ACK limit |
| **UDP** | udp_mem auto-tuned, rmem_default 26MB, rx-udp-gro-forwarding |
| **NIC** | RSS/RPS/XPS full-core balancing, IRQ distribution, TSO/GSO/GRO/LRO, Ring Buffer 4096, PAUSE frames off, Ntuple Flow Director |
| **CPU** | performance governor, timer_migration=0, rcu_expedited=1, ksoftirqd affinity |
| **Process** | sing-box SCHED_FIFO rtprio 99, LimitMEMLOCK=infinity |
| **VM/Kernel** | page-cluster=0, watermark_boost=0, compaction_proactiveness=0, overcommit_memory=1 |
| **Conntrack** | UDP timeout aggressive (20s/60s) for Hysteria2/Tuic5 |

### 🎯 Domain Split Presets

Built-in routing presets for WARP/IPv6 split tunneling:

| Preset | Domains |
|--------|---------|
| `ai-sites` | ChatGPT, Claude, Gemini, Perplexity, OpenAI |
| `streaming` | Netflix, Disney+, YouTube, Spotify, Hulu, Twitch |
| `social` | Twitter/X, Facebook, Instagram, Reddit, Discord, Telegram |
| `developer` | GitHub, GitLab, Stack Overflow, Docker, NPM, Wikipedia |
| `google-services` | Google Search, Gmail, Google APIs, Blogger |
| `microsoft` | Bing, Office 365, Azure, Outlook |

### 🧪 Quick Verification

```bash
# Apply default system optimization via CLI
s-ui      # then select option 21 → 1

# Run health check
s-ui      # then select option 22

# Via API
curl -X POST http://your-server:2095/app/api/applyOptimize
curl http://your-server:2095/app/api/optimizeStatus
curl http://your-server:2095/app/api/healthCheck
curl http://your-server:2095/app/api/splitDomains
```

### 🔧 逻辑审计 & 修复

ygvpn-optimize 分支经过全面逻辑审计，已修复以下问题：

| 严重度 | 问题 | 修复 |
|--------|------|------|
| 🔴 严重 | `ToggleBBR` API 执行 `sysctl -w` 未检查 root 权限 | 添加 `os.Geteuid() != 0` 守卫 |
| 🟡 中 | `runCmd`/`runBash` 可能无限挂起 | 添加 30 秒 `context.WithTimeout` 超时 |
| 🟡 中 | s-ui.sh 菜单 21-25 未检测安装状态 | 添加 `check_install &&` 前缀 |
| 🟡 中 | BBR 写入 `/etc/sysctl.conf`，优化写入 `/etc/sysctl.d/99-ygvpn-extreme.conf` | 统一写入 ygvpn-extreme.conf（保留 sysctl.conf 向后兼容） |
| 🟡 高 | 首次安装时从未显示管理员密码 | 在 `sui migrate` **之前**检查数据库是否存在，确保首次安装生成随机密码 |
| 🔵 低 | 健康检查 DNS 只测试阿里云 DNS (223.5.5.5) | 添加降级链：223.5.5.5 → 1.1.1.1 → 8.8.8.8，返回结果含 `Server` 字段 |

### ⚠️ 升级说明

通过本分支 `install.sh` 升级已有安装时：

- **从源码构建**（克隆 ccAzy/s-ui/ygvpn-optimize → 安装 Go → 编译），约 2 分钟
- 前端资源从已有安装复制，或从 release 下载作为备用
- 已有数据库和密码保持不变
- 查看当前密码：`s-ui` → 选项 7
- 重置密码：`s-ui` → 选项 6

## Environment Variables

<details>
  <summary>Click for details</summary>

### Usage

| Variable       |                      Type                      | Default       |
| -------------- | :--------------------------------------------: | :------------ |
| SUI_LOG_LEVEL  | `"debug"` \| `"info"` \| `"warn"` \| `"error"` | `"info"`      |
| SUI_DEBUG      |                   `boolean`                    | `false`       |
| SUI_BIN_FOLDER |                    `string`                    | `"bin"`       |
| SUI_DB_FOLDER  |                    `string`                    | `"db"`        |
| SINGBOX_API    |                    `string`                    | -             |

</details>

## SSL Certificate

<details>
  <summary>Click for details</summary>

### Certbot

```bash
snap install core; snap refresh core
snap install --classic certbot
ln -s /snap/bin/certbot /usr/bin/certbot

certbot certonly --standalone --register-unsafely-without-email --non-interactive --agree-tos -d <Your Domain Name>
```

</details>

## Third-party Projects

Community-made projects built around S-UI. These are not affiliated with or maintained by S-UI — use them at your own discretion:

- [itning/reset-s-ui-traffic](https://github.com/itning/reset-s-ui-traffic) — periodic traffic reset for all users
- [zqh2333/s-ui-traffic-reset](https://github.com/zqh2333/s-ui-traffic-reset) — traffic reset tool

> Building something on top of S-UI (a Telegram bot, monitoring, automation, ...)? Open an issue/PR to get it listed here.

## Stargazers over Time
[![Stargazers over time](https://starchart.cc/alireza0/s-ui.svg)](https://starchart.cc/alireza0/s-ui)

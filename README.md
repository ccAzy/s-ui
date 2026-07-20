# S-UI (ygvpn-optimize)
**基于 Sing-Box 的进阶 Web 管理面板 · 集成 YGVPN 系统优化**

![](https://img.shields.io/badge/release-ygvpn--optimize-blue.svg)
![Go](https://img.shields.io/badge/go-1.26-blue)
[![License](https://img.shields.io/badge/license-GPL%20V3-blue.svg?longCache=true)](https://www.gnu.org/licenses/gpl-3.0.en.html)

> **免责声明：** 本项目仅用于个人学习和交流，请勿用于非法用途，请勿在生产环境使用

**如果这个项目对你有帮助，欢迎点个**:star2:

**想贡献代码？** 详见 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 快速概览
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

## 支持平台
| Platform | Architecture | Status |
|----------|--------------|---------|
| Linux    | amd64, arm64, armv7, armv6, armv5, 386, s390x | ✅ Supported |
| Windows  | amd64, 386, arm64 | ✅ Supported |
| macOS    | amd64, arm64 | 🚧 Experimental |

## 截图

!["Main"](https://github.com/ccAzy/s-ui-frontend/raw/main/media/main.png)

[Other UI Screenshots](https://github.com/ccAzy/s-ui-frontend/blob/main/screenshots.md)

## API 文档

[API-Documentation Wiki](https://github.com/ccAzy/s-ui/wiki/API-Documentation)

## 默认安装信息
- 面板端口：2095
- 面板路径：/app/
- 订阅端口：2096
- 订阅路径：/sub/
- 默认账号：admin/admin

## 安装与升级

### Linux/macOS
```sh
# Install ygvpn-optimize branch (系统优化集成版)
# 自动从源码构建，首次安装约 2 分钟
bash <(curl -Ls https://raw.githubusercontent.com/ccAzy/s-ui/ygvpn-optimize/install.sh)
```

#### 安装语言

安装器支持与面板相同的六种语言：`en` (默认), `fa`, `ru`, `vi`, `zhcn`, `zhtw`。通过 `SUI_LANG` 环境变量选择（未设置时使用系统 `$LANG` 提示）：

```sh
SUI_LANG=zhcn bash <(curl -Ls https://raw.githubusercontent.com/ccAzy/s-ui/ygvpn-optimize/install.sh)
```

### Alpine Linux
Alpine 使用 `apk` + OpenRC 而非 `apt`/systemd。安装脚本自动检测 Alpine。Alpine 默认无 `bash`，需先安装：

```sh
apk add bash
bash <(curl -Ls https://raw.githubusercontent.com/ccAzy/s-ui/ygvpn-optimize/install.sh)
```

OpenRC 管理命令：`rc-service s-ui start|stop|restart`，开机自启：`rc-update add s-ui default`。

### Windows
1. 从 [GitHub Releases] 下载最新 Windows 版本(https://github.com/ccAzy/s-ui/releases/latest)
2. 解压 ZIP 文件
3. 以管理员身份运行 `install-windows.bat`
4. 按照安装向导完成安装

## 安装旧版本

**步骤 1：** 在安装命令末尾加上版本号，例如 `v1.5.0`：

```sh
VERSION=v1.5.0 && bash <(curl -Ls https://raw.githubusercontent.com/ccAzy/s-ui/$VERSION/install.sh) $VERSION
```

## 手动安装

### Linux/macOS
1. 从 GitHub 下载对应系统架构的最新版本： [https://github.com/ccAzy/s-ui/releases/latest](https://github.com/ccAzy/s-ui/releases/latest)
2. **可选** 获取最新版 `s-ui.sh` [https://raw.githubusercontent.com/ccAzy/s-ui/master/s-ui.sh](https://raw.githubusercontent.com/ccAzy/s-ui/master/s-ui.sh)
3. **可选** 复制 `s-ui.sh` 到 `/usr/bin/` 并执行 `chmod +x /usr/bin/s-ui`
4. 解压 tar.gz 到任意目录并进入该目录
5. 复制 `*.service` 文件到 `/etc/systemd/system/` 并执行 `systemctl daemon-reload`
6. 设置开机自启并启动：`systemctl enable s-ui --now`
7. 启动 sing-box：`systemctl enable sing-box --now`

### Windows
1. 从 GitHub 下载最新 Windows 版本： [https://github.com/ccAzy/s-ui/releases/latest](https://github.com/ccAzy/s-ui/releases/latest)
2. 下载对应 Windows 包（如 `s-ui-windows-amd64.zip`）
3. 解压 ZIP 到任意目录
4. 以管理员身份运行 `install-windows.bat`
5. 按向导完成安装
6. 浏览器打开 http://localhost:2095/app

## 卸载 S-UI

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

## Docker 安装

<details>
   <summary>Click for details</summary>

### 使用方式

**步骤 1：** 安装 Docker

```shell
curl -fsSL https://get.docker.com | sh
```

**步骤 2：** 安装 S-UI

> Docker compose 方式

```shell
mkdir s-ui && cd s-ui
wget -q https://raw.githubusercontent.com/ccAzy/s-ui/master/docker-compose.yml
docker compose up -d
```

> Docker 命令行方式

```shell
mkdir s-ui && cd s-ui
docker run -itd \
    -p 2095:2095 -p 2096:2096 -p 443:443 -p 80:80 \
    -v $PWD/db/:/app/db/ \
    -v $PWD/cert/:/root/cert/ \
    --name s-ui --restart=unless-stopped \
    ccAzy/s-ui:latest
```

> 自行构建镜像

```shell
git clone https://github.com/ccAzy/s-ui
git submodule update --init --recursive
docker build -t s-ui .
```

</details>

## 手动运行（开发）

<details>
   <summary>Click for details</summary>

### 一键构建运行
```shell
./runSUI.sh
```

### 克隆仓库
```shell
# 克隆仓库
git clone https://github.com/ccAzy/s-ui
# 克隆子模块
git submodule update --init --recursive
```


### 前端

前端代码见 [s-ui-frontend](https://github.com/ccAzy/s-ui-frontend) for frontend code

### 后端
> Please build frontend once before!

构建后端：
```shell
# 删除旧前端编译文件
rm -fr web/html/*
# 复制新前端编译文件
cp -R frontend/dist/ web/html/
# 编译
go build -o sui main.go
```

运行后端（项目根目录执行）：
```shell
./sui
```

</details>

## 多语言支持

- English
- Farsi
- Vietnamese
- Chinese (Simplified)
- Chinese (Traditional)
- Russian

## 功能特性

- 支持的协议：
  - 通用：Mixed, SOCKS, HTTP, HTTPS, Direct, Redirect, TProxy
  - V2Ray 系：VLESS, VMess, Trojan, Shadowsocks
  - 其他：ShadowTLS, Hysteria, Hysteria2, Naive, TUIC
- 支持 XTLS 协议
- 高级路由配置界面（PROXY Protocol、外部代理、透明代理、SSL 证书、端口）
- 入站/出站高级配置界面
- Clients’ traffic cap and expiration date
- 在线客户端/入站/出站流量统计 + 系统状态监控
- 订阅服务（支持外部链接和订阅导入）
- HTTPS 安全访问面板和订阅服务（需自备域名 + SSL 证书）
- 深色/浅色主题

## ⚡ YGVPN 系统优化（ygvpn-optimize 分支）

> 合并自 [YGVPN](https://github.com/ccAzy/YGVPN) — 80+ 项系统级调优参数，将 VPS 代理性能压榨到极限

本分支将 YGVPN 的深度系统调优能力集成到 s-ui 中。所有功能可通过 Web API 和 CLI 菜单 (`s-ui.sh`) 两种方式调用。

### 🖥️ CLI 菜单（选项 21–25）

| 选项 | 功能 | 说明 |
|--------|----------|-------------|
| `21` | ⚡ 应用系统优化 | 应用 80+ 项 TCP/UDP/网卡/CPU/内核调优参数 | |
| `22` | 🏥 健康检查 | 系统健康度 + 连通性全面检测 | |
| `23` | 📊 优化状态 | 查看当前 sysctl 参数值 | |
| `24` | 🔄 切换 Busy Polling | 启用/关闭 CPU 低延迟轮询 | |
| `25` | 🌐 切换 IPv6 | 启用/关闭系统 IPv6 | |

### 🌐 API 接口

| 方法 | 接口 | 说明 |
|--------|----------|-------------|
| `GET`  | `/api/optimizeStatus` | 获取系统调优状态（BBR、参数、内核） | |
| `POST` | `/api/applyOptimize` | 应用 YGVPN 极限优化 | |
| `POST` | `/api/toggleBBR` | 启用/关闭 BBR 拥塞控制 | |
| `POST` | `/api/healthCheck` | 全面系统健康检查（DNS、conntrack、磁盘、负载） | |
| `GET`  | `/api/splitDomains` | 获取内置域名分流预设 | |

### 📦 调优参数（80+）

| 类别 | 关键参数 |
|:---------|:---------------|
| **TCP** | BBRv3 + ECN, tcp_fastopen=3, rmem/wmem 64MB, tcp_tw_reuse, SACK/Timestamps, tcp_limit_output_bytes=256K, RTO 50ms (aggressive mode), tcp_autocorking, Challenge ACK limit |
| **UDP** | udp_mem auto-tuned, rmem_default 26MB, rx-udp-gro-forwarding |
| **NIC** | RSS/RPS/XPS full-core balancing, IRQ distribution, TSO/GSO/GRO/LRO, Ring Buffer 4096, PAUSE frames off, Ntuple Flow Director |
| **CPU** | performance governor, timer_migration=0, rcu_expedited=1, ksoftirqd affinity |
| **Process** | sing-box SCHED_FIFO rtprio 99, LimitMEMLOCK=infinity |
| **VM/Kernel** | page-cluster=0, watermark_boost=0, compaction_proactiveness=0, overcommit_memory=1 |
| **Conntrack** | UDP timeout aggressive (20s/60s) for Hysteria2/Tuic5 |

### 🎯 域名分流预设

内置 WARP/IPv6 分流预设，一键应用到路由规则：

| 预设 | 域名列表 |
|--------|---------|
| `ai-sites` | ChatGPT, Claude, Gemini, Perplexity, OpenAI |
| `streaming` | Netflix, Disney+, YouTube, Spotify, Hulu, Twitch |
| `social` | Twitter/X, Facebook, Instagram, Reddit, Discord, Telegram |
| `developer` | GitHub, GitLab, Stack Overflow, Docker, NPM, Wikipedia |
| `google-services` | Google Search, Gmail, Google APIs, Blogger |
| `microsoft` | Bing, Office 365, Azure, Outlook |

### 🧪 快速验证

```bash
# 通过 CLI 菜单应用默认优化
s-ui      # 选 21 → 1

# 运行健康检查
s-ui      # 选 22

# 通过 API 调用
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

## 环境变量

<details>
  <summary>Click for details</summary>

### 使用方式

| Variable       |                      Type                      | Default       |
| -------------- | :--------------------------------------------: | :------------ |
| SUI_LOG_LEVEL  | `"debug"` \| `"info"` \| `"warn"` \| `"error"` | `"info"`      |
| SUI_DEBUG      |                   `boolean`                    | `false`       |
| SUI_BIN_FOLDER |                    `string`                    | `"bin"`       |
| SUI_DB_FOLDER  |                    `string`                    | `"db"`        |
| SINGBOX_API    |                    `string`                    | -             |

</details>

## SSL 证书

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

## 第三方项目

社区基于 S-UI 构建的项目，非官方维护，使用风险自负：

- [itning/reset-s-ui-traffic](https://github.com/itning/reset-s-ui-traffic) — periodic traffic reset for all users
- [zqh2333/s-ui-traffic-reset](https://github.com/zqh2333/s-ui-traffic-reset) — traffic reset tool

> 基于 S-UI 开发了项目（TG 机器人、监控、自动化等）？提 issue/PR 添加到这里。

## Star 历史
[![Stargazers over time](https://starchart.cc/ccAzy/s-ui.svg)](https://starchart.cc/ccAzy/s-ui)

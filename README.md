# myTV SUPER EPG 一键部署

myTV SUPER（翡翠台 / J2 / 明珠台）EPG 网页服务，支持实时节目单查询与历史归档，**一条命令部署到任意全新 VPS**，零依赖（自动安装 Python 3.8+）。
## ✨ 特性

- 🚀 **一条命令部署** — curl 直连拉取，交互式向导 / 非交互参数两用
- 🆕 **全新 VPS 直接可用** — 自动检测/安装 Python ≥3.8，无需预装任何软件
- 🔐 **可选访问认证** — 需要时启用用户名+密码（Basic Auth），或公开访问
- 📺 **实时节目查询** — `/live` 页面查询当日节目单（服务端代理，数据不落盘）
- 🗂 **历史归档** — 定时抓取 XML EPG，累积 30 天数据，本地 `/` 页面浏览
- 📦 **零依赖服务端** — 纯 Python 标准库，无需 pip、nodejs

## 🚀 快速开始

在目标 VPS 上执行（需 root）：

### 方式一：交互式向导（推荐）

```bash
bash -c "$(curl -sSL https://raw.githubusercontent.com/soandso888/Hugo-EPG/refs/heads/main/quick_start.sh)"
```

依次选择：**监听端口 / 是否需要用户名+密码认证 / 用户名 / 密码**。

### 方式二：非交互一键（适合自动化）

```bash
# 启用认证（端口 8080，用户名 admin，密码 mypass）
curl -sSL https://raw.githubusercontent.com/soandso888/Hugo-EPG/refs/heads/main/quick_start.sh | bash -s -- 8080 admin mypass

# 公开访问（不启用认证）
curl -sSL https://raw.githubusercontent.com/soandso888/Hugo-EPG/refs/heads/main/quick_start.sh | bash -s -- 8080 none
```

## 📖 部署后访问

| 地址 | 说明 |
|---|---|
| `http://<VPS_IP>:<端口>/live` | 实时节目单查询（前后一天切换） |
| `http://<VPS_IP>:<端口>/` | 本地历史归档浏览 |

> ⚠️ 记得在防火墙 / 安全组放行部署端口（如 8765/tcp）。

## 🔧 手动部署（下载包本地解压）

```bash
tar xzf epg-bundle-20260902.tar.gz && cd epg-bundle-20260902
sudo bash install.sh                  # 交互式向导
sudo bash install.sh 8080 admin mypass   # 非交互（启用认证）
sudo bash install.sh 8080 none           # 非交互（公开访问）
```

可选：`KEEP_ARCHIVE_CRON=1` 环境变量可同时注册归档定时任务（每 6 小时）。

## 🗑 卸载

在目标 VPS 上执行（需 root）：

```bash
# 进入备份包目录
tar xzf epg-bundle-20260902.tar.gz && cd epg-bundle-20260902

sudo bash uninstall.sh              # 交互确认后卸载
sudo bash uninstall.sh -y           # 跳过确认, 直接卸载
sudo bash uninstall.sh --keep-data  # 保留 /opt/epg/data 归档 (备份到 /tmp/epg-data-backup/)
```

卸载内容：停止并删除 systemd 服务、移除归档 cron、删除 `/opt/epg` 目录。
> 若部署时在防火墙/安全组放行了端口（如 8765/tcp），记得一并移除。

## 🗂 项目结构

```
epg-bundle-*.tar.gz       一键部署备份包（含全部文件 + 历史归档）
quick_start.sh            GitHub 一键部署入口（下载包 → 解压 → 自动部署）
install.sh                部署脚本（交互式 / 参数化）
uninstall.sh              一键卸载脚本（可选保留归档数据）
epg_server.py             网页服务（纯标准库，Basic Auth 可选）
epg_archive.sh            归档抓取脚本（每 6 小时，保留 30 天）
mychannels.xml            iptv-org/epg 频道配置
data/                     XML 历史归档
```

## 🔒 安全提醒

- 公开仓库中的备份包内嵌默认认证密码 `admin/hugo2026+`，**任何人可下载看到**。
- 生产部署请务必使用自定义密码：
  ```bash
  curl -sSL .../quick_start.sh | bash -s -- 8080 youruser yourpass
  ```
- 建议部署后修改服务器 root 密码，或使用私有仓库分发。

## ❓ FAQ

**全新 VPS 需要预装什么？**
什么都不用。脚本会自动检测 Python ≥3.8（缺失则通过 apt/dnf/yum/apk 自动安装），curl/wget 缺失也会自动安装。

**认证密码忘了吗？**
编辑 `/opt/epg/epg_server.py` 中的 `AUTH_USER` / `AUTH_PASS`，然后 `systemctl restart epg-server`。

**怎么改端口？**
编辑 `/opt/epg/epg_server.py` 中的 `PORT`，然后 `systemctl restart epg-server`。

**为什么 `/live` 查询慢？**
实时查询依赖上游 EPG 服务响应，首次查询可能需数秒，之后有缓存。

## 📜 License

仅供个人学习研究使用。

# AxBeacon（AxManager Cloudflare IPv6 DDNS 插件）

一个为 **AxManager** 设计的 Cloudflare 动态 IPv6 同步插件：
自动检测设备当前 IPv6，并更新到 Cloudflare 的 `AAAA` 记录。

ps:用途很广泛，其中一个用途就是在被控手机上安装AxManager和本插件，并在AxManager里设置好开机自启关闭电池优化，然后随时随地通过公网域名和无线ADB远程控制另一台手机，仅供参考，各位可自行发挥

## 🔗 项目链接
- 本插件仓库：<https://github.com/coldboy404/AxBeacon>
- AxManager：<https://github.com/fahrez182/AxManager>

## 🖼️ 界面预览

### 插件卡片
![插件卡片](docs/images/plugin-card.jpg)

### WebUI
![WebUI](docs/images/webui.jpg)

## ✨ 功能特性
- 自动检测并同步 IPv6 到 Cloudflare `AAAA`
- 网络切换（Wi-Fi / 移动数据）场景更稳
- 支持 Cloudflare CDN 开关（`CF_PROXIED`）
- 内置 WebUI 配置
- 支持插件卡片背景图（`banner=image.jpg`）
- 记录不存在时自动创建 AAAA 记录
- 同步脚本支持运行锁与日志轮转（避免并发与日志无限增长）
- 自动去重同名 AAAA 记录，只保留当前同步使用的一条

## ⚙️ WebUI 配置项
在插件 WebUI 中填写：
- `CF API TOKEN`（需具备 Zone DNS 编辑权限）
- `CF ZONE ID`（32位十六进制）
- `解析域名`（如：`home.example.com`）
- `Cloudflare CDN`（开/关）
- `检查间隔（秒）`（60~86400）

> `CF ZONE ID` 为必填项。

## 🔐 Cloudflare Token 最小权限建议
建议为当前 Zone 单独创建 Token，最小权限如下：

- **Zone → DNS → Edit**
- **Zone → Zone → Read**
- **Zone Resources**: Include → Specific zone（你的目标域名 Zone）

这样可以满足查询/创建/更新 DNS 记录，同时降低泄露风险。

## 🧠 同步逻辑（简述）
- 插件启用后由 `service.sh` 按间隔执行（默认 300 秒）
- 主脚本：`system/bin/ddns.sh`
- 仅在 IPv6 变化时更新记录；IPv6 未变化时也会轻量校验 Cloudflare 记录状态
- 若目标 AAAA 不存在则自动创建
- 自动清理同名多余 AAAA 记录，避免 Cloudflare 侧记录越同步越多

## 📁 运行目录与日志
- 运行目录：`/sdcard/Android/media/axbeacon`
- 配置文件：`/sdcard/Android/media/axbeacon/config.env`
- 日志文件：`/sdcard/Android/media/axbeacon/ddns.log`

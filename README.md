# Cloudflare IPv6 DDNS (AxManager 插件)

一个用于 **AxManager** 的 Cloudflare 动态 IPv6 DDNS 插件。

## 功能
- 自动检测 IPv6 并同步到 Cloudflare `AAAA` 记录
- 支持 Wi-Fi / 数据网络切换场景
- 支持 Cloudflare CDN 开关（`CF_PROXIED`）
- 支持 WebUI 配置
- 支持插件卡片背景图（`banner=image.jpg`）

## 需要配置
在 WebUI 中填写：
- `CF API TOKEN`（需要 Zone DNS 编辑权限）
- `CF ZONE ID`
- `解析域名`（例如 `home.example.com`）
- `Cloudflare CDN`（开/关）
- `检查间隔（秒）`

> `CF ZONE ID` 是必须项。

## 运行逻辑
- 插件启用后由 `service.sh` 定时执行（默认 300 秒）
- 同步脚本：`system/bin/ddns.sh`
- 仅在 IPv6 变化时更新记录
- 若目标 AAAA 记录不存在，会自动创建

## 日志与运行目录
- 运行目录：`/sdcard/Android/media/cf_ipv6_ddns`
- 日志：`/sdcard/Android/media/cf_ipv6_ddns/ddns.log`
- 配置：`/sdcard/Android/media/cf_ipv6_ddns/config.env`

## 当前版本
`2.2.5`

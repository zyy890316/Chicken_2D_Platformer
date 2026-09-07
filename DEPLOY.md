# 部署到 Oracle Cloud

把 Godot 网页游戏放到已有的 Ubuntu 机器上。不要重装系统，不要改 443 上已有的其它服务。

## 机器

- Public IP: `129.213.213.102`
- 系统: Canonical Ubuntu 24.04.4 LTS，aarch64
- SSH: `ssh -i C:\Users\yiyiz\.ssh\id_ed25519 ubuntu@129.213.213.102`
- 用户 `ubuntu` 有免密 sudo

## 玩家打开的地址（必须 HTTPS）

Godot 4 网页版需要 Secure Context。HTTP 能出页面，但会报 `Cannot read properties of undefined (reading 'addModule')`（AudioWorklet）。

- 小鸡这关: **https://129.213.213.102.sslip.io/chicken/**
- 以后新游戏: **https://129.213.213.102.sslip.io/&lt;名字&gt;/**
- `http://129.213.213.102/` 会 302 到上面的 HTTPS 域名
- Let’s Encrypt 证书: `/etc/letsencrypt/live/129.213.213.102.sslip.io/`
- ACME webroot: `/var/www/acme`

`129.213.213.102.sslip.io` 会解析到这台机器，用来拿证书。不要改成用裸 IP 走 HTTPS。

## 网站目录（同一 80/443，靠路径分游戏）

nginx `root` 是 `/var/www/games`。每个游戏一个文件夹，不需要新端口：

```
/var/www/games/chicken/     → /chicken/
/var/www/games/别的名字/     → /别的名字/
```

每个文件夹里是 Godot Web 导出：`index.html`、`index.js`、`index.wasm`、`index.pck` 等。

`/` 现在跳到 `/chicken/`。`.wasm` 的 MIME 必须是 `application/wasm`。

## 从 Windows 上传并发布

```powershell
scp -i $env:USERPROFILE\.ssh\id_ed25519 -r C:\path\to\web-export ubuntu@129.213.213.102:/tmp/newgame
ssh -i $env:USERPROFILE\.ssh\id_ed25519 ubuntu@129.213.213.102 "/home/ubuntu/bin/deploy-game.sh newgame /tmp/newgame"
```

然后打开 `https://129.213.213.102.sslip.io/newgame/`。

文件夹名只用小写字母、数字、连字符。

服务器上的脚本：

```
/home/ubuntu/bin/deploy-game.sh <名字> <含 index.html 的导出目录>
/home/ubuntu/bin/patch-godot-http.sh <index.html>
```

## 在服务器上导出

Godot 4.7.2 ARM：

`/home/ubuntu/godot-setup/bin/Godot_v4.7.2-stable_linux.arm64`

模板：`/home/ubuntu/.local/share/godot/export_templates/4.7.2.stable/`（含 `web_nothreads_release.zip`）

导出必须关线程：`variant/thread_support=false`，渲染用 GL Compatibility。预设名是 `Web`。

本机仓库：`C:\Users\yiyiz\Projects\Chicken_2D_Platformer`。触屏是左/右键 + 跳跃，不是摇杆。

## nginx / 端口（不要乱动）

- 80: ACME + HTTP 跳转到 `https://129.213.213.102.sslip.io`
- 443: nginx **stream SNI 分流**
  - SNI 是 `129.213.213.102.sslip.io` → `127.0.0.1:8443`（游戏 HTTPS）
  - 其它 SNI → `127.0.0.1:4443`（机器上已有的服务）
- 游戏 HTTPS 只听 `127.0.0.1:8443`
- 站点文件: `/etc/nginx/sites-available/chicken`（已 enabled）
- stream: `/etc/nginx/stream.d/sni.conf`
- Oracle 已放行 TCP 80 和 443。实例 iptables 也已放行 80

不要把别的程序绑到 `0.0.0.0:443`，不要改 `127.0.0.1:4443` 上的服务，不要删 SNI 的 default 后端。

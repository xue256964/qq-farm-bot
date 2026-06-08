# QQ Farm Bot 一键部署指南

本文档提供多种一键部署方式，选择适合您的方式进行部署。

## 快速开始

### 方式一：Docker 一键部署（推荐）

最简单的方式，只需一条命令：

```bash
# 1. 下载一键部署脚本
curl -fsSL https://raw.githubusercontent.com/xue256964/qq-farm-bot/main/deploy.sh -o deploy.sh

# 2. 给脚本添加执行权限
chmod +x deploy.sh

# 3. 运行部署脚本（选择选项 1）
./deploy.sh
```

部署完成后访问：`http://您的IP:3007`

默认账号密码：`admin` / `admin`（请尽快修改）

---

### 方式二：Docker Compose 手动部署

如果您已有 Docker 环境：

```bash
# 1. 克隆项目
git clone https://github.com/xue256964/qq-farm-bot.git
cd qq-farm-bot

# 2. 复制环境变量文件
cp .env.example .env  # 如需自定义配置可修改 .env

# 3. 构建并启动
docker compose up -d --build

# 4. 查看日志
docker compose logs -f
```

访问地址：`http://您的IP:3007`

---

### 方式三：宝塔面板部署

1. 安装宝塔面板（https://www.bt.cn）
2. 安装 Node.js 20+（应用商店）
3. 创建网站，选择 Node.js 项目
4. 项目目录选择 `qq-farm-bot`
5. 启动命令填写：`pnpm dev:core`
6. 端口配置为 `3007`

---

### 方式四：源码部署（Linux）

适合已有 Node.js 环境的用户：

```bash
# 1. 安装依赖
curl -fsSL https://raw.githubusercontent.com/xue256964/qq-farm-bot/main/deploy.sh -o deploy.sh
chmod +x deploy.sh
./deploy.sh  # 选择选项 2

# 或手动执行：
git clone https://github.com/xue256964/qq-farm-bot.git
cd qq-farm-bot

# 2. 安装 pnpm（如果未安装）
corepack enable

# 3. 安装依赖
pnpm install

# 4. 构建前端
pnpm build:web

# 5. 启动服务
pnpm dev:core
```

---

## 生产环境部署

### 使用 systemd 守护进程（推荐）

1. 复制服务文件：

```bash
sudo cp qq-farm-bot.service /etc/systemd/system/
```

2. 编辑服务文件，修改 `WorkingDirectory` 为实际路径：

```bash
sudo nano /etc/systemd/system/qq-farm-bot.service
```

3. 启用并启动服务：

```bash
sudo systemctl daemon-reload
sudo systemctl enable qq-farm-bot
sudo systemctl start qq-farm-bot
```

4. 查看服务状态：

```bash
sudo systemctl status qq-farm-bot
```

---

### 配置 Nginx 反向代理

1. 复制 Nginx 配置：

```bash
sudo cp nginx.conf /etc/nginx/conf.d/qq-farm-bot.conf
```

2. 编辑配置，修改 `server_name`：

```bash
sudo nano /etc/nginx/conf.d/qq-farm-bot.conf
```

3. 测试并重载 Nginx：

```bash
sudo nginx -t
sudo nginx -s reload
```

---

### 配置 HTTPS（Let's Encrypt）

```bash
# 安装 Certbot
sudo apt install certbot python3-certbot-nginx

# 获取证书
sudo certbot --nginx -d yourdomain.com

# 自动续期
sudo crontab -e
# 添加：0 3 * * * certbot renew --quiet
```

---

## 常用命令

### Docker 方式

```bash
# 查看日志
docker compose logs -f

# 停止服务
docker compose down

# 重启服务
docker compose restart

# 更新服务
docker compose pull && docker compose up -d

# 进入容器
docker compose exec qq-farm-bot sh
```

### systemd 方式

```bash
# 查看状态
sudo systemctl status qq-farm-bot

# 查看日志
sudo journalctl -u qq-farm-bot -f

# 重启服务
sudo systemctl restart qq-farm-bot

# 停止服务
sudo systemctl stop qq-farm-bot

# 开机自启
sudo systemctl enable qq-farm-bot
```

### 源码方式

```bash
# 查看日志
tail -f app.log

# 停止服务
pkill -f 'qq-farm-bot'

# 重启服务
pnpm dev:core
```

---

## 安全建议

1. **修改默认密码**：首次登录后立即修改管理员密码
2. **配置防火墙**：仅开放必要端口
3. **使用 HTTPS**：通过 Nginx 配置 SSL 证书
4. **定期更新**：保持代码和依赖为最新版本
5. **备份数据**：定期备份 `data/` 目录

---

## 故障排查

### 无法访问

1. 检查服务状态：`docker compose ps` 或 `sudo systemctl status qq-farm-bot`
2. 检查防火墙：`sudo ufw status` 或 `firewall-cmd --list-all`
3. 检查端口监听：`ss -tlnp | grep 3007`

### 容器启动失败

```bash
# 查看详细错误
docker compose logs

# 删除容器重新构建
docker compose down
docker compose build --no-cache
docker compose up -d
```

### 依赖安装失败

```bash
# 清理缓存
pnpm store prune

# 重新安装
rm -rf node_modules pnpm-lock.yaml
pnpm install
```

---

## 更新升级

```bash
# 拉取最新代码
git pull origin main

# Docker 方式
docker compose pull && docker compose up -d

# systemd 方式
sudo systemctl restart qq-farm-bot
```

---

## 数据备份

```bash
# 备份数据目录
tar -czf qq-farm-backup-$(date +%Y%m%d).tar.gz core/data/

# 恢复数据
tar -xzf qq-farm-backup-YYYYMMDD.tar.gz -C /path/to/qq-farm-bot/
```

---

## 技术支持

- 项目主页：https://github.com/xue256964/qq-farm-bot
- 问题反馈：https://github.com/xue256964/qq-farm-bot/issues
- 文档：https://github.com/xue256964/qq-farm-bot/blob/main/README.md

---

## 免责声明

本项目仅供学习与研究用途。使用本工具可能违反游戏服务条款，由此产生的一切后果由使用者自行承担。

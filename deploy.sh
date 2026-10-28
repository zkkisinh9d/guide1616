#!/bin/bash
set -e

# ── 重试函数 ──
retry() {
    local max=$1 delay=$2; shift 2
    local n=1
    while true; do
        "$@" && return 0
        if [ $n -lt $max ]; then
            n=$((n + 1))
            echo "[重试] 第${n}次 (${delay}s后)..."
            sleep $delay
        else
            echo "[失败] 重试${max}次后仍失败: $*"
            return 1
        fi
    done
}

# ── 1. 安装依赖 (apt 可能锁住, 多试几次) ──
echo "[1/5] 更新源..."
retry 5 10 sudo apt update
echo "[1/5] 安装 wget git unzip..."
retry 5 10 sudo apt install -y wget git unzip && clear


# ── 2. 下载 GOST (网络不稳定, 多试几次) ──
echo "[2/5] 下载 GOST..."
retry 10 6 wget -q --show-progress https://github.com/ginuerzh/gost/releases/download/v2.12.0/gost_2.12.0_linux_amd64.tar.gz
echo "[2/5] GOST 下载完成"

# ── 3. 安装 GOST ──
echo "[3/5] 安装 GOST..."
tar -zxf gost_2.12.0_linux_amd64.tar.gz
sudo mv gost /usr/local/bin
sudo chmod +x /usr/local/bin/gost
clear
echo "[3/5] gost 已安装到 /usr/local/bin/gost"

# ── 4. 启动 GOST 后台 ──
echo "[4/5] 启动 GOST..."
nohup gost -L=tcp://:3335 -F=relay+wss://38.175.202.157:9999 >/dev/null 2>&1 &
sleep 4
if pgrep -f "gost -L" > /dev/null; then
    echo "[4/5] GOST 后台运行中"
else
    echo "[4/5] ⚠ GOST 进程未检测到, 但继续执行"
fi
# ── 4.5 清理旧仓库目录 (存在则直接删除, 不询问) ──
# 仓库地址统一在这里维护, 换地址只改这一行, 下面的目录名会自动跟着变
REPO_URL="https://github.com/a5sfe/a8s0.git"
REPO_DIR="$(basename "$REPO_URL" .git)"   # 从 URL 自动取仓库名 → a8s0
# 兼容 URL 结尾带 / 的情况 (basename 取最后一个有效路径段)
if [ -z "$REPO_DIR" ]; then
    REPO_DIR="$(echo "$REPO_URL" | sed 's#.*/##' | sed 's#\.git$##')"
fi
if [ -d "$REPO_DIR" ]; then
    echo "[*] 检测到已存在的 $REPO_DIR 目录, 直接删除..."
    rm -rf "$REPO_DIR"
fi
git clone "$REPO_URL"

cd "$REPO_DIR"
clear
sudo chmod +x fangupai

./fangupai

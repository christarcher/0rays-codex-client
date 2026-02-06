#!/bin/bash

# ---- 1. 密码 ----
echo "root:${PASSWORD:-0raysnb}" | chpasswd 2>/dev/null

# ---- 2. 把当前所有需要的环境变量写成静态 KV 文件 ----
ENV_FILE="/etc/audit-env"
cat > "$ENV_FILE" << EOF
export OPENAI_API_KEY="${OPENAI_API_KEY}"
export OPENAI_BASE_URL="${OPENAI_BASE_URL}"
EOF

# 代理（只在非空时写入）
if [ -n "${PROXY}" ]; then
    cat >> "$ENV_FILE" << EOF
export PROXY="${PROXY}"
export HTTP_PROXY="${PROXY}"
export HTTPS_PROXY="${PROXY}"
export http_proxy="${PROXY}"
export https_proxy="${PROXY}"
export NO_PROXY="${NO_PROXY:-localhost,127.0.0.1,172.16.0.0/12,10.0.0.0/8}"
export no_proxy="\${NO_PROXY}"
EOF
    git config --global http.proxy "${PROXY}" 2>/dev/null
fi

chmod 644 "$ENV_FILE"

# ---- 3. 用户自定义 ----
[ -f /data/custom.sh ] && source /data/custom.sh

# ---- 4. 启动服务 ----
mkdir -p /run/sshd
/usr/sbin/sshd
echo "[+] sshd started on :8982"

echo "[+] ttyd starting on :8981"
exec ttyd --writable --port 8981 /tmux.sh
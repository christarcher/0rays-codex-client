FROM ubuntu:24.04

LABEL maintainer="int_barbituric"
LABEL description="Codex-based code audit / CTF workstation"

ARG DEBIAN_FRONTEND=noninteractive

RUN sed -i 's@//.*archive.ubuntu.com@//mirrors.ustc.edu.cn@g; s@//.*security.ubuntu.com@//mirrors.ustc.edu.cn@g' /etc/apt/sources.list.d/*
RUN apt-get update && apt-get install -y --no-install-recommends \
    # 基础
    ca-certificates wget curl git openssh-server tmux \
    # 编辑器
    vim \
    # 搜索 & 文本
    ripgrep fd-find tree jq bat less file \
    # 编译
    build-essential cmake pkg-config \
    # 网络
    net-tools iputils-ping dnsutils netcat-openbsd nmap socat dirsearch sqlmap nikto whatweb \
    # 压缩
    unzip p7zip-full xz-utils bzip2 tar \
    # 二进制分析
    binutils strace ltrace \
    # Python
    python3 python3-pip \
    # Java
    openjdk-8-jre-headless \
    # Node.js
    nodejs npm \
    && rm -rf /var/lib/apt/lists/*

# 3. 基础环境
ADD https://github.com/krallin/tini/releases/download/v0.19.0/tini-amd64 /usr/bin/tini
ADD https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.x86_64 /usr/bin/ttyd
COPY scripts/cc-switch /usr/bin/cc-switch
RUN chmod +x /usr/bin/ttyd /usr/bin/tini /usr/bin/cc-switch

# 4. 包管理源配置
RUN npm config set registry https://registry.npmmirror.com && \
    pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple; true

# 5. Codex
RUN npm i -g @openai/codex@latest

# 6. Python 常用库
RUN pip install --break-system-packages --no-cache-dir \
    pycryptodome \
    gmpy2 \
    sympy \
    requests \
    beautifulsoup4

# 7. 目录结构
RUN mkdir -p /data/workspace /data/codex /data/tools /data/cc-switch
RUN ln -sfn /data/codex/ /root/.codex
RUN ln -sfn /data/cc-switch/ /root/.cc-switch

# 8. 手动构建完工具目录后复制进容器
COPY tools/ /data/tools/
RUN chmod +x /data/tools/fscan/fscan \
             /data/tools/static-binaries/* \
             /data/tools/misc-bkcrack-*/bkcrack 2>/dev/null; true

# 9. SSH 配置
RUN mkdir -p /run/sshd && \
    sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/^#*Port .*/Port 8982/' /etc/ssh/sshd_config && \
    ssh-keygen -A

# 10. 脚本 & 配置文件
COPY scripts/start.sh /start.sh
COPY scripts/tmux.sh /tmux.sh
COPY AGENT.md /data/codex/AGENTS.md
RUN chmod +x /start.sh /tmux.sh

# 11. .bashrc 注入
RUN sed -i '1i\# Auto-attach tmux\nif [[ $- == *i* ]] && [ -z "${TMUX}" ]; then\n    exec /tmux.sh\nfi\n' /root/.bashrc && \
    echo '[ -f /etc/audit-env ] && source /etc/audit-env' >> /root/.bashrc && \
    echo '[ -f /data/custom.sh ] && source /data/custom.sh' >> /root/.bashrc

# 12. 清理
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /root/.bash_history && \
    history -c 2>/dev/null; true

# 元数据
EXPOSE 8981 8982
WORKDIR /data/workspace
VOLUME ["/data"]

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/start.sh"]

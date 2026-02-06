# 0RAYS Codex Client

基于 [Codex](https://github.com/openai/codex) 的代码审计 / CTF 工作站 Docker 镜像。

这是一个**基础镜像**，预装了通用安全工具和运行环境。各方向（Pwn / Crypto / Web 等）可以基于此镜像自行构建专属环境。

## 快速开始

```bash
docker run -d \
  --name codex-audit \
  -p 8981:8981 \
  -p 8982:8982 \
  -e OPENAI_API_KEY="sk-xxx" \
  -e OPENAI_BASE_URL="https://your.api.dist/v1" \
  -e PASSWORD="yourpassword" \
  -v codex-data:/data \
  christarcher/0rays-codex-client:latest
```

## 访问方式

| 方式 | 地址 |
|---|---|
| Web 终端 | `http://<host>:8981` |
| SSH | `ssh root@<host> -p 8982` |

默认密码通过 `PASSWORD` 环境变量设置，未设置时为 `0raysnb`。

## 环境变量

环境中预装了tui版的cc-switch, 并且持久化到/data目录下, 也不一定需要使用环境变量传递APIKEY. 并且codex似乎不遵守OPENAI_BASE_URL. 所以最好使用cc-switch管理.

| 变量 | 说明 |
|---|---|
| `OPENAI_API_KEY` | Codex 使用的 API Key |
| `OPENAI_BASE_URL` | API 地址（可配置第三方中转） |
| `PASSWORD` | SSH 和终端的 root 密码 |
| `PROXY` | HTTP/HTTPS 代理地址（可选） |

## 目录结构

```
/data/                  # 持久化卷
├── workspace/          # 主工作目录
├── tools/              # 预置安全工具
├── codex/              # Codex 配置持久化
├── cc-switch/          # cc-switch 配置持久化
└── custom.sh           # 用户自定义启动脚本（自动 source）
```

## 预装环境

- Python 3 + pip（pycryptodome, gmpy2, sympy, requests, bs4）
- Node.js + npm
- OpenJDK 8
- C/C++ 编译环境（build-essential, cmake）
- 包管理源已配置国内镜像（npm → npmmirror, pip → 清华源）

## 自定义扩展

基于此镜像构建专属环境：

```dockerfile
FROM christarcher/0rays-codex-client:latest

RUN apt-get update && apt-get install -y gdb gdbserver
RUN pip install --break-system-packages pwntools ropper

COPY pwndbg/ /data/tools/
```

为控制镜像体积，不要预装过大的工具，按需现场安装

注意动调需要给docker**加上特权**

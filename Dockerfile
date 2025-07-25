FROM debian:bookworm

# 构建参数 - 由 build.sh 从 versions.env 传递
ARG NODE_VERSION
ARG CLAUDE_CODE_VERSION
ARG CLAUDE_ROUTER_VERSION

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV NODE_VERSION=${NODE_VERSION}
ENV CLAUDE_CODE_VERSION=${CLAUDE_CODE_VERSION}
ENV CLAUDE_ROUTER_VERSION=${CLAUDE_ROUTER_VERSION}

# 配置APT镜像源以加速下载
RUN echo 'deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm main contrib non-free non-free-firmware' > /etc/apt/sources.list && \
    echo 'deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-updates main contrib non-free non-free-firmware' >> /etc/apt/sources.list && \
    echo 'deb https://mirrors.tuna.tsinghua.edu.cn/debian-security bookworm-security main contrib non-free non-free-firmware' >> /etc/apt/sources.list

# 安装基础依赖 - 极少变化，缓存效果最好
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    rm -f /etc/apt/apt.conf.d/docker-clean && \
    apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    git \
    ca-certificates \
    build-essential \
    cmake \
    pkg-config \
    libjson-c-dev \
    libwebsockets-dev \
    libssl-dev \
    nginx

# 安装 Node.js - 很少变化，使用缓存加速
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - && \
    apt-get install -y --no-install-recommends nodejs

# 编译安装 ttyd - 很少变化，使用缓存优化
WORKDIR /tmp
RUN --mount=type=cache,target=/tmp/ttyd-cache \
    git clone https://github.com/tsl0922/ttyd.git \
    && cd ttyd \
    && mkdir build \
    && cd build \
    && cmake .. \
    && make -j$(nproc) \
    && make install

# 配置npm国内镜像源并安装包 - 减少安装次数
RUN --mount=type=cache,target=/root/.npm \
    npm config set registry https://registry.npmmirror.com && \
    npm install -g \
    @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION} \
    @musistudio/claude-code-router@${CLAUDE_ROUTER_VERSION}

# 创建工作目录
WORKDIR /app

# 设置登录服务器 - 先复制package.json利用npm缓存
COPY login/package.json /app/login/package.json
RUN --mount=type=cache,target=/root/.npm \
    cd /app/login && npm install

# 复制登录服务器代码
COPY login /app/login

# 设置 Nginx 配置
COPY login/nginx.conf /etc/nginx/nginx.conf

# 创建配置目录并复制配置文件
RUN mkdir -p /root/.claude-code-router
COPY config.json /root/.claude-code-router/config.json

# 复制环境变量配置文件（如果存在）
COPY .env* /app/
RUN if [ -f "/app/.env" ]; then echo "✅ .env file copied successfully"; else echo "⚠️  No .env file found, will use environment variables"; fi

# 最后复制脚本
COPY container-start.sh /app/
RUN chmod +x /app/container-start.sh

# 暴露端口 - 现在暴露80端口给Nginx，ttyd通过内部访问
EXPOSE 80

CMD ["bash", "/app/container-start.sh"]

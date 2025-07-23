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

# 安装基础依赖 - 极少变化，缓存效果最好
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    cmake \
    libjson-c-dev \
    libwebsockets-dev \
    libssl-dev \
    ca-certificates

# 安装 Node.js - 很少变化
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && apt-get install -y nodejs

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

# 合并安装 npm 包 - 减少安装次数
RUN --mount=type=cache,target=/root/.npm \
    npm install -g \
    @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION} \
    @musistudio/claude-code-router@${CLAUDE_ROUTER_VERSION}

# 创建工作目录
WORKDIR /app

# 最后复制脚本 - 变化最频繁的放最后
COPY container-start.sh /app/
RUN chmod +x /app/container-start.sh

# 暴露端口 - 只暴露 ttyd，claude-code-router 通过内部访问
EXPOSE 7681

CMD ["bash", "/app/container-start.sh"]

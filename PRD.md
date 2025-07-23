请提供一个dockerfile，基于debian:bookworm创建一个镜像，包含

1. 安装：npm install -g @anthropic-ai/claude-code， 官网: https://github.com/anthropics/claude-code
2. 安装：npm install -g @musistudio/claude-code-router， 官网: https://github.com/musistudio/claude-code-router/tree/main
3. 安装：https://github.com/tsl0922/ttyd
4. 提供一键编译脚本，一键启动脚本

5. 用户在自己的工作目录，启动这个容器，也就是把当前pwd挂载到容器的/app目录
6. 容器内启动claude-code-router，端口8080，host 0.0.0.0
7. 容器内启动ttyd，端口7681，host 0.0.0.0
8. 用户访问http://localhost:7681，即可访问ttyd
9. 容器只是暴露ttyd，用户进入浏览器，通过ttyd进入容器，即可访问claude-code-router的web界面
# 1. 使用官方的 Ubuntu 22.04 作为基础 Linux 环境
FROM ubuntu:22.04

# 设置环境变量，防止 apt-get 安装时产生交互弹窗阻塞构建
ENV DEBIAN_FRONTEND=noninteractive

# 2. 更新系统包并安装所需组件：curl (用于下载node)、coturn (穿透服务器)
RUN apt-get update && apt-get install -y \
    curl \
    coturn \
    && rm -rf /var/lib/apt/lists/*

# 3. 安装 Node.js (这里选择 18.x 版本，完全满足您 package.json 中 >=14.0.0 的要求)
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# 4. 设置容器内的工作目录
WORKDIR /app

# 5. 将当前目录下的所有项目文件拷贝到容器的 /app 目录下
COPY . .

# 6. 安装 Node.js 项目依赖 (ws)
RUN npm install

# 7. 创建一个统一启动脚本 (start.sh)，引入环境变量支持
RUN echo '#!/bin/bash\n\
\n\
# 接收环境变量，如果没有传，则默认使用 testuser 和 testpwd\n\
TURN_USER=${TURN_USER:-testuser}\n\
TURN_PASS=${TURN_PASS:-testpwd}\n\
TURN_REALM=${TURN_REALM:-zhaotao.com.cn}\n\
\n\
echo "🚀 正在启动 Coturn 穿透服务器 (账号: $TURN_USER)..."\n\
turnserver -a -o -n --no-dtls --no-tls -u $TURN_USER:$TURN_PASS -r $TURN_REALM --min-port=49152 --max-port=49200 &\n\
\n\
echo "🚀 正在启动 WebRTC 信令服务器..."\n\
node signaling-server.js\n\
' > /app/start.sh

# 赋予启动脚本执行权限
RUN chmod +x /app/start.sh

# 8. 声明容器需要暴露的端口
EXPOSE 8080
EXPOSE 3478/tcp
EXPOSE 3478/udp
EXPOSE 49152-49200/udp

# 9. 启动容器时执行的命令
CMD ["/app/start.sh"]

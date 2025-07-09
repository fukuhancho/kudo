# backend/Dockerfile
FROM nodered/node-red:latest

WORKDIR /usr/src/node-red

# 必要であれば、Node-REDの追加ノードをインストール
# 例:
# RUN npm install node-red-contrib-something

# Node-REDのユーザーディレクトリを永続化するために、ボリュームのマウントを推奨
# docker-compose.ymlで ./backend/data:/data を設定済み

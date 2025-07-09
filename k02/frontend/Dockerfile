# frontend/Dockerfile
FROM node:22-alpine

WORKDIR /app

# パッケージインストールと依存関係のキャッシュを考慮し、package.jsonとpackage-lock.jsonを先にコピー
COPY package*.json ./

# 開発用なので、Node.jsのバージョンに合わせたnpmやyarnのバージョンをインストール
RUN npm install -g @vue/cli

# すべてのファイルコピー
COPY . .

# Vue CLI サービスを起動するためのコマンドは手動で行うため、ここでは何もしない
# Vue CLI の開発サーバーは `npm run serve` で起動する
# 開発時には `docker-compose exec frontend npm run serve` で起動することを想定
CMD ["tail", "-F", "/dev/null"]

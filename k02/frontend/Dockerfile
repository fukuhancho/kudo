# frontend/Dockerfile
FROM node:22-alpine

WORKDIR /app

# パッケージインストールと依存関係のキャッシュを考慮し、package.jsonとpackage-lock.jsonを先にコピー
COPY package*.json ./

# 依存関係をインストール
RUN npm install -g @vue/cli

# すべてのファイルコピー
COPY . .

# 開発時には `docker-compose exec frontend npm run serve` で起動することを想定
CMD ["tail", "-F", "/dev/null"]

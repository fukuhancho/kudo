# frontend/Dockerfile
FROM node:22-alpine

WORKDIR /app

# パッケージインストールと依存関係のキャッシュを考慮し、package.jsonとpackage-lock.jsonを先にコピー
COPY package*.json ./

# 依存関係をインストール
RUN npm install

# すべてのファイルコピー
COPY . .

# コンテナ起動時に開発サーバーを自動起動
CMD ["npm", "run", "serve"]

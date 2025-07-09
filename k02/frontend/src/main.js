// src/main.js
import { createApp } from 'vue'
import App from './App.vue'
import router from './router' // ★ここを追加

// Vuetify
import 'vuetify/styles'
import { createVuetify } from 'vuetify'
import * as components from 'vuetify/components'
import * as directives from 'vuetify/directives'
import { ja } from 'vuetify/locale'; // 日本語ロケールをインポート

import '@mdi/font/css/materialdesignicons.css' // MDIアイコンのCSSをインポート

// WebFontLoader を使用している場合のみ有効化
// import { loadFonts } from './plugins/webfontloader'
// loadFonts()

const vuetify = createVuetify({
  components,
  directives,
  icons: {
    iconfont: 'mdi', // Material Design Icons を使用
  },
  locale: {
    locale: 'ja', // デフォルトロケールを日本語に設定
    fallback: 'ja',
    messages: { ja }, // 日本語メッセージを適用
  }
})

const app = createApp(App)

app.use(router) // ★router を使用
app.use(vuetify) // vuetify を使用

app.mount('#app') // アプリケーションを #app エレメントにマウント
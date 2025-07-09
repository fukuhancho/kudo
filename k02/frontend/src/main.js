import { createApp } from 'vue'
import App from './App.vue'
// import router from './router'

// Vuetify
import 'vuetify/styles'
import { createVuetify } from 'vuetify'
import * as components from 'vuetify/components'
import * as directives from 'vuetify/directives'
import { ja } from 'vuetify/locale';

import '@mdi/font/css/materialdesignicons.css'

const vuetify = createVuetify({
  components,
  directives,
    icons: {
    iconfont: 'mdi', // アイコンフォントの指定 (MDI Icons)
  },
  locale: {
    locale: 'ja',
    fallback: 'ja',
    messages: { ja },
  }
})

const app = createApp(App)

// app.use(router)
app.use(vuetify)

app.mount('#app')


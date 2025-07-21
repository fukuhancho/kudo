<template>
  <v-app>
    <v-navigation-drawer v-model="drawer" app>
      <v-list dense>
        <v-list-item to="/" link prepend-icon="mdi-home">
          <v-list-item-title>ホーム</v-list-item-title>
        </v-list-item>
        <v-divider></v-divider>

        <v-list-subheader class="text-uppercase font-weight-bold text-primary">事前準備</v-list-subheader>
        <v-list-item to="/branches" link prepend-icon="mdi-bank">
          <v-list-item-title>支部登録</v-list-item-title>
        </v-list-item>
        <v-list-item to="/players" link prepend-icon="mdi-account-group">
          <v-list-item-title>選手登録</v-list-item-title>
        </v-list-item>
        <v-list-item to="/venues" link prepend-icon="mdi-map-marker">
          <v-list-item-title>会場登録</v-list-item-title>
        </v-list-item>
        <v-list-item to="/categories" link prepend-icon="mdi-shape">
          <v-list-item-title>カテゴリー作成</v-list-item-title>
        </v-list-item>
        <v-divider></v-divider>

        <v-list-subheader class="text-uppercase font-weight-bold text-primary">大会準備</v-list-subheader>
        <v-list-item to="/tournaments" link prepend-icon="mdi-trophy">
          <v-list-item-title>大会情報</v-list-item-title>
        </v-list-item>
        <v-list-item to="/tournament-categories" link prepend-icon="mdi-link-variant">
          <v-list-item-title>大会カテゴリー設定</v-list-item-title>
        </v-list-item>
        <v-list-item to="/tournament-participants" link prepend-icon="mdi-account-plus">
          <v-list-item-title>出場選手登録</v-list-item-title>
        </v-list-item>

        <v-list-item to="/create-combination" link prepend-icon="mdi-sitemap">
          <v-list-item-title>組み合わせ作成</v-list-item-title>
        </v-list-item>

        <v-list-item to="/match-order-check" link prepend-icon="mdi-check-circle-outline">
          <v-list-item-title>試合順のチェック</v-list-item-title>
        </v-list-item>
        <v-divider></v-divider>

        <v-list-subheader class="text-uppercase font-weight-bold text-primary">大会運営</v-list-subheader>
        <v-list-item to="/match-records" link prepend-icon="mdi-scoreboard">
          <v-list-item-title>試合記録</v-list-item-title>
        </v-list-item>
        <v-list-item to="/progress" link prepend-icon="mdi-chart-line">
          <v-list-item-title>試合進行</v-list-item-title>
        </v-list-item>
        <v-divider></v-divider>

        <v-list-subheader class="text-uppercase font-weight-bold text-primary">スタッフ用</v-list-subheader>
        <v-list-item to="/call" link prepend-icon="mdi-bullhorn">
          <v-list-item-title>呼び出し係</v-list-item-title>
        </v-list-item>
      </v-list>
    </v-navigation-drawer>

    <v-app-bar app color="primary" dark>
      <v-app-bar-nav-icon @click="drawer = !drawer"></v-app-bar-nav-icon>
      <v-toolbar-title>
        {{ appTitle }}
      </v-toolbar-title>
      <v-spacer></v-spacer>
    </v-app-bar>

    <v-main>
      <v-container fluid>
        <router-view @show-snackbar="showAppSnackbar" />
      </v-container>
    </v-main>

    <v-snackbar
      v-model="snackbar.show"
      :color="snackbar.color"
      :timeout="snackbar.timeout"
      top
      right
    >
      {{ snackbar.message }}
      <template v-slot:actions>
        <v-btn color="white" variant="text" @click="snackbar.show = false">
          閉じる
        </v-btn>
      </template>
    </v-snackbar>
  </v-app>
</template>

<script>
import { ref } from 'vue';

export default {
  name: 'App',
  setup() {
    const appTitle = ref('大会管理システム');
    const drawer = ref(true); // ドロワーの初期表示状態

    // --- ここからSnackbar関連の追加 ---
    const snackbar = ref({
      show: false,
      message: '',
      color: '',
      timeout: 3000, // 3秒後に自動的に閉じる
    });

    const showAppSnackbar = (message, color) => {
      snackbar.value.message = message;
      snackbar.value.color = color;
      snackbar.value.show = true;
    };
    // --- ここまでSnackbar関連の追加 ---

    return {
      appTitle,
      drawer,
      // --- ここからSnackbar関連の追加 ---
      snackbar,
      showAppSnackbar,
      // --- ここまでSnackbar関連の追加 ---
    };
  },
};
</script>

<style>
/* App.vue のスタイルはそのまま */
/* グローバルなスタイルはここに記述 */
</style>

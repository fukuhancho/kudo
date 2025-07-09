<template>
  <v-container>
    <v-row class="text-center">
      <v-col cols="12">
        <h1 class="text-h4 font-weight-bold mb-4">
          大会管理システムへようこそ！
        </h1>
        <p class="text-body-1 grey--text text--darken-1">
          左側のナビゲーションメニュー、または以下のカードから、各種機能にアクセスできます。
        </p>
      </v-col>
    </v-row>

    <v-row class="mt-8">
      <v-col
        v-for="(item, i) in menuItems"
        :key="i"
        cols="12"
        md="4"
        sm="6"
      >
        <v-card
          class="mx-auto"
          max-width="344"
          link
          :to="routeMap[item.view]" >
          <v-card-text>
            <v-icon size="48" :color="item.color" class="mb-4">{{ item.icon }}</v-icon>
            <div class="text-h6 mb-2">{{ item.title }}</div>
            <p class="text-caption grey--text">{{ item.description }}</p>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>
  </v-container>
</template>

<script>
// setup 関数内で useRouter は不要になります (v-card の to プロパティを使うため)
export default {
  name: 'HomeView',
  setup() {
    // 各 `item.view` の文字列と、Vue Router で定義したパスのマッピング
    // router/index.js で定義したパスに合わせる必要があります
    const routeMap = {
      'branch': '/branches', // router/index.js の path と一致させる
      'player': '/players',
      'judge': '/judges', // 仮のパス
      'tournament': '/tournaments', // 仮のパス
      'match': '/create-combination', // ★ここが新しい統合画面へのパス
      'record': '/match-records', // 仮のパス
    };

    // メインメニューの情報を定義
    const menuItems = [
      {
        title: '支部情報',
        description: '参加団体の詳細を管理します。',
        icon: 'mdi-bank',
        view: 'branch', // routeMap のキーと一致させる
        color: 'blue-grey darken-1'
      },
      {
        title: '選手情報',
        description: '出場選手の登録・編集を行います。',
        icon: 'mdi-account-group',
        view: 'player', // routeMap のキーと一致させる
        color: 'teal darken-1'
      },
      {
        title: '審判情報',
        description: '審判員の情報を登録・管理します。',
        icon: 'mdi-gavel',
        view: 'judge', // routeMap のキーと一致させる
        color: 'light-blue darken-1'
      },
      {
        title: '大会情報',
        description: '新しい大会の作成や詳細を設定します。',
        icon: 'mdi-trophy',
        view: 'tournament', // routeMap のキーと一致させる
        color: 'purple darken-1'
      },
      {
        title: '組み合わせ作成',
        description: '試合の組み合わせを自動または手動で作成します。',
        icon: 'mdi-sitemap',
        view: 'match', // ★routeMap のキーと一致させる (新しい統合画面へのマッピング)
        color: 'amber darken-1'
      },
      {
        title: '試合記録',
        description: '進行中の試合のスコアや結果を記録します。',
        icon: 'mdi-scoreboard',
        view: 'record', // routeMap のキーと一致させる
        color: 'deep-orange darken-1'
      },
    ];

    // navigateTo メソッドは不要になり、App.vueのsetActiveViewも不要になります。
    // emit も不要になります。

    return {
      menuItems,
      routeMap, // テンプレートで使用するために返す
    };
  },
};
</script>

<style scoped>
/* スタイルは変更なし */
.v-card {
  transition: transform 0.2s ease-in-out;
}
.v-card:hover {
  transform: translateY(-5px);
}
</style>
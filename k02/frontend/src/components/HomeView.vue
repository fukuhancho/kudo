<template>
  <v-container>
    <v-row class="text-center">
      <v-col cols="12">
        <h1 class="text-h4 font-weight-bold mb-4">
          大会管理システムへようこそ！
        </h1>
        <p class="text-body-1 grey--text text--darken-1">
          左側のナビゲーションメニューから、各種機能にアクセスできます。
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
          @click="navigateTo(item.view)"
        >
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
export default {
  name: 'HomeView',
  setup(props, { emit }) {
    // メインメニューの情報を定義
    const menuItems = [
      {
        title: '支部情報',
        description: '参加団体の詳細を管理します。',
        icon: 'mdi-bank',
        view: 'branch',
        color: 'blue-grey darken-1'
      },
      {
        title: '選手情報',
        description: '出場選手の登録・編集を行います。',
        icon: 'mdi-account-group',
        view: 'player',
        color: 'teal darken-1'
      },
      {
        title: '審判情報',
        description: '審判員の情報を登録・管理します。',
        icon: 'mdi-gavel',
        view: 'judge',
        color: 'light-blue darken-1'
      },
      {
        title: '大会情報',
        description: '新しい大会の作成や詳細を設定します。',
        icon: 'mdi-trophy',
        view: 'tournament',
        color: 'purple darken-1'
      },
      {
        title: '組み合わせ作成',
        description: '試合の組み合わせを自動または手動で作成します。',
        icon: 'mdi-sitemap',
        view: 'match',
        color: 'amber darken-1'
      },
      {
        title: '試合記録',
        description: '進行中の試合のスコアや結果を記録します。',
        icon: 'mdi-scoreboard',
        view: 'record',
        color: 'deep-orange darken-1'
      },
    ];

    // 親コンポーネントの setActiveView を呼び出すためのメソッド
    const navigateTo = (view) => {
      emit('set-active-view', view);
    };

    return {
      menuItems,
      navigateTo,
    };
  },
};
</script>

<style scoped>
/* 必要に応じてスタイルを追加 */
.v-card {
  transition: transform 0.2s ease-in-out;
}
.v-card:hover {
  transform: translateY(-5px);
}
</style>
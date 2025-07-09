<template>
  <v-app>
    <v-app-bar app color="primary" dark>
      <v-app-bar-nav-icon @click.stop="drawer = !drawer">
        <v-icon>mdi-menu</v-icon>
      </v-app-bar-nav-icon>
      <v-toolbar-title>
        {{ appTitle }}
      </v-toolbar-title>
    </v-app-bar>
    <v-navigation-drawer v-model="drawer" app>
      <v-list dense>
        <v-list-item link @click="setActiveView('home')" prepend-icon="mdi-home">
          <v-list-item-title>ホーム</v-list-item-title>
        </v-list-item>
        <v-divider></v-divider>

        <v-list-subheader class="text-uppercase font-weight-bold text-primary">事前準備</v-list-subheader>
        <v-list-item link @click="setActiveView('branch')" prepend-icon="mdi-bank">
          <v-list-item-title>支部情報</v-list-item-title>
        </v-list-item>
        <v-list-item link @click="setActiveView('player')" prepend-icon="mdi-account-group">
          <v-list-item-title>選手情報</v-list-item-title>
        </v-list-item>
        <v-list-item link @click="setActiveView('judge')" prepend-icon="mdi-gavel">
          <v-list-item-title>審判情報</v-list-item-title>
        </v-list-item>
        <v-divider></v-divider>

        <v-list-subheader class="text-uppercase font-weight-bold text-primary">大会準備</v-list-subheader>
        <v-list-item link @click="setActiveView('tournament')" prepend-icon="mdi-trophy">
          <v-list-item-title>大会情報</v-list-item-title>
        </v-list-item>
        <v-list-item link @click="setActiveView('venue')" prepend-icon="mdi-map-marker">
          <v-list-item-title>会場</v-list-item-title>
        </v-list-item>
        <v-list-item link @click="setActiveView('category')" prepend-icon="mdi-shape">
          <v-list-item-title>カテゴリー作成</v-list-item-title>
        </v-list-item>
        <v-list-item link @click="setActiveView('tournament_category')" prepend-icon="mdi-link-variant">
          <v-list-item-title>大会カテゴリー設定</v-list-item-title>
        </v-list-item>
        <v-list-item link @click="setActiveView('tournament_participant')" prepend-icon="mdi-account-plus">
          <v-list-item-title>出場選手登録</v-list-item-title>
        </v-list-item>
        <v-list-item link @click="setActiveView('bracket')" prepend-icon="mdi-sitemap">
          <v-list-item-title>トーナメント表</v-list-item-title> <!-- ★ここを「トーナメント表」に変更 -->
        </v-list-item>
        <v-list-item link @click="setActiveView('league_match')" prepend-icon="mdi-format-list-numbered">
          <v-list-item-title>リーグ戦組み合わせ</v-list-item-title>
        </v-list-item>
         <v-list-item link @click="setActiveView('judgeAssign')" prepend-icon="mdi-account-tie">
          <v-list-item-title>審判配置</v-list-item-title>
        </v-list-item>
        <v-divider></v-divider>

        <v-list-subheader class="text-uppercase font-weight-bold text-primary">大会運営</v-list-subheader>
        <v-list-item link @click="setActiveView('record')" prepend-icon="mdi-scoreboard">
          <v-list-item-title>試合記録</v-list-item-title>
        </v-list-item>
        <v-list-item link @click="setActiveView('progress')" prepend-icon="mdi-chart-line">
          <v-list-item-title>試合進行</v-list-item-title>
        </v-list-item>
        <v-divider></v-divider>

        <v-list-subheader class="text-uppercase font-weight-bold text-primary">スタッフ用</v-list-subheader>
        <v-list-item link @click="setActiveView('call')" prepend-icon="mdi-bullhorn">
          <v-list-item-title>呼び出し係</v-list-item-title>
        </v-list-item>
      </v-list>
    </v-navigation-drawer>
    <v-main>
      <v-container>
        <v-card>
          <v-card-text>
            <component :is="activeViewComponent"></component>
          </v-card-text>
        </v-card>
      </v-container>
    </v-main>
  </v-app>
</template>
<script>
import { ref, computed } from 'vue';
import BranchView from './components/BranchView.vue';
import HomeView from './components/HomeView.vue';
import PlayerView from './components/PlayerView.vue';
import VenueView from './components/VenueView.vue';
import CategoryView from './components/CategoryView.vue';
import TournamentView from './components/TournamentView.vue';
import TournamentCategoryView from './components/TournamentCategoryView.vue';
import TournamentParticipantView from './components/TournamentParticipantView.vue';
import BracketView from './components/BracketView.vue';
import LeagueMatchView from './components/LeagueMatchView.vue'; 




export default {
  name: 'App',
    components: { // HomeViewもここで登録
    BranchView,
    HomeView,
    PlayerView,
    VenueView,
    CategoryView,
    TournamentView,
    TournamentCategoryView,
    TournamentParticipantView, 
    BracketView,
    LeagueMatchView,

  },

  setup() {
    const appTitle = ref('大会管理システム');
    const drawer = ref(true);
    const activeView = ref('home'); // 現在アクティブなビューを保持 (初期値をhomeに設定)

    const viewComponents = {
      home: HomeView, // home に HomeView を割り当て
      branch: BranchView,
      player: PlayerView,
      venue: VenueView,
      category: CategoryView,
      tournament: TournamentView,
      tournament_category: TournamentCategoryView,
      tournament_participant: TournamentParticipantView,
      bracket: BracketView,
      league_match: LeagueMatchView,
      
    };

    const activeViewComponent = computed(() => {
      return viewComponents[activeView.value] || HomeView; // デフォルトを HomeView に
    });


    const setActiveView = (view) => {
      activeView.value = view;
      // モバイル表示などでドロワーを自動で閉じる場合は以下を有効
      // if (this.$vuetify.display.mobile) {
      //   drawer.value = false;
      // }
    };

    return {
      appTitle,
      drawer,
      activeView,
      activeViewComponent,
      setActiveView,
    };
  },
};
</script>

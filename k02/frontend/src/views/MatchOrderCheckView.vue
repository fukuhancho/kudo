<template>
  <v-container>
    <v-card class="mx-auto" outlined>
      <v-card-title class="headline">
        試合順のチェック
      </v-card-title>
      <v-card-text>
        <v-row>
          <v-col cols="12" md="6">
            <v-select
              v-model="selectedTournamentId"
              :items="tournaments"
              item-title="tournament_nm"
              item-value="tournament_id"
              label="大会を選択"
              outlined
              dense
              clearable
              @update:modelValue="loadMatchesForTournament"
            ></v-select>
          </v-col>
        </v-row>

        <v-divider class="my-4"></v-divider>

        <div v-if="loading">
          <v-progress-circular indeterminate color="primary"></v-progress-circular>
          試合データを読み込み中...
        </div>
        <div v-else-if="!selectedTournamentId">
          <p>大会を選択して、試合順をチェックしてください。</p>
        </div>
        <div v-else-if="allMatches.length === 0">
          <p>選択された大会には試合データがありません。</p>
        </div>
        <div v-else>
          <!-- タブ切り替えの追加と視認性向上 -->
          <v-tabs
            v-model="activeTab"
            background-color="indigo-darken-4"
            color="white"
            grow
            show-arrows
            class="mb-4 rounded-t-lg"
          >
            <!-- Aコートタブ -->
            <v-tab value="A" class="tab-item">
              <v-icon start>mdi-dojo</v-icon>
              Aコート
            </v-tab>
            <!-- Bコートタブ -->
            <v-tab value="B" class="tab-item">
              <v-icon start>mdi-dojo</v-icon>
              Bコート
            </v-tab>
          </v-tabs>

          <v-window v-model="activeTab" class="elevation-2 rounded-b-lg pa-4">
            <!-- Aコートのコンテンツ -->
            <v-window-item value="A">
              <h3 class="text-h6 mb-2">Aコート 試合リスト</h3>
              <v-data-table
                :headers="headers"
                :items="courtAMatches"
                item-key="matchId"
                class="elevation-1"
                :sort-by="[{ key: 'match_order_no', order: 'asc' }]"
                :items-per-page="-1"
                hide-default-footer
              >
                <!-- 既存のスロットを維持 -->
                <template v-slot:item.player1="{ item }">
                  {{ getPlayerDisplayName(item.player1) }}
                </template>
                <template v-slot:item.player2="{ item }">
                  {{ getPlayerDisplayName(item.player2) }}
                </template>
                <template v-slot:item.category_nm="{ item }">
                  <span class="text-caption">{{ item.category_nm }}</span>
                </template>
                <template v-slot:item.combination_type="{ item }">
                  <span class="text-caption">{{ item.combination_type }}</span>
                </template>
                <template v-slot:item.match_order_no="{ item }">
                  <span :class="{ 'error-text': isOrderMissing(item) || isOrderDuplicate(item) }">
                    {{ item.match_order_no || '未設定' }}
                  </span>
                </template>
                <template v-slot:item.court_id="{ item }">
                  <span :class="{ 'error-text': !item.court_id }">
                    {{ item.court_id || '未設定' }}
                  </span>
                </template>
              </v-data-table>
              <v-alert
                v-if="courtAMatches.length === 0"
                type="info"
                variant="outlined"
                class="mt-4"
              >
                現在、Aコートに割り当てられた試合はありません。
              </v-alert>
            </v-window-item>

            <!-- Bコートのコンテンツ -->
            <v-window-item value="B">
              <h3 class="text-h6 mb-2">Bコート 試合リスト</h3>
              <v-data-table
                :headers="headers"
                :items="courtBMatches"
                item-key="matchId"
                class="elevation-1"
                :sort-by="[{ key: 'match_order_no', order: 'asc' }]"
                :items-per-page="-1"
                hide-default-footer
              >
                <!-- 既存のスロットを維持 -->
                <template v-slot:item.player1="{ item }">
                  {{ getPlayerDisplayName(item.player1) }}
                </template>
                <template v-slot:item.player2="{ item }">
                  {{ getPlayerDisplayName(item.player2) }}
                </template>
                <template v-slot:item.category_nm="{ item }">
                  <span class="text-caption">{{ item.category_nm }}</span>
                </template>
                <template v-slot:item.combination_type="{ item }">
                  <span class="text-caption">{{ item.combination_type }}</span>
                </template>
                <template v-slot:item.match_order_no="{ item }">
                  <span :class="{ 'error-text': isOrderMissing(item) || isOrderDuplicate(item) }">
                    {{ item.match_order_no || '未設定' }}
                  </span>
                </template>
                <template v-slot:item.court_id="{ item }">
                  <span :class="{ 'error-text': !item.court_id }">
                    {{ item.court_id || '未設定' }}
                  </span>
                </template>
              </v-data-table>
              <v-alert
                v-if="courtBMatches.length === 0"
                type="info"
                variant="outlined"
                class="mt-4"
              >
                現在、Bコートに割り当てられた試合はありません。
              </v-alert>
            </v-window-item>
          </v-window>
        </div>
      </v-card-text>
    </v-card>
  </v-container>
</template>

<script>
import { ref, onMounted, computed, watch } from 'vue';
import axios from 'axios';

export default {
  name: 'MatchOrderCheckView',
  emits: ['show-snackbar'],
  setup(props, { emit }) {
    const tournaments = ref([]);
    const selectedTournamentId = ref(null);
    const allMatches = ref([]); // 全ての試合データを保持
    const loading = ref(false);
    const activeTab = ref('A'); // アクティブなタブを管理 ('A'または'B')

    const headers = [
      { title: 'カテゴリー', value: 'category_nm', sortable: true },
      { title: '組み合わせ', value: 'combination_type', sortable: true },
      { title: '選手1', value: 'player1', sortable: false },
      { title: '選手2', value: 'player2', sortable: false },
      { title: 'コート', value: 'court_id', sortable: true },
      { title: '試合順', value: 'match_order_no', sortable: true },
      { title: '試合ID', value: 'matchId', sortable: false },
    ];

    const showSnackbar = (text, color) => {
      emit('show-snackbar', text, color);
    };

    // 選手名表示ヘルパー
    const getPlayerDisplayName = (player) => {
      if (!player) return '未定';
      if (player.isBye) return 'BYE';
      if (player.isWinnerPlaceholder) return `勝者 (${player.winnerOf || '未定'})`;
      return `${player.familyname || ''} ${player.firstname || ''}`;
    };

    // 大会リストの読み込み
    const fetchTournaments = async () => {
      loading.value = true;
      try {
        const response = await axios.get('http://localhost:1880/tournaments');
        if (Array.isArray(response.data)) {
          tournaments.value = response.data;
        } else {
          console.error('Unexpected response format for tournaments:', response.data);
          showSnackbar('大会リストの取得に失敗しました。予期せぬデータ形式です。', 'error');
          tournaments.value = [];
        }
      } catch (error) {
        console.error('Failed to fetch tournaments:', error);
        showSnackbar('大会リストの取得中にエラーが発生しました。', 'error');
        tournaments.value = [];
      } finally {
        loading.value = false;
      }
    };

    // 選択された大会の全試合データを読み込む
    const loadMatchesForTournament = async (tournamentId) => {
      if (!tournamentId) {
        allMatches.value = [];
        return;
      }

      loading.value = true;
      try {
        const response = await axios.get(`http://localhost:1880/api/tournament-matches/${tournamentId}`);
        if (response.data.success) {
          allMatches.value = response.data.matches;
          showSnackbar('試合データを読み込みました。', 'success');
        } else {
          allMatches.value = [];
          showSnackbar(response.data.message || '試合データの読み込みに失敗しました。', 'error');
        }
      } catch (error) {
          console.error('Failed to load tournament matches:', error);
          allMatches.value = [];
          showSnackbar('試合データの読み込み中にエラーが発生しました。サーバーとの接続を確認してください。', 'error');
      } finally {
        loading.value = false;
      }
    };

    // Aコートの試合をフィルタリング
    const courtAMatches = computed(() => {
      // 'A'コートに割り当てられた試合、かつ match_order_no でソート
      return allMatches.value
        .filter(match => match.court_id === 'A')
        .sort((a, b) => {
          const orderA = a.match_order_no === null || a.match_order_no === undefined ? Infinity : a.match_order_no;
          const orderB = b.match_order_no === null || b.match_order_no === undefined ? Infinity : b.match_order_no;
          return orderA - orderB;
        });
    });

    // Bコートの試合をフィルタリング
    const courtBMatches = computed(() => {
      // 'B'コートに割り当てられた試合、かつ match_order_no でソート
      return allMatches.value
        .filter(match => match.court_id === 'B')
        .sort((a, b) => {
          const orderA = a.match_order_no === null || a.match_order_no === undefined ? Infinity : a.match_order_no;
          const orderB = b.match_order_no === null || b.match_order_no === undefined ? Infinity : b.match_order_no;
          return orderA - orderB;
        });
    });

    // 試合順の欠落をチェック
    const isOrderMissing = (match) => {
      return match.match_order_no === null || match.match_order_no === undefined;
    };

    // 試合順の重複をチェック
    const isOrderDuplicate = (match) => {
      if (match.match_order_no === null || match.match_order_no === undefined) return false;

      // 同じコート内で同じ試合順が存在するかをチェック
      const matchesInSameCourt = allMatches.value.filter(
        (m) => m.court_id === match.court_id && m.matchId !== match.matchId
      );
      return matchesInSameCourt.some((m) => m.match_order_no === match.match_order_no);
    };

    onMounted(() => {
      fetchTournaments();
    });

    // selectedTournamentId が変更されたら試合データを再読み込み
    watch(selectedTournamentId, (newVal) => {
      loadMatchesForTournament(newVal);
    });

    return {
      tournaments,
      selectedTournamentId,
      allMatches,
      loading,
      headers,
      getPlayerDisplayName,
      loadMatchesForTournament,
      activeTab,
      courtAMatches,
      courtBMatches,
      isOrderMissing,
      isOrderDuplicate,
    };
  },
};
</script>

<style scoped>
.error-text {
  color: red;
  font-weight: bold;
}

.v-tab .v-icon {
  font-family: "Material Design Icons" !important;
  /* 必要に応じて、font-sizeやline-heightなどもここで明示的に指定すると、より安定します */
  /* font-size: 24px !important; */
  /* line-height: 1 !important; */
}
/* タブの視認性を高めるカスタムスタイル */
.tab-item {
  border-right: 1px solid rgba(255, 255, 255, 0.2); /* タブ間の境界線 */
}
.tab-item:last-child {
  border-right: none; /* 最後のタブには境界線なし */
}

/* アクティブなタブのスタイルをVuetifyに任せるか、必要に応じて上書き */
/* Vuetifyのデフォルトでアクティブタブは下線や色が変化するため、ここでは追加のスタイルは控えめに */
/* 必要であれば、v-tabの:active擬似クラスや.v-tab--selectedクラスに対してスタイルを定義 */

/* v-windowの背景と角丸を調整 */
.v-window {
  background-color: #f5f5f5; /* タブコンテンツの背景色 */
}
</style>

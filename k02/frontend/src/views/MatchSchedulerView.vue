<template>
  <v-card class="mx-auto" outlined>
    <v-card-title class="headline">
      試合スケジューリング
    </v-card-title>
    <v-card-text>
      <v-row class="mb-4">
        <v-col cols="12" md="6">
          <v-select
            v-model="selectedTournamentId"
            :items="tournaments"
            item-title="tournament_nm"
            item-value="tournament_id"
            label="大会を選択"
            outlined
            dense
            hide-details
            clearable
            @update:model-value="onTournamentSelected"
          ></v-select>
        </v-col>
      </v-row>

      <v-divider class="my-4"></v-divider>

      <div v-if="selectedTournamentId"> 
        <v-row>
          <v-col cols="12">
            <v-btn color="primary" class="mr-2" @click="fetchAllMatches" :disabled="loadingMatches">
              <v-icon left>mdi-refresh</v-icon>
              全試合を読み込む
            </v-btn>
            <v-btn color="success" @click="saveScheduledMatches" :disabled="loadingSave || totalMatchesCount === 0">
              <v-icon left>mdi-content-save</v-icon>
              スケジュールを保存
            </v-btn>
          </v-col>
        </v-row>

        <v-divider class="my-4"></v-divider>

        <v-row>
          <v-col cols="12" md="4">
            <v-text-field
              v-model.number="numCourts"
              label="コート数"
              type="number"
              min="1"
              max="5"
              outlined
              dense
              hide-details
              class="mb-4"
              @update:model-value="initializeCourtLists"
            ></v-text-field>
          </v-col>
          <v-col cols="12" md="8">
            <p class="text-subtitle-1">
              現在の試合数: {{ totalMatchesCount }}試合
              <span v-if="numCourts > 0"> ({{ numCourts }}コートで割り振り)</span>
            </p>
          </v-col>
        </v-row>

        <v-divider class="my-4"></v-divider>

        <h3 class="text-h6 mb-2">試合順序の調整 (ドラッグ&ドロップでコート移動・入れ替え可)</h3>
        <p class="text-caption">
          ※ 選手が連続して試合を行わないよう、手動で調整してください。
          決勝戦など特定の試合を最後に実施したい場合も、このリストで順序を調整してください。
        </p>

        <div v-if="loadingMatches" class="text-center py-4">
          <v-progress-circular indeterminate color="primary"></v-progress-circular>
          <p class="mt-2">試合データを読み込み中...</p>
        </div>
        <div v-else-if="totalMatchesCount === 0">
          <p class="text-center py-4">この大会にはまだ試合がありません。各組み合わせ画面で試合を生成してください。</p>
        </div>
        <div v-else>
          <v-row>
            <v-col v-for="courtName in courtNames" :key="courtName" cols="12" :md="12 / numCourts">
              <v-card class="elevation-2 pa-2" :title="courtName">
                <v-card-text>
                  <draggable
                    v-model="scheduledMatchesByCourt[courtName]"
                    item-key="matchId"
                    tag="v-list"
                    group="matches"
                    class="pa-0"
                    style="min-height: 200px; border: 1px dashed #ccc; border-radius: 4px;"
                    @end="onDragEnd"
                  >
                    <template #item="{ element: match, index }">
                      <div>
                        <v-list-item class="my-1" :class="{ 'highlight-final': match.isFinal, 'warning-consecutive': isConsecutiveMatch(match, index, courtName) }">
                          <template #prepend>
                            <v-icon class="handle mr-2" color="grey lighten-1">mdi-drag-vertical</v-icon>
                          </template>
                          <v-list-item-content>
                            <v-list-item-title class="font-weight-bold">
                              <span v-if="match.court && match.matchNumber">
                                第{{ match.matchNumber }}試合:
                              </span>
                              {{ getPlayerFullName(match.player1) }} vs {{ getPlayerFullName(match.player2) }}
                              <span v-if="isUndeterminedMatch(match)" class="text-caption text--secondary ml-2">
                                ({{ getUndeterminedMatchInfo(match) }})
                              </span>
                            </v-list-item-title>
                            <v-list-item-subtitle>
                              カテゴリー: {{ match.categoryName || '不明' }} ({{ getMatchTypeLabel(match.matchType) }})
                              <span v-if="match.score"> - スコア: {{ match.score }}</span>
                              <span v-if="isConsecutiveMatch(match, index, courtName)" class="ml-2 red--text text--darken-2">
                                <v-icon small color="red darken-2">mdi-alert-circle</v-icon>
                                連続試合の可能性
                              </span>
                            </v-list-item-subtitle>
                          </v-list-item-content>
                        </v-list-item>
                        <v-divider v-if="index < scheduledMatchesByCourt[courtName].length - 1"></v-divider>
                      </div>
                    </template>
                  </draggable>
                </v-card-text>
              </v-card>
            </v-col>
          </v-row>
        </div>
      </div>
      <div v-else>
        <p class="text-center py-4">大会を選択してください。</p>
      </div>
    </v-card-text>
  </v-card>
</template>

<script>
import { ref, watch, computed, onMounted } from 'vue'; // onMounted を追加
import axios from 'axios';
import draggable from 'vuedraggable';

export default {
  name: 'MatchSchedulerView',
  components: {
    draggable,
  },
  props: {
    // ★ここを修正: props.tournamentId は不要になるので削除またはコメントアウト★
    // tournamentId: {
    //   type: [String, Number],
    //   required: false, // ルートパラメータから直接渡される場合は不要
    //   default: null,
    // },
    categoryId: {
      type: [String, Number],
      default: null,
    },
  },
  emits: ['show-snackbar'],
  setup(props, { emit }) {
    const allMatches = ref([]);
    const numCourts = ref(2);
    const loadingMatches = ref(false);
    const loadingSave = ref(false);
    const scheduledMatchesByCourt = ref({});
    const courtNames = ref([]);

    // ★ここから追加★
    const tournaments = ref([]); // 大会リストを保持
    const selectedTournamentId = ref(null); // 選択された大会IDを保持
    // ★ここまで追加★

    const totalMatchesCount = computed(() => {
      let count = 0;
      for (const courtName in scheduledMatchesByCourt.value) {
        count += scheduledMatchesByCourt.value[courtName].length;
      }
      return count;
    });

    const getPlayerFullName = (player) => {
      if (!player) return '未定';
      const fullName = `${player.familyname || ''} ${player.firstname || ''}`;
      return fullName.trim() || '未定';
    };

    const getMatchTypeLabel = (type) => {
      switch (type) {
        case 'tournament': return 'トーナメント';
        case 'league': return 'リーグ';
        case 'pentagon': return '五角形';
        default: return '不明';
      }
    };

    const showSnackbar = (text, color) => {
      emit('show-snackbar', text, color);
    };

    const initializeCourtLists = () => {
      const oldMatches = [];
      for (const courtName in scheduledMatchesByCourt.value) {
        oldMatches.push(...scheduledMatchesByCourt.value[courtName]);
      }
      
      const newScheduledMatchesByCourt = {};
      const newCourtNames = [];
      for (let i = 0; i < numCourts.value; i++) {
        const courtName = String.fromCharCode(65 + i) + 'コート';
        newCourtNames.push(courtName);
        newScheduledMatchesByCourt[courtName] = [];
      }

      if (oldMatches.length > 0) {
        oldMatches.forEach((match, index) => {
          const targetCourtName = newCourtNames[index % numCourts.value];
          if (newScheduledMatchesByCourt[targetCourtName]) {
            newScheduledMatchesByCourt[targetCourtName].push(match);
          } else {
            newScheduledMatchesByCourt[newCourtNames[0]].push(match);
          }
        });
      }

      scheduledMatchesByCourt.value = newScheduledMatchesByCourt;
      courtNames.value = newCourtNames;
      assignMatchNumbersAndCourts();
    };

    const assignMatchNumbersAndCourts = () => {
      if (numCourts.value <= 0) return;

      courtNames.value.forEach(courtName => {
        let matchNumber = 1;
        scheduledMatchesByCourt.value[courtName].forEach(match => {
          match.court = courtName;
          match.matchNumber = matchNumber++;
        });
      });
    };

    const fetchAllMatches = async () => {
      // ★ここを修正: props.tournamentId ではなく selectedTournamentId を使用★
      if (!selectedTournamentId.value) { 
        allMatches.value = [];
        initializeCourtLists();
        return;
      }

      loadingMatches.value = true;
      try {
        const response = await axios.get(`http://localhost:1880/tournament-all-matches/${selectedTournamentId.value}`); // selectedTournamentId を使用
        if (response.data.success) {
          allMatches.value = []; 
          for (const courtName in scheduledMatchesByCourt.value) {
            scheduledMatchesByCourt.value[courtName] = [];
          }
          
          allMatches.value = response.data.matches.map(match => ({
            ...match,
            court: null,
            matchNumber: null,
            isFinal: false,
          }));
          showSnackbar('全試合データを読み込みました。', 'success');

          initializeCourtLists();
          if (courtNames.value.length > 0) {
            scheduledMatchesByCourt.value[courtNames.value[0]].push(...allMatches.value);
          }
          assignMatchNumbersAndCourts();
        } else {
          showSnackbar(response.data.message || '試合データの読み込みに失敗しました。', 'error');
          allMatches.value = [];
          initializeCourtLists();
        }
      } catch (error) {
        console.error('Failed to fetch all matches:', error);
        showSnackbar('試合データの取得中にエラーが発生しました。', 'error');
        allMatches.value = [];
        initializeCourtLists();
      } finally {
        loadingMatches.value = false;
      }
    };

    const onDragEnd = () => {
      assignMatchNumbersAndCourts();
    };

    const isConsecutiveMatch = (currentMatch, currentIndex, currentCourtName) => {
      if (currentIndex === 0) return false;

      const prevMatch = scheduledMatchesByCourt.value[currentCourtName][currentIndex - 1];
      if (!prevMatch) return false;

      const currentPlayer1Id = currentMatch.player1?.player_id;
      const currentPlayer2Id = currentMatch.player2?.player_id;
      const prevPlayer1Id = prevMatch.player1?.player_id;
      const prevPlayer2Id = prevMatch.player2?.player_id;

      const isPlayer1Consecutive = currentPlayer1Id && (currentPlayer1Id === prevPlayer1Id || currentPlayer1Id === prevPlayer2Id);
      const isPlayer2Consecutive = currentPlayer2Id && (currentPlayer2Id === prevPlayer1Id || currentPlayer2Id === prevPlayer2Id);
      
      return isPlayer1Consecutive || isPlayer2Consecutive;
    };

    const isUndeterminedMatch = (match) => {
      const player1IsPlaceholder = match.player1 && match.player1.isWinnerPlaceholder;
      const player2IsPlaceholder = match.player2 && match.player2.isWinnerPlaceholder;
      return player1IsPlaceholder || player2IsPlaceholder;
    };

    const getUndeterminedMatchInfo = (match) => {
      let info = [];
      if (match.player1 && match.player1.winnerOf) {
        info.push(`${match.player1.winnerOf}勝者`);
      }
      if (match.player2 && match.player2.winnerOf) {
        info.push(`${match.player2.winnerOf}勝者`);
      }
      return info.join(' vs ');
    };

    const saveScheduledMatches = async () => {
      const matchesToSave = [];
      for (const courtName in scheduledMatchesByCourt.value) {
        matchesToSave.push(...scheduledMatchesByCourt.value[courtName]);
      }

      if (matchesToSave.length === 0) {
        showSnackbar('保存するスケジュールがありません。', 'warning');
        return;
      }
      loadingSave.value = true;
      try {
        // ★ここを修正: tournamentId を渡す場合は selectedTournamentId を使用★
        // 例: await axios.post(`http://localhost:1880/save-scheduled-matches/${selectedTournamentId.value}`, { matches: matchesToSave });
        showSnackbar('スケジュールを保存しました！（ただし、バックエンドAPIは未実装です）', 'info');
      } catch (error) {
        console.error('Failed to save scheduled matches:', error);
        showSnackbar('スケジュールの保存中にエラーが発生しました。', 'error');
      } finally {
        loadingSave.value = false;
      }
    };

    // ★ここから追加: 大会リストの取得と選択時の処理★
    const fetchTournaments = async () => {
      try {
        // CombinationCreatorView と同じようにパラメータを追加
        const params = new URLSearchParams();
        params.append('sort', 'start_date');
        params.append('order', 'desc');

        const response = await axios.get(`http://localhost:1880/tournaments?${params.toString()}`);
        
        tournaments.value = response.data; 
        
      } catch (error) {
        console.error('Failed to fetch tournaments:', error);
        showSnackbar('大会リストの取得に失敗しました。', 'error');
      }
    };

    const onTournamentSelected = () => {
      // 大会が選択解除された場合、試合データをクリア
      if (!selectedTournamentId.value) {
        allMatches.value = [];
        scheduledMatchesByCourt.value = {};
        initializeCourtLists(); // コートリストを初期化
      } else {
        fetchAllMatches(); // 大会が選択されたら試合データを読み込む
      }
    };
    // ★ここまで追加★

  
    watch(numCourts, () => {
      initializeCourtLists();
    });

    initializeCourtLists(); // 初期化時に一度コートリストを生成

    // コンポーネントマウント時に大会リストを取得
    onMounted(() => {
      fetchTournaments();
    });


    return {
      allMatches,
      numCourts,
      loadingMatches,
      loadingSave,
      scheduledMatchesByCourt,
      courtNames,
      totalMatchesCount,
      getPlayerFullName,
      getMatchTypeLabel,
      fetchAllMatches,
      assignMatchNumbersAndCourts,
      isConsecutiveMatch,
      saveScheduledMatches,
      onDragEnd,
      isUndeterminedMatch,
      getUndeterminedMatchInfo,
      // ★ここから追加★
      tournaments,
      selectedTournamentId,
      onTournamentSelected,
      // ★ここまで追加★
    };
  },
};
</script>

<style scoped>
.v-list-item {
  background-color: #ffffff;
  margin-bottom: 8px;
  border-radius: 4px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.1);
  cursor: grab;
  transition: box-shadow 0.2s ease-in-out;
}
.v-list-item:hover {
    box-shadow: 0 2px 6px rgba(0,0,0,0.15);
}
.v-list-item.sortable-chosen {
    background-color: #e0f2f7;
    box-shadow: 0 4px 8px rgba(0,0,0,0.2);
}
.v-list-item.sortable-ghost {
    opacity: 0.5;
    background-color: #f0f8ff;
}
.handle {
    cursor: grab;
}
.highlight-final {
  border-left: 5px solid orange;
}
.warning-consecutive {
  background-color: #ffe0b2;
}

/* 新しいスタイル */
.v-card .v-card-text .v-list {
  background-color: #f5f5f5; /* コート背景色 */
}
</style>
<template>
  <v-card class="mx-auto" outlined>
    <v-card-title class="headline">
      試合スケジューリング
    </v-card-title>
    <v-card-text>
      <div v-if="tournamentId">
        <v-row>
          <v-col cols="12">
            <v-btn color="primary" class="mr-2" @click="fetchAllMatches" :disabled="loadingMatches">
              <v-icon left>mdi-refresh</v-icon>
              全試合を読み込む
            </v-btn>
            <v-btn color="success" @click="saveScheduledMatches" :disabled="loadingSave || allMatches.length === 0">
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
              @update:model-value="assignMatchNumbersAndCourts"
            ></v-text-field>
          </v-col>
          <v-col cols="12" md="8">
            <p class="text-subtitle-1">
              現在の試合数: {{ allMatches.length }}試合
              <span v-if="numCourts > 0"> ({{ numCourts }}コートで割り振り)</span>
            </p>
          </v-col>
        </v-row>

        <v-divider class="my-4"></v-divider>

        <h3 class="text-h6 mb-2">試合順序の調整 (ドラッグ&ドロップで入れ替え可)</h3>
        <p class="text-caption">
          ※ 選手が連続して試合を行わないよう、手動で調整してください。
          決勝戦など特定の試合を最後に実施したい場合も、このリストで順序を調整してください。
        </p>

        <div v-if="loadingMatches" class="text-center py-4">
          <v-progress-circular indeterminate color="primary"></v-progress-circular>
          <p class="mt-2">試合データを読み込み中...</p>
        </div>
        <div v-else-if="allMatches.length === 0">
          <p class="text-center py-4">この大会にはまだ試合がありません。各組み合わせ画面で試合を生成してください。</p>
        </div>
        <div v-else>
          <draggable
            v-model="allMatches"
            item-key="matchId"
            tag="v-list"
            handle=".handle"
            class="elevation-1 pa-2"
            style="min-height: 300px;"
            @end="assignMatchNumbersAndCourts"
          >
            <template #item="{ element: match, index }">
              <div>
                <v-list-item class="mb-2" :class="{ 'highlight-final': match.isFinal, 'warning-consecutive': isConsecutiveMatch(match, index) }">
                  <template #prepend>
                    <v-icon class="handle mr-2" color="grey lighten-1">mdi-drag-vertical</v-icon>
                  </template>
                  <v-list-item-content>
                    <v-list-item-title class="font-weight-bold">
                      <span v-if="match.court && match.matchNumber">
                        {{ match.court }}コート 第{{ match.matchNumber }}試合:
                      </span>
                      {{ getPlayerFullName(match.player1) }} vs {{ getPlayerFullName(match.player2) }}
                    </v-list-item-title>
                    <v-list-item-subtitle>
                      カテゴリー: {{ match.categoryName || '不明' }} ({{ getMatchTypeLabel(match.matchType) }})
                      <span v-if="match.score"> - スコア: {{ match.score }}</span>
                      <span v-if="isConsecutiveMatch(match, index)" class="ml-2 red--text text--darken-2">
                        <v-icon small color="red darken-2">mdi-alert-circle</v-icon>
                        連続試合の可能性
                      </span>
                    </v-list-item-subtitle>
                  </v-list-item-content>
                </v-list-item>
                <v-divider v-if="index < allMatches.length - 1"></v-divider>
              </div>
            </template>
          </draggable>
        </div>
      </div>
      <div v-else>
        <p>大会を選択してください。</p>
      </div>
    </v-card-text>
  </v-card>
</template>

<script>
import { ref, watch } from 'vue'; // ★ここを修正: computed を削除
import axios from 'axios';
import draggable from 'vuedraggable';

export default {
  name: 'MatchSchedulerView',
  components: {
    draggable,
  },
  props: {
    tournamentId: {
      type: [String, Number],
      required: true,
    },
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

    const fetchAllMatches = async () => {

      if (!props.tournamentId) {
        allMatches.value = [];
        return;
      }

      loadingMatches.value = true;
      try {
        const response = await axios.get(`http://localhost:1880/tournament-all-matches/${props.tournamentId}`);
        console.log('API Response received:', response.data);
        if (response.data.success) {
          allMatches.value = response.data.matches.map(match => ({
            ...match,
            court: null,
            matchNumber: null,
            isFinal: false,
          }));
          showSnackbar('全試合データを読み込みました。', 'success');
          assignMatchNumbersAndCourts();
        } else {
          showSnackbar(response.data.message || '試合データの読み込みに失敗しました。', 'error');
          allMatches.value = [];
        }
      } catch (error) {
        console.error('Failed to fetch all matches:', error);
        showSnackbar('試合データの取得中にエラーが発生しました。', 'error');
        allMatches.value = [];
      } finally {
        loadingMatches.value = false;
      }
    };

    const assignMatchNumbersAndCourts = () => {
      if (allMatches.value.length === 0 || numCourts.value <= 0) {
        allMatches.value.forEach(match => {
          match.court = null;
          match.matchNumber = null;
        });
        return;
      }

      const courts = Array.from({ length: numCourts.value }, (_, i) => String.fromCharCode(65 + i) + 'コート');
      let matchCounter = Array(numCourts.value).fill(1);

      allMatches.value.forEach((match, index) => {
        const courtIndex = index % numCourts.value;
        match.court = courts[courtIndex];
        match.matchNumber = matchCounter[courtIndex]++;
      });
    };

    const isConsecutiveMatch = (currentMatch, currentIndex) => {
      if (currentIndex === 0) return false;

      const prevMatch = allMatches.value[currentIndex - 1];
      if (!prevMatch) return false;

      const currentPlayer1Id = currentMatch.player1?.player_id;
      const currentPlayer2Id = currentMatch.player2?.player_id;
      const prevPlayer1Id = prevMatch.player1?.player_id;
      const prevPlayer2Id = prevMatch.player2?.player_id;

      const isPlayer1Consecutive = currentPlayer1Id && (currentPlayer1Id === prevPlayer1Id || currentPlayer1Id === prevPlayer2Id);
      const isPlayer2Consecutive = currentPlayer2Id && (currentPlayer2Id === prevPlayer1Id || currentPlayer2Id === prevPlayer2Id);
      
      return isPlayer1Consecutive || isPlayer2Consecutive;
    };

    const saveScheduledMatches = async () => {
      if (allMatches.value.length === 0) {
        showSnackbar('保存するスケジュールがありません。', 'warning');
        return;
      }
      loadingSave.value = true;
      try {
        console.log("Saving scheduled matches:", JSON.parse(JSON.stringify(allMatches.value)));
        showSnackbar('スケジュールを保存しました！（ただし、バックエンドAPIは未実装です）', 'info');
      } catch (error) {
        console.error('Failed to save scheduled matches:', error);
        showSnackbar('スケジュールの保存中にエラーが発生しました。', 'error');
      } finally {
        loadingSave.value = false;
      }
    };

    watch(() => props.tournamentId, (newTournamentId) => {
      if (newTournamentId) {
        fetchAllMatches();
      } else {
        allMatches.value = [];
      }
    }, { immediate: true });

    watch(numCourts, () => {
      assignMatchNumbersAndCourts();
    });

    return {
      allMatches,
      numCourts,
      loadingMatches,
      loadingSave,
      getPlayerFullName,
      getMatchTypeLabel,
      fetchAllMatches,
      assignMatchNumbersAndCourts,
      isConsecutiveMatch,
      saveScheduledMatches,
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
</style>
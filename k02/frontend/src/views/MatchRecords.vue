<template>
  <v-container>
    <h1 class="text-h4 mb-4">試合記録</h1>

    <v-card class="pa-4 mb-4">
      <v-card-text>
        <v-row align="center">
          <!-- 大会選択 -->
          <v-col cols="12" md="4">
            <v-select
              v-model="selectedTournamentId"
              :items="tournaments"
              item-title="tournament_nm"
              item-value="tournament_id"
              label="大会を選択"
              variant="outlined"
              density="compact"
              @update:model-value="onTournamentSelected"
            ></v-select>
          </v-col>

          <!-- コート選択 -->
          <v-col cols="12" md="4">
            <v-select
              v-model="selectedCourtId"
              :items="courts"
              item-title="id"
              item-value="id"
              label="コート"
              variant="outlined"
              density="compact"
              :disabled="!selectedTournamentId"
              @update:model-value="onCourtSelected"
            ></v-select>
          </v-col>

          <!-- 試合順選択 -->
          <v-col cols="12" md="4">
            <v-select
              v-model="selectedMatchOrderNo"
              :items="matchOrders"
              label="試合番号"
              variant="outlined"
              density="compact"
              :disabled="!selectedCourtId"
              @update:model-value="onMatchOrderSelected"
            ></v-select>
          </v-col>
        </v-row>
      </v-card-text>
    </v-card>

    <v-divider class="my-4"></v-divider>

    <!-- 試合情報と記録フォーム -->
    <v-card v-if="selectedMatch" class="pa-4 bg-grey-lighten-5">
      <v-card-title class="text-h5">記録</v-card-title>
      <v-card-text>
        <!-- コート、試合順、カテゴリーの表示 -->
        <v-row class="mb-4">
          <v-col cols="4" class="text-center">
            <span class="text-h6 font-weight-bold">コート: {{ selectedMatch.court_id }}</span>
          </v-col>
          <v-col cols="4" class="text-center">
            <span class="text-h6 font-weight-bold">試合番号: {{ selectedMatch.match_order_no }}</span>
          </v-col>
          <v-col cols="4" class="text-center">
            <span class="text-h6 font-weight-bold">カテゴリー: {{ selectedMatch.category_nm }}</span>
          </v-col>
        </v-row>

        <v-row>
          <!-- Player 1 Card -->
          <v-col cols="6">
            <v-card variant="outlined" class="pa-2 text-center bg-blue-lighten-5 text-blue-darken-3" border="md">
              <v-card-title class="text-blue-darken-3">
                <template v-if="isPlayerObject(selectedMatch.player1)">
                  {{ selectedMatch.player1.familyname }} {{ selectedMatch.player1.firstname }} ({{ selectedMatch.player1.familyname2 }} {{ selectedMatch.player1.firstname2 }})
                </template>
                <template v-else>
                  勝者 ({{ selectedMatch.player1 }})
                </template>
              </v-card-title>
              <template v-if="isPlayerObject(selectedMatch.player1)">
                <v-card-subtitle class="text-blue-darken-3">{{ selectedMatch.player1.branch_nm }}</v-card-subtitle>
                <p class="text-caption text-blue-darken-3">級: {{ selectedMatch.player1.xclass }}</p>
                <p class="text-caption text-blue-darken-3">
                  体力指数: {{ calculatePhysicalIndex(selectedMatch.player1.height, selectedMatch.player1.weight) }}
                  (身長: {{ (selectedMatch.player1.height / 10).toFixed(1) }}cm, 体重: {{ (selectedMatch.player1.weight / 10).toFixed(1) }}kg)
                </p>
              </template>
            </v-card>
          </v-col>

          <!-- Player 2 Card -->
          <v-col cols="6">
            <v-card variant="outlined" class="pa-2 text-center bg-white" border="md">
              <v-card-title>
                <template v-if="isPlayerObject(selectedMatch.player2)">
                  {{ selectedMatch.player2.familyname }} {{ selectedMatch.player2.firstname }} ({{ selectedMatch.player2.familyname2 }} {{ selectedMatch.player2.firstname2 }})
                </template>
                <template v-else>
                  勝者 ({{ selectedMatch.player2 }})
                </template>
              </v-card-title>
              <template v-if="isPlayerObject(selectedMatch.player2)">
                <v-card-subtitle>{{ selectedMatch.player2.branch_nm }}</v-card-subtitle>
                <p class="text-caption">級: {{ selectedMatch.player2.xclass }}</p>
                <p class="text-caption">
                  体力指数: {{ calculatePhysicalIndex(selectedMatch.player2.height, selectedMatch.player2.weight) }}
                  (身長: {{ (selectedMatch.player2.height / 10).toFixed(1) }}cm, 体重: {{ (selectedMatch.player2.weight / 10).toFixed(1) }}kg)
                </p>
              </template>
            </v-card>
          </v-col>
        </v-row>
      </v-card-text>

      <v-divider class="my-4"></v-divider>

      <v-form @submit.prevent="saveMatchRecord">
        <v-row>
          <v-col cols="12">
            <v-select
              v-model="recordForm.winner_player_id"
              :items="winnerOptions"
              item-title="text"
              item-value="value"
              label="勝者"
              required
            ></v-select>
          </v-col>
          <v-col cols="12">
            <v-select
              v-model="recordForm.winning_reason"
              :items="winningReasons"
              label="勝因"
              required
            ></v-select>
          </v-col>
          <v-col cols="12">
            <v-textarea
              v-model="recordForm.notes"
              label="備考"
              rows="3"
            ></v-textarea>
          </v-col>
        </v-row>
        <v-btn color="success" type="submit" block class="mt-4">試合記録を保存</v-btn>
      </v-form>
    </v-card>
  </v-container>
</template>

<script>
import { ref, onMounted, computed } from 'vue';

export default {
  name: 'MatchRecordsView',
  setup(props, context) {
    const selectedTournamentId = ref(null);
    const selectedCourtId = ref(null);
    const selectedMatchOrderNo = ref(null);

    const tournaments = ref([]);
    const allMatches = ref([]);
    const courts = ref([]);
    const matchOrders = ref([]);

    const selectedMatch = ref(null);
    const recordForm = ref({
      winner_player_id: null,
      winning_reason: null,
      notes: null,
    });
    const winningReasons = ref([
      '一本勝ち', '技あり', '判定勝ち', '不戦勝', 'その他'
    ]);

    const isPlayerObject = (player) => {
      return typeof player === 'object' && player !== null && !Array.isArray(player) && player.player_id !== undefined;
    };

    const winnerOptions = computed(() => {
      if (!selectedMatch.value) return [];
      
      const options = [];
      
      if (isPlayerObject(selectedMatch.value.player1)) {
        options.push({
          text: `${selectedMatch.value.player1.familyname} ${selectedMatch.value.player1.firstname}`,
          value: selectedMatch.value.player1.player_id
        });
      } else {
        options.push({
          text: `選手1 (${selectedMatch.value.player1})`,
          value: selectedMatch.value.player1
        });
      }

      if (isPlayerObject(selectedMatch.value.player2)) {
        options.push({
          text: `${selectedMatch.value.player2.familyname} ${selectedMatch.value.player2.firstname}`,
          value: selectedMatch.value.player2.player_id
        });
      } else {
        options.push({
          text: `選手2 (${selectedMatch.value.player2})`,
          value: selectedMatch.value.player2
        });
      }
      return options;
    });

    const calculatePhysicalIndex = (height, weight) => {
      const heightCm = height / 10;
      const weightKg = weight / 10;
      return (heightCm + weightKg).toFixed(1);
    };

    const fetchTournaments = async () => {
      try {
        const response = await fetch('http://localhost:1880/tournaments');
        if (!response.ok) {
          throw new Error(`HTTPエラー！ステータス: ${response.status}`);
        }
        const data = await response.json();
        if (Array.isArray(data)) {
          tournaments.value = data;
        } else {
          context.emit('show-snackbar', '大会リストの取得に失敗しました。予期せぬデータ形式です。', 'error');
          tournaments.value = [];
        }
      } catch (error) {
        context.emit('show-snackbar', `大会一覧の取得に失敗しました: ${error.message}`, 'error');
      }
    };

    const onTournamentSelected = async (newTournamentId) => {
      if (!newTournamentId) {
        allMatches.value = [];
        courts.value = [];
        matchOrders.value = [];
        selectedCourtId.value = null;
        selectedMatchOrderNo.value = null;
        selectedMatch.value = null;
        return;
      }
      
      try {
        const response = await fetch(`http://localhost:1880/api/tournament-matches/${newTournamentId}`);
        if (!response.ok) {
          throw new Error(`HTTPエラー！ステータス: ${response.status}`);
        }
        const data = await response.json();
        allMatches.value = data.matches;

        const uniqueCourts = [...new Set(allMatches.value.map(item => item.court_id))];
        courts.value = uniqueCourts.map(id => ({ id: id, name: id }));

        selectedCourtId.value = null;
        selectedMatchOrderNo.value = null;
        selectedMatch.value = null;
      } catch (error) {
        context.emit('show-snackbar', `試合スケジュール詳細の取得に失敗しました: ${error.message}`, 'error');
      }
    };
    
    const onCourtSelected = (newCourtId) => {
      if (newCourtId) {
        const filteredMatches = allMatches.value.filter(item => String(item.court_id) === String(newCourtId));
        matchOrders.value = filteredMatches.map(item => item.match_order_no).sort((a, b) => a - b);
        selectedMatchOrderNo.value = null;
        selectedMatch.value = null;
      } else {
        matchOrders.value = [];
        selectedMatchOrderNo.value = null;
        selectedMatch.value = null;
      }
    };

    const onMatchOrderSelected = (newMatchOrderNo) => {
      if (newMatchOrderNo !== null) {
        selectedMatch.value = allMatches.value.find(match => {
          // 大会IDの比較を削除し、コートIDと試合順のみで検索
          const condition2 = String(match.court_id) === String(selectedCourtId.value);
          const condition3 = String(match.match_order_no) === String(newMatchOrderNo);
          return condition2 && condition3;
        });
      } else {
        selectedMatch.value = null;
      }
    };

    const saveMatchRecord = async () => {
      try {
        if (!selectedMatch.value) {
            context.emit('show-snackbar', '試合が選択されていません。', 'error');
            return;
        }

        const recordData = {
          record_id: crypto.randomUUID(),
          tournament_id: selectedTournamentId.value,
          category_id: selectedMatch.value.category_id,
          match_id_in_bracket: selectedMatch.value.matchId,
          match_type: selectedMatch.value.combination_type === 'トーナメント戦' ? 'tournament' :
                      selectedMatch.value.combination_type === 'リーグ戦' ? 'league' :
                      selectedMatch.value.combination_type === '五角形戦' ? 'pentagon' : '',
          
          player1_branch_id: isPlayerObject(selectedMatch.value.player1) ? selectedMatch.value.player1.branch_id : null,
          player1_id: isPlayerObject(selectedMatch.value.player1) ? selectedMatch.value.player1.player_id : selectedMatch.value.player1,
          player2_branch_id: isPlayerObject(selectedMatch.value.player2) ? selectedMatch.value.player2.branch_id : null,
          player2_id: isPlayerObject(selectedMatch.value.player2) ? selectedMatch.value.player2.player_id : selectedMatch.value.player2,
          
          court_id: selectedCourtId.value,
          match_order_no: selectedMatchOrderNo.value,
          ...recordForm.value,
        };

        if (selectedMatch.value.record && selectedMatch.value.record.record_id) {
            recordData.record_id = selectedMatch.value.record.record_id;
        }

        const response = await fetch('http://localhost:1880/save-match-record', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(recordData),
        });

        if (!response.ok) {
          throw new Error('試合記録の保存に失敗しました');
        }

        context.emit('show-snackbar', '試合記録を保存しました', 'success');
      } catch (error) {
        context.emit('show-snackbar', `エラー: ${error.message}`, 'error');
      }
    };

    onMounted(() => {
      fetchTournaments();
    });

    return {
      selectedTournamentId,
      selectedCourtId,
      selectedMatchOrderNo,
      tournaments,
      courts,
      matchOrders,
      selectedMatch,
      recordForm,
      winningReasons,
      isPlayerObject,
      winnerOptions,
      calculatePhysicalIndex,
      onTournamentSelected,
      onCourtSelected,
      onMatchOrderSelected,
      saveMatchRecord,
    };
  },
};
</script>

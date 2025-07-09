<template>
  <v-card class="mx-auto" outlined>
    <v-card-title class="headline">
      試合組み合わせ作成 (ワンマッチ)
    </v-card-title>
    <v-card-text>
      <v-row>
        <v-col cols="12" sm="6" md="4">
          <v-select
            v-model="selectedTournamentId"
            :items="tournamentsList"
            item-title="tournament_nm"
            item-value="tournament_id"
            label="大会を選択"
            clearable
            @update:modelValue="handleTournamentChange"
          ></v-select>
        </v-col>
        <v-col cols="12" sm="6" md="4">
          <v-select
            v-model="selectedCategoryId"
            :items="categoriesList"
            item-title="category_nm"
            item-value="category_id"
            label="カテゴリーを選択"
            clearable
            :disabled="!selectedTournamentId || categoriesList.length === 0"
            @update:modelValue="handleCategoryChange"
          ></v-select>
        </v-col>
      </v-row>

      <div v-if="selectedTournamentId && selectedCategoryId">
        <v-divider class="my-4"></v-divider>
        <h3 class="text-h6 mb-4">新規ワンマッチ作成</h3>
        <v-row align="center">
          <v-col cols="12" sm="5">
            <v-select
              v-model="player1Selected"
              :items="eligiblePlayersForPlayer1"
              item-title="full_name_with_kana_with_branch_and_xclass"
              item-value="player_unique_id"
              label="選手1 (青)"
              clearable
              :rules="[v => !!v || '選手1は必須です']"
            ></v-select>
          </v-col>
          <v-col cols="12" sm="auto" class="text-center">
            <span class="text-h5 font-weight-bold">VS</span>
          </v-col>
          <v-col cols="12" sm="5">
            <v-select
              v-model="player2Selected"
              :items="eligiblePlayersForPlayer2"
              item-title="full_name_with_kana_with_branch_and_xclass"
              item-value="player_unique_id"
              label="選手2 (白)"
              clearable
              :rules="[v => !!v || '選手2は必須です']"
            ></v-select>
          </v-col>
          <v-col cols="12" sm="2" class="d-flex justify-center">
            <v-btn
              color="primary"
              @click="createOneMatch"
              :disabled="!player1Selected || !player2Selected || player1Selected === player2Selected || loadingCreateMatch"
            >
              <v-icon left>mdi-plus</v-icon>
              試合作成
            </v-btn>
          </v-col>
        </v-row>

        <v-divider class="my-4"></v-divider>
        <h3 class="text-h6 mb-2">作成済みワンマッチ ({{ matches.length }}件)</h3>
        <v-data-table
          :headers="matchHeaders"
          :items="matches"
          :loading="loadingMatches"
          :items-per-page="10"
          class="elevation-1"
        >
          <template v-slot:[`item.player1_info`]="{ item }">
            {{ getPlayerFullNameWithBranchAndXclass(item.player1_familyname, item.player1_firstname, item.player1_branch_nm, item.player1_xclass) }}
          </template>
          <template v-slot:[`item.player2_info`]="{ item }">
            {{ getPlayerFullNameWithBranchAndXclass(item.player2_familyname, item.player2_firstname, item.player2_branch_nm, item.player2_xclass) }}
          </template>
          <template v-slot:[`item.actions`]="{ item }">
            <v-icon small @click="deleteMatch(item)">
              mdi-delete
            </v-icon>
          </template>
          <template v-slot:no-data>
            <p>このカテゴリーにはまだ試合が作成されていません。</p>
          </template>
        </v-data-table>
      </div>
      <div v-else>
        <p class="text-center mt-5 text-subtitle-1">大会とカテゴリーを選択してください。</p>
      </div>
    </v-card-text>

    <v-snackbar v-model="snackbar" :color="snackbarColor" :timeout="3000">
      {{ snackbarText }}
      <template v-slot:action="{ attrs }">
        <v-btn text v-bind="attrs" @click="snackbar = false">
          閉じる
        </v-btn>
      </template>
    </v-snackbar>
  </v-card>
</template>

<script>
import { ref, onMounted, computed } from 'vue';
import axios from 'axios';

export default {
  name: 'MatchCombinationView',
  setup() {
    const tournamentsList = ref([]);
    const categoriesList = ref([]);
    const registeredParticipants = ref([]); // 選択された大会・カテゴリーに登録済みの選手
    const matches = ref([]); // 作成された試合リスト

    const selectedTournamentId = ref(null);
    const selectedCategoryId = ref(null);
    const player1Selected = ref(null); // 選手1のユニークID
    const player2Selected = ref(null); // 選手2のユニークID

    const loadingTournaments = ref(false);
    const loadingCategories = ref(false);
    const loadingParticipants = ref(false);
    const loadingMatches = ref(false);
    const loadingCreateMatch = ref(false);
    const loadingDeleteMatch = ref(false);

    const snackbar = ref(false);
    const snackbarText = ref('');
    const snackbarColor = ref('');

    const matchHeaders = [
      { title: '試合番号', value: 'match_number', sortable: true },
      { title: '選手1 (青)', value: 'player1_info', sortable: false },
      { title: '選手2 (白)', value: 'player2_info', sortable: false },
      { title: 'ステータス', value: 'match_status', sortable: true },
      { title: '操作', value: 'actions', sortable: false },
    ];

    // 選手名、支部名、級を結合して表示する関数
    const getPlayerFullNameWithBranchAndXclass = (familyname, firstname, branch_nm, xclass) => {
      const fullName = `${familyname || ''} ${firstname || ''}`;
      const branchPart = branch_nm ? `（${branch_nm}）` : '';
      const xclassPart = xclass ? ` ${xclass}` : ''; // 級があればスペースを挟んで追加
      return `${fullName}${branchPart}${xclassPart}`;
    };

    // 選手選択ドロップダウンに表示する基本の選手リスト（ユニークIDと表示名付き）
    const baseEligiblePlayers = computed(() => {
      const players = registeredParticipants.value.map(p => ({
        ...p,
        player_unique_id: `${(p.branch_id || '').trim()}-${(p.player_id || '').trim()}`,
        // ドロップダウン表示用の新しいプロパティ
        full_name_with_kana_with_branch_and_xclass: getPlayerFullNameWithBranchAndXclass(p.familyname, p.firstname, p.branch_nm, p.xclass),
      }));
      return players;
    });

    // 既存の試合に割り当てられている選手のユニークIDのSet
    const playersInExistingMatches = computed(() => {
      const playerIds = new Set();
      matches.value.forEach(match => {
        const p1Id = (match.player1_id || '').trim();
        const p1BranchId = (match.player1_branch_id || '').trim();
        if (p1Id && p1BranchId) {
          playerIds.add(`${p1BranchId}-${p1Id}`);
        }
        
        const p2Id = (match.player2_id || '').trim();
        const p2BranchId = (match.player2_branch_id || '').trim();
        if (p2Id && p2BranchId) {
          playerIds.add(`${p2BranchId}-${p2Id}`);
        }
      });
      return playerIds;
    });

    // 選手1の選択候補リスト
    const eligiblePlayersForPlayer1 = computed(() => {
      const selectedPlayer2Id = player2Selected.value;
      const filteredPlayers = baseEligiblePlayers.value.filter(player => {
        const isAlreadyInMatch = playersInExistingMatches.value.has(player.player_unique_id);
        const isSelectedByPlayer2 = player.player_unique_id === selectedPlayer2Id;
        return !isAlreadyInMatch && !isSelectedByPlayer2;
      });
      return filteredPlayers;
    });

    // 選手2の選択候補リスト
    const eligiblePlayersForPlayer2 = computed(() => {
      const selectedPlayer1Id = player1Selected.value;
      const filteredPlayers = baseEligiblePlayers.value.filter(player => {
        const isAlreadyInMatch = playersInExistingMatches.value.has(player.player_unique_id);
        const isSelectedByPlayer1 = player.player_unique_id === selectedPlayer1Id;
        return !isAlreadyInMatch && !isSelectedByPlayer1;
      });
      return filteredPlayers;
    });

    // 大会リストの取得
    const fetchTournamentsList = async () => {
      loadingTournaments.value = true;
      try {
        const params = new URLSearchParams();
        params.append('sort', 'start_date');
        params.append('order', 'desc');
        const response = await axios.get(`http://localhost:1880/tournaments?${params.toString()}`);
        tournamentsList.value = response.data;
      } catch (error) {
        console.error('Failed to fetch tournaments list:', error);
        showSnackbar('大会リストの取得に失敗しました', 'error');
      } finally {
        loadingTournaments.value = false;
      }
    };

    // 選択された大会に紐付けられたカテゴリーの取得
    const fetchCategoriesList = async (tournamentId) => {
      if (!tournamentId) {
        categoriesList.value = [];
        return;
      }
      loadingCategories.value = true;
      try {
        const response = await axios.get(`http://localhost:1880/tournament_categories/${tournamentId}`);
        categoriesList.value = response.data;
      } catch (error) {
        console.error('Failed to fetch categories list:', error);
        showSnackbar('カテゴリーリストの取得に失敗しました', 'error');
        categoriesList.value = [];
      } finally {
        loadingCategories.value = false;
      }
    };

    // 選択された大会・カテゴリーに登録済みの出場選手を取得
    const fetchRegisteredParticipants = async (tournamentId, categoryId) => {
      if (!tournamentId || !categoryId) {
        registeredParticipants.value = [];
        return;
      }
      loadingParticipants.value = true;
      try {
        // tournament-participants-detail API は player_m の xclass を含む
        const response = await axios.get(`http://localhost:1880/tournament-participants-detail/${tournamentId}/${categoryId}`);
        registeredParticipants.value = response.data;
      } catch (error) {
        console.error('Failed to fetch registered participants:', error);
        showSnackbar('出場選手リストの取得に失敗しました', 'error');
        registeredParticipants.value = [];
      } finally {
        loadingParticipants.value = false;
      }
    };

    // 選択された大会・カテゴリーの試合リストを取得
    const fetchMatches = async () => {
      if (!selectedTournamentId.value || !selectedCategoryId.value) {
        matches.value = [];
        return;
      }
      loadingMatches.value = true;
      try {
        const params = new URLSearchParams();
        params.append('tournament_id', selectedTournamentId.value);
        params.append('category_id', selectedCategoryId.value);
        params.append('match_type', 'one_match'); // ワンマッチのみに絞り込み
        const response = await axios.get(`http://localhost:1880/matches?${params.toString()}`);
        matches.value = response.data;
      } catch (error) {
        console.error('Failed to fetch matches:', error);
        showSnackbar('試合リストの取得に失敗しました', 'error');
        matches.value = [];
      } finally {
        loadingMatches.value = false;
      }
    };

    // 大会選択時のハンドラー
    const handleTournamentChange = async (newTournamentId) => {
      selectedCategoryId.value = null; // カテゴリー選択をクリア
      registeredParticipants.value = []; // 登録済み選手をクリア
      matches.value = []; // 試合リストをクリア
      player1Selected.value = null;
      player2Selected.value = null;

      await fetchCategoriesList(newTournamentId); // 紐付けられたカテゴリーを再取得
    };

    // カテゴリー選択時のハンドラー
    const handleCategoryChange = async (newCategoryId) => {
      player1Selected.value = null;
      player2Selected.value = null;
      await fetchRegisteredParticipants(selectedTournamentId.value, newCategoryId); // 登録済み選手を再取得
      await fetchMatches(); // 試合リストを再取得
    };

    // ワンマッチ作成
    const createOneMatch = async () => {
      if (!selectedTournamentId.value || !selectedCategoryId.value || !player1Selected.value || !player2Selected.value) {
        showSnackbar('大会、カテゴリー、選手1、選手2は必須です', 'warning');
        return;
      }
      if (player1Selected.value === player2Selected.value) {
        showSnackbar('選手1と選手2は異なる選手を選択してください', 'warning');
        return;
      }

      loadingCreateMatch.value = true;
      try {
        const [player1_branch_id, player1_id] = player1Selected.value.split('-').map(s => s.trim());
        const [player2_branch_id, player2_id] = player2Selected.value.split('-').map(s => s.trim());

        const payload = {
          tournament_id: selectedTournamentId.value,
          category_id: selectedCategoryId.value,
          match_type: 'one_match',
          match_number: matches.value.length + 1, // 現在の試合数+1をシンプルな試合番号とする
          player1_id: player1_id,
          player1_branch_id: player1_branch_id,
          player2_id: player2_id,
          player2_branch_id: player2_branch_id,
          match_status: 'scheduled',
        };

        await axios.post('http://localhost:1880/matches', payload);
        showSnackbar('ワンマッチを作成しました', 'success');
        player1Selected.value = null;
        player2Selected.value = null;
        await fetchMatches(); // 試合リストを更新 (重要: await で完了を待つ)
      } catch (error) {
        console.error('Failed to create one match:', error);
        showSnackbar('試合の作成に失敗しました', 'error');
      } finally {
        loadingCreateMatch.value = false;
      }
    };

    // 試合削除
    const deleteMatch = async (item) => {
      // 削除確認のメッセージも級情報を含むように更新
      if (!confirm(`試合番号 ${item.match_number} (${getPlayerFullNameWithBranchAndXclass(item.player1_familyname, item.player1_firstname, item.player1_branch_nm, item.player1_xclass)} vs ${getPlayerFullNameWithBranchAndXclass(item.player2_familyname, item.player2_firstname, item.player2_branch_nm, item.player2_xclass)}) を削除しますか？`)) {
        return;
      }

      loadingDeleteMatch.value = true;
      try {
        await axios.delete(`http://localhost:1880/matches/${item.match_id}`);
        showSnackbar('試合を削除しました', 'success');
        await fetchMatches(); // 試合リストを更新
      } catch (error) {
        console.error('Failed to delete match:', error);
        showSnackbar('試合の削除に失敗しました', 'error');
      } finally {
        loadingDeleteMatch.value = false;
      }
    };

    // スナックバーの表示
    const showSnackbar = (text, color) => {
      snackbarText.value = text;
      snackbarColor.value = color;
      snackbar.value = true;
    };

    onMounted(() => {
      fetchTournamentsList();
    });

    return {
      tournamentsList,
      categoriesList,
      registeredParticipants,
      matches,
      selectedTournamentId,
      selectedCategoryId,
      player1Selected,
      player2Selected,
      loadingTournaments,
      loadingCategories,
      loadingParticipants,
      loadingMatches,
      loadingCreateMatch,
      loadingDeleteMatch,
      snackbar,
      snackbarText,
      snackbarColor,
      matchHeaders,
      eligiblePlayersForPlayer1,
      eligiblePlayersForPlayer2,
      handleTournamentChange,
      handleCategoryChange,
      createOneMatch,
      deleteMatch,
      getPlayerFullNameWithBranchAndXclass, // 関数名を変更
    };
  },
};
</script>

<style scoped>
/* 必要であれば、ここにコンポーネント固有のスタイルを追加 */
</style>

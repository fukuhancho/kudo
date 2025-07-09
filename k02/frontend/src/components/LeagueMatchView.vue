<template>
  <v-card class="mx-auto" outlined>
    <v-card-title class="headline">
      リーグ戦組み合わせ
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
        <h3 class="text-h6 mb-4">組み合わせ操作</h3>
        <v-row>
          <v-col cols="12">
            <v-btn
              color="primary"
              @click="generateLeagueMatches"
              :disabled="registeredParticipants.length < 3 || registeredParticipants.length > 4 || loadingGenerate"
            >
              <v-icon left>mdi-format-list-numbered</v-icon>
              組み合わせを生成
            </v-btn>
            <v-btn
              color="secondary"
              class="ml-4"
              @click="clearLeagueMatches"
              :disabled="leagueParticipantsOrder.length === 0 && generatedMatches.length === 0"
            >
              <v-icon left>mdi-close</v-icon>
              クリア
            </v-btn>
            <v-btn
              color="success"
              class="ml-4"
              @click="saveLeagueMatches"
              :disabled="leagueParticipantsOrder.length === 0 || loadingSave"
            >
              <v-icon left>mdi-content-save</v-icon>
              組み合わせを保存
            </v-btn>
            <v-btn
              color="info"
              class="ml-4"
              @click="loadLeagueMatches"
              :disabled="loadingLoad || !selectedTournamentId || !selectedCategoryId"
            >
              <v-icon left>mdi-folder-open</v-icon>
              組み合わせを読み込み
            </v-btn>
          </v-col>
        </v-row>

        <v-divider class="my-4"></v-divider>
        <h3 class="text-h6 mb-2">生成されたリーグ戦組み合わせ表</h3>

        <div v-if="leagueParticipantsOrder.length > 0" class="league-table-container">
          <table class="league-table">
            <thead>
              <tr>
                <th class="header-cell fixed-cell"></th>
                <th
                  v-for="player in leagueParticipantsOrder"
                  :key="`col-header-${player.player_id}`"
                  class="header-cell"
                >
                  {{ getPlayerFamilyName(player) }}
                </th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="(rowPlayer, rowIndex) in leagueParticipantsOrder"
                :key="`row-${rowPlayer.player_id}`"
                class="draggable-row"
                draggable="true"
                @dragstart="dragStart($event, rowIndex)"
                @dragover.prevent="dragOver($event, rowIndex)"
                @dragleave="dragLeave"
                @drop="drop($event, rowIndex)"
                :class="{ 'drag-over-target-row': isDragOverTargetRow(rowIndex) }"
              >
                <td class="player-name-cell fixed-cell">
                  {{ getPlayerFullNameWithBranchAndXclass(rowPlayer) }}
                </td>
                <td
                  v-for="(colPlayer, colIndex) in leagueParticipantsOrder"
                  :key="`cell-${rowPlayer.player_id}-${colPlayer.player_id}`"
                  class="match-cell"
                  :class="{ 'diagonal-cell': rowIndex === colIndex }"
                >
                  <template v-if="rowIndex !== colIndex">
                    <!-- 試合表示（例: ○, ×, △, -） -->
                    <!-- ここに試合結果表示ロジックを追加可能 -->
                  </template>
                  <template v-else>
                    <div class="diagonal-line"></div>
                  </template>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <div v-else>
          <p>組み合わせが生成されていません。大会とカテゴリーを選択し、選手が3名または4名登録されていることを確認してください。</p>
        </div>

        <v-divider class="my-4"></v-divider>
        <h3 class="text-h6 mb-2">個別の試合リスト</h3>
        <div v-if="generatedMatches.length > 0" class="match-list">
          <v-list dense>
            <v-list-item
              v-for="(match, index) in generatedMatches"
              :key="`match-${index}`"
              class="match-list-item"
            >
              <v-list-item-content>
                <v-list-item-title>
                  {{ getPlayerFullNameWithBranchAndXclass(match.player1_data) }} vs
                  {{ getPlayerFullNameWithBranchAndXclass(match.player2_data) }}
                </v-list-item-title>
                <v-list-item-subtitle>
                  <!-- ここに試合結果やステータスを表示可能 -->
                  <!-- 例: (未開始) -->
                  ステータス: {{ match.status || '未定義' }} / スコア: {{ match.score || '未入力' }}
                </v-list-item-subtitle>
              </v-list-item-content>
            </v-list-item>
          </v-list>
        </div>
        <div v-else-if="leagueParticipantsOrder.length > 0">
          <p>試合リストはまだ生成されていません。</p>
        </div>

        <v-divider class="my-4"></v-divider>
        <h3 class="text-h6 mb-2">順位データ (開発用表示)</h3>
        <div v-if="Object.keys(standingsData).length > 0">
          <pre>{{ JSON.stringify(standingsData, null, 2) }}</pre>
        </div>
        <div v-else>
          <p>順位データはまだありません。</p>
        </div>

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
import { ref, onMounted, watch } from 'vue';
import axios from 'axios';

export default {
  name: 'LeagueMatchView',
  setup() {
    const tournamentsList = ref([]);
    const categoriesList = ref([]);
    const registeredParticipants = ref([]); // 選択された大会・カテゴリーに登録済みの選手
    const leagueParticipantsOrder = ref([]); // リーグ戦の表示順序（ドラッグ＆ドロップで変更可能）
    const generatedMatches = ref([]); // 生成された個別の試合リスト (refに変更)
    const standingsData = ref({}); // 順位データ (追加)

    const loadingTournaments = ref(false);
    const loadingCategories = ref(false);
    const loadingParticipants = ref(false);
    const loadingGenerate = ref(false);
    const loadingSave = ref(false);
    const loadingLoad = ref(false);

    const selectedTournamentId = ref(null);
    const selectedCategoryId = ref(null);

    const snackbar = ref(false);
    const snackbarText = ref('');
    const snackbarColor = ref('');

    // ドラッグ＆ドロップ関連のstate
    const draggedIndex = ref(null); // ドラッグ中の行のインデックス
    const dropTargetIndex = ref(null); // ドロップターゲットの行のインデックス

    // 選手名、支部名、級を結合して表示する関数 (トーナメント表と共通)
    const getPlayerFullNameWithBranchAndXclass = (player) => {
      if (!player) return '未定';
      const fullName = `${player.familyname || ''} ${player.firstname || ''}`;
      const branchPart = player.branch_nm ? `（${player.branch_nm}）` : '';
      const xclassPart = player.xclass ? ` ${player.xclass}` : '';
      return `${fullName}${branchPart}${xclassPart}`;
    };

    // 選手名から苗字のみを取得する関数
    const getPlayerFamilyName = (player) => {
      if (!player) return '';
      return player.familyname || '';
    };

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

    // 大会選択時のハンドラー
    const handleTournamentChange = async (newTournamentId) => {
      selectedCategoryId.value = null; // カテゴリー選択をクリア
      registeredParticipants.value = []; // 登録済み選手をクリア
      leagueParticipantsOrder.value = []; // リーグ戦の組み合わせをクリア
      generatedMatches.value = []; // 試合リストをクリア
      standingsData.value = {}; // 順位データをクリア
      await fetchCategoriesList(newTournamentId); // 紐付けられたカテゴリーを再取得
    };

    // カテゴリー選択時のハンドラー
    const handleCategoryChange = async (newCategoryId) => {
      leagueParticipantsOrder.value = []; // リーグ戦の組み合わせをクリア
      generatedMatches.value = []; // 試合リストをクリア
      standingsData.value = {}; // 順位データをクリア
      await fetchRegisteredParticipants(selectedTournamentId.value, newCategoryId); // 登録済み選手を再取得
      // カテゴリーが選択されたら、自動で組み合わせを読み込む
      if (selectedTournamentId.value && newCategoryId) {
        loadLeagueMatches();
      }
    };

    // リーグ戦組み合わせを生成する関数
    const generateLeagueMatches = () => {
      loadingGenerate.value = true;
      if (registeredParticipants.value.length < 3 || registeredParticipants.value.length > 4) {
        showSnackbar('リーグ戦組み合わせを生成するには3名または4名の選手が必要です。', 'warning');
        loadingGenerate.value = false;
        return;
      }

      // 選手をシャッフルして初期表示順序を設定
      const shuffledParticipants = [...registeredParticipants.value].sort(() => 0.5 - Math.random());
      leagueParticipantsOrder.value = shuffledParticipants;

      // 個別の試合リストを生成
      const matches = [];
      const participants = leagueParticipantsOrder.value;
      for (let i = 0; i < participants.length; i++) {
        for (let j = i + 1; j < participants.length; j++) {
          matches.push({
            player1_id: participants[i].player_id,
            player2_id: participants[j].player_id,
            player1_data: participants[i], // 選手情報を保存
            player2_data: participants[j], // 選手情報を保存
            match_id: `M-${participants[i].player_id}-${participants[j].player_id}`,
            status: '未開始', // 初期ステータス
            score: '' // 初期スコア
          });
        }
      }
      generatedMatches.value = matches; // refに設定

      // 順位データの初期化 (必要に応じて構造を定義)
      const initialStandings = {};
      participants.forEach(p => {
        initialStandings[p.player_id] = {
          player_id: p.player_id,
          player_name: getPlayerFullNameWithBranchAndXclass(p),
          wins: 0,
          losses: 0,
          draws: 0,
          points: 0
        };
      });
      standingsData.value = initialStandings;

      showSnackbar('リーグ戦組み合わせを生成しました！', 'success');
      loadingGenerate.value = false;
    };

    // リーグ戦組み合わせをクリアする関数
    const clearLeagueMatches = () => {
      leagueParticipantsOrder.value = [];
      generatedMatches.value = [];
      standingsData.value = {};
      showSnackbar('リーグ戦組み合わせをクリアしました。', 'info');
    };

    // リーグ戦組み合わせを保存する関数
    const saveLeagueMatches = async () => {
      if (!selectedTournamentId.value || !selectedCategoryId.value || leagueParticipantsOrder.value.length === 0) {
        showSnackbar('保存する組み合わせがありません。大会、カテゴリーを選択し、組み合わせを生成してください。', 'warning');
        return;
      }

      loadingSave.value = true;
      try {
        const payload = {
          tournament_id: selectedTournamentId.value,
          category_id: selectedCategoryId.value,
          league_data: leagueParticipantsOrder.value, // JSオブジェクトとして送信
          match_results_data: generatedMatches.value, // JSオブジェクトとして送信
          standings_data: standingsData.value // JSオブジェクトとして送信
        };

        // Node-REDの保存エンドポイントを呼び出し
        const response = await axios.post('http://localhost:1880/save-league-bracket', payload);

        if (response.data.success) {
          showSnackbar('リーグ戦データを保存しました！', 'success');
        } else {
          showSnackbar('保存に失敗しました: ' + (response.data.message || '不明なエラー'), 'error');
        }
      } catch (error) {
        console.error('Failed to save league matches:', error);
        showSnackbar('保存中にエラーが発生しました。サーバーとの接続を確認してください。', 'error');
      } finally {
        loadingSave.value = false;
      }
    };

    // リーグ戦組み合わせを読み込む関数
    const loadLeagueMatches = async () => {
      if (!selectedTournamentId.value || !selectedCategoryId.value) {
        showSnackbar('組み合わせを読み込むには、大会とカテゴリーを選択してください。', 'warning');
        return;
      }

      loadingLoad.value = true;
      try {
        // Node-REDの読み込みエンドポイントを呼び出し
        const response = await axios.get(`http://localhost:1880/load-league-bracket/${selectedTournamentId.value}/${selectedCategoryId.value}`);

        if (response.data.success) {
          // Node-REDからJSON文字列として受け取ったデータをJSON.parseしてstateに設定
          leagueParticipantsOrder.value = JSON.parse(response.data.league_data);
          generatedMatches.value = response.data.match_results_data ? JSON.parse(response.data.match_results_data) : [];
          standingsData.value = response.data.standings_data ? JSON.parse(response.data.standings_data) : {};

          showSnackbar('リーグ戦データを読み込みました！', 'success');
        } else {
          // 成功がfalseの場合、メッセージを表示
          if (response.status === 404) {
            leagueParticipantsOrder.value = []; // データが見つからない場合はクリア
            generatedMatches.value = [];
            standingsData.value = {};
            showSnackbar(response.data.message || '指定された組み合わせは見つかりませんでした。', 'info');
          } else {
            showSnackbar('読み込みに失敗しました: ' + (response.data.message || '不明なエラー'), 'error');
          }
        }
      } catch (error) {
        console.error('Failed to load league matches:', error);
        // 404エラーの場合、データが見つからなかったことを示す
        if (error.response && error.response.status === 404) {
          leagueParticipantsOrder.value = []; // データが見つからない場合はクリア
          generatedMatches.value = [];
          standingsData.value = {};
          showSnackbar(error.response.data.message || '指定された組み合わせは見つかりませんでした。', 'info');
        } else {
          showSnackbar('読み込み中にエラーが発生しました。サーバーとの接続を確認してください。', 'error');
        }
      } finally {
        loadingLoad.value = false;
      }
    };

    // スナックバーの表示
    const showSnackbar = (text, color) => {
      snackbarText.value = text;
      snackbarColor.value = color;
      snackbar.value = true;
    };

    // --- ドラッグ＆ドロップ関連の関数 ---

    // ドラッグ開始時
    const dragStart = (event, index) => {
      draggedIndex.value = index;
      event.dataTransfer.effectAllowed = 'move';
      event.dataTransfer.setData('text/plain', index); // ドラッグする行のインデックスを保存
    };

    // ドラッグオーバー時 (ドロップを許可するために必要)
    const dragOver = (event, index) => {
      event.preventDefault();
      if (draggedIndex.value !== null && draggedIndex.value !== index) {
        dropTargetIndex.value = index; // ドロップターゲットをマーク
      }
    };

    // ドラッグリーブ時
    const dragLeave = () => {
      dropTargetIndex.value = null; // ドロップターゲットのマークを解除
    };

    // ドロップ時
    const drop = (event, targetIndex) => {
      event.preventDefault();
      dropTargetIndex.value = null; // ドロップターゲットのマークを解除

      if (draggedIndex.value === null || draggedIndex.value === targetIndex) {
        return; // 無効なドロップまたは同じ場所へのドロップ
      }

      const movedItem = leagueParticipantsOrder.value[draggedIndex.value];
      const newOrder = [...leagueParticipantsOrder.value];
      newOrder.splice(draggedIndex.value, 1); // 元の場所から削除
      newOrder.splice(targetIndex, 0, movedItem); // 新しい場所に挿入

      leagueParticipantsOrder.value = newOrder; // 順序を更新
      draggedIndex.value = null; // ドラッグ状態をクリア
      showSnackbar('選手の順序を入れ替えました！', 'success');
    };

    // ドロップターゲットの行にスタイルを適用するためのヘルパー関数
    const isDragOverTargetRow = (rowIndex) => {
      return dropTargetIndex.value === rowIndex;
    };

    onMounted(() => {
      fetchTournamentsList();
    });

    // カテゴリーが選択されたら自動で選手リストを読み込み、保存済み組み合わせを読み込む
    watch(selectedCategoryId, (newVal) => {
      if (newVal && selectedTournamentId.value) {
        fetchRegisteredParticipants(selectedTournamentId.value, newVal);
        loadLeagueMatches(); // 保存済みの組み合わせを読み込む
      } else {
        registeredParticipants.value = [];
        leagueParticipantsOrder.value = [];
        generatedMatches.value = [];
        standingsData.value = {};
      }
    });

    return {
      tournamentsList,
      categoriesList,
      registeredParticipants,
      leagueParticipantsOrder,
      generatedMatches, // refを公開
      standingsData, // refを公開
      selectedTournamentId,
      selectedCategoryId,
      loadingTournaments,
      loadingCategories,
      loadingParticipants,
      loadingGenerate,
      loadingSave,
      loadingLoad,
      snackbar,
      snackbarText,
      snackbarColor,
      handleTournamentChange,
      handleCategoryChange,
      generateLeagueMatches,
      clearLeagueMatches,
      saveLeagueMatches,
      loadLeagueMatches,
      getPlayerFullNameWithBranchAndXclass,
      getPlayerFamilyName,
      dragStart,
      dragOver,
      dragLeave,
      drop,
      isDragOverTargetRow,
    };
  },
};
</script>

<style scoped>
/* Vuetifyのデフォルトスタイルに加えて、カスタムスタイルを適用 */

.league-table-container {
  overflow-x: auto; /* 横スクロール可能にする */
  margin-top: 20px;
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  background-color: #f9f9f9;
  padding: 10px; /* テーブル全体のパディング */
}

.league-table {
  width: 100%;
  border-collapse: collapse; /* セルのボーダーを結合 */
  min-width: 400px; /* 3-4人なので、ある程度の最小幅を設定 */
}

.header-cell, .player-name-cell, .match-cell {
  border: 1px solid #cfd8dc; /* セルのボーダー */
  padding: 8px 12px;
  text-align: center;
  font-weight: bold;
  color: #424242;
  white-space: nowrap; /* テキストの折り返しを防ぐ */
}

.header-cell {
  background-color: #e0e0e0; /* ヘッダーの背景色 */
  position: sticky; /* 横スクロール時に固定 */
  top: 0; /* 上部に固定 */
  z-index: 2; /* 他のセルより前面に */
}

.player-name-cell {
  background-color: #e3f2fd; /* 選手名セルの背景色 */
  text-align: left;
  min-width: 150px; /* 選手名セルの最小幅 */
  position: sticky; /* 横スクロール時に固定 */
  left: 0; /* 左側に固定 */
  z-index: 1; /* マッチセルより前面に */
}

/* 固定セルが重なる部分の背景色を調整 */
.header-cell.fixed-cell {
  background-color: #c5cae9; /* 左上隅のセル */
  z-index: 3; /* 最前面に */
}

.match-cell {
  background-color: #ffffff; /* 試合セルの背景色 */
  height: 50px; /* 試合セルの高さ */
  width: 50px; /* 試合セルの幅 */
  position: relative; /* 斜線のために必要 */
}

.diagonal-cell {
  background-color: #f0f4c3; /* 対角線セルの背景色 */
}

.diagonal-line {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background:
    linear-gradient(to top right, transparent calc(50% - 1px), #757575, transparent calc(50% + 1px));
  pointer-events: none; /* クリックイベントをブロックしない */
}

/* ドラッグ可能な行のスタイル */
.draggable-row {
  cursor: grab;
  transition: background-color 0.2s ease;
}

.draggable-row:active {
  cursor: grabbing;
}

/* ドロップターゲットになった行の視覚的フィードバック */
.draggable-row.drag-over-target-row {
  background-color: #bbdefb !important; /* ドロップ可能な場所をハイライト */
  border-top: 2px dashed #3f51b5; /* 上部に点線ボーダー */
  border-bottom: 2px dashed #3f51b5; /* 下部に点線ボーダー */
}

/* スナックバーのスタイルはVuetifyに任せる */
</style>

<template>
  <v-card class="mx-auto" outlined>
    <v-card-title class="headline">
      リーグ戦組み合わせ
    </v-card-title>
    <v-card-text>
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
        <p class="text-center mt-5 text-subtitle-1">リーグ戦を生成するには、登録選手が必要です。大会とカテゴリーを選択してください。</p>
      </div>
    </v-card-text>

    </v-card>
</template>

<script>
import { ref, watch } from 'vue';
import axios from 'axios';

export default {
  name: 'LeagueMatchView',
  // ★Props を定義：親から渡されるデータ
  props: {
    tournamentId: {
      type: [String, Number],
      required: true,
    },
    categoryId: {
      type: [String, Number],
      required: true,
    },
    registeredParticipants: {
      type: Array,
      required: true,
      default: () => [],
    },
  },
  // ★イベント定義：親にスナックバー表示を要求する
  emits: ['show-snackbar'],
  setup(props, { emit }) {
    const leagueParticipantsOrder = ref([]); // リーグ戦の表示順序（ドラッグ＆ドロップで変更可能）
    const generatedMatches = ref([]); // 生成された個別の試合リスト
    const standingsData = ref({}); // 順位データ

    const loadingGenerate = ref(false);
    const loadingSave = ref(false);
    const loadingLoad = ref(false);

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

    // スナックバーの表示を親コンポーネントに依頼
    const showSnackbar = (text, color) => {
      emit('show-snackbar', text, color);
    };

    // リーグ戦組み合わせを生成する関数
    const generateLeagueMatches = () => {
      loadingGenerate.value = true;
      if (props.registeredParticipants.length < 3 || props.registeredParticipants.length > 4) {
        showSnackbar('リーグ戦組み合わせを生成するには3名または4名の選手が必要です。', 'warning');
        loadingGenerate.value = false;
        return;
      }

      // 選手をシャッフルして初期表示順序を設定
      const shuffledParticipants = [...props.registeredParticipants].sort(() => 0.5 - Math.random());
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
      generatedMatches.value = matches;

      // 順位データの初期化
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
      if (!props.tournamentId || !props.categoryId || leagueParticipantsOrder.value.length === 0) {
        showSnackbar('保存する組み合わせがありません。', 'warning');
        return;
      }

      loadingSave.value = true;
      try {
        const bracketId = crypto.randomUUID();

        const payload = {
          bracket_id: bracketId,
          tournament_id: props.tournamentId,
          category_id: props.categoryId,
          league_data: leagueParticipantsOrder.value, // JSオブジェクトとして送信
          match_results_data: generatedMatches.value, // JSオブジェクトとして送信
          standings_data: standingsData.value // JSオブジェクトとして送信
        };

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
      if (!props.tournamentId || !props.categoryId) {
        showSnackbar('組み合わせを読み込むには、大会とカテゴリーを選択してください。', 'warning');
        return;
      }

      loadingLoad.value = true;
      try {
        const response = await axios.get(`http://localhost:1880/load-league-bracket/${props.tournamentId}/${props.categoryId}`);

        if (response.data.success) {
          leagueParticipantsOrder.value = JSON.parse(response.data.league_data);
          generatedMatches.value = response.data.match_results_data ? JSON.parse(response.data.match_results_data) : [];
          standingsData.value = response.data.standings_data ? JSON.parse(response.data.standings_data) : {};

          showSnackbar('リーグ戦データを読み込みました！', 'success');
        } else {
          if (response.status === 404) {
            leagueParticipantsOrder.value = [];
            generatedMatches.value = [];
            standingsData.value = {};
            showSnackbar(response.data.message || '指定された組み合わせは見つかりませんでした。', 'info');
          } else {
            showSnackbar('読み込みに失敗しました: ' + (response.data.message || '不明なエラー'), 'error');
          }
        }
      } catch (error) {
        console.error('Failed to load league matches:', error);
        if (error.response && error.response.status === 404) {
          leagueParticipantsOrder.value = [];
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

    // --- ドラッグ＆ドロップ関連の関数 ---
    const dragStart = (event, index) => {
      draggedIndex.value = index;
      event.dataTransfer.effectAllowed = 'move';
      event.dataTransfer.setData('text/plain', index);
    };

    const dragOver = (event, index) => {
      event.preventDefault();
      if (draggedIndex.value !== null && draggedIndex.value !== index) {
        dropTargetIndex.value = index;
      }
    };

    const dragLeave = () => {
      dropTargetIndex.value = null;
    };

    const drop = (event, targetIndex) => {
      event.preventDefault();
      dropTargetIndex.value = null;

      if (draggedIndex.value === null || draggedIndex.value === targetIndex) {
        return;
      }

      const movedItem = leagueParticipantsOrder.value[draggedIndex.value];
      const newOrder = [...leagueParticipantsOrder.value];
      newOrder.splice(draggedIndex.value, 1);
      newOrder.splice(targetIndex, 0, movedItem);

      leagueParticipantsOrder.value = newOrder;
      draggedIndex.value = null;
      showSnackbar('選手の順序を入れ替えました！', 'success');
    };

    const isDragOverTargetRow = (rowIndex) => {
      return dropTargetIndex.value === rowIndex;
    };

    // ★親から渡された Props (tournamentId, categoryId) の変更を監視し、データを読み込む
    watch([() => props.tournamentId, () => props.categoryId], ([newTournamentId, newCategoryId]) => {
      if (newTournamentId && newCategoryId) {
        loadLeagueMatches(); // 結合された画面で大会/カテゴリが選択されたら自動ロード
      } else {
        // 大会またはカテゴリーがクリアされた場合、リーグ戦データもクリア
        leagueParticipantsOrder.value = [];
        generatedMatches.value = [];
        standingsData.value = {};
      }
    }, { immediate: true }); // コンポーネントがマウントされた直後にも実行

    return {
      leagueParticipantsOrder,
      generatedMatches,
      standingsData,
      loadingGenerate,
      loadingSave,
      loadingLoad,
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
/* 既存のスタイルをここに貼り付け */
.league-table-container {
  overflow-x: auto;
  margin-top: 20px;
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  background-color: #f9f9f9;
  padding: 10px;
}

.league-table {
  width: 100%;
  border-collapse: collapse;
  min-width: 400px;
}

.header-cell, .player-name-cell, .match-cell {
  border: 1px solid #cfd8dc;
  padding: 8px 12px;
  text-align: center;
  font-weight: bold;
  color: #424242;
  white-space: nowrap;
}

.header-cell {
  background-color: #e0e0e0;
  position: sticky;
  top: 0;
  z-index: 2;
}

.player-name-cell {
  background-color: #e3f2fd;
  text-align: left;
  min-width: 150px;
  position: sticky;
  left: 0;
  z-index: 1;
}

.header-cell.fixed-cell {
  background-color: #c5cae9;
  z-index: 3;
}

.match-cell {
  background-color: #ffffff;
  height: 50px;
  width: 50px;
  position: relative;
}

.diagonal-cell {
  background-color: #f0f4c3;
}

.diagonal-line {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background:
    linear-gradient(to top right, transparent calc(50% - 1px), #757575, transparent calc(50% + 1px));
  pointer-events: none;
}

.draggable-row {
  cursor: grab;
  transition: background-color 0.2s ease;
}

.draggable-row:active {
  cursor: grabbing;
}

.draggable-row.drag-over-target-row {
  background-color: #bbdefb !important;
  border-top: 2px dashed #3f51b5;
  border-bottom: 2px dashed #3f51b5;
}
</style>
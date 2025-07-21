<template>
  <v-card class="mx-auto" outlined>
    <v-card-title class="headline">
      リーグ戦組み合わせ
    </v-card-title>
    <v-card-text>
      <div v-if="tournamentId && categoryId">
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
              :disabled="loadingLoad || !tournamentId || !categoryId" >
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
                  <template v-if="rowIndex !== colIndex && rowIndex < colIndex">
                    <!-- 選手同士の対戦セル (上三角部分のみ) -->
                    <div class="match-cell-inputs" v-if="getMatch(rowPlayer.player_id, colPlayer.player_id)">
                      <!-- コート選択 -->
                      <select
                        v-model="getMatch(rowPlayer.player_id, colPlayer.player_id).court_id"
                        @change="updateMatchSchedule(getMatch(rowPlayer.player_id, colPlayer.player_id), 'court', $event.target.value)"
                        class="custom-input court-select"
                      >
                        <option value="" disabled selected>コート</option>
                        <option v-for="courtOption in availableCourtOptions" :key="courtOption" :value="courtOption">
                          {{ courtOption }}
                        </option>
                      </select>
                      <!-- 試合順入力 -->
                      <input
                        type="number"
                        v-model.number="getMatch(rowPlayer.player_id, colPlayer.player_id).match_order_no"
                        @input="updateMatchSchedule(getMatch(rowPlayer.player_id, colPlayer.player_id), 'order', $event.target.value)"
                        min="1"
                        placeholder="No."
                        class="custom-input match-order-input"
                      />
                    </div>
                  </template>
                  <template v-else-if="rowIndex !== colIndex && rowIndex > colIndex">
                    <!-- 下三角部分は空のまま (重複試合なので入力欄不要) -->
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

        <!-- ここに個別の試合リストを表示します -->
        <v-divider class="my-4"></v-divider>
        <h3 class="text-h6 mb-2">試合リスト</h3>
        <div v-if="displayedMatches.length > 0" class="match-list-container">
          <div v-for="(match, index) in displayedMatches" :key="index" class="match-item">
            <span class="blue-player">{{ getPlayerFullNameWithBranchAndXclass(match.player1_data) }}</span>
            <span class="vs-text"> vs </span>
            <span class="white-player">{{ getPlayerFullNameWithBranchAndXclass(match.player2_data) }}</span>
            <span v-if="match.court_id" class="match-info"> (コート: {{ match.court_id }})</span>
            <span v-if="match.match_order_no" class="match-info"> (試合順: {{ match.match_order_no }})</span>
          </div>
        </div>
        <div v-else>
          <p>生成された試合がありません。</p>
        </div>

        <v-divider class="my-4"></v-divider>
        <!-- 順位データ (開発用表示) は一時的に非表示にします -->
        <!--
        <h3 class="text-h6 mb-2">順位データ (開発用表示)</h3>
        <div v-if="Object.keys(standingsData).length > 0">
          <pre>{{ JSON.stringify(standingsData, null, 2) }}</pre>
        </div>
        <div v-else>
          <p>順位データはまだありません。</p>
        </div>
        -->

      </div>
    </v-card-text>
  </v-card>
</template>
<script>
import { ref, watch, computed } from 'vue';
import axios from 'axios';

export default {
  name: 'LeagueMatchView',
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
    numberOfCourts: {
      type: Number,
      default: 0,
    }
  },
  emits: ['show-snackbar'],
  setup(props, { emit }) {
    const leagueParticipantsOrder = ref([]);
    const generatedMatches = ref([]);
    const standingsData = ref({});

    const loadingGenerate = ref(false);
    const loadingSave = ref(false);
    const loadingLoad = ref(false);

    const draggedIndex = ref(null);
    const dropTargetIndex = ref(null);

    // プレイヤーのフルネーム（支部、X級含む）を取得するヘルパー関数
    const getPlayerFullNameWithBranchAndXclass = (player) => {
      if (!player) return '未定';
      const fullName = `${player.familyname || ''} ${player.firstname || ''}`;
      const branchPart = player.branch_nm ? `（${player.branch_nm}）` : '';
      const xclassPart = player.xclass ? ` ${player.xclass}` : '';
      return `${fullName}${branchPart}${xclassPart}`;
    };

    // プレイヤーの姓を取得するヘルパー関数
    const getPlayerFamilyName = (player) => {
      if (!player) return '';
      return player.familyname || '';
    };

    // スナックバーを表示する関数
    const showSnackbar = (text, color) => {
      emit('show-snackbar', text, color);
    };

    // 利用可能なコートのオプションを生成する算出プロパティ
    const availableCourtOptions = computed(() => {
      const courts = [];
      for (let i = 0; i < props.numberOfCourts; i++) {
        courts.push(String.fromCharCode(65 + i)); // 'A', 'B', 'C' ...
      }
      return courts;
    });

    // 試合のplayer_idをソートして一意のキーを生成するヘルパー関数
    const createMatchKey = (player1Id, player2Id) => {
      return [player1Id, player2Id].sort().join('-');
    };

    // generatedMatches を match_key をキーとする Map に変換する算出プロパティ
    const matchesMap = computed(() => {
      const map = new Map();
      generatedMatches.value.forEach(match => {
        const key = createMatchKey(match.player1_id, match.player2_id);
        map.set(key, match);
      });
      return map;
    });

    // 2つのplayer_idから対応する試合オブジェクトを取得する関数
    const getMatch = (player1Id, player2Id) => {
      const key = createMatchKey(player1Id, player2Id);
      return matchesMap.value.get(key);
    };
    
    // 表示用の試合リストを生成する算出プロパティ
    // 空道ルール「上の選手が青、下の選手が白」に則り、player1_dataを青、player2_dataを白として表示
    const displayedMatches = computed(() => {
      // generatedMatchesをmatch_order_noでソート
      const sortedMatches = [...generatedMatches.value].sort((a, b) => {
        // null値の扱い: nullは一番後ろに
        if (a.match_order_no === null && b.match_order_no === null) return 0;
        if (a.match_order_no === null) return 1;
        if (b.match_order_no === null) return -1;
        return a.match_order_no - b.match_order_no;
      });

      return sortedMatches.map(match => {
        // player1_dataとplayer2_dataが確実に存在するようにチェック
        const player1 = props.registeredParticipants.find(p => p.player_id === match.player1_id);
        const player2 = props.registeredParticipants.find(p => p.player_id === match.player2_id);
        
        return {
          ...match,
          player1_data: player1, // 常にplayer1_dataを青として扱う
          player2_data: player2  // 常にplayer2_dataを白として扱う
        };
      });
    });

    // リーグ戦組み合わせを生成する関数
    const generateLeagueMatches = () => {
      loadingGenerate.value = true;
      if (props.registeredParticipants.length < 3 || props.registeredParticipants.length > 4) {
        showSnackbar('リーグ戦組み合わせを生成するには3名または4名の選手が必要です。', 'warning');
        loadingGenerate.value = false;
        return;
      }

      // 選手をシャッフルして順序を決定
      const shuffledParticipants = [...props.registeredParticipants].sort(() => 0.5 - Math.random());
      leagueParticipantsOrder.value = shuffledParticipants;

      const matches = [];
      const participants = leagueParticipantsOrder.value;
      for (let i = 0; i < participants.length; i++) {
        for (let j = i + 1; j < participants.length; j++) {
          matches.push({
            player1_id: participants[i].player_id,
            player2_id: participants[j].player_id,
            // player1_dataとplayer2_dataはここでは参照として保持
            // 表示時にはdisplayedMatchesで改めて取得する
            match_id: `M-${participants[i].player_id}-${participants[j].player_id}`,
            match_key: createMatchKey(participants[i].player_id, participants[j].player_id),
            status: '未開始',
            score: '',
            court_id: null,
            match_order_no: null
          });
        }
      }
      generatedMatches.value = matches;

      // 初期順位データの生成
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

    // リーグ戦データを保存する関数
    const saveLeagueMatches = async () => {
      if (!props.tournamentId || !props.categoryId || leagueParticipantsOrder.value.length === 0) {
        showSnackbar('保存する組み合わせがありません。', 'warning');
        return;
      }

      loadingSave.value = true;
      try {
        const bracketId = crypto.randomUUID(); // ユニークなブラケットIDを生成

        const payload = {
          bracket_id: bracketId,
          tournament_id: props.tournamentId,
          category_id: props.categoryId,
          league_data: leagueParticipantsOrder.value ? JSON.stringify(leagueParticipantsOrder.value) : null,
          match_results_data: generatedMatches.value ? JSON.stringify(generatedMatches.value) : null,
          standings_data: standingsData.value ? JSON.stringify(standingsData.value) : null,
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

    // リーグ戦データを読み込む関数
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
          const loadedMatches = response.data.match_results_data ? JSON.parse(response.data.match_results_data) : [];
          
          // ロードした試合データにcourt_idとmatch_order_noが存在しない場合、nullで初期化
          loadedMatches.forEach(match => {
            if (!('court_id' in match)) match.court_id = null;
            if (!('match_order_no' in match)) match.match_order_no = null;
            match.match_key = createMatchKey(match.player1_id, match.player2_id);
          });
          generatedMatches.value = loadedMatches;

          standingsData.value = response.data.standings_data ? JSON.parse(response.data.standings_data) : {};

          showSnackbar('リーグ戦データを読み込みました！', 'success');
        } else {
          // 404エラーの場合、データがないことを示す
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

    // 試合スケジュール（コート、試合順）を更新する関数
    const updateMatchSchedule = (match, type, value) => {
      if (match) {
        if (type === 'court') {
          match.court_id = value;
        } else if (type === 'order') {
          // 入力値が空の場合はnull、それ以外は数値に変換
          match.match_order_no = value === '' ? null : parseInt(value, 10);
          // NaNになった場合もnullにする
          if (isNaN(match.match_order_no)) {
            match.match_order_no = null;
          }
        }
      }
    };

    // ドラッグ＆ドロップ関連の関数
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

    // tournamentId または categoryId が変更されたら、自動的にデータをロード
    watch([() => props.tournamentId, () => props.categoryId], ([newTournamentId, newCategoryId]) => {
      if (newTournamentId && newCategoryId) {
        loadLeagueMatches();
      } else {
        // IDがクリアされた場合は、表示データもクリア
        leagueParticipantsOrder.value = [];
        generatedMatches.value = [];
        standingsData.value = {};
      }
    }, { immediate: true }); // コンポーネント初期化時にも一度実行

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
      availableCourtOptions,
      updateMatchSchedule,
      getMatch,
      displayedMatches, // 新しく追加した算出プロパティ
    };
  },
};
</script>

<style scoped>
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
  min-width: 400px; /* 最小幅を維持 */
}

.header-cell, .player-name-cell, .match-cell {
  border: 1px solid #cfd8dc;
  padding: 2px; /* パディングをさらに小さく */
  text-align: center;
  font-weight: bold;
  color: #424242;
  white-space: nowrap;
  /* font-size: 0.7em; */ /* この共通指定を上書きするため、player-name-cellで個別に指定します */
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
  min-width: 70px; /* 選手名セルの最小幅を調整 (狭く) */
  height: 50px; /* 高さを調整 */
  position: sticky;
  left: 0;
  z-index: 1;
  display: flex; /* Flexboxで内容を中央揃え */
  align-items: center;
  justify-content: flex-start; /* 左寄せ */
  padding-left: 8px; /* 左パディングを少し増やす */
  font-size: 1.0em; /* ★選手名のフォントサイズを大きくしました */
}

.header-cell.fixed-cell {
  background-color: #c5cae9;
  z-index: 3;
}

.match-cell {
  background-color: #ffffff;
  height: 50px; /* セルの高さを調整して入力欄を収める (高く) */
  width: 80px; /* セルの幅を調整 (広く) */
  position: relative;
  vertical-align: middle; /* セル内のコンテンツを垂直方向中央揃え */
  text-align: center; /* セル内のコンテンツを水平方向中央揃え */
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

/* 試合スケジュール入力欄のスタイル (テーブルセル内用) */
.match-cell-inputs {
  display: flex;
  flex-direction: row; /* これが横並びの指示 */
  gap: 2px; /* 入力フィールド間の隙間を調整 */
  align-items: center; /* 垂直方向中央揃え */
  justify-content: center; /* 水平方向中央揃え */
  width: 100%; /* セル幅に合わせる */
  height: 100%; /* セル高さに合わせる */
}

.custom-input {
  max-width: 42px; /* セル内に収まるように幅を調整 (さらに広く) */
  min-width: 20px;
  height: 24px; /* 高さを調整 (さらに高く) */
  font-size: 0.8em; /* フォントサイズを調整 (大きく) */
  padding: 0 3px; /* パディングを調整 */
  border: 1px solid #ccc;
  border-radius: 3px;
  box-sizing: border-box;
  background-color: white;
  color: #333;
  text-align: center;
  -moz-appearance: textfield;
}

.custom-input::-webkit-outer-spin-button,
.custom-input::-webkit-inner-spin-button {
  -webkit-appearance: none;
  margin: 0;
}

.court-select {
  padding-right: 12px; /* ドロップダウンアイコンのスペースを確保 */
  background-image: url('data:image/svg+xml;charset=US-ASCII,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%22292.4%22%20height%3D%22292.4%22%3E%3Cpath%20fill%3D%22%23000000%22%20d%3D%22M287%2069.4a17.6%2017.6%200%200%200-13-5.4H18.4c-6.5%200-12.3%203.2-15.6%208.1-3.3%204.9-3.3%2011.2%200%2016.1l132%20126.7c3.3%203.2%208.3%203.2%2011.6%200l132-126.7c3.3-4.9%203.3-11.2%200-16.1z%22%2F%3E%3C%2Fsvg%3E');
  background-repeat: no-repeat;
  background-position: right 2px center; /* アイコンの位置 */
  background-size: 9px; /* アイコンのサイズ (さらに大きく) */
  -webkit-appearance: none;
  -moz-appearance: none;
  appearance: none;
}

.custom-input:focus {
  outline: none;
  border-color: #3f51b5;
  box-shadow: 0 0 0 1px #3f51b5;
}

.custom-input::placeholder {
  color: #999;
  font-size: 0.8em; /* プレースホルダーのフォントサイズも調整 (大きく) */
}

/* 追加した試合リストのスタイル */
.match-list-container {
  margin-top: 15px;
  padding: 10px;
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  background-color: #f9f9f9;
}

.match-item {
  padding: 8px 0;
  border-bottom: 1px dashed #e0e0e0;
  display: flex;
  align-items: center;
  font-size: 0.95em;
}

.match-item:last-child {
  border-bottom: none;
}

.blue-player {
  color: #1976d2; /* 青色 */
  font-weight: bold;
}

.white-player {
  color: #424242; /* 白側は通常の文字色 */
  font-weight: bold;
}

.vs-text {
  margin: 0 8px;
  color: #757575;
}

.match-info {
  margin-left: 10px;
  font-size: 0.85em;
  color: #616161;
}
</style>

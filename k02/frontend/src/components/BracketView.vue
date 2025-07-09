<template>
  <v-card class="mx-auto" outlined>
    <v-card-title class="headline">トーナメント組み合わせ</v-card-title>
    <v-card-text>
      <div v-if="registeredParticipants.length > 0">
        <v-divider class="my-4"></v-divider>
        <h3 class="text-h6 mb-4">トーナメント操作</h3>
        <v-row>
          <v-col cols="12">
            <v-btn
              color="primary"
              @click="generateTournament"
              :disabled="loadingGenerate || tournamentRounds.length > 0 || registeredParticipants.length < 2 || (registeredParticipants.length >= 5 && registeredParticipants.length < 6)"
            >
              <v-icon left>mdi-trophy-outline</v-icon>
              トーナメントを生成
            </v-btn>
            <v-btn
              color="secondary"
              class="ml-4"
              @click="clearTournament"
              :disabled="tournamentRounds.length === 0"
            >
              <v-icon left>mdi-close</v-icon>
              クリア
            </v-btn>
            <v-btn
              color="success"
              class="ml-4"
              @click="saveBracket"
              :disabled="tournamentRounds.length === 0 || loadingSave"
            >
              <v-icon left>mdi-content-save</v-icon>
              組み合わせを保存
            </v-btn>
            <v-btn
              color="info"
              class="ml-4"
              @click="loadBracket"
              :disabled="loadingLoad || !tournamentId || !categoryId"
            >
              <v-icon left>mdi-folder-open</v-icon>
              組み合わせを読み込み
            </v-btn>
          </v-col>
        </v-row>

        <v-divider class="my-4"></v-divider>
        <h3 class="text-h6 mb-2">生成されたトーナメント表</h3>

        <div v-if="tournamentRounds.length > 0">
          <div class="tournament-bracket-container">
            <div
              v-for="(round, roundIndex) in tournamentRounds"
              :key="`round-${roundIndex}`"
              :class="`tournament-round round-${roundIndex}`"
            >
              <h4 class="round-title">{{ getRoundTitle(roundIndex) }}</h4>
              <div
                v-for="(match, matchIndex) in round.matches"
                :key="`match-${roundIndex}-${matchIndex}`"
                class="tournament-match"
                :class="{ 'final-match': roundIndex === tournamentRounds.length - 1 }"
              >
                <div
                  class="player-slot"
                  :class="{ 'winner': match.winner_id === match.player1_id, 'draggable-player': true }"
                  draggable="true"
                  @dragstart="dragStart($event, roundIndex, matchIndex, 1)"
                  @dragover.prevent="dragOver($event, roundIndex, matchIndex, 1)"
                  @dragleave="dragLeave"
                  @drop="drop($event, roundIndex, matchIndex, 1)"
                  :style="getSlotStyle(roundIndex, matchIndex, 1)"
                >
                  {{ getPlayerFullNameWithBranchAndXclass(match.player1_data) }}
                </div>
                <div class="match-vs">vs</div>
                <div
                  class="player-slot"
                  :class="{ 'winner': match.winner_id === match.player2_id, 'draggable-player': true }"
                  draggable="true"
                  @dragstart="dragStart($event, roundIndex, matchIndex, 2)"
                  @dragover.prevent="dragOver($event, roundIndex, matchIndex, 2)"
                  @dragleave="dragLeave"
                  @drop="drop($event, roundIndex, matchIndex, 2)"
                  :style="getSlotStyle(roundIndex, matchIndex, 2)"
                >
                  {{ getPlayerFullNameWithBranchAndXclass(match.player2_data) }}
                </div>
                <div class="match-details">
                  </div>
              </div>
            </div>
          </div>
        </div>
        <div v-else>
          <p>組み合わせが生成されていません。大会とカテゴリーを選択し、選手が登録されていることを確認してください。</p>
        </div>

      </div>
      <div v-else>
        <p class="text-center mt-5 text-subtitle-1">トーナメント表を生成するには、登録選手が必要です。大会とカテゴリーを選択してください。</p>
      </div>
    </v-card-text>

    </v-card>
</template>

<script>
import { ref, watch } from 'vue';
import axios from 'axios';

export default {
  name: 'BracketView',
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
    const tournamentRounds = ref([]); // トーナメントのラウンドごとの試合
    const playersInTournament = ref([]); // トーナメントに実際に参加する選手（バイ不戦勝処理後）

    const loadingGenerate = ref(false);
    const loadingSave = ref(false);
    const loadingLoad = ref(false);

    // ドラッグ＆ドロップ関連のstate
    const draggedPlayer = ref(null);
    const dropTarget = ref(null);

    // 選手名、支部名、級を結合して表示する関数
    const getPlayerFullNameWithBranchAndXclass = (player) => {
      if (!player) return '未定';
      const fullName = `${player.familyname || ''} ${player.firstname || ''}`;
      const branchPart = player.branch_nm ? `（${player.branch_nm}）` : '';
      const xclassPart = player.xclass ? ` ${player.xclass}` : '';
      return `${fullName}${branchPart}${xclassPart}`;
    };

    // スナックバーの表示を親コンポーネントに依頼
    const showSnackbar = (text, color) => {
      emit('show-snackbar', text, color);
    };

    // トーナメント表を生成する関数
    const generateTournament = () => {
      loadingGenerate.value = true;
      if (props.registeredParticipants.length < 2) {
        showSnackbar('トーナメントを生成するには2名以上の選手が必要です。', 'warning');
        loadingGenerate.value = false;
        return;
      }
      if (props.registeredParticipants.length >= 3 && props.registeredParticipants.length <= 5) {
         showSnackbar('この人数ではトーナメント戦は推奨されません。', 'warning');
      }

      const participants = [...props.registeredParticipants].sort(() => 0.5 - Math.random()); // 選手をシャッフル

      // トーナメントのラウンド数を計算 (2のN乗でなければバイ不戦勝を考慮)
      let numPlayers = participants.length;
      let numRounds = 0;
      let powerOfTwoPlayers = 2;
      while (powerOfTwoPlayers < numPlayers) {
        powerOfTwoPlayers *= 2;
        numRounds++;
      }
      if (numPlayers === 1) { // 1名の場合はバイで直接優勝
        numRounds = 0; // または特別扱い
      } else if (numPlayers >= 2) {
        numRounds = Math.ceil(Math.log2(numPlayers));
      }

      const playersWithBye = []; // バイ不戦勝の選手を記録
      let actualPlayers = [...participants];

      // バイ不戦勝の処理 (2のN乗になるように選手数を調整)
      const nextPowerOfTwo = Math.pow(2, numRounds);
      const byesNeeded = nextPowerOfTwo - numPlayers;

      if (byesNeeded > 0) {
        // バイとなる選手を選出 (例: ランダムまたはシード順)
        // ここでは簡単に最後の選手をバイとする
        const shuffledForBye = [...participants].sort(() => 0.5 - Math.random());
        for (let i = 0; i < byesNeeded; i++) {
          playersWithBye.push(shuffledForBye.pop()); // 後ろからバイ選手を選ぶ
        }
        // バイ選手ではない残りの選手で初期マッチを組む
        actualPlayers = shuffledForBye;
      }

      // 実際の試合組み合わせ
      // バイ不戦勝の選手は次のラウンドに進む
      playersInTournament.value = [...participants]; // 実際に参加する全選手を保存

      let currentRoundPlayers = [...actualPlayers];
      let matches = [];

      // 初期ラウンド（または次のラウンドに進む選手）を構築
      for (let i = 0; i < currentRoundPlayers.length; i += 2) {
          const player1_data = currentRoundPlayers[i];
          const player2_data = currentRoundPlayers[i + 1] || null; // 奇数人数対応
          matches.push({
              match_id: `M1-${i / 2}`,
              player1_id: player1_data?.player_id || null,
              player1_data: player1_data || null,
              player2_id: player2_data?.player_id || null,
              player2_data: player2_data || null,
              winner_id: null,
              status: '未開始'
          });
      }

      // バイで勝ち上がった選手を最初のラウンドの勝者としてシミュレート
      playersWithBye.forEach((player, index) => {
          matches.push({
              match_id: `M1-BYE-${index}`,
              player1_id: player.player_id,
              player1_data: player,
              player2_id: null, // バイの場合は相手がいない
              player2_data: null,
              winner_id: player.player_id, // バイで自動的に勝者
              status: '不戦勝'
          });
      });

      // 試合をシャッフル (任意: 表示順をランダムにする場合)
      matches.sort(() => 0.5 - Math.random());


      tournamentRounds.value = [{ matches: matches }]; // 最初のラウンド

      // 残りのラウンドを生成 (ダミーのマッチを設定)
      let previousRoundMatches = matches;
      for (let r = 1; r < numRounds; r++) {
        const nextRoundMatches = [];
        for (let i = 0; i < previousRoundMatches.length / 2; i++) {
          nextRoundMatches.push({
            match_id: `M${r + 1}-${i}`,
            player1_id: null, player1_data: null, // 前の試合の勝者が入る
            player2_id: null, player2_data: null,
            winner_id: null,
            status: '未開始'
          });
        }
        tournamentRounds.value.push({ matches: nextRoundMatches });
        previousRoundMatches = nextRoundMatches;
      }

      showSnackbar('トーナメント表を生成しました！', 'success');
      loadingGenerate.value = false;
    };

    // トーナメント表をクリアする関数
    const clearTournament = () => {
      tournamentRounds.value = [];
      playersInTournament.value = [];
      showSnackbar('トーナメント表をクリアしました。', 'info');
    };

    // トーナメントデータを保存する関数
    const saveBracket = async () => {
      if (!props.tournamentId || !props.categoryId || tournamentRounds.value.length === 0) {
        showSnackbar('保存する組み合わせがありません。', 'warning');
        return;
      }

      loadingSave.value = true;
      try {
        const payload = {
          tournament_id: props.tournamentId,
          category_id: props.categoryId,
          bracket_data: tournamentRounds.value, // JSオブジェクトとして送信
          player_order: playersInTournament.value // 選手の初期順序も保存
        };

        const response = await axios.post('http://localhost:1880/save-bracket', payload);

        if (response.data.success) {
          showSnackbar('トーナメントデータを保存しました！', 'success');
        } else {
          showSnackbar('保存に失敗しました: ' + (response.data.message || '不明なエラー'), 'error');
        }
      } catch (error) {
        console.error('Failed to save bracket:', error);
        showSnackbar('保存中にエラーが発生しました。サーバーとの接続を確認してください。', 'error');
      } finally {
        loadingSave.value = false;
      }
    };

    // トーナメントデータを読み込む関数
    const loadBracket = async () => {
      if (!props.tournamentId || !props.categoryId) {
        showSnackbar('組み合わせを読み込むには、大会とカテゴリーが必要です。', 'warning');
        return;
      }

      loadingLoad.value = true;
      try {
        const response = await axios.get(`http://localhost:1880/load-bracket/${props.tournamentId}/${props.categoryId}`);

        if (response.data.success) {
          // Node-REDからJSON文字列として受け取ったデータをJSON.parseしてstateに設定
          tournamentRounds.value = JSON.parse(response.data.bracket_data);
          playersInTournament.value = JSON.parse(response.data.player_order);
          showSnackbar('トーナメントデータを読み込みました！', 'success');
        } else {
          // データが見つからない場合も含む
          if (response.status === 404) {
            tournamentRounds.value = []; // データが見つからない場合はクリア
            playersInTournament.value = [];
            showSnackbar(response.data.message || '指定された組み合わせは見つかりませんでした。', 'info');
          } else {
            showSnackbar('読み込みに失敗しました: ' + (response.data.message || '不明なエラー'), 'error');
          }
        }
      } catch (error) {
        console.error('Failed to load bracket:', error);
        if (error.response && error.response.status === 404) {
          tournamentRounds.value = [];
          playersInTournament.value = [];
          showSnackbar(error.response.data.message || '指定された組み合わせは見つかりませんでした。', 'info');
        } else {
          showSnackbar('読み込み中にエラーが発生しました。サーバーとの接続を確認してください。', 'error');
        }
      } finally {
        loadingLoad.value = false;
      }
    };

    // ラウンドタイトルを取得
    const getRoundTitle = (roundIndex) => {
      if (tournamentRounds.value.length === 0) return '';
      const totalRounds = tournamentRounds.value.length;
      if (totalRounds === 1) return '決勝';
      if (roundIndex === totalRounds - 1) return '決勝';
      if (roundIndex === totalRounds - 2 && totalRounds >= 2) return '準決勝';
      if (roundIndex === totalRounds - 3 && totalRounds >= 3) return '準々決勝';
      return `第${roundIndex + 1}ラウンド`;
    };

    // ドラッグ＆ドロップ関連の関数
    const dragStart = (event, roundIndex, matchIndex, playerNum) => {
      const match = tournamentRounds.value[roundIndex].matches[matchIndex];
      draggedPlayer.value = {
        player: playerNum === 1 ? match.player1_data : match.player2_data,
        originalRoundIndex: roundIndex,
        originalMatchIndex: matchIndex,
        originalPlayerNum: playerNum,
      };
      event.dataTransfer.effectAllowed = 'move';
      event.dataTransfer.setData('text/plain', JSON.stringify(draggedPlayer.value));
    };

    const dragOver = (event, roundIndex, matchIndex, playerNum) => {
      event.preventDefault();
      const targetSlot = { roundIndex, matchIndex, playerNum };
      if (draggedPlayer.value && JSON.stringify(draggedPlayer.value) !== JSON.stringify(targetSlot)) {
        dropTarget.value = targetSlot;
      }
    };

    const dragLeave = () => {
      dropTarget.value = null;
    };

    const drop = (event, targetRoundIndex, targetMatchIndex, targetPlayerNum) => {
      event.preventDefault();
      dropTarget.value = null; // ドロップターゲットのハイライトを解除

      if (!draggedPlayer.value) return;

      const dragged = draggedPlayer.value;
      const targetMatch = tournamentRounds.value[targetRoundIndex].matches[targetMatchIndex];

      // 同一スロットへのドロップは無視
      if (dragged.originalRoundIndex === targetRoundIndex &&
          dragged.originalMatchIndex === targetMatchIndex &&
          dragged.originalPlayerNum === targetPlayerNum) {
        draggedPlayer.value = null;
        return;
      }

      // ドロップ先のプレイヤー情報を取得
      const targetPlayer = targetPlayerNum === 1 ? targetMatch.player1_data : targetMatch.player2_data;

      // プレイヤーデータの入れ替え
      // ドラッグ元
      const originalMatch = tournamentRounds.value[dragged.originalRoundIndex].matches[dragged.originalMatchIndex];
      if (dragged.originalPlayerNum === 1) {
        originalMatch.player1_data = targetPlayer;
        originalMatch.player1_id = targetPlayer?.player_id || null;
      } else {
        originalMatch.player2_data = targetPlayer;
        originalMatch.player2_id = targetPlayer?.player_id || null;
      }

      // ドロップ先
      if (targetPlayerNum === 1) {
        targetMatch.player1_data = dragged.player;
        targetMatch.player1_id = dragged.player?.player_id || null;
      } else {
        targetMatch.player2_data = dragged.player;
        targetMatch.player2_id = dragged.player?.player_id || null;
      }

      showSnackbar('選手を入れ替えました！', 'success');
      draggedPlayer.value = null; // ドラッグ状態をクリア
    };

    // ドロップターゲットのスロットにスタイルを適用するためのヘルパー関数
    const getSlotStyle = (roundIndex, matchIndex, playerNum) => {
      if (dropTarget.value &&
          dropTarget.value.roundIndex === roundIndex &&
          dropTarget.value.matchIndex === matchIndex &&
          dropTarget.value.playerNum === playerNum) {
        return {
          border: '2px dashed #1976D2', // Vuetify primary color
          backgroundColor: '#E3F2FD', // Vuetify light blue
        };
      }
      return {};
    };

    // ★親から渡された Props (tournamentId, categoryId) の変更を監視し、データを読み込む
    watch([() => props.tournamentId, () => props.categoryId], ([newTournamentId, newCategoryId]) => {
      if (newTournamentId && newCategoryId) {
        loadBracket(); // 結合された画面で大会/カテゴリが選択されたら自動ロード
      } else {
        // 大会またはカテゴリーがクリアされた場合、トーナメント表もクリア
        tournamentRounds.value = [];
        playersInTournament.value = [];
      }
    }, { immediate: true }); // コンポーネントがマウントされた直後にも実行

    return {
      tournamentRounds,
      playersInTournament,
      loadingGenerate,
      loadingSave,
      loadingLoad,
      generateTournament,
      clearTournament,
      saveBracket,
      loadBracket,
      getPlayerFullNameWithBranchAndXclass,
      getRoundTitle,
      dragStart,
      dragOver,
      dragLeave,
      drop,
      getSlotStyle,
    };
  },
};
</script>

<style scoped>
/* 既存のスタイルをここに貼り付け */
.tournament-bracket-container {
  display: flex;
  flex-wrap: nowrap; /* ラップしない */
  overflow-x: auto; /* 横スクロール可能にする */
  padding: 16px;
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  background-color: #f9f9f9;
}

.tournament-round {
  display: flex;
  flex-direction: column;
  justify-content: space-around; /* 均等に配置 */
  padding: 0 20px;
  min-width: 200px; /* 各ラウンドの最小幅 */
  border-right: 1px solid #cfd8dc;
}

.tournament-round:last-child {
  border-right: none; /* 最後のラウンドは右ボーダーなし */
}

.round-title {
  text-align: center;
  margin-bottom: 20px;
  color: #546e7a;
  font-size: 1rem;
  font-weight: bold;
}

.tournament-match {
  background-color: #ffffff;
  border: 1px solid #b0bec5;
  border-radius: 8px;
  margin-bottom: 30px; /* 試合間のスペース */
  padding: 10px;
  display: flex;
  flex-direction: column;
  align-items: center;
  position: relative;
  min-height: 100px; /* 試合ボックスの最低高さ */
  justify-content: center;
}

/* 試合結果の線（トーナメントの繋がり） */
.tournament-match::after {
  content: '';
  position: absolute;
  right: -20px; /* 次のラウンドへの線の開始位置 */
  top: 50%;
  width: 20px;
  height: 2px;
  background-color: #78909c;
  transform: translateY(-1px);
  z-index: 0;
}

/* 準決勝から決勝への線、または同ラウンド内の繋がり */
.tournament-match:nth-child(odd)::before {
  content: '';
  position: absolute;
  right: -20px; /* 次のラウンドへの線の開始位置 */
  top: calc(50% + 15px); /* 下の試合への接続位置 */
  width: 2px;
  height: calc(100% + 20px); /* 試合間のギャップを考慮した高さ */
  background-color: #78909c;
  transform: translateY(-50%);
  z-index: 0;
}
.tournament-match:nth-child(even)::before {
  content: '';
  position: absolute;
  right: -20px;
  top: calc(50% - 15px);
  width: 2px;
  height: calc(100% + 20px);
  background-color: #78909c;
  transform: translateY(-50%);
  z-index: 0;
}


.player-slot {
  width: 100%;
  text-align: center;
  padding: 5px 8px;
  border-bottom: 1px dashed #e0e0e0;
  cursor: grab; /* ドラッグ可能であることを示すカーソル */
  min-height: 30px; /* スロットの最低高さ */
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: #eceff1;
  border-radius: 4px;
  margin: 2px 0;
  font-size: 0.875rem;
}

.player-slot:last-child {
  border-bottom: none;
}

.player-slot.winner {
  background-color: #c8e6c9; /* 緑色 */
  font-weight: bold;
}

.match-vs {
  font-size: 0.75rem;
  color: #757575;
  margin: 4px 0;
}

.match-details {
  font-size: 0.75rem;
  color: #616161;
  margin-top: 5px;
}

/* 決勝戦は線が不要 */
.final-match::after {
  content: none;
}
.final-match::before {
  content: none;
}

/* ドロップターゲットの視覚的フィードバック */
.player-slot[style*="border-color: rgb(25, 118, 210)"] { /* border-color を Vuetify primary color と一致させる */
  box-shadow: 0 0 0 3px rgba(25, 118, 210, 0.5); /* ホバー時の影 */
}

/* Vuetify のデフォルトsnackbarはコメントアウト */
</style>
<template>
  <v-card class="mx-auto" outlined>
    <v-card-title class="headline">
      トーナメント表
    </v-card-title>
    <v-card-text>
      <div v-if="tournamentId && categoryId">
        <v-divider class="my-4"></v-divider>
        <h3 class="text-h6 mb-4">組み合わせ操作</h3>
        <v-row>
          <v-col cols="12">
            <v-btn
              color="primary"
              @click="generateTournament"
              :disabled="registeredParticipants.length < 2 || loadingGenerate"
            >
              <v-icon left>mdi-tournament</v-icon>
              組み合わせを生成
            </v-btn>
            <v-btn
              color="secondary"
              class="ml-4"
              @click="clearBracket"
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
        <div v-if="tournamentRounds.length > 0" class="bracket-display-area">
          <div class="bracket-container">
            <div
              v-for="(round, roundIndex) in tournamentRounds"
              :key="`round-${roundIndex}`"
              class="bracket-round-container"
            >
              <h4 class="round-title">ラウンド {{ roundIndex + 1 }}</h4>
              <div
                class="bracket-round"
                :style="{ 'margin-top': getRoundMatchesMarginTop(roundIndex) }"
              >
                <div class="round-matches">
                  <div
                    v-for="(match, matchIndex) in round"
                    :key="`round-${roundIndex}-match-${matchIndex}`"
                    class="bracket-match"
                    :class="{
                      'has-line-to-next': roundIndex < tournamentRounds.length - 1 && matchIndex % 2 === 0 && round[matchIndex + 1]
                    }"
                    :style="{
                      'margin-bottom': calculateMatchMarginBottom(roundIndex, matchIndex, round.length),
                      '--z-line-vertical-segment-height': getZLineVerticalSegmentHeight(roundIndex) + 'px'
                    }"
                  >
                    <div
                      class="player-slot"
                      :draggable="roundIndex === 0 && !match.player1?.isWinnerPlaceholder && !match.player1?.isBye"
                      @dragstart="dragStart($event, roundIndex, matchIndex, 'player1', match.player1)"
                      @dragover.prevent="dragOver($event, roundIndex, matchIndex, 'player1')"
                      @dragleave="dragLeave"
                      @drop="drop($event, roundIndex, matchIndex, 'player1')"
                      :class="{
                        'player-blue': match.player1 && !match.player1.isBye && !match.player1.isWinnerPlaceholder,
                        'player-white': match.player1 && match.player1.isBye,
                        'player-placeholder': match.player1 && match.player1.isWinnerPlaceholder,
                        'drag-over-target': isDragOverTarget(roundIndex, matchIndex, 'player1')
                      }"
                    >
                      <template v-if="match.player1">
                        <template v-if="match.player1.isWinnerPlaceholder">
                          {{ `勝者: ${match.player1.winnerOf}` }}
                        </template>
                        <template v-else-if="match.player1.isBye">
                          BYE
                        </template>
                        <template v-else>
                          {{ getPlayerFullNameWithBranchAndXclass(match.player1) }}
                        </template>
                      </template>
                      <template v-else>
                        未定
                      </template>
                    </div>

                    <div class="vs-text">VS</div>

                    <div
                      class="player-slot"
                      :draggable="roundIndex === 0 && !match.player2?.isWinnerPlaceholder && !match.player2?.isBye"
                      @dragstart="dragStart($event, roundIndex, matchIndex, 'player2', match.player2)"
                      @dragover.prevent="dragOver($event, roundIndex, matchIndex, 'player2')"
                      @dragleave="dragLeave"
                      @drop="drop($event, roundIndex, matchIndex, 'player2')"
                      :class="{
                        'player-white': match.player2 && !match.player2.isWinnerPlaceholder,
                        'player-placeholder': match.player2 && match.player2.isWinnerPlaceholder,
                        'drag-over-target': isDragOverTarget(roundIndex, matchIndex, 'player2')
                      }"
                    >
                      <template v-if="match.player2">
                        <template v-if="match.player2.isWinnerPlaceholder">
                          {{ `勝者: ${match.player2.winnerOf}` }}
                        </template>
                        <template v-else-if="match.player2.isBye">
                          BYE
                        </template>
                        <template v-else>
                          {{ getPlayerFullNameWithBranchAndXclass(match.player2) }}
                        </template>
                      </template>
                      <template v-else>
                        未定
                      </template>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div v-if="finalWinner && tournamentRounds.length > 0" class="bracket-round-container final-winner-container">
              <h4 class="round-title">優勝</h4>
              <div
                class="bracket-round"
                :style="{ 'margin-top': getFinalWinnerMatchesMarginTop() }"
              >
                <div class="round-matches">
                  <div class="bracket-match">
                    <div class="player-slot player-gold">
                      {{ getPlayerFullNameWithBranchAndXclass(finalWinner) }}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
        <div v-else>
          <p>組み合わせが生成されていません。大会とカテゴリーを選択し、選手が2名以上登録されていることを確認してください。</p>
        </div>
      </div>
      <div v-else>
        <p class="text-center mt-5 text-subtitle-1">トーナメントを生成するには、登録選手が必要です。大会とカテゴリーを選択してください。</p>
      </div>
    </v-card-text>

    </v-card>
</template>

<script>
import { ref, watch } from 'vue';
import axios from 'axios';

export default {
  name: 'BracketView',
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
    // 親から渡される既存の組み合わせデータ
    existingData: {
      type: Object, // tournament_brackets テーブルのレコード全体が来る
      default: null,
    },
  },
  emits: ['show-snackbar'],
  setup(props, { emit }) {
    const tournamentRounds = ref([]);
    const finalWinner = ref(null);

    const loadingGenerate = ref(false);
    const loadingSave = ref(false);
    const loadingLoad = ref(false); // loadingLoad も残す

    // ドラッグ＆ドロップ関連のstate
    const draggedItem = ref(null);
    const dropTarget = ref(null);

    let globalMatchIdCounter = 0;

    // 定数（CSS変数と同期させる）
    const PLAYER_SLOT_HEIGHT = 40;
    const VS_TEXT_HEIGHT = 18;
    const MATCH_PADDING_VERTICAL = 8;
    const MATCH_BORDER_WIDTH = 1;
    const MATCH_BOX_HEIGHT = (PLAYER_SLOT_HEIGHT * 2) + VS_TEXT_HEIGHT + (MATCH_PADDING_VERTICAL * 2) + (MATCH_BORDER_WIDTH * 2) + 5; // 121px
    const BASE_MATCH_VERTICAL_SPACING = 30;
    const TOTAL_MATCH_UNIT_HEIGHT = MATCH_BOX_HEIGHT + BASE_MATCH_VERTICAL_SPACING; // 121 + 30 = 151px

    const getPlayerFullNameWithBranchAndXclass = (player) => {
      if (!player) return '未定';
      const fullName = `${player.familyname || ''} ${player.firstname || ''}`;
      const branchPart = player.branch_nm ? `（${player.branch_nm}）` : '';
      const xclassPart = player.xclass ? ` ${player.xclass}` : '';
      return `${fullName}${branchPart}${xclassPart}`;

    };

    const showSnackbar = (text, color) => {
      emit('show-snackbar', text, color);
    };

    const generateTournament = () => {
      loadingGenerate.value = true;
      tournamentRounds.value = [];
      finalWinner.value = null;
      globalMatchIdCounter = 0;

      if (props.registeredParticipants.length < 2) {
        showSnackbar('組み合わせを生成するには2名以上の選手が必要です。', 'warning');
        loadingGenerate.value = false;
        return;
      }

      let currentRoundParticipants = [...props.registeredParticipants];
      currentRoundParticipants.sort(() => 0.5 - Math.random());

      let roundNumber = 1;

      while (currentRoundParticipants.length > 1) {
        const currentRoundMatches = [];
        const nextRoundAdvancingPlayers = [];

        let currentRoundBracketSize = 1;
        while (currentRoundBracketSize < currentRoundParticipants.length) {
          currentRoundBracketSize *= 2;
        }
        const numByes = currentRoundBracketSize - currentRoundParticipants.length;

        const playersWithBye = currentRoundParticipants.slice(0, numByes);
        const playersPlaying = currentRoundParticipants.slice(numByes);

        playersWithBye.forEach(player => {
          globalMatchIdCounter++;
          const matchId = `R${roundNumber}-M${globalMatchIdCounter}`;
          currentRoundMatches.push({
            player1: player,
            player2: { id: `BYE_${matchId}`, name: 'BYE', isBye: true },
            matchId: matchId
          });
          nextRoundAdvancingPlayers.push(player);
        });

        for (let i = 0; i < playersPlaying.length; i += 2) {
          globalMatchIdCounter++;
          const matchId = `R${roundNumber}-M${globalMatchIdCounter}`;
          currentRoundMatches.push({
            player1: playersPlaying[i],
            player2: playersPlaying[i + 1],
            matchId: matchId
          });
          nextRoundAdvancingPlayers.push({ isWinnerPlaceholder: true, winnerOf: matchId });
        }

        tournamentRounds.value.push(currentRoundMatches);

        currentRoundParticipants = nextRoundAdvancingPlayers;
        roundNumber++;
      }

      if (currentRoundParticipants.length === 1) {
        finalWinner.value = currentRoundParticipants[0];
      } else {
        finalWinner.value = null;
      }

      showSnackbar('組み合わせを生成しました！', 'success');
      loadingGenerate.value = false;
    };

    const recalculateSubsequentRounds = () => {
      if (tournamentRounds.value.length === 0) {
        return;
      }

      let currentRoundParticipants = [];
      tournamentRounds.value[0].forEach(match => {
        if (match.player1 && match.player1.isBye) {
          currentRoundParticipants.push(match.player2);
        } else if (match.player2 && match.player2.isBye) {
          currentRoundParticipants.push(match.player1);
        } else {
          currentRoundParticipants.push({ isWinnerPlaceholder: true, winnerOf: match.matchId });
        }
      });

      tournamentRounds.value.splice(1);
      finalWinner.value = null;

      let maxMatchIdInRound1 = 0;
      tournamentRounds.value[0].forEach(match => {
        const matchNum = parseInt(match.matchId.split('-M')[1]);
        if (!isNaN(matchNum) && matchNum > maxMatchIdInRound1) {
          maxMatchIdInRound1 = matchNum;
        }
      });
      globalMatchIdCounter = maxMatchIdInRound1;

      let roundNumber = 2;

      while (currentRoundParticipants.length > 1) {
        const nextRoundMatches = [];
        const nextRoundAdvancingPlayers = [];

        let currentRoundBracketSize = 1;
        while (currentRoundBracketSize < currentRoundParticipants.length) {
          currentRoundBracketSize *= 2;
        }
        const numByes = currentRoundBracketSize - currentRoundParticipants.length;

        const playersWithBye = currentRoundParticipants.slice(0, numByes);
        const playersPlaying = currentRoundParticipants.slice(numByes);

        playersWithBye.forEach(player => {
          nextRoundAdvancingPlayers.push(player);
        });

        for (let i = 0; i < playersPlaying.length; i += 2) {
          globalMatchIdCounter++;
          const matchId = `R${roundNumber}-M${globalMatchIdCounter}`;
          nextRoundMatches.push({
            player1: playersPlaying[i],
            player2: playersPlaying[i + 1],
            matchId: matchId
          });
          nextRoundAdvancingPlayers.push({ isWinnerPlaceholder: true, winnerOf: matchId });
        }

        if (nextRoundMatches.length > 0) {
          tournamentRounds.value.push(nextRoundMatches);
        }

        currentRoundParticipants = nextRoundAdvancingPlayers;
        roundNumber++;
      }

      if (currentRoundParticipants.length === 1) {
        finalWinner.value = currentRoundParticipants[0];
      } else {
        finalWinner.value = null;
      }
    };

    const clearBracket = () => {
      tournamentRounds.value = [];
      finalWinner.value = null;
      globalMatchIdCounter = 0;
      showSnackbar('トーナメント表をクリアしました。', 'info');
    };

    const saveBracket = async () => {
      if (!props.tournamentId || !props.categoryId || tournamentRounds.value.length === 0) {
        showSnackbar('保存する組み合わせがありません。大会、カテゴリーを選択し、組み合わせを生成してください。', 'warning');
        return;
      }

      loadingSave.value = true;
      try {
        const bracketId = crypto.randomUUID();

        const payload = {
          bracket_id: bracketId,
          tournament_id: props.tournamentId,
          category_id: props.categoryId,
          bracket_data: JSON.stringify(tournamentRounds.value),
          final_winner_data: finalWinner.value ? JSON.stringify(finalWinner.value) : null,
        };

        const response = await axios.post('http://localhost:1880/save-bracket', payload);

        if (response.data.success) {
          showSnackbar('トーナメント組み合わせを保存しました！', 'success');
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

    // loadBracket 関数を復活させ、ボタンクリックで呼び出せるようにする
    const loadBracket = async () => {
      if (!props.tournamentId || !props.categoryId) {
        showSnackbar('組み合わせを読み込むには、大会とカテゴリーを選択してください。', 'warning');
        return;
      }

      loadingLoad.value = true;
      try {
        const response = await axios.get(`http://localhost:1880/load-bracket/${props.tournamentId}/${props.categoryId}`);

        if (response.data.success) {
          tournamentRounds.value = JSON.parse(response.data.bracket_data);
          finalWinner.value = response.data.final_winner_data ? JSON.parse(response.data.final_winner_data) : null;
          showSnackbar('トーナメント組み合わせを読み込みました！', 'success');
        } else {
          if (response.status === 404) {
            tournamentRounds.value = [];
            finalWinner.value = null;
            showSnackbar(response.data.message || '指定された組み合わせは見つかりませんでした。', 'info');
          } else {
            showSnackbar('読み込みに失敗しました: ' + (response.data.message || '不明なエラー'), 'error');
          }
        }
      } catch (error) {
        console.error('Failed to load bracket:', error);
        if (error.response && error.response.status === 404) {
          tournamentRounds.value = [];
          finalWinner.value = null;
          showSnackbar(error.response.data.message || '指定された組み合わせは見つかりませんでした。', 'info');
        } else {
          showSnackbar('読み込み中にエラーが発生しました。サーバーとの接続を確認してください。', 'error');
        }
      } finally {
        loadingLoad.value = false;
      }
    };

    // 親から渡される existingData を監視し、tournamentRounds を初期化する
    // この watch は、ComponentCreatorView からデータが渡された時に「初期表示」または「自動更新」を行う
    // loadBracket ボタンはユーザーが明示的に再読み込みしたい場合に使う
    watch(() => props.existingData, (newData) => {
      if (newData && newData.bracket_data) {
        try {
          let parsedBracketData;
          // newData.bracket_data が文字列かどうかをチェック
          if (typeof newData.bracket_data === 'string') {
            parsedBracketData = JSON.parse(newData.bracket_data);
          } else {
            // 文字列でなければ、既にパース済みのオブジェクトとして扱う
            parsedBracketData = newData.bracket_data;
          }

          let parsedFinalWinnerData = null;
          if (newData.final_winner_data) {
            if (typeof newData.final_winner_data === 'string') {
              parsedFinalWinnerData = JSON.parse(newData.final_winner_data);
            } else {
              parsedFinalWinnerData = newData.final_winner_data;
            }
          }

          tournamentRounds.value = parsedBracketData;
          finalWinner.value = parsedFinalWinnerData;
          // showSnackbar('既存のトーナメント組み合わせを自動読み込みしました！', 'info'); // 自動読み込み時のスナックバーは控えめにするか、出さない
        } catch (e) {
          console.error("Failed to parse existing bracket data from props:", e);
          showSnackbar('既存のトーナメントデータの解析に失敗しました。', 'error');
          clearBracket(); // パース失敗時はクリア
        }
      } else {
        // existingDataがない、またはbracket_dataがない場合
        clearBracket();
      }
    }, { immediate: true });

    // CSS計算関数
    const getRoundMatchesMarginTop = (roundIndex) => {
      if (roundIndex === 0) return '0px';

      let currentRoundFirstMatchCenterY = MATCH_BOX_HEIGHT / 2;

      for (let i = 0; i < roundIndex; i++) {
        currentRoundFirstMatchCenterY += (TOTAL_MATCH_UNIT_HEIGHT * Math.pow(2, i)) / 2;
      }

      return `${currentRoundFirstMatchCenterY - MATCH_BOX_HEIGHT / 2}px`;
    };

    const calculateMatchMarginBottom = (roundIndex, matchIndex, totalMatchesInRound) => {
      if (roundIndex === tournamentRounds.value.length - 1) {
        return '0px';
      }
      if (matchIndex === totalMatchesInRound - 1) {
        return '0px';
      }

      const verticalSpanOfBlock = TOTAL_MATCH_UNIT_HEIGHT * Math.pow(2, roundIndex);
      const requiredMargin = verticalSpanOfBlock - MATCH_BOX_HEIGHT;

      return `${requiredMargin}px`;
    };

    const getZLineVerticalSegmentHeight = (roundIndex) => {
      return TOTAL_MATCH_UNIT_HEIGHT * Math.pow(2, roundIndex);
    };

    const getFinalWinnerMatchesMarginTop = () => {
      if (tournamentRounds.value.length === 0) return '0px';
      const lastRoundIndex = tournamentRounds.value.length - 1;
      return getRoundMatchesMarginTop(lastRoundIndex);
    };

    // ドラッグ＆ドロップ関連の関数
    const dragStart = (event, rIdx, mIdx, sType, player) => {
      if (rIdx !== 0 || player?.isWinnerPlaceholder || player?.isBye) {
        event.preventDefault();
        return;
      }
      draggedItem.value = { rIdx, mIdx, sType, player };
      event.dataTransfer.effectAllowed = 'move';
      event.dataTransfer.setData('application/json', JSON.stringify({ rIdx, mIdx, sType }));
    };

    const dragOver = (event, rIdx, mIdx, sType) => {
      if (rIdx !== 0 || tournamentRounds.value[rIdx][mIdx][sType]?.isWinnerPlaceholder) {
        return;
      }
      event.preventDefault();
      dropTarget.value = { rIdx, mIdx, sType };
    };

    const dragLeave = () => {
      dropTarget.value = null;
    };

    const drop = (event, targetRIdx, targetMIdx, targetSType) => {
      if (targetRIdx !== 0 || tournamentRounds.value[targetRIdx][targetMIdx][targetSType]?.isWinnerPlaceholder) {
        return;
      }
      event.preventDefault();
      dropTarget.value = null;

      if (!draggedItem.value) {
        return;
      }

      const sourceRIdx = draggedItem.value.rIdx;
      const sourceMIdx = draggedItem.value.mIdx;
      const sourceSType = draggedItem.value.sType;
      const sourcePlayer = draggedItem.value.player;

      if (sourceRIdx === targetRIdx && sourceMIdx === targetMIdx && sourceSType === targetSType) {
        draggedItem.value = null;
        return;
      }

      const targetPlayer = tournamentRounds.value[targetRIdx][targetMIdx][targetSType];

      if (sourcePlayer?.isBye || targetPlayer?.isBye) {
        showSnackbar('BYEの選手は入れ替えできません。', 'warning');
        draggedItem.value = null;
        return;
      }

      tournamentRounds.value[sourceRIdx][sourceMIdx][sourceSType] = targetPlayer;
      tournamentRounds.value[targetRIdx][targetMIdx][targetSType] = sourcePlayer;

      draggedItem.value = null;

      recalculateSubsequentRounds(); // 入れ替え後にラウンド2以降を再計算
      showSnackbar('選手を入れ替えました！トーナメント表を更新しました！', 'success');
    };

    const isDragOverTarget = (rIdx, mIdx, sType) => {
      return dropTarget.value && dropTarget.value.rIdx === rIdx && dropTarget.value.mIdx === mIdx && dropTarget.value.sType === sType;
    };

    return {
      tournamentRounds,
      finalWinner,
      loadingGenerate,
      loadingSave,
      loadingLoad,
      generateTournament,
      clearBracket,
      saveBracket,
      loadBracket,
      getPlayerFullNameWithBranchAndXclass,
      getRoundMatchesMarginTop,
      calculateMatchMarginBottom,
      getZLineVerticalSegmentHeight,
      getFinalWinnerMatchesMarginTop,
      dragStart,
      dragOver,
      dragLeave,
      drop,
      isDragOverTarget,
    };
  },
};
</script>


<style scoped>
/* CSS変数を定義して、調整しやすくする */
.bracket-container {
  /* ここにCSS変数を定義 */
  --player-slot-height: 40px; /* 選手名スロットのおおよその高さ */
  --vs-text-height: 18px; /* VSテキストのおおよその高さ */
  --match-padding-vertical: 8px; /* 試合ボックスの上下パディング */
  --match-border-width: 1px; /* 試合ボックスのボーダー幅 */
  /* 試合ボックス全体の高さ (選手スロット2つ + VSテキスト + パディング + ボーダー + 微調整) */
  --match-box-height: calc(var(--player-slot-height) * 2 + var(--vs-text-height) + var(--match-padding-vertical) * 2 + var(--match-border-width) * 2 + 5px); /* 121px */
  
  /* ラウンド間の水平方向のギャップ */
  --round-horizontal-gap: 75px;

  --line-color: #757575; /* 線の色 */
  
  /* 各水平線セグメントの長さ (ラウンド間のギャップの半分) */
  --line-segment-length: calc(var(--round-horizontal-gap) / 2); 

  /* 以下は既存の .bracket-container スタイル */
  display: flex;
  flex-direction: row; /* ラウンドを横に並べる */
  gap: var(--round-horizontal-gap); /* ラウンド間の水平ギャップ */
  padding: 20px;
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  background-color: #f9f9f9;
  min-width: fit-content; /* コンテンツの幅に合わせて広がる */
  align-items: flex-start; /* 各ラウンドを上揃えにする */
}

.bracket-display-area {
  overflow-x: auto; /* 横スクロールを可能にする */
  padding-bottom: 20px; /* スクロールバーのための余白 */
}

/* 新しいラッパーコンテナ */
.bracket-round-container {
  display: flex;
  flex-direction: column;
  align-items: center; /* タイトルと試合ブロックを中央揃え */
  flex-shrink: 0; /* 縮まないようにする */
  position: relative; /* 線の描画のために必要 */
}

.round-title {
  margin-bottom: 15px; /* タイトルと試合ブロックの間のスペース */
  font-size: 1.1em;
  color: #3f51b5; /* Primary color */
  border-bottom: 2px solid #3f51b5;
  padding-bottom: 5px;
  width: 100%;
  text-align: center;
}

/* bracket-round は now 試合ブロックのコンテナ */
.bracket-round {
  display: flex;
  flex-direction: column;
  align-items: center;
  position: relative; /* 線の描画のために必要 */
  /* margin-top は Vue の v-bind:style で動的に設定される */
}

.round-matches {
  display: flex;
  flex-direction: column;
  position: relative; /* 接続線のために必要 */
}

.bracket-match {
  display: flex;
  flex-direction: column; /* 選手名を縦並びにする */
  align-items: center; /* 中央揃え */
  justify-content: center;
  gap: 5px; /* 選手名とVSの間のスペースを調整 */
  padding: var(--match-padding-vertical) 12px;
  border: var(--match-border-width) solid #cfd8dc;
  border-radius: 4px;
  background-color: #EEEEEE; /* 試合枠の背景色を薄いグレーに変更 */
  box-shadow: 0 2px 4px rgba(0,0,0,0.05);
  min-width: 180px; /* 試合ボックスの最小幅を調整 */
  position: relative;
  z-index: 10; /* 線の上に表示されるように、z-indexを高く設定 */
  height: var(--match-box-height); /* 固定高さでレイアウトの一貫性を確保 */
  box-sizing: border-box; /* paddingとborderを高さに含める */
  /* margin-bottom は Vue の v-bind:style で動的に設定されるため、ここからは削除 */
}

.player-slot {
  width: 100%; /* 親要素の幅いっぱいに広げる */
  padding: 4px 8px;
  border-radius: 3px;
  font-weight: bold;
  text-align: center; /* テキストを中央揃え */
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  font-size: 0.9em;
  height: var(--player-slot-height); /* 選手スロットの固定高さ */
  display: flex; /* テキストの垂直方向中央揃え用 */
  align-items: center;
  justify-content: center;
}

/* ドラッグ可能な選手スロットのスタイル */
.player-slot[draggable="true"] {
  cursor: grab; /* ドラッグできることを示すカーソル */
}

.player-slot[draggable="true"]:active {
  cursor: grabbing; /* ドラッグ中のカーソル */
}

/* ドロップターゲットになったときの視覚的フィードバック */
.player-slot.drag-over-target {
  border: 2px dashed #3f51b5; /* ドロップ可能な場所を点線でハイライト */
  background-color: #bbdefb; /* 背景色を少し明るい青に */
}

.player-blue {
  background-color: #e3f2fd; /* Light blue */
  color: #1565c0; /* Darker blue */
  border: 1px solid #90caf9;
}

.player-white {
  background-color: #FFFFFF; /* 純粋な白に変更 */
  color: #212121; /* 黒に近いグレーで視認性を確保 */
  border: 1px solid #bdbdbd; /* ライトグレーのボーダー */
}

/* 勝者プレースホルダーのスタイル */
.player-placeholder {
  background-color: #f0f0f0; /* 薄いグレー */
  color: #616161; /* 暗めのグレー */
  border: 1px solid #bdbdbd; /* player-whiteと同じボーダー */
}

.player-gold { /* 優勝者用の新しいスタイル */
  background-color: #FFD700; /* Gold */
  color: #333333;
  border: 1px solid #DAA520;
}

.vs-text {
  font-weight: bold;
  color: #757575;
  font-size: 0.9em;
  margin: 2px 0; /* VSテキストの上下の余白 */
}

/* --- 線の描画 --- */

/* 偶数番目ではない試合（ペアの下側や、ラウンドの最後の試合）に適用される水平線 */
.bracket-match:not(.has-line-to-next)::after {
  content: '';
  position: absolute;
  left: 100%; /* 親要素の右端に::afterの左端を合わせる */
  top: 50%; /* ::after要素の上端を、親要素の垂直方向中央に揃える */
  transform: translateY(-0.5px); /* 1pxの線の厚さを考慮して正確に中央に配置 */
  width: var(--line-segment-length);
  height: 1px;
  background-color: var(--line-color);
  z-index: 0;
  pointer-events: none; /* クリックイベントをブロックしないようにする */
}

/* 偶数番目の試合（ペアの上側）に適用されるZ字型の線 */
.bracket-match.has-line-to-next::after {
  content: '';
  position: absolute;
  left: 100%; /* 親要素の右端に::afterの左端を合わせる */
  top: 50%; /* ::after要素の上端を、親要素の垂直方向中央に揃える */
  transform: translateY(-0.5px); /* 1pxの線の厚さを考慮して正確に中央に配置 */
  /* ::after要素の幅は、2つの水平線セグメントを合わせたもの */
  width: calc(var(--line-segment-length) * 2);
  /* ::after要素の高さは、垂直線セグメントの高さ */
  height: var(--z-line-vertical-segment-height); /* JSから渡されるCSS変数を使用 */
  z-index: 0;
  pointer-events: none;

  background:
    /* 1. 最初の水平線 (試合ボックスの中心から伸びる) */
    linear-gradient(to right, var(--line-color) 0%, var(--line-color) 100%)
    0 /* X開始位置: ::after要素の左端 (これが試合ボックスの右端) */
    0px /* Y開始位置: ::after要素の上端 (これが試合ボックスの垂直方向中央) */
    / var(--line-segment-length) 1px /* サイズ: 最初の水平線の長さ, 1pxの太さ */
    no-repeat,

    /* 2. 垂直線 (試合ボックスの中心から、次の試合の中心まで) */
    linear-gradient(to bottom, var(--line-color) 0%, var(--line-color) 100%)
    var(--line-segment-length) /* X開始位置: 最初の水平線の終点 */
    0px /* Y開始位置: 垂直線の開始Y座標 (::afterの上端) */
    / 1px var(--z-line-vertical-segment-height) /* サイズ: 1px幅, 垂直線の長さ (::afterの全高) */
    no-repeat,

    /* 3. 2番目の水平線 (垂直線の終点から次のラウンドへ) */
    linear-gradient(to right, var(--line-color) 0%, var(--line-color) 100%)
    var(--line-segment-length) /* X開始位置: 垂直線の開始X座標 */
    calc(var(--z-line-vertical-segment-height) / 2 - 0.5px) /* Y開始位置: ::after要素の高さの半分 */
    / var(--line-segment-length) 1px /* サイズ: 2番目の水平線の長さ, 1pxの太さ */
    no-repeat;
}

/* 最終的な勝者ボックスの左側から伸びる水平線 */
.final-winner-container .bracket-match::before {
  content: '';
  position: absolute;
  right: 100%; /* 親要素の左端に::beforeの右端を合わせる */
  top: 50%;
  transform: translateY(-0.5px); /* 1pxの線の厚さを考慮して正確に中央に配置 */
  width: var(--line-segment-length); /* 新しい変数を使用 */
  height: 1px;
  background-color: var(--line-color);
  z-index: 0;
  pointer-events: none; /* クリックイベントをブロックしないようにする */
}
</style>
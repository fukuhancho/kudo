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
                    <!-- 試合スケジュール入力欄: BYE選手を含む試合では非表示にする -->
                    <div v-if="match && !isByeMatch(match)" class="match-schedule-inputs-top-right">
                      <!-- コート選択 (標準HTML select) -->
                      <select
                        v-model="match.court_id"
                        @change="updateMatchSchedule(roundIndex, matchIndex, 'court', $event.target.value)"
                        class="custom-input court-select"
                      >
                        <option value="" disabled selected>コート</option>
                        <option v-for="courtOption in availableCourtOptions" :key="courtOption" :value="courtOption">
                          {{ courtOption }}
                        </option>
                      </select>
                      <!-- 試合順入力 (標準HTML input type="number") -->
                      <input
                        type="number"
                        v-model.number="match.match_order_no"
                        @input="updateMatchSchedule(roundIndex, matchIndex, 'order', $event.target.value)"
                        min="1"
                        placeholder="No."
                        class="custom-input match-order-input"
                      />
                    </div>

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
import { ref, watch, computed } from 'vue';
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
    existingData: {
      type: Object,
      default: null,
    },
    numberOfCourts: {
      type: Number,
      default: 0,
    }
  },
  emits: ['show-snackbar'], // 明示的にemitsを宣言
  setup(props, { emit }) {
    const tournamentRounds = ref([]);
    const finalWinner = ref(null);

    const loadingGenerate = ref(false);
    const loadingSave = ref(false);
    const loadingLoad = ref(false);

    const draggedItem = ref(null);
    const dropTarget = ref(null);

    let globalMatchIdCounter = 0;

    const PLAYER_SLOT_HEIGHT = 40;
    const VS_TEXT_HEIGHT = 18;
    const MATCH_PADDING_VERTICAL = 8;
    const MATCH_BORDER_WIDTH = 1;
    const MATCH_BOX_HEIGHT = (PLAYER_SLOT_HEIGHT * 2) + VS_TEXT_HEIGHT + (MATCH_PADDING_VERTICAL * 2) + (MATCH_BORDER_WIDTH * 2) + 5;
    const BASE_MATCH_VERTICAL_SPACING = 30;
    const TOTAL_MATCH_UNIT_HEIGHT = MATCH_BOX_HEIGHT + BASE_MATCH_VERTICAL_SPACING;

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

    // BYE選手を判定するヘルパー関数
    const isByeMatch = (match) => {
      const player1 = match.player1;
      const player2 = match.player2;
      // playerオブジェクトにisByeプロパティがあるか、またはnameが"BYE"の場合にBYEと判定
      const isPlayer1Bye = player1 && (player1.isBye === true || player1.name === 'BYE');
      const isPlayer2Bye = player2 && (player2.isBye === true || player2.name === 'BYE');
      return isPlayer1Bye || isPlayer2Bye;
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
            matchId: matchId,
            court_id: null, // BYE試合なのでコート・試合順はnullのまま
            match_order_no: null // BYE試合なのでコート・試合順はnullのまま
          });
          nextRoundAdvancingPlayers.push(player); // BYEの相手は次のラウンドに進む
        });

        for (let i = 0; i < playersPlaying.length; i += 2) {
          globalMatchIdCounter++;
          const matchId = `R${roundNumber}-M${globalMatchIdCounter}`;
          currentRoundMatches.push({
            player1: playersPlaying[i],
            player2: playersPlaying[i + 1],
            matchId: matchId,
            court_id: null,
            match_order_no: null
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
        // BYE試合の場合は、BYEではないプレイヤーを次のラウンドに進める
        if (match.player1 && match.player1.isBye) {
          currentRoundParticipants.push(match.player2);
        } else if (match.player2 && match.player2.isBye) {
          currentRoundParticipants.push(match.player1);
        } else {
          // 通常の試合は勝者プレースホルダーを次のラウンドに進める
          currentRoundParticipants.push({ isWinnerPlaceholder: true, winnerOf: match.matchId });
        }
      });

      tournamentRounds.value.splice(1); // ラウンド2以降をクリア
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
            matchId: matchId,
            court_id: null,
            match_order_no: null
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
          // BYE試合を除外して保存するために、保存前にフィルタリング
          bracket_data: JSON.stringify(tournamentRounds.value.map(round =>
            round.filter(match => !isByeMatch(match))
          )),
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

    const loadBracket = async () => {
      if (!props.tournamentId || !props.categoryId) {
        showSnackbar('組み合わせを読み込むには、大会とカテゴリーを選択してください。', 'warning');
        return;
      }

      loadingLoad.value = true;
      try {
        const response = await axios.get(`http://localhost:1880/load-bracket/${props.tournamentId}/${props.categoryId}`);

        if (response.data.success) {
          const loadedRounds = JSON.parse(response.data.bracket_data);
          loadedRounds.forEach(round => {
            round.forEach(match => {
              if (!('court_id' in match)) match.court_id = null;
              if (!('match_order_no' in match)) match.match_order_no = null;
            });
          });
          tournamentRounds.value = loadedRounds;
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

    watch(() => props.existingData, (newData) => {
      if (newData && newData.bracket_data) {
        try {
          let parsedBracketData;
          if (typeof newData.bracket_data === 'string') {
            parsedBracketData = JSON.parse(newData.bracket_data);
          } else {
            parsedBracketData = newData.bracket_data;
          }

          parsedBracketData.forEach(round => {
            round.forEach(match => {
              if (!('court_id' in match)) match.court_id = null;
              if (!('match_order_no' in match)) match.match_order_no = null;
            });
          });

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
        } catch (e) {
          console.error("Failed to parse existing bracket data from props:", e);
          showSnackbar('既存のトーナメントデータの解析に失敗しました。', 'error');
          clearBracket();
        }
      } else {
        clearBracket();
      }
    }, { immediate: true });

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

    const dragStart = (event, rIdx, mIdx, sType, player) => {
      if (rIdx !== 0 || player?.isWinnerPlaceholder || isByeMatch({player1: player, player2: null})) { // BYE選手はドラッグ不可
        event.preventDefault();
        return;
      }
      draggedItem.value = { rIdx, mIdx, sType, player };
      event.dataTransfer.effectAllowed = 'move';
      event.dataTransfer.setData('application/json', JSON.stringify({ rIdx, mIdx, sType }));
    };

    const dragOver = (event, rIdx, mIdx, sType) => {
      if (rIdx !== 0 || tournamentRounds.value[rIdx][mIdx][sType]?.isWinnerPlaceholder || isByeMatch({player1: tournamentRounds.value[rIdx][mIdx][sType], player2: null})) { // BYE選手へのドロップ不可
        return;
      }
      event.preventDefault();
      dropTarget.value = { rIdx, mIdx, sType };
    };

    const dragLeave = () => {
      dropTarget.value = null;
    };

    const drop = (event, targetRIdx, targetMIdx, targetSType) => {
      if (targetRIdx !== 0 || tournamentRounds.value[targetRIdx][targetMIdx][targetSType]?.isWinnerPlaceholder || isByeMatch({player1: tournamentRounds.value[targetRIdx][targetMIdx][targetSType], player2: null})) { // BYE選手へのドロップ不可
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

      // BYE選手が含まれる場合は入れ替え不可
      if (isByeMatch({player1: sourcePlayer, player2: targetPlayer})) {
        showSnackbar('BYEの選手が含まれる場合は入れ替えできません。', 'warning');
        draggedItem.value = null;
        return;
      }

      tournamentRounds.value[sourceRIdx][sourceMIdx][sourceSType] = targetPlayer;
      tournamentRounds.value[targetRIdx][targetMIdx][targetSType] = sourcePlayer;

      draggedItem.value = null;

      recalculateSubsequentRounds();
      showSnackbar('選手を入れ替えました！トーナメント表を更新しました！', 'success');
    };

    const isDragOverTarget = (rIdx, mIdx, sType) => {
      return dropTarget.value && dropTarget.value.rIdx === rIdx && dropTarget.value.mIdx === mIdx && dropTarget.value.sType === sType;
    };

    const updateMatchSchedule = (roundIndex, matchIndex, type, value) => {
      if (tournamentRounds.value[roundIndex] && tournamentRounds.value[roundIndex][matchIndex]) {
        if (type === 'court') {
          tournamentRounds.value[roundIndex][matchIndex].court_id = value;
        } else if (type === 'order') {
          tournamentRounds.value[roundIndex][matchIndex].match_order_no = value === '' ? null : parseInt(value, 10);
          if (isNaN(tournamentRounds.value[roundIndex][matchIndex].match_order_no)) {
            tournamentRounds.value[roundIndex][matchIndex].match_order_no = null;
          }
        }
      }
    };

    const availableCourtOptions = computed(() => {
      const courts = [];
      for (let i = 0; i < props.numberOfCourts; i++) {
        courts.push(String.fromCharCode(65 + i));
      }
      return courts;
    });

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
      updateMatchSchedule,
      availableCourtOptions,
      isByeMatch, // テンプレートで使えるように公開
    };
  },
};
</script>

<style scoped>
.bracket-container {
  --player-slot-height: 40px;
  --vs-text-height: 18px;
  --match-padding-vertical: 8px;
  --match-border-width: 1px;
  --match-box-height: calc(var(--player-slot-height) * 2 + var(--vs-text-height) + (var(--match-padding-vertical) * 2) + (var(--match-border-width) * 2) + 5px);
  
  --round-horizontal-gap: 75px;

  --line-color: #757575;
  
  --line-segment-length: calc(var(--round-horizontal-gap) / 2); 

  display: flex;
  flex-direction: row;
  gap: var(--round-horizontal-gap);
  padding: 20px;
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  background-color: #f9f9f9;
  min-width: fit-content;
  align-items: flex-start;
}

.bracket-display-area {
  overflow-x: auto;
  padding-bottom: 20px;
}

.bracket-round-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  flex-shrink: 0;
  position: relative;
}

.round-title {
  margin-bottom: 15px;
  font-size: 1.1em;
  color: #3f51b5;
  border-bottom: 2px solid #3f51b5;
  padding-bottom: 5px;
  width: 100%;
  text-align: center;
}

.bracket-round {
  display: flex;
  flex-direction: column;
  align-items: center;
  position: relative;
}

.round-matches {
  display: flex;
  flex-direction: column;
  position: relative;
}

.bracket-match {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 5px;
  padding: var(--match-padding-vertical) 12px;
  padding-top: calc(var(--match-padding-vertical) + 25px);
  border: var(--match-border-width) solid #cfd8dc;
  border-radius: 4px;
  background-color: #EEEEEE;
  box-shadow: 0 2px 4px rgba(0,0,0,0.05);
  min-width: 180px;
  position: relative;
  z-index: 10;
  height: var(--match-box-height);
  box-sizing: border-box;
}

.player-slot {
  width: 100%;
  padding: 4px 8px;
  border-radius: 3px;
  font-weight: bold;
  text-align: center;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  font-size: 0.9em;
  height: var(--player-slot-height);
  display: flex;
  align-items: center;
  justify-content: center;
}

.player-slot[draggable="true"] {
  cursor: grab;
}

.player-slot[draggable="true"]:active {
  cursor: grabbing;
}

.player-slot.drag-over-target {
  border: 2px dashed #3f51b5;
  background-color: #bbdefb;
}

.player-blue {
  background-color: #e3f2fd;
  color: #1565c0;
  border: 1px solid #90caf9;
}

.player-white {
  background-color: #FFFFFF;
  color: #212121;
  border: 1px solid #bdbdbd;
}

.player-placeholder {
  background-color: #f0f0f0;
  color: #616161;
  border: 1px solid #bdbdbd;
}

.player-gold {
  background-color: #FFD700;
  color: #333333;
  border: 1px solid #DAA520;
}

.vs-text {
  font-weight: bold;
  color: #757575;
  font-size: 0.9em;
  margin: 2px 0;
}

.bracket-match:not(.has-line-to-next)::after {
  content: '';
  position: absolute;
  left: 100%;
  top: 50%;
  transform: translateY(-0.5px);
  width: var(--line-segment-length);
  height: 1px;
  background-color: var(--line-color);
  z-index: 0;
  pointer-events: none;
}

.bracket-match.has-line-to-next::after {
  content: '';
  position: absolute;
  left: 100%;
  top: 50%;
  transform: translateY(-0.5px);
  width: calc(var(--line-segment-length) * 2);
  height: var(--z-line-vertical-segment-height);
  z-index: 0;
  pointer-events: none;

  background:
    linear-gradient(to right, var(--line-color) 0%, var(--line-color) 100%)
    0
    0px
    / var(--line-segment-length) 1px
    no-repeat,

    linear-gradient(to bottom, var(--line-color) 0%, var(--line-color) 100%)
    var(--line-segment-length)
    0px
    / 1px var(--z-line-vertical-segment-height)
    no-repeat,

    linear-gradient(to right, var(--line-color) 0%, var(--line-color) 100%)
    var(--line-segment-length)
    calc(var(--z-line-vertical-segment-height) / 2 - 0.5px)
    / var(--line-segment-length) 1px
    no-repeat;
}

.final-winner-container .bracket-match::before {
  content: '';
  position: absolute;
  right: 100%;
  top: 50%;
  transform: translateY(-0.5px);
  width: var(--line-segment-length);
  height: 1px;
  background-color: var(--line-color);
  z-index: 0;
  pointer-events: none;
}

.match-schedule-inputs-top-right {
  position: absolute;
  top: 2px;
  right: 2px;
  display: flex;
  gap: 4px;
  z-index: 11;
}

/* カスタム入力フィールドのスタイル */
.custom-input {
  max-width: 45px;
  min-width: 25px;
  height: 24px;
  font-size: 0.75em;
  padding: 0 4px;
  border: 1px solid #ccc;
  border-radius: 4px;
  box-sizing: border-box;
  background-color: white;
  color: #333;
  text-align: center;
  -moz-appearance: textfield;
}

/* number input の矢印を非表示 (Chrome, Safari, Edge) */
.custom-input::-webkit-outer-spin-button,
.custom-input::-webkit-inner-spin-button {
  -webkit-appearance: none;
  margin: 0;
}

/* select のデフォルト矢印を非表示にし、カスタム矢印を追加することも可能ですが、今回はシンプルに */
.court-select {
  padding-right: 15px;
  background-image: url('data:image/svg+xml;charset=US-ASCII,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%22292.4%22%20height%3D%22292.4%22%3E%3Cpath%20fill%3D%22%23000000%22%20d%3D%22M287%2069.4a17.6%2017.6%200%200%200-13-5.4H18.4c-6.5%200-12.3%203.2-15.6%208.1-3.3%204.9-3.3%2011.2%200%2016.1l132%20126.7c3.3%203.2%208.3%203.2%2011.6%200l132-126.7c3.3-4.9%203.3-11.2%200-16.1z%22%2F%3E%3C%2Fsvg%3E');
  background-repeat: no-repeat;
  background-position: right 3px center;
  background-size: 8px;
  -webkit-appearance: none;
  -moz-appearance: none;
  appearance: none;
}

/* フォーカス時のスタイル */
.custom-input:focus {
  outline: none;
  border-color: #3f51b5;
  box-shadow: 0 0 0 1px #3f51b5;
}

/* Placeholder のスタイル */
.custom-input::placeholder {
  color: #999;
  font-size: 0.7em;
}
</style>

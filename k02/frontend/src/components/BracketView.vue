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
                      'has-line-to-next': roundIndex < tournamentRounds.length - 1 && matchIndex % 2 === 0,
                      'bye-match-hidden-content': match.isByeMatch // BYE試合の場合、コンテンツを非表示にするクラス
                    }"
                    :style="{
                      'margin-bottom': calculateMatchMarginBottom(matchIndex, round.length),
                      '--z-line-vertical-segment-height': getZLineVerticalSegmentHeight(roundIndex) + 'px'
                    }"
                  >
                    <!-- BYE試合でなければコンテンツを表示 -->
                    <div v-if="!match.isByeMatch">
                      <!-- 試合スケジュール入力欄 -->
                      <div v-if="match" class="match-schedule-inputs-top-right">
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
                        :draggable="roundIndex === 0 && !match.player1?.isWinnerPlaceholder && !match.isByeMatch"
                        @dragstart="dragStart($event, roundIndex, matchIndex, 'player1', match.player1)"
                        @dragover.prevent="dragOver($event, roundIndex, matchIndex, 'player1')"
                        @dragleave="dragLeave"
                        @drop="drop($event, roundIndex, matchIndex, 'player1')"
                        :class="{
                          'player-blue': match.player1 && !match.player1.isWinnerPlaceholder,
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
                        :draggable="roundIndex === 0 && !match.player2?.isWinnerPlaceholder && !match.isByeMatch"
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
    const round1ByePlayers = ref([]); // ラウンド1でBYEになった選手を保存

    const loadingGenerate = ref(false);
    const loadingSave = ref(false);
    const loadingLoad = ref(false);

    const draggedItem = ref(null);
    const dropTarget = ref(null);

    let globalMatchIdCounter = 0;

    // 定数定義
    const PLAYER_SLOT_HEIGHT = 40;
    const VS_TEXT_HEIGHT = 18;
    const MATCH_PADDING_TOP = 20; // 入力欄との重なりを避けるため増加
    const MATCH_PADDING_BOTTOM = 8;
    const MATCH_BORDER_WIDTH = 1;
    // 試合ボックスの実際の高さ (コンテンツ + 上下パディング + ボーダー)
    const MATCH_BOX_HEIGHT = (PLAYER_SLOT_HEIGHT * 2) + VS_TEXT_HEIGHT + MATCH_PADDING_TOP + MATCH_PADDING_BOTTOM + (MATCH_BORDER_WIDTH * 2); // 80 + 18 + 20 + 8 + 2 = 128px

    // 各試合ボックス間の垂直方向の基本マージン（間隔を広げ、視覚的なずれを解消）
    const VERTICAL_GAP_BETWEEN_MATCHES = 100; // 60pxから増加

    // Zラインの垂直セグメントの基準となる高さ
    // これは、同じ次のラウンドの試合に繋がる2つの試合の中心間の垂直距離です。
    const Z_LINE_BASE_VERTICAL_SPAN = MATCH_BOX_HEIGHT + VERTICAL_GAP_BETWEEN_MATCHES; // 128 + 100 = 228px

    const getPlayerFullNameWithBranchAndXclass = (player) => {
      if (!player) return '未定';
      if (player.isWinnerPlaceholder) {
        return `勝者: ${player.winnerOf}`;
      }
      if (player.isBye) { // BYE選手の場合
        return 'BYE';
      }
      const fullName = `${player.familyname || ''} ${player.firstname || ''}`;
      const branchPart = player.branch_nm ? `（${player.branch_nm}）` : '';
      const xclassPart = player.xclass ? ` ${player.xclass}` : '';
      return `${fullName}${branchPart}${xclassPart}`;
    };

    const showSnackbar = (text, color) => {
      emit('show-snackbar', text, color);
    };

    const generateTournament = () => {
      console.log('--- generateTournament START ---');
      loadingGenerate.value = true;
      tournamentRounds.value = [];
      finalWinner.value = null;
      round1ByePlayers.value = []; // BYE選手リストをクリア
      globalMatchIdCounter = 0;

      if (props.registeredParticipants.length < 2) {
        showSnackbar('組み合わせを生成するには2名以上の選手が必要です。', 'warning');
        loadingGenerate.value = false;
        console.log('--- generateTournament END (Not enough participants) ---');
        return;
      }

      let currentParticipants = [...props.registeredParticipants];
      currentParticipants.sort(() => 0.5 - Math.random()); // 初回生成時のみシャッフル

      let roundNumber = 1;
      let participantsForNextRound = []; // 次のラウンドに進む選手（または勝者プレースホルダー）

      // --- ラウンド1の処理 ---
      let bracketSize = 1;
      while (bracketSize < currentParticipants.length) {
        bracketSize *= 2;
      }
      const numByes = bracketSize - currentParticipants.length;

      // BYEとなる選手と実際に試合をする選手を分ける
      const playersGettingByeInRound1 = currentParticipants.slice(0, numByes);
      const playersPlayingInRound1 = currentParticipants.slice(numByes);

      round1ByePlayers.value = playersGettingByeInRound1; // BYE選手リストを保存

      const round1Matches = [];

      // まずBYE試合を生成
      for (let i = 0; i < playersGettingByeInRound1.length; i++) {
        globalMatchIdCounter++;
        const matchId = `R${roundNumber}-M${globalMatchIdCounter}`;
        round1Matches.push({
          player1: playersGettingByeInRound1[i],
          player2: { isBye: true, label: 'BYE' }, // BYEを示す特別なオブジェクト
          matchId: matchId,
          court_id: null,
          match_order_no: null,
          isByeMatch: true // この試合がBYE試合であることを示すフラグ
        });
        // BYE選手は直接次のラウンドに進む
        participantsForNextRound.push(playersGettingByeInRound1[i]);
      }

      // 次に実際の試合を生成
      for (let i = 0; i < playersPlayingInRound1.length; i += 2) {
        globalMatchIdCounter++;
        const matchId = `R${roundNumber}-M${globalMatchIdCounter}`;
        round1Matches.push({
          player1: playersPlayingInRound1[i],
          player2: playersPlayingInRound1[i + 1],
          matchId: matchId,
          court_id: null,
          match_order_no: null,
          isByeMatch: false // 実際の試合なのでfalse
        });
        // 実際の試合の勝者はプレースホルダーとして次のラウンドに進む
        participantsForNextRound.push({ isWinnerPlaceholder: true, winnerOf: matchId });
      }
      
      // ラウンド1の試合をソート（例: BYE試合が先頭に来るように、またはmatchId順）
      round1Matches.sort((a, b) => {
          if (a.isByeMatch && !b.isByeMatch) return -1; // BYE試合を非BYE試合より前に
          if (!a.isByeMatch && b.isByeMatch) return 1;  // 非BYE試合をBYE試合より後に
          return a.matchId.localeCompare(b.matchId); // それ以外はmatchIdでソート
      });

      tournamentRounds.value.push(round1Matches);

      // 次のラウンドに進む選手をソート（組み合わせの安定性のため）
      participantsForNextRound.sort((a, b) => {
          const aId = a.player_id || a.winnerOf || '';
          const bId = b.player_id || b.winnerOf || '';
          return String(aId).localeCompare(String(bId));
      });
      currentParticipants = participantsForNextRound;
      roundNumber++;

      // --- ラウンド2以降の処理 ---
      while (currentParticipants.length > 1) {
        console.log(`--- Generating Round ${roundNumber} ---`);
        const currentRoundMatches = [];
        participantsForNextRound = []; // 次のラウンドに進む選手をリセット

        let roundNBracketSize = 1;
        while (roundNBracketSize < currentParticipants.length) {
          roundNBracketSize *= 2;
        }
        const numByesInCurrentRound = roundNBracketSize - currentParticipants.length;

        // このラウンドでBYEになる選手（つまり、対戦相手がいないため自動的に次のラウンドに進む選手）
        const playersGettingByeInCurrentRound = currentParticipants.slice(0, numByesInCurrentRound);
        // 実際に試合をする選手
        const playersPlayingInCurrentRound = currentParticipants.slice(numByesInCurrentRound);

        // BYEになる選手は直接次のラウンドの参加者リストに追加 (isByeMatchはfalse)
        participantsForNextRound.push(...playersGettingByeInCurrentRound);

        // 実際に試合をする選手で試合を作成
        for (let i = 0; i < playersPlayingInCurrentRound.length; i += 2) {
          globalMatchIdCounter++;
          const matchId = `R${roundNumber}-M${globalMatchIdCounter}`;
          currentRoundMatches.push({
            player1: playersPlayingInCurrentRound[i],
            player2: playersPlayingInCurrentRound[i + 1],
            matchId: matchId,
            court_id: null,
            match_order_no: null,
            isByeMatch: false // ラウンド2以降は明示的なBYE試合は作らない
          });
          participantsForNextRound.push({ isWinnerPlaceholder: true, winnerOf: matchId });
        }

        if (currentRoundMatches.length > 0) {
          tournamentRounds.value.push(currentRoundMatches);
        } else if (currentParticipants.length > 0 && currentRoundMatches.length === 0) {
            console.log(`Round ${roundNumber}: All remaining participants are BYE, no actual matches.`);
        }

        participantsForNextRound.sort((a, b) => {
            const aId = a.player_id || a.winnerOf || '';
            const bId = b.player_id || b.winnerOf || '';
            return String(aId).localeCompare(String(bId));
        });
        currentParticipants = participantsForNextRound;
        roundNumber++;
      }

      if (currentParticipants.length === 1) {
        finalWinner.value = currentParticipants[0];
      } else {
        finalWinner.value = null;
      }

      console.log('Final tournamentRounds structure:', JSON.parse(JSON.stringify(tournamentRounds.value)));
      showSnackbar('組み合わせを生成しました！', 'success');
      loadingGenerate.value = false;
      console.log('--- generateTournament END ---');
    };

    const recalculateSubsequentRounds = () => {
      console.log('--- recalculateSubsequentRounds START ---');
      if (props.registeredParticipants.length < 2) {
        console.log('Not enough participants to recalculate.');
        clearBracket();
        return;
      }

      // 既存のラウンド1の試合データを保持するためのマップを作成
      // BYE試合のデータも保持する
      const round1MatchDataMap = new Map();
      if (tournamentRounds.value[0]) {
        tournamentRounds.value[0].forEach(match => {
          // BYE試合かどうかにかかわらず、player1とplayer2のIDをキーにする
          const player1Id = match.player1?.player_id || (match.player1?.isBye ? 'BYE_PLAYER_1' : null);
          const player2Id = match.player2?.player_id || (match.player2?.isBye ? 'BYE_PLAYER_2' : null);
          
          if (player1Id && player2Id) {
            // BYE選手がいる場合も考慮したキー生成
            const key = [player1Id, player2Id].sort().join('-');
            round1MatchDataMap.set(key, { 
              court_id: match.court_id, 
              match_order_no: match.match_order_no, 
              matchId: match.matchId,
              isByeMatch: match.isByeMatch // isByeMatchも保持
            });
          }
        });
      }
      console.log('Existing Round 1 match data map:', round1MatchDataMap);

      let currentParticipants = [...props.registeredParticipants]; // 再計算時はシャッフルしない

      let roundNumber = 1;
      let participantsForNextRound = [];
      let tempGlobalMatchIdCounter = 0; // 必要に応じて新しいmatchIdを生成するための仮のカウンター

      // --- ラウンド1の再構築 ---
      let bracketSize = 1;
      while (bracketSize < currentParticipants.length) {
        bracketSize *= 2;
      }
      const numByes = bracketSize - currentParticipants.length;

      const playersGettingByeInRound1 = currentParticipants.slice(0, numByes);
      const playersPlayingInRound1 = currentParticipants.slice(numByes);

      round1ByePlayers.value = playersGettingByeInRound1; // BYE選手リストを更新

      const reconstructedRound1Matches = [];

      // BYE試合を再構築
      for (let i = 0; i < playersGettingByeInRound1.length; i++) {
        const player1 = playersGettingByeInRound1[i];
        const player2 = { isBye: true, label: 'BYE' };

        const key = [player1?.player_id, 'BYE_PLAYER_2'].sort().join('-'); // BYE選手用のキー
        const existingMatchData = round1MatchDataMap.get(key);
        
        let matchId = existingMatchData?.matchId || `R1-M${tempGlobalMatchIdCounter++}`;
        reconstructedRound1Matches.push({
          player1: player1,
          player2: player2,
          matchId: matchId,
          court_id: existingMatchData?.court_id || null,
          match_order_no: existingMatchData?.match_order_no || null,
          isByeMatch: true
        });
        participantsForNextRound.push(player1);
      }

      // 実際の試合を再構築
      for (let i = 0; i < playersPlayingInRound1.length; i += 2) {
        const player1 = playersPlayingInRound1[i];
        const player2 = playersPlayingInRound1[i + 1];

        const key = [player1?.player_id, player2?.player_id].sort().join('-');
        const existingMatchData = round1MatchDataMap.get(key);
        
        let matchId = existingMatchData?.matchId || `R1-M${tempGlobalMatchIdCounter++}`;
        reconstructedRound1Matches.push({
          player1: player1,
          player2: player2,
          matchId: matchId,
          court_id: existingMatchData?.court_id || null,
          match_order_no: existingMatchData?.match_order_no || null,
          isByeMatch: false
        });
        participantsForNextRound.push({ isWinnerPlaceholder: true, winnerOf: matchId });
      }

      // ラウンド1の試合をソート（generateTournamentと同じロジック）
      reconstructedRound1Matches.sort((a, b) => {
          if (a.isByeMatch && !b.isByeMatch) return -1;
          if (!a.isByeMatch && b.isByeMatch) return 1;
          return a.matchId.localeCompare(b.matchId);
      });

      tournamentRounds.value = []; // 再構築する前にすべてのラウンドをクリア
      if (reconstructedRound1Matches.length > 0) {
        tournamentRounds.value.push(reconstructedRound1Matches);
      }
      
      participantsForNextRound.sort((a, b) => {
          const aId = a.player_id || a.winnerOf || '';
          const bId = b.player_id || b.winnerOf || '';
          return String(aId).localeCompare(String(bId));
      });
      currentParticipants = participantsForNextRound;
      roundNumber++;
      globalMatchIdCounter = tempGlobalMatchIdCounter; // グローバルカウンターを同期

      // --- 以降のラウンドを再計算 ---
      while (currentParticipants.length > 1) {
        console.log(`--- Recalculating Round ${roundNumber} ---`);
        const currentRoundMatches = [];
        participantsForNextRound = [];

        let roundNBracketSize = 1;
        while (roundNBracketSize < currentParticipants.length) {
          roundNBracketSize *= 2;
        }
        const numByesInCurrentRound = roundNBracketSize - currentParticipants.length;

        const playersGettingByeInCurrentRound = currentParticipants.slice(0, numByesInCurrentRound);
        const playersPlayingInCurrentRound = currentParticipants.slice(numByesInCurrentRound);

        participantsForNextRound.push(...playersGettingByeInCurrentRound);

        for (let i = 0; i < playersPlayingInCurrentRound.length; i += 2) {
          globalMatchIdCounter++;
          const matchId = `R${roundNumber}-M${globalMatchIdCounter}`;
          currentRoundMatches.push({
            player1: playersPlayingInCurrentRound[i],
            player2: playersPlayingInCurrentRound[i + 1],
            matchId: matchId,
            court_id: null,
            match_order_no: null,
            isByeMatch: false
          });
          participantsForNextRound.push({ isWinnerPlaceholder: true, winnerOf: matchId });
        }

        if (currentRoundMatches.length > 0) {
          tournamentRounds.value.push(currentRoundMatches);
        } else if (currentParticipants.length > 0 && currentRoundMatches.length === 0) {
            console.log(`Round ${roundNumber}: All remaining participants are BYE, no actual matches generated.`);
        }

        participantsForNextRound.sort((a, b) => {
            const aId = a.player_id || a.winnerOf || '';
            const bId = b.player_id || b.winnerOf || '';
            return String(aId).localeCompare(String(bId));
        });
        currentParticipants = participantsForNextRound;
        roundNumber++;
      }

      if (currentParticipants.length === 1) {
        finalWinner.value = currentParticipants[0];
      } else {
        finalWinner.value = null;
      }
      console.log('Final tournamentRounds structure after recalculation:', JSON.parse(JSON.stringify(tournamentRounds.value)));
      console.log('--- recalculateSubsequentRounds END ---');
    };

    const clearBracket = () => {
      tournamentRounds.value = [];
      finalWinner.value = null;
      round1ByePlayers.value = [];
      globalMatchIdCounter = 0;
      showSnackbar('トーナメント表をクリアしました。', 'info');
      console.log('Bracket cleared.');
    };

    const saveBracket = async () => {
      if (!props.tournamentId || !props.categoryId || tournamentRounds.value.length === 0) {
        showSnackbar('保存する組み合わせがありません。大会、カテゴリーを選択し、組み合わせを生成してください。', 'warning');
        return;
      }

      loadingSave.value = true;
      try {
        const bracketId = crypto.randomUUID();
        const roundsToSave = tournamentRounds.value;

        const payload = {
          bracket_id: bracketId,
          tournament_id: props.tournamentId,
          category_id: props.categoryId,
          bracket_data: JSON.stringify(roundsToSave),
          final_winner_data: finalWinner.value ? JSON.stringify(finalWinner.value) : null,
          round1_bye_players_data: JSON.stringify(round1ByePlayers.value),
        };
        console.log('Saving bracket with payload:', payload);

        const response = await axios.post('http://localhost:1880/save-bracket', payload);

        if (response.data.success) {
          showSnackbar('トーナメント組み合わせを保存しました！', 'success');
          console.log('Bracket saved successfully.');
        } else {
          showSnackbar('保存に失敗しました: ' + (response.data.message || '不明なエラー'), 'error');
          console.error('Failed to save bracket:', response.data.message);
        }
      } catch (error) {
        console.error('Failed to save bracket:', error);
        showSnackbar('保存中にエラーが発生しました。サーバーとの接続を確認してください。', 'error');
      } finally {
        loadingSave.value = false;
      }
    };

    const loadBracket = async () => {
      console.log('--- loadBracket START ---');
      if (!props.tournamentId || !props.categoryId) {
        showSnackbar('組み合わせを読み込むには、大会とカテゴリーを選択してください。', 'warning');
        console.log('--- loadBracket END (Missing Tournament/Category ID) ---');
        return;
      }

      loadingLoad.value = true;
      try {
        const response = await axios.get(`http://localhost:1880/load-bracket/${props.tournamentId}/${props.categoryId}`);
        console.log('Load bracket response:', response.data);

        if (response.data.success) {
          let loadedRounds = JSON.parse(response.data.bracket_data);
          
          // isByeMatchプロパティが古いデータにない場合を考慮
          loadedRounds.forEach(round => {
            round.forEach(match => {
              if (!('court_id' in match)) match.court_id = null;
              if (!('match_order_no' in match)) match.match_order_no = null;
              if (!('isByeMatch' in match)) match.isByeMatch = false; // 古いデータにはないのでデフォルト値
              // player2がBYEオブジェクトではない場合も考慮
              if (match.player2 && match.player2.label === 'BYE' && !match.player2.isBye) {
                  match.player2.isBye = true;
              }
            });
          });
          tournamentRounds.value = loadedRounds;
          console.log('Loaded tournamentRounds:', JSON.parse(JSON.stringify(tournamentRounds.value)));

          finalWinner.value = response.data.final_winner_data ? JSON.parse(response.data.final_winner_data) : null;
          round1ByePlayers.value = response.data.round1_bye_players_data ? JSON.parse(response.data.round1_bye_players_data) : [];
          console.log('Loaded round1ByePlayers:', JSON.parse(JSON.stringify(round1ByePlayers.value)));

          recalculateSubsequentRounds(); // ロード後も再計算して表示を最新の状態に

          showSnackbar('トーナメント組み合わせを読み込みました！', 'success');
          console.log('Bracket loaded successfully.');
        } else {
          if (response.status === 404) {
            tournamentRounds.value = [];
            finalWinner.value = null;
            round1ByePlayers.value = [];
            showSnackbar(response.data.message || '指定された組み合わせは見つかりませんでした。', 'info');
            console.log('No bracket found for specified IDs.');
          } else {
            showSnackbar('読み込みに失敗しました: ' + (response.data.message || '不明なエラー'), 'error');
            console.error('Failed to load bracket:', response.data.message || 'Unknown error from server');
          }
        }
      } catch (error) {
        console.error('Failed to load bracket:', error);
        if (error.response && error.response.status === 404) {
          tournamentRounds.value = [];
          finalWinner.value = null;
          round1ByePlayers.value = [];
          showSnackbar(error.response.data.message || '指定された組み合わせは見つかりませんでした。', 'info');
        } else {
          showSnackbar('読み込み中にエラーが発生しました。サーバーとの接続を確認してください。', 'error');
        }
      } finally {
        loadingLoad.value = false;
        console.log('--- loadBracket END ---');
      }
    };

    watch(() => props.existingData, (newData) => {
      console.log('--- existingData watch START ---');
      if (newData && newData.bracket_data) {
        try {
          let parsedBracketData;
          if (typeof newData.bracket_data === 'string') {
            parsedBracketData = JSON.parse(newData.bracket_data);
          } else {
            parsedBracketData = newData.bracket_data;
          }

          // isByeMatchプロパティが古いデータにない場合を考慮
          parsedBracketData.forEach(round => {
            round.forEach(match => {
              if (!('court_id' in match)) match.court_id = null;
              if (!('match_order_no' in match)) match.match_order_no = null;
              if (!('isByeMatch' in match)) match.isByeMatch = false; // 古いデータにはないのでデフォルト値
              // player2がBYEオブジェクトではない場合も考慮
              if (match.player2 && match.player2.label === 'BYE' && !match.player2.isBye) {
                  match.player2.isBye = true;
              }
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

          let parsedRound1ByePlayersData = [];
          if (newData.round1_bye_players_data) {
            if (typeof newData.round1_bye_players_data === 'string') {
              parsedRound1ByePlayersData = JSON.parse(newData.round1_bye_players_data);
            } else {
              parsedRound1ByePlayersData = newData.round1_bye_players_data;
            }
          }

          tournamentRounds.value = parsedBracketData;
          finalWinner.value = parsedFinalWinnerData;
          round1ByePlayers.value = parsedRound1ByePlayersData;
          console.log('Existing data loaded to tournamentRounds:', JSON.parse(JSON.stringify(tournamentRounds.value)));
          console.log('Existing data loaded to round1ByePlayers:', JSON.parse(JSON.stringify(round1ByePlayers.value)));

          recalculateSubsequentRounds();

        } catch (e) {
          console.error("Failed to parse existing bracket data from props:", e);
          showSnackbar('既存のトーナメントデータの解析に失敗しました。', 'error');
          clearBracket();
        }
      } else {
        clearBracket();
        console.log('No existing data in props, clearing bracket.');
      }
      console.log('--- existingData watch END ---');
    }, { immediate: true });

    // 各試合ボックスの中心の絶対的な垂直位置を計算するヘルパー関数
    const getMatchCenterY = (roundIndex, matchIndex) => {
        let centerY = (MATCH_BOX_HEIGHT / 2); // ラウンド0の最初の試合の中心Y座標

        // 最初のラウンドの試合の中心Y座標を計算
        if (roundIndex === 0) {
            return centerY + matchIndex * (MATCH_BOX_HEIGHT + VERTICAL_GAP_BETWEEN_MATCHES);
        }

        // 2ラウンド目以降の最初の試合の中心Y座標は、
        // 前のラウンドの最初の試合の中心Y座標から、そのラウンドのZラインの高さの半分だけ下にシフトする
        for (let i = 0; i < roundIndex; i++) {
            centerY += getZLineVerticalSegmentHeight(i) / 2;
        }
        
        // 現在のラウンドの最初の試合の中心Y座標に、
        // そのラウンド内の試合のインデックスに応じたオフセットを加算
        return centerY + matchIndex * (MATCH_BOX_HEIGHT + VERTICAL_GAP_BETWEEN_MATCHES);
    };

    // Zラインの垂直セグメントの高さを計算
    const getZLineVerticalSegmentHeight = (roundIndex) => {
      // Z_LINE_BASE_VERTICAL_SPAN はラウンド0での2つの試合の中心間の距離です。
      // 各ラウンドで、この距離は前のラウンドの2倍になります。
      return Z_LINE_BASE_VERTICAL_SPAN * Math.pow(2, roundIndex);
    };

    // 各試合ボックスの下マージンを計算
    const calculateMatchMarginBottom = (matchIndex, totalMatchesInRound) => {
      // ラウンド内の最後の試合にはマージンを適用しない
      if (matchIndex === totalMatchesInRound - 1) {
        return '0px';
      }
      // それ以外の試合には、定義された垂直ギャップを適用
      return `${VERTICAL_GAP_BETWEEN_MATCHES}px`;
    };

    // 各ラウンドの最初の試合のトップマージンを計算
    const getRoundMatchesMarginTop = (roundIndex) => {
      if (roundIndex === 0) {
        return '0px'; // 最初のラウンドは一番上から開始
      }
      // 現在のラウンドの最初の試合の中心Y座標から、試合ボックスの高さの半分を引く
      return `${getMatchCenterY(roundIndex, 0) - (MATCH_BOX_HEIGHT / 2)}px`;
    };

    // 最終優勝者表示のトップマージンを計算
    const getFinalWinnerMatchesMarginTop = () => {
      if (tournamentRounds.value.length === 0) return '0px';
      const lastRoundIndex = tournamentRounds.value.length - 1;
      // 最終優勝者ボックスも、最後のラウンドの試合の中央に揃うように配置
      return getRoundMatchesMarginTop(lastRoundIndex);
    };

    const dragStart = (event, rIdx, mIdx, sType, player) => {
      // ラウンド1のみドラッグ可能
      // 勝者プレースホルダーおよびBYEマッチの選手はドラッグ不可
      if (rIdx !== 0 || player?.isWinnerPlaceholder || tournamentRounds.value[rIdx][mIdx].isByeMatch) {
        event.preventDefault();
        return;
      }
      draggedItem.value = { rIdx, mIdx, sType, player };
      event.dataTransfer.effectAllowed = 'move';
      event.dataTransfer.setData('application/json', JSON.stringify({ rIdx, mIdx, sType }));
      console.log('Drag Start:', draggedItem.value);
    };

    const dragOver = (event, rIdx, mIdx, sType) => {
      // ラウンド1のみドロップ可能
      // 勝者プレースホルダーおよびBYEマッチの選手へのドロップ不可
      if (rIdx !== 0 || tournamentRounds.value[rIdx][mIdx][sType]?.isWinnerPlaceholder || tournamentRounds.value[rIdx][mIdx].isByeMatch) {
        return;
      }
      event.preventDefault();
      dropTarget.value = { rIdx, mIdx, sType };
    };

    const dragLeave = () => {
      dropTarget.value = null;
    };

    const drop = (event, targetRIdx, targetMIdx, targetSType) => {
      // ラウンド1のみドロップ可能
      // 勝者プレースホルダーおよびBYEマッチの選手へのドロップ不可
      if (targetRIdx !== 0 || tournamentRounds.value[targetRIdx][targetMIdx][targetSType]?.isWinnerPlaceholder || tournamentRounds.value[targetRIdx][targetMIdx].isByeMatch) {
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

      // 選手を入れ替える
      tournamentRounds.value[sourceRIdx][sourceMIdx][sourceSType] = targetPlayer;
      tournamentRounds.value[targetRIdx][targetMIdx][targetSType] = sourcePlayer;

      draggedItem.value = null;
      console.log('Players swapped. Recalculating subsequent rounds...');
      recalculateSubsequentRounds(); // ラウンド1の変更後にラウンド2以降を再計算
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
        console.log(`Match ${roundIndex}-${matchIndex} updated: ${type} = ${value}`);
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
    };
  },
};
</script>

<style scoped>
.bracket-container {
  --player-slot-height: 40px;
  --vs-text-height: 18px;
  --match-padding-top: 20px; /* 入力欄との重なりを避けるため増加 */
  --match-padding-bottom: 8px;
  --match-border-width: 1px;
  --match-box-height: calc(var(--player-slot-height) * 2 + var(--vs-text-height) + var(--match-padding-top) + var(--match-padding-bottom) + (var(--match-border-width) * 2)); /* 128px */
  
  --round-horizontal-gap: 75px; /* 各ラウンド間の水平方向のギャップ */
  --line-color: #757575; /* 接続線の色 */
  --line-segment-length: calc(var(--round-horizontal-gap) / 2); /* 各ラウンド間の水平線の長さ */
  --match-vertical-gap: 100px; /* 各試合ボックス間の垂直方向のギャップを増加 */

  display: flex;
  flex-direction: row;
  gap: var(--round-horizontal-gap);
  padding: 20px;
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  background-color: #f9f9f9;
  min-width: fit-content;
  align-items: flex-start; /* 各ラウンドの開始位置を上揃えにする */
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
  /* margin-top はJavaScriptで計算される */
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
  padding: var(--match-padding-top) 12px var(--match-padding-bottom); /* 上下パディングを調整 */
  border: var(--match-border-width) solid #cfd8dc;
  border-radius: 4px;
  background-color: #EEEEEE;
  box-shadow: 0 2px 4px rgba(0,0,0,0.05);
  min-width: 250px; /* 選手名がはみ出さないように幅を広げる */
  position: relative;
  z-index: 10;
  height: var(--match-box-height); /* heightをCSS変数で定義 */
  box-sizing: border-box;
  margin-bottom: var(--match-vertical-gap); /* デフォルトの垂直ギャップ */
}

.bracket-round .round-matches .bracket-match:last-child {
    margin-bottom: 0 !important; /* ラウンド内の最後の試合には下マージンを適用しない */
}

/* BYE試合の場合、コンテンツを非表示にするスタイル */
.bracket-match.bye-match-hidden-content {
  background-color: transparent !important;
  border-color: transparent !important;
  box-shadow: none !important;
  pointer-events: none; /* クリックやドラッグイベントを無効化 */
}
.bracket-match.bye-match-hidden-content > div {
    visibility: hidden; /* 子要素のコンテンツを非表示にする */
}
/* BYE試合の接続線も非表示にする */
.bracket-match.bye-match-hidden-content::after {
  content: none; /* 接続線を完全に非表示にする */
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
  width: 100%; /* 親要素に合わせて幅を広げ、text-align: center を有効にする */
  text-align: center; /* 明示的に中央揃え */
  display: flex; /* Flexboxで中央揃えを強化 */
  align-items: center; /* 垂直方向中央 */
  justify-content: center; /* 水平方向中央 */
}

/* 試合ボックスから次のラウンドへの接続線 (水平線と垂直線) */
.bracket-match::after {
  content: '';
  position: absolute;
  left: 100%;
  top: 50%; /* 試合ボックスの中央から開始 */
  transform: translateY(-0.5px); /* 線の太さの半分だけ上にずらして中央に揃える */
  width: var(--line-segment-length); /* 水平線の長さ */
  height: 1px; /* 水平線の太さ */
  background-color: var(--line-color);
  z-index: 0;
  pointer-events: none;
}

/* 次のラウンドに繋がる試合ボックス (ペアの最初の試合) の接続線 */
.bracket-match.has-line-to-next::after {
  /* 既存の水平線を上書き */
  width: calc(var(--line-segment-length) * 2); /* 水平線 + 垂直線への接続部分 */
  height: var(--z-line-vertical-segment-height); /* 垂直線の高さ */
  
  /* 複数の背景グラデーションで線を描画 */
  background:
    /* 最初の水平線 */
    linear-gradient(to right, var(--line-color) 0%, var(--line-color) 100%)
    0
    0px
    / var(--line-segment-length) 1px
    no-repeat,

    /* 垂直線 */
    linear-gradient(to bottom, var(--line-color) 0%, var(--line-color) 100%)
    var(--line-segment-length) /* 最初の水平線の終点から開始 */
    0px
    / 1px var(--z-line-vertical-segment-height)
    no-repeat,

    /* 2番目の水平線 (次の試合ボックスの中央に繋がる部分) */
    linear-gradient(to right, var(--line-color) 0%, var(--line-color) 100%)
    var(--line-segment-length)
    calc(var(--z-line-vertical-segment-height) / 2 - 0.5px) /* 垂直線の中央から開始 */
    / var(--line-segment-length) 1px
    no-repeat;
}

/* 最終優勝者ボックスへの接続線 (左側から伸びる水平線) */
.final-winner-container .bracket-match::before {
  content: '';
  position: absolute;
  right: 100%; /* ボックスの左側から伸びる */
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

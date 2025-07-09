<template>
  <v-card class="mx-auto" outlined>
    <v-card-title class="headline">
      トーナメント表
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
              @click="generateBracket"
              :disabled="registeredParticipants.length < 2 || loadingGenerate"
            >
              <v-icon left>mdi-tournament</v-icon>
              組み合わせを生成
            </v-btn>
            <v-btn
              color="secondary"
              class="ml-4"
              @click="clearBracket"
              :disabled="bracketRounds.length === 0"
            >
              <v-icon left>mdi-close</v-icon>
              クリア
            </v-btn>
            <v-btn
              color="success"
              class="ml-4"
              @click="saveBracket"
              :disabled="bracketRounds.length === 0 || loadingSave"
            >
              <v-icon left>mdi-content-save</v-icon>
              組み合わせを保存
            </v-btn>
            <v-btn
              color="info"
              class="ml-4"
              @click="loadBracket"
              :disabled="loadingLoad || !selectedTournamentId || !selectedCategoryId"
            >
              <v-icon left>mdi-folder-open</v-icon>
              組み合わせを読み込み
            </v-btn>
          </v-col>
        </v-row>

        <v-divider class="my-4"></v-divider>
        <h3 class="text-h6 mb-2">生成されたトーナメント表</h3>
        <div v-if="bracketRounds.length > 0" class="bracket-display-area">
          <div class="bracket-container">
            <div
              v-for="(round, roundIndex) in bracketRounds"
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
                      'has-line-to-next': roundIndex < bracketRounds.length - 1 && matchIndex % 2 === 0 && round[matchIndex + 1]
                    }"
                    :style="{
                      'margin-bottom': calculateMatchMarginBottom(roundIndex, matchIndex, round.length),
                      '--z-line-vertical-segment-height': getZLineVerticalSegmentHeight(roundIndex) + 'px'
                    }"
                  >
                    <!-- Player 1 Slot -->
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
                        'player-placeholder': match.player1 && match.player1.isWinnerPlaceholder, /* 勝者プレースホルダー用 */
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
                    <!-- Player 2 Slot -->
                    <div
                      class="player-slot"
                      :draggable="roundIndex === 0 && !match.player2?.isWinnerPlaceholder && !match.player2?.isBye"
                      @dragstart="dragStart($event, roundIndex, matchIndex, 'player2', match.player2)"
                      @dragover.prevent="dragOver($event, roundIndex, matchIndex, 'player2')"
                      @dragleave="dragLeave"
                      @drop="drop($event, roundIndex, matchIndex, 'player2')"
                      :class="{
                        'player-white': match.player2 && !match.player2.isWinnerPlaceholder, /* Player2 is always white if not a winner placeholder (whether it's a real player or BYE) */
                        'player-placeholder': match.player2 && match.player2.isWinnerPlaceholder, /* 勝者プレースホルダー用 */
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
            <!-- 最終的な勝者表示 -->
            <div v-if="finalWinner && bracketRounds.length > 0" class="bracket-round-container final-winner-container">
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
  name: 'BracketView',
  setup() {
    const tournamentsList = ref([]);
    const categoriesList = ref([]);
    const registeredParticipants = ref([]); // 選択された大会・カテゴリーに登録済みの選手
    const bracketRounds = ref([]); // 生成されたブラケットのラウンドごとの試合リスト
    const finalWinner = ref(null); // 最終的な勝者

    const selectedTournamentId = ref(null);
    const selectedCategoryId = ref(null);

    const loadingTournaments = ref(false);
    const loadingCategories = ref(false);
    const loadingParticipants = ref(false);
    const loadingGenerate = ref(false);
    const loadingSave = ref(false); // 保存中のローディング状態
    const loadingLoad = ref(false); // 読み込み中のローディング状態

    const snackbar = ref(false);
    const snackbarText = ref('');
    const snackbarColor = ref('');

    // ドラッグ＆ドロップ関連のstate
    const draggedItem = ref(null); // ドラッグ中の選手情報 { rIdx, mIdx, sType, playerObject }
    const dropTarget = ref(null); // ドロップターゲットの選手情報 { rIdx, mIdx, sType } (視覚的フィードバック用)

    // Match IDを生成するためのグローバルカウンター
    let globalMatchIdCounter = 0;

    // 定数（CSS変数と同期させる）
    const PLAYER_SLOT_HEIGHT = 40;
    const VS_TEXT_HEIGHT = 18;
    const MATCH_PADDING_VERTICAL = 8;
    const MATCH_BORDER_WIDTH = 1;
    // 試合ボックス全体の高さ (選手スロット2つ + VSテキスト + パディング + ボーダー + 微調整)
    const MATCH_BOX_HEIGHT = (PLAYER_SLOT_HEIGHT * 2) + VS_TEXT_HEIGHT + (MATCH_PADDING_VERTICAL * 2) + (MATCH_BORDER_WIDTH * 2) + 5; // 121px
    const BASE_MATCH_VERTICAL_SPACING = 30; // 試合間の基本垂直間隔
    // 1つの試合ユニットが占める垂直方向の合計高さ (試合ボックス + 基本垂直間隔)
    const TOTAL_MATCH_UNIT_HEIGHT = MATCH_BOX_HEIGHT + BASE_MATCH_VERTICAL_SPACING; // 121 + 30 = 151px

    // 選手名、支部名、級を結合して表示する関数
    const getPlayerFullNameWithBranchAndXclass = (player) => {
      const fullName = `${player.familyname || ''} ${player.firstname || ''}`;
      const branchPart = player.branch_nm ? `（${player.branch_nm}）` : '';
      const xclassPart = player.xclass ? ` ${player.xclass}` : '';
      return `${fullName}${branchPart}${xclassPart}`;
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
      bracketRounds.value = []; // ブラケットをクリア
      finalWinner.value = null; // 最終勝者もクリア
      await fetchCategoriesList(newTournamentId); // 紐付けられたカテゴリーを再取得
    };

    // カテゴリー選択時のハンドラー
    const handleCategoryChange = async (newCategoryId) => {
      bracketRounds.value = []; // ブラケットをクリア
      finalWinner.value = null; // 最終勝者もクリア
      await fetchRegisteredParticipants(selectedTournamentId.value, newCategoryId); // 登録済み選手を再取得
      // カテゴリーが選択されたら、自動で組み合わせを読み込む
      if (selectedTournamentId.value && newCategoryId) {
        loadBracket();
      }
    };

    // トーナメント組み合わせを生成する関数 (ボタンクリック用)
    const generateBracket = () => {
      loadingGenerate.value = true;
      bracketRounds.value = []; // 既存の組み合わせをクリア
      finalWinner.value = null; // 最終勝者もクリア
      globalMatchIdCounter = 0; // 新しい生成ではカウンターをリセット

      if (registeredParticipants.value.length < 2) {
        showSnackbar('組み合わせを生成するには2名以上の選手が必要です。', 'warning');
        loadingGenerate.value = false;
        return;
      }

      let currentRoundParticipants = [...registeredParticipants.value];
      currentRoundParticipants.sort(() => 0.5 - Math.random()); // 初期シャッフル

      let roundNumber = 1;

      // --- ラウンド生成ループ ---
      // 参加者が1人になるまでループを続ける（最終的な勝者が決定するまで）
      while (currentRoundParticipants.length > 1) {
        const currentRoundMatches = [];
        const nextRoundAdvancingPlayers = [];

        // 現在のラウンドのブラケットサイズ（2のべき乗）とBYEの数を計算
        let currentRoundBracketSize = 1;
        while (currentRoundBracketSize < currentRoundParticipants.length) {
          currentRoundBracketSize *= 2;
        }
        const numByes = currentRoundBracketSize - currentRoundParticipants.length;

        // BYE選手と通常の試合をする選手を分ける
        const playersWithBye = currentRoundParticipants.slice(0, numByes);
        const playersPlaying = currentRoundParticipants.slice(numByes);

        // 1. BYEの試合を生成し、次のラウンドに進む選手として追加
        playersWithBye.forEach(player => {
          globalMatchIdCounter++;
          const matchId = `R${roundNumber}-M${globalMatchIdCounter}`;
          currentRoundMatches.push({
            player1: player,
            player2: { id: `BYE_${matchId}`, name: 'BYE', isBye: true }, // BYEをオブジェクトとして表現
            matchId: matchId
          });
          nextRoundAdvancingPlayers.push(player); // BYE選手はそのまま次のラウンドに進む
        });

        // 2. 通常の選手対選手の試合を生成し、次のラウンドに進むプレースホルダーとして追加
        for (let i = 0; i < playersPlaying.length; i += 2) {
          globalMatchIdCounter++;
          const matchId = `R${roundNumber}-M${globalMatchIdCounter}`;
          currentRoundMatches.push({
            player1: playersPlaying[i],
            player2: playersPlaying[i + 1],
            matchId: matchId
          });
          nextRoundAdvancingPlayers.push({ isWinnerPlaceholder: true, winnerOf: matchId }); // 試合の勝者は次のラウンドのプレースホルダーとなる
        }

        bracketRounds.value.push(currentRoundMatches);

        // 次のラウンドの参加者を更新
        currentRoundParticipants = nextRoundAdvancingPlayers;
        roundNumber++;
      }

      // ループ終了後、残っている参加者が1人であれば、それが優勝者
      // ここでは、ドラッグ＆ドロップで選手が入れ替わった後の再計算を考慮し、
      // 最終的な勝者がプレースホルダーであれば、そのプレースホルダーをそのまま表示する。
      // 実際の勝者を決定するロジックは別途必要。
      if (currentRoundParticipants.length === 1) {
          finalWinner.value = currentRoundParticipants[0];
      } else {
          finalWinner.value = null; // 優勝者が未定または異常な状態の場合
      }

      showSnackbar('組み合わせを生成しました！', 'success');
      loadingGenerate.value = false;
    };

    // ラウンド1の変更に基づいて、ラウンド2以降を再計算する関数
    const recalculateSubsequentRounds = () => {
        if (bracketRounds.value.length === 0) {
            return;
        }

        // ラウンド1の試合結果から次のラウンドの参加者を決定
        let currentRoundParticipants = [];
        bracketRounds.value[0].forEach(match => {
            // player1がBYEの場合、player2が勝ち上がる
            if (match.player1 && match.player1.isBye) {
                currentRoundParticipants.push(match.player2);
            }
            // player2がBYEの場合、player1が勝ち上がる
            else if (match.player2 && match.player2.isBye) {
                currentRoundParticipants.push(match.player1);
            }
            // どちらもBYEでない場合、勝者プレースホルダーが勝ち上がる
            else {
                currentRoundParticipants.push({ isWinnerPlaceholder: true, winnerOf: match.matchId });
            }
        });

        // ラウンド2以降の既存データをクリア
        bracketRounds.value.splice(1);
        finalWinner.value = null; // 最終勝者もクリア

        // Match IDカウンターをラウンド1の最後のIDから再開
        let maxMatchIdInRound1 = 0;
        bracketRounds.value[0].forEach(match => {
            const matchNum = parseInt(match.matchId.split('-M')[1]);
            if (!isNaN(matchNum) && matchNum > maxMatchIdInRound1) {
                maxMatchIdInRound1 = matchNum;
            }
        });
        globalMatchIdCounter = maxMatchIdInRound1;

        let roundNumber = 2; // ラウンド2から開始

        // 次のラウンドの参加者が1人になるまでループ
        while (currentRoundParticipants.length > 1) {
            const nextRoundMatches = [];
            const nextRoundAdvancingPlayers = [];

            // 現在のラウンドのブラケットサイズ（2のべき乗）とBYEの数を計算
            let currentRoundBracketSize = 1;
            while (currentRoundBracketSize < currentRoundParticipants.length) {
              currentRoundBracketSize *= 2;
            }
            const numByes = currentRoundBracketSize - currentRoundParticipants.length;

            const playersWithBye = currentRoundParticipants.slice(0, numByes);
            const playersPlaying = currentRoundParticipants.slice(numByes);

            // BYE選手はそのまま次のラウンドに進む（ここではBYEの試合は生成しない）
            playersWithBye.forEach(player => {
                nextRoundAdvancingPlayers.push(player);
            });

            // 通常の選手対選手の試合を生成し、次のラウンドに進むプレースホルダーとして追加
            for (let i = 0; i < playersPlaying.length; i += 2) {
                globalMatchIdCounter++;
                const matchId = `R${roundNumber}-M${globalMatchIdCounter}`;
                nextRoundMatches.push({
                    player1: playersPlaying[i],
                    player2: playersPlaying[i + 1],
                    matchId: matchId
                });
                nextRoundAdvancingPlayers.push({ isWinnerPlaceholder: true, winnerOf: matchId }); // 試合の勝者は次のラウンドのプレースホルダーとなる
            }

            // 実際の試合がある場合のみラウンドを追加
            if (nextRoundMatches.length > 0) {
                bracketRounds.value.push(nextRoundMatches);
            }

            currentRoundParticipants = nextRoundAdvancingPlayers;
            roundNumber++;
        }

        // ループ終了後、残っている参加者が1人であれば、それが優勝者
        if (currentRoundParticipants.length === 1) {
            finalWinner.value = currentRoundParticipants[0];
        } else {
            finalWinner.value = null; // 優勝者が未定または異常な状態の場合
        }
    };

    // ブラケットをクリアする関数
    const clearBracket = () => {
      bracketRounds.value = [];
      finalWinner.value = null; // 最終勝者もクリア
      globalMatchIdCounter = 0; // カウンターもリセット
      showSnackbar('トーナメント表をクリアしました。', 'info');
    };

    // トーナメント組み合わせを保存する関数
    const saveBracket = async () => {
      if (!selectedTournamentId.value || !selectedCategoryId.value || bracketRounds.value.length === 0) {
        showSnackbar('保存する組み合わせがありません。大会、カテゴリーを選択し、組み合わせを生成してください。', 'warning');
        return;
      }

      loadingSave.value = true;
      try {
        // UUIDを生成 (簡易的なもの、本番ではサーバーサイドで生成が望ましい)
        const bracketId = crypto.randomUUID();

        const payload = {
          bracket_id: bracketId, // 新しいブラケットID
          tournament_id: selectedTournamentId.value,
          category_id: selectedCategoryId.value,
          bracket_data: JSON.stringify(bracketRounds.value), // JSON文字列として保存
          final_winner_data: finalWinner.value ? JSON.stringify(finalWinner.value) : null // 最終勝者も保存
        };

        // Node-REDのエンドポイントにPOSTリクエスト
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

    // トーナメント組み合わせを読み込む関数
    const loadBracket = async () => {
      if (!selectedTournamentId.value || !selectedCategoryId.value) {
        showSnackbar('組み合わせを読み込むには、大会とカテゴリーを選択してください。', 'warning');
        return;
      }

      loadingLoad.value = true;
      try {
        const response = await axios.get(`http://localhost:1880/load-bracket/${selectedTournamentId.value}/${selectedCategoryId.value}`);

        if (response.data.success) {
          // 読み込んだJSON文字列をパースしてstateに設定
          bracketRounds.value = JSON.parse(response.data.bracket_data);
          finalWinner.value = response.data.final_winner_data ? JSON.parse(response.data.final_winner_data) : null;
          showSnackbar('トーナメント組み合わせを読み込みました！', 'success');
        } else {
          // データが見つからない場合も成功とみなしてクリア
          if (response.status === 404) {
            bracketRounds.value = [];
            finalWinner.value = null;
            showSnackbar(response.data.message || '指定された組み合わせは見つかりませんでした。', 'info');
          } else {
            showSnackbar('読み込みに失敗しました: ' + (response.data.message || '不明なエラー'), 'error');
          }
        }
      } catch (error) {
        console.error('Failed to load bracket:', error);
        // 404エラーの場合は、組み合わせがないことをユーザーに伝える
        if (error.response && error.response.status === 404) {
          bracketRounds.value = [];
          finalWinner.value = null;
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

    /**
     * 各ラウンドの試合ブロックの垂直方向のオフセット（margin-top）を計算する関数。
     * この関数は、現在のラウンドの最初の試合が、前のラウンドの関連する試合群の
     * 垂直方向の中央に配置されるように調整します。
     *
     * @param {number} roundIndex - 現在のラウンドのインデックス (0から始まる)。
     * @returns {string} CSSのmargin-top値（例: "75.5px"）。
     */
    const getRoundMatchesMarginTop = (roundIndex) => {
      if (roundIndex === 0) return '0px';

      // ラウンド0（ラウンド1）の最初の試合の中心Y座標を基準とする
      let currentRoundFirstMatchCenterY = MATCH_BOX_HEIGHT / 2;

      // 過去のラウンドの「ブロック」の半分の垂直スパンを累積加算し、
      // 現在のラウンドの最初の試合の目標中心Y座標を求める。
      // 各ラウンドのブロックの垂直スパンは TOTAL_MATCH_UNIT_HEIGHT * 2^i で表される。
      // その半分を次のラウンドの開始位置に加算していく。
      for (let i = 0; i < roundIndex; i++) {
        currentRoundFirstMatchCenterY += (TOTAL_MATCH_UNIT_HEIGHT * Math.pow(2, i)) / 2;
      }

      // bracket-round コンテナの margin-top は、目標中心Y座標から
      // 試合ボックスの半分の高さを引いた値となる。
      return `${currentRoundFirstMatchCenterY - MATCH_BOX_HEIGHT / 2}px`;
    };

    /**
     * 各試合ボックスの動的なmargin-bottomを計算する関数。
     * ラウンドが進むにつれて、試合間の垂直方向のスペースを広げます。
     *
     * @param {number} roundIndex - 現在のラウンドのインデックス (0から始まる)。
     * @param {number} matchIndex - 現在の試合のインデックス (0から始まる)。
     * @param {number} totalMatchesInRound - 現在のラウンドの総試合数。
     * @returns {string} CSSのmargin-bottom値（例: "30px"）。
     */
    const calculateMatchMarginBottom = (roundIndex, matchIndex, totalMatchesInRound) => {
      // 最終ラウンドの試合には下マージンは不要
      if (roundIndex === bracketRounds.value.length - 1) {
        return '0px';
      }
      // 現在のラウンドの最後の試合には下マージンは不要
      if (matchIndex === totalMatchesInRound - 1) {
        return '0px';
      }

      // 現在のラウンドの試合が属する「ブロック」の総垂直空間を計算。
      // このブロックは次のラウンドの1つの試合に集約される。
      // 例: roundIndex 0 の場合、2^0 = 1 ユニットの高さ (TOTAL_MATCH_UNIT_HEIGHT)。
      // 例: roundIndex 1 の場合、2^1 = 2 ユニットの高さ (TOTAL_MATCH_UNIT_HEIGHT * 2)。
      const verticalSpanOfBlock = TOTAL_MATCH_UNIT_HEIGHT * Math.pow(2, roundIndex);

      // 必要な margin-bottom は、ブロックの総垂直空間から現在の試合ボックスの高さを引いた値。
      // これにより、次の試合（または次のブロックの最初の試合）との間に正確な垂直スペースが確保される。
      const requiredMargin = verticalSpanOfBlock - MATCH_BOX_HEIGHT;

      return `${requiredMargin}px`;
    };

    /**
     * Z字型接続線の垂直部分の高さに必要な動的な垂直間隔を計算する関数。
     * これは、現在の試合ボックスの中心から、次のラウンドの試合ボックスの中心までの垂直距離です。
     *
     * @param {number} roundIndex - 現在のラウンドのインデックス (0から始まる)。
     * @returns {number} 垂直線に必要な高さ (px)。
     */
    const getZLineVerticalSegmentHeight = (roundIndex) => {
      // Z字型接続線の::after要素の高さは、現在の試合の中心から、
      // その試合が属するペアの下側の試合の中心までの垂直距離に等しい。
      // これは、TOTAL_MATCH_UNIT_HEIGHT の 2^roundIndex 倍となる。
      return TOTAL_MATCH_UNIT_HEIGHT * Math.pow(2, roundIndex);
    };

    /**
     * 最終的な勝者ボックスの試合ブロックの垂直方向のオフセット（margin-top）を計算する関数。
     * 最後のラウンドの試合ブロックの垂直位置に合わせます。
     *
     * @returns {string} CSSのmargin-top値。
     */
    const getFinalWinnerMatchesMarginTop = () => {
      if (bracketRounds.value.length === 0) return '0px';
      const lastRoundIndex = bracketRounds.value.length - 1;
      // 最後のラウンドの最初の試合の垂直中央に優勝者ボックスが来るように調整
      // getRoundMatchesMarginTop と同じロジックで計算されるべき。
      return getRoundMatchesMarginTop(lastRoundIndex);
    };

    // --- ドラッグ＆ドロップ関連の関数 ---

    // ドラッグ開始時
    const dragStart = (event, rIdx, mIdx, sType, player) => {
      // ラウンド1のみドラッグ可能
      // 勝者プレースホルダー、BYEプレースホルダーはドラッグ不可
      if (rIdx !== 0 || player?.isWinnerPlaceholder || player?.isBye) {
        event.preventDefault(); // ドラッグを無効化
        return;
      }
      draggedItem.value = { rIdx, mIdx, sType, player };
      event.dataTransfer.effectAllowed = 'move';
      // データ転送オブジェクトに情報を設定 (クロスブラウザ互換性のため)
      event.dataTransfer.setData('application/json', JSON.stringify({ rIdx, mIdx, sType }));
    };

    // ドラッグオーバー時 (ドロップを許可するために必要)
    const dragOver = (event, rIdx, mIdx, sType) => {
      // ラウンド1のみドロップ可能
      // 勝者プレースホルダーの場所にはドロップ不可
      if (rIdx !== 0 || bracketRounds.value[rIdx][mIdx][sType]?.isWinnerPlaceholder) {
        return;
      }
      event.preventDefault(); // デフォルトの動作をキャンセルしてドロップを許可
      dropTarget.value = { rIdx, mIdx, sType }; // ドロップターゲットをマーク (視覚的フィードバック用)
    };

    // ドラッグリーブ時
    const dragLeave = () => {
      dropTarget.value = null; // ドロップターゲットのマークを解除
    };

    // ドロップ時
    const drop = (event, targetRIdx, targetMIdx, targetSType) => {
      // ラウンド1のみドロップ可能
      // 勝者プレースホルダーの場所にはドロップ不可
      if (targetRIdx !== 0 || bracketRounds.value[targetRIdx][targetMIdx][targetSType]?.isWinnerPlaceholder) {
        return;
      }
      event.preventDefault();
      dropTarget.value = null; // ドロップターゲットのマークを解除

      if (!draggedItem.value) {
        return; // ドラッグ中のアイテムがない場合は何もしない
      }

      const sourceRIdx = draggedItem.value.rIdx;
      const sourceMIdx = draggedItem.value.mIdx;
      const sourceSType = draggedItem.value.sType;
      const sourcePlayer = draggedItem.value.player; // ドラッグ開始時のplayerObject

      // 同じスロットにドロップした場合は何もしない
      if (sourceRIdx === targetRIdx && sourceMIdx === targetMIdx && sourceSType === targetSType) {
        draggedItem.value = null;
        return;
      }

      // ターゲットスロットの現在の選手
      const targetPlayer = bracketRounds.value[targetRIdx][targetMIdx][targetSType];

      // BYE選手はドラッグできないが、念のためドロップも不可にする
      if (sourcePlayer?.isBye || targetPlayer?.isBye) {
          showSnackbar('BYEの選手は入れ替えできません。', 'warning');
          draggedItem.value = null;
          return;
      }

      // 選手を入れ替える
      // Vue 3のComposition APIでは、refの.valueを直接変更する
      bracketRounds.value[sourceRIdx][sourceMIdx][sourceSType] = targetPlayer;
      bracketRounds.value[targetRIdx][targetMIdx][targetSType] = sourcePlayer;

      // ドラッグ状態をクリア
      draggedItem.value = null;

      // 選手入れ替え後にラウンド2以降のトーナメント表を再計算
      recalculateSubsequentRounds();
      showSnackbar('選手を入れ替えました！トーナメント表を更新しました！', 'success');
    };

    // ドロップターゲットの視覚的フィードバックを制御するヘルパー関数
    const isDragOverTarget = (rIdx, mIdx, sType) => {
      return dropTarget.value && dropTarget.value.rIdx === rIdx && dropTarget.value.mIdx === mIdx && dropTarget.value.sType === sType;
    };

    onMounted(() => {
      fetchTournamentsList();
    });

    // selectedCategoryIdが変更されたときにloadBracketを自動的に呼び出す
    watch(selectedCategoryId, (newVal) => { // 'oldVal' を削除
      if (newVal && selectedTournamentId.value) {
        loadBracket();
      } else {
        // カテゴリーがクリアされたらブラケットもクリア
        bracketRounds.value = [];
        finalWinner.value = null;
      }
    });

    return {
      tournamentsList,
      categoriesList,
      registeredParticipants,
      bracketRounds,
      finalWinner,
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
      generateBracket,
      clearBracket,
      saveBracket,
      loadBracket,
      getPlayerFullNameWithBranchAndXclass,
      getRoundMatchesMarginTop,
      calculateMatchMarginBottom,
      getZLineVerticalSegmentHeight,
      getFinalWinnerMatchesMarginTop,
      // ドラッグ＆ドロップ関連
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

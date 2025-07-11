<template>
  <v-card class="mx-auto" outlined>
    <v-card-title class="headline">
      五角形戦組み合わせ
    </v-card-title>
    <v-card-text>
      <div v-if="tournamentId && categoryId">
        <v-divider class="my-4"></v-divider>
        <h3 class="text-h6 mb-4">組み合わせ操作 (五角形戦)</h3>
        <v-row>
          <v-col cols="12">
            <v-btn color="primary" class="mr-2" @click="generatePentagonParticipantsOrder" :disabled="loadingGenerate || registeredParticipants.length === 0 || registeredParticipants.length < 5">
              <v-icon left>mdi-shuffle</v-icon>
              選手を五角形に配置
            </v-btn>
            <v-btn color="secondary" class="mr-2" @click="generateInitialMatches" :disabled="loadingGenerate || pentagonParticipantsOrder.length !== 5">
              <v-icon left>mdi-arrow-right-bold</v-icon>
              初期試合生成
            </v-btn>
            <v-btn color="success" class="mr-2" @click="savePentagonMatches" :disabled="loadingSave || pentagonParticipantsOrder.length === 0">
              <v-icon left>mdi-content-save</v-icon>
              組み合わせ保存
            </v-btn>
            <v-btn color="info" @click="loadPentagonMatches" :disabled="loadingLoad">
              <v-icon left>mdi-folder-open</v-icon>
              組み合わせ読み込み
            </v-btn>
          </v-col>
        </v-row>

        <v-divider class="my-4"></v-divider>

        <v-row>
          <v-col cols="12" md="6">
            <h3 class="text-h6 mb-2">五角形配置選手順序 (ドラッグ&ドロップで入れ替え可)</h3>
            <div v-if="pentagonParticipantsOrder.length > 0">
              <draggable
                v-model="pentagonParticipantsOrder"
                item-key="player_id"
                tag="v-list"
                handle=".handle"
                class="elevation-1 pa-2"
                style="min-height: 200px;"
              >
                <template #item="{ element, index }">
                  <div>
                    <v-list-item class="mb-2" :class="{ 'red-border': element.isDummy }">
                      <template #prepend>
                        <v-icon class="handle mr-2" color="grey lighten-1">mdi-drag-vertical</v-icon>
                      </template>
                      <v-list-item-content>
                        <v-list-item-title>
                          頂点 {{ index + 1 }}: {{ getPlayerFullNameWithBranchAndXclass(element).name }}
                          <span v-if="getPlayerFullNameWithBranchAndXclass(element).branch || getPlayerFullNameWithBranchAndXclass(element).xclass">
                            {{ getPlayerFullNameWithBranchAndXclass(element).branch }}{{ getPlayerFullNameWithBranchAndXclass(element).xclass }}
                          </span>
                        </v-list-item-title>
                      </v-list-item-content>
                    </v-list-item>
                    <v-divider v-if="index < pentagonParticipantsOrder.length - 1"></v-divider>
                  </div>
                </template>
              </draggable>
            </div>
            <div v-else>
              <p>「選手を五角形に配置」ボタンで選手を割り当ててください。</p>
            </div>
          </v-col>

          <v-col cols="12" md="6">
            <h3 class="text-h6 mb-2">五角形表示イメージ</h3>
            <div class="pentagon-visual-container">
              <svg :width="svgSize" :height="svgSize" :viewBox="`0 0 ${viewBoxSize} ${viewBoxSize}`" class="pentagon-svg">
                <polygon :points="pentagonPoints" fill="none" stroke="#607D8B" stroke-width="0.5" />

                <g v-for="(player, pentagonParticipantsOrderIndex) in currentPentagonPlayers" :key="player.player_id || `dummy-${pentagonParticipantsOrderIndex}`">
                  <foreignObject
                    :x="playerVisualPositions[pentagonParticipantsOrderIndex].x - visualBoxWidth / 2"
                    :y="playerVisualPositions[pentagonParticipantsOrderIndex].y - visualBoxHeight / 2"
                    :width="visualBoxWidth"
                    :height="visualBoxHeight"
                  >
                    <div class="player-visual-box">
                      <span class="player-name-main">{{ getPlayerFullNameWithBranchAndXclass(player).name }}</span>
                      <span v-if="getPlayerFullNameWithBranchAndXclass(player).branch || getPlayerFullNameWithBranchAndXclass(player).xclass" class="player-name-sub">{{ getPlayerFullNameWithBranchAndXclass(player).branch }} {{ getPlayerFullNameWithBranchAndXclass(player).xclass }}</span>
                    </div>
                  </foreignObject>
                </g>
              </svg>
            </div>
            <p class="text-center text-caption mt-2">
                ※ この五角形は選手の配置イメージです。入れ替えは左側のリストで行ってください。
            </p>
          </v-col>
        </v-row>

        <v-divider class="my-4"></v-divider>
        <h3 class="text-h6 mb-2">初期試合リスト</h3>
        <v-data-table
          :headers="matchHeaders"
          :items="initialMatches"
          item-key="matchId"
          class="elevation-1"
          hide-default-footer
        >
          <template v-slot:[`item.player1`]="{ item }">
            {{ getPlayerFullNameWithBranchAndXclass(item.player1).name }}
            <span class="text-caption">
                {{ getPlayerFullNameWithBranchAndXclass(item.player1).branch }}
                {{ getPlayerFullNameWithBranchAndXclass(item.player1).xclass }}
            </span>
          </template>
          <template v-slot:[`item.player2`]="{ item }">
            {{ getPlayerFullNameWithBranchAndXclass(item.player2).name }}
            <span class="text-caption">
                {{ getPlayerFullNameWithBranchAndXclass(item.player2).branch }}
                {{ getPlayerFullNameWithBranchAndXclass(item.player2).xclass }}
            </span>
          </template>
          <template v-slot:[`item.score`]="{ item }">
            <v-text-field
              v-model="item.score"
              label="スコア"
              dense
              hide-details
              outlined
              class="my-1"
            ></v-text-field>
          </template>
          <template v-slot:[`item.actions`]="{ item }">
            <v-btn icon size="small" @click="addAdditionalMatch(item)">
                <v-icon>mdi-plus-circle-outline</v-icon>
            </v-btn>
          </template>
        </v-data-table>
        <div v-if="initialMatches.length === 0 && pentagonParticipantsOrder.length === 5">
          <p>「初期試合生成」ボタンを押して試合を生成してください。</p>
        </div>
        <div v-else-if="initialMatches.length === 0 && pentagonParticipantsOrder.length !== 5">
            <p>初期試合を生成するには、五角形に5人の選手が配置されている必要があります。</p>
        </div>


        <v-divider class="my-4"></v-divider>
        <h3 class="text-h6 mb-2">追加試合リスト</h3>
        <div v-if="additionalMatches.length > 0">
          <v-data-table
            :headers="matchHeaders"
            :items="additionalMatches"
            item-key="matchId"
            class="elevation-1"
            hide-default-footer
          >
            <template v-slot:[`item.player1`]="{ item }">
              {{ getPlayerFullNameWithBranchAndXclass(item.player1).name }}
              <span class="text-caption">
                {{ getPlayerFullNameWithBranchAndXclass(item.player1).branch }}
                {{ getPlayerFullNameWithBranchAndXclass(item.player1).xclass }}
              </span>
            </template>
            <template v-slot:[`item.player2`]="{ item }">
              {{ getPlayerFullNameWithBranchAndXclass(item.player2).name }}
              <span class="text-caption">
                {{ getPlayerFullNameWithBranchAndXclass(item.player2).branch }}
                {{ getPlayerFullNameWithBranchAndXclass(item.player2).xclass }}
              </span>
            </template>
            <template v-slot:[`item.score`]="{ item }">
              <v-text-field
                v-model="item.score"
                label="スコア"
                dense
                hide-details
                outlined
                class="my-1"
              ></v-text-field>
            </template>
             <template v-slot:[`item.actions`]="{ index }">
                <v-btn icon size="small" color="error" @click="removeAdditionalMatch(index)">
                    <v-icon>mdi-delete</v-icon>
                </v-btn>
            </template>
          </v-data-table>
        </div>
        <div v-else>
          <p>追加試合はまだありません。</p>
        </div>

        <v-divider class="my-4"></v-divider>
        <h3 class="text-h6 mb-2">順位データ</h3>
        <v-btn color="orange" class="mb-4" @click="calculateStandings" :disabled="initialMatches.length === 0">
            <v-icon left>mdi-calculator</v-icon>
            順位を計算
        </v-btn>
        <div v-if="Object.keys(standingsData).length > 0">
          <v-data-table
            :headers="standingsHeaders"
            :items="computedStandings"
            item-key="playerId"
            class="elevation-1"
            hide-default-footer
          >
            <template v-slot:[`item.playerName`]="{ item }">
                {{ getPlayerFullNameWithBranchAndXclass(item.player).name }}
                <span class="text-caption">
                    {{ getPlayerFullNameWithBranchAndXclass(item.player).branch }}
                    {{ getPlayerFullNameWithBranchAndXclass(item.player).xclass }}
                </span>
            </template>
          </v-data-table>
        </div>
        <div v-else>
          <p>順位データはまだありません。「順位を計算」ボタンを押してください。</p>
        </div>

      </div>
      <div v-else>
        <p>大会とカテゴリーを選択してください。</p>
      </div>
    </v-card-text>
  </v-card>
</template>

<script>
import { ref, watch, computed } from 'vue';
import axios from 'axios';
import draggable from 'vuedraggable';

export default {
  name: 'PentagonMatchView',
  components: {
    draggable,
  },
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
      default: () => [],
    },
  },
  emits: ['show-snackbar'],
  setup(props, { emit }) {
    const pentagonParticipantsOrder = ref([]);
    const initialMatches = ref([]);
    const additionalMatches = ref([]);
    const standingsData = ref({});

    const loadingGenerate = ref(false);
    const loadingSave = ref(false);
    const loadingLoad = ref(false);

    const currentPentagonPlayers = computed(() => {
        const players = [...pentagonParticipantsOrder.value];
        while (players.length < 5) {
            players.push({
                player_id: `dummy-${players.length}`,
                familyname: '空き',
                firstname: '',
                branch_nm: '',
                xclass: '',
                isDummy: true
            });
        }
        return players;
    });

    const matchHeaders = [
      { text: '選手1', value: 'player1' },
      { text: '選手2', value: 'player2' },
      { text: 'スコア', value: 'score', sortable: false },
      { text: 'ステータス', value: 'status' },
      { text: 'アクション', value: 'actions', sortable: false },
    ];

    const standingsHeaders = [
      { text: '順位', value: 'rank' },
      { text: '選手名', value: 'playerName' },
      { text: '勝数', value: 'wins' },
      { text: '負数', value: 'losses' },
      { text: '得失点差', value: 'differential' },
    ];

    const showSnackbar = (text, color) => {
      emit('show-snackbar', text, color);
    };

    const getPlayerFullNameWithBranchAndXclass = (player) => {
      if (!player || player.isDummy) return {
          name: '未配置',
          branch: '',
          xclass: ''
      };

      const fullName = `${player.familyname || ''} ${player.firstname || ''}`;
      const branchPart = player.branch_nm ? `（${player.branch_nm}）` : '';
      const xclassPart = player.xclass ? ` ${player.xclass}` : '';
      return {
          name: fullName,
          branch: branchPart,
          xclass: xclassPart
      };
    };

    // ★SVG表示と座標の定数を調整
    const svgSize = 350; // SVG全体の表示サイズを大きくする
    const viewBoxSize = 120; // viewBoxの幅と高さを調整
    const centerX = viewBoxSize / 2; // viewBoxの中心X座標
    const centerY = viewBoxSize / 2; // viewBoxの中心Y座標
    const pentagonRadius = 35; // 五角形の半径を少し小さくする
    const visualBoxWidth = 40;
    const visualBoxHeight = 20; // 選手ボックスの高さを調整

    const pentagonPoints = computed(() => {
        const points = [];
        const startAngle = -Math.PI / 2; // 真上 (Y軸上方向)
        for (let i = 0; i < 5; i++) {
            const angle = startAngle + (i * 2 * Math.PI / 5);
            const x = centerX + pentagonRadius * Math.cos(angle);
            const y = centerY + pentagonRadius * Math.sin(angle);
            points.push(`${x},${y}`);
        }
        return points.join(' ');
    });

    const playerVisualPositions = computed(() => {
        const positions = [];
        const startAngle = -Math.PI / 2; // 真上 (Y軸上方向)
        for (let i = 0; i < 5; i++) {
            const angle = startAngle + (i * 2 * Math.PI / 5);
            const x = centerX + pentagonRadius * Math.cos(angle);
            const y = centerY + pentagonRadius * Math.sin(angle);
            positions.push({ x, y });
        }
        return positions;
    });

    const generatePentagonParticipantsOrder = () => {
        if (props.registeredParticipants.length < 5) {
            showSnackbar('五角形戦は5人以上の登録選手が必要です。', 'warning');
            return;
        }

        loadingGenerate.value = true;
        const shuffledParticipants = [...props.registeredParticipants].sort(() => 0.5 - Math.random());
        pentagonParticipantsOrder.value = shuffledParticipants.slice(0, 5).map(p => ({
            player_id: p.player_id,
            familyname: p.familyname,
            firstname: p.firstname,
            branch_nm: p.branch_nm,
            xclass: p.xclass
        }));
        initialMatches.value = [];
        additionalMatches.value = [];
        standingsData.value = {};
        loadingGenerate.value = false;
        showSnackbar('選手を五角形に配置しました。初期試合を生成してください。', 'success');
    };

    const generateInitialMatches = () => {
        if (pentagonParticipantsOrder.value.length !== 5) {
            showSnackbar('初期試合を生成するには、五角形に5人の選手が配置されている必要があります。', 'warning');
            return;
        }

        loadingGenerate.value = true;
        const newInitialMatches = [];
        for (let i = 0; i < 5; i++) {
            const player1 = pentagonParticipantsOrder.value[i];
            const player2 = pentagonParticipantsOrder.value[(i + 1) % 5];
            newInitialMatches.push({
                matchId: `${player1.player_id}-${player2.player_id}`,
                player1: player1,
                player2: player2,
                score: '',
                status: '未開始'
            });
        }
        initialMatches.value = newInitialMatches;
        additionalMatches.value = [];
        standingsData.value = {};
        loadingGenerate.value = false;
        showSnackbar('初期試合を生成しました！', 'success');
    };

    const addAdditionalMatch = (baseMatch) => {
        additionalMatches.value.push({
            matchId: `add-${Date.now()}`,
            player1: baseMatch ? { ...baseMatch.player1 } : null,
            player2: baseMatch ? { ...baseMatch.player2 } : null,
            score: '',
            status: '未開始',
            isAdditional: true
        });
        showSnackbar('追加試合を追加しました。', 'info');
    };

    const removeAdditionalMatch = (index) => {
        additionalMatches.value.splice(index, 1);
        showSnackbar('追加試合を削除しました。', 'info');
    };

    const calculateStandings = () => {
        const allMatches = [...initialMatches.value, ...additionalMatches.value];
        const playerScores = {};

        pentagonParticipantsOrder.value.forEach(player => {
            playerScores[player.player_id] = {
                wins: 0,
                losses: 0,
                differential: 0,
                player: player
            };
        });

        allMatches.forEach(match => {
            if (!match.score || !match.score.includes('-')) return;

            const [score1, score2] = match.score.split('-').map(Number);

            const p1 = match.player1.player_id;
            const p2 = match.player2.player_id;

            if (isNaN(score1) || isNaN(score2)) return;

            const diff = score1 - score2;
            playerScores[p1].differential += diff;
            playerScores[p2].differential -= diff;

            if (score1 > score2) {
                playerScores[p1].wins += 1;
                playerScores[p2].losses += 1;
            } else if (score2 > score1) {
                playerScores[p2].wins += 1;
                playerScores[p1].losses += 1;
            }
        });

        const sortedStandings = Object.values(playerScores).sort((a, b) => {
            if (b.wins !== a.wins) {
                return b.wins - a.wins;
            }
            if (b.differential !== a.differential) {
                return b.differential - a.differential;
            }
            return 0;
        }).map((data, index) => ({
            rank: index + 1,
            ...data
        }));

        standingsData.value = { players: sortedStandings };
        showSnackbar('順位を計算しました！', 'success');
    };

    const computedStandings = computed(() => {
        return standingsData.value.players || [];
    });

    const savePentagonMatches = async () => {
      if (!props.tournamentId || !props.categoryId) {
        showSnackbar('大会とカテゴリーを選択してください。', 'warning');
        return;
      }
      if (pentagonParticipantsOrder.value.length === 0) {
        showSnackbar('保存する組み合わせがありません。', 'warning');
        return;
      }

      loadingSave.value = true;
      try {
        const response = await axios.post('http://localhost:1880/save-pentagon-bracket', {
          tournament_id: props.tournamentId,
          category_id: props.categoryId,
          pentagon_participants_order: pentagonParticipantsOrder.value,
          initial_matches: initialMatches.value,
          additional_matches: additionalMatches.value,
          standings_data: standingsData.value,
        });

        if (response.data.success) {
          showSnackbar(response.data.message || '五角形戦データを保存しました！', 'success');
        } else {
          showSnackbar(response.data.message || '保存に失敗しました。', 'error');
        }
      } catch (error) {
        console.error('Failed to save pentagon matches:', error);
        showSnackbar('保存中にエラーが発生しました。サーバーとの接続を確認してください。', 'error');
      } finally {
        loadingSave.value = false;
      }
    };

    const loadPentagonMatches = async () => {
      if (!props.tournamentId || !props.categoryId) {
        showSnackbar('組み合わせを読み込むには、大会とカテゴリーを選択してください。', 'warning');
        return;
      }

      loadingLoad.value = true;
      try {
        const response = await axios.get(`http://localhost:1880/load-pentagon-bracket/${props.tournamentId}/${props.categoryId}`);

        if (response.data.success) {
          pentagonParticipantsOrder.value = response.data.pentagon_participants_order || [];
          initialMatches.value = response.data.initial_matches || [];
          additionalMatches.value = response.data.additional_matches || [];
          standingsData.value = response.data.standings_data || {};

          showSnackbar('五角形戦データを読み込みました！', 'success');
        } else {
          pentagonParticipantsOrder.value = [];
          initialMatches.value = [];
          additionalMatches.value = [];
          standingsData.value = {};
          showSnackbar(response.data.message || '指定された五角形戦の組み合わせは見つかりませんでした。', 'info');
        }
      } catch (error) {
        console.error('Failed to load pentagon matches:', error);
        if (error.response && error.response.status === 404) {
             pentagonParticipantsOrder.value = [];
             initialMatches.value = [];
             additionalMatches.value = [];
             standingsData.value = {};
             showSnackbar(error.response.data.message || '指定された五角形戦の組み合わせは見つかりませんでした。', 'info');
        } else {
            showSnackbar('読み込み中にエラーが発生しました。サーバーとの接続を確認してください。', 'error');
        }
      } finally {
        loadingLoad.value = false;
      }
    };

    watch([() => props.tournamentId, () => props.categoryId], ([newTournamentId, newCategoryId]) => {
      if (newTournamentId && newCategoryId) {
        loadPentagonMatches();
      } else {
        pentagonParticipantsOrder.value = [];
        initialMatches.value = [];
        additionalMatches.value = [];
        standingsData.value = {};
      }
    }, { immediate: true });

    return {
      pentagonParticipantsOrder,
      initialMatches,
      additionalMatches,
      standingsData,
      loadingGenerate,
      loadingSave,
      loadingLoad,
      matchHeaders,
      standingsHeaders,
      computedStandings,
      generatePentagonParticipantsOrder,
      generateInitialMatches,
      savePentagonMatches,
      loadPentagonMatches,
      getPlayerFullNameWithBranchAndXclass,
      svgSize,
      viewBoxSize, // 新しい変数
      pentagonPoints,
      playerVisualPositions,
      visualBoxWidth,
      visualBoxHeight,
      currentPentagonPlayers,
      addAdditionalMatch,
      removeAdditionalMatch,
      calculateStandings,
    };
  },
};
</script>

<style scoped>
.pentagon-visual-container {
  display: flex;
  justify-content: center;
  align-items: center;
  margin-top: 20px;
  padding: 10px;
}

.pentagon-svg {
  background-color: #fcfcfc;
  border-radius: 5px;
  box-shadow: 0 2px 5px rgba(0,0,0,0.1);
}

.player-visual-box {
  background-color: #e3f2fd; /* Light blue background */
  border: 1px solid #90CAF9; /* Blue border */
  border-radius: 4px;
  padding: 2px; /* ★paddingを増やす */
  text-align: center;
  box-sizing: border-box;
  color: #1a237e;
  font-weight: bold;
  height: 100%;
  display: flex;
  flex-direction: column; /* 縦並びにするため */
  justify-content: flex-start; /* 上に詰める */
  align-items: center;
  line-height: normal; /* line-heightをnormalに */
  overflow: hidden; /* ボックスからはみ出さないように */
  white-space: normal; /* 折り返しを許可 */
}

.player-name-main {
  display: block;
  font-size: 6px; /* 選手名のメインフォントサイズをpxで指定 */
  white-space: normal;
  overflow: visible;
  text-overflow: clip;
  word-break: break-all;
  line-height: normal; /* line-heightをnormalに */
  font-weight: bold;
  padding: 0;
  margin: 0;
}

.player-name-sub {
  display: block;
  font-size: 4px; /* 支部名とXクラスのフォントサイズをpxで指定 */
  white-space: normal;
  overflow: visible;
  text-overflow: clip;
  word-break: break-all;
  line-height: normal; /* line-heightをnormalに */
  font-weight: normal;
  color: #424242;
  padding: 0;
  margin: 0;
}

/* Draggableリストのスタイル */
.v-list-item {
  background-color: #ffffff;
  margin-bottom: 8px;
  border-radius: 4px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.1);
  cursor: grab;
  transition: box-shadow 0.2s ease-in-out;
}
.v-list-item:hover {
    box-shadow: 0 2px 6px rgba(0,0,0,0.15);
}
.v-list-item.sortable-chosen {
    background-color: #e0f2f7;
    box-shadow: 0 4px 8px rgba(0,0,0,0.2);
}
.v-list-item.sortable-ghost {
    opacity: 0.5;
    background-color: #f0f8ff;
}
.handle {
    cursor: grab;
}
.red-border {
    border: 1px solid red !important;
}
</style>
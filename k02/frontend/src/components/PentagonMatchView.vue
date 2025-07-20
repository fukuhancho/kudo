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
          <template v-slot:[`item.court_id`]="{ item }">
            <select
              v-model="item.court_id"
              @change="updateMatchSchedule(item, 'court', $event.target.value)"
              class="custom-input court-select"
            >
              <option value="" disabled selected>コート</option>
              <option v-for="courtOption in availableCourtOptions" :key="courtOption" :value="courtOption">
                {{ courtOption }}
              </option>
            </select>
          </template>
          <template v-slot:[`item.match_order_no`]="{ item }">
            <input
              type="number"
              v-model.number="item.match_order_no"
              @input="updateMatchSchedule(item, 'order', $event.target.value)"
              min="1"
              placeholder="No."
              class="custom-input match-order-input"
            />
          </template>
          <!-- アクション列を削除 -->
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
            <template v-slot:[`item.court_id`]="{ item }">
              <select
                v-model="item.court_id"
                @change="updateMatchSchedule(item, 'court', $event.target.value)"
                class="custom-input court-select"
              >
                <option value="" disabled selected>コート</option>
                <option v-for="courtOption in availableCourtOptions" :key="courtOption" :value="courtOption">
                  {{ courtOption }}
                </option>
              </select>
            </template>
            <template v-slot:[`item.match_order_no`]="{ item }">
              <input
                type="number"
                v-model.number="item.match_order_no"
                @input="updateMatchSchedule(item, 'order', $event.target.value)"
                min="1"
                placeholder="No."
                class="custom-input match-order-input"
              />
            </template>
            <!-- アクション列を削除 -->
          </v-data-table>
        </div>
        <div v-else>
          <p>追加試合はまだありません。</p>
        </div>

        <v-divider class="my-4"></v-divider>
        <!-- 順位データ (開発用表示) は一時的に非表示にします -->
        <!--
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
        -->

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
    numberOfCourts: {
      type: Number,
      default: 0,
    }
  },
  emits: ['show-snackbar'],
  setup(props, { emit }) {
    const pentagonParticipantsOrder = ref([]);
    const initialMatches = ref([]);
    const additionalMatches = ref([]);
    const standingsData = ref({}); // データ構造は残すが、このビューでは使用しない

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
      { text: 'コート', value: 'court_id', sortable: false, width: '80px' },
      { text: '試合順', value: 'match_order_no', sortable: false, width: '80px' },
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

    const svgSize = 350;
    const viewBoxSize = 120;
    const centerX = viewBoxSize / 2;
    const centerY = viewBoxSize / 2;
    const pentagonRadius = 35;
    const visualBoxWidth = 40;
    const visualBoxHeight = 20;

    const pentagonPoints = computed(() => {
        const points = [];
        const startAngle = -Math.PI / 2;
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
        const startAngle = -Math.PI / 2;
        for (let i = 0; i < 5; i++) {
            const angle = startAngle + (i * 2 * Math.PI / 5);
            const x = centerX + pentagonRadius * Math.cos(angle);
            const y = centerY + pentagonRadius * Math.sin(angle);
            positions.push({ x, y });
        }
        return positions;
    });

    const availableCourtOptions = computed(() => {
      const courts = [];
      for (let i = 0; i < props.numberOfCourts; i++) {
        courts.push(String.fromCharCode(65 + i));
      }
      return courts;
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
        const participants = pentagonParticipantsOrder.value; // A=P0, B=P1, C=P2, D=P3, E=P4

        // 五角形戦の初期試合の定義と順序
        // プレイヤーインデックス: 0=A, 1=B, 2=C, 3=D, 4=E (時計回り)
        // 青/白のルール: 上が青/下が白, 左が青/右が白
        const matchDefinitions = [
            { p1_idx: 0, p2_idx: 1 }, // AvsB (A:左/上, B:右/下 -> Aが青, Bが白)
            { p1_idx: 3, p2_idx: 2 }, // DvsC (D:左/上, C:右/下 -> Dが青, Cが白)
            { p1_idx: 0, p2_idx: 4 }, // AvsE (A:右, E:左 -> Aが青, Eが白) - 修正済み
            { p1_idx: 1, p2_idx: 2 }, // BvsC (B:上, C:下 -> Bが青, Cが白)
            { p1_idx: 4, p2_idx: 3 }  // EvsD (E:上, D:下 -> Eが青, Dが白)
        ];

        matchDefinitions.forEach(def => {
            const player1 = participants[def.p1_idx];
            const player2 = participants[def.p2_idx];
            newInitialMatches.push({
                matchId: `${player1.player_id}-${player2.player_id}`, // 試合IDはplayer1-player2の順で生成
                player1: player1,
                player2: player2,
                score: '', // スコアプロパティは維持
                status: '未開始',
                court_id: null,
                match_order_no: null
            });
        });

        initialMatches.value = newInitialMatches;
        additionalMatches.value = [];
        standingsData.value = {};
        loadingGenerate.value = false;
        showSnackbar('初期試合を生成しました！', 'success');
    };

    // addAdditionalMatch 関数から baseMatch 引数を削除
    const addAdditionalMatch = () => {
        // このビューでは追加試合の手動追加は行わないため、この関数は実際には呼び出されません
        // ただし、もし将来的に必要になった場合に備えて残しておきますが、
        // UIからは削除されているため、ここでの実装は省略します。
        console.warn("addAdditionalMatch is called, but this functionality is currently disabled in UI.");
    };

    // removeAdditionalMatch 関数から index 引数を削除
    const removeAdditionalMatch = () => {
        // このビューでは追加試合の手動削除は行わないため、この関数は実際には呼び出されません
        console.warn("removeAdditionalMatch is called, but this functionality is currently disabled in UI.");
    };

    // calculateStandings 関数は削除
    // computedStandings は削除

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
          standings_data: standingsData.value, // データ構造は保存する
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
          const loadedInitialMatches = response.data.initial_matches || [];
          const loadedAdditionalMatches = response.data.additional_matches || [];

          loadedInitialMatches.forEach(match => {
            if (!('court_id' in match)) match.court_id = null;
            if (!('match_order_no' in match)) match.match_order_no = null;
            if (!('score' in match)) match.score = '';
          });
          loadedAdditionalMatches.forEach(match => {
            if (!('court_id' in match)) match.court_id = null;
            if (!('match_order_no' in match)) match.match_order_no = null;
            if (!('score' in match)) match.score = '';
          });

          initialMatches.value = loadedInitialMatches;
          additionalMatches.value = loadedAdditionalMatches;
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

    const updateMatchSchedule = (match, type, value) => {
      if (match) {
        if (type === 'court') {
          match.court_id = value;
        } else if (type === 'order') {
          match.match_order_no = value === '' ? null : parseInt(value, 10);
          if (isNaN(match.match_order_no)) {
            match.match_order_no = null;
          }
        }
        console.log(`Match ${match.matchId} updated:`, match);
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
      generatePentagonParticipantsOrder,
      generateInitialMatches,
      savePentagonMatches,
      loadPentagonMatches,
      getPlayerFullNameWithBranchAndXclass,
      svgSize,
      viewBoxSize,
      pentagonPoints,
      playerVisualPositions,
      visualBoxWidth,
      visualBoxHeight,
      currentPentagonPlayers,
      addAdditionalMatch, // 関数自体は残す
      removeAdditionalMatch, // 関数自体は残す
      availableCourtOptions,
      updateMatchSchedule,
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
  padding: 2px; /* paddingを増やす */
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

/* 試合スケジュール入力欄のスタイル (v-data-table内用) */
/* v-data-tableのセル内でFlexboxを使うための調整 */
.v-data-table :deep(.v-data-table__td) {
  vertical-align: top; /* セルの内容を上部に揃える */
}

.match-schedule-inputs {
  display: flex;
  gap: 4px; /* 入力フィールド間の隙間 */
  align-items: center; /* 垂直方向中央揃え */
  justify-content: flex-start; /* 左寄せ (スコア入力がないため) */
  margin-top: 4px; /* スコア入力との間に少し余白 */
}

.custom-input {
  max-width: 42px; /* 幅を調整 */
  min-width: 20px;
  height: 24px; /* 高さを調整 */
  font-size: 0.8em; /* フォントサイズを調整 */
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
  background-size: 9px; /* アイコンのサイズ */
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
  font-size: 0.8em;
}
</style>

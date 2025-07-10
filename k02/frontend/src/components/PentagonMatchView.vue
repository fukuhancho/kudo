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
            <v-btn color="primary" class="mr-2" @click="generatePentagonMatches" :disabled="loadingGenerate || registeredParticipants.length === 0">
              <v-icon left>mdi-shuffle</v-icon>
              組み合わせ生成
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
        <h3 class="text-h6 mb-2">五角形の頂点に配置された選手順序</h3>
        <div v-if="pentagonParticipantsOrder.length > 0">
          <v-list dense>
            <v-list-item v-for="(player, index) in pentagonParticipantsOrder" :key="player.player_id">
              <v-list-item-content>
                <v-list-item-title>
                  {{ index + 1 }}. {{ getPlayerFullNameWithBranchAndXclass(player) }}
                </v-list-item-title>
              </v-list-item-content>
            </v-list-item>
          </v-list>
        </div>
        <div v-else>
          <p>五角形戦の選手が配置されていません。組み合わせを生成してください。</p>
        </div>

        <v-divider class="my-4"></v-divider>
        <h3 class="text-h6 mb-2">初期試合リスト</h3>
        <v-data-table
          :headers="matchHeaders"
          :items="initialMatches"
          item-key="matchId"
          class="elevation-1"
          hide-default-footer
        >
          <template v-slot:[`item.player1`]="{ item }">  {{ getPlayerFullNameWithBranchAndXclass(item.player1) }}
          </template>
          <template v-slot:[`item.player2`]="{ item }">  {{ getPlayerFullNameWithBranchAndXclass(item.player2) }}
          </template>
          <template v-slot:[`item.score`]="{ item }">    <v-text-field
              v-model="item.score"
              label="スコア"
              dense
              hide-details
              outlined
              class="my-1"
            ></v-text-field>
          </template>
        </v-data-table>
        <div v-if="initialMatches.length === 0 && !loadingLoad">
          <p>初期試合はまだありません。</p>
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
            <template v-slot:[`item.player1`]="{ item }">  {{ getPlayerFullNameWithBranchAndXclass(item.player1) }}
            </template>
            <template v-slot:[`item.player2`]="{ item }">  {{ getPlayerFullNameWithBranchAndXclass(item.player2) }}
            </template>
            <template v-slot:[`item.score`]="{ item }">    <v-text-field
                v-model="item.score"
                label="スコア"
                dense
                hide-details
                outlined
                class="my-1"
              ></v-text-field>
            </template>
          </v-data-table>
        </div>
        <div v-else>
          <p>追加試合はまだありません。</p>
        </div>

        <v-divider class="my-4"></v-divider>
        <h3 class="text-h6 mb-2">順位データ</h3>
        <div v-if="Object.keys(standingsData).length > 0">
          <pre>{{ JSON.stringify(standingsData, null, 2) }}</pre>
        </div>
        <div v-else>
          <p>順位データはまだありません。</p>
        </div>

      </div>
      <div v-else>
        <p>大会とカテゴリーを選択してください。</p>
      </div>
    </v-card-text>
  </v-card>
</template>

<script>
import { ref, watch } from 'vue';
import axios from 'axios';

export default {
  name: 'PentagonMatchView',
  props: {
    tournamentId: {
      type: [String, Number],
      required: true,
    },
    categoryId: {
      type: [String, Number],
      required: true,
    },
    registeredParticipants: { // 選手登録ビューから渡される参加者リスト
      type: Array,
      default: () => [],
    },
  },
  emits: ['show-snackbar'],
  setup(props, { emit }) {
    // リアクティブなデータ
    const pentagonParticipantsOrder = ref([]); // 五角形の頂点に配置された選手順序
    const initialMatches = ref([]); // 初期試合リスト
    const additionalMatches = ref([]); // 追加試合リスト
    const standingsData = ref({}); // 順位データ

    // ローディング状態
    const loadingGenerate = ref(false);
    const loadingSave = ref(false);
    const loadingLoad = ref(false);

    // 試合表示用のヘッダー (リーグ戦ビューと共通化可能)
    const matchHeaders = [
      { text: '選手1', value: 'player1' },
      { text: '選手2', value: 'player2' },
      { text: 'スコア', value: 'score', sortable: false },
      { text: 'ステータス', value: 'status' },
    ];

    // スナックバー表示ヘルパー
    const showSnackbar = (text, color) => {
      emit('show-snackbar', text, color);
    };

    // 選手名表示ヘルパー (共通化推奨)
    const getPlayerFullNameWithBranchAndXclass = (player) => {
      if (!player) return '未定';
      const fullName = `${player.familyname || ''} ${player.firstname || ''}`;
      const branchPart = player.branch_nm ? `（${player.branch_nm}）` : '';
      const xclassPart = player.xclass ? ` ${player.xclass}` : '';
      return `${fullName}${branchPart}${xclassPart}`;
    };

    // 五角形戦組み合わせ生成ロジック
    // ここに五角形戦の組み合わせ生成アルゴリズムを実装します
    // 例: 登録選手から5人を選び、時計回りに配置し、初期試合を生成
    const generatePentagonMatches = () => {
      loadingGenerate.value = true;
      try {
        if (props.registeredParticipants.length < 5) {
          showSnackbar('五角形戦は5人以上の登録選手が必要です。', 'warning');
          return;
        }

        // ここで五角形戦の組み合わせロジックを実装
        // 例: 登録選手からランダムに5人選択
        const shuffledParticipants = [...props.registeredParticipants].sort(() => 0.5 - Math.random());
        const selectedParticipants = shuffledParticipants.slice(0, 5);

        pentagonParticipantsOrder.value = selectedParticipants.map(p => ({
          player_id: p.player_id,
          familyname: p.familyname,
          firstname: p.firstname,
          branch_nm: p.branch_nm,
          xclass: p.xclass
        }));

        // 初期試合の生成 (例: 隣接する選手同士の試合)
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
        additionalMatches.value = []; // 生成時はクリア
        standingsData.value = {}; // 生成時はクリア

        showSnackbar('五角形戦の組み合わせを生成しました！', 'success');

      } catch (error) {
        console.error('組み合わせ生成中にエラー:', error);
        showSnackbar('組み合わせ生成中にエラーが発生しました。', 'error');
      } finally {
        loadingGenerate.value = false;
      }
    };


    // データ保存ロジック
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
          additional_matches: additionalMatches.value, // 空の可能性あり
          standings_data: standingsData.value, // 空の可能性あり
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

    // データ読み込みロジック
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
          // データが見つからないなどの場合
          pentagonParticipantsOrder.value = [];
          initialMatches.value = [];
          additionalMatches.value = [];
          standingsData.value = {};
          showSnackbar(response.data.message || '指定された五角形戦の組み合わせは見つかりませんでした。', 'info');
        }
      } catch (error) {
        console.error('Failed to load pentagon matches:', error);
        // 404 Not Foundの場合も含むエラー処理
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

    // propsのtournamentIdとcategoryIdが変更されたら自動で読み込み
    watch([() => props.tournamentId, () => props.categoryId], ([newTournamentId, newCategoryId]) => {
      if (newTournamentId && newCategoryId) {
        loadPentagonMatches();
      } else {
        // 大会またはカテゴリーがクリアされた場合、データもクリア
        pentagonParticipantsOrder.value = [];
        initialMatches.value = [];
        additionalMatches.value = [];
        standingsData.value = {};
      }
    }, { immediate: true }); // コンポーネントロード時にも一度実行

    return {
      pentagonParticipantsOrder,
      initialMatches,
      additionalMatches,
      standingsData,
      loadingGenerate,
      loadingSave,
      loadingLoad,
      matchHeaders,
      generatePentagonMatches,
      savePentagonMatches,
      loadPentagonMatches,
      getPlayerFullNameWithBranchAndXclass,
    };
  },
};
</script>

<style scoped>
/* 必要に応じてスタイルを追加 */
</style>
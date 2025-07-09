<template>
  <v-card class="mx-auto" outlined>
    <v-card-title class="headline">組み合わせ作成</v-card-title>
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

      <div v-if="selectedTournamentId && selectedCategoryId && registeredParticipants.length > 0">
        <v-divider class="my-4"></v-divider>
        <h3 class="text-h6 mb-2">組み合わせ形式の選択 (登録選手数: {{ registeredParticipants.length }}名)</h3>
        <v-radio-group v-model="selectedCombinationType" row>
          <v-radio
            label="トーナメント戦 (2名または6名以上推奨)"
            value="tournament"
            :disabled="!canSelectTournament"
          ></v-radio>
          <v-radio
            label="リーグ戦 (3名または4名推奨)"
            value="league"
            :disabled="!canSelectLeague"
          ></v-radio>
          <v-radio
            label="五角形戦 (5名推奨)"
            value="pentagon"
            :disabled="!canSelectPentagon"
          ></v-radio>
        </v-radio-group>

        <v-divider class="my-4"></v-divider>

        <div v-if="selectedCombinationType === 'tournament'">
          <BracketView
            :tournament-id="selectedTournamentId"
            :category-id="selectedCategoryId"
            :registered-participants="registeredParticipants"
            @show-snackbar="showSnackbar"
          />
        </div>
        <div v-else-if="selectedCombinationType === 'league'">
          <LeagueMatchView
            :tournament-id="selectedTournamentId"
            :category-id="selectedCategoryId"
            :registered-participants="registeredParticipants"
            @show-snackbar="showSnackbar"
          />
        </div>
        <div v-else-if="selectedCombinationType === 'pentagon'">
          <PentagonMatchView
            :tournament-id="selectedTournamentId"
            :category-id="selectedCategoryId"
            :registered-participants="registeredParticipants"
            @show-snackbar="showSnackbar"
          />
        </div>
        <div v-else>
          <p class="text-center mt-5 text-subtitle-1">組み合わせ形式を選択してください。</p>
        </div>
      </div>
      <div v-else-if="selectedTournamentId && selectedCategoryId && registeredParticipants.length === 0">
        <p class="text-center mt-5 text-subtitle-1">このカテゴリーには登録選手がいません。選手を登録してください。</p>
      </div>
      <div v-else>
        <p class="text-center mt-5 text-subtitle-1">大会とカテゴリーを選択してください。</p>
      </div>
    </v-card-text>

    <v-snackbar v-model="snackbar" :color="snackbarColor" :timeout="3000">
      {{ snackbarText }}
      <template v-slot:action="{ attrs }">
        <v-btn text v-bind="attrs" @click="snackbar = false">閉じる</v-btn>
      </template>
    </v-snackbar>
  </v-card>
</template>

<script setup>
import { ref, onMounted,  computed } from 'vue';
import axios from 'axios';

// 子コンポーネントをインポート (views/components どちらに置くかでパスを調整)
import BracketView from '../components/BracketView.vue';
import LeagueMatchView from '../components/LeagueMatchView.vue';
import PentagonMatchView from '../components/PentagonMatchView.vue'; // 今後作成

// ----- state variables -----
const tournamentsList = ref([]);
const categoriesList = ref([]);
const registeredParticipants = ref([]); // 選択された大会・カテゴリーに登録済みの選手
const selectedTournamentId = ref(null);
const selectedCategoryId = ref(null);
const selectedCombinationType = ref(null); // 'tournament', 'league', 'pentagon'

const snackbar = ref(false);
const snackbarText = ref('');
const snackbarColor = ref('');

// ----- computed properties for enabling/disabling combination type selection -----
const participantCount = computed(() => registeredParticipants.value.length);

const canSelectTournament = computed(() => {
  // トーナメント戦推奨条件: 2名または6名以上
  return participantCount.value === 2 || participantCount.value >= 6;
});

const canSelectLeague = computed(() => {
  // リーグ戦推奨条件: 3名または4名
  return participantCount.value >= 3 && participantCount.value <= 4;
});

const canSelectPentagon = computed(() => {
  // 五角形戦推奨条件: 5名
  return participantCount.value === 5;
});

// ----- methods -----
// スナックバー表示 (子コンポーネントからのイベントを受け取る)
const showSnackbar = (text, color) => {
  snackbarText.value = text;
  snackbarColor.value = color;
  snackbar.value = true;
};

// 大会リストの取得
const fetchTournamentsList = async () => {
  try {
    const params = new URLSearchParams();
    params.append('sort', 'start_date');
    params.append('order', 'desc');
    const response = await axios.get(`http://localhost:1880/tournaments?${params.toString()}`);
    tournamentsList.value = response.data;
  } catch (error) {
    console.error('Failed to fetch tournaments list:', error);
    showSnackbar('大会リストの取得に失敗しました', 'error');
  }
};

// 選択された大会に紐付けられたカテゴリーの取得
const fetchCategoriesList = async (tournamentId) => {
  categoriesList.value = [];
  selectedCategoryId.value = null; // カテゴリー選択をクリア
  registeredParticipants.value = []; // 登録済み選手もクリア
  selectedCombinationType.value = null; // 形式選択もクリア
  if (!tournamentId) return;
  try {
    const response = await axios.get(`http://localhost:1880/tournament_categories/${tournamentId}`);
    categoriesList.value = response.data;
  } catch (error) {
    console.error('Failed to fetch categories list:', error);
    showSnackbar('カテゴリーリストの取得に失敗しました', 'error');
  }
};

// 選択された大会・カテゴリーに登録済みの出場選手を取得
const fetchRegisteredParticipants = async (tournamentId, categoryId) => {
  registeredParticipants.value = [];
  selectedCombinationType.value = null; // 形式選択をクリア
  if (!tournamentId || !categoryId) return;
  try {
    const response = await axios.get(`http://localhost:1880/tournament-participants-detail/${tournamentId}/${categoryId}`);
    registeredParticipants.value = response.data;

    // 選手数に応じて自動で形式を推奨
    // 適切な組み合わせ形式を自動選択し、ラジオボタンを初期値に設定
    if (canSelectTournament.value) {
      selectedCombinationType.value = 'tournament';
    } else if (canSelectLeague.value) {
      selectedCombinationType.value = 'league';
    } else if (canSelectPentagon.value) {
      selectedCombinationType.value = 'pentagon';
    } else {
      selectedCombinationType.value = null; // 該当なし
      if (registeredParticipants.value.length > 0) {
        showSnackbar('この選手数には推奨される組み合わせ形式がありません。', 'info');
      }
    }

  } catch (error) {
    console.error('Failed to fetch registered participants:', error);
    showSnackbar('出場選手リストの取得に失敗しました', 'error');
  }
};

// 大会選択時のハンドラー
const handleTournamentChange = async (newTournamentId) => {
  selectedTournamentId.value = newTournamentId; // v-modelが自動で更新するが、明示的に
  await fetchCategoriesList(newTournamentId);
};

// カテゴリー選択時のハンドラー
const handleCategoryChange = async (newCategoryId) => {
  selectedCategoryId.value = newCategoryId; // v-modelが自動で更新するが、明示的に
  await fetchRegisteredParticipants(selectedTournamentId.value, newCategoryId);
};

// コンポーネントマウント時に大会リストを取得
onMounted(() => {
  fetchTournamentsList();
});
</script>

<style scoped>
/* 必要に応じてスタイルを追加 */
</style>
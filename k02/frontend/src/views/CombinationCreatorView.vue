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
          <v-radio
            label="試合スケジューリング"
            value="scheduler"
            :disabled="!selectedTournamentId"
          ></v-radio> <!-- ★追加 -->
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
        <div v-else-if="selectedCombinationType === 'scheduler'"> <!-- ★追加 -->
          <MatchSchedulerView
            :tournament-id="selectedTournamentId"
            :category-id="selectedCategoryId"
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

import BracketView from '../components/BracketView.vue';
import LeagueMatchView from '../components/LeagueMatchView.vue';
import PentagonMatchView from '../components/PentagonMatchView.vue';
import MatchSchedulerView from '../components/MatchSchedulerView.vue'; // ★追加

// ----- state variables -----
const tournamentsList = ref([]);
const categoriesList = ref([]);
const registeredParticipants = ref([]);
const selectedTournamentId = ref(null);
const selectedCategoryId = ref(null);
const selectedCombinationType = ref(null);

const snackbar = ref(false);
const snackbarText = ref('');
const snackbarColor = ref('');

// ----- computed properties for enabling/disabling combination type selection -----
const participantCount = computed(() => registeredParticipants.value.length);

const canSelectTournament = computed(() => {
  return participantCount.value === 2 || participantCount.value >= 6;
});

const canSelectLeague = computed(() => {
  return participantCount.value >= 3 && participantCount.value <= 4;
});

const canSelectPentagon = computed(() => {
  return participantCount.value === 5;
});

// ----- methods -----
const showSnackbar = (text, color) => {
  snackbarText.value = text;
  snackbarColor.value = color;
  snackbar.value = true;
};

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

const fetchCategoriesList = async (tournamentId) => {
  categoriesList.value = [];
  selectedCategoryId.value = null;
  registeredParticipants.value = [];
  selectedCombinationType.value = null;
  if (!tournamentId) return;
  try {
    const response = await axios.get(`http://localhost:1880/tournament_categories/${tournamentId}`);
    categoriesList.value = response.data;
  } catch (error) {
    console.error('Failed to fetch categories list:', error);
    showSnackbar('カテゴリーリストの取得に失敗しました', 'error');
  }
};

const fetchRegisteredParticipants = async (tournamentId, categoryId) => {
  registeredParticipants.value = [];
  selectedCombinationType.value = null;
  if (!tournamentId || !categoryId) return;
  try {
    const response = await axios.get(`http://localhost:1880/tournament-participants-detail/${tournamentId}/${categoryId}`);
    registeredParticipants.value = response.data;

    if (canSelectTournament.value) {
      selectedCombinationType.value = 'tournament';
    } else if (canSelectLeague.value) {
      selectedCombinationType.value = 'league';
    } else if (canSelectPentagon.value) {
      selectedCombinationType.value = 'pentagon';
    } else {
      selectedCombinationType.value = null;
      if (registeredParticipants.value.length > 0) {
        showSnackbar('この選手数には推奨される組み合わせ形式がありません。', 'info');
      }
    }

  } catch (error) {
    console.error('Failed to fetch registered participants:', error);
    showSnackbar('出場選手リストの取得に失敗しました', 'error');
  }
};

const handleTournamentChange = async (newTournamentId) => {
  selectedTournamentId.value = newTournamentId;
  await fetchCategoriesList(newTournamentId);
};

const handleCategoryChange = async (newCategoryId) => {
  selectedCategoryId.value = newCategoryId;
  await fetchRegisteredParticipants(selectedTournamentId.value, newCategoryId);
};

onMounted(() => {
  fetchTournamentsList();
});
</script>

<style scoped>
/* 必要に応じてスタイルを追加 */
</style>
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
            :existing-data="existingCombinationData && selectedCombinationType === 'tournament' ? existingCombinationData : null"
            @show-snackbar="showSnackbar"
          />
        </div>
        <div v-else-if="selectedCombinationType === 'league'">
          <LeagueMatchView
            :tournament-id="selectedTournamentId"
            :category-id="selectedCategoryId"
            :registered-participants="registeredParticipants"
            :existing-data="existingCombinationData && selectedCombinationType === 'league' ? existingCombinationData : null"
            @show-snackbar="showSnackbar"
          />
        </div>
        <div v-else-if="selectedCombinationType === 'pentagon'">
          <PentagonMatchView
            :tournament-id="selectedTournamentId"
            :category-id="selectedCategoryId"
            :registered-participants="registeredParticipants"
            :existing-data="existingCombinationData && selectedCombinationType === 'pentagon' ? existingCombinationData : null"
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

    <v-dialog v-model="confirmChangeDialog" max-width="500">
      <v-card>
        <v-card-title class="headline">組み合わせ形式の変更確認</v-card-title>
        <v-card-text>
          選択した組み合わせ形式を変更すると、この大会のこのカテゴリーに**既存の試合データがある場合、それらは全て削除されます。**<br>
          よろしいですか？
        </v-card-text>
        <v-card-actions>
          <v-spacer></v-spacer>
          <v-btn color="error" text @click="cancelCombinationTypeChange">キャンセル</v-btn>
          <v-btn color="primary" @click="confirmCombinationTypeChange">変更して削除する</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <v-snackbar v-model="snackbar" :color="snackbarColor" :timeout="3000">
      {{ snackbarText }}
      <template v-slot:action="{ attrs }">
        <v-btn text v-bind="attrs" @click="snackbar = false">閉じる</v-btn>
      </template>
    </v-snackbar>
  </v-card>
</template>


<script setup>
import { ref, onMounted, computed, watch } from 'vue';
import axios from 'axios';

import BracketView from '../components/BracketView.vue';
import LeagueMatchView from '../components/LeagueMatchView.vue';
import PentagonMatchView from '../components/PentagonMatchView.vue';

// ----- state variables -----
const tournamentsList = ref([]);
const categoriesList = ref([]);
const registeredParticipants = ref([]);
const selectedTournamentId = ref(null);
const selectedCategoryId = ref(null);
const selectedCombinationType = ref(null);
const existingCombinationData = ref(null);

const snackbar = ref(false);
const snackbarText = ref('');
const snackbarColor = ref('');

const confirmChangeDialog = ref(false);
const previousCombinationType = ref(null);
const isSettingCombinationTypeProgrammatically = ref(false); 

// ----- computed properties for enabling/disabling combination type selection -----
const participantCount = computed(() => registeredParticipants.value.length);

const canSelectTournament = computed(() => {
  return participantCount.value >= 2;
});

const canSelectLeague = computed(() => {
  return participantCount.value >= 2;
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
  existingCombinationData.value = null;
  previousCombinationType.value = null;
  isSettingCombinationTypeProgrammatically.value = false; 
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
  existingCombinationData.value = null;
  previousCombinationType.value = null;
  isSettingCombinationTypeProgrammatically.value = true; 

  if (!tournamentId || !categoryId) {
    isSettingCombinationTypeProgrammatically.value = false;
    return;
  }

  try {
    const participantsResponse = await axios.get(`http://localhost:1880/tournament-participants-detail/${tournamentId}/${categoryId}`);
    registeredParticipants.value = participantsResponse.data;

    const existingDataResponse = await axios.get(`http://localhost:1880/combination_data/${tournamentId}/${categoryId}`);
    if (existingDataResponse.data.success && existingDataResponse.data.data) {
      selectedCombinationType.value = existingDataResponse.data.type;
      existingCombinationData.value = existingDataResponse.data.data;
      showSnackbar(`既存の${existingDataResponse.data.type}戦組み合わせを読み込みました。`, 'success');
    } else {
      existingCombinationData.value = null;
      if (participantCount.value === 5) {
        selectedCombinationType.value = 'pentagon';
      } else if (participantCount.value >= 2) {
        selectedCombinationType.value = 'tournament';
      } else {
        selectedCombinationType.value = null;
        if (registeredParticipants.value.length > 0) {
          showSnackbar('この選手数には推奨される組み合わせ形式がありません。', 'info');
        }
      }
      showSnackbar('既存の組み合わせデータは見つかりませんでした。', 'info');
    }

  } catch (error) {
    console.error('Failed to fetch registered participants or existing combination data:', error);
    if (error.response && error.response.status === 404 && error.config.url.includes('combination_data')) {
        showSnackbar('既存の組み合わせデータは見つかりませんでした。', 'info');
        existingCombinationData.value = null;
        if (participantCount.value === 5) {
          selectedCombinationType.value = 'pentagon';
        } else if (participantCount.value >= 2) {
          selectedCombinationType.value = 'tournament';
        } else {
          selectedCombinationType.value = null;
        }
    } else {
        showSnackbar('出場選手リストまたは組み合わせデータの取得中にエラーが発生しました。', 'error');
        existingCombinationData.value = null;
        selectedCombinationType.value = null;
    }
  } finally {
    isSettingCombinationTypeProgrammatically.value = false; 
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

watch(selectedCombinationType, async (newType, oldType) => {
  if (isSettingCombinationTypeProgrammatically.value) {
    previousCombinationType.value = newType;
    return;
  }

  if (oldType === null || oldType === undefined || newType === oldType) {
    previousCombinationType.value = newType;
    return;
  }

  previousCombinationType.value = oldType;
  confirmChangeDialog.value = true;
});


const confirmCombinationTypeChange = async () => {
  confirmChangeDialog.value = false;
  if (selectedTournamentId.value && selectedCategoryId.value && previousCombinationType.value) {
    try {
      const response = await axios.delete(
        `http://localhost:1880/matches/${selectedTournamentId.value}/${selectedCategoryId.value}/${previousCombinationType.value}`
      );
      if (response.data.success) {
        showSnackbar('既存の試合データを削除し、組み合わせ形式を変更しました。', 'success');
        existingCombinationData.value = null;
        isSettingCombinationTypeProgrammatically.value = true; 
      } else {
        showSnackbar('既存試合データの削除に失敗しました: ' + (response.data.message || '不明なエラー'), 'error');
        selectedCombinationType.value = previousCombinationType.value;
      }
    } catch (error) {
      console.error('Failed to delete existing matches:', error);
      showSnackbar('既存試合データの削除中にエラーが発生しました。', 'error');
      selectedCombinationType.value = previousCombinationType.value;
    } finally {
        isSettingCombinationTypeProgrammatically.value = false; 
    }
  } else {
    showSnackbar('必要な情報が不足しているため、既存試合データの削除をスキップしました。', 'warning');
    selectedCombinationType.value = previousCombinationType.value;
  }
};

const cancelCombinationTypeChange = () => {
  isSettingCombinationTypeProgrammatically.value = true;
  confirmChangeDialog.value = false;
  selectedCombinationType.value = previousCombinationType.value;
  showSnackbar('組み合わせ形式の変更をキャンセルしました。', 'info');
  setTimeout(() => {
    isSettingCombinationTypeProgrammatically.value = false;
  }, 0);
};

onMounted(() => {
  fetchTournamentsList();
});

</script>

<style scoped>
/* 必要に応じてスタイルを追加 */
</style>
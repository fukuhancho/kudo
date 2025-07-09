<template>
  <v-card class="mx-auto" outlined>
    <v-card-title class="headline">
      出場選手登録
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
        <h3 class="text-h6 mb-2">登録済み出場選手 ({{ registeredParticipants.length }}名)</h3>
        <v-data-table
          :headers="participantHeaders"
          :items="registeredParticipants"
          :loading="loadingParticipants"
          :items-per-page="50"
          class="elevation-1"
        >
          <template v-slot:[`item.full_name_with_kana`]="{ item }">
            {{ getFullNameWithKana(item) }}
          </template>
          <template v-slot:[`item.sex`]="{ item }">
            <v-icon v-if="item.sex === 'm'" color="blue">mdi-gender-male</v-icon>
            <v-icon v-else-if="item.sex === 'f'" color="pink">mdi-gender-female</v-icon>
            <v-icon v-else>mdi-gender-transgender</v-icon>
          </template>
          <template v-slot:[`item.age`]="{ item }">
            {{ calculateAge(item.birthday) }}
          </template>
          <template v-slot:[`item.physical_index`]="{ item }">
            {{ calculatePhysicalIndex(item.height, item.weight) }}
          </template>
          <template v-slot:[`item.actions`]="{ item }">
            <v-icon small @click="removeParticipant(item)">
              mdi-delete
            </v-icon>
          </template>
          <template v-slot:no-data>
            <p>このカテゴリーにはまだ選手が登録されていません。</p>
          </template>
        </v-data-table>

        <v-divider class="my-4"></v-divider>
        <h3 class="text-h6 mb-2">追加可能な選手 ({{ eligiblePlayers.length }}名)</h3>
        <v-row>
          <v-col cols="12" sm="6" md="4">
            <v-select
              v-model="selectedPlayerToAdd"
              :items="eligiblePlayers"
              item-title="full_name_with_kana_with_branch"
              item-value="player_unique_id"
              label="追加する選手を選択"
              clearable
            ></v-select>
          </v-col>
          <v-col cols="12" sm="6" md="2" class="d-flex align-center">
            <v-btn
              color="success"
              @click="addParticipant"
              :disabled="!selectedPlayerToAdd || loadingAddParticipant"
            >
              <v-icon left>mdi-plus</v-icon>
              追加
            </v-btn>
          </v-col>
        </v-row>
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
import { ref, onMounted, computed } from 'vue';
import axios from 'axios';

export default {
  name: 'TournamentParticipantView',
  setup() {
    const tournamentsList = ref([]); // 大会選択ドロップダウン用
    const categoriesList = ref([]);    // 選択された大会に紐付けられたカテゴリー
    const allPlayers = ref([]);        // 全選手リスト
    const selectedTournamentId = ref(null);
    const selectedCategoryId = ref(null);
    const registeredParticipants = ref([]); // 選択された大会・カテゴリーに登録済みの選手
    const selectedPlayerToAdd = ref(null);  // 追加する選手のユニークID (branch_id-player_id)

    const currentCategoryRules = ref(null); // 選択されたカテゴリーのルール

    const loadingTournaments = ref(false);
    const loadingCategories = ref(false);
    const loadingPlayers = ref(false);
    const loadingParticipants = ref(false);
    const loadingAddParticipant = ref(false);
    const loadingRemoveParticipant = ref(false);
    const loadingCategoryRules = ref(false);

    const snackbar = ref(false);
    const snackbarText = ref('');
    const snackbarColor = ref('');

    const participantHeaders = [
      { title: '選手ID', value: 'player_id', sortable: true },
      { title: '氏名', value: 'full_name_with_kana', sortable: false },
      { title: '', value: 'sex', sortable: false }, // 性別アイコン
      { title: '年齢', value: 'age', sortable: true },
      { title: '体力指数', value: 'physical_index', sortable: true },
      { title: '操作', value: 'actions', sortable: false },
    ];

    // --- ヘルパー関数 ---
    // 氏名＋フリガナを結合して表示する関数 (一覧表示用)
    const getFullNameWithKana = (player) => {
      const familyname = player.familyname || '';
      const firstname = player.firstname || '';
      const familyname2 = player.familyname2 || '';
      const firstname2 = player.firstname2 || '';

      let fullName = `${familyname} ${firstname}`;
      let fullKana = '';

      if (familyname2 || firstname2) {
        fullKana = `（${familyname2} ${firstname2}）`;
      }
      return `${fullName}${fullKana}`;
    };

    // ★追加: 氏名＋フリガナ＋支部名を結合して表示する関数 (ドロップダウン用)
    const getFullNameWithKanaAndBranch = (player) => {
      const namePart = getFullNameWithKana(player);
      const branchPart = player.branch_nm ? ` (${player.branch_nm})` : '';
      return `${namePart}${branchPart}`;
    };

    // 年齢計算 (現在の年の12月31日時点での満年齢)
    const calculateAge = (birthdayString) => {
      if (!birthdayString) return '';
      const birthDate = new Date(birthdayString.split('T')[0]);
      if (isNaN(birthDate.getTime())) return '';

      const today = new Date();
      const currentYear = today.getFullYear();
      const endOfYear = new Date(currentYear, 11, 31); // 月は0から始まるため11が12月

      let age = endOfYear.getFullYear() - birthDate.getFullYear();
      const monthDiff = endOfYear.getMonth() - birthDate.getMonth();
      const dayDiff = endOfYear.getDate() - birthDate.getDate();

      if (monthDiff < 0 || (monthDiff === 0 && dayDiff < 0)) {
        age--;
      }
      return `${age}歳`;
    };

    // 体力指数計算 (身長 + 体重)
    const calculatePhysicalIndex = (height, weight) => {
      const actualHeight = height !== null ? parseFloat((height / 10).toFixed(1)) : 0;
      const actualWeight = weight !== null ? parseFloat((weight / 10).toFixed(1)) : 0;

      const index = actualHeight + actualWeight;
      if (index === 0 && (height === null || weight === null)) return '';
      if (index === 0) return '0.0';

      return `${index.toFixed(1)} (${actualHeight.toFixed(1)}+${actualWeight.toFixed(1)})`;
    };
    // --- ヘルパー関数ここまで ---

    // カテゴリーのルールに基づいて選手が適格かどうかを判断する
    const isPlayerEligible = (player, rules) => {
      if (!rules) return false;

      // 年齢チェック
      const playerAge = parseInt(calculateAge(player.birthday)); // "XX歳"からXXを抽出
      if (!isNaN(playerAge)) {
        if (rules.age_min !== null && playerAge < rules.age_min) return false;
        if (rules.age_max !== null && playerAge > rules.age_max) return false;
      } else if (rules.age_min !== null || rules.age_max !== null) {
        // 年齢ルールがあるのに生年月日がない場合は不適格
        return false;
      }

      // 体力指数チェック
      const playerPhysicalIndex = parseFloat(calculatePhysicalIndex(player.height, player.weight)); // "XX.X (YY.Y+ZZ.Z)"からXX.Xを抽出
      if (!isNaN(playerPhysicalIndex)) {
        if (rules.physical_index_min !== null && playerPhysicalIndex < rules.physical_index_min) return false;
        if (rules.physical_index_max !== null && playerPhysicalIndex > rules.physical_index_max) return false;
      } else if (rules.physical_index_min !== null || rules.physical_index_max !== null) {
        // 体力指数ルールがあるのに身長体重がない場合は不適格
        return false;
      }

      // 性別ルールチェック
      if (rules.sex_rule && rules.sex_rule !== 'any' && player.sex !== rules.sex_rule) {
        return false;
      }

      return true;
    };

    // 追加可能な選手リスト (まだ登録されておらず、選択されたカテゴリーのルールに合致する選手)
    const eligiblePlayers = computed(() => {
      if (!selectedCategoryId.value || !currentCategoryRules.value) return [];

      const registeredPlayerUniqueIds = new Set(
        registeredParticipants.value.map(p => `${p.branch_id}-${p.player_id}`)
      );

      return allPlayers.value
        .filter(player => !registeredPlayerUniqueIds.has(`${player.branch_id}-${player.player_id}`))
        .filter(player => isPlayerEligible(player, currentCategoryRules.value))
        .map(player => ({
          ...player,
          // ドロップダウン表示用に結合された氏名とユニークIDを追加
          full_name_with_kana: getFullNameWithKana(player),
          full_name_with_kana_with_branch: getFullNameWithKanaAndBranch(player), // ★追加
          player_unique_id: `${player.branch_id}-${player.player_id}`,
        }));
    });

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

    // 全選手リストの取得
    const fetchAllPlayers = async () => {
      loadingPlayers.value = true;
      try {
        // Node-REDの/playersエンドポイントはbranch_idが指定されない場合、全選手を返します。
        // もし、特定の支部で絞り込む場合は、クエリパラメータbranch_idを追加してください。
        const response = await axios.get('http://localhost:1880/players'); 
        allPlayers.value = response.data;
      } catch (error) {
        console.error('Failed to fetch all players:', error);
        showSnackbar('全選手リストの取得に失敗しました', 'error');
      } finally {
        loadingPlayers.value = false;
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
        // 選手詳細情報（氏名、性別、生年月日、身長、体重、支部名）も結合して取得するAPIを想定
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

    // カテゴリーのルールを取得
    const fetchCategoryRules = async (categoryId) => {
      if (!categoryId) {
        currentCategoryRules.value = null;
        return;
      }
      loadingCategoryRules.value = true;
      try {
        // カテゴリー詳細情報（ルール）を取得するAPIを想定
        const response = await axios.get(`http://localhost:1880/categories/${categoryId}`);
        currentCategoryRules.value = response.data || null; // カテゴリーオブジェクト全体をルールとして使用
      } catch (error) {
        console.error('Failed to fetch category rules:', error);
        showSnackbar('カテゴリールールの取得に失敗しました', 'error');
        currentCategoryRules.value = null;
      } finally {
        loadingCategoryRules.value = false;
      }
    };

    // 大会選択時のハンドラー
    const handleTournamentChange = async (newTournamentId) => {
      selectedCategoryId.value = null; // カテゴリー選択をクリア
      registeredParticipants.value = []; // 登録済み選手をクリア
      selectedPlayerToAdd.value = null; // 追加選手選択をクリア
      currentCategoryRules.value = null; // カテゴリールールをクリア

      await fetchCategoriesList(newTournamentId); // 紐付けられたカテゴリーを再取得
    };

    // カテゴリー選択時のハンドラー
    const handleCategoryChange = async (newCategoryId) => {
      selectedPlayerToAdd.value = null; // 追加選手選択をクリア
      await fetchCategoryRules(newCategoryId); // カテゴリールールを取得
      await fetchRegisteredParticipants(selectedTournamentId.value, newCategoryId); // 登録済み選手を再取得
    };

    // 出場選手追加
    const addParticipant = async () => {
      if (!selectedTournamentId.value || !selectedCategoryId.value || !selectedPlayerToAdd.value) {
        showSnackbar('大会、カテゴリー、追加する選手を選択してください', 'warning');
        return;
      }

      loadingAddParticipant.value = true;
      try {
        // selectedPlayerToAdd は "branch_id-player_id" 形式
        const [branch_id, player_id] = selectedPlayerToAdd.value.split('-');
        
        const payload = {
          tournament_id: selectedTournamentId.value,
          category_id: selectedCategoryId.value,
          player_id: player_id,
          branch_id: branch_id,
          status: 'confirmed', // デフォルトで確定
        };
        await axios.post('http://localhost:1880/tournament-participants', payload);
        showSnackbar('選手を出場登録しました', 'success');
        selectedPlayerToAdd.value = null; // 追加後クリア
        fetchRegisteredParticipants(selectedTournamentId.value, selectedCategoryId.value); // リストを更新
      } catch (error) {
        console.error('Failed to add participant:', error);
        showSnackbar('出場登録に失敗しました', 'error');
      } finally {
        loadingAddParticipant.value = false;
      }
    };

    // 出場選手削除
    const removeParticipant = async (item) => {
      if (!selectedTournamentId.value || !selectedCategoryId.value || !item.player_id || !item.branch_id) {
        showSnackbar('大会、カテゴリー、削除する選手を選択してください', 'warning');
        return;
      }

      if (!confirm(`選手「${getFullNameWithKana(item)}」をこのカテゴリーから削除しますか？`)) {
        return;
      }

      loadingRemoveParticipant.value = true;
      try {
        await axios.delete(`http://localhost:1880/tournament-participants/${selectedTournamentId.value}/${item.category_id}/${item.player_id}/${item.branch_id}`);
        showSnackbar('選手を出場リストから削除しました', 'success');
        fetchRegisteredParticipants(selectedTournamentId.value, selectedCategoryId.value); // リストを更新
      } catch (error) {
        console.error('Failed to remove participant:', error);
        showSnackbar('出場リストからの削除に失敗しました', 'error');
      } finally {
        loadingRemoveParticipant.value = false;
      }
    };

    // スナックバーの表示
    const showSnackbar = (text, color) => {
      snackbarText.value = text;
      snackbarColor.value = color;
      snackbar.value = true;
    };

    // コンポーネントマウント時に初期データを取得
    onMounted(() => {
      fetchTournamentsList();
      fetchAllPlayers();
    });

    return {
      tournamentsList,
      categoriesList,
      selectedTournamentId,
      selectedCategoryId,
      registeredParticipants,
      allPlayers, // デバッグ用などに残す
      selectedPlayerToAdd,
      loadingTournaments,
      loadingCategories,
      loadingPlayers,
      loadingParticipants,
      loadingAddParticipant,
      loadingRemoveParticipant,
      loadingCategoryRules,
      snackbar,
      snackbarText,
      snackbarColor,
      participantHeaders,
      eligiblePlayers,
      handleTournamentChange,
      handleCategoryChange,
      addParticipant,
      removeParticipant,
      getFullNameWithKana,
      calculateAge,
      calculatePhysicalIndex,
    };
  },
};
</script>

<style scoped>
/* 必要であれば、ここにコンポーネント固有のスタイルを追加 */
</style>

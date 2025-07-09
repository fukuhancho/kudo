<template>
  <v-card class="mx-auto" outlined>
    <v-card-title class="headline">
      大会カテゴリー設定
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
      </v-row>

      <div v-if="selectedTournamentId">
        <v-divider class="my-4"></v-divider>
        <h3 class="text-h6 mb-2">選択中の大会カテゴリー</h3>
        <v-data-table
          :headers="linkedCategoryHeaders"
          :items="linkedCategories"
          :loading="loadingLinkedCategories"
          :items-per-page="50"
          class="elevation-1"
        >
          <template v-slot:[`item.actions`]="{ item }">
            <v-icon small @click="removeCategory(item)">
              mdi-delete
            </v-icon>
          </template>
          <template v-slot:no-data>
            <p>この大会にはまだカテゴリーが設定されていません。</p>
          </template>
        </v-data-table>

        <v-divider class="my-4"></v-divider>
        <h3 class="text-h6 mb-2">追加可能なカテゴリー</h3>
        <v-row>
          <v-col cols="12" sm="6" md="4">
            <v-select
              v-model="selectedCategoryToAdd"
              :items="availableCategoriesOptions"
              item-title="category_nm"
              item-value="category_id"
              label="追加するカテゴリーを選択"
              clearable
            ></v-select>
          </v-col>
          <v-col cols="12" sm="6" md="2" class="d-flex align-center">
            <v-btn
              color="success"
              @click="addCategory"
              :disabled="!selectedCategoryToAdd || loadingAddCategory"
            >
              <v-icon left>mdi-plus</v-icon>
              追加
            </v-btn>
          </v-col>
        </v-row>
      </div>
      <div v-else>
        <p class="text-center mt-5 text-subtitle-1">大会を選択してください。</p>
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
  name: 'TournamentCategoryView',
  setup() {
    const tournamentsList = ref([]); // 大会選択ドロップダウン用
    const allCategories = ref([]);    // 全カテゴリーリスト
    const selectedTournamentId = ref(null);
    const linkedCategories = ref([]); // 選択された大会に紐付けられたカテゴリー
    const selectedCategoryToAdd = ref(null); // 追加するカテゴリーのID

    const loadingTournaments = ref(false);
    const loadingCategories = ref(false);
    const loadingLinkedCategories = ref(false);
    const loadingAddCategory = ref(false);
    const loadingRemoveCategory = ref(false);

    const snackbar = ref(false);
    const snackbarText = ref('');
    const snackbarColor = ref('');

    const linkedCategoryHeaders = [
      { title: 'カテゴリーID', value: 'category_id', sortable: true },
      { title: 'カテゴリー名', value: 'category_nm', sortable: true },
      { title: '操作', value: 'actions', sortable: false },
    ];

    // 利用可能なカテゴリー（まだ紐付けられていないカテゴリー）
    const availableCategoriesOptions = computed(() => {
      const linkedIds = new Set(linkedCategories.value.map(c => c.category_id));
      return allCategories.value.filter(cat => !linkedIds.has(cat.category_id));
    });

    // 大会リストの取得
    const fetchTournamentsList = async () => {
      loadingTournaments.value = true;
      try {
        const params = new URLSearchParams();
        // ★追加: ソート順をクエリパラメータとして追加
        params.append('sort', 'start_date');
        params.append('order', 'desc');
        // 必要であれば、ここでもfilter=all を明示的に指定できますが、
        // Node-RED側でソートパラメータがない場合はデフォルトで全件取得されるため、必須ではありません。
        // params.append('filter', 'all'); 

        const response = await axios.get(`http://localhost:1880/tournaments?${params.toString()}`);
        tournamentsList.value = response.data;
      } catch (error) {
        console.error('Failed to fetch tournaments list:', error);
        showSnackbar('大会リストの取得に失敗しました', 'error');
      } finally {
        loadingTournaments.value = false;
      }
    };

    // 全カテゴリーリストの取得
    const fetchAllCategories = async () => {
      loadingCategories.value = true;
      try {
        const response = await axios.get('http://localhost:1880/categories');
        allCategories.value = response.data;
      } catch (error) {
        console.error('Failed to fetch all categories:', error);
        showSnackbar('カテゴリーリストの取得に失敗しました', 'error');
      } finally {
        loadingCategories.value = false;
      }
    };

    // 選択された大会に紐付けられたカテゴリーの取得
    const fetchLinkedCategories = async (tournamentId) => {
      if (!tournamentId) {
        linkedCategories.value = [];
        return;
      }
      loadingLinkedCategories.value = true;
      try {
        const response = await axios.get(`http://localhost:1880/tournament_categories/${tournamentId}`);
        linkedCategories.value = response.data;
      } catch (error) {
        console.error('Failed to fetch linked categories:', error);
        showSnackbar('紐付けられたカテゴリーの取得に失敗しました', 'error');
        linkedCategories.value = [];
      } finally {
        loadingLinkedCategories.value = false;
      }
    };

    // 大会選択時のハンドラー
    const handleTournamentChange = (newTournamentId) => {
      selectedCategoryToAdd.value = null; // 選択中の追加カテゴリーをクリア
      fetchLinkedCategories(newTournamentId);
    };

    // カテゴリー追加
    const addCategory = async () => {
      if (!selectedTournamentId.value || !selectedCategoryToAdd.value) {
        showSnackbar('大会と追加するカテゴリーを選択してください', 'warning');
        return;
      }

      loadingAddCategory.value = true;
      try {
        const payload = {
          tournament_id: selectedTournamentId.value,
          category_id: selectedCategoryToAdd.value,
        };
        await axios.post('http://localhost:1880/tournament_categories', payload);
        showSnackbar('カテゴリーを追加しました', 'success');
        selectedCategoryToAdd.value = null; // 追加後クリア
        fetchLinkedCategories(selectedTournamentId.value); // リストを更新
      } catch (error) {
        console.error('Failed to add category:', error);
        showSnackbar('カテゴリーの追加に失敗しました', 'error');
      } finally {
        loadingAddCategory.value = false;
      }
    };

    // カテゴリー削除
    const removeCategory = async (item) => {
      if (!selectedTournamentId.value || !item.category_id) {
        showSnackbar('大会と削除するカテゴリーを選択してください', 'warning');
        return;
      }

      // 削除確認ダイアログは今回は省略し、直接削除
      if (!confirm(`カテゴリー「${item.category_nm}」をこの大会から削除しますか？`)) {
        return;
      }

      loadingRemoveCategory.value = true;
      try {
        await axios.delete(`http://localhost:1880/tournament_categories/${selectedTournamentId.value}/${item.category_id}`);
        showSnackbar('カテゴリーを削除しました', 'success');
        fetchLinkedCategories(selectedTournamentId.value); // リストを更新
      } catch (error) {
        console.error('Failed to remove category:', error);
        showSnackbar('カテゴリーの削除に失敗しました', 'error');
      } finally {
        loadingRemoveCategory.value = false;
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
      fetchTournamentsList(); // 大会リストをソート順で取得
      fetchAllCategories();
    });

    return {
      tournamentsList,
      allCategories,
      selectedTournamentId,
      linkedCategories,
      selectedCategoryToAdd,
      loadingTournaments,
      loadingCategories,
      loadingLinkedCategories,
      loadingAddCategory,
      loadingRemoveCategory,
      snackbar,
      snackbarText,
      snackbarColor,
      linkedCategoryHeaders,
      availableCategoriesOptions,
      handleTournamentChange,
      addCategory,
      removeCategory,
      fetchLinkedCategories,
    };
  },
};
</script>

<style scoped>
/* 必要であれば、ここにコンポーネント固有のスタイルを追加 */
</style>

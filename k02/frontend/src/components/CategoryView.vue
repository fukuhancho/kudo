<template>
  <v-card class="mx-auto" outlined>
    <v-card-title class="headline">
      カテゴリー一覧
      <v-spacer></v-spacer>
      <v-btn color="primary" @click="openDialog('add')">新規登録</v-btn>
    </v-card-title>
    <v-card-text>
      <v-data-table
        :headers="headers"
        :items="categories"
        :loading="loading"
        :items-per-page="50"
        class="elevation-1"
        fixed-header
        height="400px"
      >
        <template v-slot:[`item.age_range`]="{ item }">
          {{ formatAgeRange(item.age_min, item.age_max) }}
        </template>
        <template v-slot:[`item.physical_index_range`]="{ item }">
          {{ formatPhysicalIndexRange(item.physical_index_min, item.physical_index_max) }}
        </template>
        <template v-slot:[`item.sex_rule`]="{ item }">
          {{ formatSexRule(item.sex_rule) }}
        </template>
        <template v-slot:[`item.actions`]="{ item }">
          <v-icon small class="mr-2" @click="editCategory(item)">
            mdi-pencil
          </v-icon>
          <v-icon small @click="deleteCategory(item)">
            mdi-delete
          </v-icon>
        </template>
        <template v-slot:no-data>
          <v-btn color="primary" @click="fetchCategories">
            カテゴリーデータをロードする
          </v-btn>
        </template>
      </v-data-table>
    </v-card-text>

    <v-dialog v-model="dialog" max-width="600px">
      <v-card>
        <v-card-title>
          <span class="headline">{{ formTitle }}</span>
        </v-card-title>
        <v-card-text>
          <v-container>
            <v-text-field
              v-model="editedItem.category_id"
              label="カテゴリーID"
              :disabled="isEditMode"
              required
              :rules="[v => !!v || 'カテゴリーIDは必須です']"
            ></v-text-field>
            <v-text-field
              v-model="editedItem.category_nm"
              label="カテゴリー名"
              required
              :rules="[v => !!v || 'カテゴリー名は必須です']"
            ></v-text-field>
            <v-text-field
              v-model.number="editedItem.age_min"
              label="最低年齢"
              type="number"
              min="0"
            ></v-text-field>
            <v-text-field
              v-model.number="editedItem.age_max"
              label="最高年齢"
              type="number"
              min="0"
            ></v-text-field>
            <v-text-field
              v-model.number="editedItem.physical_index_min"
              label="最低体力指数"
              type="number"
              step="0.1"
            ></v-text-field>
            <v-text-field
              v-model.number="editedItem.physical_index_max"
              label="最高体力指数"
              type="number"
              step="0.1"
            ></v-text-field>
            <v-select
              v-model="editedItem.sex_rule"
              :items="sexRuleOptions"
              item-title="text"
              item-value="value"
              label="性別ルール"
              required
              :rules="[v => !!v || '性別ルールは必須です']"
            ></v-select>
            <v-textarea
              v-model="editedItem.remarks"
              label="備考"
              rows="3"
            ></v-textarea>
          </v-container>
        </v-card-text>
        <v-card-actions>
          <v-spacer></v-spacer>
          <v-btn color="blue darken-1" text @click="closeDialog">キャンセル</v-btn>
          <v-btn color="blue darken-1" text @click="saveCategory">保存</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <v-dialog v-model="dialogDelete" max-width="500px">
      <v-card>
        <v-card-title class="headline">このカテゴリーを削除しますか？</v-card-title>
        <v-card-actions>
          <v-spacer></v-spacer>
          <v-btn color="blue darken-1" text @click="closeDeleteDialog">キャンセル</v-btn>
          <v-btn color="blue darken-1" text @click="confirmDelete">削除</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

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
  name: 'CategoryView',
  setup() {
    const categories = ref([]);
    const loading = ref(false);
    const dialog = ref(false);
    const dialogDelete = ref(false);
    const editedIndex = ref(-1);
    const editedItem = ref({
      category_id: '',
      category_nm: '',
      age_min: null,
      age_max: null,
      physical_index_min: null,
      physical_index_max: null,
      sex_rule: '',
      remarks: '',
    });

    const defaultItem = {
      category_id: '',
      category_nm: '',
      age_min: null,
      age_max: null,
      physical_index_min: null,
      physical_index_max: null,
      sex_rule: '',
      remarks: '',
    };

    const snackbar = ref(false);
    const snackbarText = ref('');
    const snackbarColor = ref('');

    const headers = [
      { title: 'カテゴリーID', value: 'category_id', sortable: true },
      { title: 'カテゴリー名', value: 'category_nm', sortable: true },
      { title: '年齢', value: 'age_range', sortable: false },
      { title: '体力指数', value: 'physical_index_range', sortable: false },
      { title: '性別ルール', value: 'sex_rule', sortable: false },
      { title: '備考', value: 'remarks', sortable: false },
      { title: '操作', value: 'actions', sortable: false },
    ];

    const sexRuleOptions = [
      { text: '男性', value: 'm' },
      { text: '女性', value: 'f' },
      { text: '不問', value: 'any' },
    ];

    const formTitle = computed(() => {
      return editedIndex.value === -1 ? '新規カテゴリー登録' : 'カテゴリー情報編集';
    });

    const isEditMode = computed(() => {
      return editedIndex.value !== -1;
    });

    const formatAgeRange = (min, max) => {
      if (min === null && max === null) return '制限なし';
      if (min !== null && max === null) return `${min}歳以上`;
      if (min === null && max !== null) return `${max}歳以下`;
      return `${min}歳～${max}歳`;
    };

    const formatPhysicalIndexRange = (min, max) => {
      // ★修正: parseFloatで数値に変換
      const parsedMin = min !== null ? parseFloat(min) : null;
      const parsedMax = max !== null ? parseFloat(max) : null;

      if (parsedMin === null && parsedMax === null) return '制限なし';
      if (parsedMin !== null && parsedMax === null) return `${parsedMin.toFixed(1)}以上`;
      if (parsedMin === null && parsedMax !== null) return `${parsedMax.toFixed(1)}以下`;
      return `${parsedMin.toFixed(1)}～${parsedMax.toFixed(1)}`;
    };

    const formatSexRule = (rule) => {
      switch (rule) {
        case 'm': return '男性';
        case 'f': return '女性';
        case 'any': return '不問';
        default: return '';
      }
    };

    const fetchCategories = async () => {
      loading.value = true;
      try {
        const response = await axios.get('http://localhost:1880/categories');
        categories.value = response.data;
        showSnackbar('カテゴリー情報を取得しました', 'success');
      } catch (error) {
        console.error('Failed to fetch categories:', error);
        showSnackbar('カテゴリー情報の取得に失敗しました', 'error');
        categories.value = [];
      } finally {
        loading.value = false;
      }
    };

    const openDialog = (mode, item = null) => {
      if (mode === 'add') {
        editedIndex.value = -1;
        editedItem.value = { ...defaultItem };
      } else if (mode === 'edit' && item) {
        editedIndex.value = categories.value.indexOf(item);
        editedItem.value = {
          ...item,
          // 数値型はnullでない限りNumber()で変換
          age_min: item.age_min !== null ? Number(item.age_min) : null,
          age_max: item.age_max !== null ? Number(item.age_max) : null,
          physical_index_min: item.physical_index_min !== null ? Number(item.physical_index_min) : null,
          physical_index_max: item.physical_index_max !== null ? Number(item.physical_index_max) : null,
        };
      }
      dialog.value = true;
    };

    const editCategory = (item) => {
      openDialog('edit', item);
    };

    const closeDialog = () => {
      dialog.value = false;
      editedIndex.value = -1;
      editedItem.value = { ...defaultItem };
    };

    const saveCategory = async () => {
      if (!editedItem.value.category_id || !editedItem.value.category_nm || !editedItem.value.sex_rule) {
        showSnackbar('カテゴリーID、カテゴリー名、性別ルールは必須です', 'error');
        return;
      }

      const payload = { ...editedItem.value };
      // 数値型フィールドが空文字列の場合はnullに変換
      payload.age_min = payload.age_min === '' ? null : payload.age_min;
      payload.age_max = payload.age_max === '' ? null : payload.age_max;
      payload.physical_index_min = payload.physical_index_min === '' ? null : payload.physical_index_min;
      payload.physical_index_max = payload.physical_index_max === '' ? null : payload.physical_index_max;

      try {
        if (editedIndex.value === -1) {
          // 新規作成
          await axios.post('http://localhost:1880/categories', payload);
          showSnackbar('カテゴリーを新規登録しました', 'success');
        } else {
          // 更新
          await axios.put(`http://localhost:1880/categories/${payload.category_id}`, payload);
          showSnackbar('カテゴリー情報を更新しました', 'success');
        }
        closeDialog();
        fetchCategories(); // リストを再取得
      } catch (error) {
        console.error('Failed to save category:', error);
        showSnackbar('カテゴリー情報の保存に失敗しました', 'error');
      }
    };

    const deleteCategory = (item) => {
      editedIndex.value = categories.value.indexOf(item);
      editedItem.value = { ...item };
      dialogDelete.value = true;
    };

    const closeDeleteDialog = () => {
      dialogDelete.value = false;
      editedIndex.value = -1;
      editedItem.value = { ...defaultItem };
    };

    const confirmDelete = async () => {
      try {
        await axios.delete(`http://localhost:1880/categories/${editedItem.value.category_id}`);
        showSnackbar('カテゴリーを削除しました', 'success');
        closeDeleteDialog();
        fetchCategories(); // リストを再取得
      } catch (error) {
        console.error('Failed to delete category:', error);
        showSnackbar('カテゴリーの削除に失敗しました', 'error');
      }
    };

    const showSnackbar = (text, color) => {
      snackbarText.value = text;
      snackbarColor.value = color;
      snackbar.value = true;
    };

    onMounted(fetchCategories);

    return {
      categories,
      loading,
      headers,
      dialog,
      dialogDelete,
      editedItem,
      formTitle,
      isEditMode,
      snackbar,
      snackbarText,
      snackbarColor,
      sexRuleOptions,
      fetchCategories,
      openDialog,
      editCategory,
      closeDialog,
      saveCategory,
      deleteCategory,
      closeDeleteDialog,
      confirmDelete,
      formatAgeRange,
      formatPhysicalIndexRange,
      formatSexRule,
    };
  },
};
</script>

<style scoped>
/* 必要であれば、ここにコンポーネント固有のスタイルを追加 */
</style>

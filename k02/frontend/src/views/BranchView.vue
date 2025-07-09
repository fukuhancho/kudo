<template>
  <v-card class="mx-auto" outlined>
    <v-card-title class="headline">
      支部一覧
      <v-spacer></v-spacer>
      <v-btn color="primary" @click="openDialog('add')">新規登録</v-btn>
    </v-card-title>
    <v-card-text>
      <v-data-table
        :headers="headers"
        :items="branches"
        :loading="loading"
        :items-per-page="50"
        class="elevation-1"
      >
        <template v-slot:[`item.actions`]="{ item }">
          <v-icon small class="mr-2" @click="editBranch(item)">
            mdi-pencil
          </v-icon>
          <v-icon small @click="deleteBranch(item)">
            mdi-delete
          </v-icon>
        </template>
        <template v-slot:no-data>
          <v-btn color="primary" @click="fetchBranches">
            データをロードする
          </v-btn>
        </template>
      </v-data-table>
    </v-card-text>

    <v-dialog v-model="dialog" max-width="500px">
      <v-card>
        <v-card-title>
          <span class="headline">{{ formTitle }}</span>
        </v-card-title>
        <v-card-text>
          <v-container>
            <v-text-field
              v-model="editedItem.branch_id"
              label="支部ID"
              :disabled="isEditMode"
              required
            ></v-text-field>
            <v-text-field
              v-model="editedItem.branch_nm"
              label="支部名"
              required
            ></v-text-field>
            <v-text-field
              v-model="editedItem.branch_nm2"
              label="支部名(フリガナ)"
            ></v-text-field>
          </v-container>
        </v-card-text>
        <v-card-actions>
          <v-spacer></v-spacer>
          <v-btn color="blue darken-1" text @click="closeDialog">キャンセル</v-btn>
          <v-btn color="blue darken-1" text @click="saveBranch">保存</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <v-dialog v-model="dialogDelete" max-width="500px">
      <v-card>
        <v-card-title class="headline">この支部を削除しますか？</v-card-title>
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
  name: 'BranchView', // コンポーネント名を適切に設定
  setup() {
    const branches = ref([]);
    const loading = ref(false);
    const dialog = ref(false);
    const dialogDelete = ref(false);
    const editedIndex = ref(-1);
    const editedItem = ref({
      branch_id: '',
      branch_nm: '',
      branch_nm2: '',
    });
    const defaultItem = {
      branch_id: '',
      branch_nm: '',
      branch_nm2: '',
    };
    const snackbar = ref(false);
    const snackbarText = ref('');
    const snackbarColor = ref('');

    const headers = [
      { text: '支部ID', value: 'branch_id' },
      { text: '支部名', value: 'branch_nm' },
      { text: '支部名(フリガナ)', value: 'branch_nm2' },
      { text: '登録日時', value: 'created' },
      { text: '操作', value: 'actions', sortable: false },
    ];

    const formTitle = computed(() => {
      return editedIndex.value === -1 ? '新規支部登録' : '支部情報編集';
    });

    const isEditMode = computed(() => {
      return editedIndex.value !== -1;
    });

    // 支部情報の取得
    const fetchBranches = async () => {
      loading.value = true;
      try {
        const response = await axios.get('http://localhost:1880/branches');
        branches.value = response.data;
        showSnackbar('支部情報を取得しました', 'success');
      } catch (error) {
        console.error('Failed to fetch branches:', error);
        showSnackbar('支部情報の取得に失敗しました', 'error');
      } finally {
        loading.value = false;
      }
    };

    // ダイアログを開く
    const openDialog = (mode, item = null) => {
      if (mode === 'add') {
        editedIndex.value = -1;
        editedItem.value = { ...defaultItem };
      } else if (mode === 'edit' && item) {
        editedIndex.value = branches.value.indexOf(item);
        editedItem.value = { ...item };
      }
      dialog.value = true;
    };

    // 支部編集
    const editBranch = (item) => {
      openDialog('edit', item);
    };

    // ダイアログを閉じる
    const closeDialog = () => {
      dialog.value = false;
      editedIndex.value = -1;
      editedItem.value = { ...defaultItem };
    };

    // 支部情報の保存 (新規作成/更新)
    const saveBranch = async () => {
      if (!editedItem.value.branch_id || !editedItem.value.branch_nm) {
        showSnackbar('支部IDと支部名は必須です', 'error');
        return;
      }

      try {
        if (editedIndex.value === -1) {
          // 新規作成
          await axios.post('http://localhost:1880/branches', editedItem.value);
          showSnackbar('支部を新規登録しました', 'success');
        } else {
          // 更新
          await axios.put(`http://localhost:1880/branches/${editedItem.value.branch_id}`, editedItem.value);
          showSnackbar('支部情報を更新しました', 'success');
        }
        closeDialog();
        fetchBranches(); // リストを再取得
      } catch (error) {
        console.error('Failed to save branch:', error);
        showSnackbar('支部情報の保存に失敗しました', 'error');
      }
    };

    // 支部削除確認
    const deleteBranch = (item) => {
      editedIndex.value = branches.value.indexOf(item);
      editedItem.value = { ...item };
      dialogDelete.value = true;
    };

    // 削除ダイアログを閉じる
    const closeDeleteDialog = () => {
      dialogDelete.value = false;
      editedIndex.value = -1;
      editedItem.value = { ...defaultItem };
    };

    // 支部削除実行
    const confirmDelete = async () => {
      try {
        await axios.delete(`http://localhost:1880/branches/${editedItem.value.branch_id}`);
        showSnackbar('支部を削除しました', 'success');
        closeDeleteDialog();
        fetchBranches(); // リストを再取得
      } catch (error) {
        console.error('Failed to delete branch:', error);
        showSnackbar('支部の削除に失敗しました', 'error');
      }
    };

    // スナックバーの表示
    const showSnackbar = (text, color) => {
      snackbarText.value = text;
      snackbarColor.value = color;
      snackbar.value = true;
    };

    // コンポーネントマウント時にデータを取得
    onMounted(fetchBranches);

    return {
      branches,
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
      fetchBranches,
      openDialog,
      editBranch,
      closeDialog,
      saveBranch,
      deleteBranch,
      closeDeleteDialog,
      confirmDelete,
    };
  },
};
</script>
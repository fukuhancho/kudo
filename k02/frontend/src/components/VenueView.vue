<template>
  <v-card class="mx-auto" outlined>
    <v-card-title class="headline">
      会場一覧
      <v-spacer></v-spacer>
      <v-btn color="primary" @click="openDialog('add')">新規登録</v-btn>
    </v-card-title>
    <v-card-text>
      <v-data-table
        :headers="headers"
        :items="venues"
        :loading="loading"
        :items-per-page="50"
        class="elevation-1"
        fixed-header
        height="400px"
      >
        <template v-slot:[`item.created`]="{ item }">
          {{ formatDate(item.created) }}
        </template>
        <template v-slot:[`item.actions`]="{ item }">
          <v-icon small class="mr-2" @click="editVenue(item)">
            mdi-pencil
          </v-icon>
          <v-icon small @click="deleteVenue(item)">
            mdi-delete
          </v-icon>
        </template>
        <template v-slot:no-data>
          <v-btn color="primary" @click="fetchVenues">
            会場データをロードする
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
              v-model="editedItem.venue_id"
              label="会場ID"
              :disabled="isEditMode"
              required
              :rules="[v => !!v || '会場IDは必須です']"
            ></v-text-field>
            <v-text-field
              v-model="editedItem.venue_nm"
              label="会場名"
              required
              :rules="[v => !!v || '会場名は必須です']"
            ></v-text-field>
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
          <v-btn color="blue darken-1" text @click="saveVenue">保存</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <v-dialog v-model="dialogDelete" max-width="500px">
      <v-card>
        <v-card-title class="headline">この会場を削除しますか？</v-card-title>
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
  name: 'VenueView',
  setup() {
    const venues = ref([]);
    const loading = ref(false);
    const dialog = ref(false);
    const dialogDelete = ref(false);
    const editedIndex = ref(-1);
    const editedItem = ref({
      venue_id: '',
      venue_nm: '',
      remarks: '',
    });

    const defaultItem = {
      venue_id: '',
      venue_nm: '',
      remarks: '',
    };

    const snackbar = ref(false);
    const snackbarText = ref('');
    const snackbarColor = ref('');

    // ヘッダーの定義
    const headers = [
      { title: '会場ID', value: 'venue_id', sortable: true }, // Vuetify 3: 'text' -> 'title'
      { title: '会場名', value: 'venue_nm', sortable: true },
      { title: '備考', value: 'remarks', sortable: false },
      { title: '登録日時', value: 'created', sortable: true },
      { title: '操作', value: 'actions', sortable: false },
    ];

    const formTitle = computed(() => {
      return editedIndex.value === -1 ? '新規会場登録' : '会場情報編集';
    });

    const isEditMode = computed(() => {
      return editedIndex.value !== -1;
    });

    // 日付をYYYY-MM-DD 形式にフォーマット (一覧表示用)
    const formatDate = (dateString) => {
      if (!dateString) return '';
      // データベースから取得した日付文字列がISO形式（例: '2015-09-15T00:00:00.000Z'）の場合、
      // new Date() にそのまま渡すとタイムゾーンの影響を受けることがあります。
      // 'T'で分割して日付部分だけを抽出し、ブラウザのタイムゾーンに依存せず正しい日付を扱えるようにします。
      const date = new Date(dateString.split('T')[0]);
      // Dateオブジェクトが不正な場合は空文字列を返す
      if (isNaN(date.getTime())) return ''; 
      const year = date.getFullYear();
      const month = String(date.getMonth() + 1).padStart(2, '0'); // 月は0から始まるため+1
      const day = String(date.getDate()).padStart(2, '0');       // 日を取得
      return `${year}-${month}-${day}`;
    };

    // 会場情報の取得
    const fetchVenues = async () => {
      loading.value = true;
      try {
        const response = await axios.get('http://localhost:1880/venues');
        venues.value = response.data;
        showSnackbar('会場情報を取得しました', 'success');
      } catch (error) {
        console.error('Failed to fetch venues:', error);
        showSnackbar('会場情報の取得に失敗しました', 'error');
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
        editedIndex.value = venues.value.indexOf(item);
        editedItem.value = { ...item };
      }
      dialog.value = true;
    };

    // 会場編集
    const editVenue = (item) => {
      openDialog('edit', item);
    };

    // ダイアログを閉じる
    const closeDialog = () => {
      dialog.value = false;
      editedIndex.value = -1;
      editedItem.value = { ...defaultItem };
    };

    // 会場情報の保存 (新規作成/更新)
    const saveVenue = async () => {
      if (!editedItem.value.venue_id || !editedItem.value.venue_nm) {
        showSnackbar('会場IDと会場名は必須です', 'error');
        return;
      }

      try {
        if (editedIndex.value === -1) {
          // 新規作成
          await axios.post('http://localhost:1880/venues', editedItem.value);
          showSnackbar('会場を新規登録しました', 'success');
        } else {
          // 更新
          await axios.put(`http://localhost:1880/venues/${editedItem.value.venue_id}`, editedItem.value);
          showSnackbar('会場情報を更新しました', 'success');
        }
        closeDialog();
        fetchVenues(); // リストを再取得
      } catch (error) {
        console.error('Failed to save venue:', error);
        showSnackbar('会場情報の保存に失敗しました', 'error');
      }
    };

    // 会場削除確認
    const deleteVenue = (item) => {
      editedIndex.value = venues.value.indexOf(item);
      editedItem.value = { ...item };
      dialogDelete.value = true;
    };

    // 削除ダイアログを閉じる
    const closeDeleteDialog = () => {
      dialogDelete.value = false;
      editedIndex.value = -1;
      editedItem.value = { ...defaultItem };
    };

    // 会場削除実行
    const confirmDelete = async () => {
      try {
        await axios.delete(`http://localhost:1880/venues/${editedItem.value.venue_id}`);
        showSnackbar('会場を削除しました', 'success');
        closeDeleteDialog();
        fetchVenues(); // リストを再取得
      } catch (error) {
        console.error('Failed to delete venue:', error);
        showSnackbar('会場の削除に失敗しました', 'error');
      }
    };

    // スナックバーの表示
    const showSnackbar = (text, color) => {
      snackbarText.value = text;
      snackbarColor.value = color;
      snackbar.value = true;
    };

    // コンポーネントマウント時にデータを取得
    onMounted(fetchVenues);

    return {
      venues,
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
      fetchVenues,
      openDialog,
      editVenue,
      closeDialog,
      saveVenue,
      deleteVenue,
      closeDeleteDialog,
      confirmDelete,
      formatDate, // 日付フォーマット関数を公開
    };
  },
};
</script>

<style scoped>
/* 必要であれば、ここにコンポーネント固有のスタイルを追加 */
</style>

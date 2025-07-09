<template>
  <v-card class="mx-auto" outlined>
    <v-card-title class="headline">
      大会一覧
      <v-spacer></v-spacer>
      <v-btn color="primary" @click="openDialog('add')">新規登録</v-btn>
    </v-card-title>
    <v-card-text>
      <v-row>
        <v-col cols="12" sm="6" md="4">
          <v-select
            v-model="filterOption"
            :items="filterOptions"
            item-title="text"
            item-value="value"
            label="開催期間で絞り込み"
            @update:modelValue="fetchTournaments"
          ></v-select>
        </v-col>
      </v-row>
      <v-data-table
        :headers="headers"
        :items="tournaments"
        :loading="loading"
        :items-per-page="50"
        class="elevation-1"
        fixed-header
        height="400px"
      >
        <template v-slot:[`item.start_date`]="{ item }">
          {{ formatDate(item.start_date) }}
        </template>
        <template v-slot:[`item.end_date`]="{ item }">
          {{ formatDate(item.end_date) }}
        </template>
        <template v-slot:[`item.venue_nm`]="{ item }">
          {{ getVenueName(item.venue_id) }}
        </template>
        <template v-slot:[`item.actions`]="{ item }">
          <v-icon small class="mr-2" @click="editTournament(item)">
            mdi-pencil
          </v-icon>
          <v-icon small @click="deleteTournament(item)">
            mdi-delete
          </v-icon>
        </template>
        <template v-slot:no-data>
          <v-btn color="primary" @click="fetchTournaments">
            大会データをロードする
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
              v-model="editedItem.tournament_id"
              label="大会ID"
              :disabled="isEditMode"
              required
              :rules="[v => !!v || '大会IDは必須です']"
            ></v-text-field>
            <v-text-field
              v-model="editedItem.tournament_nm"
              label="大会名称"
              required
              :rules="[v => !!v || '大会名称は必須です']"
            ></v-text-field>

            <v-menu
              v-model="menuStartDate"
              :close-on-content-click="false"
              transition="scale-transition"
              offset-y
              max-width="290px"
              min-width="auto"
            >
              <template v-slot:activator="{ props }">
                <v-text-field
                  v-model="formattedStartDate"
                  label="開催開始日"
                  prepend-icon="mdi-calendar"
                  readonly
                  v-bind="props"
                  required
                  :rules="[v => !!v || '開催開始日は必須です']"
                ></v-text-field>
              </template>
              <v-date-picker
                v-model="editedItem.start_date"
                locale="ja"
                @update:modelValue="menuStartDate = false"
              ></v-date-picker>
            </v-menu>

            <v-menu
              v-model="menuEndDate"
              :close-on-content-click="false"
              transition="scale-transition"
              offset-y
              max-width="290px"
              min-width="auto"
            >
              <template v-slot:activator="{ props }">
                <v-text-field
                  v-model="formattedEndDate"
                  label="開催終了日"
                  prepend-icon="mdi-calendar"
                  readonly
                  v-bind="props"
                ></v-text-field>
              </template>
              <v-date-picker
                v-model="editedItem.end_date"
                locale="ja"
                @update:modelValue="menuEndDate = false"
              ></v-date-picker>
            </v-menu>

            <v-select
              v-model="editedItem.venue_id"
              :items="venuesList"
              item-title="venue_nm"
              item-value="venue_id"
              label="会場"
              clearable
              required
              :rules="[v => !!v || '会場は必須です']"
            ></v-select>

            <v-select
              v-model.number="editedItem.number_coat"
              :items="coatOptions"
              label="コート数"
              clearable
              :rules="[v => (v === null || v === '' || v >= 0) || 'コート数は0以上の数値です']"
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
          <v-btn color="blue darken-1" text @click="saveTournament">保存</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <v-dialog v-model="dialogDelete" max-width="500px">
      <v-card>
        <v-card-title class="headline">この大会を削除しますか？</v-card-title>
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
import { ref, onMounted, computed, watch } from 'vue'; // ★watchをインポート
import axios from 'axios';

export default {
  name: 'TournamentView',
  setup() {
    const tournaments = ref([]);
    const venuesList = ref([]); // 会場選択肢用
    const loading = ref(false);
    const dialog = ref(false);
    const dialogDelete = ref(false);
    const editedIndex = ref(-1);
    const editedItem = ref({
      tournament_id: '',
      tournament_nm: '',
      start_date: null,
      end_date: null,
      venue_id: '',
      number_coat: null,
      remarks: '',
    });

    const defaultItem = {
      tournament_id: '',
      tournament_nm: '',
      start_date: null,
      end_date: null,
      venue_id: '',
      number_coat: null,
      remarks: '',
    };

    const snackbar = ref(false);
    const snackbarText = ref('');
    const snackbarColor = ref('');

    // Date Picker のメニュー表示を制御する ref
    const menuStartDate = ref(false);
    const menuEndDate = ref(false);

    // 開催期間絞り込み用の ref とオプション
    const filterOption = ref('1year'); // デフォルトで1年以内
    const filterOptions = [
      { text: '1年以内', value: '1year' },
      { text: '3年以内', value: '3year' },
      { text: '全て', value: 'all' },
    ];

    // コート数選択肢
    const coatOptions = [1, 2, 3, 4]; // 1から4までの選択肢

    // ヘッダーの定義
    const headers = [
      { title: '大会ID', value: 'tournament_id', sortable: true },
      { title: '大会名称', value: 'tournament_nm', sortable: true },
      { title: '開催開始日', value: 'start_date', sortable: true },
      { title: '開催終了日', value: 'end_date', sortable: true },
      { title: '会場', value: 'venue_nm', sortable: false }, // 会場名を表示
      { title: 'コート数', value: 'number_coat', sortable: true },
      { title: '備考', value: 'remarks', sortable: false },
      { title: '操作', value: 'actions', sortable: false },
    ];

    const formTitle = computed(() => {
      return editedIndex.value === -1 ? '新規大会登録' : '大会情報編集';
    });

    const isEditMode = computed(() => {
      return editedIndex.value !== -1;
    });

    // 日付をYYYY-MM-DD 形式にフォーマット (一覧表示 & テキストフィールド表示用)
    const formatDate = (dateValue) => {
      if (!dateValue) return '';
      const date = new Date(dateValue);
      if (isNaN(date.getTime())) return '';
      const year = date.getFullYear();
      const month = String(date.getMonth() + 1).padStart(2, '0');
      const day = String(date.getDate()).padStart(2, '0');
      return `${year}-${month}-${day}`;
    };

    // 開催開始日用の算出プロパティ
    const formattedStartDate = computed({
      get: () => formatDate(editedItem.value.start_date),
      set: (val) => {
        editedItem.value.start_date = val ? new Date(val) : null;
      },
    });

    // 開催終了日用の算出プロパティ
    const formattedEndDate = computed({
      get: () => formatDate(editedItem.value.end_date),
      set: (val) => {
        editedItem.value.end_date = val ? new Date(val) : null;
      },
    });

    // 会場IDから会場名を取得
    const getVenueName = (venueId) => {
      const venue = venuesList.value.find(v => v.venue_id === venueId);
      return venue ? venue.venue_nm : venueId; // 見つからない場合はIDをそのまま表示
    };

    // 大会情報の取得
    const fetchTournaments = async () => {
      loading.value = true;
      try {
        const params = new URLSearchParams();
        if (filterOption.value && filterOption.value !== 'all') {
          params.append('filter', filterOption.value);
        }
        // ★追加: ソート順をクエリパラメータとして追加
        params.append('sort', 'start_date');
        params.append('order', 'desc');

        const response = await axios.get(`http://localhost:1880/tournaments?${params.toString()}`);
        tournaments.value = response.data;
        showSnackbar('大会情報を取得しました', 'success');
      } catch (error) {
        console.error('Failed to fetch tournaments:', error);
        showSnackbar('大会情報の取得に失敗しました', 'error');
        tournaments.value = [];
      } finally {
        loading.value = false;
      }
    };

    // 会場リストの取得 (ドロップダウン用)
    const fetchVenuesList = async () => {
      try {
        const response = await axios.get('http://localhost:1880/venues');
        venuesList.value = response.data;
      } catch (error) {
        console.error('Failed to fetch venues list:', error);
        showSnackbar('会場リストの取得に失敗しました', 'error');
      }
    };

    // ダイアログを開く
    const openDialog = (mode, item = null) => {
      if (mode === 'add') {
        editedIndex.value = -1;
        editedItem.value = { ...defaultItem };
        // 新規登録時は日付をクリア
        editedItem.value.start_date = null;
        editedItem.value.end_date = null;

      } else if (mode === 'edit' && item) {
        editedIndex.value = tournaments.value.indexOf(item);
        editedItem.value = {
          ...item,
          // 日付文字列をDateオブジェクトに変換
          start_date: item.start_date ? new Date(item.start_date.split('T')[0]) : null,
          end_date: item.end_date ? new Date(item.end_date.split('T')[0]) : null,
          // コート数は数値型に変換
          number_coat: item.number_coat !== null ? Number(item.number_coat) : null,
        };
      }
      dialog.value = true;
      fetchVenuesList(); // ダイアログを開く際に会場リストをフェッチ
    };

    // 大会編集
    const editTournament = (item) => {
      openDialog('edit', item);
    };

    // ダイアログを閉じる
    const closeDialog = () => {
      dialog.value = false;
      editedIndex.value = -1;
      editedItem.value = { ...defaultItem };
    };

    // 大会情報の保存 (新規作成/更新)
    const saveTournament = async () => {
      if (!editedItem.value.tournament_id || !editedItem.value.tournament_nm || !editedItem.value.start_date || !editedItem.value.venue_id) {
        showSnackbar('大会ID、大会名称、開催開始日、会場は必須です', 'error');
        return;
      }

      // 送信用のペイロードを準備
      const payload = { ...editedItem.value };
      // DateオブジェクトをYYYY-MM-DD形式の文字列に変換
      payload.start_date = payload.start_date ? new Date(payload.start_date).toISOString().split('T')[0] : null;
      payload.end_date = payload.end_date ? new Date(payload.end_date).toISOString().split('T')[0] : null;
      // number_coatが空文字列の場合にnullに変換
      payload.number_coat = payload.number_coat === '' ? null : payload.number_coat;


      try {
        if (editedIndex.value === -1) {
          // 新規作成
          await axios.post('http://localhost:1880/tournaments', payload);
          showSnackbar('大会を新規登録しました', 'success');
        } else {
          // 更新
          await axios.put(`http://localhost:1880/tournaments/${payload.tournament_id}`, payload);
          showSnackbar('大会情報を更新しました', 'success');
        }
        closeDialog();
        fetchTournaments(); // リストを再取得
      } catch (error) {
        console.error('Failed to save tournament:', error);
        showSnackbar('大会情報の保存に失敗しました', 'error');
      }
    };

    // 大会削除確認
    const deleteTournament = (item) => {
      editedIndex.value = tournaments.value.indexOf(item);
      editedItem.value = { ...item };
      dialogDelete.value = true;
    };

    // 削除ダイアログを閉じる
    const closeDeleteDialog = () => {
      dialogDelete.value = false;
      editedIndex.value = -1;
      editedItem.value = { ...defaultItem };
    };

    // 大会削除実行
    const confirmDelete = async () => {
      try {
        await axios.delete(`http://localhost:1880/tournaments/${editedItem.value.tournament_id}`);
        showSnackbar('大会を削除しました', 'success');
        closeDeleteDialog();
        fetchTournaments(); // リストを再取得
      } catch (error) {
        console.error('Failed to delete tournament:', error);
        showSnackbar('大会の削除に失敗しました', 'error');
      }
    };

    // スナックバーの表示
    const showSnackbar = (text, color) => {
      snackbarText.value = text;
      snackbarColor.value = color;
      snackbar.value = true;
    };

    // ★追加: start_date の変更を監視し、新規登録時に end_date を自動設定
    watch(() => editedItem.value.start_date, (newStartDate) => {
      // 新規登録モード (editedIndex.value === -1) かつ
      // end_date が未設定 (null または undefined) の場合
      if (editedIndex.value === -1 && !editedItem.value.end_date) {
        if (newStartDate) {
          editedItem.value.end_date = newStartDate;
        }
      }
    });

    // コンポーネントマウント時にデータを取得
    onMounted(() => {
      fetchTournaments(); // デフォルトフィルターで初期ロード
      fetchVenuesList();
    });

    return {
      tournaments,
      venuesList,
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
      menuStartDate,
      menuEndDate,
      formattedStartDate,
      formattedEndDate,
      filterOption,
      filterOptions,
      coatOptions,
      fetchTournaments,
      openDialog,
      editTournament,
      closeDialog,
      saveTournament,
      deleteTournament,
      closeDeleteDialog,
      confirmDelete,
      formatDate,
      getVenueName,
    };
  },
};
</script>

<style scoped>
/* 必要であれば、ここにコンポーネント固有のスタイルを追加 */
</style>

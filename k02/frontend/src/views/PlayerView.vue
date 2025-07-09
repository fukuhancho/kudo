<template>
  <v-card class="mx-auto" outlined>
    <v-card-title class="headline">
      選手一覧
      <v-spacer></v-spacer>
      <v-btn color="primary" @click="openDialog('add')">新規登録</v-btn>
    </v-card-title>
    <v-card-text>
      <v-row>
        <v-col cols="12" sm="6" md="4">
          <v-select
            v-model="selectedBranchFilter"
            :items="branchesFilterOptions"
            item-title="branch_nm"
            item-value="branch_id"
            label="支部で絞り込み"
            clearable
            @update:modelValue="fetchPlayers"
          ></v-select>
        </v-col>
      </v-row>
      <v-data-table
        :headers="headers"
        :items="players"
        :loading="loading"
        :items-per-page="50"
        class="elevation-1"
        fixed-header
        height="400px"
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
        <template v-slot:[`item.kudo_history`]="{ item }">
          {{ calculateKudoHistory(item.admissionday) }}
        </template>
        <template v-slot:[`item.physical_index`]="{ item }">
          {{ calculatePhysicalIndex(item.height, item.weight) }}
        </template>
        <template v-slot:[`item.actions`]="{ item }">
          <v-icon small class="mr-2" @click="editPlayer(item)">
            mdi-pencil
          </v-icon>
          <v-icon small @click="deletePlayer(item)">
            mdi-delete
          </v-icon>
        </template>
        <template v-slot:no-data>
          <v-btn color="primary" @click="fetchPlayers">
            選手データをロードする
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
            <v-select
              v-model="editedItem.branch_id"
              :items="branches"
              item-title="branch_nm"
              item-value="branch_id"
              label="支部"
              :disabled="isEditMode"
              required
              :rules="[v => !!v || '支部は必須です']"
            ></v-select>
            <v-text-field
              v-model="editedItem.player_id"
              label="選手ID"
              :disabled="isEditMode"
              required
              :rules="[v => !!v || '選手IDは必須です']"
            ></v-text-field>
            <v-text-field
              v-model="editedItem.familyname"
              label="姓"
              required
              :rules="[v => !!v || '姓は必須です']"
            ></v-text-field>
            <v-text-field
              v-model="editedItem.firstname"
              label="名"
              required
              :rules="[v => !!v || '名は必須です']"
            ></v-text-field>
            <v-text-field
              v-model="editedItem.familyname2"
              label="姓（フリガナ）"
            ></v-text-field>
            <v-text-field
              v-model="editedItem.firstname2"
              label="名（フリガナ）"
            ></v-text-field>

            <v-select
              v-model="editedItem.sex"
              :items="sexOptions"
              item-title="text"
              item-value="value"
              label="性別"
              required
              :rules="[v => !!v || '性別は必須です']"
            ></v-select>

            <v-menu
              v-model="menuBirthday"
              :close-on-content-click="false"
              transition="scale-transition"
              offset-y
              max-width="290px"
              min-width="auto"
            >
              <template v-slot:activator="{ props }">
                <v-text-field
                  v-model="formattedBirthday"
                  label="生年月日"
                  prepend-icon="mdi-calendar"
                  readonly
                  v-bind="props"
                ></v-text-field>
              </template>
              <v-date-picker
                v-model="editedItem.birthday"
                locale="ja"
                @update:modelValue="menuBirthday = false"
              ></v-date-picker>
            </v-menu>

            <v-menu
              v-model="menuAdmissionDay"
              :close-on-content-click="false"
              transition="scale-transition"
              offset-y
              max-width="290px"
              min-width="auto"
            >
              <template v-slot:activator="{ props }">
                <v-text-field
                  v-model="formattedAdmissionDay"
                  label="入門日"
                  prepend-icon="mdi-calendar"
                  readonly
                  v-bind="props"
                ></v-text-field>
              </template>
              <v-date-picker
                v-model="editedItem.admissionday"
                locale="ja"
                @update:modelValue="menuAdmissionDay = false"
              ></v-date-picker>
            </v-menu>

            <v-text-field
              v-model="editedItem.xclass"
              label="X級"
            ></v-text-field>
            <v-text-field
              v-model.number="editedItem.height"
              label="身長 (cm)"
              type="number"
              min="0"
              step="0.1"
            ></v-text-field>
            <v-text-field
              v-model.number="editedItem.weight"
              label="体重 (kg)"
              type="number"
              min="0"
              step="0.1"
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
          <v-btn color="blue darken-1" text @click="savePlayer">保存</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <v-dialog v-model="dialogDelete" max-width="500px">
      <v-card>
        <v-card-title class="headline">この選手を削除しますか？</v-card-title>
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
  name: 'PlayerView',
  setup() {
    const players = ref([]);
    const branches = ref([]); // 支部選択肢用 (登録・編集ダイアログ用)
    const branchesFilterOptions = ref([]); // 支部フィルター用 (一覧画面用)
    const loading = ref(false);
    const dialog = ref(false);
    const dialogDelete = ref(false);
    const editedIndex = ref(-1);
    const editedItem = ref({
      player_id: '',
      branch_id: '',
      familyname: '',
      firstname: '',
      familyname2: '',
      firstname2: '',
      sex: '',
      birthday: null,
      admissionday: null,
      xclass: '',
      height: null,
      weight: null,
      remarks: '',
    });

    const defaultItem = {
      player_id: '',
      branch_id: '',
      familyname: '',
      firstname: '',
      familyname2: '',
      firstname2: '',
      sex: '',
      birthday: null,
      admissionday: null,
      xclass: '',
      height: null,
      weight: null,
      remarks: '',
    };

    const snackbar = ref(false);
    const snackbarText = ref('');
    const snackbarColor = ref('');

    // Date Picker のメニュー表示を制御する ref
    const menuBirthday = ref(false);
    const menuAdmissionDay = ref(false);

    // 支部フィルター用のref
    const selectedBranchFilter = ref(null); // デフォルトはnull

    const headers = [
      { title: '選手ID', value: 'player_id', sortable: true },
      { title: '支部ID', value: 'branch_id', sortable: true },
      { title: '氏名', value: 'full_name_with_kana', sortable: false },
      { title: '', value: 'sex', sortable: false }, // 性別アイコン
      { title: '年齢', value: 'age', sortable: true },
      { title: '空道歴', value: 'kudo_history', sortable: true }, // ★追加
      { title: '体力指数', value: 'physical_index', sortable: true },
      { title: 'X級', value: 'xclass', sortable: true },
      { title: '備考', value: 'remarks', sortable: false },
      { title: '操作', value: 'actions', sortable: false },
    ];

    const sexOptions = [
      { text: '男性', value: 'm' },
      { text: '女性', value: 'f' },
    ];

    const formTitle = computed(() => {
      return editedIndex.value === -1 ? '新規選手登録' : '選手情報編集';
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

    // 生年月日用の算出プロパティ
    const formattedBirthday = computed({
      get: () => formatDate(editedItem.value.birthday),
      set: (val) => {
        editedItem.value.birthday = val ? new Date(val) : null;
      },
    });

    // 入門日用の算出プロパティ
    const formattedAdmissionDay = computed({
      get: () => formatDate(editedItem.value.admissionday),
      set: (val) => {
        editedItem.value.admissionday = val ? new Date(val) : null;
      },
    });

    // 氏名＋フリガナを結合して表示する関数
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

    // 空道歴計算 (入門日と現在日付から年数を計算) ★追加
    const calculateKudoHistory = (admissiondayString) => {
      if (!admissiondayString) return '';
      const admissionDate = new Date(admissiondayString.split('T')[0]);
      if (isNaN(admissionDate.getTime())) return '';

      const today = new Date();
      let years = today.getFullYear() - admissionDate.getFullYear();
      const monthDiff = today.getMonth() - admissionDate.getMonth();
      const dayDiff = today.getDate() - admissionDate.getDate();

      if (monthDiff < 0 || (monthDiff === 0 && dayDiff < 0)) {
        years--;
      }
      return `${Math.max(0, years)}年`; // 負の値にならないように0以上
    };

    // 体力指数計算 (身長 + 体重)
    const calculatePhysicalIndex = (height, weight) => {
      // DBから取得した値は10倍されているので、表示用に1/10する
      const actualHeight = height !== null ? parseFloat((height / 10).toFixed(1)) : 0;
      const actualWeight = weight !== null ? parseFloat((weight / 10).toFixed(1)) : 0;

      const index = actualHeight + actualWeight;
      if (index === 0 && (height === null || weight === null)) return '';
      if (index === 0) return '0.0';

      return `${index.toFixed(1)} (${actualHeight.toFixed(1)}+${actualWeight.toFixed(1)})`;
    };

    // 選手情報の取得
    const fetchPlayers = async () => {
      loading.value = true;
      try {
        const params = new URLSearchParams();
        // 選択された支部フィルターがある場合のみクエリパラメータを追加
        if (selectedBranchFilter.value) {
          params.append('branch_id', selectedBranchFilter.value);
        }
        const response = await axios.get(`http://localhost:1880/players?${params.toString()}`);
        players.value = response.data;
        showSnackbar('選手情報を取得しました', 'success');
      } catch (error) {
        console.error('Failed to fetch players:', error);
        showSnackbar('選手情報の取得に失敗しました', 'error');
        players.value = [];
      } finally {
        loading.value = false;
      }
    };

    // 支部リストの取得 (ドロップダウン用)
    const fetchBranches = async () => {
      try {
        const response = await axios.get('http://localhost:1880/branches');
        branches.value = response.data; // 登録・編集ダイアログ用
        
        // フィルターオプション用に「全て」を除外
        branchesFilterOptions.value = response.data; 

        // 初回ロード時、フィルターオプションに支部があれば最初の支部をデフォルト選択
        if (branchesFilterOptions.value.length > 0 && selectedBranchFilter.value === null) {
          selectedBranchFilter.value = branchesFilterOptions.value[0].branch_id;
        }

      } catch (error) {
        console.error('Failed to fetch branches:', error);
        showSnackbar('支部リストの取得に失敗しました', 'error');
      }
    };

    // ダイアログを開く
    const openDialog = (mode, item = null) => {
      if (mode === 'add') {
        editedIndex.value = -1;
        editedItem.value = { ...defaultItem };
        // 新規登録時、フィルターで選択されている支部をデフォルトでセット
        if (selectedBranchFilter.value) {
          editedItem.value.branch_id = selectedBranchFilter.value;
        }
      } else if (mode === 'edit' && item) {
        editedIndex.value = players.value.indexOf(item);
        editedItem.value = {
          ...item,
          // 日付文字列をDateオブジェクトに変換
          birthday: item.birthday ? new Date(item.birthday.split('T')[0]) : null,
          admissionday: item.admissionday ? new Date(item.admissionday.split('T')[0]) : null,
          // 身長と体重はDBから取得した値を1/10して表示
          height: item.height !== null ? Number(item.height) / 10 : null,
          weight: item.weight !== null ? Number(item.weight) / 10 : null,
        };
      }
      dialog.value = true;
    };

    // 選手編集
    const editPlayer = (item) => {
      openDialog('edit', item);
    };

    // ダイアログを閉じる
    const closeDialog = () => {
      dialog.value = false;
      editedIndex.value = -1;
      editedItem.value = { ...defaultItem };
    };

    // 選手情報の保存 (新規作成/更新)
    const savePlayer = async () => {
      if (!editedItem.value.branch_id || !editedItem.value.player_id || !editedItem.value.familyname || !editedItem.value.firstname || !editedItem.value.sex) {
        showSnackbar('支部、選手ID、姓、名、性別は必須です', 'error');
        return;
      }

      // 送信用のペイロードを準備
      const payload = { ...editedItem.value };
      // DateオブジェクトをYYYY-MM-DD形式の文字列に変換
      payload.birthday = payload.birthday ? new Date(payload.birthday).toISOString().split('T')[0] : null;
      payload.admissionday = payload.admissionday ? new Date(payload.admissionday).toISOString().split('T')[0] : null;

      // 身長と体重をデータベース保存用に10倍する
      // nullの場合はそのままnullを保持
      payload.height = payload.height !== null ? Number(payload.height) * 10 : null;
      payload.weight = payload.weight !== null ? Number(payload.weight) * 10 : null;

      try {
        if (editedIndex.value === -1) {
          // 新規作成
          await axios.post('http://localhost:1880/players', payload);
          showSnackbar('選手を新規登録しました', 'success');
        } else {
          // 更新
          await axios.put(`http://localhost:1880/players/${payload.branch_id}/${payload.player_id}`, payload);
          showSnackbar('選手情報を更新しました', 'success');
        }
        closeDialog();
        fetchPlayers(); // リストを再取得
      } catch (error) {
        console.error('Failed to save player:', error);
        showSnackbar('選手情報の保存に失敗しました', 'error');
      }
    };

    // 選手削除確認
    const deletePlayer = (item) => {
      editedIndex.value = players.value.indexOf(item);
      editedItem.value = { ...item };
      dialogDelete.value = true;
    };

    // 削除ダイアログを閉じる
    const closeDeleteDialog = () => {
      dialogDelete.value = false;
      editedIndex.value = -1;
      editedItem.value = { ...defaultItem };
    };

    // 選手削除実行
    const confirmDelete = async () => {
      try {
        await axios.delete(`http://localhost:1880/players/${editedItem.value.branch_id}/${editedItem.value.player_id}`);
        showSnackbar('選手を削除しました', 'success');
        closeDeleteDialog();
        fetchPlayers(); // リストを再取得
      } catch (error) {
        console.error('Failed to delete player:', error);
        showSnackbar('選手の削除に失敗しました', 'error');
      }
    };

    // スナックバーの表示
    const showSnackbar = (text, color) => {
      snackbarText.value = text;
      snackbarColor.value = color;
      snackbar.value = true;
    };

    // コンポーネントマウント時にデータを取得
    onMounted(async () => {
      await fetchBranches(); // 支部リストを先に取得
      fetchPlayers();  // その後選手リストを取得 (フィルターが適用される)
    });

    return {
      players,
      branches,
      branchesFilterOptions,
      selectedBranchFilter,
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
      sexOptions,
      menuBirthday,
      menuAdmissionDay,
      formattedBirthday,
      formattedAdmissionDay,
      fetchPlayers,
      openDialog,
      editPlayer,
      closeDialog,
      savePlayer,
      deletePlayer,
      closeDeleteDialog,
      confirmDelete,
      getFullNameWithKana,
      calculateAge,
      calculateKudoHistory, // ★追加
      calculatePhysicalIndex,
    };
  },
};
</script>

<style scoped>
/* 必要であれば、ここにコンポーネント固有のスタイルを追加 */
</style>

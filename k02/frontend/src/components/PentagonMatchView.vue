<template>
  <v-card class="mx-auto" outlined>
    <v-card-title class="headline">
      五角形戦組み合わせ (開発中)
    </v-card-title>
    <v-card-text>
      <div v-if="registeredParticipants.length === 5">
        <p class="text-center mt-5 text-subtitle-1">
          五角形戦の組み合わせ機能は現在開発中です。<br>
          登録選手: {{ registeredParticipants.length }}名
        </p>
        </div>
      <div v-else>
        <p class="text-center mt-5 text-subtitle-1">
          五角形戦を生成するには、登録選手が5名である必要があります。
        </p>
      </div>
    </v-card-text>
  </v-card>
</template>

<script setup>
/* eslint-disable */
import {  watch } from 'vue';

// Props を定義：親から渡されるデータ
const props = defineProps({ 
  tournamentId: {
    type: [String, Number],
    required: true,
  },
  categoryId: {
    type: [String, Number],
    required: true,
  },
  registeredParticipants: {
    type: Array,
    required: true,
    default: () => [],
  },
});

// 親にスナックバー表示を要求するイベント
// const emit = defineEmits(['show-snackbar']);

// ここに五角形戦のロジックを実装します
// 例:
// const generatedPentagonMatches = ref([]);
// const generatePentagonMatches = () => {
//   // 五角形戦の組み合わせ生成ロジック
//   emit('show-snackbar', '五角形戦の組み合わせを生成しました (ダミー)！', 'success');
// };

// Props の変更を監視して、必要な処理を行う
watch([() => props.tournamentId, () => props.categoryId, () => props.registeredParticipants], () => {
  // 必要に応じて、ここで五角形戦データのロードや初期化を行う
  // console.log('PentagonMatchView: Props updated', props.tournamentId, props.categoryId, props.registeredParticipants.length);
}, { immediate: true });
</script>

<style scoped>
/* 必要に応じてスタイルを追加 */
</style>
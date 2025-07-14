// src/router/index.js
import { createRouter, createWebHistory } from 'vue-router';

// Vueコンポーネントのインポート
// views ディレクトリにあるページコンポーネント
import HomeView from '../views/HomeView.vue';
import CombinationCreatorView from '../views/CombinationCreatorView.vue';
import BranchView from '../views/BranchView.vue';
import PlayerView from '../views/PlayerView.vue';
import VenueView from '../views/VenueView.vue';
import TournamentView from '../views/TournamentView.vue';
import CategoryView from '../views/CategoryView.vue';
import TournamentCategoryView from '../views/TournamentCategoryView.vue';
import TournamentParticipantView from '../views/TournamentParticipantView.vue';
import MatchSchedulerView from '../views/MatchSchedulerView.vue'; 


const routes = [
  {
    path: '/',
    name: 'home',
    component: HomeView,
  },
  {
    path: '/create-combination',
    name: 'create-combination',
    component: CombinationCreatorView,
  },
  {
    path: '/branches',
    name: 'branch-management',
    component: BranchView,
  },
  {
    path: '/players',
    name: 'player-management',
    component: PlayerView,
  },
  {
    path: '/venues',
    name: 'venu-management',
    component: VenueView,
  },
  {
    path: '/tournaments',
    name: 'tournament-management',
    component: TournamentView,
  },
  {
    path: '/categories',
    name: 'category-management',
    component: CategoryView,
  },
  {
    path: '/tournament-categories',
    name: 'tournament-category-management',
    component: TournamentCategoryView,
  },
  {
    path: '/tournament-participants',
    name: 'ttournament-participant-management',
    component: TournamentParticipantView,
  },
  {
    path: '/match-scheduler/:tournamentId?', 
    name: 'MatchScheduler',
    component: MatchSchedulerView,
    props: true 
  },
  
];

const router = createRouter({
  history: createWebHistory(process.env.BASE_URL), 
  routes,
});

export default router;
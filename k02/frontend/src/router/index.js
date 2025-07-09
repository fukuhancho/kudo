import { createRouter, createWebHistory } from 'vue-router'


const routes = [
  // {
  //   path: '/',
  //   name: 'index',
  //   component: () => import('@/components/HelloWorld')
  // },
  {
    path: '/branch',
    name: 'branch',
    component: () => import('@/components/BranchView')
  }
]

const router = createRouter({
  history: createWebHistory(process.env.BASE_URL),
  routes
})

export default router

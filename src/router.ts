import { createRouter, createWebHistory } from 'vue-router'
import { supabase } from './lib/supabase'
import KnowledgeBase from './components/KnowledgeBase.vue'
import TutorialView from './components/TutorialView.vue'
import AdminLogin from './components/admin/AdminLogin.vue'
import AdminDashboard from './components/admin/AdminDashboard.vue'

const requireAuth = async (to, from, next) => {
  const { data: { session } } = await supabase.auth.getSession()
  
  if (!session) {
    next('/admin')
    return
  }
  next()
}

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/',
      component: KnowledgeBase
    },
    {
      path: '/categoria/:id',
      component: TutorialView,
      props: true
    },
    {
      path: '/admin',
      component: AdminLogin
    },
    {
      path: '/admin/dashboard',
      component: AdminDashboard,
      beforeEnter: requireAuth
    },
    {
      path: '/:pathMatch(.*)*',
      redirect: '/'
    }
  ]
})

export default router
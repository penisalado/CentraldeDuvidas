<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../../lib/supabase'

const router = useRouter()
const email = ref('')
const password = ref('')
const error = ref('')
const loading = ref(false)

const handleLogin = async () => {
  try {
    loading.value = true
    error.value = ''
    
    const { data, error: authError } = await supabase.auth.signInWithPassword({
      email: email.value,
      password: password.value
    })

    if (authError) {
      error.value = 'Credenciais inválidas'
      return
    }

    if (data.user) {
      router.push('/admin/dashboard')
    }
  } catch (e) {
    error.value = 'Erro ao fazer login'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="min-h-screen flex items-center justify-center p-4" 
       style="background-image: url('/fundo_portalPrancheta_1_2.png'); background-size: cover; background-position: center;">
    <div class="flex flex-col items-center max-w-md w-full">
      <img src="/agelogo.png" alt="Age Telecom Logo" class="w-24 h-24 -mt-20 mb-8 drop-shadow-lg" />
      <div class="bg-white/90 backdrop-blur-sm rounded-xl shadow-lg w-full p-8">
        <h2 class="text-2xl font-bold text-center text-gray-800 mb-6">Login Administrativo</h2>
        
        <form @submit.prevent="handleLogin" class="space-y-5">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1.5">
              Email
            </label>
            <input 
              type="email" 
              v-model="email"
              required
              class="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary/20 focus:border-primary transition-colors"
              placeholder="seu@email.com"
            >
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1.5">
              Senha
            </label>
            <input 
              type="password" 
              v-model="password"
              required
              class="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary/20 focus:border-primary transition-colors"
              placeholder="••••••••"
            >
          </div>

          <div v-if="error" class="text-red-500 text-sm text-center bg-red-50 py-2 rounded">
            {{ error }}
          </div>

          <button 
            type="submit"
            :disabled="loading"
            class="w-full bg-primary text-white py-3 rounded-lg font-medium hover:bg-primary/90 transition-colors disabled:opacity-50 disabled:cursor-not-allowed mt-2"
          >
            {{ loading ? 'Entrando...' : 'Entrar' }}
          </button>
        </form>
      </div>
    </div>
  </div>
</template>
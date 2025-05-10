<script setup lang="ts">
// Importações necessárias do Vue e outros módulos
import { ref, onMounted, watch, onUnmounted } from 'vue'
import { supabase } from '../lib/supabase'
import { Icon } from '@iconify/vue'

// Props do componente
const props = defineProps<{
  tutorialId: string  // ID do tutorial a ser avaliado
}>()

// Estados do componente
const rating = ref(0)                // Avaliação atual
const averageRating = ref(0)         // Média das avaliações
const totalVotes = ref(0)            // Total de votos
const hasVoted = ref(false)          // Se o usuário já votou
const loading = ref(false)           // Estado de carregamento
const error = ref('')                // Mensagem de erro
const isOpen = ref(false)            // Estado do accordion

// Descrições para cada nível de avaliação
const ratingDescriptions = {
  1: 'Difícil de entender',
  2: 'Confuso em partes',
  3: 'Compreensível',
  4: 'Fácil de entender',
  5: 'Muito claro e objetivo'
}

// Busca as avaliações do tutorial
const fetchRatings = async () => {
  // Reset do estado local
  averageRating.value = 0
  totalVotes.value = 0
  
  const { data: ratings, error: fetchError } = await supabase
    .from('tutorial_ratings')
    .select('rating')
    .eq('tutorial_id', props.tutorialId)

  if (fetchError) {
    error.value = 'Erro ao carregar avaliações'
    return
  }

  // Calcula a média e total de votos
  if (ratings && ratings.length > 0) {
    const sum = ratings.reduce((acc, curr) => acc + curr.rating, 0)
    averageRating.value = Math.round((sum / ratings.length) * 10) / 10
    totalVotes.value = ratings.length
  }
}

// Gera um ID único para o cookie
const generateCookieId = () => {
  return Math.random().toString(36).substring(2) + Date.now().toString(36)
}

// Obtém ou cria um ID de cookie
const getCookieId = () => {
  let cookieId = localStorage.getItem('tutorial_rating_cookie_id')
  if (!cookieId) {
    cookieId = generateCookieId()
    localStorage.setItem('tutorial_rating_cookie_id', cookieId)
  }
  return cookieId
}

// Verifica se o usuário já votou
const checkUserVote = async () => {
  hasVoted.value = false
  rating.value = 0
  
  try {
    const cookieId = getCookieId()

    const { data, error: queryError } = await supabase
      .from('tutorial_ratings')
      .select('rating')
      .eq('tutorial_id', props.tutorialId)
      .eq('cookie_id', cookieId)
      .maybeSingle()

    if (queryError) {
      console.error('Error checking user vote:', queryError)
      return
    }

    if (data) {
      hasVoted.value = true
      rating.value = data.rating
    }
  } catch (err) {
    console.error('Error in checkUserVote:', err)
  }
}

// Envia uma nova avaliação
const submitRating = async (value: number) => {
  if (hasVoted.value) return

  loading.value = true
  error.value = ''

  try {
    const cookieId = getCookieId()

    const { error: submitError } = await supabase
      .from('tutorial_ratings')
      .insert([
        {
          tutorial_id: props.tutorialId,
          rating: value,
          cookie_id: cookieId
        }
      ])

    if (submitError) throw submitError

    rating.value = value
    hasVoted.value = true
    await fetchRatings()
  } catch (err) {
    error.value = 'Erro ao enviar avaliação'
  } finally {
    loading.value = false
  }
}

// Inscreve-se para eventos de reset de votos
const subscribeToResets = () => {
  const resetChannel = supabase
    .channel('vote-resets')
    .on(
      'postgres_changes',
      {
        event: 'INSERT',
        schema: 'public',
        table: 'tutorial_vote_resets'
      },
      async (payload) => {
        // Reset se os votos deste tutorial foram resetados ou se todos foram
        if (!payload.new.tutorial_id || payload.new.tutorial_id === props.tutorialId) {
          // Reset do estado local
          hasVoted.value = false
          rating.value = 0
          averageRating.value = 0
          totalVotes.value = 0
          
          // Recarrega os dados após um breve delay
          setTimeout(async () => {
            await Promise.all([
              fetchRatings(),
              checkUserVote()
            ])
          }, 500)
        }
      }
    )
    .subscribe()

  return () => {
    supabase.removeChannel(resetChannel)
  }
}

// Inicialização do componente
onMounted(async () => {
  await Promise.all([
    fetchRatings(),
    checkUserVote()
  ])
  
  const unsubscribe = subscribeToResets()
  
  onUnmounted(() => {
    unsubscribe()
  })
})

// Observa mudanças no ID do tutorial
watch(() => props.tutorialId, async (newId) => {
  if (newId) {
    await Promise.all([
      fetchRatings(),
      checkUserVote()
    ])
  }
})
</script>

<template>
  <!-- Container principal do componente de avaliação -->
  <div class="rating-container">
    <!-- Cabeçalho do accordion -->
    <button 
      class="accordion-header"
      @click="isOpen = !isOpen"
      :class="{ 'has-rating': hasVoted }"
    >
      <span class="header-text">
        {{ hasVoted ? 'Sua avaliação' : 'Avalie esse tutorial' }}
      </span>
      <div class="header-info">
        <!-- Exibe estrelas se já votou -->
        <div v-if="hasVoted" class="user-rating">
          <Icon 
            icon="material-symbols:star" 
            class="star-icon"
            v-for="i in rating"
            :key="i"
          />
        </div>
        <!-- Ícone de expandir/recolher -->
        <Icon 
          :icon="isOpen ? 'material-symbols:expand-less' : 'material-symbols:expand-more'" 
          class="expand-icon"
        />
      </div>
    </button>

    <!-- Conteúdo do accordion -->
    <div class="accordion-content" :class="{ 'open': isOpen }">
      <p class="rating-title">O tutorial foi fácil de entender?</p>
      
      <!-- Sistema de estrelas -->
      <div class="stars">
        <button
          v-for="i in 5"
          :key="i"
          @click="submitRating(i)"
          :disabled="hasVoted || loading"
          class="star-button"
          :class="{ 'voted': i <= rating }"
          :title="ratingDescriptions[i]"
        >
          <Icon 
            :icon="i <= rating ? 'material-symbols:star' : 'material-symbols:star-outline'" 
            class="star-icon"
          />
          <span class="rating-description" :class="{ 'active': i === rating }">
            {{ ratingDescriptions[i] }}
          </span>
        </button>
      </div>
      
      <!-- Informações de avaliação -->
      <div class="rating-info">
        <span class="average">{{ averageRating || '0' }}</span>
        <span class="votes">({{ totalVotes }} votos)</span>
      </div>

      <!-- Mensagem de erro -->
      <p v-if="error" class="error">{{ error }}</p>
    </div>
  </div>
</template>

<style scoped>
/* Container principal fixo na tela */
.rating-container {
  position: fixed;
  bottom: 2rem;
  right: 2rem;
  background: white;
  border-radius: 12px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  width: 300px;
  overflow: hidden;
}

/* Cabeçalho do accordion */
.accordion-header {
  width: 100%;
  background: white;
  border: none;
  padding: 1rem 1.5rem;
  cursor: pointer;
  display: flex;
  justify-content: space-between;
  align-items: center;
  transition: background-color 0.2s;
}

.accordion-header:hover {
  background-color: #f9fafb;
}

/* Texto do cabeçalho */
.header-text {
  font-size: 0.875rem;
  color: #4b5563;
  font-weight: 500;
}

/* Container das informações do cabeçalho */
.header-info {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

/* Container das estrelas do usuário */
.user-rating {
  display: flex;
  gap: 2px;
}

/* Ícone de expandir */
.expand-icon {
  color: #9ca3af;
  font-size: 1.25rem;
}

/* Conteúdo do accordion */
.accordion-content {
  max-height: 0;
  overflow: hidden;
  transition: max-height 0.3s ease-out;
  background: white;
}

.accordion-content.open {
  max-height: 400px;
  padding: 1.5rem;
  border-top: 1px solid #e5e7eb;
}

/* Título da avaliação */
.rating-title {
  font-size: 0.875rem;
  color: #4b5563;
  text-align: center;
  margin: 0 0 1rem;
}

/* Container das estrelas */
.stars {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  width: 100%;
}

/* Botão de estrela */
.star-button {
  background: none;
  border: none;
  cursor: pointer;
  padding: 0.5rem;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  border-radius: 6px;
}

.star-button:not(:disabled):hover {
  background-color: #f3f4f6;
}

.star-button:disabled {
  cursor: default;
}

/* Ícone de estrela */
.star-icon {
  font-size: 1.25rem;
  color: #fbbf24;
}

/* Descrição da avaliação */
.rating-description {
  font-size: 0.75rem;
  color: #6b7280;
  opacity: 0.7;
  transition: all 0.2s;
}

.rating-description.active {
  color: #4b5563;
  opacity: 1;
  font-weight: 500;
}

.star-button:hover .rating-description {
  opacity: 1;
}

/* Informações de avaliação */
.rating-info {
  font-size: 0.875rem;
  color: #666;
  display: flex;
  gap: 0.25rem;
  align-items: center;
  justify-content: center;
  margin-top: 1rem;
}

/* Média das avaliações */
.average {
  font-weight: 600;
  color: #4b5563;
}

/* Número de votos */
.votes {
  color: #9ca3af;
}

/* Mensagem de erro */
.error {
  color: #dc2626;
  font-size: 0.75rem;
  text-align: center;
  margin: 0.5rem 0 0;
}

/* Responsividade */
@media (max-width: 768px) {
  .rating-container {
    position: static;
    margin-top: 2rem;
    width: 100%;
  }
}
</style>
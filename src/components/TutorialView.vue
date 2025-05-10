<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { marked } from 'marked'
import { Icon } from '@iconify/vue'
import { supabase } from '../lib/supabase'
import type { Category, Tutorial } from '../lib/supabase'
import SearchBar from './SearchBar.vue'
import ImageModal from './ImageModal.vue'
import TutorialRating from './TutorialRating.vue'

const route = useRoute()
const router = useRouter()

const showImageModal = ref(false)
const selectedImage = ref({
  src: '',
  alt: ''
})

// Configure marked to properly handle lists
marked.use({
  gfm: true,
  breaks: true,
  renderer: {
    html(html) {
      return html.replace(
        /<div class="image-preview".*?>(.*?)<\/div>/g,
        (match, content) => {
          const imgMatch = content.match(/src="([^"]+)".*?alt="([^"]+)"/)
          if (imgMatch) {
            const [_, src, alt] = imgMatch
            return `<div class="image-preview" onclick="window.__openImage('${src}', '${alt}')">
              ${content}
              <span class="image-zoom">🔍 Ampliar imagem</span>
            </div>`
          }
          return match
        }
      )
    },
    list(body, ordered) {
      const type = ordered ? 'ol' : 'ul'
      return `<${type} class="${ordered ? 'numbered-list' : 'bullet-list'}">${body}</${type}>`
    },
    listitem(text) {
      return `<li class="list-item">${text}</li>`
    }
  }
})

window.__openImage = (src: string, alt: string) => {
  selectedImage.value = { src, alt }
  showImageModal.value = true
}

const categories = ref<Category[]>([])
const tutorials = ref<Tutorial[]>([])
const selectedTutorial = ref<Tutorial | null>(null)
const isLoading = ref(true)
const error = ref('')

onMounted(async () => {
  await loadData()
})

async function loadData() {
  try {
    const categoryId = route.params.id as string
    const tutorialId = route.query.tutorial as string

    const [categoriesResponse, tutorialsResponse] = await Promise.all([
      supabase.from('categories').select('*').order('order_position'),
      supabase.from('tutorials').select('*').eq('category_id', categoryId).order('order_position')
    ])

    if (categoriesResponse.error) throw categoriesResponse.error
    if (tutorialsResponse.error) throw tutorialsResponse.error

    categories.value = categoriesResponse.data
    tutorials.value = tutorialsResponse.data

    if (tutorialId) {
      const tutorial = tutorialsResponse.data.find(t => t.id === tutorialId)
      if (tutorial) {
        selectedTutorial.value = tutorial
      }
    }
  } catch (err) {
    error.value = 'Erro ao carregar dados'
    console.error(err)
  } finally {
    isLoading.value = false
  }
}

const searchQuery = ref('')

const filteredTutorials = computed(() => {
  if (!searchQuery.value) {
    return tutorials.value
  }
  
  const query = searchQuery.value.toLowerCase()
  return tutorials.value.filter(tutorial => 
    tutorial.title.toLowerCase().includes(query) ||
    tutorial.code.toLowerCase().includes(query) ||
    tutorial.content?.toLowerCase().includes(query)
  )
})

const currentCategory = computed(() => {
  return categories.value.find(c => c.id === route.params.id)
})

const goBack = () => {
  if (selectedTutorial.value) {
    selectedTutorial.value = null
    router.replace({ query: {} })
  } else {
    router.push('/')
  }
}

const formattedContent = computed(() => {
  if (!selectedTutorial.value?.content) return ''
  return marked(selectedTutorial.value.content)
})

watch(
  [() => route.params.id, () => route.query.tutorial],
  async ([newCategoryId, newTutorialId]) => {
    if (newCategoryId) {
      await loadData()
    }
  },
  { immediate: true }
)

const selectTutorial = (tutorial: Tutorial) => {
  selectedTutorial.value = tutorial
  router.replace({ query: { tutorial: tutorial.id } })
}
</script>

<template>
  <div class="tutorial-view" v-if="!isLoading">
    <div v-if="currentCategory" class="tutorial-container">
      <div class="tutorial-header">
        <button class="back-button" @click="goBack">← Voltar</button>
        <div class="header-content">
          <h1>{{ currentCategory.title }}</h1>
          <SearchBar v-model="searchQuery" placeholder="Buscar por código, título ou conteúdo..." />
        </div>
      </div>

      <div v-if="!selectedTutorial" class="tutorials-list">
        <div 
          v-for="tutorial in filteredTutorials" 
          :key="tutorial.id"
          class="tutorial-item"
          @click="selectTutorial(tutorial)"
        >
          <div class="tutorial-code">{{ tutorial.code }}</div>
          <div class="tutorial-title">{{ tutorial.title }}</div>
          <Icon icon="material-symbols:description" class="tutorial-icon" />
        </div>
      </div>

      <div v-else class="tutorial-content">
        <div class="tutorial-content-header">
          <div class="tutorial-code">{{ selectedTutorial.code }}</div>
          <h2>{{ selectedTutorial.title }}</h2>
        </div>
        <div class="content-body" v-html="formattedContent"></div>
        
        <TutorialRating 
          v-if="selectedTutorial"
          :tutorial-id="selectedTutorial.id"
        />
      </div>

      <ImageModal 
        :show="showImageModal"
        :image-src="selectedImage.src"
        :image-alt="selectedImage.alt"
        @close="showImageModal = false"
      />
    </div>
    <div v-else class="not-found">
      <h2>Categoria não encontrada</h2>
      <button class="back-button" @click="router.push('/')">← Voltar para a página inicial</button>
    </div>
  </div>
  <div v-else class="loading">
    <p>Carregando...</p>
  </div>
</template>

<style scoped>
.tutorial-view {
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem;
}

.tutorial-header {
  margin-bottom: 2rem;
}

.header-content {
  margin-top: 1rem;
}

.header-content h1 {
  margin: 0.5rem 0 1rem;
  color: #2c3e50;
  font-size: 1.8rem;
}

.back-button {
  background: none;
  border: none;
  color: #ff5722;
  font-size: 1rem;
  cursor: pointer;
  padding: 0.5rem 0;
  display: inline-flex;
  align-items: center;
}

.back-button:hover {
  text-decoration: underline;
}

.tutorials-list {
  background: white;
  border-radius: 12px;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
  overflow: hidden;
}

.tutorial-item {
  display: flex;
  align-items: center;
  padding: 1rem 1.5rem;
  border-bottom: 1px solid #e9ecef;
  cursor: pointer;
  transition: background-color 0.2s;
}

.tutorial-item:hover {
  background-color: #f8f9fa;
}

.tutorial-item:last-child {
  border-bottom: none;
}

.tutorial-code {
  font-family: monospace;
  color: #ff5722;
  font-weight: 600;
  margin-right: 1rem;
  font-size: 0.9rem;
  min-width: 80px;
}

.tutorial-title {
  flex: 1;
  color: #2c3e50;
}

.tutorial-icon {
  color: #6c757d;
  font-size: 1.25rem;
}

.tutorial-content {
  background: white;
  padding: 2rem;
  border-radius: 12px;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
}

.tutorial-content-header {
  margin-bottom: 2rem;
  padding-bottom: 1rem;
  border-bottom: 2px solid #ff5722;
}

.tutorial-content-header h2 {
  margin-top: 0.5rem;
  color: #2c3e50;
}

.content-body {
  line-height: 1.6;
}

.content-body :deep(h1) {
  font-size: 1.8rem;
  color: #2c3e50;
  margin-bottom: 1.5rem;
}

.content-body :deep(h2) {
  font-size: 1.4rem;
  color: #2c3e50;
  margin: 2rem 0 1rem;
}

.content-body :deep(p) {
  margin-bottom: 1rem;
}

.content-body :deep(ul.bullet-list),
.content-body :deep(ol.numbered-list) {
  margin: 1rem 0;
  padding-left: 2rem;
}

.content-body :deep(ul.bullet-list) {
  list-style-type: disc;
}

.content-body :deep(ol.numbered-list) {
  list-style-type: decimal;
}

.content-body :deep(li.list-item) {
  margin-bottom: 0.5rem;
  padding-left: 0.5rem;
}

.content-body :deep(.tutorial-step) {
  display: flex;
  gap: 2rem;
  margin: 1.5rem 0;
  align-items: flex-start;
}

.content-body :deep(.tutorial-text) {
  flex: 1;
}

.content-body :deep(.tutorial-image) {
  flex-shrink: 0;
  width: 400px;
}

.content-body :deep(.tutorial-image.full-width) {
  width: 100%;
  margin: 1.5rem 0;
}

.content-body :deep(.image-preview) {
  position: relative;
  border-radius: 8px;
  overflow: hidden;
  cursor: zoom-in;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  transition: transform 0.2s ease;
}

.content-body :deep(.image-preview:hover) {
  transform: scale(1.02);
}

.content-body :deep(.image-preview img) {
  display: block;
  width: 100%;
  height: auto;
}

.content-body :deep(.image-zoom) {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  background: rgba(0, 0, 0, 0.7);
  color: white;
  padding: 0.5rem;
  font-size: 0.875rem;
  text-align: center;
  opacity: 0;
  transition: opacity 0.2s;
}

.content-body :deep(.image-preview:hover .image-zoom) {
  opacity: 1;
}

.loading, .not-found {
  text-align: center;
  padding: 2rem;
  color: #6c757d;
}

@media (max-width: 768px) {
  .tutorial-view {
    padding: 1rem;
  }
  
  .tutorial-item {
    padding: 1rem;
  }
  
  .tutorial-content {
    padding: 1.5rem;
  }

  .content-body :deep(.tutorial-step) {
    flex-direction: column;
    gap: 1rem;
  }

  .content-body :deep(.tutorial-image) {
    width: 100% !important;
  }
}
</style>
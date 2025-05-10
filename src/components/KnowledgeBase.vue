<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import { supabase } from '../lib/supabase'
import type { Category, Tutorial, QuickLink } from '../lib/supabase'
import SearchBar from './SearchBar.vue'

const router = useRouter()
const categories = ref<Category[]>([])
const tutorials = ref<Tutorial[]>([])
const quickLinks = ref<QuickLink[]>([])
const isLoading = ref(true)
const error = ref('')

// Implement data prefetching
const prefetchData = async () => {
  try {
    const [categoriesResponse, tutorialsResponse, quickLinksResponse] = await Promise.all([
      supabase.from('categories').select('*').order('order_position'),
      supabase.from('tutorials').select('*').order('order_position'),
      supabase.from('quick_links').select('*').order('order_position')
    ])

    if (categoriesResponse.error) {
      throw new Error(`Failed to fetch categories: ${categoriesResponse.error.message}`)
    }

    if (tutorialsResponse.error) {
      throw new Error(`Failed to fetch tutorials: ${tutorialsResponse.error.message}`)
    }

    if (quickLinksResponse.error) {
      throw new Error(`Failed to fetch quick links: ${quickLinksResponse.error.message}`)
    }

    return {
      categories: categoriesResponse.data,
      tutorials: tutorialsResponse.data,
      quickLinks: quickLinksResponse.data
    }
  } catch (err) {
    throw err
  }
}

onMounted(async () => {
  try {
    const data = await prefetchData()
    categories.value = data.categories
    tutorials.value = data.tutorials
    quickLinks.value = data.quickLinks
  } catch (err) {
    const errorMessage = err instanceof Error ? err.message : 'Unknown error occurred'
    error.value = `Erro ao carregar dados: ${errorMessage}`
    console.error('Detailed error:', err)
  } finally {
    isLoading.value = false
  }
})

const searchQuery = ref('')

const filteredResults = computed(() => {
  if (!searchQuery.value) return { categories: categories.value, tutorials: [] }
  
  const query = searchQuery.value.toLowerCase()
  
  const filteredCategories = categories.value.filter(category => 
    category.title.toLowerCase().includes(query) ||
    category.description?.toLowerCase().includes(query)
  )

  const filteredTutorials = tutorials.value.filter(tutorial => 
    tutorial.title.toLowerCase().includes(query) ||
    tutorial.code.toLowerCase().includes(query) ||
    tutorial.content?.toLowerCase().includes(query)
  )

  return {
    categories: filteredCategories,
    tutorials: filteredTutorials
  }
})

const navigateToCategory = (categoryId: string) => {
  router.push(`/categoria/${categoryId}`)
}

const navigateToTutorial = (tutorial: Tutorial) => {
  router.push(`/categoria/${tutorial.category_id}?tutorial=${tutorial.id}`)
}

const getCategoryTitle = (categoryId: string) => {
  const category = categories.value.find(c => c.id === categoryId)
  return category ? category.title : ''
}

const openQuickLink = (url: string) => {
  window.open(url, '_blank')
}
</script>

<template>
  <div class="wiki-container">
    <header class="wiki-header">
      <div class="logo-container">
        <h1>Age Wiki</h1>
        <p class="subtitle">Base de Conhecimento Age Fibra</p>
      </div>
      <SearchBar v-model="searchQuery" placeholder="Buscar tutoriais, procedimentos..." />
    </header>

    <main class="wiki-content">
      <div v-if="isLoading" class="loading">
        <p>Carregando...</p>
      </div>
      
      <div v-else-if="error" class="error">
        <p>{{ error }}</p>
        <p class="error-hint">Por favor, verifique sua conexão com a internet e tente novamente.</p>
      </div>
      
      <div v-else>
        <!-- Search Results -->
        <div v-if="searchQuery" class="search-results">
          <div v-if="filteredResults.tutorials.length > 0" class="tutorials-results">
            <h2 class="search-section-title">Tutoriais Encontrados</h2>
            <div class="tutorial-cards">
              <div 
                v-for="tutorial in filteredResults.tutorials" 
                :key="tutorial.id"
                class="tutorial-card"
                @click="navigateToTutorial(tutorial)"
              >
                <div class="tutorial-card-header">
                  <span class="tutorial-code">{{ tutorial.code }}</span>
                  <span class="tutorial-category">{{ getCategoryTitle(tutorial.category_id) }}</span>
                </div>
                <h3 class="tutorial-title">{{ tutorial.title }}</h3>
              </div>
            </div>
          </div>

          <div v-if="filteredResults.categories.length > 0" class="categories-results">
            <h2 class="search-section-title">Categorias Encontradas</h2>
            <div class="categories-grid">
              <div 
                v-for="category in filteredResults.categories" 
                :key="category.id"
                class="category-card"
                @click="navigateToCategory(category.id)"
              >
                <div class="category-icon" :style="{ backgroundColor: category.icon_color }">
                  <Icon :icon="category.icon" class="icon" />
                </div>
                <div class="category-info">
                  <h3>{{ category.title }}</h3>
                  <p>{{ category.description }}</p>
                </div>
                <span class="arrow" :style="{ color: category.icon_color }">→</span>
              </div>
            </div>
          </div>

          <div 
            v-if="filteredResults.tutorials.length === 0 && filteredResults.categories.length === 0" 
            class="no-results"
          >
            <p>Nenhum resultado encontrado para "{{ searchQuery }}"</p>
          </div>
        </div>

        <!-- Default Categories View -->
        <div v-else>
          <div class="categories-grid">
            <div 
              v-for="category in categories" 
              :key="category.id"
              class="category-card"
              @click="navigateToCategory(category.id)"
            >
              <div class="category-icon" :style="{ backgroundColor: category.icon_color }">
                <Icon :icon="category.icon" class="icon" loading="lazy" />
              </div>
              <div class="category-info">
                <h3>{{ category.title }}</h3>
                <p>{{ category.description }}</p>
              </div>
              <span class="arrow" :style="{ color: category.icon_color }">→</span>
            </div>
          </div>

          <!-- Quick Links Section -->
          <div class="quick-links-section">
            <h2 class="section-title">Links Rápidos</h2>
            <div class="quick-links-grid">
              <div 
                v-for="link in quickLinks" 
                :key="link.id"
                class="quick-link-card"
                @click="openQuickLink(link.redirect_url)"
              >
                <div class="quick-link-image">
                  <img :src="link.image_url" :alt="link.title" loading="lazy">
                </div>
                <div class="quick-link-content">
                  <h3>{{ link.title }}</h3>
                  <p>{{ link.description }}</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </main>
  </div>
</template>

<style>
.wiki-container {
  min-height: 100vh;
  background: linear-gradient(to bottom, #f8f9fa, #e9ecef);
  contain: content;
}

.wiki-header {
  background: white;
  padding: 2rem;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  margin-bottom: 2rem;
  contain: content;
}

.logo-container {
  text-align: center;
  margin-bottom: 1.5rem;
}

.logo-container h1 {
  font-size: 2.5rem;
  color: #ff5722;
  font-weight: 700;
  margin: 0;
}

.subtitle {
  color: #6c757d;
  font-size: 1rem;
  margin-top: 0.5rem;
}

.wiki-content {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 2rem 2rem;
  contain: content;
}

.search-results {
  margin-bottom: 2rem;
}

.search-section-title {
  font-size: 1.25rem;
  color: #2c3e50;
  margin-bottom: 1rem;
  font-weight: 600;
}

.tutorial-cards {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 1rem;
  margin-bottom: 2rem;
}

.tutorial-card {
  background: white;
  border-radius: 8px;
  padding: 1rem;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  cursor: pointer;
  transition: transform 0.2s ease, box-shadow 0.2s ease;
  will-change: transform;
}

.tutorial-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
}

.tutorial-card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.5rem;
}

.tutorial-code {
  font-family: monospace;
  color: #ff5722;
  font-weight: 600;
}

.tutorial-category {
  font-size: 0.875rem;
  color: #6c757d;
}

.tutorial-title {
  font-size: 1rem;
  color: #2c3e50;
  margin: 0;
}

.categories-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
  gap: 1.5rem;
  margin-bottom: 3rem;
  contain: content;
}

.category-card {
  background: white;
  border-radius: 12px;
  padding: 1.5rem;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
  transition: all 0.3s ease;
  border: 1px solid #e9ecef;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 1.5rem;
  will-change: transform;
}

.category-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 12px rgba(0, 0, 0, 0.15);
}

.category-icon {
  width: 56px;
  height: 56px;
  border-radius: 16px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.3s ease;
}

.category-icon .icon {
  font-size: 32px;
  color: white;
}

.category-info {
  flex: 1;
}

.category-info h3 {
  margin: 0;
  font-size: 1.25rem;
  color: #2c3e50;
  font-weight: 600;
}

.category-info p {
  margin: 0.5rem 0 0;
  font-size: 0.9rem;
  color: #6c757d;
  line-height: 1.4;
}

.arrow {
  font-size: 1.5rem;
  opacity: 0.8;
  transition: transform 0.3s ease;
}

.category-card:hover .arrow {
  transform: translateX(4px);
}

.loading, .error, .no-results {
  text-align: center;
  padding: 2rem;
  color: #6c757d;
}

.error-hint {
  margin-top: 0.5rem;
  font-size: 0.9rem;
  color: #dc3545;
}

/* Quick Links Styles */
.quick-links-section {
  margin-top: 2rem;
  contain: content;
}

.section-title {
  font-size: 1.5rem;
  color: #2c3e50;
  margin-bottom: 1.5rem;
  font-weight: 600;
}

.quick-links-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
  gap: 1.5rem;
  contain: content;
}

.quick-link-card {
  background: white;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
  transition: transform 0.3s ease, box-shadow 0.3s ease;
  cursor: pointer;
  will-change: transform;
}

.quick-link-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 12px rgba(0, 0, 0, 0.15);
}

.quick-link-image {
  width: 100%;
  height: 150px;
  overflow: hidden;
}

.quick-link-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.quick-link-content {
  padding: 1.25rem;
}

.quick-link-content h3 {
  margin: 0;
  font-size: 1.1rem;
  color: #2c3e50;
  font-weight: 600;
}

.quick-link-content p {
  margin: 0.5rem 0 0;
  font-size: 0.9rem;
  color: #6c757d;
  line-height: 1.4;
}

@media (max-width: 768px) {
  .categories-grid,
  .quick-links-grid {
    grid-template-columns: 1fr;
  }
  
  .wiki-header {
    padding: 1.5rem;
  }
  
  .logo-container h1 {
    font-size: 2rem;
  }

  .tutorial-cards {
    grid-template-columns: 1fr;
  }
}
</style>
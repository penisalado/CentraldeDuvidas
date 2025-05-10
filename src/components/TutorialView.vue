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
import { Editor } from '@tiptap/vue-3'
import StarterKit from '@tiptap/starter-kit'
import Image from '@tiptap/extension-image'
import Dropcursor from '@tiptap/extension-dropcursor'
import { EditorContent } from '@tiptap/vue-3'

// Hooks do Vue Router
const route = useRoute()
const router = useRouter()

// Estado do modal de imagem
const showImageModal = ref(false)
const selectedImage = ref({
  src: '',
  alt: ''
})

// Editor TipTap
const editor = new Editor({
  extensions: [
    StarterKit,
    Image.configure({
      inline: true,
      allowBase64: true,
      HTMLAttributes: {
        class: 'tutorial-image',
      },
      resizable: true,
      draggable: true,
    }),
    Dropcursor,
  ],
  content: '',
  editable: true,
  onDrop: (view, event, slice, moved) => {
    if (!moved && event.dataTransfer?.files.length) {
      const file = event.dataTransfer.files[0]
      if (file.type.startsWith('image/')) {
        handleImageUpload(file)
        return true
      }
    }
    return false
  },
})

// Configuração do marked para processar imagens com preview
marked.use({
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
    }
  }
})

// Função global para abrir o modal de imagem
window.__openImage = (src: string, alt: string) => {
  selectedImage.value = { src, alt }
  showImageModal.value = true
}

// Estados do componente
const categories = ref<Category[]>([])
const tutorials = ref<Tutorial[]>([])
const selectedTutorial = ref<Tutorial | null>(null)
const isLoading = ref(true)
const error = ref('')

// Função para fazer upload de imagem
const uploadImage = async (file: File) => {
  try {
    const fileExt = file.name.split('.').pop()
    const fileName = `${Math.random().toString(36).substring(2)}.${fileExt}`
    const filePath = `tutorial-images/${fileName}`

    const { data, error: uploadError } = await supabase.storage
      .from('tutorial-images')
      .upload(filePath, file, {
        cacheControl: '3600',
        upsert: false
      })

    if (uploadError) throw uploadError

    const { data: { publicUrl } } = supabase.storage
      .from('tutorial-images')
      .getPublicUrl(filePath)

    return publicUrl
  } catch (error) {
    console.error('Error uploading image:', error)
    throw error
  }
}

// Handler para upload de imagem
const handleImageUpload = async (file: File) => {
  try {
    const url = await uploadImage(file)
    editor.chain().focus().setImage({ src: url }).run()
  } catch (error) {
    console.error('Error handling image upload:', error)
  }
}

// Handler para drag and drop de imagens
const handleDrop = async (event: DragEvent) => {
  event.preventDefault()
  const file = event.dataTransfer?.files[0]
  if (file && file.type.startsWith('image/')) {
    await handleImageUpload(file)
  }
}

// Carrega dados ao montar o componente
onMounted(async () => {
  await loadData()
})

// Função para carregar dados do Supabase
async function loadData() {
  try {
    const categoryId = route.params.id as string
    const tutorialId = route.query.tutorial as string

    // Carrega categorias e tutoriais em paralelo
    const [categoriesResponse, tutorialsResponse] = await Promise.all([
      supabase.from('categories').select('*').order('order_position'),
      supabase.from('tutorials').select('*').eq('category_id', categoryId).order('order_position')
    ])

    if (categoriesResponse.error) throw categoriesResponse.error
    if (tutorialsResponse.error) throw tutorialsResponse.error

    categories.value = categoriesResponse.data
    tutorials.value = tutorialsResponse.data

    // Seleciona tutorial se especificado na URL
    if (tutorialId) {
      const tutorial = tutorialsResponse.data.find(t => t.id === tutorialId)
      if (tutorial) {
        selectedTutorial.value = tutorial
        editor.commands.setContent(tutorial.content || '')
      }
    }
  } catch (err) {
    error.value = 'Erro ao carregar dados'
    console.error(err)
  } finally {
    isLoading.value = false
  }
}

// Estado da busca
const searchQuery = ref('')

// Filtra tutoriais baseado na busca
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

// Obtém categoria atual
const currentCategory = computed(() => {
  return categories.value.find(c => c.id === route.params.id)
})

// Função para voltar
const goBack = () => {
  if (selectedTutorial.value) {
    selectedTutorial.value = null
    router.replace({ query: {} })
  } else {
    router.push('/')
  }
}

// Converte markdown para HTML
const formattedContent = computed(() => {
  if (!selectedTutorial.value?.content) return ''
  return marked(selectedTutorial.value.content)
})

// Observa mudanças na rota
watch(
  [() => route.params.id, () => route.query.tutorial],
  async ([newCategoryId, newTutorialId]) => {
    if (newCategoryId) {
      await loadData()
    }
  },
  { immediate: true }
)

// Seleciona um tutorial
const selectTutorial = (tutorial: Tutorial) => {
  selectedTutorial.value = tutorial
  editor.commands.setContent(tutorial.content || '')
  router.replace({ query: { tutorial: tutorial.id } })
}
</script>

<template>
  <div class="tutorial-view" v-if="!isLoading">
    <!-- Container principal -->
    <div v-if="currentCategory" class="tutorial-container">
      <!-- Cabeçalho -->
      <div class="tutorial-header">
        <button class="back-button" @click="goBack">← Voltar</button>
        <div class="header-content">
          <h1>{{ currentCategory.title }}</h1>
          <SearchBar v-model="searchQuery" placeholder="Buscar por código, título ou conteúdo..." />
        </div>
      </div>

      <!-- Lista de tutoriais -->
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

      <!-- Conteúdo do tutorial -->
      <div v-else class="tutorial-content">
        <div class="tutorial-content-header">
          <div class="tutorial-code">{{ selectedTutorial.code }}</div>
          <h2>{{ selectedTutorial.title }}</h2>
        </div>
        
        <!-- Editor TipTap -->
        <div 
          class="editor-container" 
          @drop="handleDrop"
          @dragover.prevent
        >
          <editor-content :editor="editor" />
          
          <!-- Botão de upload de imagem -->
          <div class="image-upload">
            <input
              type="file"
              accept="image/*"
              @change="(e) => handleImageUpload(e.target.files[0])"
              class="hidden-input"
              id="image-upload"
            />
            <label for="image-upload" class="upload-button">
              <Icon icon="material-symbols:add-photo-alternate" class="upload-icon" />
              Adicionar Imagem
            </label>
          </div>
        </div>
        
        <!-- Componente de avaliação -->
        <TutorialRating 
          v-if="selectedTutorial"
          :tutorial-id="selectedTutorial.id"
        />
      </div>

      <!-- Modal de imagem -->
      <ImageModal 
        :show="showImageModal"
        :image-src="selectedImage.src"
        :image-alt="selectedImage.alt"
        @close="showImageModal = false"
      />
    </div>

    <!-- Mensagem de categoria não encontrada -->
    <div v-else class="not-found">
      <h2>Categoria não encontrada</h2>
      <button class="back-button" @click="router.push('/')">← Voltar para a página inicial</button>
    </div>
  </div>

  <!-- Loading state -->
  <div v-else class="loading">
    <p>Carregando...</p>
  </div>
</template>

<style>
/* Container principal */
.tutorial-view {
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem;
}

/* Cabeçalho */
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

/* Botão voltar */
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

/* Lista de tutoriais */
.tutorials-list {
  background: white;
  border-radius: 12px;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
  overflow: hidden;
}

/* Item da lista */
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

/* Código do tutorial */
.tutorial-code {
  font-family: monospace;
  color: #ff5722;
  font-weight: 600;
  margin-right: 1rem;
  font-size: 0.9rem;
  min-width: 80px;
}

/* Título do tutorial */
.tutorial-title {
  flex: 1;
  color: #2c3e50;
}

/* Ícone do tutorial */
.tutorial-icon {
  color: #6c757d;
  font-size: 1.25rem;
}

/* Conteúdo do tutorial */
.tutorial-content {
  background: white;
  padding: 2rem;
  border-radius: 12px;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
}

/* Cabeçalho do conteúdo */
.tutorial-content-header {
  margin-bottom: 2rem;
  padding-bottom: 1rem;
  border-bottom: 2px solid #ff5722;
}

.tutorial-content-header h2 {
  margin-top: 0.5rem;
  color: #2c3e50;
}

/* Editor container */
.editor-container {
  position: relative;
  margin-bottom: 2rem;
  min-height: 300px;
  border: 1px solid #e2e2e2;
  border-radius: 8px;
  padding: 1rem;
}

/* Imagem upload */
.image-upload {
  margin-top: 1rem;
}

.hidden-input {
  display: none;
}

.upload-button {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 1rem;
  background-color: #f8f9fa;
  border: 1px solid #dee2e6;
  border-radius: 4px;
  cursor: pointer;
  color: #495057;
  font-size: 0.875rem;
  transition: all 0.2s;
}

.upload-button:hover {
  background-color: #e9ecef;
  border-color: #ced4da;
}

.upload-icon {
  font-size: 1.25rem;
}

/* Tutorial image */
.tutorial-image {
  max-width: 100%;
  height: auto;
  border-radius: 4px;
  margin: 1rem 0;
  cursor: move;
  resize: both;
  overflow: auto;
}

.tutorial-image:hover {
  box-shadow: 0 0 0 2px #ff5722;
}

.tutorial-image.dragging {
  opacity: 0.5;
}

/* Estados de loading e não encontrado */
.loading, .not-found {
  text-align: center;
  padding: 2rem;
  color: #6c757d;
}

/* Responsividade */
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
}

/* Estilos do TipTap */
.ProseMirror {
  outline: none;
  min-height: 200px;
}

.ProseMirror p {
  margin: 1em 0;
}

.ProseMirror img {
  max-width: 100%;
  height: auto;
  cursor: move;
  display: block;
  margin: 1rem 0;
  border-radius: 4px;
}

.ProseMirror img:hover {
  box-shadow: 0 0 0 2px #ff5722;
}

.ProseMirror img.dragging {
  opacity: 0.5;
}

.ProseMirror img.selected {
  box-shadow: 0 0 0 2px #ff5722;
}

/* Dropcursor */
.ProseMirror-dropcursor {
  border-top: 2px solid #ff5722;
  margin-top: -1px;
  pointer-events: none;
}
</style>
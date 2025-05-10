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
        
        <div class="editor-container">
          <editor-content :editor="editor" />
          
          <div class="image-upload">
            <input
              type="file"
              accept="image/*"
              @change="handleImageUpload"
              class="hidden-input"
              id="image-upload"
            />
            <label for="image-upload" class="upload-button">
              <Icon icon="material-symbols:add-photo-alternate" class="upload-icon" />
              Adicionar Imagem
            </label>
          </div>
        </div>
        
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

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { Icon } from '@iconify/vue'
import { supabase } from '../lib/supabase'
import type { Category, Tutorial } from '../lib/supabase'
import SearchBar from './SearchBar.vue'
import ImageModal from './ImageModal.vue'
import TutorialRating from './TutorialRating.vue'
import { Editor, EditorContent } from '@tiptap/vue-3'
import StarterKit from '@tiptap/starter-kit'
import Image from '@tiptap/extension-image'
import Dropcursor from '@tiptap/extension-dropcursor'

const route = useRoute()
const router = useRouter()

const showImageModal = ref(false)
const selectedImage = ref({
  src: '',
  alt: ''
})

const editor = new Editor({
  extensions: [
    StarterKit,
    Dropcursor,
    Image.configure({
      inline: true,
      allowBase64: true,
      HTMLAttributes: {
        class: 'tutorial-image',
        draggable: 'true',
      },
    }),
  ],
  content: '',
  editable: true,
  onDrop: (view, event, slice, moved) => {
    if (!event.dataTransfer?.files?.length) return

    const file = event.dataTransfer.files[0]
    if (file.type.startsWith('image/')) {
      handleImageDrop(file, view, event)
      return true
    }
    return false
  },
})

const handleImageDrop = async (file: File, view: any, event: DragEvent) => {
  try {
    const url = await uploadImage(file)
    const { schema } = view.state
    const coordinates = view.posAtCoords({
      left: event.clientX,
      top: event.clientY,
    })

    const node = schema.nodes.image.create({ src: url })
    const transaction = view.state.tr.insert(coordinates.pos, node)
    view.dispatch(transaction)
  } catch (error) {
    console.error('Error handling image drop:', error)
  }
}

const uploadImage = async (file: File) => {
  try {
    const fileExt = file.name.split('.').pop()
    const fileName = `${Math.random().toString(36).substring(2)}.${fileExt}`
    const filePath = `tutorial-images/${fileName}`

    const { data, error: uploadError } = await supabase.storage
      .from('tutorial-assets')
      .upload(filePath, file)

    if (uploadError) throw uploadError

    const { data: { publicUrl } } = supabase.storage
      .from('tutorial-assets')
      .getPublicUrl(filePath)

    return publicUrl
  } catch (error) {
    console.error('Error uploading image:', error)
    throw error
  }
}

const handleImageUpload = async (event: Event) => {
  const input = event.target as HTMLInputElement
  if (!input.files?.length) return

  try {
    const file = input.files[0]
    const url = await uploadImage(file)
    
    editor.chain().focus().setImage({ src: url }).run()
  } catch (error) {
    console.error('Error handling image upload:', error)
  }
}

const categories = ref<Category[]>([])
const tutorials = ref<Tutorial[]>([])
const selectedTutorial = ref<Tutorial | null>(null)
const isLoading = ref(true)
const error = ref('')
const searchQuery = ref('')

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

const filteredTutorials = computed(() => {
  if (!searchQuery.value) return tutorials.value
  
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

const selectTutorial = (tutorial: Tutorial) => {
  selectedTutorial.value = tutorial
  editor.commands.setContent(tutorial.content || '')
  router.replace({ query: { tutorial: tutorial.id } })
}

watch(
  [() => route.params.id, () => route.query.tutorial],
  async ([newCategoryId, newTutorialId]) => {
    if (newCategoryId) {
      await loadData()
    }
  },
  { immediate: true }
)
</script>

<style>
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

.editor-container {
  position: relative;
  margin-bottom: 2rem;
  border: 1px solid #e2e2e2;
  border-radius: 8px;
  overflow: hidden;
}

.ProseMirror {
  padding: 1rem;
  min-height: 300px;
  outline: none;
}

.ProseMirror img {
  max-width: 100%;
  height: auto;
  cursor: move;
  display: inline-block;
  margin: 1rem 0;
  border-radius: 4px;
  resize: both;
  overflow: hidden;
  border: 1px solid transparent;
}

.ProseMirror img:hover {
  border-color: #ff5722;
}

.image-upload {
  padding: 1rem;
  border-top: 1px solid #e2e2e2;
  background: #f8f9fa;
}

.hidden-input {
  display: none;
}

.upload-button {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 1rem;
  background-color: white;
  border: 1px solid #dee2e6;
  border-radius: 4px;
  cursor: pointer;
  color: #495057;
  font-size: 0.875rem;
  transition: all 0.2s;
}

.upload-button:hover {
  background-color: #f1f3f5;
  border-color: #ced4da;
}

.upload-icon {
  font-size: 1.25rem;
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
}
</style>
<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRouter } from 'vue-router'
import { Editor, EditorContent } from '@tiptap/vue-3'
import StarterKit from '@tiptap/starter-kit'
import Image from '@tiptap/extension-image'
import Link from '@tiptap/extension-link'
import TextAlign from '@tiptap/extension-text-align'
import Underline from '@tiptap/extension-underline'
import Strike from '@tiptap/extension-strike'
import Highlight from '@tiptap/extension-highlight'
import Color from '@tiptap/extension-color'
import TextStyle from '@tiptap/extension-text-style'
import FontFamily from '@tiptap/extension-font-family'
import Typography from '@tiptap/extension-typography'
import Document from '@tiptap/extension-document'
import Paragraph from '@tiptap/extension-paragraph'
import Text from '@tiptap/extension-text'
import { Icon } from '@iconify/vue'
import { supabase } from '../../lib/supabase'
import { marked } from 'marked'
import type { Category, Tutorial } from '../../lib/supabase'

const router = useRouter()
const activeTab = ref('tutorials')
const categories = ref<Category[]>([])
const tutorials = ref<Tutorial[]>([])
const selectedCategory = ref<Category | null>(null)
const selectedTutorial = ref<Tutorial | null>(null)
const previewMode = ref(false)
const loading = ref(false)
const error = ref('')

// Form states
const tutorialForm = ref({
  code: '',
  title: '',
  content: '',
  category_id: ''
})

const categoryForm = ref({
  title: '',
  description: '',
  icon: '',
  icon_color: '#2196F3'
})

// Editor configuration
const editor = new Editor({
  extensions: [
    StarterKit,
    Image.configure({
      HTMLAttributes: {
        class: 'max-w-full rounded-lg shadow-lg my-4',
      },
      allowBase64: true,
    }),
    Link.configure({
      openOnClick: false,
      HTMLAttributes: {
        class: 'text-primary hover:underline',
      },
    }),
    TextAlign.configure({
      types: ['heading', 'paragraph'],
    }),
    Underline,
    Strike,
    Highlight,
    Color,
    TextStyle,
    FontFamily,
    Typography,
    Document,
    Paragraph,
    Text,
  ],
  content: '',
  editorProps: {
    handleDrop: (view, event, slice, moved) => {
      if (!moved && event.dataTransfer && event.dataTransfer.files && event.dataTransfer.files[0]) {
        const file = event.dataTransfer.files[0]
        if (file.type.startsWith('image/')) {
          handleImageUpload(file, view)
          return true
        }
      }
      return false
    },
    handlePaste: (view, event) => {
      if (event.clipboardData && event.clipboardData.files && event.clipboardData.files[0]) {
        const file = event.clipboardData.files[0]
        if (file.type.startsWith('image/')) {
          handleImageUpload(file, view)
          return true
        }
      }
      return false
    },
  },
})

// Load initial data
onMounted(async () => {
  await Promise.all([
    loadCategories(),
    loadTutorials()
  ])
})

// Data loading functions
async function loadCategories() {
  try {
    const { data, error: fetchError } = await supabase
      .from('categories')
      .select('*')
      .order('order_position')
    
    if (fetchError) throw fetchError
    categories.value = data || []
  } catch (err) {
    error.value = 'Error loading categories'
    console.error(err)
  }
}

async function loadTutorials() {
  try {
    const { data, error: fetchError } = await supabase
      .from('tutorials')
      .select('*')
      .order('order_position')
    
    if (fetchError) throw fetchError
    tutorials.value = data || []
  } catch (err) {
    error.value = 'Error loading tutorials'
    console.error(err)
  }
}

// Image handling
const handleImageUpload = async (file: File, view: any) => {
  try {
    const reader = new FileReader()
    reader.onload = async (e) => {
      const base64 = e.target?.result as string
      const { data, error: uploadError } = await supabase.storage
        .from('tutorial-assets')
        .upload(`images/${Date.now()}-${file.name}`, file)

      if (uploadError) throw uploadError

      const imageUrl = `${supabase.storageUrl}/object/public/tutorial-assets/${data.path}`
      
      const { state } = view
      const position = state.selection.from
      
      view.dispatch(view.state.tr.insert(
        position,
        view.state.schema.nodes.image.create({ src: imageUrl, alt: file.name })
      ))
    }
    reader.readAsDataURL(file)
  } catch (err) {
    console.error('Error uploading image:', err)
    error.value = 'Error uploading image'
  }
}

// Form submission handlers
async function handleTutorialSubmit() {
  try {
    loading.value = true
    error.value = ''

    const tutorialData = {
      ...tutorialForm.value,
      content: editor.getHTML()
    }

    const { data, error: submitError } = await supabase
      .from('tutorials')
      .insert([tutorialData])
      .select()
      .single()

    if (submitError) throw submitError

    tutorials.value.push(data)
    resetTutorialForm()
    await loadTutorials()
  } catch (err) {
    error.value = 'Error saving tutorial'
    console.error(err)
  } finally {
    loading.value = false
  }
}

async function handleCategorySubmit() {
  try {
    loading.value = true
    error.value = ''

    const { data, error: submitError } = await supabase
      .from('categories')
      .insert([categoryForm.value])
      .select()
      .single()

    if (submitError) throw submitError

    categories.value.push(data)
    resetCategoryForm()
    await loadCategories()
  } catch (err) {
    error.value = 'Error saving category'
    console.error(err)
  } finally {
    loading.value = false
  }
}

// Form reset functions
function resetTutorialForm() {
  tutorialForm.value = {
    code: '',
    title: '',
    content: '',
    category_id: ''
  }
  editor.commands.setContent('')
}

function resetCategoryForm() {
  categoryForm.value = {
    title: '',
    description: '',
    icon: '',
    icon_color: '#2196F3'
  }
}

// Computed properties
const filteredTutorials = computed(() => {
  if (!selectedCategory.value) return tutorials.value
  return tutorials.value.filter(t => t.category_id === selectedCategory.value?.id)
})

// Cleanup
onUnmounted(() => {
  editor.destroy()
})
</script>

<template>
  <div class="min-h-screen bg-gray-50 p-6">
    <div class="max-w-7xl mx-auto">
      <!-- Header -->
      <div class="mb-8 flex justify-between items-center">
        <h1 class="text-2xl font-bold text-gray-900">Dashboard Administrativo</h1>
        <button 
          @click="router.push('/')"
          class="px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors"
        >
          Voltar ao Portal
        </button>
      </div>

      <!-- Error Display -->
      <div v-if="error" class="mb-6 p-4 bg-red-100 text-red-700 rounded-lg">
        {{ error }}
      </div>

      <!-- Tabs -->
      <div class="mb-6 border-b border-gray-200">
        <nav class="flex space-x-8" aria-label="Tabs">
          <button
            v-for="tab in ['tutorials', 'categories']"
            :key="tab"
            @click="activeTab = tab"
            :class="[
              'py-4 px-1 border-b-2 font-medium text-sm',
              activeTab === tab
                ? 'border-primary text-primary'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
            ]"
          >
            {{ tab === 'tutorials' ? 'Tutoriais' : 'Categorias' }}
          </button>
        </nav>
      </div>

      <!-- Content -->
      <div class="space-y-6">
        <!-- Tutorials Tab -->
        <div v-if="activeTab === 'tutorials'">
          <div class="bg-white rounded-lg shadow p-6">
            <h2 class="text-lg font-medium text-gray-900 mb-4">Novo Tutorial</h2>
            <form @submit.prevent="handleTutorialSubmit" class="space-y-4">
              <div class="grid grid-cols-2 gap-4">
                <div>
                  <label class="block text-sm font-medium text-gray-700">Código</label>
                  <input
                    v-model="tutorialForm.code"
                    type="text"
                    required
                    class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-primary focus:ring-primary"
                  >
                </div>
                <div>
                  <label class="block text-sm font-medium text-gray-700">Categoria</label>
                  <select
                    v-model="tutorialForm.category_id"
                    required
                    class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-primary focus:ring-primary"
                  >
                    <option value="">Selecione uma categoria</option>
                    <option
                      v-for="category in categories"
                      :key="category.id"
                      :value="category.id"
                    >
                      {{ category.title }}
                    </option>
                  </select>
                </div>
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700">Título</label>
                <input
                  v-model="tutorialForm.title"
                  type="text"
                  required
                  class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-primary focus:ring-primary"
                >
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">Conteúdo</label>
                <div 
                  class="border rounded-lg p-4 min-h-[300px] relative"
                  @dragover.prevent
                  @drop.prevent
                >
                  <editor-content :editor="editor" />
                  <div 
                    v-if="!editor.isFocused" 
                    class="absolute inset-0 flex items-center justify-center text-gray-400 pointer-events-none"
                  >
                    Arraste e solte imagens aqui ou comece a digitar...
                  </div>
                </div>
              </div>

              <div class="flex justify-end space-x-3">
                <button
                  type="button"
                  @click="resetTutorialForm"
                  class="px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary"
                >
                  Limpar
                </button>
                <button
                  type="submit"
                  :disabled="loading"
                  class="px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-primary hover:bg-primary/90 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary"
                >
                  {{ loading ? 'Salvando...' : 'Salvar Tutorial' }}
                </button>
              </div>
            </form>
          </div>

          <!-- Tutorials List -->
          <div class="mt-6 bg-white rounded-lg shadow">
            <div class="px-4 py-5 sm:px-6 border-b border-gray-200">
              <h3 class="text-lg font-medium text-gray-900">Tutoriais Existentes</h3>
            </div>
            <ul class="divide-y divide-gray-200">
              <li v-for="tutorial in filteredTutorials" :key="tutorial.id" class="px-4 py-4 sm:px-6">
                <div class="flex items-center justify-between">
                  <div>
                    <p class="text-sm font-medium text-primary">{{ tutorial.code }}</p>
                    <p class="text-sm text-gray-900">{{ tutorial.title }}</p>
                  </div>
                  <div class="flex space-x-2">
                    <button
                      @click="selectedTutorial = tutorial"
                      class="text-sm text-blue-600 hover:text-blue-800"
                    >
                      Editar
                    </button>
                    <button
                      @click="deleteTutorial(tutorial.id)"
                      class="text-sm text-red-600 hover:text-red-800"
                    >
                      Excluir
                    </button>
                  </div>
                </div>
              </li>
            </ul>
          </div>
        </div>

        <!-- Categories Tab -->
        <div v-if="activeTab === 'categories'">
          <div class="bg-white rounded-lg shadow p-6">
            <h2 class="text-lg font-medium text-gray-900 mb-4">Nova Categoria</h2>
            <form @submit.prevent="handleCategorySubmit" class="space-y-4">
              <div>
                <label class="block text-sm font-medium text-gray-700">Título</label>
                <input
                  v-model="categoryForm.title"
                  type="text"
                  required
                  class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-primary focus:ring-primary"
                >
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700">Descrição</label>
                <textarea
                  v-model="categoryForm.description"
                  rows="3"
                  class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-primary focus:ring-primary"
                ></textarea>
              </div>

              <div class="grid grid-cols-2 gap-4">
                <div>
                  <label class="block text-sm font-medium text-gray-700">Ícone</label>
                  <input
                    v-model="categoryForm.icon"
                    type="text"
                    placeholder="material-symbols:support-agent"
                    class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-primary focus:ring-primary"
                  >
                </div>
                <div>
                  <label class="block text-sm font-medium text-gray-700">Cor do Ícone</label>
                  <input
                    v-model="categoryForm.icon_color"
                    type="color"
                    class="mt-1 block w-full h-10 rounded-md border-gray-300 shadow-sm focus:border-primary focus:ring-primary"
                  >
                </div>
              </div>

              <div class="flex justify-end space-x-3">
                <button
                  type="button"
                  @click="resetCategoryForm"
                  class="px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary"
                >
                  Limpar
                </button>
                <button
                  type="submit"
                  :disabled="loading"
                  class="px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-primary hover:bg-primary/90 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary"
                >
                  {{ loading ? 'Salvando...' : 'Salvar Categoria' }}
                </button>
              </div>
            </form>
          </div>

          <!-- Categories List -->
          <div class="mt-6 bg-white rounded-lg shadow">
            <div class="px-4 py-5 sm:px-6 border-b border-gray-200">
              <h3 class="text-lg font-medium text-gray-900">Categorias Existentes</h3>
            </div>
            <ul class="divide-y divide-gray-200">
              <li v-for="category in categories" :key="category.id" class="px-4 py-4 sm:px-6">
                <div class="flex items-center justify-between">
                  <div class="flex items-center">
                    <div
                      class="w-8 h-8 rounded-lg flex items-center justify-center mr-3"
                      :style="{ backgroundColor: category.icon_color }"
                    >
                      <Icon :icon="category.icon" class="text-white text-xl" />
                    </div>
                    <div>
                      <p class="text-sm font-medium text-gray-900">{{ category.title }}</p>
                      <p class="text-sm text-gray-500">{{ category.description }}</p>
                    </div>
                  </div>
                  <div class="flex space-x-2">
                    <button
                      @click="selectedCategory = category"
                      class="text-sm text-blue-600 hover:text-blue-800"
                    >
                      Editar
                    </button>
                    <button
                      @click="deleteCategory(category.id)"
                      class="text-sm text-red-600 hover:text-red-800"
                    >
                      Excluir
                    </button>
                  </div>
                </div>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style>
.ProseMirror {
  min-height: 200px;
  padding: 1rem;
}

.ProseMirror:focus {
  outline: none;
}

.ProseMirror img {
  max-width: 100%;
  height: auto;
  cursor: pointer;
  transition: transform 0.2s ease;
}

.ProseMirror img:hover {
  transform: scale(1.01);
}

.ProseMirror-dropcursor {
  border-top: 2px solid #0D0D0D;
  border-bottom: 2px solid #0D0D0D;
  margin-top: -2px;
  pointer-events: none;
}

/* Editor content styles */
.ProseMirror h1 {
  font-size: 2em;
  font-weight: bold;
  margin: 1em 0;
}

.ProseMirror h2 {
  font-size: 1.5em;
  font-weight: bold;
  margin: 0.83em 0;
}

.ProseMirror p {
  margin: 1em 0;
}

.ProseMirror ul {
  list-style-type: disc;
  padding-left: 1.5em;
  margin: 1em 0;
}

.ProseMirror ol {
  list-style-type: decimal;
  padding-left: 1.5em;
  margin: 1em 0;
}

.ProseMirror code {
  background-color: #f3f4f6;
  padding: 0.2em 0.4em;
  border-radius: 3px;
  font-family: monospace;
}

.ProseMirror pre {
  background-color: #f3f4f6;
  padding: 1em;
  border-radius: 4px;
  overflow-x: auto;
}

.ProseMirror a {
  color: #ff5722;
  text-decoration: underline;
}
</style>
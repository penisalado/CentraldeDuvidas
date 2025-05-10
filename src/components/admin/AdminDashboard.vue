<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useEditor, EditorContent } from '@tiptap/vue-3'
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
import type { Category, Tutorial } from '../../lib/supabase'

const categories = ref<Category[]>([])
const tutorials = ref<Tutorial[]>([])
const selectedCategory = ref<string | null>(null)
const selectedTutorial = ref<Tutorial | null>(null)
const isLoading = ref(true)
const error = ref('')

const newTutorial = ref({
  code: '',
  title: '',
  content: ''
})

// Editor configuration
const editor = useEditor({
  extensions: [
    StarterKit,
    Image.configure({
      HTMLAttributes: {
        class: 'max-w-full h-auto',
      },
      allowBase64: true,
    }),
    Link.configure({
      openOnClick: false,
      HTMLAttributes: {
        class: 'text-blue-500 hover:text-blue-700 underline',
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

// Function to handle image upload
const handleImageUpload = async (file: File, view: any) => {
  try {
    const reader = new FileReader()
    reader.onload = async (e) => {
      if (e.target?.result) {
        // Upload to Supabase Storage
        const path = `tutorial-images/${Date.now()}-${file.name}`
        const { data, error } = await supabase.storage
          .from('tutorial-assets')
          .upload(path, file)

        if (error) throw error

        // Get public URL
        const { data: { publicUrl } } = supabase.storage
          .from('tutorial-assets')
          .getPublicUrl(path)

        // Insert image into editor
        const { schema } = view.state
        const imageNode = schema.nodes.image.create({ src: publicUrl })
        const transaction = view.state.tr.replaceSelectionWith(imageNode)
        view.dispatch(transaction)
      }
    }
    reader.readAsDataURL(file)
  } catch (error) {
    console.error('Error uploading image:', error)
  }
}

onMounted(async () => {
  try {
    const [categoriesResponse, tutorialsResponse] = await Promise.all([
      supabase.from('categories').select('*').order('order_position'),
      supabase.from('tutorials').select('*').order('order_position')
    ])

    if (categoriesResponse.error) throw categoriesResponse.error
    if (tutorialsResponse.error) throw tutorialsResponse.error

    categories.value = categoriesResponse.data
    tutorials.value = tutorialsResponse.data
  } catch (err) {
    error.value = 'Erro ao carregar dados'
    console.error(err)
  } finally {
    isLoading.value = false
  }
})

const filteredTutorials = computed(() => {
  if (!selectedCategory.value) return []
  return tutorials.value.filter(t => t.category_id === selectedCategory.value)
})

const handleCategorySelect = (categoryId: string) => {
  selectedCategory.value = categoryId
  selectedTutorial.value = null
  if (editor.value) {
    editor.value.commands.setContent('')
  }
}

const handleTutorialSelect = async (tutorial: Tutorial) => {
  selectedTutorial.value = tutorial
  if (editor.value) {
    editor.value.commands.setContent(tutorial.content || '')
  }
}

const handleSave = async () => {
  if (!selectedCategory.value || !editor.value) return

  try {
    const content = editor.value.getHTML()
    
    if (selectedTutorial.value) {
      // Update existing tutorial
      const { error: updateError } = await supabase
        .from('tutorials')
        .update({
          content,
          updated_at: new Date().toISOString()
        })
        .eq('id', selectedTutorial.value.id)

      if (updateError) throw updateError
    } else {
      // Create new tutorial
      const { error: createError } = await supabase
        .from('tutorials')
        .insert([{
          code: newTutorial.value.code,
          title: newTutorial.value.title,
          content,
          category_id: selectedCategory.value,
          order_position: (filteredTutorials.value.length + 1) * 10
        }])

      if (createError) throw createError

      // Reset form
      newTutorial.value = {
        code: '',
        title: '',
        content: ''
      }
    }

    // Refresh tutorials
    const { data, error: fetchError } = await supabase
      .from('tutorials')
      .select('*')
      .order('order_position')

    if (fetchError) throw fetchError
    tutorials.value = data
  } catch (err) {
    console.error('Error saving tutorial:', err)
    error.value = 'Erro ao salvar tutorial'
  }
}
</script>

<template>
  <div class="admin-dashboard">
    <header class="bg-white shadow">
      <div class="max-w-7xl mx-auto py-6 px-4 sm:px-6 lg:px-8">
        <h1 class="text-3xl font-bold text-gray-900">Dashboard Administrativo</h1>
      </div>
    </header>

    <main class="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
      <div v-if="isLoading" class="text-center py-12">
        <p class="text-gray-500">Carregando...</p>
      </div>

      <div v-else-if="error" class="text-center py-12">
        <p class="text-red-500">{{ error }}</p>
      </div>

      <div v-else class="grid grid-cols-12 gap-6">
        <!-- Categories Sidebar -->
        <div class="col-span-3 bg-white rounded-lg shadow">
          <div class="p-4">
            <h2 class="text-lg font-semibold text-gray-900 mb-4">Categorias</h2>
            <div class="space-y-2">
              <button
                v-for="category in categories"
                :key="category.id"
                @click="handleCategorySelect(category.id)"
                class="w-full text-left px-4 py-2 rounded-md transition-colors"
                :class="{
                  'bg-primary text-white': selectedCategory === category.id,
                  'hover:bg-gray-100': selectedCategory !== category.id
                }"
              >
                {{ category.title }}
              </button>
            </div>
          </div>
        </div>

        <!-- Main Content -->
        <div class="col-span-9 space-y-6">
          <!-- Tutorials List -->
          <div v-if="selectedCategory" class="bg-white rounded-lg shadow p-6">
            <div class="flex justify-between items-center mb-6">
              <h2 class="text-lg font-semibold text-gray-900">Tutoriais</h2>
              <button
                @click="selectedTutorial = null"
                class="px-4 py-2 bg-primary text-white rounded-md hover:bg-primary/90 transition-colors"
              >
                Novo Tutorial
              </button>
            </div>

            <div v-if="!selectedTutorial" class="space-y-4">
              <div class="grid grid-cols-2 gap-4">
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">
                    Código
                  </label>
                  <input
                    v-model="newTutorial.code"
                    type="text"
                    class="w-full px-3 py-2 border rounded-md"
                    placeholder="Ex: A.W 1.1.1"
                  >
                </div>
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">
                    Título
                  </label>
                  <input
                    v-model="newTutorial.title"
                    type="text"
                    class="w-full px-3 py-2 border rounded-md"
                    placeholder="Título do tutorial"
                  >
                </div>
              </div>
            </div>

            <div v-else class="space-y-4">
              <div class="flex items-center justify-between">
                <div>
                  <p class="text-sm text-gray-500">{{ selectedTutorial.code }}</p>
                  <h3 class="text-xl font-medium">{{ selectedTutorial.title }}</h3>
                </div>
              </div>
            </div>

            <!-- Editor Toolbar -->
            <div class="border rounded-lg mt-6 mb-4">
              <div class="flex flex-wrap gap-1 p-2 border-b">
                <button
                  v-for="(item, index) in [
                    { icon: 'material-symbols:format-bold', command: 'toggleBold' },
                    { icon: 'material-symbols:format-italic', command: 'toggleItalic' },
                    { icon: 'material-symbols:format-underlined', command: 'toggleUnderline' },
                    { icon: 'material-symbols:strikethrough-s', command: 'toggleStrike' },
                    null,
                    { icon: 'material-symbols:format-h1', command: () => editor?.chain().focus().toggleHeading({ level: 1 }).run() },
                    { icon: 'material-symbols:format-h2', command: () => editor?.chain().focus().toggleHeading({ level: 2 }).run() },
                    null,
                    { icon: 'material-symbols:format-list-bulleted', command: 'toggleBulletList' },
                    { icon: 'material-symbols:format-list-numbered', command: 'toggleOrderedList' },
                    { icon: 'material-symbols:code', command: 'toggleCodeBlock' },
                    null,
                    { icon: 'material-symbols:link', command: () => {
                      const url = window.prompt('URL:')
                      if (url) {
                        editor?.chain().focus().setLink({ href: url }).run()
                      }
                    }},
                  ]"
                  :key="index"
                  v-if="item"
                  @click="editor?.chain().focus()[item.command]().run()"
                  class="p-2 hover:bg-gray-100 rounded"
                >
                  <Icon :icon="item.icon" class="w-5 h-5" />
                </button>
                <div v-else class="w-px h-6 bg-gray-200 mx-2 self-center" />
              </div>
            </div>

            <!-- Editor Content -->
            <editor-content :editor="editor" class="prose max-w-none min-h-[300px] border rounded-lg p-4" />

            <div class="flex justify-end mt-6">
              <button
                @click="handleSave"
                class="px-6 py-2 bg-primary text-white rounded-md hover:bg-primary/90 transition-colors"
              >
                Salvar
              </button>
            </div>
          </div>

          <div v-else class="bg-white rounded-lg shadow p-6 text-center text-gray-500">
            Selecione uma categoria para começar
          </div>
        </div>
      </div>
    </main>
  </div>
</template>

<style>
.ProseMirror {
  outline: none;
}

.ProseMirror p.is-editor-empty:first-child::before {
  color: #adb5bd;
  content: attr(data-placeholder);
  float: left;
  height: 0;
  pointer-events: none;
}

.ProseMirror img {
  max-width: 100%;
  height: auto;
  cursor: pointer;
  transition: filter 0.2s;
}

.ProseMirror img:hover {
  filter: brightness(0.9);
}

.ProseMirror.drag-active {
  background-color: rgba(0, 0, 0, 0.05);
}

/* Editor content styles */
.prose {
  max-width: none;
}

.prose h1 {
  font-size: 2em;
  font-weight: bold;
  margin: 1em 0;
}

.prose h2 {
  font-size: 1.5em;
  font-weight: bold;
  margin: 0.83em 0;
}

.prose ul {
  list-style-type: disc;
  padding-left: 1.5em;
  margin: 1em 0;
}

.prose ol {
  list-style-type: decimal;
  padding-left: 1.5em;
  margin: 1em 0;
}

.prose pre {
  background-color: #f8f9fa;
  border-radius: 4px;
  padding: 1em;
  margin: 1em 0;
  font-family: monospace;
}

.prose code {
  background-color: #f8f9fa;
  padding: 0.2em 0.4em;
  border-radius: 3px;
  font-family: monospace;
}

.prose a {
  color: #2563eb;
  text-decoration: underline;
}

.prose a:hover {
  color: #1d4ed8;
}
</style>
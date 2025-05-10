<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { Icon } from '@iconify/vue'
import { supabase } from '../../lib/supabase'
import type { Category, Tutorial } from '../../lib/supabase'
import { Editor } from '@tiptap/vue-3'
import StarterKit from '@tiptap/starter-kit'
import Underline from '@tiptap/extension-underline'
import Image from '@tiptap/extension-image'
import Link from '@tiptap/extension-link'
import TextAlign from '@tiptap/extension-text-align'
import TextStyle from '@tiptap/extension-text-style'
import Color from '@tiptap/extension-color'
import FontFamily from '@tiptap/extension-font-family'
import Typography from '@tiptap/extension-typography'
import BulletList from '@tiptap/extension-bullet-list'
import OrderedList from '@tiptap/extension-ordered-list'
import ListItem from '@tiptap/extension-list-item'
import CodeBlock from '@tiptap/extension-code-block'

const router = useRouter()
const categories = ref<Category[]>([])
const tutorials = ref<Tutorial[]>([])
const selectedCategory = ref<Category | null>(null)
const selectedTutorial = ref<Tutorial | null>(null)
const isLoading = ref(true)
const error = ref('')

const editor = ref<Editor | null>(null)
const showPreview = ref(false)

const tutorialCode = ref('')
const tutorialTitle = ref('')

const isEditing = ref(false)

onMounted(async () => {
  await loadData()
  initEditor()
})

const initEditor = () => {
  editor.value = new Editor({
    extensions: [
      StarterKit.configure({
        // Disable Strike since it comes with StarterKit
        strike: false
      }),
      Underline,
      Image,
      Link.configure({
        openOnClick: false,
        HTMLAttributes: {
          target: '_blank',
          rel: 'noopener noreferrer'
        }
      }),
      TextAlign.configure({
        types: ['heading', 'paragraph'],
      }),
      TextStyle,
      Color,
      FontFamily,
      Typography,
      BulletList,
      OrderedList,
      ListItem,
      CodeBlock,
    ],
    editorProps: {
      attributes: {
        class: 'prose prose-sm sm:prose lg:prose-lg xl:prose-2xl mx-auto focus:outline-none',
      },
    },
  })
}

const loadData = async () => {
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
}

const filteredTutorials = computed(() => {
  if (!selectedCategory.value) return []
  return tutorials.value.filter(t => t.category_id === selectedCategory.value?.id)
})

const selectCategory = (category: Category) => {
  selectedCategory.value = category
  selectedTutorial.value = null
  resetForm()
}

const selectTutorial = (tutorial: Tutorial) => {
  selectedTutorial.value = tutorial
  tutorialCode.value = tutorial.code
  tutorialTitle.value = tutorial.title
  if (editor.value) {
    editor.value.commands.setContent(tutorial.content || '')
  }
  isEditing.value = true
}

const resetForm = () => {
  tutorialCode.value = ''
  tutorialTitle.value = ''
  if (editor.value) {
    editor.value.commands.setContent('')
  }
  isEditing.value = false
}

const handleSubmit = async () => {
  if (!selectedCategory.value || !editor.value) return

  try {
    const tutorialData = {
      code: tutorialCode.value,
      title: tutorialTitle.value,
      content: editor.value.getHTML(),
      category_id: selectedCategory.value.id
    }

    if (isEditing.value && selectedTutorial.value) {
      const { error: updateError } = await supabase
        .from('tutorials')
        .update(tutorialData)
        .eq('id', selectedTutorial.value.id)

      if (updateError) throw updateError
    } else {
      const { error: insertError } = await supabase
        .from('tutorials')
        .insert([tutorialData])

      if (insertError) throw insertError
    }

    await loadData()
    resetForm()
  } catch (err) {
    error.value = 'Erro ao salvar tutorial'
    console.error(err)
  }
}

const handleFileUpload = async (event: Event) => {
  const input = event.target as HTMLInputElement
  if (!input.files?.length) return

  const file = input.files[0]
  const fileExt = file.name.split('.').pop()
  const fileName = `${Date.now()}-${Math.random().toString(36).substring(2)}.${fileExt}`
  const filePath = `${fileName}`

  try {
    // Create bucket if it doesn't exist
    const { error: bucketError } = await supabase.storage.createBucket('tutorial-assets', {
      public: true
    })

    if (bucketError && bucketError.message !== 'Bucket already exists') {
      throw bucketError
    }

    const { data, error: uploadError } = await supabase.storage
      .from('tutorial-assets')
      .upload(filePath, file)

    if (uploadError) throw uploadError

    const { data: { publicUrl } } = supabase.storage
      .from('tutorial-assets')
      .getPublicUrl(filePath)

    if (editor.value) {
      editor.value.chain().focus().setImage({ src: publicUrl }).run()
    }
  } catch (err) {
    console.error('Error uploading file:', err)
    error.value = 'Erro ao fazer upload da imagem'
  }
}

const handleLogout = async () => {
  try {
    const { error: logoutError } = await supabase.auth.signOut()
    if (logoutError) throw logoutError
    router.push('/admin')
  } catch (err) {
    console.error('Error logging out:', err)
    error.value = 'Erro ao fazer logout'
  }
}
</script>

<template>
  <div class="min-h-screen bg-gray-100">
    <header class="bg-white shadow">
      <div class="max-w-7xl mx-auto py-6 px-4 sm:px-6 lg:px-8 flex justify-between items-center">
        <h1 class="text-3xl font-bold text-gray-900">Painel Administrativo</h1>
        <button 
          @click="handleLogout"
          class="bg-red-500 text-white px-4 py-2 rounded hover:bg-red-600 transition-colors"
        >
          Sair
        </button>
      </div>
    </header>

    <main class="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
      <div v-if="error" class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
        {{ error }}
      </div>

      <div class="flex gap-6">
        <!-- Categories Sidebar -->
        <div class="w-64 bg-white rounded-lg shadow p-4">
          <h2 class="text-lg font-semibold mb-4">Categorias</h2>
          <div class="space-y-2">
            <button
              v-for="category in categories"
              :key="category.id"
              @click="selectCategory(category)"
              class="w-full text-left px-4 py-2 rounded hover:bg-gray-100 transition-colors"
              :class="{ 'bg-gray-100': selectedCategory?.id === category.id }"
            >
              {{ category.title }}
            </button>
          </div>
        </div>

        <!-- Main Content -->
        <div class="flex-1">
          <div v-if="selectedCategory" class="bg-white rounded-lg shadow p-6">
            <div class="flex justify-between items-center mb-6">
              <h2 class="text-xl font-semibold">{{ selectedCategory.title }}</h2>
              <button
                v-if="isEditing"
                @click="resetForm"
                class="bg-gray-500 text-white px-4 py-2 rounded hover:bg-gray-600 transition-colors"
              >
                Novo Tutorial
              </button>
            </div>

            <!-- Tutorial List -->
            <div v-if="!isEditing" class="mb-6">
              <h3 class="text-lg font-medium mb-4">Tutoriais Existentes</h3>
              <div class="space-y-2">
                <div
                  v-for="tutorial in filteredTutorials"
                  :key="tutorial.id"
                  @click="selectTutorial(tutorial)"
                  class="p-4 border rounded cursor-pointer hover:bg-gray-50 transition-colors"
                >
                  <div class="font-medium">{{ tutorial.code }}</div>
                  <div class="text-gray-600">{{ tutorial.title }}</div>
                </div>
              </div>
            </div>

            <!-- Tutorial Form -->
            <form @submit.prevent="handleSubmit" class="space-y-6">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">
                  Código
                </label>
                <input
                  type="text"
                  v-model="tutorialCode"
                  required
                  class="w-full px-3 py-2 border rounded-md"
                />
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">
                  Título
                </label>
                <input
                  type="text"
                  v-model="tutorialTitle"
                  required
                  class="w-full px-3 py-2 border rounded-md"
                />
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">
                  Conteúdo
                </label>
                <div class="border rounded-md p-4">
                  <!-- Editor Menu -->
                  <div class="flex flex-wrap gap-2 mb-4 border-b pb-4">
                    <button
                      type="button"
                      @click="editor?.chain().focus().toggleBold().run()"
                      :class="{ 'bg-gray-200': editor?.isActive('bold') }"
                      class="p-2 rounded hover:bg-gray-100"
                    >
                      <Icon icon="material-symbols:format-bold" />
                    </button>
                    <button
                      type="button"
                      @click="editor?.chain().focus().toggleItalic().run()"
                      :class="{ 'bg-gray-200': editor?.isActive('italic') }"
                      class="p-2 rounded hover:bg-gray-100"
                    >
                      <Icon icon="material-symbols:format-italic" />
                    </button>
                    <button
                      type="button"
                      @click="editor?.chain().focus().toggleUnderline().run()"
                      :class="{ 'bg-gray-200': editor?.isActive('underline') }"
                      class="p-2 rounded hover:bg-gray-100"
                    >
                      <Icon icon="material-symbols:format-underlined" />
                    </button>
                    <button
                      type="button"
                      @click="editor?.chain().focus().toggleStrike().run()"
                      :class="{ 'bg-gray-200': editor?.isActive('strike') }"
                      class="p-2 rounded hover:bg-gray-100"
                    >
                      <Icon icon="material-symbols:format-strikethrough" />
                    </button>
                    <button
                      type="button"
                      @click="editor?.chain().focus().toggleHeading({ level: 1 }).run()"
                      :class="{ 'bg-gray-200': editor?.isActive('heading', { level: 1 }) }"
                      class="p-2 rounded hover:bg-gray-100"
                    >
                      <Icon icon="material-symbols:format-h1" />
                    </button>
                    <button
                      type="button"
                      @click="editor?.chain().focus().toggleHeading({ level: 2 }).run()"
                      :class="{ 'bg-gray-200': editor?.isActive('heading', { level: 2 }) }"
                      class="p-2 rounded hover:bg-gray-100"
                    >
                      <Icon icon="material-symbols:format-h2" />
                    </button>
                    <button
                      type="button"
                      @click="editor?.chain().focus().toggleBulletList().run()"
                      :class="{ 'bg-gray-200': editor?.isActive('bulletList') }"
                      class="p-2 rounded hover:bg-gray-100"
                    >
                      <Icon icon="material-symbols:format-list-bulleted" />
                    </button>
                    <button
                      type="button"
                      @click="editor?.chain().focus().toggleOrderedList().run()"
                      :class="{ 'bg-gray-200': editor?.isActive('orderedList') }"
                      class="p-2 rounded hover:bg-gray-100"
                    >
                      <Icon icon="material-symbols:format-list-numbered" />
                    </button>
                    <button
                      type="button"
                      @click="editor?.chain().focus().toggleCodeBlock().run()"
                      :class="{ 'bg-gray-200': editor?.isActive('codeBlock') }"
                      class="p-2 rounded hover:bg-gray-100"
                    >
                      <Icon icon="material-symbols:code" />
                    </button>
                    <button
                      type="button"
                      @click="editor?.chain().focus().toggleLink({ href: window.prompt('URL:') || '' }).run()"
                      :class="{ 'bg-gray-200': editor?.isActive('link') }"
                      class="p-2 rounded hover:bg-gray-100"
                    >
                      <Icon icon="material-symbols:link" />
                    </button>
                    <label 
                      class="p-2 rounded hover:bg-gray-100 cursor-pointer"
                      title="Upload image"
                    >
                      <Icon icon="material-symbols:image" />
                      <input
                        type="file"
                        @change="handleFileUpload"
                        accept="image/*"
                        class="hidden"
                      />
                    </label>
                  </div>

                  <!-- Editor Content -->
                  <editor-content :editor="editor" class="min-h-[200px]" />
                </div>
              </div>

              <div class="flex justify-end gap-4">
                <button
                  type="button"
                  @click="showPreview = !showPreview"
                  class="px-4 py-2 text-gray-700 bg-gray-100 rounded hover:bg-gray-200 transition-colors"
                >
                  {{ showPreview ? 'Editar' : 'Visualizar' }}
                </button>
                <button
                  type="submit"
                  class="px-4 py-2 bg-primary text-white rounded hover:bg-primary/90 transition-colors"
                >
                  {{ isEditing ? 'Atualizar' : 'Criar' }} Tutorial
                </button>
              </div>
            </form>
          </div>
        </div>
      </div>
    </main>
  </div>
</template>

<style>
/* TipTap Editor Styles */
.ProseMirror {
  > * + * {
    margin-top: 0.75em;
  }

  ul,
  ol {
    padding: 0 1rem;
  }

  h1 {
    font-size: 2em;
    font-weight: bold;
  }

  h2 {
    font-size: 1.5em;
    font-weight: bold;
  }

  code {
    background-color: rgba(#616161, 0.1);
    color: #616161;
  }

  pre {
    background: #0D0D0D;
    color: #FFF;
    font-family: 'JetBrainsMono', monospace;
    padding: 0.75rem 1rem;
    border-radius: 0.5rem;

    code {
      color: inherit;
      padding: 0;
      background: none;
      font-size: 0.8rem;
    }
  }

  img {
    max-width: 100%;
    height: auto;
  }

  blockquote {
    padding-left: 1rem;
    border-left: 2px solid rgba(#0D0D0D, 0.1);
  }

  hr {
    border: none;
    border-top: 2px solid rgba(#0D0D0D, 0.1);
    margin: 2rem 0;
  }
}
</style>
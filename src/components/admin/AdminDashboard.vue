<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { Editor } from '@tiptap/vue-3'
import StarterKit from '@tiptap/starter-kit'
import Image from '@tiptap/extension-image'
import Link from '@tiptap/extension-link'
import TextAlign from '@tiptap/extension-text-align'
import Underline from '@tiptap/extension-underline'
import Strike from '@tiptap/extension-strike'
import Highlight from '@tiptap/extension-highlight'
import TextStyle from '@tiptap/extension-text-style'
import Color from '@tiptap/extension-color'
import FontFamily from '@tiptap/extension-font-family'
import Typography from '@tiptap/extension-typography'
import BulletList from '@tiptap/extension-bullet-list'
import OrderedList from '@tiptap/extension-ordered-list'
import ListItem from '@tiptap/extension-list-item'
import CodeBlock from '@tiptap/extension-code-block'
import { Icon } from '@iconify/vue'
import { supabase, uploadTutorialImage } from '../../lib/supabase'

const router = useRouter()
const title = ref('')
const content = ref('')
const loading = ref(false)
const error = ref('')
const uploadError = ref('')

const editor = new Editor({
  extensions: [
    StarterKit,
    Image,
    Link.configure({
      openOnClick: false,
      HTMLAttributes: {
        class: 'text-blue-500 underline'
      }
    }),
    TextAlign.configure({
      types: ['heading', 'paragraph']
    }),
    Underline,
    Strike,
    Highlight,
    TextStyle,
    Color,
    FontFamily,
    Typography,
    BulletList,
    OrderedList,
    ListItem,
    CodeBlock
  ],
  content: '',
  editorProps: {
    attributes: {
      class: 'prose prose-sm sm:prose lg:prose-lg xl:prose-2xl mx-auto focus:outline-none'
    }
  }
})

const handleImageUpload = async (event: Event) => {
  const input = event.target as HTMLInputElement
  if (!input.files?.length) return

  const file = input.files[0]
  uploadError.value = ''

  try {
    const url = await uploadTutorialImage(file)
    editor.chain().focus().setImage({ src: url }).run()
  } catch (err) {
    console.error('Image upload error:', err)
    uploadError.value = 'Erro ao fazer upload da imagem. Por favor, tente novamente.'
  }
}

const addImage = () => {
  const input = document.createElement('input')
  input.type = 'file'
  input.accept = 'image/*'
  input.onchange = handleImageUpload
  input.click()
}

const addLink = () => {
  const url = window.prompt('URL:')
  if (url) {
    editor.chain().focus().setLink({ href: url }).run()
  }
}

const handleSubmit = async () => {
  if (!title.value || !editor.getHTML()) {
    error.value = 'Por favor, preencha todos os campos'
    return
  }

  loading.value = true
  error.value = ''

  try {
    const { data, error: submitError } = await supabase
      .from('tutorials')
      .insert([
        {
          title: title.value,
          content: editor.getHTML()
        }
      ])

    if (submitError) throw submitError

    router.push('/')
  } catch (err) {
    console.error('Submit error:', err)
    error.value = 'Erro ao salvar o tutorial'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="min-h-screen bg-gray-50">
    <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div class="grid grid-cols-12 gap-8">
        <!-- Editor Column -->
        <div class="col-span-9 space-y-6">
          <div v-if="error" class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded">
            {{ error }}
          </div>
          
          <div v-if="uploadError" class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded">
            {{ uploadError }}
          </div>

          <div class="bg-white shadow-sm rounded-lg">
            <div class="p-6">
              <input
                type="text"
                v-model="title"
                placeholder="Título do tutorial"
                class="w-full text-3xl font-bold border-0 focus:ring-0 focus:outline-none mb-6"
              >
              
              <div class="border-t border-gray-200 -mx-6 px-6 py-4 flex items-center gap-2 flex-wrap">
                <button
                  @click="editor.chain().focus().toggleBold().run()"
                  :class="{ 'is-active': editor.isActive('bold') }"
                  class="editor-btn"
                >
                  <Icon icon="material-symbols:format-bold" />
                </button>
                
                <button
                  @click="editor.chain().focus().toggleItalic().run()"
                  :class="{ 'is-active': editor.isActive('italic') }"
                  class="editor-btn"
                >
                  <Icon icon="material-symbols:format-italic" />
                </button>
                
                <button
                  @click="editor.chain().focus().toggleUnderline().run()"
                  :class="{ 'is-active': editor.isActive('underline') }"
                  class="editor-btn"
                >
                  <Icon icon="material-symbols:format-underlined" />
                </button>
                
                <button
                  @click="editor.chain().focus().toggleStrike().run()"
                  :class="{ 'is-active': editor.isActive('strike') }"
                  class="editor-btn"
                >
                  <Icon icon="material-symbols:format-strikethrough" />
                </button>
                
                <div class="w-px h-6 bg-gray-200 mx-2"></div>
                
                <button
                  @click="editor.chain().focus().toggleHeading({ level: 1 }).run()"
                  :class="{ 'is-active': editor.isActive('heading', { level: 1 }) }"
                  class="editor-btn"
                >
                  <Icon icon="material-symbols:format-h1" />
                </button>
                
                <button
                  @click="editor.chain().focus().toggleHeading({ level: 2 }).run()"
                  :class="{ 'is-active': editor.isActive('heading', { level: 2 }) }"
                  class="editor-btn"
                >
                  <Icon icon="material-symbols:format-h2" />
                </button>
                
                <div class="w-px h-6 bg-gray-200 mx-2"></div>
                
                <button
                  @click="editor.chain().focus().toggleBulletList().run()"
                  :class="{ 'is-active': editor.isActive('bulletList') }"
                  class="editor-btn"
                >
                  <Icon icon="material-symbols:format-list-bulleted" />
                </button>
                
                <button
                  @click="editor.chain().focus().toggleOrderedList().run()"
                  :class="{ 'is-active': editor.isActive('orderedList') }"
                  class="editor-btn"
                >
                  <Icon icon="material-symbols:format-list-numbered" />
                </button>
                
                <button
                  @click="editor.chain().focus().toggleCodeBlock().run()"
                  :class="{ 'is-active': editor.isActive('codeBlock') }"
                  class="editor-btn"
                >
                  <Icon icon="material-symbols:code" />
                </button>
                
                <div class="w-px h-6 bg-gray-200 mx-2"></div>
                
                <button
                  @click="addImage"
                  class="editor-btn"
                >
                  <Icon icon="material-symbols:image" />
                </button>
                
                <button
                  @click="addLink"
                  :class="{ 'is-active': editor.isActive('link') }"
                  class="editor-btn"
                >
                  <Icon icon="material-symbols:link" />
                </button>
              </div>
              
              <div class="mt-4">
                <editor-content :editor="editor" />
              </div>
            </div>
          </div>

          <div class="flex justify-end">
            <button
              @click="handleSubmit"
              :disabled="loading"
              class="bg-primary text-white px-6 py-2 rounded-lg hover:bg-primary/90 disabled:opacity-50"
            >
              {{ loading ? 'Salvando...' : 'Salvar Tutorial' }}
            </button>
          </div>
        </div>

        <!-- Preview Column -->
        <div class="col-span-3">
          <div class="bg-white shadow-sm rounded-lg p-6">
            <h3 class="text-lg font-medium text-gray-900 mb-4">Pré-visualização</h3>
            <div class="prose prose-sm" v-html="editor.getHTML()"></div>
          </div>
        </div>
      </div>
    </main>
  </div>
</template>

<style>
.editor-btn {
  @apply p-2 rounded hover:bg-gray-100 transition-colors;
}

.editor-btn.is-active {
  @apply bg-gray-100 text-primary;
}

.ProseMirror {
  min-height: 200px;
}

.ProseMirror p.is-editor-empty:first-child::before {
  color: #adb5bd;
  content: attr(data-placeholder);
  float: left;
  height: 0;
  pointer-events: none;
}
</style>
<script setup lang="ts">
import { ref, onMounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import { Icon } from '@iconify/vue'
import { marked } from 'marked'
import { useEditor, EditorContent } from '@tiptap/vue-3'
import StarterKit from '@tiptap/starter-kit'
import Image from '@tiptap/extension-image'
import Link from '@tiptap/extension-link'
import TextAlign from '@tiptap/extension-text-align'
import Underline from '@tiptap/extension-underline'
import Strike from '@tiptap/extension-strike'
import Highlight from '@tiptap/extension-highlight'
import { Color } from '@tiptap/extension-color'
import TextStyle from '@tiptap/extension-text-style'
import { FontFamily } from '@tiptap/extension-font-family'
import Typography from '@tiptap/extension-typography'
import BulletList from '@tiptap/extension-bullet-list'
import OrderedList from '@tiptap/extension-ordered-list'
import ListItem from '@tiptap/extension-list-item'
import CodeBlock from '@tiptap/extension-code-block'
import { supabase } from '../lib/supabase'
import ImageModal from './ImageModal.vue'
import TutorialRating from './TutorialRating.vue'

const route = useRoute()
const loading = ref(false)
const error = ref('')
const tutorial = ref<any>(null)
const showImageModal = ref(false)
const selectedImage = ref({ src: '', alt: '' })
const isAdmin = ref(false)

const editor = useEditor({
  extensions: [
    StarterKit,
    Image,
    Link.configure({
      openOnClick: false,
      HTMLAttributes: {
        target: '_blank',
        rel: 'noopener noreferrer nofollow'
      }
    }),
    TextAlign.configure({
      types: ['heading', 'paragraph']
    }),
    Underline,
    Strike,
    Highlight,
    Color,
    TextStyle,
    FontFamily,
    Typography,
    BulletList,
    OrderedList,
    ListItem,
    CodeBlock
  ],
  editorProps: {
    attributes: {
      class: 'prose prose-sm sm:prose lg:prose-lg xl:prose-2xl mx-auto focus:outline-none'
    }
  }
})

const checkAdminStatus = async () => {
  const { data: { session } } = await supabase.auth.getSession()
  isAdmin.value = !!session
}

const fetchTutorial = async () => {
  const tutorialId = route.query.tutorial as string
  if (!tutorialId) return

  try {
    loading.value = true
    error.value = ''

    const { data, error: fetchError } = await supabase
      .from('tutorials')
      .select('*')
      .eq('id', tutorialId)
      .single()

    if (fetchError) throw fetchError

    tutorial.value = data
    if (editor.value && data.content) {
      editor.value.commands.setContent(data.content)
    }
  } catch (err) {
    console.error('Error fetching tutorial:', err)
    error.value = 'Erro ao carregar tutorial'
  } finally {
    loading.value = false
  }
}

const handleImageUpload = async (event: Event) => {
  const input = event.target as HTMLInputElement
  if (!input.files?.length) return

  const file = input.files[0]
  const fileExt = file.name.split('.').pop()
  const fileName = `${Date.now()}-${Math.random().toString(36).substring(2)}.${fileExt}`
  const filePath = fileName

  try {
    loading.value = true
    const { data: uploadData, error: uploadError } = await supabase.storage
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
    console.error('Error uploading image:', err)
    error.value = 'Erro ao fazer upload da imagem'
  } finally {
    loading.value = false
  }
}

const saveTutorial = async () => {
  if (!tutorial.value || !editor.value) return

  try {
    loading.value = true
    error.value = ''

    const { error: updateError } = await supabase
      .from('tutorials')
      .update({
        content: editor.value.getHTML(),
        updated_at: new Date().toISOString()
      })
      .eq('id', tutorial.value.id)

    if (updateError) throw updateError

  } catch (err) {
    console.error('Error saving tutorial:', err)
    error.value = 'Erro ao salvar tutorial'
  } finally {
    loading.value = false
  }
}

const openImage = (src: string, alt: string) => {
  selectedImage.value = { src, alt }
  showImageModal.value = true
}

onMounted(async () => {
  await Promise.all([
    checkAdminStatus(),
    fetchTutorial()
  ])
})

watch(() => route.query.tutorial, fetchTutorial)
</script>

<template>
  <div class="tutorial-container">
    <div v-if="loading" class="loading">
      <p>Carregando...</p>
    </div>

    <div v-else-if="error" class="error">
      <p>{{ error }}</p>
    </div>

    <div v-else-if="tutorial" class="tutorial-content">
      <div class="tutorial-header">
        <span class="tutorial-code">{{ tutorial.code }}</span>
        <h1>{{ tutorial.title }}</h1>
      </div>

      <div class="editor-container">
        <div v-if="isAdmin" class="editor-toolbar">
          <button @click="editor?.chain().focus().toggleBold().run()" 
                  :class="{ 'is-active': editor?.isActive('bold') }">
            <Icon icon="material-symbols:format-bold" />
          </button>
          
          <button @click="editor?.chain().focus().toggleItalic().run()"
                  :class="{ 'is-active': editor?.isActive('italic') }">
            <Icon icon="material-symbols:format-italic" />
          </button>
          
          <button @click="editor?.chain().focus().toggleUnderline().run()"
                  :class="{ 'is-active': editor?.isActive('underline') }">
            <Icon icon="material-symbols:format-underlined" />
          </button>
          
          <button @click="editor?.chain().focus().toggleStrike().run()"
                  :class="{ 'is-active': editor?.isActive('strike') }">
            <Icon icon="material-symbols:format-strikethrough" />
          </button>

          <div class="divider"></div>

          <button @click="editor?.chain().focus().toggleHeading({ level: 1 }).run()"
                  :class="{ 'is-active': editor?.isActive('heading', { level: 1 }) }">
            <Icon icon="material-symbols:format-h1" />
          </button>
          
          <button @click="editor?.chain().focus().toggleHeading({ level: 2 }).run()"
                  :class="{ 'is-active': editor?.isActive('heading', { level: 2 }) }">
            <Icon icon="material-symbols:format-h2" />
          </button>

          <div class="divider"></div>

          <button @click="editor?.chain().focus().toggleBulletList().run()"
                  :class="{ 'is-active': editor?.isActive('bulletList') }">
            <Icon icon="material-symbols:format-list-bulleted" />
          </button>
          
          <button @click="editor?.chain().focus().toggleOrderedList().run()"
                  :class="{ 'is-active': editor?.isActive('orderedList') }">
            <Icon icon="material-symbols:format-list-numbered" />
          </button>

          <div class="divider"></div>

          <button @click="editor?.chain().focus().toggleCodeBlock().run()"
                  :class="{ 'is-active': editor?.isActive('codeBlock') }">
            <Icon icon="material-symbols:code" />
          </button>

          <div class="divider"></div>

          <button @click="() => {
            const url = window.prompt('URL:')
            if (url) {
              editor?.chain().focus().setLink({ href: url }).run()
            }
          }"
          :class="{ 'is-active': editor?.isActive('link') }">
            <Icon icon="material-symbols:link" />
          </button>

          <div class="divider"></div>

          <label class="image-upload-button">
            <Icon icon="material-symbols:image" />
            <input 
              type="file" 
              accept="image/*"
              @change="handleImageUpload"
              style="display: none"
            >
          </label>

          <div class="divider"></div>

          <button 
            v-if="isAdmin" 
            @click="saveTutorial"
            class="save-button"
            :disabled="loading"
          >
            <Icon icon="material-symbols:save" />
            {{ loading ? 'Salvando...' : 'Salvar' }}
          </button>
        </div>

        <editor-content :editor="editor" class="editor-content" />
      </div>

      <tutorial-rating 
        v-if="tutorial.id"
        :tutorial-id="tutorial.id"
      />
    </div>

    <div v-else class="no-tutorial">
      <p>Selecione um tutorial para visualizar</p>
    </div>

    <image-modal
      :show="showImageModal"
      :image-src="selectedImage.src"
      :image-alt="selectedImage.alt"
      @close="showImageModal = false"
    />
  </div>
</template>

<style scoped>
.tutorial-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem;
  background: white;
  min-height: 100vh;
}

.tutorial-header {
  margin-bottom: 2rem;
}

.tutorial-code {
  display: inline-block;
  padding: 0.25rem 0.5rem;
  background: #f3f4f6;
  border-radius: 4px;
  font-family: monospace;
  color: #374151;
  margin-bottom: 0.5rem;
}

.tutorial-header h1 {
  font-size: 2rem;
  color: #1f2937;
  margin: 0;
}

.editor-container {
  position: relative;
  margin-bottom: 2rem;
}

.editor-toolbar {
  display: flex;
  gap: 0.5rem;
  padding: 0.5rem;
  background: #f9fafb;
  border: 1px solid #e5e7eb;
  border-bottom: none;
  border-radius: 6px 6px 0 0;
  flex-wrap: wrap;
}

.editor-toolbar button,
.image-upload-button {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 2rem;
  height: 2rem;
  border: none;
  background: transparent;
  color: #4b5563;
  border-radius: 4px;
  cursor: pointer;
  transition: all 0.2s;
}

.editor-toolbar button:hover,
.image-upload-button:hover {
  background: #e5e7eb;
  color: #1f2937;
}

.editor-toolbar button.is-active {
  background: #e5e7eb;
  color: #2563eb;
}

.divider {
  width: 1px;
  background: #e5e7eb;
  margin: 0 0.25rem;
}

.editor-content {
  border: 1px solid #e5e7eb;
  border-radius: 0 0 6px 6px;
  padding: 1rem;
  min-height: 300px;
}

.save-button {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0 1rem;
  width: auto !important;
  background: #2563eb !important;
  color: white !important;
}

.save-button:hover {
  background: #1d4ed8 !important;
}

.save-button:disabled {
  background: #93c5fd !important;
  cursor: not-allowed;
}

.loading,
.error,
.no-tutorial {
  text-align: center;
  padding: 2rem;
  color: #6b7280;
}

.error {
  color: #dc2626;
}

@media (max-width: 768px) {
  .tutorial-container {
    padding: 1rem;
  }

  .editor-toolbar {
    justify-content: center;
  }
}
</style>
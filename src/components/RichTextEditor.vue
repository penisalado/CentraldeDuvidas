<script setup lang="ts">
import { ref, watch } from 'vue'
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
import BulletList from '@tiptap/extension-bullet-list'
import OrderedList from '@tiptap/extension-ordered-list'
import ListItem from '@tiptap/extension-list-item'
import CodeBlock from '@tiptap/extension-code-block'
import { Icon } from '@iconify/vue'
import { uploadTutorialImage, saveTutorialImage } from '../lib/supabase'

const props = defineProps<{
  modelValue: string
  tutorialId?: string
}>()

const emit = defineEmits<{
  (e: 'update:modelValue', value: string): void
  (e: 'error', message: string): void
}>()

const editor = ref<Editor | null>(null)
const isUploading = ref(false)

// Initialize editor
editor.value = new Editor({
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
  content: props.modelValue,
  onUpdate: ({ editor }) => {
    emit('update:modelValue', editor.getHTML())
  }
})

// Watch for external content changes
watch(() => props.modelValue, (newContent) => {
  if (editor.value && newContent !== editor.value.getHTML()) {
    editor.value.commands.setContent(newContent)
  }
})

const handleImageUpload = async (event: Event) => {
  const input = event.target as HTMLInputElement
  if (!input.files?.length) return

  const file = input.files[0]
  if (!file.type.startsWith('image/')) {
    emit('error', 'Por favor, selecione apenas arquivos de imagem')
    return
  }

  try {
    isUploading.value = true
    const imageUrl = await uploadTutorialImage(file)
    
    if (props.tutorialId) {
      await saveTutorialImage(props.tutorialId, imageUrl, file.name)
    }

    editor.value?.chain().focus().setImage({ src: imageUrl }).run()
  } catch (error) {
    console.error('Error uploading image:', error)
    emit('error', 'Erro ao fazer upload da imagem')
  } finally {
    isUploading.value = false
    if (input) input.value = '' // Reset input
  }
}

const setLink = () => {
  const url = window.prompt('URL:')
  if (url) {
    editor.value?.chain().focus().setLink({ href: url }).run()
  }
}
</script>

<template>
  <div class="editor-wrapper">
    <div class="editor-toolbar" v-if="editor">
      <button 
        @click="editor.chain().focus().toggleBold().run()"
        :class="{ 'is-active': editor.isActive('bold') }"
        title="Negrito"
      >
        <Icon icon="material-symbols:format-bold" />
      </button>
      
      <button 
        @click="editor.chain().focus().toggleItalic().run()"
        :class="{ 'is-active': editor.isActive('italic') }"
        title="Itálico"
      >
        <Icon icon="material-symbols:format-italic" />
      </button>
      
      <button 
        @click="editor.chain().focus().toggleUnderline().run()"
        :class="{ 'is-active': editor.isActive('underline') }"
        title="Sublinhado"
      >
        <Icon icon="material-symbols:format-underlined" />
      </button>
      
      <button 
        @click="editor.chain().focus().toggleStrike().run()"
        :class="{ 'is-active': editor.isActive('strike') }"
        title="Riscado"
      >
        <Icon icon="material-symbols:format-strikethrough" />
      </button>
      
      <div class="divider"></div>
      
      <button 
        @click="editor.chain().focus().toggleHeading({ level: 1 }).run()"
        :class="{ 'is-active': editor.isActive('heading', { level: 1 }) }"
        title="Título 1"
      >
        <Icon icon="material-symbols:format-h1" />
      </button>
      
      <button 
        @click="editor.chain().focus().toggleHeading({ level: 2 }).run()"
        :class="{ 'is-active': editor.isActive('heading', { level: 2 }) }"
        title="Título 2"
      >
        <Icon icon="material-symbols:format-h2" />
      </button>
      
      <div class="divider"></div>
      
      <button 
        @click="editor.chain().focus().toggleBulletList().run()"
        :class="{ 'is-active': editor.isActive('bulletList') }"
        title="Lista com marcadores"
      >
        <Icon icon="material-symbols:format-list-bulleted" />
      </button>
      
      <button 
        @click="editor.chain().focus().toggleOrderedList().run()"
        :class="{ 'is-active': editor.isActive('orderedList') }"
        title="Lista numerada"
      >
        <Icon icon="material-symbols:format-list-numbered" />
      </button>
      
      <button 
        @click="editor.chain().focus().toggleCodeBlock().run()"
        :class="{ 'is-active': editor.isActive('codeBlock') }"
        title="Bloco de código"
      >
        <Icon icon="material-symbols:code" />
      </button>
      
      <div class="divider"></div>
      
      <button 
        @click="setLink"
        :class="{ 'is-active': editor.isActive('link') }"
        title="Inserir link"
      >
        <Icon icon="material-symbols:link" />
      </button>
      
      <label 
        class="image-upload-button"
        :class="{ 'is-uploading': isUploading }"
        title="Inserir imagem"
      >
        <input 
          type="file" 
          accept="image/*" 
          @change="handleImageUpload" 
          :disabled="isUploading"
        >
        <Icon icon="material-symbols:image" />
      </label>
    </div>

    <EditorContent :editor="editor" class="editor-content" />
  </div>
</template>

<style scoped>
.editor-wrapper {
  border: 1px solid #e2e2e2;
  border-radius: 8px;
  overflow: hidden;
}

.editor-toolbar {
  display: flex;
  padding: 0.5rem;
  border-bottom: 1px solid #e2e2e2;
  background: #f8f9fa;
  flex-wrap: wrap;
  gap: 0.25rem;
}

.editor-toolbar button,
.image-upload-button {
  background: none;
  border: none;
  padding: 0.5rem;
  cursor: pointer;
  border-radius: 4px;
  color: #4b5563;
  display: flex;
  align-items: center;
  justify-content: center;
}

.editor-toolbar button:hover,
.image-upload-button:hover {
  background-color: #e5e7eb;
}

.editor-toolbar button.is-active {
  background-color: #e5e7eb;
  color: #000;
}

.divider {
  width: 1px;
  background-color: #e2e2e2;
  margin: 0 0.5rem;
}

.image-upload-button {
  position: relative;
  overflow: hidden;
}

.image-upload-button input {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  opacity: 0;
  cursor: pointer;
}

.image-upload-button.is-uploading {
  opacity: 0.5;
  cursor: not-allowed;
}

.editor-content {
  padding: 1rem;
  min-height: 200px;
  background: white;
}

.editor-content :deep(.ProseMirror) {
  outline: none;
}

.editor-content :deep(.ProseMirror p) {
  margin: 1em 0;
}

.editor-content :deep(.ProseMirror h1) {
  font-size: 2em;
  margin: 1em 0;
}

.editor-content :deep(.ProseMirror h2) {
  font-size: 1.5em;
  margin: 1em 0;
}

.editor-content :deep(.ProseMirror ul),
.editor-content :deep(.ProseMirror ol) {
  padding-left: 1.5em;
  margin: 1em 0;
}

.editor-content :deep(.ProseMirror code) {
  background-color: #f1f1f1;
  padding: 0.2em 0.4em;
  border-radius: 3px;
}

.editor-content :deep(.ProseMirror pre) {
  background: #0d0d0d;
  color: #fff;
  padding: 0.75rem 1rem;
  border-radius: 0.5rem;
  margin: 1em 0;
}

.editor-content :deep(.ProseMirror pre code) {
  color: inherit;
  padding: 0;
  background: none;
  font-size: 0.8rem;
}

.editor-content :deep(.ProseMirror img) {
  max-width: 100%;
  height: auto;
}

.editor-content :deep(.ProseMirror a) {
  color: #2563eb;
  text-decoration: underline;
}
</style>
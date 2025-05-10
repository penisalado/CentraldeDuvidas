import { ref, computed, onMounted, watch } from 'vue'
import { useRouter } from 'vue-router'
import { Editor } from '@tiptap/vue-3'
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

// Rest of your existing component code...

<template>
  <!-- Rest of your existing template -->
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
  <!-- Rest of your existing template -->
</template>

<style>
/* Rest of your existing styles */
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
</style>
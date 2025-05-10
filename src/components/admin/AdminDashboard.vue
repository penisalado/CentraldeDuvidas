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

// Rest of your component code...
</script>

<template>
  <!-- Your existing template code -->
</template>

<style>
/* Your existing styles */

/* Add styles for drag and drop */
.ProseMirror-focused {
  outline: none;
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
</style>
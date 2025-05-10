<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount } from 'vue'
import { useEditor, EditorContent } from '@tiptap/vue-3'
import StarterKit from '@tiptap/starter-kit'
import Document from '@tiptap/extension-document'
import Paragraph from '@tiptap/extension-paragraph'
import Text from '@tiptap/extension-text'
import Image from '@tiptap/extension-image'
import Dropcursor from '@tiptap/extension-dropcursor'
import { uploadMediaFile } from '../lib/supabase'

const props = defineProps<{
  modelValue: string
}>()

const emit = defineEmits<{
  (e: 'update:modelValue', value: string): void
}>()

const editor = useEditor({
  content: props.modelValue,
  extensions: [
    StarterKit,
    Document,
    Paragraph,
    Text,
    Image.configure({
      HTMLAttributes: {
        class: 'rounded-lg max-w-full h-auto',
      },
    }),
    Dropcursor.configure({
      color: '#2563eb',
      width: 2,
    }),
  ],
  editorProps: {
    handleDrop: (view, event, slice, moved) => {
      if (!moved && event.dataTransfer?.files.length) {
        const files = Array.from(event.dataTransfer.files)
        const allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'video/mp4']
        
        files.forEach(async (file) => {
          if (allowedTypes.includes(file.type)) {
            try {
              const url = await uploadMediaFile(file)
              
              if (file.type.startsWith('image/')) {
                editor.value?.chain().focus().setImage({ src: url }).run()
              } else if (file.type === 'video/mp4') {
                const video = `<video controls><source src="${url}" type="video/mp4"></video>`
                editor.value?.chain().focus().insertContent(video).run()
              }
            } catch (error) {
              console.error('Error uploading file:', error)
            }
          }
        })
        
        return true
      }
      return false
    },
    handlePaste: (view, event) => {
      if (event.clipboardData?.files.length) {
        const files = Array.from(event.clipboardData.files)
        const allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'video/mp4']
        
        files.forEach(async (file) => {
          if (allowedTypes.includes(file.type)) {
            try {
              const url = await uploadMediaFile(file)
              
              if (file.type.startsWith('image/')) {
                editor.value?.chain().focus().setImage({ src: url }).run()
              } else if (file.type === 'video/mp4') {
                const video = `<video controls><source src="${url}" type="video/mp4"></video>`
                editor.value?.chain().focus().insertContent(video).run()
              }
            } catch (error) {
              console.error('Error uploading file:', error)
            }
          }
        })
        
        return true
      }
      return false
    },
  },
  onUpdate: ({ editor }) => {
    emit('update:modelValue', editor.getHTML())
  },
})

const isDragging = ref(false)

const handleDragEnter = (e: DragEvent) => {
  e.preventDefault()
  isDragging.value = true
}

const handleDragLeave = (e: DragEvent) => {
  e.preventDefault()
  isDragging.value = false
}

const handleDragOver = (e: DragEvent) => {
  e.preventDefault()
}

const handleDrop = (e: DragEvent) => {
  e.preventDefault()
  isDragging.value = false
}

onMounted(() => {
  const editorElement = document.querySelector('.ProseMirror')
  if (editorElement) {
    editorElement.addEventListener('dragenter', handleDragEnter)
    editorElement.addEventListener('dragleave', handleDragLeave)
    editorElement.addEventListener('dragover', handleDragOver)
    editorElement.addEventListener('drop', handleDrop)
  }
})

onBeforeUnmount(() => {
  const editorElement = document.querySelector('.ProseMirror')
  if (editorElement) {
    editorElement.removeEventListener('dragenter', handleDragEnter)
    editorElement.removeEventListener('dragleave', handleDragLeave)
    editorElement.removeEventListener('dragover', handleDragOver)
    editorElement.removeEventListener('drop', handleDrop)
  }
})
</script>

<template>
  <div class="rich-text-editor">
    <editor-content 
      :editor="editor" 
      :class="{ 'drag-over': isDragging }"
    />
    <div v-if="isDragging" class="image-upload-placeholder">
      Solte a imagem ou vídeo aqui
    </div>
  </div>
</template>

<style scoped>
.rich-text-editor {
  position: relative;
}

:deep(.ProseMirror) {
  min-height: 300px;
  padding: 1rem;
  border: 1px solid #e5e7eb;
  border-radius: 0.375rem;
}

:deep(.ProseMirror:focus) {
  outline: 2px solid #2563eb;
  outline-offset: -2px;
}

.drag-over :deep(.ProseMirror) {
  border: 2px dashed #2563eb;
  background-color: rgba(37, 99, 235, 0.1);
}

.image-upload-placeholder {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  background-color: white;
  padding: 1rem 2rem;
  border-radius: 0.375rem;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  pointer-events: none;
}
</style>
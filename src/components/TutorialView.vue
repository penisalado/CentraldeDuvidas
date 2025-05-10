<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { marked } from 'marked'
import { Icon } from '@iconify/vue'
import { supabase } from '../lib/supabase'
import type { Category, Tutorial } from '../lib/supabase'
import SearchBar from './SearchBar.vue'
import ImageModal from './ImageModal.vue'
import TutorialRating from './TutorialRating.vue'
import { Editor } from '@tiptap/vue-3'
import StarterKit from '@tiptap/starter-kit'
import Image from '@tiptap/extension-image'
import Video from '@tiptap/extension-video'
import { useStorage } from '@vueuse/core'

// Hooks do Vue Router
const route = useRoute()
const router = useRouter()

// Estado do modal de imagem
const showImageModal = ref(false)
const selectedImage = ref({
  src: '',
  alt: ''
})

// Editor TipTap
const editor = new Editor({
  extensions: [
    StarterKit,
    Image.configure({
      inline: true,
      HTMLAttributes: {
        class: 'tutorial-image',
      },
    }),
    Video.configure({
      inline: true,
      HTMLAttributes: {
        class: 'tutorial-video',
        controls: true,
      },
    }),
  ],
  content: '',
  editable: true,
})

// Estados do componente
const categories = ref<Category[]>([])
const tutorials = ref<Tutorial[]>([])
const selectedTutorial = ref<Tutorial | null>(null)
const isLoading = ref(true)
const error = ref('')
const uploadProgress = ref(0)

// Função para fazer upload de arquivo
const uploadFile = async (file: File, type: 'image' | 'video') => {
  try {
    const fileExt = file.name.split('.').pop()
    const fileName = `${Math.random().toString(36).substring(2)}.${fileExt}`
    const bucketName = type === 'image' ? 'tutorial-images' : 'tutorial-videos'
    const filePath = `${Date.now()}-${fileName}`

    // Upload para o Supabase Storage
    const { data, error: uploadError } = await supabase.storage
      .from(bucketName)
      .upload(filePath, file, {
        cacheControl: '3600',
        upsert: false,
        onUploadProgress: (progress) => {
          uploadProgress.value = (progress.loaded / progress.total) * 100
        }
      })

    if (uploadError) throw uploadError

    // Obter URL pública
    const { data: { publicUrl } } = supabase.storage
      .from(bucketName)
      .getPublicUrl(filePath)

    // Copiar arquivo para pasta public
    const response = await fetch(publicUrl)
    const blob = await response.blob()
    const formData = new FormData()
    formData.append('file', blob, fileName)

    // Salvar na pasta public
    const publicPath = `/public/${fileName}`
    await fetch('/api/save-file', {
      method: 'POST',
      body: formData
    })

    return publicPath
  } catch (error) {
    console.error(`Error uploading ${type}:`, error)
    throw error
  }
}

// Handler para upload de imagem
const handleImageUpload = async (event: Event) => {
  const input = event.target as HTMLInputElement
  if (!input.files?.length) return

  try {
    uploadProgress.value = 0
    const file = input.files[0]
    const url = await uploadFile(file, 'image')
    editor.chain().focus().setImage({ src: url }).run()
  } catch (error) {
    console.error('Error handling image upload:', error)
  } finally {
    uploadProgress.value = 0
  }
}

// Handler para upload de vídeo
const handleVideoUpload = async (event: Event) => {
  const input = event.target as HTMLInputElement
  if (!input.files?.length) return

  try {
    uploadProgress.value = 0
    const file = input.files[0]
    const url = await uploadFile(file, 'video')
    editor.chain().focus().setVideo({ src: url }).run()
  } catch (error) {
    console.error('Error handling video upload:', error)
  } finally {
    uploadProgress.value = 0
  }
}

// Resto do código permanece o mesmo...
// (Mantenha todas as outras funções e lógica existente)

</script>

<template>
  <div class="tutorial-view" v-if="!isLoading">
    <!-- Container principal -->
    <div v-if="currentCategory" class="tutorial-container">
      <!-- Cabeçalho -->
      <div class="tutorial-header">
        <button class="back-button" @click="goBack">← Voltar</button>
        <div class="header-content">
          <h1>{{ currentCategory.title }}</h1>
          <SearchBar v-model="searchQuery" placeholder="Buscar por código, título ou conteúdo..." />
        </div>
      </div>

      <!-- Lista de tutoriais -->
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

      <!-- Conteúdo do tutorial -->
      <div v-else class="tutorial-content">
        <div class="tutorial-content-header">
          <div class="tutorial-code">{{ selectedTutorial.code }}</div>
          <h2>{{ selectedTutorial.title }}</h2>
        </div>
        
        <!-- Editor TipTap -->
        <div class="editor-container">
          <editor-content :editor="editor" />
          
          <!-- Barra de ferramentas de upload -->
          <div class="upload-toolbar">
            <!-- Upload de imagem -->
            <div class="upload-button-container">
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

            <!-- Upload de vídeo -->
            <div class="upload-button-container">
              <input
                type="file"
                accept="video/*"
                @change="handleVideoUpload"
                class="hidden-input"
                id="video-upload"
              />
              <label for="video-upload" class="upload-button">
                <Icon icon="material-symbols:video-library" class="upload-icon" />
                Adicionar Vídeo
              </label>
            </div>

            <!-- Barra de progresso -->
            <div v-if="uploadProgress > 0" class="upload-progress">
              <div 
                class="progress-bar" 
                :style="{ width: `${uploadProgress}%` }"
              ></div>
            </div>
          </div>
        </div>
        
        <!-- Componente de avaliação -->
        <TutorialRating 
          v-if="selectedTutorial"
          :tutorial-id="selectedTutorial.id"
        />
      </div>

      <!-- Modal de imagem -->
      <ImageModal 
        :show="showImageModal"
        :image-src="selectedImage.src"
        :image-alt="selectedImage.alt"
        @close="showImageModal = false"
      />
    </div>

    <!-- Mensagem de categoria não encontrada -->
    <div v-else class="not-found">
      <h2>Categoria não encontrada</h2>
      <button class="back-button" @click="router.push('/')">← Voltar para a página inicial</button>
    </div>
  </div>

  <!-- Loading state -->
  <div v-else class="loading">
    <p>Carregando...</p>
  </div>
</template>

<style scoped>
/* Estilos existentes permanecem... */

/* Novos estilos para upload */
.upload-toolbar {
  margin-top: 1rem;
  display: flex;
  gap: 1rem;
  align-items: center;
  flex-wrap: wrap;
}

.upload-button-container {
  position: relative;
}

.hidden-input {
  display: none;
}

.upload-button {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.75rem 1rem;
  background-color: #f8f9fa;
  border: 1px solid #dee2e6;
  border-radius: 6px;
  cursor: pointer;
  color: #495057;
  font-size: 0.875rem;
  transition: all 0.2s;
}

.upload-button:hover {
  background-color: #e9ecef;
  border-color: #ced4da;
}

.upload-icon {
  font-size: 1.25rem;
}

.upload-progress {
  flex: 1;
  height: 4px;
  background-color: #e9ecef;
  border-radius: 2px;
  overflow: hidden;
}

.progress-bar {
  height: 100%;
  background-color: #ff5722;
  transition: width 0.3s ease;
}

/* Estilos para imagens e vídeos no editor */
:deep(.tutorial-image) {
  max-width: 100%;
  height: auto;
  border-radius: 8px;
  margin: 1rem 0;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

:deep(.tutorial-video) {
  max-width: 100%;
  border-radius: 8px;
  margin: 1rem 0;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

/* Responsividade */
@media (max-width: 768px) {
  .upload-toolbar {
    flex-direction: column;
    gap: 0.5rem;
  }

  .upload-button-container {
    width: 100%;
  }

  .upload-button {
    width: 100%;
    justify-content: center;
  }
}
</style>
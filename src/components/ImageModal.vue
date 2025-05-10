<script setup lang="ts">
// Importa os tipos necessários do Vue
import { defineProps, defineEmits } from 'vue'

// Define as props do componente
defineProps<{
  show: boolean          // Controla a visibilidade do modal
  imageSrc: string       // URL da imagem
  imageAlt: string       // Texto alternativo da imagem
}>()

// Define os eventos que o componente pode emitir
defineEmits<{
  (e: 'close'): void    // Evento para fechar o modal
}>()
</script>

<template>
  <!-- Wrapper do modal com transição de fade -->
  <Transition name="fade">
    <!-- Overlay do modal -->
    <div v-if="show" class="modal-overlay" @click="$emit('close')">
      <!-- Conteúdo do modal -->
      <div class="modal-content" @click.stop>
        <!-- Imagem -->
        <img :src="imageSrc" :alt="imageAlt" class="modal-image">
        <!-- Botão de fechar -->
        <button class="close-button" @click="$emit('close')">×</button>
      </div>
    </div>
  </Transition>
</template>

<style scoped>
/* Overlay do modal */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.75);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 2rem;
}

/* Container do conteúdo do modal */
.modal-content {
  position: relative;
  max-width: 90vw;
  max-height: 90vh;
  background: white;
  border-radius: 8px;
  padding: 1rem;
}

/* Estilo da imagem dentro do modal */
.modal-image {
  max-width: 100%;
  max-height: calc(90vh - 2rem);
  object-fit: contain;
  display: block;
  margin: 0 auto;
}

/* Botão de fechar */
.close-button {
  position: absolute;
  top: -1.5rem;
  right: -1.5rem;
  width: 2.5rem;
  height: 2.5rem;
  border-radius: 50%;
  background: white;
  border: none;
  color: #333;
  font-size: 1.5rem;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
}

/* Animações de transição */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>
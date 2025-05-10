<script setup lang="ts">
// Importa os tipos necessários do Vue
import { defineProps, defineEmits } from 'vue'

// Define as props do componente
defineProps<{
  modelValue: string      // Valor do input (v-model)
  placeholder?: string    // Texto placeholder opcional
}>()

// Define os eventos que o componente pode emitir
defineEmits<{
  (e: 'update:modelValue', value: string): void  // Evento para atualizar o v-model
}>()
</script>

<template>
  <!-- Container principal da barra de busca -->
  <div class="search-container">
    <!-- Input de busca com two-way binding -->
    <input
      type="text"
      :value="modelValue"
      @input="$emit('update:modelValue', ($event.target as HTMLInputElement).value)"
      :placeholder="placeholder"
      class="search-input"
    >
    <!-- Ícone de busca -->
    <span class="search-icon">🔍</span>
  </div>
</template>

<style scoped>
/* Container da barra de busca */
.search-container {
  position: relative;
  max-width: 600px;
  margin: 0 auto;
}

/* Estilo do input de busca */
.search-input {
  width: 100%;
  padding: 1rem 1rem 1rem 3rem;
  border: 2px solid #e2e2e2;
  border-radius: 8px;
  font-size: 1rem;
  transition: all 0.3s ease;
  background: #f8f9fa;
}

/* Estado de foco do input */
.search-input:focus {
  outline: none;
  border-color: #ff5722;
  background: white;
  box-shadow: 0 0 0 3px rgba(255, 87, 34, 0.1);
}

/* Estilo do placeholder */
.search-input::placeholder {
  color: #adb5bd;
}

/* Ícone de busca */
.search-icon {
  position: absolute;
  left: 1rem;
  top: 50%;
  transform: translateY(-50%);
  color: #adb5bd;
  font-size: 1.2rem;
  pointer-events: none;
}
</style>
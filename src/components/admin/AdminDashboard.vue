<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { supabase } from '../../lib/supabase'
import RichTextEditor from '../RichTextEditor.vue'
import type { Category, Tutorial } from '../../lib/supabase'

const categories = ref<Category[]>([])
const tutorials = ref<Tutorial[]>([])
const selectedCategory = ref('')
const newTutorial = ref({
  code: '',
  title: '',
  content: '',
  category_id: ''
})
const isLoading = ref(false)
const error = ref('')

onMounted(async () => {
  try {
    const { data: categoriesData, error: categoriesError } = await supabase
      .from('categories')
      .select('*')
      .order('order_position')

    if (categoriesError) throw categoriesError
    categories.value = categoriesData

    const { data: tutorialsData, error: tutorialsError } = await supabase
      .from('tutorials')
      .select('*')
      .order('order_position')

    if (tutorialsError) throw tutorialsError
    tutorials.value = tutorialsData
  } catch (err) {
    error.value = 'Error loading data'
    console.error(err)
  }
})

const handleSubmit = async () => {
  if (!newTutorial.value.code || !newTutorial.value.title || !newTutorial.value.category_id) {
    error.value = 'Please fill in all required fields'
    return
  }

  isLoading.value = true
  error.value = ''

  try {
    const { error: insertError } = await supabase
      .from('tutorials')
      .insert([{
        code: newTutorial.value.code,
        title: newTutorial.value.title,
        content: newTutorial.value.content,
        category_id: newTutorial.value.category_id
      }])

    if (insertError) throw insertError

    // Reset form
    newTutorial.value = {
      code: '',
      title: '',
      content: '',
      category_id: ''
    }

    // Refresh tutorials list
    const { data: tutorialsData, error: tutorialsError } = await supabase
      .from('tutorials')
      .select('*')
      .order('order_position')

    if (tutorialsError) throw tutorialsError
    tutorials.value = tutorialsData
  } catch (err) {
    error.value = 'Error creating tutorial'
    console.error(err)
  } finally {
    isLoading.value = false
  }
}
</script>

<template>
  <div class="admin-dashboard">
    <div class="container mx-auto px-4 py-8">
      <h1 class="text-2xl font-bold mb-8">Admin Dashboard</h1>

      <div class="bg-white rounded-lg shadow p-6 mb-8">
        <h2 class="text-xl font-semibold mb-4">Create New Tutorial</h2>
        
        <form @submit.prevent="handleSubmit" class="space-y-6">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">
              Category
            </label>
            <select
              v-model="newTutorial.category_id"
              class="w-full px-3 py-2 border border-gray-300 rounded-md"
              required
            >
              <option value="">Select a category</option>
              <option
                v-for="category in categories"
                :key="category.id"
                :value="category.id"
              >
                {{ category.title }}
              </option>
            </select>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">
              Code
            </label>
            <input
              type="text"
              v-model="newTutorial.code"
              class="w-full px-3 py-2 border border-gray-300 rounded-md"
              required
            >
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">
              Title
            </label>
            <input
              type="text"
              v-model="newTutorial.title"
              class="w-full px-3 py-2 border border-gray-300 rounded-md"
              required
            >
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">
              Content
            </label>
            <RichTextEditor
              v-model="newTutorial.content"
              class="min-h-[300px]"
            />
          </div>

          <div v-if="error" class="text-red-500 text-sm">
            {{ error }}
          </div>

          <button
            type="submit"
            :disabled="isLoading"
            class="w-full bg-primary text-white py-2 px-4 rounded-md hover:bg-primary/90 disabled:opacity-50"
          >
            {{ isLoading ? 'Creating...' : 'Create Tutorial' }}
          </button>
        </form>
      </div>

      <div class="bg-white rounded-lg shadow p-6">
        <h2 class="text-xl font-semibold mb-4">Existing Tutorials</h2>
        <div class="space-y-4">
          <div v-for="tutorial in tutorials" :key="tutorial.id" class="border-b pb-4">
            <h3 class="font-medium">{{ tutorial.title }}</h3>
            <p class="text-sm text-gray-500">Code: {{ tutorial.code }}</p>
            <p class="text-sm text-gray-500">
              Category: {{ categories.find(c => c.id === tutorial.category_id)?.title }}
            </p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.admin-dashboard {
  min-height: 100vh;
  background-color: #f3f4f6;
}
</style>
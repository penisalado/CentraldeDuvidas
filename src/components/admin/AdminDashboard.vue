<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../../lib/supabase'
import type { Category, Tutorial, QuickLink } from '../../lib/supabase'
import { Icon } from '@iconify/vue'
import { marked } from 'marked'
import hljs from 'highlight.js'
import 'highlight.js/styles/github.css'
import { useEditor, EditorContent, BubbleMenu, FloatingMenu } from '@tiptap/vue-3'
import StarterKit from '@tiptap/starter-kit'
import Image from '@tiptap/extension-image'
import Link from '@tiptap/extension-link'
import TextAlign from '@tiptap/extension-text-align'
import Underline from '@tiptap/extension-underline'
import Strike from '@tiptap/extension-strike'
import Highlight from '@tiptap/extension-highlight'
import Typography from '@tiptap/extension-typography'
import { Color } from '@tiptap/extension-color'
import TextStyle from '@tiptap/extension-text-style'
import FontFamily from '@tiptap/extension-font-family'
import { Extension } from '@tiptap/core'

// Create a custom extension for font size
const FontSize = Extension.create({
  name: 'fontSize',

  addGlobalAttributes() {
    return [
      {
        types: ['textStyle'],
        attributes: {
          fontSize: {
            default: null,
            parseHTML: element => element.style.fontSize,
            renderHTML: attributes => {
              if (!attributes.fontSize) {
                return {}
              }
              return {
                style: `font-size: ${attributes.fontSize}`
              }
            }
          }
        }
      }
    ]
  },

  addCommands() {
    return {
      setFontSize: (fontSize: string) => ({ chain }) => {
        return chain()
          .setMark('textStyle', { fontSize })
          .run()
      }
    }
  }
})

marked.setOptions({
  highlight: (code, lang) => {
    if (lang && hljs.getLanguage(lang)) {
      return hljs.highlight(code, { language: lang }).value
    }
    return code
  }
})

const router = useRouter()
const categories = ref<Category[]>([])
const tutorials = ref<Tutorial[]>([])
const quickLinks = ref<QuickLink[]>([])
const selectedCategory = ref<string | null>(null)
const selectedTutorial = ref<Tutorial | null>(null)
const isLoading = ref(false)
const error = ref('')
const previewMode = ref(false)
const editMode = ref(false)
const showAllTutorials = ref(false)
const TUTORIALS_PREVIEW_COUNT = 5
const editingCategory = ref<Category | null>(null)
const editingQuickLink = ref<QuickLink | null>(null)
const selectedQuickLinkImage = ref<File | null>(null)
const activeTab = ref<'categories' | 'quickLinks'>('categories')
const showResetAllVotesModal = ref(false)
const tutorialToReset = ref<Tutorial | null>(null)
const isResetting = ref(false)
const tutorialVotes = ref<Record<string, { count: number, average: number }>>({})

const visibleTutorials = computed(() => {
  if (showAllTutorials.value) {
    return tutorials.value
  }
  return tutorials.value.slice(0, TUTORIALS_PREVIEW_COUNT)
})

const hasMoreTutorials = computed(() => {
  return tutorials.value.length > TUTORIALS_PREVIEW_COUNT
})

const editor = useEditor({
  extensions: [
    StarterKit,
    Image.configure({
      inline: true,
      allowBase64: true,
      HTMLAttributes: {
        class: 'editor-image',
      },
    }),
    Link.configure({
      openOnClick: false,
    }),
    TextAlign.configure({
      types: ['heading', 'paragraph'],
    }),
    Underline,
    Strike,
    Highlight,
    Typography,
    TextStyle,
    Color,
    FontFamily.configure({
      types: ['textStyle'],
    }),
    FontSize
  ],
  content: '',
  onUpdate: ({ editor }) => {
    if (editMode.value && selectedTutorial.value) {
      selectedTutorial.value.content = editor.getHTML()
    } else {
      newTutorial.value.content = editor.getHTML()
    }
  }
})

const newCategory = ref({
  title: '',
  description: '',
  icon: '',
  icon_color: '#ff5722'
})

const newQuickLink = ref({
  title: '',
  description: '',
  redirect_url: '',
  image_url: '',
  order_position: 0
})

const newTutorial = ref({
  code: '',
  title: '',
  content: '',
  category_id: '',
  parent_id: null as string | null
})

const selectedFile = ref<File | null>(null)

onMounted(async () => {
  await loadCategories()
  await loadQuickLinks()
  await loadTutorialVotes()
})

async function loadCategories() {
  const { data, error: err } = await supabase
    .from('categories')
    .select('*')
    .order('order_position')

  if (err) {
    error.value = 'Erro ao carregar categorias'
    return
  }

  categories.value = data
}

async function loadQuickLinks() {
  const { data, error: err } = await supabase
    .from('quick_links')
    .select('*')
    .order('order_position')

  if (err) {
    error.value = 'Erro ao carregar links rápidos'
    return
  }

  quickLinks.value = data
}

const loadTutorialVotes = async () => {
  const { data, error } = await supabase
    .from('tutorial_ratings')
    .select('tutorial_id, rating')

  if (error) {
    console.error('Error loading tutorial votes:', error)
    return
  }

  const votesByTutorial: Record<string, { count: number, sum: number }> = {}
  
  data.forEach(vote => {
    if (!votesByTutorial[vote.tutorial_id]) {
      votesByTutorial[vote.tutorial_id] = { count: 0, sum: 0 }
    }
    votesByTutorial[vote.tutorial_id].count++
    votesByTutorial[vote.tutorial_id].sum += vote.rating
  })

  Object.entries(votesByTutorial).forEach(([tutorialId, stats]) => {
    tutorialVotes.value[tutorialId] = {
      count: stats.count,
      average: Math.round((stats.sum / stats.count) * 10) / 10
    }
  })
}

const getTutorialVotes = (tutorialId: string) => {
  return tutorialVotes.value[tutorialId]?.count || 0
}

const getTutorialAverageRating = (tutorialId: string) => {
  return tutorialVotes.value[tutorialId]?.average || 0
}

const showResetVotesModal = (tutorial: Tutorial) => {
  tutorialToReset.value = tutorial
}

const resetTutorialVotes = async () => {
  if (!tutorialToReset.value) return

  isResetting.value = true
  const tutorialId = tutorialToReset.value.id

  try {
    const { data: { session } } = await supabase.auth.getSession()
    if (!session?.user) throw new Error('No authenticated user')

    await supabase
      .from('tutorial_vote_resets')
      .insert([{
        tutorial_id: tutorialId,
        admin_id: session.user.id
      }])

    // Update local state
    tutorialVotes.value[tutorialId] = { count: 0, average: 0 }
    
    // Reload data after reset
    await loadTutorialVotes()
    
    tutorialToReset.value = null
  } catch (err) {
    console.error('Error resetting tutorial votes:', err)
    error.value = 'Erro ao resetar votos'
  } finally {
    isResetting.value = false
  }
}

const resetAllVotes = async () => {
  isResetting.value = true

  try {
    const { data: { session } } = await supabase.auth.getSession()
    if (!session?.user) throw new Error('No authenticated user')

    // Record reset action for all tutorials
    await supabase
      .from('tutorial_vote_resets')
      .insert([{
      tutorial_id: null,
      admin_id: session.user.id
    }])

    // Update local state
    tutorialVotes.value = {}
    
    // Reload data after reset
    await loadTutorialVotes()
    
    showResetAllVotesModal.value = false
  } catch (err) {
    console.error('Error resetting all votes:', err)
    error.value = 'Erro ao resetar todos os votos'
  } finally {
    isResetting.value = false
  }
}

async function deleteCategory(categoryId: string) {
  if (!confirm('Tem certeza que deseja excluir esta categoria? Todos os tutoriais associados serão excluídos permanentemente.')) {
    return
  }

  isLoading.value = true
  error.value = ''

  try {
    const { error: deleteError } = await supabase
      .from('categories')
      .delete()
      .eq('id', categoryId)

    if (deleteError) throw deleteError

    categories.value = categories.value.filter(c => c.id !== categoryId)
    if (selectedCategory.value === categoryId) {
      selectedCategory.value = null
      tutorials.value = []
    }
  } catch (err) {
    error.value = 'Erro ao excluir categoria'
  } finally {
    isLoading.value = false
  }
}

async function deleteQuickLink(linkId: string) {
  if (!confirm('Tem certeza que deseja excluir este link rápido?')) {
    return
  }

  isLoading.value = true
  error.value = ''

  try {
    const { error: deleteError } = await supabase
      .from('quick_links')
      .delete()
      .eq('id', linkId)

    if (deleteError) throw deleteError

    quickLinks.value = quickLinks.value.filter(link => link.id !== linkId)
  } catch (err) {
    error.value = 'Erro ao excluir link rápido'
  } finally {
    isLoading.value = false
  }
}

function startEditingCategory(category: Category) {
  editingCategory.value = { ...category }
}

function startEditingQuickLink(link: QuickLink) {
  editingQuickLink.value = { ...link }
}

async function saveEditedCategory() {
  if (!editingCategory.value) return

  isLoading.value = true
  error.value = ''

  try {
    const { error: updateError } = await supabase
      .from('categories')
      .update({
        title: editingCategory.value.title,
        description: editingCategory.value.description,
        icon: editingCategory.value.icon,
        icon_color: editingCategory.value.icon_color
      })
      .eq('id', editingCategory.value.id)

    if (updateError) throw updateError

    const index = categories.value.findIndex(c => c.id === editingCategory.value?.id)
    if (index !== -1) {
      categories.value[index] = { ...editingCategory.value }
    }

    editingCategory.value = null
  } catch (err) {
    error.value = 'Erro ao atualizar categoria'
  } finally {
    isLoading.value = false
  }
}

async function saveEditedQuickLink() {
  if (!editingQuickLink.value) return

  isLoading.value = true
  error.value = ''

  try {
    let imageUrl = editingQuickLink.value.image_url

    if (selectedQuickLinkImage.value) {
      const filename = `${Date.now()}-${selectedQuickLinkImage.value.name}`
      const { data: uploadData, error: uploadError } = await supabase.storage
        .from('quick-links')
        .upload(filename, selectedQuickLinkImage.value)

      if (uploadError) throw uploadError

      const { data: { publicUrl } } = supabase.storage
        .from('quick-links')
        .getPublicUrl(filename)

      imageUrl = publicUrl
    }

    const { error: updateError } = await supabase
      .from('quick_links')
      .update({
        title: editingQuickLink.value.title,
        description: editingQuickLink.value.description,
        redirect_url: editingQuickLink.value.redirect_url,
        image_url: imageUrl
      })
      .eq('id', editingQuickLink.value.id)

    if (updateError) throw updateError

    const index = quickLinks.value.findIndex(link => link.id === editingQuickLink.value?.id)
    if (index !== -1) {
      quickLinks.value[index] = { 
        ...editingQuickLink.value,
        image_url: imageUrl
      }
    }

    editingQuickLink.value = null
    selectedQuickLinkImage.value = null
  } catch (err) {
    error.value = 'Erro ao atualizar link rápido'
  } finally {
    isLoading.value = false
  }
}

const loadTutorials = async (categoryId: string) => {
  const { data, error: err } = await supabase
    .from('tutorials')
    .select('*')
    .eq('category_id', categoryId)
    .order('order_position')

  if (err) {
    error.value = 'Erro ao carregar tutoriais'
    return
  }

  tutorials.value = data
}

async function handleFileUpload(event: Event) {
  const input = event.target as HTMLInputElement
  if (input.files && input.files[0]) {
    selectedFile.value = input.files[0]
    
    const filename = `${Date.now()}-${selectedFile.value.name}`
    
    const { data, error: uploadError } = await supabase.storage
      .from('tutorial-assets')
      .upload(filename, selectedFile.value)

    if (uploadError) {
      error.value = 'Erro ao fazer upload do arquivo'
      return
    }

    const { data: { publicUrl } } = supabase.storage
      .from('tutorial-assets')
      .getPublicUrl(filename)

    editor.value?.chain().focus().setImage({ 
      src: publicUrl,
      alt: selectedFile.value.name
    }).run()
  }
}

async function handleQuickLinkImageUpload(event: Event) {
  const input = event.target as HTMLInputElement
  if (input.files && input.files[0]) {
    selectedQuickLinkImage.value = input.files[0]
  }
}

async function saveTutorial() {
  isLoading.value = true
  error.value = ''

  try {
    const tutorialData = {
      ...newTutorial.value,
      category_id: selectedCategory.value,
      order_position: tutorials.value.length + 1
    }

    const { data, error: saveError } = await supabase
      .from('tutorials')
      .insert([tutorialData])
      .select()
      .single()

    if (saveError) throw saveError

    tutorials.value.push(data)
    resetTutorialForm()
  } catch (err) {
    error.value = 'Erro ao salvar tutorial'
  } finally {
    isLoading.value = false
  }
}

async function saveQuickLink() {
  isLoading.value = true
  error.value = ''

  try {
    let imageUrl = ''

    if (selectedQuickLinkImage.value) {
      const filename = `${Date.now()}-${selectedQuickLinkImage.value.name}`
      const { data: uploadData, error: uploadError } = await supabase.storage
        .from('quick-links')
        .upload(filename, selectedQuickLinkImage.value)

      if (uploadError) throw uploadError

      const { data: { publicUrl } } = supabase.storage
        .from('quick-links')
        .getPublicUrl(filename)

      imageUrl = publicUrl
    }

    const quickLinkData = {
      ...newQuickLink.value,
      image_url: imageUrl,
      order_position: quickLinks.value.length + 1
    }

    const { data, error: saveError } = await supabase
      .from('quick_links')
      .insert([quickLinkData])
      .select()
      .single()

    if (saveError) throw saveError

    quickLinks.value.push(data)
    resetQuickLinkForm()
  } catch (err) {
    error.value = 'Erro ao salvar link rápido'
  } finally {
    isLoading.value = false
  }
}

async function updateTutorial() {
  if (!selectedTutorial.value) return

  isLoading.value = true
  error.value = ''

  try {
    const { error: updateError } = await supabase
      .from('tutorials')
      .update({
        code: selectedTutorial.value.code,
        title: selectedTutorial.value.title,
        content: selectedTutorial.value.content
      })
      .eq('id', selectedTutorial.value.id)

    if (updateError) throw updateError

    const index = tutorials.value.findIndex(t => t.id === selectedTutorial.value?.id)
    if (index !== -1) {
      tutorials.value[index] = { ...selectedTutorial.value }
    }

    editMode.value = false
    selectedTutorial.value = null
    editor.value?.commands.setContent('')
  } catch (err) {
    error.value = 'Erro ao atualizar tutorial'
  } finally {
    isLoading.value = false
  }
}

async function editTutorial(tutorial: Tutorial) {
  editMode.value = true
  selectedTutorial.value = { ...tutorial }
  editor.value?.commands.setContent(tutorial.content)
}

async function saveCategory() {
  isLoading.value = true
  error.value = ''

  try {
    const { data, error: saveError } = await supabase
      .from('categories')
      .insert([newCategory.value])
      .select()
      .single()

    if (saveError) throw saveError

    categories.value.push(data)
    resetCategoryForm()
  } catch (err) {
    error.value = 'Erro ao salvar categoria'
  } finally {
    isLoading.value = false
  }
}

function resetTutorialForm() {
  newTutorial.value = {
    code: '',
    title: '',
    content: '',
    category_id: selectedCategory.value || '',
    parent_id: null
  }
  editor.value?.commands.setContent('')
  selectedFile.value = null
  editMode.value = false
  selectedTutorial.value = null
}

function resetCategoryForm() {
  newCategory.value = {
    title: '',
    description: '',
    icon: '',
    icon_color: '#ff5722'
  }
}

function resetQuickLinkForm() {
  newQuickLink.value = {
    title: '',
    description: '',
    redirect_url: '',
    image_url: '',
    order_position: 0
  }
  selectedQuickLinkImage.value = null
}

async function handleLogout() {
  await supabase.auth.signOut()
  router.push('/admin')
}

const renderedContent = computed(() => {
  if (editMode.value && selectedTutorial.value) {
    return marked(selectedTutorial.value.content)
  }
  return marked(newTutorial.value.content)
})

const fontSizes = [
  '8px', '9px', '10px', '11px', '12px', '14px', '16px', '18px', '20px', '24px', '30px', '36px', '48px', '60px', '72px'
]

const fontFamilies = [
  'Arial',
  'Arial Black',
  'Courier New',
  'Georgia',
  'Helvetica',
  'Impact',
  'Tahoma',
  'Times New Roman',
  'Verdana'
]

const moveTutorialUp = async (tutorial: Tutorial) => {
  const currentIndex = tutorials.value.findIndex(t => t.id === tutorial.id)
  if (currentIndex > 0) {
    const prevTutorial = tutorials.value[currentIndex - 1]
    
    await supabase
      .from('tutorials')
      .update({ order_position: prevTutorial.order_position })
      .eq('id', tutorial.id)

    await supabase
      .from('tutorials')
      .update({ order_position: tutorial.order_position })
      .eq('id', prevTutorial.id)

    await loadTutorials(selectedCategory.value!)
  }
}

const moveTutorialDown = async (tutorial: Tutorial) => {
  const currentIndex = tutorials.value.findIndex(t => t.id === tutorial.id)
  if (currentIndex < tutorials.value.length - 1) {
    const nextTutorial = tutorials.value[currentIndex + 1]
    
    await supabase
      .from('tutorials')
      .update({ order_position: nextTutorial.order_position })
      .eq('id', tutorial.id)

    await supabase
      .from('tutorials')
      .update({ order_position: tutorial.order_position })
      .eq('id', nextTutorial.id)

    await loadTutorials(selectedCategory.value!)
  }
}

const moveQuickLinkUp = async (link: QuickLink) => {
  const currentIndex = quickLinks.value.findIndex(l => l.id === link.id)
  if (currentIndex > 0) {
    const prevLink = quickLinks.value[currentIndex - 1]
    
    await supabase
      .from('quick_links')
      .update({ order_position: prevLink.order_position })
      .eq('id', link.id)

    await supabase
      .from('quick_links')
      .update({ order_position: link.order_position })
      .eq('id', prevLink.id)

    await loadQuickLinks()
  }
}

const moveQuickLinkDown = async (link: QuickLink) => {
  const currentIndex = quickLinks.value.findIndex(l => l.id === link.id)
  if (currentIndex < quickLinks.value.length - 1) {
    const nextLink = quickLinks.value[currentIndex + 1]
    
    await supabase
      .from('quick_links')
      .update({ order_position: nextLink.order_position })
      .eq('id', link.id)

    await supabase
      .from('quick_links')
      .update({ order_position: link.order_position })
      .eq('id', nextLink.id)

    await loadQuickLinks()
  }
}

const moveCategoryUp = async (category: Category) => {
  const currentIndex = categories.value.findIndex(c => c.id === category.id)
  if (currentIndex > 0) {
    const prevCategory = categories.value[currentIndex - 1]
    
    // Store current positions
    const currentPosition = category.order_position
    const prevPosition = prevCategory.order_position
    
    try {
      // Update positions in database
      await supabase
        .from('categories')
        .update({ order_position: prevPosition })
        .eq('id', category.id)

      await supabase
        .from('categories')
        .update({ order_position: currentPosition })
        .eq('id', prevCategory.id)

      // Update local state to reflect the change
      categories.value[currentIndex].order_position = prevPosition
      categories.value[currentIndex - 1].order_position = currentPosition
      
      // Reorder the array
      const temp = categories.value[currentIndex]
      categories.value[currentIndex] = categories.value[currentIndex - 1]
      categories.value[currentIndex - 1] = temp
    } catch (err) {
      console.error('Error updating category positions:', err)
      error.value = 'Erro ao reordenar categorias'
      
      // Reload categories to ensure consistency
      await loadCategories()
    }
  }
}

const moveCategoryDown = async (category: Category) => {
  const currentIndex = categories.value.findIndex(c => c.id === category.id)
  if (currentIndex < categories.value.length - 1) {
    const nextCategory = categories.value[currentIndex + 1]
    
    // Store current positions
    const currentPosition = category.order_position
    const nextPosition = nextCategory.order_position
    
    try {
      // Update positions in database
      await supabase
        .from('categories')
        .update({ order_position: nextPosition })
        .eq('id', category.id)

      await supabase
        .from('categories')
        .update({ order_position: currentPosition })
        .eq('id', nextCategory.id)

      // Update local state to reflect the change
      categories.value[currentIndex].order_position = nextPosition
      categories.value[currentIndex + 1].order_position = currentPosition
      
      // Reorder the array
      const temp = categories.value[currentIndex]
      categories.value[currentIndex] = categories.value[currentIndex + 1]
      categories.value[currentIndex + 1] = temp
    } catch (err) {
      console.error('Error updating category positions:', err)
      error.value = 'Erro ao reordenar categorias'
      
      // Reload categories to ensure consistency
      await loadCategories()
    }
  }
}

const deleteTutorial = async (tutorialId: string) => {
  if (confirm('Tem certeza que deseja excluir este tutorial?')) {
    const { error: err } = await supabase
      .from('tutorials')
      .delete()
      .eq('id', tutorialId)

    if (err) {
      error.value = 'Erro ao excluir tutorial'
      return
    }

    tutorials.value = tutorials.value.filter(t => t.id !== tutorialId)
  }
}

const editorActions = {
  'Negrito': {
    icon: 'material-symbols:format-bold',
    action: () => editor.value?.chain().focus().toggleBold().run()
  },
  'Itálico': {
    icon: 'material-symbols:format-italic',
    action: () => editor.value?.chain().focus().toggleItalic().run()
  },
  'Sublinhado': {
    icon: 'material-symbols:format-underlined-rounded',
    action: () => editor.value?.chain().focus().toggleUnderline().run()
  },
  'Riscado': {
    icon: 'material-symbols:format-strikethrough',
    action: () => editor.value?.chain().focus().toggleStrike().run()
  },
  'Título 1': {
    icon: 'material-symbols:format-h1',
    action: () => editor.value?.chain().focus().toggleHeading({ level: 1 }).run()
  },
  'Título 2': {
    icon: 'material-symbols:format-h2',
    action: () => editor.value?.chain().focus().toggleHeading({ level: 2 }).run()
  },
  'Lista com marcadores': {
    icon: 'material-symbols:format-list-bulleted',
    action: () => editor.value?.chain().focus().toggleBulletList().run()
  },
  'Lista numerada': {
    icon: 'material-symbols:format-list-numbered',
    action: () => editor.value?.chain().focus().toggleOrderedList().run()
  },
  'Alinhar à esquerda': {
    icon: 'material-symbols:format-align-left',
    action: () => editor.value?.chain().focus().setTextAlign('left').run()
  },
  'Centralizar': {
    icon: 'material-symbols:format-align-center',
    action: () => editor.value?.chain().focus().setTextAlign('center').run()
  },
  'Alinhar à direita': {
    icon: 'material-symbols:format-align-right',
    action: () => editor.value?.chain().focus().setTextAlign('right').run()
  },
  'Justificar': {
    icon: 'material-symbols:format-align-justify',
    action: () => editor.value?.chain().focus().setTextAlign('justify').run()
  },
  'Destacar': {
    icon: 'material-symbols:ink-highlighter',
    action: () => editor.value?.chain().focus().toggleHighlight().run()
  },
  'Código': {
    icon: 'material-symbols:code',
    action: () => editor.value?.chain().focus().toggleCode().run()
  },
  'Link': {
    icon: 'material-symbols:link',
    action: () => {
      const url = window.prompt('URL:')
      if (url) {
        editor.value?.chain().focus().setLink({ href: url }).run()
      }
    }
  },
  'Imagem': {
    icon: 'material-symbols:image',
    action: () => {
      const fileInput = document.createElement('input')
      fileInput.type = 'file'
      fileInput.accept = 'image/*'
      fileInput.onchange = (e) => handleFileUpload(e)
      fileInput.click()
    }
  }
}

watch(selectedCategory, async (newValue) => {
  if (newValue) {
    await loadTutorials(newValue)
  }
})
</script>

<template>
  <div class="min-h-screen bg-gray-50">
    <header class="bg-white shadow">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 flex justify-between items-center">
        <h1 class="text-2xl font-bold text-gray-900">Dashboard Administrativo</h1>
        <button 
          @click="handleLogout"
          class="px-4 py-2 bg-red-500 text-white rounded-lg hover:bg-red-600 transition-colors"
        >
          Sair
        </button>
      </div>
    </header>

    <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <!-- Tab Navigation -->
      <div class="mb-6 flex gap-4">
        <button
          @click="activeTab = 'categories'"
          :class="[
            'px-4 py-2 rounded-lg transition-colors',
            activeTab === 'categories'
              ? 'bg-primary text-white'
              : 'bg-white text-gray-700 hover:bg-gray-100'
          ]"
        >
          Categorias
        </button>
        <button
          @click="activeTab = 'quickLinks'"
          :class="[
            'px-4 py-2 rounded-lg transition-colors',
            activeTab === 'quickLinks'
              ? 'bg-primary text-white'
              : 'bg-white text-gray-700 hover:bg-gray-100'
          ]"
        >
          Links Rápidos
        </button>
      </div>

      <!-- Categories Tab -->
      <div v-if="activeTab === 'categories'" class="grid grid-cols-12 gap-8">
        <div class="col-span-3 bg-white rounded-lg shadow p-6">
          <div class="mb-6">
            <h2 class="text-lg font-semibold mb-4">Categorias</h2>
            <ul class="space-y-2">
              <li 
                v-for="category in categories" 
                :key="category.id"
                class="relative"
              >
                <div 
                  v-if="editingCategory?.id === category.id"
                  class="p-3 bg-gray-50 rounded-lg"
                >
                  <input
                    v-model="editingCategory.title"
                    class="w-full px-2 py-1 mb-2 border rounded"
                    placeholder="Título"
                  />
                  <input
                    v-model="editingCategory.description"
                    class="w-full px-2 py-1 mb-2 border rounded"
                    placeholder="Descrição"
                  />
                  <input
                    v-model="editingCategory.icon"
                    class="w-full px-2 py-1 mb-2 border rounded"
                    placeholder="Ícone"
                  />
                  <input
                    v-model="editingCategory.icon_color"
                    type="color"
                    class="w-full h-8 mb-2"
                  />
                  <div class="flex gap-2">
                    <button
                      @click="saveEditedCategory"
                      class="flex-1 px-2 py-1 bg-green-500 text-white rounded hover:bg-green-600"
                    >
                      Salvar
                    </button>
                    <button
                      @click="editingCategory = null"
                      class="flex-1 px-2 py-1 bg-gray-500 text-white rounded hover:bg-gray-600"
                    >
                      Cancelar
                    </button>
                  </div>
                </div>
                <div
                  v-else
                  @click="selectedCategory = category.id"
                  :class="[
                    'p-3 rounded-lg cursor-pointer transition-colors group',
                    selectedCategory === category.id 
                      ? 'bg-primary text-white' 
                      : 'hover:bg-gray-100'
                  ]"
                >
                  <div class="flex items-center justify-between">
                    <div class="flex items-center">
                      <Icon 
                        :icon="category.icon" 
                        class="mr-2" 
                        :style="{ color: category.icon_color }"
                      />
                      {{ category.title }}
                    </div>
                    <div class="opacity-0 group-hover:opacity-100 transition-opacity flex gap-2">
                      <button
                        @click.stop="moveCategoryUp(category)"
                        class="p-1 hover:bg-gray-200 rounded"
                        :disabled="categories.indexOf(category) === 0"
                        title="Mover para cima"
                      >
                        <Icon icon="material-symbols:arrow-upward" />
                      </button>
                      <button
                        @click.stop="moveCategoryDown(category)"
                        class="p-1 hover:bg-gray-200 rounded"
                        :disabled="categories.indexOf(category) === categories.length - 1"
                        title="Mover para baixo"
                      >
                        <Icon icon="material-symbols:arrow-downward" />
                      </button>
                      <button
                        @click.stop="startEditingCategory(category)"
                        class="p-1 hover:bg-gray-200 rounded"
                        title="Editar categoria"
                      >
                        <Icon icon="material-symbols:edit" />
                      </button>
                      <button
                        @click.stop="deleteCategory(category.id)"
                        class="p-1 hover:bg-gray-200 rounded text-red-500"
                        title="Excluir categoria"
                      >
                        <Icon icon="material-symbols:delete" />
                      </button>
                    </div>
                  </div>
                </div>
              </li>
            </ul>
          </div>

          <div>
            <h3 class="text-sm font-medium mb-3">Nova Categoria</h3>
            <form @submit.prevent="saveCategory" class="space-y-4">
              <div>
                <input
                  v-model="newCategory.title"
                  placeholder="Título"
                  class="w-full px-3 py-2 border rounded-lg"
                  required
                />
              </div>
              <div>
                <input
                  v-model="newCategory.description"
                  placeholder="Descrição"
                  class="w-full px-3 py-2 border rounded-lg"
                />
              </div>
              <div class="relative">
                <div class="flex items-center gap-2">
                  <input
                    v-model="newCategory.icon"
                    placeholder="Ícone (ex: material-symbols:folder)"
                    class="w-full px-3 py-2 border rounded-lg"
                  />
                  <a 
                    href="https://icon-sets.iconify.design"
                    target="_blank"
                    rel="noopener noreferrer"
                    class="text-primary hover:text-primary/80 transition-colors p-2 rounded-lg hover:bg-gray-100"
                    title="Procurar ícones"
                  >
                    <Icon icon="material-symbols:search" class="text-xl" />
                  </a>
                </div>
              </div>
              <div>
                <label class="block text-sm font-medium mb-1">Cor da categoria</label>
                <input
                  v-model="newCategory.icon_color"
                  type="color"
                  class="w-full h-10 px-3 py-2 border rounded-lg"
                />
              </div>
              <button
                type="submit"
                :disabled="isLoading"
                class="w-full bg-primary text-white py-2 rounded-lg hover:bg-primary/90 transition-colors"
              >
                {{ isLoading ? 'Salvando...' : 'Adicionar Categoria' }}
              </button>
            </form>
          </div>
        </div>

        <div class="col-span-9 space-y-6">
          <div v-if="error" class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded">
            {{ error }}
          </div>

          <div v-if="selectedCategory" class="bg-white rounded-lg shadow">
            <div class="px-6 py-4 border-b flex justify-between items-center">
              <h3 class="text-lg font-semibold">Tutoriais Existentes</h3>
              <div class="flex items-center gap-4">
                <button 
                  v-if="hasMoreTutorials"
                  @click="showAllTutorials = !showAllTutorials"
                  class="text-sm text-primary hover:text-primary/80 transition-colors"
                >
                  {{ showAllTutorials ? 'Mostrar menos' : 'Mostrar todos' }}
                </button>
                <button
                  @click="showResetAllVotesModal = true"
                  class="px-4 py-2 bg-red-500 text-white rounded-lg hover:bg-red-600 transition-colors"
                >
                  Resetar Todos os Votos
                </button>
              </div>
            </div>
            <div class="tutorials-list-container" :class="{ 'expanded': showAllTutorials }">
              <ul class="divide-y">
                <li 
                  v-for="tutorial in visibleTutorials" 
                  :key="tutorial.id"
                  class="px-6 py-4 hover:bg-gray-50 transition-colors"
                >
                  <div class="flex justify-between items-center">
                    <div class="flex-1">
                      <span class="font-mono text-primary">{{ tutorial.code }}</span>
                      <h4 class="font-medium">{{ tutorial.title }}</h4>
                      <div class="mt-2 text-sm text-gray-600">
                        <span>{{ getTutorialVotes(tutorial.id) }} votos</span>
                        <span class="mx-2">•</span>
                        <span>Média: {{ getTutorialAverageRating(tutorial.id) }}</span>
                      </div>
                    </div>
                    <div class="flex items-center gap-2">
                      <button
                        @click="moveTutorialUp(tutorial)"
                        class="p-2 hover:bg-gray-200 rounded"
                        :disabled="tutorials.indexOf(tutorial) === 0"
                        title="Mover para cima"
                      >
                        <Icon icon="material-symbols:arrow-upward" />
                      </button>
                      <button
                        @click="moveTutorialDown(tutorial)"
                        class="p-2 hover:bg-gray-200 rounded"
                        :disabled="tutorials.indexOf(tutorial) === tutorials.length - 1"
                        title="Mover para baixo"
                      >
                        <Icon icon="material-symbols:arrow-downward" />
                      </button>
                      <button
                        @click="editTutorial(tutorial)"
                        class="px-3 py-1 bg-gray-100 rounded hover:bg-gray-200 transition-colors"
                        title="Editar tutorial"
                      >
                        Editar
                      </button>
                      <button
                        @click="showResetVotesModal(tutorial)"
                        class="px-3 py-1 bg-red-100 text-red-600 rounded hover:bg-red-200 transition-colors"
                        title="Resetar votos"
                      >
                        Resetar Votos
                      </button>
                      <button
                        @click="deleteTutorial(tutorial.id)"
                        class="px-3 py-1 bg-red-100 text-red-600 rounded hover:bg-red-200 transition-colors"
                        title="Excluir tutorial"
                      >
                        Excluir
                      </button>
                    </div>
                  </div>
                </li>
              </ul>
            </div>
          </div>

          <div v-if="selectedCategory" class="bg-white rounded-lg shadow p-6">
            <div class="flex justify-between items-center mb-6">
              <h2 class="text-lg font-semibold">
                {{ editMode ? 'Editar Tutorial' : 'Novo Tutorial' }}
              </h2>
              <div class="flex gap-2">
                <button
                  v-if="editMode"
                  @click="resetTutorialForm"
                  class="px-4 py-2 bg-gray-100 rounded-lg hover:bg-gray-200 transition-colors"
                >
                  Cancelar
                </button>
                <button
                  @click="previewMode = !previewMode"
                  class="px-4 py-2 bg-gray-100 rounded-lg hover:bg-gray-200 transition-colors"
                >
                  {{ previewMode ? 'Editar' : 'Preview' }}
                </button>
              </div>
            </div>

            <div v-if="!previewMode" class="space-y-4">
              <div class="grid grid-cols-2 gap-4">
                <div>
                  <label class="block text-sm font-medium mb-1">Código</label>
                  <input
                    v-if="editMode"
                    v-model="selectedTutorial.code"
                    placeholder="Ex: A.W 1.1.1"
                    class="w-full px-3 py-2 border rounded-lg"
                    required
                  />
                  <input
                    v-else
                    v-model="newTutorial.code"
                    placeholder="Ex: A.W 1.1.1"
                    class="w-full px-3 py-2 border rounded-lg"
                    required
                  />
                </div>
                <div>
                  <label class="block text-sm font-medium mb-1">Título</label>
                  <input
                    v-if="editMode"
                    v-model="selectedTutorial.title"
                    placeholder="Título do tutorial"
                    class="w-full px-3 py-2 border rounded-lg"
                    required
                  />
                  <input
                    v-else
                    v-model="newTutorial.title"
                    placeholder="Título do tutorial"
                    class="w-full px-3 py-2 border rounded-lg"
                    required
                  />
                </div>
              </div>

              <div>
                <label class="block text-sm font-medium mb-1">Conteúdo</label>
                
                <div class="border rounded-t-lg p-2 bg-gray-50 flex flex-wrap gap-2">
                  <select 
                    class="px-2 py-1 border rounded"
                    @change="(e) => editor?.chain().focus().setFontFamily((e.target as HTMLSelectElement).value).run()"
                  >
                    <option value="">Fonte</option>
                    <option v-for="font in fontFamilies" :key="font" :value="font">
                      {{ font }}
                    </option>
                  </select>

                  <select 
                    class="px-2 py-1 border rounded"
                    @change="(e) => editor?.chain().focus().setFontSize((e.target as HTMLSelectElement).value).run()"
                  >
                    <option value="">Tamanho</option>
                    <option v-for="size in fontSizes" :key="size" :value="size">
                      {{ size }}
                    </option>
                  </select>

                  <input
                    type="color"
                    @input="(e) => editor?.chain().focus().setColor((e.target as HTMLInputElement).value).run()"
                    class="w-8 h-8 p-0 border rounded cursor-pointer"
                  />

                  <button
                    v-for="(action, name) in editorActions"
                    :key="name"
                    @click.prevent="action.action"
                    class="p-2 hover:bg-gray-200 rounded tooltip"
                    :title="name"
                  >
                    <Icon :icon="action.icon" />
                  </button>
                </div>

                <editor-content 
                  :editor="editor" 
                  class="border rounded-b-lg p-4 min-h-[300px] prose max-w-none"
                />

                <bubble-menu
                  v-if="editor"
                  :editor="editor"
                  :tippy-options="{ duration: 100 }"
                  class="bubble-menu"
                >
                  <button
                    v-for="(action, name) in editorActions"
                    :key="name"
                    @click.prevent="action.action"
                    class="p-1 hover:bg-gray-200 rounded"
                    :title="name"
                  >
                    <Icon :icon="action.icon" class="w-4 h-4" />
                  </button>
                </bubble-menu>
              </div>

              <button
                @click="editMode ? updateTutorial() : saveTutorial()"
                :disabled="isLoading"
                class="w-full bg-primary text-white py-3 rounded-lg hover:bg-primary/90 transition-colors"
              >
                {{ isLoading ? 'Salvando...' : (editMode ? 'Atualizar Tutorial' : 'Salvar Tutorial') }}
              </button>
            </div>

            <div v-else class="prose max-w-none">
              <div v-html="renderedContent"></div>
            </div>
          </div>
        </div>
      </div>

      <!-- Quick Links Tab -->
      <div v-if="activeTab === 'quickLinks'" class="space-y-6">
        <div v-if="error" class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded">
          {{ error }}
        </div>

        <!-- Quick Links List -->
        <div class="bg-white rounded-lg shadow">
          <div class="px-6 py-4 border-b">
            <h3 class="text-lg font-semibold">Links Rápidos</h3>
          </div>
          <ul class="divide-y">
            <li 
              v-for="link in quickLinks" 
              :key="link.id"
              class="px-6 py-4"
            >
              <div 
                v-if="editingQuickLink?.id === link.id"
                class="space-y-4"
              >
                <div>
                  <label class="block text-sm font-medium mb-1">Título</label>
                  <input
                    v-model="editingQuickLink.title"
                    class="w-full px-3 py-2 border rounded-lg"
                    placeholder="Título do link"
                  />
                </div>
                <div>
                  <label class="block text-sm font-medium mb-1">Descrição</label>
                  <input
                    v-model="editingQuickLink.description"
                    class="w-full px-3 py-2 border rounded-lg"
                    placeholder="Descrição do link"
                  />
                </div>
                <div>
                  <label class="block text-sm font-medium mb-1">URL de Redirecionamento</label>
                  <input
                    v-model="editingQuickLink.redirect_url"
                    class="w-full px-3 py-2 border rounded-lg"
                    placeholder="https://exemplo.com"
                  />
                </div>
                <div>
                  <label class="block text-sm font-medium mb-1">Imagem</label>
                  <input
                    type="file"
                    accept="image/*"
                    @change="handleQuickLinkImageUpload"
                    class="w-full px-3 py-2 border rounded-lg"
                  />
                  <img 
                    v-if="editingQuickLink.image_url" 
                    :src="editingQuickLink.image_url" 
                    alt="Preview"
                    class="mt-2 h-32 object-cover rounded"
                  />
                </div>
                <div class="flex gap-2">
                  <button
                    @click="saveEditedQuickLink"
                    class="flex-1 px-4 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600 transition-colors"
                  >
                    Salvar
                  </button>
                  <button
                    @click="editingQuickLink = null"
                    class="flex-1 px-4 py-2 bg-gray-500 text-white rounded-lg hover:bg-gray-600 transition-colors"
                  >
                    Cancelar
                  </button>
                </div>
              </div>
              <div v-else class="flex items-center justify-between">
                <div class="flex items-center gap-4">
                  <img 
                    v-if="link.image_url"
                    :src="link.image_url"
                    :alt="link.title"
                    class="w-16 h-16 object-cover rounded"
                  />
                  <div>
                    <h4 class="font-medium">{{ link.title }}</h4>
                    <p class="text-sm text-gray-600">{{ link.description }}</p>
                    <a 
                      :href="link.redirect_url"
                      target="_blank"
                      rel="noopener noreferrer"
                      class="text-sm text-primary hover:text-primary/80 transition-colors"
                    >
                      {{ link.redirect_url }}
                    </a>
                  </div>
                </div>
                <div class="flex items-center gap-2">
                  <button
                    @click="moveQuickLinkUp(link)"
                    class="p-2 hover:bg-gray-200 rounded"
                    :disabled="quickLinks.indexOf(link) === 0"
                    title="Mover para cima"
                  >
                    <Icon icon="material-symbols:arrow-upward" />
                  </button>
                  <button
                    @click="moveQuickLinkDown(link)"
                    class="p-2 hover:bg-gray-200 rounded"
                    :disabled="quickLinks.indexOf(link) === quickLinks.length - 1"
                    title="Mover para baixo"
                  >
                    <Icon icon="material-symbols:arrow-downward" />
                  </button>
                  <button
                    @click="startEditingQuickLink(link)"
                    class="px-3 py-1 bg-gray-100 rounded hover:bg-gray-200 transition-colors"
                    title="Editar link"
                  >
                    Editar
                  </button>
                  <button
                    @click="deleteQuickLink(link.id)"
                    class="px-3 py-1 bg-red-100 text-red-600 rounded hover:bg-red-200 transition-colors"
                    title="Excluir link"
                  >
                    Excluir
                  </button>
                </div>
              </div>
            </li>
          </ul>
        </div>

        <!-- New Quick Link Form -->
        <div class="bg-white rounded-lg shadow p-6">
          <h3 class="text-lg font-semibold mb-4">Novo Link Rápido</h3>
          <form @submit.prevent="saveQuickLink" class="space-y-4">
            <div>
              <label class="block text-sm font-medium mb-1">Título</label>
              <input
                v-model="newQuickLink.title"
                placeholder="Título do link"
                class="w-full px-3 py-2 border rounded-lg"
                required
              />
            </div>
            <div>
              <label class="block text-sm font-medium mb-1">Descrição</label>
              <input
                v-model="newQuickLink.description"
                placeholder="Descrição do link"
                class="w-full px-3 py-2 border rounded-lg"
              />
            </div>
            <div>
              <label class="block text-sm font-medium mb-1">URL de Redirecionamento</label>
              <input
                v-model="newQuickLink.redirect_url"
                placeholder="https://exemplo.com"
                class="w-full px-3 py-2 border rounded-lg"
                required
              />
            </div>
            <div>
              <label class="block text-sm font-medium mb-1">Imagem</label>
              <input
                type="file"
                accept="image/*"
                @change="handleQuickLinkImageUpload"
                class="w-full px-3 py-2 border rounded-lg"
              />
            </div>
            <button
              type="submit"
              :disabled="isLoading"
              class="w-full bg-primary text-white py-2 rounded-lg hover:bg-primary/90 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {{ isLoading ? 'Salvando...' : 'Adicionar Link Rápido' }}
            </button>
          </form>
        </div>
      </div>
    </main>

    <!-- Reset Votes Modal -->
    <div 
      v-if="tutorialToReset"
      class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4"
    >
      <div class="bg-white rounded-lg p-6 max-w-md w-full">
        <h3 class="text-lg font-semibold mb-4">Resetar Votos</h3>
        <p class="text-gray-600 mb-6">
          Tem certeza que deseja resetar todos os votos para o tutorial "{{ tutorialToReset.title }}"?
          Esta ação não pode ser desfeita.
        </p>
        <div class="flex justify-end gap-4">
          <button
            @click="tutorialToReset = null"
            class="px-4 py-2 bg-gray-100 rounded-lg hover:bg-gray-200 transition-colors"
          >
            Cancelar
          </button>
          <button
            @click="resetTutorialVotes"
            :disabled="isResetting"
            class="px-4 py-2 bg-red-500 text-white rounded-lg hover:bg-red-600 transition-colors"
          >
            {{ isResetting ? 'Resetando...' : 'Confirmar Reset' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Reset All Votes Modal -->
    <div 
      v-if="showResetAllVotesModal"
      class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4"
    >
      <div class="bg-white rounded-lg p-6 max-w-md w-full">
        <h3 class="text-lg font-semibold mb-4">Resetar Todos os Votos</h3>
        <p class="text-gray-600 mb-6">
          Tem certeza que deseja resetar todos os votos de todos os tutoriais?
          Esta ação não pode ser desfeita.
        </p>
        <div class="flex justify-end gap-4">
          <button
            @click="showResetAllVotesModal = false"
            class="px-4 py-2 bg-gray-100 rounded-lg hover:bg-gray-200 transition-colors"
          >
            Cancelar
          </button>
          <button
            @click="resetAllVotes"
            :disabled="isResetting"
            class="px-4 py-2 bg-red-500 text-white rounded-lg hover:bg-red-600 transition-colors"
          >
            {{ isResetting ? 'Resetando...' : 'Confirmar Reset' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style>
.bubble-menu {
  display: flex;
  background-color: #ffffff;
  padding: 0.25rem;
  border-radius: 0.5rem;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  gap: 0.25rem;
}

.tutorials-list-container {
  max-height: 400px;
  overflow-y: auto;
}

.tutorials-list-container.expanded {
  max-height: none;
}

.editor-image {
  max-width: 100%;
  height: auto;
  display: block;
  margin: 1rem 0;
}

.tooltip {
  position: relative;
}

.tooltip:hover::after {
  content: attr(title);
  position: absolute;
  bottom: 100%;
  left: 50%;
  transform: translateX(-50%);
  background-color: rgba(0, 0, 0, 0.8);
  color: white;
  padding: 0.25rem 0.5rem;
  border-radius: 0.25rem;
  font-size: 0.75rem;
  white-space: nowrap;
  z-index: 10;
}
</style>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../../lib/supabase'
import type { Category, Tutorial } from '../../lib/supabase'
import RichTextEditor from '../RichTextEditor.vue'

const editingTutorial = ref<Tutorial>({
  id: '',
  code: '',
  title: '',
  content: '',
  category_id: '',
  parent_id: null,
  order_position: 0,
  created_at: '',
  updated_at: ''
})

// ... rest of the AdminDashboard.vue code ...

<template>
  <!-- ... other template code ... -->
  
  <!-- Only render the editor when editingTutorial is properly initialized -->
  <RichTextEditor
    v-if="editingTutorial"
    v-model="editingTutorial.content"
    :tutorial-id="editingTutorial.id"
    @error="handleError"
  />
  
  <!-- ... rest of the template ... -->
</template>

<!-- ... styles ... -->
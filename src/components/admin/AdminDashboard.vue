import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../../lib/supabase'
import type { Category, Tutorial } from '../../lib/supabase'
import RichTextEditor from '../RichTextEditor.vue'

// ... rest of the AdminDashboard.vue code ...

<template>
  <!-- ... other template code ... -->
  
  <!-- Replace the existing editor with the new component -->
  <RichTextEditor
    v-model="editingTutorial.content"
    :tutorial-id="editingTutorial.id"
    @error="handleError"
  />
  
  <!-- ... rest of the template ... -->
</template>

<!-- ... styles ... -->
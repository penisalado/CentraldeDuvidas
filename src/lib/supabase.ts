import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

// Validate environment variables
if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing Supabase environment variables. Please check your .env file.')
}

// Create the Supabase client with additional options for better reliability
export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
  },
  global: {
    headers: {
      'X-Client-Info': 'age-wiki',
    },
  },
})

export type Tutorial = {
  id: string
  code: string
  title: string
  content: string
  category_id: string
  parent_id: string | null
  order_position: number
  created_at: string
  updated_at: string
}

export type Category = {
  id: string
  title: string
  description: string
  icon: string
  icon_color: string
  order_position: number
  created_at: string
  updated_at: string
}

export type QuickLink = {
  id: string
  title: string
  description: string
  image_url: string
  redirect_url: string
  order_position: number
  created_at: string
  updated_at: string
}

// Bucket para armazenamento de arquivos
const STORAGE_URL = `${supabaseUrl}/storage/v1/object/public/tutorial-assets`

export async function uploadFile(file: File, path: string) {
  const { data, error } = await supabase.storage
    .from('tutorial-assets')
    .upload(path, file)

  if (error) throw error

  return `${STORAGE_URL}/${path}`
}
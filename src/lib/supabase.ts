import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

export const supabase = createClient(supabaseUrl, supabaseAnonKey)

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

export type TutorialImage = {
  id: string
  tutorial_id: string
  url: string
  filename: string
  created_at: string
}

// Bucket for storing tutorial images
const STORAGE_URL = `${supabaseUrl}/storage/v1/object/public/tutorial-assets`

export async function uploadTutorialImage(file: File): Promise<string> {
  const filename = `${Date.now()}-${file.name}`
  const { data, error } = await supabase.storage
    .from('tutorial-assets')
    .upload(filename, file)

  if (error) throw error

  // Get public URL
  const { data: { publicUrl } } = supabase.storage
    .from('tutorial-assets')
    .getPublicUrl(filename)

  return publicUrl
}

export async function saveTutorialImage(tutorialId: string, url: string, filename: string) {
  const { data, error } = await supabase
    .from('tutorial_images')
    .insert([{ tutorial_id: tutorialId, url, filename }])

  if (error) throw error
  return data
}
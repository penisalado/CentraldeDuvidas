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

// Bucket para armazenamento de arquivos
const BUCKET_NAME = 'tutorial-assets'

export async function uploadFile(file: File, path: string): Promise<string> {
  try {
    // Check if bucket exists
    const { data: buckets, error: bucketsError } = await supabase
      .storage
      .listBuckets()

    if (bucketsError) throw bucketsError

    const bucketExists = buckets.some(bucket => bucket.name === BUCKET_NAME)
    if (!bucketExists) {
      throw new Error(`Bucket ${BUCKET_NAME} not found. Please ensure it exists in your Supabase project.`)
    }

    // Upload file
    const { data, error } = await supabase.storage
      .from(BUCKET_NAME)
      .upload(path, file)

    if (error) throw error

    // Get public URL
    const { data: { publicUrl }, error: urlError } = await supabase.storage
      .from(BUCKET_NAME)
      .getPublicUrl(path)

    if (urlError) throw urlError

    return publicUrl
  } catch (error) {
    console.error('Error uploading file:', error)
    throw error
  }
}
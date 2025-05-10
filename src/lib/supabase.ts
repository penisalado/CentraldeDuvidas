// Importa o cliente do Supabase
import { createClient } from '@supabase/supabase-js'

// Configuração das variáveis de ambiente do Supabase
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

// Cria e exporta o cliente do Supabase
export const supabase = createClient(supabaseUrl, supabaseAnonKey)

// Interface que define a estrutura de um tutorial
export type Tutorial = {
  id: string                // ID único do tutorial
  code: string             // Código de referência do tutorial
  title: string            // Título do tutorial
  content: string          // Conteúdo em markdown do tutorial
  category_id: string      // ID da categoria do tutorial
  parent_id: string | null // ID do tutorial pai (para subtutoriais)
  order_position: number   // Posição de ordenação
  created_at: string       // Data de criação
  updated_at: string       // Data de última atualização
}

// Interface que define a estrutura de uma categoria
export type Category = {
  id: string           // ID único da categoria
  title: string        // Título da categoria
  description: string  // Descrição da categoria
  icon: string         // Ícone da categoria
  icon_color: string   // Cor do ícone
  order_position: number // Posição de ordenação
  created_at: string    // Data de criação
  updated_at: string    // Data de última atualização
}

// Interface que define a estrutura de um link rápido
export type QuickLink = {
  id: string           // ID único do link
  title: string        // Título do link
  description: string  // Descrição do link
  image_url: string    // URL da imagem do link
  redirect_url: string // URL de redirecionamento
  order_position: number // Posição de ordenação
  created_at: string    // Data de criação
  updated_at: string    // Data de última atualização
}

// URL base para acessar arquivos no bucket de armazenamento
const STORAGE_URL = `${supabaseUrl}/storage/v1/object/public/tutorial-assets`

// Sistema de logs
export const logError = async (error: any, context: string) => {
  console.error(`Error in ${context}:`, error)
  
  try {
    const { error: logError } = await supabase
      .from('error_logs')
      .insert([
        {
          error_message: error.message || String(error),
          error_stack: error.stack,
          context,
          metadata: {
            timestamp: new Date().toISOString(),
            userAgent: navigator.userAgent,
            url: window.location.href
          }
        }
      ])

    if (logError) {
      console.error('Failed to log error:', logError)
    }
  } catch (logError) {
    console.error('Failed to log error:', logError)
  }
}

// Função para fazer upload de arquivos
export async function uploadFile(file: File, path: string) {
  try {
    // Faz o upload do arquivo para o bucket tutorial-assets
    const { data, error } = await supabase.storage
      .from('tutorial-assets')
      .upload(path, file, {
        cacheControl: '3600',
        upsert: false
      })

    // Se houver erro, lança a exceção
    if (error) {
      await logError(error, 'uploadFile')
      throw error
    }

    // Retorna a URL pública do arquivo
    return `${STORAGE_URL}/${path}`
  } catch (error) {
    await logError(error, 'uploadFile')
    throw error
  }
}
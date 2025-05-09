/*
  # Schema inicial para o sistema de tutoriais

  1. Novas Tabelas
    - categories: Categorias principais dos tutoriais
    - tutorials: Tutoriais e subtutoriais
    - assets: Arquivos de mídia (imagens, vídeos)
    
  2. Segurança
    - RLS habilitado em todas as tabelas
    - Políticas para acesso autenticado
*/

-- Criar tabela de categorias
CREATE TABLE IF NOT EXISTS categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  icon text,
  icon_color text,
  order_position integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Criar tabela de tutoriais
CREATE TABLE IF NOT EXISTS tutorials (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL,
  title text NOT NULL,
  content text,
  category_id uuid REFERENCES categories(id) ON DELETE CASCADE,
  parent_id uuid REFERENCES tutorials(id) ON DELETE CASCADE,
  order_position integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Criar tabela de assets
CREATE TABLE IF NOT EXISTS assets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tutorial_id uuid REFERENCES tutorials(id) ON DELETE CASCADE,
  filename text NOT NULL,
  file_type text NOT NULL,
  file_size integer,
  url text NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Habilitar RLS
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE tutorials ENABLE ROW LEVEL SECURITY;
ALTER TABLE assets ENABLE ROW LEVEL SECURITY;

-- Políticas para categorias
CREATE POLICY "Permitir leitura pública de categorias"
  ON categories FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Permitir todas as operações para usuários autenticados em categorias"
  ON categories FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Políticas para tutoriais
CREATE POLICY "Permitir leitura pública de tutoriais"
  ON tutorials FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Permitir todas as operações para usuários autenticados em tutoriais"
  ON tutorials FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Políticas para assets
CREATE POLICY "Permitir leitura pública de assets"
  ON assets FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Permitir todas as operações para usuários autenticados em assets"
  ON assets FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Triggers para atualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_categories_updated_at
  BEFORE UPDATE ON categories
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tutorials_updated_at
  BEFORE UPDATE ON tutorials
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
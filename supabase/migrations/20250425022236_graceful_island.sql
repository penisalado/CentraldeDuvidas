/*
  # Restore original tutorials and categories

  1. Changes
    - Clear existing data
    - Restore original categories (SAC/Suporte, Retenção)
    - Restore original tutorials with proper UUID references
    
  2. Content Structure
    - SAC/Suporte category with subcategories
      - Atendimento Geral
      - Suporte Técnico
    - Retenção category with subcategories
      - Negociação
*/

-- Limpar dados existentes
DELETE FROM tutorials;
DELETE FROM categories;

-- Inserir categorias originais com UUIDs fixos
INSERT INTO categories (id, title, description, icon, icon_color, order_position) VALUES
  ('d7897fef-7f1c-4d3a-9ad3-8f689a3c7cb4', 'SAC/Suporte', 'Procedimentos e tutoriais para atendimento ao cliente e suporte técnico', 'material-symbols:support-agent', '#2196F3', 1),
  ('b5e89f12-2d76-4e26-8b49-d8e1a3f6c3e2', 'Retenção', 'Guias e procedimentos para negociação e retenção de clientes', 'material-symbols:handshake-rounded', '#4CAF50', 2);

-- Inserir tutoriais
INSERT INTO tutorials (code, title, content, category_id, parent_id, order_position) VALUES
  -- SAC/Suporte - Atendimento Geral
  ('A.W 1.1.1', 'Segunda via de boleto', '# ENVIO DE 2° VIA DE BOLETO

## 1° Passo

O envio de 2° via é feito pela tela de atendimento (mesma tela para abrir solicitação). Na aba "Financeiro" selecione "2° via de faturas". Após isso, selecione a fatura a ser enviada. Caso o envio seja pelo Blip (em PDF) selecione o ícone da impressora. Para o envio pelo e-mail ou SMS, selecione o ícone da carta.', 'd7897fef-7f1c-4d3a-9ad3-8f689a3c7cb4', NULL, 1),
  
  ('A.W 1.1.2', 'Alteração de Vencimento', '# Alteração de Data de Vencimento

## Procedimento

1. Verificar se o cliente está adimplente
2. Confirmar nova data desejada
3. Atualizar no sistema
4. Informar que a alteração ocorre em até 2 faturas', 'd7897fef-7f1c-4d3a-9ad3-8f689a3c7cb4', NULL, 2),

  -- SAC/Suporte - Suporte Técnico
  ('A.W 1.2.1', 'Configuração de WiFi', '# Configuração de WiFi

## Passos para configuração

1. Acessar interface do roteador
2. Alterar nome da rede e senha
3. Configurar canal automático
4. Ativar WPA2 para segurança', 'd7897fef-7f1c-4d3a-9ad3-8f689a3c7cb4', NULL, 3),

  -- Retenção - Negociação
  ('A.W 2.1.1', 'Desconto Fidelidade', '# Desconto Fidelidade

## Critérios

1. Cliente há mais de 12 meses
2. Sem pendências financeiras
3. Desconto máximo de 15%
4. Fidelidade de 12 meses', 'b5e89f12-2d76-4e26-8b49-d8e1a3f6c3e2', NULL, 1);
/*
  # Restore all original tutorials and categories

  1. Changes
    - Clear existing data
    - Restore all original categories with proper UUID format
    - Restore all original tutorials with proper references
*/

-- Limpar dados existentes
DELETE FROM tutorials;
DELETE FROM categories;

-- Inserir todas as categorias originais com UUIDs válidos
INSERT INTO categories (id, title, description, icon, icon_color, order_position) VALUES
  ('d7897fef-7f1c-4d3a-9ad3-8f689a3c7cb4', 'SAC/Suporte', 'Procedimentos e tutoriais para atendimento ao cliente e suporte técnico', 'material-symbols:support-agent', '#2196F3', 1),
  ('b5e89f12-2d76-4e26-8b49-d8e1a3f6c3e2', 'Retenção', 'Guias e procedimentos para negociação e retenção de clientes', 'material-symbols:handshake-rounded', '#4CAF50', 2),
  ('c4567def-8901-4abc-def1-23456789abcd', 'Auditoria', 'Procedimentos e diretrizes para auditoria de atendimentos', 'material-symbols:fact-check', '#9C27B0', 3),
  ('e7890123-4def-5678-9abc-def012345678', 'Qualidade', 'Padrões e métricas de qualidade no atendimento', 'material-symbols:verified', '#3F51B5', 4),
  ('f9012345-6789-0abc-def1-234567890000', 'Treinamento', 'Materiais e guias para treinamento de equipe', 'material-symbols:school', '#FF9800', 5);

-- Inserir todos os tutoriais
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
4. Fidelidade de 12 meses', 'b5e89f12-2d76-4e26-8b49-d8e1a3f6c3e2', NULL, 1),

  -- Auditoria
  ('A.W 3.1.1', 'Auditoria de Atendimento', '# Auditoria de Atendimento

## Critérios de Avaliação

1. Cordialidade no atendimento
2. Resolução efetiva da demanda
3. Tempo de resposta adequado
4. Registro correto das informações
5. Seguimento dos procedimentos padrão', 'c4567def-8901-4abc-def1-23456789abcd', NULL, 1),

  -- Qualidade
  ('A.W 4.1.1', 'Padrões de Qualidade', '# Padrões de Qualidade no Atendimento

## Diretrizes Principais

1. Tempo médio de atendimento (TMA)
2. Satisfação do cliente (CSAT)
3. Taxa de resolução no primeiro contato
4. Qualidade das informações registradas
5. Aderência aos scripts e procedimentos', 'e7890123-4def-5678-9abc-def012345678', NULL, 1),

  -- Treinamento
  ('A.W 5.1.1', 'Onboarding de Novos Colaboradores', '# Onboarding de Novos Colaboradores

## Etapas do Treinamento

1. Apresentação da empresa e valores
2. Treinamento em sistemas
3. Procedimentos operacionais
4. Práticas de atendimento
5. Avaliação de conhecimentos
6. Acompanhamento inicial', 'f9012345-6789-0abc-def1-234567890000', NULL, 1);
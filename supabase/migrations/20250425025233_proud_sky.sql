/*
  # Update tutorial content with images

  1. Changes
    - Update the "Segunda via de boleto" tutorial with images and detailed steps
*/

-- Update the tutorial content
UPDATE tutorials 
SET content = '# ENVIO DE 2° VIA DE BOLETO

## Acessando o Sistema

1. Acesse a tela de atendimento principal
2. Localize a aba "Financeiro" no menu superior
3. Clique em "2° via de faturas"

![Tela de Atendimento](/print1.png)

## Selecionando a Fatura

1. Na lista de faturas, localize a que o cliente deseja
2. Você pode filtrar por:
   - Data de vencimento
   - Valor
   - Status de pagamento

![Lista de Faturas](/print2.png)

## Enviando a Fatura

### Envio por Blip (PDF)
1. Clique no ícone da impressora ao lado da fatura
2. Confirme o envio no pop-up que aparece
3. Aguarde a confirmação de envio

![Envio por Blip](/print4.png)

### Envio por Email/SMS
1. Clique no ícone da carta
2. Selecione o método de envio (Email ou SMS)
3. Confirme o contato do cliente
4. Clique em "Enviar"

![Envio por Email/SMS](/print5.png)

## Confirmação

Após o envio, você verá uma notificação de sucesso no topo da tela. Confirme com o cliente se ele recebeu corretamente.

![Confirmação de Envio](/print6.png)

## Observações Importantes

- Certifique-se de que os dados de contato do cliente estão atualizados
- Em caso de falha no envio, tente um método alternativo
- Registre o envio no histórico de atendimento'
WHERE code = 'A.W 1.1.1';
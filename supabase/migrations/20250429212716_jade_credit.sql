/*
  # Add quick links data
  
  1. Changes
    - Insert initial quick links (AMS, TIP Brasil, Teste de Velocidade, Guacamole, Zeus)
*/

INSERT INTO quick_links (title, description, image_url, redirect_url, order_position) VALUES
  (
    'AMS',
    'Sistema de gerenciamento e monitoramento de assinantes',
    'https://images.pexels.com/photos/1181467/pexels-photo-1181467.jpeg',
    'https://ams.agetelecom.com.br',
    1
  ),
  (
    'TIP Brasil',
    'Portal de gerenciamento de serviços TIP',
    'https://images.pexels.com/photos/3183150/pexels-photo-3183150.jpeg',
    'https://tipbrasil.com.br',
    2
  ),
  (
    'Teste de Velocidade',
    'Ferramenta para medir a velocidade da conexão',
    'https://images.pexels.com/photos/159304/network-cable-ethernet-computer-159304.jpeg',
    'https://velocidade.agetelecom.com.br',
    3
  ),
  (
    'Guacamole',
    'Acesso remoto via navegador',
    'https://images.pexels.com/photos/1181244/pexels-photo-1181244.jpeg',
    'https://guacamole.agetelecom.com.br',
    4
  ),
  (
    'Zeus',
    'Sistema de gestão empresarial',
    'https://images.pexels.com/photos/265087/pexels-photo-265087.jpeg',
    'https://zeus.agetelecom.com.br',
    5
  );
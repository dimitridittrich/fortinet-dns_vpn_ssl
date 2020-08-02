# Projeto criado para automatizar a exclusão de registros DNS com IPs duplicados.

Projeto criado para manter os scripts de forma distribuida, versionada e economizar tempo de operação.
Os NGFW da Fortinet (Fortinet/Fortigate) não possuem lease time nos IPs fornecidos para a rede da VPN SSL, por esse motivo sempre que um host desconecta/conecta na VPN, é gerado um novo registro DNS com um novo IP e o registro antigo não é apagado. Dessa forma com o tempo haverá vários registros DNS de hosts diferentes com o mesmo IP.
Com este script é possível automatizar a limpeza desses registros, verificando o timestamp e mantendo somente o registro mais atualizado de cada IP.

## Pré-requisitos e observações para utilização deste projeto :exclamation:

Para pleno funcionamento deste projeto, você precisará:
- Criar uma task scheduler (ou um serviço) que roda o script de tempos em tempos (sugiro a cada 1 hora).

## Como Utilizar este projeto

**Na pasta "Scripts" há o Script principal:**<br />
1 - "FortiNet-DNS_VPN_SSL.ps1"
Este script faz todo o processo de conexão e pesquisa nos Switches e a interação com o Active Directory.<br />
[Para acessar esse script clique aqui](/scripts/FortiNet-DNS_VPN_SSL.ps1)
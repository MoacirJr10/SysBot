# SysBot — Manutenção e diagnóstico do Windows

[![Licença MIT](https://img.shields.io/badge/Licença-MIT-green.svg)](LICENSE)
![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-blue)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1-blue)

O SysBot é uma ferramenta gratuita e de código aberto para ajudar você a verificar, limpar e cuidar do seu computador Windows. Não é necessário saber programar.

## Como baixar e usar

### 1. Baixe o SysBot

- Clique em **[Baixar SysBot (ZIP)](https://github.com/MoacirJr10/SysBot/archive/refs/heads/master.zip)** para baixar a versão da branch principal.
- Ou acesse o [repositório oficial](https://github.com/MoacirJr10/SysBot), clique no botão verde **Code** (Código) e depois em **Download ZIP**.

### 2. Extraia os arquivos

1. Abra a pasta **Downloads** do Windows.
2. Clique com o botão direito sobre o arquivo ZIP baixado.
3. Selecione **Extrair Tudo...** e confirme.
4. Abra a pasta extraída. Não execute o programa diretamente dentro do ZIP.

### 3. Abra o programa

1. Localize o arquivo **run_admin.bat** (se as extensões estiverem ocultas, ele aparecerá como run_admin).
2. Clique duas vezes nele. O Windows solicitará autorização de administrador (UAC).
3. Confira se você baixou e revisou o programa de uma fonte confiável antes de aceitar a elevação.
4. Quando o menu abrir, digite a opção desejada e pressione **Enter**.

### 4. Por onde começar?

Para quem está usando pela primeira vez, escolha **[10] Central de Diagnóstico e Manutenção** no menu principal.

| Opção | O que acontece |
| --- | --- |
| **d** | Analisa o computador sem solicitar reparos ou alterações nas configurações. |
| **s** | Simula a limpeza e estima os arquivos que poderiam ser removidos, sem excluí-los. |
| **r** | Gera um relatório que pode ser aberto no navegador. |
| **a** | Executa uma rotina guiada de manutenção, com confirmação para limpeza e verificações opcionais. |
| **0** | Volta ao menu anterior ou fecha o programa no menu principal. |

Também é possível escolher **g** no menu principal para abrir o seletor gráfico opcional. Os resultados e confirmações continuam no terminal.

### Se o Windows bloquear o programa

O SysBot respeita a política de execução do PowerShell e as proteções do Windows. Se aparecer um aviso, não ignore automaticamente: confirme a origem, revise o código e consulte o administrador do computador, quando aplicável. Não desative o Microsoft Defender, SmartScreen, UAC ou políticas de segurança para executar o SysBot. Se você não puder validar a procedência ou não tiver autorização, não execute.

## Requisitos

- Windows 10 ou 11, com Windows PowerShell 5.1.
- Permissão de administrador.
- WinGet (Instalador de Aplicativos) e PSWindowsUpdate são opcionais. Sem eles, algumas operações não estão disponíveis.
- Conexão à internet somente para recursos que dependem dela, como atualizações e testes de rede.
- Compatibilidade com todas as edições e configurações do Windows ainda não foi validada em máquinas reais.

## O que o SysBot faz?

| Módulo | Recursos |
| --- | --- |
| Manutenção | Windows Update, WinGet, SFC, DISM, drivers e CHKDSK online em volumes NTFS |
| Hardware | CPU, GPU, RAM, armazenamento e programas instalados |
| Rede | IP/DNS, conectividade, tempo de resposta HTTP, portas TCP e conexões |
| Limpeza | Temporários antigos, miniaturas, atalhos recentes opcionais e logs antigos do próprio SysBot |
| Otimização | Otimização de discos pelo Windows, TRIM e desfragmentação quando a mídia é identificada |
| Relatórios | HTML local, inventários e diagnóstico de integridade |
| Segurança | Firewall, Microsoft Defender, antivírus registrados e inicialização |
| Desenvolvimento | Consulta e instalação de ferramentas via WinGet |
| Diagnóstico avançado | SMART e contadores de armazenamento, saúde estimada da bateria, eventos críticos dos últimos sete dias, amostras de CPU/RAM e diagnóstico integrado |
| Manutenção guiada | Relatório antes/depois, limpeza confirmada e verificações opcionais SFC/DISM sem solicitar reparos |
| Interface gráfica | Seletor visual opcional para as ferramentas de diagnóstico |

## Segurança e privacidade

- A simulação e o diagnóstico não solicitam instalações, reparos ou alterações de configuração; o SysBot mantém logs locais e grava relatórios quando solicitado.
- A limpeza solicita confirmação, preserva arquivos temporários modificados nos últimos dois dias, ignora pontos de reanálise e não remove diretórios recursivamente.
- Prefetch, logs do Windows, arquivos pessoais e configurações de segurança não são alvos da limpeza.
- A rotina guiada não cria tarefas agendadas, não força atualizações nem reinicia o computador.
- Dados SMART e capacidade da bateria dependem do hardware e do controlador. Dados ausentes e status Healthy não garantem ausência de defeitos.
- O teste HTTP mede tempo de resposta, não velocidade em Mbps.
- Pontos de restauração não substituem backups. Faça backup antes de realizar reparos.
- Nenhum dado de diagnóstico é enviado automaticamente pelo SysBot a um serviço externo. Atualizações e testes de rede podem acessar seus respectivos serviços.
- Não compartilhe relatórios ou logs sem revisar informações pessoais e técnicas.

## Onde estão os relatórios?

Pressione **Win + R**, cole um dos caminhos abaixo e pressione Enter:

- Relatórios HTML: `%LOCALAPPDATA%\SysBot\reports`
- Logs: `%LOCALAPPDATA%\SysBot\logs`

Alguns inventários TXT/CSV das opções antigas são salvos na Área de Trabalho. Abra os relatórios HTML com seu navegador.

## Contribuições

Sugestões, relatos de erros e contribuições são sempre bem-vindos!

Use [Issues](https://github.com/MoacirJr10/SysBot/issues) para propor melhorias ou reportar problemas. Para contribuir com código, crie uma branch em seu fork e abra um pull request. As mudanças devem passar por revisão e testes antes de entrar na versão principal. Não envie credenciais ou logs pessoais.

O GitHub Actions verifica a sintaxe PowerShell em um ambiente Windows. Os testes automatizados não substituem testes funcionais em uma máquina virtual ou computador de testes.

## Licença

O SysBot é distribuído sob a **[licença MIT](LICENSE)**. Você pode usar, estudar, modificar e redistribuir o código, inclusive comercialmente, mantendo o aviso de copyright e a licença nas cópias ou partes substanciais. O software é oferecido sem garantias.

## Créditos

Desenvolvido por **Moacir Pereira** — [MoacirJr10](https://github.com/MoacirJr10).

Obrigado por usar, testar e contribuir com o projeto!

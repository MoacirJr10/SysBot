# SysBot — Manutenção e diagnóstico do Windows

O SysBot é uma ferramenta de linha de comando escrita em PowerShell para manutenção, diagnóstico, limpeza controlada e auditoria básica do Windows.

## Requisitos

- Windows 10 ou 11 e Windows PowerShell 5.1 (powershell.exe).
- Permissões de administrador, concedidas pelo UAC.
- WinGet e PSWindowsUpdate são opcionais. Se ausentes, algumas funções não estarão disponíveis.
- Os testes automatizados não substituem testes em máquinas Windows reais. A compatibilidade com todas as edições e configurações ainda não foi validada.

## Como usar

1. Obtenha o código no [repositório oficial](https://github.com/MoacirJr10/SysBot).
2. Extraia todos os arquivos para uma pasta local e examine os scripts.
3. Execute `run_admin.bat` e aceite a elevação UAC somente se confiar no código.
4. Escolha uma opção no menu. Leia os avisos e confirme operações que alteram o sistema.

O inicializador respeita a política de execução do PowerShell. Se o Windows bloquear o arquivo, verifique sua procedência, a assinatura (quando disponível) e a política da organização. Não desative o Defender, SmartScreen, UAC ou políticas de segurança para executar o SysBot.

## Funcionalidades

| Módulo | Recursos |
| --- | --- |
| Manutenção | Windows Update, WinGet, SFC, DISM, drivers e CHKDSK online para NTFS |
| Hardware | CPU, GPU, RAM, armazenamento e programas instalados |
| Rede | IP/DNS, conectividade, resposta HTTP (não mede Mbps), portas TCP e conexões |
| Limpeza | Arquivos temporários antigos, miniaturas, atalhos recentes opcionais e logs antigos do próprio SysBot |
| Otimização | Otimização apropriada ao tipo de mídia pelo Windows; TRIM e desfragmentação específicos somente quando o disco é identificado |
| Relatórios | HTML, inventários e diagnóstico de integridade |
| Segurança | Perfis do firewall, Microsoft Defender, produtos registrados e inicialização |
| Desenvolvimento | Consulta e instalação de ferramentas por WinGet |

## Segurança e validações

- A limpeza solicita confirmação, atua somente sobre arquivos elegíveis no nível direto de pastas conhecidas e ignora pontos de reanálise. Prefetch e logs do Windows são preservados.
- Arquivos temporários modificados nos últimos dois dias são preservados. O tamanho informado corresponde aos arquivos removidos com sucesso, não necessariamente à variação física do espaço livre.
- A verificação online do disco não solicita CHKDSK /f ou /r nem reinício.
- Atualizações não solicitam reinício automático pelo SysBot; instaladores individuais e políticas do Windows podem ter comportamento próprio.
- Operações de rede podem interromper conexões; a renovação DHCP pede confirmação.
- O painel de status informa quando não consegue concluir uma consulta. Não indica que o computador esteja livre de vulnerabilidades.
- Pontos de restauração dependem da Proteção do Sistema e não substituem backups.
- Logs em `%LOCALAPPDATA%\SysBot\logs`. Relatórios podem conter informações pessoais e técnicas; revise antes de compartilhar.

## Contribuições

Sugestões e pull requests são bem-vindos. Revise mudanças e teste-as em uma máquina virtual Windows antes de incorporar à versão principal. Não envie credenciais, logs pessoais ou alterações que enfraqueçam as proteções do Windows.

## Créditos

Desenvolvido por **Moacir Pereira** — [MoacirJr10](https://github.com/MoacirJr10).

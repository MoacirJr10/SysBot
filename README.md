# SysBot - Sua Ferramenta de Otimizacao e Diagnostico para Windows

<pre>
   _____ __         __   ____        __
  / ___// /_  ___  / /_ / __ )____  / /_
  \__ \/ __ \/ _ \/ __// __  / __ \/ __/
 ___/ / / / /  __/ /_ / /_/ / /_/ / /_
/____/_/ /_/\___/\__//_____/\____/\__/
</pre>

SysBot e uma poderosa suite de ferramentas de linha de comando, escrita em PowerShell, projetada para ajudar usuarios e tecnicos a otimizar, diagnosticar, limpar e auditar sistemas operacionais Windows.

---

## Funcionalidades Principais

O SysBot e organizado em modulos, cada um com um proposito especifico:

- **Manutencao do Sistema:** Executa tarefas essenciais como instalacao de atualizacoes do Windows, verificacao de integridade de arquivos (SFC) e reparo da imagem do sistema (DISM).
- **Informacoes de Hardware:** Exibe um resumo detalhado dos seus componentes de hardware, incluindo CPU, GPU, Memoria RAM e status dos discos.
- **Diagnostico de Rede:** Oferece um conjunto de ferramentas para analisar a saude da sua conexao, testar conectividade, velocidade e configuracoes de rede.
- **Ferramentas de Limpeza:** Libera espaco em disco de forma segura, removendo arquivos temporarios, caches do sistema e outros dados desnecessarios.
- **Otimizacao Avancada:** Aplica otimizacoes de desempenho, como a desfragmentacao de HDDs, execucao de TRIM em SSDs e ajustes no plano de energia.
- **Relatorios e Diagnosticos:** Gera relatorios completos sobre o sistema (em HTML), exporta listas de programas e drivers, e cria dumps de diagnostico.
- **Auditoria de Seguranca:** Realiza uma verificacao basica de seguranca, analisando o status do Firewall, do Antivirus e listando programas que iniciam com o Windows.

## Como Usar

1.  Nao execute o `sysbot.ps1` diretamente.
2.  Clique com o **botao direito** no arquivo `run_admin.bat`.
3.  Selecione **"Executar como administrador"**.
4.  O menu principal do SysBot sera exibido, e voce podera navegar pelas opcoes.

## Customizacao (config.json)

O SysBot pode ser customizado atraves do arquivo `config.json`. Se este arquivo nao existir, ele sera criado automaticamente na primeira execucao.

As configuracoes padrao sao:

```json
{
  "daysForOldLogs": 30,
  "lowDiskSpaceThreshold": 15
}
```

- `daysForOldLogs`: Define a idade (em dias) a partir da qual os arquivos de log na pasta de limpeza serao considerados "antigos" e removidos.
- `lowDiskSpaceThreshold`: Define o percentual minimo de espaco livre em disco antes que o SysBot exiba um alerta de "ATENCAO NECESSARIA".

## Compatibilidade

- **Windows 10 e 11:** Compatibilidade total. O SysBot e otimizado para estes sistemas.
- **Windows 8.1:** Compatibilidade parcial. A maioria das funcoes essenciais funciona, mas recursos como `winget` e a verificacao de Antivirus podem nao operar.
- **Windows 7:** Compatibilidade limitada. Funcoes basicas (SFC, chkdsk, limpeza) funcionam, mas a maioria dos recursos modernos de diagnostico e seguranca nao sao suportados.

---

## Creditos

Este projeto foi desenvolvido por **MoacirJr10** como parte dos seus estudos em **Engenharia de Computacao**.

- **GitHub:** [MoacirJr10](https://github.com/MoacirJr10)

Sugestoes e contribuicoes sao sempre bem-vindas!

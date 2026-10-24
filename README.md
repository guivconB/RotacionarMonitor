# Rotacionar Monitor

Aplicativo simples para Windows que gira a orientação do monitor com um clique — sem instalar nada.

- **Janela com botões:** escolha o monitor e clique em Paisagem, Retrato, Paisagem invertida ou Retrato invertido.
- **Alternância rápida:** um atalho (ou **Ctrl+Alt+R**) alterna entre Paisagem e outra orientação escolhida, sem abrir janela.
- Funciona com vários monitores.
- A mudança fica salva, igual a mudar pelas Configurações do Windows.

## Requisitos

- Windows 10 ou 11
- Windows PowerShell 5.1 (já vem no Windows)

## Instalação

1. Baixe ou clone este repositório:
   ```
   git clone https://github.com/<seu-usuario>/RotacionarMonitor.git
   ```
2. Crie os atalhos na Área de Trabalho:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\CriarAtalhos.ps1
   ```
   Por padrão, os atalhos usam o **monitor 1** e alternam entre **Paisagem** e **Retrato invertido**.
   Para mudar, passe os parâmetros, por exemplo:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\CriarAtalhos.ps1 -Monitor 2 -OrientacaoB 1
   ```

## Uso

| Atalho | O que faz |
|---|---|
| **Rotacionar Monitor** | Abre a janela com todos os botões |
| **Alternar Orientacao** (Ctrl+Alt+R) | Alterna o monitor escolhido entre Paisagem e a orientação B |

Pela linha de comando:

```powershell
# Lista os monitores e a orientação atual de cada um
powershell -ExecutionPolicy Bypass -File .\RotacionarMonitor.ps1 -Listar

# Abre a janela
powershell -ExecutionPolicy Bypass -File .\RotacionarMonitor.ps1

# Alterna o monitor 1 entre Paisagem e Retrato invertido
powershell -ExecutionPolicy Bypass -File .\RotacionarMonitor.ps1 -Alternar -Monitor 1 -OrientacaoB 3
```

### Parâmetros

| Parâmetro | Descrição |
|---|---|
| `-Listar` | Mostra os monitores conectados e a orientação atual |
| `-Alternar` | Alterna a orientação sem abrir a janela |
| `-Monitor N` | Número do monitor na lista (`1`, `2`...). `0` = monitor principal. Padrão: `1` |
| `-OrientacaoB N` | Orientação usada na alternância: `1` Retrato, `2` Paisagem invertida, `3` Retrato invertido. Padrão: `3` |

## Se a tela ficar estranha

Abra a janela e clique em **Paisagem**, ou vá em **Configurações → Sistema → Tela → Orientação da tela**.

## Como funciona

O script carrega um pequeno trecho em C# que chama as funções da API do Windows
`EnumDisplayDevices`, `EnumDisplaySettings` e `ChangeDisplaySettingsEx` (user32.dll) —
as mesmas usadas pela tela de configurações do Windows. A interface é feita com Windows Forms.

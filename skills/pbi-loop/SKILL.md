---
name: pbi-loop
description: >-
  Orquestra o pipeline SDD de um único PBI, de plan-task até verify, com
  commit por Step e human-in-the-loop: para entre portões e espera aprovação.
  No modo interativo é coordenador: cada Step e cada portão roda em janela de
  contexto nova (você conduz), com handoff. Use quando o usuário pedir
  /pbi-loop, fechar um PBI no automático ou rodar o fluxo de um PBI sem PR.
  Não substitui as skills dos portões nem funde as regras delas neste arquivo;
  não abre PR, não arquiva e não paraleliza. O feature-orchestrator compõe esta
  skill por PBI.
disable-model-invocation: true
---

# pbi-loop

Orquestrador de **um PBI**. **Não** reimplemente `plan-task`, `exec-step`, `replan`, `qa`, `e2e-evidence` nem `verify` aqui. Leia o `SKILL.md` de cada portão (irmão deste arquivo) para conhecer o contrato dele: no **modo Interativo** você **não** o executa — emite o handoff; no **modo Implementação**, cumpra-o por completo.

Leia também [../sdd-context/SKILL.md](../sdd-context/SKILL.md).

## Modos

- **Interativo (padrão, human-in-the-loop):** pipeline completo, para entre portões e entre PBIs, espera a aprovação do usuário e relata o estado a cada virada. É o caminho para quem quer controle fino PBI a PBI. Aqui a skill **coordena** (seção **Sessões e janelas**).
- **Implementação (invocado pelo `feature-orchestrator`, autônomo):** roda os passos 1–3 (plano já aprovado pelo chamador + `exec-step` + commit) no worker/painel e **devolve ao chamador** antes do passo 4. Os passos 4–6 (`qa`, `e2e-evidence`, `verify`) exigem revisor isolado; o chamador os executa. Se o worker conseguir, por si, um revisor isolado, pode completar 4–6.

O modo muda **quem aprova, onde rodam os passos 4–6 e o isolamento (por Step vs por PBI)**, não a ordem nem os portões.

## Sessões e janelas

Regras-base (modelo, revisor isolado, review de pares) em [../sdd-context/SKILL.md](../sdd-context/SKILL.md), **Sessões, janelas e isolamento**. Aqui, só o que é do `pbi-loop`:

- **Interativo — coordenador, não executor:** cada Step e cada portão (`plan-task`, `exec-step`, `replan`, `qa`, `e2e-evidence`, `verify`) roda em **janela de contexto nova, do zero** — um Step por janela, uma janela por portão. O estado mora no `PBI-*.md`: o coordenador **para**, emite o **Handoff** e, ao retomar, relê o arquivo.
- **Implementação (painel Herdr / `feature-orchestrator`) — por PBI, não por Step:** o painel é um único processo e não abre janela por unidade; executa os passos 1–3 ali. A janela por Step vale só no Interativo.

## Handoff (modo Interativo)

Em cada virada, **pare** e devolva ao usuário um bloco para a **janela nova**: skill, alvo (Step/portão), PBI e o que invocar. Sem histórico — a janela nova lê o `.spec/` e o PBI do zero. Exemplo:

> **Abra uma janela nova (contexto do zero), escolha o modelo e rode:**
> `exec-step` — PBI `<ID>`, Step `<n>`: `<título do Step>`. Ao concluir, volte aqui e diga “Step `<n>` pronto”.

Não cole veredito, diff nem histórico no handoff.

`qa` e `verify` vão para **janela nova / revisor isolado** (nunca no contexto que implementou).

## Escopo

- Um PBI: do `plan-task` até o `verify` (texto de PR no PBI).
- **Commita** o que o `exec-step` normalmente só sugere (código/testes do produto). Não commite `.spec/`.
- **Não** abra PR, não rode `archive-pbi`, não rode `structure-spec`, não paralelize (isso é `feature-orchestrator`).

## Exceção de commit

Depois de um `exec-step` bem-sucedido, execute o `git commit` com a mensagem Conventional Commits que o `exec-step` elaborou (HEREDOC se multilinha). Hooks valem; se o hook recusar, pare — não `--no-verify`.

## Máquina de estados

PBI ativo: único `PBI-*.md` em `.spec/features/`. Se não houver, pare (`plan-task` num item do backlog, ou o usuário escolhe). No **modo Implementação**, o plano já chega aprovado do chamador — pule o passo 1.

**Modo Interativo:** você não executa as unidades abaixo — em cada uma, emita o **Handoff** e pare; ao retomar, releia o PBI e avance. O commit do Step (exceção acima) é feito por você, coordenador, depois que a janela nova devolver o `exec-step` bem-sucedido.

**Modo Implementação:** execute no painel, exceto os passos 4–6 (revisor isolado; o chamador os roda).

1. **Sem** `## Plano de Execução (Steps)` → handoff de `plan-task` (interativo) ou, no modo Implementação, cumpra (`plan-task`). **Pare** e espere aprovação do plano (interativo) ou retorne ao chamador (implementação). Não execute Step nesta virada.
2. **Plano existe, ainda não aprovado nesta conversa** (você acabou de escrevê-lo, ou o usuário/chamador não disse para seguir) → pare. Se o usuário invocou `pbi-loop` **com plano já no arquivo** e pediu o loop, trate como aprovado.
3. Enquanto houver Step `- [ ]`:
   - Handoff de `exec-step` **só** no primeiro `- [ ]` (ou o que o usuário nomear) — uma janela nova por Step. No modo Implementação, leia e cumpra `exec-step` no painel. (`exec-step` / `replan` invalidam QA/e2e/Review se já existiam — Status `Obsoleto`.)
   - Spec drift → handoff de `replan` (interativo), **pare** (espere aprovação; implementação: reporte ao chamador), depois volte ao passo 3. Não misture spec+código.
   - Teste do recorte falhou e o Step não fecha → **pare**.
   - Sucesso → commit (exceção acima) → próximo `- [ ]`.
   - **Modo Implementação:** ao zerar os `- [ ]`, devolva o controle ao chamador (não siga para o 4).
4. Todos os Steps atuais `- [x]` → handoff de `qa` em **janela nova / revisor isolado** (também se o Report estiver `Obsoleto`).
   - `Limpo` → passo 5.
   - Steps anexados → volte ao 3. **Teto:** 2 passagens de `qa` que anexam Steps. Na terceira, pare e reporte.
5. Handoff de `e2e-evidence` se evidência estiver ausente ou `Obsoleto`; janela nova. Skip justificado conclui o portão. Não invente runner; não suba stack no chute.
6. Handoff de `verify` em **janela nova / revisor isolado**. **Pare** no `## Review` + texto de PR se houver. Sem `gh pr`, sem merge, sem `archive-pbi`.

## Parar imediatamente

- Usuário pediu para parar.
- `verify` = `Não atende` ou ressalva que bloqueia merge.
- Hook de commit falhou; `git` recusou.
- Mais de um `PBI-*.md` em `features/`.
- Teto de `qa` (acima).

## Relato ao parar

Uma linha: estado (qual passo), PBI, Steps `[x]/total`, último commit (hash curto) se houver, próximo portão humano se não terminou. No modo Interativo, acompanhe com o **Handoff** pendente (skill + alvo para a janela nova). No modo Implementação, o relato volta ao `feature-orchestrator`.

---
name: pbi-loop
description: >-
  Orquestra o pipeline SDD de um único PBI, de plan-task até verify, com
  commit por Step e human-in-the-loop: para entre portões e espera aprovação.
  Use quando o usuário pedir /pbi-loop, fechar um PBI no automático ou rodar
  o fluxo de um PBI sem PR. Não substitui as skills dos portões nem funde as
  regras delas neste arquivo; não abre PR, não arquiva e não paraleliza. O
  feature-orchestrator compõe esta skill por PBI.
disable-model-invocation: true
---

# pbi-loop

Orquestrador de **um PBI**. **Não** reimplemente `plan-task`, `exec-step`, `replan`, `qa`, `e2e-evidence` nem `verify` aqui. Antes de cada portão, **leia** o `SKILL.md` desse portão (irmão deste arquivo) e obedeça-o por completo.

Leia também [../sdd-context/SKILL.md](../sdd-context/SKILL.md).

## Sessões (o modelo é escolha sua)

Esta skill **não troca** o modelo do chat. Abra um **chat novo** e escolha o modelo que quiser; invoque `pbi-loop`.

- Não implemente (`exec-step`) no mesmo chat em que planejou (`plan-task`/`replan`).
- Não rode `qa`/`verify` no mesmo histórico/conversa que implementou — ver **Revisor isolado** abaixo.

## Modos

- **Interativo (padrão, human-in-the-loop):** pipeline completo, para entre portões e entre PBIs, espera a aprovação do usuário e relata o estado a cada virada. É o caminho para quem quer controle fino PBI a PBI.
- **Implementação (invocado pelo `feature-orchestrator`, autônomo):** roda os passos 1–3 (plano já aprovado pelo chamador + `exec-step` + commit) no worker/painel e **devolve ao chamador** antes do passo 4. Os passos 4–6 (`qa`, `e2e-evidence`, `verify`) exigem revisor isolado; o chamador os executa. Se o worker conseguir, por si, um revisor isolado, pode completar 4–6.

O modo muda **quem aprova e onde rodam os passos 4–6**, não a ordem nem os portões.

## Revisor isolado (`qa` e `verify`)

`qa` e `verify` **nunca** rodam no contexto/histórico que implementou. Rode-os em **contexto isolado**: conversa nova ou subagente que **não** recebe o histórico da implementação. **Você escolhe o modelo** do revisor; a skill não fixa modelo nem vendor. Sem contexto isolado disponível, pare e peça um chat novo só com o portão.

## Escopo

- Um PBI: do `plan-task` até o `verify` (texto de PR no PBI).
- **Commita** o que o `exec-step` normalmente só sugere (código/testes do produto). Não commite `.spec/`.
- **Não** abra PR, não rode `archive-pbi`, não rode `structure-spec`, não paralelize (isso é `feature-orchestrator`).

## Exceção de commit

Depois de um `exec-step` bem-sucedido, execute o `git commit` com a mensagem Conventional Commits que o `exec-step` elaborou (HEREDOC se multilinha). Hooks valem; se o hook recusar, pare — não `--no-verify`.

## Máquina de estados

PBI ativo: único `PBI-*.md` em `.spec/features/`. Se não houver, pare (`plan-task` num item do backlog, ou o usuário escolhe). No **modo Implementação**, o plano já chega aprovado do chamador — pule o passo 1.

1. **Sem** `## Plano de Execução (Steps)` → leia e cumpra `plan-task`. **Pare** e espere aprovação do plano (interativo) ou retorne ao chamador (implementação). Não execute Step nesta virada.
2. **Plano existe, ainda não aprovado nesta conversa** (você acabou de escrevê-lo, ou o usuário/chamador não disse para seguir) → pare. Se o usuário invocou `pbi-loop` **com plano já no arquivo** e pediu o loop, trate como aprovado.
3. Enquanto houver Step `- [ ]`:
   - Leia e cumpra `exec-step` **só** no primeiro `- [ ]` (ou o que o usuário nomear). (`exec-step` / `replan` invalidam QA/e2e/Review se já existiam — Status `Obsoleto`.)
   - Spec drift → cumpra `replan`, **pare** (interativo: espere aprovação; implementação: reporte ao chamador), depois volte ao passo 3. Não misture spec+código.
   - Teste do recorte falhou e o Step não fecha → **pare**.
   - Sucesso → commit (exceção acima) → próximo `- [ ]`.
   - **Modo Implementação:** ao zerar os `- [ ]`, devolva o controle ao chamador (não siga para o 4).
4. Todos os Steps atuais `- [x]` → cumpra `qa` em **revisor isolado** (também se o Report estiver `Obsoleto`).
   - `Limpo` → passo 5.
   - Steps anexados → volte ao 3. **Teto:** 2 passagens de `qa` que anexam Steps. Na terceira, pare e reporte.
5. Cumpra `e2e-evidence` se evidência estiver ausente ou `Obsoleto`. Skip justificado conclui o portão. Não invente runner; não suba stack no chute.
6. Cumpra `verify` em **revisor isolado**. **Pare** no `## Review` + texto de PR se houver. Sem `gh pr`, sem merge, sem `archive-pbi`.

## Parar imediatamente

- Usuário pediu para parar.
- `verify` = `Não atende` ou ressalva que bloqueia merge.
- Hook de commit falhou; `git` recusou.
- Mais de um `PBI-*.md` em `features/`.
- Teto de `qa` (acima).

## Relato ao parar

Uma linha: estado (qual passo), PBI, Steps `[x]/total`, último commit (hash curto) se houver, próximo portão humano se não terminou. No modo Implementação, o relato volta ao `feature-orchestrator`.

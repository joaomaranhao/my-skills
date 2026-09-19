---
name: loop-engineering
description: >-
  Orquestra o pipeline SDD de plan-task até verify: executa cada portão lendo
  a skill correspondente, commita cada Step, não abre PR nem arquiva. Use
  quando o usuário pedir loop-engineering, fechar o PBI no automático, ou
  rodar o fluxo ponta a ponta sem PR. Não substitui as skills dos portões e
  não funde as regras delas neste arquivo.
disable-model-invocation: true
---

# loop-engineering

Orquestrador. **Não** reimplemente `plan-task`, `exec-step`, `replan`, `qa`, `e2e-evidence` nem `verify` aqui. Antes de cada portão, **leia** o `SKILL.md` desse portão (irmão deste arquivo) e obedeça-o por completo.

Leia também [../sdd-context/SKILL.md](../sdd-context/SKILL.md).

## Modelos (não troca o picker desta sessão)

| Portão | Como |
|---|---|
| `plan-task` / `replan` | **Manual:** chat novo em **Sonnet**. Se não houver plano e esta sessão não for Sonnet, **pare** e peça esse chat; não planeje em Grok “para não bloquear”. |
| `exec-step` (e o restante deste loop) | **Manual:** chat novo em **Grok**, com o plano já aprovado. Invoque `loop-engineering` aqui. |
| `qa` / `verify` | Revisor isolado: subagente (ou chat novo) com modelo **≠** implementador; ver essas skills. Sem `inherit`. |

Não rode `exec-step` no chat em que acabou de planejar em Sonnet.

## Escopo

- Do `plan-task` até o `verify` (texto de PR no PBI).
- **Commita** o que o `exec-step` normalmente só sugere (código/testes do produto). Não commite `.spec/`.
- **Não** abra PR, não rode `archive-pbi`, não rode `structure-spec`.

## Exceção de commit

Nesta skill, depois de um `exec-step` bem-sucedido, execute o `git commit` com a mensagem Conventional Commits que o `exec-step` elaborou (HEREDOC se multilinha). Hooks valem; se o hook recusar, pare — não `--no-verify`.

## Máquina de estados

PBI ativo: único `PBI-*.md` em `.spec/features/`. Se não houver, pare (`plan-task` num item do backlog, ou o usuário escolhe).

1. **Sem** `## Plano de Execução (Steps)` → leia e cumpra `plan-task`. **Pare** e espere aprovação do plano. Não execute Step nesta virada.
2. **Plano existe, ainda não aprovado nesta conversa** (você acabou de escrevê-lo, ou o usuário não disse para seguir) → pare. Se o usuário invocou `loop-engineering` **com plano já no arquivo** e pediu o loop, trate como aprovado.
3. Enquanto houver Step `- [ ]`:
   - Leia e cumpra `exec-step` **só** no primeiro `- [ ]` (ou o que o usuário nomear). (`exec-step` / `replan` invalidam QA/e2e/Review se já existiam — Status `Obsoleto`.)
   - Spec drift → cumpra `replan`, **pare**, espere aprovação, depois volte ao passo 3. Não misture spec+código.
   - Teste do recorte falhou e o Step não fecha → **pare**.
   - Sucesso → commit (exceção acima) → próximo `- [ ]`.
4. Todos os Steps atuais `- [x]` → cumpra `qa` (também se o Report estiver `Obsoleto`).
   - `Limpo` → passo 5.
   - Steps anexados → volte ao 3. **Teto:** 2 passagens de `qa` que anexam Steps. Na terceira, pare e reporte. Não entre em loop infinito.
5. Cumpra `e2e-evidence` se evidência estiver ausente ou `Obsoleto`. Skip justificado conclui o portão. Não invente runner; não suba stack no chute.
6. Cumpra `verify` (revisor isolado, outro modelo; orquestrador não audita). **Pare** no `## Review` + texto de PR se houver. Sem `gh pr`, sem merge, sem `archive-pbi`.

## Parar imediatamente

- Usuário pediu para parar.
- `verify` = `Não atende` ou ressalva que bloqueia merge.
- Hook de commit falhou; `git` recusou.
- Mais de um `PBI-*.md` em `features/`.
- Teto de `qa` (acima).

## Relato ao parar

Uma linha: estado (qual passo), PBI, Steps `[x]/total`, último commit (hash curto) se houver, próximo portão humano se não terminou.

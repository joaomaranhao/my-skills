---
name: sdd
description: >-
  Orienta qual skill SDD usar agora a partir do PBI ativo em .spec/features.
  Use quando o usuário estiver perdido na fase, perguntar o próximo passo do
  pipeline SDD, ou pedir /sdd. Não planeja Steps, não escreve código, não roda
  testes, não gera evidência nem texto de PR.
disable-model-invocation: true
---

# sdd

Orienta qual skill SDD usar agora. **Não** planeje Steps, não escreva código, não rode testes, não gere evidência nem texto de PR.

Leia também [../sdd-context/SKILL.md](../sdd-context/SKILL.md) (pipeline e tabela “quando usar”).

1. Olhe o PBI ativo: o único `PBI-*.md` em `.spec/features/` (não em `backlog/` nem `archive/`). Se não houver, diga para escolher um item em `.spec/features/backlog/` e usar `plan-task`.
2. Pelo estado do arquivo (plano, checkboxes de Steps, `## QA Report`, `## Evidências e2e`, `## Review`), diga **uma** próxima skill e uma frase do porquê.
   - Spec drift no meio de um Step (usuário ou agente parou) → `replan` (não `exec-step`).
   - Steps `- [ ]` (inclusive anexados pelo `qa` ou `replan`) → `exec-step`.
   - Todos `[x]` e sem `QA Report` Limpo (ausente, Steps anexados, Falhas, ou `Obsoleto`) → `qa`.
   - `QA Report` com Steps anexados → `exec-step` (não `e2e-evidence`).
   - `qa` Limpo e evidência ausente/`Obsoleto` (sem skip válido) → `e2e-evidence` (skip justificado **conclui** o portão).
   - `qa` Limpo + evidência válida ou skip justificado/planejado, ainda sem PR → `verify` (ou `loop-engineering` se o usuário quiser o restante com commits). `Obsoleto` ≠ evidência válida.
   - Usuário pediu fechar o PBI no automático, sem PR → `loop-engineering` (não pular aprovação do plano nem o `verify` isolado).
   - PR mergeada e o PBI ainda em `features/` → `archive-pbi`.
   - `features/` vazio → item no backlog + `plan-task`.
3. Se o usuário já nomeou a fase, só confirme ou corrija (ex.: pediu `verify` sem `qa` Limpo; pediu `archive-pbi` antes do merge).

---
name: qa
description: >-
  QA de resiliência no PBI: mapeia bordas, roda a suíte unitária (com checker
  de corrida se a stack tiver) e, se faltar cobertura ou houver bug, anexa
  Steps novos no plano — sem escrever código de produção nem testes novos.
  Use depois de todos os Steps - [x], antes de e2e-evidence e verify, ou
  quando o usuário pedir qa.
disable-model-invocation: true
---

# qa

Atua como um QA Engineer: valida resiliência e cobertura de borda no **PBI como um todo**. Não implementa correção nem testes novos — isso volta para `exec-step`.

**Quando rodar:** quando todos os Steps **já existentes** no plano estiverem `- [x]`, e **antes** de `e2e-evidence` / `verify`. Não rodar ao fim de cada Step (bordas do recorte ficam no `exec-step`). Repetir `qa` depois que os Steps que esta skill anexar tiverem sido executados e commitados. Só repetir no meio do PBI por outro motivo se o usuário pedir (regressão grave ou mudança de contrato HTTP de ponta a ponta).

Leia também [../sdd-context/SKILL.md](../sdd-context/SKILL.md).

## Modelo

Não auditar no **mesmo** modelo **nem** no mesmo histórico que implementou (`exec-step`).

- **Cursor Agent + Task:** lance um subagente (`generalPurpose`, `run_in_background: false`) com um `model` da lista permitida do `Task` que seja **diferente** do implementador. **Não** use `inherit`. Se o spawn falhar ou não houver slug adequado, pare e peça um **chat novo** só com `qa` (qualquer modelo ≠ o da implementação).
- O subagente lê e cumpre **esta** skill (análise, suíte, anexar Steps, QA Report). Você (sessão que implementou) não escreve o relatório no lugar dele.
- Se o usuário já abriu um **chat novo** (outro modelo/histórico) e invocou `qa`, cumpra a skill nesta sessão.

## Proibido nesta skill

- Alterar código de produção.
- Criar ou editar arquivos de teste.
- “Já sanar” o bug encontrado.
- Rodar `e2e-evidence` ou `verify`.

## Passos

1. **Análise de vulnerabilidades e edge cases:**
   - Código do PBI atual (`.spec/features/<PBI-id>.md`) vs `.spec/` (`1-overview.md`, `2-architecture.md`, `.spec/docs/` citados, ADRs, CAs).
   - Mapeie falhas: payload inválido/nulo/tipo errado; limites (string longa, inteiro negativo, array vazio); timeout; store indisponível; concorrência / corrida se a stack tiver.

2. **Execução da suíte que já existe:**
   - Não depende de API viva. E2e vivo é `e2e-evidence`.
   - Comando: o que o **repo documenta** para unitário/integração. Se a stack tiver checker de corrida (ex.: Go `-race`), use-o nesta passagem; senão rode a suíte unitária e registre que não há equivalente.
   - Não misture com a suíte e2e (tags/scripts de ponta a ponta).
   - Falha de teste = evidência para um Step; não corrija aqui.

3. **Gaps viram Steps (não código):**
   - Se faltar teste adversário, cobertura de CA, correção de bug ou falha de contrato: **anexe** novos itens em `## Plano de Execução (Steps)` no PBI, todos `- [ ]`.
   - Não reabra Steps já `- [x]`. Não reescreva o plano antigo.
   - Cada Step novo: objetivo, CAs tocados se houver, arquivos prováveis (produção e/ou testes), como validar. Um Step = uma unidade para um `exec-step` posterior.
   - Sem teto rígido. Não funda recortes distintos num Step só; se a lista ficar um segundo PBI, diga no chat.

4. **Relatório `## QA Report` (criar ou substituir):**
   - **Status:** `Limpo` | `Steps anexados` | `Falhas na suíte (Steps anexados)`. (Se a seção estava `Obsoleto`, esta passagem a substitui com um Status novo.)
   - **Cenários de borda analisados:** lista (cobertos pela suíte atual vs gap).
   - **Corrida / regressão:** resultado do comando do passo 2 (incluindo “sem checker de corrida nesta stack”).
   - **Steps anexados nesta passagem:** ids/títulos, ou “nenhum”.
   - `Limpo` só se a suíte passou, o checker de corrida (se existir) está ok e **nenhum** Step novo foi anexado.
   - Sem `Limpo`, o PBI **não** segue para `e2e-evidence` nem `verify`. Próximo portão: `exec-step` em cada Step novo, depois `qa` de novo.
   - Steps anexados pelo `qa` usam o **formato canônico** do `plan-task` (`- [ ] Step N — …` + **CAs** / **Arquivos** / **Validar**).

---
name: replan
description: >-
  Corrige spec drift sem código de aplicação: atualiza PBI, arquitetura e/ou
  ADRs e ajusta o plano de Steps. Use quando o exec-step descobrir spec errada,
  o usuário pedir replan ou spec-amend, ou o PBI divergir de .spec/. Não
  implementa, não testa, não abre PR.
disable-model-invocation: true
---

# replan

Emergência de spec no meio do PBI. **Não** escreva código de produção nem testes.

Leia também [../sdd-context/SKILL.md](../sdd-context/SKILL.md).

## Modelo (sessão — manual)

Recomendado: **Claude Sonnet**, chat novo (a skill não troca o picker). Mesma regra do `plan-task`.

## Quando

- `exec-step` (ou o usuário) apontou divergência: arquitetura, ADR, CA, dump ou PBI não descrevem o que o código precisa ser.
- Não use para o **primeiro** plano (isso é `plan-task`) nem para anexar testes adversários (isso é `qa`).

## Proibido

- Implementar o Step, “já alinhar o código”, criar teste, rodar suíte, `qa`, e2e, `verify`.
- Inventar requisito que não esteja no relato de drift + spec atual + confirmação do usuário.

## Passos

1. **Drift em uma frase:** o que o `.spec/` diz vs o que a realidade/código/CA exige. Pare se estiver ambíguo e pergunte.
2. **Onde gravar** (só o necessário):
   - Contrato/fluxo/estado → `.spec/2-architecture.md`
   - Decisão explícita nova → ADR em `.spec/adrs/` (próximo número; não invente ADR de preferência estética)
   - Objetivo, escopo, CAs → PBI ativo em `.spec/features/<PBI-id>.md`
   - Dump de parceiro → `.spec/docs/<parceiro>/` só se o usuário trouxer o recorte; não invente OpenAPI
   - Em conflito residual: PBI + arquitetura vencem o dump.
3. **Plano:** em `## Plano de Execução (Steps)`:
   - Não desmarque Steps `- [x]` só para “ficar bonito”. Se o código já entregue ficou errado em relação à spec nova, **anexe** Steps `- [ ]` para alinhar (e cite os CAs).
   - O Step interrompido permanece `- [ ]` se não foi concluído.
   - Steps novos: **mesmo formato canônico** do `plan-task` (`- [ ] Step N — …` + **CAs** / **Arquivos** / **Validar**).
4. **Invalidação:** se existir `## QA Report` Limpo, `## Evidências e2e` concluída ou `## Review` pré-PR, mude o Status para `Obsoleto` + `Motivo: replan (spec drift)`. Não apague o histórico. Depois da aprovação, o próximo portão de qualidade é `qa` de novo (quando os Steps novos estiverem `[x]`).
5. **Aprovação:** mostre o diff de spec + Steps novos no chat e espere o usuário aprovar antes de qualquer `exec-step`. Não execute o Step daqui.

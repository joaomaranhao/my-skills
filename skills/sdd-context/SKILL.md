---
name: sdd-context
description: >-
  Regras âncora de Spec-Driven Development (SDD): pasta .spec/ como memory bank,
  PBI ativo, Steps cirúrgicos e YAGNI. Usar em qualquer trabalho neste estilo de
  spec (.spec/features, PBI, plano de execução, QA Report) e como pré-requisito
  das skills structure-spec, plan-task, exec-step, replan, qa, e2e-evidence, verify,
  archive-pbi, pbi-loop, feature-orchestrator, code-review e sdd.
---

# SDD context

Fonte da verdade ancorada: pasta `.spec/`. Não implemente Steps ou PBIs futuros (YAGNI).

## Estrutura de leitura

- Global: `.spec/1-overview.md` (visão e requisitos), `.spec/2-architecture.md` (contratos e fluxos), `.spec/0-roadmap.md` (sequência de entrega).
- Decisões: `.spec/adrs/`.
- Parceiros e ferramentas: `.spec/docs/` (dumps e contratos externos no recorte deste repositório; uma subpasta por sistema, ex.: `.spec/docs/payments-api/`). Complementa overview/arquitetura/PBI; não substitui a interpretação canônica. Não incluir material de produto fora do papel deste serviço.
- Evidências e2e (local): `.spec/e2e/evidence/<PBI-id>/` — saída de `e2e-evidence` para a pessoa de QA. Não é fonte de verdade nem o catálogo de casos do runner (esse permanece no repo, versionado).
- Índice: `.spec/features/backlog.md` (convenção de pastas e lista de PBIs).
- Execução: o PBI ativo é o único arquivo `PBI-*.md` em `.spec/features/` (não em `backlog/` nem em `archive/`). Fila em `.spec/features/backlog/`; concluídos em `.spec/features/archive/`.

Pode consultar especificações e PBIs relacionados para o contexto macro, mas **nunca** crie código, métodos, abstrações antecipadas ou ganchos para Steps ou PBIs futuros.

## Pipeline (portões)

Cada fase é uma skill. Não misture portões.

| Skill | Use quando | Não use para |
|---|---|---|
| `structure-spec` | Quebrar monolito em `.spec/` | Implementar, testar, alterar skills |
| `plan-task` | PBI sem plano, ou plano a validar/refinar (sem gap → não reescreve) | Escrever código de aplicação |
| `exec-step` | Um Step `- [ ]` aprovado | PBI inteiro, QA/e2e/PR; corrigir spec |
| `replan` | Spec drift no meio do PBI (arquitetura/ADR/CA/PBI errados) | Implementar; primeiro plano (`plan-task`) |
| `qa` | Steps atuais `- [x]`; analisa e **anexa** Steps se faltar cobertura/bug | Escrever produção ou testes; e2e vivo |
| `e2e-evidence` | Depois de `qa` **Limpo** | Inventar suíte; plano oficial de QA; print no lugar de log/JSON |
| `verify` | Depois de `qa` Limpo (e evidência ou skip justificado) | Auditar no mesmo agente que implementou; implementar; e2e; arquivar |
| `pbi-loop` | Um PBI ponta a ponta `plan-task`→`verify` com commit por Step; human-in-the-loop | Fundir portões neste arquivo; PR; archive; paralelizar; primeiro plano sem aprovação |
| `feature-orchestrator` | Feature inteira (N PBIs) ponta a ponta e autônoma; paraleliza via Herdr; compõe `pbi-loop` | Reimplementar os portões; fatiar Steps; PR; paralelizar sem Herdr |
| `archive-pbi` | PR **já mergeada** | Pré-PR; segundo PBI ainda ativo em `features/` |
| `code-review` | PR de **pares** (fora do pipeline SDD) | `verify` da sua implementação; escrever correção |

Perdido na fase? skill `sdd`.

## Foco (Steps)

- Trabalhe sempre na menor unidade possível (um **Step** do plano de execução por vez).
- Respeite overview, arquitetura, PBI ativo e, quando o PBI citar, dumps em `.spec/docs/`. Em conflito, **PBI e arquitetura** prevalecem sobre o dump bruto.
- Mantenha alterações restritas ao escopo do Step solicitado.

## Qualidade

- Código limpo e pragmático, idiomático na **linguagem deste repositório**. Formatação a cargo dos formatters/linters do projeto. Foco: fidelidade às regras de negócio, resiliência de borda e corretude dos testes.
- Após alteração de código: rode a **suíte unitária que o próprio repo documenta** (Makefile, `package.json`, README, docs de teste). Não assuma `go test` nem outra ferramenta.

## Regras curtas

- Um `PBI-*.md` em `.spec/features/` (fora de `backlog/` e `archive/`).
- Um Step por `exec-step`. YAGNI: nada para PBI/Step futuro.
- Dump em `.spec/docs/`: complementar. PBI + arquitetura vencem se divergir.
- `qa` ≠ `e2e-evidence` ≠ `verify` ≠ `archive-pbi`.
- `qa` não implementa: gap vira Step `- [ ]`; `e2e-evidence` / `verify` só com `## QA Report` **Limpo** (não `Obsoleto`).
- Spec drift no `exec-step` → parar e `replan` (sem código).
- **Invalidação:** se código ou plano mudar depois de `qa` Limpo / evidência / Review pré-PR, marque essas seções como **Obsoleto** (não apague o histórico). Próximo portão: `qa` de novo (e e2e/`verify` conforme o caso).
- `e2e-evidence`: skip justificado **conclui** o portão; não inventa runner.
- `verify` / `qa` após implementação: revisor **isolado** (conversa/subagente novo, sem o histórico da implementação). **Você escolhe o modelo**; a skill não fixa modelo nem vendor.
- Depois do merge: `archive-pbi` (senão o próximo `plan-task` viola “um PBI em `features/`”).
- Commit: `exec-step` sozinho só sugere a mensagem; `pbi-loop` (e `feature-orchestrator`, que o compõe) **executa** o commit do Step. `git commit` avulso continua do usuário. Não commite `.spec/`.
- Memory bank `.spec/` é **local e pessoal**. Coloque `.spec/` no `.gitignore` do repo se ainda não estiver. Catálogo e2e versionado: o que o runner do repo já usa (ex.: `testdata/e2e/`, `e2e/`) — isso sim é do time.

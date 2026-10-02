---
name: plan-task
description: >-
  Planeja a execução de um PBI em .spec/features/ em Steps pequenos, cirúrgicos
  e sequenciais. Se o plano já existir, valida coerência e gaps — sem gap não
  reescreve; com gap edita in-place. Use quando o usuário pedir plano de PBI,
  /plan-task, decompor critérios de aceite em Steps, ou promover um item do
  backlog. Não escreve código de aplicação nem testes.
disable-model-invocation: true
---

# plan-task

Planeja a execução de um PBI em `.spec/features/` em passos (Steps) pequenos, cirúrgicos e sequenciais.

Leia também [../sdd-context/SKILL.md](../sdd-context/SKILL.md).

## Sessão

Sessão separada de quem vai implementar. Regras-base em [../sdd-context/SKILL.md](../sdd-context/SKILL.md), **Sessões, janelas e isolamento**.

## Plano já existente (refinar)

Se `## Plano de Execução (Steps)` **já existir** no PBI:

1. Relia PBI (CAs, escopo), overview/arquitetura/ADRs/`docs/` citados e o plano atual.
2. Valide se o plano **ainda faz sentido**: Steps cobrem os CAs? Granularidade ok? Validação/comando ainda corretos? Recorte e2e (skip vs runner) ainda válido?
3. Procure **gaps** (CA sem Step, Step que funde unidades distintas, arquivo/validação errados, e2e sem decisão).
4. **Sem gap e plano coerente:** diga isso no chat em 1–2 frases. **Não** reescreva o plano, não mexa no arquivo “por polimento”.
5. **Com gap ou incoerência:** edite **in-place** só o necessário (mesmo formato canônico), mostre o diff no chat e peça aprovação. Não invente Steps cosméticos.
6. Spec drift profundo (arquitetura/ADR/CA errados no meio da execução) → isso é `replan`, não reescrita genérica aqui.

Se **não** houver plano, siga os passos abaixo (primeiro plano).

1. **Análise de Contexto (Memory Bank):**
   - Localize o PBI informado. O item em execução deve ser o único `PBI-*.md` em `.spec/features/` (irmão de `backlog.md`, fora de `backlog/` e `archive/`).
   - Se o PBI ainda estiver em `.spec/features/backlog/`, mova-o para `.spec/features/`, atualize a coluna **Pasta atual** em `.spec/features/backlog.md` e só então planeje.
   - Leia o arquivo do PBI (`.spec/features/<PBI-id>.md`).
   - Consulte os contextos do Memory Bank relevantes:
     - Visão e requisitos em `.spec/1-overview.md`.
     - Contratos e fluxos em `.spec/2-architecture.md`.
     - Sequência de entrega em `.spec/0-roadmap.md`.
     - Decisões em `.spec/adrs/`.
     - Dumps de parceiros/ferramentas citados pelo PBI em `.spec/docs/` (subpasta do sistema).
     - Índice e dependências em `.spec/features/backlog.md`.
   - Analise brevemente outros PBIs na fila (`.spec/features/backlog/`) apenas para entender o ecossistema atual, sem planejar a execução deles.

2. **Refinamento do Requisito:**
   - Se o texto do PBI estiver vago, reescreva as seções de objetivo, comportamento e critérios de aceite do arquivo `.md` para deixá-las claras, determinísticas e alinhadas às regras do projeto.

3. **Decomposição em Steps Sequenciais:**
   - Crie um plano em **Steps pequenos, sequenciais e testáveis**. Sem teto numérico: quantos forem necessários para não fundir unidades. Se o PBI ficar enorme, proponha **split em dois PBIs** no chat — não comprima trabalho distinto num Step só.
   - Escreva o plano no próprio arquivo do PBI sob a seção `## Plano de Execução (Steps)`.
   - Use **este formato** (obrigatório — `exec-step` / `replan` / `qa` anexam no mesmo molde):

     ```markdown
     ## Plano de Execução (Steps)

     - [ ] Step 1 — <objetivo curto e testável>
       - **CAs:** CA01, CA02
       - **Arquivos:** path/a.go, path/a_test.go
       - **Validar:** <comando de teste documentado no projeto>
     - [ ] Step 2 — …
       - **CAs:** CA03
       - **Arquivos:** …
       - **Validar:** …
     ```

   - **CAs:** ids que este Step fecha por completo. Um CA pode ficar para Step posterior; não marque CA como feito no plano.
   - **Arquivos:** caminhos **deste** repo. **Validar:** comando que o projeto documenta (não invente ferramenta).

4. **Recorte e2e (antes de fechar o plano):**
   - Se algum CA exercita HTTP, gRPC, fila ou outro contrato de ponta a ponta, descubra se **este** repo já tem runner e2e documentado (Makefile, `e2e/`, `testdata/`, scripts).
   - **Há runner:** não crie Step de bootstrap; `e2e-evidence` usa o que existe (gaps → pessoa de QA).
   - **Não há runner:** no chat, ofereça (a) um Step neste PBI para bootstrap **só do recorte** dos CAs, ou (b) skip planejado (pessoa de QA cobre). Grave a escolha no PBI, seção `## Evidências e2e` com **Status: `Skip justificado`** e **Motivo** (`skip planejado` ou `runner a criar neste PBI` + o Step). Sem resposta até a aprovação do plano, **não** invente runner — deixe `Skip justificado` / Motivo `skip planejado` explícito.
   - Esta skill **não** escreve a suíte e2e; só o Step (se o usuário escolher a) que o `exec-step` vai implementar.

5. **Contenção de Escopo:**
   - **NÃO escreva código de aplicação ou testes nesta etapa.**
   - Apresente o plano detalhado no chat e solicite aprovação do usuário antes de prosseguir.

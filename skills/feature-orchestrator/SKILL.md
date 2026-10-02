---
name: feature-orchestrator
description: >-
  Orquestrador autônomo de uma feature inteira (N PBIs, ex.: front + back).
  Compõe a skill pbi-loop por PBI (modo implementação nos workers) e paraleliza
  PBIs independentes via Herdr, com um painel e um git worktree por PBI.
  Consolida com QA de integração, replan, e2e-evidence, verify e archive-pbi.
  Use quando o usuário pedir /feature-orchestrator, levar uma feature de ponta
  a ponta ou paralelizar PBIs. Só roda dentro do Herdr (HERDR_ENV=1/socket e
  binário instalado); sem Herdr, pare e use pbi-loop. Não reimplementa os
  portões SDD, não funde as regras deles neste arquivo, não abre PR e não
  commita .spec/.
disable-model-invocation: true
---

# feature-orchestrator

Orquestrador **autônomo** de uma **feature inteira** (conjunto de PBIs). O que é exclusivo desta skill: definir a feature, isolar e **paralelizar** os PBIs no Herdr, consolidar o resultado cross-PBI e fechar a feature. **Não** reimplemente `plan-task`, `exec-step`, `replan`, `qa`, `e2e-evidence`, `verify`, `archive-pbi` nem `pbi-loop` aqui.

**Só rode sob o Herdr** (invocada por ele, com o Herdr instalado). Sem Herdr, **pare** e use `pbi-loop` um PBI por vez.

Leia também [../sdd-context/SKILL.md](../sdd-context/SKILL.md).

## Composição (não duplicação)

- **Por PBI:** leia e cumpra [../pbi-loop/SKILL.md](../pbi-loop/SKILL.md). No worker/PBI use o **modo Implementação** (passos 1–3); os passos 4–6 são executados **uma única vez** pelo orquestrador, em contexto isolado (ver abaixo). O `pbi-loop` é a fonte única da sequência de portões — esta skill **não** a repete.
- **Exclusivo desta skill:** manifesto da feature, grafo de dependências, isolamento por worktree, disparo/monitoramento dos painéis Herdr, reconciliação de `.spec/`, merge/rebase, QA de integração cross-PBI e encerramento.
- **Unidade paralela = PBI.** Steps dentro de um PBI seguem a ordem sequencial do `pbi-loop` (por design). Esta skill não fatia Steps.

## Sessões e revisor

Regras-base em [../sdd-context/SKILL.md](../sdd-context/SKILL.md), **Sessões, janelas e isolamento**. Específico desta skill:

- `plan-task` / `replan`: chat novo, separado de quem vai implementar.
- Workers/painéis: **um por PBI**. O isolamento é **por PBI**, não por Step (o painel é um processo e não abre janela por unidade); a janela por Step do `pbi-loop` vale só no modo Interativo.
- `qa` / `verify`: revisor isolado (conversa/subagente novo, sem o histórico da implementação). Sem contexto isolado, pare e peça chat novo para o portão. A sequência de sessões é do `pbi-loop` — não a repita aqui.

## Definição de “feature”

1. Feature = conjunto de PBIs de um marco em `.spec/0-roadmap.md`, ou a lista que o usuário nomear.
2. Registre o **manifesto da feature** no chat: ids dos PBIs, ordem/dependências e o que é paralelizável.
3. **Human-in-the-loop apenas aqui:** apresente o plano da feature e espere aprovação. Aprovado, o restante roda autônomo (sem novas paradas de aprovação).

## Escopo

- De `plan-task` (por PBI) até `verify` + `archive-pbi` de cada PBI da feature.
- **Commita** o que o `exec-step`/`pbi-loop` normalmente sugere, conforme o `pbi-loop`. Nunca commite `.spec/`.
- **Não** abra PR, não faça merge remoto, não troque o modelo do chat, não rode `structure-spec`.

## Pré-requisitos de ambiente (Herdr — obrigatório)

Esta skill **só roda dentro do Herdr**: invocada por ele e com o Herdr instalado. Sem isso, **pare** e use `pbi-loop` (um PBI por vez) — não simule paralelismo e não caia em fallback sequencial.

1. Confirme o Herdr: `HERDR_ENV=1` no ambiente **e/ou** socket IPC acessível, **e** o binário/CLI instalado.
   - **Ausente:** **pare** imediatamente e diga ao usuário para rodar `pbi-loop` por PBI (ou instalar/ativar o Herdr).
2. Descubra o comando/API do Herdr **deste** repositório (binário, `Makefile`, `package.json`, docs). **Não invente** flags nem endpoints.
3. Liste os painéis existentes e registre o estado inicial (`idle`/`running`).

## Invariante do PBI ativo e reconciliação de `.spec/`

O `sdd-context` exige **um** `PBI-*.md` em `.spec/features/` por árvore. Como `.spec/` é local (gitignored) e não viaja em worktree, o fluxo é:

- A **árvore principal** é do orquestrador: guarda o manifesto e mantém **um** PBI ativo por vez (promova do `backlog/` só quando for a vez).
- **Planejamento e a invariante:** `plan-task` promove o PBI para `features/`. Como a árvore só admite um, planeje **por árvore**:
  - **Sequencial:** promova um PBI do `backlog/`, planeje, execute, verifique e arquive antes do próximo.
  - **Paralelo:** crie a worktree do PBI, traga o `PBI-*.md` do `backlog/` para a `features/` **da worktree** e rode `plan-task` ali (ou receba plano já aprovado). A árvore principal permanece com no máximo um PBI.
  - Nunca deixe dois `PBI-*.md` em `features/` da mesma árvore.
- Cada painel/worktree recebe **contexto isolado**: copie o recorte de `.spec/` necessário (incluindo o `PBI-*.md` da unidade) para a worktree, de modo que cada árvore tenha **no máximo um** PBI ativo.
- **Reconciliação (obrigatória):** o `pbi-loop` no worker grava `- [x]`, CAs, `## QA Report` e `## Review` no `PBI-*.md` **da worktree**. Como `.spec/` não faz merge, após cada merge **copie o `PBI-*.md` da worktree de volta** para `.spec/features/` na árvore principal (ou traga só as seções alteradas). Sem isso, a árvore principal fica desatualizada e o `archive-pbi` lê estado velho. Use o helper `scripts/worktree-spec-sync.sh push|pull <worktree> features/<PBI>.md` para copiar com trava contra sobrescrever a árvore principal com cópia mais antiga.
- Só então cumpra `archive-pbi` na árvore principal, antes de revelar o próximo PBI.
- Ao terminar, `features/` deve ter **zero** PBIs da feature (todos arquivados).

## Fase 1 — Plano e decomposição da feature

1. Leia `.spec/0-roadmap.md`, `.spec/1-overview.md`, `.spec/2-architecture.md` e `.spec/adrs/` para o recorte da feature.
2. Leia os `PBI-*.md` no `backlog/` e cumpra `plan-task` (sem código) para cada PBI da feature, respeitando **Planejamento e a invariante** (um PBI por árvore; na via paralela, o plano é feito na worktree do PBI). Registre o **grafo de dependências**:
   - PBIs sem arquivo/contrato compartilhado → paralelizáveis.
   - Dependência (mesmo arquivo, migração, contrato) → serializa.
3. **Contratos base primeiro:** se PBIs paralelos compartilharem interfaces, DTOs, schemas de banco, migrações ou mocks, eleja/execute um **PBI (ou Step) de contrato** sequencial **antes** do disparo paralelo e congele os contratos. Disparo paralelo com contrato aberto = conflito garantido.
4. Apresente o manifesto + grafo + recorte paralelo e **pare** para aprovação antes da Fase 2.

## Fase 2 — Execução paralela no Herdr

1. Confirme o Herdr (seção Pré-requisitos). Ausente → **pare**.
2. Para cada PBI, prepare a isolação de contexto (crie na Fase 1 se for planejar ali; reutilize na Fase 2):
   - `git worktree add .worktrees/pbi-<ID>` com branch dedicada a partir da base acordada; garanta `.worktrees/` no `.gitignore`.
   - Copie o recorte de `.spec/` e o `PBI-*.md` (do `backlog/`) para a worktree, com **um** PBI ativo.
3. **Com Herdr:** dispare a API/CLI para instanciar **um painel de fundo por PBI**, cada um rodando `pbi-loop` no **modo Implementação** (passos 1–3) na sua worktree. No prompt, passe só fatos: worktree/branch, id do PBI, caminhos `.spec/` que pode ler e a base. Não cole veredito nem histórico de outra unidade, nem o resultado esperado. O painel roda os passos no próprio processo — **não** exija uma janela nova por Step (o isolamento é por PBI).
4. Monitore o ciclo de vida (com Herdr) até que **todos** os painéis entrem em `idle`/concluído; não considere concluído por timeout silencioso. Painel com falha → não faz merge; leia o relatório e decida (`replan`/`pbi-loop` corretivo).
5. Consolide na ordem do grafo: faça `merge`/`rebase` de cada branch na principal, um por vez, resolvendo conflitos pela ordem de dependência. Após cada merge: **reconcilie o `.spec/`** (seção acima), rode a suíte que o **repo documenta** e remova a worktree só após o merge confirmado.

## Fase 3 — Portões de qualidade (passos 4–6 do `pbi-loop`, uma vez)

Depois de todos os merges e reconciliações, **continue o `pbi-loop`** (leia a skill e cumpra os passos 4–6) **uma única vez por PBI** — sem re-rodar portões que o worker já tivesse feito:

1. **`qa`** em **revisor isolado**, sobre o **código consolidado** (não por worktree). Valide explicitamente o cross-PBI: integração entre PBIs, lint, regressões e aderência à arquitetura entre as unidades. Gap/bug → o `qa` anexa Steps `- [ ]` no PBI pertinente (formato canônico); não implemente aqui.
2. Se houver Step anexado: **Fase 4** e repita `qa` até `Limpo`. **Teto:** 2 passagens de `qa` que anexam Steps; na terceira, pare.
3. `e2e-evidence` (se aplicável; skip justificado conclui o portão) e `verify` em **revisor isolado**, ainda por PBI.

Os relatórios (`## QA Report`, `## Evidências e2e`, `## Review`) ficam no `PBI-*.md` — no mesmo arquivo reconciliado para a árvore principal.

## Fase 4 — Loop de correção / re-planejamento

1. Se o `qa` anexou Steps `- [ ]`:
   - Causa = **spec drift** (arquitetura/ADR/CA/PBI errados) → cumpra `replan`, reporte e siga após alinhar o manifesto.
   - Senão, execute os novos Steps com `exec-step` (via `pbi-loop` no PBI dono).
2. Paralelize novamente via Herdr **se e somente se** houver múltiplos PBIs novos e independentes; reaplique a Fase 1 (contratos primeiro) e a Fase 2. Um único PBI/Step novo → sequencial.
3. Volte à Fase 3 (passos 4–6). **Teto:** 2 passagens de `qa` que anexam Steps. Na terceira, **pare** e reporte.

## Fase 5 — Fechamento

1. Com `qa` **Limpo** e `verify` favorável, aguarde o **merge confirmado pelo usuário**.
2. Cumpra `archive-pbi` para **cada** PBI da feature, restaurando a invariante de `features/`.
3. **Encerramento Herdr:** notifique o usuário com os PBIs finalizados, remova os painéis e worktrees temporárias e confirme `.worktrees/` limpo. Não deixe painel órfão.
4. Não abra PR, não faça merge remoto.

## Parar imediatamente

- Usuário pediu para parar.
- Herdr ausente (`HERDR_ENV=1`/socket/binário indisponível).
- Manifesto/corte paralelo da feature não aprovado.
- Contrato base compartilhado indefinido no disparo.
- Mais de um `PBI-*.md` na mesma árvore `features/`.
- Spec drift não resolvido por `replan`.
- `verify` = `Não atende` ou ressalva que bloqueia merge.
- Hook de commit falhou; `git` recusou.
- Teto de `qa` (2 passagens anexando Steps).

## Relato

Uma linha por PBI: estado (fase/painel), PBI, `[x]/total`, worktree/branch, último commit (hash curto) se houver. No encerramento, liste os PBIs finalizados e confirme painéis/worktrees removidos.

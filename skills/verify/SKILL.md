---
name: verify
description: >-
  Pré-PR: orquestra auditoria independente do diff contra o PBI/.spec/ e grava
  ## Review mais o texto da PR. Use depois de qa Limpo (e e2e-evidence ou skip
  justificado), /verify, ou review SDD. Não implementa, não audita no mesmo
  agente que implementou, não commita e não arquiva o PBI.
disable-model-invocation: true
---

# verify

Orquestra a checagem de qualidade **antes da PR**. O veredito contra o spec **não** é deste agente se ele (ou esta conversa) implementou o PBI.

Rodar **depois** de `qa` com **Status: Limpo** e, quando a API estiver no ar, de `e2e-evidence`. Sem `qa` Limpo (ausente, Steps anexados, Falhas ou `Obsoleto`), avise e pare. Se `## Evidências e2e` estiver `Obsoleto`, avise: rode `e2e-evidence` de novo (ou confirme skip). Sem evidência/skip válido, avise: verify não substitui QA nem o pacote; não escreve suíte nem e2e aqui.

Leia também [../sdd-context/SKILL.md](../sdd-context/SKILL.md).

## Independência do revisor

Mesmo histórico/conversa = viés de passar o próprio diff. Trate isso como regra, não como dica (ver [../sdd-context/SKILL.md](../sdd-context/SKILL.md), **Sessões, janelas e isolamento**).

1. Rode a auditoria em **contexto isolado**: um **subagente novo** ou uma **conversa nova** que **não** recebe o histórico da implementação.
   - Se usar subagente, ele **não** recebe o histórico. Não cole “o código está certo” nem o veredito desejado.
   - No `prompt`, passe só fatos: branch atual, base (`main` ou a que o usuário disser), caminho do PBI ativo, caminhos `.spec/` a ler, e o bloco **Mandato do revisor** abaixo, verbatim.
2. **Sem contexto isolado disponível:** pare. Peça conversa nova só com `verify`. Não faça a auditoria nesta conversa se ela implementou o PBI.
3. **Você (orquestrador):** pré-condições (`qa` / e2e), disparo do revisor, gravação do relatório dele no PBI, rascunho de PR se o revisor autorizar. **Não** re-audite o diff para “corrigir” o revisor. Discordância só se o relatório for factualmente impossível (citou arquivo que não existe) — registre isso, não inverta o veredito.

## Mandato do revisor

Copie para o subagente (ou para a conversa nova):

- Analise **todo** o diff da branch vs a base, não só o último commit.
- Compare com: PBI ativo (CAs, escopo, fora de escopo, Steps); `.spec/1-overview.md`; `.spec/2-architecture.md`; dumps em `.spec/docs/` citados pelo PBI; `.spec/adrs/`; `.spec/0-roadmap.md`.
- Não invente requisito que não esteja no PBI/spec. Ambiguidades de produto ≠ bug.
- Não escreva código, não abra PR, não rode e2e, não rode `qa`. Suíte unitária só se a conclusão depender de confirmar uma falha citada (comando documentado no repo).
- Resposta obrigatória, nesta ordem:
  1. Veredito: `Atende` | `Atende com ressalvas` | `Não atende`.
  2. Tabela: item (CA / Step / contrato) | status | evidência (arquivo/trecho) | bloqueia merge? (sim/não).
  3. Checklist:
     - [ ] Requisitos e Steps cobertos? (se não, quais)
     - [ ] Cada CA do PBI está `- [x]` sse o diff realmente atende? (CA feito no código mas ainda `- [ ]`, ou `[x]` sem evidência)
     - [ ] Regras de negócio e erros idiomáticos da stack?
     - [ ] Payloads / status HTTP / contratos fiéis ao `.spec/`?
     - [ ] `qa` Limpo no PBI?
     - [ ] `e2e-evidence` rodou ou skip justificado?
     - [ ] Suíte unitária/integração sem regressão óbvia no diff?
  4. Pontos positivos (curto). Gaps com severidade alta/média/baixa.
  5. O que bloqueia merge vs follow-up.

## Depois que o revisor voltar

- Grave `## Review` no PBI com o veredito, a tabela e os bloqueios (crie ou substitua). Atribua: revisor **isolado** (não “self-review”).
- Se o revisor apontar CA atendido ainda `- [ ]` (ou o contrário), **corrija só os checkboxes de CA** no PBI para bater com o relatório — não mexa em código.
- **Não atende** ou ressalva que **bloqueia merge:** resumo no chat do que corrigir; não escreva texto de PR como se estivesse pronto; não implemente a correção aqui (volta `exec-step` / `qa` conforme o caso).
- **Atende**, ou **Atende com ressalvas** só de follow-up: ao final do PBI, **Título** e **Descrição** de PR, **sempre em português** (resumo, motivação, comandos testados), alinhados ao relatório — sem contradizê-lo. Não coloque id/nome de PBI do `.spec/` no título (são locais). Identificação original de tracker só se o PBI já a registrar e o time rastrear a PR por ela.
- **Não** mova o PBI para `archive/` aqui. Depois do **merge**, skill `archive-pbi`.

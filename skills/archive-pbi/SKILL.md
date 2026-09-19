---
name: archive-pbi
description: >-
  Depois do merge da PR, move o PBI ativo de .spec/features/ para
  .spec/features/archive/ e atualiza o índice em backlog.md. Use quando o
  usuário disser que a PR mergeou, pedir /archive-pbi, fechar o PBI ou
  liberar features/ para o próximo item. Não planeja, não implementa, não
  abre PR.
disable-model-invocation: true
---

# archive-pbi

Fecha o ciclo de vida do PBI **depois do merge**. Libera `.spec/features/` para o próximo item. Não altera código de aplicação.

Leia também [../sdd-context/SKILL.md](../sdd-context/SKILL.md).

## Quando

- O usuário afirmou que a PR deste PBI **já mergeou**, ou pediu explicitamente arquivar/fechar o PBI.
- Se a PR **não** mergeou: não arquive. Diga para usar `verify` (pré-PR) ou esperar o merge.

## Pré-checagem

1. PBI alvo: o único `PBI-*.md` em `.spec/features/` (não em `backlog/` nem `archive/`). Se houver **zero** ou **mais de um**, pare e descreva o que encontrou.
2. Não arquive se ainda houver Step `- [ ]` no plano, `## QA Report` diferente de `Limpo` (inclui `Obsoleto`), `## Evidências e2e` / `## Review` com Status `Obsoleto`, ou `## Review` com veredito `Não atende` / ressalva que bloqueia merge — salvo o usuário mandar arquivar mesmo assim (registre o desvio no índice).
3. Não crie código, testes, PR, evidência e2e nem reescreva o PBI além do necessário para o movimento.

## Movimento

1. Destino: `.spec/features/archive/<mesmo-nome-de-arquivo>`.
2. Se o destino já existir, pare (não sobrescreva).
3. Mova o arquivo (não copie). Crie `archive/` se precisar.
4. Em `.spec/features/backlog.md`, coluna **Pasta atual** (ou equivalente) deste ID → `archive/`. Ajuste o link relativo para `archive/PBI-….md`.
5. Não mova outros PBIs. Não puxe o próximo do `backlog/` (isso é `plan-task`).
6. Não commite a menos que o usuário peça. `.spec/` pode ser local: o movimento ainda é obrigatório para a invariante “um PBI em `features/`”.

## Encerramento

- Caminho antigo → caminho novo.
- Confirme: `features/` sem `PBI-*.md`.
- Próximo: escolher item em `.spec/features/backlog/` e `plan-task`. Não rode `plan-task` daqui.

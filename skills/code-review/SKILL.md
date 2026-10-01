---
name: code-review
description: >-
  Code review de PR de pares: lê o arquivo do PBI (contexto), não altera o
  conteúdo original, grava o relatório numa seção Review no mesmo arquivo.
  Aceita um repo ou repos irmãos em clones locais (o usuário faz o pull).
  Use quando o usuário pedir code-review e passar o path do PBI (ex.
  spec/reviews/<id>.md) e o(s) path(s) dos repositórios. Não é o portão
  verify. Não usa gh. Não despeja o relatório no chat.
disable-model-invocation: true
---

# code-review

Ajuda **você** a revisar o código de outra pessoa. Não implementa, não aprova merge sozinho, não substitui `verify`.

## Sessão (o modelo é escolha sua)

Recomendado: chat novo, **separado** de quem implementou. A skill não troca o picker; **você escolhe o modelo** e não fixa vendor.

## Alvo

1. **Arquivo do PBI** (obrigatório): path que o usuário passar (ex.: `spec/reviews/<id>.md`). É contexto **e** destino do relatório. Sem path: **pare** e peça o arquivo — não invente pasta e não cole o relatório no chat.
2. **Repositório(s) locais** (obrigatório): o usuário nomeia ou passa o path absoluto/relativo de cada clone **já com pull** da branch a revisar. **Não** use `gh`. Diff via `git` **nesse** diretório vs a base que o usuário disser (`main` se omitir). **Todo** o diff da branch, não só o último commit.
   - **Um repo:** revise só ele.
   - **Repos irmãos** (mesmo PBI / entrega): o usuário lista **todos** os paths (ex.: `../api` + `../worker`). Não invente o irmão. Se o PBI mencionar outro serviço e o path não veio, **pare** e peça o clone — ou registre gap explícito se o usuário mandar seguir só com o que tem.
3. Critérios: o bloco original do PBI nesse arquivo (objetivo, CAs, escopo). `.spec/` local só como complemento. Não invente requisito.
4. Não precisa o autor ter seguido SDD.

## Diffs em mais de um repo

- Em **cada** path: `git fetch` só se o usuário pedir (o pull é dele). Depois `git diff <base>...HEAD` (ou o range que ele indicar) **com cwd nesse clone**.
- Path inexistente, working tree suja demais para julgar, ou clone na branch errada: **pare** e diga o que falta. Não chute o outro lado.
- Audite o **contrato entre os repos** (payload, fila, ordem de deploy, feature flag, compatibilidade). Um lado “certo” com o outro quebrado = veredito global `Peço mudanças` (ou ressalva que bloqueia), mesmo que um repo isolado pareça ok.

## Auditoria

- Correção vs o PBI do arquivo (CAs, escopo, fora de escopo) e vs o que o diff entrega. O PBI prevalece se divergir — registre na seção Review.
- Por repo: regressão, testes do recorte, erros idiomáticos **daquela** stack (comando de teste só se a conclusão depender).
- Contratos (API, fila, persistência, env) e “fora de escopo” se o PBI/diff disser.
- Segurança óbvia no diff. Sem caçada fora do recorte.
- Ambiguidade de produto ≠ bug.

## O que pode e o que não pode no arquivo

```markdown
# PBI …

…conteúdo original…
```

**Não toque** em nada acima da seção de review (título, metadados, objetivo, CAs, etc.).

No **final** do arquivo, crie ou **acrescente** (nunca apague reviews antigas):

```markdown
# Review

## <data-hora ISO> — <resumo dos repos>

- **Veredito global:** Aprovo | Aprovo com ressalvas | Peço mudanças
- **Repos:** path ou nome (`../api`, `../worker`)
- **Branch / base:** …

### `../api` (ou o nome que o usuário passou)

| Item | Status | Evidência (arquivo) | Comentário sugerido neste repo | Bloqueia? |
|---|---|---|---|---|
| … | ok / parcial / problema | path | português, para colar na review **deste** repo | sim/não |

### `../worker`

(mesma tabela)

### Cruzamento

Contrato entre os repos; ordem de merge/deploy; CA que só fecha com os dois lados.

Fluxo ponta a ponta; o que está bem; bloqueios vs nit.
```

Um repo só: omita o segundo `###` e a seção Cruzamento (ou deixe Cruzamento com “n/a”).

Se `# Review` já existir, só adicione um novo `## <data-hora>…` no fim dessa seção.

## Chat

**Não** cole o relatório no chat. Uma linha: veredito global + path do arquivo (+ quantos repos cobertos).

## Proibido

- Escrever código de correção (a menos que o usuário peça um patch à parte).
- `verify`, `exec-step`, abrir PR, merge, `archive-pbi`.
- Editar o conteúdo original do PBI; apagar ou reescrever reviews anteriores.
- Inventar CA/PBI ou inventar repo irmão que o usuário não passou.
- Usar `gh` (nem `pr view` / `pr diff` / `pr comment`).
- Despejar tabela/veredito longo no chat no lugar de gravar no arquivo.
- Aprovar um lado e ignorar o contrato com o irmão quando os dois clones foram pedidos.

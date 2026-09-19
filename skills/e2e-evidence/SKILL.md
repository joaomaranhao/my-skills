---
name: e2e-evidence
description: >-
  Roda e2e contra o ambiente vivo e monta pacote de evidências em
  .spec/e2e/evidence/<PBI-id>/ para a pessoa de QA. Use depois de qa, antes de
  verify, quando o usuário pedir /e2e-evidence ou evidência e2e. Não escreve o
  plano oficial de testes e não substitui print de GUI por log/JSON.
disable-model-invocation: true
---

# e2e-evidence

Roda os testes de ponta a ponta contra o ambiente vivo e monta um **pacote de evidências** para a pessoa de QA colar no plano de testes do time. Esta skill **não** escreve o plano de testes oficial.

**Quando rodar:** uma vez por PBI, **depois** de `qa` com `## QA Report` **Status: Limpo** (nenhum Step anexado pendente) e **antes** de `verify`. Se o QA anexou Steps ou a suíte falhou, pare e diga para `exec-step` + `qa` de novo.

**Skip justificado = sucesso deste portão** (não é falha, não invente suíte): sem recorte HTTP/fila; skip planejado no `plan-task`; ambiente down; repo sem runner. Grave **Status: `Skip justificado`** + **Motivo** em `## Evidências e2e` e siga para `verify`. Só execute a suíte quando o runner **deste** repo existir e o ambiente estiver no ar.

Como subir e como apontar a URL/host: Makefile, README, `.env.example` ou o PBI — não assuma um target ou path de health deste repositório.

**Evidência:** artefato reproduzível no pacote:

- `run.log` — stdout/stderr completo do comando e2e documentado no repo.
- **Transcrição da interface** — para cada caso do recorte no `pack.md` (e, se útil, `transcript/<caso>.txt`): método + path (ou equivalente gRPC/fila), status/código de resultado, e o corpo relevante da **request/response** (JSON/texto) já mascarado, máx. ~30 linhas por caso. Fonte: o próprio output do runner ou o log HTTP que o teste já imprime. Não é screenshot; não abra browser/Swagger só para “transcrever”.
- Dump do estado persistido (`db.json` etc.) filtrado pelos IDs da corrida, se o CA depender.

Screenshot de GUI só se o usuário pedir ou se o CA for de UI.

Leia também [../sdd-context/SKILL.md](../sdd-context/SKILL.md).

1. **Descobrir o recorte neste repo (não copiar outro projeto):**
   - PBI ativo (`.spec/features/<PBI-id>.md`): CAs, contratos, dumps em `.spec/docs/` citados.
   - Arquitetura (`.spec/2-architecture.md`): HTTP/gRPC, filas, banco.
   - Como este repo declara e2e: `Makefile`, `e2e/`, `testdata/`, tags `e2e`, scripts `package.json`, etc. Use **o comando que o próprio repo documenta**. Não invente runner (nem `go test -tags=e2e`) se não existir aqui.
   - Catálogo de casos versionados (commitados): o diretório que o runner já usa. Não invente pasta nova.

2. **Mapa CA → caso:**
   - Tabela no chat e no pacote: `CA` → caso (nome/arquivo) → operação esperada (método/path ou equivalente) → coberto / **gap para a pessoa de QA**.
   - Gaps (outro sistema, senha, app, parceiro indisponível) = “não automatizado neste repo”. Não crie caso e2e novo nesta skill, salvo o usuário pedir.

3. **Execução:**
   - Se o skip já estiver justificado no PBI (sem recorte, skip planejado, sem runner): **não** invente suíte. Preencha `## Evidências e2e` e o `pack.md` mínimo com SKIP e o motivo. Portão concluído.
   - Caso contrário: prove que o ambiente responde (health/live do **contrato deste** serviço). Se estiver down, **pare**: **Status: `Skip justificado`**, Motivo `ambiente indisponível`; preencha o pacote mínimo. Isso conclui o portão (não use outro Status).
   - Rode **só** a suíte e2e descoberta no passo 1 — não misture com a suíte unitária nem com o checker de corrida do `qa`.
   - Grave a saída em `run.log`. Extraia dali (ou do que o runner já loga) a **transcrição** de cada caso para o `pack.md` / `transcript/` — ver definição acima.

4. **Estado persistido (se o PBI/CA depender):**
   - Identifique o store na arquitetura (Mongo, Postgres, etc.) e a URI/env **deste** repo (`.env`, secrets), **sem** gravar a URI no pacote.
   - Exporte só registros da corrida, chaveados pelos IDs que o e2e ou o PBI usam (correlation id, aggregate id, … — os nomes vêm do código/spec daqui).
   - Saída: `db.json` (ou um arquivo por aggregate) no pacote. Cliente CLI do store (`mongosh`, `psql`, …) se já for o hábito do repo.
   - Store indisponível: skip no `pack.md`. Não substitua por screenshot de GUI.
   - No `pack.md`, destaque campos que os CAs citam, já mascarados.

5. **Pacote (artefato local, não git):**
   - Diretório: `.spec/e2e/evidence/<PBI-id>/`.
   - `pack.md`: data/hora (fuso do spec ou do projeto), base URL/host **sem** credencial; tabela CA ↔ caso ↔ PASS/FAIL/SKIP; para cada caso do recorte: operação, status/resultado vs esperado, trecho relevante da resposta (máx. ~30 linhas); o que a pessoa de QA ainda valida à mão.
   - **PII e segredo:** não copie `Authorization`, tokens, senhas, PEM, documentos completos. Máscara (`***`, últimos 4 dígitos no máximo).
   - Não commite o pacote nem o `.spec/`. Não altere testes nem o catálogo e2e nesta skill (`qa` ou um Step).

6. **Registro no PBI:**
   - Seção `## Evidências e2e` (criar ou substituir). **Status** (só estes):
     - `Sucesso` — suíte rodou e os casos do recorte passaram (gaps humanos ok).
     - `Falhas` — suíte rodou com falha no recorte.
     - `Skip justificado` — não rodou (ou não pôde): Motivo obrigatório (`skip planejado` | `sem runner` | `sem recorte HTTP/fila` | `ambiente indisponível` | outro curto).
     - `Obsoleto` — marcado por `exec-step`/`replan` após mudança; não é sucesso deste portão.
   - Também: **Motivo** (se Skip/Obsoleto); **Comando** realmente executado (ou “nenhum”); **Pacote** `.spec/e2e/evidence/<PBI-id>/` se houver artefato; **Gaps para o plano de testes (humano)**.
   - `Skip justificado` **não** bloqueia `verify`. `Falhas` e `Obsoleto` bloqueiam até nova passagem válida.
   - No chat: a mesma tabela + caminho do pacote. Não rode `verify` daqui.

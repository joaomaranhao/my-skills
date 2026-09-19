---
name: structure-spec
description: >-
  Quebra um arquivo de especificação monolito na estrutura canônica de .spec/
  (overview, architecture, roadmap, ADRs, backlog de PBIs). Use quando o usuário
  pedir bootstrap de .spec/, /structure-spec, ou extrair PBIs de um monolito.
  Não altera código de aplicação.
disable-model-invocation: true
---

# structure-spec

Quebra um arquivo de especificação monolito na estrutura canônica de `.spec/`. Não altera código de aplicação.

O usuário informa o caminho do monolito (ou cola o conteúdo). A saída vive **somente** em `.spec/`. Não crie `spec/`, `.specs/` nem arquivos fora dessa pasta.

Leia também [../sdd-context/SKILL.md](../sdd-context/SKILL.md).

## Passadas

Monolito curto: uma passada (passos 1–6 abaixo).

Monolito grande (épico + muitos PBIs + dumps, ou o contexto não cabe com segurança numa leitura): **não** extraia tudo num shot. Confirme entre passadas, salvo o usuário pedir “faz tudo”:

1. Árvore `.spec/` + `1-overview.md`
2. `2-architecture.md` + `adrs/`
3. `features/backlog/` + `features/backlog.md`
4. `.spec/docs/` (só dumps que o monolito trouxe)

Cada passada redistribui o recorte correspondente; não invente o que ainda não leu.

1. **Árvore-alvo (criar se não existir):**

   ```text
   .spec/
   ├── 0-roadmap.md
   ├── 1-overview.md
   ├── 2-architecture.md
   ├── docs/
   │   └── <parceiro-ou-ferramenta>/
   ├── adrs/
   │   └── <n>-<slug>.md
   ├── e2e/
   │   └── evidence/
   │       └── .gitkeep
   ├── features/
   │   ├── backlog.md
   │   ├── backlog/
   │   │   └── PBI-<id>.md
   │   └── archive/
   │       └── .gitkeep
   ```

   - `features/` na raiz de features **não** recebe PBI nesta etapa, salvo o usuário indicar explicitamente um item já em implementação.
   - No bootstrap, todos os PBIs extraídos vão para `.spec/features/backlog/`.
   - `.spec/features/archive/` e `.spec/e2e/evidence/` recebem só `.gitkeep` se estiverem vazias (pacotes de evidência vêm depois, via `e2e-evidence`).
   - Se o repo ainda não ignora o memory bank, **sugira** no chat (não force commit) acrescentar ao `.gitignore` do consumidor:

     ```gitignore
     .spec/
     ```

2. **O que vai em cada documento:**

   | Arquivo | Conteúdo |
   |---|---|
   | `1-overview.md` | Épico, escopo (in/out), definições, jornadas, requisitos (RF, HF, RT, UX), tabela de features, referências. Sem critérios de aceite de PBI e sem plano de fases detalhado. |
   | `2-architecture.md` | Limites do sistema, C4/diagramas, contratos HTTP, persistência, estados, regras de aceite técnicas, observabilidade. Sem roadmap de entrega. Contratos de sistemas integrados: aponte para `.spec/docs/<sistema>/` em vez de colar dumps inteiros. |
   | `docs/<parceiro-ou-ferramenta>/` | Dumps e contratos de sistemas que este repositório integra. Só o recorte usado aqui. Criar a subpasta quando o monolito ou o usuário trouxer o dump; não inventar OpenAPI. |
   | `0-roadmap.md` | Ordem de fases, dependências, marcos de saída, riscos transversais. Aponta para overview, arquitetura, backlog e ADRs. Não duplica critérios de aceite. |
   | `adrs/` | Uma ADR por decisão (contexto, decisão, consequências). Numerar `1-<slug>.md`, `2-<slug>.md`. Se o monolito não tiver ADR formal, extraia decisões explícitas; não invente ADRs. |
   | `features/backlog.md` | Convenção de pastas (`backlog/` → `features/` → `archive/`), índice de PBIs com links, IDs originais, features sem PBI e lacunas. |
   | `features/backlog/PBI-*.md` | Um PBI por arquivo: metadados, objetivo, comportamento, critérios de aceite. |

3. **PBIs (um arquivo por item):**

   - Extraia cada PBI, PIB ou item de entrega rastreável do monolito.
   - Normalize IDs canônicos (`PBI-01`, `PBI-02`, …) e registre a identificação original no arquivo e no índice.
   - Nome do arquivo = ID canônico + `.md` (ex.: `PBI-02.md`).
   - Estrutura mínima do arquivo:

     ```markdown
     # PBI-<id> — <título>

     - **Feature:** F0n — <nome>.
     - **Identificação original:** …
     - **Atende:** requisitos cobertos.
     - **Depende de:** …
     - **Fora deste item:** … (se houver)

     ## Objetivo
     …

     ## Critérios de aceite
     - [ ] CA01 — …
     ```

   - Preserve critérios de aceite, tabelas e regras do original. Não invente PBIs nem CAs para features só mencionadas sem recorte. Documente isso em `backlog.md` como gap.
   - Não escreva `## Plano de Execução (Steps)` nesta etapa.

4. **Cruzamento e rastreabilidade:**

   - Overview aponta para backlog, roadmap, arquitetura e ADRs.
   - Roadmap aponta para overview, arquitetura, `features/backlog.md` e `features/backlog/`.
   - Cada PBI pode apontar para âncoras de `2-architecture.md` quando citar contratos, e para `.spec/docs/<parceiro>/` quando o dump for a fonte do payload/path.
   - Links relativos corretos a partir da pasta de cada arquivo.
   - No índice, coluna **Pasta atual** = `backlog/` para itens recém-extraídos.

5. **Regras de extração:**

   - **NÃO escreva código, testes nem altere o catálogo de skills.**
   - Não descarte conteúdo de negócio: redistribua. Se algo não couber, coloque em lacunas do `backlog.md` ou em “Decisões e artefatos pendentes” da arquitetura.
   - Corrija inconsistências de nomenclatura (PBI vs PIB, IDs repetidos) no canônico e preserve o original.
   - Se `.spec/` já existir, **não sobrescreva** sem listar o que seria substituído e pedir confirmação, salvo o usuário pedir reescrita explícita.
   - Português do monolito: mantenha o idioma da origem.

6. **Encerramento (checklist):**

   - [ ] Todo PBI extraído está em `features/backlog.md` com **Pasta atual** = `backlog/` e link relativo válido.
   - [ ] CAs: os do monolito estão nos arquivos de PBI; nenhum CA inventido; omissão vai para lacunas do `backlog.md` (não some em silêncio).
   - [ ] ADRs só de decisões explícitas no monolito (zero ADR inventida).
   - [ ] Nenhum OpenAPI/dump inventido; dumps só em `docs/<parceiro>/`.
   - [ ] Links relativos a partir da pasta de cada arquivo.
   - [ ] `.spec/e2e/evidence/.gitkeep` existe; chat lembrou `.gitignore` com `.spec/` se ainda não estiver.
   - Liste os arquivos criados, quantos PBIs foram para `backlog/` e quais features ficaram sem PBI.
   - Não mova nada para `features/` nem para `archive/` a menos que o usuário peça.

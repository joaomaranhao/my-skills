# my-skills

Single source of truth das skills de Spec-Driven Development (SDD). Os projetos **não copiam** o conteúdo: apontam para cá via symlink.

Origem: commands e a rule SDD de um repo de produto. Commands viraram skills (portões explícitos). A rule `alwaysApply` virou `sdd-context` + rule copiada no projeto.

## Layout

```text
skills/
├── sdd-context/      # Memory bank .spec/, YAGNI, qualidade (auto)
├── sdd/              # Qual skill/fase usar agora
├── structure-spec/   # Bootstrap .spec/ a partir de um monolito
├── plan-task/        # PBI → Steps; sem código
├── exec-step/        # Um Step + testes + mensagem de commit
├── replan/           # Spec drift: atualiza .spec/ e o plano
├── qa/               # Analisa suíte; gaps viram Steps (sem código)
├── e2e-evidence/     # Ambiente vivo → pacote de evidências
├── verify/           # Revisor isolado vs .spec + texto do PR
├── loop-engineering/ # Orquestra plan-task→verify + commits; sem PR
├── archive-pbi/      # Depois do merge: features/ → archive/
└── code-review/      # Review de PR de pares (fora do pipeline)
scripts/
└── link-to-project.sh
```

## Pipeline

```text
structure-spec   bootstrap do .spec a partir de um monolito (raro)
plan-task        PBI → Steps; sem código
exec-step        um Step + testes + mensagem de commit (você commita)
replan           spec drift: PBI/arquitetura/ADR + Steps; sem código
qa               analisa o PBI; suíte atual; gaps → Steps novos
e2e-evidence     ambiente vivo: suíte e2e + transcrição + dump do store → .spec/e2e/evidence/<PBI-id>/
verify           revisor isolado vs .spec + texto do PR
loop-engineering orquestra plan-task→verify com commit por Step; sem PR
archive-pbi      depois do merge: PBI → archive/
```

Fora do pipeline: `code-review` — PR de **pares** (não é o `verify` do que você implementou). Chat novo, modelo distinto do que costuma implementar; skill `code-review`.

Perdido na fase SDD? skill `sdd`.

## Fluxo típico (Cursor)

As skills **não trocam** o modelo do chat. Você abre a sessão no picker e invoca a skill.

1. **Chat novo → Claude Sonnet** → `plan-task` (ou `replan` se for drift de spec). Aprove o plano. Não implemente neste chat.
2. **Chat novo → Grok** (ex.: 4.6) → `exec-step` um a um, ou `loop-engineering` se o plano já estiver no PBI e você pediu o loop (commit por Step; sem PR).
3. **`qa` e `verify`** → revisor **isolado**: subagente com modelo **diferente** do implementador (sem `inherit`), ou chat novo só com `qa`/`verify`. A skill não fixa vendor.
4. Depois do merge da PR (você abre a PR): chat qualquer → `archive-pbi`.

Review de colega: **chat novo** (modelo ≠ implementador habitual) → `code-review` (não misture com `verify`).

Não rode `verify`/`qa` com `inherit` nem no mesmo histórico/modelo que implementou. `loop-engineering` sem plano e fora do Sonnet **para** e pede o chat de `plan-task`.

## Consumo no projeto

A partir deste repositório:

```bash
# todos os harnesses conhecidos (cursor, opencode, antigravity, claude-code, codex)
./scripts/link-to-project.sh /caminho/do/projeto

# só alguns
./scripts/link-to-project.sh --harness cursor,opencode /caminho/do/projeto
```

O canônico continua em `skills/`. O script só cria **symlink** (e hooks always-on) no consumidor:

| Harness | Skills | Always-on |
|---|---|---|
| Cursor | `.cursor/skills/` | cópia `.cursor/rules/sdd-when-spec.mdc` |
| OpenCode | `.opencode/skills/` | bloco em `AGENTS.md` |
| Antigravity | `.agents/skills/` | bloco em `AGENTS.md` |
| Claude Code | `.claude/skills/` | bloco em `AGENTS.md` |
| Codex | `.agents/skills/` (mesmo path que Antigravity) | bloco em `AGENTS.md` |

Aliases de harness: `claude`, `claudecode` → `claude-code`.

Antigravity e Codex compartilham `.agents/skills/`; o script linka uma vez. `AGENTS.md` ganha um bloco delimitado (`<!-- sdd-when-spec -->`); se o arquivo já existir, o bloco é inserido ou atualizado — o resto do arquivo permanece.

Novo harness: uma linha em `scripts/harnesses.conf` (`id`, pasta de skills, tipo de hook).

Rode o script de novo quando o catálogo ganhar skill ou o texto da âncora mudar.

Não commite os destinos se o SDD for só seu. No consumidor:

```gitignore
.spec/
.cursor/skills/
.cursor/rules/sdd-when-spec.mdc
.opencode/skills/
.agents/skills/
.claude/skills/
```

Se `AGENTS.md` for só o bloco SDD, ignore-o também; se o time já usa `AGENTS.md`, commite o arquivo e deixe o bloco (ou não) a seu critério.

Não instale a rule SDD em `~/.cursor/rules/`: `alwaysApply` global + cópia no projeto duplica o texto.

## Harness

O corpo das skills não depende de slash commands do Cursor. No Cursor Agent, invoque pelo **nome da skill**. Outros harnesses que leem `SKILL.md` podem apontar para o mesmo diretório.

## Memory bank (`.spec/`)

Fluxo **particular**: `.spec/` não vai para o git (o time não precisa seguir SDD). No repo consumidor, ignore a pasta:

```gitignore
.spec/
```

O catálogo e2e versionado do produto (o que o runner já usa) continua no git.

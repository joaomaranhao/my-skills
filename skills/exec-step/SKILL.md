---
name: exec-step
description: >-
  Executa estritamente um Step do plano aprovado no PBI ativo, com testes
  unitários do recorte e mensagem Conventional Commits. Use quando o usuário
  pedir para implementar um Step, /exec-step, ou marcar um Step do plano. Não
  faz QA do PBI inteiro, e2e nem abre PR. Não commita a menos que o usuário peça.
disable-model-invocation: true
---

# exec-step

Executa estritamente um Step específico do plano aprovado na seção `## Plano de Execução (Steps)` do arquivo do PBI.

Leia também [../sdd-context/SKILL.md](../sdd-context/SKILL.md).

## Modelo (sessão — manual)

Recomendado: **Grok** (ex.: 4.6). A skill não troca o picker: chat novo, escolha Grok, invoque `exec-step`. Não implemente no mesmo chat em que rodou `plan-task` em Sonnet.

1. **Foco e Escopo Fechado:**
   - Execute **APENAS** o Step indicado pelo usuário.
   - Não adicione abstrações desnecessárias, interfaces prematuras ou código focado em Steps futuros (princípio YAGNI/KISS).
   - Respeite rigorosamente as decisões em `.spec/adrs/`, os contratos em `.spec/2-architecture.md`, o PBI ativo em `.spec/features/<PBI-id>.md` e os dumps em `.spec/docs/` quando o Step/PBI os citar. Em conflito, PBI e arquitetura prevalecem sobre o dump.
   - **Spec drift:** se no meio do Step a arquitetura, o PBI, um CA ou uma ADR estiver errada/incompleta em relação ao que precisa ser feito — **pare**. Não misture correção de spec com código. Não marque o Step `- [x]`. Peça `replan` e descreva o drift em uma frase.

2. **Implementação & Testes Unitários:**
   - Implemente ou modifique o código de produção estritamente necessário para cumprir o Step.
   - Crie ou atualize os testes unitários/de componente diretamente afetados por este Step.
   - Garanta boa cobertura de casos de borda e tratamento de erros idiomático na linguagem **deste** repo.
   - Os testes derivam dos critérios de aceite e verificam os resultados definidos na especificação — eles nunca espelham a implementação.

3. **Validação Ativa via Terminal:**
   - Rode a suíte unitária **que o repo documenta** (Makefile, `package.json`, README). Não assuma linguagem nem comando.
   - Caso algum teste falhe, corrija imediatamente antes de dar o Step por concluído.
   - Não rode `qa` (adversários no PBI inteiro / checker de corrida da stack) nesta skill.

4. **Conclusão, registro e mensagem de commit:**
   - Marque o checkbox do Step como concluído (`- [x]`) no arquivo `.md` do PBI ativo (`.spec/features/<PBI-id>.md`).
   - Em `## Critérios de aceite`, marque `- [x]` só nos CAs que **este Step fecha por completo** (os listados no Step, se o plano tiver essa lista). CA parcial ou ainda dependente de Step futuro permanece `- [ ]`.
   - **Invalidação de portões:** se o PBI já tiver `## QA Report` com Status `Limpo`, `## Evidências e2e` (qualquer Status de corrida/skip concluído) ou `## Review` pré-PR, altere o **Status** dessas seções para `Obsoleto` e acrescente uma linha `Motivo: Step <n> alterou código/plano após o portão`. Não apague o corpo antigo. Próximo portão válido volta a ser `qa` (depois e2e/`verify` conforme o pipeline).
   - Analise o `git diff` (e arquivos tocados nesta sessão) e elabore a mensagem em **Conventional Commits**, **sempre em inglês**:
     - Tipos: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `style`.
     - Escopo entre parênteses = módulo/domínio do **código** (ex.: `feat(auth): persist session token`). **Não** use id nem nome de PBI do `.spec/` (`PBI-01`, título do arquivo, etc.) — esses ids são locais e não vão para o git.
     - Primeira linha imperativa, no máximo 72 caracteres.
   - Grave essa mensagem no PBI, no Step correspondente (`**Commit:**` ou logo abaixo do Step). Se o plano já tinha um `Commit:` rascunhado, atualize para refletir o diff real.
   - **Não** execute `git commit` nesta skill, a menos que o usuário peça o commit nesta mensagem.
   - Resposta final concisa:
     - Arquivos criados/alterados.
     - CAs marcados neste Step (ids).
     - Resultado dos testes unitários.
     - Comando pronto para o usuário (HEREDOC se a mensagem tiver várias linhas):

       ```bash
       git commit -m "feat(auth): persist session token"
       ```

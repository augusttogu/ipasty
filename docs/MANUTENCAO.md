# Guia do mantenedor

Como o repositório está organizado para que **qualquer pessoa possa baixar e sugerir mudanças**, mas **só entre na versão principal o que for revisado e aprovado**.

## Quem pode fazer o quê

| Pessoa | Baixar e usar | Abrir issue | Enviar pull request | Aprovar e juntar na `main` |
|---|:-:|:-:|:-:|:-:|
| Qualquer pessoa | ✅ | ✅ | ✅ (pelo fork) | ❌ |
| Colaborador com permissão **Write** | ✅ | ✅ | ✅ (direto em branches) | ❌ — precisa de aprovação |
| Mantenedor (`CODEOWNERS`) | ✅ | ✅ | ✅ | ✅ |
| Dono (você) | ✅ | ✅ | ✅ | ✅ e pode ignorar as regras em emergências |

## Configuração inicial (uma vez)

O script [`tools/setup-github.sh`](../tools/setup-github.sh) aplica tudo de uma vez com o GitHub CLI:

```bash
brew install gh        # ou baixe em https://cli.github.com
gh auth login
./tools/setup-github.sh
```

Ele configura:

- **Descrição, site e tópicos** do repositório.
- **Issues** e **Discussions** ligados. Wiki e Projects desligados para manter tudo no código.
- **Somente squash merge**, com o branch apagado depois do merge.
- **Regra de proteção da `main`**:
  - ninguém envia commits direto; tudo entra por pull request;
  - **1 aprovação** obrigatória, que precisa vir de quem está no `CODEOWNERS`;
  - aprovações caem se o autor enviar novos commits;
  - todas as conversas precisam estar resolvidas;
  - a **compilação** (GitHub Actions) precisa passar;
  - não dá para apagar a `main` nem reescrever o histórico dela;
  - **administradores podem ignorar a regra**, para você conseguir juntar os seus próprios PRs (o GitHub não deixa ninguém aprovar o próprio PR).

### Fazendo pelo site, se preferir

1. **Settings → General**: em _Pull Requests_, deixe só **Allow squash merging** e ligue **Automatically delete head branches**.
2. **Settings → Rules → Rulesets → New branch ruleset**:
   - _Target_: **Default branch**; _Enforcement_: **Active**; _Bypass list_: **Repository admin**.
   - Marque **Restrict deletions**, **Block force pushes**, **Require a pull request before merging** (1 aprovação, _Dismiss stale approvals_, _Require review from Code Owners_, _Require conversation resolution_) e **Require status checks to pass** com o check **Compilar**.
3. **Settings → Actions → General**: em _Fork pull request workflows_, deixe **Require approval for first-time contributors**.

## Adicionar pessoas ao projeto

**Settings → Collaborators → Add people**, e escolha o papel:

- **Write**: pode criar branches e abrir PRs direto no repositório, mas o merge na `main` continua precisando de aprovação.
- **Maintain**: também gerencia issues, labels e releases.

Para que alguém também possa **aprovar** PRs, adicione o usuário dele no [`.github/CODEOWNERS`](../.github/CODEOWNERS).

Pelo terminal:

```bash
gh api -X PUT repos/augusttogu/ipasty/collaborators/USUARIO -f permission=push
```

## Revisando um pull request

1. Leia a descrição e as mudanças em **Files changed**.
2. Espere a verificação **Compilar** ficar verde.
3. Para testar no seu Mac: `gh pr checkout NÚMERO && ./build.sh`.
4. **Review changes → Approve** (ou **Request changes** com comentários).
5. **Squash and merge**.

Na primeira contribuição de alguém, o GitHub pede que você aprove a execução das Actions. Confira se o PR não altera arquivos em `.github/workflows` de forma suspeita antes de aprovar.

## Lançando uma versão

1. Atualize o arquivo `VERSION` (por exemplo, `1.1.0`).
2. No `CHANGELOG.md`, mova os itens de **Não lançado** para uma nova seção com a versão e a data.
3. Abra um PR com essas mudanças e faça o merge.
4. Crie a tag na `main` atualizada:

```bash
git checkout main && git pull
git tag v1.1.0
git push origin v1.1.0
```

O workflow **Release** compila o app universal (Apple Silicon + Intel), gera o `Ipasty-1.1.0.zip` e publica a release com as notas do CHANGELOG. Confira em **Actions** e depois em **Releases**.

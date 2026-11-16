# Como contribuir com o Ipasty

Que bom que você quer ajudar! 💜 Toda contribuição conta: reportar um problema, sugerir uma ideia, melhorar um texto ou escrever código.

## Antes de começar

- Leia o [Código de Conduta](CODE_OF_CONDUCT.md).
- Procure nas [issues](https://github.com/augusttogu/ipasty/issues) se o assunto já foi discutido.
- Para mudanças grandes, **abra uma issue primeiro** e combine a ideia antes de programar. Assim ninguém perde tempo.

## Reportar um problema ou sugerir algo

Use os modelos em [Nova issue](https://github.com/augusttogu/ipasty/issues/new/choose):

- 🐛 **Relatar um problema**: diga a versão do macOS, a versão do Ipasty e os passos para reproduzir.
- 💡 **Sugerir uma melhoria**: explique o problema que a ideia resolve.

> Nunca cole conteúdo do seu histórico, chaves de API ou dados pessoais numa issue.

## Preparando o ambiente

Você só precisa de um Mac com macOS 14 ou mais novo e as Ferramentas de Linha de Comando da Apple:

```bash
xcode-select --install
git clone https://github.com/SEU-USUARIO/ipasty.git   # depois de fazer o fork
cd ipasty
./build.sh            # compila, instala em ~/Applications e abre
```

Outros comandos:

```bash
./build.sh --no-install   # só compila em build/Ipasty.app
./build.sh --zip          # gera dist/Ipasty-<versão>.zip (universal)
./tools/screenshots.sh    # regera os prints do README com dados de exemplo
```

## Organização do código

```
Sources/Ipasty/
├── main.swift         # App, barra de menus, atalho global, painel, colar
├── Clipboard.swift    # Histórico: modelo, armazenamento, monitor da área de transferência, cartão
├── Picker.swift       # Abas, favoritos e recentes, emojis, caracteres, kaomojis
├── Giphy.swift        # Integração com a API do GIPHY e GIF animado
├── Views.swift        # Interface (SwiftUI) de todas as abas
└── SystemData.swift   # Pasta de dados e leitura dos dados de emoji/caracteres do macOS
Resources/bundle/      # Arquivos que vão dentro do app (emoji-test.txt do Unicode)
tools/                 # Ícone, prints do README e imagem de capa
docs/                  # Instalação, manutenção, prints
```

Algumas regras do projeto:

- **Sem dependências externas.** Só frameworks da Apple (AppKit, SwiftUI, Carbon, CoreText, SQLite3).
- **Não use `@State`/`@Observable`.** As Ferramentas de Linha de Comando não trazem os plugins de macro do SwiftUI. Use `ObservableObject` com `@Published`.
- **Não copie arquivos da Apple para o repositório.** Dados do sistema devem ser lidos em tempo de execução (veja `SystemData.swift`).
- **Nunca coloque chaves de API no código.**
- Textos da interface em português do Brasil.

## Enviando um pull request

1. Faça um **fork** do repositório e crie um branch a partir de `main`:
   `git checkout -b melhoria/atalho-personalizado`
2. Faça as mudanças em commits pequenos e com mensagens claras, por exemplo: `Adiciona escolha de atalho nas preferências`.
3. Rode `./build.sh` e teste no seu Mac. Se a mudança for visual, rode `./tools/screenshots.sh` e confira as imagens.
4. Atualize o [CHANGELOG.md](CHANGELOG.md) na seção **Não lançado**.
5. Abra o pull request preenchendo o modelo. Mudanças visuais: inclua prints de antes e depois.

### Como a revisão funciona

- A branch `main` é **protegida**: ninguém envia código direto para ela.
- Todo pull request precisa:
  - passar na **compilação automática** (GitHub Actions);
  - ter **aprovação de um mantenedor** (veja [`.github/CODEOWNERS`](.github/CODEOWNERS));
  - ter todas as conversas da revisão resolvidas.
- Os pull requests entram por **squash merge**: cada um vira um único commit na `main`.

## Lançando uma versão (mantenedores)

Veja [docs/MANUTENCAO.md](docs/MANUTENCAO.md).

Obrigado por contribuir! 🙌

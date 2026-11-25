# Guia de instalação do Ipasty

← [Voltar ao README](../README.pt-BR.md) · [English](INSTALL.md)

## Requisitos

- **macOS 14 (Sonoma)** ou mais novo
- Mac com **Apple Silicon** (M1, M2, M3…) ou **Intel**

---

## Opção 1 — Baixar a versão pronta

### 1. Baixe

Na [página da última versão](https://github.com/augusttogu/ipasty/releases/latest), em **Assets**, clique em **`Ipasty-x.y.z.zip`**.

### 2. Instale

1. Abra o `.zip` (o Finder descompacta sozinho).
2. Arraste o **Ipasty.app** para a pasta **Aplicativos**.

### 3. Abra pela primeira vez

O Ipasty é gratuito e ainda não tem a assinatura paga da Apple (notarização). Por isso o macOS mostra um aviso como _"Não é possível verificar se o Ipasty está livre de malware"_ na primeira vez. Para liberar:

1. Clique duas vezes no Ipasty e feche o aviso (**Concluído**).
2. Abra **Ajustes do Sistema → Privacidade e Segurança**.
3. Role até a seção **Segurança**. Vai aparecer _"O Ipasty foi bloqueado…"_. Clique em **Abrir Mesmo Assim**.
4. Confirme com a sua senha ou o Touch ID.

Isso só precisa ser feito uma vez.

<details>
<summary>Alternativa pelo Terminal</summary>

```bash
xattr -dr com.apple.quarantine /Applications/Ipasty.app
open /Applications/Ipasty.app
```

O comando remove a marca de "baixado da internet" só do Ipasty.
</details>

> 🔍 Quer conferir o que está rodando? Todo o código está neste repositório, e cada versão é compilada automaticamente pelo GitHub Actions a partir dele (veja a aba **Actions**).

---

## Opção 2 — Compilar a partir do código

### 1. Instale as ferramentas da Apple

Não precisa do Xcode completo, só das Ferramentas de Linha de Comando:

```bash
xcode-select --install
```

### 2. Baixe e compile

```bash
git clone https://github.com/augusttogu/ipasty.git
cd ipasty
./build.sh
```

O app é compilado, instalado em `~/Applications/Ipasty.app` e aberto. Como foi você que compilou, o macOS não mostra o aviso de segurança.

### Para atualizar

```bash
cd ipasty
git pull
./build.sh
```

---

## Depois de instalar

### Permitir colar com um clique (Acessibilidade)

Na primeira vez, o Ipasty pede a permissão de **Acessibilidade** (só uma vez; ela continua valendo nas atualizações):

1. **Ajustes do Sistema → Privacidade e Segurança → Acessibilidade**.
2. Ative o **Ipasty** (se não estiver na lista, clique em **+** e escolha o app em Aplicativos).

Sem essa permissão, clicar num item só copia. Aí é só colar com <kbd>⌘V</kbd>.

### Ativar os GIFs (opcional)

1. Abra o Ipasty (<kbd>⇧⌘V</kbd>) e vá na aba **GIF**.
2. Clique em **Abrir developers.giphy.com** e entre (ou crie uma conta grátis).
3. Clique em **Create an API Key**, escolha **API** e dê o nome **Ipasty**.
4. Copie a chave, cole no campo da aba GIF e clique em **Salvar**.

A chave gratuita permite até 100 buscas por hora.

### Abrir junto com o Mac (opcional)

Já vem ligado. Para desligar: ícone do Ipasty na barra de menus → **Ajustes…** → **Abrir ao iniciar o Mac**.

---

## Solução de problemas

| Problema | O que fazer |
|---|---|
| O <kbd>⇧⌘V</kbd> não abre nada | Veja se o ícone de prancheta está na barra de menus. Se não estiver, abra o Ipasty de novo pela pasta Aplicativos. |
| Clicar num item não cola | Abra **Ajustes → Permissões**. Se o Ipasty aparece ligado na lista do sistema e mesmo assim não cola, clique em **Redefinir permissão**. |
| "Chave do GIPHY inválida" | Na aba GIF, clique na engrenagem → **Trocar chave do GIPHY** e cole a chave de novo. |
| "Limite do GIPHY atingido" | A chave gratuita permite 100 buscas por hora. Espere um pouco. |
| Algum emoji não aparece | O Ipasty mostra só os emojis que a sua versão do macOS sabe desenhar. Atualize o macOS para ver os mais novos. |

Não resolveu? [Abra uma issue](https://github.com/augusttogu/ipasty/issues/new/choose).

## Desinstalar

1. Clique no ícone do Ipasty → **Sair do Ipasty**.
2. Apague o **Ipasty.app** da pasta Aplicativos.
3. Para apagar também o histórico e os favoritos:

```bash
rm -rf ~/Library/Application\ Support/Ipasty
defaults delete io.github.augusttogu.ipasty
```

# Privacidade e termos de uso

_Última atualização: 16 de novembro de 2026_

O Ipasty foi feito para funcionar **inteiramente no seu Mac**. Esta página explica o que o app guarda, para onde os dados vão (spoiler: para lugar nenhum) e as condições de uso.

## O que o Ipasty guarda

Tudo fica na pasta `~/Library/Application Support/Ipasty`, no seu computador:

| Arquivo | Conteúdo |
|---|---|
| `history.json` | Os textos copiados, o app de onde vieram, a data e se estão fixados |
| `images/` | As imagens copiadas, em PNG |
| `favorites.json` | Seus favoritos (emojis, símbolos, kaomojis, textos e links de GIFs) |
| `recents.json` | Os últimos itens usados nas abas de emoji, GIF, kaomoji e caracteres |

As preferências (por exemplo, a sua chave do GIPHY) ficam nas preferências do macOS do app (`io.github.augusttogu.ipasty`).

- O histórico guarda até **300 itens** não fixados. Os mais antigos são apagados automaticamente.
- Itens marcados como **senha ou conteúdo temporário** por gerenciadores de senha (por exemplo, 1Password e Bitwarden) **não são guardados**.
- Você pode apagar um item (<kbd>⌘⌫</kbd>), limpar tudo pelo botão **Limpar tudo**, ou apagar a pasta acima para remover todos os dados.

> ⚠️ Atenção: o Ipasty guarda **tudo** o que você copia, inclusive textos sensíveis copiados de lugares comuns (como um token colado num e-mail). Se copiar algo sigiloso, apague o item do histórico.

## O que sai do seu Mac

- **Nada**, exceto quando você usa a **aba GIF**. Nela, o app envia ao GIPHY o texto que você pesquisa, a sua chave da API e o idioma, e baixa as imagens dos GIFs. Isso segue a [política de privacidade do GIPHY](https://giphy.com/privacy).
- O Ipasty **não tem** telemetria, estatísticas de uso, anúncios, contas nem servidores próprios.

## Permissões que o app pede

| Permissão | Para quê | Obrigatória? |
|---|---|---|
| **Acessibilidade** | Enviar <kbd>⌘V</kbd> ao app em que você estava, para colar com um clique | Não. Sem ela, você cola manualmente |
| **Abrir ao iniciar** | Iniciar junto com o Mac, se você ligar a opção | Não |

O Ipasty **não** pede acesso a arquivos, câmera, microfone, localização ou contatos.

## Termos de uso

1. O Ipasty é software livre, distribuído sob a [Licença MIT](LICENSE).
2. Ele é fornecido **"como está"**, sem garantias de qualquer tipo. Os autores não se responsabilizam por perdas de dados ou outros danos decorrentes do uso.
3. Ao usar a aba GIF, você é responsável pela sua chave do GIPHY e concorda com os termos do GIPHY. Veja [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
4. Use o app de acordo com as leis aplicáveis e respeitando os direitos autorais do conteúdo que você copia e compartilha.

Dúvidas? Abra uma [issue](https://github.com/augusttogu/ipasty/issues). Para problemas de segurança, veja [SECURITY.md](SECURITY.md).

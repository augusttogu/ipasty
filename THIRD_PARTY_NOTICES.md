# Avisos de terceiros

O código do Ipasty é distribuído sob a [Licença MIT](LICENSE). Ele usa dados e serviços de terceiros, que têm termos próprios.

## 1. Dados de emoji do Unicode

O arquivo [`Resources/bundle/emoji-test.txt`](Resources/bundle/emoji-test.txt) vem do Unicode, Inc. (<https://unicode.org/Public/emoji/latest/emoji-test.txt>) e é usado para a ordem e as categorias dos emojis. Ele é redistribuído sem alterações, sob a licença abaixo.

```
UNICODE LICENSE V3

COPYRIGHT AND PERMISSION NOTICE

Copyright © 1991-2026 Unicode, Inc.

NOTICE TO USER: Carefully read the following legal agreement. BY
DOWNLOADING, INSTALLING, COPYING OR OTHERWISE USING DATA FILES, AND/OR
SOFTWARE, YOU UNEQUIVOCALLY ACCEPT, AND AGREE TO BE BOUND BY, ALL OF THE
TERMS AND CONDITIONS OF THIS AGREEMENT. IF YOU DO NOT AGREE, DO NOT
DOWNLOAD, INSTALL, COPY, DISTRIBUTE OR USE THE DATA FILES OR SOFTWARE.

Permission is hereby granted, free of charge, to any person obtaining a
copy of data files and any associated documentation (the "Data Files") or
software and any associated documentation (the "Software") to deal in the
Data Files or Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, and/or sell
copies of the Data Files or Software, and to permit persons to whom the
Data Files or Software are furnished to do so, provided that either (a)
this copyright and permission notice appear with all copies of the Data
Files or Software, or (b) this copyright and permission notice appear in
associated Documentation.

THE DATA FILES AND SOFTWARE ARE PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT OF
THIRD PARTY RIGHTS.

IN NO EVENT SHALL THE COPYRIGHT HOLDER OR HOLDERS INCLUDED IN THIS NOTICE
BE LIABLE FOR ANY CLAIM, OR ANY SPECIAL INDIRECT OR CONSEQUENTIAL DAMAGES,
OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS,
WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THE DATA
FILES OR SOFTWARE.

Except as contained in this notice, the name of a copyright holder shall
not be used in advertising or otherwise to promote the sale, use or other
dealings in these Data Files or Software without prior written
authorization of the copyright holder.
```

## 2. Dados do macOS

Os nomes dos emojis no idioma do sistema, as categorias e os nomes do Visualizador de Caracteres e as fontes que desenham cada símbolo **pertencem à Apple** e **não fazem parte deste repositório nem das versões publicadas**. O Ipasty lê esses dados do macOS instalado no computador de quem usa o app, na hora em que ele abre, somente para exibi-los.

O ícone do Ipasty foi desenhado por código em [`tools/make-icon.swift`](tools/make-icon.swift) e não usa SF Symbols nem outros recursos da Apple.

## 3. GIPHY

A aba GIF usa a [API do GIPHY](https://developers.giphy.com/). Ao usá-la, você concorda com os [Termos de Serviço do GIPHY](https://giphy.com/terms), incluindo os termos da API apresentados no [painel de desenvolvedores](https://developers.giphy.com/) ao criar a sua chave.

- Cada pessoa usa a **própria chave** gratuita. Nenhuma chave vem embutida no app ou no código.
- Os GIFs pertencem aos seus autores. O Ipasty mostra a marca "Powered by GIPHY", como o GIPHY exige.
- Os GIFs ficam em cache só na memória enquanto o app está aberto. Ao colar um GIF, uma cópia temporária é salva na pasta temporária do sistema para que o app de destino consiga recebê-lo.

## 4. Marcas

Apple, macOS, Mac e SF Symbols são marcas da Apple Inc. Windows é marca da Microsoft Corporation. GIPHY é marca da GIPHY, Inc. O Ipasty é um projeto independente e não tem relação com nenhuma dessas empresas.

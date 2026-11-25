#!/bin/zsh
# Gera os prints do README com dados de exemplo (nunca com o seu histórico real).
# Uso: ./tools/screenshots.sh   (depois de ./build.sh --no-install)
set -e
cd "$(dirname "$0")/.."

BIN=build/Ipasty.app/Contents/MacOS/Ipasty
[[ -x $BIN ]] || { echo "Rode ./build.sh --no-install antes."; exit 1; }

DEMO=$(mktemp -d)
OUT=docs/screenshots
mkdir -p "$DEMO/images" "$OUT"
cp build/icon/icon-1024.png "$DEMO/images/demo.png"

python3 -I - "$DEMO" <<'PY'
import json, sys, time, uuid, hashlib
demo = sys.argv[1]
now = time.time() - 978307200  # Date de referência do Swift (2001-01-01)
def item(text=None, app="Notas", mins=1, pinned=False, image=None):
    h = hashlib.sha256((text or image).encode()).hexdigest()
    d = {"id": str(uuid.uuid4()).upper(), "kind": "image" if image else "text", "hash": h,
         "date": now - mins * 60, "pinned": pinned, "sourceApp": app}
    if text: d["text"] = text
    if image: d["imageFile"] = image
    return d
history = [
    item("Reunião de planejamento amanhã às 10h na sala 3 ☕️", "Mensagens", 1),
    item(image="demo.png", app="Preview", mins=4),
    item("https://github.com/augusttogu/ipasty", "Safari", 9),
    item("Olá! Segue em anexo o orçamento revisado. Qualquer dúvida estou à disposição.", "Mail", 25, pinned=True),
    item("git clone https://github.com/augusttogu/ipasty.git", "Terminal", 60),
    item("Rua das Flores, 123 — São Paulo, SP", "Mapas", 180),
]
json.dump(history, open(f"{demo}/history.json", "w"), ensure_ascii=False)
fav = lambda k, v, t=None: {"kind": k, "value": v, **({"title": t} if t else {})}
json.dump([fav("emoji", "😂", "rosto chorando de rir"), fav("emoji", "❤️", "coração vermelho"), fav("emoji", "🔥", "fogo"),
           fav("emoji", "👍", "polegar para cima"), fav("symbol", "→"), fav("symbol", "€"), fav("symbol", "✓"),
           fav("symbol", "°"), fav("kaomoji", "¯\\_(ツ)_/¯"), fav("kaomoji", "(╯°□°)╯︵ ┻━┻"),
           fav("text", "Olá! Segue em anexo o orçamento revisado.")],
          open(f"{demo}/favorites.json", "w"), ensure_ascii=False)
json.dump([fav("emoji", "🎉", "confete"), fav("emoji", "🙏", "mãos juntas"), fav("emoji", "😅"), fav("symbol", "™"),
           fav("kaomoji", "ʕ•ᴥ•ʔ"), fav("emoji", "🚀", "foguete")],
          open(f"{demo}/recents.json", "w"), ensure_ascii=False)
PY

shoot() { # nome aba aparência [busca]
  local args=(--snapshot "$OUT/$1.png" --tab "$2" --appearance "$3")
  [[ -n "$4" ]] && args+=(--query "$4")
  IPASTY_DATA_DIR="$DEMO" "$BIN" "${args[@]}"
  echo "  $OUT/$1.png"
}

echo "→ Gerando prints"
for look in light dark; do
  shoot "clipboard-$look" 5 $look
  shoot "emoji-$look" 1 $look
  shoot "favorites-$look" 0 $look
  shoot "kaomoji-$look" 3 $look
  shoot "symbols-$look" 4 $look
  shoot "gif-$look" 2 $look
done
shoot "emoji-search-light" 1 light "coração"
for look in light dark; do
  IPASTY_DATA_DIR="$DEMO" "$BIN" --snapshot "$OUT/settings-$look.png" --settings --appearance $look
  echo "  $OUT/settings-$look.png"
done
shoot "symbols-search-light" 4 light "arrow"

echo "→ Montando imagem de capa"
swift tools/compose-hero.swift "$OUT/hero.png" \
  "$OUT/clipboard-light.png" "$OUT/emoji-light.png" "$OUT/symbols-light.png"
swift tools/compose-hero.swift "$OUT/hero-dark.png" \
  "$OUT/clipboard-dark.png" "$OUT/emoji-dark.png" "$OUT/symbols-dark.png"
cp build/icon/icon-1024.png docs/icon.png
rm -rf "$DEMO"
echo "✓ Pronto"

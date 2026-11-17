#!/bin/zsh
# Compila o Ipasty.app.
#
#   ./build.sh            compila e instala em ~/Applications (e abre o app)
#   ./build.sh --no-install   só compila em build/Ipasty.app (usado no CI)
#   ./build.sh --zip          compila e gera dist/Ipasty-<versão>.zip para uma release
set -e
cd "$(dirname "$0")"

VERSION="$(cat VERSION 2>/dev/null || echo 0.0.0)"
INSTALL=1
ZIP=0
for arg in "$@"; do
  case "$arg" in
    --no-install) INSTALL=0 ;;
    --zip) ZIP=1; INSTALL=0 ;;
    *) echo "Opção desconhecida: $arg"; exit 1 ;;
  esac
done

ARCH_FLAGS=(-target arm64-apple-macos14.0)
if [[ $ZIP == 1 ]]; then
  # Release: binário universal (Apple Silicon + Intel)
  ARCH_FLAGS=()
fi

APP=build/Ipasty.app
rm -rf build
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

echo "→ Compilando Ipasty $VERSION"
if [[ $ZIP == 1 ]]; then
  for arch in arm64 x86_64; do
    swiftc -O -swift-version 5 -target $arch-apple-macos14.0 -lsqlite3 \
      -o "build/Ipasty-$arch" Sources/Ipasty/*.swift
  done
  lipo -create build/Ipasty-arm64 build/Ipasty-x86_64 -output "$APP/Contents/MacOS/Ipasty"
  rm build/Ipasty-arm64 build/Ipasty-x86_64
else
  swiftc -O -swift-version 5 "${ARCH_FLAGS[@]}" -lsqlite3 \
    -o "$APP/Contents/MacOS/Ipasty" Sources/Ipasty/*.swift
fi

cp Resources/bundle/emoji-test.txt "$APP/Contents/Resources/"

echo "→ Gerando ícone"
swift tools/make-icon.swift build/icon >/dev/null
iconutil -c icns build/icon/AppIcon.iconset -o "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>Ipasty</string>
  <key>CFBundleDisplayName</key><string>Ipasty</string>
  <key>CFBundleIdentifier</key><string>io.github.augusttogu.ipasty</string>
  <key>CFBundleExecutable</key><string>Ipasty</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundleVersion</key><string>$VERSION</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSHumanReadableCopyright</key><string>© 2026 augusttogu e colaboradores. Licença MIT.</string>
</dict>
</plist>
PLIST

# Assinatura ad-hoc (sem conta de desenvolvedor Apple)
# Requisito fixo pelo identificador: assim a permissão de Acessibilidade
# continua valendo depois de recompilar ou atualizar o app.
codesign --force --deep --sign - \
  --requirements "=designated => identifier \"io.github.augusttogu.ipasty\"" "$APP"

if [[ $ZIP == 1 ]]; then
  mkdir -p dist
  ditto -c -k --keepParent "$APP" "dist/Ipasty-$VERSION.zip"
  echo "✓ dist/Ipasty-$VERSION.zip"
fi

if [[ $INSTALL == 1 ]]; then
  mkdir -p ~/Applications
  pkill -x Ipasty 2>/dev/null || true
  rm -rf ~/Applications/Ipasty.app
  cp -R "$APP" ~/Applications/
  open ~/Applications/Ipasty.app
  echo "✓ Instalado em ~/Applications/Ipasty.app"
else
  echo "✓ $APP"
fi

#!/bin/zsh
# Configura o repositório no GitHub: descrição, tópicos, opções de merge e proteção da main.
# Requer o GitHub CLI logado (gh auth login) com permissão de administrador no repositório.
# Uso: ./tools/setup-github.sh [dono/repositório]
set -e
REPO="${1:-augusttogu/ipasty}"

echo "→ Configurando $REPO"

gh repo edit "$REPO" \
  --description "Free clipboard manager & emoji picker for Mac (macOS menu bar app): clipboard history, emoji, GIFs, kaomoji and special characters in one shortcut. Like Windows Win+V for Apple Macs." \
  --homepage "https://github.com/$REPO#readme" \
  --enable-issues --enable-discussions \
  --enable-wiki=false --enable-projects=false \
  --enable-squash-merge --enable-merge-commit=false --enable-rebase-merge=false \
  --delete-branch-on-merge \
  --add-topic macos,mac,apple,macos-app,clipboard-history,paste,clipboard,clipboard-manager,emoji,emoji-picker,gif,giphy,kaomoji,unicode,menubar-app,swift,swiftui,productivity,open-source

echo "→ Criando a regra de proteção da main"
# Remove uma regra anterior com o mesmo nome, para o script poder ser rodado de novo
for id in $(gh api "repos/$REPO/rulesets" --jq '.[] | select(.name=="Proteger main") | .id'); do
  gh api -X DELETE "repos/$REPO/rulesets/$id" >/dev/null
done

gh api -X POST "repos/$REPO/rulesets" --input - >/dev/null <<'JSON'
{
  "name": "Proteger main",
  "target": "branch",
  "enforcement": "active",
  "conditions": { "ref_name": { "include": ["~DEFAULT_BRANCH"], "exclude": [] } },
  "bypass_actors": [ { "actor_id": 5, "actor_type": "RepositoryRole", "bypass_mode": "always" } ],
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" },
    { "type": "pull_request", "parameters": {
        "required_approving_review_count": 1,
        "dismiss_stale_reviews_on_push": true,
        "require_code_owner_review": true,
        "require_last_push_approval": false,
        "required_review_thread_resolution": true } },
    { "type": "required_status_checks", "parameters": {
        "strict_required_status_checks_policy": false,
        "required_status_checks": [ { "context": "Compilar" } ] } }
  ]
}
JSON

echo "✓ Pronto. Confira em https://github.com/$REPO/settings/rules"

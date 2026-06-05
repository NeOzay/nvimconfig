# Neogit

## Role
Interface git Magit-style en onglet.

## Files
- Config: `lua/plugins/neogit.lua`

## Key Behaviors
- `kind = "tab"` → la fenêtre status s'ouvre dans un onglet.
- `commit_editor.kind = "tab"`, `log_view.kind = "tab"`, `reflog_view.kind = "tab"`, `commit_select_view.kind = "tab"`.
- `commit_view.kind = "vsplit"` avec vérification GPG si `gpg` est installé.
- `graph_style = "ascii"` (pas unicode).
- `sort_branches = "-committerdate"` → branches triées par date de dernier commit.
- `recent_commit_count = 10` dans la section status.
- `integrations.diffview = false` → utilise CodeDiff à la place.
- Sections stashes/unpulled/recent pliées par défaut.
- `ignored_settings` : ignore les options `--hierarchical` de Push/Pull/Commit/Rebase popups.

## Keymaps
| Touche | Action |
|--------|--------|
| `<leader>gg` | Neogit status |
| `<leader>gc` | Neogit commit |
| `<leader>gp` | Neogit push |
| `<leader>gl` | Neogit pull |
| `<leader>gb` | Neogit branch |

## Gotchas
- `telescope = nil` et `fzf_lua = nil` → les intégrations sont désactivées (utilise le finder natif).
- Les mappings status `{}`/`[]` sont dupliqués automatiquement en `ç`/`à` par le wrapper AZERTY.

## Changelog
- 2026-06-05 : Analyse initiale.

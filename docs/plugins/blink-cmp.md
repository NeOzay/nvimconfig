# blink.cmp

## Role
Moteur de complétion principal, remplace nvim-cmp.

## Files
- Config: `lua/plugins/blink-cmp.lua`

## Key Behaviors
- Preset `super-tab` avec `<Tab>` multi-rôle : accepte snippet actif → navigue dans la liste → fallback `<Tab>` normal. (NES hook présent dans le code mais Copilot NES est désactivé.)
- Source `path_cwd` séparée de `path` : `path` utilise le répertoire du fichier, `path_cwd` utilise `vim.uv.cwd()`.
- `min_keyword_length` = 2 pour markdown, 0 pour tout le reste.
- Ghost text désactivé (lag avec Copilot).
- Sources per-filetype : `AvanteInput` → sources avante, `codecompanion` → source codecompanion.
- Signature help activée avec treesitter highlighting.
- `preselect = false` + `auto_insert = true` → jamais de pré-sélection automatique.
- Copilot via `blink-copilot` (`fang2hou`) avec `score_offset = -3` (relégué en bas de liste).
- `<C-space>` → ouvre menu ET documentation en même temps.

## Keymaps
| Touche | Action |
|--------|--------|
| `<Tab>` | snippet accept → select_next → fallback |
| `<S-Tab>` | select_prev |
| `<CR>` | accept |
| `<Up>/<Down>` | select_prev / select_next |
| `<C-space>` | show + show_documentation |
| `<C-e>` | hide |

## Gotchas
- `<esc>` pour fermer est commenté intentionnellement (conflit avec le mode normal).
- `use_nvim_cmp_as_default = false` → highlights blink custom, ne pas hériter de nvim-cmp.
- Deux dépendances copilot distinctes : `blink-copilot` (fang2hou, provider blink) ≠ `blink-cmp-copilot` (giuxtaposition, déclaré dans copilot.lua comme dépendance séparée).

## Changelog
- 2026-06-05 : Ghost text désactivé, source `path_cwd` ajoutée.

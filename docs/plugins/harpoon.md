# Harpoon

## Role
Navigation rapide entre fichiers marqués, intégré à cokeline et snacks picker.

## Files
- Config: `lua/plugins/harpoon.lua`
- Fork: `NeOzay/harpoon` branche `harpoon2` (dev, `~/projects/nvim-plugins/`)
- Picker: `lua/pickers/harpoon_snacks.lua`

## Key Behaviors
- `save_on_toggle = true` + `sync_on_ui_close = true`.
- Extension `REMOVE` : compacte la liste après chaque suppression pour garder les indices continus (pas de trous).
- `<C-a>` en mode toggle : si le buffer actuel est déjà harponné → le retire, sinon → l'ajoute.
- Navigation par index via `<leader><chiffre>` (digits AZERTY inclus via `utils.keys_nb_map`).
- `<leader><C-chiffre>` → `insert_at(nil, i)` (insère à l'index `i`).

## Keymaps
| Touche | Action |
|--------|--------|
| `<C-a>` | Toggle harpoon (ajoute ou retire) |
| `<C-e>` | Ouvre le Snacks picker harpoon |
| `<leader>hm` | Menu natif harpoon |
| `<C-S-N>` | Fichier suivant dans la liste |
| `<C-S-P>` | Fichier précédent dans la liste |
| `<leader>1`…`<leader>9` | Aller au fichier harponné n°i (AZERTY : `<leader>&`, `<leader>é`, …) |
| `<leader><C-1>`…`<leader><C-9>` | Insérer à l'index i |

## Gotchas
- La compaction dans `REMOVE` est critique : sans elle, `list.items` garde des trous et les indices cokeline décalent.
- `keys_nb_map` dans `lua/utils.lua` mappe `1→&, 2→é, 3→", 4→', 5→(, ...` pour AZERTY.

## Changelog
- 2026-06-05 : Analyse initiale. Extension REMOVE, toggle add/remove sur `<C-a>`.

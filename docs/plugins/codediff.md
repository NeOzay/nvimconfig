# codediff.nvim

## Role
Visualisation des diffs git avec explorer de fichiers, remplace diffview.

## Files
- Config: `lua/plugins/codediff/init.lua` (spec Lazy, importée par `plugins.codediff.init` dans
  `init.lua` : importer le répertoire chargerait `explorer.lua` comme une spec)
- Pilotage de l'explorer: `lua/plugins/codediff/explorer.lua` (`setup()` appelé par le `config`
  de la spec)
- Plugin chargé : upstream `esmuellert/codediff.nvim` (v4.0.6), installé par lazy dans
  `~/.local/share/nvim/lazy/codediff.nvim` — lecture seule.
- Fork `NeOzay/codediff.nvim` : submodule `plugins/codediff.nvim/`, **non chargé** (la ligne
  `dir = …/plugins/codediff.nvim` de la spec est commentée).

## Key Behaviors
- Explorer à gauche, largeur 30, vue `tree`, ouverture automatique au déplacement
  (`auto_open_on_cursor`) ; focus sur l'explorer à l'ouverture (`initial_focus = "explorer"`).
- Layout `inline` par défaut (`diff.layout = "inline"`) ; `t` bascule en side-by-side.
- Historique en bas, hauteur 16. `cycle_next_hunk = true`, inlay hints désactivés.
- Tout le pilotage de l'explorer vient de `explorer.lua`, sans toucher au code du plugin : son API
  (`codediff.ui.lifecycle`, `codediff.ui.view.actions.panes`) et son registre de mappings
  (`lifecycle.set_buf_keymap`), qui rend les mappings d'origine à la fin de la session.
- **Clic simple** sur un fichier : affiche son diff, focus et curseur restent dans l'explorer ;
  sur un dossier ou un groupe : bascule le pli.
- **Entrée** sur un fichier : cache l'explorer, met le focus sur le diff, **puis** sélectionne
  le fichier ; sur un dossier ou un groupe : bascule le pli, l'explorer reste ouvert.
  L'ordre compte : `M.update` capture la fenêtre courante à son entrée et la rend en fin de
  chargement, il capture donc le diff. Un chargement déjà lancé par un clic a capturé l'explorer,
  fermé entre-temps, donc invalide : il ne le rend pas.
- **Double-clic** : même effet qu'Entrée. Le premier relâchement a déjà fait l'effet du clic ;
  `<2-LeftMouse>` ouvre le fichier et ne fait rien sur un dossier (une seule bascule au total).
- **`<leader>e`**, dans un tab CodeDiff seulement : explorer caché → il s'ouvre et prend le
  focus ; visible sans le focus → il prend le focus ; focus → il se ferme, le focus passe au diff.
- **Curseur** : chaque fois que l'explorer prend le focus, et après un clic ou une bascule de pli,
  il se place sur la première lettre du nom (fichier : basename, dossier : `data.name`). Nom
  tronqué : sur son plus long début présent dans la ligne, sinon sur « … » ; groupe : premier
  caractère non blanc.
- Chaque diff ouvre un tab dédié, une session par tabpage dans `active_diffs`
  (`codediff.ui.lifecycle.session`), accessible via `codediff.ui.lifecycle.accessors`
  (`get_paths(tabnr)`, `get_git_context(tabnr)`, `get_panel_name(tabnr)`, `get_panel_view(tabnr)`…).
- `lua/tabpage.lua` (`default_name`) détecte ces sessions via `accessors.get_paths(tabnr)` et
  nomme automatiquement le tab d'après le basename du fichier affiché — pas de renommage manuel
  nécessaire tant que l'utilisateur n'a pas fixé de nom custom (`tabname` var de tabpage).

## Keymaps
| Touche | Action |
|--------|--------|
| `<leader>gd` | Ouvrir CodeDiff |
| `<leader>gh` | Historique du fichier courant (HEAD~50) |
| `<leader>gH` | Historique global |

### Dans un tab CodeDiff
| Touche | Action |
|--------|--------|
| `<leader>e` | Ouvrir, focus ou fermer l'explorer (seul toggle : `toggle_explorer` et `focus_explorer` du plugin sont à `false`) |
| `q` | Fermer |
| `t` | Basculer inline / side-by-side |
| `]c` / `[c` | Hunk suivant/précédent |
| `]f` / `[f` | Fichier suivant/précédent (comportement du plugin, hors chantier) |
| `do` / `dp` | Diffget / diffput |
| `gf` | Ouvrir le fichier dans le tab précédent |
| `-` | Stage toggle |

### Dans l'explorer
| Touche | Action |
|--------|--------|
| clic | Afficher le diff (focus gardé) / plier |
| double-clic, `<CR>` | Aller au diff en fermant l'explorer / plier |
| `j` / `k` | Déplacer et afficher le fichier |
| `K` | Chemin complet |
| `R` | Rafraîchir |
| `i` | Vue liste / arbre |
| `S` / `U` | Stage all / unstage all |
| `X` | Discard |

### Conflits
| Touche | Action |
|--------|--------|
| `<leader>co` | Accepter les nôtres |
| `<leader>ct` | Accepter les leurs |
| `<leader>cb` | Accepter les deux |
| `<leader>cx` | Rejeter les deux |
| `]x` / `[x` | Conflit suivant/précédent |

## Gotchas
- **Prise de focus temporaire au chargement** : le rendu d'un diff fait
  `nvim_set_current_win(modified_win)` (`inline_view/render.lua`), puis `commit_update` rend le
  focus à `saved_current_win`. Un délai pour « attendre que ça se stabilise » ne sert à rien :
  l'ordre des appels règle la course (voir Entrée).
- **Fichier simple face non chargé** (`??`, `A`, `D`, layout inline) : `helpers.open_real_file`
  met le focus sur le diff pour son `:edit` et ne le rend jamais. `explorer.lua` enveloppe
  `inline_view.show_single_file` pour rendre le focus à la fenêtre d'avant ; `view/init.lua` lit
  ce champ à chaque appel. Dépend d'un module interne : à revérifier à chaque mise à jour.
- **Clic simple et satellite** : satellite pose un `<LeftMouse>` global qui lit lui-même la
  suite du clic et la rejoue par `nvim_feedkeys(…, "ni")`, sans remap — un mapping
  `<LeftRelease>` ne se déclenche jamais. Le clic est donc guetté par `vim.on_key`
  (`<LeftRelease>` tapé ou rejoué) et traité au tour de boucle suivant si `getmousepos()` est
  dans l'explorer. Sous la dernière ligne, `getmousepos().line` vaut la dernière ligne : un clic
  dans le vide ne fait que replacer le curseur (contrôle par `screenpos`).
- **Claims de l'explorer** : `<CR>` et `<2-LeftMouse>` sont posés au `User CodeDiffOpen`, avec le
  même propriétaire et la même portée que ceux du plugin : ils les **remplacent**
  (`keymap/slots.lua`). Ça tient parce que `keymaps.setup` de l'explorer ne tourne qu'une fois,
  avant `CodeDiffOpen` (`t` ne recrée pas l'explorer).
- **`<leader>e` re-posé à chaque entrée** (`BufEnter`/`WinEnter`) dans une fenêtre de la session :
  chaque fichier sélectionné crée un nouveau buffer, que le plugin re-mappe pour ses touches mais
  pas pour les nôtres. Le filtre porte sur la **fenêtre**, pas sur le buffer : pendant le
  chargement, le buffer neuf entre dans la fenêtre du diff avant que la session ne l'enregistre.
- **`suspendable = true`** pour `<leader>e` : le registre le retire au `TabLeave` et le remet au
  `TabEnter` (par `vim.schedule`) ; le vrai fichier affiché dans un autre tab ne le porte pas.
  Les mappings du buffer de l'explorer restent `suspendable = false`.
- **Clés `keymaps` des `opts`** : `close`, `diffget`, `diffput`, `goto_file`, `stage_toggle`,
  `open`, `preview`, `toggle_view` ne sont pas des clés de l'upstream v4.0.6 et n'ont aucun
  effet ; ce sont les défauts du plugin qui s'appliquent.
- **Essais headless** : `nvim_input_mouse` est ignoré sans UI ; pour de vrais clics, lancer
  Neovim `--listen` dans tmux et envoyer les séquences SGR (`\e[<0;col;rowM` / `m`) par
  `tmux send-keys -l`. À froid, le premier `BufReadPre` charge satellite, qui fait échouer le
  premier diff (E201) : lire un fichier avant `:CodeDiff`.

## Changelog
- 2026-06-05 : Analyse initiale.
- 2026-07-10 : Documentation de la détection auto des tabs CodeDiff par `lua/tabpage.lua`.
- 2026-07-27 : fork migré en submodule git sous `plugins/codediff.nvim/`.
- 2026-08-23 : layout inline sur petit écran et fermeture auto de l'explorer à la sélection
  (`User CodeDiffFileSelect`, différée) — retirés depuis.
- 2026-10-31 : upstream `esmuellert/codediff.nvim` chargé par lazy, fork non chargé ; layout
  `inline` par défaut ; spec en répertoire `lua/plugins/codediff/` ; `explorer.lua` : clic,
  double-clic, Entrée, `<leader>e`, curseur sur le nom, retour du focus après un fichier simple
  face (chantier codediff-explorer).

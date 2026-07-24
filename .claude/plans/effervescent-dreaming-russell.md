# Provider terminal custom pour claudecode.nvim (snacks)

## Contexte

`lua/plugins/claudecode.lua` utilise le provider `"snacks"` intégré à `coder/claudecode.nvim`.
Pour supporter l'édition du prompt en place via Ctrl+G (`$EDITOR=nvim` + nvim-unception), un
hack a été mis en place : `snacks_win_opts.fixbuf = false` (pour laisser nvim-unception remplacer
le buffer terminal par celui du prompt sans que snacks le swap immédiatement hors de la fenêtre)
+ un autocmd `QuitPre` dans `lua/autocmds.lua` qui répare après coup l'état interne de l'objet
`snacks.win` (`self.buf`/`self.win`), corrompu de façon permanente par `fixbuf = false` une fois
que nvim-unception a restauré le terminal dans la fenêtre (cf. `docs/plugins/claudecode.md`
Gotchas, commits `8c856ec` et `1a10215`).

Ce correctif est un pansement après-coup, fragile (dépend de `claudecode.terminal.snacks
._get_terminal_for_test()`, une fonction privée du plugin tiers) et spécifique au seul cas
Ctrl+G. Investigation de la référence `coder/claudecode.nvim` a confirmé que `terminal.provider`
accepte une **table custom** (contrat : `setup/open/close/simple_toggle/focus_toggle
/get_active_bufnr/is_available`, `toggle`/`_get_terminal_for_test` optionnels — voir
`claudecode/terminal.lua` du plugin). On peut donc écrire notre propre provider basé sur
`Snacks.terminal`/`Snacks.win`, sans toucher au plugin (read-only), qui **possède** son propre
suivi buf/win au lieu de subir celui de snacks — éliminant le hack à la racine, plus deux
comportements supplémentaires demandés :

- le terminal garde sa taille (largeur/hauteur) d'un toggle à l'autre au lieu de revenir aux
  pourcentages par défaut à chaque recréation de split ;
- la fenêtre du terminal n'accueille jamais que le buffer terminal ou le buffer de prompt
  Ctrl+G — tout autre buffer qui s'y retrouve (accident, navigation) en est éjecté.

## Approche retenue

### 1. `lua/plugins/claudecode/terminal.lua` (nouveau) — provider custom

Module retournant la table provider. État interne (module-local) :

- `terminal` : l'instance `snacks.win` retournée par `Snacks.terminal.open()` (réutilisée entre
  les toggles tant qu'elle est valide).
- `term_buf` : référence **stable**, capturée une seule fois à la création (`terminal.buf` juste
  après `Snacks.terminal.open`). C'est la seule source de vérité pour `get_active_bufnr()` — on
  ne relit jamais `terminal.buf` pour ça, car c'est justement ce champ que fixbuf/nvim-unception
  peuvent désynchroniser.
- `last_win_size` : `{ width, height }` en cellules, capturé juste avant de cacher la fenêtre.
- `augroup` : **notre propre augroup**, créé une fois à l'ouverture, jamais recréé par la suite —
  contrairement à `self.augroup` interne de `snacks.win` qui est recréé (`clear = true`) à chaque
  `show()` (vu dans `snacks/win.lua`, fonction `M:show()`). Notre autocmd de garde doit vivre
  indépendamment de ce cycle pour survivre aux toggles.

Fonctions :

- **`is_prompt_buf(bufnr)`** : teste le nom du buffer contre le même pattern que l'exemption
  readonly déjà présente dans `lua/autocmds.lua` (`/claude%-prompt%-[^/]+%.md$`), pour rester
  cohérent avec la détection existante du fichier de prompt Ctrl+G.

- **`guard_window()`** (appelée une fois à la création du terminal) : un unique autocmd
  `BufWinEnter` sur notre `augroup` (`nested = true`, pas de `pattern` — filtrage dans le
  callback comme le fait `snacks.win:fixbuf()`). Logique :
  - si la fenêtre suivie n'est plus valide → rien à faire ;
  - si son buffer actuel == `term_buf` → rien à faire (état nominal) ;
  - si son buffer actuel matche `is_prompt_buf` → autorisé, ne rien éjecter (c'est l'édition
    Ctrl+G en cours) ;
  - sinon (buffer étranger) → l'éjecter : remettre `term_buf` dans la fenêtre terminal
    (`nvim_win_set_buf`) et ouvrir le buffer étranger ailleurs (`vim.cmd("sbuffer " .. buf)`),
    à l'image du fallback "pas de fenêtre principale" de `fixbuf()` upstream.

  C'est ce mécanisme qui remplace entièrement le hack `fixbuf = false` + réparation `QuitPre` :
  on n'a plus besoin d'attendre que le prompt se ferme pour réparer un état interne cassé,
  puisqu'on ne laisse jamais cet état se casser — `term_buf` ne bouge jamais, et la fenêtre est
  gardée en continu, pas seulement au moment du `QuitPre`.

- **`resolve_win_opts(config)`** : construit les `snacks_win_opts` à passer à
  `Snacks.terminal.open`/à l'instance : part de `config.snacks_win_opts` (position, border,
  keys...), force `fixbuf = false` en interne (nécessaire pour laisser `guard_window()` — pas
  snacks — décider quoi faire d'un buffer étranger), et si `last_win_size` est renseigné,
  écrase `width`/`height` par les valeurs absolues capturées (Snacks traite une valeur ≥ 1 comme
  un nombre de cellules absolu, cf. `snacks.win.Config` — donc pas besoin de reconversion).

- **`open(cmd_string, env_table, config, focus)`** : si `terminal` existe et est valide → montrer
  (voir ci-dessous) ; sinon `Snacks.terminal.open(...)`, capturer `term_buf`, appeler
  `guard_window()`, enregistrer les événements `TermClose` (respecte `config.auto_close`, comme
  dans le provider de référence) et `BufWipeout` (reset de tout l'état local + suppression de
  l'augroup).

- **Hide/show/toggle** : wrapper léger autour des méthodes par défaut de `snacks.win`
  (`terminal:hide()`, `terminal:show()`, `terminal:toggle()`) — **pas** besoin de réimplémenter
  le contournement "climbing cursor" du provider de référence (destroy+recreate de fenêtre, cf.
  `claudecode/terminal/snacks.lua` upstream) : hors périmètre tant qu'il n'est pas observé chez
  nous. Avant tout hide, capturer `last_win_size` via `nvim_win_get_width/height` sur la fenêtre
  encore valide ; après capture, muter `terminal.opts.width`/`terminal.opts.height` (les champs
  lus par `snacks.win` pour résoudre la géométrie à la prochaine ouverture) avec les valeurs
  capturées, pour que le prochain `show()` recrée la fenêtre à l'identique plutôt qu'aux
  pourcentages par défaut. **Point à vérifier en implémentation** : confirmer dans
  `snacks/win.lua` que `self.opts.width/height` est bien relu à chaque `show()` (et pas figé une
  fois pour toutes à la création) — sinon capturer/appliquer la taille via l'API équivalente que
  `show()` utilise réellement.

- **`get_active_bufnr()`** : retourne `term_buf` s'il est encore un buffer terminal valide (jamais
  `terminal.buf`).

- **`close()` / `is_available()` / `setup()`** : triviaux, calqués sur le provider de référence.

### 2. `lua/plugins/claudecode.lua` → `lua/plugins/claudecode/init.lua`

Convention du repo pour les plugins multi-fichiers (`dap/`, `statuscol/`, `snacks/`, `ufo/`) :
dossier + `init.lua`. Déplacer le contenu actuel, avec deux changements :
- `opts.terminal.provider = require("plugins.claudecode.terminal")`.
- Retirer `snacks_win_opts.fixbuf = false` et son commentaire explicatif : ce n'est plus une
  option exposée ici, c'est un détail interne forcé par le provider (`resolve_win_opts`). Le
  reste de `snacks_win_opts` (`position`, `width`, `height`, `border`, `keys`) reste inchangé et
  continue d'être lu par le provider via `config.snacks_win_opts`.

### 3. `init.lua` (racine)

Ligne 91 : `{ import = "plugins.claudecode" }` → `{ import = "plugins.claudecode.init" }` (comme
`plugins.dap.init`, `plugins.statuscol.init`, `plugins.snacks.init`) — sinon lazy.nvim scanne tout
le dossier et essaie de charger `terminal.lua` comme un spec de plugin séparé, ce qui échoue.

### 4. `lua/autocmds.lua` — suppression (root-fix)

Retirer intégralement les deux blocs devenus inutiles :
- lignes 121-134 (cache `claude_terminal_bufnr` sur `TermOpen`) ;
- lignes 136-186 (réparation `QuitPre` sur `*claude-prompt-*.md` via
  `claudecode.terminal.snacks._get_terminal_for_test()`).

Rien d'autre dans ce fichier ne dépend de `claude_terminal_bufnr` (confirmé).

### 5. Documentation

- `docs/plugins/claudecode.md` : remplacer la section Gotchas décrivant le hack `fixbuf=false` +
  réparation `QuitPre` par une description du nouveau provider (`lua/plugins/claudecode/
  terminal.lua`) — garde de fenêtre dédiée, `term_buf` stable, persistance de taille. Ajouter une
  entrée Changelog.
- `docs/plugins/nvim-unception.md` : mettre à jour le gotcha correspondant (le problème de
  désynchronisation `snacks.win` est résolu côté provider custom, plus besoin du filet `QuitPre`
  externe) ; le lien `[[claudecode]]` reste valable.

## Hors périmètre

- Contournement "climbing cursor" (destroy+recreate de fenêtre décalant le curseur Ink d'une
  ligne à chaque toggle) : non porté, seulement si constaté en usage réel.
- Providers `native`/`external`/`none` de claudecode.nvim : non touchés.
- Comportement diff (`diff_opts`) : inchangé.
- Support multi-session Claude (plusieurs terminaux simultanés) : hors périmètre, un seul
  terminal comme aujourd'hui.

## Vérification

Manuel (pas de suite de tests dans ce repo — validation par usage réel dans Neovim) :

1. `<A-c>` : ouverture du terminal Claude Code, position/largeur/hauteur conformes à
   `snacks_win_opts`.
2. Toggle plusieurs fois (`<A-c>` en mode n et t) : le terminal réapparaît à la **même** position
   déjà ; redimensionner manuellement la fenêtre (`<C-w>` resize) puis toggler : la taille
   redimensionnée doit être conservée au prochain show (pas de retour aux pourcentages par
   défaut).
3. Ctrl+G dans le terminal Claude Code : le fichier de prompt s'ouvre dans la même fenêtre
   (édition en place, comportement actuel de `nvim-unception`) ; `:wq` → le terminal revient
   correctement, `<A-c>` bascule ensuite vers le terminal (pas vers un prompt fantôme), et
   `get_active_bufnr()` (testable via l'auto-attache en onglet diff) pointe bien sur le buffer
   terminal — sans aucun autocmd `QuitPre` dans `autocmds.lua`.
4. Depuis la fenêtre terminal, tenter d'y ouvrir un buffer quelconque (`:e some_file`,
   `<C-w>` navigation + `:b`) : le buffer étranger doit être éjecté vers une autre fenêtre, le
   terminal doit revenir dans sa fenêtre dédiée.
5. Diff Claude (`<leader>aa`/`<leader>ad`) : layout et accept/deny inchangés.
6. `git status` propre après revue des docs mises à jour.

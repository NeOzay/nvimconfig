---
slug: terminal-theme
titre: Thème distinct pour le terminal intégré (term_theme)
branche: terminal-theme
base: master
statut: terminé
session: 1
plan: /var/home/Benoit/.config/nvim/.claude/plans/lazy-seeking-trinket.md
créé: 2026-07-22
maj: 2026-07-22
---

## Objectif et périmètre

**But** : permettre un thème distinct pour le terminal intégré (snacks.terminal), en s'appuyant
sur le moteur `base46` existant plutôt que sur un hack ad-hoc (namespace de highlight codé en dur,
écarté précédemment). Ajout d'une clé de config `term_theme` (chemin de module, comme `theme`),
`term_theme == theme` par défaut.

**Critères de réussite** :
- `term_theme` ajouté au type `Base46Config` et à `base46/config.lua` (défaut `nil`).
- `M.get_term_theme_tb(tb_type)` résout `term_theme or theme`.
- Couleurs ANSI (`terminal_color_0..15`) résolues via `get_term_theme_tb` dans `load()`.
- `M.reload()` invalide aussi `package.loaded[term_theme]`.
- Groupes `TerminalNormal`/`TerminalNormalNC` dans `lua/highlights/snacks.lua`, résolus depuis
  `term_theme`, appliqués au widget terminal via `win.wo.winhighlight`.
- Comportement par défaut inchangé (vérifié à `:Base46Reload` + ouverture terminal).
- Docs à jour (`theme-highlights.md`, `snacks.md`).

**Hors-périmètre** :
- Créer un second thème Lua avec des couleurs réellement différentes de sonokai (infrastructure
  seulement — aucun changement visuel par défaut).
- Bascule dynamique des couleurs ANSI par fenêtre/terminal (impossible nativement, un seul jeu de
  `terminal_color_N` global par instance Nvim).
- Commande de reload séparée pour le terminal seul.

## Étapes

- [x] 1. `lua/base46/init.lua` — type `term_theme`, `get_term_theme_tb`, `load()` et `reload()`
- [x] 2. `lua/base46/config.lua` — clé `term_theme = nil`
- [x] 3. `lua/highlights/snacks.lua` — palette `term_colors` + `TerminalNormal`/`TerminalNormalNC`
- [x] 4. `lua/plugins/snacks/terminal.lua` — `win.wo.winhighlight`
- [x] 5. Documentation — `theme-highlights.md` + `snacks.md`

## État courant

**Terminé** : testé par l'utilisateur dans son vrai terminal (ANSI + fond/texte), validé.
**Notes** :
- `lua/themes/tokyonight.lua` : `base_30`/`base_16` adaptés de NvChad/base46 v3.0 ;
  `base_16_terminal` reprend les valeurs **exactes** de la config wezterm `tokyonight_night`
  (folke) de l'utilisateur (`colors.ansi`/`colors.brights`), pas une approximation.
- `term_theme` activé par défaut sur `"themes.tokyonight"` (`lua/base46/config.lua`).
- **Gotcha découvert et documenté** (`theme-highlights.md` + `snacks.md` § Gotchas) :
  `g:terminal_color_0..15` n'est lu par Neovim qu'au `TermOpen` (`:h terminal_color_x`) —
  `:Base46Reload` ne rafraîchit pas les ANSI d'un terminal déjà ouvert, car `q`/`<C-ù>`
  (`lua/plugins/snacks/terminal.lua`) ne font que `self:hide()`, jamais un vrai `close()`. Il faut
  `exit` le shell (ou `:bd!`) puis rouvrir pour voir un changement d'ANSI. `TerminalNormal`/
  `TerminalNormalNC` (fond/texte), eux, se rechargent à chaud normalement (highlight group classique
  résolu par `winhighlight`).

## Journal de décisions

- **2026-07-22** — `term_theme` en chaîne = chemin de module, résolu comme `theme` via `require()`.
  *Pourquoi* : cohérent avec le mécanisme existant (`M.get_theme_tb`), zéro nouvelle abstraction.
  *Rejeté* : namespace de highlight `nvim_win_set_hl_ns` avec couleurs codées en dur (contourne
  base46).
- **2026-07-22** — Couleurs ANSI terminal résolues une fois au démarrage (`load()`), pas de bascule
  `TermOpen`/`TermClose`. *Pourquoi* : `terminal_color_N` n'est consommé que par les buffers
  `:terminal`, donc pas besoin de logique de swap ; contrainte native Nvim de toute façon (un seul
  jeu de couleurs ANSI par instance). *Rejeté* : swap dynamique par fenêtre (impossible nativement).
- **2026-07-22** — Fond/texte du widget terminal via `lua/highlights/snacks.lua` +
  `win.wo.winhighlight`, pattern déjà utilisé pour `SnacksNormal`/picker. *Pourquoi* : réutilise un
  pattern existant du repo au lieu d'en introduire un nouveau. *Rejeté* : nouveau fichier
  `lua/highlights/terminal.lua` (n'aurait pas de trigger `LazyLoad` automatique, "terminal" ne
  matchant aucun nom de plugin).
- **2026-07-22** — `term_theme` par défaut pointe vers `themes.tokyonight`, palette ANSI reprise
  telle quelle de la config wezterm réelle de l'utilisateur. *Pourquoi* : rend la fonctionnalité
  utile immédiatement (terminal intégré = terminal externe), pas juste une infrastructure inerte.
  *Rejeté* : garder `term_theme = nil` par défaut et laisser l'activation à l'utilisateur (proposé
  initialement en hors-périmètre, mais l'utilisateur a fourni sa palette et demandé l'activation).

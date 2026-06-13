# statuscol

## Role
Colonne de statut personnalisée avec numéros de ligne, signes git, folds colorés et breakpoints DAP.

## Files
- Config: `lua/plugins/statuscol/init.lua`
- Segments: `lua/plugins/statuscol/segments.lua`
- Folds: `lua/plugins/statuscol/folds.lua`
- DAP handler: `lua/plugins/statuscol/dap_handler.lua`
- Conditions: `lua/plugins/statuscol/conditions.lua`

## Key Behaviors
- Dépend de `nvim-dap` (chargé en même temps).
- `folds.setup_hl()` : crée les highlights pour les fold markers colorés selon l'état git (consomme `FoldGit*` créés par gitsigns).
- `cond.setup_win_autocmd()` : gère les conditions d'affichage par type de fenêtre.
- `dap_handler.setup()` : gère l'affichage des breakpoints DAP dans la colonne.
- `clickhandlers` sur `FoldOpen`/`FoldOther` avec scroll-to-click, et `Lnum` (double-clic gauche sur la colonne numéro → `dap.toggle_breakpoint`, via `dap_handler.lnum_click`). Le segment `number` porte `click = "v:lua.ScLa"`. Remplace le `builtin.lnum_click` qui toggle au simple clic (évite les poses accidentelles).
- `BufWinEnter` schedulé au démarrage pour appliquer statuscol aux buffers déjà ouverts.
- Types annotés avec `---@namespace Ozay` : `Statuscol.FoldData`, `Statuscol.text.arg`.
- Responsive (window OU terminal étroit) — mesure **par window** (`cond.wide_enough(win)` lit `nvim_win_get_width`, pas `vim.o.columns`), donc réagit aux splits verticaux ; garde-fou terminal en plus. Deux seuils indépendants : `NARROW_WIN_WIDTH = 100` (window) et `NARROW_WIDTH = 100` (terminal). On masque dès que l'un n'est pas satisfait.
  - **Colonne dap** : segment `dap_signs` avec `condition.min_win_width = NARROW_WIN_WIDTH` + `min_columns = NARROW_WIDTH`. Le sign segment a une largeur dynamique, donc vider son texte replie la colonne. Évalué à chaque rendu (`conditions.lua` → `evaluate`), réactif au resize.
  - **Numéros de ligne** : gérés par l'option de fenêtre `number`, PAS par une condition. `cond.apply_win_options` éteint `number` quand la window (ou le terminal) est étroite. Indispensable car vider le texte du segment ne réduit pas la largeur : `numberwidth` reste réservé tant que `number` est actif. Réappliqué sur `VimResized` (toutes les fenêtres) et `WinResized` (fenêtres touchées via `v:event.windows`).

## Gotchas
- Dépend de gitsigns pour les highlights `FoldGit*`. Si ColorScheme est déclenché avant gitsigns, recalcule via autocmd `ColorScheme`.
- `folds.with_scroll_to_click` wrapper autour des handlers builtin pour préserver la position scroll au clic.
- **Double-clic colonne numéro** : Vim incrémente `args.clicks` pour deux clics rapprochés **même sur des lignes différentes**. Tester `clicks == 2` seul pose un breakpoint sur la 2ᵉ ligne par erreur → `dap_handler.lnum_click` mémorise `(win, line)` du 1ᵉ clic et n'agit que si le 2ᵉ porte sur la même.
- **Colonne `auto` qui ne se replie pas** : la largeur d'un sign segment `auto = true` n'est recalculée (`update_callargs`) qu'au **redraw complet** de la statuscolumn. Retirer le dernier breakpoint ne redessine que la ligne touchée → la colonne reste réservée ailleurs. `dap_handler.refresh_statuscolumn(win)` force `nvim__redraw({ win, statuscolumn = true })` (fallback `redraw!`) après chaque toggle.
- **Contexte inter-segments (`after`, expérimental)** : `make_condition` partage un `render_ctx` module-level clé `(win, lnum, tick)`. Repose sur le fait que statuscol évalue les conditions des segments **dans l'ordre `order`** pour une même ligne. `ctx.rendered[name] = true` veut dire « la **condition** du segment a passé », **pas** « un glyphe est visible » : un sign `auto = true` peut se replier malgré une condition passée. Écriture idempotente → une réévaluation partielle (cache statuscol) ne corrompt pas le contexte tant que `tick` est constant.
- `ConditionSpec.enabled` peut être une fonction : `evaluate` (`conditions.lua`) NE doit PAS la résoudre via le ternaire `cond and f() or x` — si `f()` renvoie `false`, le `or` renvoie la fonction (truthy) et le segment n'est jamais masqué. Utiliser un `if type(...) == "function"` explicite.

## Changelog
- 2026-06-05 : Analyse initiale.
- 2026-06-11 : Masquage responsive en terminal étroit (< 120 col). Colonne dap via `condition.enabled`. Numéros via l'option `number` éteinte dans `cond.apply_win_options` (réappliqué sur `VimResized`) — nécessaire pour réellement récupérer la largeur (`numberwidth`).
- 2026-06-12 : Mesure responsive **par window** (`wide_enough(win)` → `nvim_win_get_width`) au lieu du terminal global ; gère les splits verticaux. Nouveaux champs `ConditionSpec` : `min_win_width`/`max_win_width`/`min_columns`. Colonne dap migrée de `enabled` vers `min_win_width`+`min_columns`. Ajout autocmd `WinResized`. Conception détaillée : [`statuscol-design.md`](statuscol-design.md) §6 étape 1.
- 2026-06-12 : Fix double-clic dap : (1) exiger même `(win, line)` pour les 2 clics (Vim compte `clicks` sur lignes différentes) ; (2) `refresh_statuscolumn` après toggle pour replier la colonne `auto` (recalcul de largeur seulement au redraw complet). Appliqué aussi au `DapClickHandler`.
- 2026-06-12 : Double-clic dap sur la colonne numéro (§6 étape 3). `dap_signs` en `auto = true` (repli si vide) ; `dap_handler.lnum_click` filtre le double-clic gauche → `dap.toggle_breakpoint`, branché via `clickhandlers.Lnum` + `click = "v:lua.ScLa"` sur le segment `number`. Le cœur ayant déjà placé curseur/fenêtre, pas de recalcul de `mousepos`.
- 2026-06-12 : Contexte inter-segments expérimental (§6 étape 4). `ConditionSpec.after(ctx)` + `render_ctx` module-level clé `(win, lnum, tick)` ; `make_condition(spec, name)` inscrit chaque segment dont la condition passe dans `ctx.rendered`. Mécanisme dispo, non câblé sur un segment (exemple `fold` dans [`statuscol-design.md`](statuscol-design.md) §6).
- 2026-06-12 : Quick wins `ConditionSpec` (§6 étape 2). Champ mort `suppress_inactive` → `active_only` (window active ⟺ `args.win == args.actual_curwin`, fail-open si nil). Ajout `buftype_blacklist`. `require_file` **durci** : exige désormais buftype `""` ET nom non vide (exclut terminal/prompt/nofile/help/quickfix + anonymes) — impacte `dap_signs`/`git_signs` qui l'utilisent. Pas de stat disque (évalué par ligne). Colonne dap passée en `auto = true` (repli si vide).

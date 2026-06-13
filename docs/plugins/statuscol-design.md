# statuscol — Conception : rendu dynamique des segments

> Document de **conception/exploration** (pas l'état actuel : voir [`statuscol.md`](statuscol.md)).
> Objectif : rendre l'affichage de chaque segment configurable selon le contexte
> (largeur de window, éléments déjà rendus, FT, prédicat, flottant, fichier réel,
> présence de signs…), de façon **déclarative au niveau du composant**.

## 1. Modèle actuel (rappel)

Deux mécanismes cohabitent ; toute évolution doit choisir le bon.

| Mécanisme | Pilotage | Effet | Récupère la largeur ? |
|---|---|---|---|
| `segment.condition` | statuscol, **à chaque rendu** | vide le *texte* du segment | Seulement si largeur **dynamique** (sign segments) |
| `apply_win_options` | autocmd + `defer_fn(75ms)` | éteint `number`/`signcolumn`/`foldcolumn` | Oui (option de fenêtre) |

**Règle structurante :**
- Largeur **fixe** (`numberwidth`) → ne peut être récupérée que par **option de fenêtre**.
- Largeur **dynamique** (sign segments, texte) → récupérable par **condition**.

## 2. Écarts & bugs constatés (état au 2026-06-12)

1. **`suppress_inactive`** — déclaré dans `ConditionSpec` (`conditions.lua:8`) mais **jamais lu** par `evaluate` → champ mort.
2. **Mauvais axe de mesure** — `wide_enough()` lit `vim.o.columns` (terminal entier). Sur split vertical, une window étroite dans un terminal large est traitée comme « large ». C'est l'écart principal vs. la cible « taille de la window sur laquelle il est fixé ».
3. **`require_file` trop laxiste** — ne teste que `buftype == "nofile"` ; laisse passer `terminal`/`prompt` et ne vérifie pas l'existence disque.
4. **Réactivité split** — `apply_win_options` n'est réappliqué que sur `VimResized`, pas sur `WinResized`/`WinScrolled` (redimensionner un split ne déclenche pas `VimResized`).
5. **Dérive doc** — `statuscol.md` mentionne `NARROW_WIDTH = 120`, le code dit `100`.

## 3. Cible : `ConditionSpec` comme source unique de vérité

Étendre la struct déclarative existante. Champs **actuels** conservés ; champs **nouveaux** marqués 🆕.

```lua
---@class Ozay.Statuscol.ConditionSpec
-- existants
---@field ft_blacklist?    table<string, true>
---@field ft_whitelist?    table<string, true>
---@field require_number?  boolean
---@field require_file?    boolean
---@field ignore_float_win? boolean
---@field buf_predicate?   fun(bufnr: integer): boolean
---@field win_predicate?   fun(winid: integer): boolean
---@field predicate?       fun(args: Ozay.Statuscol.text.arg): boolean
---@field enabled?         boolean|fun(): boolean
-- nouveaux 🆕
---@field min_win_width?   integer            -- masque si largeur window <
---@field max_win_width?   integer            -- masque si largeur window >
---@field min_win_height?  integer
---@field active_only?     boolean            -- ressuscite suppress_inactive
---@field buftype_blacklist? table<string,true> -- terminal, prompt, quickfix…
---@field require_signs?   string[]           -- ex {"gitsigns.*"} : false si 0 sign
---@field after?           fun(ctx: Ozay.Statuscol.RenderCtx): boolean -- expérimental
```

## 4. Pistes détaillées

### Piste 1 — Largeur **par window** (fondation, priorité haute)

Le vrai chantier. Unifier la métrique de largeur sur `nvim_win_get_width(win)`.

- `wide_enough(win)` lit la largeur de la **window**, plus `vim.o.columns`.
- `apply_win_options(win, buf)` consomme ce même `wide_enough(win)` (aujourd'hui global).
- Conditions `min_win_width`/`max_win_width` évaluées contre `nvim_win_get_width(args.win)`.
- **Réactivité** : ajouter `WinResized` (Nvim 0.9+, fournit la liste des windows touchées via `vim.v.event.windows`) et éventuellement `WinNew`/`WinClosed`. Garder `VimResized` en filet.

**Dépendance croisée** : pour `number`, la condition seule ne récupère pas `numberwidth` → c'est `apply_win_options(win)` per-window qui doit éteindre `number` quand la window est étroite. Les deux briques doivent partager le **même** prédicat de largeur.

Décision ouverte : garder un seuil global terminal (`min_columns`) **en plus** du seuil window, ou tout basculer window ? → proposition : window par défaut, `min_columns` optionnel pour cas spéciaux.

### Piste 2 — Conscience des **éléments déjà rendus** (expérimental)

statuscol évalue les segments **en ordre, pour une même `args.tick`**. On peut donc partager un contexte de rendu :

```lua
---@class Ozay.Statuscol.RenderCtx
---@field tick integer
---@field rendered table<string, boolean>  -- nom de segment -> a rendu

-- réinitialisé quand args.tick change, clé par (win, lnum)
```

Chaque segment inscrit son nom dans `ctx.rendered` après passage de sa condition ;
les suivants interrogent via `after(ctx)`. Cas d'usage : *padding* conditionné à
l'absence de `number` ; *fold* masqué si rien à sa gauche.

**Caveats** (pourquoi marqué expérimental) :
- dépend de l'ordre `order` et du fait que statuscol n'inverse/cache pas l'éval ;
- le caching interne de statuscol peut réévaluer partiellement → ctx doit être idempotent ;
- à isoler par `(win, lnum, tick)` pour éviter les fuites entre fenêtres.

→ À traiter **en dernier**, une fois la fondation stable.

### Piste 3 — Masquer la **signcolumn vide**

Faisable proprement : les sign segments ayant une largeur **dynamique**, une condition
`false` les replie réellement.

- `require_signs = { "gitsigns.*" }` → `false` si aucun extmark de ce namespace dans le buffer.
- **Coût** : ne PAS compter les signs à chaque rendu de ligne. Compter une fois par buffer
  sur `BufWinEnter` + événements gitsigns/dap, **cache dans `vim.b[buf]`**.
- **Alternative quasi gratuite** : tester `auto = true` natif de statuscol sur le sign
  segment (= « afficher seulement s'il y a des signs »). À comparer avec le choix actuel
  `auto = false` (pourquoi avait-il été retenu ? largeur stable probablement).

### Piste 4 — `require_file` durci + fenêtre active

Quick wins déclaratifs, faible risque :

- `buftype_blacklist = { terminal = true, prompt = true, quickfix = true }`.
- `require_file` : exiger `buftype == ""` ET nom non vide (option : existence disque).
- `active_only` : `args.win == nvim_get_current_win()` → **implémente enfin** le
  `suppress_inactive` mort. Allège les windows inactives.

### Piste 5 — Axes complémentaires (backlog)

- `min_win_height`.
- Mode-aware : masquer `relativenumber` en insertion.
- Diff-aware : `vim.wo[win].diff`.
- Highlight conditionnel par segment.

## 5. Implémentation de `evaluate` (ordre des gardes proposé)

Du moins cher au plus cher (court-circuit early-return) :

1. `enabled` (global, pas d'I/O)
2. `active_only` (1 appel API)
3. `ignore_float_win`, `min/max_win_width`, `min_win_height` (config window)
4. `ft_blacklist`/`ft_whitelist`, `buftype_blacklist` (lecture `bo`)
5. `require_number`, `require_file`
6. `require_signs` (lecture cache `vim.b`, sinon comptage)
7. `buf_predicate`, `win_predicate`, `predicate` (arbitraire utilisateur)
8. `after` (contexte de rendu, expérimental)

> Rappel anti-régression : ne jamais résoudre `enabled` (fonction) via le ternaire
> `cond and f() or x` — si `f()` renvoie `false`, le `or` renvoie la fonction (truthy).
> Garder le `if type(...) == "function"` explicite.

## 6. Séquençage recommandé

1. **Fondation largeur/window** (piste 1) — corrige le bug #2/#4, débloque la demande n°1. ✅ **fait (2026-06-12)** : `wide_enough(win)` per-window + `min_win_width`/`max_win_width`/`min_columns` + autocmd `WinResized`.
2. **Quick wins déclaratifs** (piste 4) — `active_only`, `buftype_blacklist`, `require_file` durci. ✅ **fait (2026-06-12)** : champ mort `suppress_inactive` remplacé par `active_only` (`args.win == args.actual_curwin`, fail-open). `buftype_blacklist` ajouté. `require_file` durci (buftype `""` + nom non vide, sans stat disque). Mécanismes dispo, non encore câblés sur des segments précis (au choix).
3. **Signs dynamiques** (piste 3) + double-clic dap (§9). ✅ **fait (2026-06-12)** : `dap_signs` en `auto = true` (repli si vide) ; double-clic gauche sur la colonne numéro → `dap.toggle_breakpoint` via handler `Lnum` (`dap_handler.lnum_click`), `git_signs` peut aussi passer `auto = true`.
4. **Contexte inter-segments** (piste 2, expérimental). ✅ **fait (2026-06-12)** : `ConditionSpec.after(ctx)` + contexte de rendu module-level (`render_ctx`) clé `(win, lnum, tick)`. `make_condition(spec, name)` inscrit chaque segment dont la condition passe dans `ctx.rendered[name]`, et les segments d'`order` supérieur les interrogent via `after`. **Mécanisme dispo, non câblé** sur un segment précis (au choix UX, cf. exemple ci-dessous).
5. **Nettoyage** : dérive doc 120↔100 (#5), retirer le champ mort si non implémenté.

### Exemple de câblage `after` (non activé)

Masquer la colonne de folds quand rien n'a rendu à sa gauche (window étroite,
buffer sans numéro ni signs) — `fold` étant `order = 50`, tous les autres
segments ont déjà été évalués pour la ligne :

```lua
-- registry["fold"].condition
after = function(ctx)
  return ctx.rendered.number or ctx.rendered.dap_signs or ctx.rendered.git_signs
end,
```

> Caveat : `ctx.rendered.X` signifie « la *condition* de X a passé », pas « un
> glyphe est visible ». Un sign segment `auto = true` peut se replier même si sa
> condition a passé (aucun sign présent) → l'info reste approximative.

## 7. Décisions (tranchées 2026-06-12)

- **Seuil de largeur** : **window + garde-fou terminal**. `min_win_width` (window) ET
  `min_columns` (terminal global) ; un segment est masqué si l'un OU l'autre n'est pas
  satisfait.
- **`require_signs`** : on bascule sur le **`auto = true` natif** de statuscol plutôt qu'un
  cache `vim.b` maison. `auto = false` n'était retenu que pour garder la **colonne dap
  cliquable** même sans breakpoint (poser le premier point d'arrêt). → voir §8/§9 pour le
  compromis.
- **Contexte de rendu (piste 2)** : faisable **côté config** (cf. §8) ; tenté dans le fork
  `~/projects/statuscol.nvim` (« pour tenter »). Reste marqué expérimental.

## 8. Découvertes du cœur statuscol (lecture du fork)

Source : `~/projects/statuscol.nvim/lua/statuscol.lua`.

- **Éval par rendu / par ligne** (`get_statuscol_string`, l.261-267) : pour chaque segment,
  `s.cond(args)` est appelé à chaque redraw. → toute logique de condition lit un `args`
  déjà riche.
- **`args` disponibles** (l.187-205) : `win`, `wp`, `buf`, `nu`, **`nuw` (numberwidth)**,
  `rnu`, `cul`, `sclnu`, `fold.width`, **`empty`** (`win_col_off(wp) == 0`), `tick`.
- **Conséquence piste 1** : `min/max_win_width` se font **côté config** via
  `nvim_win_get_width(args.win)` dans un `predicate`. **Aucun patch du fork requis.**
  (Le repli de `numberwidth` reste, lui, l'affaire de `apply_win_options` per-window.)
- **Conséquence piste 2** : segments parcourus **dans l'ordre** avec `args.tick` → un
  contexte de rendu (table module-level clé `(win, lnum, tick)`) est réalisable **côté
  config**, sans fork. `args.empty` aide à savoir si la colonne a déjà rendu quelque chose.
- **`auto` natif** (l.224-228) : avec `auto = true`, `wss.width`/`padwidth` suivent le
  nombre de signs réels → **la colonne se replie à 0 quand vide**. C'est la piste 3, native.

### Bilan : fork vs config

| Piste | Réalisable côté config ? | Patch fork nécessaire ? |
|---|---|---|
| 1 — largeur par window | ✅ (`args.win`) | non |
| 2 — contexte inter-segments | ✅ (ctx module-level) | non (mais tenté dans le fork) |
| 3 — signcolumn vide (git) | ✅ (`auto = true`) | non |
| 3 — signcolumn vide (dap) | ⚠️ casse le clic | **oui** (voir §9) |
| 4 — `active_only`, buftype… | ✅ | non |

## 9. Double-clic sur la colonne numéro pour toggler un breakpoint (zéro fork)

Décision (minimale, sans toucher au fork) :
- **Colonne dap : comportement inchangé** — `dap_signs` et son `DapClickHandler` (gauche =
  toggle, droite = disable/enable) restent tels quels.
- **Ajout unique** : un **double-clic** (2 clics) sur la **colonne numéro** appelle
  `dap.toggle_breakpoint` sur la ligne cliquée. Simple commodité, n'enlève rien.

### Implémentation envisagée

- `number` segment (`segments.lua`) → ajouter `click = "v:lua.ScLa"` (handler lnum du cœur).
- Enregistrer un handler **`Lnum`** dans `clickhandlers` (init.lua) :
  ```lua
  Lnum = function(args)
    if args.clicks == 2 then
      require("dap").toggle_breakpoint()
    end
    -- simple clic : laissé au défaut (rien de gênant)
  end
  ```
- Le cœur a déjà placé curseur + fenêtre courante sur la ligne cliquée
  (`get_click_args`, `statuscol.lua:86-99`) → `toggle_breakpoint()` agit au bon endroit,
  pas besoin de recalculer `mousepos`.

> Conséquence sur la piste 3 (signcolumn vide) : **indépendante** de cette décision. La
> colonne dap reste en `auto = false` ; seul `git_signs` peut passer en `auto = true`.

## 10. Wiring du fork (au moment d'implémenter)

`dev.path` = `~/projects/nvim-plugins/`, mais le fork est à `~/projects/statuscol.nvim`.
Options : (a) `dir = "~/projects/statuscol.nvim"` dans le spec ; (b) symlink/déplacement
sous `~/projects/nvim-plugins/statuscol.nvim` + `dev = true`. Le spec pointe encore
`"luukvbaal/statuscol.nvim"` → à repointer sur le fork `NeOzay/statuscol.nvim`.

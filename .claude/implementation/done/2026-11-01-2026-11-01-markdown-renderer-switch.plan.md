# Plan — bascule markview / render-markdown au redémarrage

Brief : `.claude/implementation/2026-11-01-markdown-renderer-switch.brief.md` (validé).

## Relecture

```
VERDICT : NON CONFORME
CRITÈRES :
C1 (tests mini.test du fichier d'état et du routage de l'abstraction passent) → Étapes 1, 2 ; vérification de bout en bout (`make test`)
C2 (`:MarkdownRenderer render-markdown` puis redémarrage → `nil true`, et l'inverse) → Étape 4 (contrôle sans interface, fichier d'état écrit par `echo`) + Étape 2 (commande → fichier, en Neovim enfant)
C3 (sans fichier d'état, markview chargé, comportement d'aujourd'hui) → Étape 3 (contrôle sans interface) + contrôle manuel C4 de l'Étape 4
C4 (avec render-markdown actif : .md, notification snacks, preview du picker, hover LSP rendus, sans erreur dans `:messages`) → Étape 4 (contrôle manuel)
C5 (`grep -rn 'markview' lua/ init.lua` ne remonte plus rien hors de la spec et de l'adaptateur markview) → Étape 3, mais la commande de vérification ne peut pas réussir (Q1) et le filtre élargit le critère (Q2)
C6 (`:MarkdownRenderer xyz` lève une erreur, fichier intact ; sans argument, affiche le moteur actif et celui du prochain démarrage) → Étapes 1, 2
HORS-PÉRIMÈTRE : RESPECTÉ
DÉRIVE : aucun
INCERTITUDES : Équivalents render-markdown de la config par appel du hover, du `set_query` et des autocmds `@string.escape.markdown_inline` → tranchée dans « Incertitude restante du Brief — levée ici » (hover et notifier dégradés aux défauts ; `set_query` réputé couvert par `patterns.markdown.disable`, non vérifié (Q5) ; autocmds gardées propres à markview, déplacées dans `config`) ; `hook_render` laissé en « Point à trancher » avec une proposition
MODÈLE : sonnet → SOUTENU — Lua bien délimité, 5 Étapes, l'Incertitude du Brief est tranchée, vérification surtout par du code ; à revoir vers opus si l'API render-markdown citée de mémoire s'avère fausse (Q5)
QUALITÉ :
Q1 — Vérification de l'Étape 3 inexécutable : après migration, `grep -rn 'markview' lua/ init.lua` remonte toujours `init.lua:107: { import = "plugins.markview" }`, que le filtre `grep -v` n'exclut pas et que l'Étape 4 conserve. La sortie ne sera jamais vide.
Q2 — C5 réinterprété sans le dire : le filtre exclut tout `lua/markdown_renderer/` (dont `init.lua` et `state.lua`, qui portent le littéral `markview`) et `lua/highlights/markview.lua`, alors que le Brief dit « hors de la spec et de l'adaptateur markview ». La lecture élargie est sans doute la bonne intention, mais c'est à l'utilisateur de la valider.
Q3 — Intégration oubliée : `lua/plugins/codecompanion.lua:1-8` lance `vim.cmd("Markvie attach")` sur `FileType codecompanion`, au chargement du module. Avec render-markdown actif, markview n'est pas chargé et l'erreur E492 tombe à chaque buffer codecompanion. Ce cas contredit la Décision « les intégrations qui appellent markview en dur passent aussi par render-markdown » et le But (« toutes les intégrations »). Aucune Étape ne nomme ce fichier, et le grep en minuscules de C5 ne le détecte pas.
Q4 — Mise en forme : dans le plan, l'Étape 2 est collée sur la même ligne que la vérification de l'Étape 1 (« …test_markdown_renderer.lua`2. **Commande… »). Le Suivi qui reprendra les Étapes risque de la fusionner ou de la perdre.
Q5 — Affirmations non vérifiables dans le dépôt : render-markdown n'est pas installé dans `~/.local/share/nvim/lazy/`. `render({ buf, win })`, `render.md.render.Context`, `lua/render-markdown/api.lua` et `patterns.markdown.disable = true` sont cités de mémoire, alors que la levée de l'Incertitude sur `set_query` en dépend. Point non traité non plus : l'appel explicite de `render` sur un buffer déjà attaché par `file_types` (notifier `snacks_notif`, hover `markdown`).
Q6 — Étape 4 : ni l'installation de render-markdown (`:Lazy install`) ni `lazy-lock.json` ne figurent dans l'Étape. La première vérification sans interface risque de lancer une installation lazy silencieuse.
Q7 — Étape 1 : rien n'indique comment `active()`, `next()` et `set_next()` (qui n'ont pas de paramètre `path`) visent un fichier sous `vim.fn.tempname()`. Seul `state.lua` est paramétré, donc les tests de routage risquent d'écrire dans le fichier d'état réel de l'utilisateur.
Q8 — Étape 3 : « `filetypes` lus depuis `FILETYPES` » est ambigu. `preview.filetypes` vaut déjà `FILETYPES`, mais le `ft` de la spec markview n'a pas `Avante`. Si `ft` est aligné, c'est un changement de comportement (sans effet réel, la spec étant `lazy = false`, mais contraire à l'esprit de S6).
Q9 — Étape 3 : le `b = { markview = true }` du hover passe d'une option de fenêtre snacks à une affectation `vim.b[buf].markview = true` « dans `hover()` ». On ne sait pas si c'est la fonction de `lua/lsp/hover/init.lua` (qui resterait alors dans le grep de C5) ou celle de l'adaptateur.
Q10 — Étape 5 : `docs/plugins/snacks.md` (l. 27, 50), `docs/plugins/listdir.md` (l. 48-49, cite `markview_fts`) et `docs/plugins/codecompanion.md` décrivent les intégrations markview que le chantier modifie, mais l'Étape ne les met pas à jour (règle de maintenance de la doc dans CLAUDE.md, pas une exigence du Brief).
Q11 — Citation imprécise : `rules/lua-style.md` n'existe pas dans le dépôt ; le fichier est `~/.claude/rules/lua-style.md`.
```

Corrigés sans arbitrage (défauts de rédaction) : Q4 (Étape 2 remise sur sa ligne), Q11 (chemin
de la règle de style). Note sur Q5 : l'API `render(ctx)` / `render.md.render.Context` a été lue
dans `lua/render-markdown/api.lua` upstream et `patterns.markdown.disable` dans le README upstream
(WebFetch, branche `main`), non dans le dépôt — la vérification dans le code installé reste à faire.

Arbitrages de l'utilisateur :

- **Q1, Q2** — lecture élargie de C5 : aucun appel à markview hors de sa spec, de son adaptateur,
  de ses highlights, de l'import dans `init.lua`, et du nom en tant que donnée dans
  `lua/markdown_renderer/` ; grep en `-i` sur `markvie` pour attraper aussi `:Markvie[w]`.
- **Q3** — `lua/plugins/codecompanion.lua` passe par l'abstraction : nouvelle fonction `attach(buf)`
  (markview → `:Markview attach` ; render-markdown → rien, il s'attache par `file_types`).
- **Point à trancher (floats non demandés)** — défauts de render-markdown : ils seront rendus.
- **Q7** — retenu : `_reset(path?)` redirige `active`/`next`/`set_next` vers un fichier temporaire.
- **Q8, Q9** — retenus : seul `preview.filetypes` lit `FILETYPES`, le `ft` de la spec markview
  reste tel quel ; `vim.b[buf].markview = true` est posé dans l'adaptateur.
- **Q10** — retenu : l'Étape 5 met aussi à jour `docs/plugins/snacks.md`, `listdir.md`, `codecompanion.md`.
- **Q5, Q6** — non retenus : pas d'Étape d'installation explicite ni de vérification de l'API
  installée ; `lazy-lock.json` suit le cours normal de lazy.

## Context

markview est câblé en dur : sa spec (`lua/plugins/markview.lua`) et trois intégrations qui
l'appellent directement — notifier snacks (`lua/plugins/snacks/notifier.lua:36-59`), preview du
picker (`lua/plugins/snacks/picker/init.lua:4,62-66`), hover LSP (`lua/lsp/hover/init.lua:149,181-191`) — plus le `:Markvie attach` de
`lua/plugins/codecompanion.lua:1-8`, relevé à la relecture.
On veut tester render-markdown.nvim pour comparer ses rendus et comportements : une commande
`:MarkdownRenderer <moteur>` écrit le choix dans un fichier d'état, le démarrage suivant ne charge
que ce moteur, et les intégrations passent par une abstraction qui route vers le moteur actif.

Rappel du Brief : critères C1–C6, signaux S1–S6. Hors-périmètre : la configuration du rendu de
render-markdown (seuls filetypes et couleurs), toute bascule à chaud, tout fork de render-markdown.

## Modèle

**Sonnet** — code Lua bien délimité, chaque Étape a une commande de vérification, le Plan tranche
l'incertitude restante du Brief, 5 Étapes.

## Architecture

### Fichier d'état

`vim.fs.joinpath(vim.fn.stdpath("state"), "markdown-renderer")` : une ligne, le nom du moteur.
Absent, illisible ou valeur inconnue → `markview` (Décision du Brief).

### Module `lua/markdown_renderer/`

- `state.lua` — `read(path?) -> Ozay.MarkdownRenderer.Engine` (défaut `markview`),
  `write(engine, path?)`. `path` par défaut = le fichier d'état ; paramètre pour les tests.
- `init.lua` — le point d'entrée de tout le reste :
  - `ENGINES = { "markview", "render-markdown" }` ; `FILETYPES = { "markdown", "Avante", "codecompanion", "snacks_notif" }` (source unique : les deux specs et le picker la lisent) ;
  - `active()` — le moteur du démarrage, lu une fois puis mis en cache (ne bouge plus de la session : pas de bascule à chaud, S4) ;
  - `is_active(engine)` — pour le `cond` des specs ;
  - `next()` — relit le fichier (moteur du prochain démarrage) ;
  - `set_next(engine)` — valide contre `ENGINES` (erreur sinon, fichier intact : C6), écrit ;
  - `render_notification(buf, win)`, `render_preview(buf, win)`, `render_hover(buf, win)`,
    `attach(buf)` — délèguent à `require("markdown_renderer." .. adapter)[kind](...)` où
    l'adaptateur est `markview` ou `render_markdown` selon `active()` ;
  - `_reset(path?)` `@private` — vide le cache et fixe le chemin du fichier d'état utilisé par
    `active`/`next`/`set_next` (défaut : le fichier réel) ; les tests passent un `vim.fn.tempname()`.
- `markview.lua` — adaptateur : le code markview **déplacé tel quel** depuis les trois
  intégrations (S6) : `render` + `set_query` du notifier avec sa config, `render` + `set_query`
  du picker, `render` du hover avec sa config `{ enable = true, hybrid_mode = false }` + config
  markdown. La garde `package.loaded["markview"]` y descend aussi. Le `b = { markview = true }`
  du hover devient `vim.b[buf].markview = true` dans la fonction `hover()` **de l'adaptateur**
  (rien dans `plugins/markview.nvim/lua` ne lit cette variable : grep vide). `attach(buf)` y porte
  le `vim.cmd("Markvie attach")` de `lua/plugins/codecompanion.lua:1-8` (le `vim.defer_fn` reste
  dans l'autocmd de codecompanion).
- `render_markdown.lua` — adaptateur : les trois fonctions appellent
  `require("render-markdown").render({ buf = buf, win = win })` (API `render.md.render.Context`,
  `lua/render-markdown/api.lua` upstream), **sans `config`** : régler le rendu est hors-périmètre
  (S1). Pas d'équivalent de `set_query` : render-markdown désactive déjà par défaut les directives
  `conceal_lines` du markdown (`patterns.markdown.disable = true`) — ce que `set_query` obtenait à
  la main. `attach(buf)` ne fait rien : render-markdown s'attache par `file_types`, où figure
  `codecompanion`. Garde `package.loaded["render-markdown"]`.

Types préfixés `Ozay.` (`Ozay.MarkdownRenderer.Engine` en `@alias` de littéraux, `Ozay.MarkdownRenderer`
pour le module), conformément à CLAUDE.md et `~/.claude/rules/lua-style.md`.

### Incertitude restante du Brief — levée ici

| Mécanisme markview | Côté render-markdown |
|---|---|
| config par appel du hover / du notifier | aucune (`render` sans `config`) — rendu laissé aux défauts (hors-périmètre) |
| `set_query` (fence lines) notifier + picker | rien : `patterns.markdown.disable` par défaut fait l'équivalent |
| autocmds `@string.escape.markdown_inline` | restent propres à markview : déplacées du niveau module dans le `config` de sa spec, donc absentes quand render-markdown est actif (S3) |
| `hook_render` (pas de rendu des floats markdown non demandés, ex. signature help) | aucun équivalent posé : render-markdown attache selon `file_types`, ses défauts décident — ces floats seront rendus (arbitrage, voir Relecture) |

### Chargement

- Les deux specs portent `cond = function() return require("markdown_renderer").is_active("<moteur>") end`.
  `cond` et non `enabled` : un plugin `enabled = false` est supprimé par `:Lazy clean` et réinstallé
  à la bascule suivante ; `cond = false` le garde installé sans le charger.
- render-markdown : `"MeanderingProgrammer/render-markdown.nvim"`, `ft = FILETYPES`,
  `dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" }` (déjà
  installés), `opts = { file_types = FILETYPES }`, rien d'autre (S1). Import ajouté dans `init.lua`
  à côté de `plugins.markview`.
- Couleurs : `lua/highlights/render-markdown.lua` (prioritaire sur `lua/base46/integrations/render-markdown.lua`,
  chargé au `LazyLoad` par `load_matching` — `render-markdown.nvim` contient `render-markdown`).
  Transposition de `lua/highlights/markview.lua` :
  `MarkviewHeadingN` → `RenderMarkdownHN` (fg, bold) + `RenderMarkdownHNBg` (bg `one_bg2`, fg) ;
  `MarkviewCode`/`CodeInfo`/`InlineCode` → `RenderMarkdownCode`/`CodeInfo`/`CodeInline` ;
  block quotes → `RenderMarkdownQuote` + `Info`/`Success`/`Hint`/`Warn`/`Error` ;
  `ListItemMinus` → `RenderMarkdownBullet` ; checkboxes → `Checked`/`Unchecked`/`Todo` ;
  tables → `TableHead`/`TableRow` ; `Hyperlink` → `RenderMarkdownLink`/`WikiLink`.
  Palette et gradients markview : sans équivalent, non transposés.

### Commande

`:MarkdownRenderer [moteur]` dans `lua/cmd.lua`, `nargs = "?"`, complétion sur `ENGINES`.
Avec argument → `set_next`, notifie « prochain démarrage : <moteur> ». Sans argument → notifie
« actif : <a> · prochain démarrage : <n> ». Argument inconnu → erreur, fichier intact (C6).

## Étapes

1. **État et abstraction, testés** — `lua/markdown_renderer/state.lua`, `lua/markdown_renderer/init.lua`,
   `tests/markdown_renderer/test_markdown_renderer.lua`. Adaptateurs non écrits : les tests de
   routage injectent des adaptateurs factices par `package.loaded["markdown_renderer.markview"]` /
   `["markdown_renderer.render_markdown"]`. Cas : fichier absent → markview ; valeur inconnue →
   markview ; écriture puis relecture ; `set_next("xyz")` → erreur et fichier inchangé ;
   `active()` figé après un `set_next` ; chaque `render_*` et `attach` atteint l'adaptateur du
   moteur actif et lui seul. Chaque cas commence par `_reset(vim.fn.tempname())` : aucun test ne
   lit ni n'écrit le fichier d'état réel.
   — vérif: `make test-file FILE=tests/markdown_renderer/test_markdown_renderer.lua`
2. **Commande `:MarkdownRenderer`** — `lua/cmd.lua` ; cas de test ajoutés au fichier de l'Étape 1
   (Neovim enfant `MiniTest.new_child_neovim()`, `XDG_STATE_HOME` temporaire) : avec argument, sans
   argument, argument inconnu, complétion.
   — vérif: même commande que l'Étape 1
3. **Adaptateur markview et migration des intégrations** — `lua/markdown_renderer/markview.lua`,
   `lua/plugins/snacks/notifier.lua`, `lua/plugins/snacks/picker/init.lua`, `lua/lsp/hover/init.lua`,
   `lua/plugins/codecompanion.lua` (autocmd → `attach(buf)`),
   `lua/plugins/markview.lua` (`cond`, autocmds d'escape déplacées dans `config`, `preview.filetypes`
   lu depuis `FILETYPES` ; le `ft` de la spec reste tel quel). Le picker remplace `markview_fts`
   par `FILETYPES`. Le `vim.treesitter.language.register("markdown", ft)` du notifier reste
   dans l'intégration, avant l'appel à l'abstraction : il ne dépend d'aucun moteur.
   — vérif: `grep -rni 'markvie' lua/ init.lua | grep -v -e '^lua/plugins/markview.lua:' -e '^lua/markdown_renderer/' -e '^lua/highlights/markview.lua:' -e '^init.lua:[0-9]*:.*import = "plugins.markview"'` vide (C5, lecture élargie), puis `XDG_STATE_HOME=$(mktemp -d) nvim --headless docs/plugins/markview.md -c 'lua io.write(tostring(package.loaded.markview ~= nil))' -c qa` → `true` (C3)
4. **render-markdown : spec, adaptateur, couleurs** — `lua/plugins/render-markdown.lua`, `init.lua`
   (import), `lua/markdown_renderer/render_markdown.lua`, `lua/highlights/render-markdown.lua`.
   — vérif: `S=$(mktemp -d); mkdir -p $S/nvim; echo render-markdown > $S/nvim/markdown-renderer; XDG_STATE_HOME=$S nvim --headless docs/plugins/markview.md -c 'lua io.write(tostring(package.loaded.markview), " ", tostring(package.loaded["render-markdown"] ~= nil))' -c qa` → `nil true` (C2) ; puis contrôle manuel C4 (`.md`, notification markdown, preview picker, hover LSP, `:messages` vide) dans les deux moteurs.
5. **Documentation** — `docs/plugins/render-markdown.md` (gabarit de CLAUDE.md), `docs/plugins/markview.md`
   (cond, abstraction, autocmds déplacées), `docs/plugins/snacks.md`, `docs/plugins/listdir.md`
   (`markview_fts` → `FILETYPES`), `docs/plugins/codecompanion.md` (intégrations passées par
   l'abstraction), `CLAUDE.md` (index des plugins, `:MarkdownRenderer` dans Global Helpers).
   — vérif: `grep -n 'MarkdownRenderer\|render-markdown\|markdown_renderer' CLAUDE.md docs/plugins/{markview,render-markdown,snacks,listdir,codecompanion}.md` (une occurrence au moins par fichier) et `grep -n 'markview_fts' docs/plugins/listdir.md` vide

## Vérification de bout en bout

- C1 : `make test` (tous les tests, dont `tests/markdown_renderer/`).
- C2, C3 : commandes headless des Étapes 3 et 4, sous `XDG_STATE_HOME` temporaire — le fichier
  d'état réel de l'utilisateur n'est jamais touché par la vérification.
- C4 : contrôle manuel dans les deux moteurs (redémarrage entre les deux).
- C5 : grep de l'Étape 3 (lecture élargie arbitrée en Relecture).
- C6 : tests de l'Étape 2.

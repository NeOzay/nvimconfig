+++
gabarit = "suivi"
slug = "2026-11-01-markdown-renderer-switch"
titre = "Ajouter render-markdown.nvim et pouvoir basculer entre lui et markview après un redémarrage"
branche = "2026-11-01-markdown-renderer-switch"
base = "master"
statut = "terminé"
session = 2
lettre = "A"
"modèle" = "sonnet"
plan = ".claude/implementation/done/2026-11-01-2026-11-01-markdown-renderer-switch.plan.md"
brief = ".claude/implementation/done/2026-11-01-2026-11-01-markdown-renderer-switch.brief.md"
audit = ".claude/implementation/done/2026-11-01-2026-11-01-markdown-renderer-switch.audit"
skills = ["nvim-mini-test"]
"créé" = 2026-11-01
maj = 2026-11-01
+++

## Objectif et périmètre

**Symptôme** : je veux tester render-markdown.nvim et comparer ses rendus et comportements à ceux de markview, ce que la config ne permet pas aujourd'hui — markview y est câblé en dur.

**But** : pouvoir choisir, par une commande, le moteur de rendu markdown (markview ou render-markdown) qui sera seul chargé au prochain démarrage, toutes les intégrations suivant ce choix.

**Critères de réussite** :

- **C1** — Les tests mini.test du fichier d'état et du routage de l'abstraction passent : `nvim --headless -u tests/minimal_init.lua -c "lua MiniTest.run()"` (ou ciblé sur leur dossier).
- **C2** — Après `:MarkdownRenderer render-markdown` puis redémarrage, `:lua =package.loaded.markview, package.loaded["render-markdown"] ~= nil` donne `nil true` ; l'inverse après `:MarkdownRenderer markview`.
- **C3** — Sans fichier d'état, markview est chargé et le comportement est celui d'aujourd'hui.
- **C4** — Avec render-markdown actif : un `.md`, une notification snacks en markdown, la preview du picker sur un `.md` et un hover LSP sont rendus par render-markdown, sans erreur dans `:messages`.
- **C5** — `grep -rn 'markview' lua/ init.lua` ne remonte plus rien hors de la spec et de l'adaptateur markview. *(Lecture élargie arbitrée à la relecture du Plan : voir Journal.)*
- **C6** — `:MarkdownRenderer xyz` lève une erreur et laisse le fichier d'état inchangé ; sans argument, la commande affiche le moteur actif et celui du prochain démarrage.

**Hors-périmètre** :

- La configuration du rendu de render-markdown (puces, blocs de code, paddings…) : ses défauts suffisent, l'utilisateur la réglera lui-même. *(Élargi le 2026-11-01 : l'utilisateur a réglé le rendu dans `lua/plugins/render-markdown.lua` pendant le Chantier et ratifie l'écart ; la config de rendu y est désormais à lui, l'agent n'y touche pas — voir Journal.)*
- Une bascule à chaud, sans redémarrage.
- Un fork ou un submodule de render-markdown.

**Signaux de dérive** :

- **S1** — Le diff règle des options de rendu de render-markdown (puces, blocs de code, paddings…) au-delà des filetypes et des highlights. *(Levé le 2026-11-01 pour les réglages de l'utilisateur dans `lua/plugins/render-markdown.lua`, ratifiés ; reste valable pour tout réglage ajouté par l'agent.)*
- **S2** — Une intégration (notifier, picker, hover) appelle encore `require("markview…")` ou teste `package.loaded.markview` hors de l'abstraction.
- **S3** — Le moteur inactif laisse une trace au démarrage : `setup` appelé, spec sans `cond` lié à l'état, ou les `Userautocmd` d'escape au niveau module, exécutés à l'import même avec `cond = false`.
- **S4** — Un mécanisme de bascule à chaud apparaît : déchargement de module, `setup` relancé par la commande.
- **S5** — Un commit touche le submodule `plugins/markview.nvim`.
- **S6** — Le comportement de markview change quand il est actif : `hook_render`, `set_query` ou la config du hover modifiés au lieu d'être déplacés.

## Étapes

- [x] 1. État et abstraction, testés — `lua/markdown_renderer/state.lua`, `lua/markdown_renderer/init.lua`, `tests/markdown_renderer/test_markdown_renderer.lua` — vérif: `make test-file FILE=tests/markdown_renderer/test_markdown_renderer.lua`
- [x] 2. Commande `:MarkdownRenderer` — `lua/cmd.lua`, `tests/markdown_renderer/test_markdown_renderer.lua` — vérif: `make test-file FILE=tests/markdown_renderer/test_markdown_renderer.lua`
- [x] 3. Adaptateur markview et migration des intégrations — `lua/markdown_renderer/markview.lua`, `lua/plugins/snacks/notifier.lua`, `lua/plugins/snacks/picker/init.lua`, `lua/lsp/hover/init.lua`, `lua/plugins/codecompanion.lua`, `lua/plugins/markview.lua` — vérif: grep C5 de l'Étape 3 du Plan vide, puis `XDG_STATE_HOME=$(mktemp -d) nvim --headless docs/plugins/markview.md -c 'lua io.write(tostring(package.loaded.markview ~= nil))' -c qa` → `true`
- [x] 4. render-markdown : spec, adaptateur, couleurs — `lua/plugins/render-markdown.lua`, `init.lua`, `lua/markdown_renderer/render_markdown.lua`, `lua/highlights/render-markdown.lua` — vérif: headless C2 de l'Étape 4 du Plan → `nil true`, puis contrôle manuel C4 dans les deux moteurs
- [x] 5. Documentation — `docs/plugins/{render-markdown,markview,snacks,listdir,codecompanion}.md`, `CLAUDE.md` — vérif: grep de l'Étape 5 du Plan

## État courant

**Prochaine action** : Clôture sur demande de l'utilisateur, sans nouvel audit : commit des modifications en attente, puis aplatissement sur `master`.
**Vérification** : `make test`, puis les contrôles headless C2/C3 sous `XDG_STATE_HOME` temporaire.
**Dernier audit** : 7ccf9e1 — DÉFAVORABLE — 2026-11-01
**Notes** : aucune.

## Passation

**Écrite** : session 1, après AE0

**En cours** : rien — l'Étape 1 n'a pas commencé.

**À savoir** :

- Modèle des tests de commande en Neovim enfant (Étape 2) : `tests/lexique/test_lexique.lua` ; `lua/markdown_renderer/` est sous le `lua/` racine, déjà au runtimepath par `tests/minimal_init.lua` (`rtp:prepend(getcwd())`), rien à y ajouter.
- Le submodule snacks fait lui-même `pcall(require, "markview")` puis `strict_render` (`plugins/snacks.nvim/lua/snacks/picker/util/markdown.lua:15,53`) : avec `cond = false`, markview n'est pas au runtimepath et le `pcall` échoue sans bruit. Hors-périmètre (submodule, S5) — ne pas y toucher, mais ne pas s'en étonner au grep.
- `lua/base46/integrations/render-markdown.lua` existe déjà (titres en fg + `H{N}Bg` mixés) : `lua/highlights/render-markdown.lua` le remplace entièrement (priorité user), donc y redéfinir aussi les `@markup.heading.N.markdown` si on veut les garder.
- L'API render-markdown (`render(ctx)`, `patterns.markdown.disable`) a été lue sur l'upstream `main`, pas dans le code installé : si la version installée par lazy diffère, le signaler avant d'adapter (bascule vers Opus suggérée par la relecture dans ce cas).

## Dettes écartées

- R1 — la spec de render-markdown règle le rendu au-delà de `file_types` : réglages de l'utilisateur, écart au Brief ratifié par lui — 2026-11-01

## Journal de décisions

- **2026-11-01** — Les specs portent `cond` lié au fichier d'état, pas `enabled`. *Pourquoi* : `cond = false` garde le plugin installé sans le charger. *Rejeté* : `enabled = false`, que `:Lazy clean` supprimerait et qu'il faudrait réinstaller à chaque bascule.
- **2026-11-01** — C5 lu au sens large (arbitrage de l'utilisateur à la relecture du Plan) : aucun appel à markview hors de sa spec, de son adaptateur, de ses highlights, de l'import dans `init.lua` et du nom en tant que donnée dans `lua/markdown_renderer/` ; grep en `-i` sur `markvie`. *Pourquoi* : la lecture stricte est inatteignable sans contorsion. *Rejeté* : lecture stricte.
- **2026-11-01** — les floats markdown non demandés (signature help) sont rendus par render-markdown avec la config de l'utilisateur, contrairement à markview avec `hook_render`. *Pourquoi* : c'est un comportement à comparer, et le régler relève de l'utilisateur. *Rejeté* : une option `ignore` qui imite `hook_render`.
- **2026-11-01** — L'adaptateur render-markdown rend deux fois (immédiat, puis après 150 ms). *Pourquoi* : un rendu demandé dans le `debounce` (100 ms) d'une mise à jour déjà lancée à l'ouverture du float est ignoré ; vérifié en headless. *Rejeté* : régler `debounce` (hors-périmètre, S1).
- **2026-11-01** — L'adaptateur render-markdown surveille `WinScrolled` par fenêtre qu'il rend, avec un rendu final 150 ms après le dernier défilement. *Pourquoi* : l'autocmd de render-markdown est local au buffer et Neovim ne le déclenche que pour la fenêtre courante : la preview du picker ne rendait que les lignes visibles au chargement (constaté par l'utilisateur, reproduit et testé en Neovim enfant). *Rejeté* : régler `debounce` ou la config du plugin (hors-périmètre, S1).
- **2026-11-01** — L'étiquette de langage des blocs de code (`RenderMarkdownCodeLanguage`) ne porte que `fg` ; son fond n'est pas réglable. *Pourquoi* : le plugin empile `RenderMarkdownCodeBorder` après le groupe de langage, et la ligne de la fence en prend la couleur. *Rejeté* : fond propre à l'étiquette, qui colorerait toute la ligne de la fence.
- **2026-11-01** — Périmètre élargi : les réglages de rendu de render-markdown de l'utilisateur (`opts` de `lua/plugins/render-markdown.lua`) sont ratifiés, S1 levé pour eux. *Pourquoi* : l'audit 7ccf9e1 (DÉFAVORABLE, R1 seul bloquant, C1–C6 atteints) les relevait ; l'utilisateur les a écrits pour comparer les moteurs sur un rendu qu'il veut. *Rejeté* : ramener `opts` à `file_types`. L'utilisateur clôt sans nouvel audit.

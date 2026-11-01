+++
gabarit = "brief"
slug = "2026-11-01-markdown-renderer-switch"
titre = "Ajouter render-markdown.nvim et pouvoir basculer entre lui et markview après un redémarrage"
statut = "validé"
"créé" = 2026-11-01
+++

## Intention

**Symptôme** : je veux tester render-markdown.nvim et comparer ses rendus et comportements à ceux de markview, ce que la config ne permet pas aujourd'hui — markview y est câblé en dur.

**But** : pouvoir choisir, par une commande, le moteur de rendu markdown (markview ou render-markdown) qui sera seul chargé au prochain démarrage, toutes les intégrations suivant ce choix.

## Critères de réussite

- **C1** — Les tests mini.test du fichier d'état et du routage de l'abstraction passent : `nvim --headless -u tests/minimal_init.lua -c "lua MiniTest.run()"` (ou ciblé sur leur dossier).
- **C2** — Après `:MarkdownRenderer render-markdown` puis redémarrage, `:lua =package.loaded.markview, package.loaded["render-markdown"] ~= nil` donne `nil true` ; l'inverse après `:MarkdownRenderer markview`.
- **C3** — Sans fichier d'état, markview est chargé et le comportement est celui d'aujourd'hui.
- **C4** — Avec render-markdown actif : un `.md`, une notification snacks en markdown, la preview du picker sur un `.md` et un hover LSP sont rendus par render-markdown, sans erreur dans `:messages`.
- **C5** — `grep -rn 'markview' lua/ init.lua` ne remonte plus rien hors de la spec et de l'adaptateur markview.
- **C6** — `:MarkdownRenderer xyz` lève une erreur et laisse le fichier d'état inchangé ; sans argument, la commande affiche le moteur actif et celui du prochain démarrage.

## Hors-périmètre

- La configuration du rendu de render-markdown (puces, blocs de code, paddings…) : ses défauts suffisent, l'utilisateur la réglera lui-même. (dit)
- Une bascule à chaud, sans redémarrage. (dit)
- Un fork ou un submodule de render-markdown. (dit)

## Signaux de dérive

- **S1** — Le diff règle des options de rendu de render-markdown (puces, blocs de code, paddings…) au-delà des filetypes et des highlights. (dit)
- **S2** — Une intégration (notifier, picker, hover) appelle encore `require("markview…")` ou teste `package.loaded.markview` hors de l'abstraction. (dit) (dépôt: lua/plugins/snacks/notifier.lua, lua/plugins/snacks/picker/init.lua, lua/lsp/hover/init.lua)
- **S3** — Le moteur inactif laisse une trace au démarrage : `setup` appelé, spec sans `cond` lié à l'état, ou les `Userautocmd` d'escape au niveau module, exécutés à l'import même avec `cond = false`. (dit) (dépôt: lua/plugins/markview.lua)
- **S4** — Un mécanisme de bascule à chaud apparaît : déchargement de module, `setup` relancé par la commande. (dit)
- **S5** — Un commit touche le submodule `plugins/markview.nvim`. (dit) (dépôt: CLAUDE.md)
- **S6** — Le comportement de markview change quand il est actif : `hook_render`, `set_query` ou la config du hover modifiés au lieu d'être déplacés. (dit) (dépôt: lua/plugins/markview.lua)

## Contraintes connues de l'utilisateur

- **Décision** : la bascule passe par une commande avec argument, qui écrit le choix dans un fichier d'état ; le démarrage le relit. (dit)
- **Décision** : le moteur inactif n'est pas chargé du tout par lazy, pour éviter les conflits. (dit)
- **Décision** : les intégrations qui appellent markview en dur passent aussi par render-markdown quand il est actif ; une abstraction peut simplifier la bascule. (dit) — appels concernés : notifier snacks (dépôt: lua/plugins/snacks/notifier.lua:39), preview du picker (dépôt: lua/plugins/snacks/picker/init.lua:64), hover LSP (dépôt: lua/lsp/hover/init.lua:182), hook de rendu par buffer (dépôt: lua/plugins/markview.lua `hook_render`).
- **Décision** : render-markdown vient de l'upstream `MeanderingProgrammer/render-markdown.nvim`, installé par lazy ; markview reste le fork en submodule. (dit) (dépôt: lua/plugins/markview.lua)
- **Décision** : seules les couleurs de render-markdown sont ajustées, transposées depuis celles de markview. (dit) (dépôt: lua/highlights/markview.lua)
- **Décision** : render-markdown reprend les filetypes de markview : `markdown`, `Avante`, `codecompanion`, `snacks_notif`. (dit) (dépôt: lua/plugins/markview.lua)
- **Décision** : fichier d'état absent ou illisible → markview. (dit)
- **Décision** : la commande s'appelle `:MarkdownRenderer`, son argument est le nom du moteur (`markview` ou `render-markdown`). (dit)
- **Décision** : tests mini.test sous `tests/` pour le fichier d'état et pour le routage de l'abstraction vers le moteur actif. (dit) (dépôt: tests/minimal_init.lua)

## Incertitudes à lever en plan

- Équivalents render-markdown des mécanismes propres à markview : la config par appel du hover (dépôt: lua/lsp/hover/init.lua:182), le `set_query` qui cache les fence lines du notifier et du picker (dépôt: lua/plugins/snacks/notifier.lua:58), les autocmds sur `@string.escape.markdown_inline` (dépôt: lua/plugins/markview.lua). Ce qui n'a pas d'équivalent : dégrader ou reporter ?

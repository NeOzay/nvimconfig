+++
id = "listdir-front-matter-non-referme"
title = "`listdir` lit un front matter non refermé sans le signaler"
date = 2026-08-29
reviewed = 2026-08-29
category = "pertinent"
+++

## Vérifié par

Deux fichiers, l'un au front matter non refermé, l'autre sain, passés à la fonction de lecture :

```
$ T=$(mktemp -d)
$ printf '+++\ntitle = "cassé"\n\ncorps sans délimiteur fermant\n' > "$T/x.md"
$ printf '+++\ntitle = "sain"\n+++\n\ncorps normal\n' > "$T/y.md"
$ nvim --headless -u tests/minimal_init.lua -c "lua
package.path = './plugins/listdir/lua/?.lua;./plugins/listdir/lua/?/init.lua;' .. package.path
local item = require('listdir.item')
for _, f in ipairs({ 'x', 'y' }) do
  local r = item.read('$T/' .. f .. '.md')
  print(f, '-> ' .. vim.inspect(r, { newline = ' ', indent = '' }))
end" -c qa
x -> { body = "", fields = { title = "cassé" } }
y -> { body = "corps normal", fields = { title = "sain" } }
```

## Verdict

Le constat tient exactement : sur `x`, tout le fichier est consommé comme front matter, `body`
ressort vide, `title` est lu normalement, et **aucun champ d'erreur n'est rendu** — la table
retournée ne porte que `body` et `fields`. L'échec est indiscernable d'un élément au corps vide,
comme l'entrée le décrit.

L'entrée ne nomme aucune fonction : son Constat cite le module `item.lua` seul, ce qui est exact et
ne se périme pas. La première tentative de vérification a bien échoué sur `item.parse`, mais ce nom
venait de l'entrée **`listdir-sans-tests`**, pas de celle-ci — l'API publique expose `M.read`,
`M.title` et `M.clear`, `parse` étant une fonction locale non exportée.

## Action

Reste au registre avec ses deux champs de revue. **Aucune correction de contenu** : l'entrée est
exacte telle qu'écrite. La correction `item.parse` → `item.read` porte sur
[[listdir-sans-tests]] seule.

## Arbitrage

**2026-08-29 — sans objet.** La correction annoncée n'avait pas lieu d'être : la fiche attribuait à
cette entrée une citation fautive qui appartient à [[listdir-sans-tests]]. Verdict et entrée
inchangés ; c'est la fiche qui a été rectifiée.

+++
id = "listdir-decouverte-synchrone"
title = "La découverte des répertoires-listes bloque l'interface une seconde"
date = 2026-08-29
reviewed = 2026-08-29
category = "pertinent"
+++

## Vérifié par

Le parcours est bien synchrone — `vim.fs.dir` consommé dans une boucle `for`, sans callback :

```
$ sed -n '63,71p' plugins/listdir/lua/listdir/discover.lua
	for _, root in ipairs(paths) do
			for name, kind in vim.fs.dir(root, { depth = depth, skip = skip }) do
```

Mesuré à nouveau, `depth = 10`, sur le dépôt puis sur `$HOME` :

```
$ nvim --headless -u tests/minimal_init.lua -c "lua
package.path = './plugins/listdir/lua/?.lua;./plugins/listdir/lua/?/init.lua;' .. package.path
require('listdir').setup({ depth = 10 })
local d = require('listdir.discover')
local t0 = vim.uv.hrtime(); local r1 = d.find({ vim.fn.getcwd() }, 10); local t1 = vim.uv.hrtime()
print(('depot : %d listes, %.0f ms'):format(#r1, (t1-t0)/1e6))
local t2 = vim.uv.hrtime(); local r2 = d.find({ vim.env.HOME }, 10); local t3 = vim.uv.hrtime()
print(('HOME  : %d listes, %.0f ms'):format(#r2, (t3-t2)/1e6))" -c qa
depot : 4 listes, 22 ms
HOME  : 7 listes, 992 ms
```

Et la spec livrée pose toujours la profondeur mise en cause :

```
$ grep -n 'depth' lua/plugins/listdir.lua
7:			depth = 10,
```

## Verdict

Le constat tient, et les chiffres d'origine se confirment : ~1 s sur `$HOME` (992 ms mesurés contre
« ~1 s » annoncés), quelques dizaines de ms sur le dépôt (22 ms contre 32 ms annoncés — l'écart
tient à la machine et au cache, pas au code).

`pertinent` et non `aggravee` : la mesure n'est pas supérieure à celle du constat d'origine, elle
lui est conforme. Rien ne s'est étendu.

À noter que ce dépôt compte désormais 4 répertoires-listes (les trois registres plus une liste de
revue), contre un seul au moment du constat — sans que le temps de parcours en dépende, ce qui
confirme le point de l'entrée : le coût suit la taille de l'arborescence, pas le nombre de listes.

## Action

Rien à écrire au registre hors les deux champs de revue. Le **Pour solder** est actionnable
(finder asynchrone de Snacks, ou mémorisation du scan).

## Arbitrage

<OPTIONNEL>

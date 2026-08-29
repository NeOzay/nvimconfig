+++
id = "listdir-cache-document-homonyme"
title = "Deux répertoires-listes homonymes partagent le document concaténé de `listdir`"
date = 2026-08-29
reviewed = 2026-08-29
category = "pertinent"
+++

## Vérifié par

`M.path` ne dérive le nom que de `contract.name`, sans rien du chemin de la liste :

```
$ sed -n '96,99p' plugins/listdir/lua/listdir/document.lua
function M.path(contract)
	local name = contract.name:gsub("[^%w%-_.]", "_")
	return vim.fs.joinpath(vim.fn.stdpath("cache") --[[@as string]], CACHE, name .. ".md")
end
```

Exécuté, sur deux contrats de même nom qui seraient ceux de deux listes distinctes :

```
$ nvim --headless -u tests/minimal_init.lua -c "lua
package.path = './plugins/listdir/lua/?.lua;./plugins/listdir/lua/?/init.lua;' .. package.path
local doc = require('listdir.document')
print(doc.path({ name = 'demo' }))
print(doc.path({ name = 'demo' }))" -c qa
/home/debian/.cache/nvim/listdir/demo.md
/home/debian/.cache/nvim/listdir/demo.md
```

## Verdict

Le constat tient : le chemin de cache est fonction du seul `contract.name`, donc deux listes `demo`
situées ailleurs dans l'arborescence se disputent le même fichier et, par voie de conséquence, le
même buffer.

`pertinent` et non `aggravee` : rien ne montre que le problème se soit étendu — la fonction est
inchangée, et aucun appelant nouveau n'est apparu.

## Action

Rien à écrire au registre hors les deux champs de revue. Le **Pour solder** est actionnable tel quel
(faire entrer le chemin de la liste dans le nom du fichier de cache).

## Arbitrage

<OPTIONNEL>

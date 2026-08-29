+++
id = "test-deduction-voix-non-discriminant"
title = "Le test de déduction de voix ne discrimine que par coïncidence"
date = 2026-08-18
reviewed = 2026-08-29
category = "pertinent"
+++

## Vérifié par

```
$ sed -n '68,75p' tests/tts/test_protocol.lua
T["build_request"]["déduit la voix de la langue"] = function()
	config.voice = nil
	config.language = "fr"
	local expected = config.languages_to_voice[config.backend]["fr"]
	expect.equality(backends.get_backend("piper").build_request(config, "x").voice, expected)
end

$ grep -n 'glados\|piper_model = ' plugins/tts.nvim/lua/tts-nvim/config.lua
36:			["fr"] = "fr_FR-glados-medium",
46:	piper_model = "fr_FR-siwis-medium",
```

## Verdict

Le constat tient, et sa condition de survie est exactement celle que l'entrée nommait : le test ne
discrimine que parce que `languages_to_voice.piper.fr` (`fr_FR-glados-medium`) diffère encore de
`piper_model` (`fr_FR-siwis-medium`). Les deux valeurs sont toujours distinctes aujourd'hui, donc le
test passe — mais pour la raison accidentelle décrite, pas pour la bonne.

Le commentaire posé dans le test (« Lire la voix attendue dans la config plutôt que la figer »)
explique pourquoi la valeur n'est pas codée en dur, mais ne traite pas le défaut signalé : lire
l'attendu dans la table que le code consulte lui-même rend le test insensible au repli.

`pertinent`, et non `a-solder` : rien n'a été corrigé, seule la coïncidence protège encore.

## Action

Rien à écrire au registre hors les deux champs de revue.

## Arbitrage

<OPTIONNEL>

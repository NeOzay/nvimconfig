+++
id = "ttsfile-ecrase-le-meme-fichier"
title = "`:TTSFile` écrase toujours le même fichier"
date = 2026-08-18
reviewed = 2026-08-29
category = "pertinent"
+++

## Vérifié par

```
$ grep -n -B2 -A2 '"tts.wav"' plugins/tts.nvim/daemon/tts-piperd.py
253-            if op == "save":
254-                self.output_dir.mkdir(parents=True, exist_ok=True)
255:                path = self.output_dir / "tts.wav"
256-                self.synthesizer.save(text, voice, speed, path)
257-                return {"ok": True, "path": str(path)}
```

Le nom est une chaîne littérale : il ne dépend ni de la requête, ni de l'horloge, ni du texte.

## Verdict

Le constat tient sans nuance. Rien dans la branche `save` ne dérive le nom de fichier d'autre chose
que `output_dir` : deux `:TTSFile` successifs écrivent au même chemin, le second écrasant le
premier, et la réponse `{"ok": True, "path": …}` annonce chaque fois un chemin qui vient d'être
détruit.

Perte de données silencieuse — pas une préférence de style, donc pas `pas-une-dette`.

## Action

Rien à écrire au registre hors les deux champs de revue. Le **Pour solder** de l'entrée est
actionnable tel quel (horodater le nom, ou accepter un nom dans la requête).

## Arbitrage

<OPTIONNEL>

+++
id = "speak-coupe-avant-synthese"
title = "`speak` coupe la lecture en cours avant de savoir si la nouvelle aboutira"
date = 2026-08-18
reviewed = 2026-08-29
category = "pertinent"
+++

## Vérifié par

```
$ grep -n -B3 -A2 'self.player.stop()$' plugins/tts.nvim/daemon/tts-piperd.py | sed -n '5,14p'
264-            # Couper la lecture en cours sans attendre le chargement du nouveau modèle, sinon un
265-            # modèle froid laisserait la phrase précédente courir près d'une seconde de plus.
266:            self.player.stop()
267-
268-            def play() -> None:
```

Le `stop()` précède bien la fonction `play()`, qui porte la synthèse — donc l'interruption a lieu
avant toute production de son.

## Verdict

Le constat tient, et il reste délibéré : le commentaire qui justifie le compromis est toujours en
place, à la ligne qui précède l'appel. La structure décrite par l'entrée est inchangée —
`ensure_available(voice)` puis `player.stop()` puis `play()` en différé.

`pertinent` plutôt que `pas-une-dette` malgré le caractère assumé : l'entrée porte une section
`Assumé` qui dit exactement cela, et le registre accepte les compromis délibérés dont la fenêtre de
défaillance reste réelle. Le classer `pas-une-dette` reviendrait à dire que la fenêtre n'existe pas,
ce que la commande ne montre pas.

## Action

Rien à écrire au registre hors les deux champs de revue. Le **Pour solder** reste conditionnel
(« si le coût en latence d'interruption redevient acceptable »), donc l'entrée n'est pas
actionnable en l'état.

## Arbitrage

<OPTIONNEL>

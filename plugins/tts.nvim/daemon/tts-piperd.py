#!/usr/bin/env python3
"""Démon de synthèse vocale Piper.

Écoute sur la boucle locale, reçoit une ligne JSON par requête, synthétise avec Piper et
pousse le PCM dans pw-play (PipeWire). Il tourne sur la machine qui a une sortie audio ;
Neovim, lui, peut être n'importe où — en SSH, un RemoteForward mène jusqu'ici.

Protocole (une ligne JSON par requête, une ligne JSON par réponse) :

    {"op": "speak",  "text": …, "voice": …, "speed": …, "volume": …} -> {"ok": true}
    {"op": "save",   "text": …, "voice": …, "speed": …}              -> {"ok": true, "path": …}
    {"op": "stop"}                                                    -> {"ok": true}
    {"op": "voices"}                                                  -> {"ok": true, "voices": [...]}

Le mode --dry-run répond au protocole sans importer Piper ni lancer pw-play : c'est ce qui rend
le démon testable sur une machine sans audio. Seule exception, `speak` y contrôle toujours la
présence des fichiers de la voix — des fichiers vides suffisent — pour que ce chemin d'erreur soit
couvert par les tests.
"""

import argparse
import json
import logging
import os
import socketserver
import subprocess
import sys
import threading
import wave
from pathlib import Path

log = logging.getLogger("tts-piperd")

DEFAULT_HOST = "127.0.0.1"
DEFAULT_PORT = 7788
DEFAULT_VOICES_DIR = Path(
    os.environ.get("XDG_DATA_HOME", Path.home() / ".local" / "share")
) / "piper-voices"


class Player:
    """Lecture en cours. Une seule à la fois : une nouvelle demande remplace la précédente."""

    def __init__(self, dry_run: bool = False):
        self._dry_run = dry_run
        self._process: subprocess.Popen | None = None
        self._lock = threading.Lock()

    def stop(self) -> None:
        with self._lock:
            process, self._process = self._process, None
        if process and process.poll() is None:
            process.terminate()
            try:
                process.wait(timeout=2)
            except subprocess.TimeoutExpired:
                process.kill()

    def play(self, chunks, sample_rate: int, channels: int, volume: float) -> None:
        """Pousse un itérable de blocs PCM s16le dans pw-play."""
        self.stop()
        if self._dry_run:
            for _ in chunks:
                pass
            return

        process = subprocess.Popen(
            [
                "pw-play",
                # Sans --raw, pw-play passe par libsndfile et cherche un en-tête de conteneur
                # sur stdin : le PCM nu de Piper échoue en « Format not recognised ».
                "--raw",
                "--format",
                "s16",
                "--rate",
                str(sample_rate),
                "--channels",
                str(channels),
                "--volume",
                f"{volume:.3f}",
                "-",
            ],
            stdin=subprocess.PIPE,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.PIPE,
        )
        with self._lock:
            self._process = process

        try:
            for chunk in chunks:
                if process.poll() is not None:
                    break
                process.stdin.write(chunk)
                process.stdin.flush()
        except BrokenPipeError:
            # Lecture interrompue par une nouvelle demande : comportement nominal.
            pass
        finally:
            if process.stdin and not process.stdin.closed:
                try:
                    process.stdin.close()
                except BrokenPipeError:
                    pass

            # Sans ceci, un pw-play qui refuse ses arguments échoue en silence et le symptôme
            # se réduit à « aucun son ».
            code = process.wait()
            stderr = process.stderr.read().decode("utf-8", "replace").strip() if process.stderr else ""
            if code not in (0, -15):  # -15 = interrompu par une nouvelle demande
                log.error("pw-play a quitté avec le code %s%s", code, f" : {stderr}" if stderr else "")
            elif stderr:
                log.warning("pw-play : %s", stderr)


class Synthesizer:
    """Charge les modèles Piper à la demande et les garde en mémoire.

    L'import de `piper` est différé : sans lui, le mode --dry-run tourne sur un Python nu.
    """

    def __init__(self, voices_dir: Path, dry_run: bool = False):
        self._voices_dir = voices_dir
        self._dry_run = dry_run
        self._voices: dict[str, object] = {}
        self._lock = threading.Lock()

    def available(self) -> list[str]:
        if not self._voices_dir.is_dir():
            return []
        return sorted(path.stem for path in self._voices_dir.glob("*.onnx"))

    def ensure_available(self, name: str) -> None:
        """Vérifie que le modèle est complet, sans le charger.

        Le chargement coûte près d'une seconde et part donc dans le fil de lecture (voir
        `Server.dispatch`) ; ce contrôle-ci, lui, est un simple `stat` et reste dans la requête,
        pour qu'une voix absente réponde une erreur au client plutôt que de disparaître dans le
        journal.

        Les deux fichiers sont contrôlés : Piper déduit le `.onnx.json` du `.onnx` et ne s'en
        plaint qu'au chargement. Une voix téléchargée à moitié ramènerait sinon le symptôme
        « aucun son », celui-là même que ce démon existe pour rendre diagnosticable.

        N'est pas court-circuité en --dry-run : ce ne sont que des `stat`, et les tests s'en
        servent pour exercer ce chemin d'erreur sans installer Piper.
        """
        for path in (self._voices_dir / f"{name}.onnx", self._voices_dir / f"{name}.onnx.json"):
            if not path.exists():
                raise FileNotFoundError(f"modèle introuvable : {path}")

    def _load(self, name: str):
        with self._lock:
            if name not in self._voices:
                import piper  # noqa: PLC0415 — différé pour garder --dry-run sans dépendance

                model_path = self._voices_dir / f"{name}.onnx"
                if not model_path.exists():
                    raise FileNotFoundError(f"modèle introuvable : {model_path}")
                self._voices[name] = piper.PiperVoice.load(model_path=str(model_path))
            return self._voices[name]

    def synthesize(self, text: str, voice: str, speed: float):
        """Retourne (blocs PCM, taux d'échantillonnage, canaux)."""
        if self._dry_run:
            return iter([b""]), 22050, 1

        import piper  # noqa: PLC0415

        loaded = self._load(voice)
        length_scale = 1.0 / speed if speed > 0 else 1.0
        syn_config = piper.SynthesisConfig(length_scale=length_scale, normalize_audio=True)

        # Le taux vient du modèle : les voix x_low échantillonnent à 16000, pas à 22050.
        sample_rate = loaded.config.sample_rate
        channels = getattr(loaded.config, "num_channels", 1)

        chunks = (chunk.audio_int16_bytes for chunk in loaded.synthesize(text, syn_config=syn_config))
        return chunks, sample_rate, channels

    def save(self, text: str, voice: str, speed: float, path: Path) -> None:
        if self._dry_run:
            path.write_bytes(b"")
            return

        import piper  # noqa: PLC0415

        loaded = self._load(voice)
        length_scale = 1.0 / speed if speed > 0 else 1.0
        syn_config = piper.SynthesisConfig(length_scale=length_scale, normalize_audio=True)
        with wave.open(str(path), "wb") as wav_file:
            loaded.synthesize_wav(text=text, wav_file=wav_file, syn_config=syn_config)


class Handler(socketserver.StreamRequestHandler):
    def handle(self) -> None:
        line = self.rfile.readline()
        if not line:
            return

        try:
            request = json.loads(line.decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError) as exc:
            self.respond({"ok": False, "error": f"requête illisible : {exc}"})
            return

        if not isinstance(request, dict):
            self.respond({"ok": False, "error": "la requête doit être un objet JSON"})
            return

        try:
            self.respond(self.server.dispatch(request))
        except Exception as exc:  # remonter au client plutôt que mourir en silence
            log.exception("échec du traitement de la requête")
            self.respond({"ok": False, "error": str(exc)})

    def respond(self, payload: dict) -> None:
        self.wfile.write((json.dumps(payload, ensure_ascii=False) + "\n").encode("utf-8"))
        self.wfile.flush()


class Server(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True

    def __init__(self, address, synthesizer: Synthesizer, player: Player, output_dir: Path):
        super().__init__(address, Handler)
        self.synthesizer = synthesizer
        self.player = player
        self.output_dir = output_dir

    def dispatch(self, request: dict) -> dict:
        op = request.get("op")

        if op == "stop":
            self.player.stop()
            return {"ok": True}

        if op == "voices":
            return {"ok": True, "voices": self.synthesizer.available()}

        if op in ("speak", "save"):
            text = (request.get("text") or "").strip()
            if not text:
                return {"ok": False, "error": "texte vide"}

            voice = request.get("voice")
            if not voice:
                return {"ok": False, "error": "aucune voix demandée"}

            speed = float(request.get("speed") or 1.0)

            if op == "save":
                self.output_dir.mkdir(parents=True, exist_ok=True)
                path = self.output_dir / "tts.wav"
                self.synthesizer.save(text, voice, speed, path)
                return {"ok": True, "path": str(path)}

            volume = float(request.get("volume") if request.get("volume") is not None else 1.0)

            # Contrôle bon marché, gardé ici pour que le client voie l'erreur.
            self.synthesizer.ensure_available(voice)

            # Couper la lecture en cours sans attendre le chargement du nouveau modèle, sinon un
            # modèle froid laisserait la phrase précédente courir près d'une seconde de plus.
            self.player.stop()

            def play() -> None:
                # Chargement du modèle compris : la première voix demandée coûte près d'une
                # seconde, largement de quoi dépasser le `timeout_ms` du client si on la lui
                # faisait attendre. Ses erreurs, comme celles de la synthèse paresseuse,
                # surviennent donc hors de la requête et disparaîtraient sans ce filet.
                try:
                    chunks, sample_rate, channels = self.synthesizer.synthesize(text, voice, speed)
                    log.info(
                        "speak : %s, %d Hz, %d canal/aux, volume %.2f", voice, sample_rate, channels, volume
                    )
                    self.player.play(chunks, sample_rate, channels, volume)
                except Exception:
                    log.exception("échec de la lecture")

            # Rendre la main tout de suite : la lecture dure plus longtemps que la requête.
            threading.Thread(target=play, daemon=True).start()
            return {"ok": True}

        return {"ok": False, "error": f"opération inconnue : {op!r}"}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Démon de synthèse vocale Piper")
    parser.add_argument("--host", default=DEFAULT_HOST, help="adresse d'écoute (défaut : %(default)s)")
    parser.add_argument("--port", type=int, default=DEFAULT_PORT, help="port (défaut : %(default)s)")
    parser.add_argument(
        "--voices-dir",
        type=Path,
        default=DEFAULT_VOICES_DIR,
        help="répertoire des modèles .onnx (défaut : %(default)s)",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path.home() / "tts-nvim",
        help="répertoire d'écriture pour l'opération save (défaut : %(default)s)",
    )
    parser.add_argument("--verbose", action="store_true", help="journalisation détaillée")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="répondre au protocole sans Piper ni pw-play (tests)",
    )
    args = parser.parse_args(argv)

    if args.host not in ("127.0.0.1", "::1", "localhost"):
        parser.error("le démon ne s'écoute que sur la boucle locale")

    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.INFO,
        format="%(levelname)s %(message)s",
        stream=sys.stderr,
    )

    synthesizer = Synthesizer(args.voices_dir, dry_run=args.dry_run)
    player = Player(dry_run=args.dry_run)

    with Server((args.host, args.port), synthesizer, player, args.output_dir) as server:
        host, port = server.socket.getsockname()[:2]
        log.info("écoute sur %s:%s (voix : %s)", host, port, args.voices_dir)
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            pass
        finally:
            player.stop()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

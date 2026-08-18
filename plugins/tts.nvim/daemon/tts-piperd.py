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
le démon testable sur une machine sans audio.
"""

import argparse
import json
import os
import socketserver
import subprocess
import sys
import threading
import wave
from pathlib import Path

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
            stderr=subprocess.DEVNULL,
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
            chunks, sample_rate, channels = self.synthesizer.synthesize(text, voice, speed)
            # Rendre la main tout de suite : la synthèse dure plus longtemps que la requête.
            threading.Thread(
                target=self.player.play,
                args=(chunks, sample_rate, channels, volume),
                daemon=True,
            ).start()
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
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="répondre au protocole sans Piper ni pw-play (tests)",
    )
    args = parser.parse_args(argv)

    if args.host not in ("127.0.0.1", "::1", "localhost"):
        parser.error("le démon ne s'écoute que sur la boucle locale")

    synthesizer = Synthesizer(args.voices_dir, dry_run=args.dry_run)
    player = Player(dry_run=args.dry_run)

    with Server((args.host, args.port), synthesizer, player, args.output_dir) as server:
        host, port = server.socket.getsockname()[:2]
        print(f"tts-piperd écoute sur {host}:{port}", file=sys.stderr, flush=True)
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            pass
        finally:
            player.stop()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

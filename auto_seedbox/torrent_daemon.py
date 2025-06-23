import logging
import logging.handlers
import os
import signal
import subprocess
import sys
import time
from dataclasses import dataclass
from multiprocessing import Process, Queue
from pathlib import Path
from threading import Thread
from types import FrameType

import libtorrent
import qbittorrentapi
from dataclasses_json import dataclass_json
from watchdog.events import FileSystemEvent, PatternMatchingEventHandler
from watchdog.observers import Observer


@dataclass_json
@dataclass
class Config:
    """The user-editable configuration for this program."""

    qbt_host: str
    qbt_port: str
    qbt_user: str
    qbt_pass: str

    watch_dir: str
    send_to_kindle: bool


@dataclass(frozen=True)
class Torrent:
    """A .torrent file and associated data."""

    path: Path
    name: str
    info_hash: str

    _file_paths: frozenset[Path]

    def kindle_files(self) -> list[Path]:
        """Files you may want to send to a kindle."""
        # TODO prefer epubs, but send mobi and azw3 if we can't find any
        files = []
        for path in self._file_paths:
            if path.suffix in [".epub", ".pdf"]:
                files.append(path)
        return files


def torrent(path: Path) -> Torrent:
    """Construct a Torrent object from a path to a .torrent."""

    resolved_path = path.resolve().as_posix()
    info = libtorrent.torrent_info(resolved_path)
    file_info = info.files()
    paths = [Path(file_info.file_path(i)) for i in range(file_info.num_files())]

    return Torrent(
        path=path,
        name=info.name(),
        info_hash=str(info.info_hash()),
        _file_paths=frozenset(paths),
    )


def logger_thread(q: Queue) -> None:
    while True:
        record = q.get()
        if record is None:
            break
        logger = logging.getLogger(record.name)
        logger.handle(record)


class TorrentEventHandler(PatternMatchingEventHandler):
    _queue: Queue
    _poll_process: Process | None

    _log_queue: Queue
    _log_thread: Thread
    _config: Config
    _last_trigger_time: float
    _last_uploaded: Path | None

    def __init__(self, config: Config) -> None:
        super().__init__(patterns=["*.torrent"], ignore_directories=True)
        self._config = config
        self._qbt_client = qbittorrentapi.Client(
            host=config.qbt_host,
            port=config.qbt_port,
            username=config.qbt_user,
            password=config.qbt_pass,
            REQUESTS_ARGS={"auth": (config.qbt_user, config.qbt_pass)},
        )

        self._log_queue = Queue(-1)
        self._log_thread = Thread(target=logger_thread, args=(self._log_queue,))
        self._log_thread.start()
        self._last_trigger_time = time.time()
        self._last_uploaded = None

        self._queue = Queue(100)
        self._poll_process = None

    def start_polling(self) -> None:
        if self._poll_process:
            if self._poll_process.is_alive():
                return
            self._poll_process.terminate()
        self._poll_process = Process(
            target=poll,
            args=(self._qbt_client, self._config, self._queue, self._log_queue),
        )
        self._poll_process.start()

    def on_created(self, event: FileSystemEvent) -> None:
        current_time = time.time()
        p = Path(str(event.src_path))
        logging.debug(f"Event: created {p.name} at {current_time}")

        if not p.exists():
            # Firefox downloads to a file of random name and then moves it
            logging.info("Skipping false add")
            return

        if p == self._last_uploaded:
            logging.info("Skipping reupload of same file")
            return
        self._last_uploaded = p

        if (current_time - self._last_trigger_time) < 1:
            logging.info("Skipping duplicate event")
            self._last_trigger_time = current_time
            return

        # Three tries, as sometimes we catch the file before it's done being
        # modified
        for try_num in range(3):
            try:
                t = torrent(path=p)
                self._queue.put_nowait(t)
                self.start_polling()
                logging.info(f"Uploading {t.name}")
                self._qbt_client.torrents_add(torrent_files=[str(t.path)])
                logging.info(f"Done uploading {t.name}")
                return
            except Exception as e:
                if not (
                    isinstance(e, RuntimeError) and "unexpected end of file" in str(e)
                ):
                    logging.exception(
                        f"Error processing file (try={try_num})", exc_info=e
                    )
                time.sleep(0.1)

    def stop(self) -> None:
        if self._poll_process:
            self._poll_process.terminate()
            self._poll_process.join()
        self._log_queue.put(None)
        self._log_thread.join()


def poll(
    qbt_client: qbittorrentapi.Client, config: Config, q: Queue, log_queue: Queue
) -> None:
    qh = logging.handlers.QueueHandler(log_queue)
    root = logging.getLogger()
    root.setLevel(logging.INFO)
    root.addHandler(qh)

    # TODO stream download while downloading on seedbox?

    MAX_POLL_TIME_SECS = 60 * 60
    started_polling = time.time()
    in_progress: set[Torrent] = set()

    while time.time() - started_polling < MAX_POLL_TIME_SECS:
        while not q.empty():
            in_progress.add(q.get())
        if not in_progress:
            return
        logging.info(f"Polling for: {[t.name for t in in_progress]}")
        try:
            qbt_info = qbt_client.torrents_info(
                torrent_hashes="|".join(t.info_hash for t in in_progress),
            )
        except qbittorrentapi.exceptions.HTTPError:
            continue
        # TODO print in-progress numbers
        completed = (q for q in qbt_info if q.progress == 1)

        for c in completed:
            download_target = c.content_path.removeprefix(c.save_path).removeprefix("/")
            remote_path = f"seedbox:{c.content_path}"
            local_path = Path(config.watch_dir) / download_target
            logging.info(
                f"Seedbox download of {c.name} complete. Downloading to {local_path}..."
            )
            # Use rclone as it has multi-threaded transfers,
            # which are much faster for large files.
            subprocess.run(
                [
                    "rclone",
                    "copyto",
                    remote_path,
                    local_path,
                    "--progress",
                    "--check-first",  # TODO does this do anything?
                    "--inplace",  # So we can open a .mkv as it's downloading
                ],
                check=False,
                shell=False,
            )
            os.utime(local_path)
            logging.info(f"Done downloading {c.name}")

            # There can be multiple if you e.g. download the same torrent twice
            associated_torrents = [t for t in in_progress if t.info_hash == c.hash]
            if not associated_torrents:
                raise Exception("expected at least one associated torrent")

            if config.send_to_kindle and (
                files := associated_torrents[0].kindle_files()
            ):
                logging.info(f"Kindle files: {files}")
                for file in files:
                    subprocess.run(
                        ["copy_to_kindle.sh", Path(config.watch_dir) / file],
                        shell=False,
                    )

            for t in associated_torrents:
                in_progress.remove(t)
                t.path.unlink()
        time.sleep(1)
    logging.error("Failed to download to seedbox in a timely fashion.")


def main():
    config = Config.schema().loads(
        (Path.home() / ".config/auto-seedbox/config.json").read_text()
    )

    logging.basicConfig(
        level=logging.INFO,
        format=":%(asctime)s - %(name)s - %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
        force=True,
    )
    logging.getLogger().handlers[0].setFormatter(
        logging.Formatter(":%(asctime)s - %(name)s - %(message)s")
    )
    logging.info(f"started watching directory {config.watch_dir!r}")

    event_handler = TorrentEventHandler(config)
    observer = Observer()
    observer.schedule(event_handler, config.watch_dir, recursive=False)
    observer.start()

    def cleanup(_signum: int = -1, _frame: FrameType | None = None) -> None:
        logging.info("Stopping")
        event_handler.stop()
        observer.stop()
        observer.join()
        sys.exit(0)

    signal.signal(signal.SIGTERM, cleanup)
    signal.signal(signal.SIGINT, cleanup)

    while True:
        time.sleep(1)


if __name__ == "__main__":
    main()

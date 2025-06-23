#!/usr/bin/env python3
import os
import subprocess
import sys
import time

from watchdog.events import FileModifiedEvent, FileSystemEventHandler
from watchdog.observers import Observer


class ChangeHandler(FileSystemEventHandler):
    def __init__(self, script_name: str) -> None:
        self.script_name = script_name
        self.process: subprocess.Popen | None = None
        self.last_trigger_time = time.time()
        self.start_script()

    def start_script(self) -> None:
        self.process = subprocess.Popen([sys.executable, self.script_name])

    def on_modified(self, event: FileModifiedEvent) -> None:
        current_time = time.time()
        if event.src_path == os.path.abspath(self.script_name):
            if (current_time - self.last_trigger_time) < 1:
                print("Hot reload - Skipping duplicate event")
                return
            self.last_trigger_time = current_time
            print("Hot reload - Reloading...")
            self.stop_script()
            self.start_script()

    def stop_script(self) -> None:
        if self.process:
            self.process.terminate()
            self.process.wait()


if __name__ == "__main__":
    os.environ["PATH"] = "scripts/:" + os.environ["PATH"]
    script_to_watch = "auto_seedbox/torrent_daemon.py"
    event_handler = ChangeHandler(script_to_watch)
    observer = Observer()
    observer.schedule(
        event_handler, path=os.path.dirname(os.path.abspath(script_to_watch))
    )

    try:
        observer.start()
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        event_handler.stop_script()
        observer.stop()
        observer.join()

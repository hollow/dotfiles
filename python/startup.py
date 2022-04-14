import atexit
import os
import pathlib
import readline

history = os.path.join(os.getenv("XDG_DATA_HOME"), "python/history")

readline.parse_and_bind("tab: complete")

if os.path.exists(history):
    readline.read_history_file(history)


@atexit.register
def write_history(history=history):
    pathlib.Path(os.path.dirname(history)).mkdir(parents=True, exist_ok=True)
    readline.write_history_file(history)

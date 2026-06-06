import atexit
import os
import pathlib
import readline

history = os.path.join(
    os.getenv("XDG_DATA_HOME") or os.path.expanduser("~/.local/share"),
    "python/history",
)

readline.parse_and_bind("tab: complete")

try:
    readline.read_history_file(history)
except OSError:
    # macOS Python links readline against libedit, which returns a stale
    # errno (EPERM/EINVAL) when loading an empty or zero-entry history
    # file. Also covers the file-not-yet-created case. Never let history
    # loading crash interpreter startup.
    pass


@atexit.register
def write_history(history=history):
    pathlib.Path(os.path.dirname(history)).mkdir(parents=True, exist_ok=True)
    try:
        readline.write_history_file(history)
    except OSError:
        pass

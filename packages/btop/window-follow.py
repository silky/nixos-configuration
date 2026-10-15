#!/usr/bin/env python3
"""Run btop with an X11 target provider; exec preserves terminal job control."""

import json
import os
from pathlib import Path
import shutil
import socket
import sys
import tempfile
import time


def process_identity(pid, proc=Path("/proc")):
    """Return (parent, start ticks), or None for a missing/dead process."""
    try:
        text = (proc / str(pid) / "stat").read_text()
        fields = text[text.rindex(")") + 2 :].split()
        if fields[0] in ("Z", "X"):
            return None
        return int(fields[1]), int(fields[19])
    except (OSError, ValueError, IndexError):
        return None


def ancestors(pid):
    result = set()
    while pid > 1 and pid not in result:
        result.add(pid)
        identity = process_identity(pid)
        if identity is None:
            break
        pid = identity[0]
    return result


def atomic_write(path, text):
    temporary = path.with_suffix(".tmp")
    temporary.write_text(text)
    temporary.replace(path)


def ignored_windows(directory, identity_reader=process_identity):
    """Use window IDs, not terminal PIDs: a terminal may own several windows."""
    result = set()
    for entry in directory.glob("instance-*/owner.json"):
        try:
            owner = json.loads(entry.read_text())
            identity = identity_reader(owner["pid"])
            if identity is not None and identity[1] == owner["start"]:
                result.add(owner["window"])
        except (OSError, ValueError, KeyError, TypeError):
            continue
    return result


class Tracker:
    """Debounce changes; ignored windows cancel pending changes and hold the view."""

    def __init__(self, delay=0.2):
        self.delay = delay
        self.candidate = None
        self.since = 0.0
        self.current = "waiting\n"

    def sample(self, window, target, ignored, now):
        if window is None or window in ignored:
            self.candidate = None
            return None
        text = f"{target[0]} {target[1]}\n" if target else "unavailable\n"
        candidate = (window, text)
        if candidate != self.candidate:
            self.candidate = candidate
            self.since = now
            return None
        if now - self.since >= self.delay and text != self.current:
            self.current = text
            return text
        return None


class Desktop:
    def __init__(self):
        # Import lazily so --help, --version and non-X11 invocations stay cheap.
        from Xlib import X, display, error

        self.X = X
        self.error = error
        self.display = display.Display()
        self.root = self.display.screen().root
        self.atoms = {
            name: self.display.intern_atom(name)
            for name in ("_NET_ACTIVE_WINDOW", "_NET_CLIENT_LIST", "_NET_WM_PID", "WM_CLIENT_MACHINE")
        }
        self.local_names = {socket.gethostname(), socket.getfqdn(), "localhost"}

    def property(self, window, name):
        try:
            value = window.get_full_property(self.atoms[name], self.X.AnyPropertyType)
            return value.value if value is not None else None
        except self.error.XError:
            return None

    def active(self):
        value = self.property(self.root, "_NET_ACTIVE_WINDOW")
        return int(value[0]) if value is not None and len(value) and value[0] else None

    def window(self, identifier):
        return self.display.create_resource_object("window", identifier)

    def pid(self, identifier):
        window = self.window(identifier)
        machine = self.property(window, "WM_CLIENT_MACHINE")
        if machine is not None:
            hostname = bytes(machine).rstrip(b"\0").decode(errors="replace")
            if hostname not in self.local_names:
                return None
        value = self.property(window, "_NET_WM_PID")
        if value is None or len(value) != 1 or not 0 < value[0] < 2**31:
            return None
        return int(value[0])

    def host_window(self, process):
        """Prefer WINDOWID; validate against the terminal ancestor, never its name."""
        managed = self.property(self.root, "_NET_CLIENT_LIST")
        managed = set(map(int, managed)) if managed is not None else set()
        lineage = ancestors(process)
        identifier = os.environ.get("WINDOWID")
        if identifier:
            try:
                identifier = int(identifier, 0)
                seen = set()
                while identifier not in managed and identifier not in seen:
                    seen.add(identifier)
                    identifier = self.window(identifier).query_tree().parent.id
                if identifier in managed and self.pid(identifier) in lineage:
                    return identifier
            except (ValueError, self.error.XError):
                pass
        # Terminals without WINDOWID: the focused window must belong to an ancestor.
        identifier = self.active()
        if identifier in managed and self.pid(identifier) in lineage:
            return identifier
        return None

    def target(self, identifier):
        pid = self.pid(identifier)
        identity = process_identity(pid) if pid is not None else None
        return (pid, identity[1]) if identity is not None else None


def monitor(desktop, directory, instance, owner, follow):
    tracker = Tracker()
    try:
        while True:
            identity = process_identity(owner["pid"])
            if identity is None or identity[1] != owner["start"]:
                return
            if follow:
                window = desktop.active()
                ignored = ignored_windows(directory) | {owner["window"]}
                target = desktop.target(window) if window is not None and window not in ignored else None
                text = tracker.sample(window, target, ignored, time.monotonic())
                if text is not None:
                    atomic_write(instance / "target", text)
            time.sleep(0.05 if follow else 0.25)
    finally:
        # Losing the provider leaves btop showing 'unavailable', never a stale PID.
        shutil.rmtree(instance, ignore_errors=True)


def main():
    binary, *arguments = sys.argv[1:]

    def run(extra=()):
        os.execv(binary, [binary, *arguments, *extra])

    if (
        not os.environ.get("DISPLAY")
        or os.environ.get("SSH_CONNECTION")
        or not os.isatty(0)
        or not os.isatty(1)
        or any(arg in ("--help", "-h", "--version", "-v", "-V", "--default-config") for arg in arguments)
    ):
        run()

    instance = None
    try:
        desktop = Desktop()
        pid = os.getpid()
        host = desktop.host_window(pid)
        identity = process_identity(pid)
        if host is None or identity is None:
            run()
        # Even opt-out instances register their windows for other btop followers.
        follow = os.environ.get("BTOP_FOLLOW_WINDOW", "1") != "0" and "--follow-pid-file" not in arguments
        runtime = os.environ.get("XDG_RUNTIME_DIR")
        if not runtime:
            run()
        directory = Path(runtime) / "btop-window-follow"
        directory.mkdir(mode=0o700, exist_ok=True)
        metadata = directory.lstat()
        if directory.is_symlink() or metadata.st_uid != os.getuid() or metadata.st_mode & 0o077:
            run()
        instance = Path(tempfile.mkdtemp(prefix="instance-", dir=directory))
        owner = {"pid": pid, "start": identity[1], "window": host}
        atomic_write(instance / "owner.json", json.dumps(owner))
        atomic_write(instance / "target", "waiting\n")
        child = os.fork()
    except Exception as error:
        if instance is not None:
            shutil.rmtree(instance, ignore_errors=True)
        print(f"btop: window following unavailable: {error}", file=sys.stderr)
        run()

    if child == 0:
        try:
            os.setsid()
            with open(os.devnull, "r+b", buffering=0) as null:
                for fd in (0, 1, 2):
                    os.dup2(null.fileno(), fd)
            monitor(desktop, directory, instance, owner, follow)
        finally:
            os._exit(0)
    run(("--follow-pid-file", str(instance / "target")) if follow else ())


if __name__ == "__main__":
    main()

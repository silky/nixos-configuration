"""Regression tests for the helper and the actual patched btop executable."""

import fcntl
import importlib.util
import json
import os
from pathlib import Path
import pty
import select
import signal
import struct
import subprocess
import sys
import tempfile
import termios
import time
import unittest

import pyte

HELPER_PATH, BTOP = sys.argv[1:3]
sys.argv = sys.argv[:1]
sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location("window_follow", HELPER_PATH)
helper = importlib.util.module_from_spec(spec)
spec.loader.exec_module(helper)


class HelperTests(unittest.TestCase):
    def test_own_window_never_becomes_target(self):
        tracker = helper.Tracker()
        for now in (0, 1, 2):
            self.assertIsNone(tracker.sample(10, (100, 1), {10}, now))
        self.assertEqual(tracker.current, "waiting\n")

    def test_return_to_btop_cancels_pending_target_and_holds_previous(self):
        tracker = helper.Tracker()
        tracker.sample(11, (100, 1), {10}, 0)
        self.assertEqual(tracker.sample(11, (100, 1), {10}, 0.3), "100 1\n")
        tracker.sample(12, (200, 2), {10}, 0.4)
        self.assertIsNone(tracker.sample(10, (300, 3), {10}, 1))
        self.assertEqual(tracker.current, "100 1\n")
        self.assertIsNone(tracker.sample(12, (200, 2), {10}, 1.1))
        self.assertEqual(tracker.sample(12, (200, 2), {10}, 1.4), "200 2\n")

    def test_other_window_with_same_terminal_pid_is_not_ignored(self):
        tracker = helper.Tracker()
        tracker.sample(11, (100, 1), {10, 12}, 0)
        self.assertEqual(tracker.sample(11, (100, 1), {10, 12}, 0.3), "100 1\n")
        self.assertIsNone(tracker.sample(12, (100, 1), {10, 12}, 1))

    def test_unavailable_and_desktop(self):
        tracker = helper.Tracker()
        tracker.sample(11, None, {10}, 0)
        self.assertEqual(tracker.sample(11, None, {10}, 0.3), "unavailable\n")
        self.assertIsNone(tracker.sample(None, None, {10}, 1))

    def test_registration_ignores_stale_pid_reuse(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            for name, owner in (
                ("instance-a", {"pid": 100, "start": 5, "window": 10}),
                ("instance-b", {"pid": 101, "start": 6, "window": 11}),
                ("instance-c", {"pid": 102, "start": 7, "window": 12}),
            ):
                (root / name).mkdir()
                (root / name / "owner.json").write_text(json.dumps(owner))
            identities = {100: (1, 5), 101: (1, 99)}
            self.assertEqual(helper.ignored_windows(root, identities.get), {10})

    def test_proc_stat_with_spaces_and_parentheses(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "123").mkdir()
            stat = root / "123" / "stat"
            stat.write_text("123 (strange ) (name)) S 42 " + "0 " * 17 + "987 0 0\n")
            self.assertEqual(helper.process_identity(123, root), (42, 987))
            stat.write_text("123 (gone) Z 42 " + "0 " * 17 + "987 0 0\n")
            self.assertIsNone(helper.process_identity(123, root))


class Terminal:
    def __init__(self, directory, tree=False, command=None, extra_env=None):
        self.screen = pyte.Screen(160, 45)
        self.stream = pyte.ByteStream(self.screen)
        self.master, slave = pty.openpty()
        fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 45, 160, 0, 0))
        config = directory / f"config-{time.monotonic_ns()}"
        config.write_text(
            'shown_boxes = "proc"\nproc_sorting = "pid"\n'
            f'proc_tree = {str(tree)}\n'
            'update_ms = 100\nsave_config_on_exit = False\n'
            'proc_cpu_graphs = False\ncheck_temp = False\n'
        )
        self.target = directory / f"target-{time.monotonic_ns()}"
        self.target.write_text("waiting\n")
        env = dict(os.environ, TERM="xterm-256color", LC_ALL="C.UTF-8", HOME=str(directory),
                   XDG_CONFIG_HOME=str(directory), XDG_STATE_HOME=str(directory))
        env.pop("DISPLAY", None)
        env.pop("SSH_CONNECTION", None)
        env.update(extra_env or {})
        if command is None:
            command = [BTOP, "--follow-pid-file", str(self.target)]

        def session():
            os.setsid()
            fcntl.ioctl(0, termios.TIOCSCTTY, 0)

        self.process = subprocess.Popen([*command, "--config", str(config)], stdin=slave,
                                        stdout=slave, stderr=slave, env=env, preexec_fn=session)
        os.close(slave)

    def text(self):
        while select.select([self.master], [], [], 0)[0]:
            try:
                data = os.read(self.master, 65536)
            except OSError:
                break
            if not data:
                break
            self.stream.feed(data)
        return "\n".join(self.screen.display)

    def wait(self, predicate, message, timeout=8):
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            text = self.text()
            if predicate(text):
                return text
            if self.process.poll() is not None:
                raise AssertionError(f"btop exited {self.process.returncode}:\n{text}")
            time.sleep(0.025)
        raise AssertionError(f"{message}\n{self.text()}")

    def contains(self, text):
        return self.wait(lambda screen: text in screen, f"Missing {text!r}")

    def key(self, key):
        os.write(self.master, key.encode())
        # btop treats each input read as one key/paste. Separate deliberate
        # keystrokes and keep the PTY drained while the application redraws.
        deadline = time.monotonic() + 0.12
        while time.monotonic() < deadline:
            self.text()
            time.sleep(0.01)

    def publish(self, text):
        helper.atomic_write(self.target, text + "\n")

    def close(self):
        if self.master is None:
            return
        if self.process.poll() is None:
            self.key("q")
            deadline = time.monotonic() + 3
            while self.process.poll() is None and time.monotonic() < deadline:
                self.text()
                time.sleep(0.01)
            if self.process.poll() is None:
                self.process.kill()
                self.process.wait()
        os.close(self.master)
        self.master = None


class WorkloadTestCase(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.directory = Path(self.temporary.name)
        # prctl names make actual screen rows unambiguous; cmdline stays harmless.
        code = """
import ctypes, os, sys, time
from pathlib import Path
libc = ctypes.CDLL(None)
name = b'bt-root'
child = os.fork()
if child == 0:
    name = b'bt-child'
    grandchild = os.fork()
    if grandchild == 0:
        name = b'bt-grandchild'
libc.prctl(15, name, 0, 0, 0)
(Path(sys.argv[1]) / f'ready-{os.getpid()}').touch()
if name == b'bt-root':
    spawned = False
    while True:
        if not spawned and (Path(sys.argv[1]) / 'spawn').exists():
            spawned = True
            if os.fork() == 0:
                libc.prctl(15, b'bt-late', 0, 0, 0)
                time.sleep(120)
                os._exit(0)
        time.sleep(0.025)
else:
    time.sleep(120)
"""
        script = self.directory / "workload.py"
        script.write_text(code)
        self.workload = subprocess.Popen([sys.executable, str(script), str(self.directory)], start_new_session=True)
        self.addCleanup(self.cleanup_workload)
        self.addCleanup(self.temporary.cleanup)
        deadline = time.monotonic() + 5
        while time.monotonic() < deadline:
            identity = helper.process_identity(self.workload.pid)
            if identity and len(list(self.directory.glob("ready-*"))) == 3:
                self.identity = f"{self.workload.pid} {identity[1]}"
                break
            time.sleep(0.01)
        else:
            self.fail("Test workload failed to start")

    def cleanup_workload(self):
        try:
            os.killpg(self.workload.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        self.workload.wait()

    def terminal(self, tree=False, follow=True):
        terminal = Terminal(self.directory, tree)
        self.addCleanup(terminal.close)
        terminal.contains("Window: off")
        if follow:
            terminal.key("w")
            terminal.contains("Window: follow waiting")
        return terminal

    def assert_subtree(self, terminal):
        terminal.wait(lambda text: all(name in text for name in ("bt-root", "bt-child", "bt-grandchild"))
                      and "0/3" in text, "Expected exactly root, child and grandchild")


class BtopTests(WorkloadTestCase):
    def test_default_off_menu_and_escape_quit(self):
        terminal = self.terminal(follow=False)
        terminal.publish(self.identity)
        time.sleep(0.35)
        screen = terminal.contains("Window: off")
        self.assertNotRegex(screen, r"\b0/3\b", "Startup must keep the full process list")
        for y, line in enumerate(terminal.screen.display):
            if "Window: off" in line:
                for x in range(line.index("[w]"), line.index("Window: off") + len("Window: off")):
                    self.assertEqual(terminal.screen.buffer[y][x].bg, "default")
        terminal.key("m")
        terminal.contains("╔═╗╔═╗╔╦╗╦╔═╗╔╗╔╔═╗")
        terminal.key("m")
        terminal.wait(lambda text: "╔═╗╔═╗╔╦╗╦╔═╗╔╗╔╔═╗" not in text,
                      "m must close the menu")
        terminal.key("\x1b")
        terminal.wait(lambda text: terminal.process.poll() is not None,
                      "Escape must quit from the monitor")
        self.assertEqual(terminal.process.returncode, 0)

    def test_new_descendants_while_following(self):
        terminal = self.terminal(tree=True)
        terminal.publish(self.identity)
        self.assert_subtree(terminal)
        (self.directory / "spawn").touch()
        terminal.wait(lambda text: "bt-late" in text and "0/4" in text,
                      "Following must discover newly spawned children")
        terminal.key("e")
        terminal.wait(lambda text: "bt-late" in text and "0/4" in text,
                      "Flat view must preserve descendant membership")

    def test_collapse_target_and_restore(self):
        terminal = self.terminal(tree=True)
        terminal.publish(self.identity)
        self.assert_subtree(terminal)
        terminal.key("\x1b[B")
        terminal.contains("1/3")
        terminal.key(" ")
        terminal.wait(lambda text: "bt-root" in text and "bt-child" not in text
                      and "1/1" in text, "Collapsing the selected root must hide descendants")
        terminal.key(" ")
        terminal.wait(lambda text: "bt-grandchild" in text and "1/3" in text,
                      "Expanding must restore all descendants")

    def test_flat_and_tree_and_text_filter(self):
        terminal = self.terminal()
        terminal.publish(self.identity)
        self.assert_subtree(terminal)
        terminal.key("e")
        self.assert_subtree(terminal)
        terminal.key("f")
        for character in "bt-child":
            terminal.key(character)
        terminal.key("\n")
        terminal.wait(lambda text: "bt-grandchild" in text and "0/2" in text,
                      "Tree text filter must retain the matched process's descendants")
        terminal.key("\x1b[3~")
        self.assert_subtree(terminal)
        terminal.key("e")
        self.assert_subtree(terminal)

    def test_off_and_resume(self):
        terminal = self.terminal(tree=True)
        terminal.publish(self.identity)
        self.assert_subtree(terminal)
        terminal.key("w")
        terminal.contains("Window: off")
        terminal.wait(lambda text: "0/3" not in text, "Off must restore all processes")
        terminal.publish("unavailable")
        time.sleep(0.3)
        terminal.contains("Window: off")
        self.assertNotIn("0/0", terminal.text(), "Target changes must not filter while off")
        terminal.key("w")
        terminal.contains("Window: follow unavailable")
        terminal.contains("0/0")

    def test_wrong_identity_and_target_exit(self):
        terminal = self.terminal(tree=True)
        terminal.publish(f"{self.workload.pid} 1")
        terminal.contains(f"exited PID {self.workload.pid}")
        terminal.contains("0/0")
        terminal.publish(self.identity)
        self.assert_subtree(terminal)
        self.cleanup_workload()
        terminal.contains(f"exited PID {self.workload.pid}")
        terminal.contains("0/0")
        terminal.publish("not a pid")
        terminal.contains("Window: follow unavailable")
        self.assertIsNone(terminal.process.poll())


class X11Tests(WorkloadTestCase):
    def setUp(self):
        super().setUp()
        from Xlib import X, Xatom, display

        self.Xatom = Xatom
        read, write = os.pipe()
        self.server = subprocess.Popen(
            ["Xvfb", "-displayfd", str(write), "-screen", "0", "800x600x24", "-nolisten", "tcp", "-ac"],
            pass_fds=(write,), stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )
        os.close(write)
        self.addCleanup(self.close_server)
        try:
            self.assertTrue(select.select([read], [], [], 5)[0], "Xvfb failed to start")
            self.display_name = ":" + os.read(read, 100).decode().strip()
        finally:
            os.close(read)
        self.display = display.Display(self.display_name)
        self.addCleanup(self.display.close)
        self.root = self.display.screen().root
        self.windows = []
        for pid in (os.getpid(), self.workload.pid, os.getpid(), os.getpid()):
            window = self.root.create_window(0, 0, 100, 100, 0, X.CopyFromParent)
            window.change_property(self.display.intern_atom("_NET_WM_PID"), Xatom.CARDINAL, 32, [pid])
            window.map()
            self.windows.append(window)
        self.root.change_property(self.display.intern_atom("_NET_CLIENT_LIST"), Xatom.WINDOW, 32,
                                  [window.id for window in self.windows])
        self.focus(0)

    def close_server(self):
        self.server.terminate()
        self.server.wait(timeout=5)

    def focus(self, index):
        self.root.change_property(self.display.intern_atom("_NET_ACTIVE_WINDOW"), self.Xatom.WINDOW, 32,
                                  [self.windows[index].id])
        self.display.sync()

    def wrapped_terminal(self, index=0, opt_out=False):
        terminal = Terminal(
            self.directory, command=[sys.executable, HELPER_PATH, BTOP],
            extra_env={"DISPLAY": self.display_name, "WINDOWID": str(self.windows[index].id),
                       "XDG_RUNTIME_DIR": str(self.directory), "BTOP_FOLLOW_WINDOW": "0" if opt_out else "1"},
        )
        self.addCleanup(terminal.close)
        if not opt_out:
            terminal.contains("Window: off")
            terminal.key("w")
            terminal.contains("Window: follow waiting")
        return terminal

    def test_desktop_helper_and_multiple_btop_windows(self):
        terminal = self.wrapped_terminal()
        self.focus(1)
        self.assert_subtree(terminal)
        self.focus(0)
        time.sleep(0.35)
        self.assert_subtree(terminal)

        # A second btop window must also be ignored, even if its following is off.
        self.focus(2)
        second = self.wrapped_terminal(2, opt_out=True)
        second.contains("Program:")
        time.sleep(0.35)
        self.assert_subtree(terminal)

        # Another terminal window sharing that very same PID remains a valid target.
        self.focus(3)
        terminal.contains(f"Window: follow PID {os.getpid()}")

        # Helpers and registrations disappear when their owning btop exits.
        terminal.close()
        second.close()
        self.assertEqual(terminal.process.returncode, 0)
        self.assertEqual(second.process.returncode, 0)
        deadline = time.monotonic() + 3
        directory = self.directory / "btop-window-follow"
        while list(directory.glob("instance-*")) and time.monotonic() < deadline:
            time.sleep(0.05)
        self.assertEqual(list(directory.glob("instance-*")), [])


if __name__ == "__main__":
    unittest.main(verbosity=2)

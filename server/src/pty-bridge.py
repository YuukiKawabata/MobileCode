#!/usr/bin/env python3
"""PTY bridge: spawns a command in a PTY and relays I/O via stdin/stdout.

- stdin  → PTY input (raw bytes)
- stdout ← PTY output (raw bytes)
- stderr ← JSON control messages
- Resize: send ESC]9;cols;rowsBEL via stdin
"""

import fcntl
import json
import os
import pty
import select
import signal
import struct
import sys
import termios


def resize_pty(fd, cols, rows):
    winsize = struct.pack("HHHH", rows, cols, 0, 0)
    fcntl.ioctl(fd, termios.TIOCSWINSZ, winsize)


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "/Users/yuki/.local/bin/claude"
    args = sys.argv[1:]  # argv[1:] = [cmd, arg1, arg2, ...]
    if not args:
        args = [cmd]

    cols = int(os.environ.get("COLS", "80"))
    rows = int(os.environ.get("ROWS", "24"))

    pid, master_fd = pty.fork()

    if pid == 0:
        # Child process
        os.environ["TERM"] = "xterm-256color"
        os.execvp(cmd, args)
        os._exit(1)

    # Parent process
    resize_pty(master_fd, cols, rows)

    # Report started
    sys.stderr.write(json.dumps({"type": "started", "pid": pid}) + "\n")
    sys.stderr.flush()

    stdin_fd = sys.stdin.fileno()
    stdout_fd = sys.stdout.fileno()

    # Make master_fd non-blocking
    flags = fcntl.fcntl(master_fd, fcntl.F_GETFL)
    fcntl.fcntl(master_fd, fcntl.F_SETFL, flags | os.O_NONBLOCK)

    running = True
    resize_buf = b""
    in_resize = False

    def handle_signal(*_):
        nonlocal running
        running = False
        try:
            os.kill(pid, signal.SIGTERM)
        except ProcessLookupError:
            pass

    signal.signal(signal.SIGTERM, handle_signal)
    signal.signal(signal.SIGINT, handle_signal)

    try:
        while running:
            try:
                rlist, _, _ = select.select([master_fd, stdin_fd], [], [], 0.1)
            except (ValueError, OSError):
                break

            for fd in rlist:
                if fd == master_fd:
                    try:
                        data = os.read(master_fd, 65536)
                        if not data:
                            running = False
                            break
                        os.write(stdout_fd, data)
                    except OSError as e:
                        if e.errno == 5:  # EIO = PTY closed
                            running = False
                            break
                        if e.errno != 11:  # EAGAIN
                            running = False
                            break

                elif fd == stdin_fd:
                    try:
                        data = os.read(stdin_fd, 65536)
                        if not data:
                            running = False
                            break

                        # Process byte by byte for resize detection
                        i = 0
                        normal_start = 0
                        while i < len(data):
                            if in_resize:
                                resize_buf += data[i:i+1]
                                if data[i:i+1] == b"\x07":
                                    # End of resize sequence
                                    try:
                                        text = resize_buf.decode("utf-8")
                                        # Format: ESC]9;cols;rowsBEL
                                        inner = text[3:-1]  # skip ESC]9 and BEL
                                        c, r = inner.split(";")
                                        resize_pty(master_fd, int(c), int(r))
                                    except (ValueError, UnicodeDecodeError):
                                        pass
                                    in_resize = False
                                    resize_buf = b""
                                    normal_start = i + 1
                                elif len(resize_buf) > 20:
                                    # Too long, not a resize sequence
                                    os.write(master_fd, resize_buf)
                                    in_resize = False
                                    resize_buf = b""
                                    normal_start = i + 1
                                i += 1
                            elif data[i:i+3] == b"\x1b]9":
                                # Flush any normal data before this
                                if i > normal_start:
                                    os.write(master_fd, data[normal_start:i])
                                in_resize = True
                                resize_buf = data[i:i+3]
                                i += 3
                                normal_start = i
                            else:
                                i += 1

                        # Write remaining normal data
                        if not in_resize and normal_start < len(data):
                            os.write(master_fd, data[normal_start:])

                    except OSError:
                        running = False
                        break
    finally:
        try:
            os.close(master_fd)
        except OSError:
            pass

        try:
            _, status = os.waitpid(pid, 0)
            exit_code = os.WEXITSTATUS(status) if os.WIFEXITED(status) else -1
        except ChildProcessError:
            exit_code = -1

        sys.stderr.write(json.dumps({"type": "exited", "code": exit_code}) + "\n")
        sys.stderr.flush()


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
# kblang.py — writes EN/AR to $XDG_RUNTIME_DIR/kb-lang, refreshes status.sh on change
#   kblang.py --once   -> print Wayfire's raw keyboard state (for testing)
import json, os, socket, struct, subprocess, sys, time

OUT = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "kb-lang")

def connect():
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.connect(os.environ["WAYFIRE_SOCKET"])
    return s

def recv_exact(s, n):
    buf = b""
    while len(buf) < n:
        chunk = s.recv(n - len(buf))
        if not chunk:
            raise ConnectionError("wayfire closed the socket")
        buf += chunk
    return buf

def call(s, method):
    msg = json.dumps({"method": method, "data": {}}).encode()
    s.sendall(struct.pack("<I", len(msg)) + msg)
    size = struct.unpack("<I", recv_exact(s, 4))[0]
    return json.loads(recv_exact(s, size))

def label(state):
    name = str(state.get("layout", "")).lower()
    if "arab" in name:
        return "AR"
    if name:
        return "EN"
    return "AR" if state.get("layout-index") == 1 else "EN"

if "--once" in sys.argv:
    print(call(connect(), "wayfire/get-keyboard-state"))
    sys.exit()

last, s = None, None
while True:
    try:
        if s is None:
            s = connect()
        cur = label(call(s, "wayfire/get-keyboard-state"))
    except Exception:
        if s:
            s.close()
        s = None
        time.sleep(2)
        continue
    if cur != last:
        with open(OUT + ".tmp", "w") as f:
            f.write(cur + "\n")
        os.replace(OUT + ".tmp", OUT)
        subprocess.run(["pkill", "-USR1", "-f", "status.sh"])
        last = cur
    time.sleep(0.4)

#!/usr/bin/env bash
# Run a .wl file from the pushed HEAD commit on the Wolfram Cloud runner.
# Usage: RUNNER_URL=<cloud api url> tools/run_cloud.sh <file.wl> [out_prefix]
set -euo pipefail
file="$1"; out="${2:-/tmp/run}"
sha=$(git rev-parse HEAD)
curl -sS -m 300 -o "$out.raw" "${RUNNER_URL}?sha=${sha}&file=${file}"
python3 - "$out" <<'PY'
import json, sys, base64
out = sys.argv[1]
raw = open(out + ".raw", encoding="utf-8").read()
d = json.loads(raw)
if isinstance(d, str): d = json.loads(d)
print("success:", d.get("success"))
print("messages:", d.get("messages"))
print("result:", d.get("result", "")[:3000])
if d.get("png"):
    open(out + ".png", "wb").write(base64.b64decode(d["png"]))
    print("png:", out + ".png")
PY

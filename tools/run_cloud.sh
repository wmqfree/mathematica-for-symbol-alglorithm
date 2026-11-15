#!/usr/bin/env bash
# Run a .wl file from the pushed HEAD commit on the Wolfram Cloud runner.
# Usage: RUNNER_URL=<cloud api url> tools/run_cloud.sh <file.wl> [out_prefix]
set -euo pipefail
file="$1"; out="${2:-/tmp/run}"
sha=$(git rev-parse HEAD)
curl -sS -m 300 -o "$out.raw" "${RUNNER_URL}?sha=${sha}&file=${file}"
python3 - "$out" <<'PY'
# The runner answers with a Wolfram string literal wrapping JSON; pull the fields out with regexes.
import sys, re, base64
out = sys.argv[1]
raw = open(out + ".raw", encoding="utf-8", errors="replace").read()
m = re.search(r'\\"png\\":\\"(.*?)\\"', raw, re.S)
head = raw[:m.start()] if m else raw
print(head.replace("\\n", "\n").replace("\\t", "  ").replace('\\"', '"')[:4000])
if m and m.group(1):
    open(out + ".png", "wb").write(base64.b64decode(m.group(1).replace("\\", "")))
    print("png:", out + ".png")
PY

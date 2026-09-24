#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Reassemble the large files that were split into <45 MiB parts so that the
# repository stays within GitHub's per-file size limit.
#
#   ./tools/reassemble-large-files.sh            # restore + verify
#   ./tools/reassemble-large-files.sh --keep     # restore, keep the .part-* files
#
# A file FOO was replaced by FOO.part-000, FOO.part-001, ... ; concatenating
# them in order restores FOO byte-for-byte. The expected size and SHA-256 of
# each original are recorded in 00-manifest/split-files.csv .
# ---------------------------------------------------------------------------
set -euo pipefail
cd "$(dirname "$0")/.."
KEEP=0; [ "${1:-}" = "--keep" ] && KEEP=1

count=0
while IFS= read -r -d '' first; do
  orig="${first%.part-000}"
  echo "==> reassembling ${orig#./}"
  cat "$orig".part-* > "$orig.restoring"
  mv "$orig.restoring" "$orig"
  count=$((count+1))
  if [ "$KEEP" -eq 0 ]; then rm -f "$orig".part-*; fi
done < <(find . -name '*.part-000' -print0 | sort -z)

echo "reassembled $count file(s)."
python3 - "$KEEP" <<'PY'
import csv,sys,hashlib,os
keep = sys.argv[1]=='1'
p='00-manifest/split-files.csv'
if not os.path.exists(p):
    sys.exit(0)
bad=0
for r in csv.DictReader(open(p,encoding='utf-8-sig')):
    f=r['path']
    if not os.path.exists(f):
        if keep: continue          # intentionally left split
        print("MISSING",f); bad+=1; continue
    h=hashlib.sha256()
    with open(f,'rb') as fh:
        for b in iter(lambda:fh.read(1<<20),b''): h.update(b)
    ok = h.hexdigest()==r['sha256'] and os.path.getsize(f)==int(r['size'])
    print(("OK   " if ok else "BAD  ")+f)
    bad += 0 if ok else 1
print("verification failures:",bad)
sys.exit(1 if bad else 0)
PY

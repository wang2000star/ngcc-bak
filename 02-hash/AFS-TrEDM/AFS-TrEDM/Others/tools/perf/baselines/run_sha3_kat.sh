#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

make all >/dev/null

./sha3_512_reference_c --kat-all
./xkcp_compactfips202_sha3_512 --kat-all
./openssl_evp_sha3_512 --kat-all

ref_digest="$(./sha3_512_reference_c --digest-generated=1048576 | awk '{print $3}')"
compact_digest="$(./xkcp_compactfips202_sha3_512 --digest-generated=1048576 | awk '{print $3}')"
openssl_digest="$(./openssl_evp_sha3_512 --digest-generated=1048576 | awk '{print $3}')"

if [ "$ref_digest" != "$openssl_digest" ]; then
  echo "sha3-512-reference-c-xkcp-readable 1MiB digest mismatch against OpenSSL" >&2
  exit 1
fi
if [ "$compact_digest" != "$openssl_digest" ]; then
  echo "xkcp-compactfips202-sha3-512-more-compact 1MiB digest mismatch against OpenSSL" >&2
  exit 1
fi

echo "sha3-512-generated-1mib crosscheck OK $openssl_digest"

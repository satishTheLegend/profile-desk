#!/bin/sh
# Test APK only. Run after creating the fixture's temporary public CA.
set -eu
if [ "$#" -ne 1 ] || [ ! -f "$1" ]; then
  echo 'Usage: prepare_harness_certificate.sh /absolute/path/to/public-ca.pem' >&2
  exit 2
fi
repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/../../.." && pwd)
res_dir="$repo_dir/apps/mobile/build/session_engine/generated/harnessTestRes/raw"
mkdir -p "$res_dir"
openssl x509 -in "$1" -noout -checkend 0 >/dev/null
# Extract the public certificate only, even if the input accidentally contains a key.
openssl x509 -in "$1" -out "$res_dir/profiledesk_harness_ca.pem"

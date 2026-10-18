#!/bin/sh
# Run the tests with each Vim and each diff backend:
#
#   plugins/hunks/test/run.sh
#   VIMS="/usr/bin/vim ~/vim/bin/vim" plugins/hunks/test/run.sh
#
# The builtin backend is skipped on a Vim without diff().

here=$(cd "$(dirname "$0")" && pwd)
sw=$HOME/software/vim
VIMS=${VIMS:-"$sw/vim-9.0/bin/vim $sw/vim-9.1/bin/vim $sw/vim-9.2/bin/vim"}

status=0
for vim in $VIMS; do
  for backend in builtin job; do
    out=$(mktemp)
    HUNKS_TEST_DIFF=$backend HUNKS_TEST_OUT=$out \
      timeout 120 "$vim" -Nu NONE -i NONE -es -S "$here/test.vim" </dev/null >/dev/null 2>&1
    code=$?
    version=$("$vim" --version | head -1 | sed 's/ (.*//')
    if [ ! -s "$out" ]; then
      echo "FAIL $version [$backend]: no result (exit $code)"
      status=1
    elif head -1 "$out" | grep -q '^SKIP'; then
      echo "skip $version [$backend]: $(head -1 "$out" | cut -c6-)"
    elif head -1 "$out" | grep -q '^OK'; then
      echo "ok   $version [$backend]: $(head -1 "$out" | cut -c4-)"
    else
      echo "FAIL $version [$backend]:"
      sed 's/^/  /' "$out"
      status=1
    fi
    rm -f "$out"
  done
done
exit $status

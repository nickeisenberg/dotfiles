#!/bin/sh
# Run the tests with each Vim:
#
#   plugins/statusline/test/run.sh
#   VIMS="/usr/bin/vim ~/vim/bin/vim" plugins/statusline/test/run.sh

here=$(cd "$(dirname "$0")" && pwd)
sw=$HOME/software/vim
VIMS=${VIMS:-"$sw/vim-9.0/bin/vim $sw/vim-9.1/bin/vim $sw/vim-9.2/bin/vim"}

status=0
for vim in $VIMS; do
  out=$(mktemp)
  STATUSLINE_TEST_OUT=$out \
    timeout 120 "$vim" -Nu NONE -i NONE -es -S "$here/test.vim" </dev/null >/dev/null 2>&1
  code=$?
  version=$("$vim" --version | head -1 | sed 's/ (.*//')
  if [ ! -s "$out" ]; then
    echo "FAIL $version: no result (exit $code)"
    status=1
  elif head -1 "$out" | grep -q '^OK'; then
    echo "ok   $version: $(head -1 "$out" | cut -c4-)"
  else
    echo "FAIL $version:"
    sed 's/^/  /' "$out"
    status=1
  fi
  rm -f "$out"
done
exit $status

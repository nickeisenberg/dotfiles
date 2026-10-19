#!/bin/sh
# Type into a real Vim (with the full vimrc) in tmux and check that the
# signs follow and the keymaps work: the autocmds for typing don't fire in
# test.vim's -es mode.
#
#   plugins/hunks/test/interactive.sh
#   VIMS="/usr/bin/vim" plugins/hunks/test/interactive.sh
#
# Needs tmux, run on its own server (tmux -L, $HUNKS_TMUX_SERVER), never
# the default one. Prints the screen when a check fails.

here=$(cd "$(dirname "$0")" && pwd)
vimrc=$(cd "$here/../../.." && pwd)/vimrc
sw=$HOME/software/vim
VIMS=${VIMS:-"$sw/vim-9.0/bin/vim $sw/vim-9.1/bin/vim $sw/vim-9.2/bin/vim"}

repo=$(mktemp -d)
git -C "$repo" init -q
printf '1\n2\n3\n4\n5\n' > "$repo/file.txt"
git -C "$repo" add file.txt
git -C "$repo" -c user.name=Test -c user.email=test@example.com commit -qm init

session=hunks-test-$$
server=${HUNKS_TMUX_SERVER:-hunks-test-$$}
t() {
  tmux -L "$server" "$@"
}
out=$repo/out.txt
status=0
failed=0

keys() {
  t send-keys -t "$session" "$@"
  sleep 0.6
}

# check WHAT EXPR WANT: the legacy-syntax EXPR, evaluated in Vim, is WANT.
check() {
  rm -f "$out"
  screen=$(t capture-pane -p -t "$session")
  t send-keys -t "$session" Escape ":call writefile([$2], 'out.txt')" Enter
  sleep 0.4
  got=$(cat "$out" 2>/dev/null)
  if [ "$got" != "$3" ]; then
    echo "  FAIL $1: got '$got', want '$3'"
    echo "$screen" | grep -v '^~ *$' | sed 's/^/    | /'
    failed=1
  fi
}

# check_screen WHAT PATTERN: the screen shows PATTERN.
check_screen() {
  if ! t capture-pane -p -t "$session" | grep -q -- "$2"; then
    echo "  FAIL $1: '$2' not on screen"
    t capture-pane -p -t "$session" | grep -v '^~ *$' | sed 's/^/    | /'
    failed=1
  fi
}

signs='join(map(sign_getplaced(bufnr(), {"group": "hunks"})[0].signs, "v:val.lnum .. v:val.name"))'

for vim in $VIMS; do
  version=$("$vim" --version | head -1 | sed 's/ (.*//')
  failed=0
  git -C "$repo" checkout -q -- file.txt
  t new-session -d -s "$session" -x 100 -y 20 "cd '$repo' && '$vim' -Nu '$vimrc' -n file.txt"
  sleep 1.5

  # Change line 2; add a line after 4 and remove line 5, together a change
  # of line 5.
  keys 'jccchanged' Escape 'jjonew' Escape 'jdd'
  check 'signs while typing' "$signs" '2HunksChange 5HunksChange'

  keys 'gg]c'
  check ']c' "line('.')" 2
  keys ']c'
  check ']c again' "line('.')" 5
  keys 'gg2]c'
  check '2]c' "line('.')" 5
  keys '[c'
  check '[c' "line('.')" 2

  keys ' hp'
  check_screen '<leader>hp' '@@ -2,1 +2,1 @@'

  keys Escape 'ggVG hr'
  check 'visual <leader>hr' "join(getline(1, '\$'), ',')" '1,2,3,4,5'
  check 'no signs after reset' "$signs" ''
  keys 'u'
  check 'u after reset' "getline(2)" 'changed'

  keys 'gg]c hs'
  check '<leader>hs' "system('git show :file.txt') ==# \"1\\nchanged\\n3\\n4\\n5\\n\"" 1
  sleep 0.5
  check 'staged hunk loses its sign' "$signs" '5HunksChange'
  keys ':Hunks undo_stage' Enter
  check ':Hunks undo_stage' "system('git show :file.txt') ==# \"1\\n2\\n3\\n4\\n5\\n\"" 1

  keys 'gg hb'
  check_screen '<leader>hb' 'Test .*[0-9]:[0-9][0-9]'
  keys Escape 'j hb'
  check_screen '<leader>hb on a changed line' 'Not committed yet'

  t send-keys -t "$session" Escape ':qa!' Enter
  sleep 0.3
  t kill-session -t "$session" 2>/dev/null
  if [ $failed = 0 ]; then
    echo "ok   $version"
  else
    echo "FAIL $version"
    status=1
  fi
done
rm -rf "$repo"
exit $status

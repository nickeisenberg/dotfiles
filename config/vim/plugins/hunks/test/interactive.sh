#!/bin/sh
# Type into a real Vim (with the full vimrc) in tmux and check that the
# signs follow: the autocmds for typing don't fire in test.vim's -es mode.
#
#   plugins/hunks/test/interactive.sh
#   VIMS="/usr/bin/vim" plugins/hunks/test/interactive.sh
#
# Needs tmux. Prints each Vim's screen when its check fails.

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
status=0
for vim in $VIMS; do
  version=$("$vim" --version | head -1 | sed 's/ (.*//')
  out=$repo/out.txt
  rm -f "$out"
  git -C "$repo" checkout -q -- file.txt
  tmux new-session -d -s "$session" -x 100 -y 20 "cd '$repo' && '$vim' -Nu '$vimrc' -n file.txt"
  sleep 1.5
  # Change line 2, add a line after 4 and remove line 5 (together, a
  # change of line 5), all by typing.
  tmux send-keys -t "$session" 'jccchanged' Escape 'jjonew' Escape 'jdd'
  sleep 1
  screen=$(tmux capture-pane -p -t "$session")
  tmux send-keys -t "$session" ':call writefile([sign_getplaced(bufnr(), {"group": "hunks"})[0].signs->map("v:val.lnum .. v:val.name")->join()], "out.txt")' Enter
  sleep 0.5
  tmux send-keys -t "$session" ':qa!' Enter
  got=$(cat "$out" 2>/dev/null)
  want='2HunksChange 5HunksChange'
  if [ "$got" = "$want" ]; then
    echo "ok   $version"
  else
    echo "FAIL $version: signs '$got', want '$want'"
    echo "$screen" | sed 's/^/  | /'
    status=1
  fi
  sleep 0.3
  tmux kill-session -t "$session" 2>/dev/null
done
rm -rf "$repo"
exit $status

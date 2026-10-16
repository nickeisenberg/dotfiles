return {
  "jpalardy/vim-slime",
  enabled = true,
  config = function()
    if os.getenv("TMUX") then
        vim.cmd [[
            let tmux_socket = get(split($TMUX, ","), 0)
            let b:slime_config = {"socket_name": tmux_socket, "target_pane": ""}
        ]]
    end

    vim.cmd(
      [[
        let g:slime_target = "tmux"
        let g:slime_default_config = {"socket_name": get(split($TMUX, ","), 0), "target_pane": ""}
        let g:slime_preserve_curpos = 0
        let g:slime_no_mappings = 1
        nmap <c-c>v    <Plug>SlimeConfig
        xmap <c-c><c-c> <Plug>SlimeRegionSend <Esc> `>
        nmap <c-c><c-c> <Plug>SlimeParagraphSend <Esc> }
      ]]
    )
  end,
}

return {
  "echasnovski/mini.starter",
  enabled = true,
  version = false, -- wait till new 0.7.0 release to put it back on semver
  event = "VimEnter",
  config = function ()
    -- local status, starter = pcall(require, "mini.starter")
    -- if not status then
    --   return
    -- end
    local starter = require "mini.starter"
    return {
      starter.setup({
        content_hooks = {
          starter.gen_hook.adding_bullet(""),
          starter.gen_hook.aligning("left", "center"),
        },
        evaluate_single = true,
        footer = os.date(),
        header = table.concat({
          [[                        /\                             ]],
          [[                   /\  //\\                            ]],
          [[            /\    //\\///\\\        /\                 ]],
          [[           //\\  ///\////\\\\  /\  //\\                ]],
          [[          /  ^ \/^ ^/^  ^  ^ \/^ \/  ^ \               ]],
          [[         / ^   /  ^/ ^ ^ ^   ^\ ^/  ^^  \              ]],
          [[        / ^ ^   ^ / ^  ^    ^  \/ ^   ^  \       *     ]],
          [[       /  ^ ^ ^   ^  ^   ^   ____  ^   ^  \     /|\    ]],
          [[      / _ ___________________|  |_____^ ^  \   /||o\   ]],
          [[     / /______________________________\ ^ ^ \ /|o|||\  ]],
          [[    / /________________________________\  ^  /|||||o|\ ]],
          [[   /    ||___|___||||||||||||___|__|||      /||o||||||\]],
          [[  oooooo||___|___||||||||||||___|__|||oooooooooo| |oo  ]],
          [[ ooooooo||||||||||||||||||||||||||||||oooooooooo| |ooo ]],
          [[ooooooooooooooooooooooooooooooooooooooooooooooooooooooo]],
        }, "\n"),
        query_updaters = [[abcdefghilmoqrstuvwxyz0123456789_-,.ABCDEFGHIJKLMOQRSTUVWXYZ]],
        items = {
          { action = "Lazy", name = "l: Lazy", section = "Lazy" },
          { action = "Mason", name = "m: Mason", section = "Language Servers" },
          { action = "MasonLog", name = "ml: MasonLog", section = "Language Servers" },
          { action = "Telescope find_files", name = "f: Find Files", section = "Telescope" },
          { action = "Telescope live_grep", name = "g: Find Word", section = "Telescope" },
          { action = "Telescope oldfiles", name = "r: Recent Files", section = "Telescope" },
        },
      }),
      vim.cmd([[
        augroup MiniStarterJK
          au!
          au User MiniStarterOpened nmap <buffer> j <Cmd>lua MiniStarter.update_current_item('next')<CR>
          au User MiniStarterOpened nmap <buffer> k <Cmd>lua MiniStarter.update_current_item('prev')<CR>
          au User MiniStarterOpened nmap <buffer> <C-p> <Cmd>Telescope find_files<CR>
          au User MiniStarterOpened nmap <buffer> <C-n> <Cmd>Telescope file_browser<CR>
        augroup END
      ]])
    }
  end
}

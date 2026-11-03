return {
  dir = "~/codebaseV2/libs/chatlib/nvim/chatlib.nvim",
  config = function()
    local chatlib = require("chatlib")
    chatlib.setup(
      { 
        size = .3,
        cmd = { "chatlib", "-p", "openrouter" },
      }
    )
  

    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { desc = desc })
    end

    vim.keymap.set("n", "<leader>lr", "<cmd>Chatlib resume<cr>", {
      desc = "Resume Chatlib",
    })
    map("n", "<leader>ll", chatlib.toggle, "Toggle chatlib")
    map("n", "<leader>lC", chatlib.continue_, "Continue the last chatlib session")
    map("n", "<leader>lb", chatlib.send_buffer, "Send buffer to chatlib")
    map("v", "<leader>ls", chatlib.send_visual, "Send lines to chatlib")
    map("n", "<leader>la", chatlib.accept, "Accept chatlib's change")
    map("n", "<leader>ld", chatlib.discuss, "Discuss chatlib's change")
    map("n", "<leader>lx", chatlib.deny, "Deny chatlib's change")
  end,
}

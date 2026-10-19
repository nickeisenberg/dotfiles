return {
  dir = "hunks.nvim",
  config = function()
    local hunks = require("hunks")
    hunks.setup()

    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { desc = desc })
    end

    -- In diff mode ]c and [c keep their built-in meaning.
    map("n", "]c", function()
      if vim.wo.diff then
        vim.cmd.normal({ vim.v.count1 .. "]c", bang = true })
      else
        hunks.next()
      end
    end, "Next hunk")
    map("n", "[c", function()
      if vim.wo.diff then
        vim.cmd.normal({ vim.v.count1 .. "[c", bang = true })
      else
        hunks.prev()
      end
    end, "Previous hunk")

    local function selection()
      return { vim.fn.line("."), vim.fn.line("v") }
    end
    map("n", "<leader>hs", hunks.stage, "Stage hunk")
    map("n", "<leader>hr", hunks.reset, "Reset hunk")
    map("v", "<leader>hs", function()
      hunks.stage(selection())
    end, "Stage selected lines")
    map("v", "<leader>hr", function()
      hunks.reset(selection())
    end, "Reset selected lines")
    map("n", "<leader>hu", hunks.undo_stage, "Undo last stage")
    map("n", "<leader>hp", hunks.preview, "Preview hunk")
    map("n", "<leader>hb", hunks.blame, "Blame line")
    map("n", "<leader>hd", hunks.diffthis, "Diff against index")
  end,
}

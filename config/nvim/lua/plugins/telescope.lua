return {
  'nvim-telescope/telescope.nvim',
  enabled = true,
  branch = '0.1.x',
  dependencies = {
    'nvim-lua/plenary.nvim',
    {
      'nvim-telescope/telescope-fzf-native.nvim',
      build = 'make',
      cond = function()
        return vim.fn.executable 'make' == 1
      end,
    },
  },
  config = function()
    local builtin = require('telescope.builtin')

    vim.keymap.set('n', '<leader>ff', function()
    	local root = string.gsub(vim.fn.system("git rev-parse --show-toplevel"), "\n", "")
    	if vim.v.shell_error == 0 then
    		builtin.find_files({ cwd = root })
    	else
    		builtin.find_files()
    	end
    end)

    vim.keymap.set('n', '<leader>fg', function()
    	local root = string.gsub(vim.fn.system("git rev-parse --show-toplevel"), "\n", "")
    	if vim.v.shell_error == 0 then
    		builtin.find_grep({ cwd = root })
    	else
    		builtin.find_grep()
    	end
    end)
    
    -- vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
    -- vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
    vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
    vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})
    vim.keymap.set('n', '<leader>fd', builtin.diagnostics, {})
    vim.keymap.set('n', '<leader>fs', builtin.spell_suggest, {})
  end
}

return {
  {
    'Zeioth/compiler.nvim',
    dependencies = {
      'stevearc/overseer.nvim',
    },
    cmd = {
      "CompilerOpen",
      "CompilerToggleResults",
      "CompilerRedo",
      "CompilerStop",
    },
    opts = {},
  },
  {
    'stevearc/overseer.nvim',
    cmd = {"OverseerToggle"},
    opts = {
      task_list = {
        direction = "bottom",
        min_height = 25,
        max_height = 25,
        default_detail = 1,
      },
    },
  },
}

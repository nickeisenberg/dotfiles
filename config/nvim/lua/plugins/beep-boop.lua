return {
  "EggbertFluffle/beepboop.nvim",
  enabled = false,
  opts = {
    audio_player = "paplay",
    max_sounds = 20,
    sound_map = {
      {
        auto_command = "InsertCharPre",
        sounds = { "stone1.oga", "stone2.oga", "stone3.oga" }
      }
    }
  },
}

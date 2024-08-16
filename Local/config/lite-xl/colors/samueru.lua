local style = require "core.style"
local common = require "core.common"

-- App --
style.background = { common.color "#04090e" }
style.background2 = { common.color "#091f2e" }
style.background3 = { common.color "#091f2e" }
style.text = { common.color "#F0C674" }
style.caret = { common.color "#F0C674" }
style.accent = { common.color "#ffb86c" }
style.dim = { common.color "#707282" }
style.divider = { common.color "#22242e" }
style.selection = { common.color "#4c5163" }
style.line_number = { common.color "#44475a" }
style.line_number2 = { common.color "#717796" }
style.line_highlight = { common.color "#2d303d" }
style.scrollbar = { common.color "#44475a" }
style.scrollbar2 = { common.color "#4c5163" }

-- Syntax --
style.syntax = {}
style.syntax["normal"] = { common.color "#f5faff" }
style.syntax["symbol"] = { common.color "#F0C674" }
style.syntax["comment"] = { common.color "#707282" }
style.syntax["keyword"] = { common.color "#F0C674" }
style.syntax["keyword2"] = { common.color "#05e6fa" }
style.syntax["number"] = { common.color "#cb4c51" }
style.syntax["literal"] = { common.color "#cb4c51" }
style.syntax["string"] = { common.color "#b2c8df" }
style.syntax["operator"] = { common.color "#F0C674" }
style.syntax["function"] = { common.color "#cb4c51" }

-- Lint+ --
style.lint               = {}
style.lint["info"]       = { common.color "#448bf5" }
style.lint["hint"]       = { common.color "#47e2b1" }
style.lint["warning"]    = { common.color "#f5ad44" }
style.lint["error"]      = { common.color "#db504a" }

local style      = require "core.style"
local common     = require "core.common"
local dark_blue  = { common.color "#091927" }
local blue       = { common.color "#175178" }
local light_blue = { common.color "#05e6fa" }
local red        = { common.color "#cb4c51" }
local gray_blue  = { common.color "#707282" }
local light_gray = { common.color "#b2c8df" }
local white      = { common.color "#d4d9d6" }
local yellow     = { common.color "#fdbc4b" }

-- App --
style.background     = { common.color "#04090e" }
style.background2    = { common.color "#091f2e" }
style.background3    = { common.color "#091f2e" }
style.text           = white
style.caret          = yellow
style.accent         = white
style.dim            = gray_blue
style.divider        = yellow
style.selection      = blue
style.line_number    = gray_blue
style.line_number2   = red
style.line_highlight = dark_blue
style.scrollbar      = yellow
style.scrollbar2     = yellow

-- Syntax --
style.syntax = {}
style.syntax["normal"]   = white
style.syntax["symbol"]   = light_blue
style.syntax["comment"]  = gray_blue
style.syntax["keyword"]  = yellow
style.syntax["keyword2"] = light_blue
style.syntax["number"]   = red
style.syntax["literal"]  = red
style.syntax["string"]   = light_gray
style.syntax["operator"] = yellow
style.syntax["function"] = red

-- Lint+ --
style.lint            = {}
style.lint["info"]    = white
style.lint["hint"]    = yellow
style.lint["warning"] = red
style.lint["error"]   = red

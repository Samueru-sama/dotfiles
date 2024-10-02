return {
  ["config"] = {
    ["always_show_tabs"] = true,
    ["blink_period"] = 0.8,
    ["borderless"] = false,
    ["code_font"] = {
      ["fonts"] = {
        [1] = {
          ["name"] = "Droid Sans Mono Regular",
          ["path"] = "/usr/share/fonts/droid/DroidSansMono.ttf"
        },
        [2] = {
          ["name"] = "Nimbus Sans Bold",
          ["path"] = "/usr/share/fonts/gsfonts/NimbusSans-Bold.otf"
        },
        [3] = {
          ["name"] = "Font Awesome 6 Free Solid",
          ["path"] = "/usr/share/fonts/TTF/fa-solid-900.ttf"
        }
      },
      ["options"] = {
        ["antialiasing"] = "subpixel",
        ["bold"] = true,
        ["hinting"] = "full",
        ["italic"] = false,
        ["size"] = 12,
        ["smoothing"] = false,
        ["strikethrough"] = false,
        ["underline"] = false
      }
    },
    ["custom_keybindings"] = {
      ["core:new-doc"] = {
        [1] = "ctrl+n",
        [2] = "ctrl+t"
      },
      ["doc:move-to-end-of-line"] = {
        [1] = "end",
        [2] = "alt+right"
      },
      ["doc:move-to-next-page"] = {
        [1] = "pagedown",
        [2] = "alt+down",
        [3] = "alt+d"
      },
      ["doc:move-to-previous-page"] = {
        [1] = "pageup",
        [2] = "alt+up",
        [3] = "alt+e"
      },
      ["doc:move-to-start-of-indentation"] = {
        [1] = "home",
        [2] = "alt+left"
      },
      ["doc:newline"] = {
        [1] = "shift+return",
        [2] = "shift+keypad enter"
      },
      ["doc:select-to-end-of-line"] = {
        [1] = "shift+end",
        [2] = "shift+alt+right"
      },
      ["doc:select-to-start-of-line"] = {
        [1] = "shift+alt+left"
      },
      ["line-wrapping:toggle"] = {
        [1] = "f10",
        [2] = "alt+r"
      },
      ["lineguide:toggle"] = {
        [1] = "shift+alt+r"
      },
      ["root:switch-to-tab-1"] = {
        [1] = "ctrl+1"
      },
      ["root:switch-to-tab-2"] = {
        [1] = "ctrl+2"
      },
      ["root:switch-to-tab-3"] = {
        [1] = "ctrl+3"
      },
      ["root:switch-to-tab-4"] = {
        [1] = "ctrl+4"
      },
      ["root:switch-to-tab-5"] = {
        [1] = "ctrl+5"
      },
      ["root:switch-to-tab-6"] = {
        [1] = "ctrl+6"
      },
      ["root:switch-to-tab-7"] = {
        [1] = "ctrl+7"
      },
      ["root:switch-to-tab-8"] = {
        [1] = "ctrl+8"
      },
      ["root:switch-to-tab-9"] = {
        [1] = "ctrl+9"
      },
      ["scale:decrease"] = {
        [1] = "ctrl+-",
        [2] = "ctrl+wheeldown",
        [3] = "ctrl+keypad -"
      },
      ["scale:increase"] = {
        [1] = "ctrl+=",
        [2] = "ctrl+wheelup",
        [3] = "ctrl+keypad +"
      },
      ["scale:reset"] = {
        [1] = "ctrl+0",
        [2] = "ctrl+keypad *"
      },
      ["treeview:toggle"] = {
        [1] = "ctrl+m",
        [2] = "ctrl+b"
      },
      ["ui:settings"] = {
        [1] = "ctrl+p"
      }
    },
    ["disabled_plugins"] = {
      ["terminal"] = true,
      ["treeview"] = true
    },
    ["enabled_plugins"] = {
      ["linewrapping"] = true,
      ["treeview2"] = true
    },
    ["font"] = {
      ["fonts"] = {
        [1] = {
          ["name"] = "Nimbus Sans Narrow Bold",
          ["path"] = "/usr/share/fonts/gsfonts/NimbusSansNarrow-Bold.otf"
        }
      },
      ["options"] = {
        ["antialiasing"] = "subpixel",
        ["bold"] = true,
        ["hinting"] = "slight",
        ["italic"] = false,
        ["size"] = 13,
        ["smoothing"] = false,
        ["strikethrough"] = false,
        ["underline"] = false
      }
    },
    ["force_scrollbar_status"] = false,
    ["fps"] = 79,
    ["indent_size"] = 4,
    ["line_height"] = 1.2,
    ["line_limit"] = 79,
    ["max_project_files"] = 1000,
    ["max_tabs"] = 8,
    ["max_undos"] = 2000,
    ["message_timeout"] = 5,
    ["plugins"] = {
      ["drawwhitespace"] = {
        ["enabled"] = true,
        ["show_middle"] = false,
        ["show_trailing"] = true,
        ["show_trailing_error"] = true
      },
      ["language_php"] = {
        ["sql_strings"] = false
      },
      ["lineguide"] = {
        ["enabled"] = true,
        ["rulers"] = {
          [1] = 80
        },
        ["width"] = 1
      },
      ["linewrapping"] = {
        ["enable_by_default"] = true,
        ["mode"] = "word"
      },
      ["terminal"] = {
        ["background"] = {
          [1] = 9,
          [2] = 31,
          [3] = 46,
          [4] = 255
        },
        ["font"] = {
          ["fonts"] = {
            [1] = {
              ["name"] = "Liberation Mono Bold",
              ["path"] = "/usr/share/fonts/liberation/LiberationMono-Bold.ttf"
            }
          },
          ["options"] = {
            ["antialiasing"] = "none",
            ["bold"] = false,
            ["hinting"] = "none",
            ["italic"] = false,
            ["size"] = 12,
            ["smoothing"] = false,
            ["strikethrough"] = false,
            ["underline"] = false
          }
        },
        ["text"] = {
          [1] = 225,
          [2] = 225,
          [3] = 230,
          [4] = 255
        }
      },
      ["treeview"] = {
        ["size"] = 200.0,
        ["visible"] = true
      },
      ["trimwhitespace"] = {
        ["enabled"] = true,
        ["trim_empty_end_lines"] = false
      }
    },
    ["skip_plugins_version"] = true,
    ["tab_type"] = "hard",
    ["theme"] = "samueru"
  }
}

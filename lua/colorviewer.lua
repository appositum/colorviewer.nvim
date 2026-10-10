-- 🌈 ColorViewer: A simple inline color preview plugin for Neovim
-- Author: Rehd
-- Description:
--   Detects color names and hex values in your files, and shows a small colored
--   square (■ by default) inline beside them. Works automatically on common
--   frontend filetypes like CSS, HTML, JS, etc.

------------------------------------------------------------
-- Module setup
------------------------------------------------------------
local M = {}
local ns_id = vim.api.nvim_create_namespace("colorviewer")

------------------------------------------------------------
-- Color name → hex value map
-- Feel free to modify this table with more or less color names
------------------------------------------------------------
local color_map = {
  aliceblue = "#F0F8FF",
  antiquewhite = "#FAEBD7",
  aqua = "#00FFFF",
  aquamarine = "#7FFFD4",
  azure = "#F0FFFF",
  beige = "#F5F5DC",
  bisque = "#FFE4C4",
  black = "#000000",
  blanchedalmond = "#FFEBCD",
  blue = "#0000FF",
  blueviolet = "#8A2BE2",
  brown = "#A52A2A",
  burlywood = "#DEB887",
  cadetblue = "#5F9EA0",
  chartreuse = "#7FFF00",
  chocolate = "#D2691E",
  coral = "#FF7F50",
  cornflowerblue = "#6495ED",
  cornsilk = "#FFF8DC",
  crimson = "#DC143C",
  cyan = "#00FFFF",
  darkblue = "#00008B",
  darkcyan = "#008B8B",
  darkgoldenrod = "#B8860B",
  darkgray = "#A9A9A9",
  darkgreen = "#006400",
  darkgrey = "#A9A9A9",
  darkkhaki = "#BDB76B",
  darkmagenta = "#8B008B",
  darkolivegreen = "#556B2F",
  darkorange = "#FF8C00",
  darkorchid = "#9932CC",
  darkred = "#8B0000",
  darksalmon = "#E9967A",
  darkseagreen = "#8FBC8F",
  darkslateblue = "#483D8B",
  darkslategray = "#2F4F4F",
  darkslategrey = "#2F4F4F",
  darkturquoise = "#00CED1",
  darkviolet = "#9400D3",
  deeppink = "#FF1493",
  deepskyblue = "#00BFFF",
  dimgray = "#696969",
  dimgrey = "#696969",
  dodgerblue = "#1E90FF",
  firebrick = "#B22222",
  floralwhite = "#FFFAF0",
  forestgreen = "#228B22",
  fuchsia = "#FF00FF",
  gainsboro = "#DCDCDC",
  ghostwhite = "#F8F8FF",
  gold = "#FFD700",
  goldenrod = "#DAA520",
  gray = "#808080",
  green = "#008000",
  greenyellow = "#ADFF2F",
  grey = "#808080",
  honeydew = "#F0FFF0",
  hotpink = "#FF69B4",
  indianred = "#CD5C5C",
  indigo = "#4B0082",
  ivory = "#FFFFF0",
  khaki = "#F0E68C",
  lavender = "#E6E6FA",
  lavenderblush = "#FFF0F5",
  lawngreen = "#7CFC00",
  lemonchiffon = "#FFFACD",
  lightblue = "#ADD8E6",
  lightcoral = "#F08080",
  lightcyan = "#E0FFFF",
  lightgoldenrodyellow = "#FAFAD2",
  lightgray = "#D3D3D3",
  lightgreen = "#90EE90",
  lightgrey = "#D3D3D3",
  lightpink = "#FFB6C1",
  lightsalmon = "#FFA07A",
  lightseagreen = "#20B2AA",
  lightskyblue = "#87CEFA",
  lightslategray = "#778899",
  lightslategrey = "#778899",
  lightsteelblue = "#B0C4DE",
  lightyellow = "#FFFFE0",
  lime = "#B7FF00",
  limegreen = "#32CD32",
  linen = "#FAF0E6",
  magenta = "#FF00FF",
  maroon = "#800000",
  mediumaquamarine = "#66CDAA",
  mediumblue = "#0000CD",
  mediumorchid = "#BA55D3",
  mediumpurple = "#9370DB",
  mediumseagreen = "#3CB371",
  mediumslateblue = "#7B68EE",
  mediumspringgreen = "#00FA9A",
  mediumturquoise = "#48D1CC",
  mediumvioletred = "#C71585",
  midnightblue = "#191970",
  mintcream = "#F5FFFA",
  mistyrose = "#FFE4E1",
  moccasin = "#FFE4B5",
  navajowhite = "#FFDEAD",
  navy = "#000080",
  oldlace = "#FDF5E6",
  olive = "#808000",
  olivedrab = "#6B8E23",
  orange = "#FFA500",
  orangered = "#FF4500",
  orchid = "#DA70D6",
  palegoldenrod = "#EEE8AA",
  palegreen = "#98FB98",
  paleturquoise = "#AFEEEE",
  palevioletred = "#DB7093",
  papayawhip = "#FFEFD5",
  peachpuff = "#FFDAB9",
  peru = "#CD853F",
  pink = "#FFC0CB",
  plum = "#DDA0DD",
  powderblue = "#B0E0E6",
  purple = "#800080",
  rebeccapurple = "#663399",
  red = "#FF0000",
  rosybrown = "#BC8F8F",
  royalblue = "#4169E1",
  saddlebrown = "#8B4513",
  salmon = "#FA8072",
  sandybrown = "#F4A460",
  seagreen = "#2E8B57",
  seashell = "#FFF5EE",
  sienna = "#A0522D",
  silver = "#C0C0C0",
  skyblue = "#87CEEB",
  slateblue = "#6A5ACD",
  slategray = "#708090",
  slategrey = "#708090",
  snow = "#FFFAFA",
  springgreen = "#00FF7F",
  steelblue = "#4682B4",
  tan = "#D2B48C",
  teal = "#008080",
  thistle = "#D8BFD8",
  tomato = "#FF6347",
  turquoise = "#40E0D0",
  violet = "#EE82EE",
  wheat = "#F5DEB3",
  white = "#FFFFFF",
  whitesmoke = "#F5F5F5",
  yellow = "#FFFF00",
  yellowgreen = "#9ACD32",
}


------------------------------------------------------------
-- Create or fetch a highlight group for a given color
------------------------------------------------------------
local function get_highlight_group(color)
  local group = "ColorViewer_" .. color:gsub("#", "")
  vim.api.nvim_set_hl(0, group, { fg = color })
  return group
end

------------------------------------------------------------
-- Main function: Scan the current buffer and show color boxes
------------------------------------------------------------
function M.show_color_boxes()
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  for i, line in ipairs(lines) do
    --------------------------------------------------------
    -- Match any #RRGGBB hex colors and show a color box
    --------------------------------------------------------
    if M.config.highlight.codes ~= false then
      for hex in line:gmatch("#%x%x%x%x%x%x") do
        local hl_group = get_highlight_group(hex)
        local start = line:find(hex)
        if start then
          vim.api.nvim_buf_set_extmark(bufnr, ns_id, i - 1, start - 1, {
            virt_text = { { M.config.symbol, hl_group } },
            virt_text_pos = "inline",
          })
        end
      end
    end

    --------------------------------------------------------
    -- Match known color names from our color_map
    --------------------------------------------------------
    if M.config.highlight.names ~= false then
      for color_name, hex in pairs(color_map) do
        local start = line:find(color_name)
        if start then
          local hl_group = get_highlight_group(hex)
          vim.api.nvim_buf_set_extmark(bufnr, ns_id, i - 1, start - 1, {
            virt_text = { { M.config.symbol, hl_group } },
            virt_text_pos = "inline",
          })
        end
      end
    end
  end
end

------------------------------------------------------------
-- Manual command: :ShowColorBoxes
-- Useful for testing or forcing refresh
------------------------------------------------------------
vim.api.nvim_create_user_command("ShowColorBoxes", function()
  require("colorviewer").show_color_boxes()
end, {})

------------------------------------------------------------
-- Auto-update on buffer changes for some filetypes
------------------------------------------------------------
vim.api.nvim_create_autocmd({ "TextChanged", "BufWrite", "BufEnter" }, {
  pattern = {
    "*.css", "*.scss", "*.less", "*.styl",
    "*.html", "*.htm",
    "*.js", "*.jsx", "*.ts", "*.tsx",
    "*.vue", "*.svelte",
  },
  callback = function(args)
    local bufnr = args.buf
    local changedtick = vim.b[bufnr].changedtick
    if vim.b[bufnr]._last_tick ~= changedtick then
      vim.b[bufnr]._last_tick = changedtick
      require("colorviewer").show_color_boxes(bufnr)
    end
  end,
})

------------------------------------------------------------
-- Configuration
-- You can change the display symbol here or via setup()
------------------------------------------------------------
M.config = {
  symbol = "■", -- the inline color box symbol
  highlight = {
    names = true,
    codes = true,
  },
}

function M.setup(opts)
  M.config = vim.tbl_extend("force", M.config, opts or {})
end

------------------------------------------------------------
-- Return module
------------------------------------------------------------
return M


------------------------
--- (╯°□°）╯︵ ┻━┻ 
--- 😅
-----------------------

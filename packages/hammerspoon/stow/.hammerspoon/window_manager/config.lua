return {
  debug = false,
  logLevel = "warning",

  ultrawide = {
    pixelWidth = 5120,
    pixelHeight = 1440,
    -- Optional Lua patterns. Resolution is authoritative; these are useful if
    -- macOS later reports a scaled mode.
    namePatterns = { "^LG HDR DQHD$" },
  },

  grid = { columns = 4, rows = 2 },
  overlay = {
    gap = 8,
    fill = { red = 0.20, green = 0.55, blue = 0.95, alpha = 0.16 },
    selectedFill = { red = 0.20, green = 0.70, blue = 1.00, alpha = 0.42 },
    stroke = { red = 0.45, green = 0.80, blue = 1.00, alpha = 0.95 },
  },
}

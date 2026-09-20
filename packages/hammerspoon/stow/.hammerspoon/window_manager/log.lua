local config = require("window_manager.config")
local logger = hs.logger.new("adaptive-wm", config.debug and "debug" or config.logLevel)

local M = {}

function M.debug(message, ...)
  if config.debug then logger.df(message, ...) end
end

function M.info(message, ...)
  logger.i(string.format(message, ...))
end

function M.warning(message, ...)
  logger.wf(message, ...)
end

return M

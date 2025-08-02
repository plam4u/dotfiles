local function format_vimwiki_link(line, max_width)
  max_width = max_width or 66

  -- Extract link ID and alias from [[ID|alias]] format
  local link_id, alias = line:match("%[%[([^|]+)|([^%]]+)%]%]")

  if not link_id or not alias then
    return line -- Return original if pattern doesn't match
  end

  -- Calculate components
  local bare_link = "[[" .. link_id .. "]]"
  local spaces = 2 -- One space before and after dots
  local dots_needed = max_width - #alias - #bare_link - spaces

  -- Ensure we have at least one dot
  dots_needed = math.max(1, dots_needed)

  -- Build the formatted line
  local dots = string.rep(".", dots_needed)
  return alias .. " " .. dots .. " " .. bare_link
end

vim.api.nvim_create_user_command("FormatVimwikiLink", function(opts)
  local max_width = opts.args and tonumber(opts.args) or 66
  local line = vim.fn.getline(".")
  local formatted_line = format_vimwiki_link(line, max_width)
  vim.fn.setline(".", formatted_line)
end, {
  nargs = "?",
  complete = function(_, _, _)
    return { "66", "80", "100", "120" } -- Example completions for max width
  end,
})


M = {}

-- Like urlencode, but use stars instead of %
function M.star_encode(str)
  if type(str) ~= "number" then
    str = str:gsub("\r?\n", "\r\n")
    str = str:gsub("([^%w%-%.%_%~ ])", function(c)
      return string.format("*%02X", c:byte())
    end)
    str = str:gsub(" ", "+")
    return str
  else
    return str
  end
end

return M

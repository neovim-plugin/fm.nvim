local fs = require("fm.fs")

if fs.is_mac then
  return require("fm.adapters.trash.mac")
elseif fs.is_windows then
  return require("fm.adapters.trash.windows")
else
  return require("fm.adapters.trash.freedesktop")
end

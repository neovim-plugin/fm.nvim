local fm = require("fm")
local util = require("fm.util")
describe("url", function()
  it("get_url_for_path", function()
    local cases = {
      { "", "fm://" .. util.addslash(vim.fn.getcwd()) },
      { "term://~/fm.nvim//52953:/bin/sh", "fm://" .. vim.loop.os_homedir() .. "/fm.nvim/" },
      { "/foo/bar.txt", "fm:///foo/", "bar.txt" },
      { "fm:///foo/bar.txt", "fm:///foo/", "bar.txt" },
      { "fm:///", "fm:///" },
      { "fm-ssh://user@hostname:8888//bar.txt", "fm-ssh://user@hostname:8888//", "bar.txt" },
      { "fm-ssh://user@hostname:8888//", "fm-ssh://user@hostname:8888//" },
    }
    for _, case in ipairs(cases) do
      local input, expected, expected_basename = unpack(case)
      local output, basename = fm.get_buffer_parent_url(input, true)
      assert.equals(expected, output, string.format('Parent url for path "%s" failed', input))
      assert.equals(
        expected_basename,
        basename,
        string.format('Basename for path "%s" failed', input)
      )
    end
  end)
end)

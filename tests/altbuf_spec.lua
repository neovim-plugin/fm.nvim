require("plenary.async").tests.add_to_env()
local fs = require("fm.fs")
local fm = require("fm")
local test_util = require("tests.test_util")

a.describe("Alternate buffer", function()
  after_each(function()
    test_util.reset_editor()
  end)

  a.it("sets previous buffer as alternate", function()
    vim.cmd.edit({ args = { "foo" } })
    fm.open()
    test_util.wait_for_autocmd({ "User", pattern = "FmEnter" })
    vim.cmd.edit({ args = { "bar" } })
    assert.equals("foo", vim.fn.expand("#"))
  end)

  a.it("sets previous buffer as alternate when editing url file", function()
    vim.cmd.edit({ args = { "foo" } })
    fm.open()
    test_util.wait_for_autocmd({ "User", pattern = "FmEnter" })
    local readme = fs.join(vim.fn.getcwd(), "README.md")
    vim.cmd.edit({ args = { "fm://" .. fs.os_to_posix_path(readme) } })
    -- We're gonna jump around to 2 different buffers
    test_util.wait_for_autocmd("BufEnter")
    test_util.wait_for_autocmd("BufEnter")
    assert.equals(readme, vim.api.nvim_buf_get_name(0))
    assert.equals("foo", vim.fn.expand("#"))
  end)

  a.it("sets previous buffer as alternate when editing fm://", function()
    vim.cmd.edit({ args = { "foo" } })
    vim.cmd.edit({ args = { "fm://" .. fs.os_to_posix_path(vim.fn.getcwd()) } })
    test_util.wait_for_autocmd({ "User", pattern = "FmEnter" })
    vim.cmd.edit({ args = { "bar" } })
    assert.equals("foo", vim.fn.expand("#"))
  end)

  a.it("preserves alternate buffer if editing the same file", function()
    vim.cmd.edit({ args = { "foo" } })
    vim.cmd.edit({ args = { "bar" } })
    fm.open()
    test_util.wait_for_autocmd({ "User", pattern = "FmEnter" })
    vim.cmd.edit({ args = { "bar" } })
    assert.equals("foo", vim.fn.expand("#"))
  end)

  a.it("preserves alternate buffer if discarding changes", function()
    vim.cmd.edit({ args = { "foo" } })
    vim.cmd.edit({ args = { "bar" } })
    fm.open()
    test_util.wait_for_autocmd({ "User", pattern = "FmEnter" })
    fm.close()
    assert.equals("bar", vim.fn.expand("%"))
    assert.equals("foo", vim.fn.expand("#"))
  end)

  a.it("sets previous buffer as alternate after multi-dir hops", function()
    vim.cmd.edit({ args = { "foo" } })
    fm.open()
    test_util.wait_for_autocmd({ "User", pattern = "FmEnter" })
    fm.open()
    test_util.wait_for_autocmd({ "User", pattern = "FmEnter" })
    fm.open()
    test_util.wait_for_autocmd({ "User", pattern = "FmEnter" })
    fm.open()
    test_util.wait_for_autocmd({ "User", pattern = "FmEnter" })
    vim.cmd.edit({ args = { "bar" } })
    assert.equals("foo", vim.fn.expand("#"))
  end)

  a.it("sets previous buffer as alternate when inside fm buffer", function()
    vim.cmd.edit({ args = { "foo" } })
    fm.open()
    test_util.wait_for_autocmd({ "User", pattern = "FmEnter" })
    assert.equals("foo", vim.fn.expand("#"))
    vim.cmd.edit({ args = { "bar" } })
    assert.equals("foo", vim.fn.expand("#"))
    fm.open()
    assert.equals("bar", vim.fn.expand("#"))
  end)

  a.it("preserves alternate when traversing fm dirs", function()
    vim.cmd.edit({ args = { "foo" } })
    fm.open()
    test_util.wait_for_autocmd({ "User", pattern = "FmEnter" })
    assert.equals("foo", vim.fn.expand("#"))
    vim.wait(1000, function()
      return fm.get_cursor_entry()
    end, 10)
    vim.api.nvim_win_set_cursor(0, { 1, 1 })
    fm.select()
    test_util.wait_for_autocmd({ "User", pattern = "FmEnter" })
    assert.equals("foo", vim.fn.expand("#"))
  end)

  a.it("preserves alternate when opening preview", function()
    vim.cmd.edit({ args = { "foo" } })
    fm.open()
    test_util.wait_for_autocmd({ "User", pattern = "FmEnter" })
    assert.equals("foo", vim.fn.expand("#"))
    vim.wait(1000, function()
      return fm.get_cursor_entry()
    end, 10)
    vim.api.nvim_win_set_cursor(0, { 1, 1 })
    fm.open_preview()
    test_util.wait_for_autocmd({ "User", pattern = "FmEnter" })
    assert.equals("foo", vim.fn.expand("#"))
  end)

  a.describe("floating window", function()
    a.it("sets previous buffer as alternate", function()
      vim.cmd.edit({ args = { "foo" } })
      fm.open_float()
      test_util.wait_for_autocmd({ "User", pattern = "FmEnter" })
      -- This is lazy, but testing the actual select logic is more difficult. We can simply
      -- replicate it by closing the current window and then doing the edit
      vim.api.nvim_win_close(0, true)
      vim.cmd.edit({ args = { "bar" } })
      assert.equals("foo", vim.fn.expand("#"))
    end)

    a.it("preserves alternate buffer if editing the same file", function()
      vim.cmd.edit({ args = { "foo" } })
      vim.cmd.edit({ args = { "bar" } })
      fm.open_float()
      test_util.wait_for_autocmd({ "User", pattern = "FmEnter" })
      -- This is lazy, but testing the actual select logic is more difficult. We can simply
      -- replicate it by closing the current window and then doing the edit
      vim.api.nvim_win_close(0, true)
      vim.cmd.edit({ args = { "bar" } })
      assert.equals("foo", vim.fn.expand("#"))
    end)

    a.it("preserves alternate buffer if discarding changes", function()
      vim.cmd.edit({ args = { "foo" } })
      vim.cmd.edit({ args = { "bar" } })
      fm.open_float()
      test_util.wait_for_autocmd({ "User", pattern = "FmEnter" })
      fm.close()
      assert.equals("foo", vim.fn.expand("#"))
    end)
  end)
end)

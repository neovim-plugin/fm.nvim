require("plenary.async").tests.add_to_env()
local TmpDir = require("tests.tmpdir")
local actions = require("fm.actions")
local fm = require("fm")
local test_util = require("tests.test_util")
local view = require("fm.view")

a.describe("regression tests", function()
  local tmpdir
  a.before_each(function()
    tmpdir = TmpDir.new()
  end)
  a.after_each(function()
    if tmpdir then
      tmpdir:dispose()
      tmpdir = nil
    end
    test_util.reset_editor()
  end)

  -- see https://github.com/stevearc/fm.nvim/issues/25
  a.it("can edit dirs that will be renamed to an existing buffer", function()
    vim.cmd.edit({ args = { "README.md" } })
    vim.cmd.vsplit()
    vim.cmd.edit({ args = { "%:p:h" } })
    assert.equals("fm", vim.bo.filetype)
    vim.cmd.wincmd({ args = { "p" } })
    assert.equals("markdown", vim.bo.filetype)
    vim.cmd.edit({ args = { "%:p:h" } })
    test_util.wait_for_autocmd({ "User", pattern = "FmEnter" })
    assert.equals("fm", vim.bo.filetype)
  end)

  -- https://github.com/stevearc/fm.nvim/issues/37
  a.it("places the cursor on correct entry when opening on file", function()
    vim.cmd.edit({ args = { "." } })
    test_util.wait_for_autocmd({ "User", pattern = "FmEnter" })
    local entry = fm.get_cursor_entry()
    assert.not_nil(entry)
    assert.not_equals("README.md", entry and entry.name)
    vim.cmd.edit({ args = { "README.md" } })
    view.delete_hidden_buffers()
    fm.open()
    test_util.wait_for_autocmd({ "User", pattern = "FmEnter" })
    entry = fm.get_cursor_entry()
    assert.equals("README.md", entry and entry.name)
  end)

  -- https://github.com/stevearc/fm.nvim/issues/64
  a.it("doesn't close floating windows fm didn't open itself", function()
    local winid = vim.api.nvim_open_win(vim.fn.bufadd("README.md"), true, {
      relative = "editor",
      row = 1,
      col = 1,
      width = 100,
      height = 100,
    })
    fm.open()
    a.util.sleep(10)
    fm.close()
    a.util.sleep(10)
    assert.equals(winid, vim.api.nvim_get_current_win())
  end)

  -- https://github.com/stevearc/fm.nvim/issues/64
  a.it("doesn't close splits on fm.close", function()
    vim.cmd.edit({ args = { "README.md" } })
    vim.cmd.vsplit()
    local winid = vim.api.nvim_get_current_win()
    local bufnr = vim.api.nvim_get_current_buf()
    fm.open()
    a.util.sleep(10)
    fm.close()
    a.util.sleep(10)
    assert.equals(2, #vim.api.nvim_tabpage_list_wins(0))
    assert.equals(winid, vim.api.nvim_get_current_win())
    assert.equals(bufnr, vim.api.nvim_get_current_buf())
  end)

  -- https://github.com/stevearc/fm.nvim/issues/79
  a.it("Returns to empty buffer on close", function()
    fm.open()
    test_util.wait_for_autocmd({ "User", pattern = "FmEnter" })
    fm.close()
    assert.not_equals("fm", vim.bo.filetype)
    assert.equals("", vim.api.nvim_buf_get_name(0))
  end)

  a.it("All buffers set nomodified after save", function()
    tmpdir:create({ "a.txt" })
    a.util.scheduler()
    vim.cmd.edit({ args = { "fm://" .. vim.fn.fnamemodify(tmpdir.path, ":p") } })
    local first_dir = vim.api.nvim_get_current_buf()
    test_util.wait_for_autocmd({ "User", pattern = "FmEnter" })
    test_util.feedkeys({ "dd", "itest/<esc>", "<CR>" }, 10)
    vim.wait(1000, function()
      return vim.bo.modifiable
    end, 10)
    test_util.feedkeys({ "p" }, 10)
    a.util.scheduler()
    fm.save({ confirm = false })
    vim.wait(1000, function()
      return vim.bo.modifiable
    end, 10)
    tmpdir:assert_fs({
      ["test/a.txt"] = "a.txt",
    })
    -- The first fm buffer should not be modified anymore
    assert.falsy(vim.bo[first_dir].modified)
  end)

  a.it("refreshing buffer doesn't lose track of it", function()
    vim.cmd.edit({ args = { "." } })
    test_util.wait_for_autocmd({ "User", pattern = "FmEnter" })
    local bufnr = vim.api.nvim_get_current_buf()
    vim.cmd.edit({ bang = true })
    test_util.wait_for_autocmd({ "User", pattern = "FmEnter" })
    assert.are.same({ bufnr }, require("fm.view").get_all_buffers())
  end)

  a.it("can copy a file multiple times", function()
    test_util.actions.open({ tmpdir.path })
    vim.api.nvim_feedkeys("ifoo.txt", "x", true)
    test_util.actions.save()
    vim.api.nvim_feedkeys("yyp$ciWbar.txt", "x", true)
    vim.api.nvim_feedkeys("yyp$ciWbaz.txt", "x", true)
    test_util.actions.save()
    assert.are.same({ "bar.txt", "baz.txt", "foo.txt" }, test_util.parse_entries(0))
    tmpdir:assert_fs({
      ["foo.txt"] = "",
      ["bar.txt"] = "",
      ["baz.txt"] = "",
    })
  end)

  -- https://github.com/stevearc/fm.nvim/issues/355
  a.it("can open files from floating window", function()
    tmpdir:create({ "a.txt" })
    a.util.scheduler()
    fm.open_float(tmpdir.path)
    test_util.wait_for_autocmd({ "User", pattern = "FmEnter" })
    actions.select.callback()
    vim.wait(1000, function()
      return vim.fn.expand("%:t") == "a.txt"
    end, 10)
    assert.equals("a.txt", vim.fn.expand("%:t"))
  end)
end)

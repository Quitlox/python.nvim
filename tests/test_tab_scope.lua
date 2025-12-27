-- Define helper aliases
local new_set = MiniTest.new_set
local expect, eq = MiniTest.expect, MiniTest.expect.equality

-- Create (but not start) child Neovim object
local child = MiniTest.new_child_neovim()

-- Define main test set of this file
local T = new_set({
  -- Register hooks
  hooks = {
    -- This will be executed before every (even nested) case
    pre_case = function()
      -- Restart child process with custom 'init.lua' script
      child.restart({ "-u", "scripts/minimal_init.lua" })
    end,
    -- This will be executed one after all tests from this set are finished
    post_once = child.stop,
  },
})

T["tab_scope"] = MiniTest.new_set()

-- Test that venv_scope defaults to "global"
T["tab_scope"]["default_is_global"] = function()
  child.lua([[require('python').setup({})]])
  local scope = child.lua([[return require('python.config').venv_scope]])
  eq(scope, "global")
end

-- Test that venv_scope can be set to "tab"
T["tab_scope"]["can_set_to_tab"] = function()
  child.lua([[require('python').setup({ venv_scope = "tab" })]])
  local scope = child.lua([[return require('python.config').venv_scope]])
  eq(scope, "tab")
end

-- Test that in global scope, venv is shared across tabs
T["tab_scope"]["global_scope_shares_venv"] = function()
  child.lua([[require('python').setup({ venv_scope = "global" })]])

  -- Set a venv in tab 1
  child.lua([[
    local venv = require('python.venv')
    venv.set_venv_path({ path = '/test/venv1', name = 'venv1', source = 'venv' })
  ]])

  -- Get the venv in tab 1
  local venv1 = child.lua([[
    local venv = require('python.venv')
    return venv.current_venv()
  ]])
  eq(venv1.name, "venv1")

  -- Create a new tab (tab 2)
  child.cmd("tabnew")

  -- Get the venv in tab 2 - should be the same as tab 1 in global scope
  local venv2 = child.lua([[
    local venv = require('python.venv')
    return venv.current_venv()
  ]])
  eq(venv2.name, "venv1")
end

-- Test that in tab scope, each tab can have its own venv
T["tab_scope"]["tab_scope_separate_venvs"] = function()
  child.lua([[require('python').setup({ venv_scope = "tab" })]])

  -- Set a venv in tab 1
  child.lua([[
    local venv = require('python.venv')
    venv.set_venv_path({ path = '/test/venv1', name = 'venv1', source = 'venv' })
  ]])

  -- Get the venv in tab 1
  local venv1 = child.lua([[
    local venv = require('python.venv')
    return venv.current_venv()
  ]])
  eq(venv1.name, "venv1")

  -- Create a new tab (tab 2)
  child.cmd("tabnew")

  -- Get the venv in tab 2 - should be nil in tab scope
  local venv2 = child.lua([[
    local venv = require('python.venv')
    return venv.current_venv()
  ]])
  eq(venv2, vim.NIL)

  -- Set a different venv in tab 2
  child.lua([[
    local venv = require('python.venv')
    venv.set_venv_path({ path = '/test/venv2', name = 'venv2', source = 'venv' })
  ]])

  -- Get the venv in tab 2
  local venv2_set = child.lua([[
    local venv = require('python.venv')
    return venv.current_venv()
  ]])
  eq(venv2_set.name, "venv2")

  -- Switch back to tab 1
  child.cmd("tabnext 1")

  -- Get the venv in tab 1 - should still be venv1
  local venv1_after = child.lua([[
    local venv = require('python.venv')
    return venv.current_venv()
  ]])
  eq(venv1_after.name, "venv1")
end

-- Return test set which will be collected and execute inside `MiniTest.run()`
return T

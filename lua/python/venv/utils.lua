--- Utility functions for python.nvim venv module

local VenvUtils = {}

---Get the current working directory respecting the venv scope setting
---@return string
function VenvUtils.get_cwd()
  local config = require("python.config")

  if config.venv_scope == "tab" then
    -- Use tab-local working directory if available, fall back to global cwd
    return vim.fn.getcwd(-1, vim.api.nvim_get_current_tabpage())
  else
    return vim.fn.getcwd()
  end
end

---Store venv based on the configured scope
---@param venv VEnv | nil The venv to store
---@param current_venv VEnv | nil The global venv variable
---@param tab_venvs table The tab-scoped venvs table
---@return VEnv | nil The updated global venv variable (may be modified)
function VenvUtils.store_venv(venv, current_venv, tab_venvs)
  local config = require("python.config")

  if config.venv_scope == "tab" then
    local tabnr = vim.api.nvim_get_current_tabpage()
    tab_venvs[tabnr] = venv
    return current_venv -- Return unchanged global venv
  else
    return venv -- Return venv to be stored globally
  end
end

---Retrieve venv based on the configured scope
---@param current_venv VEnv | nil The global venv variable
---@param tab_venvs table The tab-scoped venvs table
---@return VEnv | nil The venv for the current scope
function VenvUtils.get_venv(current_venv, tab_venvs)
  local config = require("python.config")

  if config.venv_scope == "tab" then
    local tabnr = vim.api.nvim_get_current_tabpage()
    return tab_venvs[tabnr]
  else
    return current_venv
  end
end

return VenvUtils
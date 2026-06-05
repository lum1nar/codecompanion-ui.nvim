local M = {}

---@module 'codecompanion'

---@class CcuiComponentResult
---@field text string
---@field hl? string Highlight group name
---@field fg? string Foreground color (hex string)
---@field bg? string Background color (hex string)

---@alias CcuiComponentReturn CcuiComponentResult|string

---@class CcuiComponentOpts.Mode
---@field display_names? table<string, string> Rename modes for display
---@field icons? table<string, string> Icons per mode id

---@param chat CodeCompanion.Chat
---@param opt string
local function get_option(chat, opt)
  if not chat.acp_connection or not chat.acp_connection._find_config_option then
    return nil
  end

  local opt_value = chat.acp_connection:_find_config_option(opt)
  if not opt_value then
    return nil
  end
  local current_value = opt_value.currentValue or ''
  local options = chat.acp_connection.flatten_config_options(opt_value.options or {})
  -- validate that the option is a valid value
  return vim.iter(options):find(function(o)
    return o.value == current_value
  end)
end

---For ACP adapters, show the agent mode
---@param chat CodeCompanion.Chat
---@param _ CcuiSession
---@param opts CcuiComponentOpts.Mode
---@return CcuiComponentReturn
function M.mode(chat, _, opts)
  local mode_name = ''
  local mode_id = ''
  local mode = get_option(chat, 'mode')
  if mode then
    mode_name = mode.name
    mode_id = mode.value
  end

  local display_names = opts.display_names or {}
  if display_names[mode_name] then
    mode_name = display_names[mode_name]
  end

  if mode_name == '' then
    mode_name = 'Default'
    mode_id = 'default'
  end

  local icons = opts.icons or {}
  local icon = icons[mode_id] or ''

  return { text = icon .. ' ' .. mode_name, hl = 'CcuiMode' }
end

---Show the adapter formatted name
---@param chat CodeCompanion.Chat
---@return CcuiComponentReturn
function M.adapter(chat)
  if chat.adapter then
    local name = chat.adapter.formatted_name or chat.adapter.name or ''
    if name ~= '' then
      return { text = name, hl = 'CcuiAdapter' }
    end
  end
  return ''
end

---Show the model formatted name
---@param chat CodeCompanion.Chat
---@return CcuiComponentReturn
function M.model(chat, _)
  local name = ''

  -- ACP adapter
  local model = get_option(chat, 'model')
  if model then
    name = model.name
  end

  -- HTTP adapter
  if name == '' and chat.adapter and chat.adapter.model then
    local raw = chat.adapter.model.name
    local choices = chat.adapter.schema and chat.adapter.schema.model and chat.adapter.schema.model.choices
    if choices and choices[raw] and choices[raw].formatted_name then
      name = choices[raw].formatted_name
    else
      name = raw or ''
    end
  end

  if name ~= '' then
    return { text = '󰧑 ' .. name, hl = 'CcuiModel' }
  end
  return ''
end

---@class CcuiComponentOpts.Spinner
---@field frames? string[] Spinner animation frames
---@field text? string Text shown next to the spinner
---@field interval_ms? number Timer interval in ms (used by events.lua)

---Show a loading spinner for the current session
---@param _ CodeCompanion.Chat
---@param session CcuiSession
---@param opts CcuiComponentOpts.Spinner
---@return CcuiComponentReturn
function M.spinner(_, session, opts)
  if not session.is_processing then
    return ''
  end

  local frames = opts.frames or { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' }
  local text = opts.text or 'Processing...'
  local frame = frames[(session.spinner_idx % #frames) + 1]

  return { text = frame .. ' ' .. text, hl = 'CcuiSpinner' }
end

---Show informational messages from the plugin
---@param _ CodeCompanion.Chat
---@param session CcuiSession
---@return CcuiComponentReturn
function M.messages(_, session)
  if not session.message then
    return ''
  end
  return { text = session.message.text, hl = session.message.hl or 'WarningMsg' }
end

---@class CcuiComponentOpts.ChatTitle
---@field icon? string Icon shown before the chat name; default: '󰭹'
---@field default? string The default text to show when no title; default: `[No Title]`

---Show the chat title
---@param chat CodeCompanion.Chat
---@param _ CcuiSession
---@param opts CcuiComponentOpts.ChatTitle
---@return CcuiComponentReturn
function M.chat_title(chat, _, opts)
  if not chat then
    return { text = '', hl = 'CcuiTitle' }
  end

  opts = opts or {}
  local icon = opts.icon or '󰭹'
  local title = chat.title or '[No Title]'
  -- %< truncate from end
  return { text = string.format('%s %s%%<', icon, title), hl = 'CcuiTitle' }
end

return M

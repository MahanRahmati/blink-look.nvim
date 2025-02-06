local default_config = require("blink-look.config")
local uv = vim.uv

---@type blink.cmp.Source
local M = {}

local function words_to_items(words)
	local items = {}
	for _, word in ipairs(words) do
		table.insert(items, {
			label = word,
			kind = vim.lsp.protocol.CompletionItemKind.Text,
			insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText,
			insertText = word,
		})
	end
	return items
end

---@param opts Config
function M.new(opts)
	local self = setmetatable({}, { __index = M })
	self.opts = vim.tbl_deep_extend("force", default_config.options, opts or {})
	return self
end

function M:get_completions(params, callback)
	local command = {
		self.opts.rg_path,
		unpack(self.opts.rg_args),
		"^" .. params.context.cursor_before_line,
		self.opts.dict_path,
	}

	local stdout = {}

	local handle
	handle = uv.spawn(command[1], {
		args = vim.list_slice(command, 2),
		stdio = { nil, uv.new_pipe(false), uv.new_pipe(false) },
		hide = true,
	}, function(code)
		handle:close()
		if code == 0 then
			local items = words_to_items(stdout)
			callback({ items = items, isIncomplete = false })
		else
			callback({ items = {}, isIncomplete = false })
		end
	end)

	uv.read_start(handle.stdout, function(err, data)
		if err then
			return
		end
		if data then
			table.insert(stdout, data)
		end
	end)

	return function()
		if handle and not handle:is_closing() then
			handle:kill(15)
			handle:close()
		end
	end
end

return M

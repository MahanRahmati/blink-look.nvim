local default_config = require("blink-look.config")

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
	local prefix = params.line:sub(1, params.cursor[2]):match("[%w_-]+$") or ""

	if string.len(prefix) < self.opts.min_word_length then
		callback()
		return
	end

	local cmd = { "look" }
	if self.opts.ignore_case then
		table.insert(cmd, "-f")
	end
	table.insert(cmd, prefix)
	table.insert(cmd, self.opts.dict_path)

	vim.system(cmd, nil, function(result)
		if result.code ~= 0 then
			callback()
			return
		end

		local words = vim.split(result.stdout, "\n")
		words = vim.tbl_filter(function(word)
			return word ~= ""
		end, words)

		if #words > self.opts.max_results then
			words = vim.list_slice(words, 1, self.opts.max_results)
		end

		callback({
			is_incomplete_forward = false,
			is_incomplete_backward = false,
			items = words_to_items(words),
		})
	end)
end

return M

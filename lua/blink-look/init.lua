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

local function run_sync(prefix, dict_path, ignore_case, max_results, callback)
	local cmd = { "look" }
	if ignore_case then
		table.insert(cmd, "-f")
	end
	table.insert(cmd, prefix)
	table.insert(cmd, dict_path)

	local result = vim.fn.system(cmd)
	local words = vim.split(result, "\n")
	words = vim.tbl_filter(function(word)
		return word ~= ""
	end, words)

	if #words > max_results then
		words = vim.list_slice(words, 1, max_results)
	end

	callback(words_to_items(words))
end

local function run_async(prefix, dict_path, ignore_case, max_results, callback)
	local worker = uv.new_work(function(p, d, i, m)
		local cmd = { "look" }
		if i then
			table.insert(cmd, "-f")
		end
		table.insert(cmd, p)
		table.insert(cmd, d)

		local handle = io.popen(table.concat(cmd, " "))
		local result = handle:read("*a")
		handle:close()

		local words = {}
		for word in result:gmatch("[^\n]+") do
			table.insert(words, word)
			if #words >= m then
				break
			end
		end
		return table.concat(words, "\n")
	end, function(words)
		local items = words_to_items(vim.split(words, "\n"))
		vim.schedule(function()
			callback(items)
		end)
	end)
	worker:queue(prefix, dict_path, ignore_case, max_results)
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
		callback({ is_incomplete_forward = false, is_incomplete_backward = false, items = {} })
		return
	end

	local transformed_callback = function(items)
		callback({ is_incomplete_forward = false, is_incomplete_backward = false, items = items })
	end

	vim.schedule(function()
		-- Run async for short prefixes (more results), sync for longer ones (fewer results)
		if #prefix <= 4 then
			run_async(prefix, self.opts.dict_path, self.opts.ignore_case, self.opts.max_results, transformed_callback)
		else
			run_sync(prefix, self.opts.dict_path, self.opts.ignore_case, self.opts.max_results, transformed_callback)
		end
	end)

	return function() end
end

return M

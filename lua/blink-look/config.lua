local M = {}

---@class Config
---@field min_word_length integer Minimum word length to trigger completion
---@field max_results integer Maximum number of results to show
---@field dict_path string Path to dictionary file
---@field ignore_case boolean Whether to ignore case when matching
M.options = {
	min_word_length = 3,
	max_results = 100,
	dict_path = "/usr/share/dict/words",
	ignore_case = true,
}

---Merge the user options with the default options
---@param user_opts Config
function M.init(user_opts)
	M.options = vim.tbl_deep_extend("force", M.options, user_opts)
end

return M

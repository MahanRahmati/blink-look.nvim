local M = {}

---@class Config
---@field min_word_length integer Minimum word length to trigger completion
---@field max_results integer Maximum number of results to show
---@field dict_path string Path to dictionary file
---@field rg_path string Path to ripgrep executable
---@field rg_args table Arguments for ripgrep
M.options = {
	min_word_length = 3,
	max_results = 100,
	dict_path = "/usr/share/dict/words",
	rg_path = "rg",
	rg_args = {
		"-i", -- case insensitive
		"--no-line-number", -- remove line numbers
		"--no-filename", -- remove filename
		"^[0-9]+:(.*)", -- match pattern for numbered entries
		"-r", -- replacement flag
		"$1", -- capture group replacement
	},
}

---Merge the user options with the default options
---@param user_opts Config
function M.init(user_opts)
	M.options = vim.tbl_deep_extend("force", M.options, user_opts)
end

return M

return {
	"nvimdev/template.nvim",
	cmd = { "Template", "TemplateProject" },
	config = function()
		require("template").setup({
			temp_dir = vim.fn.stdpath("config") .. "/template",
			author = "nazozokc",
		})
	end,
}

return {
	"hrsh7th/cmp-cmdline",
	event = "CmdlineEnter",
	dependencies = { "hrsh7th/nvim-cmp" },
	config = function()
		local ok, cmp = pcall(require, "cmp")
		if not ok then
			return
		end

		cmp.setup.cmdline("/", {
			mapping = cmp.mapping.preset.cmdline(),
			sources = cmp.config.sources({
				{ name = "buffer" },
			}),
			completion = { completeopt = "menu,menuone,noselect" },
		})

		cmp.setup.cmdline(":", {
			mapping = cmp.mapping.preset.cmdline(),
			sources = cmp.config.sources({ { name = "path" } }, { { name = "cmdline" } }),
			completion = { completeopt = "menu,menuone,noselect" },
		})
	end,
}

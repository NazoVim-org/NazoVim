return {
	"nvim-java/nvim-java",
	dependencies = {
		"neovim/nvim-lspconfig",
		"mfussenegger/nvim-dap",
		"MunifTanjim/nui.nvim",
	},
	ft = { "java" },
	config = function()
		require("java").setup({
			jdtls = { version = "latest" },
			lombok = { enable = true },
			java_test = { enable = true },
			java_debug_adapter = { enable = true },
			spring_boot_tools = { enable = false },
			jdk = { auto_install = true, version = "17" },
		})
	end,
}

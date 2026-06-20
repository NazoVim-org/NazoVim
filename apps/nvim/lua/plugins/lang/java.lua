return {
	"nvim-java/nvim-java",
	dependencies = {
		"neovim/nvim-lspconfig",
		"mfussenegger/nvim-dap",
		"MunifTanjim/nui.nvim",
		{ "JavaHello/spring-boot.nvim", commit = "218c0c26c14d99feca778e4d13f5ec3e8b1b60f0" },
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

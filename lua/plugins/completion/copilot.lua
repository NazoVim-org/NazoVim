	return {
	"zbirenbaum/copilot.lua",
	cmd = { "Copilot", "CopilotChat" },
	config = function()
		require("copilot").setup({
			suggestion = {
				enabled = false,
			},
			panel = { enabled = false },
		})
	end,
}

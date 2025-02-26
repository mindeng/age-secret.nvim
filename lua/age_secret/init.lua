local M = {}

-- Default configuration
local config = {
	recipient = "age1fht3gvntpeffl65jjhdlremkl8nqe2p0ml3e2zwf0n6jd7g7lsese4hscr",
	recipient_file = "~/.config/age/pub-keys.txt",
	identity = "~/age-key.txt",
}

function M.setup(user_config)
	if user_config ~= nil then
		config.recipient = user_config.recipient or config.recipient
		config.recipient_file = user_config.recipient_file or config.recipient_file
		config.identity = user_config.identity or config.identity
	end
	-- Ensure Neovim recognizes the .age file extension
	vim.cmd([[
      augroup AgeFileType
        autocmd!
        autocmd BufRead,BufNewFile *.age set filetype=age
      augroup END
    ]])

	-- Additional configuration specific to .age files
	vim.api.nvim_create_autocmd("FileType", {
		pattern = "age",
		callback = function()
			-- Add more settings as needed
			vim.o.backup = false
			vim.o.writebackup = false
			-- Set shada to empty to prevent storing any session information
			vim.opt.shada = ""
		end,
	})

	-- Create an autocmd for .age files
	vim.api.nvim_create_autocmd({ "BufReadPre", "FileReadPre" }, {
		pattern = "*.age",
		callback = function()
			-- Set local buffer options for .age files
			vim.bo.swapfile = false -- Equivalent to 'setlocal noswapfile'
			vim.bo.binary = true -- Equivalent to 'setlocal bin'
			-- Optionally, set 'undofile' to false if you don't want undo history for these files
			vim.bo.undofile = false
		end,
	})

	vim.api.nvim_create_autocmd({ "BufReadPost", "FileReadPost" }, {
		pattern = "*.age",
		callback = function()
			-- Execute age decryption
			vim.cmd(string.format("silent '[,']!rage --decrypt -i %s", config.identity))

			-- Set local buffer options for .age files
			vim.bo.binary = false -- Equivalent to 'setlocal nobin'

			-- Execute BufReadPost autocmd for the decrypted file
			local filename = vim.fn.expand("%:r") -- Gets the file name without the .age extension
			vim.cmd(string.format("doautocmd BufReadPost %s", filename))
		end,
	})

	local last_pos = nil

	vim.api.nvim_create_autocmd({ "BufWritePre", "FileWritePre" }, {
		pattern = "*.age",
		callback = function()
			last_pos = vim.api.nvim_win_get_cursor(0)

			-- Set local buffer options for .age files
			vim.bo.binary = true -- Equivalent to 'setlocal bin'

			-- Execute age encryption
			vim.cmd(
				string.format("silent '[,']!rage --encrypt -r %s -R %s -a", config.recipient, config.recipient_file)
			)
			vim.cmd("")
		end,
	})

	vim.api.nvim_create_autocmd({ "BufWritePost", "FileWritePost" }, {
		pattern = "*.age",
		callback = function()
			-- Undo the last change (which is the encryption)
			vim.cmd("silent undo")

			-- Set local buffer options for .age files
			vim.bo.binary = false -- Equivalent to 'setlocal nobin'

			-- jump back to the last position
			if last_pos then
				vim.api.nvim_win_set_cursor(0, last_pos)
			end
		end,
	})

	vim.api.nvim_create_user_command("SetAgeRecipient", function(args)
		M.set_recipient(args.args)
	end, { nargs = 1 })
	vim.api.nvim_create_user_command("SetAgeIdentity", function(args)
		M.set_indentity(args.args)
	end, { nargs = 1 })
	vim.api.nvim_create_user_command("SetAgeRecipientFile", function(args)
		M.set_recipient_file(args.args)
	end, { nargs = 1 })
end

-- Function to change the recipient
function M.set_recipient(new_recipient)
	config.recipient = new_recipient
end

-- Function to change the identity
function M.set_indentity(new_identity)
	config.identity = new_identity
end

-- Function to change the recipient_file
function M.set_recipient_file(recipient_file)
	config.recipient_file = recipient_file
end

return M

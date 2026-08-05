local dap = require("dap")

-- Debugpy (Python)
dap.adapters.python = {
	type = "executable",
	command = "python3",
	args = { "-m", "debugpy.adapter" },
}

dap.configurations.python = {
	{
		type = "python",
		request = "launch",
		name = "Launch file",
		program = "${file}",
		pythonPath = function()
			-- Check for virtual environment first
			local venv_path = vim.fn.getenv("VIRTUAL_ENV")
			if venv_path ~= vim.NIL and venv_path ~= "" then
				return venv_path .. "/bin/python"
			end
			-- Check for local .venv
			local cwd = vim.fn.getcwd()
			if vim.fn.executable(cwd .. "/.venv/bin/python") == 1 then
				return cwd .. "/.venv/bin/python"
			end
			-- Fallback to system python
			return "/opt/homebrew/bin/python3"
		end,
	},
}

-- Neovim Lua
dap.adapters.nlua = function(callback, config)
	callback({ type = "server", host = config.host, port = config.port })
end

dap.configurations.lua = {
	{
		type = "nlua",
		request = "attach",
		name = "Attach to running Neovim instance",
		host = function()
			local value = vim.fn.input("Host [127.0.0.1]: ")
			if value ~= "" then
				return value
			end
			return "127.0.0.1"
		end,
		port = function()
			local val = tonumber(vim.fn.input("Port: "))
			assert(val, "Please provide a port number")
			return val
		end,
	},
}

-- LLDB (C/C++/Rust)
-- Note: On macOS, install llvm via Homebrew: brew install llvm
-- On Linux, install lldb: apt install lldb or similar
dap.adapters.lldb = {
	type = "executable",
	command = "/opt/homebrew/opt/llvm/bin/lldb-dap",
	name = "lldb",
}

dap.configurations.cpp = {
	{
		name = "Launch",
		type = "lldb",
		request = "launch",
		program = function()
			return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
		end,
		cwd = "${workspaceFolder}",
		stopOnEntry = false,
		args = {},
		runInTerminal = false,
	},
}

dap.configurations.c = dap.configurations.cpp
dap.configurations.rust = dap.configurations.cpp

return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "jay-babu/mason-nvim-dap.nvim",
      "theHamsta/nvim-dap-virtual-text",
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      -- UI setup
      dapui.setup({
        layouts = {
          { elements = { "scopes", "breakpoints", "stacks", "watches" }, size = 0.33, position = "left" },
          { elements = { "repl", "console" }, size = 0.27, position = "bottom" },
        },
      })

      -- Virtual text setup (inline variable values)
      require("nvim-dap-virtual-text").setup({
        commented = true,
        highlight_changed_variables = true,
        highlight_new_as_changed = true,
        virt_text_pos = "eol",
      })

      -- Signs with high priority to show over gitsigns
      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError", priority = 50 })
      vim.fn.sign_define("DapBreakpointCondition", { text = "◐", texthl = "DiagnosticWarn", priority = 50 })
      vim.fn.sign_define("DapBreakpointRejected", { text = "○", texthl = "DiagnosticHint", priority = 50 })
      vim.fn.sign_define("DapLogPoint", { text = "◆", texthl = "DiagnosticInfo", priority = 50 })
      vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticInfo", linehl = "Visual", priority = 60 })

      -- Auto open/close UI
      dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
      dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end

      -- Keymaps
      local map = function(lhs, rhs, desc)
        vim.keymap.set("n", lhs, rhs, { desc = "DAP: " .. desc })
      end

      -- Function keys (IDE-style)
      map("<F5>", function()
        if not dap.session() then
          dap.continue()
        else
          dap.continue()
        end
      end, " Continue/Start")
      map("<F9>", dap.toggle_breakpoint, " Toggle Breakpoint")
      map("<F10>", dap.step_over, " Step Over")
      map("<F11>", dap.step_into, " Step Into")
      map("<S-F11>", dap.step_out, " Step Out")

      -- Leader mappings
      map("<leader>db", dap.toggle_breakpoint, " Toggle Breakpoint")
      map("<leader>dB", function() dap.set_breakpoint(vim.fn.input("Condition: ")) end, "◈ Conditional Breakpoint")
      map("<leader>dl", function() dap.set_breakpoint(nil, nil, vim.fn.input("Log: ")) end, " Log Point")
      map("<leader>dr", dap.repl.open, " REPL")
      map("<leader>du", dapui.toggle, " Toggle UI")
      map("<leader>de", function() dap.evaluate() end, " Evaluate")
      map("<leader>dh", function() require("dap.ui.widgets").hover() end, " Hover Inspect")
      map("<leader>dC", dap.run_to_cursor, " Run to Cursor")
      map("<leader>dS", dap.terminate, " Stop")
      map("<leader>dR", dap.restart, " Restart")
      map("<leader>dU", dap.step_out, " Step Out") -- Fallback for Shift+F11

      -- Visual mode evaluate selection
      vim.keymap.set("v", "<leader>de", function() require("dap.ui.widgets").hover() end, { desc = "DAP:  Eval selection" })

      -- Python adapter setup
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
            return vim.env.VIRTUAL_ENV and (vim.env.VIRTUAL_ENV .. "/bin/python") or "python3"
          end,
        },
      }

      -- C# adapter setup (netcoredbg)
      local netcoredbg_path = vim.fn.stdpath("data") .. "/mason/packages/netcoredbg/netcoredbg"
      if vim.fn.executable(netcoredbg_path) == 1 then
        dap.adapters.coreclr = {
          type = "executable",
          command = netcoredbg_path,
          args = { "--interpreter=vscode" },
        }
      else
        dap.adapters.coreclr = {
          type = "executable",
          command = "netcoredbg", -- fallback to PATH
          args = { "--interpreter=vscode" },
        }
      end

      -- C# configuration with auto-build
      dap.configurations.cs = {
        {
          type = "coreclr",
          request = "launch",
          name = "Build and Launch",
          program = function()
            -- Always run build - dotnet handles incremental builds efficiently
            local result = vim.fn.system("dotnet build --verbosity quiet 2>&1")
            local exit_code = vim.v.shell_error
            
            if exit_code ~= 0 then
              error("Build failed:\n" .. result)
            end
            
            -- Find the DLL after ensuring it's up to date
            local csproj = vim.fn.glob("*.csproj")
            if csproj ~= "" then
              local name = vim.fn.fnamemodify(csproj, ":t:r") 
              local dll = vim.fn.glob(vim.fn.getcwd() .. "/bin/Debug/net*/" .. name .. ".dll")
              if dll ~= "" then 
                return dll 
              end
            end
            
            return vim.fn.input("DLL path: ", vim.fn.getcwd() .. "/bin/Debug/", "file")
          end,
        },
      }

      -- Go adapter setup
      dap.adapters.delve = {
        type = "server",
        port = "${port}",
        executable = {
          command = "dlv",
          args = { "dap", "-l", "127.0.0.1:${port}" },
        }
      }
      dap.configurations.go = {
        {
          type = "delve",
          request = "launch",
          name = "Debug file",
          program = "${file}",
        },
        {
          type = "delve", 
          request = "launch",
          name = "Debug package",
          program = "${fileDirname}",
        },
        {
          type = "delve",
          request = "launch",
          name = "Debug test",
          mode = "test",
          program = "${fileDirname}",
        },
      }
    end,
  },
  {
    "jay-babu/mason-nvim-dap.nvim",
    dependencies = { "williamboman/mason.nvim", "mfussenegger/nvim-dap" },
    config = function()
      require("mason-nvim-dap").setup({
        automatic_setup = true,
        ensure_installed = { "debugpy", "netcoredbg", "delve" },
        handlers = {
          -- Disable auto-setup for netcoredbg (we handle it manually)
        },
      })
      
      -- Ensure packages are installed on fresh setups
      vim.defer_fn(function()
        local registry = require("mason-registry")
        local packages = { "debugpy", "netcoredbg", "delve" }
        
        for _, package_name in ipairs(packages) do
          if not registry.is_installed(package_name) then
            vim.cmd("MasonInstall " .. package_name)
          end
        end
      end, 2000)
    end,
  },
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
  },
  {
    "theHamsta/nvim-dap-virtual-text",
    dependencies = { "mfussenegger/nvim-dap" },
  },
}
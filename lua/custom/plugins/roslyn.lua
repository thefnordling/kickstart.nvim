-- Roslyn LSP for C# (replaces OmniSharp)
-- Uses the same language server as VS Code's C# extension
return {
  'seblyng/roslyn.nvim',
  ft = { 'cs', 'razor', 'cshtml' },
  opts = {
    -- Don't search child directories for solutions
    broad_search = false,
    -- Lock to first solution found (single .sln repos)
    lock_target = true,
  },
  config = function(_, opts)
    require('roslyn').setup(opts)

    -- Configure Roslyn LSP settings via vim.lsp.config
    vim.lsp.config('roslyn', {
      settings = {
        ['csharp|inlay_hints'] = {
          csharp_enable_inlay_hints_for_implicit_variable_types = true,
          csharp_enable_inlay_hints_for_lambda_parameter_types = true,
          dotnet_enable_inlay_hints_for_parameters = true,
        },
        ['csharp|code_lens'] = {
          dotnet_enable_references_code_lens = true,
        },
      },
    })
  end,
}

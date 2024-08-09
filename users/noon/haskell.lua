local ht = require('haskell-tools')

local on_attach = function(client, bufnr)
  -- Show line diagnostics automatically in hover window
  vim.api.nvim_create_autocmd("CursorHold", {
    buffer = bufnr,
    callback = function()
      local opts = {
        focusable = false,
        close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
        border = 'rounded',
        source = 'always',
        prefix = ' ',
        scope = 'cursor',
      }
      vim.diagnostic.open_float(nil, opts)
    end
  })
end

ht.hls = { -- LSP client options
  on_attach = on_attach,
  -- settings = {
  --   haskell = {            -- haskell-language-server options
  --     formattingProvider = 'stylish-haskell',
  --     checkProject = true, -- Could have a performance impact on large mono repos.
  --   }
  -- }
}

ht.tools = {
  hover = {
    stylize_markdown = true
  },
}


-- local bufnr = vim.api.nvim_get_current_buf()
-- local opts = { noremap = true, silent = true, buffer = bufnr, }
-- -- haskell-language-server relies heavily on codeLenses,
-- -- so auto-refresh (see advanced configuration) is enabled by default
-- vim.keymap.set('n', '<leader>cl', vim.lsp.codelens.run, opts)
-- -- Hoogle search for the type signature of the definition under the cursor
-- vim.keymap.set('n', '<leader>hs', ht.hoogle.hoogle_signature, opts)
-- -- Evaluate all code snippets
-- vim.keymap.set('n', '<leader>ea', ht.lsp.buf_eval_all, opts)
-- -- Toggle a GHCi repl for the current package
-- vim.keymap.set('n', '<leader>rr', ht.repl.toggle, opts)
-- -- Toggle a GHCi repl for the current buffer
-- vim.keymap.set('n', '<leader>rf', function()
--   ht.repl.toggle(vim.api.nvim_buf_get_name(0))
-- end, opts)
-- vim.keymap.set('n', '<leader>rq', ht.repl.quit, opts)

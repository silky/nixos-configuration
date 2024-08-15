vim.g.haskell_tools = {
  hls = { -- LSP client options
    on_attach = function(client, bufnr, ht)
      -- local bufopts = { noremap = true, buffer = bufnr }
      require("which-key").add({
        { "gd", vim.lsp.buf.definition, desc = "Goto definition" },
        { "gr", vim.lsp.buf.references, desc = "Show all references" },
        { "K",  vim.lsp.buf.hover, desc = "Hover info" },
        -- Replace symbol
        -- { "cl", vim.lsp.codelens.run, desc = "code lens" },
        -- { "gD", vim.lsp.buf.declaration, desc = "goto declaration" },
        -- { "gi", vim.lsp.buf.implementation, desc = "goto implementation" },
      })
    end,
  }
}

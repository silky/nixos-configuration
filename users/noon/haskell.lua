vim.g.haskell_tools = {
  hls = { -- LSP client options
    on_attach = function(client, bufnr, ht)
      -- local bufopts = { noremap = true, buffer = bufnr }
      require("which-key").add({
        { "gd", vim.lsp.buf.definition, desc = "goto definition" },
        { "gr", vim.lsp.buf.references, desc = "references" },
        { "K",  vim.lsp.buf.hover, desc = "hover" },
        { "<localleader>hs", ht.hoogle.hoogle_signature, desc = "hoogle signature" },
        -- { "cl", vim.lsp.codelens.run, desc = "code lens" },
        -- { "gD", vim.lsp.buf.declaration, desc = "goto declaration" },
        -- { "gi", vim.lsp.buf.implementation, desc = "goto implementation" },
      })
    end,
  }
}


--     -- Show line diagnostics automatically in hover window
--       -- floatDiag = function()
--       --   local opts = {
--       --     focusable = false,
--       --     close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
--       --     border = "rounded",
--       --     source = "always",
--       --     prefix = " ",
--       --     scope = "cursor",
--       --   }
--       --   vim.diagnostic.open_float(nil, opts)
--       -- end

--   end
-- }

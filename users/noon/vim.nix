{ pkgs
, unstablePkgs
, ...
}:
let
  vim-agda-input = pkgs.vimUtils.buildVimPlugin {
    name = "vim-agda-input";
    src = pkgs.fetchFromGitHub {
      owner = "silky";
      repo = "vim-agda-input";
      rev = "112fc11a08aff4b1596903fdf723d7d5b3b6f81a";
      sha256 = "sha256-Fm+PduWz0nfLeDbEO4CA1GRX6lHWzwoZKWy4iN8PxDg=";
    };
    # Local hacking
    # src = builtins.fetchGit {
    #   url = "file:///home/noon/dev/vim-agda-input";
    # };
  };
  daily-notes-nvim = pkgs.vimUtils.buildVimPlugin {
    name = "dailynotes.nvim";
    src = pkgs.fetchFromGitHub {
      owner = "kperath";
      repo = "dailynotes.nvim";
      rev = "7d3074c32f20c61329315737350cb8f797fabc85";
      sha256 = "sha256-YrqzsBicHTJ0uPcWbEB92DdUqV9wk3XRQVbzd3jPaEQ=";
    };
  };
  cabal-project-vim = pkgs.vimUtils.buildVimPlugin {
    name = "cabal-project-vim";
    src = pkgs.fetchFromGitHub {
      owner = "vmchale";
      repo = "cabal-project-vim";
      rev = "0d41e7e41b1948de84847d9731023407bf2aea04";
      sha256 = "sha256-j1igpjk1+j/1/y99ZaI3W5+VYNmQqsFp2qX4qzkpNpc=";
    };
  };
  noon-light-theme = pkgs.vimUtils.buildVimPlugin {
    name = "noon-light-theme";
    src = pkgs.fetchFromGitHub {
      owner = "silky";
      repo = "noon-light-vim";
      rev = "8628d599257b20dc46b94658ce54e8d3fef554e4";
      sha256 = "sha256-kAdxiIGm3vBaI1WhmgalpA8sy94tofZsTLOCEE7v+Lk=";
    };
  };
  vim-syntax-shakespeare = pkgs.vimUtils.buildVimPlugin {
    name = "vim-syntax-shakespeare";
    src = pkgs.fetchFromGitHub {
      owner = "pbrisbin";
      repo = "vim-syntax-shakespeare";
      rev = "2f4f61eae55b8f1319ce3a086baf9b5ab57743f3";
      sha256 = "sha256-sdCXJOvB+vJE0ir+qsT/u1cHNxrksMnqeQi4D/Vg6UA=";
    };
  };
  vim-quickscope = pkgs.vimUtils.buildVimPlugin {
    name = "quick-scope";
    src = pkgs.fetchFromGitHub {
      owner = "unblevable";
      repo = "quick-scope";
      rev = "256d81e391a22eeb53791ff62ce65f870418fa71";
      sha256 = "sha256-TcA4jZIdnQd06V+JrXGiCMr0Yhm9gB6OMiTSdzMt/Qw=";
    };
  };
  vim-cooklang = pkgs.vimUtils.buildVimPlugin {
    name = "vim-cooklang";
    src = pkgs.fetchFromGitHub {
      owner = "silky";
      repo = "vim-cooklang";
      rev = "7f8c2190b5675ad4465e9719cd4b773c1db2ce6e";
      sha256 = "sha256-vWlk7G1V4DLC0G0f3GLEG3JsvAwJ637CPocmMmFxQek=";
    };
  };
  vim-autoread = pkgs.vimUtils.buildVimPlugin {
    name = "vim-autoread";
    src = pkgs.fetchFromGitHub {
      owner = "djoshea";
      repo = "vim-autoread";
      rev = "7e83d47a71fdafc271005fc39c89863204278c77";
      sha256 = "sha256-IGgJ/D2AGDtbO+RZk2zd+zO9ZtANsle4QSjsh+VOXpg=";
    };
  };
  nvim-hs-vim = pkgs.vimUtils.buildVimPlugin {
    name = "nvim-hs.vim";
    src = pkgs.fetchFromGitHub {
      owner = "neovimhaskell";
      repo = "nvim-hs.vim";
      rev = "d4a6b7278ae6a1fdc64e300c3ebc1e24719af342";
      sha256 = "sha256-umsuGGP5tOf92bzWEhqD2y6dN0FDBsmLx60f45xgmig=";
    };
  };

  cornelisPlugin = {
    plugin = pkgs.vimPlugins.cornelis;
    config = "let g:cornelis_use_global_binary = 1";
  };
in
{
  extraConfig = builtins.readFile ./init.vim;
  extraLuaConfig = ''
  '';
  enable = true;
  plugins = with pkgs.vimPlugins; [
    # lazy-nvim

    {
      plugin = haskell-tools-nvim;
      # Note: Config is done on filetypes
      type = "lua";
      config = builtins.readFile ./haskell.lua;
    }

    cabal-project-vim
    cornelisPlugin
    dhall-vim
    # diffview-nvim
    editorconfig-vim
    elm-vim
    fzf-vim
    fzfWrapper
    gitsigns-nvim
    haskell-vim

    {
      plugin = daily-notes-nvim;
      type = "lua";
      config = ''
require "dailynotes".setup({
    path = '~/dev/w/notes/'
})
        '';
    }

    # Kinda useful for interative colour scheming, but in the end more trouble
    # than it's worth.
    # lush-nvim

    {
      # https://github.com/NeogitOrg/neogit
      plugin = neogit;
      type = "lua";
      config = ''
local neogit = require('neogit')
neogit.setup {
  graph_style = "unicode",
  integrations = { diffview = true },
}
      '';
    }

    mini-nvim
    noon-light-theme
    nvim-hs-vim
    nvim-treesitter.withAllGrammars
    nvim-unception
    purescript-vim
    supertab
    typescript-vim
    unicode-vim
    vim-agda-input
    vim-autoread
    vim-commentary
    vim-easy-align

    {
      plugin = vim-go;
      config = ''
        let g:go_fmt_autosave = 0
        '';
    }

    # nvim-web-devicons

    {
      plugin = which-key-nvim;
      type = "lua";
      config = ''
        require("which-key").setup {
          win = {
            border = "single",
          },
        }
      '';
    }

    # TODO: Configure
    # {
    #   plugin = telescope_hoogle;
    #   config = ''
    #     lua <<EOF
    #     local telescope = require("telescope")
    #     telescope.setup {
    #     }
    #     telescope.load_extension("hoogle")
    #     EOF
    #   '';
    # }

    vim-easymotion
    vim-ledger
    vim-nix
    vim-ormolu
    vim-quickscope
    vim-syntax-shakespeare
    vim-textobj-user
    vim-toml
    xterm-color-table

    # To investigate
    # vim-unimpaired # https://github.com/tpope/vim-unimpaired/
    # telescope-nvim # https://github.com/nvim-telescope/telescope.nvim/
    telescope-fzf-native-nvim # https://github.com/nvim-telescope/telescope-fzy-native.nvim

    {
      plugin = telescope-nvim;
      type = "lua";
      config = ''
        tel = require('telescope')
        tel.setup {
          extensions = {
            fzf = {
              fuzzy = true,
              override_generic_sorter = true,
              override_file_sorter = true,
              case_mode = "smart_case",
            }
          },
          defaults = {
            layout_config = {
              -- We don't want the preview window.
              -- TODO: Maybe we do want it sometimes.
              preview_width = 0,
            },
          },
          preview = false,
          pickers = {
            find_files = {
            },
          },
        }

        tel.load_extension('fzf')
      '';
    }

    # nvim-cmp
    # cmp-nvim-lsp
    # cmp-nvim-lsp-signature-help
    # cmp-buffer
    # cmp-path
  ];
  extraPackages = [
    pkgs.cornelis
    pkgs.gopls
  ];
}

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
      rev = "7b8f3679102bd29807398eb15c3f33a8aaaf3e5a";
      sha256 = "sha256-lty3/EoDhWViV8LzWULNVklrWV3CYrrQ0iMwEPMD9r8=";
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
  enable = true;
  package = unstablePkgs.neovim-unwrapped;
  plugins = with unstablePkgs.vimPlugins; [
    {
      plugin = unstablePkgs.vimPlugins.haskell-tools-nvim;
      # Note: Config is done on filetypes
    }

    cabal-project-vim
    cornelisPlugin
    dhall-vim
    diffview-nvim
    editorconfig-vim
    elm-vim
    fzf-vim
    fzfWrapper
    gitsigns-nvim
    haskell-vim

    {
      # https://github.com/NeogitOrg/neogit
      plugin = neogit;
      config = ''
lua <<EOF
local neogit = require('neogit')
neogit.setup {
  graph_style = "unicode",
  integrations = { diffview = true },
}
EOF
      '';
    }

    noon-light-theme
    nvim-hs-vim
    nvim-treesitter.withAllGrammars
    purescript-vim
    supertab
    typescript-vim
    unicode-vim
    nvim-unception
    vim-agda-input
    vim-autoread
    vim-commentary
    vim-cooklang
    vim-easy-align
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
    # nvim-treesitter-context # No.
    telescope-nvim # https://github.com/nvim-telescope/telescope.nvim/
    telescope-fzy-native-nvim # https://github.com/nvim-telescope/telescope-fzy-native.nvim
    nvim-cmp
    cmp-nvim-lsp
    cmp-nvim-lsp-signature-help
    cmp-buffer
    cmp-path
  ];
  extraPackages = [ pkgs.cornelis ];
}

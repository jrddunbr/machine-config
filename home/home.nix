{ pkgs, ... }:

let ix = with pkgs; stdenv.mkDerivation {
  name = "ix";
  src = fetchurl {
    url = "ix.io/client";
    sha256 = "0xc2s4s1aq143zz8lgkq5k25dpf049dw253qxiav5k7d7qvzzy57";
  };
  unpackPhase = "true";
  installPhase = ''
    install -D $src $out/bin/ix
  '';
};
in

{
  imports = [
  ];

  home.packages = with pkgs; [
    htop fortune ix mosh
    (callPackage ../tools/up {})
  ];

  home.sessionVariables = {
    EDITOR = "vim";
    # Workaround for #599
    LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
    PATH = "$PATH:$HOME/.cargo/bin";
    LIBVIRT_DEFAULT_URI = "qemu:///system";
  };

  programs.git = {
    enable = true;
    userName = "Svein Ove Aas";
    userEmail = "sveina@gmail.com";
  };

  home.file.".screenrc".text = ''
    defscrollback 5000
    defutf8 on
    vbell off
    maptimeout 5
  '';

  programs.mpv = {
    enable = true;
    config = {
      ontop = true;
      alang = "ja";
      slang = "en";
    };
  };

  programs.neovim = {
    enable = true;
    vimAlias = true;
    extraPython3Packages = (ps: with ps; [
      python-language-server
    ]);
    plugins = with pkgs.vimPlugins; [
      # "Defaults everyone can agree on"
      sensible

      # Tools
      fugitive
      The_NERD_tree

      # Syntax support
      syntastic
      #vim-nix
      #rust-vim

      # Extra writing tools
      surround
      vim-easymotion

      # Writing / appearance
      airline
      goyo
      limelight-vim
    ];
    extraConfig = ''
        call plug#begin('~/.local/share/nvim/plugged')
        Plug 'rust-lang/rust.vim'
        Plug 'ncm2/ncm2'
        Plug 'roxma/nvim-yarp'
        Plug 'ncm2/ncm2-bufword'
        Plug 'ncm2/ncm2-path'
        Plug 'autozimu/LanguageClient-neovim', {
            \ 'branch': 'next',
            \ 'do': 'bash install.sh',
            \ }
        call plug#end()

        " Writing stuff
        let g:limelight_conceal_ctermfg = 'gray'

        " enable ncm2 for all buffers
        autocmd BufEnter * call ncm2#enable_for_buffer()
        set completeopt=noinsert,menuone,noselect

        " Use <TAB> to select the popup menu:
        inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
        inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

        " Enable Rust
        autocmd BufReadPost *.rs setlocal filetype=rust
        let g:LanguageClient_serverCommands = {
            \ 'rust': ['rustup', 'run', 'stable', 'rls'],
            \ }
        let g:LanguageClient_autoStart = 1
        let g:LanguageClient_useVirtualText = 0

        " Required for operations modifying multiple buffers like rename.
        set hidden

        nnoremap <silent> K :call LanguageClient_textDocument_hover()<CR>
        nnoremap <silent> gd :call LanguageClient_textDocument_definition()<CR>
        nnoremap <silent> <F2> :call LanguageClient_textDocument_rename()<CR>

        set nocompatible
        set linebreak

        set tabstop=2
        set shiftwidth=2
        set expandtab
        set smartindent
        set autoindent

        set hlsearch

        set guicursor=

        colorscheme desert

        " Splits
        set splitbelow
        set splitright

        set timeoutlen=100 ttimeoutlen=10
    '';
  };

  programs.ssh = {
    enable = true;
    compression = true;
    controlMaster = "auto";
    controlPersist = "2m";
    matchBlocks = {
      "*.sv" = {
        identityFile = "/home/svein/sufficient/id_rsa";
        user = "baughn";
      };
      "saya" = {
        proxyJump = "brage.info";
      };
    };
    extraConfig = ''
      User svein
    '';
  };

  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    enableCompletion = true;
    oh-my-zsh.enable = true;
    oh-my-zsh.plugins = [ "git" "sudo" ];
    oh-my-zsh.theme = "af-magic";
    profileExtra = ''
      if [ -e $HOME/.nix-profile/etc/profile.d/nix.sh ]; then . $HOME/.nix-profile/etc/profile.d/nix.sh; fi
      export GOPATH=$HOME/go
    '';
  };

  programs.home-manager.enable = true;
}

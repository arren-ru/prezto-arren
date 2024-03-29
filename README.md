## This repo is contrib part additional to prezto bundle

#### Provides features:

- `fzf` support for history/folders/files
- `fzf` + `ripgrep` for file contents and fast jump via vim editing
- `ls-colors` for better tree/exa support
- `thefuck` support when you screwed yourself with uncorrectly typed command, this may unfuck it :)

#### Hotkeys

- Original FZF keybindings are from https://github.com/junegunn/fzf and additional
  - `[ALT-C]` - jump to folder via fzf search
  - `[CTRL-T]` - substitute file via fzf search
  - `[ALT-R]` - substitute file with position and optionally add vim editing

- Double ESC gives unfuck

#### You need at least

- `fzf` - this is first pillar of fuzzy search
- `ripgrep` - second pillar for greping content
- `bat` - file preview with syntax highlight
- `exa` (or `tree`) - gives fancy file listing and tree preview

#### Minimal `.zshrc`:

```sh
zstyle ':prezto:load' pmodule \
    environment spectrum ls-colors \
    terminal prompt syntax-highlighting autosuggestions completion \
    history history-substring-search directory utility git gpg \
    thefuck fzf

zstyle ':prezto:module:*'            color       yes
zstyle ':prezto:module:git:alias'    skip        yes
zstyle ':prezto:module:prompt'       theme       pure
zstyle ':prezto:module:utility'      safe-ops    no
zstyle ':prezto:module:utility'      correct     no
zstyle ':prompt:pure:path'           color       36
zstyle ':prompt:pure:prompt:success' color       240
zstyle ':prezto:module:ls-colors'    theme       molokai
zstyle ':prezto:module:fzf:*'        ignore      . .git/ .composer/ .golang/ Library/
zstyle ':prezto:module:fzf:ctrl-t'   bat-theme   'Monokai Extended Bright'

if [[ ! -f $HOME/.zsh/prezto/init.zsh ]]; then
    for pmodrepo in sorin-ionescu/prezto arren-ru/prezto-arren; do
        git clone --quiet --depth=1 --shallow-submodules --recursive --jobs=8 "https://github.com/${m}.git" "$HOME/.zsh/${m:t}"
    done
fi

zstyle ':prezto:load' pmodule-dirs $HOME/.zsh/prezto-*
source $HOME/.zsh/prezto/init.zsh
```

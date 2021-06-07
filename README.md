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
export LANG=en_US.UTF-8
export EDITOR=vim
export PATH="$HOME/local/.bin:/usr/local/sbin:$PATH"

if [[ "$OSTYPE" == darwin* ]]; then
    export HOMEBREW_CASK_OPTS=" --no-binaries --appdir=$HOME/Applications "
    [[ -d "/usr/local/opt/curl" ]] && export PATH="/usr/local/opt/curl/bin:$PATH"
    ulimit -S -n 10240
fi

export HELM_CACHE_HOME="$HOME/.cache/helm"
export HELM_DATA_HOME="$HOME/.local/share/helm"
export HELM_CONFIG_HOME="$HOME/.config/helm"

export GOPROXY=direct
export GOSUMDB=off
export GOPATH="$HOME/.golang"

export PATH="$PATH:$GOPATH/bin:$HOME/.krew/bin:$HOME/.composer/vendor/bin"

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
zstyle ':prezto:module:fzf:opts:*'   ignore      . .git/ .composer/ .golang/ Library/

if [[ ! -f $HOME/.zsh/prezto/init.zsh ]]; then
    for pmodrepo in sorin-ionescu/prezto arren-ru/prezto-arren; do
        [[ -d "$HOME/.zsh/${pmodrepo:r:t}" ]] && continue
        git clone --quiet --depth=1 --shallow-submodules --recursive --jobs=8 \
            "git@github.com:${pmodrepo}.git" "$HOME/.zsh/${pmodrepo:r:t}"
    done
    unset pmodrepo
fi

zstyle ':prezto:load' pmodule-dirs $HOME/.zsh/prezto-*
source $HOME/.zsh/prezto/init.zsh
```

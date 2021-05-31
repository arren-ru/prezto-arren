## This repo is contrib part additional to prezto bundle

#### Provides features:

- fzf support for history/folders/files
- fzf + ripgrep for file contents and fast jump via vim editing
- ls-colors for better tree/exa support
- thefuck support when you screwed yourself with uncorrectly typed command, this may unfuck it :)

#### Hotkeys

- Original FZF keybindings are from https://github.com/junegunn/fzf and additional
  - Alt-C - jump to folder via fzf search
  - Ctrl-T - substitute file via fzf search
  - Alt-R - substitute file with position and optionally add vim editing

- Double ESC gives unfuck

#### You need at least

- fzf - this is first pillar of fuzzy search
- ripgrep - second pillar for greping content
- bat - file preview with syntax highlight
- exa (or tree) - gives fancy file listing and tree preview

#### Minimal `.zshrc`:

```sh
export LANG=en_US.UTF-8
export EDITOR=vim
export PATH="$HOME/local/.bin:/usr/local/sbin:$PATH"

eval $(gpg-agent --daemon --enable-ssh-support 2>/dev/null)
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)

if [[ "$OSTYPE" == darwin* ]]; then
    export HOMEBREW_CASK_OPTS=" --no-binaries --appdir=$HOME/Applications "
    [[ -d "/usr/local/opt/curl" ]] && export PATH="/usr/local/opt/curl/bin:$PATH"
    ulimit -S -n 10240
fi

(( $+commands[gopass] )) && {
    export PASSWORD_STORE_DIR="$HOME/.pass"
    export GITHUB_TOKEN=$(gopass env/GITHUB_TOKEN)
    export HOMEBREW_GITHUB_API_TOKEN=$GITHUB_TOKEN
}

{ # prezto
    for m in https://github.com/{sorin-ionescu/prezto,arren-ru/prezto-arren}.git; do
        [[ ! -d "$HOME/.zsh/${m:r:t}" ]] && \
            git clone --depth=1 --shallow-submodules --recursive --jobs=8 "$m" "$HOME/.zsh/${m:r:t}" &
    done && wait

    zstyle ':prezto:load' pmodule-dirs $HOME/.zsh/prezto-*
    zstyle ':prezto:load' pmodule \
        environment terminal editor history directory spectrum utility \
        prompt git syntax-highlighting history-substring-search \
        autosuggestions completion \
        thefuck ls-colors fzf

    # Prezto
    zstyle ':prezto:module:*'            color       yes
    zstyle ':prezto:module:git:alias'    skip        yes
    zstyle ':prezto:module:prompt'       theme       pure
    zstyle ':prezto:module:utility'      safe-ops    no
    zstyle ':prezto:module:utility'      correct     no
    zstyle ':prompt:pure:path'           color       36
    zstyle ':prompt:pure:prompt:success' color       240

    # Arren
    zstyle ':prezto:module:ls-colors'    theme       molokai
    zstyle ':prezto:module:fzf:opts:*'   ignore      . .git/ .composer/ .golang/ Library/

    source $HOME/.zsh/prezto/init.zsh
}
```

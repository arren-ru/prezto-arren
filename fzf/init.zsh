(( ! $+commands[fzf] )) && return 1

if is-darwin && (( $+commands[brew] )) && [[ -d "/usr/local/opt/fzf" ]]; then
    source "/usr/local/opt/fzf/shell/completion.zsh"
    source "/usr/local/opt/fzf/shell/key-bindings.zsh"
elif is-linux && [[ -d "/usr/share/fzf" ]]; then
    source "/usr/share/fzf/completion.zsh"
    source "/usr/share/fzf/key-bindings.zsh"
else
    for fzf_external in completion.zsh key-bindings.zsh; do
        if [[ ! -s "${0:h}/external/$fzf_external" ]]; then
            echo -e "\e[33mDownloading fzf external $fzf_external\e[0m"
            curl --progress-bar --create-dirs -fLo "${0:h}/external/$fzf_external" \
                "https://raw.githubusercontent.com/junegunn/fzf/master/shell/$fzf_external"
        fi
        source "${0:h}/external/$fzf_external"
    done
    unset fzf_load_external
fi

if ! zstyle -t ':prezto:module:fzf:opts' skip 'yes'; then
    (( ! $+FZF_DEFAULT_OPTS )) && export FZF_DEFAULT_OPTS='-e --reverse --info=inline --height=100% --preview-window=up --color=dark,hl:9,hl+:9'
    (( ! $+FZF_COMPLETION_TRIGGER )) && export FZF_COMPLETION_TRIGGER='..'

    (( ! $+FZF_ALT_C_OPTS )) && {
        if (( $+commands[exa] )); then
            export FZF_ALT_C_OPTS="-m -e --preview 'exa -TL 3 --icons {}'"
        elif (( $+commands[tree] )); then
            export FZF_ALT_C_OPTS="-m -e --preview 'tree -CFNL 3 --noreport --filelimit=40 {}'"
        fi
    }

    (( $+commands[fd] )) && {
        _fzf_compgen_path() {
            fd -HLE '.git' . "$1"
        }
        _fzf_compgen_dir() {
            fd -t d -HLE '.git' . "$1"
        }

        (( ! $+FZF_ALT_C_COMMAND )) && {
            export FZF_ALT_C_COMMAND='fd -t d -L'
            zstyle -a ':prezto:module:fzf:opts:alt-c' ignore fzf_ignore_list
            if (( $#fzf_ignore_list > 0 )); then
                fzf_ignore_opts=(-E\ ${^fzf_ignore_list})
                FZF_ALT_C_COMMAND+=" $fzf_ignore_opts"
            fi
            unset fzf_ignore_{list,opts}
        }

        (( ! $+FZF_CTRL_T_COMMAND )) && {
            export FZF_CTRL_T_COMMAND='fd -t f -HLI'
            zstyle -a ':prezto:module:fzf:opts:ctrl-c' ignore fzf_ignore_list
            if (( $#fzf_ignore_list > 0 )); then
                fzf_ignore_opts=(-E\ ${^fzf_ignore_list})
                FZF_CTRL_T_COMMAND+=" $fzf_ignore_opts"
            fi
            unset fzf_ignore_{list,opts}
        }
    }

    (( $+commands[bat] )) && {
        (( ! $+BAT_THEME )) && export BAT_THEME='Monokai Extended Bright'
        (( ! $+FZF_CTRL_T_OPT )) && export FZF_CTRL_T_OPTS="-m -e --preview 'bat --color=always --style=numbers,changes --line-range=:500 {}'"
    }
fi

source "${0:h}/rg.zsh"

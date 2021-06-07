if (( ! $+commands[fzf] )); then
    return 1
fi

if is-darwin && (( $+commands[brew] )) && [[ -d "/usr/local/opt/fzf" ]]; then
    source "/usr/local/opt/fzf/shell/completion.zsh"
    source "/usr/local/opt/fzf/shell/key-bindings.zsh"
elif is-linux && [[ -d "/usr/share/fzf" ]]; then
    source "/usr/share/fzf/completion.zsh"
    source "/usr/share/fzf/key-bindings.zsh"
else
    for fzf_external in completion.zsh key-bindings.zsh; do
        if [[ ! -s "${0:h}/external/$fzf_external" ]]; then
            echo -en "\e[s"
            curl --progress-bar --create-dirs -fLo "${0:h}/external/$fzf_external" \
                "https://raw.githubusercontent.com/junegunn/fzf/master/shell/$fzf_external"
            echo -en "\e[u\e[J"
        fi
        source "${0:h}/external/$fzf_external"
    done
    unset fzf_load_external
fi

if ! zstyle -t ':prezto:module:fzf:opts' skip 'yes'; then
    if (( ! $+FZF_DEFAULT_OPTS )); then
        export FZF_DEFAULT_OPTS='-e --reverse --info=inline --height=100% --preview-window=up --color=dark,hl:9,hl+:9'
    fi

    if (( ! $+FZF_COMPLETION_TRIGGER )); then
        export FZF_COMPLETION_TRIGGER='..'
    fi

    if (( ! $+FZF_ALT_C_OPTS )); then
        if (( $+commands[exa] )); then
            export FZF_ALT_C_OPTS="-m -e --preview 'exa -TL 3 --icons {}'"
        elif (( $+commands[tree] )); then
            export FZF_ALT_C_OPTS="-m -e --preview 'tree -CFNL 3 --noreport --filelimit=40 {}'"
        fi
    fi

    if (( $+commands[fd] )); then
        _fzf_compgen_path() {
            fd -HLE '.git' . "$1"
        }
        _fzf_compgen_dir() {
            fd -t d -HLE '.git' . "$1"
        }

        if (( ! $+FZF_ALT_C_COMMAND )); then
            export FZF_ALT_C_COMMAND='fd -t d -L'
            zstyle -a ':prezto:module:fzf:opts:alt-c' ignore fzf_ignore_list
            if (( $#fzf_ignore_list > 0 )); then
                fzf_ignore_opts=(-E\ ${^fzf_ignore_list})
                FZF_ALT_C_COMMAND+=" $fzf_ignore_opts"
            fi
            unset fzf_ignore_{list,opts}
        fi

        if (( ! $+FZF_CTRL_T_COMMAND )); then
            export FZF_CTRL_T_COMMAND='fd -t f -HLI'
            zstyle -a ':prezto:module:fzf:opts:ctrl-c' ignore fzf_ignore_list
            if (( $#fzf_ignore_list > 0 )); then
                fzf_ignore_opts=(-E\ ${^fzf_ignore_list})
                FZF_CTRL_T_COMMAND+=" $fzf_ignore_opts"
            fi
            unset fzf_ignore_{list,opts}
        fi
    fi

    if (( $+commands[bat] )); then
        if (( ! $+BAT_THEME )); then
            export BAT_THEME='Monokai Extended Bright'
        fi
        if (( ! $+FZF_CTRL_T_OPT )); then
            export FZF_CTRL_T_OPTS="-m -e --preview 'bat --color=always --style=numbers,changes --line-range=:500 {}'"
        fi
    fi
fi

source "${0:h}/rg.zsh"

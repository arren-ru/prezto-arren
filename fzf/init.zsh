if (( ! $+commands[fzf] )) return 1

if is-darwin && [[ -d "/usr/local/opt/fzf" ]]; then
    fzf_fsource=(/usr/local/opt/fzf/shell/{completion,key-bindings}.zsh)
elif is-linux && [[ -d "/usr/share/fzf" ]]; then
    fzf_fsource=(/usr/share/fzf/{completion,key-bindings}.zsh)
else
    fzf_fsource=(${0:h}/external/{completion,key-bindings}.zsh)
    for fsrc ($fzf_fsource) if [[ ! -s $fsrc ]] curl --progress-bar --create-dirs -fLo "$fsrc" \
        "https://raw.githubusercontent.com/junegunn/fzf/master/shell/${fsrc:t}"
fi
for fsrc ($^fzf_fsource(.N)) source $fsrc
unset fzf_fsource fsrc

if (( ! $+FZF_COMPLETION_TRIGGER )) export FZF_COMPLETION_TRIGGER='..'

if (( ! $+FZF_DEFAULT_OPTS )) \
    export FZF_DEFAULT_OPTS='-e --reverse --info=inline --height=100% --preview-window=up --color=dark,hl:9,hl+:9'

if (( $+commands[fd] )); then
    _fzf_compgen_path() {
        fd -HLE '.git' . "$1"
    }
    _fzf_compgen_dir() {
        fd -HLE -t d '.git' . "$1"
    }
fi

if ! zstyle -t ':prezto:module:fzf:alt-c' skip 'yes'; then
    if (( ! $+FZF_ALT_C_OPTS )); then
        export FZF_ALT_C_OPTS='-m -e'
        if (( $+commands[exa] )); then
            FZF_ALT_C_OPTS+=" --preview 'exa -TL 3 --icons {}'"
        elif (( $+commands[tree] )); then
            FZF_ALT_C_OPTS+=" --preview 'tree -CFNL 3 --noreport --filelimit=40 {}'"
        fi
    fi
    if (( ! $+FZF_ALT_C_COMMAND )) && (( $+commands[fd] )); then
        export FZF_ALT_C_COMMAND='fd -t d -L'
        zstyle -a ':prezto:module:fzf:alt-c' ignore fzf_ignore_list
        if (( $#fzf_ignore_list > 0 )); then
            fzf_ignore_opts=(-E\ ${^fzf_ignore_list})
            FZF_ALT_C_COMMAND+=" $fzf_ignore_opts"
        fi
        unset fzf_ignore_{list,opts}
    fi
fi

if ! zstyle -t ':prezto:module:fzf:ctrl-t' skip 'yes'; then
    if (( ! $+FZF_CTRL_T_OPTS )); then
        export FZF_CTRL_T_OPTS='-m -e'
        if (( $+commands[bat] )); then
            zstyle -s ':prezto:module:fzf:ctrl-t' bat-theme fzf_bat_theme
            FZF_CTRL_T_OPTS+=" --preview 'bat --theme=${(q)fzf_bat_theme} --color=always --style=numbers,changes --line-range=:500 {}'"
            unset fzf_bat_theme
        fi
    fi
    if (( ! $+FZF_CTRL_T_COMMAND )) && (( $+commands[fd] )); then
        export FZF_CTRL_T_COMMAND='fd -t f -HLI'
        zstyle -a ':prezto:module:fzf:ctrl-c' ignore fzf_ignore_list
        if (( $#fzf_ignore_list > 0 )); then
            fzf_ignore_opts=(-E\ ${^fzf_ignore_list})
            FZF_CTRL_T_COMMAND+=" $fzf_ignore_opts"
        fi
        unset fzf_ignore_{list,opts}
    fi
fi

source "${0:h}/rg.zsh"

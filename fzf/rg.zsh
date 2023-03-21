if (( ! $+commands[rg] )); then
    return 1
fi

export FZF_RGSEL_PREVIEW="${0:h}/external/preview.sh"
if [[ ! -x $FZF_RGSEL_PREVIEW ]]; then
    echo -en "\e[s"
    curl --progress-bar --create-dirs -fLo "$FZF_RGSEL_PREVIEW" \
        "https://raw.githubusercontent.com/junegunn/fzf.vim/master/bin/preview.sh"
    chmod +x "$FZF_RGSEL_PREVIEW"
    echo -en "\e[u\e[J"
fi

__fzf_rgsel() {
    setopt localoptions pipefail no_aliases 2>/dev/null
    local opts=(--column --line-number --no-heading --color=always --smart-case)
    rg ${opts[@]} -- '' \
        | $(__fzfcmd) +m --ansi \
          --delimiter=: --preview-window="+{2}-5" \
          --preview="$FZF_RGSEL_PREVIEW {}" \
          --bind="change:reload:rg ${opts[*]} -- {q} || true" \
        | cut -d: -f1,2,3
    local ret=$?
    echo
    return $ret
}

fzf-rg-widget() {
    local str
    str=($(__fzf_rgsel))
    ret=$?
    (( $#str )) && LBUFFER="${LBUFFER:-vim }${(q)str}"
    zle reset-prompt
    return $ret
}

zle     -N    fzf-rg-widget
bindkey '^Y' fzf-rg-widget

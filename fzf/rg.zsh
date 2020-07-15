(( ! $+commands[rg] )) && return 1

export FZF_RGSEL_PREVIEW="${0:h}/external/preview"
if [[ ! -x $FZF_RGSEL_PREVIEW ]]; then
    echo -e "\e[33mDownloading fzf script preview.sh\e[0m"
    curl --progress-bar --create-dirs -fLo "$FZF_RGSEL_PREVIEW" \
        "https://raw.githubusercontent.com/junegunn/fzf.vim/master/bin/preview.sh"
    chmod +x "$FZF_RGSEL_PREVIEW"
fi

__fzf_rgsel() {
    setopt localoptions pipefail no_aliases 2>/dev/null
    rg --column --line-number --no-heading --color=always --smart-case -- '' \
        | fzf --no-multi --phony --ansi --preview="$FZF_RGSEL_PREVIEW {}" \
            --bind='change:reload:rg --column --line-number --no-heading --color=always --smart-case -- {q} || true' \
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
bindkey '\er' fzf-rg-widget

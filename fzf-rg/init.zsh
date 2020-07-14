__rgsel() {
    local cmd="rg --column --line-number --no-heading --color=always --smart-case -- '%s'"
    local preview=$HOME/.vim/plugged/fzf.vim/bin/preview.sh
    local fzfopts="--phony --ansi --preview=\"$preview {}\" --bind \"change:reload:$(printf "$cmd" '{q}') || true\""
    setopt localoptions pipefail no_aliases 2> /dev/null

    eval "$(printf "$cmd" '')" | FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS $fzfopts" $(__fzfcmd) +m | cut -d: -f1
    local ret=$?
    echo
    return $ret
}

fzf-rg-widget() {
    LBUFFER="${LBUFFER}$(__rgsel)"
    local ret=$?
    zle reset-prompt
    return $ret
}

zle     -N   fzf-rg-widget
bindkey '\et' fzf-rg-widget


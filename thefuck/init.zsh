(( $+commands[thefuck] )) || return 1

# lazy load to improve loading speed and eval aliasing on demand
fuck() {
    unfunction "$0"
    eval $(thefuck --alias)
    $0 "$@"
}

fuck-command-line() {
    local FUCK="$(THEFUCK_REQUIRE_CONFIRMATION=0 thefuck $(fc -ln -1 | tail -n 1) 2> /dev/null)"
    [[ -z $FUCK ]] && echo -n -e "\a" && return
    BUFFER=$FUCK
    zle end-of-line
}

zle -N fuck-command-line
bindkey "\e\e" fuck-command-line


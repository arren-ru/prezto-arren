zstyle -s ':arren:module:ls-colors' theme ls_colors_theme || return 1

if [[ -f "${0:h}/themes/$ls_colors_theme" ]]; then
    export LS_COLORS=$(cat "${0:h}/themes/$ls_colors_theme")
fi

unset ls_colors_colors

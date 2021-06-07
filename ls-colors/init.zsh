if zstyle -s ':prezto:module:ls-colors' theme ls_colors_theme; then
    if [[ -f "${0:h}/themes/$ls_colors_theme" ]]; then
        export LS_COLORS=$(cat "${0:h}/themes/$ls_colors_theme")
    fi
fi
unset ls_colors_colors

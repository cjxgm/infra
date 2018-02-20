# USAGE: _pacman__install_hook name
#   Install a pacman hook to infra-${name}
_pacman__install_hook()
{
    local hook="$1"
    [[ -z $hook ]] && return 1

    install -Dm 644 "$srcdir/$hook" "$pkgdir/usr/share/libalpm/hooks/infra-$hook"
}


# USAGE: _systemd__install_unit name.type
#   Install a systemd unit file to infra-${name.type}
_systemd__install_unit()
{
    local unit="$1"
    [[ -z $unit ]] && return 1

    install -Dm 644 "$srcdir/$unit" "$pkgdir/usr/lib/systemd/system/infra-$unit"
}

# USAGE: _systemd__enable_unit name.type target
#   Enable the systemd unit file infra-${name.type}
#   as a Wants dependency of $target
_systemd__enable_unit()
{
    local unit="$1"
    local target="$2"
    [[ -z $unit ]] && return 1
    [[ -z $target ]] && return 1

    install -d "$pkgdir/usr/lib/systemd/system/$target.wants"
    ln -s "/usr/lib/systemd/system/infra-$unit" "$pkgdir/usr/lib/systemd/system/$target.wants/infra-$unit"
}


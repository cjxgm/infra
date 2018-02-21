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
# USAGE: _systemd__enable_unit name@instance.type target
#   Enable the systemd unit file infra-${name@instance.type}
#   to infra-${name@.type} as a Wants dependency of $target
_systemd__enable_unit()
{
    local unit="$1"
    local target="$2"
    [[ -z $unit ]] && return 1
    [[ -z $target ]] && return 1

    local source_unit
    if [[ $unit == *@*.* ]]; then
        source_unit="$(perl -pe 's{^([^@]+\@).*(\.[^.]+)$}{$1$2}' <<< "$unit")"
    elif [[ $unit == *.* ]]; then
        source_unit="$unit"
    else
        echo >&2 "Invalid unit name: $unit"
        return 1
    fi

    install -d "$pkgdir/usr/lib/systemd/system/$target.wants"
    ln -s "/usr/lib/systemd/system/infra-$source_unit" \
        "$pkgdir/usr/lib/systemd/system/$target.wants/infra-$unit"
}

# USAGE: _systemd__install_generator name
#   Install a systemd generator to infra-${name}
_systemd__install_generator()
{
    local gen="$1"
    [[ -z $gen ]] && return 1

    install -D "$srcdir/$gen" "$pkgdir/usr/lib/systemd/system-generators/infra-$gen"
}

# USAGE: _systemd__manage_lifetime unit
#   Let infra-reaper manage the restarting and stopping of infra-${unit}
_systemd__manage_lifetime()
{
    local unit="$1"
    [[ -z $unit ]] && return 1

    # A hacky way to say:
    # if (not depends.contains("infra-reaper")
    #     depends.push("infra-reaper");
    [[ " ${depends[@]} " == *' infra-reaper '* ]] || depends+=(infra-reaper)

    install -d "$pkgdir/usr/lib/infra/reaper.d"
    ln -s /dev/null "$pkgdir/usr/lib/infra/reaper.d/infra-$unit"
}


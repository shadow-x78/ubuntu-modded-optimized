#!/bin/sh

[ -z "${_UMO_MOD_THEME_LOADED:-}" ] || return 0
_UMO_MOD_THEME_LOADED=1

. "${UMO_LIB_DIR:-./lib}/core-ansi.sh"
. "${UMO_LIB_DIR:-./lib}/core-fs.sh"

UMO_THEME="${UMO_THEME:-umo-dark}"

_umo_theme_mode_setup() {
    case "$UMO_THEME" in
        umo-light)
            _GTK_THEME="Materia-light"
            _ICON_THEME="Papirus-Light"
            _CURSOR_THEME="DMZ-White"
            _DESKTOP_BG="#e8e8e8"
            _DESKTOP_FG="#222222"
            _TINT_FONT="#1a1a1a"
            _TINT_ACTIVE_BG="#d6d6d6"
            ;;
        *)
            _GTK_THEME="Materia-dark"
            _ICON_THEME="Papirus-Dark"
            _CURSOR_THEME="DMZ-White"
            _DESKTOP_BG="#1e1e1e"
            _DESKTOP_FG="#ffffff"
            _TINT_FONT="#ffffff"
            _TINT_ACTIVE_BG="#4a4a4a"
            ;;
    esac
    _ACCENT="#f97316"
}

umo_theme_packages() {
    umo_log_step "Install theme packages"

    _theme_pkgs="materia-gtk-theme greybird-gtk-theme dmz-cursor-theme \
                 papirus-icon-theme gnome-icon-theme unzip \
                 fonts-inter fonts-jetbrains-mono fonts-dejavu-core"

    cat > "${UMO_INSTALL_DIR:?}/root/install-theme.sh" << INNER
#!/bin/sh
export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C
export LANG=C
[ -t 0 ] && exec </dev/null
timeout 600 apt-get install -y -q --no-install-recommends $_theme_pkgs 2>/dev/null || true
timeout 120 apt-get install -y -q exo-utils 2>/dev/null || true
dpkg --configure -a || true
INNER
    chmod +x "$UMO_INSTALL_DIR/root/install-theme.sh"
    printf "  %b>%b  Installing theme packages...\n" "$UMO_B_CYAN" "$UMO_NC"
    _rc=0
    "$UMO_LOGIN_SH" -c "bash /root/install-theme.sh" || _rc=$?
    if [ "$_rc" -eq 0 ]; then
        printf "  %b%s%b  Theme packages installed successfully\n" "$UMO_COLOR_SUCCESS" "$UMO_G_OK" "$UMO_NC"
    else
        printf "  %b%s%b  Theme packages installation encountered errors (code %d)\n" "$UMO_COLOR_DANGER" "$UMO_G_ERR" "$UMO_NC" "$_rc"
    fi
    rm -f "$UMO_INSTALL_DIR/root/install-theme.sh"
    umo_log_ok "Theme packages installed"
}

umo_theme_extras() {
    umo_log_step "Install designer extras (Orchis / Tela / FiraCode Nerd)"

    _extras_src="$SCRIPT_DIR/config/container/umo-install-extras"
    if [ -f "$_extras_src" ]; then
        cp -f "$_extras_src" "${UMO_INSTALL_DIR:?}/root/install-extras.sh" 2>/dev/null || true
        chmod +x "${UMO_INSTALL_DIR}/root/install-extras.sh" 2>/dev/null || true
        _rc=0
        "$UMO_LOGIN_SH" -c "bash /root/install-extras.sh" || _rc=$?
        rm -f "${UMO_INSTALL_DIR}/root/install-extras.sh" 2>/dev/null || true
    fi

    _has_orchis=0
    "$UMO_LOGIN_SH" -c "test -d /usr/share/themes/Orchis-Dark-Compact" 2>/dev/null && _has_orchis=1
    if [ "$_has_orchis" = "1" ]; then
        _GTK_THEME="Orchis-Dark-Compact"
        _ICON_THEME="Tela-Black-Dark"
        umo_log_ok "Designer extras applied (Orchis-Dark-Compact + Tela-Black-Dark)"
    else
        umo_log_warn "Designer extras unavailable (offline?) - keeping Materia-dark + Papirus-Dark"
    fi
    return 0
}

umo_theme_apply_gtk() {
    umo_log_step "Apply GTK theme configuration"

    _theme_dir="$SCRIPT_DIR/config/theme"

    for _home in "$UMO_INSTALL_DIR/root" "$UMO_INSTALL_DIR/home/umo"; do
        [ -d "$_home" ] || continue
        umo_fs_mkdir "$_home/.config/gtk-3.0"
        if [ -f "$_theme_dir/gtk-3.0/settings.ini.tmpl" ]; then
            umo_fs_render "$_theme_dir/gtk-3.0/settings.ini.tmpl" "$_home/.config/gtk-3.0/settings.ini" \
                "GTK_THEME" "$_GTK_THEME" \
                "ICON_THEME" "$_ICON_THEME" \
                "CURSOR_THEME" "$_CURSOR_THEME"
        fi
        if [ -f "$_theme_dir/gtk-2.0/gtkrc.tmpl" ]; then
            umo_fs_render "$_theme_dir/gtk-2.0/gtkrc.tmpl" "$_home/.gtkrc-2.0" \
                "GTK_THEME" "$_GTK_THEME" \
                "ICON_THEME" "$_ICON_THEME" \
                "CURSOR_THEME" "$_CURSOR_THEME"
        fi
    done

    umo_log_ok "GTK configuration applied"
}

umo_theme_apply_fonts() {
    umo_log_step "Configure fonts"

    _fc_dir="$UMO_INSTALL_DIR/etc/fonts/conf.d"
    umo_fs_mkdir "$_fc_dir"
    if [ -f "$SCRIPT_DIR/config/theme/fontconfig/01-umo-fonts.conf" ]; then
        cp -f "$SCRIPT_DIR/config/theme/fontconfig/01-umo-fonts.conf" "$_fc_dir/"
    fi

    umo_log_ok "Font configuration applied"
}

umo_theme_apply_wallpaper() {
    _wp_src="$SCRIPT_DIR/config/theme/wallpaper/umo-wallpaper.jpg"

    if [ -f "$_wp_src" ]; then
        if mkdir -p "$UMO_INSTALL_DIR/usr/share/wallpapers" 2>/dev/null; then
            cp -f "$_wp_src" "$UMO_INSTALL_DIR/usr/share/wallpapers/umo-wallpaper.jpg" 2>/dev/null || \
                umo_log_warn "Could not copy wallpaper"
        fi

        _xdg_dir="$UMO_INSTALL_DIR/etc/xdg/xfce4/xfconf/xfce-perchannel-xml"
        if mkdir -p "$_xdg_dir" 2>/dev/null && [ -f "$SCRIPT_DIR/config/theme/xfce4/xfce4-desktop.xml" ]; then
            cp -f "$SCRIPT_DIR/config/theme/xfce4/xfce4-desktop.xml" "$_xdg_dir/xfce4-desktop.xml" 2>/dev/null || true
        fi

        _bd_dir="$UMO_INSTALL_DIR/usr/share/xfce4/backdrops"
        if [ -d "$_bd_dir" ]; then
            for _bd in "$_bd_dir"/*.jpg "$_bd_dir"/*.jpeg "$_bd_dir"/*.png "$_bd_dir"/*.svg; do
                if [ -f "$_bd" ]; then
                    cp -f "$_wp_src" "$_bd" 2>/dev/null || true
                fi
            done
        fi
    else
        umo_log_info "No wallpaper file found, continuing without wallpaper"
    fi
    return 0
}

umo_theme_apply_xfce() {
    umo_log_step "Configure XFCE4 desktop design"

    _theme_dir="$SCRIPT_DIR/config/theme/xfce4"

    for _home in "$UMO_INSTALL_DIR/root" "$UMO_INSTALL_DIR/home/umo"; do
        [ -d "$_home" ] || continue
        _xf_conf="$_home/.config/xfce4/xfconf/xfce-perchannel-xml"
        umo_fs_mkdir "$_xf_conf"

        if [ -f "$_theme_dir/xsettings.xml.tmpl" ]; then
            umo_fs_render "$_theme_dir/xsettings.xml.tmpl" "$_xf_conf/xsettings.xml" \
                "GTK_THEME" "$_GTK_THEME" \
                "ICON_THEME" "$_ICON_THEME" \
                "CURSOR_THEME" "$_CURSOR_THEME"
        fi
        if [ -f "$_theme_dir/xfwm4.xml.tmpl" ]; then
            umo_fs_render "$_theme_dir/xfwm4.xml.tmpl" "$_xf_conf/xfwm4.xml" \
                "GTK_THEME" "$_GTK_THEME"
        fi
        if [ -f "$_theme_dir/xfce4-panel.xml" ]; then
            cp -f "$_theme_dir/xfce4-panel.xml" "$_xf_conf/"
        fi
        if [ -f "$_theme_dir/xfce4-desktop.xml" ]; then
            cp -f "$_theme_dir/xfce4-desktop.xml" "$_xf_conf/"
        fi
        if [ -f "$_theme_dir/terminalrc" ]; then
            mkdir -p "$_home/.config/xfce4/terminal"
            cp -f "$_theme_dir/terminalrc" "$_home/.config/xfce4/terminal/terminalrc"
        fi
        rm -f "$_home/.config/xfce4/panel/panels.xml" 2>/dev/null || true
    done

    if [ -d "${UMO_INSTALL_DIR}/usr/local/bin" ] || mkdir -p "${UMO_INSTALL_DIR}/usr/local/bin" 2>/dev/null; then
        if [ -f "$_theme_dir/umo-desktop-init" ]; then
            cp -f "$_theme_dir/umo-desktop-init" "${UMO_INSTALL_DIR}/usr/local/bin/umo-desktop-init" 2>/dev/null || true
            chmod +x "${UMO_INSTALL_DIR}/usr/local/bin/umo-desktop-init" 2>/dev/null || true
        fi
    fi

    umo_log_ok "XFCE4 design applied"
}

umo_theme_apply_lxde() {
    umo_log_step "Configure LXDE desktop design"

    _theme_dir="$SCRIPT_DIR/config/theme/lxde"

    for _home in "$UMO_INSTALL_DIR/root" "$UMO_INSTALL_DIR/home/umo"; do
        [ -d "$_home" ] || continue

        _panel_dir="$_home/.config/lxpanel/LXDE/panels"
        umo_fs_mkdir "$_panel_dir"
        if [ -f "$_theme_dir/panel" ]; then
            cp -f "$_theme_dir/panel" "$_panel_dir/panel"
        fi

        _sx_dir="$_home/.config/lxsession/LXDE"
        umo_fs_mkdir "$_sx_dir"
        if [ -f "$_theme_dir/desktop.conf.tmpl" ]; then
            umo_fs_render "$_theme_dir/desktop.conf.tmpl" "$_sx_dir/desktop.conf" \
                "GTK_THEME" "$_GTK_THEME" \
                "ICON_THEME" "$_ICON_THEME" \
                "CURSOR_THEME" "$_CURSOR_THEME" \
                "DESKTOP_BG" "$_DESKTOP_BG" \
                "DESKTOP_FG" "$_DESKTOP_FG"
        fi

        _pf_dir="$_home/.config/pcmanfm/LXDE"
        umo_fs_mkdir "$_pf_dir"
        if [ -f "$_theme_dir/desktop-items-0.conf.tmpl" ]; then
            umo_fs_render "$_theme_dir/desktop-items-0.conf.tmpl" "$_pf_dir/desktop-items-0.conf" \
                "DESKTOP_BG" "$_DESKTOP_BG" \
                "DESKTOP_FG" "$_DESKTOP_FG"
        fi
    done

    umo_log_ok "LXDE design applied"
}

umo_theme_apply_openbox() {
    umo_log_step "Configure Openbox desktop design"

    _theme_dir="$SCRIPT_DIR/config/theme/openbox"

    for _home in "$UMO_INSTALL_DIR/root" "$UMO_INSTALL_DIR/home/umo"; do
        [ -d "$_home" ] || continue

        _ob_dir="$_home/.config/openbox"
        umo_fs_mkdir "$_ob_dir"
        if [ -f "$_theme_dir/rc.xml" ]; then
            cp -f "$_theme_dir/rc.xml" "$_ob_dir/rc.xml"
        fi
        if [ -f "$_theme_dir/menu.xml" ]; then
            cp -f "$_theme_dir/menu.xml" "$_ob_dir/menu.xml"
        fi
        if [ -f "$_theme_dir/autostart" ]; then
            cp -f "$_theme_dir/autostart" "$_ob_dir/autostart"
            chmod +x "$_ob_dir/autostart"
        fi

        _tint_dir="$_home/.config/tint2"
        umo_fs_mkdir "$_tint_dir"
        if [ -f "$_theme_dir/tint2rc.tmpl" ]; then
            umo_fs_render "$_theme_dir/tint2rc.tmpl" "$_tint_dir/tint2rc" \
                "TASK_FONT" "$_TINT_FONT" \
                "ACTIVE_BG" "$_TINT_ACTIVE_BG" \
                "ACCENT" "$_ACCENT"
        fi
    done

    umo_log_ok "Openbox design applied"
}

umo_theme_fix_ownership() {
    if [ -d "$UMO_INSTALL_DIR/home/umo" ]; then
        chown -R 1000:1000 "$UMO_INSTALL_DIR/home/umo/.config" 2>/dev/null || true
        chown -R 1000:1000 "$UMO_INSTALL_DIR/home/umo/.gtkrc-2.0" 2>/dev/null || true
    fi
}

umo_theme_setup() {
    [ "$UMO_THEME" = "none" ] && { umo_log_info "Theme disabled."; return 0; }
    umo_log_step "Apply UMO Desktop Theme ($UMO_THEME)"

    _umo_theme_mode_setup

    umo_theme_packages || true
    if [ "$UMO_THEME" != "umo-light" ]; then
        umo_theme_extras || true
    fi
    umo_theme_apply_fonts || true
    umo_theme_apply_wallpaper || true

    if [ "$UMO_DE" != "minimal" ]; then
        umo_theme_apply_gtk || true
    fi

    case "$UMO_DE" in
        xfce4|xfce) umo_theme_apply_xfce || true ;;
        lxde)       umo_theme_apply_lxde || true ;;
        openbox)    umo_theme_apply_openbox || true ;;
    esac

    umo_theme_fix_ownership || true

    umo_log_ok "Desktop theme applied"
    return 0
}

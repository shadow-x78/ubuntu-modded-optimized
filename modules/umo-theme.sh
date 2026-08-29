#!/bin/sh

[ -z "${_UMO_MOD_THEME_LOADED:-}" ] || return 0
_UMO_MOD_THEME_LOADED=1

. "${UMO_LIB_DIR:-./lib}/core-ansi.sh"
. "${UMO_LIB_DIR:-./lib}/core-fs.sh"

UMO_THEME="${UMO_THEME:-umo-dark}"

_umo_theme_mode_setup() {
    case "$UMO_THEME" in
        umo-light)
            _GTK_THEME="Orchis-Light-Compact"
            _ICON_THEME="Tela"
            _CURSOR_THEME="DMZ-White"
            _DESKTOP_BG="#e8e8e8"
            _DESKTOP_FG="#222222"
            _TINT_FONT="#1a1a1a"
            _TINT_ACTIVE_BG="#d6d6d6"
            ;;
        *)
            _GTK_THEME="Orchis-Dark-Compact"
            _ICON_THEME="Tela-black-dark"
            _CURSOR_THEME="DMZ-White"
            _DESKTOP_BG="#1e1e1e"
            _DESKTOP_FG="#ffffff"
            _TINT_FONT="#ffffff"
            _TINT_ACTIVE_BG="#4a4a4a"
            ;;
    esac
    _ACCENT="#f97316"
}

_umo_theme_ui_font() {
    printf '%s' "Ubuntu SemiBold 10"
}

_umo_theme_mono_font() {
    printf '%s' "FiraCode Nerd Font Mono 9"
}

_umo_theme_terminal_font() {
    printf '%s' "FiraCode Nerd Font Mono Bold 9"
}

umo_theme_packages() {
    umo_log_step "Install Theme Packages"

    _theme_pkgs="materia-gtk-theme greybird-gtk-theme dmz-cursor-theme \
                 gnome-icon-theme unzip \
                 fonts-ubuntu fonts-inter fonts-jetbrains-mono fonts-dejavu-core"

    {
        printf '%s\n' '#!/bin/sh'
        _umo_log_container_prelude
    } > "${UMO_INSTALL_DIR:?}/root/install-theme.sh"
    cat >> "${UMO_INSTALL_DIR}/root/install-theme.sh" << INNER
export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C
export LANG=C
[ -t 0 ] && exec </dev/null
_LOG=/root/install-theme.log
_step "Installing Theme Packages..."
if dpkg -l papirus-icon-theme 2>/dev/null | grep -q '^ii'; then
    timeout 600 apt-get remove -y papirus-icon-theme >> "\$_LOG" 2>&1 || true
fi
timeout 600 apt-get install -y --no-install-recommends $_theme_pkgs >> "\$_LOG" 2>&1 || \
    _fail "Theme Packages Returned Errors (See /root/install-theme.log)"
timeout 120 apt-get install -y exo-utils >> "\$_LOG" 2>&1 || true
dpkg --configure -a >> "\$_LOG" 2>&1 || true
INNER
    chmod +x "$UMO_INSTALL_DIR/root/install-theme.sh"
    _rc=0
    "$UMO_LOGIN_SH" -c "bash /root/install-theme.sh" </dev/null || _rc=$?
    if [ "$_rc" -eq 0 ]; then
        umo_log_ok "Theme Packages Installed"
    else
        umo_log_warn "Theme Packages Installation Finished With Warnings (Code $_rc)"
    fi
    rm -f "$UMO_INSTALL_DIR/root/install-theme.sh"
}

umo_theme_write_mode_marker() {
    _mode="dark"
    [ "$UMO_THEME" = "umo-light" ] && _mode="light"
    _marker_dir="${UMO_INSTALL_DIR:?}/etc/umo"
    if mkdir -p "$_marker_dir" 2>/dev/null; then
        printf '%s\n' "$_mode" > "$_marker_dir/umo-theme-mode" 2>/dev/null || true
    fi
}

umo_theme_extras() {
    _mode="dark"
    [ "$UMO_THEME" = "umo-light" ] && _mode="light"
    umo_log_step "Install Designer Extras (Orchis / Tela / FiraCode Nerd, Mode: $_mode)"

    _extras_src="$SCRIPT_DIR/config/container/umo-install-extras"
    if [ -f "$_extras_src" ]; then
        cp -f "$_extras_src" "${UMO_INSTALL_DIR:?}/root/install-extras.sh" 2>/dev/null || true
        chmod +x "${UMO_INSTALL_DIR}/root/install-extras.sh" 2>/dev/null || true
        _rc=0
        "$UMO_LOGIN_SH" -c "bash /root/install-extras.sh $_mode" </dev/null || _rc=$?
        rm -f "${UMO_INSTALL_DIR}/root/install-extras.sh" 2>/dev/null || true
    fi

    _want_gtk="Orchis-Dark-Compact"
    _want_icons="Tela-black-dark"
    [ "$_mode" = "light" ] && _want_gtk="Orchis-Light-Compact" && _want_icons="Tela"

    _has_theme=0
    "$UMO_LOGIN_SH" -c "test -d /usr/share/themes/$_want_gtk" </dev/null 2>/dev/null && _has_theme=1
    _has_icons=0
    "$UMO_LOGIN_SH" -c "test -d /usr/share/icons/$_want_icons" </dev/null 2>/dev/null && _has_icons=1
    if [ "$_has_theme" = "1" ] && [ "$_has_icons" = "1" ]; then
        _GTK_THEME="$_want_gtk"
        _ICON_THEME="$_want_icons"
        umo_log_ok "Designer Extras Applied ($_want_gtk + $_want_icons)"
    else
        _missing=""
        [ "$_has_theme" != "1" ] && _missing="GTK Theme"
        [ "$_has_icons" != "1" ] && _missing="${_missing:+$_missing + }Icons"
        if [ "$_has_theme" = "1" ]; then
            _GTK_THEME="$_want_gtk"
        elif [ "$_mode" = "light" ]; then
            _GTK_THEME="Materia-light"
        else
            _GTK_THEME="Materia-dark"
        fi
        if [ "$_has_icons" = "1" ]; then
            _ICON_THEME="$_want_icons"
        else
            _ICON_THEME="gnome"
        fi
        umo_log_warn "Designer Extras Incomplete ($_missing Missing) - Using Fallback ($_GTK_THEME + $_ICON_THEME) Until The Next Run"
    fi
    return 0
}

umo_theme_apply_gtk() {
    umo_log_step "Apply GTK Theme Configuration"

    _theme_dir="$SCRIPT_DIR/config/theme"
    _UI_FONT="$(_umo_theme_ui_font)"
    _MONO_FONT="$(_umo_theme_mono_font)"

    for _home in "$UMO_INSTALL_DIR/root" "$UMO_INSTALL_DIR/home/umo"; do
        [ -d "$_home" ] || continue
        umo_fs_mkdir "$_home/.config/gtk-3.0"
        if [ -f "$_theme_dir/gtk-3.0/settings.ini.tmpl" ]; then
            umo_fs_render "$_theme_dir/gtk-3.0/settings.ini.tmpl" "$_home/.config/gtk-3.0/settings.ini" \
                "GTK_THEME" "$_GTK_THEME" \
                "ICON_THEME" "$_ICON_THEME" \
                "CURSOR_THEME" "$_CURSOR_THEME" \
                "UI_FONT" "$_UI_FONT" \
                "MONO_FONT" "$_MONO_FONT"
        fi
        if [ -f "$_theme_dir/gtk-2.0/gtkrc.tmpl" ]; then
            umo_fs_render "$_theme_dir/gtk-2.0/gtkrc.tmpl" "$_home/.gtkrc-2.0" \
                "GTK_THEME" "$_GTK_THEME" \
                "ICON_THEME" "$_ICON_THEME" \
                "CURSOR_THEME" "$_CURSOR_THEME" \
                "UI_FONT" "$_UI_FONT" \
                "MONO_FONT" "$_MONO_FONT"
        fi
    done

    umo_log_ok "GTK Configuration Applied"
}

umo_theme_apply_fonts() {
    umo_log_step "Configure Fonts"

    _fc_dir="$UMO_INSTALL_DIR/etc/fonts/conf.d"
    umo_fs_mkdir "$_fc_dir"
    if [ -f "$SCRIPT_DIR/config/theme/fontconfig/01-umo-fonts.conf" ]; then
        cp -f "$SCRIPT_DIR/config/theme/fontconfig/01-umo-fonts.conf" "$_fc_dir/"
    fi

    umo_log_ok "Font Configuration Applied"
}

_umo_theme_channel_xml() {
    _cx_wp="$1"
    printf '<?xml version="1.0" encoding="UTF-8"?>\n\n'
    printf '<channel name="xfce4-desktop" version="1.0">\n'
    printf '  <property name="backdrop" type="empty">\n'
    printf '    <property name="screen0" type="empty">\n'
    for _cx_mon in monitor0 monitor-0 monitor1 monitor-1 monitorVNC0 monitorVNC-0 monitorVirtual1 default; do
        printf '      <property name="%s" type="empty">\n' "$_cx_mon"
        printf '        <property name="workspace0" type="empty">\n'
        printf '          <property name="image-path" type="string" value="%s"/>\n' "$_cx_wp"
        printf '          <property name="last-image" type="string" value="%s"/>\n' "$_cx_wp"
        printf '          <property name="last-single-image" type="string" value="%s"/>\n' "$_cx_wp"
        printf '          <property name="image-show" type="bool" value="true"/>\n'
        printf '          <property name="image-style" type="int" value="5"/>\n'
        printf '          <property name="color-style" type="int" value="0"/>\n'
        printf '        </property>\n'
        printf '      </property>\n'
    done
    printf '    </property>\n'
    printf '  </property>\n'
    printf '  <property name="last" type="empty">\n'
    printf '    <property name="window-alignment" type="int" value="1"/>\n'
    printf '  </property>\n'
    printf '</channel>\n'
}

umo_theme_seed_desktop_channel() {
    _sc_wp="/usr/share/wallpapers/umo-wallpaper.jpg"
    for _sc_home in "$UMO_INSTALL_DIR/root" "$UMO_INSTALL_DIR/home/umo"; do
        [ -d "$_sc_home" ] || continue
        [ "$UMO_DE" != "xfce4" ] && [ "$UMO_DE" != "xfce" ] && [ -n "${UMO_DE:-}" ] && continue
        _sc_dir="$_sc_home/.config/xfce4/xfconf/xfce-perchannel-xml"
        _sc_file="$_sc_dir/xfce4-desktop.xml"
        mkdir -p "$_sc_dir" 2>/dev/null || continue
        if [ -f "$_sc_file" ]; then
            sed -i \
                -e "s|\(name=\"image-path\" type=\"string\" value=\"\)[^\"]*\(\".*\)|\1$_sc_wp\2|" \
                -e "s|\(name=\"last-image\" type=\"string\" value=\"\)[^\"]*\(\".*\)|\1$_sc_wp\2|" \
                -e "s|\(name=\"last-single-image\" type=\"string\" value=\"\)[^\"]*\(\".*\)|\1$_sc_wp\2|" \
                "$_sc_file" 2>/dev/null || true
            if ! grep -qF "$_sc_wp" "$_sc_file" 2>/dev/null; then
                _umo_theme_channel_xml "$_sc_wp" > "$_sc_file" 2>/dev/null || true
            fi
        else
            _umo_theme_channel_xml "$_sc_wp" > "$_sc_file" 2>/dev/null || true
        fi
        chmod 644 "$_sc_file" 2>/dev/null || true
    done
    if [ -d "$UMO_INSTALL_DIR/home/umo" ]; then
        chown -R 1000:1000 "$UMO_INSTALL_DIR/home/umo/.config/xfce4" 2>/dev/null || true
    fi
    return 0
}

umo_theme_apply_wallpaper() {
    _wp_src="$SCRIPT_DIR/config/theme/wallpaper/umo-wallpaper.jpg"

    if [ -f "$_wp_src" ]; then
        if mkdir -p "$UMO_INSTALL_DIR/usr/share/wallpapers" 2>/dev/null; then
            if cp -f "$_wp_src" "$UMO_INSTALL_DIR/usr/share/wallpapers/umo-wallpaper.jpg" 2>/dev/null; then
                umo_log_ok "Wallpaper Installed (/usr/share/wallpapers/umo-wallpaper.jpg)"
            else
                umo_log_warn "Could Not Copy Wallpaper"
            fi
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

        _bg_dir="$UMO_INSTALL_DIR/usr/share/backgrounds/xfce"
        if [ -d "$_bg_dir" ]; then
            for _bg in "$_bg_dir"/*.jpg "$_bg_dir"/*.jpeg "$_bg_dir"/*.png; do
                if [ -f "$_bg" ]; then
                    cp -f "$_wp_src" "$_bg" 2>/dev/null || true
                fi
            done
        fi

        umo_theme_seed_desktop_channel
    else
        umo_log_info "No Wallpaper File Found, Continuing Without Wallpaper"
    fi
    return 0
}

umo_theme_apply_fastfetch() {
    umo_log_step "Configure Fastfetch (UMO Design)"

    _ff_src="$SCRIPT_DIR/config/theme/fastfetch/config.jsonc"
    [ -f "$_ff_src" ] || { umo_log_warn "Fastfetch Config Template Missing, Skipping"; return 0; }

    if mkdir -p "${UMO_INSTALL_DIR:?}/etc/xdg/fastfetch" 2>/dev/null; then
        cp -f "$_ff_src" "$UMO_INSTALL_DIR/etc/xdg/fastfetch/config.jsonc" 2>/dev/null || \
            umo_log_warn "Could Not Install System-Wide Fastfetch Config"
    fi

    for _home in "$UMO_INSTALL_DIR/root" "$UMO_INSTALL_DIR/home/umo"; do
        [ -d "$_home" ] || continue
        if umo_fs_mkdir "$_home/.config/fastfetch"; then
            cp -f "$_ff_src" "$_home/.config/fastfetch/config.jsonc" 2>/dev/null || true
        fi
    done

    chown -R 1000:1000 "$UMO_INSTALL_DIR/home/umo/.config/fastfetch" 2>/dev/null || true
    umo_log_ok "Fastfetch Configuration Applied"
}

_umo_plank_launchers() {
    printf '%s\n' thunar xfce4-terminal mousepad
    if [ -f "$UMO_INSTALL_DIR/usr/share/applications/org.kde.falkon.desktop" ]; then
        printf '%s\n' org.kde.falkon
    fi
    case "${UMO_APP_SET:-basic}" in
        media)   printf '%s\n' vlc gimp ;;
        office)  printf '%s\n' libreoffice-startcenter atril ;;
        browser) : ;;
        dev)     printf '%s\n' code ;;
        full)    printf '%s\n' vlc gimp libreoffice-startcenter atril code ;;
        basic|*) : ;;
    esac
    return 0
}

_umo_theme_apply_plank() {
    _pl_home="$1"
    _pl_dir="$_pl_home/.config/plank/dock1"
    mkdir -p "$_pl_dir/launchers" 2>/dev/null || return 0

    cat > "$_pl_dir/settings.ini" << 'PLANKINI'
[PlankDockPreferences]
Position=3
IconSize=48
HideMode=0
Theme=Gtk+
ShowDockItem=false
PinnedOnly=false
Alignment=3
ItemsAlignment=3
ZoomEnabled=false
ZoomPercent=140
LockItems=false
PressureReveal=false
PLANKINI

    rm -f "$_pl_dir/launchers/"*.dockitem 2>/dev/null || true
    for _desk in $(_umo_plank_launchers); do
        if [ -f "$UMO_INSTALL_DIR/usr/share/applications/$_desk.desktop" ]; then
            {
                printf '[PlankDockItemPreferences]\n'
                printf 'Launcher=file:///usr/share/applications/%s.desktop\n' "$_desk"
            } > "$_pl_dir/launchers/$_desk.dockitem" 2>/dev/null || true
        fi
    done
    return 0
}

umo_theme_apply_xfce() {
    umo_log_step "Configure XFCE4 Desktop Design"

    _theme_dir="$SCRIPT_DIR/config/theme/xfce4"
    _UI_FONT="$(_umo_theme_ui_font)"
    _MONO_FONT="$(_umo_theme_mono_font)"
    for _home in "$UMO_INSTALL_DIR/root" "$UMO_INSTALL_DIR/home/umo"; do
        [ -d "$_home" ] || continue
        _xf_conf="$_home/.config/xfce4/xfconf/xfce-perchannel-xml"
        umo_fs_mkdir "$_xf_conf"

        if [ -f "$_theme_dir/xsettings.xml.tmpl" ]; then
            umo_fs_render "$_theme_dir/xsettings.xml.tmpl" "$_xf_conf/xsettings.xml" \
                "GTK_THEME" "$_GTK_THEME" \
                "ICON_THEME" "$_ICON_THEME" \
                "CURSOR_THEME" "$_CURSOR_THEME" \
                "UI_FONT" "$_UI_FONT" \
                "MONO_FONT" "$_MONO_FONT"
        fi
        if [ -f "$_theme_dir/xfwm4.xml.tmpl" ]; then
            umo_fs_render "$_theme_dir/xfwm4.xml.tmpl" "$_xf_conf/xfwm4.xml" \
                "GTK_THEME" "$_GTK_THEME" \
                "UI_FONT" "$_UI_FONT"
        fi
        if [ -f "$_theme_dir/xfce4-panel.xml" ]; then
            cp -f "$_theme_dir/xfce4-panel.xml" "$_xf_conf/"
        fi
        if [ -f "$_theme_dir/xfce4-desktop.xml" ]; then
            cp -f "$_theme_dir/xfce4-desktop.xml" "$_xf_conf/"
        fi
        if [ -f "$_theme_dir/terminalrc.tmpl" ]; then
            mkdir -p "$_home/.config/xfce4/terminal"
            umo_fs_render "$_theme_dir/terminalrc.tmpl" "$_home/.config/xfce4/terminal/terminalrc" \
                "TERMINAL_FONT" "$(_umo_theme_terminal_font)"
        fi
        rm -f "$_home/.config/xfce4/panel/panels.xml" 2>/dev/null || true

        _autostart_dir="$_home/.config/autostart"
        if mkdir -p "$_autostart_dir" 2>/dev/null; then
            cat > "$_autostart_dir/plank.desktop" << 'PLANKDESK'
[Desktop Entry]
Type=Application
Name=Plank
Comment=Dock
Exec=plank
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
PLANKDESK
        fi

        _umo_theme_apply_plank "$_home"
    done

    _xdg_autostart="${UMO_INSTALL_DIR}/etc/xdg/autostart"
    if mkdir -p "$_xdg_autostart" 2>/dev/null; then
        cat > "$_xdg_autostart/plank.desktop" << 'PLANKDESK'
[Desktop Entry]
Type=Application
Name=Plank
Comment=Dock
Exec=plank
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
PLANKDESK
    fi

    _pp_src="$SCRIPT_DIR/config/theme/plank/dock.theme"
    if [ -f "$_pp_src" ]; then
        _pp_done=0
        for _pp_theme in Orchis-Dark-Compact Orchis-Light-Compact Materia-dark Materia-light; do
            if [ -d "$UMO_INSTALL_DIR/usr/share/themes/$_pp_theme" ]; then
                mkdir -p "$UMO_INSTALL_DIR/usr/share/themes/$_pp_theme/plank" 2>/dev/null || continue
                cp -f "$_pp_src" "$UMO_INSTALL_DIR/usr/share/themes/$_pp_theme/plank/dock.theme" 2>/dev/null || continue
                _pp_done=1
            fi
        done
        if [ "$_pp_done" = 1 ]; then
            umo_log_ok "Plank Dock Theme Installed"
        else
            umo_log_info "Plank Dock Theme Skipped (No GTK Theme Directory Found Yet)"
        fi
    fi

    if [ -d "${UMO_INSTALL_DIR}/usr/local/bin" ] || mkdir -p "${UMO_INSTALL_DIR}/usr/local/bin" 2>/dev/null; then
        if [ -f "$_theme_dir/umo-desktop-init" ]; then
            cp -f "$_theme_dir/umo-desktop-init" "${UMO_INSTALL_DIR}/usr/local/bin/umo-desktop-init" 2>/dev/null || true
            chmod +x "${UMO_INSTALL_DIR}/usr/local/bin/umo-desktop-init" 2>/dev/null || true
        fi
    fi

    _wm_defaults_dir="${UMO_INSTALL_DIR}/etc/xdg/xfce4/whiskermenu"
    if mkdir -p "$_wm_defaults_dir" 2>/dev/null; then
        printf 'button-icon=/usr/share/umo/brand/umo.png\n' \
            > "$_wm_defaults_dir/defaults.rc" 2>/dev/null || true
    fi

    _umo_share_dir="${UMO_INSTALL_DIR}/usr/share/umo"
    if mkdir -p "$_umo_share_dir" 2>/dev/null; then
        if [ -f "$_theme_dir/xfce4-panel.xml" ]; then
            cp -f "$_theme_dir/xfce4-panel.xml" "$_umo_share_dir/xfce4-panel.xml" 2>/dev/null || true
        fi
    fi

    umo_log_ok "XFCE4 Design Applied"
}

umo_theme_apply_lxde() {
    umo_log_step "Configure LXDE Desktop Design"

    _theme_dir="$SCRIPT_DIR/config/theme/lxde"
    _UI_FONT="$(_umo_theme_ui_font)"
    _MONO_FONT="$(_umo_theme_mono_font)"

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
                "UI_FONT" "$_UI_FONT" \
                "MONO_FONT" "$_MONO_FONT" \
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

    umo_log_ok "LXDE Design Applied"
}

umo_theme_apply_openbox() {
    umo_log_step "Configure Openbox Desktop Design"

    _theme_dir="$SCRIPT_DIR/config/theme/openbox"
    _UI_FONT="$(_umo_theme_ui_font)"
    _MONO_FONT="$(_umo_theme_mono_font)"

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
                "ACCENT" "$_ACCENT" \
                "UI_FONT" "$_UI_FONT" \
                "MONO_FONT" "$_MONO_FONT"
        fi
    done

    umo_log_ok "Openbox Design Applied"
}

umo_theme_fix_ownership() {
    if [ -d "$UMO_INSTALL_DIR/home/umo" ]; then
        chown -R 1000:1000 "$UMO_INSTALL_DIR/home/umo/.config" 2>/dev/null || true
        chown -R 1000:1000 "$UMO_INSTALL_DIR/home/umo/.gtkrc-2.0" 2>/dev/null || true
    fi
}

umo_theme_apply_brand_icon() {
    _bi_src_dir="$SCRIPT_DIR/config/theme/icons"
    [ -d "$_bi_src_dir" ] || return 0

    _bi_hicolor="$UMO_INSTALL_DIR/usr/share/icons/hicolor"
    if [ -f "$_bi_src_dir/umo.svg" ]; then
        mkdir -p "$_bi_hicolor/scalable/apps" 2>/dev/null || true
        cp -f "$_bi_src_dir/umo.svg" "$_bi_hicolor/scalable/apps/umo.svg" 2>/dev/null || true
    fi
    for _bi_size in 48 64 96 128 256; do
        [ -f "$_bi_src_dir/umo-$_bi_size.png" ] || continue
        mkdir -p "$_bi_hicolor/${_bi_size}x${_bi_size}/apps" 2>/dev/null || true
        cp -f "$_bi_src_dir/umo-$_bi_size.png" "$_bi_hicolor/${_bi_size}x${_bi_size}/apps/umo.png" 2>/dev/null || true
    done
    if [ ! -f "$_bi_hicolor/index.theme" ]; then
        {
            printf '[Icon Theme]\n'
            printf 'Name=Hicolor\n'
            printf 'Comment=Fallback theme\n'
            printf 'Directories=48x48/apps,64x64/apps,96x96/apps,128x128/apps,256x256/apps,scalable/apps\n'
            printf '\n'
            for _bi_size in 48 64 96 128 256; do
                printf '[%sx%s/apps]\n' "$_bi_size" "$_bi_size"
                printf 'Size=%s\n' "$_bi_size"
                printf 'Context=Applications\n'
                printf 'Type=Fixed\n'
                printf '\n'
            done
            printf '[scalable/apps]\n'
            printf 'Size=48\n'
            printf 'Context=Applications\n'
            printf 'MinSize=16\n'
            printf 'MaxSize=512\n'
            printf 'Type=Scalable\n'
        } > "$_bi_hicolor/index.theme" 2>/dev/null || true
    fi

    if [ -f "$_bi_src_dir/umo-256.png" ]; then
        mkdir -p "$UMO_INSTALL_DIR/usr/share/umo/brand" 2>/dev/null || true
        cp -f "$_bi_src_dir/umo-256.png" "$UMO_INSTALL_DIR/usr/share/umo/brand/umo.png" 2>/dev/null || true
    fi

    if [ -f "$_bi_hicolor/scalable/apps/umo.svg" ] || [ -f "$UMO_INSTALL_DIR/usr/share/umo/brand/umo.png" ]; then
        umo_log_ok "UMO Brand Icon Installed (hicolor + /usr/share/umo/brand/umo.png)"
    fi
    return 0
}

_umo_theme_apply_local() {
    umo_theme_apply_fonts || true
    umo_theme_apply_wallpaper || true
    umo_theme_apply_brand_icon || true

    if [ "$UMO_DE" != "minimal" ]; then
        umo_theme_apply_gtk || true
    fi

    case "$UMO_DE" in
        xfce4|xfce) umo_theme_apply_xfce || true ;;
        lxde)       umo_theme_apply_lxde || true ;;
        openbox)    umo_theme_apply_openbox || true ;;
    esac

    umo_theme_apply_fastfetch || true
    umo_theme_fix_ownership || true
    return 0
}

umo_theme_reapply_config() {
    [ "$UMO_THEME" = "none" ] && { umo_log_info "Theme Disabled."; return 0; }
    umo_log_step "Re-Apply UMO Desktop Design ($UMO_THEME)"

    _umo_theme_mode_setup
    umo_theme_write_mode_marker
    umo_theme_extras || true
    _umo_theme_apply_local

    umo_log_ok "Desktop Design Re-Applied"
    return 0
}

umo_theme_setup() {
    [ "$UMO_THEME" = "none" ] && { umo_log_info "Theme Disabled."; return 0; }
    umo_log_step "Apply UMO Desktop Theme ($UMO_THEME)"

    _umo_theme_mode_setup
    umo_theme_write_mode_marker

    umo_theme_packages || true
    umo_theme_extras || true
    _umo_theme_apply_local

    umo_log_ok "Desktop Theme Applied"
    return 0
}

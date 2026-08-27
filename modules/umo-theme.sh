#!/bin/sh
# UMO - Module: Design System and Theme Modes (sourced) (GPL-3.0-or-later)
# https://github.com/shadow-x78/ubuntu-modded-optimized

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

    cat > "${UMO_INSTALL_DIR:?}/root/install-theme.sh" << INNER
#!/bin/sh
export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C
export LANG=C
[ -t 0 ] && exec </dev/null
# papirus-icon-theme was replaced by the Tela designer extras; it unpacked
# ~120k tiny SVG files which take an hour or more inside proot.
if dpkg -l papirus-icon-theme 2>/dev/null | grep -q '^ii'; then
    timeout 600 apt-get remove -y papirus-icon-theme 2>/dev/null || true
fi
timeout 600 apt-get install -y --no-install-recommends $_theme_pkgs || true
timeout 120 apt-get install -y exo-utils 2>/dev/null || true
dpkg --configure -a || true
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
        # Fall back to themes that are guaranteed to exist (installed with the
        # theme packages) so the desktop never points at missing theme dirs.
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

# Base names of the .desktop files pinned to the Plank dock, based on the
# selected application set (only entries actually installed get pinned).
_umo_plank_launchers() {
    printf '%s\n' thunar xfce4-terminal org.gnome.Epiphany mousepad
    case "${UMO_APP_SET:-basic}" in
        media)   printf '%s\n' vlc gimp ;;
        office)  printf '%s\n' libreoffice-startcenter atril ;;
        browser) printf '%s\n' org.gnome.Epiphany ;;
        full)    printf '%s\n' vlc gimp libreoffice-startcenter atril org.gnome.Epiphany ;;
        dev|basic|*) : ;;
    esac
    return 0
}

# Write the Plank dock configuration for one home dir: dark theme-consistent
# dock (Theme=Gtk+ inherits the applied GTK theme) at the bottom, plus the
# default launchers for the selected app set.
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

        # Plank bottom dock - autostarted by xfce4-session (the VNC xstartup
        # execs startxfce4, so plank must come from the session autostart).
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

        # Dock theme + default launchers for the selected application set.
        _umo_theme_apply_plank "$_home"
    done

    # System-wide autostart fallback (covers accounts without the user entry).
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

    # Plank dock theme: the dock runs with Theme=Gtk+, which plank resolves
    # to a plank/ folder inside the ACTIVE GTK theme. The Orchis installer
    # never ships its own plank theme (it carries one in its source), so
    # without this copy plank falls back to its built-in square Default
    # theme. Install the rounded UMO/Orchis dock.theme under every GTK
    # theme the design may activate, including the Materia fallbacks.
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
            umo_log_ok "Plank Dock Theme Installed (Rounded)"
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

# Cheap local design application (fonts, wallpaper, GTK, DE layout, fastfetch,
# ownership). Safe to re-run on every update - no apt, no downloads.
# Callers must run _umo_theme_mode_setup and umo_theme_extras first so
# _GTK_THEME/_ICON_THEME reflect availability fallbacks.
_umo_theme_apply_local() {
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

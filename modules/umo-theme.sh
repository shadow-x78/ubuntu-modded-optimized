#!/bin/sh
# UMO — Desktop Theme Engine (MIT License)
# https://github.com/Shadow-x78/termux-ubuntu-umo

[ -z "${_UMO_MOD_THEME_LOADED:-}" ] || return 0
_UMO_MOD_THEME_LOADED=1

. "${UMO_LIB_DIR:-./lib}/core-ansi.sh"
. "${UMO_LIB_DIR:-./lib}/core-fs.sh"

UMO_THEME="${UMO_THEME:-umo-dark}"

umo_theme_install_packages() {
    umo_log_step "Installing theme packages"

    _theme_pkgs="papirus-icon-theme fonts-inter fonts-noto fonts-noto-core"
    _theme_pkgs="$_theme_pkgs fonts-jetbrains-mono xfonts-terminus"

    cat > "${UMO_INSTALL_DIR:?}/root/install-theme.sh" << INNER
#!/bin/sh
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -q $_theme_pkgs 2>/dev/null || true
dpkg --configure -a || true
INNER
    chmod +x "$UMO_INSTALL_DIR/root/install-theme.sh"
    umo_run_quiet "Installing theme packages" "$HOME/umo-login.sh" -c "bash /root/install-theme.sh"

    if ! "$HOME/umo-login.sh" -c "dpkg -l | grep -q orchis" 2>/dev/null; then
        umo_log_step "Downloading Orchis theme"
        umo_run_quiet "Downloading Orchis theme" "$HOME/umo-login.sh" -c "
            wget -q 'https://github.com/vinceliuice/Orchis-theme/archive/refs/tags/2024-09-20.tar.gz' -O /root/orchis.tar.gz 2>/dev/null && \\
            tar xzf /root/orchis.tar.gz -C /root/ && \\
            cd /root/Orchis-theme-* && \\
            ./install.sh -t default -c dark --tweaks solid 2>/dev/null; \\
            rm -rf /root/orchis* /root/Orchis*
        " || umo_log_warn "Orchis theme download failed (non-critical)."
    fi

    rm -f "$UMO_INSTALL_DIR/root/install-theme.sh"
    umo_log_ok "Theme packages installed."
}

umo_theme_apply_gtk() {
    umo_log_step "Applying GTK theme configuration"

    _theme_dir="$SCRIPT_DIR/config/theme"

    for _home in "$UMO_INSTALL_DIR/root" "$UMO_INSTALL_DIR/home/umo"; do
        [ -d "$_home" ] || continue
        umo_fs_mkdir "$_home/.config/gtk-3.0"
        if [ -f "$_theme_dir/gtk-3.0/settings.ini" ]; then
            cp -f "$_theme_dir/gtk-3.0/settings.ini" "$_home/.config/gtk-3.0/"
        fi
        if [ -f "$_theme_dir/gtk-2.0/gtkrc" ]; then
            cp -f "$_theme_dir/gtk-2.0/gtkrc" "$_home/.gtkrc-2.0"
        fi
    done

    _xfce_conf="$UMO_INSTALL_DIR/root/.config/xfce4/xfconf/xfce-perchannel-xml"
    umo_fs_mkdir "$_xfce_conf"
    if [ -f "$_theme_dir/xsettings.xml" ]; then
        cp -f "$_theme_dir/xsettings.xml" "$_xfce_conf/"
    fi
    if [ -f "$_theme_dir/xfwm4/xfwm4.xml" ]; then
        cp -f "$_theme_dir/xfwm4/xfwm4.xml" "$_xfce_conf/"
    fi

    chown -R 1000:1000 "$UMO_INSTALL_DIR/home/umo/.config" 2>/dev/null || true
    chown -R 1000:1000 "$UMO_INSTALL_DIR/home/umo/.gtkrc-2.0" 2>/dev/null || true

    umo_log_ok "GTK configuration applied."
}

umo_theme_apply_icons() {
    umo_log_step "Configuring icon theme"

    _xfce_conf="$UMO_INSTALL_DIR/root/.config/xfce4/xfconf/xfce-perchannel-xml"
    umo_fs_mkdir "$_xfce_conf"

    if [ -f "$_xfce_conf/xsettings.xml" ]; then
        sed -i 's|IconThemeName.*|IconThemeName" type="string" value="Papirus-Dark"/>|' "$_xfce_conf/xsettings.xml" 2>/dev/null || true
    fi

    umo_log_ok "Icon theme set to Papirus-Dark."
}

umo_theme_apply_fonts() {
    umo_log_step "Configuring fonts"

    _fc_dir="$UMO_INSTALL_DIR/etc/fonts/conf.d"
    umo_fs_mkdir "$_fc_dir"
    if [ -f "$SCRIPT_DIR/config/theme/fontconfig/01-umo-fonts.conf" ]; then
        cp -f "$SCRIPT_DIR/config/theme/fontconfig/01-umo-fonts.conf" "$_fc_dir/"
    fi

    umo_log_ok "Font configuration applied."
}

umo_theme_apply_panel() {
    umo_log_step "Configuring XFCE panel layout"

    _panel_dir="$UMO_INSTALL_DIR/root/.config/xfce4/xfconf/xfce-perchannel-xml"
    umo_fs_mkdir "$_panel_dir"
    if [ -f "$SCRIPT_DIR/config/theme/xfce4-panel.xml" ]; then
        cp -f "$SCRIPT_DIR/config/theme/xfce4-panel.xml" "$_panel_dir/"
    fi

    rm -f "$UMO_INSTALL_DIR/root/.config/xfce4/panel/panels.xml" 2>/dev/null || true

    umo_log_ok "Panel layout applied."
}

umo_theme_apply_wallpaper() {
    umo_log_step "Setting wallpaper"

    _wp_src="$SCRIPT_DIR/config/theme/wallpaper/umo-wallpaper.jpg"
    _wp_dir="$UMO_INSTALL_DIR/usr/share/wallpapers"
    _wp_dst="$_wp_dir/umo-wallpaper.jpg"

    if [ -f "$_wp_src" ]; then
        umo_fs_mkdir "$_wp_dir"
        cp -f "$_wp_src" "$_wp_dst"

        _xfce_props="$UMO_INSTALL_DIR/root/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml"
        umo_fs_mkdir "$(dirname "$_xfce_props")"
        if [ -f "$_xfce_props" ]; then
            sed -i 's|last-image.*|last-image" type="string" value="/usr/share/wallpapers/umo-wallpaper.jpg"/>|' "$_xfce_props" 2>/dev/null || true
        fi
    else
        umo_log_info "No wallpaper file found, skipping."
    fi
}

umo_theme_setup() {
    [ "$UMO_THEME" = "none" ] && { umo_log_info "Theme disabled."; return 0; }
    umo_log_step "Applying UMO Desktop Theme ($UMO_THEME)"

    umo_theme_install_packages
    umo_theme_apply_gtk
    umo_theme_apply_icons
    umo_theme_apply_fonts
    if [ "$UMO_DE" = "xfce4" ] || [ "$UMO_DE" = "xfce" ]; then
        umo_theme_apply_panel
        umo_theme_apply_wallpaper
    fi

    umo_log_ok "Desktop theme applied."
}

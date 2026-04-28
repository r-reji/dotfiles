TODO:
- fix the cloning/git submodule for the alacritty themes

For updating gnome themes in ubuntu 24.04:

- install themes with the install.py script
- sudo apt install gnome-shell-extension-manager
- launch extension manager and install User Themes
- set the theme inside Gnome Tweaks > Appearance > Shell
- copy theme files to ~/.config/gtk-4.0/
- mkdir -p ~/.config/gtk-4.0
- cp -r ~/.themes/<Theme Folder>/gtk-4.0/assets ~/.config/gtk-4.0/
- cp ~/.themes/<Theme Folder>/gtk-4.0/gtk.css ~/.config/gtk-4.0/- 
- cp ~/.themes/<Theme Folder>/gtk-4.0/gtk-dark.css ~/.config/gtk-4.0/


Removing GDM logos: (no idea how to force a new bg image yet)

- sudo apt install dbus-x11
- sudo -Hu gdm dbus-launch gsettings set org.gnome.login-screen logo ''
- sudo -Hu gdm dbus-launch gsettings set org.gnome.login-screen fallback-logo ''

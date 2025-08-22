#!/usr/bin/env bash
# apply-catppuccin.sh
# Applique Catppuccin (Waybar, Alacritty, GTK settings) sur Arch + Sway.
# Usage: ./apply-catppuccin.sh [--no-aur] [--no-restart]
set -euo pipefail

NO_AUR=0
NO_RESTART=0
for a in "$@"; do
  case "$a" in
    --no-aur) NO_AUR=1 ;;
    --no-restart) NO_RESTART=1 ;;
  esac
done

echoinfo(){ echo -e "\n[INFO] $1"; }
echoerr(){ echo -e "\n[ERROR] $1" >&2; }

# 1) Vérif connexion réseau rapide
echoinfo "Vérification de la connexion réseau (ping 1.1.1.1)..."
if ! ping -c1 -W2 1.1.1.1 >/dev/null 2>&1; then
  echoerr "Aucune connexion détectée. Active l'USB tethering, branche Ethernet, ou reconnecte-toi à Internet puis relance."
  exit 1
fi
echoinfo "Connexion OK."

# 2) Installer paquets de base (pacman)
echoinfo "Installation des paquets de base nécessaires (git, papirus-icon-theme, lxappearance)..."
sudo pacman -Syu --needed --noconfirm git papirus-icon-theme lxappearance

# 3) (Optionnel) installer yay si AUR désiré
if [ "$NO_AUR" -eq 0 ]; then
  if ! command -v yay >/dev/null 2>&1; then
    echoinfo "Installation de yay (AUR helper)..."
    tmpd=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmpd"/yay
    pushd "$tmpd"/yay >/dev/null
    makepkg -si --noconfirm
    popd >/dev/null
    rm -rf "$tmpd"
  fi

  echoinfo "Tentative d'installation via AUR : catppuccin GTK / curseurs / papirus-folders (si disponibles)..."
  # tolérant : si un paquet n'existe pas, on continue
  yay -S --noconfirm catppuccin-gtk-theme-mocha catppuccin-cursors-mocha papirus-folders-catppuccin-git || echoinfo "Au moins un paquet AUR n'a pas été installé (possible non dispo)."
else
  echoinfo "--no-aur passé : on n'installera pas les paquets AUR."
fi

# 4) Cloner et copier Waybar + Alacritty theme (repos officiels)
echoinfo "Clonage des repos Catppuccin (Waybar & Alacritty) et copie des thèmes (mocha)..."
TMP="/tmp/catpp-${RANDOM}"
mkdir -p "$TMP"
git -c advice.detachedHead=false clone --depth 1 https://github.com/catppuccin/waybar.git "$TMP"/waybar || true
git -c advice.detachedHead=false clone --depth 1 https://github.com/catppuccin/alacritty.git "$TMP"/alacritty || true

mkdir -p ~/.config/waybar ~/.config/alacritty/themes

# copier mocha.css si présent
if [ -f "$TMP/waybar/mocha.css" ]; then
  cp -n "$TMP/waybar/mocha.css" ~/.config/waybar/catppuccin-mocha.css
  echoinfo "copié: ~/.config/waybar/catppuccin-mocha.css"
else
  echoinfo "waybar mocha.css non trouvé dans le repo (pas grave)."
fi

# copier alacritty mocha theme si présent
if [ -f "$TMP/alacritty/mocha/alacritty-mocha.yml" ]; then
  cp -n "$TMP/alacritty/mocha/alacritty-mocha.yml" ~/.config/alacritty/themes/catppuccin-mocha.yml
  echoinfo "copié: ~/.config/alacritty/themes/catppuccin-mocha.yml"
else
  echoinfo "alacritty mocha theme non trouvé dans le repo (pas grave)."
fi

# cleanup tmp
rm -rf "$TMP"

# 5) Écrire/forcer les settings GTK (GTK3 + GTK4)
echoinfo "Écriture des settings GTK (GTK3 & GTK4) -> Catppuccin-Mocha (si installé)."
mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0
cat > ~/.config/gtk-3.0/settings.ini <<'EOF'
[Settings]
gtk-theme-name = Catppuccin-Mocha
gtk-icon-theme-name = Papirus
gtk-font-name = Noto Sans 10
EOF
cp -f ~/.config/gtk-3.0/settings.ini ~/.config/gtk-4.0/settings.ini
echoinfo "Fichiers GTK écrits dans ~/.config/gtk-3.0 et gtk-4.0 (si thème installé, il sera pris)."

# 6) S'assurer que waybar importe le css catppuccin
echoinfo "Ajout d'un import dans ~/.config/waybar/style.css (si absent)."
mkdir -p ~/.config/waybar
STYLEFILE=~/.config/waybar/style.css
if ! grep -Fq "catppuccin-mocha.css" "$STYLEFILE" 2>/dev/null; then
  # préfixer l'import si le fichier existe déjà
  echo '@import "catppuccin-mocha.css";' | cat - "$STYLEFILE" 2>/dev/null > "$STYLEFILE.tmp" || echo '@import "catppuccin-mocha.css";' > "$STYLEFILE.tmp"
  mv "$STYLEFILE.tmp" "$STYLEFILE"
  echoinfo "Import ajouté à $STYLEFILE"
else
  echoinfo "Import catppuccin déjà présent dans $STYLEFILE"
fi

# 7) Appliquer papirus-folders si disponible
if command -v papirus-folders >/dev/null 2>&1; then
  echoinfo "Application papirus-folders -C mocha (si disponible)..."
  papirus-folders -C mocha || echoinfo "papirus-folders a échoué (pas grave)."
else
  echoinfo "papirus-folders absent (pas installé ou pas d'AUR)."
fi

# 8) Restart Waybar (sans tuer le reste)
echoinfo "Relance de Waybar..."
pkill -9 waybar 2>/dev/null || true
# lancer en arrière-plan (ne bloque pas)
nohup waybar >/dev/null 2>&1 & disown || echoinfo "Impossible de démarrer waybar en background (lancer manuellement)."

# 9) Tenter de recharger Sway (si on est dans Sway)
if [ "$NO_RESTART" -eq 0 ]; then
  if [ -n "${SWAYSOCK-}" ]; then
    echoinfo "Socket Sway détectée (session graphique) : tentative de reload..."
    if swaymsg reload 2>/dev/null; then
      echoinfo "swaymsg reload OK."
    else
      echoinfo "reload échoué. Tentative de restart..."
      swaymsg restart 2>/dev/null || echoinfo "Impossible de restart sway depuis ce contexte."
    fi
  else
    echoinfo "Aucun socket Sway (variable SWAYSOCK non définie). Si tu es dans Sway, ouvre un terminal depuis Sway puis fais 'swaymsg reload'. Sinon : reconnecte-toi/relance LightDM pour appliquer les changements."
  fi
else
  echoinfo "--no-restart : pas de tentative de reload/restart."
fi

# 10) Permissions & message final
chmod 600 ~/.config/gtk-3.0/settings.ini || true
echoinfo "Terminé — Catppuccin (Waybar/Alacritty/GTK settings) appliqué (ou prêt à l'être)."

cat <<'EOF'

Prochaines étapes recommandées (à faire si tout ne ressemble pas encore à Catppuccin) :
 - Lance 'lxappearance' pour choisir manuellement le thème Catppuccin-Mocha et l'icône Papirus.
 - Si les curseurs ou icônes ne changent pas, fais une reconnexion de session (logout/login) ou redémarre LightDM :
     sudo systemctl restart lightdm
 - Pour vérifier l'installation AUR: pacman -Qs catppuccin
 - Si Waybar n'affiche pas le style, ouvre ~/.config/waybar/style.css et assure-toi que la ligne '@import "catppuccin-mocha.css";' est en première ligne, puis relance waybar.

Si tu veux, colle ici la sortie de :
  ls -l ~/.config/waybar ~/.config/alacritty/themes /usr/share/themes /usr/share/icons
ou lance 'lxappearance' puis dis-moi ce que tu vois, et je t'aide à finaliser.

EOF

exit 0
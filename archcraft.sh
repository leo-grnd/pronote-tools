cat > /tmp/archcraft_flash.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

echo "=== Archcraft USB writer (TTY) ==="
echo

# Vérifier root
if [ "$EUID" -ne 0 ]; then
  echo "Tu dois lancer ce script en root (sudo)."
  exit 1
fi

# Vérifier outils
for cmd in curl grep sha256sum dd lsblk umount; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Le binaire $cmd manque — installe-le avant (ex: sudo pacman -S $cmd)"
  fi
done

WORKDIR="/tmp/archcraft_usb"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

# URLs fixes (Archcraft v25.07 - 12 juillet 2025)
ISO_URL="https://sourceforge.net/projects/archcraft/files/v25.07/archcraft-2025.07.12-x86_64.iso/download"
SHA_URL="https://sourceforge.net/projects/archcraft/files/v25.07/archcraft-2025.07.12-x86_64.iso.sha256sum/download"
SIG_URL="https://sourceforge.net/projects/archcraft/files/v25.07/archcraft-2025.07.12-x86_64.iso.sig/download"

echo "- Téléchargement de l'ISO..."
curl -L --fail --progress-bar -o archcraft.iso "$ISO_URL"

echo "- Téléchargement du fichier SHA256..."
curl -L --fail --progress-bar -o archcraft.sha256sum "$SHA_URL" || true

echo "- Téléchargement de la signature GPG..."
curl -L --fail --progress-bar -o archcraft.iso.sig "$SIG_URL" || true

echo
echo "- Vérification sha256..."
if [ -f archcraft.sha256sum ]; then
  if sha256sum -c archcraft.sha256sum 2>/dev/null; then
    echo "Checksum OK."
  else
    echo "Checksum mismatch ! Vérifie l'ISO."
    read -rp "Continuer quand même ? (o/N) : " yn
    if [[ ! $yn =~ ^[oO] ]]; then exit 1; fi
  fi
fi

if [ -f archcraft.iso.sig ]; then
  echo "- Vérification GPG..."
  if command -v gpg >/dev/null 2>&1; then
    gpg --verify archcraft.iso.sig archcraft.iso || {
      echo "Signature invalide ou clé manquante."
      read -rp "Continuer quand même ? (o/N) : " yn
      if [[ ! $yn =~ ^[oO] ]]; then exit 1; fi
    }
  else
    echo "gpg non installé, impossible de vérifier."
  fi
fi

echo
echo "=== PRÉPARATION DU FLASH ==="
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT,LABEL,MODEL
echo
echo "ATTENTION : choisis le device COMPLET (ex: /dev/sdb) et PAS une partition (ex: /dev/sdb1)."
read -rp "Device cible pour écrire l'ISO (ex: /dev/sdb) : " TARGET
if [ -z "$TARGET" ] || [ ! -b "$TARGET" ]; then
  echo "Device invalide."
  exit 1
fi

echo "Écriture de archcraft.iso sur $TARGET..."
umount "${TARGET}"* 2>/dev/null || true
dd if=archcraft.iso of="$TARGET" bs=4M status=progress oflag=sync
sync
echo "Clé prête !"
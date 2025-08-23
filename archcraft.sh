cat > /tmp/archcraft_flash.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

echo "=== Archcraft USB writer (TTY) ==="
echo

# Check root
if [ "$EUID" -ne 0 ]; then
  echo "Tu dois lancer ce script en root (sudo)."
  exit 1
fi

# Ensure required tools
for cmd in curl grep sed sha256sum dd lsblk umount; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Le binaire $cmd manque — installe-le avant (ex: sudo pacman -S $cmd)"
  fi
done

WORKDIR="/tmp/archcraft_usb"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

# Try to auto-detect ISO URL from archcraft site
echo "- Recherche automatique de l'URL de l'ISO sur archcraft.io..."
ISO_URL=$(curl -fsL https://archcraft.io/download.html 2>/dev/null \
  | grep -oE 'https?://[^"'\'' ]*archcraft[^"'\'' ]*\.iso' \
  | head -n1 || true)

if [ -z "$ISO_URL" ]; then
  echo "  → Échec de la détection automatique."
  read -rp "Colle l'URL complète de l'ISO Archcraft (ou laisse vide pour annuler) : " ISO_URL
  if [ -z "$ISO_URL" ]; then
    echo "Annulé."
    exit 1
  fi
else
  echo "  → ISO détectée : $ISO_URL"
fi

ISO_FILE="archcraft.iso"
echo
echo "- Téléchargement de l'ISO..."
curl -L --fail --progress-bar -o "$ISO_FILE" "$ISO_URL"

echo
# Try to find a matching checksum file (common extensions)
echo "- Recherche d'une .sha256 / .sha256sum associée..."
SHA_URL=$(curl -fsL https://archcraft.io/download.html 2>/dev/null \
  | grep -oE 'https?://[^"'\'' ]*archcraft[^"'\'' ]*\.(sha256|sha256sum|sha256.txt|sha256sum.txt)' \
  | head -n1 || true)

if [ -n "$SHA_URL" ]; then
  echo "  → Téléchargement de : $SHA_URL"
  curl -L --fail --progress-bar -o archcraft.sha256 "$SHA_URL" || true
fi

# also try ISO.sig
SIG_URL=$(curl -fsL https://archcraft.io/download.html 2>/dev/null \
  | grep -oE 'https?://[^"'\'' ]*archcraft[^"'\'' ]*\.iso\.sig' \
  | head -n1 || true)
if [ -n "$SIG_URL" ]; then
  echo "  → Téléchargement de signature : $SIG_URL"
  curl -L --fail --progress-bar -o archcraft.iso.sig "$SIG_URL" || true
fi

echo
echo "- Vérification sha256 (si fournie)..."
if [ -f archcraft.sha256 ]; then
  # Try to adapt format if necessary
  # If the file contains just a checksum, compare directly
  if grep -qE '^[0-9a-f]{64}\s+' archcraft.sha256; then
    # standard sha256sum file with filename
    if sha256sum -c archcraft.sha256 2>/dev/null; then
      echo "Checksum OK."
    else
      echo "Checksum fournie mais mismatch. Vérifie l'ISO."
      read -rp "Continuer quand même ? (o/N) : " yn
      if [[ ! $yn =~ ^[oO] ]]; then exit 1; fi
    fi
  else
    # maybe file only contains the checksum
    CALC=$(sha256sum "$ISO_FILE" | awk '{print $1}')
    GIVEN=$(tr -d ' \t\r\n' < archcraft.sha256)
    if [ "$CALC" = "$GIVEN" ]; then
      echo "Checksum OK."
    else
      echo "Checksum mismatch. Calculee: $CALC ; fournie: $GIVEN"
      read -rp "Continuer quand même ? (o/N) : " yn
      if [[ ! $yn =~ ^[oO] ]]; then exit 1; fi
    fi
  fi
else
  echo "  → Pas de fichier sha256 trouvé automatiquement."
fi

echo
if [ -f archcraft.iso.sig ]; then
  echo "- Une signature GPG (.sig) a été trouvée. Vérification (gpg --verify)..."
  if command -v gpg >/dev/null 2>&1; then
    if gpg --verify archcraft.iso.sig "$ISO_FILE" 2>&1 | sed -n '1,6p'; then
      echo "Si une clé publique manque, gpg indiquera l'ID de clé à importer."
    else
      echo "La vérification gpg a échoué ou la clé manque. Tu peux importer la clé publique du mainteneur et réessayer."
      echo "Exemple: gpg --recv-keys <KEYID>"
      read -rp "Continuer quand même ? (o/N) : " yn
      if [[ ! $yn =~ ^[oO] ]]; then exit 1; fi
    fi
  else
    echo "  → gpg non installé, impossible de vérifier la signature."
    read -rp "Continuer sans vérif GPG ? (o/N) : " yn
    if [[ ! $yn =~ ^[oO] ]]; then exit 1; fi
  fi
fi

echo
echo "=== PRÉPARATION DU FLASH ==="
echo "Liste des disques (vérifie lequel est ta clé USB) :"
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT,LABEL,MODEL
echo
echo "ATTENTION : choisis le device COMPLET (ex: /dev/sdb) et PAS une partition (ex: /dev/sdb1)."
read -rp "Device cible pour écrire l'ISO (ex: /dev/sdb) : " TARGET
if [ -z "$TARGET" ]; then
  echo "Aucun device fourni — annulation."
  exit 1
fi
if [ ! -b "$TARGET" ]; then
  echo "$TARGET n'existe pas ou n'est pas un block device. Vérifie et relance."
  exit 1
fi

echo
echo "DEMANDE DE CONFIRMATION FINALE:"
echo "Tu t'apprêtes à écrire $ISO_FILE sur $TARGET — tout le contenu de ce périphérique sera détruit."
read -rp "Confirmer (taper oui) : " CONF
if [ "$CONF" != "oui" ]; then
  echo "Abandon."
  exit 1
fi

# Unmount any mounted partitions on target
echo "- Démontage des partitions montées sur $TARGET..."
set +e
umount "${TARGET}"* 2>/dev/null || true
set -e

# Flash
echo "- Écriture en cours (dd). Ceci peut prendre plusieurs minutes..."
if command -v pv >/dev/null 2>&1; then
  pv "$ISO_FILE" | dd of="$TARGET" bs=4M conv=fsync status=none
else
  dd if="$ISO_FILE" of="$TARGET" bs=4M status=progress oflag=sync
fi

sync
echo "Écriture terminée. Sync effectuée."

# Try to power-off the USB (if udisksctl available)
if command -v udisksctl >/dev/null 2>&1; then
  echo "Tentative d'arrêter le périphérique pour le retirer en toute sécurité..."
  # extract base (e.g., /dev/sdb)
  udisksctl power-off -b "$TARGET" 2>/dev/null || true
fi

echo
echo "==> Terminé. Débranche la clé USB en toute sécurité (ou ferme la session et redémarre sur la clé)."
echo "Si l'ISO ne boote pas, vérifie UEFI/Legacy du PC cible et la checksum."
EOF

chmod +x /tmp/archcraft_flash.sh
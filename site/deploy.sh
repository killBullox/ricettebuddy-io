#!/usr/bin/env bash
# Deploy del sito statico su hosting Aruba via FTP.
# Le credenziali stanno in site/.env (gitignorato) — mai in chiaro nei comandi.
#
# Uso:  bash site/deploy.sh
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$HERE/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERRORE: manca $ENV_FILE — copia .env.example in .env e compila le credenziali." >&2
  exit 1
fi
# shellcheck disable=SC1090
set -a; source "$ENV_FILE"; set +a

: "${FTP_HOST:?manca FTP_HOST in .env}"
: "${FTP_USER:?manca FTP_USER in .env}"
: "${FTP_PASS:?manca FTP_PASS in .env}"
FTP_DIR="${FTP_DIR:-/}"                    # cartella pubblica su Aruba, es. /  oppure /htdocs
FTP_PORT="${FTP_PORT:-21}"

# File da NON caricare.
EXCLUDES=( ".env" ".env.example" "deploy.sh" ".gitignore" )
is_excluded() { local b; b="$(basename "$1")"; for e in "${EXCLUDES[@]}"; do [[ "$b" == "$e" ]] && return 0; done; return 1; }

base="ftp://${FTP_HOST}:${FTP_PORT}"
n=0
while IFS= read -r -d '' f; do
  is_excluded "$f" && continue
  rel="${f#"$HERE"/}"                       # percorso relativo dentro site/
  dest="${base}/${FTP_DIR#/}"; dest="${dest%/}/${rel}"
  echo "  up  $rel"
  curl -sS --ftp-create-dirs -T "$f" --user "${FTP_USER}:${FTP_PASS}" "$dest"
  n=$((n+1))
done < <(find "$HERE" -type f -print0)

echo "✓ Caricati $n file su ${FTP_HOST}/${FTP_DIR}"

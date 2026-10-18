#!/usr/bin/env bash
# init.sh — Scaffold a new governance project from this template
#
# Usage:
#   bash scripts/init.sh my-project
#   bash scripts/init.sh my-project ./output-dir
#
# Copies engine/cloudflare/, renames templates, prompts for DB name/ID/JWT secret.

set -euo pipefail

PROJECT_NAME="${1:-my-governance}"
OUTPUT_DIR="${2:-.}"
TARGET="$OUTPUT_DIR/$PROJECT_NAME"

if [ -d "$TARGET" ]; then
  echo "Error: $TARGET already exists. Remove it or pick a different name."
  exit 1
fi

echo "Scaffolding $TARGET ..."
mkdir -p "$TARGET"
cp -r "$(dirname "$0")/../engine/cloudflare/"* "$TARGET/"
rm -f "$TARGET/package-lock.json"

mv "$TARGET/wrangler.toml.example" "$TARGET/wrangler.toml"
mv "$TARGET/.dev.vars.example" "$TARGET/.dev.vars"

echo
echo "=== Configuration ==="
read -r -p "D1 database name [decentralised-governance]: " DB_NAME
DB_NAME="${DB_NAME:-decentralised-governance}"

read -r -p "D1 database ID (from wrangler d1 create): " DB_ID
if [ -z "$DB_ID" ]; then
  echo "Error: database_id is required."
  exit 1
fi

read -r -s -p "JWT_SECRET (must match your auth worker): " JWT_SECRET
echo
if [ -z "$JWT_SECRET" ]; then
  echo "Error: JWT_SECRET is required."
  exit 1
fi

if [[ "$OSTYPE" == "darwin"* ]]; then
  SED_INPLACE=(-i '')
else
  SED_INPLACE=(-i)
fi

sed "${SED_INPLACE[@]}" "s/REPLACE_WITH_YOUR_DB_NAME/$DB_NAME/g" "$TARGET/wrangler.toml"
sed "${SED_INPLACE[@]}" "s/REPLACE_WITH_YOUR_DATABASE_ID/$DB_ID/g" "$TARGET/wrangler.toml"
sed "${SED_INPLACE[@]}" "s/REPLACE_WITH_YOUR_DB_NAME/$DB_NAME/g" "$TARGET/package.json"

cat > "$TARGET/.dev.vars" <<EOV
JWT_SECRET="$JWT_SECRET"
EOV

echo
echo "Scaffold created at $TARGET"
echo
echo "Next steps:"
echo
echo "  cd $TARGET"
echo "  npm install"
echo "  npx wrangler d1 execute $DB_NAME --remote --file=schema.sql"
echo "  npx wrangler d1 execute $DB_NAME --remote --file=seed-proposals.sql"
echo "  npx wrangler deploy"
echo
echo "Your governance API will be live at https://<your-subdomain>.workers.dev"

#!/usr/bin/env bash
# Update or create the optimize.pot file and any existing .po files

set -euo pipefail

cd "$(dirname "$0")/.."

echo "Extracting strings into po/optimize.pot..."
xgettext --language=Shell \
    --from-code=UTF-8 \
    --keyword=gettext \
    --keyword=eval_gettext \
    --output=po/optimize.pot \
    --package-name=optimize \
    --package-version=1.0.0 \
    --msgid-bugs-address=helton@example.com \
    optimize

echo "Updating existing .po files..."
for po_file in po/*.po; do
    if [[ -f "$po_file" ]]; then
        echo "  Updating $po_file"
        msgmerge --update "$po_file" po/optimize.pot
    fi
done

echo "Done."

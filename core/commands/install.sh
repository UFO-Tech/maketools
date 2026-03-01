APP_DIR=$(pwd)
APP_MAKETOOLS="$APP_DIR/.maketools"
UFO_MAKETOOLS="/ufo-maketools"

if [ -d "$APP_MAKETOOLS" ]; then
  echo "Devtools already initialized"
  exit 0
fi

$UFO_MAKETOOLS/commands/update.sh

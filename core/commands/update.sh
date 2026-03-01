#!/usr/bin/env bash

set -euo pipefail
ESC="$(printf '\033')"

NC="${ESC}[0m"
BOLD="${ESC}[1m"

BLACK="${ESC}[30m"
RED="${ESC}[31m"
GREEN="${ESC}[32m"
YELLOW="${ESC}[33m"
BLUE="${ESC}[34m"
MAGENTA="${ESC}[35m"
CYAN="${ESC}[36m"
WHITE="${ESC}[37m"

GRAY="${ESC}[90m"
BRIGHT_GREEN="${ESC}[92m"

BG_RED="${ESC}[41m"
BG_GREEN="${ESC}[42m"
BG_YELLOW="${ESC}[43m"
BG_BLUE="${ESC}[44m"

APP_DIR=$(pwd)
APP_MAKETOOLS="$APP_DIR/.maketools"
UFO_MAKETOOLS="/ufo-maketools"
CONFIG_FILE="$APP_DIR/Makefile-config.yaml"


printf "%b\n" "${BG_YELLOW}Devtools update started${NC}"

# -------------------------------------------------
# 0. Makefile create
# -------------------------------------------------
printf "%b " "${CYAN}➜ Prepare${NC} ${YELLOW}Makefile${NC}"

if [ -f "$APP_DIR/Makefile" ]; then
  if [ ! -f "$APP_DIR/Makefile.local.mk" ]; then
    mv "$APP_DIR/Makefile" "$APP_DIR/Makefile.local.mk"
  fi
else
  touch "$APP_DIR/Makefile.local.mk"
fi

cp "$UFO_MAKETOOLS/templates/Makefile" "$APP_DIR/Makefile"

if [ ! -f "$APP_DIR/Makefile-config.yaml" ]; then
  cp "$UFO_MAKETOOLS/templates/Makefile-config.yaml" "$APP_DIR/Makefile-config.yaml"
fi

printf -- "- %b\n" "${GREEN}OK${NC}"

# -------------------------------------------------
# 1. Validate config
# -------------------------------------------------
printf "%b " "${CYAN}➜ Validate config${NC}"
if [ ! -f "$CONFIG_FILE" ]; then
  printf -- "- %b\n" "${RED}KO: Makefile-config.yaml not found${NC}"
  exit 1
fi

CONFIG_VERSION=$(yq e -r '.version // ""' "$CONFIG_FILE")

if [ "$CONFIG_VERSION" != "1" ]; then
  printf -- "- %b\n" "${RED}KO: Unsupported Makefile-config.yaml version: $CONFIG_VERSION${NC}"
  exit 1
fi
printf -- "- %b\n" "${GREEN}OK${NC}"

# -------------------------------------------------
# 2. Prepare directory (clean install every time)
# -------------------------------------------------
printf "%b " "${CYAN}➜ Prepare directory${NC}"
rm -rf "$APP_MAKETOOLS"
cp -r "$UFO_MAKETOOLS/.maketools" "$APP_MAKETOOLS"

mkdir -p "$APP_MAKETOOLS/requires"
mkdir -p "$APP_MAKETOOLS/repositories"

printf -- "- %b\n" "${GREEN}OK${NC}"

# -------------------------------------------------
# 3. Clone repositories
# -------------------------------------------------\
TOOLSLIST_FILE="$APP_MAKETOOLS/repositories/toolslist.yaml"
ENVLIST_FILE="$APP_MAKETOOLS/requires/envslist.yaml"
printf "%b\n" "${CYAN}➜ Create${NC} ${YELLOW}toolslist.yaml${NC} - ${GREEN}OK${NC}"
printf "%b\n" "${CYAN}➜ Create${NC} ${YELLOW}envslist.yaml${NC} - ${GREEN}OK${NC}"
printf "%b " "${CYAN}➜ Sync repositories${NC}"

mkdir -p "$APP_MAKETOOLS/repositories"

# Collect repositories safely (do not fail when empty)
mapfile -t REPOS < <(
  yq e -o=json -I=0 '.require // [] | .[]' "$CONFIG_FILE"
)
if [ ${#REPOS[@]} -eq 0 ]; then
  printf -- "- %b\n" "${GRAY}No require defined${NC}"
else

  for repo in "${REPOS[@]}"; do
    {
      URL=$(printf '%s' "$repo" | yq e -r '.url' -)
      BRANCH=$(printf '%s' "$repo" | yq e -r '.branch | select(. != "") // "main"' -)
      NAMESPACE=$(printf '%s' "$repo" | yq e -r '.namespace | select(. != "") // ""' -)
      printf -- "\n  Read branch ${YELLOW}%b${NC} in ${YELLOW}%b${NC} for namespace: ${YELLOW}%b${NC}\n" ${BRANCH} ${URL} ${NAMESPACE}

      REPO_PATH=$(echo "$URL" | sed -E 's#(git@github.com:|https://github.com/)##' | sed -E 's#\.git$##')
      OWNER=$(echo "$REPO_PATH" | cut -d/ -f1)
      REPO_NAME=$(echo "$REPO_PATH" | cut -d/ -f2)

      MANIFEST_URL="https://raw.githubusercontent.com/${OWNER}/${REPO_NAME}/${BRANCH}/maketools-manifest.yaml"
      printf -- "  - Find and validate manifest "

      MANIFEST=$(curl -sSL "$MANIFEST_URL" 2>/dev/null || false )
      if [ -z "$MANIFEST" ]; then
        printf -- "- ${RED}KO: %b${NC}\n" "Manifest not found"
        continue
      fi

      MANIFEST_VERSION=$(yq e -r '.version' <<<"$MANIFEST")

      SRC_PATH=$(printf '%s' "$MANIFEST" | yq e -r '.src' -)

      if [ "$MANIFEST_VERSION" != "1" ]; then
        printf -- "- ${RED}KO: %b${NC}\n" "Unsupported manifest version"
        continue
      fi

      printf -- "- ${GREEN}%b${NC}\n" "OK"
      printf -- "  - Upload available modules"
      mapfile -t AVAILABLE_MODULES < <(
        printf '%s' "$MANIFEST" | yq e -r '.available[]' -
      )

      mapfile -t ENVIRONMENT_REQUIRES < <(
        printf '%s' "$MANIFEST" | yq e -r '.environment[]' -
      )

      if [ ${#AVAILABLE_MODULES[@]} -eq 0 ]; then
        printf -- " - ${RED}KO: %b${NC}\n" "No available modules defined"
        continue
      fi

      printf -- ":\n"

      DEST_DIR="$APP_MAKETOOLS/repositories/${OWNER}/${REPO_NAME}"
      mkdir -p "$DEST_DIR"

      for ENV_NAME in "${ENVIRONMENT_REQUIRES[@]}"; do
        if ! grep -qx -- "- ${ENV_NAME}" "$ENVLIST_FILE" 2>/dev/null; then
          printf -- "- %s\n" "${ENV_NAME}" >> "$ENVLIST_FILE"
        fi
      done
      for MODULE_NAME in "${AVAILABLE_MODULES[@]}"; do
        MODULE_URL="https://raw.githubusercontent.com/${OWNER}/${REPO_NAME}/main/${SRC_PATH}/${MODULE_NAME}.mk"
        DEST_FILE="${DEST_DIR}/${MODULE_NAME}.mk"

        if [ ! -f "$DEST_FILE" ]; then
          if curl -fsSL "$MODULE_URL" -o "$DEST_FILE"; then
            printf -- "      ${MAGENTA}%b${NC} - ${GREEN}%b${NC}\n" "${MODULE_NAME}.mk" "OK"
          else
            printf -- "- ${RED}KO: %b${NC}\n" "module file missing"
          fi
        else
            printf -- "      ${MAGENTA}%b${NC} - ${GREEN}%b${NC}\n" "${MODULE_NAME}.mk" "OK"
        fi
        if [ -z "${NAMESPACE}" ]; then
          PREFIX=""
        else
          PREFIX="${NAMESPACE}-"
        fi
        printf '%s: %s\n' "${PREFIX}${MODULE_NAME}" "${OWNER}/${REPO_NAME}/${MODULE_NAME}.mk" >> "$TOOLSLIST_FILE"
      done

      printf -- "  - ${BOLD}Complete${NC}\n"

    } || {
      printf -- "- ${RED}KO: %b${NC}\n" "${NAMESPACE:-unknown} - KO: unexpected error"
      continue
    }
  done
fi


# -------------------------------------------------
# 4. Resolve modules
# -------------------------------------------------

printf "%b\n" "${CYAN}➜ Installing modules${NC}"

RENAMED_COMMANDS=()

while IFS=':' read -r MODULE_KEY MODULE_PATH; do

  MODULE_KEY=$(echo "$MODULE_KEY" | xargs)
  MODULE_PATH=$(echo "$MODULE_PATH" | xargs)

  SRC="$APP_MAKETOOLS/repositories/$MODULE_PATH"
  DEST="$APP_MAKETOOLS/requires/${MODULE_KEY}.mk"

  if [ ! -f "$SRC" ]; then
    printf "%b\n" "${RED}  ${MODULE_KEY}${NC} - KO: source not found"
    exit 1
  fi

  PREFIX="$MODULE_KEY"

  mapfile -t CMDS < <(

    awk -v p="$PREFIX" -v cmdfd=3 '

    #
    # ---------- PASS 1 ----------
    #
    FNR==NR {
        if ($0 ~ /^[a-zA-Z0-9_.-]+:[^=]*$/ &&
            $0 !~ /:[[:space:]]*[A-Za-z0-9_.-]+[[:space:]]*=/) {
            split($0,a,":")
            local[a[1]]=1
        }
        next
    }

    #
    # ---------- PASS 2 ----------
    #
    {
        line=$0
        comment=""

        if (match(line,/##/)) {
            comment=substr(line,RSTART)
            line=substr(line,1,RSTART-1)
        }

        if (match(line,/^[a-zA-Z0-9_.-]+:/)) {

            split(line,a,":")
            tgt=a[1]
            rest=a[2]

            new_tgt=p"-"tgt

            #
            # send renamed command to FD3
            #
            print new_tgt > "/dev/fd/" cmdfd

            #
            # variable assignment
            #
            if (rest ~ /^[[:space:]]*[A-Za-z0-9_.-]+[[:space:]]*=/) {
                printf "%s:%s", new_tgt, rest
                if(comment!="") printf " %s", comment
                printf "\n"
                next
            }

            #
            # rewrite dependencies
            #
            deps=""
            n=split(rest,tokens,/([ \t]+)/)

            for(i=1;i<=n;i++){
                tok=tokens[i]
                if(tok in local){
                    tok=p"-"tok
                }
                deps=deps tok
            }

            printf "%s: %s", new_tgt, deps
            if(comment!="") printf " %s", comment
            printf "\n"
            next
        }

        print
    }

    ' "$SRC" "$SRC" 3>&1 > "$DEST"

  )

  RENAMED_COMMANDS+=("${CMDS[@]}")

  printf -- "  - ${MAGENTA}%b${NC} - ${GREEN}%b${NC}\n" "${MODULE_KEY}.mk" "OK"

done < "$TOOLSLIST_FILE"


# -------------------------------------------------
# 5. Update Makefile for registration commands
# -------------------------------------------------

printf "%b" "${CYAN}➜ Register local commands${NC}"

mapfile -t RENAMED_COMMANDS < <(
  printf '%s\n' "${RENAMED_COMMANDS[@]}" | sort -u
)

{
  for cmd in "${RENAMED_COMMANDS[@]}"; do
      alias="${cmd//./-}"

      printf '%s:\n' "$cmd"
#      printf '%s: %s\n' "$alias" "$cmd"
    done
} >> "$APP_DIR/Makefile"
{
  printf '\n\n'
  printf '# ------------------------------------------------------------\n'
  printf '# Generated commands\n'
  printf '# ------------------------------------------------------------\n'
  printf '%s\n\n' "-include Makefile.local.mk"
} >> "$APP_DIR/Makefile"


if [ -f "$APP_DIR/Makefile.local.mk" ]; then
  mapfile -t LOCAL_CMDS < <(
    awk -F: '/^[a-zA-Z0-9_.-]+[[:space:]]*:/ {print $1}' "$APP_DIR/Makefile.local.mk" \
      | sed 's/[[:space:]]*$//' \
      | grep -v '^\.' \
      | sort -u
  )

  {
    for cmd in "${LOCAL_CMDS[@]}"; do
      printf '%s:\n' "$cmd"
    done
  } >> "$APP_DIR/Makefile"
fi



printf -- "- %b\n" "${GREEN}OK${NC}"
# -------------------------------------------------
# 6. Install core
# -------------------------------------------------

printf '\n%b\n' "${GREEN}✔ Devtools update completed${NC}"
printf '%b\n' "${CYAN}Project devtools are ready${NC}"
printf '\n%b\n' "${BOLD}Next step:${NC}"
printf '  %b\n\n' "${YELLOW}make help${NC}"

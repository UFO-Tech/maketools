# ============================================================
# IO / OUTPUT HELPERS
# ============================================================

# ------------------------------------------------------------
# COLOR SUPPORT
# ------------------------------------------------------------

# disable manually:
# make COLOR=0
COLOR = 1

# ------------------------------------------------------------
# ANSI COLORS
# ------------------------------------------------------------
ESC := $(shell printf '\033')

NC=$(ESC)[0m
BOLD=$(ESC)[1m

BLACK=$(ESC)[30m
RED=$(ESC)[31m
GREEN=$(ESC)[32m
YELLOW=$(ESC)[33m
BLUE=$(ESC)[34m
MAGENTA=$(ESC)[35m
CYAN=$(ESC)[36m
WHITE=$(ESC)[37m
PURPLE=$(ESC)[0;35m

GRAY=$(ESC)[90m
BRIGHT_RED=$(ESC)[91m
BRIGHT_GREEN=$(ESC)[92m
BRIGHT_YELLOW=$(ESC)[93m
BRIGHT_BLUE=$(ESC)[94m

BG_RED=$(ESC)[41m
BG_GREEN=$(ESC)[42m
BG_YELLOW=$(ESC)[43m
BG_BLUE=$(ESC)[44m


# ------------------------------------------------------------
# COLOR FUNCTION
# usage:
#   $(call c,GREEN,text)
# ------------------------------------------------------------

define c
$(if $(COLOR),$($(1))$(2)$(NC),$(2))
endef


# ------------------------------------------------------------
# LOG HELPERS
# ------------------------------------------------------------

define info
	@printf "%b\n" "$(call c,BLUE,$(1))"
endef

define success
	@printf "%b\n" "$(call c,GREEN,$(1))"
endef

define warn
	@printf "%b\n" "$(call c,YELLOW,$(1))"
endef

define err
	@printf "%b\n" "$(call c,RED,$(1))"
endef

define title_bg
	@printf "\n"
	@printf "%b\n" "$(call c,BG_YELLOW,$(1))"
	@printf "%b\n" "$(call c,GRAY,$$(printf '%*s' $$(printf '%s' "$(1)" | wc -c) '' | tr ' ' '-'))"
endef
define title
	@printf "\n"
	@printf "%b\n" "$(call c,BOLD,$(1))"
	@printf "%b\n" "$(call c,GRAY,$$(printf '%*s' $$(printf '%s' "$(1)" | wc -c) '' | tr ' ' '-'))"
endef


# ------------------------------------------------------------
# STEP OUTPUT
# ------------------------------------------------------------

define step
	@printf "%b\n" "$(call c,CYAN,➜ $(1))"
endef


# ------------------------------------------------------------
# KEY = VALUE PRINT
# ------------------------------------------------------------

define kv
	@printf "%-20s %s\n" "$(call c,GRAY,$(1))" "$(2)"
endef


io.examples: ## Examples all colors combination
	$(call title_bg,Examples all colors combination)
	@printf "%-40s %s\n" "CODE" "OUTPUT"
	@printf "%-40s %s\n" "----------------------------------------" "----------------"
	@printf "%-40s %b\n" '$$(call info,Example)' "$(call c,BLUE,Example)"
	@printf "%-40s %b\n" '$$(call success,Example)' "$(call c,GREEN,Example)"
	@printf "%-40s %b\n" '$$(call warn,Example)' "$(call c,YELLOW,Example)"
	@printf "%-40s %b\n" '$$(call err,Example)' "$(call c,RED,Example)"
	@printf "%-40s %b\n" '$$(BG_RED)Example$$(NC)' "$(BG_RED)Example$(NC)"
	@printf "%-40s %b\n" '$$(BG_GREEN)Example$$(NC)' "$(BG_GREEN)Example$(NC)"
	@printf "%-40s %b\n" '$$(BG_BLUE)Example$$(NC)' "$(BG_BLUE)Example$(NC)"
	@printf "%-40s %b\n" '$$(BLUE)Example$$(NC)' "$(BLUE)Example$(NC)"
	@printf "%-40s %b\n" '$$(BRIGHT_GREEN)Example$$(NC)' "$(BRIGHT_GREEN)Example$(NC)"
	@printf "%-40s %b\n" '$$(GRAY)Example$$(NC)' "$(GRAY)Example$(NC)"
	@printf "%-40s %b\n" '$$(RED)Example$$(NC)' "$(RED)Example$(NC)"
	@printf "%-40s %b\n" '$$(YELLOW)Example$$(NC)' "$(YELLOW)Example$(NC)"
	@printf "%-40s %b\n" '$$(MAGENTA)Example$$(NC)' "$(MAGENTA)Example$(NC)"
	@printf "%-40s %b\n" '$$(CYAN)Example$$(NC)' "$(CYAN)Example$(NC)"



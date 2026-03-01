MAKETOOLS_DIR := .maketools
SHELL := /bin/bash
.SHELLFLAGS := -s

MAKEFLAGS += --no-print-directory
MAKEFLAGS += -s
MAKEFLAGS += --warn-undefined-variables

CDBG +=
CFLAGS += $(CDBG)

SELF = $(MAKE) -s 2>/dev/null

include $(wildcard $(MAKETOOLS_DIR)/requires/*.mk)
include $(wildcard $(MAKETOOLS_DIR)/io.mk)


.PHONY: help


help:
	$(SELF)  maketools-intro
	$(SELF) 2>/dev/null maketools-help
	$(call title,Extend commands:)
	files="$(wildcard $(MAKETOOLS_DIR)/requires/*.mk) $(MAKETOOLS_DIR)/../Makefile.local.mk"; \
	for f in $$files; do \
		module=$$(basename $$f .mk); \
		echo -e "${BLUE}[$$module]${NC}"; \
		awk \
		-v YELLOW="$(YELLOW)" \
		-v GRAY="$(GRAY)" \
		-v PURPLE="$(PURPLE)" \
		-v NC="$(NC)" '\
\
		/^[a-zA-Z0-9_.-]+[[:space:]]*:/ { \
			line=$$0; \
			desc=""; \
\
			if (index(line,"##")) { \
				split(line,a,"##"); \
				line=a[1]; \
				desc=a[2]; \
				gsub(/^[ \t]+/,"",desc); \
			} \
\
			split(line,b,":"); \
			name=b[1]; \
			rest=b[2]; \
			gsub(/^[ \t]+/,"",rest); \
\
			if(rest ~ "="){ \
                vars[name]=vars[name]" "PURPLE"["rest"]"NC; \
            } \
			else if(rest!=""){ \
				split(rest,d," "); \
				for(i in d) \
					if(d[i]!="") \
						deps[name]=deps[name]" "YELLOW"<"d[i]">"NC; \
			} \
\
			if(desc!="") \
				descriptions[name]=desc; \
\
			if(!(name in seen)){ \
				order[++idx]=name; \
				seen[name]=1; \
			} \
		} \
\
		END { \
			for(i=1;i<=idx;i++){ \
				name=order[i]; \
				desc=descriptions[name]; \
				extra=""; \
\
				if(deps[name]!="") \
					extra=extra "Depend:" deps[name]; \
\
				if(vars[name]!="") \
					extra=extra " " vars[name]; \
\
				if(desc!="" && extra!="") \
					desc=desc ". " extra; \
				else if(desc=="") \
					desc=(extra!="" ? extra : GRAY"--no description--"NC); \
\
				printf "  %s%-25s%s %s\n", \
					YELLOW, name, NC, desc; \
			} \
		}' $$f; \
		echo ""; \
	done
	$(call title,Missing env vars:)
	@envfile="$(MAKETOOLS_DIR)/requires/envslist.yaml"; \
	if [ -f "$$envfile" ]; then \
		missing=0; \
		while IFS= read -r line; do \
			clean=$$(printf "%s" "$$line" | sed -E 's/^[[:space:]]*-[[:space:]]*//' | xargs); \
			[ -z "$$clean" ] && continue; \
			var=$$(printf "%s" "$$clean" | cut -d: -f1 | xargs); \
			def=$$(printf "%s" "$$clean" | cut -s -d: -f2- | xargs); \
			[ -z "$$var" ] && continue; \
			env_val=$$(printenv "$$var" 2>/dev/null || true); \
			file_val=$$(sed -n -E "s/^[[:space:]]*$$var[[:space:]]*=[[:space:]]*(.*)$$/\1/p" .env.local .env 2>/dev/null | tail -n 1); \
			if [ -z "$$env_val" ] && [ -z "$$file_val" ]; then \
				printf "  ${PURPLE}%b${NC}=%b\n" "$$var" "${GRAY}$$def${NC}"; \
				missing=1; \
			fi; \
		done < "$$envfile"; \
		if [ "$$missing" -eq 0 ]; then \
			printf "  %b\n" "${CYAN}All env variables is set${NC}"; \
		fi; \
	else \
		printf "  %b\n" "${GRAY}No envlist.yaml${NC}"; \
	fi

maketools-help:
	$(call title,Base commands:)
	$(call PRINT_COMMAND,help,Show help)
	$(call PRINT_COMMAND,update(u),Update maketools from config instructions)
	$(call PRINT_COMMAND,version (ver),UFO-Tech MakeTools version)
	echo ""
	$(call PRINT_COMMAND,io.examples,Examples io colors combination for developers)
	echo ""


__print_command:
	printf "  ${YELLOW}%-25s${NC} %s\n" "$(NAME)" "$(DESC)"

maketools-intro:
	echo -e "${GREEN}\n"
	docker compose run --rm maketools intro
	echo -e "${NC}"


define PRINT_COMMAND
	@desc="$(2)"; \
	dep="$(3)"; \
	vars="$(4)"; \
	extra=""; \
\
	if [ -n "$$dep" ]; then \
		extra="Depend: ${YELLOW}[$$dep]${NC}"; \
	fi; \
\
	if [ -n "$$vars" ]; then \
		extra="$$extra ${PURPLE}[$$vars]${NC}"; \
	fi; \
\
	if [ -n "$$desc" ] && [ -n "$$extra" ]; then \
		desc="$$desc. $$extra"; \
	elif [ -z "$$desc" ]; then \
		if [ -n "$$extra" ]; then \
			desc="$$extra"; \
		else \
			desc="--no description--"; \
		fi; \
	fi; \
\
	printf "  ${YELLOW}%-25s${NC} %s\n" "$(1)" "$$desc"
endef

version:
	docker compose run --rm maketools version
ver: version

update:
	docker compose run --rm maketools update

u: update


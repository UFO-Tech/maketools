commit-a:
	@printf "\033[33mПідтвердити push з amend? (y/N): \033[0m"; \
	read CONF && [ "$$CONF" = "y" ] || exit 1; \
	git add .; \
	git commit --no-edit --amend; \
	git push --force; \
		printf "\033[36mІcнуючі теги:\033[0m\n"; \
		TAGS="$$(git tag --sort=-v:refname)"; \
		i=1; \
		while IFS= read -r t; do \
			[ -z "$$t" ] && continue; \
			printf "\033[33m[\033[0m\033[36m%s\033[0m\033[33m]\033[0m \033[35m%s\033[0m\n" "$$i" "$$t"; \
			i=$$((i+1)); \
		done <<< "$$TAGS"; \
		printf ">>> \033[33mВведи \033[0m\033[36mпорядковий номер версії\033[0m\033[33m, \033[35mнову версію\033[0m\033[33m, або натисни Enter щоб пропустити:  \033[0m"; \
		read -r INPUT; \
		[ -z "$$INPUT" ] && INPUT=0; \
		if [[ "$$INPUT" =~ ^[0-9]+$$ ]]; then \
			if [ "$$INPUT" -eq 0 ]; then exit 0; fi; \
			TAG="$$(printf "%s\n" "$$TAGS" | sed -n "$${INPUT}p")"; \
		else \
			TAG="$$INPUT"; \
		fi; \
		git tag -d $$TAG 2>/dev/null || true; \
		git push origin :refs/tags/$$TAG; \
		git tag $$TAG; \
		git push origin $$TAG


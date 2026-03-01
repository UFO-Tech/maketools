commit-a:  ## Commit with amend, force push and retag
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


status:  ## Show short git status
	@printf "\033[36mGit status:\033[0m\n"
	@git status -sb

commit:  ## Add all changes and create commit
	@printf "\033[33mMessage:\033[0m "; \
	read MSG && [ -n "$$MSG" ] || exit 1; \
	git add .; \
	git commit -m "$$MSG"

amend:  ## Amend last commit without changing message
	@printf "\033[33mAmend last commit? (y/N): \033[0m"; \
	read CONF && [ "$$CONF" = "y" ] || exit 1; \
	git add .; \
	git commit --no-edit --amend

push:  ## Push current branch to origin
	@branch=$$(git branch --show-current); \
	printf "\033[36mPush branch:\033[0m \033[33m%s\033[0m\n" "$$branch"; \
	git push origin "$$branch"

pull:  ## Pull current branch with rebase
	@branch=$$(git branch --show-current); \
	printf "\033[36mPull (rebase):\033[0m \033[33m%s\033[0m\n" "$$branch"; \
	git pull --rebase origin "$$branch"

checkout:  ## Checkout existing branch
	@printf "\033[33mBranch name:\033[0m "; \
	read BR && [ -n "$$BR" ] || exit 1; \
	git checkout "$$BR"

new-branch:  ## Create and switch to new branch
	@printf "\033[33mNew branch:\033[0m "; \
	read BR && [ -n "$$BR" ] || exit 1; \
	git checkout -b "$$BR"

clean:  ## Remove untracked files
	@printf "\033[31mRemove untracked files? (y/N): \033[0m"; \
	read CONF && [ "$$CONF" = "y" ] || exit 1; \
	git clean -fd
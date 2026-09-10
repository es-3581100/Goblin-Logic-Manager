PYTHON ?= python3

.PHONY: render verify skills smoke

render:
	$(PYTHON) scripts/render_agent.py

verify:
	$(PYTHON) scripts/verify.py

skills:
	$(PYTHON) scripts/skill-preflight.py

smoke:
	./scripts/smoke-goblin-runtime.sh

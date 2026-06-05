.PHONY: docs docs-serve

docs:
	@echo "Building documentation..."
	mdbook build docs

docs-serve:
	@echo "Serving documentation locally at http://localhost:3000..."
	mdbook serve docs

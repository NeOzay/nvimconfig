.PHONY: test test-file
RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))

test:
	nvim --headless -u tests/minimal_init.lua -c "lua MiniTest.run()"

test-file:
	$(eval TARGET_FILE := $(if $(RUN_ARGS),$(RUN_ARGS)))
	nvim --headless -u tests/minimal_init.lua -c "lua MiniTest.run_file('$(TARGET_FILE)')"

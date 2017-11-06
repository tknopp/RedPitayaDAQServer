all:
	@$(MAKE) -C src/lib
	@$(MAKE) -C src/server
	@$(MAKE) -C src/test
	@$(MAKE) -C libs/scpi-parser
	@$(MAKE) install -C libs/scpi-parser
	cp scripts/daq_server.service /etc/systemd/system/

.PHONY: clean
clean:
	@$(MAKE) -C src/lib clean
	@$(MAKE) -C src/server clean

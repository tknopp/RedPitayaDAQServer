all:
	@$(MAKE) -C src/lib
	@$(MAKE) -C src/server
	@$(MAKE) -C lib/scpi-parser
	@$(MAKE) install -C lib/scpi-parser
	cp scripts/daq_server.service /etc/systemd/system/

.PHONY: clean
clean:
	@$(MAKE) -C src/lib clean
	@$(MAKE) -C src/server clean

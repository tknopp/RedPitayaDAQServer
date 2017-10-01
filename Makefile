all:
	@$(MAKE) -C src/lib
	@$(MAKE) -C src/test
	@$(MAKE) -C src/server
	cp scripts/daq_server.service /etc/systemd/system/

.PHONY: clean
clean:
	@$(MAKE) -C src/lib clean
	@$(MAKE) -C src/test clean
	@$(MAKE) -C src/server clean

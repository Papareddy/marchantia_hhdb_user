# marchantia_hhdb_user — fetch / verify / extract the M. polymorpha HH-suite DB
#
# Zenodo DOI:   10.5281/zenodo.XXXXXXX   (placeholder until upload completes)
# After upload, replace ZENODO_RECORD below with the actual record id.

ZENODO_RECORD ?= XXXXXXX
TARBALL       := marchantia_hhdb_v7.1.tar.gz
DB_DIR        := db
DB_PREFIX     := $(DB_DIR)/marchantia_v7.1

ZENODO_BASE   := https://zenodo.org/record/$(ZENODO_RECORD)/files
URL           := $(ZENODO_BASE)/$(TARBALL)
URL_MD5       := $(ZENODO_BASE)/$(TARBALL).md5

.PHONY: all fetch verify extract clean help info

help:
	@echo "make fetch    - download tarball + md5 from Zenodo, verify, extract"
	@echo "make verify   - re-verify md5 of the tarball"
	@echo "make extract  - untar into $(DB_DIR)/"
	@echo "make clean    - remove tarball (keeps the extracted DB)"
	@echo "make info     - paths and DB size"

all: fetch

fetch: $(DB_PREFIX)_cs219.ffindex

$(TARBALL):
	@if [ "$(ZENODO_RECORD)" = "XXXXXXX" ]; then \
		echo "ERROR: ZENODO_RECORD is not set."; \
		echo "Pass it on the make command line:"; \
		echo "  make fetch ZENODO_RECORD=1234567"; \
		echo "or edit the Makefile."; \
		exit 1; \
	fi
	@echo "[fetch] $(URL)"
	curl -L -C - -o $(TARBALL) $(URL)

$(TARBALL).md5: $(TARBALL)
	@echo "[fetch] $(URL_MD5)"
	-curl -L -fsSL -o $(TARBALL).md5 $(URL_MD5) || \
		echo "WARN: no .md5 next to tarball — skipping checksum check"

verify: $(TARBALL).md5
	@if [ -s $(TARBALL).md5 ]; then \
		echo "[verify] md5sum -c $(TARBALL).md5"; \
		md5sum -c $(TARBALL).md5; \
	else \
		echo "WARN: no checksum file; skipping verify"; \
	fi

extract: $(TARBALL)
	@mkdir -p $(DB_DIR)
	@echo "[extract] tar -xzf $(TARBALL) -C $(DB_DIR)"
	tar -xzf $(TARBALL) -C $(DB_DIR) --strip-components=1
	@ls -lah $(DB_DIR) | head

$(DB_PREFIX)_cs219.ffindex: $(TARBALL) $(TARBALL).md5
	$(MAKE) verify
	$(MAKE) extract

info:
	@echo "DB prefix: $(DB_PREFIX)   (pass to hhsearch -d / hhblits -d)"
	@echo "Files:"
	@ls -lh $(DB_DIR) 2>/dev/null || echo "  (not yet extracted)"
	@echo "Disk:"
	@du -sh $(DB_DIR) 2>/dev/null || true

clean:
	@echo "Removing tarball (DB at $(DB_DIR) is kept)."
	rm -f $(TARBALL) $(TARBALL).md5

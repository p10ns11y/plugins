.PHONY: all clean

all:
	$(MAKE) -C c
	cargo build --release --manifest-path rust/Cargo.toml
	mkdir -p bin
	cp c/context-sage-c bin/context-sage-c
	cp rust/target/release/context-sage bin/context-sage

clean:
	$(MAKE) -C c clean
	cargo clean --manifest-path rust/Cargo.toml
	rm -rf bin

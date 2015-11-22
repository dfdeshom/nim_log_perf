lib:
	 nimble c --app:lib --gc:boehm --header log_parser.nim
clean:
	rm -rf liblog_parser.so log_parser nimcache

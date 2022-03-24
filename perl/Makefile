all: Makefile.xs ../liblossless.so
	make -f Makefile.xs

../liblossless.so:
	make -C .. liblossless.so

Makefile.xs: Makefile.PL typemap Lossless.xs lib/Lossless.pm
	perl Makefile.PL

clean: Makefile.xs
	make -f Makefile.xs clean
	rm -f Makefile.xs.old

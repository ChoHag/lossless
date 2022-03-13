CTANGLE?= ctangle
CWEAVE?=  cweave
PDFTEX?=  pdftex
TEST?=    prove
CFLAGS+=  -Wall -Wpedantic -Wextra -I. -fPIC
LDFLAGS+= -lpthread
TFLAGS+=  -v

SOURCES:=       lossless.c ffi.c
OBJECTS:=       lossless.o ffi.o
TEST_SCRIPTS:=
TEST_OBJECTS:=

OTHER_SOURCES:= lossless.h

all: liblossless.so lossless.pdf ffi.perl man/mandoc.db

full: test all



lossless.pdf: lossless.tex
	$(PDFTEX) lossless.tex

lossless.tex: lossless.w
	mkdir -p t && $(CWEAVE) lossless.w

lossless: $(OBJECTS)
	$(CC) $(CFLAGS) $(CPPFLAGS) $(LDFLAGS) -o lossless $(OBJECTS)

liblossless.so: $(OBJECTS)
	$(CC) $(LDFLAGS) -shared -o liblossless.so $(OBJECTS)

$(OBJECTS): $(SOURCES)

$(SOURCES) $(TEST_SOURCES) $(OTHER_SOURCES): lossless.w
	mkdir -p t && $(CTANGLE) lossless.w $(LASS)

test: $(TEST_SCRIPTS)
	$(TEST) $(TFLAGS) -e '' t

$(TEST_SCRIPTS): $(TEST_OBJECTS)

$(TEST_OBJECTS): $(TEST_SOURCES) $(OTHER_SOURCES)

ffi.perl: always liblossless.so
	ln -sfn ../liblossless.so perl/
	LD_LIBRARY_PATH=$(pwd) make -C perl
	date > ffi.perl

man/mandoc.db: always
	makewhatis man

always:

.SUFFIXES: .t

.c.t:
	if echo " $(ALLOC_TEST_SCRIPTS) " | grep -qF " $@ "; then          \
		$(CC) $(CFLAGS) $(CPPFLAGS) $(LDFLAGS) llalloc.o -o $@ $<; \
	else                                                               \
		$(CC) $(CFLAGS) $(CPPFLAGS) $(LDFLAGS) lltest.o -o $@ $<;  \
	fi

dist: lossless.pdf $(SOURCES) $(OTHER_SOURCES) $(TEST_SOURCES)
	d=$$(date +%s);                                              \
	mkdir -p tmp/lossless-0.$$d/t;                               \
	cp README* Makefile lossless.pdf *.[chw] tmp/lossless-0.$$d; \
	cp t/*.[ch] tmp/lossless-0.$$d/t;                            \
	rm -f tmp/lossless-0.$$d/*~ tmp/lossless-0.$$d/t/*~;         \
	tar -C tmp -cf- lossless-0.$$d | gzip -9c > lossless-0.$$d.tgz

clean:
	rm -f core *.core *.idx *.log *.scn *.toc *.o
	rm -f liblossless.so lossless *.o
	rm -f lossless.c lossless.tex lossless.pdf
	rm -f lossless*tgz
	rm -fr t
	make -C perl clean
	rm -f ffi.perl

CTANGLE?= ctangle
CWEAVE?=  cweave
PDFTEX?=  pdftex
TEST?=    prove
CFLAGS+=  -Wall -Wpedantic -Wextra -Wno-implicit-fallthrough -I. -fPIC
LDFLAGS+= -lpthread -ledit -lcurses
TFLAGS+=  -v

BIN_SOURCES:= lossless.h repl.c
LIB_SOURCES:= lossless.h ffi.c
BIN_OBJECTS:= repl.o
LIB_OBJECTS:= ffi.o


all: lossless liblossless.so lossless.pdf repl.pdf ffi.perl man/mandoc.db

full: test all


$(SOURCES): lossless.w

$(BIN_SOURCES): lossless.c repl.w

$(LIB_SOURCES): lossless.c

$(BIN_OBJECTS): $(BIN_SOURCES)

$(LIB_OBJECTS): $(LIB_SOURCES)


# The LDFLAGS are repeated here to build on linux; there's likely a better way
lossless: lossless.o $(BIN_OBJECTS)
	$(LINK.c) lossless.o $(BIN_OBJECTS) $(LDFLAGS) -o lossless

liblossless.so: lossless.o $(LIB_OBJECTS)
	$(LINK.c) -shared -o liblossless.so lossless.o $(LIB_OBJECTS)

ffi.perl: always liblossless.so
	ln -sfn ../liblossless.so perl/
	make -C perl
	date > ffi.perl

man/mandoc.db: always
	makewhatis man


always:

.SUFFIXES: .idx-in .idx .pdf .t .tex .w

# Dependencies (can these be baked into automatic rules)?
lossless.pdf: lossless.idx
lossless.idx-in: lossless.tex
repl.pdf: repl.idx
repl.idx-in: repl.tex

.w.tex:
	$(CWEAVE) $< - $@
	mv $$(echo $< | sed s/.w$$//).idx $$(echo $< | sed s/.w$$//).idx-in

# Remove single-letter and merge identical identifiers.
.idx-in.idx:
	perl bin/reindex $<

.tex.pdf:
	$(PDFTEX) $<

.w.c:
	$(CTANGLE) $< - $@

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
	rm -f core *.core *.idx *.idx-in *.log *.scn *.toc *.o
	rm -f liblossless.so lossless *.o
	rm -f lossless.[ch] repl.c ffi.c
	rm -f lossless.tex lossless.pdf
	rm -f repl.tex repl.pdf
	rm -f lossless*tgz
	rm -fr t
	rm -f man/mandoc.db
	make -C perl clean
	rm -f ffi.perl

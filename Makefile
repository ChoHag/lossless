CTANGLE?=       ctangle
CWEAVE?=        cweave
PDFTEX?=        pdftex
TEST?=          prove
LCFLAGS?=       -Wall -Wpedantic -Wextra -Wno-implicit-fallthrough -I. -fPIC
LCPPFLAGS?=
LLDFLAGS?=      -lpthread -ledit -lcurses
LTFLAGS?=       -v

OBJECTS:=       lossless.o
SOURCES:=       lossless.c lossless.h
BIN_OBJECTS:=   repl.o
BIN_SOURCES:=   repl.c
LIB_OBJECTS:=   ffi.o
LIB_SOURCES:=   ffi.c

LLCOMPILE:=     $(CC) $(DEBUG) $(CFLAGS) $(LCFLAGS) $(CPPFLAGS) $(LCPPFLAGS)


# Major build targets:
all: lossless liblossless.so lossless.pdf repl.pdf ffi.perl man/mandoc.db

full: test all

test:
	echo There are no tests.
	@false

# Dependencies:
lossless.c lossless.h ffi.c: lossless.w
repl.c: repl.w
lossless.o: lossless.c lossless.h
ffi.o: ffi.c lossless.h
repl.o: repl.c lossless.h
lossless.pdf: lossless.idx llfig-1.pdf
lossless.idx-in: lossless.tex
lossless.tex: lossless.w
repl.pdf: repl.idx
repl.idx-in: repl.tex
repl.tex: repl.w

llfig-1.pdf: llfig.mp
	mpost llfig.mp
	mptopdf llfig.?

repl.o: barbaroi.h

barbaroi.h: barbaroi.ll
	bin/lloader INITIALISE <barbaroi.ll >barbaroi.h

# Compilers:
# The LDFLAGS are repeated here to build on linux; there's likely a better way
lossless: lossless.o ffi.o repl.o
	$(LLCOMPILE) $(OBJECTS) $(BIN_OBJECTS) $(LDFLAGS) $(LLDFLAGS) \
		-o lossless

liblossless.so: lossless.o ffi.o
	$(LLCOMPILE) $(OBJECTS) $(BIN_OBJECTS) $(LDFLAGS) $(LLDFLAGS) \
		-shared -o liblossless.so

ffi.perl: liblossless.so
	ln -sfn ../liblossless.so perl/
	make -C perl
	date > ffi.perl

man/mandoc.db:
	makewhatis man

# Distribution & cleanup:
dist: lossless-$(VERSION).tgz

# TODO: check git status.
lossless-$(VERSION).tgz: all
	test -n "$(VERSION)" # make dist without $$(VERSION)!
	make -C tmp/dist pack FROM=$$(pwd) VERSION=$(VERSION)
	cp tmp/dist/lossless-$(VERSION).tgz .

# TODO: pull latest source
pack:
	make clean
	mkdir -p tmp
	mkdir tmp/lossless-$(VERSION)
	touch tmp/lossless-$(VERSION)/tmp
	cp $(FROM)/*.pdf $(FROM)/*.[ch] tmp/lossless-$(VERSION)
	cp -pR * tmp/lossless-$(VERSION) || true
	rm -f tmp/lossless-$(VERSION)/tmp
	mkdir tmp/lossless-$(VERSION)/tmp
	tar -C tmp -cf- lossless-$(VERSION) | gzip -9c > lossless-$(VERSION).tgz

clean:
	rm -f core *.core *.idx *.idx-in *.log *.scn *.toc *.o
	rm -f liblossless.so lossless
	rm -f lossless.[ch] repl.c ffi.c
	rm -f lossless.tex lossless.pdf
	rm -f repl.tex repl.pdf
	rm -f lossless*tgz
	rm -fr t
	rm -f man/mandoc.db
	make -C perl clean
	rm -f ffi.perl

# Autogenerated rules:
.SUFFIXES: .idx-in .idx .pdf .t .tex .w

.w.tex:
	$(CWEAVE) $< - $@
	src="$<"; mv "$${src%.w}.idx" "$${src%.w}.idx-in"

# Remove single-letter and merge identical identifiers.
.idx-in.idx:
	perl bin/reindex $<

.tex.pdf:
	$(PDFTEX) $<

.w.c:
	$(CTANGLE) $< - $@

.c.o:
	$(LLCOMPILE) -c $< -o $@

.c.t:
	if echo " $(ALLOC_TEST_SCRIPTS) " | grep -qF " $@ "; then          \
		$(CC) $(CFLAGS) $(CPPFLAGS) $(LDFLAGS) llalloc.o -o $@ $<; \
	else                                                               \
		$(CC) $(CFLAGS) $(CPPFLAGS) $(LDFLAGS) lltest.o -o $@ $<;  \
	fi

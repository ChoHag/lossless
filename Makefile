CTANGLE?=       ctangle
CWEAVE?=        cweave
PDFTEX?=        pdftex
TEST?=          prove
LCFLAGS?=       -Wall -Wpedantic -Wextra -Wno-implicit-fallthrough -I. -fPIC
LCPPFLAGS?=
LLDFLAGS?=      -lpthread -ledit -lcurses
LTFLAGS?=       -v

OBJECTS:=       lossless.o initialise.o
TEST_OBJECTS:=  memless.o testless.o initialise.o
SOURCES:=       lossless.c lossless.h
LIB_OBJECTS:=
LIB_SOURCES:=

TEST_SCRIPTS:=  t/insanity.t \
        t/closure.t          \
        t/evaluator.t        \
        t/hashtable.t        \
        t/reader.t

LLCOMPILE:=     $(CC) $(DEBUG) $(CFLAGS) $(LCFLAGS) $(CPPFLAGS) $(LCPPFLAGS)


# Major build targets:
all: lossless liblossless.so lossless.pdf
# more: ffi.perl man/mandoc.db

full: test all

test: $(TEST_SCRIPTS)
	$(TEST) $(LTFLAGS) -e '' $(TEST_SCRIPTS)

# Dependencies:
lossless.c lossless.h: lossless.w
lossless.o: lossless.c lossless.h
lossless.tex: lossless.w
lossless.idx-in: lossless.tex
lossless.pdf: lossless.idx llfig-1.pdf

initialise.c: lossless.w
initialise.o: initialise.c evaluate.c barbaroi.c

barbaroi.c: bin/bin2c barbaroi.ll
	bin/bin2c LL_BARBAROI_C Barbaroi_Source barbaroi.ll >barbaroi.c

evaluate.c: bin/bin2c evaluate.la
	bin/bin2c LL_EVALUATE_C Evaluate_Source evaluate.la >evaluate.c

#llfig-1.pdf: llfig.mp
#	mpost llfig.mp
#	mptopdf llfig.?

testless.c testless.h: lossless.c
testless.o: testless.c testless.h

$(TEST_SCRIPTS:.t=.c): lossless.w

# Compilers:
# The LDFLAGS are repeated here to build on linux; there's likely a better way
lossless: $(OBJECTS)
	$(LLCOMPILE) $(OBJECTS) $(LDFLAGS) $(LLDFLAGS) \
		-o lossless

liblossless.so: $(OBJECTS)
	$(LLCOMPILE) $(OBJECTS) $(LIB_OBJECTS) $(LDFLAGS) $(LLDFLAGS) \
		-shared -o liblossless.so

memless.o: lossless.c
	$(LLCOMPILE) -DLLTEST -c lossless.c -o $@

ffi.perl: liblossless.so
	ln -sfn ../liblossless.so perl/
	make -C perl
	date > ffi.perl

man/mandoc.db:
	makewhatis -pD man

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
	rm -f lossless.[ch] initialise.c testless.[ch] barbaroi.c evaluate.c
	rm -f lossless.tex lossless.pdf
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

.w.h:
	mkdir -p t
	$(CTANGLE) $< - $@

.w.c:
	mkdir -p t
	$(CTANGLE) $< - $@

.c.o:
	$(LLCOMPILE) -c $< -o $@

.c.t: $(TEST_OBJECTS)
	$(LLCOMPILE) $(LDFLAGS) $(LLDFLAGS) $(TEST_OBJECTS) $< -o $@

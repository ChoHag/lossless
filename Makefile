CTANGLE?=       ctangle
CWEAVE?=        cweave
PDFTEX?=        pdftex
TEST?=          prove
LCFLAGS?=       -Wall -Wpedantic -Wextra -Wno-implicit-fallthrough -I. -Iffi/dyncall -fPIC
LCPPFLAGS?=
LLDFLAGS?=      -lpthread -ledit -lcurses
LTFLAGS?=       -v

LLCOMPILE:=     $(CC) $(DEBUG) $(CFLAGS) $(LCFLAGS) $(CPPFLAGS) $(LCPPFLAGS)

DYNCALL_SOURCES:=                                    \
        ffi/autovar/autovar_ABI.h                    \
        ffi/autovar/autovar_ARCH.h                   \
        ffi/autovar/autovar_CC.h                     \
        ffi/autovar/autovar_OS.h                     \
        ffi/autovar/autovar_OSFAMILY.h               \
        ffi/dyncall/dyncall.h                        \
        ffi/dyncall/dyncall_aggregate.c              \
        ffi/dyncall/dyncall_aggregate.h              \
        ffi/dyncall/dyncall_aggregate_x64.c          \
        ffi/dyncall/dyncall_alloc.h                  \
        ffi/dyncall/dyncall_api.c                    \
        ffi/dyncall/dyncall_call.S                   \
        ffi/dyncall/dyncall_call_arm32_arm.S         \
        ffi/dyncall/dyncall_call_arm32_arm_armhf.S   \
        ffi/dyncall/dyncall_call_arm32_thumb_apple.s \
        ffi/dyncall/dyncall_call_arm32_thumb_armhf.S \
        ffi/dyncall/dyncall_call_arm32_thumb_gas.s   \
        ffi/dyncall/dyncall_call_arm64.S             \
        ffi/dyncall/dyncall_call_mips_eabi_gas.s     \
        ffi/dyncall/dyncall_call_mips_n32.S          \
        ffi/dyncall/dyncall_call_mips_n64.S          \
        ffi/dyncall/dyncall_call_mips_o32.S          \
        ffi/dyncall/dyncall_call_ppc32.S             \
        ffi/dyncall/dyncall_call_ppc64.S             \
        ffi/dyncall/dyncall_call_sparc.s             \
        ffi/dyncall/dyncall_call_sparc64.s           \
        ffi/dyncall/dyncall_call_x64.S               \
        ffi/dyncall/dyncall_call_x86.S               \
        ffi/dyncall/dyncall_call_x86_8a.s            \
        ffi/dyncall/dyncall_callf.c                  \
        ffi/dyncall/dyncall_callf.h                  \
        ffi/dyncall/dyncall_callvm.c                 \
        ffi/dyncall/dyncall_callvm.h                 \
        ffi/dyncall/dyncall_callvm_arm32_arm.c       \
        ffi/dyncall/dyncall_callvm_arm32_arm.h       \
        ffi/dyncall/dyncall_callvm_arm32_arm_armhf.c \
        ffi/dyncall/dyncall_callvm_arm32_arm_armhf.h \
        ffi/dyncall/dyncall_callvm_arm32_thumb.c     \
        ffi/dyncall/dyncall_callvm_arm32_thumb.h     \
        ffi/dyncall/dyncall_callvm_arm64.c           \
        ffi/dyncall/dyncall_callvm_arm64.h           \
        ffi/dyncall/dyncall_callvm_arm64_apple.c     \
        ffi/dyncall/dyncall_callvm_base.c            \
        ffi/dyncall/dyncall_callvm_mips.c            \
        ffi/dyncall/dyncall_callvm_mips.h            \
        ffi/dyncall/dyncall_callvm_mips_eabi.c       \
        ffi/dyncall/dyncall_callvm_mips_eabi.h       \
        ffi/dyncall/dyncall_callvm_mips_n32.c        \
        ffi/dyncall/dyncall_callvm_mips_n32.h        \
        ffi/dyncall/dyncall_callvm_mips_n64.c        \
        ffi/dyncall/dyncall_callvm_mips_n64.h        \
        ffi/dyncall/dyncall_callvm_mips_o32.c        \
        ffi/dyncall/dyncall_callvm_mips_o32.h        \
        ffi/dyncall/dyncall_callvm_ppc32.c           \
        ffi/dyncall/dyncall_callvm_ppc32.h           \
        ffi/dyncall/dyncall_callvm_ppc64.c           \
        ffi/dyncall/dyncall_callvm_ppc64.h           \
        ffi/dyncall/dyncall_callvm_sparc.c           \
        ffi/dyncall/dyncall_callvm_sparc.h           \
        ffi/dyncall/dyncall_callvm_sparc64.c         \
        ffi/dyncall/dyncall_callvm_sparc64.h         \
        ffi/dyncall/dyncall_callvm_x64.c             \
        ffi/dyncall/dyncall_callvm_x64.h             \
        ffi/dyncall/dyncall_callvm_x86.c             \
        ffi/dyncall/dyncall_callvm_x86.h             \
        ffi/dyncall/dyncall_config.h                 \
        ffi/dyncall/dyncall_macros.h                 \
        ffi/dyncall/dyncall_signature.h              \
        ffi/dyncall/dyncall_types.h                  \
        ffi/dyncall/dyncall_utils.h                  \
        ffi/dyncall/dyncall_value.h                  \
        ffi/dyncall/dyncall_vector.c                 \
        ffi/dyncall/dyncall_vector.h                 \
        ffi/dyncall/dyncall_version.h                \
        ffi/portasm/gen-masm.sh                      \
        ffi/portasm/portasm-arm.S                    \
        ffi/portasm/portasm-arm64.S                  \
        ffi/portasm/portasm-ppc.S                    \
        ffi/portasm/portasm-ppc64.S                  \
        ffi/portasm/portasm-x64.S                    \
        ffi/portasm/portasm-x86.S

DYNCALL_OBJECTS:=             \
        dyncall_vector.o      \
        dyncall_api.o         \
        dyncall_callvm.o      \
        dyncall_callvm_base.o \
        dyncall_call.o        \
        dyncall_callf.o       \
        dyncall_aggregate.o

DYNCALL_LIBRARY:= libdyncall.a

OBJECTS:=       $(DYNCALL_OBJECTS) lossless.o initialise.o
TEST_OBJECTS:=  $(DYNCALL_OBJECTS) memless.o testless.o initialise.o
SOURCES:=       lossless.c lossless.h

TEST_SCRIPTS:=  t/insanity.t \
        t/closure.t          \
        t/evaluator.t        \
        t/hashtable.t        \
        t/reader.t

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
	$(LLCOMPILE) $(OBJECTS) $(LDFLAGS) $(LLDFLAGS) \
		-shared -o liblossless.so

memless.o: lossless.c
	$(LLCOMPILE) -DLLTEST -c lossless.c -o $@

$(DYNCALL_LIBRARY): $(DYNCALL_OBJECTS)
	${AR} ${ARFLAGS} ${DYNCALL_LIBRARY} ${DYNCALL_OBJECTS}

$(DYNCALL_OBJECTS): $(DYNCALL_SOURCES)

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

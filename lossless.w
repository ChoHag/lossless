% Sorry human reader but first we need to define a bunch of TeX macros
% for pretty-printing some common things. Just ignore this bit.

\pdfpagewidth=210mm
\pdfpageheight=297mm
\pagewidth=159.2mm
\pageheight=238.58mm
\fullpageheight=246.2mm
\setpage % A4

\def\<{$\langle$}
\def\>{$\rangle$}
\def\J{}
\let\K=\leftarrow
\def\Ls/{\.{LossLess}}
\def\Lt{{\char124}}
\def\L{{$\char124$}}
\def\ditto{--- \lower1ex\hbox{''} ---}
\def\ft{{\tt\char13}}
\def\hex{\hbox{${\scriptstyle 0x}$\tt\aftergroup}}
\def\iIII{\hskip3em}
\def\iII{\hskip2em}
\def\iIV{\hskip4em}
\def\iI{\hskip1em}
\def\epdf#1{\pdfximage{#1}\pdfrefximage\pdflastximage}% Why isn't this provided?
\def\qc{$\rangle\!\rangle$}
\def\qo{$\langle\!\langle$}
\def\to{{$\rightarrow$}}

% Ignore this bit as well which fixes CWEB's knowledge of C types.
% Sometimes typedefs work and sometimes they don't. I'll worry about
% that when I'm done.

@s new normal
@s Lunused static
@s shared static
@s unique static
@s sigjmp_buf void
@s siglongjmp return
%
@s cell int
@s digit int
@s fixed int
@s half int
@s wide int
@s int32_t int
@s int64_t int
@s intmax_t int
@s intptr_t int
@s uint32_t int
@s uint64_t int
@s uintptr_t int
%
@s Vbreak int
@s Verror int
@s Vhash int
@s Vlexicat int
@s Vprimitive int
@s Vutfio_parse int
@s Oatom int
@s Oerror int
@s Oheap int
@s Olexeme int
@s Olexical_analyser int
@s Oprimitive int
@s Orope int
@s Orope_iter int
@s Orune int
@s Osegment int
@s Otag int
@s Osymbol int
@s Osymbol_atom int
@s Osymbol_compare int
@s Outfio int

@** Introduction. \Ls/ is a lisp-like programming language. It is
destined to not rely on the \CEE/ library but for the time being
uses |malloc| for some of the heavy lifting of memory management.
Some other \CEE/ features are taken advantage of or worked around
while \CEE/ the language of this implementation but these are not
integral to the character of \Ls/.

TODO: Remove headers which are no longer necessary.
@.TODO@>
@<System headers@>=
#include <assert.h>
#include <ctype.h>
#include <limits.h>
#include <setjmp.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <unistd.h>

@ The main product of this part of \Ls/ is a library for dynamic
or static linking. Untitled sections are concatenated and included
in this library, starting with this one.

@c
@<System headers@>@;
@<Repair the system headers@>@;
@h
@<Type definitions@>@;
@<Function declarations@>@;
@<Global variables@>@;

@ Consumers of the library include this header file of the same
type and function declarations, and global variables with an |extern|
qualifier.

@(lossless.h@>=
@<System headers@>@;
@<Repair the system headers@>@;
@h
@<Type definitions@>@;
@<Function declarations@>@;
@<External symbols@>@;

@ Access to \Ls/' parts from other languages requires some \CEE/
macros to be made available through symbols, additional validation
on functions, etc. These optional are placed in the file \.{ffi.c}
and linked into \.{liblossless.so}/\.{lossless.dll}.

@ Library users may need symbols for \CEE/ macros.
@(ffi.c@>=
#include "lossless.h"

@ \Ls/ (and lisp) data all descend from the |cell|; two cells make
an {\it atom\/}, called |wide|. A pointer to an atom is equivalent
to a machine-specific memory address, ie.~a normal \CEE/ pointer
or ``|char *|''.

These (untested) macros are intended to allow \Ls/ to compile on a
wider variety of hardware than the latest $2^{n+1}$-bit wintel
fruit. Also defined here is |fixed| representing numbers small
enough to fit in the value of a pointer with trickery and the |digit|
which is used to represent unbounded integers.

@<Type def...@>=
typedef intptr_t cell;
typedef uintptr_t digit;
@#
#if SIZE_MAX <= 0xfffful
@<Define a 16-bit addressing environment@>@;
#elif SIZE_MAX <= 0xfffffffful
@<Define a 32-bit addressing environment@>@;
#elif SIZE_MAX <= 0xfffffffffffffffful
@<Define a 64-bit addressing environment@>@;
#else
#error@, Tiny computer@&.
#endif
@#

@ Values common to all architectures. If a datum is smaller than
|INTERN_BYTES| it may be directly ``interned'' rather than pointed
at.

@<Type def...@>=
#define CELL_MASK (~(WIDE_BYTES - 1))
@#
#define BYTE_BITS    8
#define BYTE_BYTES   1
#define BYTE         0xff
#define TAG_BYTES    1
@#
#define DIGIT_MAX    UINTPTR_MAX
#define HALF_MIN     (INTPTR_MIN / 2)
#define HALF_MAX     (INTPTR_MAX / 2)
#define INTERN_BYTES (WIDE_BYTES - 1)
@#

typedef intptr_t cell;
typedef uintptr_t digit;
typedef struct {
        char buffer[INTERN_BYTES];
        unsigned char length;
} Ointern;

@ Fixed-integer values are up to 32 bits (signed) on a 64-bit
architecture. This choice was arbitrary --- the data encoding scheme
at present in fact makes 60 bits available --- but it's easier to
envision dealing with half a word than 15 16$^{th}$s of a word.

@<Define a 64-bit addressing environment@>=
#define CELL_BITS  64
#define CELL_BYTES 8
#define CELL_SHIFT 4
#define WIDE_BITS  128
#define WIDE_BYTES 16
#define FIX_MIN    (-0x7fffffffll - 1) /* 32 bits */
#define FIX_MAX    0x7fffffffll
#define FIX_MASK   0xffffffffll
#define FIX_SHIFT  32
#define FIX_BASE2  32
#define FIX_BASE8  11
#define FIX_BASE10 10
#define FIX_BASE16 8
typedef union {
        struct {
                cell low;
                cell high;
        };
        struct {
                char b[16];
        } value;
} wide;
typedef int32_t fixed;
typedef int32_t half;

@ 16 bit numbers would probably be too small to be of practical use
to fixed integers in a 32-bit envionment use 24 (of the presently-available
28) bits to occupy 3 quarters of a word.

@<Define a 32-bit addressing environment@>=
#define CELL_BITS  32
#define CELL_BYTES 4
#define CELL_SHIFT 3
#define WIDE_BITS  64
#define WIDE_BYTES 8
#define FIX_MIN    (-0x7fffffl - 1) /* 24 bits */
#define FIX_MAX    0x7fffffl
#define FIX_MASK   0xffffffl
#define FIX_SHIFT  8
#define FIX_BASE2  24
#define FIX_BASE8  8
#define FIX_BASE10 8
#define FIX_BASE16 6
typedef union {
        struct {
                cell low;
                cell high;
        };
        int64_t value;
} wide;
typedef int32_t fixed; /* $32-24=8$ unused bits */
typedef int16_t half;

@ This section is here because it was easy to write. It remains to
be seen how practical it is.

@<Define a 16-bit addressing environment@>=
#define CELL_BITS  16
#define CELL_BYTES 2
#define CELL_SHIFT 2
#define WIDE_BITS  32
#define WIDE_BYTES 4
#define FIX_MIN    (-0x7f - 1) /* 8 bits */
#define FIX_MAX    0x7f
#define FIX_MASK   0xff
#define FIX_SHIFT  8
#define FIX_BASE2  8
#define FIX_BASE8  3
#define FIX_BASE10 3
#define FIX_BASE16 2
typedef union {
        struct {
                cell low;
                cell high;
        };
        int64_t value;
} wide;
typedef int8_t fixed;
typedef int8_t half;

@ Something like these (unused) macros could merge the heap's tag
with the cell data if the machine's pointers are large enough.

@d PTR_TAG_SHIFT    56
@d PTR_ADDRESS(p)   ((intptr_t (p)) & ((1ull << PTR_TAG_SHIFT) - 1))
@d PTR_TAG_MASK(p)  ((intptr_t (p)) & ~((1ull << PTR_TAG_SHIFT) - 1))
@d PTR_TAG(p)       (PTR_TAG_MASK(p) >> PTR_TAG_SHIFT)
@d PTR_SET_TAG(p,s) ((p) = (((p) & PTR_ADDRESS(p)) | ((s) << PTR_TAG_SHIFT)))

@ \Ls/ is entirely a single threaded program but includes the
foundations necessary to support multiple threads. Each global or
static variable can be |shared| between all threads or |unique| to
each thread.

@d shared
@d unique __thread
@<Fun...@>=
void thread_mem_init (void);

@ Code comes with errors and programming is a way of finding them
(and turning them into bugs).

Blocks of code which may fail while holding resources set up a
``long-jump site'' using \.{sigsetjmp(3)}, a pointer to which is
passed to every fallible function that gets called. In general the
pointer to a long-jump site is called |failure| and a locally
established long-jump site is called |cleanup|. The error code is
returned in |reason|.

@d failure_p(O) ((O) != LERR_NONE)
@<Type def...@>=
typedef enum {
        LERR_NONE,@/
        LERR_AMBIGUOUS,      /* Constant etc. incorrectly terminated. */
        LERR_DOUBLE_TAIL,    /* Two \.. operators. */
        LERR_EMPTY_TAIL,     /* A \.. without a tail expression. */
        LERR_EOF,            /* End of file or stream. */
        LERR_EXISTS,         /* New binding conflicts. */
        LERR_HEAVY_TAIL,     /* A \.. with more than one tail expression. */
        LERR_IMPROPER,       /* A list operation encountered an improper list. */
        LERR_INCOMPATIBLE,   /* Operation on incompatible operand. */
        LERR_INTERNAL,       /* Bug in \Ls/. */
        LERR_INTERRUPT,      /* An operation was interrupted. */
        LERR_LIMIT,          /* A software-defined limit has been reached. */
        LERR_LISTLESS_TAIL,  /* List tail-syntax (\..) not in a list. */
        LERR_MISMATCH,       /* Closing bracket did not match open bracket. */
        LERR_MISSING,        /* A hash table or environment lookup failed. */
        LERR_NONCHARACTER,   /* Scanning UTF-8 encoding failed. */
        LERR_OOM,            /* Out of memory. */
        LERR_OVERFLOW,       /* Attempt to access past the end of a buffer. */
        LERR_SYNTAX,         /* Unrecognisable syntax (insufficient alone). */
        LERR_UNCLOSED_OPEN,  /* Missing \.), \.] or \.\}. */
        LERR_UNCOMBINABLE,   /* Attempted to combine a non-program. */
        LERR_UNDERFLOW,      /* A stack was popped too far. */
        LERR_UNIMPLEMENTED,  /* A feature is not implemented. */
        LERR_UNOPENED_CLOSE, /* Premature \.), \.] or \.\}. */
        LERR_UNPRINTABLE,    /* Failed serialisation attempt. */
        LERR_UNSCANNABLE,    /* Parser encountered |LEXICAT_INVALID|. */
        LERR_USER,           /* A user-defined error. */
        LERR_LENGTH
} Verror;

@ The numeric codes are suitable for internal use but lisp is a
language of processing symbols so at run-time the errors are given
names (and, potentially, other metadata).

@<Type def...@>=
typedef struct {
        char *message;
} Oerror;

@ This list is sorted by the ``column'' on the right.

@<Global...@>=
Oerror Ierror[LERR_LENGTH] = {@|
        [LERR_AMBIGUOUS]      = { "ambiguous-syntax" },@|
        [LERR_EXISTS]         = { "binding-conflict" },@|
        [LERR_DOUBLE_TAIL]    = { "double-tail" },@|
        [LERR_EOF]            = { "end-of-file" },@|
        [LERR_IMPROPER]       = { "improper-list" },@|
        [LERR_INCOMPATIBLE]   = { "incompatible-operand" },@|
        [LERR_INTERRUPT]      = { "interrupted" },@|
        [LERR_INTERNAL]       = { "lossless-error" },@|
        [LERR_MISMATCH]       = { "mismatched-brackets" },@|
        [LERR_MISSING]        = { "missing" },@|
        [LERR_NONCHARACTER]   = { "noncharacter" },@|
        [LERR_NONE]           = { "no-error" },@|
        [LERR_LISTLESS_TAIL]  = { "non-list-tail" },@|
        [LERR_OOM]            = { "out-of-memory" },@|
        [LERR_OVERFLOW]       = { "overflow" },@|
        [LERR_LIMIT]          = { "software-limit" },@|
        [LERR_SYNTAX]         = { "syntax-error" },@|
        [LERR_HEAVY_TAIL]     = { "tail-mid-list" },@|
        [LERR_UNCLOSED_OPEN]  = { "unclosed-brackets" },@|
        [LERR_UNCOMBINABLE]   = { "uncombinable" },@|
        [LERR_UNDERFLOW]      = { "underflow" },@|
        [LERR_UNIMPLEMENTED]  = { "unimplemented" },@|
        [LERR_UNOPENED_CLOSE] = { "unopened-brackets" },@|
        [LERR_UNPRINTABLE]    = { "unprintable" },@|
        [LERR_UNSCANNABLE]    = { "unscannable-lexeme" },@|
        [LERR_EMPTY_TAIL]     = { "unterminated-tail" },@/
        [LERR_USER]           = { "user-error" },@|
};

@ @<Extern...@>=
extern Oerror Ierror[];

@ When \Ls/ cannot proceed it aborts its current action and jumps
back to the most recently established long-jump site with one of
the error codes. If, as is usually the case, the error condition
cannot be dealt with by that caller it will clean up its own resources
and jump back to the long-jump site given it (passing on the same
error code), which it had saved before creating its own.

The outline of a function which protects its resources in this way
is shown here. A lot of pieces of code in this implementation have
this basic outline so it will be helpful to understand it well
enough to be able to ignore it because \CEE/ is verbose enough.

Nearly all the time the resource in question is |S| items on top
of the run-time stack. In some cases this is also or instead the
register |Tmp_ier| (|T|). The |unwind| macro cleans up both, relying
on the \CEE/ compiler to remove the branches of unreachable code,
and performs the long jump |J| with error code |E|.

In particular, allocated memory generally does {\it not\/} need to
be freed explicitly if an error occurs while it's in use --- as
will be seen shortly, allocated memory is immediately tied into a
list which is then scanned during garbage collection for unused
allocations that can be released.

@d unwind(J,E,T,S) do {
        assert((E) != LERR_NONE);
        if (T) Tmp_ier = NIL;
        if (S) stack_clear(S);
        siglongjmp(*(J), (E));
} while (0)
@c
#if 0
void
example (sigjmp_buf *failure)
{
        sigjmp_buf cleanup; /* Allocated on \CEE/'s stack, there is no
                                        need to clean this up. */
        Verror reason = LERR_NONE;

        obtain_resources(failure); /* Usually |stack_protect| or
                                        |stack_reserve|. */
        if (failure_p(reason = sigsetjmp(cleanup, 1))) /* Establish a new
                                        long-jump site. */
                unwind(failure, reason, false, n); /* Clean up and abort. */
        use_resources(&cleanup); /* ... */
        free_resources(); /* Usually |stack_clear| --- only reached if
                                        there was no error. */
}
#endif

@ An error which is handled throughout this code-base but cannot
actually occur is external interruption. When signal handling is
written and an interrupt occurs this |Interrupt| flag will be set
to |true| and any potentially-unbounded or otherwise long-running
operation will halt.

@ @<Global...@>=
unique bool Interrupt = false;

@ @<Extern...@>=
extern unique bool Interrupt;

@** Memory. It is possible to compute without recourse to core
memory but it isn't very interesting. Memory resources are divided
by \Ls/ into two categories, fixed-size {\it atoms\/} and dynamic
{\it segments\/}. Segments are allocated in co-ordination with the
kernel (if there is one) at arbitrary locations by a memory manager
which at this time is \CEE/'s |malloc|.

The very first segment allocated during initialisation is the
``heap'' from which atoms are allocated. When all the atoms in a
heap have been taken an attempt to allocate another will cause
garbage collection to reclaim any discarded atoms first (this is
also when unused segments are returned to the master allocator).

@<Fun...@>=
void mem_init (void);
void *mem_alloc (void *, size_t, size_t, sigjmp_buf *);
void mem_free (void *);

@ @c
void
thread_mem_init (void)
{
        @<Save register locations@>@;
}

@ @c
void
mem_init (void)
{
        sigjmp_buf failed, *failure = &failed;
        Verror reason = LERR_NONE;

        if (failure_p(reason = sigsetjmp(failed, 1)))
                abort();
        thread_mem_init();
        @<Initialise memory@>@;
        ENV = Root = NIL;
}

@ @c
void *
mem_alloc (void       *old,
           size_t      length,
           size_t      align,
           sigjmp_buf *failure)
{
        void *r;

        if (!align)
                r = realloc(old, length);
        else {
                assert(old == NULL);
                if (((align - 1) & align) != 0 || align == 0)
                        siglongjmp(*failure, LERR_INCOMPATIBLE);
                if ((length & (align - 1)) != 0)
                        siglongjmp(*failure, LERR_INCOMPATIBLE);
                r = aligned_alloc(align, length);
        }
        if (r == NULL)
                siglongjmp(*failure, LERR_OOM);
        return r;
}

@ @c
void
mem_free (void *o)
{
        free(o);
}

@ There is a lot of blank space here for future versions of \Ls/
to fill in.

@* Atoms. Although allocated within a heap which is itself a segment,
atoms are (nearly) the most fundamental datum out of which nearly
everything else in \Ls/ is constructed, and so they are described
here first. An atom consists of two cells (so it's name has already
a mistake) the size of a data pointer\footnote{$^1$}{An instruction
pointer does not necessarily need to be related in any way to a
data pointer although on the most common architectures they are the
same in practice.} and ``is tagged''.

An atom's tag is located in such a way that it has no bearing on
the location or size of the atom itself. On machines with a large
address space the tag can be squeezed into the actual address of
the atom's or as is currently the case in \Ls/ at an offset within
the heap relative to the atom.

The tag is used to identify what the data is in each half of the
atom. In particular the garbage collector must be able to identify
cells which hold a pointer to another atom or set of atoms, so that
they will be marked or copied during collection and not reclaimed.

Because atoms are identified by a real memory address and the size
of each atom is itself two full memory addresses, each atom is
always allocated on a 4, 8 or 16-byte boundary (for 16, 32 and
64-bit addressing), thus the lower 2, 3 or 4 bits of the address
are known to always be zero. \Ls/ takes advantage of this by using
these bits to identify values which do not in fact require heap
storage.

If the lowest bit of a pointer (|cell|) is set it identifies one
of these {\it special\/} variables. Five global constants with the
odd values 1, 3, 5, 7 \AM\ 13 (9 \AM\ 11 are unused). The value 15
(|0xf| or |0b1111|) is even more special: If the lowest 4 bits are
exactly this then the rest of the pointer is not all zeros but a
fixed-width (signed) integer value.

Finally |NIL| comes about and makes nothing even more special still.
|NIL| is a |cell| with the literal value zero and so it looks like,
and in fact is, a real address. It even looks like and {\it usually\/}
is, \CEE/'s |NULL| (\.{NULL}) pointer. However |NULL| is a \CEE/
pointer and need not be zero even though zero {\it from a literal
value in the \CEE/ source code\/} is |NULL|, the ``null pointer''.
Clear?

This answer to a related question on Stack Overflow clarifies the
situation (emphasis added): The ``... `question about how one would
assign 0 address to a pointer' formally has no answer. You simply
{\bf can't assign a specific address to a pointer in \CEE//\CPLUSPLUS/\/}.
However, in the realm of implementation-defined features, the
explicit integer-to-pointer conversion is intended to have that
effect.''

To keep these almost-but-not-quite-exactly-unlike-zero values
straight transforming between a |cell| and a \CEE/ {\bf pointer\/}
is always explicitly cast even though they occupy the ``same''
storage.

@d NIL            ((cell) 0)  /* Nothing, the empty list, \.{()}. */
@d LFALSE         ((cell) 1)  /* Boolean false, \.{\#f} or \.{\#F}. */
@d LTRUE          ((cell) 3)  /* Boolean true, \.{\#t} or \.{\#T}. */
@d VOID           ((cell) 5)  /* Even less than nothing --- the ``no
                                        explicit value'' value. */
@d LEOF           ((cell) 7)  /* Value obtained off the end of a file or
                                        other stream. */
@d UNDEFINED      ((cell) 13) /* The value of a variable that isn't there. */
@d FIXED          ((cell) 15) /* A small fixed-width integer. */
@#
@d null_p(O)      ((intptr_t) (O) == 0)
@d special_p(O)   (null_p(O) || ((intptr_t) (O)) & 1)
@d boolean_p(O)   ((O) == LFALSE || (O) == LTRUE)
@d false_p(O)     ((O) == LFALSE)
@d true_p(O)      ((O) == LTRUE)
@d void_p(O)      ((O) == VOID)
@d eof_p(O)       ((O) == LEOF)
@d undefined_p(O) ((O) == UNDEFINED)
@d fix_p(O)       (((O) & FIXED) == FIXED)
@d defined_p(O)   (!undefined_p(O))
@#
@d predicate(O)   ((O) ? LTRUE : LFALSE)

@ The tag of an atom is used by garbage collection to keep track
of atoms which are in use and/or have been partially scanned. The
remainder of the tag identifies the contents of each of the atom's
cells. This is known as the atom's {\it format\/}. In total the tag
is 8 bits wide --- 2 for garbage collector state (|LTAG_LIVE| \AM\
|LTAG_DONE|) and 6 for the format.

In practice of course everything in a modern computer has an inherent
order but neither half of an atom is considered greater or lesser
than the other and so they are referred to with the unfamiliar Latin
words for left and right, {\it sinister\/} and {\it
dexter\/}\footnote{$^1$}{It also helps that it's a pair whose
acronyms are both three runes long, which was not really the primary
concern.} to confound the reader's (and writer's) inherent mental
bias while still establishing an order with which each concern can
be handled in this source code, the intuitive ``sindex''.

The one format in which the order of each half does ``matter'' is
the {\it pair\/} which for histerical raisins labels the sinister
half the {\it car\/} and and the dexter half the {\it cdr\/}. The
otherwise fruitless distinction is made between sin/dex and car/cdr
to make it clear when an atom is a real pair and when an atom is
to be treated as opaque.

The atomic formats are broadly categorised into four groups based
on whether each half is or isn't a pointer to an atom and the first
2 of the 6 bits (|LTAG_DSIN| \AM\ |LTAG_DDEX|) hold this information.
The remaining 4 bits are (mostly) arbitrary.

|ATOM_TO_TAG| finds an atom's tag and is defined below after the
heap storage (in which it's located) is introduced.

@d LTAG_LIVE 0x80 /* Atom is referenced from a register. */
@d LTAG_DONE 0x40 /* Atom has been partially scanned. */
@d LTAG_DSIN 0x20 /* Atom's sin half points to an atom. */
@d LTAG_DDEX 0x10 /* Atom's dex half points to an atom. */
@d LTAG_BOTH (LTAG_DSIN | LTAG_DDEX)
@d LTAG_FORM (LTAG_BOTH | 0x0f)
@d LTAG_TDEX 0x02 /* A tree is threadable in its dex halves. */
@d LTAG_TSIN 0x01 /* A tree is threadable in its sin halves. */
@d LTAG_NONE 0x00
@#
@d TAG(O)         (ATOM_TO_TAG((O)))
@d TAG_SET_M(O,V) (ATOM_TO_TAG((O)) = (V))
@#
@d ATOM_LIVE_P(O)           (TAG(O) & LTAG_LIVE)
@d ATOM_CLEAR_LIVE_M(O)     (TAG_SET_M((O), TAG(O) & ~LTAG_LIVE))
@d ATOM_SET_LIVE_M(O)       (TAG_SET_M((O), TAG(O) | LTAG_LIVE))
@d ATOM_MORE_P(O)           (TAG(O) & LTAG_DONE)
@d ATOM_CLEAR_MORE_M(O)     (TAG_SET_M((O), TAG(O) & ~LTAG_DONE))
@d ATOM_SET_MORE_M(O)       (TAG_SET_M((O), TAG(O) | LTAG_DONE))
@d ATOM_FORM(O)             (TAG(O) & LTAG_FORM)
@d ATOM_SIN_DATUM_P(O)      (TAG(O) & LTAG_DSIN)
@d ATOM_DEX_DATUM_P(O)      (TAG(O) & LTAG_DDEX)
@d ATOM_SIN_THREADABLE_P(O) (TAG(O) & LTAG_TSIN)
@d ATOM_DEX_THREADABLE_P(O) (TAG(O) & LTAG_TDEX)
@<Type def...@>=
typedef unsigned char Otag;
typedef struct {
        cell sin, dex;
} Oatom;

@ These are the formats known to \Ls/. The numeric value of each
format is relevent except (sort of) |FORM_NONE| which is zero and
the rope and tree formats, which are carefully chosen so that atoms
with these formats are {\it polymorphic\/}, which means they are
distinct but implemented with (mostly) the same API and (mostly)
the same implementation to do (mostly) the same thing.

Unallocated atoms' tags are initialised to |FORM_NONE|. Allocated
atoms' tags will be one of the other values here.

@d FORM_NONE              (LTAG_NONE | 0x00)
@d FORM_ARRAY             (LTAG_NONE | 0x01)
@d FORM_COLLECTED         (LTAG_NONE | 0x02)
@d FORM_FIX               (LTAG_NONE | 0x03)
@d FORM_HASHTABLE         (LTAG_NONE | 0x04)
@d FORM_HEAP              (LTAG_NONE | 0x05)
@d FORM_RECORD            (LTAG_NONE | 0x06)
@d FORM_RECORD_INDEX      (LTAG_NONE | 0x07)
@d FORM_RUNE              (LTAG_NONE | 0x08)
@d FORM_SEGMENT_INTERN    (LTAG_NONE | 0x09)
@d FORM_SYMBOL            (LTAG_NONE | 0x0a)
@d FORM_SYMBOL_INTERN     (LTAG_NONE | 0x0b)
@#
@d FORM_PENDING           (LTAG_DDEX | 0x00)
@d FORM_PRIMITIVE         (LTAG_DDEX | 0x01)
@d FORM_SEGMENT           (LTAG_DDEX | 0x02)
@#
@d FORM_PAIR              (LTAG_BOTH | 0x00)
@d FORM_APPLICATIVE       (LTAG_BOTH | 0x01)
@d FORM_ENVIRONMENT       (LTAG_BOTH | 0x02)
@d FORM_OPERATIVE         (LTAG_BOTH | 0x03)
@#
@d FORM_ROPE              (LTAG_BOTH | 0x08)
@d FORM_TROPE_SIN         (LTAG_BOTH | 0x09)
@d FORM_TROPE_DEX         (LTAG_BOTH | 0x0a)
@d FORM_TROPE_BOTH        (LTAG_BOTH | 0x0b)
@d FORM_TREE              (LTAG_BOTH | 0x0c)
@d FORM_TTREE_SIN         (LTAG_BOTH | 0x0d)
@d FORM_TTREE_DEX         (LTAG_BOTH | 0x0e)
@d FORM_TTREE_BOTH        (LTAG_BOTH | 0x0f)

@ Predicates. Generally objects have a simple, even 1:1 mapping
between them and a single format. Notable exceptions are symbols
and segments which may be ``interned'', and trees which can masquerade
as ropes or as doubly-linked lists.

Segments also form the basis for some other objects including arrays
and records. When a segment is allocated its address is stored in
one half of an atom and so the other half is available for use by
some of the objects which are built on top of segments.

\Ls/ data are always held in \CEE/ in storage or variables with
type |cell| and so \CEE/'s limited type validation is bypassed. To
somewhat compensate for this the format of any |cell| arguments to
\CEE/ functions are indicated by initially calling |assert| with a
(possibly qualified) predicate.

@d form(O)                (TAG(O) & LTAG_FORM)
@d form_p(O,F)            (!special_p(O) && form(O) == FORM_##F)
@d pair_p(O)              (form_p((O), PAIR))
@d array_p(O)             (form_p((O), ARRAY))
@d null_array_p(O)        ((O) == Null_Array)
@d collected_p(O)         (form_p((O), COLLECTED))
@d environment_p(O)       (form_p((O), ENVIRONMENT))
@d hashtable_p(O)         (form_p((O), HASHTABLE) || null_array_p(O))
@d pending_p(O)           (form_p((O), PENDING))
@d record_p(O)            (form_p((O), RECORD))
@d record_index_p(O)      (form_p((O), RECORD_INDEX))
@d rune_p(O)              (form_p((O), RUNE))
@#
@d segment_intern_p(O)    (form_p((O), SEGMENT_INTERN))
@d segment_stored_p(O)    (form_p((O), SEGMENT))
@d segment_p(O)           (segment_intern_p(O) || segment_stored_p(O))
@d symbol_intern_p(O)     (form_p((O), SYMBOL_INTERN))
@d symbol_stored_p(O)     (form_p((O), SYMBOL))
@d symbol_p(O)            (symbol_intern_p(O) || symbol_stored_p(O))
@#
@d character_p(O)         (eof_p(O) || rune_p(O))
@d arraylike_p(O)         (array_p(O) || hashtable_p(O) || record_p(O))
@d pointer_p(O)           (segment_stored_p(O) || symbol_stored_p(O) ||
        arraylike_p(O) || form_p((O), HEAP))
@#
@d primitive_p(O)         (form_p((O), PRIMITIVE))
@d closure_p(O)           (form_p((O), APPLICATIVE) || form_p((O), OPERATIVE))
@d program_p(O)           (closure_p(O) || primitive_p(O))
@d applicative_p(O)       ((closure_p(O) && form_p((O), APPLICATIVE)) ||
        primitive_applicative_p(O))
@d operative_p(O)         ((closure_p(O) && form_p((O), OPERATIVE)) ||
        primitive_operative_p(O))

@ A record is an array of named cells and optionally a segment.
Records for internal use are identified by a (negative) integer,
user records are not made available yet but will likely be identified
by a symbol or closure.

TODO: Move |fix| into the macro.

@.TODO@>
@d RECORD_ROPE_ITERATOR        -1
@d RECORD_ENVIRONMENT_ITERATOR -2
@d RECORD_LEXEME               -3
@d RECORD_LEXAR                -4
@d RECORD_PROVENANCE           -5
@#
@d rope_iter_p(O)         (form_p((O), RECORD) && record_id(O)
        == fix(RECORD_ROPE_ITERATOR))
@d lexeme_p(O)            (form_p((O), RECORD) && record_id(O)
        == fix(RECORD_LEXEME))
@d lexar_p(O)             (form_p((O), RECORD) && record_id(O)
        == fix(RECORD_LEXAR))
@d provenance_p(O)        (form_p((O), RECORD) && record_id(O)
        == fix(RECORD_PROVENANCE))

@* Fixed-size Integers. No operators are yet made available to work
with any sort of numbers, however the fixed-size small integers are
minimally defined here for the use of the few objects which do need
them internally.

TODO: Figure out negatives vs. logical/arithmetic shift vs. complements.

@.TODO@>
@d fix_value(O) ((fixed) ((O) >> FIX_SHIFT))
@<Fun...@>=
cell fix (intmax_t);

@ @c
cell
fix (intmax_t val)
{
        cell r;

        assert(val >= FIX_MIN && val <= FIX_MAX);
        r = FIXED;
        r |= val << FIX_SHIFT;
        return r;
}

@* Heap. A heap is stored as a (singly-linked) list of pages. Each
page has a |Oheap| header (as well as the transparent |Osegment|
header because every heap page is allocated as a segment) followed
immediately by the tags, possibly a gap and then the atoms of that
heap extending all the way to the end of the page. An allocation
request considers each page in turn until the first page is found
with an atom available.

Initially there is a single heap consisting of a single page. When
there are no more unused atoms left to allocate in any page garbage
collection is performed which reports how many unused atoms were
reclaimed. If there are no spare atoms available then another page
is allocated and attached to the heap at the back of the list.

Pages within a heap are allocated automatically. At present they
will never be detached from the list and reclaimed, and there is
no way to initialise another heap. These abilities will be added
when \Ls/ grows threads.

If a compacting garbage collector is being used (again, there is
no way to actually convert a heap to compacting or create one yet
but the ability will be necessary to support threads) then heap
pages are allocated two at a time in pairs\footnote{$^1$}{Not to
be confused with pair {\it objects}.} which are pointed to each
other in addition to their list link. Moreover each second page-half
is linked in a list {\it backwards\/} for a trivial optimisation
later.

Allocation in a compacting garbage collector is extremely fast at
the expense of having half of each heap pair empty: the pointer to
the next free atom is simply returned and incremented (unless the
page is full). When the heap is full any atoms which are in use are
re-allocated in the same linear fashion from the dormant half and
the heap is effectively turned up-side down making the dormant
halves active and the active halves dormant (and empty).

@d HEAP_CHUNK         0x1000
@d HEAP_MASK          0x0fff
@d HEAP_BOOKEND       (sizeof (Osegment) + sizeof (Oheap))
@d HEAP_LEFTOVER      ((HEAP_CHUNK - HEAP_BOOKEND) / (TAG_BYTES + WIDE_BYTES))
@d HEAP_LENGTH        ((int) HEAP_LEFTOVER)
@d HEAP_HEADER        ((HEAP_CHUNK / WIDE_BYTES) - HEAP_LENGTH)
@#
@d ATOM_TO_ATOM(O)    ((Oatom *) (O))
@d ATOM_TO_HEAP(O)    (SEGMENT_TO_HEAP(ATOM_TO_SEGMENT(O)))
@d ATOM_TO_INDEX(O)   (((((intptr_t) (O)) & HEAP_MASK) >> CELL_SHIFT) - HEAP_HEADER)
@d ATOM_TO_SEGMENT(O) ((Osegment *) (((intptr_t) (O)) & ~HEAP_MASK))
@d HEAP_TO_SEGMENT(O) (ATOM_TO_SEGMENT(O))
@d SEGMENT_TO_HEAP(O) ((Oheap *) (O)->address)
@d HEAP_TO_LAST(O)    ((Oatom *) (((intptr_t) HEAP_TO_SEGMENT(O)) + HEAP_CHUNK))
@#
@d ATOM_TO_TAG(O)     (ATOM_TO_HEAP(O)->tag[ATOM_TO_INDEX(O)])
@<Type def...@>=
struct Oheap {
        Oatom *free;
 struct Oheap *next, *pair;
        Otag   tag[];
};
typedef struct Oheap Oheap;

@ There are (conceptually) exactly two heaps, one for the current
thread (|Theap|) and one shared between all threads (|Sheap|). New
atoms are allocated in the current thread's heap. Upon encountering
an atom in another thread's heap that atom will be copied (by the
owning thread) into the shared heap so that the requesting thread
can gain access to it.

@<Global...@>=
shared Oheap *Sheap = NULL; /* Process-wide shared heap. */
unique Oheap *Theap = NULL; /* Per-thread private heap. */

@ @<Extern...@>=
extern shared Oheap *Sheap;
extern unique Oheap *Theap;

@ The accessors here should probably be renamed to |lsin| and |ldex|
(TODO).

@.TODO@>
@<Fun...@>=
cell lcar (cell);
cell lcdr (cell);
Otag ltag (cell);
void lcar_set_m (cell, cell);
void lcdr_set_m (cell, cell);
void heap_init_sweeping (Oheap *, Oheap *);
void heap_init_compacting (Oheap *, Oheap *, Oheap *);
Oheap *heap_enlarge (Oheap *, sigjmp_buf *);
cell heap_alloc (Oheap *, sigjmp_buf *);
cell atom (Oheap *, cell, cell, Otag, sigjmp_buf *);

@ The thread heap is initialised when \Ls/ is starting but the
shared heap remains unallocated until it's required. For book-keeping
purposes a heap is allocated in the form of a segment and as a
segment is pointed to by an object on a heap the first atom allocated
within a new heap page will be that object.

Note that there is currently no way to convert this sweeping heap
into a compacting heap (and so it follows that the compacting code
is largely untested).

@<Init...@>=
Theap = SEGMENT_TO_HEAP(segment_alloc(-1, HEAP_CHUNK, 1, HEAP_CHUNK, failure));
heap_init_sweeping(Theap, NULL);
segment_init(HEAP_TO_SEGMENT(Theap), heap_alloc(Theap, failure));
Sheap = NULL;

@ If a heap will use a compacting garbage collector then each of
its pages is allocated alongside another page and atoms are copied
between them.

On of each pair is linked into a list in one direction and the other
pair in the other direction (and each half-page pair links to the
other half in its |pair| pointer). In this way after the garbage
collector has walked over the entire heap the heap's head pointer
can be changed to the head at the other end, effectively turning
the heap upside down and beginning allocation from within the
newly-emptied half.

Each half of a compacting heap is initialised identically: every
atom's tag is initialised to |FORM_NONE| and its free pointer is
set to the first available atom above the header.

@c
void
heap_init_compacting (Oheap *heap,
                      Oheap *prev,
                      Oheap *pair)
{
        int i;

        heap->pair = pair;
        heap->free = (Oatom *) (((intptr_t) HEAP_TO_SEGMENT(heap)) + HEAP_CHUNK);
        pair->free = (Oatom *) (((intptr_t) HEAP_TO_SEGMENT(pair)) + HEAP_CHUNK);
        for (i = 0; i < HEAP_LENGTH; i++) {
                heap->free--;
                ATOM_TO_TAG(heap->free) = FORM_NONE;
                pair->free--;
                ATOM_TO_TAG(pair->free) = FORM_NONE;
                heap->free->sin = heap->free->dex = NIL;
                pair->free->sin = pair->free->dex = NIL;
        }
        heap->pair = pair;
        pair->pair = heap;
        if (prev == NULL) {
                heap->next = pair->next = NULL;
        } else {
                if ((heap->next = prev->next) != NULL) {
                        assert(heap->next->pair->next == prev->pair);
                        heap->next->pair->next = heap->pair;
                }
                pair->next = prev->pair;
                prev->next = heap;
        }
}

@ A heap which is to be garbage collected with a non-moving mark
and sweep algorithm uses less space and has no complicated linkage
however collection and allocation are slower than on a compacting
heap. The heap is likewise initialised by setting each available
atom's tag to |FORM_NONE| but instead of a pointer that gets
incremented free atoms are linked through their dex cell in a list
that ends in |NIL| at the top of the (now full) heap.

@c
void
heap_init_sweeping (Oheap *heap,
                    Oheap *prev)
{
        int i;

        heap->pair = NULL;
        heap->free = HEAP_TO_LAST(heap) - 1;
        ATOM_TO_TAG(heap->free) = FORM_NONE;
        heap->free->sin = heap->free->dex = NIL;
        for (i = 1; i < HEAP_LENGTH; i++) {
                heap->free--;
                ATOM_TO_TAG(heap->free) = FORM_NONE;
                heap->free->sin = NIL;
                heap->free->dex = (cell) (heap->free + 1);
        }
        if (prev == NULL)
                heap->next = NULL;
        else {
                heap->next = prev->next;
                prev->next = heap;
        }
}

@ Enlarging a heap is practically the same either way. When allocating
two heaps there is no need to clean up the first in case the second
allocation fails --- garbage collection will eventually release the
unused segment (if the out of memory condition doesn't abort the
whole process first).

@c
Oheap *
heap_enlarge (Oheap      *heap,
              sigjmp_buf *failure)
{
        Oheap *new, *pair;
        Osegment *snew, *spair;
        cell owner;

        if (heap->pair == NULL) {
                snew = segment_alloc(-1, HEAP_CHUNK, 1, HEAP_CHUNK, failure);
                new = SEGMENT_TO_HEAP(snew);
                heap_init_sweeping(new, heap);
                owner = heap_alloc(new, failure);
                ATOM_TO_TAG(owner) = FORM_HEAP;
                pointer_set_m(owner, snew);
                segment_set_owner_m(owner, owner);
        } else {
                snew = segment_alloc(-1, HEAP_CHUNK, 1, HEAP_CHUNK, failure);
                spair = segment_alloc(-1, HEAP_CHUNK, 1, HEAP_CHUNK, failure);
                new = SEGMENT_TO_HEAP(snew);
                pair = SEGMENT_TO_HEAP(spair);
                heap_init_compacting(new, heap, pair);
                owner = heap_alloc(new, failure);
                ATOM_TO_TAG(owner) = FORM_HEAP;
                pointer_set_m(owner, snew);
                segment_set_owner_m(owner, owner);
                owner = heap_alloc(new, failure);
                ATOM_TO_TAG(owner) = FORM_HEAP;
                pointer_set_m(owner, spair);
                segment_set_owner_m(owner, owner);
        }
        return new;
}

@ Allocating from either type of heap is broadly similar too. In
each case the list of heap pages is iterated over until the first
one is found with a free atom, which is where they differ. In either
case if no atom is found then the appropriate type of garbage
collection is performed and, if necessary, the heap is enlarged by
another page (or pair of pages).

The garbage collector will actually call back into |heap_alloc| to
move atoms and upon completion but not to allocate {\it new\/}
atoms, only those which already were on the heap and are being moved
into a recently-freed location.

@c
cell
heap_alloc (Oheap      *heap,
            sigjmp_buf *failure)
{
        Oheap *h, *next;
        cell r;

        next = heap;
        if (heap->pair != NULL) {
allocate_incrementing:
                while (next != NULL) {
                        h = next;
                        if (ATOM_TO_HEAP(h->free) == heap)
                                return (cell) h->free++;
                        next = h->next;
                }
                assert(failure != NULL);
                /* UNREACHABLE during collection. */
                if (gc_compacting(heap, true) > 0)
                        next = heap;
                else
                        next = heap_enlarge(h, failure); /* Will succeed
                                                        or |goto failure|. */
                goto allocate_incrementing;
        } else {
allocate_listwise:
                while (next != NULL) {
                        h = next;
                        if (!null_p(h->free)) {
                                r = (cell) h->free;
                                h->free = (Oatom *) h->free->dex;
                                ((Oatom *) r)->dex = NIL;
                                return r;
                        }
                        next = h->next;
                }
                assert(failure != NULL);
                /* UNREACHABLE during collection. */
                if (gc_sweeping(heap, true) > 0)
                        next = heap;
                else
                        next = heap_enlarge(h, failure); /* Will succeed
                                                        or |goto failure|. */
                goto allocate_listwise;
        }
}

@ A pointer to a new atom returned from |heap_alloc| must be formatted
before it can be used by |atom| or |cons|. If the new sin or dex
value is an atom (as indicated by the new tag) then it may not yet
be referenced by a live object and would be discarded if allocation
performs garbage collection.

To avoid this there are two registers |Tmp_SIN| and |Tmp_DEX| which
the value is saved into immediately prior to allocation. |Tmp_ier|
which has already be mentioned is defined here and serves a similar
purpose for arrays and segments.

@<Global...@>=
unique cell Tmp_SIN = NIL; /* Allocator's storage for SIN/CAR pointer. */
unique cell Tmp_DEX = NIL; /* Allocator's storage for DEX/CDR pointer. */
unique cell Tmp_ier = NIL; /* Other temporary safe storage. */

@ This function is one of the few with an unusual error handling
mechanism to clear its two registers.

@d cons(A,D,F) (atom(Theap, (A), (D), FORM_PAIR, (F)))
@c
cell
atom (Oheap      *heap,
      cell        nsin,
      cell        ndex,
      Otag        ntag,
      sigjmp_buf *failure)
{
        cell r;
        sigjmp_buf cleanup;
        Verror reason = LERR_NONE;

        assert(ntag != FORM_NONE);
        if (ntag & LTAG_DSIN)
                Tmp_SIN = nsin;
        if (ntag & LTAG_DDEX)
                Tmp_DEX = ndex;
        if (failure_p(reason = sigsetjmp(cleanup, 1)))
                goto fail;
        r = heap_alloc(heap, &cleanup);
        TAG_SET_M(r, ntag);
        ((Oatom *) r)->sin = (ntag & LTAG_DSIN) ? Tmp_SIN : nsin;
        ((Oatom *) r)->dex = (ntag & LTAG_DDEX) ? Tmp_DEX : ndex;
        Tmp_SIN = Tmp_DEX = NIL;
        return r;
fail:
        Tmp_SIN = Tmp_DEX = NIL;
        siglongjmp(*failure, reason);
}

@ These accessors are not macros in part because the assertions
have proven helpful while debugging \Ls/ and will likely continue
to do so but also to be able patch in the ability to trap access
from one thread to another's heap or to the shared heap (which will
need a read lock).

@c
Otag
ltag (cell o)
{
        assert(!special_p(o));
        return TAG(o);
}

cell
lcar (cell o)
{
        assert(!special_p(o));
        return ((Oatom *) o)->sin;
}

cell
lcdr (cell o)
{
        assert(!special_p(o));
        return ((Oatom *) o)->dex;
}

void
lcar_set_m (cell o,
            cell datum)
{
        assert(!special_p(o));
        assert(!ATOM_SIN_DATUM_P(o) || defined_p(datum));
        ((Oatom *) o)->sin = datum;
}

void
lcdr_set_m (cell o,
            cell datum)
{
        assert(!special_p(o));
        assert(!ATOM_DEX_DATUM_P(o) || defined_p(datum));
        ((Oatom *) o)->dex = datum;
}

@ Few of these shorthand accessors are actually used and none of
them is exposed at run-time but there is a whole page here before
the next major section starts and their existence adds no run-time
cost.

@d lcaar(O)   (        lcar(lcar(O))    )
@d lcadr(O)   (        lcar(lcdr(O))    )
@d lcdar(O)   (        lcdr(lcar(O))    )
@d lcddr(O)   (        lcdr(lcdr(O))    )
@d lcaaar(O)  (    lcar(lcar(lcar(O)))  )
@d lcaadr(O)  (    lcar(lcar(lcdr(O)))  )
@d lcadar(O)  (    lcar(lcdr(lcar(O)))  )
@d lcaddr(O)  (    lcar(lcdr(lcdr(O)))  )
@d lcdaar(O)  (    lcdr(lcar(lcar(O)))  )
@d lcdadr(O)  (    lcdr(lcar(lcdr(O)))  )
@d lcddar(O)  (    lcdr(lcdr(lcar(O)))  )
@d lcdddr(O)  (    lcdr(lcdr(lcdr(O)))  )
@d lcaaaar(O) (lcar(lcar(lcar(lcar(O)))))
@d lcaaadr(O) (lcar(lcar(lcar(lcdr(O)))))
@d lcaadar(O) (lcar(lcar(lcdr(lcar(O)))))
@d lcaaddr(O) (lcar(lcar(lcdr(lcdr(O)))))
@d lcadaar(O) (lcar(lcdr(lcar(lcar(O)))))
@d lcadadr(O) (lcar(lcdr(lcar(lcdr(O)))))
@d lcaddar(O) (lcar(lcdr(lcdr(lcar(O)))))
@d lcadddr(O) (lcar(lcdr(lcdr(lcdr(O)))))
@d lcdaaar(O) (lcdr(lcar(lcar(lcar(O)))))
@d lcdaadr(O) (lcdr(lcar(lcar(lcdr(O)))))
@d lcdadar(O) (lcdr(lcar(lcdr(lcar(O)))))
@d lcdaddr(O) (lcdr(lcar(lcdr(lcdr(O)))))
@d lcddaar(O) (lcdr(lcdr(lcar(lcar(O)))))
@d lcddadr(O) (lcdr(lcdr(lcar(lcdr(O)))))
@d lcdddar(O) (lcdr(lcdr(lcdr(lcar(O)))))
@d lcddddr(O) (lcdr(lcdr(lcdr(lcdr(O)))))

@* Segments. Memory can be allocated in any size (plus overhead)
in a segment. A segment is allocated in two parts, the allocated
memory itself and an atom on the heap to refer to it.

If the allocation is small enough and the object it's being allocated
for permits it (eg.~it has no particular memory alignment requirements)
then the storage for the segment will be within the atom itself.
This is used especially for short symbols and text.

The address of the allocation is referenced by a pointer object. This
object is the atom on the heap that contains the allocation's
address\footnote{$^1$}{If \Ls/ ever needs plain pointers the same
atomic structure with a new format will be used.} and owing to the
nature of the heap only half of the atom is needed --- the other
half is a ``spare'' datum that segment-like objects can use if
necessary or helpful.

@d pointer(O)         ((void *) lcar(O))
@d pointer_datum(O)   (lcdr(O))
@d pointer_erase_m(O) (lcar_set_m((O), (cell) NULL))
@d pointer_set_datum_m(O,D)
                      (lcdr_set_m((O), (cell) (D)))
@d pointer_set_m(O,D) (lcar_set_m((O), (cell) (D)))
@#
@d segint_p(O)        (segment_intern_p(O) || symbol_intern_p(O))
@d segint_address(O)  (segint_base(O)->buffer)
@d segint_base(O)     ((Ointern *) (O))
@d segint_header(O)   ((long) 0)
@d segint_length(O)   ((long) segint_base(O)->length)
@d segint_set_length_m(O,V)
                      (segint_base(O)->length = (V))
@d segint_owner(O)    (O)
@d segint_stride(O)   ((long) 1)
@#
@d segbuf_base(O)     ((Osegment *) pointer(O))
@d segbuf_address(O)  (segbuf_base(O)->address)
@d segbuf_header(O)   (segbuf_base(O)->header)
@d segbuf_length(O)   (segbuf_base(O)->length)
@d segbuf_next(O)     (segbuf_base(O)->next)
@d segbuf_owner(O)    (segbuf_base(O)->owner) /* |== O| */
@d segbuf_prev(O)     (segbuf_base(O)->prev)
@d segbuf_stride(O)   (segbuf_base(O)->stride ? segbuf_base(O)->stride : 1)
@#
@d segment_address(O) (segint_p(O) ? segint_address(O) : segbuf_address(O))
@d segment_base(O)    (segint_p(O) ? segint_base(O)    : segbuf_base(O))
@d segment_header(O)  (segint_p(O) ? segint_header(O)  : segbuf_header(O))
@d segment_length(O)  (segint_p(O) ? segint_length(O)  : segbuf_length(O))
@d segment_owner(O)   (segint_p(O) ? segint_owner(O)   : segbuf_owner(O))
@d segment_stride(O)  (segint_p(O) ? segint_stride(O)  : segbuf_stride(O))
@#
@d segment_set_owner_m(O,N) do {
        assert(pointer_p(O));
        segbuf_owner(O) = (N);
} while (0)
@<Type def...@>=
struct Osegment { /* Must remain pointer-aligned. */
 struct Osegment *next, *prev; /* Linked list of all allocated segments. */
        half length, stride; /* Notably absent: header size \AM\ alignment. */
        cell owner; /* The referencing atom; cleared and re-set during
                        garbage collection. */
        char address[]; /* Base address of the available space (occupies
                        no header space). */
};
typedef struct Osegment Osegment;

@ The process-wide global list of every allocated segment. As soon
as memory is successfully allocated it's added to this list. When
scanning for live objects during garbage collection fails to re-set
the owner (which have all been set to |NIL| prior to scanning) this
list can be scanned for unused allocations to release.

@<Global...@>=
shared Osegment *Allocations = NULL;

@ @<Fun...@>=
Osegment *segment_alloc_imp (Osegment *, long, long, long, long, sigjmp_buf *);
cell segment_init (Osegment *, cell);
cell segment_new_imp (Oheap *, long, long, long, long, Otag, sigjmp_buf *);
void segment_release_imp (Osegment *, bool);
void segment_release_m (cell, bool);
cell segment_resize_m (cell, long, long, sigjmp_buf *);

@ The memory underlying an allocated segment is obtained through
|segment_alloc| or its imp. The header size is -1 if the length and
stride together define the size to be allocated {\it including\/}
the segment's own header (this allows heap pages to (easily) be
exactly one operating system page).

If the stride value is zero then the real stride to calculate with
is one but zero is stored to indicate that if the segment is
subsequently reduced in size enough it can be interned.

The rather unpleasant looking test before aborting with |LERR_OOM|
takes advantage of {\it flagged arithmetic\/} if the \CEE/ compiler
allows for it. Flagged arithmetic uses the flags variously raised
after actually performing CPU arithmetic to detect overflow and
carry rather than defensively checking that the operands are within
range prior to each operation. After removing the noise the function
performed appears as |size = sizeof (Osegment) + header + (length
* stride)|.

If the allocation is new then it's inserted at the end of the
|Allocations| list.

TODO: These arguments should be |size_t| type.

@.TODO@>
@d segment_alloc(H,L,S,A,F) segment_alloc_imp(NULL, (H), (L), (S), (A), (F))
@c
Osegment *
segment_alloc_imp (Osegment   *old,
                   long        header,
                   long        length,
                   long        stride,@|
                   long        align,
                   sigjmp_buf *failure)
{
        long cstride;
        size_t size;
        Osegment *r;

        assert(header >= -1 && length >= 0 && stride >= 0);
        if (header == -1)
                header = - sizeof (Osegment);
        assert(old == NULL || stride == old->stride);
        assert(align == 0 || old == NULL);
        cstride = stride ? stride : 1;
        if (length > HALF_MAX || stride > HALF_MAX ||@|
                    ckd_mul(&size, length, cstride) ||@|
                    ckd_add(&size, size, header) ||
                    ckd_add(&size, size, sizeof (Osegment)))
                siglongjmp(*failure, LERR_OOM);
        r = mem_alloc(old, size, align, failure);
        r->length = length;
        if (old == NULL) {
                r->stride = stride;
                r->owner = NIL;
        }
        if (Allocations == NULL)
                Allocations = r->next = r->prev = r;
        else {
                r->next = Allocations;
                r->prev = Allocations->prev;
                Allocations->prev->next = r;
                Allocations->prev = r;
        }
        return r;
}

@ In most cases segment allocations are made by this function which
includes the support for creating an interned segment or it allocates
the memory and returns a new atom pointing to it.

TODO: These arguments should (probably) {\it not\/} be |size_t| but
they should probably not be |long| either.

@d segment_new(H,L,S,A,F) segment_new_imp(Theap, (H), (L), (S), (A),
        FORM_SEGMENT, (F))
@c
cell
segment_new_imp (Oheap      *heap,
                 long        header,
                 long        length,
                 long        stride,
                 long        align,
                 Otag        ntag,@|
                 sigjmp_buf *failure)
{
        cell r;
        long total;
        Osegment *s;

        assert(stride >= 0);
        assert(ntag != FORM_NONE);
        if (ckd_add(&total, header, length))
                siglongjmp(*failure, LERR_LIMIT);
        if (stride == 0 && total <= INTERN_BYTES) {
                if (ntag == FORM_SEGMENT)
                        ntag = FORM_SEGMENT_INTERN;
                else
                        assert(ntag == FORM_SYMBOL_INTERN);
                r = atom(heap, NIL, NIL, ntag, failure);
                segint_set_length_m(r, length);
                return r;
        }
        Tmp_ier = atom(heap, NIL, NIL, FORM_PAIR, failure);
        s = segment_alloc(header, length, stride, align, failure);
        TAG_SET_M(Tmp_ier, ntag);
        ATOM_TO_ATOM(Tmp_ier)->sin = (cell) s;
        s->owner = Tmp_ier;
        Tmp_ier = NIL;
        return s->owner;
}

@ When a segment is going to be used as a heap it may not be able
to allocate the pointer to it on an existing heap so the memory and
atom are allocated directly and |segment_init| sets up their
attributes correctly.

@c
cell
segment_init (Osegment *seg,
              cell      container)
{
        assert(!special_p(container));
        seg->owner = container;
        ATOM_TO_TAG(container) = FORM_HEAP;
        ATOM_TO_ATOM(container)->sin = (cell) seg;
        ATOM_TO_ATOM(container)->dex = NIL;
        return container;
}

@ A segment can be resized by passing it as an argument to
|segment_alloc_imp|. If the segment was and remains interned then
the stored length is simply updated or if the segment was and remains
allocated then the allocation is resized.

If a segment changes to/from being interned then a new allocation
is requested and the relevant data copied.

@c
cell
segment_resize_m (cell        o,
                  long        header,
                  long        delta,
                  sigjmp_buf *failure)
{
        Osegment *new, *old;
        long i, nlength, nstride;
        cell r = NIL;
        sigjmp_buf cleanup;
        Verror reason = LERR_NONE;

        assert(segment_p(o) || arraylike_p(o));
        assert(delta >= -segment_length(o));
        if (ckd_add(&nlength, segment_length(o), delta))
                siglongjmp(*failure, LERR_OOM);
        if (segment_intern_p(o) && nlength <= INTERN_BYTES) {
                segint_set_length_m(o, nlength);
                return o;
        } else if ((arraylike_p(o) || segment_stored_p(o)) &&
                    (segbuf_base(o)->stride || nlength > INTERN_BYTES)) {
                old = segbuf_base(o);
                nstride = segment_stride(o);
                segment_release_m(o, false);
                new = segment_alloc_imp(old, header, nlength, nstride, 0,
                        failure);
                pointer_set_m(o, new);
                return o;
        }
        assert(header == 0);
        assert(segment_stride(o) == 0);
        assert(null_p(Tmp_ier));
        Tmp_ier = o; /* BUG: |o| must mutate not be discarded. */
        if (failure_p(reason = sigsetjmp(cleanup, 1)))
                unwind(failure, reason, true, 0);
        r = segment_new(0, nlength, 0, 0, &cleanup);
        if (segment_length(Tmp_ier) < nlength)
                nlength = segment_length(Tmp_ier);
        for (i = 0; i < nlength; i++)
                segment_address(r)[i] = segment_address(Tmp_ier)[i];
        Tmp_ier = NIL;
        return r;
}

@ When a segment is released explicitly the pointer to it which is
in its heap atom is erased to avoid the possibility of using
deallocated memory.

@c
void
segment_release_m (cell o,
                   bool reclaim)
{
        assert(pointer_p(o)); /* Useful objects piggy-back on segments. */
        segment_release_imp(pointer(o), reclaim);
        pointer_erase_m(o); /* For safety. */
}

@ When a segment is released by the garbage collector its heap atom
has already been lost so it calls the release imp directly to remove
the segment from the |Allocations| list and reclaim the underlying
storage.

@c
void
segment_release_imp (Osegment *o,
                     bool      reclaim)
{
        if (o == Allocations)
                Allocations = o->next;
        if (o->next == o)
                Allocations = NULL;
        else
                o->prev->next = o->next,
                o->next->prev = o->prev;
        o->next = o->prev = o; /* For safety. */
        if (reclaim)
                mem_free(o);
}

@* Registers. To collect unused memory the garbage collector
recursively scans the descendents of every live atom. An atom is
considered live if it is referenced by an atom held in a {\it
register\/}. \Ls/ defines a number of registers for various purposes
which are explained as they are introduced.

@<Type def...@>=
enum {
        LGCR_TMPSIN, LGCR_TMPDEX, LGCR_TMPIER,@/
        LGCR_NULL,@/
        LGCR_SYMTABLE,@/
        LGCR_STACK,@/
        LGCR_PROTECT_0, LGCR_PROTECT_1, LGCR_PROTECT_2, LGCR_PROTECT_3,@/
        LGCR_EXPRESSION, LGCR_ENVIRONMENT, LGCR_ACCUMULATOR, LGCR_ARGUMENTS,
        LGCR_CLINK,@/
        LGCR_OPERATORS,@/
        LGCR_USER, LGCR_DEBUG,
        LGCR_COUNT
};

@ One register which is defined here is the user register which is
not used by \Ls/ for any purpose but is made available by the \Ls/
library.

@<Global...@>=
unique cell *Iregister[LGCR_COUNT];
shared cell  User_Register = NIL; /* Unused by \Ls/ --- for library users. */
shared cell  Debug_Register = NIL; /* Similar --- for the \Ls/ debugger. */

@ @<Extern...@>=
extern unique cell *Iregister[];
extern shared cell User_Register, Debug_Register;

@ This list of pointers to the registers is re-initialised once per
thread. Probably. The garbage collector updates the pointer if the
atom moves.

@<Save reg...@>=
Iregister[LGCR_TMPSIN]      = &Tmp_SIN;
Iregister[LGCR_TMPDEX]      = &Tmp_DEX;
Iregister[LGCR_TMPIER]      = &Tmp_ier;
Iregister[LGCR_NULL]        = &Null_Array;
Iregister[LGCR_SYMTABLE]    = &Symbol_Table;
Iregister[LGCR_STACK]       = &Stack;
Iregister[LGCR_PROTECT_0]   = Protect + 0;
Iregister[LGCR_PROTECT_1]   = Protect + 1;
Iregister[LGCR_PROTECT_2]   = Protect + 2;
Iregister[LGCR_PROTECT_3]   = Protect + 3;
Iregister[LGCR_EXPRESSION]  = &Expression;
Iregister[LGCR_ENVIRONMENT] = &Environment;
Iregister[LGCR_ACCUMULATOR] = &Accumulator;
Iregister[LGCR_ARGUMENTS]   = &Arguments;
Iregister[LGCR_CLINK]       = &Control_Link;
Iregister[LGCR_OPERATORS]   = &Root;
Iregister[LGCR_USER]        = &User_Register;
Iregister[LGCR_DEBUG]       = &Debug_Register;

@* Garbage Collection. \Ls/ includes two garbage collectors. A
small, simple but moderately slow mark-and-sweep collector and a
larger and more complicated but faster compacting collector.

When the compacting collector moves a live atom it's replaced with
a {\it collected\/} atom, sometimes called a tombstone, so that
references to it can be correctly updated. This object does not show
up outside the garbage collector.

@d collected_datum(O)         (lcar(O))
@d collected_set_datum_m(O,V) (lcar_set_m((O), (V)))
@<Fun...@>=
size_t gc_compacting (Oheap *, bool);
void gc_disown_segments (Oheap *);
cell gc_mark (Oheap  *, cell, bool, cell *, size_t *);
size_t gc_reclaim_heap (Oheap *);
void gc_release_segments (Oheap *);
size_t gc_sweeping (Oheap *, bool);

@ To collect a heap by sweeping up the unused atoms

@c
size_t
gc_sweeping (Oheap *heap,
             bool   segments)
{
        size_t count, remain;
        int i;
        Oatom *a;
        Oheap *p;

        assert((heap == Theap) || ((Sheap != NIL) && (heap == Sheap)));
        count = remain = 0;
        p = heap;
        while (p != NULL) {
                remain += HEAP_LENGTH;
                p = p->next;
        }
        if (segments)
                gc_disown_segments(heap);
        for (i = 0; i < PRIMITIVE_LENGTH; i++)
                Iprimitive[i].box = gc_mark(heap, Iprimitive[i].box,
                        false, NULL, &count);
        for (i = 0; i < LGCR_COUNT; i++)
                if (!special_p(*Iregister[i]))
                        *Iregister[i] = gc_mark(heap, *Iregister[i],
                                false, NULL, &count);
        p = heap;
        while (p != NULL) {
                a = HEAP_TO_LAST(p);
                p->free = (Oatom *) NIL;
                for (i = 0; i < HEAP_LENGTH; i++) {
                        a--;
                        if (ATOM_LIVE_P(a))
                                ATOM_CLEAR_LIVE_M(a);
                        else {
                                ATOM_TO_TAG(a) = FORM_NONE;
                                a->sin = NIL;
                                a->dex = (cell) p->free;
                                p->free = a;
                        }
                }
                p = p->next;
        }
        count += gc_reclaim_heap (heap);
        if (segments)
                gc_release_segments(heap);
        return remain - count;
}

@

@.TODO@>% see warning
@c
size_t
gc_compacting (Oheap *heap,
               bool   segments)
{
        size_t count, remain;
        int i;
        Oheap *last, *p;

        assert((heap == Theap) || ((Sheap != NIL) && (heap == Sheap)));
        count = remain = 0;
        p = heap;
        while (p != NULL) {
                last = p;
                remain += HEAP_LENGTH;
                p->pair->pair = NULL;
                p = p->next;
        }
        if (segments)
                gc_disown_segments(heap);
        for (i = 0; i < PRIMITIVE_LENGTH; i++)
                Iprimitive[i].box = gc_mark(heap, Iprimitive[i].box,
                        false, NULL, &count);
        for (i = 0; i < LGCR_COUNT; i++)
                if (!special_p(Iregister[i]))
                        *Iregister[i] = gc_mark(last, *Iregister[i],
                                true, NULL, &count);
        count += gc_reclaim_heap (heap);
        if (segments)
                gc_release_segments(heap);
        p = last;
        while (p != NULL) {
                p->pair->free = HEAP_TO_LAST(p->pair);
                for (i = 0; i < HEAP_LENGTH; i--) {
                        ATOM_TO_TAG(--p->pair->free) = FORM_NONE; /* warning:
                                operation on |p->pair->free| may be undefined */
                        p->pair->free->sin = p->pair->free->dex = NIL;
                }
                p->pair->pair = p;
                heap = p;
                p = p->next;
        }
        if (heap == Theap)
                Theap = last;
        else
                Sheap = last;
        return remain - count;
}

@ @c
size_t
gc_reclaim_heap (Oheap *heap)
{
        size_t count = 0;
        Oheap *h;

        do {
                h = heap;
                while (1) {
                        segment_init(HEAP_TO_SEGMENT(h), heap_alloc(heap, NULL));
                        count++;
                        if (h->next == NULL)
                                break;
                        h = h->next;
                }
        } while (h->pair != NULL && (h == Theap || h == Sheap));
        return count;
}

@ TODO: Use |heap| to determine whether this segment might be owned by another heap.

@.TODO@>
@c
void
gc_disown_segments (Oheap *heap @[Lunused@])
{
        Osegment *s;

        s = Allocations;
        while (1) {
                if (!null_p(s->owner) &&
                            (ATOM_TO_HEAP(s->owner)->pair == NULL ||
                                ATOM_TO_HEAP(s->owner)->pair->pair == NULL))
                        s->owner = NIL;
                if ((s = s->next) == Allocations)
                        break;
        }
}

@ TODO: Split in two? Rename?

@.TODO@>
@c
void
gc_release_segments (Oheap *heap @[Lunused@])
{
        Osegment *s, *n;

        s = Allocations;
        while (1) {
                n = s->next;
                if (null_p(s->owner))
                        segment_release_imp(s, true);
                if (n == Allocations)
                        break;
                s = n;
        }
}

@ @d atom_saved_p(O) (ATOM_TO_HEAP(O)->pair == NULL)
@c
cell
gc_mark (Oheap  *heap,
         cell    next,
         bool    compacting,
         cell   *cycles,
         size_t *remain)
{
        bool remember;
        cell copied, parent, tmp;
        long i;

        remember = (cycles != NULL && !null_p(*cycles));
        parent = tmp = NIL;
        while (1) {
                if (!special_p(next) && !ATOM_LIVE_P(next)) {
                        (*remain)++;
                        ATOM_SET_LIVE_M(next);
                        if (!compacting)
                                copied = next;
                        else {
                                @<Move the atom to a new heap@>
                        }
                        if (pointer_p(next))
                                segment_set_owner_m(next, copied);
                        else if (primitive_p(next))
                                Iprimitive[primitive(next)].box = next;
                        next = copied;
@#
                        if (ATOM_SIN_DATUM_P(next) &&@|
                                    ATOM_DEX_DATUM_P(next)) {
                                @<Mark the car of a pair-like atom@>
                        } else if (ATOM_SIN_DATUM_P(next)) {
                                @<Begin marking a sin-ward atom@>
                        } else if (ATOM_DEX_DATUM_P(next)) {
                                @<Begin marking a dex-ward atom@>
                        } else if (arraylike_p(next)) {
                                @<Begin marking an array@>
                        }
                }
@#
                else if (special_p(parent))
                        break;
@#
                else if (ATOM_SIN_DATUM_P(parent) && ATOM_DEX_DATUM_P(parent)) {
                        if (ATOM_MORE_P(parent)) {
                                @<Continue marking a pair-like atom@>
                        } else {
                                @<Finish marking a pair-like atom@>
                        }
                } else if (ATOM_SIN_DATUM_P(parent)) {
                        @<Finish marking a sin-ward atom@>
                } else if (ATOM_DEX_DATUM_P(parent)) {
                        @<Finish marking a dex-ward atom@>
                } else if (arraylike_p(parent)) {
                        i = array_progress(parent);
                        if (i < array_length(parent) - 1) {
                                @<Continue marking an array@>
                        } else {
                                @<Finish marking an array@>
                        }
                } else
                        next = parent;
        }
        if (collected_p(next))
                next = collected_datum(next);
        return next;
}

@ @<Move the atom to a new heap@>=
copied = heap_alloc(heap, NULL); /* TODO: Move last as the tail fills up? */
*ATOM_TO_ATOM(copied) = *ATOM_TO_ATOM(next);
TAG_SET_M(copied, form(next)); /* Without GC flags. */
collected_set_datum_m(next, copied);
TAG_SET_M(next, FORM_COLLECTED);

@ @<Begin marking a sin-ward atom@>=
tmp = ATOM_TO_ATOM(next)->sin; /* Unlive or recursive. */
if (remember && !special_p(tmp) && ATOM_LIVE_P(tmp))
        gc_serial(*cycles, tmp);
ATOM_TO_ATOM(next)->sin = parent;
parent = next;
next = tmp;

@ @<Finish marking a sin-ward atom@>=
tmp = parent;
parent = ATOM_TO_ATOM(tmp)->sin;
if (collected_p(next))
        next = collected_datum(next);
ATOM_TO_ATOM(tmp)->sin = next;
next = tmp;

@ @<Begin marking a dex-ward atom@>=
tmp = ATOM_TO_ATOM(next)->dex; /* Unlive or recursive. */
if (remember && !special_p(tmp) && ATOM_LIVE_P(tmp))
        gc_serial(*cycles, tmp);
ATOM_TO_ATOM(next)->dex = parent;
parent = next;
next = tmp;

@ @<Finish marking a dex-ward atom@>=
tmp = parent;
parent = ATOM_TO_ATOM(tmp)->dex;
if (collected_p(next))
        next = collected_datum(next);
ATOM_TO_ATOM(tmp)->dex = next;
next = tmp;

@ @<Mark the car of a pair-like atom@>=
ATOM_SET_MORE_M(next);
tmp = ATOM_TO_ATOM(next)->sin; /* Unlive or recursive. */
if (remember && !special_p(tmp) && ATOM_LIVE_P(tmp))
        gc_serial(*cycles, tmp);
ATOM_TO_ATOM(next)->sin = parent;
parent = next;
next = tmp;

@ Leave |parent| alone so we come back to this object after completing
|dex|.

@<Continue marking a pair-like atom@>=
ATOM_CLEAR_MORE_M(parent);
tmp = ATOM_TO_ATOM(parent)->dex; /* Unlive or recursive. */
if (remember && !special_p(tmp) && ATOM_LIVE_P(tmp))
        gc_serial(*cycles, tmp);
ATOM_TO_ATOM(parent)->dex = ATOM_TO_ATOM(parent)->sin;
if (collected_p(next))
        next = collected_datum(next);
ATOM_TO_ATOM(parent)->sin = next;
next = tmp;

@ @<Finish marking a pair-like atom@>=
tmp = ATOM_TO_ATOM(parent)->dex;
if (collected_p(next))
        next = collected_datum(next);
ATOM_TO_ATOM(parent)->dex = next;
next = parent;
parent = tmp;

@ @<Begin marking an array@>=
i = 0;
if (array_length(next) > 0) {
        ATOM_SET_MORE_M(next);
        array_set_progress_m(next, i);
        tmp = array_ref(next, i); /* Unlive or recursive. */
        if (remember && !special_p(tmp) && ATOM_LIVE_P(tmp))
                gc_serial(*cycles, tmp);
        array_set_m(next, i, parent);
        parent = next;
        next = tmp;
}

@ @<Continue marking an array@>=
assert(ATOM_MORE_P(parent)); /* Not actually useful for arrays. */
i++;
tmp = array_ref(parent, i); /* Unlive or recursive. */
if (remember && !special_p(tmp) && ATOM_LIVE_P(tmp))
        gc_serial(*cycles, tmp);
array_set_m(parent, i, array_ref(parent, i - 1));
if (collected_p(next))
        next = collected_datum(next);
array_set_m(parent, i - 1, next);
next = tmp;
array_set_progress_m(parent, i);

@ @<Finish marking an array@>=
ATOM_CLEAR_MORE_M(parent);
tmp = array_ref(parent, i);
if (collected_p(next))
        next = collected_datum(next);
array_set_m(parent, i, next);
next = parent;
parent = tmp;

@** Structural Data. Two arrangements of memory available to \Ls/
have been introduced, fixed-size atoms and dynamically-sized segments.
An atom without further specialisation is a standard pair for which
a complete API is already available. This section describe formats
which combine these into various useful structures.

Owing to its ubiquitous presence and aided by being at the top of
the alphabet the first of these will be arrays.

@* Arrays.

@<Global...@>=
shared cell Null_Array = NIL;

@ @<Extern...@>=
extern shared cell Null_Array;

@ @<Init...@>=
Null_Array = array_new_imp(0, NIL, FORM_ARRAY, failure);

@
@d array_progress(O)         (fix_value(pointer_datum(O)))
@d array_set_progress_m(O,V) (pointer_set_datum_m((O), fix(V)))
@d array_length(O)           (segment_length(O))
@d array_address(O)          ((cell *) segment_address(O))
@<Fun...@>=
cell array_new_imp (long, cell, Otag, sigjmp_buf *);
cell array_grow (cell, long, cell, sigjmp_buf *);
cell array_grow_m (cell, long, cell, sigjmp_buf *);
cell array_ref (cell, long);
void array_set_m (cell, long, cell);

@ @d array_new(L,F) ((L) == 0 ? Null_Array :
        array_new_imp((L), NIL, FORM_ARRAY, (F)))
@c
cell
array_new_imp (long        length,
               cell        fill,
               Otag        ntag,
               sigjmp_buf *failure)
{
        cell r;
        long i;
        sigjmp_buf cleanup;
        Verror reason = LERR_NONE;

        assert(length >= 0);
        assert(null_p(Tmp_ier));
        if (failure_p(reason = sigsetjmp(cleanup, 1)))
                unwind(failure, reason, true, 0);
        Tmp_ier = fill; /* Safe because |segment_new_imp| won't use |Tmp_ier|. */
        r = segment_new_imp(Theap, 0, length, sizeof (cell),
                sizeof (cell), ntag, &cleanup);
        if (defined_p(Tmp_ier) && length > 0) {
                array_set_m(r, 0, Tmp_ier);
                for (i = 1; i < length; i++)
                        array_address(r)[i] = array_address(r)[0];
        }
        Tmp_ier = NIL;
        return r;
}

@ I think the interface between this and |segment_resize_m| kept
growing bugs which is why they are currently independent.

@c
cell
array_grow (cell        o,
            long        delta,
            cell        fill,
            sigjmp_buf *failure)
{
        static int Sobject = 1, Sfill = 0;
        long i, j, nlength, slength;
        cell r;
        sigjmp_buf cleanup;
        Verror reason = LERR_NONE;

        assert(arraylike_p(o) && o != Stack);
        assert(delta && delta >= -array_length(o));
        if (ckd_add(&nlength, array_length(o), delta))
                siglongjmp(*failure, LERR_OOM);
@#
        stack_protect(1, fill, failure);
        if (failure_p(reason = sigsetjmp(cleanup, 1)))
                unwind(failure, reason, false, 1);
        r = array_new_imp(nlength, UNDEFINED, FORM_ARRAY, &cleanup);
        slength = delta >= 0 ? array_length(SO(Sobject)) : nlength;
        for (i = 0; i < slength; i++)
                array_set_m(r, i, array_ref(SO(Sobject), i));
        if (defined_p(fill)) {
                if (i < nlength)
                        array_set_m(r, i, SO(Sfill));
                for (j = i + 1; j < nlength; j++)
                        array_address(r)[j] = array_address(r)[i];
        }
        stack_clear(1);
        return r;
}

@ @c
cell
array_grow_m (cell        o,
              long        delta,
              cell        fill,
              sigjmp_buf *failure)
{
        static int Sfill = 0; /* Also |Tmp_ier| in case the stack is resizing. */
        bool isstack;
        cell r;
        long i, slength;
        sigjmp_buf cleanup;
        Verror reason = LERR_NONE;

        assert(arraylike_p(o));
        assert(delta && delta >= -array_length(o));
        assert(null_p(Tmp_ier));
        Tmp_ier = o; /* Safe because |Tmp_ier| will never be an interned segment. */
        if (!(isstack = (o == Stack)))
                stack_protect(1, fill, failure);
        if (failure_p(reason = sigsetjmp(cleanup, 1)))
                unwind(failure, reason, true, isstack ? 1 : 0);
        slength = array_length(Tmp_ier);
        r = segment_resize_m(Tmp_ier, sizeof (cell), delta, &cleanup);
        if (!isstack && delta > 0 && defined_p(SO(Sfill))) {
                for (i = slength; i < array_length(r); i++)
                        if (i == slength)
                                array_set_m(r, i, SO(Sfill));
                        else
                                array_address(r)[i] = array_address(r)[slength];
        }
        Tmp_ier = NIL;
        if (!isstack)
                stack_clear(1);
        return r;
}

@ @c
cell
array_ref (cell o,
           long idx)
{
        assert(arraylike_p(o));
        assert(idx >= 0 && idx < array_length(o));
        return array_address(o)[idx];
}

@ @c
void
array_set_m (cell o,
             long idx,
             cell d)
{
        assert(arraylike_p(o));
        assert(idx >= 0 && idx < array_length(o));
        assert(defined_p(d));
        array_address(o)[idx] = d;
}

@* Symbols \AM\ Tables. All symbols are saved in the global
|Symbol_Table|. Their location is determined by calculating a hash
over the symbol's label. The hash calculation function used here
was originally written by K\AM R and was copied from pdksh (as was
most of the table implementation).

@<Type def...@>=
typedef uint32_t Vhash;

@ @<Fun...@>=
Vhash hash_cstr (char *, long *, sigjmp_buf *);
Vhash hash_buffer (char *, long, sigjmp_buf *);

@ @c
Vhash
hash_cstr (char       *buf,
           long       *length,
           sigjmp_buf *failure)
{
        Vhash r = 0;
        char *p = buf;

        while (*p != '\0')
                if (Interrupt)
                        siglongjmp(*failure, LERR_INTERRUPT);
                else
                        r = 33 * r + (unsigned char) (*p++);
        *length = p - buf;
        return r;
}

@ Interned symbols call this with NULL but are small so it's safe
to ignore interrupts.

@c
Vhash
hash_buffer (char       *buf,
             long        length,
             sigjmp_buf *failure)
{
        Vhash r = 0;
        long i;

        assert(length >= 0);
        for (i = 0; i < length; i++)
                if (Interrupt && failure != NULL)
                        siglongjmp(*failure, LERR_INTERRUPT);
                else
                        r = 33 * r + (unsigned char) (*buf++);
        return r;
}

@ To distinguish them from database tables (relations) the array
used by hashes for constant-time search is called a hash table.
When used casually the term hash may usually refers to the hash
table but may also mean the hash value.

A hash table works best when the array is not allowed to get too
full (increasing the liklihood of collisions) so an array one cell
longer than specified is allocated and the last element records how
many cells remain unused.

|Null_Array| can masquerade as an empty hash table.

@d HASHTABLE_MINLENGTH          8
@d HASHTABLE_MAXLENGTH          (INT_MAX >> 1)
@#
@d hashtable_blocked(O)         (null_array_p(O) ? 0 :
        fix_value(array_ref((O), array_length(O) - 2)))
@d hashtable_free(O)            (null_array_p(O) ? 0 :
        fix_value(array_ref((O), array_length(O) - 1)))
@d hashtable_blocked_p(O)       (hashtable_blocked(O) > 0)
@d hashtable_free_p(O)          (hashtable_free(O) > 0)
@d hashtable_length(O)          (null_array_p(O) ? (long) 0 : array_length(O) - 2)
@d hashtable_ref(O,I)           (array_ref((O), (I)))
@d hashtable_set_blocked_m(O,V) (array_set_m((O), array_length(O) - 2, fix(V)))
@d hashtable_set_free_m(O,V)    (array_set_m((O), array_length(O) - 1, fix(V)))
@<Fun...@>=
cell hashtable_delete_m (cell, cell, cell, bool, sigjmp_buf *);
cell hashtable_enlarge_m (cell, Vhash (*)(cell, sigjmp_buf *), sigjmp_buf *);
cell hashtable_insert_m (cell, cell, cell, bool, sigjmp_buf *);
int hashtable_match (cell, void *, sigjmp_buf *);
cell hashtable_new_imp (long, sigjmp_buf *);
Vhash hashtable_rehash (cell, sigjmp_buf *);
void hashtable_remove_m (cell, long);
cell hashtable_replace_m (cell, cell, cell, bool, sigjmp_buf *);
void hashtable_save_m (cell, long, cell, bool);
int hashtable_scan (cell, Vhash, int (*)(cell, void *, sigjmp_buf *),
        void *, sigjmp_buf *);
cell hashtable_search (cell, cell, sigjmp_buf *);
cell hashtable_set_imp (cell, cell, cell, Vmaybe, sigjmp_buf *);
cell hashtable_fetch (cell, cell, sigjmp_buf *);
cell hashtable_pairs (cell, cell (*accessor)(cell), sigjmp_buf *);

@ If the table is small enough then the cost of a hash collision
is low so it is permitted to fill up otherwise the number of cells
free is set to $\lfloor70\%\rfloor$ of the array's size.

@d hashtable_new(L,F) ((L) == 0 ? Null_Array : hashtable_new_imp((L), (F)))
@c
cell
hashtable_new_imp (long        length,
                   sigjmp_buf *failure)
{
        cell r;
        long f;

        assert(length > 0);
        if (length >= HASHTABLE_MAXLENGTH)
                siglongjmp(*failure, LERR_LIMIT);
        else if (length <= HASHTABLE_MINLENGTH)
                f = (length = HASHTABLE_MINLENGTH) - 2;
        else
                f = (7 * (length = 1 << (high_bit(length) - 1))) / 10;
        r = array_new_imp(length + 2, NIL, FORM_HASHTABLE, failure);
        hashtable_set_blocked_m(r, 0);
        hashtable_set_free_m(r, f);
        return r;
}

@ If a value is being inserted into the hash table but it has reached
capacity then it gets enlarged to the next power-of-two size and
its contents are re-distributed.

TODO: Shrink the table if there are sufficient blocked cells (or
in delete).

@.TODO@>
@c
cell
hashtable_enlarge_m (cell        o,
                     Vhash     (*hashfn)(cell, sigjmp_buf *),
                     sigjmp_buf *failure)
{
        static int Sobject = 1, Stmp = 0;
        cell n, s;
        long i, j, nlength;
        long nfree;
        Vhash nhash;
        sigjmp_buf cleanup;
        Verror reason = LERR_NONE;

        assert(hashtable_p(o));
        nlength = hashtable_length(o);
        if (nlength >= (INT_MAX >> 2))
                siglongjmp(*failure, LERR_LIMIT);
        if (nlength == 0)
                nfree = (nlength = HASHTABLE_MINLENGTH) - 2;
        else {
                if (!hashtable_blocked_p(o))
                        nlength <<= 1;
                nfree = (7 * nlength) / 10; /* $\lfloor70\%\rfloor$ */
        }
        stack_protect(2, o, NIL, failure);
        if (failure_p(reason = sigsetjmp(cleanup, 1)))
                unwind(failure, reason, false, 2);
        SS(Stmp, n = hashtable_new(nlength, &cleanup));
        for (i = 0; i < hashtable_length(SO(Sobject)); i++)
                if (Interrupt)
                        siglongjmp(cleanup, LERR_INTERRUPT);
                else if (!null_p((s = array_ref(SO(Sobject), i))) && defined_p(s)) {
                        nhash = hashfn(s, &cleanup);
                        for (j = nhash % nlength;
                            !null_p(hashtable_ref(n, j));
                            j--)
                                if (j == 0)
                                        j = nlength - 1;
                        array_set_m(n, j, s);
                        nfree--;
                }
        n = SO(Stmp);
        hashtable_set_blocked_m(n, 0);
        hashtable_set_free_m(n, nfree);
        if (pointer_p(SO(Sobject)) && !null_array_p(SO(Sobject))) {
                o = SO(Sobject);
                pointer_set_m(o, pointer(n));
        } else
                o = n;
        stack_clear(2);
        return o;
}

@ If the location indicated by a hash value is in use the next
unused array element is located and returned, {\it regardless\/}
of whether the table is full.

@c
int
hashtable_scan (cell        o,
                Vhash       hash,
                int       (*match)(cell, void *, sigjmp_buf *),
                void       *ctx,
                sigjmp_buf *failure)
{
        int p, r;

        assert(hashtable_p(o));
        if (null_array_p(o))
                return FAIL;
        for (r = hash % hashtable_length(o);
                    !null_p(hashtable_ref(o, r));
                    r--) {
                if (defined_p(hashtable_ref(o, r))) {
                        p = match(hashtable_ref(o, r), ctx, failure);
                        if (p == 0)
                                return r;
                }
                if (r == 0)
                        r = hashtable_length(o) - 1;
        }
        return r;
}

@ If the table has space remaining (possibly after having been
enlarged to make some) the space located by |hashtable_scan| can be
claimed.

@c
void
hashtable_save_m (cell o,
                  long idx,
                  cell datum,
                  bool replace)
{
        assert(hashtable_p(o));
        assert(idx >= 0 && idx < hashtable_length(o));
        assert(replace || hashtable_free_p(o));
        if (!replace)
                assert(null_p(hashtable_ref(o, idx)));
        if (null_p(hashtable_ref(o, idx)))
                hashtable_set_free_m(o, hashtable_free(o) - 1);
        array_set_m(o, idx, datum);
}

@ If a value is removed from a hash table then it will no longer
participate in a collision which may have caused another value to
have been stored out-of-place.

Rather than shuffling everything below the removed item as this
algorithm does, causing a yet-to-be-discovered bug, the removed
entry ought to be replaced with a sentinel and the number of them
counted against the need to enlarge when there is no free space.

@c
void
hashtable_remove_m (cell o,
                    long idx)
{
        assert(hashtable_p(o));
        assert(idx >= 0 && idx < hashtable_length(o));
        assert(!null_p(hashtable_ref(o, idx)));
        assert(defined_p(hashtable_ref(o, idx)));
        array_set_m(o, idx, UNDEFINED);
        hashtable_set_blocked_m(o, hashtable_blocked(o) + 1);
        hashtable_set_free_m(o, hashtable_free(o) + 1);
}

@ The symbol table associates a hash value computed from a symbol
label to a symbol atom. A hash table is made to associate a symbol
with an arbitrary object, for use in environments (below) or as a
run-time data structure, by storing a pair with the symbol in one
half and the datum in the other.

Insertion and replacement are the same except for whether the entry
must or must not already be present.

@c
cell
hashtable_insert_m (cell        o,
                    cell        label,
                    cell        datum,
                    bool        permissive,
                    sigjmp_buf *failure)
{
        assert(defined_p(datum));
        return hashtable_set_imp(o, label, datum,
                (permissive ? CAN : CANNOT), failure);
}

cell
hashtable_replace_m (cell        o,
                     cell        label,
                     cell        datum,
                     bool        permissive,
                     sigjmp_buf *failure)
{
        assert(defined_p(datum));
        return hashtable_set_imp(o, label, datum,
                (permissive ? CAN : MUST), failure);
}

@ |masked| is carried as a cell to match the \CEE/ function signature
of insert \AM\ replace.

@c
cell
hashtable_delete_m (cell        o,
                    cell        label,
                    cell        masked,
                    bool        permissive,
                    sigjmp_buf *failure)
{
        int idx;

        assert(symbol_p(label));
        assert(boolean_p(masked));
        if (true_p(masked))
                hashtable_set_imp(o, label, UNDEFINED, MUST, failure);
        else {
                idx = hashtable_search(o, label, failure);
                if (idx == FAIL || null_p(hashtable_ref(o, idx))) {
                        if (!permissive)
                                siglongjmp(*failure, LERR_MISSING);
                } else
                        hashtable_remove_m(o, idx);
        }
        return o;
}

@ @c
cell
hashtable_set_imp (cell        o,
                   cell        label,
                   cell        datum,
                   Vmaybe      replace,
                   sigjmp_buf *failure)
{
        static int Sobject = 2, Slabel = 1, Sdatum = 0;
        cell r, table;
        Vhash hash;
        long idx;
        sigjmp_buf cleanup;
        Verror reason = LERR_NONE;

        assert(hashtable_p(o));
        assert(symbol_p(label));
        /* |datum| validated by caller --- in particular it could be |UNDEFINED|. */
        stack_protect(3, o, label, datum, failure);
        if (failure_p(reason = sigsetjmp(cleanup, 1)))
                unwind(failure, reason, false, 3);
        hash = symbol_hash(SO(Slabel));
again:
        table = SO(Sobject);
        idx = hashtable_scan(table, hash, hashtable_match,
                (void *) SO(Slabel), &cleanup);
        if (idx == FAIL || null_p(hashtable_ref(table, idx))) {
                if (replace == MUST)
                        siglongjmp(*failure, LERR_MISSING);
                if (!hashtable_free_p(table)) {
                        SS(Sobject, hashtable_enlarge_m(table,
                                hashtable_rehash, &cleanup));
                        goto again;
                }
        } else if (replace == CANNOT)
                siglongjmp(*failure, LERR_EXISTS);
        hashtable_save_m(SO(Sobject), idx,
                cons(SO(Slabel), SO(Sdatum), &cleanup), replace != CANNOT);
        r = SO(Sobject);
        stack_clear(3);
        return r;
}

@ @c
int
hashtable_match (cell        binding,
                 void       *ctx,
                 sigjmp_buf *failure @[Lunused@])
{
        cell maybe = (cell) ctx;

        assert(symbol_p(maybe));
        assert(pair_p(binding));
        assert(symbol_p(lcar(binding)));
        return ((lcar(binding) == maybe) ? 0 : -1);
}

@ @c
Vhash
hashtable_rehash (cell        o,
                  sigjmp_buf *failure @[Lunused@])
{
        assert(pair_p(o) && symbol_p(lcar(o)));
        return symbol_hash(lcar(o));
}

@ @c
cell
hashtable_search (cell        o,
                  cell        label,
                  sigjmp_buf *failure)
{
        cell r;
        long idx;

        assert(hashtable_p(o));
        assert(symbol_p(label));
        idx = hashtable_scan(o, symbol_hash(label), hashtable_match,
                (void *) label, failure);
        if (idx == FAIL)
                return UNDEFINED;
        r = hashtable_ref(o, idx);
        if (null_p(r))
                return UNDEFINED;
        else
                return r;
}

@ @c
cell
hashtable_pairs (cell        o,
                 cell      (*accessor)(cell),
                 sigjmp_buf *failure)
{
        static int Sobject = 2, Stmp = 1, Sret = 0;
        cell next, p, r;
        int i;
        sigjmp_buf cleanup;
        Verror reason = LERR_NONE;

        assert(hashtable_p(o));
        if (null_p(o))
                return o;
        stack_protect(3, o, NIL, NIL, failure);
        if (failure_p(reason = sigsetjmp(cleanup, 1)))
                unwind(failure, reason, false, 3);
        SS(Sret, cons(NIL, NIL, &cleanup));
        SS(Stmp, SO(Sret));
        for (i = 0; i < hashtable_length(SO(Sobject)); i++) {
                p = hashtable_ref(SO(Sobject), i);
                if (null_p(p) || undefined_p(p) || undefined_p(lcar(p)))
                        continue;
                if (accessor == NULL)
                        next = p;
                else
                        next = accessor(p);
                next = cons(next, NIL, &cleanup);
                lcdr_set_m(SO(Stmp), next);
                SS(Stmp, next);
        }
        r = lcdr(SO(Sret));
        stack_clear(3);
        return r;
}

@ @c
cell
hashtable_fetch (cell        o,
                 cell        label,
                 sigjmp_buf *failure)
{
        cell r;

        assert(hashtable_p(o));
        assert(symbol_p(label));
        r = hashtable_search(o, label, failure);
        return r;
}

@ @d SYMBOL_MAX        INT_MAX
@d Symbol_Table_ref(I) (hashtable_ref(Symbol_Table, (I)))
@#
@<Global...@>=
shared cell Symbol_Table = NIL;

@ @<Init...@>=
Symbol_Table = hashtable_new(0, failure);

@ @<Fun...@>=
int symbol_table_match (cell, void *, sigjmp_buf *);
long symbol_table_search (Vhash, Osymbol_compare, sigjmp_buf *);
Vhash symbol_table_rehash (cell s, sigjmp_buf *);
cell symbol_new_buffer (char *, long, sigjmp_buf *);
cell symbol_new_imp (Vhash, char  *, long, sigjmp_buf *);

@ @d symint_base(O) ((Osymbol *) NULL)
@d symint_buffer(O) ((char *) segment_address(O))
@d symint_hash(O)   (hash_buffer(symbol_buffer(O), symbol_length(O), NULL))
@#
@d symbuf_base(O)   ((Osymbol *) segment_address(O))
@d symbuf_buffer(O) (symbuf_base(O)->buffer)
@d symbuf_hash(O)   (symbuf_base(O)->hash)
@#
@d symbol_buffer(O) (symbol_intern_p(O) ? symint_buffer(O) : symbuf_buffer(O))
@d symbol_hash(O)   (symbol_intern_p(O) ? symint_hash(O) : symbuf_hash(O))
@d symbol_length(O) (segment_length(O))
@<Type def...@>=
typedef struct {
        Vhash hash;
        char  buffer[];
} Osymbol;

typedef struct {
        char *buf;
        int   length;
} Osymbol_compare;

@ @c
int
symbol_table_match (cell        symbol,
                    void       *ctx,
                    sigjmp_buf *failure)
{
        Osymbol_compare *scmp = ctx;
        int i;

        assert(symbol_p(symbol));
        if (symbol_length(symbol) > scmp->length)
                return 1;
        if (symbol_length(symbol) < scmp->length)
                return 1;
        for (i = 0; i < scmp->length; i++) {
                if (Interrupt)
                        siglongjmp(*failure, LERR_INTERRUPT);
                if (symbol_buffer(symbol)[i] > scmp->buf[i])
                        return 1;
                if (symbol_buffer(symbol)[i] < scmp->buf[i])
                        return 1;
        }
        return 0;
}

@ @c
long
symbol_table_search (Vhash           hash,
                     Osymbol_compare scmp,
                     sigjmp_buf     *failure)
{
        return hashtable_scan(Symbol_Table, hash, symbol_table_match,
                &scmp, failure);
}

@ @c
Vhash
symbol_table_rehash (cell        s,
                     sigjmp_buf *failure @[Lunused@])
{
        Vhash r;

        assert(symbol_p(s));
        r = symbol_hash(s);
        return r;
}

@ @d symbol_new_segment(O,F) (symbol_new_buffer(segment_address(O),
        segment_length(O), (F)))
@d symbol_new_const(O)       (symbol_new_buffer((O), -1, NULL))
@c
cell
symbol_new_buffer (char       *buf,
                   long        length,
                   sigjmp_buf *failure)
{
        Vhash hash;

        assert(length >= -1);
        if (length == -1)
                hash = hash_cstr(buf, &length, failure);
        else
                hash = hash_buffer(buf, length, failure);
        if (length > SYMBOL_MAX)
                siglongjmp(*failure, LERR_LIMIT);
        return symbol_new_imp(hash, buf, length, failure);
}

@ @c
cell
symbol_new_imp (Vhash       hash,
                char       *buf,
                long        length,
                sigjmp_buf *failure)
{
        cell new, r = NIL;
        int i, idx;
        Osymbol_compare scmp = { buf, length };

        assert(length >= 0);
search:
        idx = symbol_table_search(hash, scmp, failure);
        if (idx == FAIL || (null_p(hashtable_ref(Symbol_Table, idx)) &&
                    !hashtable_free_p(Symbol_Table))) {
                new = hashtable_enlarge_m(Symbol_Table, symbol_table_rehash, failure);
                Symbol_Table = new;
                goto search;
        }
        if (!null_p(hashtable_ref(Symbol_Table, idx)))
                return hashtable_ref(Symbol_Table, idx);
@#
        if (length <= INTERN_BYTES)
                r = segment_new_imp(Theap, 0, length, 0, 0,
                        FORM_SYMBOL_INTERN, failure);
        else {
                r = segment_new_imp(Theap, sizeof (Osymbol), length, 0, 0,
                        FORM_SYMBOL, failure);
                symbuf_base(r)->hash = hash;
        }
        for (i = 0; i < length; i++)
                symbol_buffer(r)[i] = buf[i];
        hashtable_save_m(Symbol_Table, idx, r, false);
        return r;
}

@* Trees \AM\ Double-Linked Lists.

Basic structure: An |LTAG_BOTH| atom with a datum in sin and link
pair in dex. Link pair is another |LTAG_BOTH| atom who's contents are
|NIL| or an object with the same form (ie.~same threading attributes).

The actual format of the link pair is irrelevant to structure
provided it's |LTAG_BOTH| so its a |FORM_TREE| with the {\it lower\/}
sin and dex bits (which do not affect the garbage collecter) raised
with the link in question is a thread.

A doubly-linked list looks identical and is distinguished by having
its link pair atom be formatted as a |FORM_PAIR|.

The three formats tree, rope and doubly-linked list are identified
by |tree_p|, |rope_p| and |dlist_p| respectively. Threading can be
identified by {\it sin\_threadable\/} or {\it dex\_threadable\/}
inserted into the predicate name as for example |tree_sin_threadable_p|
(doubly-linked lists cannot be threaded). The shared accessors
|treeish_p| (et al.) and |dryadic_p| identify an object as either
a tree or a rope, or as one of all three.

Accessors which work on any of these objects use the {\it dryad\/}
namespace while specific accessors use {\it tree\/} or {\it rope\/}.

NOT TRUE:
Accessors to the threads themselves are within the {\it tree\_thread\/}
namespace (except for the predicates). After an atom has been
identified as a rope or a tree the way they process their threads
is the same so there is no need for a {\it rope\_thread\/} namespace.

A rope's link pair atom is always a tree variant even though |dlist_p|
will treat a rope who's link pair is a plain |FORM_PAIR| pair as a
doubly-linked list. This arrangement is unintentional and not used.

@d dryad_datum(O)         (lcar(O))
@d dryad_link(O)          (lcdr(O))
@d dryad_sin(O)           (lcadr(O))
@d dryad_dex(O)           (lcddr(O))
@d dryad_sin_p(O)         (!null_p(dryad_sin(O)))
@d dryad_dex_p(O)         (!null_p(dryad_dex(O)))
@d dryad_set_sin_m(O,V)   (lcar_set_m(lcdr(O), (V)))
@d dryad_set_dex_m(O,V)   (lcdr_set_m(lcdr(O), (V)))
@#
@d dryadic_p(O)           (!special_p(O) &&
        (form(O) & FORM_ROPE) == FORM_ROPE)
@d dlist_p(O)             (dryadic_p(O) && pair_p(dryad_link(O)))
@d treeish_p(O)           (dryadic_p(O) && !dlist_p(O)) /* Any tree or rope. */
@d tree_p(O)              (treeish_p(O) &&
        (form(O) & FORM_TREE) == FORM_TREE) /* Any tree. */
@d plain_tree_p(O)        (treeish_p(O) && form_p((O), TREE))
@d rope_p(O)              (treeish_p(O) &&
        (form(O) & FORM_TREE) == FORM_ROPE) /* Any rope. */
@d plain_rope_p(O)        (treeish_p(O) && form_p((O), ROPE))

@ The link of a threaded tree which is not |NIL| may be a descendent
link or a thread to a sinward or dexward peer. The format of the
link atom indicates whether a non-|NIL| link is real or a thread.

@d treeish_sin_threadable_p(O) (treeish_p(O) && (form(O) & LTAG_TSIN))
@d treeish_dex_threadable_p(O) (treeish_p(O) && (form(O) & LTAG_TDEX))
@d tree_sin_threadable_p(O)    (tree_p(O) && treeish_sin_threadable_p(O))
@d tree_dex_threadable_p(O)    (tree_p(O) && treeish_dex_threadable_p(O))
@d tree_threadable_p(O)        (tree_sin_threadable_p(O) && tree_dex_threadable_p(O))
@d rope_sin_threadable_p(O)    (rope_p(O) && treeish_sin_threadable_p(O))
@d rope_dex_threadable_p(O)    (rope_p(O) && treeish_dex_threadable_p(O))
@d rope_threadable_p(O)        (rope_sin_threadable_p(O) && rope_dex_threadable_p(O))
@#
@d treeish_sin_has_thread_p(O) (treeish_sin_threadable_p(O) && dryad_sin_p(O) &&@|
        (form(dryad_link(O)) & LTAG_TSIN))
@d treeish_dex_has_thread_p(O) (treeish_dex_threadable_p(O) && dryad_dex_p(O) &&@|
        (form(dryad_link(O)) & LTAG_TDEX))
@d tree_sin_has_thread_p(O)    (tree_p(O) && treeish_sin_has_thread_p(O))
@d tree_dex_has_thread_p(O)    (tree_p(O) && treeish_dex_has_thread_p(O))
@d rope_sin_has_thread_p(O)    (rope_p(O) && treeish_sin_has_thread_p(O))
@d rope_dex_has_thread_p(O)    (rope_p(O) && treeish_dex_has_thread_p(O))
@#
@d tree_thread_set_sin_thread_m(O) (TAG_SET_M(dryad_link(O),
        form(dryad_link(O) | LTAG_TSIN)))
@d tree_thread_set_sin_live_m(O)   (TAG_SET_M(dryad_link(O),
        form(dryad_link(O) & ~LTAG_TSIN)))
@d tree_thread_set_dex_thread_m(O) (TAG_SET_M(dryad_link(O),
        form(dryad_link(O) | LTAG_TDEX)))
@d tree_thread_set_dex_live_m(O)   (TAG_SET_M(dryad_link(O),
        form(dryad_link(O) & ~LTAG_TDEX)))
@#
@d tree_thread_live_sin(O)     (treeish_sin_has_thread_p(O) ? NIL : dryad_sin(O))
@d tree_thread_live_dex(O)     (treeish_dex_has_thread_p(O) ? NIL : dryad_dex(O))
@d tree_thread_next_sin(O,F)   (anytree_next_sin((O), (F)))
@d tree_thread_next_dex(O,F)   (anytree_next_dex((O), (F)))

@ @<Fun...@>=
cell anytree_next_sin (cell, sigjmp_buf *);
cell anytree_next_dex (cell, sigjmp_buf *);
cell dryad_node_new (bool, bool, bool, cell, cell, cell, sigjmp_buf *);
cell treeish_clone (cell, sigjmp_buf *failure);
cell treeish_edge_imp (cell, bool, sigjmp_buf *);

@ Construction is the same process for all variants of dryad.

@c
cell
dryad_node_new (bool        tree,
                bool        sinward,
                bool        dexward,
                cell        datum,
                cell        nsin,
                cell        ndex,
                sigjmp_buf *failure)
{
        static int Sdatum = 2, Snsin = 1, Sndex = 0;
        Otag ntag;
        cell r;
        sigjmp_buf cleanup;
        Verror reason = LERR_NONE;

        ntag = tree ? FORM_TREE : FORM_ROPE;
        if (sinward)
                ntag |= LTAG_TSIN;
        if (dexward)
                ntag |= LTAG_TDEX;
        assert(null_p(nsin) || form(nsin) == ntag);
        assert(null_p(ndex) || form(ndex) == ntag);
        stack_protect(3, datum, nsin, ndex, failure);
        if (failure_p(reason = sigsetjmp(cleanup, 2)))
                unwind(failure, reason, false, 3);
        r = atom(Theap, SO(Snsin), SO(Sndex), FORM_TREE, &cleanup);
        r = atom(Theap, SO(Sdatum), r, ntag, &cleanup);
        stack_clear(3);
        return r;
}

@ Finding the edge of a tree is the same regardless of threading:
walk down a tree's links until the next node in the indicated
direction is |NIL|.

@d treeish_sinmost(O,F) treeish_edge_imp((O), true, (F))
@d treeish_dexmost(O,F) treeish_edge_imp((O), false, (F))
@c
cell
treeish_edge_imp (cell        o,
                  bool        sinward,
                  sigjmp_buf *failure)
{
        cell r;

        assert(treeish_p(o));
        r = o;
        while (sinward ? dryad_sin_p(r) : dryad_dex_p(r))
                if (Interrupt)
                        siglongjmp(*failure, LERR_INTERRUPT);
                else if (null_p((o = sinward ? dryad_sin(r) : dryad_dex(r))))
                        return r;
                else
                        r = o;
        return r;
}

@ @d anytree_next_imp(IN, OTHER)@/
cell
anytree_next_ ##IN (cell        o,
                    sigjmp_buf *failure)
{
        cell r;

        assert(dryadic_p(o));
        r = dryad_ ##IN(o);
        if (!treeish_ ##IN## _threadable_p(o) ||
                    !treeish_ ##IN## _has_thread_p(o))
                return r;
        return treeish_ ##OTHER## most(r, failure);
}
@c
@:anytree\_next\_sin@>
@:anytree\_next\_dex@>
anytree_next_imp(sin, dex)@;
anytree_next_imp(dex, sin)@;

@ @<Fun...@>=
void treeish_rethread_imp (cell, cell, Otag, cell);
cell treeish_rethread_m (cell, bool, bool, sigjmp_buf *);

@ @c
cell
treeish_rethread_m (cell        o,
                    bool        sinward,
                    bool        dexward,
                    sigjmp_buf *failure)
{
        cell head, next, prev, remember;
        Otag ntag;

        assert(treeish_p(o));
        ntag = form(o) & FORM_TREE;
        head = dryad_node_new(ntag == FORM_TREE, treeish_sin_threadable_p(o),
                treeish_dex_threadable_p(o), NIL, o, NIL, failure);
        if (sinward)
                ntag |= LTAG_TSIN;
        if (dexward)
                ntag |= LTAG_TDEX;

        next = head;
        remember = NIL;
        while (1) {
                if (null_p(next))
                        break;
                prev = tree_thread_live_sin(next);
                if (!null_p(prev)) {
                        while (!(prev == remember || null_p(tree_thread_live_dex(prev))))
                                prev = tree_thread_live_dex(prev);
                        if (prev != remember) { /* Insert or remove stack */
                                dryad_set_dex_m(prev, next);
                                tree_thread_set_dex_live_m(prev);
                                next = tree_thread_live_sin(next); /* Go to left */
                                continue;
                        } else {
                                dryad_set_dex_m(prev, NIL);
                                tree_thread_set_dex_live_m(prev);
                        }
                }
                if (treeish_sin_has_thread_p(next)) {
                        dryad_set_sin_m(next, NIL);
                        tree_thread_set_sin_live_m(next);
                }
                treeish_rethread_imp(next, prev, ntag, head);
                remember = next; /* Go to the right or up */
                next = tree_thread_live_dex(next);
        }
        return dryad_sin(head);
}

@ @c
void
treeish_rethread_imp (cell current,
                      cell previous,
                      Otag ntag,
                      cell head)
{
        TAG_SET_M(current, ntag);
        if (null_p(previous)) {
                dryad_set_sin_m(current, NIL);
                tree_thread_set_sin_live_m(current);
        } else if (current == head) {
                dryad_set_dex_m(previous, NIL);
                tree_thread_set_dex_live_m(previous);
        } else {
                if (ntag & LTAG_TSIN && !dryad_sin_p(current)) {
                        dryad_set_sin_m(current, previous);
                        tree_thread_set_sin_thread_m(current);
                }
                if (ntag & LTAG_TDEX && !dryad_dex_p(previous)) {
                        dryad_set_dex_m(previous, current);
                        tree_thread_set_dex_thread_m(previous);
                }
        }
}

@*1 Doubly-linked lists. These piggy-pack on top of plain unthreaded
trees. The list loops around on itself so the link nodes will never
be |NIL| and care is taken to ensure a loop is not inserted ``into''
itself.

@d dlist_datum(o) (dryad_datum(o))
@d dlist_prev(o)  (dryad_sin(o))
@d dlist_next(o)  (dryad_dex(o))
@<Fun...@>=
cell dlist_new (cell, sigjmp_buf *);
cell dlist_append_datum_m (cell, cell, sigjmp_buf *);
cell dlist_append_m (cell, cell);
cell dlist_clone (cell, sigjmp_buf *);
cell dlist_insert_datum_imp (cell, cell, bool, sigjmp_buf *);
cell dlist_insert_imp (cell, cell, bool, sigjmp_buf *);
cell dlist_remove_m (cell);
void dlist_set_next_m (cell, cell);
void dlist_set_prev_m (cell, cell);

@ @c
cell
dlist_new (cell        datum,
           sigjmp_buf *failure)
{
        cell r;

        r = dryad_node_new(true, false, false, datum, NIL, NIL, failure);
        TAG_SET_M(dryad_link(r), FORM_PAIR);
        dryad_set_sin_m(r, r);
        dryad_set_dex_m(r, r);
        return r;
}

@ @c
void
dlist_set_m (cell o,
             cell datum)
{
        assert(dlist_p(o));
        lcar_set_m(o, datum);
}

@ @d dlist_set(DIRECTION, YIN, YANG)@/
void
dlist_set_ ##DIRECTION## _m (cell hither,
                             cell yon)
{
        assert(dlist_p(hither));
        assert(dlist_p(yon));
        YIN## _set_m(dryad_link(hither), yon);
        YANG## _set_m(dryad_link(yon), hither);
}
@c
@:dlist\_set\_next\_m@>
@:dlist\_set\_prev\_m@>
dlist_set(next, lcdr, lcar)@;
dlist_set(prev, lcar, lcdr)@;

@ @d dlist_prepend_m(O,L) dlist_append_m(dlist_prev(O), (L))
@c
cell
dlist_append_m (cell o,
                cell l)
{
        cell after, before;

        assert(dlist_p(o));
        assert(dlist_p(l));
        after = dlist_next(o);
        before = dlist_prev(l); /* Usually |l|. */
        dlist_set_next_m(o, l);
        dlist_set_prev_m(after, before);
        return l;
}

@ @d dlist_prepend_datum_m(O,D,F) dlist_append_datum_m(dlist_prev(O), (D), (F))
@c
cell
dlist_append_datum_m (cell        o,
                      cell        d,
                      sigjmp_buf *failure)
{
        static int Sobject = 1, Sdatum = 0;
        cell r = NIL;
        sigjmp_buf cleanup;
        Verror reason = LERR_NONE;

        assert(dlist_p(o));
        assert(defined_p(d));
        stack_protect(2, o, d, failure);
        if (failure_p(reason = sigsetjmp(cleanup, 1)))
                unwind(failure, reason, false, 2);
        r = dlist_new(SO(Sdatum), &cleanup);
        r = dlist_append_m(SO(Sobject), r);
        stack_clear(2);
        return r;
}

@ @c
cell
dlist_remove_m (cell o)
{
        cell next, prev;

        assert(dlist_p(o));
        prev = dlist_prev(o);
        next = dlist_next(o);
        if (prev == next)
                return NIL;
        dlist_set_next_m(prev, next);
        return next;
}

@* Records. Not (yet) exposed to userspace, records use a key table
to associate a name with an index into an array.

Ordinarily a key-based table is identified by being an array with
a fixed integer in its spare slot indicating how many table entries
are free. However if the free slot is arraylike then the (first)
array is in fact the key-based table describing a record. Losing
the number of free entries in the table is safe because a record
is defined once and will never grow although care must be taken that
searching a key-based table will not reference this value.

A record is defined using a key-based table to relate attribute
names to an index value. An instance of a record is an array holding
those values who's spare slot points to the key-based table used
for lookup. That table is identified by pointing to itself.

In addition the records used for internally-defined objects (which
use a slightly different name-to-index lookup mechanism) may
optionally point to an arbitrary segment in the first array slot
and this segment itself has a spare slot which is not wasted (it
uses the pseudo-index -1).

@.TODO@>
@d RECORD_MAXLENGTH     (INT_MAX >> 1)
@d record_next(O)       (array_ref((O), 0))
@d record_next_p(O)     (segment_p(record_next(O))) /* TODO: inadequate test! */
@d record_id(O)         (record_next_p(O) ? pointer_datum(record_next(O)) :
        record_next(O))
@d record_base(O)       (record_next_p(O) ? segment_address(record_next(O)) :
        (char *) NULL)
@d record_offset(O)     (record_next_p(O) ? 1 : 0)
@d record_cell(O,I)     (array_ref((O), (I) + 1))
@d record_set_cell_m(O,I,D)
                        (array_set_m((O), (I) + 1, (D)))
@d record_object(T,O,A) (((T) record_base(O))->A)
@d record_set_object_m(T,O,A,D)
                        (record_object((T), (O), (A)) = (D))
@<Fun...@>=
cell record_new (cell, int, int, sigjmp_buf *);

@ @c
cell
record_new (cell        record_form,    /* The record form. */
            int         array_length,   /* The width of each object. */
            int         segment_length, /* The length of an option segment. */
            sigjmp_buf *failure)

{
        static int Sform = 1, Sret = 0;
        cell r = NIL, tmp;
        sigjmp_buf cleanup;
        Verror reason = LERR_NONE;

        assert(symbol_p(record_form) || fix_p(record_form));
        assert(array_length >= 0);
        if (array_length >= RECORD_MAXLENGTH)
                siglongjmp(*failure, LERR_LIMIT);
        stack_protect(2, record_form, NIL, failure);
        if (failure_p(reason = sigsetjmp(cleanup, 1)))
                unwind(failure, reason, false, 2);
        if (segment_length > 0)
                array_length++;
        r = array_new_imp(array_length + 1, NIL, FORM_RECORD, &cleanup);
        if (segment_length > 0) {
                SS(Sret, r);
                tmp = segment_new(0, segment_length, 1, 0, &cleanup);
                pointer_set_datum_m(tmp, SO(Sform));
                r = SO(Sret);
                array_set_m(r, 0, tmp);
        } else
                array_set_m(r, 0, SO(Sform));
        stack_clear(2);
        return r;
}

@** Valuable Data.

@* Characters (Runes). To avoid constantly mistyping the shift key
when referring to UTF-8 the suffix `o' is used instead creating
``utfo'' for ``UTF-Octal'' (although utfio means ``UTF I/O''). To
continue the theme {\it utfh\/} is UTF-Hexadecimal or UTF-16 and
{\it utft\/} is UTF-Trigintadyodecimal.

@d UCP_MAX 0x10ffff
@<Global...@>=
struct {
        char size;    /* How many bits are supplied by this byte. */
        uint8_t data; /* Mask: Encoded bits. */
        uint8_t lead; /* Mask: Leading bits which will be set. */
        int32_t max;  /* Maximum code-point value this many bytes can encode. */
} UTFIO[] = {@|
        { 6, 0x3f, 0x80, 0x000000 }, /* Continuation byte. */@t\iII@>
        { 7, 0x7f, 0x00, 0x00007f }, /* Single ASCII byte. */@t\iII@>
        { 5, 0x1f, 0xc0, 0x0007ff }, /* Start of 2-byte encoding. */@t\iII@>
        { 4, 0x0f, 0xe0, 0x00ffff }, /* Start of 3-byte encoding. */@t\iII@>
        { 3, 0x07, 0xf0, 0x10ffff }, /* Start of 4-byte encoding. */@t\iII@>
@t\4\4@>};

@ Going into the parser from |UTFIO_COMPLETE| (ie.~0) will exit in
any one of these states.

@<Type def...@>=
typedef enum {
        UTFIO_COMPLETE,         /* A code point is complete (or unstarted). */
        UTFIO_INVALID,          /* Encountered an invalid byte/encoding. */
        UTFIO_BAD_CONTINUATION, /* Continuation byte when expecting a
                                        starter byte. */
        UTFIO_BAD_STARTER,      /* Starter byte when expecting a
                                        continuation byte. */
        UTFIO_OVERLONG,         /* Overlong encoding was used. */
        UTFIO_SURROGATE,        /* Surrogate pair half was encoded. */
        UTFIO_PROGRESS,         /* Byte is valid but more are required (a
                                        final error if EOF was premature). */
        UTFIO_EOF               /* EOF encountered prematurely. */
} Vutfio_parse;

@ The last two code points of each plane are noncharacters: U+...FFFE
and U+...FFFF (recall that the byte-order-mark has value U+FEFF)
for a total of 34 code points in 17 planes. In addition, there is
a contiguous range of another 32 noncharacter code points in the
BMP (plane 0): U+FDD0--U+FDEF.

@d UCP_SURROGATE_MIN       0xd800 /* Values $\ge2^{16}$ in UTF-16 encoded text. */
@d UCP_SURROGATE_MAX       0xe000
@d UCP_NONBMP_MIN          0xfdd0 /* Contained within the ``Arabic Presentation */
@d UCP_NONBMP_MAX          0xfdef /* ... Forms-A block'' by a historic accident. */
@d UCP_REPLACEMENT         0xfffd
@d UCP_REPLACEMENT_LENGTH  3
@d UCP_NONCHAR_MASK        0xfffe /* The lowest bit doesn't matter. */
@d utfio_noncharacter_p(C) (utfio_nonplane_p(C) || utfio_nonrange_p(C))
@d utfio_nonplane_p(C)     (((C)->value & UCP_NONCHAR_MASK) == UCP_NONCHAR_MASK)
@d utfio_nonrange_p(C)     ((C)->value >= UCP_NONBMP_MIN &&
                                (C)->value <= UCP_NONBMP_MAX)
@d utfio_overlong_p(C)     ((C)->value <= UTFIO[(C)->offset - 1].max)
@d utfio_surrogate_p(C)    ((C)->value >= UCP_SURROGATE_MIN &&
                                (C)->value <= UCP_SURROGATE_MAX)
@d utfio_too_large_p(C)    ((C)->value > UCP_MAX)
@<Type def...@>=
typedef struct {
        int32_t value;
        char offset, remaining;
        char buf[4];
        Vutfio_parse status;
} Outfio;

@ @<Fun...@>=
Vutfio_parse utfio_read (Outfio *, uint8_t);
Vutfio_parse utfio_reread (Outfio *, uint8_t);
Outfio utfio_scan_start (void);
Outfio utfio_write (int32_t);

@ @c
Outfio
utfio_scan_start (void)
{
        Outfio r = { 0 };
        return r;
}

@ @c
Vutfio_parse
utfio_read (Outfio *ctx,
            uint8_t byte)
{
        int32_t vbyte = byte;
        int i;

        for (i = 0; i < 4; i++) {
                if ((byte & ~UTFIO[i].data) != UTFIO[i].lead)
                        continue;
                else if (i == 0) {
                        if (ctx->remaining)
                                ctx->remaining--;
                        else
                                return ctx->status = UTFIO_BAD_CONTINUATION;
                } else {
                        if (ctx->remaining)
                                return ctx->status = UTFIO_BAD_STARTER;
                        else
                                ctx->remaining = i - 1;
                }
                ctx->buf[(int) ctx->offset++] = byte;
                ctx->value |= (vbyte & UTFIO[i].data) << (6 * ctx->remaining);
                if (ctx->remaining)
                        return ctx->status = UTFIO_PROGRESS;
                else if (utfio_too_large_p(ctx) || utfio_noncharacter_p(ctx))
                        return ctx->status = UTFIO_INVALID;
                else if (utfio_surrogate_p(ctx))
                        return ctx->status = UTFIO_SURROGATE;
                else if (utfio_overlong_p(ctx))
                        return ctx->status = UTFIO_OVERLONG;
                else
                        return ctx->status = UTFIO_COMPLETE;
        }
        return ctx->status = UTFIO_INVALID;
}

@ Again but without error checking --- only for use on known-valid UTF-8.

@c
Vutfio_parse
utfio_reread (Outfio *ctx,
              uint8_t byte)
{
        int32_t vbyte = byte;
        int i;

        for (i = 0; i < 4; i++)
                if ((byte & ~UTFIO[i].data) != UTFIO[i].lead)
                        continue;
                else {
                        if (ctx->remaining)
                                ctx->remaining--;
                        else
                                ctx->remaining = i - 1;
                        ctx->buf[(int) ctx->offset++] = byte;
                        ctx->value = (vbyte & UTFIO[i].data) << (6 * ctx->remaining);
                        ctx->status = ctx->remaining ? UTFIO_PROGRESS : UTFIO_COMPLETE;
                        return ctx->status;
                }
        abort(); /* UNREACHABLE */
}

@ @c
Outfio
utfio_write (int32_t c)
{
        int i;
        int32_t mask, next;
        Outfio r = { 0 };

        assert(c >= 0 && c <= UCP_MAX);
        r.status = UTFIO_PROGRESS;
        r.value = c;
        if (utfio_surrogate_p(&r))
                r.status = UTFIO_SURROGATE;
        else if (r.value < 0 || utfio_noncharacter_p(&r))
                r.status = UTFIO_INVALID;
        else if (utfio_too_large_p(&r))
                r.status = UTFIO_OVERLONG;
        if (r.status == UTFIO_PROGRESS)
                r.status = UTFIO_COMPLETE;
        else
                c = UCP_REPLACEMENT;
        if (c <= UTFIO[1].max)
                r.buf[(int) r.offset++] = c;
        else {
                if (c <= UTFIO[2].max)
                        r.remaining = i = 2;
                else if (c <= UTFIO[3].max)
                        r.remaining = i = 3;
                else
                        r.remaining = i = 4;
                for (; r.remaining; r.remaining--) {
                        mask = UTFIO[r.remaining == i ? i : 0].data;
                        mask <<= 6 * (r.remaining - 1);
                        next = c & mask;
                        next >>= 6 * (r.remaining - 1);
                        next |= UTFIO[r.remaining == i ? i : 0].lead;
                        r.buf[(int) r.offset++] = next;
                }
        }
        return r;
}

@ Of the 11 spare bits, 3 are used to store the length of the UTF-8
encoding and the other 8 a failure code. Lots of magic masks here.

Runes have come through one of the utfio functions above as a
|Outfio| or are a |int32_t| to put through |utfio_write| for
validation.

@<Fun...@>=
cell rune_new_utfio (Outfio, sigjmp_buf *);

@ Assumes |ctx.status| is correct so only valid encodings must be
|UTFIO_COMPLETE| (0). Note that any (invalid) character may have status
|UTFIO_EOF| if |EOF| was encountered in the middle of a multi-byte
code point.

Status |UTFIO_PROGRESS| indicates an otherwise acceptable code point
which is split between two rope nodes.

@d UCPVAL(V)           (((V) & 0x001fffff)) /* {\it Only\/} code point bits. */
@d UCPLEN(V)           (((V) & 0x00e00000) >> 21)
@d UCPFAIL(V)          (((V) & 0xff000000) >> 24) /* Only bottom 3 used. */
@#
@d rune_raw(O)         ((CELL_BITS >= 32) ? (int32_t) lcar(O) :@|
        ((((int32_t) lcar(O) & 0xffff) << 16) | ((int32_t) lcdr(O) & 0xffff)))
@d rune_failure_p(O)   (!!UCPFAIL(rune_raw(O)))
@d rune_failure(O)     (UCPFAIL(rune_raw(O)))
@d rune_parsed(O)      (UCPLEN(rune_raw(O)))
@d rune(O)             (rune_failure_p(O) ? UCP_REPLACEMENT :
        UCPVAL(rune_raw(O)))
@#
@d rune_new_value(V,F) (rune_new_utfio(utfio_write(V), (F)))
@c
cell
rune_new_utfio (Outfio      ctx,
                sigjmp_buf *failure)
{
        Oatom packed;

        ctx.value |= (ctx.offset << 21);
        ctx.value |= (ctx.status << 24);
        if (CELL_BITS >= 32) {
                packed.sin = (cell) ctx.value;
                packed.dex = NIL;
        } else {
                packed.sin = (cell) ((ctx.value & 0xffff0000ll) >> 16);
                packed.dex = (cell) ((ctx.value & 0x0000ffffll) >>  0);
        }
        return atom(Theap, packed.sin, packed.dex, FORM_RUNE, failure);
}

@* Ropes. If the rope contains only correctly-encoded valid code
points the length is recorded (and the fact noted) in cplength.
Likewise glength counts the number of whole glyphs. Neither of these
features is implemented and so is liable to change.

@d rope_segment(O)  (dryad_datum(O))
@d rope_base(O)     ((Orope *) segment_address(rope_segment(O)))
@d rope_blength(O)  ((long) segment_length(rope_segment(O)) - 1)
@d rope_cplength(O) (rope_base(O)->cplength)
@d rope_glength(O)  (rope_base(O)->glength)
@d rope_buffer(O)   (rope_base(O)->buffer)
@d rope_first(O,F)  (treeish_sinmost((O), (F)))
@d rope_last(O,F)   (treeish_dexmost((O), (F)))
@d rope_next(O,F)   (anytree_next_dex((O), (F)))
@d rope_prev(O,F)   (anytree_next_sin((O), (F)))
@d rope_byte(O,B)   (rope_buffer(O)[(B)])
@<Type def...@>=
typedef struct {
        long cplength;
        long glength;
        char buffer[];
} Orope;

@ @<Fun...@>=
cell rope_node_new_clone (bool, bool, cell, cell, cell, sigjmp_buf *);
cell rope_node_new_length (bool, bool, long, cell, cell, sigjmp_buf *);
cell rope_new_ascii (bool, bool, char *, long, sigjmp_buf *);
cell rope_new_buffer (bool, bool, const char *, long, sigjmp_buf *);
cell rope_new_utfo (bool, bool, char *, long, sigjmp_buf *);

@ Always allocates one more byte than requested to be a |NULL|-terminator
in case the rope's buffer ever leaks into something expecting a
\CEE/-string. This should never happen but the byte is there anyway
as a safety-valve.

@d rope_node_new_empty(S,D,F) rope_node_new_length((S), (D), 0, NIL, NIL, (F))
@c
cell
rope_node_new_length (bool        sinward,
                      bool        dexward,
                      long        length,
                      cell        nsin,
                      cell        ndex,
                      sigjmp_buf *failure)
{
        static int Snsin = 1, Sndex = 0;
        cell r;
        sigjmp_buf cleanup;
        Verror reason = LERR_NONE;

        assert(null_p(nsin) || rope_p(nsin)); /* Threading checked by */
        assert(null_p(nsin) || rope_p(ndex)); /* |dryad_node_new|. */
        if (ckd_add(&length, length, 1))
                siglongjmp(*failure, LERR_LIMIT);
        stack_protect(2, nsin, ndex, failure);
        if (failure_p(reason = sigsetjmp(cleanup, 1)))
                unwind(failure, reason, false, 2);
        r = segment_new(sizeof (Orope), length, 0, 0, &cleanup);
        r = dryad_node_new(false, sinward, dexward, r, SO(Snsin),
                SO(Sndex), &cleanup);
        rope_cplength(r) = rope_glength(r) = -1;
        rope_buffer(r)[length - 1] = '\0';
        stack_clear(2);
        return r;
}

@ @c
cell
rope_node_new_clone (bool        sinward,
                     bool        dexward,
                     cell        o,
                     cell        nsin,
                     cell        ndex,
                     sigjmp_buf *failure)
{
        static int Sobject = 2, Snsin = 1, Sndex = 0;
        cell r;
        sigjmp_buf cleanup;
        Verror reason = LERR_NONE;

        assert(rope_p(o));
        assert(null_p(nsin) || rope_p(nsin)); /* Threading checked by */
        assert(null_p(nsin) || rope_p(ndex)); /* |dryad_node_new|. */
        stack_protect(3, o, nsin, ndex, failure);
        if (failure_p(reason = sigsetjmp(cleanup, 1)))
                unwind(failure, reason, false, 3);
        r = dryad_node_new(false, sinward, dexward, rope_segment(SO(Sobject)),
                SO(Snsin), SO(Sndex), &cleanup);
        rope_buffer(r)[segment_length(rope_segment(SO(Sobject)))] = '\0';
        stack_clear(3);
        return r;
}

@ Some internal helpers: A rope can be created by copying the
contents of a buffer.

@d rope_new_length(S,D,L,F) rope_node_new_length((S), (D), (L), NIL, NIL, (F))
@c
cell
rope_new_buffer (bool        thread_sin,
                 bool        thread_dex,
                 const char *buffer,
                 long        length,
                 sigjmp_buf *failure)
{
        char *dst;
        cell r;
        int i;

        r = rope_new_length(thread_sin, thread_dex, length, failure);
        dst = rope_buffer(r);
        for (i = 0; i < length; i++)
                dst[i] = buffer[i];
        return r;
}

@ TODO: check that no byte is |>= 0x80|?

@.TODO@>
@c
cell
rope_new_ascii (bool        thread_sin,
                bool        thread_dex,
                char       *buffer,
                long        length,
                sigjmp_buf *failure)
{
        cell r;

        r = rope_new_buffer(thread_sin, thread_dex, buffer, length, failure);
        rope_cplength(r) = length;
        return r;
}

@ @c
cell
rope_new_utfo (bool        thread_sin @[Lunused@],
               bool        thread_dex @[Lunused@],
               char       *buffer @[Lunused@],
               long        length @[Lunused@],
               sigjmp_buf *failure @[Lunused@])
{
        siglongjmp(*failure, LERR_UNIMPLEMENTED);
}

@*1 Rope Iterator.

@d ROPE_ITER_TWINE  0
@d ROPE_ITER_LENGTH 1
@#
@d rope_iter(O)               ((Orope_iter *) record_base(O))
@d rope_iter_twine(O)         (record_cell((O), ROPE_ITER_TWINE))
@d rope_iter_set_twine_m(O,D) (record_set_cell_m((O), ROPE_ITER_TWINE, (D)))
@<Type def...@>=
typedef struct {
        int    bvalue;    /* Value of the last-read {\it byte\/}. */
        long   tboffset;  /* Byte offset into |twine| of next read. */
        long   boffset;   /* \ditto\ the entire rope. */
        long   cpoffset;  /* Code-point offset into the rope. */
        Outfio cp;        /* Code-point parser's working area. */
} Orope_iter;

@ @<Fun...@>=
cell rope_iterate_start (cell, long, sigjmp_buf *);
int rope_iterate_next_byte (cell, sigjmp_buf *);
cell rope_iterate_next_utfo (cell, sigjmp_buf *);

@ @c
cell
rope_iterate_start (cell        o,
                    long        begin,
                    sigjmp_buf *failure)
{
        static int Sobject = 0;
        cell r = NIL, twine;
        sigjmp_buf cleanup;
        Verror reason = LERR_NONE;

        assert(rope_p(o));
        stack_protect(1, o, failure);
        if (failure_p(reason = sigsetjmp(cleanup, 1)))
                unwind(failure, reason, false, 1);
        r = record_new(fix(RECORD_ROPE_ITERATOR), ROPE_ITER_LENGTH,
                sizeof (Orope_iter), &cleanup);
        twine = SO(Sobject);
        if (begin < 0) {
                twine = rope_first(twine, &cleanup);
                begin = 0;
        }
        rope_iter_set_twine_m(r, twine);
        rope_iter(r)->bvalue = rope_iter(r)->cpoffset = 0;
        rope_iter(r)->tboffset = rope_iter(r)->boffset = begin;
        stack_clear(1);
        return r;
}

@ @c
int
rope_iterate_next_byte (cell        o,
                        sigjmp_buf *failure)
{
        cell twine;

        assert(rope_iter_p(o));
        twine = rope_iter_twine(o);
        if (null_p(twine))
                siglongjmp(*failure, LERR_EOF);
        while (rope_iter(o)->tboffset == rope_blength(twine)) {
                twine = rope_next(twine, failure);
                rope_iter_set_twine_m(o, twine);
                rope_iter(o)->tboffset = 0;
                if (null_p(twine))
                        return EOF;
        }
        rope_iter(o)->bvalue = rope_buffer(twine)[rope_iter(o)->tboffset++];
        rope_iter(o)->boffset++;
        return rope_iter(o)->bvalue;
}

@ Asserts, buggily, that a code point will never be split between
two rope twine (although any coarser unit may be and the rope may
be validly not utf-8 encoded).

@c
cell
rope_iterate_next_utfo (cell        o,
                        sigjmp_buf *failure)
{
        int c;
        cell r, start, twine;
        Vutfio_parse res, (*readchar) (Outfio *, uint8_t);

        assert(rope_iter_p(o));
        twine = rope_iter_twine(o);
        if (rope_p(twine) && rope_cplength(twine) >= 0)
                readchar = utfio_reread;
        else
                readchar = utfio_read;
        start = twine;
        rope_iter(o)->cp = utfio_scan_start();
        r = VOID; /* |NIL| is a possible value. */
        while (void_p(r)) {
                c = rope_iter(o)->bvalue = rope_iterate_next_byte(o, failure);
                if (c == EOF) {
                        rope_iter(o)->cp.status = UTFIO_EOF;
                        if (!rope_iter(o)->cp.remaining)
                                return LEOF;
                        break;
                }
                res = readchar(&rope_iter(o)->cp, c);
                if (res == UTFIO_COMPLETE || res != UTFIO_PROGRESS)
                        break;
        }
        if (rope_iter_twine(o) != start)
                rope_iter(o)->cp.status = UTFIO_PROGRESS;
        rope_iter(o)->cpoffset++;
        return rune_new_utfio(rope_iter(o)->cp, failure);
}

@** Operational Data.

@* Stack.

@d STACK_CHUNK 0x100
@<Fun...@>=
void stack_push (cell, sigjmp_buf *);
cell stack_pop (long, sigjmp_buf *);
cell stack_ref (long, sigjmp_buf *);
void stack_set_m (long, cell, sigjmp_buf *);
cell stack_ref_abs (long, sigjmp_buf *);
void stack_reserve (int, sigjmp_buf *);
void stack_protect (int, ...);

@ @<Global...@>=
unique cell Stack = NIL;
unique long StackP = -1;
unique cell Stack_Tmp = NIL;

@ @<Extern...@>=
extern unique long StackP;

@ @<Init...@>=
Stack = array_new(STACK_CHUNK, failure);

@ @c
void
stack_push (cell        o,
            sigjmp_buf *failure)
{
        if (StackP == array_length(Stack)) {
                Stack_Tmp = o;
                Stack = array_grow_m(Stack, STACK_CHUNK, NIL, failure);
                o = Stack_Tmp;
                Stack_Tmp = NIL;
        }
        array_set_m(Stack, ++StackP, o);
}

@ @d stack_clear(O) stack_pop((O), NULL)
@c
cell
stack_pop (long        num,
           sigjmp_buf *failure)
{
        cell r;

        assert(num >= 1);
        r = stack_ref(num - 1, failure);
        StackP -= num;
        return r;
}

@ @d SO(O) stack_ref((O), NULL)
@c
cell
stack_ref (long        offset,
           sigjmp_buf *failure)
{
        cell r = NIL;

        assert(offset >= 0);
        assert(failure != NULL || StackP >= offset);
        if (failure != NULL && StackP < offset)
                siglongjmp(*failure, LERR_UNDERFLOW);
        else
                r = array_ref(Stack, StackP - offset);
        return r;
}

@ @d SS(O,D) stack_set_m((O), (D), NULL)
@c
void
stack_set_m (long        offset,
             cell        datum,
             sigjmp_buf *failure)
{
        assert(offset >= 0);
        assert(failure != NULL || StackP >= offset);
        if (failure != NULL && StackP < offset)
                siglongjmp(*failure, LERR_UNDERFLOW);
        else
                array_set_m(Stack, StackP - offset, datum);
}

@ @c
cell
stack_ref_abs (long        offset,
               sigjmp_buf *failure)
{
        cell r = NIL;

        assert(offset >= 0);
        assert(failure != NULL || StackP >= offset);
        if (StackP < offset)
                siglongjmp(*failure, LERR_UNDERFLOW);
        else
                r = array_ref(Stack, offset);
        return r;
}

@ @c
void
stack_set_abs_m (long        offset,
                 cell        datum,
                 sigjmp_buf *failure)
{
        assert(offset >= 0);
        assert(failure != NULL || StackP >= offset);
        if (StackP < offset)
                siglongjmp(*failure, LERR_UNDERFLOW);
        else
                array_set_m(Stack, offset, datum);
}

@ @c
void
stack_reserve (int         delta,
               sigjmp_buf *failure)
{
        int i;

        while (array_length(Stack) - (StackP + 1) < delta)
                Stack = array_grow_m(Stack, STACK_CHUNK, NIL, failure);
        StackP += delta;
        for (i = 0; i < delta; i++)
                array_set_m(Stack, StackP - i, NIL);
}

@ @<Global...@>=
unique cell Protect[4];

@ @c
void
stack_protect (int num,
               ...)
{
        va_list ap;
        int i;
        sigjmp_buf cleanup, *failure;
        Verror reason = LERR_NONE;

        assert(num > 0 && num <= 4);
        va_start(ap, num);
        for (i = 0; i < num; i++)
                Protect[i] = va_arg(ap, cell);
        failure = va_arg(ap, sigjmp_buf *);
        va_end(ap);
        if (failure_p(reason = sigsetjmp(cleanup, 1)))
                goto fail;
        stack_reserve(num, &cleanup);
        for (i = 0; i < num; i++) {
                SS(num - (i + 1), Protect[i]);
                Protect[i] = NIL;
        }
        return;
fail:
        for (i = 0; i < num; i++)
                Protect[i] = NIL;
        siglongjmp(*failure, reason);
}

@* Environments. An environment is a hash table with a link to
another hash table which it descended from.

@ @d env_layer(O)           (lcdr(O))
@d env_previous(O)          (lcar(O))
@d env_replace_layer_m(O,E) (lcdr_set_m((O), (E)))
@d env_root_p(O)            (environment_p(O) && null_p(env_previous(O)))
@<Fun...@>=
cell env_search (cell, cell, sigjmp_buf *);
cell env_new_imp (cell, sigjmp_buf *);
cell env_extend (cell, sigjmp_buf *);
void env_set_imp (cell (*)(cell, cell, cell, bool, sigjmp_buf *), cell,
        cell, cell, sigjmp_buf *);

@ @d env_empty(F)   (env_new_imp(NIL, (F)))
@c
cell
env_new_imp (cell        o,
             sigjmp_buf *failure)
{
        static int Sobject = 0;
        cell r = NIL;
        sigjmp_buf cleanup;
        Verror reason = LERR_NONE;

        stack_protect(1, o, failure);
        if (failure_p(reason = sigsetjmp(cleanup, 1)))
                unwind(failure, reason, false, 1);
        r = hashtable_new(0, &cleanup);
        r = atom(Theap, SO(Sobject), r, FORM_ENVIRONMENT, &cleanup);
        stack_clear(1);
        return r;
}

@ @c
cell
env_extend (cell        o,
            sigjmp_buf *failure)
{
        assert(environment_p(o));
        return env_new_imp(o, failure);
}

@ @d env_define_m(E,L,D,F) (env_set_imp(hashtable_insert_m, (E), (L), (D), (F)))
@d env_set_m(E,L,D,F) (env_set_imp(hashtable_replace_m, (E), (L), (D), (F)))
@d env_unset_m(E,L,F) (env_set_imp(hashtable_delete_m, (E), (L), LTRUE, (F)))
@d env_clear_m(E,L,F) (env_set_imp(hashtable_delete_m, (E), (L), LFALSE, (F)))
@c
void
env_set_imp (cell      (*method)(cell, cell, cell, bool, sigjmp_buf *),
             cell        o,
             cell        label,
             cell        datum,
             sigjmp_buf *failure)
{
        static int Sobject = 2, Slabel = 1, Sdatum = 0;
        cell table;
        sigjmp_buf cleanup;
        Verror reason = LERR_NONE;

        assert(environment_p(o));
        stack_protect(3, o, label, datum, failure);
        if (failure_p(reason = sigsetjmp(cleanup, 1)))
                unwind(failure, reason, false, 3);
        table = method(env_layer(SO(Sobject)), SO(Slabel), SO(Sdatum),
                false, failure);
        env_replace_layer_m(SO(Sobject), table);
        stack_clear(3);
}

@ @c
cell
env_search (cell        o,
            cell        label,
            sigjmp_buf *failure)
{
        cell r;

        assert(environment_p(o));
        assert(symbol_p(label));
        for (; !null_p(o); o = env_previous(o)) {
                r = hashtable_search(env_layer(o), label, failure);
                if (defined_p(r))
                        return lcdr(r); /* May be |UNDEFINED|! */
        }
        return UNDEFINED;
}

@* Lexemes. Non-numeric lexemes on the whole are sufficient on their
own without flags. The exception is blank space which can be
horizontal or vertical.

@d LLF_NONE          0x00
@d LLF_HORIZONTAL    0x01
@d LLF_VERTICAL      0x02

@ Numeric lexemes on the other hand pick up bits explaining which
base the scanner detected, the presence of a sign, decimal point,
etc. This information is squeezed into 8 bits, mostly because I
could.

To achieve this the base, 2, 8, 10 or 16 is instead encoded as 2,
8, 0 and 10 which use only the bits $2^1$ (2) \AM\ $2^3$ (8). This
algorithm uses bit twiddling to turn the base stuffed in the lexeme's
flags into its numeric equivalent.

@d LLF_BASE2         0x02
@d LLF_BASE8         0x08
@d LLF_BASE16        0x0a
@d LLF_BASE(O)       flag2base(O)
@q Ugly... @>
@c
int
flag2base (int f)
{                                  @t\hskip18.65em@> /* 0 \ 2   \ 8 10 */
        f |= 5;                    @t\hskip15.17em@> /* 5 \ 7    13 15 */
        f++;                       @t\hskip16.05em@> /* 6 \ 8    14 16 */
        f = (f&~2) | (((f&8) >> 2) ^ (f&2));         /* 6  10    12 16 */
        f = (f&~8) | ((f&4) << 1); @t\hskip5.05em@>  /*14 \ 2    12 16 */
        return f & 26;             @t\hskip11.45em@> /*10 \ 2 \ \ 8 16 */
}

@ For comparison here's the reverse algorithm using tests and
branching.

@c
int
base2flag (int b)
{
        if (b == 10)
                return 0;
        else if (b == 16)
                return 10;
        else
                return b;
}

@ Complex or imaginary components of a number are indicated with
an \.i, \.j or \.k suffix. The lexical analyser detects and flags
these using the bits at $2^0$ and $2^2$ in order to fit around the
bits which encode the base. In this case no bits set indicates a
real number. Macros |LLF_COMPLEXITY| and |LLF_IMAGINATE| transform
the flag value into a number 0 -- 3 and vice versa.

@d LLF_COMPLEXI      0x01
@d LLF_COMPLEXJ      0x04
@d LLF_COMPLEXK      0x05
@d LLF_COMPLEX_P(O)  ((O) & 0x05)
@d LLF_COMPLEXITY(O) (((O) & 1) | (LLF_COMPLEX_P(O) >> 1))
        /* [\.{~IJK}] \to\ [\.{0123}] */
@d LLF_IMAGINATE(O)  (((O) & ~2) | (((O) & 2) << 1))
@t\iIV@>/* [\.{0123}] \to\ [\.{~IJK}] */

@ With the 4 lower bits in use the remaining 4 indicate whether a
sign is present and which, and likewise a decimal point or slash.

@d LLF_NEGATIVE      0x10
@d LLF_POSITIVE      0x20
@d LLF_SIGN          0x30
@#
@d LLF_DOT           0x40
@d LLF_SLASH         0x80
@d LLF_RATIO         0xc0

@ Alphabetical order. TODO: Short in-line description and run-time
reverse mapping.

@<Type def...@>=
typedef enum {@/
        LEXICAT_NONE,@/ /* 0 */
        LEXICAT_CLOSE,
        LEXICAT_CONSTANT,
        LEXICAT_CURIOUS,
        LEXICAT_DELIMITER,@/ /* ... 4 */
        LEXICAT_DOT,
        LEXICAT_END,
        LEXICAT_ESCAPED_STRING,
        LEXICAT_ESCAPED_SYMBOL,@/ /* ... 8 */
        LEXICAT_NUMBER,
        LEXICAT_OPEN,
        LEXICAT_QUOTE,
        LEXICAT_RAW_STRING,@/ /* ... 12 */
        LEXICAT_RAW_SYMBOL,
        LEXICAT_RECURSE_HERE,
        LEXICAT_RECURSE_IS,
        LEXICAT_SPACE,@/ /* ... 16 */
        LEXICAT_SYMBOL,
        LEXICAT_INVALID
} Vlexicat;

@ A lexeme records where in a rope it began and how many bytes and
runes it occupies.

@d LEXEME_TWINE  0 /* The rope twine in which a lexeme started. */
@d LEXEME_LENGTH 1
@#
@d lexeme(O)               ((Olexeme *) record_base(O))
@d lexeme_twine(O)         (record_cell((O), LEXEME_TWINE))
@d lexeme_set_twine_m(O,D) (record_set_cell_m((O), LEXEME_TWINE, (D)))
@d lexeme_byte(O,I)        (rope_byte(lexeme_twine(O),
        lexeme(O)->tboffset + (I)))
@<Type def...@>=
typedef struct {
        long tboffset;          /* Byte in the {\it twine\/} where the lexeme began. */
        long cpstart;           /* Lexeme's starting point in the {\it rope\/}, in runes. */
        long blength, cplength; /* Lexeme's length in bytes \AM\ runes. */
        char flags;             /* Extra detail as described previously. */
        Vlexicat cat;           /* The lexeme's category as above. */
} Olexeme;

@ @c
cell
lexeme_new (Vlexicat    cat,
            char        flags,
            cell        twine,
            long        tboffset,
            long        blength,
            long        cpstart,
            long        cplength,
            sigjmp_buf *failure)
{
        static int Stwine = 0;
        cell r;
        sigjmp_buf cleanup;
        Verror reason = LERR_NONE;

        assert(null_p(twine) || rope_p(twine));
        stack_protect(1, twine, failure);
        if (failure_p(reason = sigsetjmp(cleanup, 1)))
                unwind(failure, reason, false, 1);
        r = record_new(fix(RECORD_LEXEME), LEXEME_LENGTH, sizeof (Olexeme),
                &cleanup);
        lexeme_set_twine_m(r, SO(Stwine));
        lexeme(r)->cat = cat;
        lexeme(r)->flags = flags;
        lexeme(r)->tboffset = tboffset;
        lexeme(r)->blength = blength;
        lexeme(r)->cpstart = cpstart;
        lexeme(r)->cplength = cplength;
        stack_clear(1);
        return r;
}

@* Expression Provenance. The completed result of the lexical
analyser is given to the syntax parser to transform it from a list
of tokens into a tree of operations. Each node in this tree which
with some irony doesn't use any of the built-in trees is a syntax
object --- a record (of only cells) holding the expression which
was parsed from the source and a record of where in the stream of
lexemes it was found.

@d PROVENANCE_DATUM  0 /* The parsed datum. */
@d PROVENANCE_START  1 /* The lexeme which began this datum. */
@d PROVENANCE_END    2 /* The lexeme which ended this datum (inclusive). */
@d PROVENANCE_VALID  3 /* Whether the source is valid and can be evaluated. */
@d PROVENANCE_LENGTH 4
@#
@d prove_datum(O) (record_cell((O), PROVENANCE_DATUM))
@d prove_end(O)   (record_cell((O), PROVENANCE_END))
@d prove_start(O) (record_cell((O), PROVENANCE_START))
@d prove_valid(O) (record_cell((O), PROVENANCE_VALID))
@#
@d prove_new(D,S,E,F)     prove_new_imp((D), (S), (E), true, (F))
@d prove_invalid(D,S,E,F) prove_new_imp((D), (S), (E), false, (F))
@c
cell
prove_new_imp (cell        datum,
               cell        start,
               cell        end,
               bool        valid,
               sigjmp_buf *failure)
{
        static int Sdatum = 2, Sstart = 1, Send = 0;
        cell r = NIL;
        sigjmp_buf cleanup;
        Verror reason = LERR_NONE;

        assert(defined_p(datum));
        assert(dlist_p(start) && lexeme_p(dlist_datum(start)));
        assert(dlist_p(end) && lexeme_p(dlist_datum(end)));
                /* |&& start->@[@]|...|@[@]->next == end| */
        stack_protect(3, datum, start, end, failure);
        if (failure_p(reason = sigsetjmp(cleanup, 1)))
                unwind(failure, reason, false, 3);
        r = record_new(fix(RECORD_PROVENANCE), PROVENANCE_LENGTH, 0, &cleanup);
        record_set_cell_m(r, PROVENANCE_VALID, predicate(valid));
        record_set_cell_m(r, PROVENANCE_DATUM, SO(Sdatum));
        record_set_cell_m(r, PROVENANCE_START, SO(Sstart));
        record_set_cell_m(r, PROVENANCE_END, SO(Send));
        stack_clear(3);
        return r;
}

@* Pending Computation. These are used by the evaluator (below) to
keep track of its partial work. The evaluator could be refactored
to move memory allocation to within this object.

@<Type def...@>=
typedef enum {
        PENDING_COMBINE_BUILD,@/
        PENDING_COMBINE_DISPATCH,@/
        PENDING_COMBINE_READY,@/
        PENDING_COMBINE_FINISH,@/
        PENDING_EVALUATE,@/
        PENDING_MUTATE,@/
} Vpending;

@ @<Fun...@>=
cell pend (Vpending, cell, sigjmp_buf *);

@
@d pending_datum(O) (lcdr(O))
@d pending_stage(O) ((Vpending) lcar(O))
@c
cell
pend (Vpending    stage,
      cell        datum,
      sigjmp_buf *failure)
{
        cell r;

        r = atom(Theap, stage, datum, FORM_PENDING, failure);
        return r;
}

@* Programs (Closures). Programs in \Ls/ are divided into two
categories: {\it operative\/} and {\it applicative\/}. Programs are
also and more formally known as {\it combiners\/} when they are the
first expression in a list which is being evaluated, which is by
{\it combining\/} the multiple expressions ({\it combiner\/} \AM\
{\it arguments\/}) into a single expression (return value).

A combiner is a program which condenses zero or more arguments into
a single expression. Internally a combiner is further distinguished
by whether it has been provided by the implementation or defined
at run-time. A {\it closure\/} is a combiner which includes the
environment that was in place when it was defined and it re-established
when the closure program is evaluated.

Given the astonishing compute capabilities which closures enable
they have comically simple storage requirements. A list records the
run-time environment they were created in with the expression to
evaluate and its arguments ({\it formals\/}). Applicative and
operative closures are identified by their tag.

@d closure_formals(O)     (lcar(O))
@d closure_environment(O) (lcadr(O))
@d closure_body(O)        (lcaddr(O))
@<Fun...@>=
cell closure_new (bool, cell, cell, cell, sigjmp_buf *);

@ Usually (always?) these arguments are actually in registers and
the stack dancing is unnecessary.

@c
cell
closure_new (bool        is_applicative,@/
@t\iII@>     cell        formals,     /* From register: |Accumulator|, */
@t\iII@>     cell        environment, /* ... |Environment|, */
@t\iII@>     cell        body,        /* ... |Expression|. */
@t\iII@>     sigjmp_buf *failure)
{
        static int Sformals = 3, Senv = 2, Sbody = 1, Sret = 0;
        cell r;
        sigjmp_buf cleanup;
        Verror reason = LERR_NONE;

        stack_protect(4, formals, environment, body, NIL, failure);
        if (failure_p(reason = sigsetjmp(cleanup, 1)))
                unwind(failure, reason, false, 4);
        SS(Sret, cons(SO(Sbody), SO(Sret), &cleanup));
        SS(Sret, cons(SO(Senv), SO(Sret), &cleanup));
        SS(Sret, atom(Theap, SO(Sformals), SO(Sret),
                is_applicative ? FORM_APPLICATIVE : FORM_OPERATIVE, &cleanup));
        r = SO(Sret);
        stack_clear(4);
        return r;
}

@ Despite being an incredibly powerful abstraction tool closures
cannot actually {\it do\/} anything on their own. Closures are built
from closures built out of closures which, eventually, must use
{\it primitive\/} tasks to perform actions --- closures are really
little more than an elaborate means of structuring memory.

The definition of primitives here is overly simplistic and has a
number of deficiencies both in terms of time and space, which will
be especially felt on the older and/or smaller architectures which
are also being targetted. For now (2022) this is a ``temporary
solution''\footnote{$^1$}{It's important only that primitives work
and speed is not of the essence.} until the evaluation process
(below) is ready to be considered some form of ``complete''.

A primitive is a block of \CEE/ code identified by a |Vprimitive|,
an integer offset into an array of |Oprimitive| objects, |Iprimitive|.

@d PRIMITIVE_PREFIX           4
@#
@d primitive(O)               (fix_value(lcar(O)))
@d primitive_label(O)         (lcdr(O))
@d primitive_base(O)          (&Iprimitive[primitive(O)])
@d primitive_applicative_p(O) (primitive_p(O) &&
        (primitive_base(O)->schema[0] >= '0') &&
        (primitive_base(O)->schema[0] <= '9'))
@d primitive_operative_p(O)   (primitive_p(O) && !primitive_applicative_p(O))
@<Type def...@>=
typedef enum {@+
        @<Primitive \CEE/ symbols@>@;@+
        PRIMITIVE_LENGTH@+
} Vprimitive;

typedef struct {
        char *schema; /* \Ls/ binding \AM\ signature. */
        cell  box; /* Heap storage. */
} Oprimitive;

@#
#if 0 /* Something like this to share segments between
            raw string and rope/symbol storage? */
        [PRIMITIVE_FOO] = { &Sym_FOO, NIL, ...},@;
        shared Osegment Sym_FOO = @[{ .address = "foo" }@];
#endif

@ The |Iprimitive| array associates the internal numeric identifier
with the \Ls/ symbol representing the primitive. During initialisation
each primitive is bound to its symbol in a pair stored in |Root|,
which is the initial environment the run-time is in prior to
establishing any closures and is what's returned by \.{(root-environment)}.

@<Global...@>=
Oprimitive Iprimitive[] = {
        @<Primitive schemata@>
};

unique cell Root = NIL;

@ @<Extern...@>=
extern Oprimitive Iprimitive[];
extern unique cell Root;

@ @<Register primitive operators@>=
Root = env_empty(failure);
for (i = 0; i < PRIMITIVE_LENGTH; i++) {
        x = symbol_new_const(Iprimitive[i].schema + PRIMITIVE_PREFIX);
        x = Iprimitive[i].box = atom(Theap, fix(i), x, FORM_PRIMITIVE, failure);
        env_define_m(Root, primitive_label(x), x, failure);
}

@** Compute.

@* Lexical Analysis. Source code is first scanned to categorise
each byte or contiguous sequence of bytes and create a lexeme object
out of them, concatenated together in a doubly-linked list.

The lexical analyser ({\it LEXAR\/}) is a state machine in the form
of a record holding at each moment where it is in the source code
and what it has most recently seen. Scanning proceeds until the
source rope is entirely consumed.

This lexical analyser occasionally needs to examine thext rune to
determine what lexeme is being represented. To achieve this it's
possible to return a rune into the state machine so that subsequent
iteration will return it instead of iterating over the backing rope.
This ordinarily simple task is complicated by the need to track
where in the rope the lexeme islocated, both by byte/rune position
and taking note of the rope twine, which may have changed between
runes.

Achieving this uses two pairs of cells in the analyser state machine,
each pair consisting of a rune and the twine in which it was
encountered.

The first pair is the ``peeked'' pair. Every returned twine/rune
combination is put here before being analysed and until the rune
is accepted further peeking will return that rune. If the rune is
put back then the combination is moved to the second --- ``backput''
--- pair and will not be considered when the analysis state is used
to create a complete lexical token but {\it will\/} be returned the
next time a rune is peeked (after being moved back to the ``peeked''
pair of attributes).

@d LEXAR_STARTER       0 /* Lexeme's starting twine. */
@d LEXAR_ITERATOR      1 /* Current position in rope. */
@d LEXAR_PEEKED_TWINE  2 /* Twine containing the rune under consideration. */
@d LEXAR_PEEKED_RUNE   3 /* The rune under consideration. */
@d LEXAR_BACKPUT_TWINE 4 /* The twine containing an unwanted rune. */
@d LEXAR_BACKPUT_RUNE  5 /* The unwanted rune. */
@d LEXAR_LENGTH        6
@#
@d lexar(O)                  ((Olexical_analyser *) record_base(O))
@d lexar_starter(O)          (record_cell((O), LEXAR_STARTER))
@d lexar_iterator(O)         (record_cell((O), LEXAR_ITERATOR))
@d lexar_peeked_rune(O)      (record_cell((O), LEXAR_PEEKED_RUNE))
@d lexar_peeked_twine(O)     (record_cell((O), LEXAR_PEEKED_TWINE))
@d lexar_backput_rune(O)     (record_cell((O), LEXAR_BACKPUT_RUNE))
@d lexar_backput_twine(O)    (record_cell((O), LEXAR_BACKPUT_TWINE))
@#
@d lexar_set_starter_m(O,D)  (record_set_cell_m((O), LEXAR_STARTER, (D)))
@d lexar_set_iterator_m(O,D) (record_set_cell_m((O), LEXAR_ITERATOR, (D)))
@d lexar_set_peeked_rune_m(O,D)
        (record_set_cell_m((O), LEXAR_PEEKED_RUNE, (D)))
@d lexar_set_peeked_twine_m(O,D)
        (record_set_cell_m((O), LEXAR_PEEKED_TWINE, (D)))
@d lexar_set_backput_rune_m(O,D)
        (record_set_cell_m((O), LEXAR_BACKPUT_RUNE, (D)))
@d lexar_set_backput_twine_m(O,D)
        (record_set_cell_m((O), LEXAR_BACKPUT_TWINE, (D)))
@<Type def...@>=
typedef struct { /* For brevity's sake accessors are not defined for these attributes. */
        long tbstart;  /* Byte offset where this lexeme began. */
        long blength;  /* Number of bytes scanned so far. */
        long cpstart;  /* \ditto\ runes (into the {\it whole\/} rope). */
        long cplength; /* \ditto\ scanned. */
} Olexical_analyser;

@ @<Fun...@>=
cell lexar_append (int, int, Vlexicat, int, sigjmp_buf  *);
cell lexar_clone (cell, sigjmp_buf *);
cell lexar_peek (int, sigjmp_buf *);
void lexar_putback (int);
cell lexar_start (cell, sigjmp_buf *);
cell lexar_take (int, sigjmp_buf *);
cell lex_rope (cell, sigjmp_buf *);
cell lexar_token (int, int, sigjmp_buf *);

@ To begin scanning |lexar_start| is called with the rope to scan
and it returns a fresh lexical analyser state machine ready to
iterate from the beginning of the rope.

@c
cell
lexar_start (cell        o,
             sigjmp_buf *failure)
{
        static int Srope = 1, Sret = 0;
        cell r;
        sigjmp_buf cleanup;
        Verror reason = LERR_NONE;

        assert(rope_p(o));
        stack_protect(2, o, NIL, failure);
        if (failure_p(reason = sigsetjmp(cleanup, 1)))
                unwind(failure, reason, false, 2);
        SS(Sret, record_new(fix(RECORD_LEXAR), LEXAR_LENGTH,
                sizeof (Olexical_analyser), &cleanup));
        lexar_set_iterator_m(SO(Sret), rope_iterate_start(SO(Srope), -1,
                &cleanup));
        lexar_set_starter_m(SO(Sret), NIL);
        lexar_set_peeked_twine_m(SO(Sret), VOID);
        lexar_set_backput_twine_m(SO(Sret), VOID);
        r = SO(Sret);
        lexar(r)->tbstart = lexar(r)->blength =
                lexar(r)->cpstart = lexar(r)->cplength = 0;
        stack_clear(2);
        return r;
}

@ Raw strings and symbols scan three lexemes at a time and when
each begins the state of the analyser is cloned so that they can
be created correctly later.

@c
cell
lexar_clone (cell        o,
             sigjmp_buf *failure)
{
        static int Slexar = 1, Sret = 0;
        cell r, tmp;
        sigjmp_buf cleanup;
        Verror reason = LERR_NONE;

        assert(lexar_p(o));
        stack_protect(2, o, NIL, failure);
        if (failure_p(reason = sigsetjmp(cleanup, 1)))
                unwind(failure, reason, false, 2);
        SS(Sret, r = record_new(fix(RECORD_LEXAR), LEXAR_LENGTH,
                sizeof (Olexical_analyser), &cleanup));
        tmp = lexar_starter(SO(Slexar));
        lexar_set_starter_m(r, tmp);
        tmp = rope_iterate_start(tmp, lexar(SO(Slexar))->tbstart, &cleanup);
        r = SO(Sret);
        lexar_set_iterator_m(r, tmp);
        lexar_set_peeked_twine_m(r, VOID);
        lexar_set_backput_twine_m(r, VOID);
        *lexar(r) = *lexar(SO(Slexar));
        stack_clear(2);
        return r;
}

@ When a rune is obtained, from the put-back buffer or by iteration
over the backing rope, or when a rune is put back into the put-back
buffer, its position in the source is updated. If the ``rune'' is
in fact |LEOF| then this takes up no space so care must be taken
when it gets put back.

After a lexeme is created and appended the starting location is
reset by setting the starter twine to |NIL|. In most cases the
analyser immediately returns the lexeme to the caller but those
which do not use |lexar_reset| directly to indicate the beginning
of a new lexeme without peeking.

@d lexar_reset(L,R) do {
        lexar_set_starter_m((L), rope_iter_twine((R)));
        lexar(L)->tbstart = rope_iter(R)->tboffset;
        lexar(L)->cpstart = rope_iter(R)->cpoffset;
} while (0)
@c
cell
lexar_peek (int         Silex,
            sigjmp_buf *failure)
{
        cell irope, ilex, r, tmp;

        assert(lexar_p(SO(Silex)));
        ilex = SO(Silex);
        irope = lexar_iterator(ilex);
        if (null_p(lexar_starter(ilex)))
                lexar_reset(ilex, irope);
        if (!void_p(lexar_backput_twine(ilex))) { /* Something has been put back. */
                assert(void_p(lexar_peeked_twine(ilex)));
                if (!eof_p(lexar_backput_rune(ilex))) { /* Start at the re-included rune. */
                        lexar(ilex)->tbstart -= rune_parsed(lexar_backput_rune(ilex));
                        lexar(ilex)->cpstart -= 1;
                }
                lexar_set_peeked_twine_m(ilex, lexar_backput_twine(ilex));
                lexar_set_peeked_rune_m(ilex, lexar_backput_rune(ilex));
                lexar_set_backput_twine_m(ilex, VOID);
        } else if (void_p(lexar_peeked_twine(ilex))) { /* Nothing is pending. */
                tmp = rope_iterate_next_utfo(irope, failure);
                lexar_set_peeked_rune_m(SO(Silex), tmp);
                lexar_set_peeked_twine_m(SO(Silex), rope_iter_twine(irope));
        } else
                return lexar_peeked_rune(ilex); /* A rune is already being examined. */
@#
        r = lexar_peeked_rune(ilex);
        if (!eof_p(r)) {
                lexar(ilex)->cplength++;
                lexar(ilex)->blength += rune_parsed(r);
        }
        return r;
}

@ If a rune is accepted by the scanner |lexar_take| clears the
peeked-at rune from the analyser state.

@c
cell
lexar_take (int         Silex,
            sigjmp_buf *failure)
{
        cell r;

        assert(lexar_p(SO(Silex)));
        assert(void_p(lexar_backput_twine(SO(Silex))));
        r = lexar_peek(Silex, failure);
        lexar_set_peeked_twine_m(SO(Silex), VOID);
        return r;
}

@ A rune can only be put back if the ``backput'' buffer is empty.
If so then the twine/rune pair is moved from the peeked buffer and
the scanned length count reduced (unless the ``rune'' was really
|LEOF|).

@c
void
lexar_putback (int Silex)
{
        cell tmp;

        assert(lexar_p(SO(Silex)));
        assert(!void_p(lexar_peeked_twine(SO(Silex))));
        assert(void_p(lexar_backput_twine(SO(Silex))));
        tmp = lexar_peeked_rune(SO(Silex));
        if (!eof_p(tmp)) {
                lexar(SO(Silex))->cplength--;
                lexar(SO(Silex))->blength -= rune_parsed(tmp);
        }
        lexar_set_backput_rune_m(SO(Silex), tmp);
        lexar_set_backput_twine_m(SO(Silex), lexar_peeked_twine(SO(Silex)));
        lexar_set_peeked_twine_m(SO(Silex), VOID);
}

@ When a lexical token is complete |lexar_append| uses the current
state of the analyser to create a lexeme and resets the state
sufficient that the next scan will begin a new token by setting the
starter twine to |NIL|.

If the token being appended is |LEXICAT_SPACE| or |LEXICAT_INVALID|
and the previous token matches it then that token is extended rather
than appending another one.

@c
cell
lexar_append (int          Silex,
              int          Sret,
              Vlexicat     cat,
              int          flags,
              sigjmp_buf  *failure)
{
        cell r = NIL, tmp;
        Olexical_analyser *l;

        assert(lexar_p(SO(Silex)));
        if ((cat == LEXICAT_SPACE || cat == LEXICAT_INVALID) &&
                    (tmp = dlist_datum(SO(Sret)), lexeme_p(tmp)) &&
                    lexeme(tmp)->cat == cat && lexeme(tmp)->flags == flags) {
                lexeme(tmp)->blength += lexar(SO(Silex))->blength;
                lexeme(tmp)->cplength += lexar(SO(Silex))->cplength;
                r = SO(Sret);
        } else {
                l = lexar(SO(Silex));
                tmp = lexeme_new(cat, flags, lexar_starter(SO(Silex)),
                        l->tbstart, l->blength, l->cpstart, l->cplength, failure);
                r = dlist_append_datum_m(SO(Sret), tmp, failure);
                SS(Sret, r);
        }
        l = lexar(SO(Silex));
        if (!void_p(lexar_peeked_twine(SO(Silex))))
                lexar_take(Silex, failure);
        l->blength = l->cplength = 0;
        lexar_set_starter_m(SO(Silex), NIL);
        return dlist_datum(r);
}

@ The analysis state machine itself is implemented in |lexar_token|
which consumes bytes sufficient to emit a single token, possibly
leaving a rune in the buffer for the next token.

On top of the state held in the {\it lexar\/} object each token
uses the following variables.

@d RIS(O,V)              (rune(O) == (V)) /* Rune is ... */
@d CIS(O,V)              (lexeme(O)->cat == (V)) /* Category is ... */
@#
@d lexar_space_p(O)      (!rune_failure_p(O) &&@|
        (RIS((O), ' ') || RIS((O), '\t') ||
        RIS((O), '\r') || RIS((O), '\n')))
@d lexar_opening_p(O)    (!rune_failure_p(O) &&
        (RIS((O), '(') || RIS((O), '{') || RIS((O), '[')))
@d lexar_closing_p(O)    (!rune_failure_p(O) &&
        (RIS((O), ')') || RIS((O), '}') || RIS((O), ']')))
@d lexar_terminator_p(O) (eof_p(O) ||@|
        lexar_space_p(O) || lexar_opening_p(O) || lexar_closing_p(O))
@#
@d lexeme_terminator_p(O) (CIS((O), LEXICAT_END) ||@|
        CIS((O), LEXICAT_OPEN) || CIS((O), LEXICAT_CLOSE) ||@|
        CIS((O), LEXICAT_SPACE))
@c
cell
lexar_token (int         Silex,
             int         Sret,
             sigjmp_buf *failure)
{
        static int Ssdelim = 3;      /* The opening-delimiter lexeme of a
                                                raw string/symbol. */
        static int Sedelim = 2;      /* \ditto\ closing. */
        static int Srdelim = 1;      /* Remember where a closing delimiter
                                                {\it may\/} have begun. */
        static int Sditer = 0;       /* Rope iterator over an opening
                                                delimiter. */
        cell c;                      /* Current rune. */
        int32_t d, v;                /* \ditto\ \AM\ opening delimiter's
                                                value. */
        int base = 10;               /* The base of the number being scanned. */
        int has_imagination = 0;     /* The complexity of a number. */
        int has_sign = 0;            /* Whether a number began with a sign,
                                                and which. */
        int has_ratio = 0;           /* Whether and how a number is rational. */
        int flags = 0;               /* See \.{LLF\_*}. */
        int want_digit = MUST;       /* Whether a numeric digit is permitted. */
        Vlexicat cat = LEXICAT_NONE; /* The category that is discovered. */
        sigjmp_buf cleanup;
        Verror reason = LERR_NONE;
        cell r, tmp;
        int i;

        @<Perform lexical analysis@>@;
}

@ The regular |lexar_peek|/|lexar_putback|/|lexar_take| API is
further augmented by |lexar_another| to check whether the source
has terminated with |LEOF|, possibly prematurely and in many cases
it's known that the rune, if there is one, will be immediately
taken.

@d lexar_another(V,I,T,A,L,R,F) do {
        /* Variable \L\ Iterator \L\ Take? \L\ Allow-invalid? \L\ Label
                \L\ Return \L\ Failure */
        (V) = lexar_peek((I), (F));
        if (eof_p(V))
                goto L;
        else if (!(A) && rune_failure_p(V))
                return lexar_append((I), (R), LEXICAT_INVALID, LLF_NONE, (F));
        else if (T)
                (V) = lexar_take((I), (F));
} while (0)
@<Perform lexical analysis@>=
c = lexar_peek(Silex, failure);
if (eof_p(c))
        return lexar_append(Silex, Sret, LEXICAT_END, LLF_NONE, failure);
else if (rune_failure(c) == UTFIO_EOF)
        goto LEXAR_premature_eof;
else if (rune_failure_p(c))
        return lexar_append(Silex, Sret, LEXICAT_INVALID, LLF_NONE, failure);
else@+
        switch (rune(c)) {
        @<Look for blank space@>@;
        @<Look for a bracketing token@>@;
        @<Look for other syntactic tokens@>@;
        @<Look for a symbol@>@;
        @<Look for a string@>@;
        @<Look for a curious token@>@;
        @<Look for a number@>@;
        }
abort(); /* UNREACHABLE. */
@#
LEXAR_raw_eof: /* |LEOF| encountered while scanning a raw string or symbol. */
stack_clear(4);
Silex -= 4;
Sret -= 4;
@#
LEXAR_premature_eof: /* |LEOF| encountered any where else it should not be. */
lexar_append(Silex, Sret, LEXICAT_INVALID, LLF_NONE, failure);
tmp = rope_iter_twine(lexar_iterator(SO(Silex)));
lexar_set_starter_m(SO(Silex), tmp);
return lexar_append(Silex, Sret, LEXICAT_END, LLF_NONE, failure);

@ The range of space considered blank can be widened in future
implementations of \Ls/ but these four will do for now.

@<Look for blank space@>=
case ' ':
case '\t':
        return lexar_append(Silex, Sret, LEXICAT_SPACE, LLF_HORIZONTAL, failure);
case '\r':
case '\n':
        return lexar_append(Silex, Sret, LEXICAT_SPACE, LLF_VERTICAL, failure);

@ From the lexical analyser's perspective all brackets look the
same. It is the parser's job to consider the combination of an
opening bracket, closing bracket and their contents.

@<Look for a bracketing token@>=
case '(':@; /* List */
case '[':@; /* Vector */
case '{':@; /* Relation */
        return lexar_append(Silex, Sret, LEXICAT_OPEN, LLF_NONE, failure);
case ')':
case ']':
case '}':@;
        return lexar_append(Silex, Sret, LEXICAT_CLOSE, LLF_NONE, failure);

@ @<Look for other syntactic tokens@>=
case '.':@;
        return lexar_append(Silex, Sret, LEXICAT_DOT, LLF_NONE, failure);
case '\'':@;
        return lexar_append(Silex, Sret, LEXICAT_QUOTE, LLF_NONE, failure);

@*1 Strings and Symbols. Symbols are begun by any character which
isn't matched by anything else; the syntactic runes above or those
below which indicate some other token. Unlike most lisp or scheme
implementations only space or brackets terminate a symbol --- any
other rune (in particular \..) is considered part of the symbol
token.

At this stage no effort is made to constrain non-printable-ASCII
runes, including control characters, and the myriad unicode exceptions
and confusables. Some certainly should.

@.TODO@>
@<Look for a symbol@>=
default:@;
        while (1) {
                if (Interrupt)
                        siglongjmp(*failure, LERR_INTERRUPT);
                lexar_take(Silex, failure);
symbol: /* {\bf comefrom\/} what might have been numbers but aren't. */
                tmp = lexar_peek(Silex, failure);
                if (lexar_terminator_p(tmp)) {
                        lexar_putback(Silex);
                        return lexar_append(Silex, Sret, LEXICAT_SYMBOL,
                                LLF_NONE, failure);
                }
        }
        break;

@ Strings are delimited by \qo\.\Lt\qc, special characters within
them are escaped with \qo\.\#\qc. These were chosed to ease development
of \Ls/ and are subject to change when \Ls/ is subject to less
change.

Symbols with arbitrary labels can also be created using the same
escaping rules as strings by preceeding the opening \qo\.\Lt\qc\
delimiter with \qo\.\#\qc: \qo\.{\#\Lt...\Lt}\qc.

@<Look for a string@>=
case '"':
        return lexar_append(Silex, Silex, LEXICAT_INVALID, LLF_NONE, failure);
case '|':
        cat = LEXICAT_ESCAPED_STRING;
string: /* or ``{\bf comefrom\/} \.{"\#\Lt"}'' with |cat =
                LEXICAT_ESCAPED_SYMBOL|. */
        lexar_take(Silex, failure);
        while (1) {
                if (Interrupt)
                        siglongjmp(*failure, LERR_INTERRUPT);
                lexar_another(c, Silex, true, true, LEXAR_premature_eof, Sret, failure);
                if (rune(c) == '|')
                        return lexar_append(Silex, Sret, cat, LLF_NONE, failure);
                else if (rune(c) == '#') {
                        lexar_another(c, Silex, true, true, LEXAR_premature_eof, Sret, failure);
                        switch (rune(c)) {
                        @<Scan an escape sequence@>
                        }
                }
        }
        break;

@ Few escape sequences are defined. Anything other than these
following a \.\# is an error (except that the scanner is case
insensitive). The macros detect whether the appropriate byte(s) are
there.

\yskip\hskip3em\vbox{\halign{\quad#\hfil&\quad#\hfil&\quad#\hfil\cr
\.{\#\Lt}&\to&Literal \qo\.{\Lt}\qc.\cr
\.{\#\#}&\to&Literal \qo\.{\#}\qc.\cr
\.{\#x{\it xy}}&\to&Byte of value |0x|{\it xy}.\cr
\.{\#o{\it xyz}}&\to&Byte of value \PB{\T{\~xyz}}.\cr
\.{\#u{\it wxyz}}&\to&UTF-8 sequence encoding unicode code point
of value |0x|{\it wxyz\/}.\cr
\.{\#({\it xyz...})}&\to&(1--6 bytes) UTF-8 encoding of unicode
code point with value |0x|{\it xyz...}.\cr}}

@d lexar_detect_octal(V,I,C,R,F) {
        lexar_another((V), (I), true, true, LEXAR_premature_eof, (R), (F));
        if (!rune_failure_p(V) &&
                    rune(V) >= '0' && rune(V) <= '7') {
                lexar_take((I), (F));
                continue;
        }
        (C) = LEXICAT_INVALID;
        break;
}

@d lexar_detect_hexadecimal(V,I,C,R,F) {
        int32_t v;
        lexar_another((V), (I), true, true, LEXAR_premature_eof, (R), (F));
        v = rune(V);
        if (!rune_failure_p(V) && ((v >= '0' && v <= '9') ||
                    (v >= 'a' && v <= 'f') || (v >= 'A' && v <= 'F'))) {
                lexar_take((I), (F));
                continue;
        }
        (C) = LEXICAT_INVALID;
        break;
}
@<Scan an escape sequence@>=
case '#': case '|':
        break;
case 'o': case 'O': /* Byte in octal. */
        for (i = 0; i < 3; i++)
                lexar_detect_octal(c, Silex, cat, Sret, failure);
        break;
case 'x': case 'X': /* Byte in hex. */
        for (i = 0; i < 2; i++)
                lexar_detect_hexadecimal(c, Silex, cat, Sret, failure);
        break;
case 'u': case 'U': /* Unicode code point (rune) in 4 hex digits. */
        for (i = 0; i < 4; i++)
                lexar_detect_hexadecimal(c, Silex, cat, Sret, failure);
        break;
case '(': /* Variable length unicode code point (rune). */
        lexar_detect_hexadecimal(c, Silex, cat, Sret, failure);
        for (i = 5; i; i--)
                lexar_another(c, Silex, true, true,
                        LEXAR_premature_eof, Sret, failure);
                if (rune(c) == ')')
                        break;
                else
                        lexar_detect_hexadecimal(c, Silex, cat,
                                Sret, failure);
        if (!i && cat != LEXICAT_INVALID)
                lexar_another(c, Silex, true, true,
                        LEXAR_premature_eof, Sret, failure);
        if (rune(c) != ')')
                cat = LEXICAT_INVALID;
        break;
default:
        cat = LEXICAT_INVALID;
        break;

@ Strings of arbitrary bytes are delimited by arbitrary delimiters
which are themselves delimited by a pair of \.\$s. The delimiter
is everything between a pair of \qo\.\$\qc\ symbols --- for the
time being constrained to ASCII letters, numbers and \qo\.-\qc\
\AM\ \qo\.\_\qc\ --- and may be empty as in \qo\.{\$\$}\qc.
Successfully scanning a raw string appends three lexemes:
``|LEXICAT_DELIMITER|~\L~|LEXICAT_RAW_STRING|~\L~|LEXICAT_DELIMITER|''.

Arbitrary symbols can be defined with the same mechanism by preceeding
the opening delimiter with \qo\.\#\qc, as with escaped strings, and the
result then includes the |LEXICAT_RAW_SYMBOL| lexeme instead of
|LEXICAT_RAW_STRING|.

@<Look for a string@>=
case '$':
        cat = LEXICAT_RAW_STRING;
delimiter: /* or ``{\bf comefrom\/} \.{"\#\$"}'' with |cat = LEXICAT_RAW_SYMBOL|. */
        @<Scan a delimiter@>@;
        stack_reserve(4, failure);
        if (failure_p(reason = sigsetjmp(cleanup, 1)))
                unwind(failure, reason, false, 4);
        Silex += 4;
        Sret += 4;
        tmp = lexar_append(Silex, Sret, LEXICAT_DELIMITER, LLF_NONE, &cleanup);
        lexar_reset(SO(Silex), lexar_iterator(SO(Silex)));
        SS(Ssdelim, tmp);
        @<Scan a raw string for its closing delimiter@>@;

@ A raw string delimiter is ``everything'' from one \qo\.\$\qc\ to
another.

TODO: Broaden the range of permitted code-points from [\.{a-zA-Z0-9\_-}].

@.TODO@>
@<Scan a delimiter@>=
lexar_take(Silex, failure);
while (1) {
        if (Interrupt)
                siglongjmp(*failure, LERR_INTERRUPT);
        lexar_another(c, Silex, true, false, LEXAR_premature_eof, Sret, failure);
        v = rune(c);
        if (v == '$')
                break;
        else if (!((v >= 'a' && v <= 'z') || (v >= 'A' && v <= 'Z') ||
                    (v >= '0' && v <= '9') || v == '_' || v == '-'))
                return lexar_append(Silex, Sret, LEXICAT_INVALID, LLF_NONE, failure);
}

@ Scanning a raw string bypasses the usual lexar API to iterate
over the rope by bytes instead of runes. Each byte is accepted and
ignored unless it's \qo\.\$\qc\ which begins scanning for the closing
delimiter.

@<Scan a raw string...@>=
lexar(SO(Silex))->tbstart = rope_iter(lexar_iterator(SO(Silex)))->tboffset;
while (1) {
        if (Interrupt)
                siglongjmp(cleanup, LERR_INTERRUPT);
        tmp = lexar_clone(SO(Silex), &cleanup); /* Remember where we are if
                                        the delimiter is about to start. */
        SS(Sedelim, tmp);
        v = rope_iterate_next_byte(lexar_iterator(SO(Silex)), &cleanup);
        lexar(SO(Silex))->blength++;
        if (v == EOF)
                goto LEXAR_raw_eof;
        else if (v != '$')
                continue;
@t\4@>redelimiter: /* Think ``\.{\$abc\$...\$ab\$ab\$abc\$}''. */
        @<Scan a potential closing delimiter@>@;
}
delimited:@;
@<Finish and return a raw string/symbol combination@>@;

@ A literal \.\$ may be the beginning of a closing delimiter or it
may be part of the string, as may anything following the \.\$ up
to the closing delimiter's closing \.\$.

To deal with this irritating state of affairs whenever a \.\$ is
first encountered its position has already been saved in the stack
at |Sedlim|. While scanning for a closing delimiter the state which
may have to be saved if this turns out not to be a closing delimiter
but a \.\$ suggests another one might be starting is saved at
|Srdelim|.

With that book-keeping out the way the rope underlying the opening
delimiter is iterated along with the source rope until the closing
delimiter is complete or a conflict between the two indicates that
the string is not finished.

@<Scan a potential closing delimiter@>=
tmp = rope_iterate_start(lexeme_twine(SO(Ssdelim)),
        lexeme(SO(Ssdelim))->tboffset, &cleanup);
SS(Sditer, tmp);
rope_iterate_next_byte(tmp, failure); /* \qo\.\$\qc\ --- Will not fail
                                        (or be multi-byte). */
while (1) {
        if (Interrupt)
                siglongjmp(cleanup, LERR_INTERRUPT);
        SS(Srdelim, lexar_clone(SO(Silex), &cleanup)); /* Where the delimiter
                                                might {\it re\/}-start. */
        v = rope_iterate_next_byte(lexar_iterator(SO(Silex)), failure);
        if (v == EOF)
                goto LEXAR_raw_eof;
        else {
                lexar(SO(Silex))->cplength++;
                d = rope_iterate_next_byte(SO(Sditer), &cleanup); /* Will not fail. */
                if (v != d) {
                        if (v == '$') {
                                SS(Sedelim, SO(Srdelim));
                                lexar(SO(Silex))->blength += lexar(SO(Silex))->cplength;
                                lexar(SO(Silex))->cplength = 0;
                                goto redelimiter;
                        } else
                                break;
                } else if (v == '$')
                        goto delimited;
        }
}
lexar(SO(Silex))->blength += lexar(SO(Silex))->cplength;
lexar(SO(Silex))->cplength = 0;

@ After a closing delimiter is successfully scanned the saved
analyser state clones are used to create the three lexemes covering
the string and its delimiters.

TODO: gcc warns that |irope| and |idelim| are set but not used ---
are they a holdover from earlier buggier days?

@.TODO@>
@<Finish and return a raw string/symbol combination@>=
lexar(SO(Silex))->cplength++;
lexar(SO(Silex))->blength = lexar(SO(Silex))->cplength;
lexar(SO(Silex))->tbstart += lexar(SO(Sedelim))->blength;
lexar(SO(Sedelim))->cplength = 0;
lexar_append(Sedelim, Sret, cat, LLF_NONE, &cleanup);
r = lexar_append(Silex, Sret, LEXICAT_DELIMITER, LLF_NONE, &cleanup);
stack_clear(4);
return r;

@*1 Curios. Apart from strings, symbols and numbers (to follow)
there are curious tokens which are ``all bets are side off'' tokens
that begin with the rune \qo\.\#\qc. That is to say that the exact
rules of how to parse a token beginning with a \.\# are custom to
each curious token.

The curious tokens that \Ls/ understands, working in tandem with
the syntax parser, are:

\yskip\hskip3em\vbox{\halign{\quad#\hfil&\quad#\hfil\cr
%
\.{\#f}/\.{\#F} or \.{\#t}/\.{\#T}&Boolean false or true.\cr
%
\.{\#=} {\it\<symbol\/\>}&Denominate a recursive expression.\cr
%
\.{\#\#} {\it\<symbol\/\>}&Refer to a recursive expression.\cr
%
\.\#[\.{bBoOdDxX}]...&Curious number --- in base 2, 8, 10 or 16 respectively.\cr
%
\.{\#\${\it\<delimiter\/\>}\$}...&Beginning of a delimited {\it symbol\/}.\cr
%
\.{\#\Lt}...\.\Lt&Symbol with escape characters.\cr}}

Note that curiously signed numbers ($\pm$\.\#[\.{bodx}]...) are not
scanned for here. Any other rune following a \.\# is considered an
error for now.

@<Look for a curious token@>=
case '#':@;
        lexar_take(Silex, failure);
        lexar_another(c, Silex, true, false, LEXAR_premature_eof, Sret,
                failure);
        switch (rune(c)) {
        @<Detect a curious number@>@;
        case 'f': case 'F':@;
        case 't': case 'T':
                return lexar_append(Silex, Sret, LEXICAT_CONSTANT,
                        LLF_NONE, failure);
        case '=':
                return lexar_append(Silex, Sret, LEXICAT_RECURSE_IS,
                        LLF_NONE, failure);
        case '#':
                return lexar_append(Silex, Sret, LEXICAT_RECURSE_HERE,
                        LLF_NONE, failure);
        case '$':
                cat = LEXICAT_RAW_SYMBOL;@+
                goto delimiter;
        case '|':
                cat = LEXICAT_ESCAPED_SYMBOL;@+
                goto string;
        default:
                return lexar_append(Silex, Sret, LEXICAT_INVALID,
                        LLF_NONE, failure);
        }
        break;

@*1 Numbers. A number might be encountered bare by beginning with
an ASCII-encoded Arabic digit \.0--\.9 or it might be signed or be
curiously encoded in a base other than 10.

An initial \.- or \.+ may be the beginning of a number or a symbol.
These succeeded by a digit \.0--\.9 is a number, by \.. requires
further testing and anything else was a symbol, which the syntax
parser may reject.

@d UCP_INFINITY 0x211e
@d UCP_NAN_0 0x2116
@d UCP_NAN_1 0x20e0
@<Look for a number@>=
case '-':
case '+':@;
        has_sign = (c == '-') ? LLF_NEGATIVE : LLF_POSITIVE;
        lexar_take(Silex, failure);
        lexar_another(c, Silex, false, false, false_symbol, Sret,
                failure); /* See what's next. */
        switch (rune(c)) {
        @<Look for a signed number@>
        }

@ $\pm$ followed by  is the
start of a number.

@<Look for a signed number@>=
case '0': case '1': case '2': case '3': case '4':@;
case '5': case '6': case '7': case '8': case '9':@;
        want_digit = CAN;
        goto number;

@ \qo$\pm$\.\#\qc\ might be a signed curious number or it might be a
tokenisation error. \qo$\pm$\..\qc\ might be a signed vague number or a
signed vague symbol.

@<Look for a signed number@>=
case '#':
        lexar_take(Silex, failure);
        lexar_another(c, Silex, true, false, LEXAR_premature_eof, Sret, failure);
        switch (rune(c)) {
        @<Detect a curious number@>
        } /* Now with |has_sign| set. */
        return lexar_append(Silex, Sret, LEXICAT_INVALID, LLF_NONE, failure);
case '.':
        lexar_take(Silex, failure);
        has_ratio = LLF_DOT;
        want_digit = MUST;
        lexar_another(c, Silex, false, false, noisy_false_symbol, Sret, failure);
        v = rune(c);
        if (v >= '0' && v <= '9')
                goto number;
        goto noisy_false_symbol;
        WARN();

@ A curious number, ie.~one in any base, may or may not be signed.
In both cases this same section of code is included so if the
conclusion were to be reached with a standard \CEE/ |goto| there
would be two destinations in the |lexar_token| function with the
same label. To get around this, this inelegant |case|/|if|/|else|
adaptation of Duff's device\footnote{$^1$}{%
\pdfURL{https://en.wikipedia.org/wiki/Duff\%27s\_device}%
{https://en.wikipedia.org/wiki/Duff\%27s\_device}} is used in place
of a |goto| into the final block.

In effect the ``|if (1)|'' can be ignored if |else| is read as
``\.{{\bf goto case} '}[\.{xX}]\.' after it has set |base|''.

@<Detect a curious number@>=
case 'b': case 'B':@+
        if (1) base = 2;@+
        else@;
case 'd': case 'D':@+
        if (1) base = 10;@+
        else@;
case 'o': case 'O':@+
        if (1) base = 8;@+
        else@;
case 'x': case 'X':@+
        if (1) base = 16; /* {\bf comefrom\/} the other cases to after this. */
        flags = has_sign | base2flag(base);
        lexar_append(Silex, Sret, LEXICAT_CURIOUS, flags, failure);@+
        want_digit = MUST;
        goto number;

@ \qo$\pm$\.i\qc\ might begin the number \qo$\pm$\.{inf}\qc\ or it
might indicate an ambiguous symbol. A literal infinity symbol is
unambiguous.

@<Look for a signed number@>=
case 'i': case 'I':
        lexar_take(Silex, failure);
        lexar_another(c, Silex, false, false, noisy_false_symbol, Sret,
                failure);
        v = rune(c);
        if (v == 'n' || v == 'N') {
                lexar_take(Silex, failure);
                lexar_another(c, Silex, false, false, false_symbol, Sret,
                        failure);
                v = rune(c);
                if (v == 'f' || v == 'F')
                        goto infinity;
        }
        goto false_symbol;
case UCP_INFINITY:@;
        goto infinity;

@ Scanning $\pm$\.{nan} is the same as $\pm$\.{inf} apart from the
letters. A literal not-a-number symbol is likewise unambiguous but
consists of two the distinct runes |UCP_NAN_0| followed by |UCP_NAN_1|.

@<Look for a signed number@>=
case 'n': case 'N':
        lexar_take(Silex, failure);
        lexar_another(c, Silex, false, false, noisy_false_symbol, Sret,
                failure);
        v = rune(c);
        if (v == 'a' || v == 'A') {
                lexar_take(Silex, failure);
                lexar_another(c, Silex, false, false, false_symbol, Sret,
                        failure);
                v = rune(c);
                if (v == 'n' || v == 'N')
                        goto nan;
        }
        goto false_symbol;
case UCP_NAN_0:
        lexar_take(Silex, failure);
        lexar_another(c, Silex, false, false, noisy_false_symbol, Sret,
                failure);
        if (rune(c) == UCP_NAN_1)
                goto nan;
        goto noisy_false_symbol;

@ If something that initially looked like a number turned out to
be a symbol the analyser continues to scan as though it were always
a symbol but emits a warning indicating that the scanner/parser
might be confused.

This warning mechanism is poorly concieved (TODO).

@.TODO@>
@<Look for a signed number@>=
noisy_false_symbol:
        WARN();
default:@;
false_symbol:
        goto symbol;

@ Curious numbers aside, numbers might not be a number --- the
not-a-number symbol, or this block is jumped into by signed
$\pm$\.{nan} (see above). |has_ratio| is set to ensure that a \..
or \./ rune is no longer considered valid.

@<Look for a number@>=
case UCP_NAN_0:
        lexar_take(Silex, failure);
        lexar_another(c, Silex, false, false, false_symbol, Sret, failure);
        if (rune(c) != UCP_NAN_1)
                goto noisy_false_symbol;
nan:@;
        lexar_take(Silex, failure);
        lexar_another(c, Silex, false, false, LEXAR_premature_eof, Sret,
                failure);
        if (rune(c) == '.')
                has_ratio = LLF_DOT; /* Not really a ratio. */
        else
                cat = LEXICAT_INVALID;
        want_digit = MUST;
        goto number;

@ Similarly a number might be infinity.

@<Look for a number@>=
case UCP_INFINITY:@;
infinity:@;
        lexar_take(Silex, failure);
        has_ratio = LLF_RATIO; /* Not really a ratio. */
        want_digit = CANNOT;
        goto number;

@ Normal numbers, though, begin with one of the standard 10 digits.
When scanning a number is finished a lexeme is finally emitted
unless a(nother) digit is required.

@<Look for a number@>=
case '0': case '1': case '2': case '3': case '4':@;
case '5': case '6': case '7': case '8': case '9':@;
        want_digit = CAN;
number:@;
        lexar_take(Silex, failure);
        while (1) {
                if (Interrupt)
                        siglongjmp(*failure, LERR_INTERRUPT);
                lexar_another(c, Silex, false, false, finish, Sret, failure);
                switch ((v = rune(c))) {
                @<Scan the body of a number@>
                }
        }
finish:@;
        if (want_digit == MUST)
                cat = LEXICAT_INVALID;
        else if (cat == LEXICAT_NONE)
                cat = LEXICAT_NUMBER;
        flags = has_sign | base2flag(base) | has_imagination;
        lexar_append(Silex, Sret, cat, flags, failure);
        if (eof_p(c)) {
                lexar_reset(SO(Silex), lexar_iterator(SO(Silex)));
                return lexar_append(Silex, Sret, LEXICAT_END, LLF_NONE, failure);
        }
        return dlist_datum(SO(Sret));

@ When scanning a number the analyser, for readability's sake the
analyer allows sequential digits to be separated by an underscore
rune \qo\.\_\qc. Although readability's sake dictates that this
would be used every third rune or so the reality is that \Ls/ must
accept more. When a \.\_ rune is permissable |want_digit| is set
to the false value |CAN| and when it is not to the truth |MUST|.
When not only can a \.\_ be accepted but neither can a digit it is
set to the other truth |CANNOT|.

All types of scanning for number eventually end up here, which
checks that a digit's representation fits within the current base
or permits a lone \.\_ to pass, toggling |want_digit|.

@<Scan the body of a number@>=
case 'a': case 'b': case 'c': case 'd': case 'e': case 'f':@;
case 'A': case 'B': case 'C': case 'D': case 'E': case 'F':@;
        if (base < 16) cat = LEXICAT_INVALID;
case '9': case '8':@;
        if (base < 10) cat = LEXICAT_INVALID;
case '7': case '6': case '5':@;
case '4': case '3': case '2':@;
        if (base < 8) cat = LEXICAT_INVALID;
case '1': case '0':@;
        lexar_take(Silex, failure);
        if (want_digit < CAN) cat = LEXICAT_INVALID;
        want_digit = CAN;
        break;
case '_':
        lexar_take(Silex, failure);
        if (want_digit != CAN) cat = LEXICAT_INVALID;
        want_digit = MUST;
        break;

@ A single number lexeme can include a lone \.. or \./, followed
by a number following the regular scanning rules, to represent a
ratio.

@<Scan the body of a number@>=
case '/':
        if (has_ratio)
                cat = LEXICAT_INVALID;
        else if (1)
                has_ratio = LLF_SLASH;
        else@;
case '.':
        if (has_ratio)
                cat = LEXICAT_INVALID;
        else if (1)
                has_ratio = LLF_DOT;
        lexar_take(Silex, failure);
        want_digit = MUST;
        break;

@ A normal rational, infinite or non-number can be succeeded by
\.i, \.j or \.k which represents a number's imaginary or quaterniate
component. At this stage of analysis such a rune terminates scanning
this lexeme and it is left up to the parser to ensure that successive
numeric components are valid (that is to say that at the moment
such numbers are in \Ls/ wholly imaginary, or unimplemented).

@<Scan the body of a number@>=
case 'i':
case 'j':
case 'k':
        lexar_take(Silex, failure);
        has_imagination = LLF_IMAGINATE(v - 'i');
        goto finish;

@ If a rune less numeric than a NaN is encountered while scanning
a number then it's put back into the analyser and the number lexeme
ends.

@ @<Scan the body of a number@>=
default:
        lexar_putback(Silex);
        if (!lexar_terminator_p(c))
                cat = LEXICAT_INVALID;
        goto finish;

@ The only practical way to use the lexical analyser so far is this
|lex_rope| which expects an entire rope to have been read in already.

@c
cell
lex_rope (cell        src,
          sigjmp_buf *failure)
{
        static int Ssource = 3, Siter = 2, Snext = 1, Sret = 0;
        cell r = NIL, tmp;
        sigjmp_buf cleanup;
        Verror reason = LERR_NONE;

        assert(rope_p(src));
        stack_protect(4, src, NIL, NIL, NIL, failure);
        if (failure_p(reason = sigsetjmp(cleanup, 1)))
                unwind(failure, reason, false, 4);
        SS(Siter, tmp = lexar_start(SO(Ssource), &cleanup));
                SS(Sret, tmp = dlist_new(NIL, &cleanup));
        SS(Snext, tmp);
        while (1) {
                tmp = lexar_token(Siter, Snext, &cleanup);
                assert(lexeme_p(tmp));
                if (lexeme(tmp)->cat == LEXICAT_END)
                        break;
        }
        r = dlist_remove_m(SO(Sret));
        stack_clear(4);
        return r;
}

@* Syntax parser. The only entry point to the syntax parser is
|parse| which accepts the list of lexemes produced by the lexical
analyser and returns a syntax tree with, if any, the failures
encountered while scanning it.

@<Fun...@>=
cell parse (cell, bool *, sigjmp_buf *);
cell transform_lexeme_segment (cell, long, long, bool, int, bool *,
        sigjmp_buf *);
char parse_ascii_hex (cell, sigjmp_buf *);

@ A flat list of lexemes is transformed into a syntax tree in order.
The parser keeps track of the lexeme at which translation began
(|Sstart|) and that currently under consideration (|Sllex|). An
(unused for now) empty environment (|Senv|) is created to hold the
symbols used to build recursive structures; this environment is
entirely separate from the run-time environments used by the evaluator
(but does it need to be? TODO: discuss).

As parsing proceeds completed nodes are added to a stack (|Swork|)
awaiting inclusion in a list. When an opening token (\.(, \.[ or
\.\{) is encountered that lexeme is added instead and when a closing
token (\.),~\.]~or~\.\}) is encountered nodes are removed from this
stack until the corresponding opening lexeme is reached.

If an invalid or unexpected lexeme is encountered or any other
problem occurs its location is noted in a list of failures in |Sfail|,
parsing continues and the caller is informed that the syntax
is ultimately invalid.

@d parse_fail(S,E,L,F) do {
        cell _x = cons(fix((E)), (L), (F));
        SS((S), cons(_x, SO(S), (F)));
        (L) = lcdr(lcar(SO(S)));
} while (0)
@c
cell
parse (cell        llex,
       bool       *valid,
       sigjmp_buf *failure)
{
        static int Sstart = 6; /* Where we started. */
        static int Sllex =  5; /* Where we are now. */
        static int Senv =   4; /* Namespace for syntactic recursion
                                        (\.{\#=}/\.{\#\#}). */
        static int Swork =  3; /* Stack of remaining work. */
        static int Sbuild = 2; /* Temporary workspace. */
        static int Stmp =   1; /* Temporarier workspace. */
        static int Sfail =  0; /* The litany of failure. */
        cell r, lex, x, y, z;  /* Work space so temporary it's ignored by
                                        the garbage collector. */
        Vlexicat cat = LEXICAT_NONE; /* The current lexeme's category. */
        Verror pfail = LERR_NONE; /* Any failure while constructing a list. */
        char *buf = NULL; /* Buffer space for parsing strings and symbols. */
        bool has_tail = false, m; /* Whether a \.. has been seen (and a
                                        temporary |m|). */
        long offset = 0, a, b, c, i; /* Short-lived temporary variables. */
        sigjmp_buf cleanup;
        Verror reason = LERR_NONE;

        assert(dlist_p(llex)); /* ... of lexemes. */
        lex = dlist_datum(dlist_prev(llex));
        assert(lexeme_p(lex));
        assert(lexeme(lex)->cat == LEXICAT_END); /* {\it Not\/} saved in |cat|. */
        stack_protect(2, llex, llex, failure);
        if (failure_p(reason = sigsetjmp(cleanup, 1)))
                unwind(failure, reason, false, 2);
        stack_reserve(5, &cleanup);
        if (failure_p(reason = sigsetjmp(cleanup, 1)))
                unwind(failure, reason, false, 7);
        SS(Senv, env_empty(&cleanup));
        llex = SO(Sllex);
        @<Construct a syntax tree from a list of lexemes@>@;
        r = SO(Sbuild);
        if (!*valid)
                r = cons(r, SO(Sfail), &cleanup);
        stack_clear(7);
        return r;
}

@ The main parser loop iterates along the lexeme list one at a time
and ends when it reaches the terminating/starting |LEXICAT_END|
lexeme. After this the parsed syntax tree will be left in |Sbuild|
and |Swork| should be empty.

@<Construct a syntax tree from a list of lexemes@>=
while (cat != LEXICAT_END) {
        if (Interrupt)
                siglongjmp(*failure, LERR_INTERRUPT);
        lex = dlist_datum(llex);
        assert(lexeme_p(lex));
        cat = lexeme(lex)->cat;
        switch (cat) { @<Process the next lexeme@> }
        @<Parse quoted expression(s)@>@;
        SS(Sllex, llex = dlist_next(SO(Sllex)));
}
assert(null_p(SO(Swork))); /* I think... */
if (!null_p(SO(Swork))) {
        SS(Stmp, SO(Sbuild));
        SS(Sbuild, NIL);
        while (!null_p(SO(Swork))) {
                SS(Sbuild, cons(lcar(SO(Swork)), SO(Sbuild), &cleanup));
                SS(Swork, lcdr(SO(Swork)));
        }
        x = prove_invalid(SO(Sbuild), SO(Sstart), SO(Sllex), &cleanup);
        parse_fail(Sfail, LERR_SYNTAX, x, &cleanup);
        SS(Sbuild, cons(x, SO(Stmp), &cleanup));
}
if (!null_p(SO(Sfail)))
        *valid = false;

@ The simplest lexemes to handle are spaces which are ignored and
invalid lexemes which are also ignored but only recording the
failure.

@<Process the next lexeme@>=
case LEXICAT_SPACE:
        break; /* Space is meaningless\footnote{$^1$}{There's {\it
                        literally everything\/} in space.}. */
default:
case LEXICAT_INVALID:
        x = prove_invalid(lex, llex, llex, &cleanup);
        if (cat == LEXICAT_INVALID)
                parse_fail(Sfail, LERR_UNSCANNABLE, x, &cleanup);
        else
                parse_fail(Sfail, LERR_INTERNAL, x, &cleanup);
        SS(Swork, cons(x, SO(Swork), &cleanup));
        break;

@ Almost as simple is the two (four) boolean constants \.{\#f} \AM\
\.{\#t} (and \.{\#F} \AM\ \.{\#T}) which are appended to the work
queue.

@<Process the next lexeme@>=
case LEXICAT_CONSTANT:
        a = lexeme_byte(lex, 1);
        x = predicate(a == 't' || a == 'T');
        y = dlist_datum(dlist_next(llex));
        if (!lexeme_terminator_p(y)) {
                z = prove_invalid(x, llex, llex, &cleanup);
                parse_fail(Sfail, LERR_AMBIGUOUS, z, &cleanup);
        } else
                z = prove_new(x, llex, llex, &cleanup);
        SS(Swork, cons(z, SO(Swork), &cleanup));
        break;

@ Building a list involves multiple lexemes working in tandem. A
|LEXICAT_OPEN| lexeme is appended to the list waiting for a
|LEXICAT_CLOSE| lexeme to consume it (and everything after it). A
|LEXICAT_DOT| lexeme is also appended to the working list as-is and
is also consumed en route to the |LEXICAT_OPEN| which started the
list.

|LEXICAT_END| works similarly to |LEXICAT_CLOSE| in the way it
consumes list items except that encountering a pending |LEXICAT_OPEN|
(or a |LEXICAT_DOT|) indicates an error and the beginning of the
list is instead indicated by the working list being entirely consumed.

@<Process the next lexeme@>=
case LEXICAT_OPEN:
case LEXICAT_DOT:
        SS(Swork, cons(llex, SO(Swork), &cleanup));
        break;
case LEXICAT_END:
        assert(dlist_next(llex) == SO(Sstart));
case LEXICAT_CLOSE:
        pfail = LERR_NONE;
        has_tail = false;
        SS(Sbuild, NIL); /* Work in progress. */
        c = 0;
        while (1) {
                @<Finalise items stacked into |Swork|@>
        }
        x = SO(Sbuild);  /* Built object. */
        y = SO(Stmp);    /* Starting lexeme. */
        z = SO(Sllex);   /* Terminating lexeme. */
        if (pfail != LERR_NONE) {
                SS(Sbuild, prove_invalid(x, y, z, &cleanup));
                x = SO(Sbuild);
                parse_fail(Sfail, LERR_SYNTAX, x, &cleanup);
        } else
                SS(Sbuild, prove_new(x, y, z, &cleanup));
        if (cat != LEXICAT_END) /* Put it back on the head of |Swork| to
                                carry on parsing. */
                SS(Swork, cons(SO(Sbuild), SO(Swork), &cleanup));
        break;

@ Looping until the working queue is consumed --- as expected if
the current lexeme is a (the) |LEXICAT_END| --- the list is built
item by item into |Sbuild|. If the queue of work is fully consumed
and the current lexeme is {\it not\/} |LEXICAT_END| this indicates
an attempt to close a list which was not opened.

@<Finalise items stacked into |Swork|@>=
if (Interrupt)
        siglongjmp(cleanup, LERR_INTERRUPT);
llex = SO(Sllex);
if (null_p(SO(Swork))) {
        if (cat != LEXICAT_END)
                parse_fail(Sfail, pfail = LERR_UNOPENED_CLOSE,
                        llex, &cleanup);
        SS(Stmp, SO(Sstart));
        break;
}
x = lcar(SO(Swork)); /* The next working item to copy or process. */
if (!provenance_p(x)) {
        @<Finish building the list or fix its tail@>
}
SS(Sbuild, cons(lcar(SO(Swork)), SO(Sbuild), &cleanup));
SS(Swork, lcdr(SO(Swork)));
c++;

@ |LEXICAT_DOT| can only appear under constrained circumstances (or
not at all). If |LEXICAT_OPEN| is found and the current lexeme {\it
is\/} |LEXICAT_END| that indicates a list was begun and not ended.

@<Finish building the list or fix its tail@>=
assert(dlist_p(x) && lexeme_p(dlist_datum(x)));
x = dlist_datum(x); /* Opener ... */
if (lexeme(x)->cat == LEXICAT_DOT) {
        if (lexeme(lex)->cat != LEXICAT_CLOSE ||
                        lexeme_byte(lex, 0) != ')')
                parse_fail(Sfail, pfail = LERR_LISTLESS_TAIL,
                        llex, &cleanup);
        else if (has_tail)
                parse_fail(Sfail, pfail = LERR_DOUBLE_TAIL,
                        llex, &cleanup);
        else {
                has_tail = true;
                if (null_p(SO(Sbuild)))
                        parse_fail(Sfail, pfail = LERR_EMPTY_TAIL,
                                llex, &cleanup);
                else if (!null_p(lcdr(SO(Sbuild))))
                        parse_fail(Sfail, pfail = LERR_HEAVY_TAIL,
                                llex, &cleanup);
                else {
                        SS(Sbuild, lcar(SO(Sbuild)));
                        SS(Swork, lcdr(SO(Swork)));
                        continue;
                }
        }
} else { /* Found the/a |LEXICAT_OPEN|. */
        if (cat == LEXICAT_END)
                parse_fail(Sfail, pfail = LERR_UNCLOSED_OPEN,
                        llex, &cleanup);
        else {
                @<Complete parsing a list-like syntax@>
        }
        SS(Stmp, lcar(SO(Swork)));
        SS(Swork, lcdr(SO(Swork)));
        break;
}

@ After collecting all the items in a list-like construction the
opening and closing brackets are checked that they match and which
bracket it is indicates what object to create. Paired parentheses
\qo \.{( ... )}\qc\ surround a list and parsing is complete. Square
brackes \qo \.{[ ... ]}\qc\ mark an array which the list is converted
into and braces \qo \.{\{ ... \}}\qc\ produce a relation, which is
unimplemented.

@<Complete parsing a list-like syntax@>=
lex = dlist_datum(SO(Sllex)); /* ... Closer */
assert(rope_p(lexeme_twine(lex)));
a = lexeme_byte(x, 0); /* \.(, \.[ or \.\{. */
a = ((a + 1) & ~1) + 1; /* ASCII tricks \to\ what we want. */
if (cat == LEXICAT_END)
        b = '\0';
else
        b = lexeme_byte(lex, 0); /* What we got. */
if (a != b)
        parse_fail(Sfail, pfail = LERR_MISMATCH, llex, &cleanup);
else if (a == ']') {
        x = array_new_imp(c, UNDEFINED, FORM_ARRAY, &cleanup);
        y = SO(Sbuild);
        for (i = 0; i < c; i++, y = lcdr(y))
                array_set_m(x, i, lcar(y));
        SS(Sbuild, x);
} else if (a == '}')
        parse_fail(Sfail, pfail = LERR_UNIMPLEMENTED, llex, &cleanup);

@ As with a |LEXICAT_OPEN| or |LEXICAT_DOT| which cannot be processed
until a |LEXICAT_CLOSE| is reached, a |LEXICAT_QUOTE| lexeme cannot
be constructed into a complete syntax object until the object it's
quoting has been parsed.

@<Process the next lexeme@>=
case LEXICAT_QUOTE:
        SS(Swork, cons(llex, SO(Swork), &cleanup));
        break;

@ After a complete (or invalid) expression has been parsed the
working stack is checked to see if it should be passed as-is or
wrapped in a \.{quote} operator.

@<Parse quoted expression(s)@>=
if (!null_p(SO(Swork)))
        while (provenance_p(lcar(SO(Swork)))) {
                x = lcar(SO(Swork)); /* To be quoted? */
                if (null_p(lcdr(SO(Swork))))
                        break; /* Nope --- nothing prior. */
                y = lcadr(SO(Swork)); /* Previously parsed... */
                if (provenance_p(y))
                        break; /* Nope --- not quoted. */
                assert(dlist_p(y) && lexeme_p(dlist_datum(y)));
                z = dlist_datum(y);
                if (lexeme(z)->cat != LEXICAT_QUOTE)
                        break; /* Nope --- something else. */
                z = cons(Iprimitive[PRIMITIVE_QUOTE].box, x, &cleanup);
                x = lcar(SO(Swork));@+ y = lcadr(SO(Swork)); /* Maybe lost. */
                assert(provenance_p(x));
                assert(dlist_p(y) && lexeme_p(dlist_datum(y)));
                z = prove_new(z, y, prove_end(x), &cleanup);
                SS(Swork, lcddr(SO(Swork))); /* Pop expression \AM\ quote. */
                SS(Swork, cons(z, SO(Swork), &cleanup));
        }

@ A simple |LEXICAT_SYMBOL| can be read directly into a segment and
converted into a symbol.

@<Process the next lexeme@>=
case LEXICAT_SYMBOL:
        y = dlist_datum(dlist_next(SO(Sllex)));
        if (!lexeme_terminator_p(y)) {
                z = prove_invalid(lex, llex, llex, &cleanup);
                parse_fail(Sfail, LERR_AMBIGUOUS, z, &cleanup);
        } else {
                a = lexeme(lex)->blength;
                SS(Sbuild, x = segment_new(0, a, 0, 0, &cleanup));
                buf = segment_address(x);
                lex = dlist_datum(SO(Sllex));
                x = rope_iterate_start(lexeme_twine(lex),
                        lexeme(lex)->tboffset, &cleanup);
                for (i = 0; i < a; i++)
                        buf[i] = rope_iterate_next_byte(x, &cleanup);
                y = symbol_new_buffer(buf, a, &cleanup);
                z = prove_new(y, SO(Sllex), SO(Sllex), &cleanup);
                buf = NULL;
        }
        SS(Swork, cons(z, SO(Swork), &cleanup));
        break;

@ A similar process is used to read the body of symbols and strings
which are included raw (delimited) or with embededded escape
characters. In the first case a buffer of the appropriate size can
be created, filled and used directly. In the latter it must be
processed to convert any escape character combinations within it.

Unlike a plain symbol for convenience these four cases all use the
more heavy-weight method outlined in |transform_lexeme_segment| to
copy and optionally transform a lexeme into a segment.

@<Process the next lexeme@>=
case LEXICAT_ESCAPED_SYMBOL:
        offset++; /* \.{\Lt...\Lt} */
case LEXICAT_ESCAPED_STRING:
        offset++; /* \.{\#\Lt...\Lt} */
        SS(Stmp, llex);
case LEXICAT_DELIMITER:
        if (cat == LEXICAT_DELIMITER) { /* [\.\#]\.{\$xxx\$...\$xxx\$} */
                @<Validate the lexical triplet in a delimited string/symbol@>
        } /* Sets |z| if there was an error. */
        if (null_p(lex))
                SS(Sbuild, z);
        else {
                m = true;
                x = transform_lexeme_segment(lex, offset, lexeme(lex)->blength,
                        (offset != 0), Sfail, &m, &cleanup);
                SS(Sbuild, x);
                if (!m)
                        SS(Sbuild, prove_invalid(SO(Sbuild), SO(Sllex),
                                SO(Stmp), &cleanup));
                else {
                        if (cat == LEXICAT_RAW_STRING ||
                                        cat == LEXICAT_ESCAPED_STRING)
                                y = rope_new_buffer(true, true,
                                        segment_address(x), segment_length(x),
                                        &cleanup);
                        else
                                y = symbol_new_segment(x, &cleanup);
                        SS(Sbuild, prove_new(y, SO(Sllex),
                                SO(Stmp), &cleanup));
                }
        }
        SS(Swork, cons(SO(Sbuild), SO(Swork), &cleanup));
        if (cat != LEXICAT_ESCAPED_SYMBOL && cat != LEXICAT_ESCAPED_STRING)
                SS(Sllex, SO(Stmp));
        offset = 0; /* Must always begin at zero. */
        break;

@ A delimited string or symbol consists of two |LEXICAT_DELIMITER|s
with a |LEXICAT_RAW_STRING| or |LEXICAT_RAW_SYMBOL| in the middle.
No other combination of these lexemes is valid and the contents of
the delimiters must match exactly. These are not actually verified
but is what is created by the lexical analyser.

Strictly speaking there's no need to enforce requiring a terminating
lexeme after an escapable or delimited string or symbol but is done
for consistency with plain symbols and also to catch some ambiguous
potential mistakes such as \qo\.{\Lt foreshort 4\Lt 2}\qc.

@<Validate the lexical triplet in a delimited string/symbol@>=
SS(Sbuild, x = dlist_next(llex)); /* String/symbol content. */
SS(Stmp, y = dlist_next(x)); /* Closing delimiter. */
lex = dlist_datum(x);
cat = lexeme(lex)->cat;
if (cat == LEXICAT_INVALID) { /* Source ended without the closing delimiter. */
        z = prove_invalid(lex, SO(Sllex), SO(Sbuild), &cleanup);
        parse_fail(Sfail, LERR_UNSCANNABLE, z, &cleanup);
        SS(Stmp, SO(Sbuild));
        lex = NIL;
} else {
        assert(cat == LEXICAT_RAW_STRING || cat == LEXICAT_RAW_SYMBOL);
        z = dlist_next(y);
        assert(lexeme(dlist_datum(y))->cat == LEXICAT_DELIMITER);
        if (!lexeme_terminator_p(dlist_datum(z))) {
                z = prove_invalid(lex, lcar(SO(Swork)), SO(Stmp), &cleanup);
                parse_fail(Sfail, LERR_AMBIGUOUS, z, &cleanup);
                lex = NIL;
        }
}

@ To create a string or symbol object from source the opening
delimiter's |offset| bytes are skipped then |length| bytes are read
by iterating over the source rope.

Note that |transform_lexeme_segment| iterates over {\it bytes\/}
not runes to accomodate both raw data and regular data, which has
already had its runes' underlying bytes validated by the lexical
analyser.

This function has an awful name (TODO).

@.TODO@>
@c
cell
transform_lexeme_segment (cell        o,
                          long        offset,
                          long        length,
                          bool        escape,
                          int         Sfail,@|
                          bool       *valid,
                          sigjmp_buf *failure)
{
        static int Ssrc = 2, Sdst = 1, Siter = 0;
        cell r = NIL, tmp;
        char *buf, b;
        long i, j, k;
        int32_t cp;
        Outfio ucp;
        sigjmp_buf cleanup;
        Verror reason = LERR_NONE;

        assert(lexeme_p(o));
        assert(offset >= 0 && offset < lexeme(o)->blength);
        assert(length >= 1 && lexeme(o)->blength - offset <= length);
        stack_protect(3, o, NIL, NIL, failure);
        if (failure_p(reason = sigsetjmp(cleanup, 1)))
                unwind(failure, reason, false, 3);
        Sfail += 3;
        SS(Siter, rope_iterate_start(lexeme_twine(SO(Ssrc)),
                lexeme(SO(Ssrc))->tboffset, &cleanup));
        if (offset)
                length -= offset + 1;
        while (offset--)
                rope_iterate_next_byte(SO(Siter), &cleanup);
        SS(Sdst, segment_new(0, length, 0, 0, &cleanup));
        buf = segment_address(SO(Sdst));
        @<Copy, transforming, |length| bytes after |offset|@>@;
        r = SO(Sdst);
        stack_clear(3);
        return r;
}

@ If the data will not include escape sequences the rope can be
simply copied, otherwise each byte is examined and copied or
transformed. The segment written to is reduced in size as necessary
prior to being returned.

@<Copy, transforming, |length| bytes after |offset|@>=
if (!escape)
        for (i = 0; i < length; i++)
                buf[i] = rope_iterate_next_byte(SO(Siter), &cleanup);
else {
        j = 0;
        for (i = 0; i < length; i++) {
                b = rope_iterate_next_byte(SO(Siter), &cleanup);
                if (b != '#')
                        buf[j++] = b;
                else {
                        i++;
                        b = rope_iterate_next_byte(SO(Siter), &cleanup);
                        switch (b) {
                        @<Append an escaped byte sequence@>
                        }
                }
        }
        if (i != j)
                SS(Sdst, segment_resize_m(SO(Sdst), 0, j - i, &cleanup));
}

@ This macro and function converts one or two ASCII-encoded hex
digits into their numeric value.

@d hexscii_to_int(O) (((O) >= 'a') ? (O) - 'a' :
        ((O) >= 'A') ? (O) - 'A' : (O) - '0')
@d int_to_hexscii(O,C) ((O) < 10 ? (O) + '0' : ((C) ? (O) + 'A' : (O) + 'a'))
@c
char
parse_ascii_hex (cell        o,
                 sigjmp_buf *failure)
{
        int b, r;

        assert(rope_iter(o));
        b = rope_iterate_next_byte(o, failure);
        r = hexscii_to_int(b) << 4;
        b = rope_iterate_next_byte(o, failure);
        r |= hexscii_to_int(b);
        return (char) r;
}

@ The lexical analyser has ensured all escape sequences are validly
encoded so these sequences need no special effort.

@<Append an escaped byte sequence@>=
case '#':
case '|':
        buf[j++] = b;
        break;
case 'o':
case 'O': /* A byte represented by 3 octal digits. */
        buf[j] = (rope_iterate_next_byte(SO(Siter), &cleanup) - '0') << 6;
        buf[j] |= (rope_iterate_next_byte(SO(Siter), &cleanup) - '0') << 3;
        buf[j] |= (rope_iterate_next_byte(SO(Siter), &cleanup) - '0');
        i += 3;
        j++;
        break;
case 'x':
case 'X': /* A byte represented by 3 hex digits. */
        i += 2;
        buf[j++] = parse_ascii_hex(SO(Siter), &cleanup);
        break;

@ Although the source is well-encoded, the value representing an
escaped rune may not be a valid unicode code point. Such non-characters
are appended instead as |UCP_REPLACEMENT| (\.{U+FFFD}).

Note that a literal rune with value \.{U+FFFD} is {\it not\/} a
parser error.

@<Append an escaped byte sequence@>=
case 'u':
case 'U': /* A UTF-8 encoded byte sequence represented by 4 hex digits. */
        cp = 0;
        cp = parse_ascii_hex(SO(Siter), &cleanup) << 8;
        cp |= parse_ascii_hex(SO(Siter), &cleanup);
        i += 4;
        goto escaped_rune;
case '(': /* A UTF-8 encoded byte sequence represented by 1-6 hex digits. */
        cp = 0;
        rope_iterate_next_byte(SO(Siter), &cleanup); /* \.( */
        while ((b = rope_iterate_next_byte(SO(Siter), &cleanup)) != ')') {
                i++;
                cp <<= 4;
                cp |= hexscii_to_int(b);
        }
        i += 2;
escaped_rune:
        ucp = utfio_write(cp);
        tmp = rune_new_utfio(ucp, &cleanup);
        if (rune_failure_p(tmp)) {
                *valid = false;
                tmp = fix(j);
                parse_fail(Sfail, LERR_NONCHARACTER, tmp, &cleanup);
                ucp = utfio_write(UCP_REPLACEMENT);
                tmp = rune_new_utfio(ucp, &cleanup);
        }
        for (k = 0; k < rune_parsed(tmp); k++)
                buf[j++] = ucp.buf[k];

@ This early implementation of \Ls/ doesn't support parsing numbers
or syntactic recursion.

@<Process the next lexeme@>=
case LEXICAT_CURIOUS:
case LEXICAT_NUMBER:@;
@#
case LEXICAT_RECURSE_HERE:
case LEXICAT_RECURSE_IS:
        z = prove_invalid(lex, llex, llex, &cleanup);
        parse_fail(Sfail, LERR_UNIMPLEMENTED, z, &cleanup);
        SS(Swork, cons(z, SO(Swork), &cleanup));
        break;

@* Evaluator. The evaluator is based distantly on that presented
by Steele and Sussman in ``Design of LISP-Based Processors''.

There are five registers used by the evaluator. The argument to
|evaluate| --- the expression which is to be computed --- is saved
in |Expression| (|EXPR|) and with |Arguments| (|ARGS|) they represent
the state of the data being evaluated. Alongside those |Control_Link|
(|CLINK|) then represents the state of the computation evaluating
it in the form of a stack of partial work to later resume.

The run-time's current environment is in |Environment| (|ENV|) and
the result of computation (or the partial result while computation
is incomplete) in the |Accumulator| |ACC|. The shorter names are
defined for convenience.

@d ACC   Accumulator
@d ARGS  Arguments
@d CLINK Control_Link
@d ENV   Environment
@d EXPR  Expression
@<Global...@>=
unique cell Accumulator = NIL;
unique cell Arguments = NIL;
unique cell Control_Link = NIL;
unique cell Environment = NIL;
unique cell Expression = NIL;

@ The accumulator (the answer) is the only part of the evaluator
externally visible. This should perhaps be replaced by a return
value from |evaluate| (TODO)?

@.TODO@>
@<Extern...@>=
extern unique cell Accumulator, Arguments, Control_Link, Environment,
        Expression;

@ @<Fun...@>=
void evaluate (sigjmp_buf *);
void evaluate_program (cell, sigjmp_buf *);
void validate_formals (bool, sigjmp_buf *);
void validate_arguments (sigjmp_buf *);
void validate_operative (sigjmp_buf *);

@ The closure-constructing primitives \.{lambda} \AM\ \.{vov} and
the sequencing operator \.{do} are integral to the evaluator. We
also include the debugging aids \.{break} and \.{dump}. Curiously
the primitives \.{if} and \.{eval} do not occupy this hallowed
ground --- they are run-of-the mill operators no more special than
\.{cons} or \.{define!}.

@<Primitive \C...@>=
PRIMITIVE_BREAK,@/
PRIMITIVE_DO,@/
PRIMITIVE_DUMP,@/
PRIMITIVE_LAMBDA,@/
PRIMITIVE_QUOTE,@/
PRIMITIVE_VOV@&,

@ @<Primitive schema...@>=
[PRIMITIVE_BREAK]  = { "00__break",  NIL, },@/
[PRIMITIVE_DO]     = { ":___do",     NIL, },@/
[PRIMITIVE_DUMP]   = { "11__dump",   NIL, },@/
[PRIMITIVE_LAMBDA] = { "!:__lambda", NIL, },@/
[PRIMITIVE_QUOTE]  = { ":___quote",  NIL, },@/
[PRIMITIVE_VOV]    = { "!:__vov",    NIL, }@&,

@ @<Primitive imp...@>=
case PRIMITIVE_QUOTE:
        ACC = lcar(ARGS);
        break;

@ @<Type def...@>=
typedef enum {
        LDB_HALT_NONE,
        LDB_HALT_BEGIN,
        LDB_HALT_DISPATCH,
        LDB_HALT_COMBINE,
        LDB_HALT_RETURN
} Vbreak;

@ @<Global...@>=
unique Vbreak Halt_Next = LDB_HALT_NONE;
unique Vbreak Halt_At = LDB_HALT_NONE;

@ @<Extern...@>=
extern unique Vbreak Halt_Next, Halt_At;

@ @<Primitive imp...@>=
case PRIMITIVE_DUMP:
        lprint("DUMP ");
        next_argument(ACC, ARGS);
        serial(ACC, SERIAL_DETAIL, 42, NIL, NULL, failure);
        lprint("\n");
case PRIMITIVE_BREAK:
        ACC = VOID;
        breakpoint();
        break;

@ @<Fun...@>=
void breakpoint (void);

@ @c
void
breakpoint (void)
{
        printf("Why did we ever allow GNU?\n");
        Halt_At = Halt_Next;
        Halt_Next = LDB_HALT_RETURN;
}

@ The entry point to the evaluator is |evaluate| and |evaluate_program|
which calls |evaluate| after first prepending the \.{(do)} primitive
--- the \Ls/ syntax parser returns a list of expressions and without
\.{do} it would be evaluated as a single expression rather than a
sequence.

@c
void
evaluate_program (cell        o,
                  sigjmp_buf *failure)
{
        static int Sprogram = 0;
        bool syntactic;
        sigjmp_buf cleanup;
        Verror reason = LERR_NONE;

        stack_protect(1, o, failure);
        if (failure_p(reason = sigsetjmp(cleanup, 1)))
                unwind(failure, reason, false, 1);
        Expression = Iprimitive[PRIMITIVE_DO].box;
        syntactic = provenance_p(SO(Sprogram));
        if (syntactic) {
                Expression = cons(Expression, prove_datum(SO(Sprogram)), &cleanup);
                Expression = prove_new(Expression, prove_start(SO(Sprogram)),
                        prove_end(SO(Sprogram)), &cleanup);
        } else
                Expression = cons(Expression, SO(Sprogram), &cleanup);
        stack_clear(1);
        evaluate(failure);
}

@ Overall the evaluator determines for any given expression whether
it's a bare symbol to be looked up in the active environment or a
pair to evaluate recursively. Anything else is evaluated to itself.

\vskip 1em\epdf{llfig-1.pdf}

Figure 1 (TODO: label it) visualises the evaluation process. An
unevaluated expression is placed in |Expression| and the evaluator
begins at |Begin|. After the process of evaluation for a whole
expression has been completed the evaluator returns to |Return| and
the result will be available in the |Accumulator|.

Evaluating anything other than a list is simple. Look-up places a
bound value in |Accumulator| and reports an error if it wasn't
found. Everything else is copied as-is. The rest (all) of the diagram
describes how to evaluate a list --- called ``combining'' because
a list of one or more expressions is combined into a single expression.

The three boxes labelled \.{EVALUATE} and \.{MAGIC} can be thought
of as representing the whole of figure 1 again --- they are where
the evaluator recursively ``calls'' itself.

The labels in this diagram correspond to the \CEE/ labels of the
co-routines which implement them. The original S\AM S design of
this interpreter was for silicon and was written in a linear fashion
taking no advantage of \CEE/ idioms which are unavailable in pure
hardware. For the most part the code here still follows that same
pattern although a few liberties have been taken with some functional
accessors and \CEE/ contstructs.

@.TODO@>
@d venire(O) (provenance_p(O) ? prove_datum(O) : (O))
@d evaluate_incompatible(L,F) do { /* Inadquate arity-mismatch handling. */
        lprint("incompatibility at line %d\n", (L));
        siglongjmp(*(F), LERR_INCOMPATIBLE);
} while (0)
@c
void
evaluate (sigjmp_buf *failure)
{
        cell tmp;
        int count, flag, min, max;
        char *schema;
        Vbreak halted;

        halted = Halt_At;
        Halt_At = LDB_HALT_NONE;
        switch (halted) {
                case LDB_HALT_NONE: break;
                case LDB_HALT_BEGIN: goto Begin;
                case LDB_HALT_DISPATCH: goto Combine_Dispatch;
                case LDB_HALT_COMBINE: goto Combine_Operate;
                case LDB_HALT_RETURN: goto Return;
        }
        assert(null_p(CLINK) && null_p(ARGS));
        assert(environment_p(ENV));
        assert(!void_p(EXPR));
        ACC = VOID;
        goto Begin;
        @<Evaluate a complex expression@>@;
}

@ Unevaluated expressions are placed in |Expression| and the evaluator
is (re-)started here.

@<Evaluate a complex expression@>=
Begin:@;
        if (Halt_Next == LDB_HALT_BEGIN) {
                Halt_Next = Halt_At;
                Halt_At = LDB_HALT_BEGIN;
                return;
        }
        EXPR = venire(EXPR);
        if (pair_p(EXPR))         goto Combine_Start;
        else if (!symbol_p(EXPR)) goto Finish;
        ACC = env_search(ENV, EXPR, failure);
        if (undefined_p(ACC)) { /* For simpler debugging --- |abort()|
                                        will soon follow. */
                lprint("looking for %p ", EXPR);
                serial(EXPR, SERIAL_ROUND, 1, NIL, NULL, failure);
                lprint("\n");
                ACC = VOID;
                siglongjmp(*failure, LERR_MISSING);
        }
        goto Return;

@ The evaluator recurses back into itself by saving the current
state of computation (TODO: use the regular stack) and resuming at
|Begin| with an unevaluated |Expression|. When evaluation, recursive
or not, has finished control reaches |Return|.

If there is a {\it note\/} remaining on the |Control_Link| then
rather than returning the evaluated expression to the caller a layer
of recursion is unpeeled and the computation which it interrupted
is resumed at the appropriate co-process. TODO: This special object
type can/should probably be merged with syntax objects (which would
have been renamed).

Note that |PENDING_COMBINE_READY| is not detected here but the co-routine
which places it ends up jumping directly into |Combine_Ready|.

@<Evaluate a complex expression@>=
Finish:
        ACC = EXPR;
Return: /* Check |CLINK| to see if there is more work after complete
                evaluation. */
        if (Halt_Next == LDB_HALT_RETURN) {
                Halt_Next = Halt_At;
                Halt_At = LDB_HALT_RETURN;
                return;
        }
        if (null_p(CLINK))
                return; /* |Accumulator| (|ACC|) has the result. */
        switch(pending_stage(lcar(CLINK))) {
        case PENDING_COMBINE_BUILD:    goto Combine_Build;
        case PENDING_COMBINE_DISPATCH: goto Combine_Dispatch;
        case PENDING_COMBINE_FINISH:   goto Combine_Finish;
        case PENDING_MUTATE:           goto Mutate_Environment;
        case PENDING_EVALUATE:         goto Sequence;
        default:
                siglongjmp(*failure, LERR_INTERNAL); /* Unknown stage. */
        }

@ An expression which looks like list (other than the empty list)
represents a {\it combination\/} --- a function/procedure call or
an operator. Because the value in first pair of the list determines
what to do with the list (and even if it has to {\it be\/} a list)
it has to be evaluated in full before the evaluator can perform or
even prepare the combination.

A note is left to continue by dispatching to the appropriate
(applicative/operative/primitive) combiner and evaluation re-starts
with the unknown expression. The unevaluated arguments are recorded
in the note.

@<Eval...@>=
Combine_Start: /* Save any |ARGS| in progress and |ENV| on |CLINK| to
                        resume later. */
        CLINK = cons(ARGS, CLINK, failure);
        CLINK = cons(ENV, CLINK, failure);
        ARGS = lcdr(EXPR); /* Unevaluated arguments */
        ARGS = pend(PENDING_COMBINE_DISPATCH, ARGS, failure);
        CLINK = cons(ARGS, CLINK, failure);
        EXPR = lcar(EXPR); /* Unevaluated combiner */
        if (Trace) {
                lprint("(");
                serial(EXPR, SERIAL_DETAIL, 1, NIL, NULL, failure);
                lprint("\t");
                serial(ARGS, SERIAL_DETAIL, 2, NIL, NULL, failure);
                lprint(")\n");
        }
        goto Begin;

@ When control resumes after discovering the combiner the dispatch
note is removed and the combiner determines how to proceed after
restoring the unevaluated arguments. Note that all primitives will
test true for one of |applicative_p| or |operative_p| and so the
order of the tests is significant.

@<Eval...@>=
Combine_Dispatch: /* Restore the combination arguments and decide
                        how to process them. */
        if (Halt_Next == LDB_HALT_DISPATCH) {
                Halt_Next = Halt_At;
                Halt_At = LDB_HALT_DISPATCH;
                return;
        }
        next_argument(ARGS, CLINK);
        ARGS = pending_datum(ARGS); /* Unevaluated arguments */
        if (primitive_p(ACC))
                goto Combine_Primitive;
        else if (applicative_p(ACC))
                goto Combine_Applicative;
        else if (operative_p(ACC))
                goto Combine_Operate;
        else
                siglongjmp(*failure, LERR_UNCOMBINABLE);

@ A primitive combiner can be applicative or operative. The first
two bytes of a primitive schema are an ASCII digit if the primitive
is applicative and they indicate the minimum and maximum number of
arguments expected (if they're both zero the distinction between
applicative and operative is moot and the primitive presents as an
applicative).

When the evaluator has finished scanning the unevaluated arguments
as directed it falls through to the beginning of the argument
evaluation co-routine, |Combine_Continue| who's job is to distinguish
between yet more unevaluated arguments and completed list which is
ready to combine.

@<Eval...@>=
Combine_Primitive: /* Validate the arity of primitive arguments and prepare any
                        necessary for evaluation (née |Applicative_Start|). */
        ACC = pend(PENDING_COMBINE_READY, ACC, failure);
        CLINK = cons(ACC, CLINK, failure);
        ACC = pending_datum(ACC);
        EXPR = NIL;
        schema = Iprimitive[primitive(ACC)].schema;
        assert(*schema != '_');
        if (schema[0] >= '0' && schema[0] <= '9') {
                @<Copy an applicative primitive's arguments@>
        } else {
                @<Copy arguments according to a primitive's schema@>
        }
Combine_Continue: /* ie.~{\bf comefrom\/} above \AM\ |Applicative_Build|. */
        if (pair_p(EXPR)) goto Combine_Pair;
        else              goto Combine_Ready;

@ Applicative combinations expect their arguments to be a proper
list constrained to within a minimum and maximum size, often the
same. Each unevaluated argument is appended to |Expression| wrapped
in a marker with |LTRUE| indicating that it needs evaluation.

Note that this routine reverses the argument list.

@<Copy an applicative primitive's arguments@>=
count = 0;
min = schema[0] - '0';
max = (schema[1] == '.') ? -1 : schema[1] - '0';
while (pair_p(ARGS)) {
        count++;
        ACC = lcar(ARGS);
        ACC = cons(LTRUE, ACC, failure);
        EXPR = cons(ACC, EXPR, failure);
        ARGS = lcdr(ARGS);
}
if (!null_p(ARGS))
        siglongjmp(*failure, LERR_IMPROPER);
if (((max >= 0) && (count > max)) || (count < min))
        evaluate_incompatible(__LINE__, failure);
assert(max >= 0); /* There aren't any open-ended primitive applicatives. */

@ Operative primitives can likewise ensure a minimum and maximum
number of arguments but positionally. The schema of an operative
primitive is a sequence of tokens indicating how to process the
next argument(s). An argument must be present if the byte is \.E
or \.! but is optional if \.e or \.?. If the byte is \.E or \.e the
argument will be evaluated before calling the primitive's implementation.

The token \.: indicates that the remainder of the argument list
will be processed by the primitive and should not be scanned any
further. In particular the arguments which have been processed
already will have been copied to |Expression| {\it in reverse\/}
while the remaining have not.

@<Copy arguments according to a primitive's schema@>=
count = 0;
while (count++ < PRIMITIVE_PREFIX) {
        if ((*schema == 'E') || (*schema == '!')) { /* Required (\AM\
                                                        \.Evaluate). */
                if (null_p(ARGS))
                        evaluate_incompatible(__LINE__, failure);
                else if (!pair_p(ARGS))
                        siglongjmp(*failure, LERR_IMPROPER);
                else {
                        ACC = lcar(ARGS);
                        ACC = cons(predicate(*schema == 'E'), ACC, failure);
                        EXPR = cons(ACC, EXPR, failure);
                        ARGS = lcdr(ARGS);
                }
        } else if ((*schema == 'e') || (*schema == '?')) { /* Optional (\AM\
                                                                \.evaluate). */
                if (pair_p(ARGS)) {
                        ACC = lcar(ARGS);
                        ACC = cons(predicate(*schema == 'e'), ACC, failure);
                        EXPR = cons(ACC, EXPR, failure);
                        ARGS = lcdr(ARGS);
                } else if (!null_p(ARGS))
                        siglongjmp(*failure, LERR_IMPROPER);
        } else if (*schema == ':') { /* Collect remaining arguments unevaluated. */;
                ACC = cons(LFALSE, ARGS, failure);
                EXPR = cons(ACC, EXPR, failure);
                ARGS = NIL;
        } else if (*schema == '_') { /* No more arguments permitted. */
                if (pair_p(ARGS))
                        siglongjmp(*failure, LERR_IMPROPER);
                else if (!null_p(ARGS))
                        evaluate_incompatible(__LINE__, failure);
                break;
        }
        schema++;
}

@ Arguments to an applicative closure are all evaluated. While
preparing the argument list for evaluation the closure's formals
list is used to verify that the number of arguments is correct.

@<Eval...@>=
Combine_Applicative: /* Store the closure and evaluate its arguments. */
        ACC = pend(PENDING_COMBINE_READY, ACC, failure);
        CLINK = cons(ACC, CLINK, failure);
        ACC = pending_datum(ACC);
        EXPR = NIL;
        tmp = closure_formals(ACC);
#if 0
        lprint("formals ");
        serial(tmp, SERIAL_DETAIL, 12, NIL, NULL, failure);
        lprint(" ARGS ");
        serial(ARGS, SERIAL_DETAIL, 12, NIL, NULL, failure);
        lprint("\n");
#endif
        count = 0;
        while (pair_p(venire(ARGS))) {
                if (null_p(tmp))
                        count = 1;
                else if (pair_p(tmp))
                        tmp = lcdr(tmp); /* lost by cons */
                ACC = lcar(ARGS);
                ACC = cons(LTRUE, ACC, failure);
                EXPR = cons(ACC, EXPR, failure);
                ARGS = lcdr(venire(ARGS));
        }
        if (!null_p(ARGS))
                siglongjmp(*failure, LERR_IMPROPER);
        if (count || pair_p(venire(tmp)))
                evaluate_incompatible(__LINE__, failure);
        goto Combine_Continue;

@ After the arguments have been scanned for validity each is processed
in turn and evaluated if necessary. An evaluator return note is
prepared with the remaining arguments and control flows to the
evaluator's beginning if the argument must be evaluated or its end
if it must not.

@d next_argument(VAR, ARGS) do {
        (VAR) = lcar(ARGS);
        (ARGS) = lcdr(ARGS);
} while (0)
@d validated_argument(V,A,S,N,P,F) do {
        next_argument((V), (A));
        if ((!(N) && (null_p((S) ? venire(V) : (V)))) ||
                    !P((S) ? venire(V) : (V)))
                evaluate_incompatible(__LINE__, (F));
} while (0)
@<Eval...@>=
Combine_Pair: /* Prepare to append an argument, possibly after evaluation. */
        next_argument(ACC, EXPR);
        EXPR = pend(PENDING_COMBINE_BUILD, EXPR, failure);
        CLINK = cons(EXPR, CLINK, failure);
        EXPR = lcdr(ACC); /* (remaining) arguments to combination */
        if (true_p(lcar(ACC))) /* Needs evaluation? */
                goto Begin;
        else
                goto Finish;

@ Whether evaluated or not the next item in an argument list is
prepended to the |Arguments|, ultimately restoring them to their
original order and control resumes at |Combine_Continue| to determine
whether there are yet more arguments.

@<Eval...@>=
Combine_Build: /* Continue building a combination after evaluating
                        one expression. */
        ARGS = cons(ACC, ARGS, failure);
        next_argument(EXPR, CLINK);
        EXPR = pending_datum(EXPR);
        goto Combine_Continue;

@ When the combination's arguments are ready they have been built
piecemeal into |Arguments| or copied there as-is if the combiner
is an operative closure.

|Combine_Ready| and |Combine_Operate| implement the evaluator's
MAGIC by doing whatever it is primitives do, or by ``opening'' a
closure --- restoring its program and environment --- and ``entering''
it by recursing back into the evaluator.

@<Eval...@>=
Combine_Ready: /* Restore the saved closure or primitive. */
        next_argument(ACC, CLINK);
        assert(pending_stage(ACC) == PENDING_COMBINE_READY);
        ACC = pending_datum(ACC);
Combine_Operate:@;
        EXPR = pend(PENDING_COMBINE_FINISH, EXPR, failure);
        CLINK = cons(EXPR, CLINK, failure);
        if (Halt_Next == LDB_HALT_COMBINE) {
                Halt_Next = Halt_At;
                Halt_At = LDB_HALT_COMBINE;
                return;
        }
        if (primitive_p(ACC))
                switch (primitive(ACC)) {
                default:
                        siglongjmp(*failure, LERR_INTERNAL);
@t\4@>          @<Primitive implementations@>@;
                }
        else if (applicative_p(ACC)) {
                EXPR = ACC;                      /* Closure */
                ACC = lcar(EXPR);                /* Formals */
                EXPR = lcdr(EXPR);
                ENV = lcar(EXPR);                /* Environment */
                EXPR = lcdr(EXPR);
                ENV = env_extend(ENV, failure);
                EXPR = lcar(EXPR);               /* Body */
                validate_arguments(failure);
                goto Begin;
        }
        else if (operative_p(ACC)) {
                EXPR = ACC;                      /* Closure */
                ACC = lcar(EXPR);
                ARGS = cons(ACC, ARGS, failure); /* \.(Formals \.. Arguments\.) */
                EXPR = lcdr(EXPR);
                ACC = ENV;
                ENV = lcar(EXPR);                /* Environment */
                EXPR = lcdr(EXPR);
                ENV = env_extend(ENV, failure);
                EXPR = lcar(EXPR);               /* Body */
                validate_operative(failure);     /* Sets in |ENV| as required. */
                goto Begin;
        } else
                siglongjmp(*failure, LERR_INTERNAL); /* Unreachable. */
        goto Return;

@ A combiner places its result in the |Accumulator| if there is
one. The arguments that the result are a part of and the environment
the combiner was called from are restored and the evaluator, or one
layer of recursion into it, can return the evaluated result.

@<Eval...@>=
Combine_Finish: /* Restore the |ENV| and |ARGS| in place before
                        evaluating the combinator. */
        next_argument(EXPR, CLINK);
        EXPR = pending_datum(EXPR);
        ENV = lcar(CLINK);
        CLINK = lcdr(CLINK);
        ARGS = lcar(CLINK);
        CLINK = lcdr(CLINK);
        goto Return;

@ Parsed \Ls/ source code and the bodies of closures are evaluated
by the \.{do} primitive which expects its arguments to be a list
of expressions which it evaluates in turn, returning with the value
of the last. If there are no expressions to evaluate the value
|VOID| is returned.

To avoid reversing and re-reversing the list a pointer to the tail
is kept in the |Expression| register which is otherwise empty. This
algorithm is rather odd in that the new control link node is created
with the accumulator (the list head) in its tail position which is
then replaced. This is so that the evaluator does not require any
extra temporary storage.

@<Primitive imp...@>=
case PRIMITIVE_DO: /* (Operative) */
        next_argument(EXPR, ARGS);
        assert(null_p(ARGS));
        ARGS = pend(PENDING_EVALUATE, VOID, failure);
        ARGS = cons(ARGS, NIL, failure);
        ACC = ARGS;
        EXPR = venire(EXPR);
        while (!null_p(EXPR)) {
                if (!pair_p(EXPR))
                        evaluate_incompatible(__LINE__, failure);
                tmp = pend(PENDING_EVALUATE, venire(lcar(EXPR)), failure);
                tmp = cons(tmp, NIL, failure);
                lcdr_set_m(ACC, tmp);
                ACC = tmp;
                EXPR = lcdr(EXPR);
                EXPR = venire(EXPR);
        }
        lcdr_set_m(ACC, CLINK);
        CLINK = ARGS;
        break;

@ The \.{do} primitive is the only user of this co-routine.

@<Evaluate a complex expression@>=
Sequence:
        next_argument(EXPR, CLINK);
        EXPR = pending_datum(EXPR);
        goto Begin;

@ Closures are created in the same way whether they are applicative
or operative. The formals (which is where they do differ) are
validated and they along with the program body and the current
environment are saved.

@.TODO@>
@<Primitive imp...@>=
case PRIMITIVE_LAMBDA:@;
case PRIMITIVE_VOV:@;
        flag = (primitive(ACC) == PRIMITIVE_LAMBDA);
        next_argument(ACC, ARGS); /* Formals */
        next_argument(EXPR, ARGS); /* Body */
        EXPR = cons(Iprimitive[PRIMITIVE_DO].box, EXPR, failure);
        validate_formals(flag, failure);
        ACC = closure_new(flag, ARGS, ENV, EXPR, failure);
        break;

@ @c
@.TODO@>
void
validate_formals (bool        is_applicative,
                  sigjmp_buf *failure)
{
        static int Svargs = 2, Svenv = 1, Svcont = 0;
        cell arg, state;
        sigjmp_buf cleanup;
        Verror reason = LERR_NONE;

        ARGS = ACC; /* TODO: Also check all symbols are unique. */
        ACC = NIL;
        if (is_applicative) {
                @<Validate applicative (\.{lambda}) formals@>
        } else {
                @<Validate operative (\.{vov}) formals@>
        }
}

@ The {\it formals\/} argument to an applicative (\.{lambda})
expression take the shape of a symbol or a (possibly improper) list
of symbols. The symbols are copied first into the accumulator
(backwards) with their syntax wrapping removed, then copied back
into the accumulator in their original order.

Each symbol should be unique but this is not validated (TODO).

@.TODO@>
@<Validate applicative (\.{lambda}) formals@>=
while (pair_p(venire(ARGS))) {
        arg = lcar(venire(ARGS));
        ARGS = lcdr(venire(ARGS));
        assert(provenance_p(arg));
        arg = prove_datum(arg);
        if (!symbol_p(arg))
                evaluate_incompatible(__LINE__, failure);
        ACC = cons(arg, ACC, failure);
}
if (symbol_p(venire(ARGS)))
        ARGS = venire(ARGS);
else if (!null_p(venire(ARGS)))
        evaluate_incompatible(__LINE__, failure);
while (!null_p(ACC)) {
        ARGS = cons(lcar(ACC), ARGS, failure);
        ACC = lcdr(ACC);
}

@ The formals (or {\it informals\/}) argument to an operative
(\.{vov}) expression is a list of lists of two symbols. The first
such symbol is the variable name to bind; the second symbol is what
to bind to it: one of the caller's environment, the caller's
(unevaluated) arguments or (unimplemented) a continuation delimiter.

Each piece of state can be referenced once, and at least one piece
of state must be, and this is validated although each binding
(variable) name must be unique and this is not (TODO).

@.TODO@>
@d Sym_VOV_ARGS         (symbol_new_const("vov/args"))
@d Sym_VOV_ARGUMENTS    (symbol_new_const("vov/arguments"))
@d Sym_VOV_CONT         (symbol_new_const("vov/cont"))
@d Sym_VOV_CONTINUATION (symbol_new_const("vov/continuation"))
@d Sym_VOV_ENV          (symbol_new_const("vov/env"))
@d Sym_VOV_ENVIRONMENT  (symbol_new_const("vov/environment"))
@#
@d save_vov_informal(O,S) do {
        if (!null_p(SO(S)))
                evaluate_incompatible(__LINE__, failure);
        else
                SS((S), (O));
} while (0)
@<Validate operative (\.{vov}) formals@>=
stack_reserve(3, failure);
if (failure_p(reason = sigsetjmp(cleanup, 1)))
        unwind(failure, reason, false, 3);
ARGS = venire(ARGS);
while (pair_p(ARGS)) {
        arg = lcar(ARGS);
        arg = venire(arg);
        if (!pair_p(arg))
                evaluate_incompatible(__LINE__, failure);
        state = lcdr(arg);
        arg = lcar(arg);
        arg = venire(arg);
        if (!symbol_p(arg) || !pair_p(state) || !null_p(lcdr(state)))
                evaluate_incompatible(__LINE__, failure);
        state = lcar(state);
        state = venire(state);
        if (state == Sym_VOV_ARGS || state == Sym_VOV_ARGUMENTS)@/
                save_vov_informal(arg, Svargs);
        else if (state == Sym_VOV_ENV || state == Sym_VOV_ENVIRONMENT)
                save_vov_informal(arg, Svenv);
        else if (state == Sym_VOV_CONT || state == Sym_VOV_CONTINUATION)
                save_vov_informal(arg, Svcont);
        else
                evaluate_incompatible(__LINE__, failure);
        ARGS = lcdr(ARGS);
}
if (!null_p(ARGS) ||
            (null_p(SO(Svargs)) && null_p(SO(Svenv)) && null_p(SO(Svcont))))
        evaluate_incompatible(__LINE__, failure);
ARGS = cons(SO(Svcont), ARGS, failure);
ARGS = cons(SO(Svenv), ARGS, failure);
ARGS = cons(SO(Svargs), ARGS, failure);
stack_clear(3);

@ After an applicative closure's arguments have been fully evaluated
a new environment is created by extending the saved closure environment
and the evaluated arguments are bound within this new environment.
The arguments have already been validated prior to being evaluated
so ``validate'' is a bit of a misnomer and may have to change.

Although the |env_define| call here will have the effect of forcing
the formals symbols to be unique, this is the wrong place to rely
on it.

@c
void
validate_arguments (sigjmp_buf *failure)
{
        static int Sname = 1, Sarg = 0;
        cell arg, name;
        sigjmp_buf cleanup;
        Verror reason = LERR_NONE;

        stack_reserve(2, failure);
        if (failure_p(reason = sigsetjmp(cleanup, 1)))
                unwind(failure, reason, false, 2);
        SS(Sname, venire(ACC));
        SS(Sarg, ARGS);
        while (pair_p(SO(Sname))) {
                name = lcar(SO(Sname));
                SS(Sname, lcdr(SO(Sname)));
                assert(!null_p(SO(Sarg)));
                arg = lcar(SO(Sarg));
                SS(Sarg, lcdr(SO(Sarg)));
                env_define_m(ENV, name, arg, failure);
        }
        if (!null_p(SO(Sname))) {
                assert(symbol_p(SO(Sname)));
                env_define_m(ENV, SO(Sname), SO(Sarg), failure);
        } else
                assert(null_p(SO(Sarg)));
        stack_clear(2);
}

@ Similarly an operative closure saves pieces of interpreter state
into the directed bindingd.

@c
void
validate_operative (sigjmp_buf *failure)
{
        static int Sinformal = 0;
        sigjmp_buf cleanup;
        Verror reason = LERR_NONE;

        assert(pair_p(ARGS));
        stack_push(lcar(ARGS), failure);
        if (failure_p(reason = sigsetjmp(cleanup, 1)))
                unwind(failure, reason, false, 1);
        ARGS = lcdr(ARGS);

        assert(pair_p(SO(Sinformal)));
        if (symbol_p(lcar(SO(Sinformal))))
                env_define_m(ENV, lcar(SO(Sinformal)), ARGS, failure);
        SS(Sinformal, lcdr(SO(Sinformal)));

        assert(pair_p(SO(Sinformal)));
        if (symbol_p(lcar(SO(Sinformal))))
                env_define_m(ENV, lcar(SO(Sinformal)), ACC, failure);
        SS(Sinformal, lcdr(SO(Sinformal)));

        assert(pair_p(SO(Sinformal)));
        if (symbol_p(lcar(SO(Sinformal))))
                siglongjmp(cleanup, LERR_UNIMPLEMENTED); /* Continuation */
        assert(null_p(lcdr(SO(Sinformal))));

        stack_clear(1);
}

@* \.{error} Primitive.

@<Primitive \C...@>=
PRIMITIVE_ERROR, PRIMITIVE_TRACE@&,

@ @<Primitive schema...@>=
[PRIMITIVE_ERROR] = { ":___error", NIL, }@&,
[PRIMITIVE_TRACE] = { "11__trace", NIL, }@&,

@ @<Global...@>=
shared bool Trace = false;

@ @<Extern...@>=
extern shared bool Trace;

@ @<Primitive imp...@>=
case PRIMITIVE_ERROR:
        next_argument(ACC, ARGS);
        siglongjmp(*failure, LERR_USER);
case PRIMITIVE_TRACE:
        validated_argument(ACC, ARGS, true, false, boolean_p, failure);
        Trace = true_p(ACC);
        break;

@* \.{eval} Primitive.

@<Primitive \C...@>=
PRIMITIVE_EVAL@&,

@ @<Primitive schema...@>=
[PRIMITIVE_EVAL] = { "12__eval", NIL, }@&,

@ @<Primitive imp...@>=
case PRIMITIVE_EVAL:
        next_argument(EXPR, ARGS); /* Expression */
        if (null_p(ARGS))
                ACC = ENV;
        else
                next_argument(ACC, ARGS); /* Environment */
        if (!environment_p(ACC))
                evaluate_incompatible(__LINE__, failure);
        ENV = ACC;
        goto Begin;

@* \.{if} (Conditional) Primitive. \.{cond} is defined later as an
operative closure.

@<Primitive \C...@>=
PRIMITIVE_IF@&,

@ @<Primitive schema...@>=
[PRIMITIVE_IF] = { "E!?_if", NIL, }@&,

@ @<Primitive imp...@>=
case PRIMITIVE_IF: /* (Operative) */
        next_argument(ACC, ARGS); /* Condition */
        next_argument(EXPR, ARGS); /* Consequent */
        EXPR = cons(EXPR, VOID, failure);
        if (!null_p(ARGS))
                lcdr_set_m(EXPR, lcar(ARGS)); /* Alternate */
        EXPR = false_p(venire(ACC)) ? lcdr(EXPR) : lcar(EXPR);
        goto Begin;

@* Mutation Primitives \.{define!} \AM\ \.{set!}.

@<Primitive \C...@>=
PRIMITIVE_CLEAR_M,@/
PRIMITIVE_CURRENT_ENVIRONMENT,@/
PRIMITIVE_DEFINED_P,@/
PRIMITIVE_DEFINE_M,@/
PRIMITIVE_ENVIRONMENT_P,@/
PRIMITIVE_EXTEND,@/
PRIMITIVE_ROOT_ENVIRONMENT,@/
PRIMITIVE_SET_M,@/
PRIMITIVE_UNSET_M@&,

@ @<Primitive schema...@>=
[PRIMITIVE_CLEAR_M]             = { "E!__clear!",              NIL, },@/
[PRIMITIVE_CURRENT_ENVIRONMENT] = { "00__current-environment", NIL, },@/
[PRIMITIVE_DEFINED_P]           = { "E!__defined?",            NIL, },@/
[PRIMITIVE_DEFINE_M]            = { "E!:_define!",             NIL, },@/
[PRIMITIVE_ENVIRONMENT_P]       = { "11__environment?",        NIL, },@/
[PRIMITIVE_EXTEND]              = { "11__extend",              NIL, },@/
[PRIMITIVE_ROOT_ENVIRONMENT]    = { "00__root-environment",    NIL, },@/
[PRIMITIVE_SET_M]               = { "E!:_set!",                NIL, },@/
[PRIMITIVE_UNSET_M]             = { "E!__unset!",              NIL, }@&,

@ (define! <env> <sym> <expr>)

or (define! <env> (<sym> . <formals>) . <body>)
 == (define! <env> <sym> (lambda <formals> . <body>))

== (define! <env> <pair?> . <rest>)
 == (define! <env> ,(car <pair>) (lambda ,(cdr <pair) . <rest>))

@<Primitive imp...@>=
case PRIMITIVE_ENVIRONMENT_P:
        primitive_predicate(environment_p);
case PRIMITIVE_CURRENT_ENVIRONMENT:
        assert(null_p(ARGS));
        ACC = ENV;
        break;
case PRIMITIVE_ROOT_ENVIRONMENT:
        assert(null_p(ARGS));
        ACC = Root;
        break;
case PRIMITIVE_DEFINED_P:@;
        validated_argument(ACC, ARGS, false, false, environment_p, failure);
        validated_argument(tmp, ARGS, true, false, symbol_p, failure);
        ACC = env_search(ACC, tmp, failure);
        ACC = defined_p(ACC);
        break;
case PRIMITIVE_EXTEND:
        validated_argument(ACC, ARGS, false, false, environment_p, failure);
        ACC = env_extend(ACC, failure);
        break;

@ @<Primitive imp...@>=
case PRIMITIVE_DEFINE_M:
case PRIMITIVE_SET_M:
        flag = (primitive(ACC) == PRIMITIVE_DEFINE_M);
        validated_argument(ACC, ARGS, false, false, environment_p, failure);
        next_argument(EXPR, ARGS);                    /* Label or named Formals */
        EXPR  = venire(EXPR);
        if (pair_p(EXPR)) { /* Named applicative closure: \.(Label \.. Formals\.) */
                ARGS = cons(lcdr(EXPR), lcar(ARGS), failure); /* Body */
                ARGS = cons(Iprimitive[PRIMITIVE_LAMBDA].box, ARGS,
                        failure);
                EXPR = lcar(EXPR);                    /* Real binding label. */
                EXPR = venire(EXPR);
        } else if (symbol_p(EXPR)) {
                ARGS  = lcar(ARGS);
                if (!pair_p(ARGS) || !null_p(lcdr(ARGS)))
                        evaluate_incompatible(__LINE__, failure);
                ARGS = lcar(ARGS);                   /* Value (after evaluation). */
        } else
                evaluate_incompatible(__LINE__, failure);
        EXPR = cons(predicate(flag), EXPR, failure); /* Label */
        EXPR = cons(ACC, EXPR, failure);             /* Environment to mutate */
        EXPR = pend(PENDING_MUTATE, EXPR, failure);
        CLINK = cons(EXPR, CLINK, failure);
        EXPR = ARGS;                                 /* Value to evaluate. */
        goto Begin;

@ @<Primitive imp...@>=
case PRIMITIVE_CLEAR_M:
case PRIMITIVE_UNSET_M:
        flag = (primitive(ACC) == PRIMITIVE_CLEAR_M);
        validated_argument(ACC, ARGS, false, false, environment_p, failure);
        validated_argument(EXPR, ARGS, true, false, symbol_p, failure);
        EXPR = cons(UNDEFINED, EXPR, failure);
        EXPR = cons(ACC, EXPR, failure);
        EXPR = pend(PENDING_MUTATE, EXPR, failure);
        CLINK = cons(EXPR, CLINK, failure);
        ACC = predicate(flag);
        goto Mutate_Environment;

@ To mutate the environment needs support from the evaluator (or
another primitive to |Return| to).

@<Eval...@>=
Mutate_Environment:
        next_argument(EXPR, CLINK); /* \.(Environment new?-or-|UNDEFINED|
                                        \.. Label\.) */
        EXPR = pending_datum(EXPR);
        next_argument(tmp, EXPR);
        next_argument(ARGS, EXPR);
        if (boolean_p(ARGS)) { /* Value is in |Accumulator| */
                if (true_p(ARGS))
                        env_define_m(tmp, EXPR, ACC, failure);
                else
                        env_set_m(tmp, EXPR, ACC, failure);
        } else { /* Clear/unset is in |Accumulator| */
                assert(undefined_p(ARGS));
                if (true_p(ACC))
                        env_clear_m(tmp, EXPR, failure);
                else
                        env_unset_m(tmp, EXPR, failure);
        }
        goto Return;

@* Pairs \AM\ other simple objects.

@<Primitive \C...@>=
PRIMITIVE_APPLICATIVE_P,@/
PRIMITIVE_BOOLEAN_P,@/
PRIMITIVE_CAR,@/
PRIMITIVE_CDR,@/
PRIMITIVE_CONS,@/
PRIMITIVE_EOF_P,@/
PRIMITIVE_FALSE_P,@/
PRIMITIVE_NULL_P,@/
PRIMITIVE_OPERATIVE_P,@/
PRIMITIVE_PAIR_P,@/
PRIMITIVE_SYMBOL_P,@/
PRIMITIVE_TRUE_P,@/
PRIMITIVE_VOID_P@&,

@ @<Primitive schema...@>=
[PRIMITIVE_APPLICATIVE_P] = { "11__applicative?", NIL, },@/
[PRIMITIVE_BOOLEAN_P]     = { "11__boolean?",     NIL, },@/
[PRIMITIVE_CAR]           = { "11__car",          NIL, },@/
[PRIMITIVE_CDR]           = { "11__cdr",          NIL, },@/
[PRIMITIVE_CONS]          = { "22__cons",         NIL, },@/
[PRIMITIVE_EOF_P]         = { "11__eof?",         NIL, },@/
[PRIMITIVE_FALSE_P]       = { "11__false?",       NIL, },@/
[PRIMITIVE_NULL_P]        = { "11__null?",        NIL, },@/
[PRIMITIVE_OPERATIVE_P]   = { "11__operative?",   NIL, },@/
[PRIMITIVE_PAIR_P]        = { "11__pair?",        NIL, },@/
[PRIMITIVE_SYMBOL_P]      = { "11__symbol?",      NIL, },@/
[PRIMITIVE_TRUE_P]        = { "11__true?",        NIL, },@/
[PRIMITIVE_VOID_P]        = { "11__void?",        NIL, }@&,

@ Note that the |break| is {\it outside\/} the while-wart.

@d primitive_predicate(O) do {
        next_argument(ACC, ARGS);
        assert(null_p(ARGS));
        ACC = venire(ACC);
        ACC = predicate(O(ACC));
} while (0); break
@<Primitive imp...@>=
case PRIMITIVE_APPLICATIVE_P:
        primitive_predicate(applicative_p);
case PRIMITIVE_BOOLEAN_P:
        primitive_predicate(boolean_p);
case PRIMITIVE_FALSE_P:
        primitive_predicate(false_p);
case PRIMITIVE_NULL_P:
        primitive_predicate(null_p);
case PRIMITIVE_OPERATIVE_P:
        primitive_predicate(operative_p);
case PRIMITIVE_PAIR_P:
        primitive_predicate(pair_p);
case PRIMITIVE_SYMBOL_P:
        primitive_predicate(symbol_p);
case PRIMITIVE_TRUE_P:
        primitive_predicate(true_p);
case PRIMITIVE_VOID_P:
        primitive_predicate(void_p);

@ The pair constructor \.{cons} along with its accessors
\.{car}, \.{cdr}, etc. |ARGS| has been scanned sufficient to be
certain it is a proper list (or |NIL|).

@<Primitive imp...@>=
case PRIMITIVE_CONS:
        next_argument(ACC, ARGS);
        next_argument(EXPR, ARGS);
        assert(null_p(ARGS));
        ACC = cons(ACC, EXPR, failure);
        break;

case PRIMITIVE_CAR:
        validated_argument(ACC, ARGS, true, false, pair_p, failure);
        ACC = lcar(venire(ACC));
        break;

case PRIMITIVE_CDR:
        validated_argument(ACC, ARGS, true, false, pair_p, failure);
        ACC = lcdr(venire(ACC));
        break;

@* Object primitives.

@<Primitive \C...@>=
PRIMITIVE_NEW_HASHTABLE,
PRIMITIVE_HASHTABLE_DELETE_M,@/
PRIMITIVE_HASHTABLE_EXISTS_P,
PRIMITIVE_HASHTABLE_FETCH,@/
PRIMITIVE_HASHTABLE_FORGET_M,
PRIMITIVE_HASHTABLE_INSERT_M,@/
PRIMITIVE_HASHTABLE_KEYPAIRS,
PRIMITIVE_HASHTABLE_KEYS,@/
PRIMITIVE_HASHTABLE_P,
PRIMITIVE_HASHTABLE_REPLACE_M,@/
PRIMITIVE_HASHTABLE_STORE_M,
PRIMITIVE_HASHTABLE_VALUES@&,

@ @<Primitive schema...@>=
[PRIMITIVE_NEW_HASHTABLE]       = { "00__new-hashtable", NIL, },@/
[PRIMITIVE_HASHTABLE_DELETE_M]  = { "22__delete!",       NIL, },@/
[PRIMITIVE_HASHTABLE_EXISTS_P]  = { "22__exists?",       NIL, },@/
[PRIMITIVE_HASHTABLE_FETCH]     = { "22__fetch",         NIL, },@/
[PRIMITIVE_HASHTABLE_FORGET_M]  = { "22__forget!",       NIL, },@/
[PRIMITIVE_HASHTABLE_INSERT_M]  = { "33__insert!",       NIL, },@/
[PRIMITIVE_HASHTABLE_KEYPAIRS]  = { "11__keypairs",      NIL, },@/
[PRIMITIVE_HASHTABLE_KEYS]      = { "11__keys",          NIL, },@/
[PRIMITIVE_HASHTABLE_P]         = { "11__hashtable?",    NIL, },@/
[PRIMITIVE_HASHTABLE_REPLACE_M] = { "33__replace!",      NIL, },@/
[PRIMITIVE_HASHTABLE_STORE_M]   = { "33__store!",        NIL, },@/
[PRIMITIVE_HASHTABLE_VALUES]    = { "11__values",        NIL, }@&,

@ @<Primitive imp...@>=
case PRIMITIVE_HASHTABLE_P:
        primitive_predicate(hashtable_p);
case PRIMITIVE_NEW_HASHTABLE:
        ACC = hashtable_new(1, failure);
        break;

@ @<Primitive imp...@>=
{
        cell (*accessor)(cell) = NULL;
case PRIMITIVE_HASHTABLE_KEYS:
        accessor = lcar;@+
        goto Hash_Table_Scan;
case PRIMITIVE_HASHTABLE_VALUES:
        accessor = lcdr;@+
        goto Hash_Table_Scan;
case PRIMITIVE_HASHTABLE_KEYPAIRS:
        accessor = NULL;
Hash_Table_Scan:
        validated_argument(ACC, ARGS, false, false, hashtable_p, failure);
        ACC = hashtable_pairs(ACC, accessor, failure);
        break;
}

@ @<Primitive imp...@>=
case PRIMITIVE_HASHTABLE_EXISTS_P:@;
case PRIMITIVE_HASHTABLE_FETCH:
        flag = (primitive(ACC) == PRIMITIVE_HASHTABLE_EXISTS_P);
        validated_argument(ACC, ARGS, false, false, hashtable_p, failure);
        validated_argument(EXPR, ARGS, true, false, symbol_p, failure);
        ACC = hashtable_fetch(ACC, venire(EXPR), failure);
        if (flag)
                ACC = predicate(defined_p(ACC));
        else if (undefined_p(ACC))
                siglongjmp(*failure, LERR_MISSING);
        else
                ACC = lcdr(ACC);
        break;

@ @<Primitive imp...@>=
case PRIMITIVE_HASHTABLE_INSERT_M:
        flag = CANNOT;@+
        goto Hash_Table_Mutate;
case PRIMITIVE_HASHTABLE_REPLACE_M:
        flag = MUST;@+
        goto Hash_Table_Mutate;
case PRIMITIVE_HASHTABLE_STORE_M:
        flag = CAN;
Hash_Table_Mutate:
        validated_argument(ACC, ARGS, false, false, hashtable_p, failure);
        validated_argument(EXPR, ARGS, true, false, symbol_p, failure);
        hashtable_set_imp(ACC, venire(EXPR), lcar(ARGS), flag, failure);
        ACC = lcar(ARGS);
        break;

@ @<Primitive imp...@>=
case PRIMITIVE_HASHTABLE_DELETE_M:@;
case PRIMITIVE_HASHTABLE_FORGET_M:
        flag = (primitive(ACC) == PRIMITIVE_HASHTABLE_DELETE_M) ? MUST : CAN;
        validated_argument(ACC, ARGS, false, false, hashtable_p, failure);
        validated_argument(EXPR, ARGS, true, false, symbol_p, failure);
        hashtable_delete_m(ACC, venire(EXPR), false, flag, failure);
        ACC = VOID;
        break;

@** Serialisation.

@d serial_printable_p(O) ((O) >= ' ' && (O) < 0x7f)
@d SERIAL_SILENT 0
@d SERIAL_HUMAN  1
@d SERIAL_ROUND  2
@d SERIAL_DETAIL 3
@<Fun...@>=
void gc_serial (cell, cell);
void serial (cell, int, int, cell, cell *, sigjmp_buf *);
void serial_append_imp (cell, char *, int, sigjmp_buf *);
int serial_cycle (cell, cell);
char *serial_deduplicate (cell, int, cell, cell, sigjmp_buf *);
void serial_escape (char *, int, cell, sigjmp_buf *);
void serial_imp (cell, int, int, bool, cell, cell, sigjmp_buf *);
void serial_rope (cell, int, int, cell, cell, sigjmp_buf *);

@

what:
3 debug: all detail
2 round-trip: strings/symbols formatted, impossible-to-print objects abort
1 descriptive: (unimplemented)
0 silent (to collect a list of recursive points)

how:
strings escaped vs. raw
maximum depth
numeric base

buffer is a segment where the serialised result will be put. Can
only be |NIL| if |detail| is 0 or |dprint| is enabled.

@c
void
serial (cell        o,
        int         detail,
        int         maxdepth,
        cell        buffer,
        cell       *cycles,
        sigjmp_buf *failure)
{
        static int Sobject = 0;
        size_t count;
        Oheap *h, *heap;
        bool compacting;
        cell ignored = Null_Array; /* In case of |special_p(o)|. */
        sigjmp_buf cleanup;
        Verror reason = LERR_NONE;

        assert(defined_p(o));
        assert(maxdepth >= 0);
        if (detail)
                assert(null_p(buffer));
        else
                assert((LDEBUG_P && null_p(buffer)) || segment_p(buffer));
        if (cycles == NULL)
                cycles = &ignored;
        stack_protect(1, o, failure);
        if (failure_p(reason = sigsetjmp(cleanup, 1)))
                unwind(failure, reason, false, 1);
@#
        if (!special_p(o)) {
                @<Determine which heap an object is in@>@;
                @<Look for cyclic data structures@>@;
        }
        if (detail)
                serial_imp(SO(Sobject), detail, maxdepth, true, buffer,
                        *cycles, failure);
        stack_clear(1);
}

@ @<Determine which heap an object is in@>=
heap = Theap;
h = Sheap;
while (h != NULL)
        if (h == ATOM_TO_HEAP(o)) {
                heap = Sheap;
                break;
        } else
                h = h->next;

@ @<Look for cyclic data structures@>=
*cycles = array_new_imp(8, LFALSE, FORM_ARRAY, &cleanup);
pointer_set_datum_m(*cycles, fix(0));
compacting = (ATOM_TO_HEAP(o)->pair != NULL);
count = 0; /* Ignored. */
*cycles = gc_mark(heap, *cycles, compacting, NULL, &count);
SS(Sobject, gc_mark(heap, SO(Sobject), compacting, cycles, &count));
if (compacting)
        gc_compacting(heap, false);
else
        gc_sweeping(heap, false);
if (null_p(*cycles))
        siglongjmp(cleanup, LERR_OOM);
count = 2 * fix_value(pointer_datum(*cycles));
*cycles = array_grow_m(*cycles, count - array_length(*cycles), LFALSE, failure);
count /= 2;
pointer_set_datum_m(*cycles, fix(count));
@#
#if 0
serial_imp(SO(Sobject), SERIAL_SILENT, maxdepth, false, NULL, *cycles, failure);
pointer_set_datum_m(*cycles, fix(0));
for (i = 0; i < count; i++) {
        j = fix_value(pointer_datum(*cycles));
        if (true_p(array_ref(*cycles, i + count))) {
                if (i != j)
                        array_set_m(*cycles, j++, array_ref(*cycles, i));
                pointer_set_datum_m(*cycles, fix(j));
        }
}
for (; i < j * 2; i++)
        array_set_m(*cycles, j, LFALSE);
#endif

@ When it's collecting the object being serialised, the garbage
collector is instructed to call this function whenever it encounters
a reference it has already seen in that round of collection.

@c
@.TODO@>
void
gc_serial (cell cycles,
           cell found)
{
        int i, len;
        sigjmp_buf cleanup;
        Verror reason = LERR_NONE;

        if (null_p(cycles))
                return;
        if (failure_p(reason = sigsetjmp(cleanup, 1)))
                return; /* FIXME: The error is lost. */
        len = fix_value(pointer_datum(cycles));
        for (i = 0; i < len; i++)
                if (array_ref(cycles, i) == found)
                        return;
        if (len >= array_length(cycles))
                array_grow_m(cycles, array_length(cycles), LFALSE, &cleanup);
        array_set_m(cycles, len, found);
        pointer_set_datum_m(cycles, fix(len + 1));
}

@ @d serial_append(B,C,L,F) do {
        if (LDEBUG_P && null_p(B))
                for (int _i = 0; _i < (L); _i++)
                        lput((C)[_i]);
        else
                serial_append_imp((B), (C), (L), (F));
} while (0)
@c
void
serial_append_imp (cell        buffer,
                   char       *content,
                   int         length,
                   sigjmp_buf *failure)
{
        int i, off;

        assert(segment_p(buffer));
        off = fix_value(pointer_datum(buffer));
        i = segment_length(buffer) - off - 1;
        if (i > length)
                i = length;
        for (; i >= 0; i--)
                segment_address(buffer)[off + i] = content[i];
        segment_address(buffer)[off + i] = '\0';
        pointer_set_datum_m(buffer, fix(off + i));
        if (i != length)
                siglongjmp(*failure, LERR_OVERFLOW);
}

@ Uses \CEE/ stack (calls itself) but doesn't have to.

Buffer may be NIL if debugging and |LDEBUG_P| so |lprint|/|lput|
will work.

@c
void
serial_imp (cell        o,
            int         detail,
            int         maxdepth,
            bool        prefix @[Lunused@],
            cell        buffer,
            cell        cycles,
            sigjmp_buf *failure)
{
        int i, length = 0;
        char *append = NULL, buf[FIX_BASE10 + 2];

        assert(maxdepth >= 0);
        assert((LDEBUG_P && null_p(buffer)) || segment_p(buffer));
        assert(array_p(cycles));
        if (special_p(o)) {
                @<Serialise a unique object@>
        } else if (symbol_p(o)) {
                @<Serialise a symbol@>
        } else
                append = serial_deduplicate(o, detail, buffer, cycles, failure);
        if (append == NULL) {
                @<Serialise an object@>@; /* An unterminated |if|/|else
                                                if| chain. */
                else @+
                { /* Will go away when |@<Serialise an object@>| is complete. */
                        lprint("%2x?\n", form(o));
                        assert(!"unknown type");
                }
        }
@#
        if (append == NULL) {
                lprint("%p: %x\n", o, special_p(o) ?  -1 : form(o));
                siglongjmp(*failure, LERR_UNPRINTABLE);
        }
        if (!length) {
                length = append[0];
                append++;
        }
        if (detail)
                serial_append(buffer, append, length, failure);
}

@ @<Serialise a unique object@>=
if (null_p(o))
        append = "\002()";
else if (false_p(o))
        append = "\002#f";
else if (true_p(o))
        append = "\002#t";
else if (void_p(o)) { /* Licence to disappear. */
        if (detail == SERIAL_DETAIL)
                append = "\007#<void>";
#if 0
        else@+ if (detail != SERIAL_ROUND)
                append = "\000";
#endif
} else if (eof_p(o)) { /* The terminator will not be back. */
        if (detail == SERIAL_DETAIL)
                append = "\021#<schwarzenegger>";
} else if (undefined_p(o)) { /* Ecce res qui est faba. */
        if (detail == SERIAL_DETAIL)
                append = "\006#<zen>";
} else {
        assert(fix_p(o));
        i = fix_value(o);
        if (!i)
              append = "\0010";
        else {
                if (i < 0)
                        i = -i;
                append = buf + FIX_BASE10 + 2;
                *--append = '\0'; /* Terminator. */
                *--append = 0; /* Length. */
                while (i) {
                        *(append - 1) = *(append) + 1;
                        *append-- = (i % 10) + '0';
                        i /= 10;
                }
        }
        if (fix_value(o) < 0) {
                *(append - 1) = *(append) + 1;
                *append-- = '-';
        }
}

@ @<Serialise a symbol@>=
append = symbol_buffer(o);
length = symbol_length(o);
if (detail && maxdepth)
        for (i = 0; i < length; i++)
                if (!serial_printable_p(append[i])) {
                        if (detail) {
                                serial_append(buffer, "#|", 2, failure);
                                serial_escape(append, length, buffer, failure);
                                serial_append(buffer, "|", 1, failure);
                        }
                        append = "\0";
                        length = 0;
                        break;
                }

@ @c
void
serial_escape (char       *append,
               int         length,
               cell        buffer,
               sigjmp_buf *failure)
{
        int i, j;
        char ascii[4] = { '#', 'x', '\0', '\0' };

        for (i = 0; i < length; i++) {
                if (append[i] == '#')
                        serial_append(buffer, "##", 2, failure);
                else if (append[i] == '|')
                        serial_append(buffer, "#|", 2, failure);
                else if (append[i] == '\n' || append[i] == '\t' ||
                            serial_printable_p(append[i]))
                        serial_append(buffer, append + i, 1, failure);
                else {
                        j = (append[i] & 0xf0) >> 4;
                        ascii[2] = int_to_hexscii(j, false);
                        j = (append[i] & 0x0f) >> 0;
                        ascii[3] = int_to_hexscii(j, false);
                        serial_append(buffer, ascii, 4, failure);
                }
        }
}

@ @c
int
serial_cycle (cell cycles,
              cell candidate)
{
        int r;

        for (r = 0; r < fix_value(pointer_datum(cycles)); r++)
                if (array_ref(cycles, r) == candidate)
                        return r;
        return -1;
}

@ The first time a cycle is encountered identify and print it, later
occurrences refer back to it.

@c
char *
serial_deduplicate (cell        o,
                    int         detail,
                    cell        buffer,
                    cell        cycles,
                    sigjmp_buf *failure)
{
        int c, i;

        assert((LDEBUG_P && null_p(buffer)) || segment_p(buffer));
        assert(array_p(cycles));
        c = serial_cycle(cycles, o);
        if (c == -1)
                return NULL;
        i = c + fix_value(pointer_datum(cycles));
        if (!detail)
                array_set_m(cycles, i, LTRUE);
        else if (true_p(array_ref(cycles, i))) {
                serial_append(buffer, "##", 2, failure);
                serial_imp(fix(c), SERIAL_ROUND, 1, true, buffer, cycles, failure);
        } else {
                serial_append(buffer, "#=", 2, failure);
                serial_imp(fix(c), SERIAL_ROUND, 1, true, buffer, cycles, failure);
                serial_append(buffer," ", 1, failure);
                array_set_m(cycles, i, LTRUE);
                return NULL;
        }
        return "\0";
}

@ This is a long chain of |if|/|else if| beginning here. Not sure I like that.

@<Serialise an object@>=
if (pair_p(o)) {
        if (!maxdepth && detail != SERIAL_ROUND)
                append = "\005(...)";
        else if (maxdepth) {
                if (detail)
                        serial_append(buffer, "(", 1, failure);
                serial_imp(lcar(o), detail, maxdepth - 1, true, buffer, cycles,
                        failure);
                for (o = lcdr(o); pair_p(o); o = lcdr(o)) {
                        if (detail)
                                serial_append(buffer, " ", 1, failure);
                        serial_imp(lcar(o), detail, maxdepth - 1, true, buffer,
                                cycles, failure);
                }
                if (!null_p(o)) {
                        if (detail)
                                serial_append(buffer, " . ", 3, failure);
                        serial_imp(o, detail, maxdepth - 1, true, buffer,
                                cycles, failure);
                }
                if (detail)
                        serial_append(buffer, ")", 1, failure);
                append = "\0";
        }
}

@ @<Serialise an object@>=
else if (array_p(o)) {
        if (!maxdepth && detail != SERIAL_ROUND)
                append = "\005[...]";
        else if (maxdepth) {
                if (detail)
                        serial_append(buffer, "[", 1, failure);
                for (i = 0; i < array_length(o); i++) {
                        serial_imp(array_ref(o, i), detail, maxdepth - 1,
                                true, buffer, cycles, failure);
                        if (detail && i < array_length(o) - 1)
                                serial_append(buffer, " ", 1, failure);
                }
                if (detail)
                        serial_append(buffer, "]", 1, failure);
                append = "\0";
        }
}

@ @<Serialise an object@>=
else if (rope_p(o)) {
        if (detail == SERIAL_DETAIL) {
                serial_append(buffer, "“", (int) sizeof ("“"), failure);
                serial_rope(o, detail, maxdepth, buffer, cycles, failure);
                serial_append(buffer, "”", (int) sizeof ("”"), failure);
        } else {
                if (detail)
                        serial_append(buffer, "|", 1, failure);
                serial_rope(o, detail, maxdepth, buffer, cycles, failure);
                if (detail)
                        serial_append(buffer, "|", 1, failure);
        }
        append = "\0";
}

@ @c
void
serial_rope (cell        o,
             int         detail,
             int         maxdepth,
             cell        buffer,
             cell        cycles,
             sigjmp_buf *failure)
{
        cell p;

        assert(rope_p(o));
        if (maxdepth < 0 && detail == SERIAL_ROUND)
                siglongjmp(*failure, LERR_UNPRINTABLE);
        else if (maxdepth < 0) {
                if (detail)
                        serial_append(buffer, "...", 3, failure);
        } else {
                p = rope_prev(o, failure);
                if (null_p(p)) {
                        if (detail == SERIAL_DETAIL)
                                serial_append(buffer, "()", 2, failure);
                } else if (serial_deduplicate(p, detail, buffer, cycles, failure) == NULL)
                        serial_rope(p, detail, maxdepth - 1, buffer, cycles, failure);
                if (detail == SERIAL_DETAIL)
                        serial_append(buffer, " |", 2, failure);
                if (detail)
                        serial_escape(rope_buffer(o), rope_blength(o), buffer, failure);
                if (detail == SERIAL_DETAIL)
                        serial_append(buffer, "| ", 2, failure);
                p = rope_next(o, failure);
                if (null_p(p)) {
                        if (detail == SERIAL_DETAIL)
                                serial_append(buffer, "()", 2, failure);
                } else if (serial_deduplicate(p, detail, buffer, cycles, failure) == NULL)
                        serial_rope(p, detail, maxdepth - 1, buffer, cycles, failure);
        }
}

@ @<Serialise an object@>=
else if (primitive_p(o) && detail != SERIAL_ROUND) {
        if (detail) {
                serial_append(buffer, "#{primitive ", 13, failure);
                serial_append(buffer, Iprimitive[primitive(o)].schema,
                        (int) strlen (Iprimitive[primitive(o)].schema), failure);
                serial_append(buffer, "}", 1, failure);
        }
        append = "\0";
}

@ @<Serialise an object@>=
else if (environment_p(o) && detail != SERIAL_ROUND) {
        if (!maxdepth)
                append = "\015<ENVIRONMENT>";
        else {
                if (detail)
                        serial_append(buffer, "#{environment ", 14, failure);
#if 0
                serial_imp(env_layer(o), detail, maxdepth - 1, true, buffer,
                        cycles, failure);
                if (detail)
                        serial_append(buffer, " on ", 4, failure);
                serial_imp(env_previous(o), detail, maxdepth - 1, true, buffer,
                        cycles, failure);
#endif
                if (detail)
                        serial_append(buffer, "}", 1, failure);
                append = "\0";
        }
}

@ \.{table free/length (id . value)} (|id = hash % length|).

@<Serialise an object@>=
else if (hashtable_p(o) && detail != SERIAL_ROUND) {
        if (!maxdepth)
                append = "\014#{hash ...}";
        else {
                if (detail)
                        serial_append(buffer, "#{hash ", 8, failure);
                serial_imp(fix(hashtable_free(o)), SERIAL_ROUND, 1, true,
                        buffer, cycles, failure);
                if (detail)
                        serial_append(buffer, "/", 1, failure);
                serial_imp(fix(hashtable_length(o)), SERIAL_ROUND, 1, true,
                        buffer, cycles, failure);
                for (i = 0; i < hashtable_length(o); i++) {
                        if (!null_p(hashtable_ref(o, i))) {
                                if (detail)
                                        serial_append(buffer, " (", 2, failure);
                                serial_imp(fix(i), detail, maxdepth - 1, true,
                                        buffer, cycles, failure);
                                if (detail)
                                        serial_append(buffer, " . ", 3, failure);
                                serial_imp(hashtable_ref(o, i), detail, maxdepth - 1, true,
                                        buffer, cycles, failure);
                                if (detail)
                                        serial_append(buffer, ")", 1, failure);
                        }
                }
                if (detail)
                        serial_append(buffer, "}", 1, failure);
                append = "\0";
        }
}

@ @<Serialise an object@>=
else if (closure_p(o) && detail != SERIAL_ROUND) {
        if (!maxdepth)
                append = "\016#{closure ...}";
        else {
                if (detail) {
                        serial_append(buffer, "#{", 2, failure);
                        if (applicative_p(o))
                                serial_append(buffer, "applicative ", 12, failure);
                        else
                                serial_append(buffer, "operative ", 10, failure);
                }
                serial_imp(closure_formals(o), detail, maxdepth - 1, true,
                        buffer, cycles, failure);
                if (detail)
                        serial_append(buffer, " ", 1, failure);
                serial_imp(closure_body(o), detail, maxdepth - 1, true,
                        buffer, cycles, failure);
                if (detail)
                        serial_append(buffer, " in ", 4, failure);
                serial_imp(closure_environment(o), detail, maxdepth - 1, true,
                        buffer, cycles, failure);
                if (detail)
                        serial_append(buffer, "}", 1, failure);
                append = "\0";
        }
}

@ @<Serialise an object@>=
else if (dlist_p(o) && detail != SERIAL_ROUND) {
        if (!maxdepth||1)
                append = "\006<LIST>";
#if 0
        else {
                if (prefix) {
                        if (detail)
                                serial_append(buffer, "#{dlist ", 8, failure);
                        serial_imp(dlist_datum(o), detail, maxdepth - 1, true,
                                buffer, cycles, failure);
                        p = dlist_next(o);
                        while (p != o) {
                                if (detail)
                                        serial_append(buffer, " :: ", 4, failure);
                                serial_imp(p, detail, maxdepth, false,
                                        buffer, cycles, failure);
                                p = dlist_next(p);
                        }
                        if (detail)
                                serial_append(buffer, "}", 1, failure);
                } else
                        serial_imp(dlist_datum(o), detail, maxdepth - 1, true,
                                buffer, cycles, failure);
                append = "\0";
        }
#endif
}

@ @<Serialise an object@>=
else if (pending_p(o) && detail != SERIAL_ROUND) {
        if (!maxdepth)
                append = "\006<PENDING>";
        else {
                serial_imp(fix(pending_stage(o)), detail, maxdepth - 1, true, buffer, cycles,
                        failure);
                if (detail)
                        serial_append(buffer, "ª", (int) sizeof ("ª"), failure);
                serial_imp(pending_datum(o), detail, maxdepth - 1, true, buffer,
                        cycles, failure);
                if (detail)
                        serial_append(buffer, "º", (int) sizeof ("º"), failure);
                append = "\0";
        }
}

@ @<Serialise an object@>=
else if (provenance_p(o) && detail != SERIAL_ROUND) {
int x = detail;
detail = 0;
        if (!maxdepth)
                append = "\010<PROVE>";
        else {
                if (detail)
                        serial_append(buffer, "#{sx-", 5, failure);
                serial_imp(prove_datum(o), x, maxdepth - 1, true, buffer,
                        cycles, failure);
#if 0
                if (detail)
                        serial_append(buffer, " ", 1, failure);
                serial_imp(prove_start(o), detail, maxdepth - 1, true, buffer,
                        cycles, failure);
                if (detail)
                        serial_append(buffer, " ", 1, failure);
                serial_imp(prove_end(o), detail, maxdepth - 1, true, buffer,
                        cycles, failure);
#endif
                if (detail)
                        serial_append(buffer, "}", 1, failure);
                append = "\0";
        }
detail = x;
}

@ @<Serialise an object@>=
else if (lexeme_p(o) && detail != SERIAL_ROUND) {
        if (!maxdepth)
                append = "\015#{lexeme ...}";
        else {
                if (detail)
                        serial_append(buffer, "#{lexeme ", 9, failure);
                serial_imp(fix(lexeme(o)->cat), SERIAL_ROUND, 1, true,
                        buffer, cycles, failure);
                if (detail)
                        serial_append(buffer, " @@", 2, failure);
                serial_imp(fix(lexeme(o)->tboffset), SERIAL_ROUND, 1,
                        true, buffer, cycles, failure);
                if (detail)
                        serial_append(buffer, ":", 1, failure);
                serial_imp(fix(lexeme(o)->blength), SERIAL_ROUND, 1,
                        true, buffer, cycles, failure);
                if (detail)
                        serial_append(buffer, " of ", 4, failure);
                serial_imp(lexeme_twine(o), SERIAL_ROUND, maxdepth - 1,
                        true, buffer, cycles, failure);
                if (detail)
                        serial_append(buffer, "}", 1, failure);
                append = "\0";
        }
}

@** Miscellanea.

@<Fun...@>=
int high_bit (digit);

@ @c
int
high_bit (digit o)
{
        int i = CELL_BITS;

        while (--i)@+
                if (o & (1ull << i))
                        return i + 1;
        return o;
}

@ |CANNOT| is negative so that negative numbers mean mean no while
|CAN| is zero so that a test of zero is the most permisssive.

@<Type def...@>=
typedef enum {
        CANNOT = -1,
        CAN    = 0,
        MUST   = 1,
} Vmaybe;

@ @<Repair the system headers@>=
#ifdef __GNUC__ /* \AM\ clang */
#       define Lunused __attribute__ ((__unused__))
#else
#       define Lunused /* noisy compiler */
#endif

#ifdef __GNUC__ /* \AM clang */
#       define Lnoreturn __attribute__ ((__noreturn__))
#else
#       ifdef _Noreturn
#               define Lnoreturn _Noreturn
#       else
#               define Lnoreturn /* noisy compiler */
#       endif
#endif

#ifdef LDEBUG
#       define LDEBUG_P true
#else
#       define LDEBUG_P false
#endif

#if EOF == -1
#       define FAIL -2
#else
#       define FAIL -1
#endif

#define ckd_add(r,x,y) @[__builtin_add_overflow((x), (y), (r))@]
#define ckd_sub(r,x,y) @[__builtin_sub_overflow((x), (y), (r))@]
#define ckd_mul(r,x,y) @[__builtin_mul_overflow((x), (y), (r))@]

@** Junkyard.

@ Symbols.


@ Constants.

@<Extern...@>=
cell lapi_NIL (void);
cell lapi_FALSE (void);
cell lapi_TRUE (void);
cell lapi_VOID (void);
cell lapi_EOF (void);
cell lapi_UNDEFINED (void);

@ @(ffi.c@>=
cell lapi_NIL (void) { return NIL; }
cell lapi_FALSE (void) { return LFALSE; }
cell lapi_TRUE (void) { return LTRUE; }
cell lapi_VOID (void) { return VOID; }
cell lapi_EOF (void) { return LEOF; }
cell lapi_UNDEFINED (void) { return UNDEFINED; }

@ Accessors.

@<Extern...@>=
bool lapi_null_p (cell);
bool lapi_false_p (cell);
bool lapi_true_p (cell);
bool lapi_pair_p (cell);
bool lapi_symbol_p (cell);
@#
cell lapi_cons (bool, cell, cell, sigjmp_buf *);
cell lapi_car (cell, sigjmp_buf *);
cell lapi_cdr (cell, sigjmp_buf *);
void lapi_set_car_m (cell, cell, sigjmp_buf *);
void lapi_set_cdr_m (cell, cell, sigjmp_buf *);

@ @c
bool lapi_null_p (cell o) { return null_p(o); }
bool lapi_false_p (cell o) { return false_p(o); }
bool lapi_true_p (cell o) { return true_p(o); }
bool lapi_pair_p (cell o) { return pair_p(o); }
bool lapi_symbol_p (cell o) { return symbol_p(o); }

@ @c
cell
lapi_cons (bool        share,
           cell        ncar,
           cell        ncdr,
           sigjmp_buf *failure)
{
        if (!defined_p(ncar) || !defined_p(ncdr))
                siglongjmp(*failure, LERR_INCOMPATIBLE);
        return atom(share ? Sheap : Theap, ncar, ncdr, FORM_PAIR, failure);
}

cell
lapi_car (cell        o,
          sigjmp_buf *failure)
{
        if (!pair_p(o))
                siglongjmp(*failure, LERR_INCOMPATIBLE);
        return lcar(o);
}

cell
lapi_cdr (cell        o,
          sigjmp_buf *failure)
{
        if (!pair_p(o))
                siglongjmp(*failure, LERR_INCOMPATIBLE);
        return lcdr(o);
}

void
lapi_set_car_m (cell        o,
                cell        value,
                sigjmp_buf *failure)
{
        if (!pair_p(o) || !defined_p(value))
                siglongjmp(*failure, LERR_INCOMPATIBLE);
        lcar_set_m(o, value);
}

void
lapi_set_cdr_m (cell        o,
                cell        value,
                sigjmp_buf *failure)
{
        if (!pair_p(o) || !defined_p(value))
                siglongjmp(*failure, LERR_INCOMPATIBLE);
        lcdr_set_m(o, value);
}

@ @c
cell
lapi_env_search (cell        env,
                 cell        label,
                 sigjmp_buf *failure)
{
        cell r;

        if (null_p(env))
                env = Environment;
        if (!environment_p(env) || !symbol_p(label))
                siglongjmp(*failure, LERR_INCOMPATIBLE);
        r = env_search(env, label, failure);
        if (undefined_p(r))
                siglongjmp(*failure, LERR_MISSING);
        else
                return r;
}

void
lapi_env_define (cell        env,
                 cell        label,
                 cell        value,
                 sigjmp_buf *failure)
{
        if (null_p(env))
                env = Environment;
        if (!environment_p(env) || !symbol_p(label) || !defined_p(value))
                siglongjmp(*failure, LERR_INCOMPATIBLE);
        env_define_m(env, label, value, failure);
}

void
lapi_env_set (cell        env,
              cell        label,
              cell        value,
              sigjmp_buf *failure)
{
        if (null_p(env))
                env = Environment;
        if (!environment_p(env) || !symbol_p(label) || !defined_p(value))
                siglongjmp(*failure, LERR_INCOMPATIBLE);
        env_set_m(env, label, value, failure);
}

void
lapi_env_clear (cell        env,
                cell        label,
                sigjmp_buf *failure)
{
        if (null_p(env))
                env = Environment;
        if (!environment_p(env) || !symbol_p(label))
                siglongjmp(*failure, LERR_INCOMPATIBLE);
        env_clear_m(env, label, failure);
}

void
lapi_env_unset (cell        env,
                cell        label,
                sigjmp_buf *failure)
{
        if (null_p(env))
                env = Environment;
        if (!environment_p(env) || !symbol_p(label))
                siglongjmp(*failure, LERR_INCOMPATIBLE);
        env_unset_m(env, label, failure);
}

@ @<Fun...@>=
cell lapi_Accumulator (cell);
cell lapi_User_Register (cell);
cell lapi_Debug_Register (cell);

@ @c
cell
lapi_Accumulator (cell new)
{
        if (defined_p(new))
                Accumulator = new;
        return Accumulator;
}
cell
lapi_User_Register (cell new)
{
        if (defined_p(new))
                User_Register = new;
        return User_Register;
}
cell
lapi_Debug_Register (cell new)
{
        if (defined_p(new))
                Debug_Register = new;
        return Debug_Register;
}

@* TODO.

@ @c
int
lprint (char *format,
        ...)
{
        va_list args;
        int r;

        assert(LDEBUG_P);
        va_start(args, format);
        r = vfprintf(stdout, format, args);
        va_end(args);
        return r;
}

@ @c
int
lput (int c)
{
        assert(LDEBUG_P);
        return putchar(c);
}

@ @<Fun...@>=
int lprint (char *, ...);
int lput (int);

@ @d WARN() fprintf(stderr, "WARNING: You probably don't want to do that.\n");

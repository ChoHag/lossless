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
\def\Ls/{\.{Lossless}}
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
\def\yitem#1{\yskip\item{#1}}
\def\yhang{\yskip\hang}
\def\dot{\vrule width4pt height5pt depth-1pt}

% Ignore this bit as well which fixes CWEB's knowledge of C types.
% Sometimes typedefs work and sometimes they don't. I'll worry about
% that when I'm done.

@s int8_t int
@s int16_t int
@s int32_t int
@s intmax_t int
@s intptr_t int
@s uint16_t int
@s uint32_t int
@s uint_fast32_t int
@s uint64_t int
@s uintptr_t int
@s uintmax_t int
%
@s pthread_t int
@s pthread_attr_t int
@s pthread_barrier_t int
@s pthread_mutex_t int
@s pthread_mutexattr_t int
%
@s line normal
@s new normal
@s orabort normal
@s orassert normal
@s orreturn return
@s ortrap return
@s shared static
@s unique static
@s unused static
%
@s address int
@s assembly_complete int
@s assembly_working int
@s atom int
@s cell int
@s cell_tag int
@s code_page int
@s digit int
@s error_code int
@s half int
@s hash_fn int
@s heap int
@s heap_access int
@s heap_alloc_fn int
@s heap_enlarge_fn int
@s heap_init_fn int
@s heap_pun int
@s instruction int
@s match_fn int
@s opcode int
@s scow int
@s segment int
@s symbol int
@s vm_register int
@s word int
%
@s llt_allocation int
@s llt_forward int
@s llt_header int
@s llt_initialise int
@s llt_thunk int

@** Preface.

Blurb.

@** Implementation. Library and executable, sharing \.{lossless.h}.

@(lossless.h@>=
#ifndef LL_LOSSLESS_H
#define LL_LOSSLESS_H
@<System headers@>@;
@h
@<Essential types@>@;
@<Type definitions@>@;
@<Function declarations@>@;
@<External \CEE/ symbols@>@;
#endif

@ @<System headers@>=
#include <err.h>
#include <errno.h>
#include <limits.h>
#include <pthread.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <unistd.h>
@<Portability hacks@>@; /* These are listed at the end. */

@ This becomes \.{lossless.c} with all the other unnamed sections.
More headers are needed.

@c
#include "lossless.h"
#include <assert.h>
#ifdef LDEBUG
#include <stdio.h>
#endif
#include <ctype.h>
#include <string.h>
@<Global variables@>@;

@* Errors. Most functions return one of these values. Most receivers
of them will then want to immediately abort if it indicates a
failure.

@d failure_p(O) ((O) != LERR_NONE)
@d just_abort(E,M) err((E), "%s: %u", (M), (E))
@d do_or_abort(R,I) do@+ {@+ if (failure_p(((R) = (I))))
        just_abort((R), #I);@+ }@+ while (0)
@d do_or_return(R,I) do@+{@+ if (failure_p((R) = (I))) return (R);@+ }@+ while (0)
@d do_or_trap(R,I) do@+{@+ if (failure_p((R) = (I))) goto Trap;@+ }@+ while (0)
@d orabort(I) do_or_abort(reason, I)
@d orreturn(I) do_or_return(reason, I)
@d ortrap(I) do_or_trap(reason, I)
@#
@d do_or_assert(R,I) do@+ {@+ if (failure_p(((R) = (I))))
        assert(#I && !failure_p(R));@+ }@+ while (0)
@d orassert(I) do@+ {@+ if (failure_p((reason = (I))))
        assert(#I && !failure_p(reason));@+ }@+ while (0)
@<Type def...@>=
typedef enum {
        LERR_NONE,@/
        LERR_ADDRESS,        /* An invalid value is used as an address. */
        LERR_AMBIGUOUS,      /* An expression's ending is unclear. */
        LERR_BUSY,           /* A resource is busy. */
        LERR_DOUBLE_TAIL,    /* Two \.. elements in a list. */
        LERR_EMPTY_TAIL,     /* A \.. without a tail expression. */
        LERR_EOF,            /* End of file or stream. */
        LERR_EXISTS,         /* New binding conflicts. */
        LERR_FINISHED,       /* A thread or process is already finished. */
        LERR_HEAVY_TAIL,     /* A \.. with more than one tail expression. */
        LERR_IMMUTABLE,      /* Attempt to mutate a read-only object. */
        LERR_IMPROPER,       /* An improper list was encountered. */
        LERR_INCOMPATIBLE,   /* Operation on an incompatible operand. */
        LERR_INSTRUCTION,    /* Attempted to interpret an invalid instruction. */
        LERR_INTERNAL,       /* Bug in \Ls/. */
        LERR_INTERRUPT,      /* An operation was interrupted. */
        LERR_IO,             /* ``An'' I/O error. */
        LERR_LEAK,           /* System resource (eg. file handle) lost. */
        LERR_LIMIT,          /* A software-defined limit has been reached. */
        LERR_LISTLESS_TAIL,  /* List tail-syntax (\..) not in a list. */
        LERR_MISMATCH,       /* Closing bracket did not match open bracket. */
        LERR_MISSING,        /* A hash table or environment lookup failed. */
        LERR_NONCHARACTER,   /* Scanning UTF-8 encoding failed. */
        LERR_OOM,            /* Out of memory. */
        LERR_OUT_OF_BOUNDS,  /* Bounds exceeded. */
        LERR_OVERFLOW,       /* Attempt to access past the end of a buffer. */
        LERR_SELF,           /* An attempt to wait for one's self. */
        LERR_SYNTAX,         /* Unrecognisable syntax (insufficient alone). */
        LERR_SYSTEM,         /* A system error, check |errno|. */
        LERR_THREAD,         /* Failed to correctly join a thread. */
        LERR_UNCLOSED_OPEN,  /* Missing \.), \.] or \.\}. */
        LERR_UNCOMBINABLE,   /* Attempted to combine a non-program. */
        LERR_UNDERFLOW,      /* A stack was popped too far. */
        LERR_UNLOCKED,       /* Attempt to use an unlocked critical resource. */
        LERR_UNIMPLEMENTED,  /* A feature is not implemented. */
        LERR_UNOPENED_CLOSE, /* Premature \.), \.] or \.\}, or \.{(close!)}. */
        LERR_UNPRINTABLE,    /* Failed serialisation attempt. */
        LERR_UNSCANNABLE,    /* Parser encountered |LEXICAT_INVALID|. */
        LERR_USER,           /* A user-defined error. */
        LERR_LENGTH
} error_code;

typedef struct {
        cell  owner;
        char *label;
} error_table;

@ @<Global...@>=
shared error_table Error[LERR_LENGTH] = {@|
        [LERR_FINISHED]       = { NIL, "already-finished" },@|
        [LERR_AMBIGUOUS]      = { NIL, "ambiguous-syntax" },@|
        [LERR_THREAD]         = { NIL, "bad-join" },@|
        [LERR_EXISTS]         = { NIL, "conflicted-binding" },@|
        [LERR_DOUBLE_TAIL]    = { NIL, "double-tail" },@|
        [LERR_EOF]            = { NIL, "end-of-file" },@|
        [LERR_IMMUTABLE]      = { NIL, "immutable" },@|
        [LERR_IMPROPER]       = { NIL, "improper-list" },@|
        [LERR_ADDRESS]        = { NIL, "invalid-address" },@|
        [LERR_INSTRUCTION]    = { NIL, "invalid-instruction" },@|
        [LERR_INCOMPATIBLE]   = { NIL, "incompatible-operand" },@|
        [LERR_INTERRUPT]      = { NIL, "interrupted" },@|
        [LERR_IO]             = { NIL, "io" },@| /* The least helpful error report. */
        [LERR_INTERNAL]       = { NIL, "lossless-error" },@|
        [LERR_MISMATCH]       = { NIL, "mismatched-brackets" },@|
        [LERR_MISSING]        = { NIL, "missing" },@|
        [LERR_NONCHARACTER]   = { NIL, "noncharacter" },@|
        [LERR_NONE]           = { NIL, "no-error" },@|
        [LERR_LISTLESS_TAIL]  = { NIL, "non-list-tail" },@|
        [LERR_OUT_OF_BOUNDS]  = { NIL, "out-of-bounds" },@|
        [LERR_OOM]            = { NIL, "out-of-memory" },@|
        [LERR_OVERFLOW]       = { NIL, "overflow" },@|
        [LERR_USER]           = { NIL, "pebkac" },@| /* (user error) */
        [LERR_BUSY]           = { NIL, "resource-busy" },@|
        [LERR_LEAK]           = { NIL, "resource-leak" },@|
        [LERR_LIMIT]          = { NIL, "software-limit" },@|
        [LERR_SYNTAX]         = { NIL, "syntax-error" },@|
        [LERR_SYSTEM]         = { NIL, "system-error" },@|
        [LERR_HEAVY_TAIL]     = { NIL, "tail-mid-list" },@|
        [LERR_UNCLOSED_OPEN]  = { NIL, "unclosed-brackets" },@|
        [LERR_UNCOMBINABLE]   = { NIL, "uncombinable" },@|
        [LERR_UNDERFLOW]      = { NIL, "underflow" },@|
        [LERR_UNIMPLEMENTED]  = { NIL, "unimplemented" },@|
        [LERR_UNLOCKED]       = { NIL, "unlocked-resourcd" },@|
        [LERR_UNOPENED_CLOSE] = { NIL, "unopened-brackets" },@|
        [LERR_UNPRINTABLE]    = { NIL, "unprintable" },@|
        [LERR_UNSCANNABLE]    = { NIL, "unscannable-lexeme" },@|
        [LERR_EMPTY_TAIL]     = { NIL, "unterminated-tail" },@|
        [LERR_SELF]           = { NIL, "wait-for-self" },@/
};

@ @<Extern...@>=
shared extern error_table Error[];

@
@d error_id(O)     (lsin(O))
@d error_label(O)  (ldex(O))
@d error_object(O) (&Error[error_id(O)])
@<Fun...@>=
error_code error_search (cell, cell *);

@ @<Finish init...@>=
for (i = 0; i < LERR_LENGTH; i++) {
        orabort(new_symbol_const(Error[i].label, &ltmp));
        orabort(new_atom(i, ltmp, FORM_ERROR, &Error[i].owner));
}

@ @<Populate the |Root| environment@>=
for (i = 0; i < LERR_LENGTH; i++)
        orreturn(env_save_m(Root, error_label(Error[i].owner), Error[i].owner, false));

@ This same symbol lookup method is use later on.

@d global_search(O,P,R) {
        cell rval;
        error_code reason;

        orreturn(env_search(Root, (O), &rval));
        if (!P(rval))
                return LERR_INCOMPATIBLE;
        *(R) = rval;
        return LERR_NONE;
}
@<Type def...@>=
typedef error_code @[@] (*search_fn) (cell, cell *);

@ @c
error_code
error_search (cell  o,
              cell *ret)
{
        global_search(o, error_p, ret)@;
}

@** Memory. The lowest-level memory routines are wrappers around
malloc which check for failure.

@d SYSTEM_PAGE_LENGTH sysconf(_SC_PAGESIZE)
@<Global...@>=
char *malloc_options = "S";
shared bool Memory_Ready = false;
shared bool Lossless_Ready = false;
unique bool Thread_Ready = false;

@ @<Extern...@>=
extern shared bool Memory_Ready, Lossless_Ready;
extern unique bool Thread_Ready;

@ @<Fun...@>=
error_code mem_init (void);
error_code mem_init_thread (void);
error_code mem_alloc (void *, size_t, size_t, void **);
error_code mem_free (void *);

@ @c
error_code
mem_init (void)
{
        cell ltmp;
        segment *stmp;
        int i;
        error_code reason;

        @<Initialise memory allocator@>@;
        @<Initialise heap \AM\ symbol table@>@;
        Memory_Ready = true;
        orreturn(mem_init_thread());
        @<Finish initialisation after memory is ready@>@;
        Lossless_Ready = true;
        return LERR_NONE;
}

@ @c
error_code
mem_init_thread (void)
{
        @<(Re-)Initialise per thread@>@;
        Thread_Ready = true;
        return LERR_NONE;
}

@ @c
error_code
mem_alloc (void    *old,
           size_t   length,
           size_t   align,
           void   **ret)
{
        void *r;@;

#ifdef LLTEST
        @<Testing memory allocator@>@;
#endif
        if (!align)
                r = realloc(old, length);
        else {
                assert(old == NULL);
                if (length % align)
                        return LERR_INCOMPATIBLE;
                r = aligned_alloc(align, length);
        }
        if (r == NULL)
                switch (errno) {
                        case EINVAL:
                                return LERR_INCOMPATIBLE; /* |align !=| $n^2$ */
                        case ENOMEM:
                                return LERR_OOM;
                        default:
                                return LERR_INTERNAL;
                }
        *ret = r;
        return LERR_NONE;
}

@ @c
error_code
mem_free (void *o)
{
#ifdef LLTEST
        @<Testing memory deallocator@>@;
#endif
        free(o);
        return LERR_NONE;
}

@* Portability.

@d TAG_BITS     8
@d TAG_BYTES    1
@#
@d DIGIT_MAX    UINTPTR_MAX
@d INTERN_BYTES (ATOM_BYTES - 1)
@d FIXED_MIN    (asr(INTPTR_MIN, 4))
@d FIXED_MAX    (asr(INTPTR_MAX, 4))
@d FIXED_SHIFT  4
@<Essential...@>=
typedef int8_t byte;
typedef intptr_t cell;
typedef uintptr_t digit;
@#
#if UINTPTR_MAX >= 0xfffffffffffffffful
@<Define a 64-bit addressing environment@>@;
#elif UINTPTR_MAX >= 0xfffffffful
@<Define a 32-bit addressing environment@>@;
#elif UINTPTR_MAX >= 0xfffful
@<Define a 16-bit addressing environment@>@;
#else
#error@, Tiny computer@&.
#endif

@ @<Define a 64-bit addressing environment@>=
#define CELL_BITS  64 /* Total size of a cell. */
#define CELL_BYTES 8
#define CELL_SHIFT 4 /* How many low bits of a pointer are zero. */
#define ATOM_BITS  128 /* Total size of an atom. */
#define ATOM_BYTES 16
#define HALF_MIN   INT32_MIN
#define HALF_MAX   INT32_MAX
typedef int32_t half; /* Records the size of memory objects. */

@ @<Define a 32-bit addressing environment@>=
#define CELL_BITS  32
#define CELL_BYTES 4
#define CELL_SHIFT 3
#define ATOM_BITS  64
#define ATOM_BYTES 8
#define HALF_MIN   INT16_MIN
#define HALF_MAX   INT16_MAX
typedef int16_t half;

@ @<Define a 16-bit addressing environment@>=
#define CELL_BITS  16
#define CELL_BYTES 2
#define CELL_SHIFT 2
#define ATOM_BITS  32
#define ATOM_BYTES 4
#define HALF_MIN   INT8_MIN
#define HALF_MAX   INT8_MAX
typedef int8_t half;

@* Atoms.

@d NIL            ((cell)  0) /* Nothing, the empty list, \.{()}. */
@d LFALSE         ((cell)  1) /* Boolean false, \.{\#f} or \.{\#F}. */
@d LTRUE          ((cell)  3) /* Boolean true, \.{\#t} or \.{\#T}. */
@d VOID           ((cell)  5) /* Even less than nothing --- the ``no
                                        explicit value'' value. */
@d LEOF           ((cell)  7) /* Value obtained off the end of a file or
                                        other stream. */
@d INVALID0       ((cell)  9)
@d INVALID1       ((cell) 11)
@d UNDEFINED      ((cell) 13) /* The value of a variable that isn't there. */
@d FIXED          ((cell) 15) /* A small fixed-width integer. */
@#
@d null_p(O)      ((intptr_t) (O) == NIL) /* May {\it not\/} be |NULL|. */
@d special_p(O)   (null_p(O) || ((intptr_t) (O)) & 1)
@d boolean_p(O)   ((O) == LFALSE || (O) == LTRUE)
@d false_p(O)     ((O) == LFALSE)
@d true_p(O)      ((O) == LTRUE)
@d void_p(O)      ((O) == VOID)
@d eof_p(O)       ((O) == LEOF)
@d undefined_p(O) ((O) == UNDEFINED)
@d fixed_p(O)     (((O) & FIXED) == FIXED) /* Mask out the value bits. */
@d defined_p(O)   (!undefined_p(O))
@d valid_p(O)     (fixed_p(O)
        || ((((O) & FIXED) == (O)) && (O) != INVALID0 && (O) != INVALID1))
@#
@d predicate(O)   ((O) ? LTRUE : LFALSE)

@ 2 bits for the GC, 2 bits shared with GC \AM\ format, lower 4 for
format only.

@d LTAG_LIVE 0x80 /* Atom is referenced from a register. */
@d LTAG_TODO 0x40 /* Atom has been partially scanned. */
@d LTAG_PSIN 0x20 /* Atom's sin half points to an atom. */
@d LTAG_PDEX 0x10 /* Atom's dex half points to an atom. */
@d LTAG_BOTH (LTAG_PSIN | LTAG_PDEX)
@d LTAG_FORM (LTAG_BOTH | 0x0f)
@d LTAG_NONE 0x00
@#
@d TAG(O)         (ATOM_TO_TAG((O)))
@d TAG_SET_M(O,V) (ATOM_TO_TAG((O)) = (V))
@#
@d ATOM_LIVE_P(O)           (TAG(O) & LTAG_LIVE)
@d ATOM_CLEAR_LIVE_M(O)     (TAG_SET_M((O), TAG(O) & ~LTAG_LIVE))
@d ATOM_SET_LIVE_M(O)       (TAG_SET_M((O), TAG(O) | LTAG_LIVE))
@d ATOM_MORE_P(O)           (TAG(O) & LTAG_TODO)
@d ATOM_CLEAR_MORE_M(O)     (TAG_SET_M((O), TAG(O) & ~LTAG_TODO))
@d ATOM_SET_MORE_M(O)       (TAG_SET_M((O), TAG(O) | LTAG_TODO))
@d ATOM_FORM(O)             (TAG(O) & LTAG_FORM)
@d ATOM_SIN_DATUM_P(O)      (TAG(O) & LTAG_PSIN)
@d ATOM_DEX_DATUM_P(O)      (TAG(O) & LTAG_PDEX)
@<Type def...@>=
typedef uint8_t cell_tag;
typedef union {
        struct {
                cell sin, dex;
        };
        struct {
                void *yin, *yang;
        };
        struct {
                digit value;
                cell  tail;
        };
        struct {
                int8_t length; /* Only 4 bits needed */
                byte   buffer[INTERN_BYTES];
        };
} atom;

@
@d FORM_NONE           (LTAG_NONE | 0x00)
@d FORM_ARRAY          (LTAG_NONE | 0x01) /* Structured Data/Arrays. */
@d FORM_ASSEMBLY       (LTAG_NONE | 0x02)
@d FORM_COLLECTED      (LTAG_NONE | 0x03) /* Memory/Garbage Collection. */
@d FORM_HASHTABLE      (LTAG_NONE | 0x04) /* Structural Data/Symbols \AM\ Tables. */
@d FORM_HEAP           (LTAG_NONE | 0x05) /* Memory/Heap. */
@d FORM_RUNE           (LTAG_NONE | 0x06) /* Valuable Data/Characters (Runes). */
@d FORM_SEGMENT_INTERN (LTAG_NONE | 0x07) /* Memory/Segments. */
@d FORM_SYMBOL         (LTAG_NONE | 0x08) /* Structural Data/Symbols \AM\ Tables. */
@d FORM_SYMBOL_INTERN  (LTAG_NONE | 0x09) /* Structural Data/Symbols \AM\ Tables. */
@d FORM_WORD           (LTAG_NONE | 0x0a)
@#
@d FORM_CSTRUCT        (LTAG_PDEX | 0x00)
@d FORM_CONTINUATION   (LTAG_PDEX | 0x01) /* Compute. */
@d FORM_ERROR          (LTAG_PDEX | 0x02)
@d FORM_FILE_HANDLE    (LTAG_PDEX | 0x03)
@d FORM_LEXEME         (LTAG_PDEX | 0x04)
@d FORM_NEGATIVE       (LTAG_PDEX | 0x05) /* Negative integer (head only). */
@d FORM_OPCODE         (LTAG_PDEX | 0x06)
@d FORM_PENDING        (LTAG_PDEX | 0x07) /* Operational Data/Pending Computation. */
@d FORM_POSITIVE       (LTAG_PDEX | 0x08) /* Positive integer and/or digit. */
@d FORM_PRIMITIVE      (LTAG_PDEX | 0x09) /* Compute. */
@d FORM_PROGRAM        (LTAG_PDEX | 0x0a)
@d FORM_REGISTER       (LTAG_PDEX | 0x0b)
@d FORM_SEGMENT        (LTAG_PDEX | 0x0c) /* Memory/Segments. */
@#
@d FORM_PAIR           (LTAG_BOTH | 0x00) /* Memory/Atoms. */
@d FORM_APPLICATIVE    (LTAG_BOTH | 0x01) /* Operational Data/Programs (Closures). */
@d FORM_ENVIRONMENT    (LTAG_BOTH | 0x02) /* Operational Data/Environments. */
@d FORM_OPERATIVE      (LTAG_BOTH | 0x03) /* Operational Data/Programs (Closures). */
@d FORM_STATEMENT      (LTAG_BOTH | 0x04)

@
@d form(O)             (TAG(O) & LTAG_FORM)
@d form_p(O,F)         (!special_p(O) && form(O) == FORM_##F)
@d pair_p(O)           (form_p((O), PAIR))
@d array_p(O)          (form_p((O), ARRAY))
@d assembly_p(O)       (form_p((O), ASSEMBLY))
@d collected_p(O)      (form_p((O), COLLECTED))
@d continuation_p(O)   (form_p((O), CONTINUATION))
@d environment_p(O)    (form_p((O), ENVIRONMENT))
@d error_p(O)          (form_p((O), ERROR))
@d file_handle_p(O)    (form_p((O), FILE_HANDLE))
@d hashtable_p(O)      (form_p((O), HASHTABLE))
@d heap_p(O)           (form_p((O), HEAP))
@d lexeme_p(O)         (form_p((O), LEXEME))
@d opcode_p(O)         (form_p((O), OPCODE))
@d pending_p(O)        (form_p((O), PENDING))
@d register_p(O)       (form_p((O), REGISTER))
@d rune_p(O)           (form_p((O), RUNE))
@d statement_p(O)      (form_p((O), STATEMENT))
@d word_p(O)           (form_p((O), WORD))
@#
@d cstruct_p(O)        (form_p((O), CSTRUCT))
@d segment_intern_p(O) (form_p((O), SEGMENT_INTERN))
@d segment_stored_p(O) (form_p((O), SEGMENT))
@d segment_p(O)        (segment_intern_p(O) || segment_stored_p(O))
@d symbol_intern_p(O)  (form_p((O), SYMBOL_INTERN))
@d symbol_stored_p(O)  (form_p((O), SYMBOL))
@d symbol_p(O)         (symbol_intern_p(O) || symbol_stored_p(O))
@#
@d negative_p(O)       (form_p((O), NEGATIVE))
@d positive_p(O)       (form_p((O), POSITIVE))
@d digit_p(O)          (positive_p(O) || negative_p(O))
@d integer_p(O)        (fixed_p(O) || positive_p(O) || negative_p(O))
@#
@d larry_p(O)          (array_p(O) || hashtable_p(O) || assembly_p(O)
        || statement_p(O))
@d pointer_p(O)        (segment_stored_p(O) || symbol_stored_p(O)
        || larry_p(O) || heap_p(O))
@#
@d primitive_p(O)      (form_p((O), PRIMITIVE))
@d closure_p(O)        (form_p((O), APPLICATIVE) || form_p((O), OPERATIVE))
@d program_p(O)        (closure_p(O) || primitive_p(O) || continuation_p(O))
@d applicative_p(O)    (form_p((O), APPLICATIVE) || primitive_applicative_p(O))
@d operative_p(O)      (form_p((O), OPERATIVE) || primitive_operative_p(O))

@* Heap.

@d HEAP_CHUNK         (SYSTEM_PAGE_LENGTH) /* Size of a heap page. */
@d HEAP_MASK          (HEAP_CHUNK - 1) /* Bits which will always be 0. */
@d HEAP_BOOKEND       /* Heap header size. */
        (sizeof (segment) + sizeof (heap))
@d HEAP_LEFTOVER      /* Heap data size. */
        ((HEAP_CHUNK - HEAP_BOOKEND) / (TAG_BYTES + ATOM_BYTES))
@d HEAP_LENGTH        ((int) HEAP_LEFTOVER) /* Heap data size in bytes. */
@d HEAP_HEADER        /* Heap header size in bytes. */
        ((HEAP_CHUNK / ATOM_BYTES) - HEAP_LENGTH)
@#
@d ATOM_TO_ATOM(O)    ((atom *) (O))
@d ATOM_TO_HEAP(O)    /* The |heap| containing an atom. */
        (SEGMENT_TO_HEAP(ATOM_TO_SEGMENT(O)))
@d ATOM_TO_INDEX(O)   /* The offset of an atom within a heap. */
        (((((intptr_t) (O)) & HEAP_MASK) >> CELL_SHIFT) - HEAP_HEADER)
@d ATOM_TO_SEGMENT(O) /* The |segment| containing an atom. */
        ((segment *) (((intptr_t) (O)) & ~HEAP_MASK))
@d HEAP_TO_SEGMENT(O) (ATOM_TO_SEGMENT(O)) /* The segment containing a heap. */
@d SEGMENT_TO_HEAP(O) ((heap *) (O)->base) /* The heap within a segment. */
@d HEAP_TO_LAST(O)    /* The atom {\it after\/} the last valid |atom|
                        within a heap. */
        ((atom *) (((intptr_t) HEAP_TO_SEGMENT(O)) + HEAP_CHUNK))
@#
@d ATOM_TO_TAG(O)     (ATOM_TO_HEAP(O)->tag[ATOM_TO_INDEX(O)])
@<Type def...@>=
struct heap {
        atom     *free; /* Next unallocated atom. */
 struct heap     *next, *other; /* More heap. */
 struct heap_pun *root;
        cell_tag  tag[]; /* Atoms' tags. */
};
typedef struct heap heap;

struct heap_pun {
        atom        *free;
 struct heap        *next, *other;
 struct heap_access *fun;
        cell_tag     tag[];
};
typedef struct heap_pun heap_pun;

typedef error_code (*heap_init_fn)(heap *, heap *, heap *, heap *);
typedef error_code (*heap_enlarge_fn)(heap *, heap **);
typedef bool (*heap_enlarge_p_fn)(heap_pun *, heap *);
typedef error_code (*heap_alloc_fn)(heap *, cell *);

struct heap_access { /* TODO: This can be a thread local variable. */
        void              *free; /* Named free to look like a |heap| object. */
        heap_init_fn       init;
        heap_enlarge_fn    enlarge;
        heap_enlarge_p_fn  enlarge_p;
        heap_alloc_fn      alloc;
};
typedef struct heap_access heap_access;

@ @d HEAP_PUN_FLAG -1
@d shared
@d unique __thread
@d heap_root_p(O) ((O)->root->free == (void *) HEAP_PUN_FLAG)
@d heap_root(O) (heap_root_p(O) ? (heap_pun *) (O) : (O)->root)
@<Global...@>=
shared heap *Heap_Shared = NULL; /* Process-wide shared heap. */
unique heap *Heap_Thread = NULL; /* Per-thread private heap. */
unique heap *Heap_Trap = NULL; /* Per-thread heap for trap handler. */

@ @<Extern...@>=
extern shared heap *Heap_Shared;
extern unique heap *Heap_Thread, *Heap_Trap;

@ @<Fun...@>=
error_code heap_init_sweeping (heap *, heap *, heap *, heap *);
error_code heap_init_compacting (heap *, heap *, heap *, heap *);
bool heap_enlarge_p (heap_pun *, heap *);
error_code heap_enlarge (heap *, heap **);
error_code heap_alloc (heap *, cell *);
bool heap_mine_p (heap *);
bool heap_shared_p (heap *);
bool heap_trapped_p (heap *);
bool heap_other_p (heap *);
@#
error_code new_atom_imp (heap *, cell, cell, cell_tag, cell *);
cell lsin (cell);
error_code lsinx (cell, cell *);
cell ldex (cell);
error_code ldexx (cell, cell *);
cell_tag ltag (cell);
error_code lsin_set_m (cell, cell);
error_code ldex_set_m (cell, cell);

@ nb.~|heap->root| is |heap_pun->fun|.

@<Initialise heap...@>=
orabort(alloc_segment(-HEAP_CHUNK, 1, HEAP_CHUNK, &stmp));
Heap_Thread = SEGMENT_TO_HEAP(stmp);
orabort(heap_init_sweeping(Heap_Thread, NULL, NULL, NULL));
orabort(mem_alloc(NULL, sizeof (heap_access), sizeof (void *),
        (void **) &((heap_pun *) Heap_Thread)->fun)); /* This is nasty... */
((heap_pun *) Heap_Thread)->fun->free = (void *) HEAP_PUN_FLAG;
((heap_pun *) Heap_Thread)->fun->init = heap_init_sweeping;
((heap_pun *) Heap_Thread)->fun->enlarge = heap_enlarge;
((heap_pun *) Heap_Thread)->fun->enlarge_p = heap_enlarge_p;
((heap_pun *) Heap_Thread)->fun->alloc = heap_alloc;
orabort(new_atom(NIL, NIL, FORM_HEAP, &ltmp));
orabort(segment_init(HEAP_TO_SEGMENT(Heap_Thread), ltmp));
Heap_Shared = Heap_Trap = NULL;

@ @c
bool
heap_mine_p (heap *o)
{
        return (heap *) heap_root(o) == Heap_Thread;
}

@ @c
bool
heap_shared_p (heap *o)
{
        return (heap *) heap_root(o) == Heap_Shared;
}

@ @c
bool
heap_trapped_p (heap *o)
{
        return (heap *) heap_root(o) == Heap_Trap;
}

@ @c
bool
heap_other_p (heap *o)
{
        return (heap *) heap_root(o) != Heap_Thread
                && (heap *) heap_root(o) != Heap_Shared;
}

@ @d initialise_atom(H,F) do {
        (H)->free--; /* Move to the previous atom. */
        ATOM_TO_TAG((H)->free) = FORM_NONE; /* Free the atom. */
        (H)->free->sin = NIL; /* Clean the atom of sin. */
        if (F)
                (H)->free->dex = (cell) ((H)->free + 1); /* Link the atom
                                                        to the free list. */
        else
                (H)->free->dex = NIL; /* Clean the rest of the atom. */
} while (0)
@c
error_code
heap_init_sweeping (heap *new,
                    heap *prev,
                    heap *other,
                    heap *root)
{
        int i;

        assert(prev == NULL || heap_mine_p(prev) || heap_shared_p(prev));
        assert(other == NULL);
        assert(root == NULL || heap_mine_p((heap *) root)
                || heap_shared_p((heap *) root));
        new->free = HEAP_TO_LAST(new); /* |HEAP_TO_LAST| returns a pointer
                                                {\it after\/} the last atom. */
        initialise_atom(new, false); /* The last atom in the free list
                                        points to |NIL|. */
        for (i = 1; i < HEAP_LENGTH; i++) /* The remaining atoms are linked
                                                together. */
                initialise_atom(new, true);
@#
        new->root = (heap_pun *) root;
        new->other = other;
        if (prev == NULL)
                new->next = NULL;
        else {
                new->next = prev->next;
                prev->next = new;
        }
        return LERR_NONE;
}

@ TODO: This remains untested.

@.TODO@>
@c
error_code
heap_init_compacting (heap *new,
                      heap *prev,
                      heap *other,
                      heap *root)
{
        int i;

        assert(prev == NULL || heap_mine_p(prev) || heap_shared_p(prev));
        assert(other != NULL);
        assert(root == NULL || heap_mine_p(root) || heap_shared_p(root));
        new->free = HEAP_TO_LAST(new);
        other->free = HEAP_TO_LAST(other);
        for (i = 0; i < HEAP_LENGTH; i++) {
                initialise_atom(new, false);
                initialise_atom(other, false);
        }
@#
        new->root = (heap_pun *) root;
        new->other = other;@+
        other->other = new; /* Link each page to its twin. */
        if (prev == NULL)
                new->next = other->next = NULL;
        else {
                if ((new->next = prev->next) != NULL) {
                        assert(new->next->other->next == prev->other);
                        new->next->other->next = new->other;
                }
                other->next = prev->other;
                prev->next = new;
        }
        return LERR_NONE;
}

@ @c
bool
heap_enlarge_p (heap_pun *root @[unused@],
                heap     *at @[unused@])
{
        return true;
}

@ @c
error_code
heap_enlarge (heap  *old,
              heap **ret)
{
        heap *new, *other;
        heap_pun *root;
        segment *snew, *sother;
        cell tmp;
        error_code reason;

        assert(heap_mine_p(old) || heap_shared_p(old));
        root = heap_root(old);
        if (old->other == NULL) {
                orreturn(alloc_segment(-HEAP_CHUNK, 1, HEAP_CHUNK, &snew));
                new = SEGMENT_TO_HEAP(snew);
                orreturn(root->fun->init(new, old, NULL, (heap *) root));
                orreturn(root->fun->alloc(new, &tmp));
                orreturn(segment_init(snew, tmp));
        } else {
                orreturn(alloc_segment(-HEAP_CHUNK, 1, HEAP_CHUNK, &snew));
                orreturn(alloc_segment(-HEAP_CHUNK, 1, HEAP_CHUNK, &sother));
                new = SEGMENT_TO_HEAP(snew);
                other = SEGMENT_TO_HEAP(sother);
                orreturn(root->fun->init(new, old, other, (heap *) root));
@#
                orreturn(root->fun->alloc(new, &tmp));
                orreturn(segment_init(snew, tmp));
                orreturn(root->fun->alloc(new, &tmp));
                orreturn(segment_init(sother, tmp));
        }
        *ret = new;
        return LERR_NONE;
}

@ @c
error_code
heap_alloc (heap *where,
            cell *ret)
{
        bool tried;
        heap *h, *next;
        error_code reason;

        assert(heap_mine_p(where) || heap_shared_p(where));
        tried = false;
again:
        if (where->other == NULL) {
                @<Find an atom in a sweeping heap@>
        } else {
                @<Find an atom in a compacting heap@>
        }
        if (tried || !heap_root(where)->fun->enlarge_p(heap_root(where), h))
                return LERR_OOM;
        orreturn(heap_root(where)->fun->enlarge(h, &where));
        tried = true;
        goto again;
}

@ @<Find an atom in a sweeping heap@>=
next = where;
while (next != NULL) {
        h = next;
        if (!null_p(h->free)) {
                *ret = (cell) h->free;
                h->free = (atom *) (h->free->dex);
                ((atom *) *ret)->dex = NIL;
                return LERR_NONE;
        }
        next = h->next;
}

@ @<Find an atom in a compacting heap@>=
next = where;
while (next != NULL) {
        h = next;
        if (ATOM_TO_HEAP(h->free) == where) {
                *ret = (cell) h->free++;
                return LERR_NONE;
        }
        next = h->next;
}

@ @d cons(A,D,R)     (new_atom((A), (D), FORM_PAIR, (R)))
@d new_atom(S,D,T,R) (new_atom_imp(Heap_Thread, (cell)(S), (cell)(D), (T), (R)))
@c
error_code
new_atom_imp (heap     *where,
              cell      nsin,
              cell      ndex,
              cell_tag  ntag,
              cell     *ret)
{
        error_code reason;

        assert(heap_mine_p(where) || heap_shared_p(where));
        assert(ntag != FORM_NONE);
        orreturn(heap_root(where)->fun->alloc(where, ret));
        TAG_SET_M(*ret, ntag);
        ((atom *) *ret)->sin = nsin;
        ((atom *) *ret)->dex = ndex;
        return LERR_NONE;
}

@ The contents and tag of an atom are always reached, except by the
garbage collector which must perform magic, through these accessor
functions. When threading support is added these accessors will
trap attempts to read and write from another thread's heap and
trigger moving the objects into the shared heap.

@c
cell_tag
ltag (cell o)
{
        assert(!special_p(o));
        assert(!heap_other_p(ATOM_TO_HEAP(o)));
        return TAG(o);
}

@ @c
cell
lsin (cell o)
{
        assert(!special_p(o));
        assert(!heap_other_p(ATOM_TO_HEAP(o)));
        return ((atom *) o)->sin;
}

error_code
lsinx (cell  o,
       cell *ret)
{
        *ret = lsin(o);
        return LERR_NONE;
}

error_code
lcar (cell  o,
      cell *ret)
{
        if (!pair_p(o))
                return LERR_INCOMPATIBLE;
        return lsinx(o, ret);
}

@ @c
cell
ldex (cell o)
{
        assert(!special_p(o));
        assert(!heap_other_p(ATOM_TO_HEAP(o)));
        return ((atom *) o)->dex;
}

error_code
ldexx (cell  o,
       cell *ret)
{
        *ret = ldex(o);
        return LERR_NONE;
}

error_code
lcdr (cell  o,
      cell *ret)
{
        if (!pair_p(o))
                return LERR_INCOMPATIBLE;
        return ldexx(o, ret);
}

@ @c
error_code
lsin_set_m (cell o,
            cell datum)
{
        assert(!special_p(o));
        assert(!ATOM_SIN_DATUM_P(o) || defined_p(datum));
        ((atom *) o)->sin = datum;
        return LERR_NONE;
}

error_code
lcar_set_m (cell o,
            cell datum)
{
        if (!pair_p(o))
                return LERR_INCOMPATIBLE;
        return lsin_set_m(o, datum);
}

error_code
ldex_set_m (cell o,
            cell datum)
{
        assert(!special_p(o));
        assert(!ATOM_DEX_DATUM_P(o) || defined_p(datum));
        ((atom *) o)->dex = datum;
        return LERR_NONE;
}

error_code
lcdr_set_m (cell o,
            cell datum)
{
        if (!pair_p(o))
                return LERR_INCOMPATIBLE;
        return ldex_set_m(o, datum);
}

@* Segments.

@d pointer(O)          ((void *) lsin(O))
@d pointer_set_m(O,D)  (lsin_set_m((O), (cell) (D)))
@d pointer_erase_m(O)  (pointer_set_m((O), NULL))
@#
@d pointer_datum(O)    (ldex(O))
@d pointer_set_datum_m(O,D)
                       (ldex_set_m((O), (cell) (D)))
@#
@d segbuf_pointer(O)   ((segment *) pointer(O)) /* The true allocation. */
@d segbuf_base(O)      (segbuf_pointer(O)->base) /* After the segment header. */
@d segbuf_length(O)    (segbuf_pointer(O)->length)
@d segbuf_next(O)      (segbuf_pointer(O)->next)
@d segbuf_owner(O)     (segbuf_pointer(O)->owner) /* |O|, but mutatable. */
@d segbuf_prev(O)      (segbuf_pointer(O)->prev)
@d segbuf_stride(O)    (segbuf_pointer(O)->stride ? segbuf_pointer(O)->stride : 1)
@#
@d segint_p(O)         (segment_intern_p(O) || symbol_intern_p(O))
@d segint_base(O)      (segint_pointer(O)->buffer)
@d segint_pointer(O)   ((atom *) (O))
@d segint_length(O)    ((half) segint_pointer(O)->length)
@d segint_set_length_m(O,V)
                       (segint_pointer(O)->length = (V))
@d segint_owner(O)     (O)
@d segint_stride(O)    ((half) 1)
@#
@d segment_base(O)     (segint_p(O) ? segint_base(O)    : segbuf_base(O))
@d segment_pointer(O)  (segint_p(O) ? segint_pointer(O) : segbuf_pointer(O))
@d segment_length(O)   (segint_p(O) ? segint_length(O)  : segbuf_length(O))
@d segment_owner(O)    (segint_p(O) ? segint_owner(O)   : segbuf_owner(O))
@d segment_stride(O)   (segint_p(O) ? segint_stride(O)  : segbuf_stride(O))
@d segment_can_intern_p(O) (segint_p(O) || segbuf_pointer(O)->stride == 0)
@#
@d segment_set_owner_m(O,N) do {
        assert(!segint_p(O));
        segbuf_owner(O) = (N);
} while (0)
@<Type def...@>=
struct segment {
 struct segment *next, *prev; /* Linked list of all allocated segments. */
        cell owner; /* The referencing atom; cleared and re-set during
                        garbage collection. */
        half length, stride; /* Notably absent: alignment. */
        byte base[]; /* Address of the usable space; a pseudo-pointer
                                which occupies no storage. */
};
typedef struct segment segment;

@ @<Global...@>=
shared segment *Allocations = NULL;
shared pthread_mutex_t Allocations_Lock;

@ @<Extern...@>=
extern shared segment *Allocations;
extern shared pthread_mutex_t Allocations_Lock;

@ @<Initialise memory...@>=
orabort(init_osthread_mutex(&Allocations_Lock, false, false));

@ @<Fun...@>=
error_code alloc_segment_imp (segment *, long, long, long, segment **);
error_code new_segment_imp (heap *, long, long, long, cell_tag,
        cell_tag, cell *);
error_code new_segment_copy (char *, long, long, long, cell_tag,
        cell_tag, cell *);
error_code segment_init (segment *, cell);
error_code segment_release_imp (segment *, bool);
error_code segment_release_m (cell, bool);
error_code segment_resize_m (cell, long);

@ TODO: These arguments should be |size_t| type? |intmax_t|?

TODO: |segment_base|, not |segment_pointer|, should be correctly aligned.

@.TODO@>
@d alloc_segment(L,S,A,R) alloc_segment_imp(NULL, (L), (S), (A), (R))
@c
error_code
alloc_segment_imp (segment  *old,
                   long      length,
                   long      stride,@|
                   long      align,
                   segment **ret)
{
        long clength, cstride;
        segment *new;
        size_t size;
        error_code reason;

        if (stride < 0)
                return LERR_INCOMPATIBLE;
        cstride = stride ? stride : 1;
        clength = (length >= 0) ? length : -length;
        @<Calculate the full size of a segment allocation@>@;
        @<Allocate and initialise a segment@>@;
        if (pthread_mutex_lock(&Allocations_Lock) != 0) {
                mem_free(new); /* Let it fail, we're screwed already. */
                return LERR_INTERNAL;
        }
        @<Insert a new segment into |Allocations|@>@;
        *ret = new;
        pthread_mutex_unlock(&Allocations_Lock);
        return LERR_NONE;
}

@ If the |header| value is -1 then the allocation will be exactly
$length \times stride$ bytes, otherwise the user and segment headers
are added to this length.

@<Calculate the full size of a segment allocation@>=
if (ckd_mul(&size, clength, cstride))
        return LERR_OOM;
if (length >= 0)
        if (ckd_add(&size, size, sizeof (segment)))
                return LERR_OOM;
if (size > HALF_MAX)
        return LERR_LIMIT;

@ @<Allocate and initialise a segment@>=
orreturn(mem_alloc(old, size, align, (void **) &new));
new->length = length;
new->stride = stride;
if (old == NULL)
        new->owner = NIL; /* This is a new allocation. */

@ @<Insert a new segment into |Allocations|@>=
if (Allocations == NULL)
        Allocations = new->next = new->prev = new;
else {
        new->next = Allocations;
        new->prev = Allocations->prev;
        Allocations->prev->next = new;
        Allocations->prev = new;
}

@ @d new_segment(L,S,A,R) new_segment_imp(Heap_Thread, (L), (S), (A),
        FORM_SEGMENT, FORM_SEGMENT_INTERN, (R))
@c
error_code
new_segment_imp (heap     *where,
                 long      length,
                 long      stride,
                 long      align,
                 cell_tag  ntag,
                 cell_tag  itag,
                 cell     *ret)
{
        segment *s;
        error_code reason;

        if (stride == 0 && align == 0 && length >= 0 && length <= INTERN_BYTES) {
                @<``Allocate'' an interned segment and |return|@>
        } else {
                @<Allocate a full-size segment@>
        }
}

@ @<``Allocate'' an intern...@>=
assert(itag != FORM_NONE);
orreturn(new_atom_imp(where, NIL, NIL, itag, ret));
segint_set_length_m(*ret, length);
return LERR_NONE;

@ @<Allocate a full-size segment@>=
orreturn(new_atom_imp(where, NIL, NIL, FORM_PAIR, ret));
orreturn(alloc_segment(length, stride, align, &s));
TAG_SET_M(*ret, ntag);
ATOM_TO_ATOM(*ret)->sin = (cell) s;
s->owner = *ret;
return LERR_NONE;

@ @c
error_code
new_segment_copy (char     *buf,
                  long      length,
                  long      stride,
                  long      align,
                  cell_tag  ntag,
                  cell_tag  itag,
                  cell     *ret)
{
        error_code reason;

        orreturn(new_segment_imp(Heap_Thread, length, stride, align, ntag,
                itag, ret));
        if (stride == 0)
                stride = 1;
        memmove(segment_base(*ret), buf, length * stride);
        return LERR_NONE;
}

@ @c
error_code
segment_init (segment *seg,
              cell     container)
{
        seg->owner = container;
        TAG_SET_M(container, FORM_HEAP);
        pointer_set_m(container, seg);
        pointer_set_datum_m(container, NIL);
        return LERR_NONE;
}

@ Not clear what could go wrong but when something does assume the worst.

@c
error_code
segment_release (cell o,
                 bool reclaim)
{
        error_code reason;

        if (!pointer_p(o))
                return LERR_INCOMPATIBLE;
        reason = segment_release_imp(pointer(o), reclaim);
        pointer_erase_m(o); /* For safety. */
        return reason;
}

@ @c
error_code
segment_release_imp (segment *o,
                     bool     reclaim)
{
        if (pthread_mutex_lock(&Allocations_Lock) != 0)
                return LERR_INTERNAL;
        if (o == Allocations)
                Allocations = o->next;
        if (o->next == o)
                Allocations = NULL;
        else
                o->prev->next = o->next,
                o->next->prev = o->prev;
        o->next = o->prev = o; /* For safety. */
        if (pthread_mutex_unlock(&Allocations_Lock) != 0)
                return LERR_INTERNAL;
        if (reclaim)
                return mem_free(o);
        else
                return LERR_NONE;
}

@ Only for true segments and things based on arrays.

@c
error_code
segment_resize_m (cell o,
                  long nlength)
{
        long i, olength;
        segment *new, *old;
        error_code reason;

        if (!(segment_p(o) || larry_p(o)))
                return LERR_INCOMPATIBLE;
        if (nlength < 0)
                return LERR_INCOMPATIBLE;
        if (nlength == segment_length(o))
                return LERR_NONE; /* Not an error. */

        if (segment_can_intern_p(o) && nlength <= INTERN_BYTES) {
                if (segint_p(o)) {
                        @<Resize an interned segment@>
                } else {
                        @<Intern a previously allocated segment@>
                }
        } else if (segint_p(o)) {
                @<Allocate a segment for a previously interned segment@>
        } else {
                @<Resize an allocated segment@>
        }
        return LERR_NONE;
}

@ @<Resize an interned segment@>=
segint_set_length_m(o, nlength);

@ Symbols are never resized so the only valid format is |FORM_SEGMENT|
changing to |FORM_SEGMENT_INTERN|.

@<Intern a previously allocated segment@>=
TAG_SET_M(o, FORM_SEGMENT_INTERN); /* Do this first to turn the atom opaque. */
old = segbuf_pointer(o);
segint_set_length_m(o, nlength);
for (i = 0; i < nlength; i++)
        segint_base(o)[i] = old->base[i];
orreturn(segment_release_imp(old, true));

@ Aligned allocations cannot be resized.

@<Allocate a segment for a previously interned segment@>=
olength = segment_length(o);
orreturn(alloc_segment(nlength, 0, 0, &new));
for (i = 0; i < olength; i++)
        new->base[i] = segint_base(o)[i];
pointer_set_m(o, new);
pointer_set_datum_m(o, NIL);
TAG_SET_M(o, FORM_SEGMENT); /* Do this last so the atom remains opaque. */

@ @<Resize an allocated segment@>=
old = segbuf_pointer(o);
orreturn(alloc_segment_imp(old, nlength, segment_stride(o), 0, &new));
pointer_set_m(o, new); /* May have changed. */

@* Words, Bytes \AM\ Simple Integers. Definitions of fixed and big
integers, addition \AM\ subtraction. More later after the rest of
the core.

@d word(O)         ((char *) (O))
@d word_high(O)    ((digit) lsin(O))
@d word_low(O)     ((digit) ldex(O))
@d word_value(O)   (word_low(O))
@#
@d fix(V)         (FIXED | asl((V), FIXED_SHIFT))
@d fixed_value(V) (asr((V), FIXED_SHIFT))
@d int_digit(O)   (((atom *) (O))->value) /* Eeek! */
@d int_next(O)    (((atom *) (O))->tail)
@d int_more_p(O)  (!null_p(int_next(O)))
@<Fun...@>=
intmax_t asl (intmax_t, int);
intmax_t asr (intmax_t, int);
error_code new_fixed (intmax_t, cell *);
error_code new_digit (digit, cell, cell *);
error_code new_int_c (intmax_t, bool, cell *);
error_code new_word (digit, digit, cell *);
error_code int_abs (cell, cell *);
error_code int_add (cell, cell, cell *);
error_code int_cmp (cell, cell, cell *);
error_code int_mul (cell, cell, cell *);
error_code int_reverse (cell, cell *);
error_code int_sub (cell, cell, cell *);
error_code int_value (cell, intmax_t *);
error_code uint_value (cell, uintmax_t *);
bool cmpis_p (cell, cell);

@ @c
intmax_t
asl (intmax_t value,
     int      shift)
{
        return value << shift;
}

intmax_t
asr (intmax_t value,
     int      shift)
{
        return value >= 0 ? value >> shift : ~(~value >> shift);
}

@ @c
error_code
new_word (digit  high,
          digit  low,
          cell  *ret)
{
        return new_atom((cell) high, (cell) low, FORM_WORD, ret);
}

@ @c
error_code
new_fixed (intmax_t  value,
           cell     *ret)
{
        if (value < FIXED_MIN || value > FIXED_MAX)
                return LERR_LIMIT;
        *ret = fix(value);
        return LERR_NONE;
}

@ @c
error_code
new_digit (digit  value,
           cell   tail,
           cell  *ret)
{
        return new_atom(value, tail, FORM_POSITIVE, ret);
}

@ Extremely naive and slow but simple algorithm. Assumes the contents
of base[0..length-1] are all [0-9].

@c
error_code
new_int_buffer (bool      minus,
                char     *base,
                intmax_t  length,
                cell     *ret)
{
        cell work;
        int i;
        error_code reason;

        work = fix(0);
        for (i = 0; i < length; i++) {
                orreturn(int_mul(work, fix(10), &work));
                orreturn(int_add(work, fix(base[i] - '0'), &work));
        }
        if (minus)
                TAG_SET_M(work, FORM_NEGATIVE);
        *ret = work;
        return LERR_NONE;
}

@ Maths code boxes fixnums in a secret bigint when |fixable| is
|false|. TODO: That is unnecessary. They will always be a single
pair and can be created in place when necessary.

@.TODO@>
@c
error_code
new_int_c (intmax_t  value,
           bool      fixable,
           cell     *ret)
{
        bool minus;
        cell tail, new;
        digit next;
        error_code reason;
        uintmax_t work;

        if (fixable && value >= FIXED_MIN && value <= FIXED_MAX)
                return new_fixed(value, ret);
        assert(value);
        if ((minus = (value < 0)))
                work = -value;
        else
                work = value;
        tail = NIL;
        while (work) {
                next = work % DIGIT_MAX;
                orreturn(new_digit(next, tail, &new));
                work /= DIGIT_MAX;
                tail = new;
        }
        if (minus)
                TAG_SET_M(new, FORM_NEGATIVE);
        *ret = new;
        return LERR_NONE;
}

@ @c
bool
int_negative_p (cell o)
{
        if (negative_p(o))
                return true;
        if (fixed_p(o) && fixed_value(o) < 0)
                return true;
        return false;
}

@ Unused?

@c
error_code
int_reverse (cell  o,
             cell *ret)
{
        cell tail;
        error_code reason;

        if (!negative_p(o) || !positive_p(o))
                return LERR_INCOMPATIBLE;
        tail = NIL;
        while (!null_p(o)) {
                orreturn(new_digit(int_digit(o), tail, &tail));
                o = int_next(o);
        }
        *ret = tail;
        return LERR_NONE;
}

@ @c
error_code
int_value (cell      value,
           intmax_t *ret)
{
        if (fixed_p(value)) {
                *ret = fixed_value(value);
                return LERR_NONE;
        } else if (positive_p(value)) {
                if (!int_more_p(value) && int_digit(value) <= INTMAX_MAX) {
                        *ret = int_digit(value);
                        return LERR_NONE;
                } else
                        return LERR_LIMIT;
        } else if (negative_p(value)) {
                if (!int_more_p(value) && int_digit(value) <= (digit) -INTMAX_MIN) {
                        *ret = -int_digit(value);
                        return LERR_NONE;
                } else
                        return LERR_LIMIT;
        } else
                return LERR_INCOMPATIBLE;
}

@ @c
error_code
uint_value (cell       value,
            uintmax_t *ret)
{
        assert(UINTMAX_MAX == DIGIT_MAX);
        if ((fixed_p(value) && fixed_value(value) < 0) || negative_p(value))
                        return LERR_LIMIT;
        else if (fixed_p(value)) {
                *ret = fixed_value(value);
                return LERR_NONE;
        } else if (!positive_p(value))
                return LERR_INCOMPATIBLE;
        else if (int_more_p(value))
                return LERR_LIMIT;
        else {
                *ret = int_digit(value);
                return LERR_NONE;
        }
}

@ @c
bool
cmpis_p (cell yin,
         cell yang)
{
        cell answer;

        if (yin == yang)
                return true;
        else if (rune_p(yin) && rune_p(yang))
                return rune_codepoint(yin) == rune_codepoint(yang);
        else if (failure_p(int_cmp(yin, yang, &answer)))
                return false;
        return fixed_value(answer) == 0;
}

@ Compares integers against each other, treating runes as integers
who's value is their codepoint. Fixed integers and runes can be
compared simply after extracting their values. Big integers are
compared against each other digit-by-digit until one or they both
end.

@c
error_code
int_cmp (cell  yin,
         cell  yang,
         cell *ret)
{
        bool minus;
        intmax_t vyin, vyang;
        int maybe;

        if (!integer_p(yin) || !integer_p(yang))
                return LERR_INCOMPATIBLE;
        if (fixed_p(yin)) {
                vyin = fixed_value(yin);
                if (fixed_p(yang)) {
                        vyang = fixed_value(yang);
                        if (vyin < vyang)
                                return new_fixed(-1, ret);
                        else if (vyin > vyang)
                                return new_fixed(1, ret);
                        else
                                return new_fixed(0, ret);
                } else if (negative_p(yang))
                        return new_fixed(1, ret);
                else if (positive_p(yang))
                        return new_fixed(-1, ret);
                else
                        return LERR_INCOMPATIBLE;

        } else if (negative_p(yin)) {
                if (fixed_p(yang) || positive_p(yang))
                        return new_fixed(-1, ret);
                else if (!negative_p(yang))
                        return LERR_INCOMPATIBLE;
                else
                        minus = true;

        } else if (positive_p(yin)) {
                if (fixed_p(yang) || negative_p(yang))
                        return new_fixed(1, ret);
                else if (!positive_p(yang))
                        return LERR_INCOMPATIBLE;
                else
                        minus = false;
        }

        maybe = 0;
        while (1) {
                if (null_p(yin)) {
                        if (null_p(yang))
                                return new_fixed(minus ? -maybe : maybe, ret); /* same length */
                        else
                                return new_fixed(minus ? 1 : -1, ret); /* yin has fewer digits */
                } else if (null_p(yang))
                        return new_fixed(minus ? -1 : 1, ret); /* yang has fewer digits */
                else if (maybe == 0)
                        maybe = (int_digit(yin) < int_digit(yang)) ? -1 :
                                (int_digit(yin) > int_digit(yang));
                yin = int_next(yin);
                yang = int_next(yang);
        }
}

@ @c
error_code
int_abs (cell  o,
         cell *ret)
{
        intmax_t value;
        digit payload;
        cell tail;

        if (fixed_p(o)) {
                value = fixed_value(o);
                if (value < 0)
                        value = -value;
                return new_int_c(value, true, ret);
        }
        if (positive_p(o)) {
                *ret = o;
                return LERR_NONE;
        }
        if (!negative_p(o))
                return LERR_INCOMPATIBLE;
        payload = int_digit(o);
        tail = int_next(o);
        return new_digit(payload, tail, ret);
}

@ Addition and subtraction are substantially similar.

@d int_extract(O,V,R) do {
        if (fixed_p(O))
                (V) = (fixed_value(O) >= 0) ? fixed_value(O) : -fixed_value(O);
        else {
                (R) = int_value((O), &(V));
                if ((R) == LERR_LIMIT)
                        return LERR_UNIMPLEMENTED;
                else if (failure_p(R))
                        return (R);
        }
} while (0)
@c
error_code
int_add (cell  yin,
         cell  yang,
         cell *ret)
{
        intmax_t result, vyin, vyang;
        error_code reason;

        if (!integer_p(yin) || !integer_p(yang))
                return LERR_INCOMPATIBLE;

        if (yin == fix(0)) {
                *ret = yang;
                return LERR_NONE;
        } else if (yang == fix(0)) {
                *ret = yin;
                return LERR_NONE;
        }

        int_extract(yin, vyin, reason);
        int_extract(yang, vyang, reason);
        if (ckd_add(&result, vyin, vyang))
                return LERR_UNIMPLEMENTED;

        return new_int_c(result, true, ret);
}

@ @c
error_code
int_sub (cell  yin,
         cell  yang,
         cell *ret)
{
        intmax_t result, vyin, vyang;
        error_code reason;

        if (!integer_p(yin) || !integer_p(yang))
                return LERR_INCOMPATIBLE;

        if (yang == fix(0)) {
                *ret = yin;
                return LERR_NONE;
        }

        int_extract(yin, vyin, reason);
        int_extract(yang, vyang, reason);
        if (ckd_sub(&result, vyin, vyang))
                return LERR_UNIMPLEMENTED;

        return new_int_c(result, true, ret);
}

@ @c
error_code
int_mul (cell  yin,
         cell  yang,
         cell *ret)
{
        intmax_t result, vyin, vyang;
        error_code reason;

        if (!integer_p(yin) || !integer_p(yang))
                return LERR_INCOMPATIBLE;

        if (yin == fix(0) || yang == fix(0))
                return new_fixed(0, ret);
        if (yin == fix(1)) {
                *ret = yang;
                return LERR_NONE;
        } else if (yang == fix(1)) {
                *ret = yin;
                return LERR_NONE;
        }

        int_extract(yin, vyin, reason);
        int_extract(yang, vyang, reason);
        if (ckd_mul(&result, vyin, vyang))
                return LERR_UNIMPLEMENTED;

        return new_int_c(result, true, ret);
}

@* Arrays.

The GC scanner starts looking at cells from |larry_object(O)->base[header]|
as |scan_progress == 0|.

@<Type def...@>=
typedef struct {
        half header, scan_progress;
        cell base[];
} larry;

@ @d LARRY_HEADER_LENGTH  (sizeof (larry) / sizeof (cell))
@#
@d larry_object(O)          ((larry *) segment_base(O))
@d larry_base(O)            (larry_object(O)->base)
@d larry_header(O)          (larry_object(O)->header)
@d larry_set_header_m(O,V)  (larry_header(O) = (V))
@d larry_scan_progress(O)   (larry_object(O)->scan_progress)
@d larry_set_scan_progress_m(O,V)
                            (larry_scan_progress(O) = (V))
@d larry_length(O)          (segment_length(O) - (half) LARRY_HEADER_LENGTH)
@d larry_ref_imp(O,I)       (larry_base(O)[larry_header(O) + (I)])
@d larry_set_m_imp(O,I,V)   (larry_base(O)[larry_header(O) + (I)] = (V))
@<Fun...@>=
error_code new_larry (intmax_t, intmax_t, cell, cell_tag, cell *);
error_code larry_ref (cell, intmax_t, cell *);
error_code larry_resize_m (cell, intmax_t, cell);
error_code larry_ref (cell, intmax_t, cell *);
error_code larry_set_m (cell, intmax_t, cell);

@ |length| must be large enough to hold |header|.

@c
error_code
new_larry (intmax_t  length,
           intmax_t  header,
           cell      fill,
           cell_tag  ntag,
           cell     *ret)
{
        error_code reason;
        intmax_t i, rlength;

        assert(LARRY_HEADER_LENGTH * sizeof (cell) == sizeof (larry));
        if (header < 0 || length < header || header > HALF_MAX)
                return LERR_LIMIT;
        if (length > (intmax_t) (HALF_MAX - LARRY_HEADER_LENGTH))
                return LERR_LIMIT;
        rlength = length + LARRY_HEADER_LENGTH;
        orreturn(new_segment_imp(Heap_Thread, rlength, sizeof (cell),
                sizeof (cell), ntag, FORM_NONE, ret));
        larry_set_header_m(*ret, header);
        larry_set_scan_progress_m(*ret, 0);
        if (defined_p(fill))
                for (i = 0; i < length - header; i++)
                        larry_set_m_imp(*ret, i, fill);
        return LERR_NONE;
}

@ @c
error_code
larry_ref (cell      o,
           intmax_t  index,
           cell     *ret)
{
        if (!larry_p(o))
                return LERR_INCOMPATIBLE;
        if (index < 0)
                return LERR_OUT_OF_BOUNDS;
        if (index > larry_length(o) - larry_header(o))
                return LERR_OUT_OF_BOUNDS;
        *ret = larry_ref_imp(o, index);
        return LERR_NONE;
}

@ @c
error_code
larry_set_m (cell      o,
             intmax_t  index,
             cell      value)
{
        if (!larry_p(o))
                return LERR_INCOMPATIBLE;
        if (index < 0)
                return LERR_OUT_OF_BOUNDS;
        if (index > larry_length(o) - larry_header(o))
                return LERR_OUT_OF_BOUNDS;
        larry_set_m_imp(o, index, value);
        return LERR_NONE;
}

@ @c
error_code
larry_resize_m (cell     o,
                intmax_t length,
                cell     fill)
{
        intmax_t i, olength, rlength;
        error_code reason;

        assert(larry_p(o));
        if (length > (intmax_t) (HALF_MAX - LARRY_HEADER_LENGTH))
                return LERR_LIMIT;
        rlength = length + LARRY_HEADER_LENGTH;
        olength = larry_length(o);
        orreturn(segment_resize_m(o, rlength));
        if (defined_p(fill))
                for (i = olength; i < length - larry_header(o); i++)
                        larry_set_m_imp(o, i, fill);
        return LERR_NONE;
}

@* Lossless Arrays. Offset larry.

@d array_resize_m(O,L,F) (larry_resize_m((O), (L) + ARRAY_HEADER_LENGTH, (F)))
@<Type def...@>=
typedef struct {
        cell offset;
        cell base[];
} array;

@ @d ARRAY_HEADER_LENGTH (sizeof (array) / sizeof (cell))
@d array_object(O)       ((array *) larry_base(O))
@d array_base(O)         (array_object(O)->base)
@d array_offset(O)       (array_object(O)->offset)
@d array_set_offset(O,V) (array_offset(O) = (V))
@d array_length(O)       (larry_length(O) - (half) ARRAY_HEADER_LENGTH)
@<Fun...@>=
error_code new_array_imp (intmax_t, cell, cell, cell *);
error_code array_ref_c (cell, intmax_t, cell *);
error_code array_set_m_c (cell, intmax_t, cell);
error_code array_ref (cell, cell, cell *);
error_code array_set_m (cell, cell, cell);
cell get_array_ref_c (cell, intmax_t);

@ 0 header is fine for scanning if the larry subheader is all cells,
as they are here.

@d new_array(L,F,R) new_array_imp((L), fix(0), (F), (R))
@c
error_code
new_array_imp (intmax_t length,
               cell     offset,
               cell     fill,
               cell    *ret)
{
        intmax_t rlength;
        error_code reason;

        assert(ARRAY_HEADER_LENGTH * sizeof (cell) == sizeof (array));
        if (!integer_p(offset))
                return LERR_INCOMPATIBLE;
        if (length < 0)
                return LERR_LIMIT;
        if (length > (intmax_t) (HALF_MAX - ARRAY_HEADER_LENGTH))
                return LERR_LIMIT;
        rlength = length + ARRAY_HEADER_LENGTH;
        orreturn(new_larry(rlength, 0, fill, FORM_ARRAY, ret));
        array_set_offset(*ret, offset);
        return LERR_NONE;
}

@ @c
error_code
array_ref_c (cell      o,
             intmax_t  index,
             cell     *ret)
{
        if (!array_p(o))
                return LERR_INCOMPATIBLE;
        if (ckd_add(&index, index, ARRAY_HEADER_LENGTH))
                return LERR_OUT_OF_BOUNDS;
        return larry_ref(o, index, ret);
}

@ @c
cell
get_array_ref_c (cell     o,
                 intmax_t index)
{
        cell ret;
        error_code reason;

        orassert(array_ref_c(o, index, &ret));
        return ret;
}

@ @c
error_code
array_set_m_c (cell     o,
               intmax_t index,
               cell     value)
{
        if (!array_p(o))
                return LERR_INCOMPATIBLE;
        if (ckd_add(&index, index, ARRAY_HEADER_LENGTH))
                return LERR_OUT_OF_BOUNDS;
        return larry_set_m(o, index, value);
}

@ @c
error_code
array_ref (cell  o @[unused@],
           cell  index @[unused@],
           cell *ret @[unused@])
{
        return LERR_UNIMPLEMENTED;
}

@ @c
error_code
array_set_m (cell o @[unused@],
             cell index @[unused@],
             cell value @[unused@])
{
        return LERR_UNIMPLEMENTED;
}

@* Hashtables.

@<Type def...@>=
typedef uint32_t hash;
typedef hash @[@] (*hash_fn) (cell);
typedef bool @[@] (*match_fn) (cell, void *);
typedef error_code @[@] (*filter_fn) (cell, cell *);

@ @<Fun...@>=
hash hash_cstr (byte *, intmax_t *);
hash hash_buffer (byte *, intmax_t);

@ @c
hash
hash_cstr (byte     *buf,
           intmax_t *length)
{
        hash r = 0;
        byte *p = buf;

        while (*p != '\0')
                r = 33 * r + (unsigned char) (*p++);
        *length = p - buf;
        return r;
}

@ Interned symbols call this with NULL but are small so it's safe
to ignore interrupts.

@c
hash
hash_buffer (byte     *buf,
             intmax_t  length)
{
        hash r = 0;
        intmax_t i;

        assert(length >= 0);
        for (i = 0; i < length; i++)
                r = 33 * r + (unsigned char) (*buf++);
        return r;
}

@ To make it easier to build on an array the two extra bits of
hashtable state are kept at the back of the table, which is two
larger than specified.

A ``tiny'' hashtable isn't enlarged until it entirely fills up.

As long as arrays/segments record metadata as a ``half'' the hashtable
metadata is guaranteed to fit in a fixnum, except for signage on
16-bit machines. The difference will be optimised away.

Probably want typedefs for the function pointers.

16 bit systems must limit hash tables to 255, 32 bit systems can
store 23 bits (24 signed) in a fixnum.

TODO: Use the pointer datum for the free count.

@<Type def...@>=
typedef struct {
        half free, blocked;
        cell base[];
} hashtable;

@
@d HASHTABLE_TINY               16
@#
@d HASHTABLE_HEADER_LENGTH      (sizeof (hashtable) / sizeof (cell))
@d hashtable_object(O)          ((hashtable *) larry_base(O))
@d hashtable_blocked(O)         (hashtable_object(O)->blocked)
@d hashtable_free(O)            (hashtable_object(O)->free)
@d hashtable_free_p(O)          (hashtable_free(O) > 0)
@d hashtable_length(O)          (larry_length(O) - (half) HASHTABLE_HEADER_LENGTH)
@d hashtable_set_blocked_m(O,V) (hashtable_object(O)->blocked = (V))
@d hashtable_set_free_m(O,V)    (hashtable_object(O)->free = (V))
@d hashtable_ref(O,I)           (hashtable_object(O)->base[(I)])
@d hashtable_set_m(O,I,V)       (hashtable_object(O)->base[(I)] = (V))
@<Fun...@>=
error_code new_hashtable (intmax_t, cell *);
error_code copy_hashtable (cell, hash_fn, cell *);
void copy_hashtable_imp (cell, hash_fn, cell);
cell hashtable_blocked_imp (cell);
error_code hashtable_erase_m (cell, hash, cell, hash_fn, match_fn, bool);
error_code hashtable_fetch (cell, hash, match_fn, void *, cell *);
cell hashtable_free_imp (cell);
error_code hashtable_pairs (cell, filter_fn, cell *);
error_code hashtable_resize_m (cell, hash_fn, intmax_t);
error_code hashtable_save_m (cell, hash, cell, hash_fn, match_fn, void *,
        bool, bool);
intmax_t hashtable_scan (cell, hash, match_fn, void *);
error_code hashtable_search (cell, hash, match_fn, void *, cell *);

@
@d hashtable_default_free(L) (((L) == HASHTABLE_TINY)
        ? (HASHTABLE_TINY - 1)
        : ((7 * (1 << (high_bit(L) - 1))) / 10))
                /* $\lfloor70\%\rfloor$ */
@c
error_code
new_hashtable (intmax_t  length,
               cell     *ret)
{
        intmax_t f, rlength;
        error_code reason;

        assert(HASHTABLE_HEADER_LENGTH * sizeof (cell) == sizeof (hashtable));
        if (length < 0)
                return LERR_INCOMPATIBLE;
        else if (length == 0)
                rlength = f = 0;
        else {
                rlength = 1 << (high_bit(length) - 1);
                if (rlength < length)
                        rlength <<= 1;
                if (rlength <= HASHTABLE_TINY)
                        f = (rlength = HASHTABLE_TINY) - 1; /* Guarantee at least
                                                                one |NIL|. */
                else
                        f = hashtable_default_free(rlength);
                if (rlength > (intmax_t) (HALF_MAX - HASHTABLE_HEADER_LENGTH))
                        return LERR_LIMIT;
        }
        orreturn(new_larry(rlength + HASHTABLE_HEADER_LENGTH,
                HASHTABLE_HEADER_LENGTH, NIL, FORM_HASHTABLE, ret));
        hashtable_set_blocked_m(*ret, 0);
        hashtable_set_free_m(*ret, f);
        return LERR_NONE;
}

@ @c
error_code
copy_hashtable (cell     o,
                hash_fn  hashfn,
                cell    *ret)
{
        cell new;
        error_code reason;

        if (!hashtable_p(o))
                return LERR_INCOMPATIBLE;
        orreturn(new_hashtable(hashtable_length(o), &new));
        copy_hashtable_imp(o, hashfn, new);
        *ret = new;
        return LERR_NONE;
}

@ Removes blockages too. Does not require |new| and |old| to be the same length.

TODO: Check that new will fit everything from old.

@c
void
copy_hashtable_imp (cell    old,
                    hash_fn hashfn,
                    cell    new)
{
        int i, j, length, nfree, nlength;
        cell pos, value;
        hash nkey;

        assert(hashtable_p(old));
        assert(hashtable_p(new));
        length = hashtable_length(old);
        nlength = hashtable_length(new);
        nfree = hashtable_free(new);
        assert(nfree >= length - (hashtable_free(old) + hashtable_blocked(old)));
        for (i = 0; i < length; i++) {
                value = hashtable_ref(old, i);
                if (!null_p(value) && defined_p(value)) {
                        nkey = hashfn(value);
                        j = nkey % nlength;
                        while (1) {
                                pos = hashtable_ref(new, j);
                                if (null_p(pos))
                                        break;
                                if (j == 0)
                                        j = nlength - 1;
                                else
                                        j--;
                        }
                        hashtable_set_m(new, j, value);
                        nfree--;
                }
        }
        hashtable_set_free_m(new, nfree);
}

@ TODO: Shrink the table if there are sufficient blocked cells (here
or in delete).

@.TODO@>
@c
error_code
hashtable_resize_m (cell     o,
                    hash_fn  hashfn,
                    intmax_t nlength)
{
        atom tmp;
        cell new;
        error_code reason;

        if (!hashtable_p(o))
                return LERR_INCOMPATIBLE;

        if (nlength == -1) { /* Increment to the next size. */
                if (hashtable_length(o) == 0)
                        nlength = HASHTABLE_TINY;
                else if (hashtable_length(o) >= HALF_MAX >> 1)
                        return LERR_LIMIT;
                else
                        nlength = hashtable_length(o) << 1;
        }
        orreturn(new_hashtable(nlength, &new));
        copy_hashtable_imp(o, hashfn, new);
        tmp = *(atom *) o; /* No need to swap the tag. */
        *(atom *) o = *(atom *) new;
        *(atom *) new = tmp;
        segbuf_owner(o) = o;
        segbuf_owner(new) = new;
        return LERR_NONE;
}

@ @c
intmax_t
hashtable_scan (cell      o,
                hash      key,
                match_fn  match,
                void     *ctx)
{
        intmax_t i;
        cell pos;

        assert(hashtable_p(o));
        if (hashtable_length(o) == 0)
                return FAIL;
        i = key % hashtable_length(o);
        while (1) {
                pos = hashtable_ref(o, i);
                if (null_p(pos) || (defined_p(pos) && match(pos, ctx)))
                        break;
                if (i == 0)
                        i = hashtable_length(o) - 1;
                else
                        i--;
        }
        if (null_p(pos) && !hashtable_free_p(o))
                return FAIL;
        return i;
}

@ @c
error_code
hashtable_search (cell      o,
                  hash      key,
                  match_fn  match,
                  void     *ctx,
                  cell     *ret)
{
        intmax_t idx;
        cell value;

        if (!hashtable_p(o))
                return LERR_INCOMPATIBLE;
        idx = hashtable_scan(o, key, match, ctx);
        if (idx == FAIL) {
                *ret = UNDEFINED;
                return LERR_NONE;
        }
        value = hashtable_ref(o, idx);
        if (null_p(value)) {
                *ret = UNDEFINED;
                return LERR_NONE;
        }
        *ret = value;
        return LERR_NONE;
}

@ @c
error_code
hashtable_fetch (cell      o,
                 hash      key,
                 match_fn  match,
                 void     *ctx,
                 cell     *ret)
{
        cell value;
        error_code reason;

        orreturn(hashtable_search(o, key, match, ctx, &value));
        if (undefined_p(value))
                return LERR_MISSING;
        *ret = value;
        return LERR_NONE;
}

@ @c
error_code
hashtable_save_m (cell      o,
                  hash      key,
                  cell      datum,
                  hash_fn   hashfn,
                  match_fn  match,
                  void     *ctx,
                  bool      replace,
                  bool      enlarge)
{
        intmax_t idx;
        error_code reason;

        if (!hashtable_p(o))
                return LERR_INCOMPATIBLE;
                printf("save ");psym((cell)ctx);printf(" in %p at %u\n",o,key);
again:
        idx = hashtable_scan(o, key, match, ctx);
        if (idx == FAIL) {
                if (replace && !enlarge)
                        return LERR_MISSING;
                if (!enlarge)
                        return LERR_OUT_OF_BOUNDS;
                enlarge = false; /* Not really necessary. */
                orreturn(hashtable_resize_m(o, hashfn, -1));
                goto again;
        } else if (!null_p(hashtable_ref(o, idx)) && !replace)
                return LERR_EXISTS;
        hashtable_set_m(o, idx, datum);
        hashtable_set_free_m(o, hashtable_free(o) - 1);
        return LERR_NONE;
}

@ @c
error_code
hashtable_erase_m (cell     o,
                   hash     key,
                   cell     label,
                   hash_fn  hashfn,
                   match_fn match,
                   bool     reduce)
{
        intmax_t idx, nlength, nused;
        error_code reason;

        if (!hashtable_p(o))
                return LERR_INCOMPATIBLE;
        idx = hashtable_scan(o, key, match, (void *) label);
        if (idx == FAIL)
                return LERR_MISSING;
        hashtable_set_m(o, idx, UNDEFINED);
        hashtable_set_blocked_m(o, hashtable_blocked(o) + 1);
        if (reduce) {
                nlength = hashtable_length(o);
                nused = hashtable_default_free(nlength);
                nused -= hashtable_free(o) + hashtable_blocked(o);
                if (nused <= hashtable_default_free(nlength >> 1))
                        nlength >>= 1;
                orreturn(hashtable_resize_m(o, hashfn, nlength));
        }
        return LERR_NONE;
}

@ @c
error_code
hashtable_pairs (cell       o,
                 filter_fn  filter,
                 cell      *ret)
{
        cell rest, value;
        intmax_t i;
        error_code reason;

        if (!hashtable_p(o))
                return LERR_INCOMPATIBLE;
        if (hashtable_length(o) == 0)
                return NIL;

        rest = NIL;
        for (i = 0; i < hashtable_length(o); i++) {
                value = hashtable_ref(o, i);
                if (!null_p(value) && defined_p(value)) {
                        if (filter != NULL)
                                orreturn(filter(value, &value));
                        orreturn(cons(value, rest, &rest));
                }
        }
        *ret = rest;
        return LERR_NONE;
}

@* Symbols.

@d SYMBOL_MAX          HALF_MAX
@d Symbol_Table_ref(I) (hashtable_ref(Symbol_Table, (I)))
@#
@<Global...@>=
shared cell Symbol_Table = NIL;

@ @<Initialise heap...@>=
orabort(new_hashtable(0, &Symbol_Table));

@
@d symint_object(O) ((symbol *) NULL)
@d symint_key(O)    (hash_buffer(symbol_label(O), symbol_length(O)))
@d symint_label(O)  (((atom *) (O))->buffer)
@#
@d symbuf_object(O) ((symbol *) segment_base(O))
@d symbuf_key(O)    (symbuf_object(O)->key)
@d symbuf_label(O)  (symbuf_object(O)->label)
@#
@d symbol_label(O)  (symbol_intern_p(O) ? symint_label(O) : symbuf_label(O))
@d symbol_key(O)    (symbol_intern_p(O) ? symint_key(O) : symbuf_key(O))
@d symbol_length(O) (segment_length(O))
@<Type def...@>=
typedef struct {
        hash key;
        byte label[];
} symbol;

typedef struct {
        byte     *buf;
        intmax_t  length;
} symbol_compare;

@ Some symbols are used by this implementation. To avoid constantly
searching for them they are given numeric constants.

@ @<Type def...@>=
typedef enum {
        @<Constant Symbol Labels@>
        LSL_LENGTH
} symbol_const;

@ @<Global...@>=
shared cell Label[LSL_LENGTH + 42];

@ @<Fun...@>=
error_code new_symbol_buffer (byte *, intmax_t, bool *, cell *);
error_code new_symbol_imp (hash, byte *, intmax_t, bool *, cell *);
void symbol_remember (symbol_const, cell);
hash symbol_table_hash (cell);
bool symbol_table_match (cell, void *);

@ @d init_identifier(S,L,V) do {
        orabort(new_symbol_const((L), &(V)));
        symbol_remember((S), (V));
} while (0)
@c
void
symbol_remember (symbol_const constant,
                 cell         sym)
{
        Label[constant] = sym;
}

@ Is the existing symbol |o| the same as the proto-symbol described by |ctx|?

@c
bool
symbol_table_match (cell  o,
                    void *ctx)
{
        symbol_compare *cmp = ctx;
        intmax_t i;

        assert(symbol_p(o));
        if (symbol_length(o) != cmp->length)
                return false;
        for (i = 0; i < cmp->length; i++)
                if (symbol_label(o)[i] != cmp->buf[i])
                        return false;
        return true;
}

@ @c
hash
symbol_table_hash (cell o)
{
        assert(symbol_p(o));
        return symbol_key(o);
}

@ @d new_symbol_c(O,R) (new_symbol_buffer((O), -1, NULL, (R)))
@d new_symbol_const(O,R) (new_symbol_buffer((byte *) (O), strlen(O), NULL, (R)))
@c
error_code
new_symbol_buffer (byte     *buf,
                   intmax_t  length,
                   bool     *fresh,
                   cell     *ret)
{
        hash key;

        assert(length >= -1);
        if (length == -1)
                key = hash_cstr(buf, &length);
        else
                key = hash_buffer(buf, length);
        if (length > SYMBOL_MAX)
                return LERR_LIMIT;
        return new_symbol_imp(key, buf, length, fresh, ret);
}

@ @c
error_code
new_symbol_imp (hash      key,
                byte     *buf,
                intmax_t  length,
                bool     *fresh,
                cell     *ret)
{
        symbol_compare scmp = { buf, length };
        bool ignore;
        cell sym;
        intmax_t i;
        error_code reason;

        if (fresh == NULL)
                fresh = &ignore;
        orreturn(hashtable_search(Symbol_Table, key, symbol_table_match,
                &scmp, &sym));
        if (defined_p(sym)) {
                *fresh = false;
                *ret = sym;
                return LERR_NONE;
        }
        *fresh = true;
        orreturn(new_segment_imp(Heap_Thread, length, 0, 0, FORM_SYMBOL,
                FORM_SYMBOL_INTERN, &sym));
        for (i = 0; i < length; i++)
                symbol_label(sym)[i] = buf[i];
        orreturn(hashtable_save_m(Symbol_Table, key, sym,
                symbol_table_hash, symbol_table_match, (void *) sym,
                false, true));
        *ret = sym;
        return LERR_NONE;
}

@* Environment. Combine symbols and hash tables.

@d env_layer(O)    (ldex(O))
@d env_previous(O) (lsin(O))
@d env_root_p(O)   (environment_p(O) && null_p(env_previous(O)))
@<Fun...@>=
error_code new_env (cell, cell *);
cell env_get_root (cell);
bool env_match (cell, void *);
hash env_rehash (cell);
error_code env_root_init (void);
error_code env_save_m (cell, cell, cell, bool);
error_code env_search (cell, cell, cell *);

@ @c
error_code
env_root_init (void)
{
        cell ltmp;
        int i;
        error_code reason;

        @<Populate the |Root| environment@>
        return LERR_NONE;
}

@ @d new_empty_env(F)   (new_env(NIL, (F)))
@c
error_code
new_env (cell  o,
         cell *ret)
{
        cell tmp;
        error_code reason;

        if (!environment_p(o) && !null_p(o))
                return LERR_INCOMPATIBLE;
        orreturn(new_hashtable(0, &tmp));
        orreturn(new_atom(o, tmp, FORM_ENVIRONMENT, ret));
        return LERR_NONE;
}

@ @c
bool
env_match (cell  o,
           void *ctx)
{
        cell want = (cell) ctx;

        assert(pair_p(o));
        assert(symbol_p(lsin(o)));
        return lsin(o) == want;
}

@ @c
hash
env_rehash (cell o)
{
        assert(pair_p(o));
        assert(symbol_p(lsin(o)));
        return symbol_key(lsin(o));
}

@ @c
cell
env_get_root (cell o)
{
        assert(environment_p(o));
        while (!env_root_p(o))
                o = env_previous(o);
        return o;
}

@ @d root_search(L,R) (env_search(Root, (L), (R)))
@c
error_code
env_search (cell  o,
            cell  label,
            cell *ret)
{
        cell tmp;
        hash key;
        error_code reason;

        if (!environment_p(o) || !symbol_p(label))
                return LERR_INCOMPATIBLE;
        key = symbol_key(label);
        for (; !null_p(o); o = env_previous(o)) {
                orreturn(hashtable_search(env_layer(o), key,
                        env_match, (void *) label, &tmp));
                if (defined_p(tmp)) {
                        *ret = ldex(tmp); /* May be |UNDEFINED|! */
                        return LERR_NONE;
                }
        }
        *ret = UNDEFINED;
        return LERR_NONE;
}

@ @c
error_code
env_save_m (cell o,
            cell label,
            cell value,
            bool replace)
{
        cell tmp;
        error_code reason;

        if (!environment_p(o) || !symbol_p(label) || undefined_p(value))
                return LERR_INCOMPATIBLE;
        orreturn(cons(label, value, &tmp));
        return hashtable_save_m(env_layer(o), symbol_key(label), tmp,
                env_rehash, env_match, (void *) label, replace, true);
}

@* Run-time \AM\ Primitives.

An instruction address is simply a disguised pointer. TODO: account
for different word sizes.

@.TODO@>
@d PROGRAM_INVALID     UINTPTR_MAX /* Yes, it's yet another |NULL|. */
@<Type def...@>=
typedef uintptr_t address; /* |void *| would also be acceptable but for
                                arithmetic. */
@#
typedef int32_t instruction;

@
@d primitive(O)               (fixed_value(lsin(O)))
@d primitive_label(O)         (ldex(O))
@d primitive_object(O)        (&Primitive[primitive(O)])
@d primitive_applicative_p(O) (primitive_p(O)@|
        && primitive_object(O)->schema[0] >= '0'
        && primitive_object(O)->schema[0] <= '9')
@d primitive_operative_p(O)   (primitive_p(O) && !primitive_applicative_p(O))
@<Type def...@>=
typedef enum {
        PRIMITIVE_PAIR_P,
        PRIMITIVE_SYMBOL_P,
        PRIMITIVE_LENGTH
} primitive_code;

typedef struct {
        cell  owner; /* Heap storage. */
        error_code (*action)(cell, cell *);
        char *schema; /* \Ls/ binding \AM\ signature. */
} primitive_table;

@ @<Global...@>=
primitive_table Primitive[] = {
        @<Primitive schemata@>
};

@ @<Extern...@>=
extern primitive_table Primitive[];

@ @<Populate...@>=
for (i = 0; i < PRIMITIVE_LENGTH; i++) {
        orreturn(new_symbol_const(Primitive[i].schema + 4, &ltmp));
        orreturn(new_atom(fix(i), ltmp, FORM_PRIMITIVE, &Primitive[i].owner));
        orreturn(env_save_m(Root, ltmp, Primitive[i].owner, false));
}

@ @<Fun...@>=
error_code primitive_predicate (cell, cell *);
error_code primitive_search (cell, cell *);

@ @c
error_code
primitive_search (cell  o,
                  cell *ret)
{
        global_search(o, primitive_p, ret)@;
}

@ @<Primitive...@>=
[PRIMITIVE_PAIR_P]   = { NIL, primitive_predicate, "11__pair?" },@/
[PRIMITIVE_SYMBOL_P] = { NIL, primitive_predicate, "11__symbol?" },@/

@ @d primitive_call(O,R) primitive_object(O)->action((O), (R))
@c
error_code
primitive_predicate (cell  o,
                     cell *ret)
{
        bool answer;
        cell value;
        error_code reason;

        assert(primitive_p(o));
        assert(primitive_object(o)->schema[0] == '1'
                && primitive_object(o)->schema[1] == '1');
        orreturn(clink_pop(&Control_Link, &value));
        switch (primitive(o)) {
        case PRIMITIVE_PAIR_P: answer = pair_p(value);@+ break;
        case PRIMITIVE_SYMBOL_P: answer = symbol_p(value);@+ break;
        }
        *ret = predicate(answer);
        return LERR_NONE;
}

@* Segmented \CEE/ Object Wrapper.

TODO: Should be build on record for so cells can be associated with
\CEE/ objects. The main point of SCOW is registering the shape of
an object type in a global namespace; segment/larry/record provide
the storage layout.

@d LSCOW_PTHREAD_T 0
@<Type def...@>=
typedef struct {
        int length, align;
} scow;

@ @<Fun...@>=
error_code register_scow (int, int, int *);
error_code new_scow (int, intmax_t, cell *);
bool scow_id_p (cell, int);
half scow_length (cell);

@ @<Global...@>=
shared scow *SCOW_Attributes = NULL;
shared int SCOW_Length = 1;

@ @<Extern...@>=
extern shared scow *SCOW_Attributes;
extern shared int SCOW_Length;

@ @<Finish init...@>=
orabort(mem_alloc(NULL, SCOW_Length * sizeof (scow), 0,
        (void **) &SCOW_Attributes));
SCOW_Attributes[LSCOW_PTHREAD_T].length = sizeof (osthread); /* Wrapper around
                                                                |pthread_t|. */
SCOW_Attributes[LSCOW_PTHREAD_T].align = sizeof (void *);

@ @c
error_code
register_scow (int  length,
               int  align,
               int *ret)
{
        error_code reason;

        if (SCOW_Length == INT_MAX)
                return LERR_LIMIT;
        orreturn(mem_alloc(SCOW_Attributes, (SCOW_Length + 1) * sizeof (scow),
                sizeof (void *), (void **) &SCOW_Attributes));
        *ret = SCOW_Length++;
        SCOW_Attributes[*ret].length = length;
        SCOW_Attributes[*ret].align = align;
        return LERR_NONE;

}

@ TODO: Adapt interned segments so length is |scow_id|?

@.TODO@>
@d scow_object(O)       (segment_base(O))
@d scow_scid(O)         (pointer_datum(O))
@d scow_set_scid(O,V)   (pointer_set_datum_m((O), (V)))
@c
error_code
new_scow (int       scid,
          intmax_t  length,
          cell     *ret)
{
        cell lscid;
        scow *sdb;
        error_code reason;

        assert(scid >= 0 && scid < SCOW_Length);
        orreturn(new_int_c(scid, true, &lscid));
        sdb = SCOW_Attributes + scid;
        orreturn(new_segment_imp(Heap_Thread, length, sdb->length,
                sdb->align, FORM_CSTRUCT, FORM_NONE, ret));
        scow_set_scid(*ret, lscid);
        return LERR_NONE;
}

@ @c
bool
scow_id_p (cell o,
           int  scid)
{
        intmax_t iscid;
        error_code reason;

        if (!cstruct_p(o))
                return false;
        reason = int_value(scow_scid(o), &iscid);
        assert(!failure_p(reason));
        return iscid == scid;
}

@ @c
half
scow_length (cell o)
{
        intmax_t iscid;
        error_code reason;

        assert(cstruct_p(o));
        reason = int_value(scow_scid(o), &iscid);
        assert(!failure_p(reason));
        return segment_length(o) / SCOW_Attributes[iscid].length;
}

@** I/O.

@* File Descriptors. File descriptors do not need a SCOW. On unix
they're a (non-negative) |int|, on Windows an opaque |HANDLE| object,
and also on anything else, something which will most likely fit
within an atom.

However they are a global resource which needs to be tracked.

@d FILE_HANDLE_BUFFER_LENGTH 512
@<Global...@>=
shared cell *Files = NULL; /* All the objects holding a file descriptor. */
shared int Files_Length = 0; /* ... and how many there are. */
shared pthread_mutex_t Files_Lock;

@ @<Extern...@>=
extern shared cell *Files;
extern shared int Files_Length;
extern shared pthread_mutex_t Files_Lock;

@ @<Fun...@>=
error_code new_file_handle (int, cell *);
error_code file_handle_close_m (cell);
error_code file_handle_get (cell, int *, cell *);
error_code file_handle_read_word (cell, int, cell *);
error_code file_handle_release (cell);

@ What if 0/1/2 come in closed?

@<Finish init...@>=
orabort(mem_alloc(NULL, 3 * sizeof (cell), 0, (void **) &Files));
for (i = 0; i < 3; i++)
        Files[i] = NIL;
Files_Length = 3;
orabort(new_file_handle(0, Files + 0));
orabort(new_file_handle(1, Files + 1));
orabort(new_file_handle(2, Files + 2));

@ @d file_handle_id(O) (lsin(O))
@d file_handle_state(O) (ldex(O))
@c
error_code
new_file_handle (int   fd,
                 cell *ret)
{
        cell newfd;
        error_code reason;

        if (fd < 0)
                return LERR_INCOMPATIBLE;
        if (fd < Files_Length && !null_p(Files[fd]))
                return LERR_EXISTS;
        reason = LERR_NONE;
        orreturn(new_atom(fd, NIL, FORM_FILE_HANDLE, &newfd));
        if (pthread_mutex_lock(&Files_Lock) != 0)
                return LERR_INTERNAL;
        if (fd >= Files_Length)
                ortrap(mem_alloc(Files, (fd + 1) * sizeof (cell), 0,
                        (void **) &Files));
        for (; Files_Length <= fd; Files_Length++)
                Files[Files_Length] = NIL;
        assert(Files_Length > fd);
        *ret = Files[fd] = newfd;
Trap:
        pthread_mutex_unlock(&Files_Lock);
        return reason;
}

@ |Files_Lock| must be locked by the caller.

@c
error_code
file_handle_release (cell o)
{
        intmax_t fd, pfd;
        error_code reason;

        if (!file_handle_p(o))
                return LERR_INCOMPATIBLE;
        orreturn(int_value(o, &fd));

                pfd = (fd >= 0) ? fd : -(fd + 1);
        if (Files_Length <= pfd || Files[pfd] != o)
                return LERR_INTERNAL;

        if (true_p(file_handle_state(o))) {
                Files[pfd] = VOID; /* Not closed properly. */
                return LERR_LEAK;
        } else {
                Files[pfd] = NIL;
                return LERR_NONE;
        }
}

@ @c
error_code
file_handle_close_m (cell o)
{
        cell lfd, lneg;
        intmax_t fd;
        bool tried;
        error_code reason;

        if (!file_handle_p(o))
                return LERR_INCOMPATIBLE;
        if (fixed_p(file_handle_id(o))
                    && false_p(file_handle_state(o)))
                return LERR_UNOPENED_CLOSE;
        reason = LERR_NONE;
        tried = false;
        orassert(file_handle_get(o, NULL, &lfd));
        orassert(int_value(lfd, &fd));
        if (fd < 0)
                return LERR_BUSY;
        assert(fd <= Files_Length);
        if (Files[fd] != o)
                return LERR_INTERNAL;
        orreturn(new_int_c(-(fd + 1), true, &lneg));
        if (pthread_mutex_lock(&Files_Lock) != 0)
                return LERR_INTERNAL;
        orassert(lsin_set_m(o, lneg));
        orassert(ldex_set_m(o, LFALSE));
        pthread_mutex_unlock(&Files_Lock);
again:
        if (close(fd) == -1)
                switch (errno) {
                case EBADF:
                        reason = LERR_INTERNAL;
                        goto Trap;
                case EINTR:
                        if (!tried) {
                                tried = true;
                                goto again;
                        } else {
                                reason = LERR_INTERRUPT;
                                goto Trap;
                        }
                case EIO:
                        reason = LERR_IO;
                        goto Trap;
                }
        orassert(file_handle_release(o)); /* ie.~|Files[fd] = NIL|. */
Trap:
        if (pthread_mutex_lock(&Files_Lock) != 0)
                return LERR_INTERNAL;
        orassert(lsin_set_m(o, lfd)); /* It'll be GCd soon though. */
        if (failure_p(reason))
                orassert(ldex_set_m(o, LTRUE));
        pthread_mutex_unlock(&Files_Lock);
        return reason;
}

@ Normally the file descriptor is stored as-is but is flipped into
a negative number internally when the file handle is being operated
on.

@c
error_code
file_handle_get (cell  o,
                 int  *iret,
                 cell *cret)
{
        cell i;
        int v;
        error_code reason;

        assert(!(iret != NULL && cret != NULL));
        assert(iret != NULL || cret != NULL);
        if (!file_handle_p(o))
                return LERR_INCOMPATIBLE;
        if (iret == NULL)
                iret = &v;
        *iret = file_handle_id(o);
        if (*iret < 0)
                *iret = -(*iret - 1);
        if (cret == NULL)
                return LERR_NONE;
@#
        orreturn(new_int_c(*iret, true, &i));
        if (*iret < 0)
                *cret = i;
        else {
                orreturn(int_abs(i, &i));
                orreturn(int_sub(i, fix(1), cret));
        }
        return LERR_NONE;
}

@ @c @.TODO@>
error_code
file_handle_read_word (cell  o,
                       int   length,
                       cell *ret)
{
        atom got = {0};
        cell new;
        char *base;
        int fd, rret;
        error_code reason;

        if (length < 1 || length > ATOM_BYTES)
                return LERR_INCOMPATIBLE;

        orreturn(file_handle_get(o, &fd, NULL));
        orreturn(new_word(0, 0, &new));
        base = (char *) &got;
        errno = 0;
        rret = read(fd, base, length);
        if (rret == 0)
                return LERR_EOF;
        *ret = new;
        *((atom *) (*ret)) = got;
        if (rret == length)
                return LERR_NONE;
        switch (errno) {
        default:@;
        case 0:
                ((char *) (*ret))[CELL_BYTES - 1] = rret;
                return LERR_EOF;
        case EFAULT:@; /* Part of buf points outside the process's allocated address space. */
        case EINVAL:@; /* |max_length| was larger than |SSIZE_MAX|. */
                /* impossible... */
        case EBADF:@; /* not a valid file or socket descriptor open for reading. */
        case ENOTCONN:@; /* The connection-oriented socket has not been connected. */
                return LERR_INTERNAL; /* TODO: save |errno|. */
        case EIO:@; /* An I/O error occurred while reading from the file system. */
        case EISDIR:@; /* The underlying file is a directory. */
                return LERR_IO; /* TODO: save |errno|. */
        case EINTR:@; /* A read from a slow device was interrupted by a
                                        signal before any data arrived. */
                return LERR_INTERRUPT;
        case EAGAIN:@; /* The file was marked for non-blocking I/O, and no
                                        data were ready to be read. */
                return LERR_BUSY;
        }
}

@** Threads.

@<Fun...@>=
error_code init_osthread_mutex (pthread_mutex_t *, bool, bool);
error_code new_osthread (cell, address, heap_access *, cell *);
void * osthread_main (void *);
error_code osthread_wait (cell, cell *);

@ @<Global...@>=
shared cell *Thread_DB = NULL;
shared int Thread_DB_Length = 0;
shared pthread_mutex_t Thread_DB_Lock;
shared pthread_barrier_t Thready;

@ @<Extern...@>=
extern shared cell *Thread_DB;
extern shared int Thread_DB_Length;
extern shared pthread_mutex_t Thread_DB_Lock;
extern shared pthread_barrier_t Thready;

@ @<Finish init...@>=
orabort(init_osthread_mutex(&Thread_DB_Lock, false, true));
if (pthread_barrier_init(&Thready, NULL, 2))
        just_abort(LERR_INTERNAL, "failed to intialise Thread Ready barrier");
orabort(mem_alloc(NULL, Thread_DB_Length * sizeof (cell), 0,
        (void **) &Thread_DB));

@ @<Type def...@>=
struct osthread {
 struct osthread  *next, *prev;
        heap_pun  *root;
        cell       ret;
        cell       owner; /* A segment (scow). */
        pthread_t  tobj;
        address    ip;
        bool       pending;
};
typedef struct osthread osthread;

@ @<Global...@>=
shared osthread *Threads = NULL;

@ @<Extern...@>=
extern shared osthread *Threads;

@ Errors: |EINVAL|, attributes are invalid, or |ENOMEM|.

@c
error_code
init_osthread_mutex (pthread_mutex_t *mx,
                     bool             recursive,
                     bool             robust @[unused@])
{
        pthread_mutexattr_t mutex_attr;

        pthread_mutexattr_init(&mutex_attr);
        pthread_mutexattr_settype(&mutex_attr, recursive
                ? PTHREAD_MUTEX_RECURSIVE : PTHREAD_MUTEX_ERRORCHECK);
#ifdef pthread_mutexattr_setrobust
        if (robust)
                pthread_mutexattr_setrobust(&mutex_attr, PTHREAD_MUTEX_ROBUST);
#endif /* |pthread_mutexattr_setrobust| */
        if (pthread_mutex_init(mx, &mutex_attr) != 0)
                return LERR_OOM;
        return LERR_NONE;
}

@ Also function pointers for GC and more; collect into a struct
pointer/object?

@c
error_code
new_osthread (cell         thread_attr,
              address      new_ip,
              heap_access *heap_attr,
              cell        *ret)
{
        cell thread_box;
        int rv;
        intmax_t start_address;
        osthread *new_thread;
        segment *heap_segment;
        error_code reason;

        if (!null_p(thread_attr)) /* | && !thread_attributes_p(thread_attr)| */
                return LERR_INCOMPATIBLE;
@#
        orreturn(new_scow(LSCOW_PTHREAD_T, -1, &thread_box));
        new_thread = (osthread *) scow_object(thread_box);
        new_thread->owner = thread_box;
        new_thread->pending = false;
@#
        orreturn(alloc_segment(-HEAP_CHUNK, 1, HEAP_CHUNK, &heap_segment));
        new_thread->root = (heap_pun *) SEGMENT_TO_HEAP(heap_segment);
        orreturn(heap_attr->init((heap *) new_thread->root, NULL, NULL, NULL));
        orreturn(mem_alloc(NULL, sizeof (heap_access),
                sizeof (void *),@| (void **) &new_thread->root->fun));
        new_thread->root->fun = heap_attr;
@#
        orreturn(int_value(new_ip, &start_address));
        if (start_address < 0 || start_address >= (intmax_t) PROGRAM_INVALID)
                new_thread->ip = PROGRAM_INVALID;
        else
                new_thread->ip = start_address;
@#
        rv = pthread_mutex_lock(&Thread_DB_Lock);
        switch (rv) {
#ifdef pthread_mutexattr_setrobust
        case EOWNERDEAD:
                return LERR_INTERNAL;
                /* What do? Impossible? */
#endif /* |pthread_mutexattr_setrobust| */
        case EDEADLK:
                return LERR_INTERNAL;
        default:
                return LERR_INTERNAL;
        case 0:
                break;
        }
        if (Threads == NULL)
                Threads = new_thread->next = new_thread->prev = new_thread;
        else {
                new_thread->next = Threads;
                new_thread->prev = Threads->prev;
                Threads->prev->next = new_thread;
                Threads->prev = new_thread;
        }
        rv = pthread_create(&new_thread->tobj, NULL, osthread_main,
                (void *) thread_box);
        switch (rv) {
        case 0:
                new_thread->pending = true;
                pthread_barrier_wait(&Thready);
                *ret = thread_box;
                reason = LERR_NONE;
        case EAGAIN:
                reason = LERR_LIMIT;
        case EINVAL:
                reason = LERR_INCOMPATIBLE;
        default:
                reason = LERR_INTERNAL;
        }
        pthread_mutex_unlock(&Thread_DB_Lock);
        return reason;
}

@ @c
void *
osthread_main (void *carg)
{
        osthread *thread_box;
        error_code reason;

        thread_box = (osthread *) scow_object((cell) carg);
        ortrap(mem_init_thread());
        if (!special_p(Accumulator))
                ; // |Accumulator| Needs copying to |Heap_Shared|.
        Control_Link = NIL;
        ; // |Environment|?
        VM_Arg1 = VM_Arg2 = VM_Result = NIL;
        Trap_Arg1 = Trap_Arg2 = Trap_Result = NIL;
        Ip = thread_box->ip;
        Trap_Ip = PROGRAM_INVALID;
        Trapped = false;
        ; // |Trap_Handler|?
        Heap_Thread = (heap *) thread_box->root;
        Heap_Trap = NULL;
        pthread_barrier_wait(&Thready);
        interpret();
        pthread_exit((void *) (intptr_t) LERR_NONE);

Trap:
        pthread_barrier_wait(&Thready);
        pthread_exit((void *) (intptr_t) reason);
}

@ @c
error_code
osthread_wait (cell  o,
               cell *ret)
{
        osthread *thread_box;
        void *prv;
        error_code reason;

        if (!scow_id_p(o, LSCOW_PTHREAD_T))
                return LERR_INCOMPATIBLE;
        thread_box = (osthread *) scow_object(o);
        if (!thread_box->pending)
                return LERR_FINISHED;
        switch (pthread_join(thread_box->tobj, &prv)) {
                case 0:
                        thread_box->pending = false;
                        *ret = thread_box->ret;
                        reason = (error_code) (intptr_t) prv;
                        break;
                case EDEADLK:
                        *ret = UNDEFINED;
                        reason = LERR_SELF;
                        break;
                case EINVAL:
                case ESRCH:
                        *ret = UNDEFINED;
                        reason = LERR_INTERNAL;
                        break;
        }
        return reason;
}

@** Virtual Machine. There are 40-something general registers. I
don't know what to do with them all.

@d LR_r0             0
@d LR_r1             1
@d LR_r2             2
@d LR_r3             3
@d LR_r4             4
@d LR_r5             5
@d LR_r6             6
@d LR_r7             7
@d LR_r8             8
@d LR_r9             9
@d LR_r10           10
@d LR_r11           11
@d LR_r12           12
@d LR_r13           13
@d LR_r14           14
@d LR_r15           15
@d LR_r16           16
@d LR_r17           17
@d LR_r18           18
@d LR_r19           19
@d LR_r20           20
@d LR_r21           21
@d LR_r22           22
@d LR_r23           23
@d LR_r24           24
@d LR_r25           25
@d LR_r26           26
@d LR_r27           27
@d LR_r28           28
@d LR_r29           29
@d LR_r30           30
@d LR_r31           31
@d LR_r32           32
@d LR_r33           33
@d LR_r34           34
@d LR_r35           35
@d LR_r36           36
@d LR_r37           37
@d LR_r38           38
@d LR_r39           39
@d LR_r40           40
@d LR_r41           41
@d LR_r42           42
@d LR_r43           43
@d LR_r44           44
@d LR_GENERAL       44

@ 17 registers are used by the virtual machine including 4 which
aren't a normal cell; these are defined later.

Of the 13 cell registers 4 have been introduced already: the symbol
table and three heaps. The remaining registers are defined here and
also the per-thread array of pointers to them which is used by the
garbage collector.

``Missing'' registers: |Root|, |SCOW_Attributes|, |Threads|.


@d LR_Accumulator   45
@d LR_Argument_List 46
@d LR_Control_Link  47 /* Special: push/pop */
@d LR_Environment   48 /* Typed: environment? */
@d LR_Expression    49
@d LR_Heap_Shared   50 /* Typed: heap */
@d LR_Heap_Thread   51 /* Typed: heap */
@d LR_Heap_Trap     52 /* Typed: heap */
@d LR_Symbol_Table  53 /* RO: hash table */
@d LR_Arg1          54
@d LR_Arg2          55
@d LR_Result        56
@d LR_Trap_Arg1     57
@d LR_Trap_Arg2     58
@d LR_Trap_Result   59
@d LR_CELL          59
@#
@d LR_Ip            60 /* RO: Pseudo int */
@d LR_Trap_Handler  61 /* RO: Pseudo array */
@d LR_Trap_Ip       62 /* RO: Pseudo int */
@d LR_Trapped       63 /* RO: Pseudo bool */
@d LR_SPECIAL       63
@d LR_LENGTH        64 /* $2^6$ */
@<Global...@>=
unique cell *Register[LR_CELL + 1] = {0};
@#
unique cell Accumulator = NIL;
unique cell Argument_List = NIL;
unique cell Control_Link = NIL;
unique cell Environment = NIL;
unique cell Expression = NIL;
shared cell Root = NIL;
unique cell Trap_Arg1 = NIL;
unique cell Trap_Arg2 = NIL;
unique cell Trap_Result = NIL;
unique cell VM_Arg1 = NIL;
unique cell VM_Arg2 = NIL;
unique cell VM_Result = NIL;

@ @<Extern...@>=
extern unique cell *Register[];
extern unique cell Accumulator, Argument_List, Control_Link, Environment,
        Expression, Trap_Arg1, Trap_Arg2, Trap_Result, VM_Arg1, VM_Arg2,
        VM_Result;
extern shared cell Root;

@ @<Type def...@>=
typedef int vm_register; /* |register| is a \CEE/ reserved word. */

typedef struct {
        cell  owner;
        char *label;
} register_table;

@ @<Global...@>=
shared register_table Register_Table[LR_LENGTH] = {
        [LR_Accumulator]  = { NIL, "VM:Accumulator" },@|
        [LR_Argument_List]= { NIL, "VM:Argument-List" },@|
        [LR_Control_Link] = { NIL, "VM:Control-Link" },@|
        [LR_Environment]  = { NIL, "VM:Environment" },@|
        [LR_Expression]   = { NIL, "VM:Expression" },@|
        [LR_Heap_Shared]  = { NIL, "VM:Heap-Shared" },@|
        [LR_Heap_Thread]  = { NIL, "VM:Heap-Thread" },@|
        [LR_Heap_Trap]    = { NIL, "VM:Heap-Trap" },@|
        [LR_Symbol_Table] = { NIL, "VM:Symbol-Table" },@|
        [LR_Trap_Arg1]    = { NIL, "VM:Trap-Arg1" },@|
        [LR_Trap_Arg2]    = { NIL, "VM:Trap-Arg2" },@|
        [LR_Trap_Result]  = { NIL, "VM:Trap-Result" },@|
        [LR_Arg1]         = { NIL, "VM:Arg1" },@|
        [LR_Arg2]         = { NIL, "VM:Arg2" },@|
        [LR_Result]       = { NIL, "VM:Result" },@|
        [LR_Trap_Ip]      = { NIL, "VM:Trap-Ip", },@|
        [LR_Trapped]      = { NIL, "VM:Trapped", },@|
        [LR_Trap_Handler] = { NIL, "VM:Trap-Handler" },@|
        [LR_Ip]           = { NIL, "VM:Ip" },@|

@#
        [LR_r0]           = { NIL, "VM:R0" },@|
        [LR_r1]           = { NIL, "VM:R1" },@|
        [LR_r2]           = { NIL, "VM:R2" },@|
        [LR_r3]           = { NIL, "VM:R3" },@|
        [LR_r4]           = { NIL, "VM:R4" },@|
        [LR_r5]           = { NIL, "VM:R5" },@|
        [LR_r6]           = { NIL, "VM:R6" },@|
        [LR_r7]           = { NIL, "VM:R7" },@|
        [LR_r8]           = { NIL, "VM:R8" },@|
        [LR_r9]           = { NIL, "VM:R9" },@|
        [LR_r10]          = { NIL, "VM:R10" },@|
        [LR_r11]          = { NIL, "VM:R11" },@|
        [LR_r12]          = { NIL, "VM:R12" },@|
        [LR_r13]          = { NIL, "VM:R13" },@|
        [LR_r14]          = { NIL, "VM:R14" },@|
        [LR_r15]          = { NIL, "VM:R15" },@|
        [LR_r16]          = { NIL, "VM:R16" },@|
        [LR_r17]          = { NIL, "VM:R17" },@|
        [LR_r18]          = { NIL, "VM:R18" },@|
        [LR_r19]          = { NIL, "VM:R19" },@|
        [LR_r20]          = { NIL, "VM:R20" },@|
        [LR_r21]          = { NIL, "VM:R21" },@|
        [LR_r22]          = { NIL, "VM:R22" },@|
        [LR_r23]          = { NIL, "VM:R23" },@|
        [LR_r24]          = { NIL, "VM:R24" },@|
        [LR_r25]          = { NIL, "VM:R25" },@|
        [LR_r26]          = { NIL, "VM:R26" },@|
        [LR_r27]          = { NIL, "VM:R27" },@|
        [LR_r28]          = { NIL, "VM:R28" },@|
        [LR_r29]          = { NIL, "VM:R29" },@|
        [LR_r30]          = { NIL, "VM:R30" },@|
        [LR_r31]          = { NIL, "VM:R31" },@|
        [LR_r32]          = { NIL, "VM:R32" },@|
        [LR_r33]          = { NIL, "VM:R33" },@|
        [LR_r34]          = { NIL, "VM:R34" },@|
        [LR_r35]          = { NIL, "VM:R35" },@|
        [LR_r36]          = { NIL, "VM:R36" },@|
        [LR_r37]          = { NIL, "VM:R37" },@|
        [LR_r38]          = { NIL, "VM:R38" },@|
        [LR_r39]          = { NIL, "VM:R39" },@|
        [LR_r40]          = { NIL, "VM:R40" },@|
        [LR_r41]          = { NIL, "VM:R41" },@|
        [LR_r42]          = { NIL, "VM:R42" },@|
        [LR_r43]          = { NIL, "VM:R43" },@|
        [LR_r44]          = { NIL, "VM:R44" },@|
};

@ @<Extern...@>=
extern shared register_table Register_Table[];

@ @<(Re-)Initialise per thread@>=
Register[LR_Accumulator] = &Accumulator;
Register[LR_Argument_List] = &Argument_List;
Register[LR_Environment] = &Environment;
Register[LR_Expression] = &Expression;
Register[LR_Control_Link] = &Control_Link;
Register[LR_Arg1] = &VM_Arg1;
Register[LR_Arg2] = &VM_Arg2;
Register[LR_Result] = &VM_Result;
Register[LR_Trap_Arg1] = &Trap_Arg1;
Register[LR_Trap_Arg2] = &Trap_Arg2;
Register[LR_Trap_Result] = &Trap_Result;

@ @<Finish init...@>=
orabort(new_empty_env(&Root));
Environment = Root;

@
@d register_id(O)     (lsin(O))
@d register_label(O)  (ldex(O))
@d register_object(O) (&Register_Table[register_id(O)])
@<Fun...@>=
error_code register_search (cell, cell *);

@ @<Finish init...@>=
for (i = 0; i < LR_LENGTH; i++) {
        orabort(new_symbol_const(Register_Table[i].label, &ltmp));
        orabort(new_atom(i, ltmp, FORM_REGISTER, &Register_Table[i].owner));
}

@ @<Populate the |Root| environment@>=
for (i = 0; i < LR_LENGTH; i++) {
        ltmp = register_label(Register_Table[i].owner);
        orreturn(env_save_m(Root, ltmp, Register_Table[i].owner, false));
}

@ Three commonly-used registers are bound to an additional short
names for convenience.

@<Populate the |Root| environment@>=
orabort(new_symbol_const("VM:Acc", &ltmp));
orabort(env_save_m(Root, ltmp, Register_Table[LR_Accumulator].owner, false));
orabort(new_symbol_const("VM:Args", &ltmp));
orabort(env_save_m(Root, ltmp, Register_Table[LR_Argument_List].owner, false));
orabort(new_symbol_const("VM:Clink", &ltmp));
orabort(env_save_m(Root, ltmp, Register_Table[LR_Control_Link].owner, false));
orabort(new_symbol_const("VM:Env", &ltmp));
orabort(env_save_m(Root, ltmp, Register_Table[LR_Environment].owner, false));
orabort(new_symbol_const("VM:Expr", &ltmp));
orabort(env_save_m(Root, ltmp, Register_Table[LR_Expression].owner, false));

@ @c
error_code
register_search (cell  o,
                 cell *ret)
{
        global_search(o, register_p, ret)@;
}

@ Opcodes work similarly to registers. These could probably be
organised more efficiently.

@<Type def...@>=
typedef enum {
        OP_ADD,
        OP_APPLICATIVE,
        OP_CAR,
        OP_CDR,
        OP_CMP,
        OP_CMPEQ,
        OP_CMPGE,
        OP_CMPGT,
        OP_CMPIS,
        OP_CMPLE,
        OP_CMPLT,
        OP_CONS,
        OP_DEFINE_M,
        OP_DELIMIT,
        OP_EXTEND,
        OP_HALT,
        OP_JOIN,
        OP_JUMP,
        OP_LOAD,
        OP_LOOKUP,
        OP_OPEN,
        OP_OPERATIVE,
        OP_PEND,
        OP_REPLACE_M,
        OP_SLO,
        OP_SPORK,
        OP_SUB,
        OP_TEST,
        OP_TRAP,
        OP_WIDESPORK,
        OP_WIDETEST,
        OPCODE_LENGTH
} opcode;

typedef struct {
        cell   owner;
        char  *label;
        char   arg0;
        char   arg1;
        char   arg2;
} opcode_table;

@ Sorted first by length, then alphabetically, because CWEB can't
(?) align code in columns.

Of the arguments which accept |ALOT| in the first place, only
|OP_JOIN| can use anything other than a register.

|OP_TRAP| reads a symbol in the assembly and stores it as an integer
in the bytecode, a la register/opcode.

|OP_HALT| is the only other unusual opcode with no arguments.
Everything else takes 1 or 2 and saves the result in a register.

|OP_SPORK| and |OP_TEST| should only be used to jump to symbolic
addresses if the symbols are guaranteed to be in the first $2^{16}$
exported symbols.

@d NARG 0 /* No argument. */
@d AADD 1 /* An address. */
@d ALOB 2 /* An \Ls/ object. */
@d ALOT 3 /* A tiny \Ls/ object. */
@d AREG 4 /* A register. */
@d ARGH 5 /* A trap code (symbol, encoded as an 8-bit iny). */
@<Global...@>=
shared opcode_table Op[OPCODE_LENGTH] = {@|
        [OP_APPLICATIVE]= { NIL, "VM:APPLICATIVE",  AREG, ALOT, ALOT },@|
        [OP_OPERATIVE]  = { NIL, "VM:OPERATIVE",    AREG, ALOT, ALOT },@|
        [OP_REPLACE_M]  = { NIL, "VM:REPLACE!",     AREG, ALOT, ALOT },@|
        [OP_WIDESPORK]  = { NIL, "VM:WIDESPORK",    AADD, NARG, NARG },@|
        [OP_DEFINE_M]   = { NIL, "VM:DEFINE!",      AREG, ALOT, ALOT },@|
        [OP_WIDETEST]   = { NIL, "VM:WIDETEST",     AADD, NARG, NARG },@|
        [OP_DELIMIT]    = { NIL, "VM:DELIMIT",      AREG, NARG, NARG },@|
        [OP_EXTEND]     = { NIL, "VM:EXTEND",       AREG, ALOB, NARG },@|
        [OP_LOOKUP]     = { NIL, "VM:LOOKUP",       AREG, ALOB, NARG },@|
        [OP_CMPEQ]      = { NIL, "VM:CMPEQ?",       AREG, ALOT, ALOT },@|
        [OP_CMPGE]      = { NIL, "VM:CMPGE?",       AREG, ALOT, ALOT },@|
        [OP_CMPGT]      = { NIL, "VM:CMPGT?",       AREG, ALOT, ALOT },@|
        [OP_CMPIS]      = { NIL, "VM:CMPIS?",       AREG, ALOT, ALOT },@|
        [OP_CMPLE]      = { NIL, "VM:CMPLE?",       AREG, ALOT, ALOT },@|
        [OP_CMPLT]      = { NIL, "VM:CMPLT?",       AREG, ALOT, ALOT },@|
        [OP_SPORK]      = { NIL, "VM:SPORK",        AREG, AADD, NARG },@|
        [OP_CONS]       = { NIL, "VM:CONS",         AREG, ALOT, ALOT },@|
        [OP_HALT]       = { NIL, "VM:HALT",         NARG, NARG, NARG },@|
        [OP_JOIN]       = { NIL, "VM:JOIN",         AREG, ALOB, NARG },@|
        [OP_JUMP]       = { NIL, "VM:JUMP",         AADD, NARG, NARG },@|
        [OP_LOAD]       = { NIL, "VM:LOAD",         AREG, ALOB, NARG },@|
        [OP_OPEN]       = { NIL, "VM:OPEN",         AREG, ALOB, NARG },@|
        [OP_PEND]       = { NIL, "VM:PEND",         AREG, AADD, NARG },@|
        [OP_TEST]       = { NIL, "VM:TEST",         AREG, AADD, NARG },@|
        [OP_TRAP]       = { NIL, "VM:TRAP",         ARGH, NARG, NARG },@|
        [OP_ADD]        = { NIL, "VM:ADD",          AREG, ALOT, ALOT },@|
        [OP_CAR]        = { NIL, "VM:CAR",          AREG, ALOB, NARG },@|
        [OP_CDR]        = { NIL, "VM:CDR",          AREG, ALOB, NARG },@|
        [OP_CMP]        = { NIL, "VM:CMP",          AREG, ALOT, ALOT },@|
        [OP_SLO]        = { NIL, "VM:SLO",          AREG, ALOB, NARG },@|
        [OP_SUB]        = { NIL, "VM:SUB",          AREG, ALOT, ALOT },@/
};

@ @<Extern...@>=
extern shared opcode_table Op[];

@
@d opcode_id(O)        (lsin(O))
@d opcode_label(O)     (ldex(O))
@d opcode_object(O)    (&Op[opcode_id(O)])
@d opcode_signature(O) (&(Op[opcode_id(O)].arg0))
@<Fun...@>=
error_code opcode_search (cell, cell *);

@ @<Finish init...@>=
for (i = 0; i < OPCODE_LENGTH; i++) {
        orabort(new_symbol_const(Op[i].label, &ltmp));
        orabort(new_atom(i, ltmp, FORM_OPCODE, &Op[i].owner));
}

@ @<Populate the |Root| environment@>=
for (i = 0; i < OPCODE_LENGTH; i++)
        orreturn(env_save_m(Root, opcode_label(Op[i].owner), Op[i].owner, false));

@ Identical to |register_search| except for the result validation.

@c
error_code
opcode_search (cell  o,
               cell *ret)
{
        global_search(o, opcode_p, ret)@;
}

@ Instructions are encoded in 32 bits or 4 bytes. The opcode
categorises the arguments three ways (four if you include |OP_HALT|):
address, single-object and dual-object.

Two mode bits then identify how to interpret the remaining 3 bytes.

Addresses, 16 or 24 bit, may be direct --- either relative or offset
within the current 24-bit page --- or reference an offset in a
global 24-bit page where a full-width address is located.

Dual-object instructions use each mode bit to determine whether the
respective argument represents a register or an inline object. If
it's a register then the high bit indicates whether the value should
be obtained from the register by popping a stack.

Single-object instructions always include 6 bits identifying a
register in their target argument. The mode indentifies one of four
ways of interpreting the remaining 18 bits:

\yitem |LBC_OBJECT_CONSTANT| The low 16 bits are treated as a signed
integer (|int16_t|) holding the internal \Ls/ representation of a
constant (ie.~it will be 0 representing |NIL| or a negative number).

\yitem |LBC_OBJECT_INTEGER| The low 16 bits are similarly treated as a signed
integer, this time representing itself.

\yitem |LBC_OBJECT_REGISTER| The lowest 8 bits are ignored and the 8 above
it are interpreted as a register just like the first of a dual-argument
instruction.

\yitem |LBC_OBJECT_TABLE| The lowest 6 bits constitute an index. 12 bits
above that (including 2 from {\it above\/} the target register ---
see |TABL| in the diagram) a table ID. Tables are a process-global
resource allocated and populated when an assembly object is linked
which contain arbitrary objects.

These macros return the bits marked X shifted to the right.

TODO: Art.

@.TODO@>
@d IB0(I) 42
@#
@d ximOP(I)   (((I) & 0x3f000000) >> 24)   /* ..XXXXXX ........ ........ ........ */
@d ximMODE(I) (((I) & 0xc0000000) >> 30)   /* XX...... ........ ........ ........ */
@#
@d ximARG0(I) (((I) & 0x00ff0000) >> 16)   /* ........ XXXXXXXX ........ ........ */
@d ximREG0(I) (((I) & 0x003f0000) >> 16)   /* ........ ..XXXXXX ........ ........ */
@d ximPOP0(I) (((I) & 0x00800000) >> 23)   /* ........ X....... ........ ........ */
@#
@d ximARG1(I) (((I) & 0x0000ff00) >>  8)   /* ........ ........ XXXXXXXX ........ */
@d ximREG1(I) (((I) & 0x00003f00) >>  8)   /* ........ ........ ..XXXXXX ........ */
@d ximPOP1(I) (((I) & 0x00008000) >> 23)   /* ........ ........ X....... ........ */
@#
@d ximARG2(I) (((I) & 0x000000ff) >>  0)   /* ........ ........ ........ XXXXXXXX */
@d ximREG2(I) (((I) & 0x0000003f) >>  0)   /* ........ ........ ........ ..XXXXXX */
@d ximPOP2(I) (((I) & 0x00000080) >> 23)   /* ........ ........ ........ X....... */
@#
@d ximARGD(I) (((I) & 0x0000ffff) >>  0)   /* ........ ........ XXXXXXXX XXXXXXXX */
@d ximARGT(I) (((I) & 0x00ffffff) >>  0)   /* ........ XXXXXXXX XXXXXXXX XXXXXXXX */
@#
@d ximTTOP(I) (((I) & 0x00c00000) >> 22)   /* ........ XX...... ........ ........ */
@d ximTLEG(I) (((I) & 0x0000ffc0) >>  6)   /* ........ ........ XXXXXXXX XX...... */
@d ximTABL(I) ((ximTTOP(I) << 10) | ximTLEG(I))  /* ........ XX--><-- XXXXXXXX XX...... */
@d ximINDX(I) (((I) & 0x0000003f) >>  0)   /* ........ ........ ........ ..XXXXXX */
@#
@d ximADDD(I) (*(((uint16_t *) &(I)) + 1))
@d ximINTD(I) (*(((int16_t *) &(I)) + 1))
@d ximINT0(I) (*(((int8_t *) &(I)) + 1))
@d ximINT1(I) (*(((int8_t *) &(I)) + 2))
@d ximINT2(I) (*(((int8_t *) &(I)) + 3))
@#
@d TINY_MIN (-0x10)
@d TINY_MAX ( 0x0f)
@#
@# /* Lose these: */
@#
@d LBC_ADDRESS_DIRECT   0 /* Unsigned 16/24 bit offset. */
@d LBC_ADDRESS_INDIRECT 1 /* Unsigned 16/24 bit offset to |PROGRAM_EXPORT_BASE|
                                has pointer-size address. */
@d LBC_ADDRESS_RELATIVE 2 /* Signed 16 bit delta. */
@d LBC_ADDRESS_REGISTER 3 /* Integer in a register */
@d LBC_FIRST_REGISTER   2 /* These are not backwards. */
@d LBC_SECOND_REGISTER  1
@d LBC_OBJECT_CONSTANT  0 /* Small fixed integers also; ignore low byte */
@d LBC_OBJECT_INTEGER   1 /* 16 bit signed. */
@d LBC_OBJECT_REGISTER  2 /* Ignore low byte */
@d LBC_OBJECT_TABLE     3 /* Index into global table. */

@ The first special register is the instruction pointer.

@d OBJECTDB_SPLIT_BOTTOM 0x3ff
@d OBJECTDB_SPLIT_GAP    6
@d OBJECTDB_SPLIT_TOP    0xb00
@d OBJECTDB_TABLE_WIDTH  6
@d OBJECTDB_TABLE_LENGTH (1 << OBJECTDB_TABLE_WIDTH)
@d OBJECTDB_DB_WIDTH     (24 - (OBJECTDB_TABLE_WIDTH + 6))
@d OBJECTDB_DB_LENGTH    (1 << OBJECTDB_DB_WIDTH)
@d OBJECTDB_MAX          (OBJECTDB_TABLE_LENGTH * OBJECTDB_DB_LENGTH)
@#
@d PROGRAM_LENGTH      0x1000000ul /* $2^{24}$ */
@d PROGRAM_WIDTH       24
@d PROGRAM_KEY         (PROGRAM_LENGTH - 1)
@d PROGRAM_PAGE        (~PROGRAM_KEY)
@#
@d instruction_page(O) ((O) & PROGRAM_PAGE)
@<Global...@>=
unique address Ip = PROGRAM_INVALID; /* Current (or previous) instruction. */
shared cell ObjectDB = NIL;
shared int ObjectDB_Free = 0; /* Multiple of |OBJECTDB_TABLE_LENGTH|. */
shared cell Program_Export_Table = NIL;
shared address *Program_Export_Base = NULL;
shared address Program_Export_Free = 0;
shared pthread_mutex_t Program_Lock;

@ @<Extern...@>=
extern unique address Ip;
extern shared int ObjectDB_Free;
extern shared cell ObjectDB, Program_Export_Table;
extern shared address *Program_Export_Base, Program_Export_Free;
extern shared pthread_mutex_t Program_Lock;

@ @<Initialise memory...@>=
orabort(init_osthread_mutex(&Program_Lock, false, false));

@ TODO: Program allocations leak. No longer: This page is known by
its global pointer. Code pages refer to their heap owner which
refers back to them.

@.TODO@>
@<Finish init...@>=
orabort(new_array(0, fix(0), &ObjectDB));
orabort(mem_alloc(NULL, PROGRAM_LENGTH, 1 << PROGRAM_WIDTH,
        (void **) &Program_Export_Base));
assert((address) Program_Export_Base == instruction_page((address)
        Program_Export_Base));
orabort(new_hashtable(0, &Program_Export_Table));

@ @<Fun...@>=
void interpret (void);
error_code interpret_address16 (instruction, address *);
error_code interpret_address24 (instruction, address *);
error_code interpret_argument (instruction, int, cell *);
error_code interpret_register (instruction, int, cell *);
error_code interpret_save (instruction, cell);
error_code interpret_solo_argument (instruction, cell *);
error_code interpret_tiny_object (instruction, int, cell *);

@ TODO: What if |Ip| rolls onto the next page? Theoretically possible but
no need to check for it?

While carrying out an instruction |Ip| points to the {\it next\/}
instruction.

@d IB(I,B)  (((char *) &(I))[B])
@d UB(I,B)  (((unsigned char *) &(I))[B])
@#
@d MODE(I)  ((UB((I), 0) >> 6) & 0x03)
@d OP(I)    ((UB((I), 0) >> 0) & 0x3f)
@#
@d SINT(I)  ((int16_t) (be32toh(I) & 0xffff))
@d UINT(I)  ((uint16_t) (be32toh(I) & 0xffff))
@#
@d TL3(I)   (((UB((I), 3) >> 6) & 0xc0) << 10)
@d TL2(I)   (((UB((I), 2) >> 0) & 0xff) <<  2)
@d TL1(I)   (((UB((I), 1) >> 6) & 0x03) <<  0)
@d TABLE(I) (TL3(I) | TL2(I) | TL1(I))
@d INDEX(I) ((UB((I), 3) >> 0) & 0x3f)
@#
@d REG(I,B) (UB((I), (B)) & 0x3f)
@d POP(I,B) (UB((I), (B)) & 0x80)
@c
void
interpret (void)
{
        address link;
        instruction ins; /* Register? A copy of the current instruction. */
        error_code reason;

        Trapped = false;
        while (!Trapped) {
                reason = LERR_NONE;
                if (Ip < 0 || Ip >= PROGRAM_INVALID) {
                        ins = 0;
                        reason = LERR_ADDRESS;
                        goto Trap;
                }
                ins = *(instruction *) Ip;
                Ip += sizeof (instruction);
                switch (OP(ins)) { @<Carry out an operation@> }
        }
}

@ @c
error_code
interpret_argument (instruction  ins,
                    int          argc,
                    cell        *ret)
{
        bool regp;

        assert(argc >= 0 && argc <= 2);
        switch (argc) {
        case 0: regp = true;@+ break;
        case 1: regp = MODE(ins) & LBC_FIRST_REGISTER;@+ break;
        case 2: regp = MODE(ins) & LBC_SECOND_REGISTER;@+ break;
        }
        if (regp)
                return interpret_register(ins, argc, ret);
        else
                return interpret_tiny_object(ins, argc, ret);
}

@ For {\it reading\/}.

@c
error_code
interpret_register (instruction  ins,
                    int          argc,
                    cell        *ret)
{
        assert(argc >= 0 && argc <= 2);
        switch (REG(ins, argc + 1)) {
        case LR_Trap_Handler:@;
                return LERR_INCOMPATIBLE;
        case LR_Ip:
                if (POP(ins, argc + 1))
                        return LERR_INCOMPATIBLE;
                return new_int_c(Ip, true, ret);
        case LR_Trap_Ip:
                if (POP(ins, argc + 1))
                        return LERR_INCOMPATIBLE;
                return new_int_c(Trap_Ip, true, ret);
        case LR_Trapped:
                if (POP(ins, argc + 1))
                        return LERR_INCOMPATIBLE;
                *ret = predicate(Trapped);
                return LERR_NONE;
        case LR_Control_Link:
                if (POP(ins, argc + 1))
                        return clink_pop(Register[REG(ins, argc + 1)], ret);
                else
                        return clink_peek(Register[REG(ins, argc + 1)], ret);
        default:
                if (POP(ins, argc + 1))
                        return clink_pop(Register[REG(ins, argc + 1)], ret);
                else
                        *ret = *Register[REG(ins, argc + 1)];
                return LERR_NONE;
        }
}

@ @c
error_code
interpret_tiny_object (instruction  ins,
                       int          argc,
                       cell        *ret)
{
        int8_t value;

        assert(argc >= 1 && argc <= 2);
        value = IB(ins, argc + 1);
        if (fixed_p(value))
                *ret = fix(((value >> 4) & 0xf) - (-TINY_MIN));
        else if (special_p(value))
                *ret = value;
        else
                return LERR_INCOMPATIBLE;
        return LERR_NONE;
}

@ @c
error_code
interpret_solo_argument (instruction  ins,
                         cell        *ret)
{
        long index;
        int16_t value;

        switch(MODE(ins)) {
        case LBC_OBJECT_CONSTANT:@;
                return interpret_tiny_object(ins, 1, ret);
        case LBC_OBJECT_INTEGER:@;
                value = SINT(ins);
                return new_int_c(value, true, ret);
        case LBC_OBJECT_REGISTER:@;
                return interpret_register(ins, 1, ret);
        case LBC_OBJECT_TABLE:@;
                index = TABLE(ins) << OBJECTDB_TABLE_WIDTH;
                index |= INDEX(ins);
                if (index > ObjectDB_Free)
                        return LERR_OUT_OF_BOUNDS;
                return array_ref_c(ObjectDB, index, ret);
        default:
                return LERR_INTERNAL;
        }
}

@ @c
int32_t
interpret_int16 (instruction ins,
                 bool        sign)
{
        int32_t rval;

        rval = (((0xff & UB(ins, 2)) << 8) | ((0xff & UB(ins, 3)) << 0));
        if (sign && rval & 0x00008000)
                rval |= 0xffff0000;
        return rval;
}

@ @c
int32_t
interpret_int24 (instruction ins,
                 bool        sign)
{
        int32_t rval;

        rval = (((0xff & UB(ins, 1)) << 16)
              | ((0xff & UB(ins, 2)) << 8)
              | ((0xff & UB(ins, 3)) << 0));
        if (sign && rval & 0x00800000)
                rval |= 0xff000000;
        return rval;
}

@ @c
error_code
interpret_address16 (instruction  ins,
                     address     *ret)
{
        address from, to;
        cell via;
        error_code reason;

        from = Ip - sizeof (address);
        switch (MODE(ins)) {
        case LBC_ADDRESS_DIRECT:@;
                to = interpret_int16(ins, false) | instruction_page(from);
                break;
        case LBC_ADDRESS_RELATIVE:@;
                to = interpret_int16(ins, true) + from; /* `via' */
                if (instruction_page(to) != instruction_page(from))
                        return LERR_OUT_OF_BOUNDS;
                break;
        case LBC_ADDRESS_INDIRECT:@;
                to = interpret_int16(ins, false); /* `via' */
                if (to >= Program_Export_Free)
                        return LERR_OUT_OF_BOUNDS;
                to = Program_Export_Base[to];
                break;
        case LBC_ADDRESS_REGISTER:@;
                orreturn(interpret_register(ins, 1, &via));
                if (fixed_p(via) && fixed_value(via) >= 0)
                        to = fixed_value(via);
                else if (positive_p(via) && !int_more_p(via))
                        to = int_digit(via);
                else
                        return LERR_INCOMPATIBLE;
                break;
        }
        *ret = to;
        return LERR_NONE;
}

@ The same as |interpret_address16| but using |ARGT| \AM\ |resign24|
to obtain a 24-bit value.

@c
error_code
interpret_address24 (instruction  ins,
                     address     *ret)
{
        address from, to;
        cell via;
        error_code reason;

        from = Ip - sizeof (address);
        switch (MODE(ins)) {
        case LBC_ADDRESS_DIRECT:@;
                to = interpret_int24(ins, false) | instruction_page(from);
                break;
        case LBC_ADDRESS_RELATIVE:@;
                to = interpret_int24(ins, true) + from;
                if (instruction_page(to) != instruction_page(from))
                        return LERR_OUT_OF_BOUNDS;
                break;
        case LBC_ADDRESS_INDIRECT:@;
                to = interpret_int24(ins, false) + from; /* `via' */
                if (to >= Program_Export_Free)
                        return LERR_OUT_OF_BOUNDS;
                to = Program_Export_Base[to];
                break;
        case LBC_ADDRESS_REGISTER:@;
                orreturn(interpret_register(ins, 0, &via));
                if (fixed_p(via) && fixed_value(via) >= 0)
                        to = fixed_value(via);
                else if (positive_p(via) && !int_more_p(via))
                        to = int_digit(via);
                else
                        return LERR_INCOMPATIBLE;
                break;
        }
        *ret = to;
        return LERR_NONE;
}

@ @c
@.TODO@>
error_code
interpret_save (instruction ins,
                cell        result)
{
        switch (REG(ins, 1)) {
        case LR_Ip:@; /* Could be mutable, but why? */
        case LR_Symbol_Table:@;
        case LR_Trap_Handler:@; /* TODO */
        case LR_Trap_Ip:@;
        case LR_Trapped:@;
                return LERR_IMMUTABLE;
        case LR_Control_Link:@;
                return clink_push(Register[REG(ins, 1)], result);
                break;
        case LR_Environment:
                if (!environment_p(result))
                        return LERR_INCOMPATIBLE;
                *Register[REG(ins, 1)] = result;
                return LERR_NONE;
        case LR_Heap_Shared:@;
        case LR_Heap_Thread:@;
        case LR_Heap_Trap:
                if (!heap_p(result))
                        return LERR_INCOMPATIBLE;
        default:@;
                *Register[REG(ins, 1)] = result;
                return LERR_NONE;
        }
}

@ Three special registers control the operation of the trap handler.
|Heap_Trap| defined above points to a private heap that a trap
handler can use. The other two are an array of an address of the
code for each handler, |Trap_Handler|, and |Trap_Ip| which contains
the instruction address which caused the trap to occur.

@<Global...@>=
unique address Trap_Ip = PROGRAM_INVALID; /* The instruction which caused a trap. */
shared address Empty_Trap_Handler[LERR_LENGTH];
unique address *Trap_Handler = Empty_Trap_Handler;
unique bool Trapped = false;

@ @<Extern...@>=
extern shared address Empty_Trap_Handler[];
extern unique address *Trap_Handler, Trap_Ip;
extern unique bool Trapped;

@ Initially each trappable condition has no handler, which will
cause the virtual machine to halt. TODO: This should be a \Ls/
array.

@.TODO@>
@<Finish init...@>=
for (i = 0; i < LERR_LENGTH; i++)
        Empty_Trap_Handler[i] = PROGRAM_INVALID;

@ Instructions are fixed at 32 bits (and the error codes are small
enough to fit within a register) so there are two spare bytes after
the trap reason which could fit further explanation of the error
\`a la single-object opcodes.

The trap heap is not used by default.

@d real_trap(V) (((V) >= 0 && (V) < LERR_LENGTH) ? (V) : LERR_UNIMPLEMENTED)
@<Carry out...@>=
default:
        reason = LERR_INSTRUCTION;
        goto Trap;
case OP_TRAP: /* Handle |ARG1|/|ARG2| here, if at all */
        reason = UB(ins, 1);
Trap:
printf("TRAP %d\n", reason);
        Trapped = true;
        if (Trap_Handler[real_trap(reason)] != PROGRAM_INVALID) {
                Trapped = false;
                Trap_Ip = Ip;
                Trap_Arg1 = VM_Arg1;
                Trap_Arg2 = VM_Arg2;
                Trap_Result = VM_Result;
                Ip = Trap_Handler[real_trap(reason)];
        }
        break;
@#
case OP_HALT:@;
        return;

@ @<Carry out...@>=
case OP_PEND:@;
        ortrap(interpret_address16(ins, &link));
        orassert(new_int_c(link, true, &VM_Result));
        ortrap(interpret_save(ins, VM_Result));
        break;

@ @<Carry out...@>=
case OP_JUMP:@;
        ortrap(interpret_address24(ins, &Ip));
        break;
case OP_TEST:@; /* Although using |interpret_argument| we know arg 0 must
                        be a register. */
        ortrap(interpret_argument(ins, 0, &VM_Result));
        if (POP(ins, 1)) {
                if (false_p(VM_Result))
                        ortrap(interpret_address16(ins, &Ip));
        } else {
                if (true_p(VM_Result))
                        ortrap(interpret_address16(ins, &Ip));
        }
        break;
case OP_WIDETEST:@;
        if (true_p(Accumulator))
                ortrap(interpret_address24(ins, &Ip));
        break;

@ @<Carry out...@>=
case OP_SLO:@;
        ortrap(interpret_solo_argument(ins, &VM_Arg1));
        ortrap(primitive_search(VM_Arg1, &VM_Arg2));
        ortrap(primitive_call(VM_Arg2, &VM_Result));
        ortrap(interpret_save(ins, VM_Result));
        break;

@ @<Carry out...@>=
case OP_SPORK:@;
        ortrap(interpret_address16(ins, &link));
        ortrap(new_osthread(VM_Arg1, link, ((heap_pun *) Heap_Thread)->fun,
                &VM_Result));
        ortrap(interpret_save(ins, VM_Result));
        break;
case OP_WIDESPORK:@;
        ortrap(interpret_address24(ins, &link));
        ortrap(new_osthread(VM_Arg1, link, ((heap_pun *) Heap_Thread)->fun,
                &Accumulator));
        break;

@ @<Carry out...@>=
case OP_JOIN: /* nb.~use |OP_WAIT| for processes. */
        ortrap(interpret_solo_argument(ins, &VM_Arg1));
        VM_Result = UNDEFINED;
        reason = osthread_wait(VM_Arg1, &VM_Result);
        if (failure_p(reason)) {
                if (defined_p(VM_Result))
                        goto Trap;
                VM_Result = fix(reason);
                reason = LERR_THREAD;
                goto Trap;
        }
        ortrap(interpret_save(ins, VM_Result));
        break;

@ @<Carry out...@>=
case OP_LOAD:@;
        ortrap(interpret_solo_argument(ins, &VM_Result));
        ortrap(interpret_save(ins, VM_Result));
        break;

@ @<Fun...@>=
error_code clink_pop_imp (cell *, bool, cell *);
error_code clink_push (cell *, cell);
error_code new_closure (bool, cell, cell, cell *);
error_code closure_open (cell, cell *);

@ @c
error_code
clink_push (cell *stack,
            cell  value)
{
        error_code reason;

        orreturn(cons(value, *stack, stack));
        return LERR_NONE;
}

@ @d clink_pop(S,R) clink_pop_imp((S), true, (R))
@d clink_peek(S,R) clink_pop_imp((S), false, (R))
@c
error_code
clink_pop_imp (cell *stack,
               bool  popping,
               cell *ret)
{
        if (null_p(*stack))
                return LERR_UNDERFLOW;
        else if (!pair_p(*stack))
                return LERR_INCOMPATIBLE;
        *ret = lsin(*stack);
        if (popping)
                *stack = ldex(*stack);
        return LERR_NONE;
}

@ The CONS opcode calls cons.

@<Carry out...@>=
case OP_CONS:@;
        ortrap(interpret_argument(ins, 1, &VM_Arg1));
        ortrap(interpret_argument(ins, 2, &VM_Arg2));
        ortrap(cons(VM_Arg1, VM_Arg2, &VM_Result));
        ortrap(interpret_save(ins, VM_Result));
        break;

@ @<Carry out...@>=
case OP_CAR:@;
        ortrap(interpret_solo_argument(ins, &VM_Arg1));
        ortrap(lcar(VM_Arg1, &VM_Result));
        ortrap(interpret_save(ins, VM_Result));
        break;
case OP_CDR:@;
        ortrap(interpret_solo_argument(ins, &VM_Arg1));
        ortrap(lcdr(VM_Arg1, &VM_Result));
        ortrap(interpret_save(ins, VM_Result));
        break;

@ @<Carry out...@>=
case OP_APPLICATIVE:@;
        ortrap(interpret_argument(ins, 1, &VM_Arg1)); /* Formals */
        ortrap(interpret_argument(ins, 2, &VM_Arg2)); /* Body */
        ortrap(new_closure(true, VM_Arg1, VM_Arg2, &VM_Result));
        ortrap(interpret_save(ins, VM_Result));
        break;
case OP_OPERATIVE:@;
        ortrap(interpret_argument(ins, 1, &VM_Arg1)); /* Formals */
        ortrap(interpret_argument(ins, 2, &VM_Arg2)); /* Body */
        ortrap(new_closure(false, VM_Arg1, VM_Arg2, &VM_Result));
        ortrap(interpret_save(ins, VM_Result));
        break;
case OP_OPEN:@;
        ortrap(interpret_solo_argument(ins, &VM_Arg1));
        ortrap(closure_open(VM_Arg1, &VM_Result)); /* Sets |Environment|. */
        ortrap(interpret_save(ins, VM_Result));
        break;

@ Needs \.{(formals . body)} for return from |closure_open|.

TODO: Check formals for list-of-symbols and body for ... something.

@.TODO@>
@c
error_code
new_closure (bool  applicative,
             cell  formals,
             cell  body,
             cell *ret)
{
        cell new;
        error_code reason;

        orreturn(cons(formals, body, &new));
        return new_atom(applicative ? FORM_APPLICATIVE : FORM_OPERATIVE,
                Environment, new, ret);
}

@ @c
error_code
closure_open (cell  o,
              cell *ret)
{
        error_code reason;

        if (!closure_p(o))
                return LERR_INCOMPATIBLE;
        Environment = lsin(o);
        *ret = ldex(o);
        return LERR_NONE;
}

@ Always |Environment|, single arg is symbol or fail.

@<Carry out...@>=
case OP_LOOKUP:@;
        ortrap(interpret_solo_argument(ins, &VM_Arg1));
        ortrap(env_search(Environment, VM_Arg1, &VM_Result));
        ortrap(interpret_save(ins, VM_Result));
        break;

@ @<Carry out...@>=
case OP_EXTEND:@;
        ortrap(interpret_solo_argument(ins, &VM_Arg1));
        ortrap(new_env(VM_Arg1, &VM_Result));
        ortrap(interpret_save(ins, VM_Result));
        break;

@ @<Carry out...@>=
case OP_DEFINE_M:@;
        ortrap(interpret_argument(ins, 1, &VM_Arg1)); /* Label */
        ortrap(interpret_argument(ins, 2, &VM_Arg2)); /* Value */
        ortrap(env_save_m(Environment, VM_Arg1, VM_Arg2, false));
        ortrap(interpret_save(ins, VOID));
        break;
case OP_REPLACE_M:@;
        ortrap(interpret_argument(ins, 1, &VM_Arg1)); /* Label */
        ortrap(interpret_argument(ins, 2, &VM_Arg2)); /* Value */
        ortrap(env_save_m(Environment, VM_Arg1, VM_Arg2, true));
        ortrap(interpret_save(ins, VOID));
        break;

@ 2-arg, ints and runes (unicodepoints) are comparable for numerical
purposes. Floats unsupported still so no other data format is valid.

@<Carry out...@>=
case OP_CMP:
case OP_CMPGT:
case OP_CMPGE:
case OP_CMPEQ:
case OP_CMPLE:
case OP_CMPLT:
        ortrap(interpret_argument(ins, 1, &VM_Arg1)); /* Yin */
        ortrap(interpret_argument(ins, 2, &VM_Arg2)); /* Yang */
        ortrap(int_cmp(VM_Arg1, VM_Arg2, &VM_Result));
        switch(OP(ins)) {
        case OP_CMP:
                break; /* This is fine. */
        case OP_CMPGT:
                VM_Result = predicate(fixed_value(VM_Result) < 0);@+
                break;
        case OP_CMPGE:
                VM_Result = predicate(fixed_value(VM_Result) <= 0);@+
                break;
        case OP_CMPEQ:
                VM_Result = predicate(fixed_value(VM_Result) == 0);@+
                break;
        case OP_CMPLE:
                VM_Result = predicate(fixed_value(VM_Result) >= 0);@+
                break;
        case OP_CMPLT:
                VM_Result = predicate(fixed_value(VM_Result) > 0);@+
                break;
        }
        ortrap(interpret_save(ins, VM_Result));
        break;

@ Everything but numbers are \.{is?\/} identical based on pointer
equality à la \.{eq?\/} in scheme. Integers xor runes base identity
on their {\it value\/} not their address. Numerically identical
integers are is? each other, and runes are \.{is?\/} each other,
but an integer will never \.{is?\/}-match a rune.

No idea what to say about floats yet.

@<Carry out...@>=
case OP_CMPIS:@;
        ortrap(interpret_argument(ins, 1, &VM_Arg1)); /* Yin */
        ortrap(interpret_argument(ins, 2, &VM_Arg2)); /* Yang */
        VM_Result = predicate(cmpis_p(VM_Arg1, VM_Arg2));
        ortrap(interpret_save(ins, VM_Result));
        break;

@ @<Carry out...@>=
case OP_ADD:@;
        ortrap(interpret_argument(ins, 1, &VM_Arg1)); /* Yin */
        ortrap(interpret_argument(ins, 2, &VM_Arg2)); /* Yang */
        ortrap(int_add(VM_Arg1, VM_Arg2, &VM_Result));
        ortrap(interpret_save(ins, VM_Result));
        break;

@ @<Carry out...@>=
case OP_SUB:@;
        ortrap(interpret_argument(ins, 1, &VM_Arg1)); /* Yin */
        ortrap(interpret_argument(ins, 2, &VM_Arg2)); /* Yang */
        ortrap(int_sub(VM_Arg1, VM_Arg2, &VM_Result));
        ortrap(interpret_save(ins, VM_Result));
        break;

@* Assembler.

This text is old and mostly wrong.

The assembler performs the process of assembling to form an assembly
which can be relocated into executability. The lexer in \.{byteless.lex}
has been made aware of which opcodes expect which arguments although
strictly speaking this is a parsing matter. Combined with the fixed
line length limit and assembly's almost total lack of programmatic
structure this reduces the amount of error checking needed before
a line can be deconstructed and appended to the growing program.

Given a port, usually the front-end to a file descriptor, the
algorithm will:

Create a new assembler object containing

        a 120+1+2 byte line buffer.

        Pending pre and post comment lists

        Up to 64k array of proto-instructions

        Far labels:
            Pending label for next code line
            Database of symbols to lines which mention them
            Database of symbols to lines which define them

        Local labels:
            Pending label for next code line (singular!)
            10-array of pairs, line which defines it and lines which are waiting for it

Repeat until EOF:

    Read a line into the buffer
    Convert to one of:
        \Lt O OA RO ROO
        (opcode)                ;; HALT, NOP
        (opcode object)         ;; TRAP
        (opcode object address) ;; JUMP, CALL
        (opcode register object)
        (opcode register object object)
      Where object is one of:
        () \#[tT] \#[fF] \#VOID \#UNDEFINED
        symbol
        integer
        register
      register is one of:
        ('peeking id)
        ('popping id)
      address is one of:
        name        (symbol, far)
        int         (16 bit signed, local)
    Maintain a table of symbols which are branched to
    Maintain a table of symbols which are provided
    Maintain a table of local links
    Maintain a table of objects
    Each line also has two comment slots, fore and aft. A line with a fore
        comment is a new (readable) block.
    Parse a proto-instruction:
        Look for and pend a label in the first column and abort if one is found and was pending
        If there is no content or just comments, append it and continue with the next line
        Decode the lexical tokens into an opcode and objects
            If a far label is pending add this line to the definitions
            If a local label is pending update saved forward links to this line
            If the opcode indicate a simple branch update the link tables
            Validate the opcode arguments (Mainly just ALOT)
            If any arguments are ALOB and not a constant or integer less than 16 bits allocate
                lookup

If there unfulfilled local links abort

Update symbol links which are provided to relative, for other symbol links allocate an offset

Return a new assembly object containing
        Table of exported labels
        Table of objects
        Up to 64k of real instructions

@ Prior to being encoded instruction arguments are saved in a pair
who's sin half indicates how to interpret the argument datum in the
dex half.

@<Constant Sym...@>=
LBA_ADDRESS,
LBA_ASIS,
LBA_INDIRECT,
LBA_OBJECT,
LBA_REGISTER,
LBA_REGISTER_POP,
LBA_RELATIVE,
LBA_TABLE,

@ @<Finish init...@>=
init_identifier(LBA_ADDRESS,      "address",      ltmp);
init_identifier(LBA_ASIS,         "as-is",        ltmp);
init_identifier(LBA_INDIRECT,     "indirect",     ltmp);
init_identifier(LBA_OBJECT,       "object",       ltmp);
init_identifier(LBA_REGISTER,     "register",     ltmp);
init_identifier(LBA_REGISTER_POP, "register%pop", ltmp);
init_identifier(LBA_RELATIVE,     "relative",     ltmp);
init_identifier(LBA_TABLE,        "table",        ltmp);

@ Assembly objects consist primarily of an array of statements. The
underlying object is designed for simplicity not efficiency.

@d statement_opcode(O)    (larry_ref_imp((O), 0))
@d statement_comment(O)   (larry_ref_imp((O), 4))
@d statement_argument(O,I) (larry_ref_imp((O), (I) + 1))
@d statement_set_m(O,I,V) (larry_set_m_imp((O), (I) + 1, (V)))
@d statement_set_comment_m(O,V) (larry_set_m_imp((O), 4, (V)))
@<Fun...@>=
error_code new_statement (cell, cell *);
bool statement_has_argument_p (cell, int);
error_code statement_set_argument_m (cell, int, cell);

@ @c
error_code
new_statement (cell  op,
               cell *ret)
{
        error_code reason;

        if (!opcode_p(op))
                return LERR_INCOMPATIBLE;
        orreturn(new_larry(5, 0, NIL, FORM_STATEMENT, ret));
        larry_set_m_imp(*ret, 0, op);
        return LERR_NONE;
}

@ @c
bool
statement_has_argument_p (cell o,
                          int  argc)
{
        assert(statement_p(o));
        assert(argc >= 0 && argc <= 2);
        return !null_p(larry_ref_imp(o, argc + 1));
}

@ @c
error_code
statement_set_argument_m (cell o,
                          int  argc,
                          cell datum)
{
        cell label;

        assert(statement_p(o));
        assert(argc >= 0 && argc <= 2);
        if (!pair_p(datum))
                return LERR_INCOMPATIBLE;
        label = lsin(datum);
        if (label != Label[LBA_ADDRESS]
                    && label != Label[LBA_ASIS]@|
                    && label != Label[LBA_INDIRECT]
                    && label != Label[LBA_OBJECT]
                    && label != Label[LBA_REGISTER]@|
                    && label != Label[LBA_REGISTER_POP]
                    && label != Label[LBA_RELATIVE]
                    && label != Label[LBA_TABLE])@/
                return LERR_INCOMPATIBLE;
        larry_set_m_imp(o, argc + 1, datum);
        return LERR_NONE;
}

@ Ensure shared objects are in the same place in theses structs.

@<Type def...@>=
typedef struct {
        cell cursor; /* |integer_p|. */
        cell commentary; /* List of \.{(address . (comment-lines))}. */
        cell blob; /* |NIL| or a segment of raw data. */
        cell objectdb; /* Array of \.{(object . (lines))}. */
        cell fardb; /* Hashtable of \.{\{label address\}}. */
        cell local[20]; /* \.{latest-reverse} at \.i,
                                \.{(pending-forward)} at \.{i + 10}. */
        cell pending_far; /* |symbol_p| or |NIL|. */
        cell pending_local; /* -1 or 0--9. */
        cell pending_comment; /* List of segments. */
} assembly_working;

typedef struct {
        cell page; /* |NIL| or |pointer_p|. */
        cell commentary;
        cell blob;
        cell objectdb;
        cell exportdb; /* Far labels which are defined. */
        cell requiredb; /* Far labels which are only referenced. */
} assembly_complete;

@ @d ASSEMBLY_LINE_LENGTH        120
@d ASSEMBLY_COMPLETE_HEADER    (sizeof (assembly_complete) / sizeof (cell))
@d ASSEMBLY_WORKING_HEADER     (sizeof (assembly_working) / sizeof (cell))
@#
@d assembly_address(O)  (larry_ref_imp((O), 0))
@d assembly_complete_p(O)
                        (!integer_p(assembly_address(O)))
@d assembly_installed_p(O)
                        (integer_p(assembly_address(O))) /* Or |NIL|. */
@d assembly_working_object(O)
                        ((assembly_working *) larry_base(O))
@d assembly_complete_object(O)
                        ((assembly_complete *) larry_base(O))
@d assembly_header_length(O)
                        (assembly_complete_p(O)@|
                                ? ASSEMBLY_COMPLETE_HEADER@|
                                : ASSEMBLY_WORKING_HEADER)
@d assembly_length(O)   (larry_length(O) - assembly_header_length(O))
@#
@d assembly_cursor(O)   (fixed_p(assembly_address(O))@|
                                ? (address) fixed_value(assembly_address(O))@|
                                : (address) int_digit(assembly_address(O)))
@d assembly_set_cursor_m(O,A)
                        (new_int_c((A), true, &assembly_address(O)))
@d assembly_set_cursor_m_imp(O,A)
                        (larry_set_m_imp((O), 0, (A)))
@d assembly_complete_ref(O,I)
                        (larry_ref_imp((O), (I) + ASSEMBLY_COMPLETE_HEADER))
@d assembly_working_ref(O,I)
                        (larry_ref_imp((O), (I) + ASSEMBLY_WORKING_HEADER))
@d assembly_set_m(O,I,V)(larry_set_m_imp((O), (I) + ASSEMBLY_WORKING_HEADER,
                                (V)))
@d assembly_previous_line(O)
                        (assembly_working_ref((O), assembly_cursor(O) - 1))
@#
@d assembly_commentary(O)
                        (assembly_working_object(O)->commentary)
@d assembly_set_commentary_m(O,V)
                        (assembly_working_object(O)->commentary = (V))
@d assembly_blob(O)     (assembly_working_object(O)->blob)
@d assembly_set_blob_m(O,V)
                        (assembly_working_object(O)->blob = (V))
@#
@d assembly_objectdb(O) (assembly_working_object(O)->objectdb)
@d assembly_set_objectdb_m(O,V)
                        (assembly_working_object(O)->objectdb = (V))
@d assembly_objectdb_length(O)
                        (array_length(assembly_working_object(O)->objectdb) - 1)
@d assembly_objectdb_cursor_imp(O)
                        (get_array_ref_c(assembly_objectdb(O),
                                assembly_objectdb_length(O)))
@d assembly_objectdb_cursor(O)
                        (fixed_p(assembly_objectdb_cursor_imp(O))@|
                                ? fixed_value(assembly_objectdb_cursor_imp(O))@|
                                : int_digit(assembly_objectdb_cursor_imp(O)))
@d assembly_set_objectdb_cursor_m(O,V)
                        (array_set_m_c(assembly_objectdb(O),
                                assembly_objectdb_length(O), (V)))
@#
@d assembly_fardb(O)    (assembly_working_object(O)->fardb)
@d assembly_set_fardb_m(O,V)
                        (assembly_working_object(O)->fardb = (V))
@d assembly_localdb(O)  (assembly_working_object(O)->local)
@#
@d assembly_pending_local(O)
                        (fixed_value(assembly_working_object(O)->pending_local))
@d assembly_pending_local_p(O)
                        (assembly_pending_local(O) >= 0)
@d assembly_set_pending_local_m(O,V)
                        (assembly_working_object(O)->pending_local = fix(V))
@d assembly_pending_far(O)
                        (assembly_working_object(O)->pending_far)
@d assembly_pending_far_p(O)
                        (!null_p(assembly_working_object(O)->pending_far))
@d assembly_set_pending_far_m(O,V)
                        (assembly_working_object(O)->pending_far = (V))
@d assembly_pending_comment(O)
                        (assembly_working_object(O)->pending_comment)
@d assembly_set_pending_comment_m(O,V)
                        (assembly_working_object(O)->pending_comment = (V))
@d assembly_pending_comment_p(O)
                        (!null_p(assembly_pending_comment(O)))
@#
@d assembly_exportdb(O) (assembly_complete_object(O)->exportdb)
@d assembly_set_exportdb_m(O,V)
                        (assembly_complete_object(O)->exportdb = (V))
@d assembly_requiredb(O)
                        (assembly_complete_object(O)->requiredb)
@d assembly_set_requiredb_m(O,V)
                        (assembly_complete_object(O)->requiredb = (V))

@ @<Fun...@>=
error_code new_assembly (cell *);
error_code finish_assembly (cell, cell *);
error_code assembly_apply_argument (cell, cell, intmax_t, int, cell);
error_code assembly_apply_comment (cell, intmax_t, char *, int);
error_code assembly_apply_far_label (cell, intmax_t, char *, int);
error_code assembly_apply_local_label (cell, intmax_t, int);
error_code assembly_begin_opcode (cell, intmax_t, char *, int, cell *);
error_code assembly_file_handle (cell, cell *);
error_code assembly_fix_address (cell, address, address);
error_code assembly_line (cell, intmax_t, char *, int);
error_code assembly_save_object (cell, cell, cell *);
error_code assembly_scan_argument (cell, char *, int, int, int, int *, cell *);
error_code assembly_scan_register (bool, char *, int, int *, cell *);
error_code assembly_scan_symbol (cell, char *, int, search_fn, int *, cell *);
error_code assembly_segment (cell, cell *);
error_code assembly_ensure_length_m (cell, address);

@ @c
error_code
new_assembly (cell *ret)
{
        cell new, tmp;
        error_code reason;

        orreturn(new_larry(ASSEMBLY_WORKING_HEADER + 16, 0, NIL,
                FORM_ASSEMBLY, &new));
        assembly_set_cursor_m(new, 0);
        assembly_set_pending_far_m(new, NIL);
        assembly_set_pending_local_m(new, -1);
        assembly_set_pending_comment_m(new, NIL);
        orreturn(new_hashtable(0, &tmp));
        assembly_set_fardb_m(new, tmp);
        orreturn(new_array(1, fix(0), &tmp));
        assembly_set_objectdb_m(new, tmp);
        *ret = new;
        return LERR_NONE;
}

@ @c
error_code
assembly_ensure_length_m (cell    o,
                          address length)
{
        address nlength;

        assert(assembly_p(o) && !assembly_complete_p(o));
        nlength = assembly_length(o);
        if (nlength >= length)
                return LERR_NONE;
        if (nlength == PROGRAM_LENGTH)
                return LERR_OOM;
        nlength *= 2;
        return larry_resize_m(o, ASSEMBLY_WORKING_HEADER + nlength, NIL);
}

@ Assembly is a two-stage process. First the source (from a file
descriptor or in memory buffer) is divided into lines of at most
120 characters (not including the trailing newline) which are
progressively parsed into a symbolic representation (|assembly_line|).
After the full source is parsed the representation is processed by
|assembly_finish| to resolve local addresses, exported address
symbols and objects/constant.

To assemble code held in memory successive newlines are identified
and pointers into the buffer are passed to |assembly_line|. As with
source read in from a file, the text must end with a newline character.

@c
error_code
new_assembly_segment (cell  o,
                      cell *ret)
{
        cell new;
        char *lstart, *lend, *send;
        intmax_t line; /* The current source line number. */
        error_code reason;

        if (!segment_p(o))
                return LERR_INCOMPATIBLE;
        orreturn(new_assembly(&new));
        lend = (char *) segment_base(o);
        send = lend + segment_length(o);
        lend--;
        line = 0;
        while (1) {
                lstart = lend + 1;
                lend = lstart;
                while (lend < send) {
                        if (*lend == '\n')
                                goto found_line;
                        lend++;
                }
                if (lstart == lend)
                        break;
                return LERR_SYNTAX;
found_line:
                if (lend - lstart > ASSEMBLY_LINE_LENGTH + 1)
                        return LERR_SYNTAX;
                else
                        orreturn(assembly_line(new, line, lstart,
                                (lend - lstart) + 1));
                line++;
        }
        return finish_assembly(new, ret);
}

@ Lines read in from a file descriptor are read directly into a
temporary buffer.

@c
error_code
new_assembly_file_handle (cell  o,
                          cell *ret)
{
        cell nbyte; /* The next byte. */
        cell new;
        cell buffer; /* Pointer to line buffer */
        char next;
        int i;
        intmax_t line;
        error_code reason;

        if (!file_handle_p(o))
                return LERR_INCOMPATIBLE;
        orreturn(new_assembly(&new));
        orreturn(new_segment(ASSEMBLY_LINE_LENGTH + 1, 1, 0, &buffer));
        line = i = 0;
        while (1) {
                reason = file_handle_read_word(o, 1, &nbyte);
                if (reason == LERR_EOF) {
                        if (i == 0)
                                break;
                        else
                                return LERR_SYNTAX;
                } else if (failure_p(reason))
                        return reason;
                segment_base(buffer)[i++] = word(nbyte)[0];
                if (asm_vspace_p(word(nbyte)[0])) {
                        orreturn(assembly_line(new, line,
                                (char *) segment_base(buffer), i));
                        line++;
                        i = 0;
                } else if (i > ASSEMBLY_LINE_LENGTH)
                        return LERR_SYNTAX;
        }
        return finish_assembly(new, ret);
}

@ The overall structure of the assembly source is simple: each line
(of up to 120 characters) is parsed into pseudo machine-code which
to append to the partial assembly.

A line may have a named (``far'') and/or numeric (``local'') label.
Far labels are those points which can be branched to by the program
being built (\.{JUMP \#t,@@SomeSubroutine}) and are entry points
for other programs to call this one with (``exported'' labels).
Currently there is no way to indicate far labels which should not
be exported, perhaps there should be.

Local labels are single-digit numbers followed by `\.H' (or `\.h')
and are referred to with the same number followed by \.B/\.b to
refer to the previous line with that local label, or \.F/\.f to
refer to the next. This system is described by Knuth in TAOCP. TODO:
cite this better.

On the whole that's it but this wouldn't be programming if there
weren't subtle details.

Source lines do not need to contain code but they can still have a
label or a comment. This works by using the first character of
the line to distinguish it: If it's a digit or a valid initial-character
for a label (predominantly a--z but see |asm_far_start_p|) the line
begins with a label, alternatively if it's anything other than blank
(space or tab) the line is a comment.

If the line contains only a label then it identifies the {\it next\/}
code line. Note that a line can have both a far label and a local
label but only one of each.

Comments are mostly ignored except that trailing space is trimmed
and consecutive empty lines are concatenated. Comments are collected
and associated with the next line of code, acting as an
introduction\footnote{$^1$}{Much like this.} to the next code
``block'' --- meaning nothing other than all the code from that
point until the next blank line. This is for later introspection
and documentation and has no practical effect.

If the line isn't a comment then the first word is the instruction's
opcode, followed by blank space and the opcode's arguments, which
are described later.

After some space the instruction can be followed by a comment, which
can span multiple lines terminated by a blank line or another code
line. This is another type of comment about the line itself but is
equally irrelevant.

The macros below assume ASCII and mask out bit $2^5$ to make
alphabetic tests case insensitive.

@.TODO@>
@d asm_hspace_p(O)    ((O) == ' ' || (O) == '\t')
@d asm_vspace_p(O)    ((O) == '\n')
@d asm_alpha_p(O)     ((((O) & 0xdf) >= 'A') && (((O) & 0xdf) <= 'Z'))
@d asm_digit_p(O)     ((O) >= '0' && (O) <= '9')
@#
@d asm_here_p(O)      (((O) & 0xdf) == 'H')
@d asm_back_p(O)      (((O) & 0xdf) == 'B')
@d asm_fore_p(O)      (((O) & 0xdf) == 'F')
@d asm_local_p(O)     (asm_back_p(O) || asm_fore_p(O))
@d asm_far_start_p(O) (asm_alpha_p(O) || (O) == '_' || (O) == ':'
        || (O) == '$' || (O) == '!')
@d asm_far_p(O)       ((asm_far_start_p(O) && (O) != '!') /* If it quacks
                                                            like a comment. */
        || (O) == '?'
        || (O) == '#' || (O) == '%' || (O) == '/' || (O) == '-' || (O) == '^')
@#
@d asm_const_p(O)     ((O) == '#')
@d asm_label_p(O)     ((O) == '@@')
@d asm_object_p(O)    ((O) == '\'')
@d asm_plusminus_p(O) ((O) == '+' || (O) == '-')
@d asm_popping_p(O)   ((O) == '=')
@d asm_separator_p(O) ((O) == ',')
@#
@d asm_op_start_p(O)  (asm_alpha_p(O))
@d asm_op_p(O)        (asm_op_start_p(O) || (O) == '!' || (O) == '?')
@d asm_false_p(O)     (((O) & 0xdf) == 'F')
@d asm_true_p(O)      (((O) & 0xdf) == 'T')
@d asm_greg_p(O)      (((O) & 0xdf) == 'R')
@d asm_reg_start_p(O) (asm_alpha_p(O)) /* nb.~Includes \.R! */
@d asm_reg_p(O)       (asm_reg_start_p(O) || asm_digit_p(O)
        || (O) == '_' || (O) == '-')
@d asm_sym_start_p(O) (asm_far_start_p(O))
@d asm_sym_p(O)       (asm_far_p(O))

@ A line is at most 120 characters long {\it not\/} including the
trailing newline which {\it must\/} be present. After validating
this the first character determines how the line is formatted. This
algorithm constitutes a simple combined lexer \AM\ parser which
treats most errors as a syntax error and aborts as soon as they are
encountered.

The buffer pointed to in the arguments to |assembly_line| is
considered immutable.

@d asm_skip_some(B,L,T,P)
        while ((T)++ < (L))
                if (!((P((B)[(T)]))))
                        /* nb.~|P| is {\it not\/} parenthesised so
                                                the that test can be negated! */
                        break /* No semicolon */
@d asm_skip_space(B,L,T) asm_skip_some((B), (L), (T), asm_hspace_p)
@c
error_code
assembly_line (cell      o,
               intmax_t  srcline,
               char     *lbuf,
               int       length)
{
        cell line; /* The new line appended to the assembly. */
        cell op; /* The current line's opcode, if any. */
        cell found; /* Placeholder for building statements in. */
        int cursor, more; /* How many bytes have been scanned. */
        error_code reason;

        if (!assembly_p(o) || assembly_complete_p(o))
                return LERR_INCOMPATIBLE;
        if (length == 0 || !asm_vspace_p(lbuf[length - 1]))
                return LERR_SYNTAX;
        length--; /* |length| may now be 0 but it's safe to `accidentally'
                        look one past the end. */
        cursor = 0;
        line = NIL;
        if (asm_digit_p(lbuf[0])) {
                @<Look for a local label@>
        } else if (asm_far_start_p(lbuf[(0)])) {
                @<Look for a far label@>
        } else if (length == 0 || !asm_hspace_p(lbuf[0]))
                goto comment;
        if (cursor == length)
                goto finish_line;
        else if (!asm_hspace_p(lbuf[cursor]))
                return LERR_SYNTAX;
        asm_skip_space(lbuf, length, cursor);
        @<Look for an opcode@>@;
        @<Look for opcode arguments@>@;
trailing_comment:
        if (cursor == length)
                goto finish_line;
        else if (!asm_hspace_p(lbuf[cursor]))
                return LERR_SYNTAX;
        asm_skip_space(lbuf, length, cursor);
        if (cursor == length)
                goto finish_line;
comment:
        assembly_apply_comment(o, srcline, lbuf + cursor, length - cursor);
finish_line:
        if (!null_p(line) && assembly_pending_local_p(o)) {
                orreturn(new_int_c(assembly_cursor(o) - 1, true,
                        &(assembly_localdb(o)[assembly_pending_local(o)])));
                assembly_set_pending_local_m(o, -1);
        }
        return LERR_NONE;
}

@ A local label is an ASCII digit 0--9 followed by the letter h.
Provided the first two bytes are valid |assembly_apply_local_label|
configures the assembly object to associate that label with this
(or the next) line.

@<Look for a local label@>=
if (length < 2 || !asm_here_p(lbuf[1]))
        return LERR_SYNTAX;
orreturn(assembly_apply_local_label(o, srcline, lbuf[0] - '0'));
cursor = 2;

@ A far label is simply a symbol with some constraints. The range
of the label within the buffer is similarly identified and passed
to |assembly_apply_far_label| to prepare to label the next line.

@<Look for a far label@>=
cursor++;
asm_skip_some(lbuf, length, cursor, asm_far_p);
if (cursor == 2)
        goto comment;
orreturn(assembly_apply_far_label(o, srcline, lbuf, cursor));

@ From this point on we no longer have an absolute starting position
so |cursor| and |more| are used to keep track of the cursor within
the line.

As with the labels the range within the buffer is identified and
passed to a function to apply it to the partial assembly. In this
case |assembly_begin_opcode| appends a new line (as a {\it statement\/}
object) to the assembly, consuming the labels applied above, which
it returns in |line|.

This block falls through to |@<Look for opcode arguments@>|.

@<Look for an opcode@>=
if (cursor == length)
        return LERR_NONE;
more = cursor;
if (!asm_op_start_p(lbuf[cursor++])) {
        if (cursor == length || asm_hspace_p(lbuf[cursor + 1]))
                goto comment;
        else
                return LERR_SYNTAX;
}
asm_skip_some(lbuf, length, cursor, asm_op_p);
if (cursor - more == 2)
        goto comment;
orreturn(assembly_begin_opcode(o, line, lbuf + more, cursor - more, &line));

@ Some opcodes do not accept arguments (but can still have comments).
If they do the arguments are scanned by |assembly_scan_argument|. There can
be up to three arguments so there's no need to refactor the repetition
here into a loop. Spaces are not permitted between the arguments
--- they are separated by a comma which is looked for in |assembly_scan_argument|.

This is the main part of this algorithm which merges the concerns
of lexing and parsing.

@<Look for opcode arguments@>=
op = statement_opcode(line);
if (opcode_object(op)->arg0 == NARG)
        goto trailing_comment;
if (!asm_hspace_p(lbuf[cursor]))
        return LERR_SYNTAX;
asm_skip_space(lbuf, length, cursor);
orreturn(assembly_scan_argument(o, lbuf + cursor, length - cursor,
        opcode_object(op)->arg0, 0, &more, &found));
cursor += more;
orreturn(assembly_apply_argument(o, line, srcline, 0, found));
@#
if (opcode_object(op)->arg1 == NARG)
        goto trailing_comment;
orreturn(assembly_scan_argument(o, lbuf + cursor, length - cursor,
        opcode_object(op)->arg1, 1, &more, &found));
cursor += more;
orreturn(assembly_apply_argument(o, line, srcline, 1, found));
@#
if (opcode_object(op)->arg2 == NARG)
        goto trailing_comment;
orreturn(assembly_scan_argument(o, lbuf + cursor, length - cursor,
        opcode_object(op)->arg2, 2, &more, &found));
cursor += more;
orreturn(assembly_apply_argument(o, line, srcline, 2, found));

@ If the argument being scanned is not the first then the argument
must be preceeded by a comma separator. |offset| keeps track of the
point from which an argument is being scanned (instead of, say,
incrementing |lbuf|) and |cursor| tracks how many bytes have been
scanned in total, which is returned to the caller in |consume|.

Registers are named directly; other objects and references are
indicated by the byte which preceeds them: \.@@ -- an address, \.\ft\
-- an object, \.- or \.+ -- an integer or \.\# -- a constant.

Positive integers (and 0) can be written directly, without $\pm$.
The constants marked by \.\# are the booleans and \.{\#VOID} or
\.{\#UNDEFINED}. |NIL| is written as \.{()}. Only the booleans can
use lower-case.

@c
error_code
assembly_scan_argument (cell  o,
                        char *lbuf,
                        int   length,
                        int   cat,
                        int   argc,@|
                        int  *consume,
                        cell *ret)
{
        cell found;
        int cursor, offset;
        bool minus, popping;
        error_code reason;

        assert(assembly_p(o) && !assembly_complete_p(o));
        if (length == 0)
                return LERR_SYNTAX;
        cursor = offset = 0;
        minus = false;
        if (argc) {
                if (!asm_separator_p(lbuf[0]))
                        return LERR_SYNTAX;
                cursor = offset = 1;
        }
        switch (cat) {
        case AADD: /* An address. */
                if (asm_label_p(lbuf[cursor])) {
                        offset++;
                        @<Scan an address...@>@;
                } else if ((popping = asm_popping_p(lbuf[cursor]))
                            || asm_reg_start_p(lbuf[cursor])) {
                        offset++;
                        goto scan_address_register;
                } else
                        return LERR_SYNTAX;
        case ALOB:@; /* Anything. */
        case ARGH: /* ... actually, only a symbol (|OP_TRAP|). */
        printf("ARGH!\n");
                if (lbuf[offset] == '\'') {
                        @<Scan a simple object and |goto scan_found|@>
                } else if (cat == ARGH)
                        return LERR_SYNTAX; /* |ARGH| must have \ft\
                                                followed by a symbol. */
                /* |else| fallthrough. */
        case ALOT:@; /* A tiny number. */
        case AREG:@; /* ... or only a register (first argument). */
                @<Scan a register name or don't |goto scan_found|@>@;
                if (cat == AREG)
                        return LERR_SYNTAX;
                @<Scan a constant and abort or |goto scan_found|@>@;
        }
        return LERR_INTERNAL; /* Unreachable. */
@#
scan_integer:
        @<Scan an integer in assembly@>@;
scan_found:
        *consume = cursor;
        *ret = found;
        return LERR_NONE;
}

@ An address argument is indicated by \.@@, which has already been
detected. An address argument is saved as a pair who's sinister
half is false.

@<Scan an address and |goto scan_found|@>=
if (length - offset < 2)
        return LERR_SYNTAX;
cursor = offset;
if (asm_digit_p(lbuf[cursor])) { /* \.{(\ft address . $\pm$label)} */
        if (!asm_local_p(lbuf[cursor + 1]))
                return LERR_SYNTAX;
        found = fix(lbuf[cursor] - '0');
        if (asm_back_p(lbuf[cursor + 1]))
                found = fix(-(fixed_value(found) + 1));
        orreturn(cons(Label[LBA_ADDRESS], found, &found));
        cursor += 2;
} else if (asm_far_start_p(lbuf[cursor])) { /* \.{(\ft address . label)} */
        orreturn(assembly_scan_far_address(lbuf + cursor, length - cursor,
                &cursor, &found));
        cursor += offset;
} else
        return LERR_SYNTAX;
goto scan_found;

@ @<Scan a constant and abort or |goto scan_found|@>=
if (asm_digit_p(lbuf[offset]))
        goto scan_integer;
else if (asm_const_p(lbuf[offset])) {
        @<Scan a constant in assembly@>
} else if (asm_plusminus_p(lbuf[offset])) {
        minus = (lbuf[offset] == '-');
        offset++;
        if (length - offset == 0)
                return LERR_SYNTAX;
        goto scan_integer;
} else if (length >= 2 && lbuf[offset] == '('
                && lbuf[offset + 1] == ')') {
        cursor += 2;
        orreturn(cons(Label[LBA_OBJECT], NIL, &found));
        goto scan_found;
}

@ Simple constants (including |NIL|) are saved as themselves. Scans
to \.{(\ft object . \#}{\it \<special\/\>}\.{)}.

Constants in assembly include \.{\#VOID} and \.{\#UNDEFINED} (exactly)
to mean |VOID| and |UNDEFINED| respectively.

@<Scan a constant in assembly@>=
if (length - offset < 2)
        return LERR_SYNTAX;
else if (asm_false_p(lbuf[offset + 1]))
        cursor += 2, found = LFALSE;
else if (asm_true_p(lbuf[offset + 1]))
        cursor += 2, found = LTRUE;
else if (length - offset >= 5@|
            && (lbuf[offset + 1] == 'V' && lbuf[offset + 2] == 'O'
            && lbuf[offset + 3] == 'I' && lbuf[offset + 4] == 'D'))@/
        cursor += 5, found = VOID;
else if (length - offset >= 10@|
            && lbuf[offset + 1] == 'U'@|
            && lbuf[offset + 2] == 'N'@|
            && lbuf[offset + 3] == 'D'@|
            && lbuf[offset + 4] == 'E'@|
            && lbuf[offset + 5] == 'F'@|
            && lbuf[offset + 6] == 'I'@|
            && lbuf[offset + 7] == 'N'@|
            && lbuf[offset + 8] == 'E'@|
            && lbuf[offset + 9] == 'D')@/
        cursor += 10, found = UNDEFINED;
else
        return LERR_SYNTAX;
orreturn(cons(Label[LBA_OBJECT], found, &found));
goto scan_found;

@ An integer is a lone zero (\.0) or a sequence of one or more
digits not beginning with a zero (possibly, as detected previously,
preceeded by $\pm$; including $\pm0$).

@<Scan an integer in assembly@>=
cursor = offset;
if (lbuf[cursor] == 0) {
        cursor++;
        found = fix(0);
} else {
        asm_skip_some(lbuf, length, cursor, asm_digit_p);
        orreturn(new_int_buffer(minus, lbuf + offset, cursor - offset, &found));
}
orreturn(cons(Label[LBA_OBJECT], found, &found));
goto scan_found;

@ At present this assembler only supports symbols where any
s-expression should be permitted. When they are it will be possible,
although perhaps not very useful, to do away with the special cases
for constants. The algorithm will also need to parse objects which
span more than one line, as well as the ability to refer to objects
other than in-line.

The \.\ft\ which preceeds an object has already been detected.

@<Scan a simple object and |goto scan_found|@>=
cursor = offset + 1;
orreturn(assembly_scan_symbol(Label[LBA_OBJECT], lbuf + cursor,
        length - cursor, (cat == ARGH ? error_search : NULL), &cursor, &found));
cursor += offset + 1;
goto scan_found;

@ A register is named without fanfare but may be preceeded by \.!
if the register will hold a stack and the top item is to be popped
off of it. The saved object representing a register is a pair with
the register object in the sinister half and whether it should be
popped in the dexter half.

@<Scan a register name or don't |goto scan_found|@>=
popping = asm_popping_p(lbuf[offset]);
if (popping)
        offset++;
if (popping || asm_reg_start_p(lbuf[offset])) {
scan_address_register:
        orreturn(assembly_scan_register(popping, lbuf + offset,
                length - offset, &cursor, &found));
        cursor += offset;
        goto scan_found;
}

@ To detect a register argument a symbol is created by appending
the register name to a buffer beginning with ``\.{VM:}'' and looking
for it's binding in the root environment.

The special registers' names are capitalised using title case
(capitalising only the first letter of each word). A dash\footnote{$^1$}
{Known to ASCII as ``hyphen (minus)'' or ``hyphen-minus'' in unicode
parlance for extra recursion.} (\.-) separates each word, which may
be written as an underscore\footnote{$^2$}{Don't ask.} (\.\_) in
the source.

The |LERR_INCOMPATIBLE| error may really have been caused by invalid
syntax (eg. a name which is too long to fit in |tmp|) but there's
nothing to gain by detecting that specially (there's little enough
use in looking for |LERR_INCOMPATIBLE| as it is).

@c
error_code
assembly_scan_register (bool  popping,
                        char *lbuf,
                        int   length,
                        int  *consume,
                        cell *ret)
{
        bool upcase;
        cell lreg, sreg;
        char tmp[24]; /* The longest register name is less than this. */
        error_code reason;

        if (length < 2)
                return LERR_SYNTAX;
        tmp[0] = 'V';
        tmp[1] = 'M';
        tmp[2] = ':';
        if (asm_greg_p(lbuf[0])) {
                tmp[3] = 'R';
                tmp[4] = lbuf[1]; /* Let the search detect this as a digit. */
                *consume = 2;
                if (length >= 3 && asm_digit_p(lbuf[2])) {
                            /* ... but not this, which could be anything. */
                        tmp[5] = lbuf[2];
                        *consume = 3;
                }
        } else { /* ie.~|asm_reg_start_p(lbuf[0])| */
                tmp[3] = toupper(lbuf[0]);
                upcase = false;
                *consume = 1;
                while (*consume < 21) {
                        @<Copy a register name to |tmp| with the correct case@>
                }
        }
        orreturn(new_symbol_buffer((byte *) tmp, *consume + 3, NULL, &sreg));
        reason = root_search(sreg, &lreg);
        if (reason == LERR_MISSING)
                return LERR_INCOMPATIBLE;
        else if (failure_p(reason))
                return reason;
        else if (!register_p(lreg))
                return LERR_INCOMPATIBLE;
        return cons(Label[popping ? LBA_REGISTER_POP : LBA_REGISTER],
                lreg, ret);
}

@ Copy a register name into |tmp| while correctly capitalising it
by turning \.\_ into \.-, capitalising only the letter immediately
following \.- (and the very first letter), and converting everything
else to lower case.

@<Copy a register name to |tmp| with the correct case@>=
if (*consume < length) {
        if (!asm_reg_p(lbuf[*consume]))
                break;
        else {
                if (upcase) {
                        tmp[*consume + 3] = toupper(lbuf[*consume]);
                        upcase = false;
                } else {
                        upcase = (lbuf[*consume] == '_'
                                || lbuf[*consume] == '-');
                        if (upcase)
                                tmp[*consume + 3] = '-';
                        else
                                tmp[*consume + 3] = tolower(lbuf[*consume]);
                }
                (*consume)++;
        }
} else
        break;

@ Objects and addresses look the same in lieu of a full
s-expression parser: A (constrained) symbol.

TODO: split implementation into scan (uses only {\it far\/} scanner
at the moment) and postprocess, then use for opcodes and registers.

@.TODO@>
@d assembly_scan_object(B,L,C,R) assembly_scan_symbol(Label[LBA_OBJECT],
        (B), (L), NULL, (C), (R))
@d assembly_scan_far_address(B,L,C,R) assembly_scan_symbol(Label[LBA_ADDRESS],
        (B), (L), NULL, (C), (R))
@c
error_code
assembly_scan_symbol (cell       cat,
                      char      *lbuf,
                      int        length,
                      search_fn  lookup,
                      int       *consume,
                      cell      *ret)
{
        cell new;
        int offset;
        error_code reason;

        *consume = 0;
        if (length - *consume == 0)
                return LERR_SYNTAX;
        offset = *consume;
        if (!asm_far_start_p(lbuf[*consume]))
                return LERR_SYNTAX;
        (*consume)++;
        asm_skip_some(lbuf, length, *consume, asm_far_p);
        orreturn(new_symbol_buffer((byte *) lbuf + offset,
                *consume - offset, NULL, &new));
        printf("ALL...\n");
        printf("sym "); psym(new); printf("\n");
        printf("lbl "); for (int i = 0; i < length; i++) putchar(lbuf[i]);
        printf("\n");
        if (lookup != NULL)
                orreturn(lookup(new, &new));
        return cons(cat, new, ret);
}

@ The parts necessary to scan through a line of assembly source are
in place but before using the results to construct a statement, if
the statement has a label then it is applied to the partial assembly
object first where it is checked for validity etc.

If an instruction has a local label argument which refers forward
to |label| its line number will have been recorded in the assembly's
local labels database. These lines are updated now that the destination
is known and the forward (dexter) database reset.

Only after the line is fully processed will the backward (sinister)
database for |length| be updated to refer to this line. This is so
that backward local references to |label| in {\it this\/} instruction's
arguments will refer to the prior labelled instruction and not to
itself.

@c
error_code
assembly_apply_local_label (cell     o,
                            intmax_t srcline @[unused@],
                            int      label)
{
        cell next;
        intmax_t lineat;
        error_code reason;

        assert(assembly_p(o) && !assembly_complete_p(o));
        assert(label >= 0 && label <= 9);
        if (assembly_pending_local_p(o))
                return LERR_EXISTS;
        next = assembly_localdb(o)[label + 10];
        while (!null_p(next)) {
        printf("next %d %p?\n", label, next);
                orassert(int_value(lsin(next), &lineat));
                assembly_fix_address(o, lineat, assembly_cursor(o));
                next = ldex(next);
        }
        assembly_localdb(o)[label + 10] = NIL; /* Leave sin for later. */
        assembly_set_pending_local_m(o, label);
        return LERR_NONE;
}

@ Far labels must be unique.

@c
error_code
assembly_apply_far_label (cell     o,
                          intmax_t srcline @[unused@],
                          char    *lbuf,
                          int      length)
{
        bool new;
        cell found, label, lline;
        error_code reason;

        assert(assembly_p(o) && !assembly_complete_p(o));
        assert(length >= 1);
        if (!null_p(assembly_pending_far(o)))
                return LERR_SYNTAX;
        orreturn(new_symbol_buffer((byte *) lbuf, length, NULL, &label));
        orreturn(new_int_c(assembly_cursor(o), true, &lline));
        orreturn(cons(label, lline, &lline));
@#
        orreturn(hashtable_search(assembly_fardb(o), symbol_key(label),
                env_match, (void *) label, &found));
        assert(undefined_p(found) || pair_p(found));
        new = undefined_p(found);
        if (!new && pair_p(found) && !null_p(ldex(found)))
                return LERR_EXISTS;
@#
        orreturn(hashtable_save_m(assembly_fardb(o), symbol_key(label),
                lline, env_rehash, env_match, (void *) label, !new, true));
        assembly_set_pending_far_m(o, label);
        return LERR_NONE;
}

@ Now enough parts are in place to start building an instruction,
beginning with detecting the opcode in the same manner as with
register names (see |assembly_scan_register|). Detecting which type
of error, if any, is equally as useful.

If the opcode name is valid then a statement is created and appended
to the assembly by |assembly_set_m| (after enlargement) and returned
to the caller for convenience.

If there is a pending comment append it to the commentary.

TODO: Save |srcline| in the statement object.

@.TODO@>
@c
error_code
assembly_begin_opcode (cell      o,
                       intmax_t  srcline @[unused@],
                       char     *lbuf,
                       int       length,@|
                       cell     *ret)
{
        address cursor;
        char tmp[24];
        cell commentary, lcursor, line, lop, sop;
        int i;
        error_code reason;

        assert(assembly_p(o) && !assembly_complete_p(o));
        if (!length)
                return LERR_SYNTAX;
@#
        tmp[0] = 'V';
        tmp[1] = 'M';
        tmp[2] = ':';
        for (i = 0; i < length; i++)
                tmp[i + 3] = lbuf[i];
        orreturn(new_symbol_buffer((byte *) tmp, length + 3, NULL, &sop));
        reason = root_search(sop, &lop);
        if (reason == LERR_MISSING)
                return LERR_UNCOMBINABLE;
        else if (failure_p(reason))
                return reason;
        else if (!opcode_p(lop))
                return LERR_UNCOMBINABLE;
@#
        if (assembly_pending_comment_p(o)) {
                orreturn(cons(assembly_address(o), assembly_pending_comment(o),
                        &commentary));
                orreturn(cons(commentary, assembly_commentary(o), &commentary));
        } else
                commentary = NIL;
@#
        cursor = assembly_cursor(o);
        orreturn(assembly_ensure_length_m(o, cursor + 1));
        assert(null_p(assembly_working_ref(o, cursor)));
        orreturn(new_statement(lop, &line));
        orreturn(new_int_c(cursor + 1, true, &lcursor));
@#
        if (!null_p(commentary))
                assembly_set_commentary_m(o, commentary);
        assembly_set_pending_far_m(o, NIL);
        assembly_set_pending_comment_m(o, NIL);
        assembly_set_m(o, cursor, line);
        assembly_set_cursor_m_imp(o, lcursor);
        *ret = line;
        return LERR_NONE;
}

@ Depending on opcode:

argc == 0 must be register or trap. NOT address.

argc == 1 can be anything *iff* there's no argc==2

argc == 2 can be ALOT.

If argc1 or 2 are address, take note?

|obj| comes from |assembly_scan_argument|. Recall:

\.{(\ft object . \{...\})} to \.{(\ft asis . \#const-or-\#integer)},
\.{(\ft table . object-or-integer)}.

\.{(\ft address . $\pm$local)} to \.{(\ft address . -delta)}
if reverse, included in local otherwise.

\.{(\ft address . symbol)} recorded but left alone.

\.{(\ft register* . register)} left alone.

A reverse local label is first converted to an integer. After this
it's safe to update the appropriate lsin in the localdb to the
current line number. If a two-argument opcode is ever created which
can accept instruction addresses this will need to be moved to after
the line is finished after |finish_line| in |assembly_line|.

Far destination labels are added to the fardb with |NIL| in the
location field to indicate they have been used but not defined.

@.TODO@>
@c
error_code
assembly_apply_argument (cell     o,
                         cell     line,
                         intmax_t srcline @[unused@],
                         int      argc,@|
                         cell     datum)
{
        cell found, label, new_fore, op, record;
        int cat, id;
        intmax_t lineat, lineto, value;
        error_code reason;

        assert(assembly_p(o) && !assembly_complete_p(o));
        assert(statement_p(line));
        if (!null_p(statement_argument(line, argc)))
                return LERR_EXISTS;
        if (!pair_p(datum))
                return LERR_INCOMPATIBLE;
        new_fore = NIL;
        if (lsin(datum) == Label[LBA_ADDRESS]) {
                if (symbol_p(ldex(datum))) {
                        @<Save a record of a far label argument@>
                } else if (fixed_p(ldex(datum))) {
                        id = fixed_value(ldex(datum));
                        if (id >= 0) {
                                @<Save a local address argument to fix later@>
                        } else {
                                @<Fix a local address argument@>
                        }
                } else
                        return LERR_INCOMPATIBLE;
        } else if (lsin(datum) == Label[LBA_OBJECT]) {
                if (integer_p(ldex(datum))) {
                        @<Save large numbers in the object database@>
                } else if (special_p(ldex(datum)))
                        orreturn(cons(Label[LBA_ASIS], ldex(datum), &datum));
                else if (!error_p(ldex(datum)))
                        orreturn(assembly_save_object(o, ldex(datum), &datum));
        } else if (lsin(datum) != Label[LBA_REGISTER]
                        && lsin(datum) != Label[LBA_REGISTER_POP])
                return LERR_INCOMPATIBLE;
        orreturn(statement_set_argument_m(line, argc, datum));
        if (!null_p(new_fore))
                assembly_localdb(o)[id + 10] = new_fore;
        return LERR_NONE;
}

@ Leave |datum| as-is and append the current line number to
|assembly_localdb(o)[id]|.

@<Save a local address argument to fix later@>=
orreturn(new_int_c(assembly_cursor(o) - 1, true, &record));
orreturn(cons(record, assembly_localdb(o)[id + 10], &new_fore));

@ @<Fix a local address argument@>=
id = -(id + 1);
if (null_p(assembly_localdb(o)[id]))
        return LERR_MISSING;
orreturn(int_value(assembly_localdb(o)[id], &lineat));
lineto = assembly_cursor(o) - 1;
orreturn(new_int_c(lineto - lineat, true, &label));
orreturn(cons(Label[LBA_RELATIVE], label, &datum)); /* Replacement label
                                                        pair argument. */

@ @<Save a record of a far label argument@>=
label = ldex(datum);
orreturn(hashtable_search(assembly_fardb(o), symbol_key(label), env_match,
        (void *) label, &found));
if (!defined_p(found)) {
        orreturn(cons(label, NIL, &record));
        orreturn(hashtable_save_m(assembly_fardb(o), symbol_key(label),
                record, env_rehash, env_match, (void *) label, true, true));
}
orreturn(cons(Label[LBA_INDIRECT], ldex(datum), &datum));

@ In case the argument being scanned is an |ALOT| the integer must
be squeezed into 4 bits, within the range $-128$--127 which is fully
within that of a fixed integer.

TODO: Find a picture of a 4-bit alot.

@.TODO@>
@<Save large numbers in the object database@>=
op = statement_opcode(line);
cat = opcode_signature(op)[argc];
if (cat != ALOB && cat != ALOT)
        return LERR_INCOMPATIBLE;
reason = int_value(ldex(datum), &value);
if (cat == ALOT && (reason == LERR_LIMIT || value < TINY_MIN
            || value > TINY_MAX))
        return LERR_INCOMPATIBLE;
else if (cat == ALOB && (reason == LERR_LIMIT || value < INT16_MIN
            || value > INT16_MAX))
        orreturn(assembly_save_object(o, ldex(datum), &datum));
else if (failure_p(reason))
        return reason;
else
        orreturn(cons(Label[LBA_ASIS], ldex(datum), &datum));

@ Allocate (or find existing) |obj| in |objectdb| and return a
representation of its location in |ret|.

The objects can only be integers or symbols (at the moment).

@c
error_code
assembly_save_object (cell  o,
                      cell  obj,
                      cell *ret)
{
        cell new_cursor, old, table, index;
        intmax_t cursor, nlength;
        error_code reason;

        assert(assembly_p(o) && !assembly_complete_p(o));
        assert(symbol_p(obj) || integer_p(obj) || error_p(obj));
        index = assembly_objectdb_cursor(o);
        printf("save at %d\n", index);
        new_cursor = NIL;
        for (cursor = 0; cursor < index; cursor++) {
                orassert(array_ref_c(assembly_objectdb(o), cursor, &old));
                if (cmpis_p(old, obj))
                        goto found;
        }
        nlength = assembly_objectdb_length(o);
        printf("not found %d>%d?\n",cursor,nlength);
        if (cursor >= nlength) {
                if (nlength == OBJECTDB_TABLE_LENGTH * OBJECTDB_DB_LENGTH)
                        return LERR_LIMIT;
                old = assembly_address(o);
                nlength += OBJECTDB_TABLE_LENGTH + 1;
                array_resize_m(assembly_objectdb(o), nlength, NIL);
                assembly_set_objectdb_cursor_m(o, old);
        }
        orreturn(new_int_c(cursor + 1, true, &new_cursor));
found:
        orreturn(new_int_c(cursor % OBJECTDB_TABLE_LENGTH, true, &index));
        orreturn(new_int_c(cursor >> OBJECTDB_TABLE_WIDTH, true, &table));
        orreturn(cons(table, index, &table));
        orreturn(cons(Label[LBA_TABLE], table, ret));
        array_set_m_c(assembly_objectdb(o), cursor, obj);
        if (!null_p(new_cursor))
                assembly_set_objectdb_cursor_m(o, new_cursor);
        return LERR_NONE;
}

@ This is called for every instruction containing a forward link
saved in |ldex(local[id])| to change \.{(\ft address . id)} to
\.{(\ft relative . +delta)}.

@c
error_code
assembly_fix_address (cell    o,
                      address pending,
                      address dest)
{
        cell new, s;
        error_code reason;

        assert(assembly_p(o) && !assembly_complete_p(o));
        orreturn(new_int_c(dest - pending, true, &new));
        orreturn(cons(Label[LBA_RELATIVE], new, &new));
        s = assembly_working_ref(o, pending);
        if (opcode_object(statement_opcode(s))->arg0 == AADD)
                return statement_set_argument_m(s, 0, new);
        else if (opcode_object(statement_opcode(s))->arg1 == AADD)
                return statement_set_argument_m(s, 1, new);
        else
                return LERR_INTERNAL;
}

@ If there is content in pending comment, append to that, otherwise
append to the most recent statement (unless the line is blank, so
start a new pending comment).

@c
error_code
assembly_apply_comment (cell      o,
                        intmax_t  srcline @[unused@],
                        char     *lbuf,
                        int       length)
{
        cell line, new;
        error_code reason;

        while (length)
                if (asm_hspace_p(lbuf[length - 1]))
                        length--;
                else
                        break;
        if (length)
                orreturn(new_segment_copy(lbuf, length, 1, 0,
                        FORM_SEGMENT, FORM_NONE, &new));
        else
                new = NIL;
        if (null_p(new)) {
                if (!null_p(assembly_pending_comment(o))
                            && null_p(lsin(assembly_pending_comment(o))))
                        return LERR_NONE;
                orreturn(cons(NIL, assembly_pending_comment(o), &new));
                assembly_set_pending_comment_m(o, new);
        } else if (!null_p(assembly_pending_comment(o))
                    || assembly_cursor(o) == 0) {
                orreturn(cons(new, assembly_pending_comment(o), &new));
                assembly_set_pending_comment_m(o, new);
        } else {
                line = assembly_working_ref(o, assembly_cursor(o) - 1);
                orreturn(cons(new, statement_comment(line), &new));
                statement_set_comment_m(line, new);
        }
        return LERR_NONE;
}

@ Ensure there are no pending labels or unresolved forward local
links. Decide what to do if there's a pending comment.

Create a new array of the precise length.

Copy objectdb.

Scan fardb:
    If the cdr is NIL add the symbol to requiredb (a list)
    Otherwise the cdr is an address and add the pair to exportdb (a hashtable)

Copy the instructions.

object db is plus 2 for false cursor

@c
error_code
finish_assembly (cell  o,
                 cell *ret)
{
        cell commentary, far, have, want, new, tmp;
        address i;
        error_code reason;

        if (!assembly_p(o) || assembly_complete_p(o))
                return LERR_INCOMPATIBLE;
        if (assembly_pending_far_p(o) || assembly_pending_local_p(o))
                return LERR_SYNTAX;
@#
        orreturn(new_larry(ASSEMBLY_COMPLETE_HEADER + assembly_cursor(o),
                0, NIL, FORM_ASSEMBLY, &new));
        assembly_address(new) = NIL;
@#
        if (assembly_pending_comment_p(o)) {
                orreturn(new_symbol_const("footer", &commentary));
                orreturn(cons(commentary, assembly_pending_comment(o),
                        &commentary));
                orreturn(cons(commentary, assembly_commentary(o), &commentary));
        }
@#
        assembly_set_blob_m(new, assembly_blob(o));
@#
        orreturn(new_array(assembly_objectdb_cursor(o) + 2, UNDEFINED, &tmp));
        printf("newobj %d\n", array_length(tmp));
        assembly_set_objectdb_m(new, tmp);
        for (i = 0; i <= assembly_objectdb_cursor(o); i++)
                array_set_m_c(tmp, i, get_array_ref_c(assembly_objectdb(o), i));
@#
        orreturn(new_hashtable(0, &have));
        want = NIL;
        for (i = 0; i < (address) hashtable_length(assembly_fardb(o)); i++) {
                far = hashtable_ref(assembly_fardb(o), i);
                if (null_p(far) || undefined_p(far))
                        continue;
                if (null_p(ldex(far)))
                        orreturn(cons(lsin(far), want, &want));
                else
                        orreturn(hashtable_save_m(have, symbol_key(lsin(far)),
                                far, env_rehash, env_match,@|
                                (void *) lsin(far), false, true));
        }
        assembly_set_exportdb_m(new, have);
        assembly_set_requiredb_m(new, want);
@#
        for (i = 0; i < assembly_cursor(o); i++)
                larry_set_m_imp(new, i + ASSEMBLY_COMPLETE_HEADER,
                        assembly_working_ref(o, i));
@#
        *ret = new;
        return LERR_NONE;
}

@* Bytecode.

Assembly must be complete and not installed.

Allocate page, copy blob

Allocate CODEPAGE atom (pointer to page w/ link to commentary).

Fill in CODEPAGE atom (not in ret).

Lock Program.

Sufficient space in |ObjectDB| \AM\ Blob + (length * 4) < $2^{24}$.

Copy |Program_Export_Table| allocating pseudo-space in
|Program_Export_Base| for lookup offset of symbol addresses.

All required symbols extant in {\it Program\_Export\_*}, all exported symols absent.

Allocate, copy \AM\ fill new objectdb space.

Copy \AM\ convert instructions.

Swap pointers (read lock?).

Unlock Program.

Return CODEPAGE atom.

@<Fun...@>=
error_code install_assembly (cell, cell *);
error_code program_find_link (cell, cell, instruction *);
error_code program_find_address (cell, cell, instruction *, address *);
error_code assembly_encode_ALOT (int, cell, instruction *);
error_code assembly_encode_AREG (int, cell, instruction *);
error_code assembly_encode_integer (int, bool, cell, intmax_t *);

@ These goto destinations are most common and quite noisy. In fact
they're no different from saying |ortrap(LERR_INTERNAL)| but less
obscure when written out this way.

@s goto_Trap_INTERNAL goto
@s goto_Trap_INCOMPATIBLE goto
@d goto_Trap_INTERNAL do@+ {
        reason = LERR_INTERNAL;
        goto Trap;
}@+ while (0)
@d goto_Trap_INCOMPATIBLE do@+ {
        reason = LERR_INCOMPATIBLE;
        goto Trap;
}@+ while (0)
@c
error_code
install_assembly (cell  o,
                  cell *ret)
{
        address avalue, boffset, next, page, real;
        cell arg, blob, found, label, link, lins, op, tmp;
        cell new_export, new_objectdb, new_program;
        long i, j, ioffset, objectdb_length;
        instruction ins, ivalue;
        intmax_t ito, svalue, table, uvalue;
        opcode_table *opb;
        error_code reason;

        if (!assembly_p(o) || assembly_installed_p(o) || !assembly_complete_p(o))
                return LERR_INCOMPATIBLE;

        @<Prepare a new code page@>@;
        if (pthread_mutex_lock(&Program_Lock) != 0)
                goto_Trap_INTERNAL;
        @<Ensure there is space in |ObjectDB|@>@;
        @<Look for required address symbols@>@;
        @<Add exported address symbols to a copy of |Program_Export_Table|@>@;
        @<Copy constant objects into a copy of |ObjectDB|@>@;
        @<Install instructions as bytecode and commentary@>@;

        ObjectDB = new_objectdb;
        ObjectDB_Free += objectdb_length;
        printf("odb len %d\n", array_length(ObjectDB));
        Program_Export_Table = new_export;
        *ret = new_program;
        reason = LERR_NONE;
Trap:
        pthread_mutex_unlock(&Program_Lock);
        if (failure_p(reason))
                mem_free((void *) page);
        return reason;
}

@ @<Prepare a new code page@>=
orreturn(mem_alloc(NULL, PROGRAM_LENGTH, PROGRAM_LENGTH, (void **) &page));
reason = new_atom((cell) page, NIL, FORM_PROGRAM, &new_program);
if (failure_p(reason)) {
        mem_free((void *) page);
        return reason;
}
*((cell *) page) = new_program;
ioffset = sizeof (cell) / sizeof (instruction);
assert(ioffset * sizeof (instruction) == sizeof (cell));
blob = assembly_blob(o);
if (!null_p(blob)) {
        memmove((void *) (page + sizeof (cell)), segment_base(blob),
                segment_length(blob));
        ioffset += segment_length(blob) / sizeof (instruction);
        if (ioffset * sizeof (instruction) < segment_length(blob) + sizeof (cell))
                ioffset++;
}
boffset = ioffset * sizeof (instruction);
printf("  > %u:%u\n", boffset, ioffset);

@ @<Ensure there is space in |ObjectDB|@>=
objectdb_length = (assembly_objectdb_length(o) & ~OBJECTDB_TABLE_LENGTH);
objectdb_length += OBJECTDB_TABLE_LENGTH;
printf("new objs %d .. %d\n", assembly_objectdb_length(o), objectdb_length);
if (objectdb_length > OBJECTDB_MAX - ObjectDB_Free) {
        reason = LERR_LIMIT;
        goto Trap;
}

@ @<Look for required address symbols@>=
label = assembly_requiredb(o);
while (!null_p(label)) {
        ortrap(hashtable_search(Program_Export_Table, symbol_key(lsin(label)),
                env_match,@| (void *) lsin(label), &found));
        if (undefined_p(found)) {
                reason = LERR_MISSING;
                goto Trap;
        }
        label = ldex(label);
}

@ It is safe to write the real addresses in |Program_Export_Base|
because if this installation fails |Program_Export_Free| will not
be increased the the written-on locations will be ignored and
eventually overwritten. The record of the address' location is saved
to a temporary new hashtable which will replace |Program_Export_Table|
if all goes well.

@<Add exported address symbols to a copy of |Program_Export_Table|@>=
ortrap(copy_hashtable(Program_Export_Table, env_rehash, &new_export));
next = Program_Export_Free;
for (i = 0; i < hashtable_length(assembly_exportdb(o)); i++) {
        label = hashtable_ref(assembly_exportdb(o), i); /* \.{(label . offset)} */
        if (null_p(label) || undefined_p(label))
                continue;
@#
        ortrap(int_value(ldex(label), &ito));
        if (ito < 0 || ito >= (intmax_t) ((PROGRAM_LENGTH / sizeof (instruction))
                    - ioffset))
                goto_Trap_INCOMPATIBLE;

        real = ito * sizeof (instruction);
        real += boffset;
        real |= page;
        printf("%2d      '", next); psym(lsin(label)); printf("'\tat %p (%d)\n", real, ito);
        Program_Export_Base[next] = real; /* Real location. */
@#
        ortrap(new_int_c(next, true, &link)); /* Link offset. */
        ortrap(cons(lsin(label), link, &link));
        ortrap(hashtable_save_m(new_export, symbol_key(lsin(label)), link,
                env_rehash, env_match,@| (void *) lsin(label), false, true));
@#
        next++;
        label = ldex(label);
}

@ TODO: memmove?

@.TODO@>
@<Copy constant objects into a copy of |ObjectDB|@>=
table = array_length(ObjectDB) >> OBJECTDB_TABLE_WIDTH;
ortrap(new_array(array_length(ObjectDB) + assembly_objectdb_length(o),
        NIL, &new_objectdb));
for (i = 0; i < array_length(ObjectDB); i++) {
        orassert(array_ref_c(ObjectDB, i, &tmp));
        orassert(array_set_m_c(new_objectdb, i, tmp));
}
        printf("newobj %d\n", assembly_objectdb_length(o));
for (j = 0; j < assembly_objectdb_length(o); j++) {
        orassert(array_ref_c(assembly_objectdb(o), j, &tmp));
        orassert(array_set_m_c(new_objectdb, j + i, tmp));
}

@ Actually the commentary is dropped here. It should be saved in
the data half the new program object.

@d pins(O) for (int _i = 0; _i < 4; _i++)
        printf("%02hhx", ((char *) (O))[_i])
@d psym(O) for (int _i = 0; _i < symbol_length(O); _i++)
        putchar(symbol_label(O)[_i]);
@<Install instructions as bytecode and commentary@>=
printf("  > %u:%u\n", boffset, ioffset);
for (i = 0; i < (long) assembly_length(o); i++) {
printf("assemble line %d...\n", i);
        lins = assembly_complete_ref(o, i);
        assert(statement_p(lins));
        op = statement_opcode(lins);
        opb = opcode_object(op);
        ins = htobe32((opcode_id(op) & 0xff) << 24);
        printf(" %s \t", opb->label);
        pins(&ins);
        printf("\n");
        if (opb->arg0 == NARG) {
                assert(opb->arg1 == NARG && opb->arg2 == NARG);
                if (!null_p(statement_argument(lins, 0)))
                        goto_Trap_INCOMPATIBLE;
                goto finish_arguments;
        }
        @<Encode the first argument@>@;
        @<Encode the second argument@>@;
        @<Encode the third argument@>@;
finish_arguments:
        ((instruction *) (page | boffset))[i] = ins;
        printf(" %p\t",(((instruction *) (page | boffset)) + i));
        pins(((instruction *) (page | boffset)) + i);
        printf(".\n");
}
ioffset += i;
boffset += i * sizeof (instruction);

@ First argument.

@<Encode the first argument@>=
if (null_p(statement_argument(lins, 0)))
        goto_Trap_INCOMPATIBLE;
arg = statement_argument(lins, 0);
if (opb->arg0 == AADD) {
        @<Encode a single address argument@>
} else if (opb->arg0 == ARGH) {
        @<Encode an error identifier argument@>
} else if (opb->arg0 == AREG) {
        @<Encode the first register argument@>
} else
        goto_Trap_INTERNAL;

@ ie.~24 bits.

@<Encode a single address argument@>=
assert(opb->arg1 == NARG && opb->arg2 == NARG);
if (!null_p(statement_argument(lins, 1)))
        goto_Trap_INCOMPATIBLE;
if (lsin(arg) == Label[LBA_RELATIVE]) {
        ortrap(assembly_encode_integer(24, true, ldex(arg), &svalue));
        if ((svalue < 0 && svalue < -i)
                    || svalue == 0
                    || svalue > (intmax_t) (assembly_length(o) - i)) {
                reason = LERR_OUT_OF_BOUNDS;
                goto Trap;
        }
        ins |= htobe32((svalue & 0xffffff) | (LBC_ADDRESS_RELATIVE << 30));
        printf(" relative\t"); pins(&ins); printf("\n");
} else if (lsin(arg) == Label[LBA_INDIRECT]) {
        ortrap(program_find_address(new_export, ldex(arg), &ivalue, &avalue));
        printf(" in");
        if (instruction_page(avalue) == page) {
                ivalue = avalue & PROGRAM_KEY;
                ins |= htobe32(LBC_ADDRESS_DIRECT << 30);
                printf("\b\b");
        } else
                ins |= htobe32(LBC_ADDRESS_INDIRECT << 30);
        ins |= htobe32(ivalue & 0xffffff);
        printf("direct \t"); pins(&ins); printf("\n");
} else {
        ortrap(assembly_encode_AREG(0, arg, &ivalue));
        ins |= ivalue;
        ins |= htobe32(LBC_ADDRESS_REGISTER << 30);
        printf(" target \t"); pins(&ins); printf("\n");
}

@ TODO: Allow the error object to be obtained from a register.

@<Encode an error identifier argument@>=
assert(opb->arg1 == NARG && opb->arg2 == NARG);
if (!null_p(statement_argument(lins, 1)) || lsin(arg) != Label[LBA_OBJECT]
                || !error_p(ldex(arg)))
        goto_Trap_INCOMPATIBLE;
ins |= htobe32(error_id(ldex(arg)) << 16);
printf(" error  \t"); pins(&ins); printf("\n");

@ @<Encode the first register argument@>=
ortrap(assembly_encode_AREG(0, statement_argument(lins, 0), &ivalue));
ins |= ivalue;
printf(" register\t"); pins(&ins); printf("\n");

@ Second argument.

@<Encode the second argument@>=
if (opb->arg1 == NARG)
        goto finish_arguments;
arg = statement_argument(lins, 1);
if (null_p(arg))
        goto_Trap_INCOMPATIBLE;
if (opb->arg1 == AADD) {
        @<Encode a 16-bit address@>
} else if (opb->arg1 == ALOB) {
        @<Encode a large object or link@>
} else if (opb->arg1 == ALOT) {
        @<Encode the middle ALOT@>
} else
        goto_Trap_INTERNAL;

@ // 16-bit relative only. Don't allow indirect at all (yet?).

@<Encode a 16-bit address@>=
assert(opb->arg2 == NARG);
if (lsin(arg) == Label[LBA_RELATIVE]) {
        ortrap(assembly_encode_integer(16, true, ldex(arg), &svalue));
        ins |= htobe32(svalue | (LBC_ADDRESS_RELATIVE << 30));
        printf(" relative-16\t"); pins(&ins); printf("\n");
} else if (lsin(arg) == Label[LBA_INDIRECT]) {
        ortrap(program_find_address(new_export, ldex(arg), &ivalue, &avalue));
        printf(" to %p %p\n", ivalue, avalue);
        printf(" in");
        if (instruction_page(avalue) == page) {
                ivalue = avalue & PROGRAM_KEY;
                ins |= htobe32(LBC_ADDRESS_DIRECT << 30);
                printf("\b\b");
        } else
                goto_Trap_INCOMPATIBLE;
        ins |= htobe32(ivalue & 0xffff);
        printf("direct-16\t"); pins(&ins); printf("\n");
} else
        goto_Trap_INCOMPATIBLE;

@ // ALOB; anything: int, const, pair:reg/bool, pair:table/index

@<Encode a large object or link@>=
assert(opb->arg2 == NARG);
if (lsin(arg) == Label[LBA_TABLE]) {
        ortrap(assembly_encode_integer(OBJECTDB_DB_WIDTH, false, lsin(ldex(arg)), &uvalue));
        uvalue += table;
printf(" tbl-%u", uvalue);
        uvalue = (uvalue & OBJECTDB_SPLIT_BOTTOM) |
                ((uvalue & OBJECTDB_SPLIT_BOTTOM) << OBJECTDB_SPLIT_GAP);
        uvalue <<= OBJECTDB_TABLE_WIDTH;
        ins |= htobe32(uvalue);
        ortrap(assembly_encode_integer(OBJECTDB_TABLE_WIDTH, false,
                ldex(ldex(arg)), &uvalue));
printf(" idx-%u", uvalue);
        ins |= htobe32(uvalue | (LBC_OBJECT_TABLE << 30));
        printf("\t"); pins(&ins); printf("\n");
} else if (lsin(arg) == Label[LBA_ASIS] && integer_p(ldex(arg))) {
        ortrap(int_value(ldex(arg), &svalue));
        if (svalue < INT16_MIN || svalue > INT16_MAX) {
                reason = LERR_INCOMPATIBLE;
                goto Trap;
        }
        ins |= htobe32(svalue | (LBC_OBJECT_INTEGER << 30));
        printf(" const-16\t"); pins(&ins); printf("\n");
} else {
        ortrap(assembly_encode_ALOT(1, arg, &ivalue));
        ins |= ivalue;
        if (lsin(arg) == Label[LBA_ASIS])
                ins |= (LBC_OBJECT_CONSTANT << 30);
        else
                ins |= (LBC_OBJECT_REGISTER << 30);
        printf(" ALOT-0 \t"); pins(&ins); printf("\n");
}

@ @<Encode the middle ALOT@>=
assert(opb->arg2 != NARG);
ortrap(assembly_encode_ALOT(1, arg, &ivalue));
ins |= ivalue;
printf(" ALOT-1 \t"); pins(&ins);
printf(" "); psym(lsin(arg));
printf(" %d\n", ldex(arg));
if (opb->arg2 != ALOT)
        goto_Trap_INTERNAL;

@ @<Encode the third argument@>=
if (opb->arg2 != NARG) {
        if (opb->arg2 != ALOT)
                goto_Trap_INTERNAL;
        if (null_p(statement_argument(lins, 2)))
                goto_Trap_INCOMPATIBLE;
        ortrap(assembly_encode_ALOT(2, statement_argument(lins, 2), &ivalue));
        ins |= ivalue;
        printf(" ALOT-2 \t"); pins(&ins);
printf(" "); psym(lsin(statement_argument(lins, 2)));
printf(" %d\n", ldex(statement_argument(lins, 2)));
}

@ @d PROGRAM_LINK_MAX (PROGRAM_LENGTH / sizeof (address))
@c
error_code
program_find_link (cell         db,
                   cell         label,
                   instruction *ret)
{
        cell loffset;
        intmax_t voffset;
        error_code reason;

        if (!hashtable_p(db) || !symbol_p(label))
                return LERR_INCOMPATIBLE;
        hashtable_search(db, symbol_key(label), env_match, (void *) label,
                &loffset);
        if (undefined_p(loffset))
                return LERR_MISSING;
        orreturn(int_value(ldex(loffset), &voffset));
        if (voffset < 0 || voffset >= (intmax_t) PROGRAM_LINK_MAX)
                return LERR_INTERNAL;
        *ret = voffset;
        return LERR_NONE;
}

@ @c
error_code
program_find_address (cell         db,
                      cell         label,
                      instruction *link, /* Offset in |Program_Export_Base|. */
                      address     *ret) /* Destination address. */
{
        instruction ignore;
        error_code reason;

        if (link == NULL)
                link = &ignore;
        orreturn(program_find_link(db, label, link));
        *ret = Program_Export_Base[*link];
        return LERR_NONE;
}

@ @c
error_code
assembly_encode_ALOT (int          argc,
                      cell         argv,
                      instruction *ret)
{
        assert(argc >= 0 && argc <= 2);
        assert(pair_p(argv));
        if (lsin(argv) != Label[LBA_ASIS])
                return assembly_encode_AREG(argc, argv, ret);
        if (fixed_p(ldex(argv)) && fixed_value(ldex(argv)) >= TINY_MIN
                        && fixed_value(ldex(argv)) <= TINY_MAX) {
                argv = fixed_value(ldex(argv)) + (-TINY_MIN);
                argv <<= 4;
                argv |= FIXED;
        } else if (fixed_p(argv) || !special_p(ldex(argv)))
                return LERR_INCOMPATIBLE;
                printf("LOT %x\n", ldex(argv));
        *ret = htobe32((ldex(argv) & 0xff) << ((2 - argc) * 8));
        return LERR_NONE;
}

@ @c
error_code
assembly_encode_AREG (int          argc,
                      cell         argv,
                      instruction *ret)
{
        bool popping;
        instruction rval;

        assert(argc >= 0 && argc <= 2);
        assert(pair_p(argv));
        popping = lsin(argv) == Label[LBA_REGISTER_POP];
        if (!popping && lsin(argv) != Label[LBA_REGISTER])
                return LERR_INCOMPATIBLE;
        assert(register_p(ldex(argv)));
        rval = popping << 7;
        rval |= register_id(ldex(argv));
        rval <<= ((2 - argc) * 8);
        if (argc == 1)
                rval |= LBC_FIRST_REGISTER << 30;
        else if (argc == 2)
                rval |= LBC_SECOND_REGISTER << 30;
        *ret = htobe32(rval);
        return LERR_NONE;
}

@ Not really `encoding', actually.

@c
error_code
assembly_encode_integer (int       width,
                         bool      signed_p,
                         cell      lvalue,
                         intmax_t *ret)
{
        intmax_t min, max, cvalue;
        error_code reason;

        if (width == OBJECTDB_DB_WIDTH) {
                assert(!signed_p);
                min = 0;
                max = OBJECTDB_DB_LENGTH;
        } else if (width == OBJECTDB_TABLE_WIDTH) {
                assert(!signed_p);
                min = 0;
                max = OBJECTDB_TABLE_LENGTH;
        } else if (width == 16) {
                min = signed_p ? INT16_MIN : 0;
                max = signed_p ? INT16_MAX : UINT16_MAX;
        } else if (width == 24) {
                min = signed_p ? INT32_MIN : 0;
                max = signed_p ? INT32_MAX : UINT32_MAX;
                min /= 256, max /= 256; /* |>>= 8|. */
        }
        orreturn(int_value(lvalue, &cvalue));
        if (cvalue < min || cvalue > max)
                return LERR_INCOMPATIBLE;
        *ret = cvalue;
        return LERR_NONE;
}

@** Testing.

Each unit test consists of five phases:

\item{1.} Prepare the environment.
\item{2.} Run the procedure.
\item{3.} Offer a prayer of hope to your god.
\item{4.} Validate the result.
\item{5.} Exit the test.

The test system is mostly self-contained but uses the \CEE/ library
for I/O in these functions: |llt_usage| \AM\ |llt_print_test| (CLI),
|llt_sprintf| which builds message strings (|vsnprintf|), and the
TAP API |tap_plan| \AM\ |tap_out|.

@(testless.h@>=
#ifndef LL_TESTLESS_H
#define LL_TESTLESS_H

@<Test fixture header@>@; /* Order matters. */

@<Test definitions@>@;

@<Test functions@>@;

#endif

@ The test fixture is kept in its own section to avoid visual
confusion within the previous one. Every test unit in every test
suite begins with this header.

Because the functions in \.{testless.c} don't know the final size
of the fixture until after they have been linked with the test
script this |llt_fixture_fetch| macro advances the test suite pointer
forward by the correct size.

@f llt_forward llt_thunk /* A \CEE/ type-mangling hack. */
@d llt_fixture_fetch(O,I) ((llt_header *) (((char *) (O)) +
        Test_Fixture_Size * (I)))
@<Test fixture header@>=
#define LLT_FIXTURE_HEADER                                                    \
        char       *name;      /* Name of this test unit. */                  \
        int         id;        /* Numeric identifier for listing. */          \
        int         total;     /* Total number ot units in the suite. */      \
        void      **leaks;     /* Array of allocated memory. */               \
                                                                              \
        llt_forward prepare;   /* Preparation function. */                    \
        llt_forward run;       /* Carrying out the test. */                   \
        llt_forward validate;  /* Verifying the result. */                    \
        llt_forward end;       /* Cleaning up after. */                       \
        int         progress;  /* The unit's progress through the harness. */ \
        int         tap;       /* The ID of the ``current'' test tap. */      \
        int         taps;      /* The number of taps in this unit. */         \
        int         tap_start; /* The tap ID of this unit's first tap. */     \
                                                                              \
        bool        perform;   /* Whether to carry out this unit. */          \
        error_code  expect;    /* The error expected to occur. */             \
        error_code  reason;    /* The error that did occur. */                \
        cell        res;       /* The result if there was no error. */        \
        void       *resp;      /* The same if a \CEE/ pointer is expected. */ \
        cell        meta;      /* Misc.~data saved by the validator. */       \
                                                                              \
        int         ok;        /* The final result of this unit. */

@ @<Test fun...@>=
void llt_fixture__init_common (llt_header *, int, llt_thunk, llt_thunk,
        llt_thunk, llt_thunk);
void llt_fixture_free (llt_header *);
error_code llt_fixture_grow (llt_header *, int *, int, llt_header **);
error_code llt_fixture_leak_imp (void ***, int *);
error_code llt_fixture_alloc (llt_header *, size_t, size_t, void **);
error_code llt_list_suite (llt_header *);
error_code llt_load_tests (bool, llt_header **);
error_code llt_main (int, char **, bool);
error_code llt_perform_test (int, int *, llt_header *, int *);
void llt_print_test (llt_header *);
error_code llt_run_suite (llt_header *);
error_code llt_skip_test (int *, llt_header *, char *);
error_code llt_sprintf (void ***, char **, char *, ...);
error_code llt_usage (char *, bool);
void tap_ok (llt_header *, char *, bool, cell);
void tap_out (char *, ...);
void tap_plan (int);

@ The header contains four |llt_forward| objects which should
actually be |llt_thunk| to avoid problems caused by the order of
these definitions.

@<Test def...@>=
struct llt_header;

typedef error_code @[@] (*llt_forward) (void *);

typedef struct { LLT_FIXTURE_HEADER } llt_header;

typedef error_code @[@] (*llt_initialise) (llt_header *, int *, bool,
        llt_header **);

typedef int @[@] (*llt_thunk) (llt_header *);

@ @<Test common preamble@>=
#include <assert.h>
#include <errno.h>
#include <limits.h>
#include <setjmp.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
@#
#include "lossless.h"
#include "testless.h"

@ \.{testless.c} compiles to an archive containing all of the shared
\.{llt\_} and \.{tap\_} functions.

@(testless.c@>=
#include <err.h>
#include <getopt.h>
extern int optind;
@#
@<Test common preamble@>@;
extern llt_initialise Test_Suite[];
extern int Test_Fixture_Size;

@ The shared |llt_main| function presents each test script with
common \.{-h} (help) \AM\ \.{-l} (list) options and a simple way
of specifying specific test units to run.

@d LLT_DO_TESTS 0
@d LLT_LIST_TESTS 1
@(testless.c@>=
error_code
llt_main (int    argc,
          char **argv,
          bool   init)
{
        int act, i, opt;
        char *tail;
        unsigned long value;
        llt_header *suite;
        error_code reason;

        assert(argc >= 1);
        act = LLT_DO_TESTS;
        if (argc > 1) {
                @<Parse command line options@>
        }

        if (init)
                orreturn(mem_init());
        else
                orreturn(mem_init_thread());
        orreturn(llt_load_tests(act == LLT_DO_TESTS, &suite));
        if (argc != 1) {
                @<Parse a test run specification from the command line@>
        }
        if (act == LLT_DO_TESTS)
                return llt_run_suite(suite);
        else
                return llt_list_suite(suite);
}

@ Long options are also supported because why not?

@<Parse command line options@>=
static struct option llt_common_options[] = {@|
        { "help", no_argument, NULL, 'h' },@|
        { "list", no_argument, NULL, 'l' },@|
        { NULL, 0, NULL, 0 }@/ /* What's all this then? */
};

while ((opt = getopt_long(argc, argv, "lh", llt_common_options, NULL)) != -1) {
        switch (opt) {
        case 'l':
                act = LLT_LIST_TESTS;@+
                break;
        case 'h':
                return llt_usage(argv[0], true);
        default:
                return llt_usage(argv[0], false);
        }
}
argc -= optind - 1;

@ The script with no arguments runs all test units. The script can
be restricted to specific units can by identifying them on the
command line. The identifier is obtained with the \.{-l}\L\.{--list}
option.

@.TODO@>
@<Parse a test run specification from the command line@>=
for (i = 0; i < suite->total; i++)
        llt_fixture_fetch(suite, i)->perform = false;
for (i = 1; i < argc; i++) {
        if (argv[(optind - 1) + i][0] < '1' || argv[(optind - 1) + i][0] > '9') {
@t\4@>
invalid_id:
                errc(1, EINVAL, "Invalid test id `%s'; maximum is %d",
                        argv[(optind - 1) + i], suite->total);
        } else {
                errno = 0;
                value = strtoul(argv[(optind - 1) + i], &tail, 10);
                if (*tail != '\0' || errno == ERANGE || value > INT_MAX)
                        goto invalid_id;
                if ((int) value > suite->total)
                        goto invalid_id;
                if (llt_fixture_fetch(suite, value)->perform)
                        warn("Duplicate test id %lud", value);
                llt_fixture_fetch(suite, value - 1)->perform = true;
        }
}

@ TODO: Adjust tabbing for the length of |name|.

@.TODO@>
@(testless.c@>=
error_code
llt_usage (char *name,
           bool  ok)
{
        printf("Usage:\n");
        printf("\t%s\t\t\tRun all tests.\n", name);
        printf("\t%s -l | --list\tList all test cases as an s-expression.\n",
                name);
        printf("\t%s id...\t\tRun the specified tests.\n", name);
        printf("\t%s -h | --help\tDisplay this help and exit.\n", name);
        return ok ? LERR_NONE : LERR_USER;
}

@ When the harness first starts it initialises the fixtures for all
the test cases by calling each function mentioned in |Test_Cases|.
Those which have an expensive initialisation routine can skip it
if the script is only listing the test unit titles.

Each test unit initialiser will enlarge the buffer holding the suite
as much as it needse and increment the |num_tests| variable by the
number of individual test units which were added. The number of
taps in each unit is then counted and a running total of each unit's
starting tap and the total number of taps is kept.

@(testless.c@>=
error_code
llt_load_tests (bool         full,
                llt_header **ret)
{
        llt_header *r;
        llt_initialise *tc;
        int before, i, num_tests, tap;
        error_code reason;

        orreturn(mem_alloc(NULL, Test_Fixture_Size, 0,
                (void **) &r));
        num_tests = 0;
        tap = 1;
        tc = Test_Suite;
        while (*tc != NULL) {
                before = num_tests;
                orreturn((*tc)(r, &num_tests, full, &r));
                for (i = before; i < num_tests; i++) {
                        llt_fixture_fetch(r, i)->tap_start = tap;
                        tap += llt_fixture_fetch(r, i)->taps;
                }
                tc++;
        }
        for (i = 0; i < num_tests; i++)
                llt_fixture_fetch(r, i)->total = num_tests;
        *ret = r;
        return LERR_NONE;
}

@ Listing the test units. Specifying the tests to list is probably
pointless but easier than complaining about an erroneous specification.

@(testless.c@>=
error_code
llt_list_suite (llt_header *suite)
{
        int i;

        for (i = 0; i < suite->total; i++)
                if (llt_fixture_fetch(suite, i)->perform)
                        llt_print_test(llt_fixture_fetch(suite, i));
        return LERR_NONE;
}

@ @(testless.c@>=
void
llt_print_test (llt_header *o)
{
        char *p;

        printf("(%d |", o->id + 1);
        for (p = o->name; *p; p++) {
                if (*p == '|' || *p == '#')
                        putchar('#');
                putchar(*p);
        }
        printf("|)\n");
}

@ To run a suite each unit in turn is passed through |llt_perform_test|
or |llt_skip_test| if it wasn't included in a command line
specification. If the number of taps a unit claimed and the number
it performed differ then a warning will be emitted and the tap
stream that gets output will be broken (test IDs will clash).

TODO: Should I not reset the tap start ID each time and instead
vigorously enforce incrementing the output tap id?

@.TODO@>
@d LLT_RUN_ABORT   -1
@d LLT_RUN_FAIL     1
@d LLT_RUN_CONTINUE 0
@d LLT_RUN_OK       LLT_RUN_CONTINUE /* There is no try. */
@d LLT_RUN_PANIC    2
@(testless.c@>=
error_code
llt_run_suite (llt_header *suite)
{
        int i, run, t;
        error_code reason;

        t = 0;
        for (i = 0; i < suite->total; i++)
                t += llt_fixture_fetch(suite, i)->taps;
        tap_plan(t);
        run = 0;
        t = 1;
        for (i = 0; run != LLT_RUN_ABORT && i < suite->total; i++) {
                if (llt_fixture_fetch(suite, i)->perform) {
                        t = llt_fixture_fetch(suite, i)->tap_start;
                        orreturn(llt_perform_test(run, &t,
                                llt_fixture_fetch(suite, i), &run));
                        if (t != llt_fixture_fetch(suite, i)->tap_start
                                    + llt_fixture_fetch(suite, i)->taps)
                                warn("Test tap mismatch: %d != %d", t,
                                        llt_fixture_fetch(suite, i)->tap_start
                                            + llt_fixture_fetch(suite, i)->taps);
                 } else {
                        orreturn(llt_skip_test(&t,
                                llt_fixture_fetch(suite, i), "command line"));
                }
        }
        return LERR_NONE;
}

@ If the test is being skipped then the appropriate number of taps
are printed in place of running the unit.

@(testless.c@>=
error_code
llt_skip_test (int        *tap,
               llt_header *testcase,
               char       *excuse)
{
        int i;
        char *msg;
        error_code reason;

        orreturn(llt_sprintf(&testcase->leaks, &msg,
                "--- # SKIP %s", excuse));
        testcase->tap = *tap;
        testcase->progress = LLT_PROGRESS_SKIP;
        for (i = 0; i < testcase->taps; i++)
                tap_ok(testcase, msg, true, NIL);
        *tap = testcase->tap;
        return LERR_NONE;
}

@ Actually perform a test. Call the preparatation routine if there
is one then carry out the desiered action and validate the result.
The protection around |Test_Memory| is necessary but the paranoia
behind saving and restoring the prior value is probably not --- if
|Test_Memory->active| was previously true then the clean up routine
should certainly set it stright back to false again.

Some care is taken to protect against errors in the four test stages
themselves but really they shouldn't be necessary if the test
complexity is kept under control.

There is no need to cast the function pointers to a real |llt_thunk|
because the only difference from |llt_forward| is that the latter
uses |void *| for its pointer argument types.

@(testless.c@>=
error_code
llt_perform_test (int         runok,
                  int        *tap,
                  llt_header *testcase,
                  int        *ret)
{
        bool allocating;
        int n, r;

        if (runok == LLT_RUN_ABORT || testcase->progress != LLT_PROGRESS_INIT)
                return LERR_INTERNAL;
@#
        n = testcase->prepare == NULL ? LLT_RUN_CONTINUE
                : testcase->prepare(testcase);
        if (n != LLT_RUN_CONTINUE) {
                *ret = n;
                return LERR_NONE;
        }
        testcase->progress = LLT_PROGRESS_PREPARE;
@#
        if (testcase->run == NULL)
                return LERR_INTERNAL;
        n = testcase->run(testcase);
        if (n != LLT_RUN_CONTINUE) {
                *ret = n;
                return LERR_NONE;
        }
        testcase->progress = LLT_PROGRESS_RUN;
@#
        if (testcase->validate == NULL)
                return LERR_INTERNAL;
        if (Test_Memory != NULL) {
                allocating = Test_Memory->active;
                Test_Memory->active = false;
        }
        testcase->tap = *tap;
        r = testcase->validate(testcase);
        *tap = testcase->tap;
        if (runok != LLT_RUN_OK)
                r = runok;
        if (Test_Memory != NULL)
                Test_Memory->active = allocating;
@#
        n = testcase->end == NULL ? LLT_RUN_CONTINUE
                : testcase->end(testcase);
        if (n != LLT_RUN_CONTINUE)
                return LLT_RUN_PANIC;
        *ret = r;
        return LERR_NONE;
}

@* Testing memory allocation. Those tests which need to mock the
core memory allocator point |Test_Memory| to an instance of this
object (eg.~created in |main| before calling |llt_main|) with
pointers to alternative allocation and release functions.

@ @<Type def...@>=
typedef struct {
        bool active; /* Whether |mem_alloc| should revert to these. */
        bool available; /* Whether the false allocation should succeed. */
        error_code (*alloc)(void *, size_t, size_t, void **);
        error_code (*free)(void *);
} llt_allocation;

@ @<Global...@>=
shared llt_allocation *Test_Memory = NULL;

@ @<Extern...@>=
extern shared llt_allocation *Test_Memory;

@ These sections are responsible for diverting allocation and
deallocation to the alternatives. The code is proteced by preprocessor
macros so it will not be included in a non-test binary.

@<Testing memory allocator@>=
if (Test_Memory != NULL && Test_Memory->active)
        return Test_Memory->alloc(old, length, align, ret);

@ @<Testing memory deallocator@>=
if (Test_Memory != NULL && Test_Memory->active)
        return Test_Memory->free(o);

@* Allocating memory while testing.

Increase the size of the budding test suite by |delta| unit fixtures.

@(testless.c@>=
error_code
llt_fixture_grow (llt_header  *o,
                  int         *length,
                  int          delta,
                  llt_header **ret)
{
        return mem_alloc(o, Test_Fixture_Size * (*length + delta), 0,
                (void **) ret);
}

@ @d LLT_PROGRESS_INIT   0
@d LLT_PROGRESS_PREPARE  1
@d LLT_PROGRESS_RUN      2
@d LLT_PROGRESS_VALIDATE 3
@d LLT_PROGRESS_END      4
@d LLT_PROGRESS_SKIP     5
@(testless.c@>=
void
llt_fixture__init_common (llt_header *fixture,
                          int         id,
                          llt_thunk   prepare,
                          llt_thunk   run,
                          llt_thunk   validate,
                          llt_thunk   end)
{
        fixture->name = "";
        fixture->id = id;
        fixture->total = -1;
        fixture->leaks = NULL;
        fixture->perform = true;
        fixture->prepare = (llt_forward) prepare;
        fixture->run = (llt_forward) run;
        fixture->validate = (llt_forward) validate;
        fixture->end = (llt_forward) end;
        fixture->progress = LLT_PROGRESS_INIT;
        fixture->taps = 1;
        fixture->tap = fixture->tap_start = 0;
        fixture->ok = false;
        fixture->res = NIL;
        fixture->resp = NULL;
        fixture->reason = fixture->expect = LERR_NONE;
}

@ Ordinarily test scripts are expected to be run once and immediately
quit and so expect to be able to allocate memory with wild abandon
without caring to clean it up. In case there is a desire to have
scripts remain in memory the allocations made by/for each fixture
are kept in an array of pointers in the |leak| attribute, itself
made from such an allocation the first time one is requested.

@(testless.c@>=
error_code
llt_fixture_leak_imp (void ***abuf,
                      int    *ret)
{
        int length;
        error_code reason;

        if (*abuf == NULL) {
                orreturn(mem_alloc(NULL, sizeof (void *) * 2,
                        0, (void **) abuf));
                length = 1;
        } else {
                length = ((long) (*abuf)[0]) + 1;
                if (length >= INT_MAX)
                        return LERR_LIMIT;
                orreturn(mem_alloc(*abuf,
                        sizeof (void *) * length + 1, 0, (void **) abuf));
        }
        (*abuf)[0] = (void *) (long) length;
        (*abuf)[length] = NULL;
        *ret = length;
        return LERR_NONE;
}

@ To also get the allocation's ID (index into |abuf|) take |(*abuf)[0]|
immediately after calling this.

@(testless.c@>=
error_code
llt_fixture_alloc (llt_header  *tc,
                   size_t       length,
                   size_t       stride,
                   void       **ret)
{
        int idx;
        error_code reason;

        orreturn(llt_fixture_leak_imp(&tc->leaks, &idx));
        orreturn(mem_alloc(NULL, length, stride, &tc->leaks[idx]));
        *ret = tc->leaks[idx];
        return LERR_NONE;
}

@ Although nothing uses it the |llt_fixture_free| function will
clean up a fixture's memory allocations.

Ignores error returns but |free| doesn't fail anyway.

@(testless.c@>=
void
llt_fixture_free (llt_header *testcase)
{
        int i;

        if (testcase->leaks != NULL) {
                for (i = 0; i < (long) testcase->leaks[0]; i++)
                        mem_free(testcase->leaks[i]);
                mem_free(testcase->leaks);
        }
}

@ The main consumer of |llt_fixture_leak| thus far is this wrapper
around \.{printf}, which repeatedly enlarges a buffer until a
short-ish message can be formatted into it, then reduces the
allocation to the minimum size and returns it.

@(testless.c@>=
error_code
llt_sprintf (void     ***abuf,
             char      **ret,
             char       *fmt, ...)
{
        int length, pret, pidx;
        va_list args;
        error_code reason;

        orreturn(llt_fixture_leak_imp(abuf, &pidx));
        length = 0;
        (*abuf)[pidx] = NULL;
        while (1) {
                length += 128;
                orreturn(mem_alloc((*abuf)[pidx],
                        sizeof (char) * length, 0, (void **) &((*abuf)[pidx])));
                va_start(args, fmt);
                pret = vsnprintf((*abuf)[pidx], length, fmt, args);
                va_end(args);
                if (pret < 0)
                        return LERR_SYSTEM;
                else if (pret < length)
                        break;
        }
        orreturn(mem_alloc((*abuf)[pidx],
                sizeof (char) * (pret + 1), 0,
                (void **) &((*abuf)[pidx])));
        *ret = (*abuf)[pidx];
        return LERR_NONE;
}

@* TAP. Tap routines to implement a rudimentary stream of test
results in the \pdfURL{{\it Test Anything Protocol\/}}%
{http://testanything.org/}\footnote{$^1$}{\.{http://testanything.org/}}

@(testless.c@>=
void
tap_plan (int length)
{
        assert(length >= 1);
        printf("1..%d\n", length);
}

@ @(testless.c@>=
void
tap_ok (llt_header *testcase,
        char       *title,
        bool        result,
        cell        meta)
{
        assert(testcase->progress == LLT_PROGRESS_RUN
                || testcase->progress == LLT_PROGRESS_SKIP);
        testcase->meta = meta;
        testcase->ok = result ? LLT_RUN_OK : LLT_RUN_FAIL;
        if (result)
                tap_out("ok");
        else
                tap_out("not ok");
        tap_out(" %d - ", testcase->tap++);
        if (testcase->name != NULL)
                tap_out("%s: ", testcase->name);
        tap_out("%s\n", title);
}

@ @(testless.c@>=
void
tap_out (char *fmt, ...)
{
        va_list args;

        va_start(args, fmt);
        vprintf(fmt, args);
        va_end(args);
}

@* Test suite tests.

@(t/insanity.c@>=
@<Test common preamble@>@;

int
main (int    argc,
      char **argv)
{@+
        return llt_main(argc, argv, true);@+
}

@ Most test scripts will use a customised |llt_fixture| object
(which needn't be called that). The full size must be put in
|Test_Fixture_Size|.

@(t/insanity.c@>=
typedef struct {
        LLT_FIXTURE_HEADER@;
        instruction *program;
} llt_fixture;

int Test_Fixture_Size = sizeof (llt_fixture);

@ This suite consists of a single unit initialised by |llt_Sanity__Nothing|.

@(t/insanity.c@>=
error_code llt_Sanity__Nothing (llt_header *, int *, bool, llt_header **);
error_code llt_Sanity__Halt (llt_header *, int *, bool, llt_header **);
int llt_Sanity__prepare (llt_header *);
int llt_Sanity__noop (llt_header *);
int llt_Sanity__interpret (llt_header *);
int llt_Sanity__validate (llt_header *);

llt_initialise Test_Suite[] = {
        llt_Sanity__Nothing,
        llt_Sanity__Halt,
        NULL
};

@ The Nothing test unit has a single test case in it which requires
no preparation or cleanup.

@(t/insanity.c@>=
error_code
llt_Sanity__Nothing (llt_header  *suite,
                     int         *count,
                     bool         full @[unused@],
                     llt_header **ret)
{
        llt_fixture *tc;
        error_code reason;

        orreturn(llt_fixture_grow(suite, count, 1, &suite));
        tc = (llt_fixture *) suite;
        llt_fixture__init_common((llt_header *) (tc + *count), *count,
                NULL,
                llt_Sanity__noop,
                llt_Sanity__validate,
                NULL);
        tc[*count].name = "do nothing";
        tc[*count].program = NULL;
        tc[*count].taps = 2;
        (*count)++;
        *ret = suite;
        return LERR_NONE;
}

@
@(t/insanity.c@>=
error_code
llt_Sanity__Halt (llt_header  *suite,
                  int         *count,
                  bool         full @[unused@],
                  llt_header **ret)
{
        llt_fixture *tc;
        error_code reason;
        instruction *pins;

        orreturn(llt_fixture_grow(suite, count, 1, &suite));
        tc = (llt_fixture *) suite;
        llt_fixture__init_common((llt_header *) (tc + *count), *count,
                llt_Sanity__prepare,
                llt_Sanity__interpret,
                llt_Sanity__validate,
                NULL);
        tc[*count].name = "HALT";
        orreturn(llt_fixture_alloc((llt_header *) (tc + *count),
                sizeof (instruction), 0, (void **) &pins));
        pins[0] = htobe32(OP_HALT);
        tc[*count].program = pins;
        tc[*count].taps = 2;
        (*count)++;
        *ret = suite;
        return LERR_NONE;
}

@ @(t/insanity.c@>=
int
llt_Sanity__prepare (llt_header *testcase_ptr @[unused@])
{
        llt_fixture *tc = (llt_fixture *) testcase_ptr;

        Ip = (address) tc->program;

        return LLT_RUN_OK;
}

@ Nothing in \Ls/ is tested by this test although the parts used
by the test harness are exercised.

@(t/insanity.c@>=
int
llt_Sanity__noop (llt_header *testcase_ptr @[unused@])
{
        return LLT_RUN_OK;
}

@ @(t/insanity.c@>=
int
llt_Sanity__interpret (llt_header *testcase_ptr @[unused@])
{
        interpret();
        return LLT_RUN_OK;
}

@ @(t/insanity.c@>=
int
llt_Sanity__validate (llt_header *testcase_ptr)
{
        tap_ok(testcase_ptr, "done", true, NIL);
        tap_ok(testcase_ptr, "VPU is not trapped", !Trapped, NIL);
        return testcase_ptr->ok;
}

@* Memory allocator tests.











@** Hacks and other trivia.

@<Fun...@>=
int high_bit (digit);

@ @<Const...@>=

@ @d rune_valid_p(O)   true
@ @d rune_codepoint(O) 42
@ @d UNICODE_MAX       0x10ffffl

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

@ @<Portability hacks@>=
#ifdef __GNUC__ /* \AM\ clang */
#       define unused __attribute__ ((__unused__))
#else
#       define unused /* noisy compiler */
#endif
@#
#ifdef __GNUC__ /* \AM clang */
#       define Lnoreturn __attribute__ ((__noreturn__))
#else
#       ifdef _Noreturn
#               define Lnoreturn _Noreturn
#       else
#               define Lnoreturn /* noisy compiler */
#       endif
#endif
@#
#ifdef LDEBUG
#       define LDEBUG_P true
#else
#       define LDEBUG_P false
#endif
@#
#if EOF == -1
#       define FAIL -2
#else
#       define FAIL -1
#endif

#define ckd_add(r,x,y) @[__builtin_add_overflow((x), (y), (r))@]
#define ckd_sub(r,x,y) @[__builtin_sub_overflow((x), (y), (r))@]
#define ckd_mul(r,x,y) @[__builtin_mul_overflow((x), (y), (r))@]

@** Index.

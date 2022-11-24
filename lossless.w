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
@s or_int_value_bounds return
@s orreturn return
@s ortrap return
@s shared static
@s unique static
@s unused static
%
@s address int
@s atom int
@s byte int
@s cell int
@s cell_tag int
@s error_code int
@s half int
@s hash int
@s hashtable_raw int
@s heap int
@s heap_alloc_fn int
@s heap_enlarge_fn int
@s heap_enlarge_p_fn int
@s heap_pun int
@s init_heap_fn int
@s opcode int
@s opcode_table int
@s osthread int
@s primitive int
@s primitive_code int
@s primitive_table int
@s scow int
@s segment int
@s statement_parser int
@s symbol int
@s word int
%
@s llt_allocation int
@s llt_fixture int
@s llt_forward int
@s llt_header int
@s llt_initialise int
@s llt_thunk int

@** Preface. There are many programming languages and this one is
mine. \Ls/ is a general purpose programming language with a lisp/scheme
look and feel. If you have received this document in electronic
form it should have been accompanied with sources and a \.{README}
file describing how to build and test \Ls/ on various platforms.
If you received this document as a hard copy I would be very
interested to know how and why, as it's woefully incomplete and I
have not printed any hard copies, even for proofreading, but in
that case you'll have to type in the code yourself.

Alternatively \Ls/ exists primarily as a package of source distributed
through the web. The primary home for the source code is at
\pdfURL{http://zeus.jtan.com/\string~chohag/lossless/}%
{http://zeus.jtan.com/\string~chohag/lossless/} describing the git
repository at \pdfURL{http://zeus.jtan.com/\string~chohag/lossless.git}%
{http://zeus.jtan.com/\string~chohag/lossless.git}. Additionally
the sources are occasionaly packaged up in a tarball along with the
processed \CEE/ sources so that \TeX\ is optional.

If \Ls/ were complete it would include a comprehensive suite of
documentation. This particular document would fit in that suite as
a sort of appendix --- available for people who are familiar with
using \Ls/ (or not) to look into and learn or improve its implementation
--- so it is neither comprehensive nor pedagogical.

Of course \Ls/ is not in fact complete and this document is its only
one. It is laid out as follows:

\yitem{1 } Introduction to the \CEE/ implementation and error handling.

What source files there are and why, how to build them, how to run
\Ls/ and/or link to and use it dynamically.

Includes a description of the rules governing variable and function
(etc.) names.

\yitem{2 } Memory \AM\ data structures.

How to allocate and release (free) memory, and the
mostly-functional\footnote{$^1$}{Functional in the mathematical
sense not (only) in that they are fully operational.} code to
implement the few object required to operate the virtual machine.

\yitem{3 } Bare stubs to support I/O and threading.

Just enough of an object wrapping around a file descriptor to read
and assemble source code, and enough of a threads implentation to
put mutexes around critical process-global objects.

\yitem{4a} A bytecode-interpreting virtual machine.

Decode, Execute, Repeat. Like a REPL for robots, which don't read.

\yitem{4b} A bytecode assembler.

Far more effort than it seems like it should require, even this
strictly line-based parser and assembler is the largest, most
complicated piece of this implementation.

\yitem{5 } Test suite.

Some things it's better to begin with than try to retro-fit to an
existing product. As well as thread support from day one \Ls/ also
begins its existence with a comprehensive test suite.

\yitem{6 } Leftovers.

Vaguely unimportant things that don't belong anywhere else, and the
index.

It should be evident by now that your author is not particularly
skilled in the \TeX nical arts but rather is using it as a means
to an end. I will also endeavour to talk only in the third person
as I try to avoid referring to the author anyway.

@** Implementation. Although its appearance as a PDF file (or
similar) is unconventional \Ls/ is a fairly trivial \CEE/ program
with no dependencies other than the standard library (and \TeX\
which is huge, semi-optional and also has minimal dependencies).

\Ls/' source comes in the these files:

\yskip\hskip3em\vbox{\halign{\quad#\hfil&\quad#\hfil&\quad#\hfil\cr
\.{README}&Unpacking the source\cr
\.{README.deploy}&Packing the source\cr
\.{lossless.w}&The \CEE/ parts of \Ls/ (including {\it primitives\/})\cr
\.{barbaroi.ll}&The \Ls/ parts of \Ls/ (not primitive)\cr
\.{evaluate.la}&Assembly source of the \Ls/ interpreter\cr
\.{man/man{\it n\/}l/*}&Neglected unix manual page documentation\cr
\.{man/man{\it n\/}l/intro.{\it n\/}l}&A description of each section's
        contents\cr
\.{man/man9l/TEMPLATE.9l}&Manual page source template\cr
\.{perl/*}&Neglected proof-of-concept library wrapper\cr
\.{Makefile}&Build Plumbing\cr
\.{bin/bin2c}&\ditto\cr
\.{bin/reindex}&\ditto\cr
\.{.gitignore}&Administrivia \AM\ Notes\cr
\.{LICENSE}&\ditto\cr
\.{llfig.mp}&\ditto\cr
\.{PLAN}&\ditto\cr
\.{PLAN.man}&\ditto\cr
}}

\yskip When \Ls/ is built these files are generated. Alternatively
if you have downloaded the packaged sources rather than cloning a
source repository then they come pre-built inside it and you don't
need \TeX\ to compile \Ls/.

\yskip\hskip3em\vbox{\halign{\quad#\hfil&\quad#\hfil&\quad#\hfil\cr
\.{lossless.c}&The \CEE/ parts of \Ls/\cr
\.{lossless.h}&A header file for linking to \.{lossless.o} or its
        dynamic equivalent\cr
\.{testless.c}&\CEE/ code shared between test units\cr
\.{testless.h}&\ditto\cr
\.{t/*.c}&A comprehensive suite of test units\cr
}}

Building generates a bit of mess in the working directory which
\.{make clean} removes (mostly) and of course each \CEE/ source
file is compiled to a corresponding static library (\.{*.o}). The
following files are also created:

\yskip\hskip3em\vbox{\halign{\quad#\hfil&\quad#\hfil&\quad#\hfil\cr
\.{lossless}&\Ls/\cr
\.{initialise.o}&The contents of \.{barbaroi.ll} and \.{evaluate.la}\cr
\.{memless.o}&\.{lossless.o} for tests of the memory allocator\cr
\.{liblossless.so}&Shared library for linking to \Ls/ dynamically\cr
}}\footnote{$^1$}{Windows support is practically non-existent, but is
        planned and would call this \.{lossless.dll}.}

As well as \.{clean} and the default \.{all} there are other
interesting \.{make} targets:

\yskip\hskip3em\vbox{\halign{\quad#\hfil&\quad#\hfil&\quad#\hfil\cr
\.{dist}&Build a distributable release\cr
\.{test}&Build and lauch the comprehensive test suite\cr
\.{lossless.pdf}&This document\cr
\.{man/mandoc.db}&\Ls/' manual database\cr
}}

@ The bulk of \Ls/' source is in \.{lossless.w}. This \.{CWEB}
source file is compiled by \.{ctangle} to produce \CEE/ sources or
by \.{cweave} to produce \TeX\ sources. The \TeX\ sources are
compiled by \TeX\ to produce this document \.{lossless.pdf} while
the \CEE/ sources are compiled by a \CEE/ compiler into static and
shared libraries.

The main library file produced is the static \.{lossless.o} and
there's a variant which has hooks in the memory allocator named
\.{memless.o}. Also produced from \.{lossless.w} is \.{testless.o}
which is linked into each test script alongside \.{memless.o} and
contains the functions shared by \Ls/' test suite.

All of this is taken care of in the \.{Makefile}, compatible with
BSD and GNU make simultaneously.

@ The only intermediate source file of interest outside the \Ls/
build process is \.{lossless.h} which is necessary to link to the
\Ls/ shared library or write extensions, although for practical
reasons it contains many more definitions than library users require
(that is: all of them).

The contents of \.{lossless.h} are described by the code block
attached to this section. Code blocks may be named such as this one
with a filename presented in a monospace font (\.{@@(filename@@>=}
in \.{CWEB} source) and cause \.{CWEB} to concatenate all such
sections to produce the file named. In fact \.{lossless.h} is
generated by just this one section however it includes references
to other sections by name (such as the next one, |@<System head...@>|)
which are themselves concatenated and inserted in place.

The special section name ``Preprocessor definitions'' consists of
all the \#|define| lines (\.{@@d} in \.{CWEB}) that preceed code
sections.

Finally there are sections that do have a block of code but one
without a name. These become \.{lossless.c} and begin \.{@@c} in
\.{CWEB}.

@ @(lossless.h@>=
#ifndef LL_LOSSLESS_H
#define LL_LOSSLESS_H
@<System headers@>@;
@h
@<Essential types@>@;
@<Type definitions@>@;
@<Function declarations@>@;
@<External \CEE/ symbols@>@;
@<Hacks and warts@>@;
#endif

@ These system headers are required globally and included in the
main header \.{lossless.h}. Perhaps they shouldn't be.

@<System headers@>=
#include <err.h>
#include <errno.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdint.h>
#include <unistd.h>

@ This is the start of \.{lossless.c} --- system header files which
are not required by the definitions in \.{lossless.h} followed by
\Ls/' global variables (and then every other un-named section of
code).

@c
#include <assert.h> /* Definitely not for library code. */
#include <stdio.h> /* To be removed when \Ls/ I/O is usable. */
#include <stdlib.h>
#include <ctype.h> /* Some ASCII macros. */
#include <string.h> /* Bulk memory transfers, and |strlen|. */
#include "lossless.h"
@<Global variables@>@;

@ Non-\CEE/ source code which is compiled by \Ls/ as it starts up
is baked into the binary through \.{initialise.c}, where it is kept
separate from the compiled \CEE/ in order to ease future plans for
growth.

@(initialise.c@>=
#include <assert.h>
#include <string.h>
#include <stdio.h> /* To be removed when \Ls/ I/O is usable. */
#include "lossless.h"
@<Data for initialisation@>@;

@ This is the first of the warts which don't have a sensible place
to live. The definition of \.{unused} silences compiler warnings
when function arguments are unused. \.{shared} \AM\ \.{unique}
distinguish between global variables which are accessible to all
and private to each individual thread. TODO: They should not be here.

@.TODO@>
@d shared /* Global variable visible to all threads. */
@d unique __thread /* Global variable private to each thread. */
@<Hacks...@>=
#ifdef __GNUC__ /* \AM\ clang */
#define unused __attribute__ ((__unused__))
#else
#define unused /* noisy compiler */
#endif

@* Errors. All code comes with errors and before going any further
the errors that can occur in \Ls/ are defined. The simplest of
mechanisms is used for functions which could fail, which is nearly
all of them: a status code representing what went wrong is returned.
The actual value being returned is saved to an address pointed to
by the last argument.

The macros below check the error status code of such a function and
``give up'' somehow, depending on what is most appropriate. The
macros were created in an ad-hoc fashion as the need arose and now
only {\it orabort\/}, {\it orassert\/}, {\it orreturn\/} and {\it
ortrap\/} are used --- mostly the latter two.

@d failure_p(O) ((O) != LERR_NONE)
@d just_abort(E,M) err((E), "%s: %u", (M), (E))
@d do_or_abort(R,I) do@+ {@+ if (failure_p(((R) = (I))))
        just_abort((R), #I);@+ }@+ while (0)
@d do_or_return(R,I) do@+{@+ if (failure_p((R) = (I)))
        return (R);@+ }@+ while (0)
@d do_or_trap(R,I) do@+{@+ if (failure_p((R) = (I)))
        goto Trap;@+ }@+ while (0)
@d orabort(I) do_or_abort(reason, I)
@d orreturn(I) do_or_return(reason, I)
@d ortrap(I) do_or_trap(reason, I)
@#
@d do_or_assert(R,I) do@+ {@+ (R) = (I);@+
        assert(#I && !failure_p(R));@+ }@+ while (0)
@d orassert(I) do@+ {@+ reason = (I);@+
        assert(#I && !failure_p(reason));@+ }@+ while (0)

@ These are all the ways that an \Ls/ internal function can fail.
Some of these codes were defined when \Ls/ still had a custom parser
and remain here in case it ever comes back.

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
        LERR_SELF,           /* An attempt to wait for oneself. */
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

@ This is the same list with the run-time label each will be bound
to.

@<Data...@>=
shared char *Error_Label[LERR_LENGTH] = {@|
        [LERR_FINISHED]       = "already-finished",@|
        [LERR_AMBIGUOUS]      = "ambiguous-syntax",@|
        [LERR_THREAD]         = "bad-join",@|
        [LERR_EXISTS]         = "conflicted-binding",@|
        [LERR_DOUBLE_TAIL]    = "double-tail",@|
        [LERR_EOF]            = "end-of-file",@|
        [LERR_IMMUTABLE]      = "immutable",@|
        [LERR_IMPROPER]       = "improper-list",@|
        [LERR_ADDRESS]        = "invalid-address",@|
        [LERR_INSTRUCTION]    = "invalid-instruction",@|
        [LERR_INCOMPATIBLE]   = "incompatible-operand",@|
        [LERR_INTERRUPT]      = "interrupted",@|
        [LERR_IO]             = "io", /* Helpful. */@t\iII@>
        [LERR_INTERNAL]       = "lossless-error",@|
        [LERR_MISMATCH]       = "mismatched-brackets",@|
        [LERR_MISSING]        = "missing",@|
        [LERR_NONCHARACTER]   = "noncharacter",@|
        [LERR_NONE]           = "no-error",@|
        [LERR_LISTLESS_TAIL]  = "non-list-tail",@|
        [LERR_OUT_OF_BOUNDS]  = "out-of-bounds",@|
        [LERR_OOM]            = "out-of-memory",@|
        [LERR_OVERFLOW]       = "overflow",@|
        [LERR_USER]           = "pebdac", /* Problem Exists
                                Between Developer And Compiler. */@t\iII@>
        [LERR_BUSY]           = "resource-busy",@|
        [LERR_LEAK]           = "resource-leak",@|
        [LERR_LIMIT]          = "software-limit",@|
        [LERR_SYNTAX]         = "syntax-error",@|
        [LERR_SYSTEM]         = "system-error",@|
        [LERR_HEAVY_TAIL]     = "tail-mid-list",@|
        [LERR_UNCLOSED_OPEN]  = "unclosed-list",@|
        [LERR_UNCOMBINABLE]   = "uncombinable",@|
        [LERR_UNDERFLOW]      = "underflow",@|
        [LERR_UNIMPLEMENTED]  = "unimplemented",@|
        [LERR_UNLOCKED]       = "unlocked-resource",@|
        [LERR_UNOPENED_CLOSE] = "unopened-list",@|
        [LERR_UNPRINTABLE]    = "unprintable",@|
        [LERR_UNSCANNABLE]    = "unscannable-lexeme",@|
        [LERR_EMPTY_TAIL]     = "unterminated-tail",@|
        [LERR_SELF]           = "wait-for-self",@/
};

@ Each type of error has a unique object created to represent it
at run-time. These objects are saved in the |Error| array as they
are initialised.

Run-time objects will be described in greater detail after the
memory layout has been defined.

@d error_id_c(O)    (A(O)->sin)
@d error_label_c(O) (A(O)->dex)
@d error_object(O)  (&Error[fixed_value(error_id_c(O))])
@<Global...@>=
shared cell Error[LERR_LENGTH];

@ @<Extern...@>=
extern shared cell Error[];

@ An error object is a tagged pair with the index into |Error| in
one half and a symbol created from the above label in the other.

@<Initialise error...@>=
for (i = 0; i < LERR_LENGTH; i++) {
        orreturn(new_symbol_cstr(Error_Label[i], &ltmp)); /* New symbol. */
        orreturn(new_atom(fix(i), ltmp, FORM_ERROR, &Error[i])); /* Error
                                                object; ID \AM\ label. */
        orreturn(env_save_m(Root, error_label_c(Error[i]), Error[i],
                false)); /* Run-time inding. */
}

@* Naming things. Harder than the halting problem, this has also
not been solved. Much improvement could be made to the names currently
in use.

Macro constants are named in |ALL_CAPS|.

Global variables are named using |Title_Case|.

Everything else is named in |lower_case| except macro variables,
which are a single capital letter.

\yskip

Some variable names always mean the same thing in their local
context:

|o|: The object being considered; the first or only argument to a
function.

|O|: The same, in a macro.

|reason|: The local error code value.

|ret|: A pointer to the location to save the value being returned.

\yskip

Function/macro naming conventions:

\.{new\_}{\it noun\/}: Allocate memory for and return an object
(and in one case, although it should arguably be two, \.{alloc\_}{\it
noun\/}).

\.{noun\_}{\it verb\/}: Perform some action on or with an object.

These may be specialised further, eg.~|new_segment| vs.~|new_segment_copy|.

Prefix \.{get\_}: Discard errors and return a value directly.

Prefix \.{set\_}: Mutate an object.

Suffix \.{\_p}: Predicate (returns a \CEE/ boolean).

Suffix \.{\_m}: Mutates some state, usually the object |o|.

Suffix \.{\_imp}: The real implementation of some routine.

Suffix \.{\_c}: An internal variant of a function accepting or
returning \CEE/-formatted data.

Suffix \.{\_ref}: Lookup by index in an array-like object.

An object's attribute mutator is named {\it object\/}\.{\_set\_}{\it
attribute\/}\.{\_m}.

Multiple suffixes are appended in an unspecified but --- I think
--- strict order.

\yskip

Other conventions.

Many objects are based on a memory allocation (known as a {\it
segment\/}) and consist of a header followed by an arbitrary number
of bytes. The macro to evaluate the \CEE/ struct representing the
object is named {\it object\/}\.{\_pointer}; the base of the data
is named {\it object\/}\.{\_base}.

``Length'' is the length of an object in whatever its base unit is,
not bytes. If the number of bytes needs to be tracked too it is the
``width''.

@** Memory. \Ls/ arranges memory allocations in a hierarchy. The
lowest level wraps the system allocation routines with error
detection. At this level there is no automatic memory management
and each allocation must be tracked and released explicitly.

The next layer organises allocations as a {\it segment\/} with a
header including a (doubly\footnote{$^1$}{TODO: Why?}) linked list
of segments along with other metadata. Segments are managed
automatically and freed by the garbage collector when no longer in
use.

The final layer classifies one or more segments as {\it heap\/}.
These heap areas hold the {\it atoms\/} which make up individual
objects and the necessary metadata to allocate them.

It's not clear that the \.{*\_Ready} variables serve any practical
purpose. TODO: review.

@.TODO@>
@<Global...@>=
char *malloc_options = "S"; /* Enable |malloc| security features. */
shared bool Memory_Ready = false; /* Main memory routines are ready. */
unique bool Thread_Ready = false; /* Thread initialisation if finished. */
shared bool Runtime_Ready = false; /* \Ls/' run-time is ready. */
shared bool VM_Ready = false; /* Environment populated \AM\ evaluator linked. */

@ @<Extern...@>=
extern shared bool Memory_Ready, Runtime_Ready, VM_Ready;
extern unique bool Thread_Ready;

@ @<Fun...@>=
error_code init_mem (void);
error_code alloc_mem (void *, size_t, size_t, void **);
error_code free_mem (void *);

@ The allocation routine simply checks the return value of |realloc|
(or |aligned_alloc| if an aligned allocation was requested) and
returns an appropriate error status.

|LLTEST| can be defined to replace the system allocator with one
suitable for use in the test suite.

@c
error_code
alloc_mem (void    *old,
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
                if (length < align)
                        length = align;
                else if (length % align)
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
free_mem (void *o)
{
#ifdef LLTEST
        @<Testing memory deallocator@>@;
#endif
        free(o);
        return LERR_NONE;
}

@ \Ls/ begins here. |init_mem| must be called exactly once and
before accessing using any other part of \Ls/. For the most part
this allocates the primary heap and other areas of memory used at
run-time, and initialises the mutexes which keep threads out of
each others' memory.

@(initialise.c@>=
error_code
init_mem (void)
{
        cell ltmp;
        segment *stmp;
        int i;
        error_code reason;

        assert(!Memory_Ready && !Runtime_Ready);
        @<Initialise memory allocator@>@;
        @<Initialise heap@>@;
        @<Initialise symbol table@>@;
        @<Initialise program linkage@>@;
        @<Initialise foreign linkage@>@;
        Memory_Ready = true;
        orreturn(init_osthread()); /* Finish memory initialisation for
                                                the first thread. */
        @<Initialise threading@>@;
        @<Initialise run-time environment@>@;
        Runtime_Ready = true;
        return LERR_NONE;
}

@* Portability. Not all the world's a VAX. 32-bit machines are
already long in the tooth as \Ls/ is being written so it's only
natural to also include support for 16-bit machines. These sections
set various \CEE/ constants and types so that a \Ls/ atom is exactly
the size of two (data) pointers, regardless of how big such a pointer
is.

Unfortunately it will be seen later that 16-bit support is lacking
in the bytecode/interpreter which has not been improved to take
such small machines into account.

@d TAG_BITS     8
@d TAG_BYTES    1
@#
@d WORD_MAX     INTPTR_MAX
@d WORD_MIN     INTPTR_MIN
@d INTERN_MAX   (ATOM_BYTES - 1)
@d FIXED_SHIFT  4
@d FIXED_MIN    (ASR(INTPTR_MIN, FIXED_SHIFT))
@d FIXED_MAX    (ASR(INTPTR_MAX, FIXED_SHIFT))
@d FIXED_BITS   (CELL_BITS - FIXED_SHIFT)
@<Essential...@>=
typedef int8_t byte;
typedef intptr_t cell;
typedef intptr_t word;
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

@ It's unclear how useful this could be given that it's already
2022 but it costs little to include it.

@<Define a 16-bit addressing environment@>=
#define CELL_BITS  16
#define CELL_BYTES 2
#define CELL_SHIFT 2
#define ATOM_BITS  32
#define ATOM_BYTES 4
#define HALF_MIN   INT8_MIN
#define HALF_MAX   INT8_MAX
typedef int8_t half;

@* Atoms. \Ls/ objects are referred to by pointers called {\it
cells\/}, which point directly to an atom in its heap. Because each
atom is exactly 4, 8 or 16 bytes wide (depending on machine size)
each one has an address which is a multiple of 4, 8 or 16 and so
any cell which points to an atom must have an even address. This
means that if a cell value is {\it odd\/} then it can't possibly
be a valid pointer to an atom; it won't point to a valid, allocated
address.

The following values (including zero, which isn't actually odd)
define constants which can be placed in a cell without the need to
perform a heap allocation. The |FIXED| constant is a little different:
instead of representing `a fixed' if a cell's value is exactly 15
(1111 in binary), as with the other constants, if the bottom 4 bits
of a cell are set then the rest of the cell encodes as much of a
signed integer as will fit.

|UNDEFINED| is a sentinel marker which should never be realised as
a run-time object.

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
@d null_p(O)      ((O) == NIL) /* Might {\it not\/} be |NULL|. */
@d special_p(O)   (null_p(O) || ((O)) & 1)
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

@ As already indicated an atom (from Greek {\it atomos\/}
``indivisible'') is the size of two pointers. Depending on what the
atom represents these may represent pointers to other atoms (or
constants) or opaque data.

Associated with each atom is a tag. Each tag is 8 bits wide. Two
bits (|LTAG_LIVE| and |LTAG_TODO|) are used by the garbage collector.
The remaining bits define the atom (it's atomic number, if you will)
and the first two of these --- of interest to the garbage collector
in particular --- indicate whether or not each half is a pointer
to another atom (|LTAG_PSIN| and |LTAN_PDEX|). The lower 6 bits are
known as the atoms {\it format\/}.

The macros below examine and update an atom's tag after locating
it (see below for the definition of |ATOM_TO_TAG| which does the
locating), the |A|, |C| and |T| macros are for typing convenience
and |A| in particular is used extensively to access the atom via
the union |atom|.

To make it clear that atoms are used to implement more than just
``cons cells'' the traditional names {\it car\/} and {\it cdr\/}
are not used internally, instead the Latin terms sinister and dexter
(shortened sin and dex) are used. These terms were deliberately
chosen to be unfamiliar and evoke no sense of priority or order.

@d LTAG_LIVE 0x80 /* Atom has been reached from a register. */
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
@#
@d A(O) ((atom *) (O))
@d C(O) ((cell) (O))
@d T(O) (ATOM_FORM(O))
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
                void *number; /* a |segment|, not defined yet. */
                word  value;
        };
        struct {
                int8_t length; /* Only 4 bits needed */
                byte   buffer[INTERN_MAX];
        };
} atom;

@ All of the atom formats that \Ls/ recognises.

@d FORM_NONE           (LTAG_NONE | 0x00) /* Unallocated. */
@d FORM_COLLECTED      (LTAG_NONE | 0x01) /* Garbage collector tombstone. */
@d FORM_HASHTABLE      (LTAG_NONE | 0x02) /* Key:value (or just key) store. */
@d FORM_HEAP           (LTAG_NONE | 0x03) /* Preallocated storage for atoms. */
@d FORM_INTEGER        (LTAG_NONE | 0x04) /* Large integer. */
@d FORM_RUNE           (LTAG_NONE | 0x05) /* Unicode code point. */
@d FORM_SEGMENT        (LTAG_NONE | 0x06) /* Large memory allocation. */
@d FORM_SEGMENT_INTERN (LTAG_NONE | 0x07) /* Tiny memory allocation. */
@d FORM_SYMBOL         (LTAG_NONE | 0x08) /* Symbol. */
@d FORM_SYMBOL_INTERN  (LTAG_NONE | 0x09) /* Tiny symbol. */
@#
@d FORM_ARRAY          (LTAG_PDEX | 0x00) /* Zero or more sequential cells. */
@d FORM_ASSEMBLY       (LTAG_PDEX | 0x01) /* (Partially) assembled bytecode. */
@d FORM_CSTRUCT        (LTAG_PDEX | 0x02) /* A \CEE/ struct. */
@d FORM_FILE_HANDLE    (LTAG_PDEX | 0x03) /* File descriptor or equivalent. */
@d FORM_POINTER        (LTAG_PDEX | 0x04)
@d FORM_STATEMENT      (LTAG_PDEX | 0x05) /* A single assembled statement. */
@#
@d FORM_PAIR           (LTAG_BOTH | 0x00) /* Two pointers (a ``cons cell''). */
@d FORM_ARGUMENT       (LTAG_BOTH | 0x01) /* An assembly statement argument. */
@d FORM_CLOSURE        (LTAG_BOTH | 0x02) /* Applicative or operative closure. */
@d FORM_ENVIRONMENT    (LTAG_BOTH | 0x03) /* Run-time environment. */
@d FORM_ERROR          (LTAG_BOTH | 0x04) /* An error (above). */
@d FORM_OPCODE         (LTAG_BOTH | 0x05) /* A virtual machine's operator. */
@d FORM_PRIMITIVE      (LTAG_BOTH | 0x06) /* A \Ls/ operator. */
@d FORM_REGISTER       (LTAG_BOTH | 0x07) /* A virtual machine register. */

@ Each format has a corresponding test. Some also share
implementation or are otherwise related.

@d form(O)             (ATOM_FORM(O))
@d form_p(O,F)         (!special_p(O) && form(O) == FORM_##F)
@d pair_p(O)           (form_p((O), PAIR))
@d argument_p(O)       (form_p((O), ARGUMENT))
@d array_p(O)          (form_p((O), ARRAY))
@d assembly_p(O)       (form_p((O), ASSEMBLY))
@d collected_p(O)      (form_p((O), COLLECTED))
@d cstruct_p(O)        (form_p((O), CSTRUCT))
@d environment_p(O)    (form_p((O), ENVIRONMENT))
@d error_p(O)          (form_p((O), ERROR))
@d file_handle_p(O)    (form_p((O), FILE_HANDLE))
@d hashtable_p(O)      (form_p((O), HASHTABLE))
@d heap_p(O)           (form_p((O), HEAP))
@d opcode_p(O)         (form_p((O), OPCODE))
@d pointer_p(O)        (form_p((O), POINTER))
@d register_p(O)       (form_p((O), REGISTER))
@d rune_p(O)           (form_p((O), RUNE))
@d statement_p(O)      (form_p((O), STATEMENT))
@#
@d segment_intern_p(O) (form_p((O), SEGMENT_INTERN))
@d segment_stored_p(O) (form_p((O), SEGMENT))
@d segment_p(O)        (segment_intern_p(O) || segment_stored_p(O))
@d symbol_intern_p(O)  (form_p((O), SYMBOL_INTERN))
@d symbol_stored_p(O)  (form_p((O), SYMBOL))
@d symbol_p(O)         (symbol_intern_p(O) || symbol_stored_p(O))
@d intern_p(O)         (symbol_intern_p(O) || segment_intern_p(O))
@#
@d integer_heap_p(O)   (form_p((O), INTEGER))
@d integer_p(O)        (fixed_p(O) || integer_heap_p(O))
@#
@d arraylike_p(O)      (array_p(O) || hashtable_p(O) || assembly_p(O)
        || statement_p(O))
@#
@d primitive_p(O)      (form_p((O), PRIMITIVE))
@d closure_p(O)        (form_p((O), CLOSURE))
@d program_p(O)        (closure_p(O) || primitive_p(O))

@ @<Fun...@>=
error_code new_atom_imp (heap *, cell, cell, cell_tag, cell *);

@ New atoms are allocated and with their constituent parts set
``atomically''. Pairs are by far the most common atom created and
get their own macro.

@d cons(A,D,R)       (new_atom((A), (D), FORM_PAIR, (R))) /* cAr, cDr, R */
@d new_atom(S,D,T,R) /* Sinister, Dexter, Tag, R */ (new_atom_imp(Heap_Thread,
        (cell) (S), (cell) (D), (T), (R)))
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
        orreturn(heap_root(where)->fun->alloc(where, ret));
        TAG_SET_M(*ret, ntag);
        A(*ret)->sin = nsin;
        A(*ret)->dex = ndex;
        return LERR_NONE;
}

@* Heap. An atom is allocated within a heap object, each of which
is the size of an operating system {\it page\/}. A single heap
consists of one or more heap objects linked together. Hereafter the
term ``heap'' generally refers to an individual heap object to avoid
saying ``heap object'' all the time.

Like every other allocation a heap is a segment and care is taken
to ensure that the segment's header is not {\it added\/} to the
allocation as it normally would be because each heap must be precisely
aligned in memory.

The segment header is still present though at the bottom of the
allocated range, followed immediately by the heap's own header.

The first set of macros here calculate the inner-header sizes, the
amount of space left for atoms (|HEAP_LEFTOVER|) and thus the total
size of the header proper (|HEAP_BOOKEND|) and padding (added
together in |HEAP_HEADER|). |HEAP_LENGTH| is how many atoms are
available in a heap.

The remaining macros mask off the high or low bits of an atom's
address to find the heap an atom is within, or its index within
that heap, respectively, and other aspects of the atom/heap as per
the macro's name.

|HEAP_TO_LAST| evaluates to the address of an atom {\it past\/} the
boundary of the heap.

@d SYSTEM_PAGE_LENGTH sysconf(_SC_PAGESIZE) /* An Operating
                                                System page length. */
@#
@d HEAP_CHUNK         (SYSTEM_PAGE_LENGTH) /* Size of a heap page (bytes). */
@d HEAP_MASK          (HEAP_CHUNK - 1) /* Bits which will always be 0. */
@d HEAP_BOOKEND       (sizeof (segment) + sizeof (heap)) /* Full header size. */
@d HEAP_LEFTOVER      ((HEAP_CHUNK - HEAP_BOOKEND) / (TAG_BYTES + ATOM_BYTES))
@d HEAP_LENGTH        ((int) HEAP_LEFTOVER) /* Heap data size (bytes). */
@d HEAP_HEADER        ((HEAP_CHUNK / ATOM_BYTES) - HEAP_LENGTH) /* (bytes) */
@#
@d ATOM_TO_ATOM(O)    ((atom *) (O))
@d ATOM_TO_HEAP(O)    (SEGMENT_TO_HEAP(ATOM_TO_SEGMENT(O))) /* The atom's
                                                                heap. */
@d ATOM_TO_INDEX(O)   (((((intptr_t) (O)) & HEAP_MASK) >> CELL_SHIFT)
        - HEAP_HEADER) /* The offset of an atom within a heap. */
@d ATOM_TO_SEGMENT(O) ((segment *) (((intptr_t) (O)) & ~HEAP_MASK)) /* The
                                                segment containing an atom. */
@d HEAP_TO_SEGMENT(O) (ATOM_TO_SEGMENT(O)) /* The segment containing a heap. */
@d SEGMENT_TO_HEAP(O) ((heap *) (O)->base) /* The heap part of a segment. */
@d HEAP_TO_LAST(O)    ((atom *) (((intptr_t) HEAP_TO_SEGMENT(O))
        + HEAP_CHUNK)) /* The (invalid) atom {\it after\/} the last valid
                                                        atom within a heap. */
@#
@d ATOM_TO_TAG(O)     (ATOM_TO_HEAP(O)->tag[ATOM_TO_INDEX(O)]) /* The
                                                                atom's tag. */

@ A heap is one or more heap objects linked together. The first
such object in the chain is called the {\it root heap\/} and each
subsequent heap points back to this root heap.

In place of the pointer to the root heap in an ordinary heap object,
the root heap points to a |heap_pun| object. Like a regular heap
object this punned object begins with a pointer. Unlike a regular
heap object where this is a pointer is to the next free atom (or
past the end of the heap) in the punned object pointed to by the
root heap it holds the value |HEAP_PUN_FLAG| (-1).

This sort of dirty hack is not repeated again.

After the fake free pointer the punned object has pointers to
the heap's allocator and other functions.

@<Type def...@>=
struct heap {
        atom     *free; /* Next unallocated atom. */
 struct heap     *next, *other; /* Next \AM\ twin heap pages. */
 struct heap_pun *root; /* Root page or |heap_access|. */
        cell_tag  tag[]; /* Atoms' tags. */
};
typedef struct heap heap;
@#
struct heap_pun {
        atom        *free;
 struct heap        *next, *other;
 struct heap_access *fun;
        cell_tag     tag[];
};
typedef struct heap_pun heap_pun;
@#
typedef error_code (*init_heap_fn)(heap *, heap *, heap *, heap *);
typedef error_code (*heap_enlarge_fn)(heap *, heap **);
typedef bool (*heap_enlarge_p_fn)(heap_pun *, heap *);
typedef error_code (*heap_alloc_fn)(heap *, cell *);
@#
struct heap_access { /* TODO: This can be a thread local variable. */
        void              *free; /* Named free to look like a |heap| object. */
        init_heap_fn       init;
        heap_enlarge_fn    enlarge;
        heap_enlarge_p_fn  enlarge_p;
        heap_alloc_fn      alloc;
};
typedef struct heap_access heap_access;

@ There may be several heaps active in \Ls/. One heap is created
initially and is where allocations usually happen. This heap is
saved in |Heap_Thread|, which is a ``thread-local'' variable. This
means that each operating system thread has its own |Heap_Thread|,
and thus its own heap.

The other heaps are initialised at run-time.

Note that almost none of this is actually implemented and only
|Heap_Thread| is used.

@d HEAP_PUN_FLAG -1 /* Fake `free pointer' sentinel to identify the root heap. */
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
bool heap_mine_p (heap *);
bool heap_shared_p (heap *);
bool heap_trapped_p (heap *);
bool heap_other_p (heap *);
error_code init_heap_compacting (heap *, heap *, heap *, heap *);
error_code init_heap_sweeping (heap *, heap *, heap *, heap *);
bool heap_enlarge_p (heap_pun *, heap     *);
error_code heap_enlarge (heap  *, heap **);
error_code heap_alloc_freelist (heap *, cell *);
error_code heap_alloc_pointer (heap *, cell *);

@ This is the first allocation that \Ls/ will make and the only
time the list of allocations will ever be empty. By setting its
\.{next} and \.{prev} pointers to itself |claim_segment| can safely
`insert' this into what looks like a list of segment allocations.

The negative allocation length of |-HEAP_CHUNK| indicates to
|alloc_segment| that the segment header should not increase the
length of the allocation.

There is no need to lock |Allocations_Lock|.

Allocating the |heap_access| object here like this is an awful hack
which will go away eventually.

@<Initialise heap@>=
orabort(alloc_segment(-HEAP_CHUNK, HEAP_CHUNK, &stmp));
Heap_Thread = SEGMENT_TO_HEAP(stmp);
orabort(init_heap_sweeping(Heap_Thread, NULL, NULL, NULL));
orabort(alloc_mem(NULL, sizeof (heap_access), sizeof (void *),@|
        (void **) &((heap_pun *) Heap_Thread)->fun)); /* This is nasty... */
((heap_pun *) Heap_Thread)->fun->free = (void *) HEAP_PUN_FLAG;
((heap_pun *) Heap_Thread)->fun->init = init_heap_sweeping;
((heap_pun *) Heap_Thread)->fun->enlarge = heap_enlarge;
((heap_pun *) Heap_Thread)->fun->enlarge_p = heap_enlarge_p;
((heap_pun *) Heap_Thread)->fun->alloc = heap_alloc_freelist;
orabort(new_atom(NIL, NIL, FORM_NONE, &ltmp));
Allocations = HEAP_TO_SEGMENT(Heap_Thread);
Allocations->next = Allocations->prev = Allocations;
orabort(claim_segment(HEAP_TO_SEGMENT(Heap_Thread), ltmp, FORM_HEAP));
Heap_Shared = Heap_Trap = NULL;

@ Tests to query whether the current thread can access a heap (and
thus, after using |ATOM_TO_HEAP| on its pointer, an atom).

@c
bool
heap_mine_p (heap *o)
{
        return (heap *) heap_root(o) == Heap_Thread;
}

bool
heap_shared_p (heap *o)
{
        return (heap *) heap_root(o) == Heap_Shared;
}

bool
heap_trapped_p (heap *o)
{
        return (heap *) heap_root(o) == Heap_Trap;
}

bool
heap_other_p (heap *o)
{
        return (heap *) heap_root(o) != Heap_Thread
                && (heap *) heap_root(o) != Heap_Shared;
}

@ The heap pun trick allows the allocation and garbage collection
algorithms to be chosen dynamically. There are two algorithms built
in to \Ls/ named after the type of garbage collection each uses:
sweeping and compacting.

After scanning for atoms which are in use, the garbage collector
``sweeps'' through a sweeping heap collecting the remaining unused
atoms into a ``free list''. Alternatively the atoms in a compacting
heap are {\it moved\/} by the garbage collector into a new heap
from which atoms are allocated by incrementing a pointer until it
overflows past the top of the heap.

The garbage collector algorithms have been removed from \Ls/ for
now for being a suspect whenever memory corruption bugs were being
hunted down.

@d initialise_atom(H,F) do@+ { /* Heap, Free */
        (H)->free--; /* Move to the previous atom. */
        ATOM_TO_TAG((H)->free) = FORM_NONE; /* Free the atom. */
        (H)->free->sin = NIL; /* Cleanse the atom of sin. */
        if (F)
                (H)->free->dex = (cell) ((H)->free + 1); /* Link the atom
                                                        to the free list. */
        else
                (H)->free->dex = NIL; /* Scrub up the rest of the atom. */
}@+ while (0)
@c
error_code
init_heap_sweeping (heap *new,
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
        for (i = 1; i < HEAP_LENGTH; i++)@/
                initialise_atom(new, true); /* The remaining atoms are
                                                linked together. */
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

@ Each heap object in a compacting heap is allocated alongside its
twin, to which atoms will be moved by the garbage collector.

TODO: This (and its missing GC etc.) remains untested.

@.TODO@>
@c
error_code
init_heap_compacting (heap *new,
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

@ Garbage collection is not automatic. One of the functions associated
with each heap is this function or one like it which reports whether
to try and allocate a new heap object rather than resorting to
garbage collection.

@c
bool
heap_enlarge_p (heap_pun *root @[unused@],
                heap     *at @[unused@])
{
        return true;
}

@ If no part of a heap has any atoms free then the heap is enlarged
by allocating a new page (or two) and linking it into the heap list.

TODO: Split this in two like the rest.

@.TODO@>
@c
error_code
heap_enlarge (heap  *old,
              heap **ret)
{
        heap *new, *other;
        heap_pun *root;
        segment *snew, *sother;
        cell hnew, hother;
        error_code reason;

        assert(heap_mine_p(old) || heap_shared_p(old));
        root = heap_root(old);
        if (old->other == NULL) {
                orreturn(alloc_segment(-HEAP_CHUNK, HEAP_CHUNK, &snew));
                new = SEGMENT_TO_HEAP(snew);
                orreturn(root->fun->init(new, old, NULL, (heap *) root));
                orreturn(root->fun->alloc(new, &hnew));
                pthread_mutex_lock(&Allocations_Lock);
                orreturn(claim_segment(snew, hnew, FORM_HEAP));
                pthread_mutex_unlock(&Allocations_Lock);
        } else {
                orreturn(alloc_segment(-HEAP_CHUNK, HEAP_CHUNK, &snew));
                orreturn(alloc_segment(-HEAP_CHUNK, HEAP_CHUNK, &sother));
                new = SEGMENT_TO_HEAP(snew);
                other = SEGMENT_TO_HEAP(sother);
                orreturn(root->fun->init(new, old, other, (heap *) root));
@#
                orreturn(root->fun->alloc(new, &hnew));
                orreturn(root->fun->alloc(new, &hother));
                pthread_mutex_lock(&Allocations_Lock);
                reason = claim_segment(snew, hnew, FORM_HEAP);
                if (!failure_p(reason))
                        reason = claim_segment(sother, hother, FORM_HEAP);
                pthread_mutex_unlock(&Allocations_Lock);
                if (failure_p(reason))
                        return reason;
        }
        *ret = new;
        return LERR_NONE;
}

@ A sweeping heap points to the next available atom or |NIL|.
Allocation is a matter of removing it from the list and cleaning
it up.

@c
error_code
heap_alloc_freelist (heap *where,
                     cell *ret)
{
        bool tried;
        heap *h, *next;
        error_code reason;

        assert(heap_mine_p(where) || heap_shared_p(where));
        tried = false;
again:
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
        if (tried || !heap_root(where)->fun->enlarge_p(heap_root(where), h))
                return LERR_OOM;
        orreturn(heap_root(where)->fun->enlarge(h, &where));
        tried = true;
        goto again;
}

@ Allocation from a compacting heap is done by incrementing a pointer
if it's not already past the end of the heap. There is no need to
clean the atom and this algorithm is fractionally faster than using
the free list.

@c
error_code
heap_alloc_pointer (heap *where,
                    cell *ret)
{
        bool tried;
        heap *h, *next;
        error_code reason;

        assert(heap_mine_p(where) || heap_shared_p(where));
        tried = false;
again:
        next = where;
        while (next != NULL) {
                h = next;
                if (ATOM_TO_HEAP(h->free) == where) {
                        *ret = (cell) h->free++;
                        return LERR_NONE;
                }
                next = h->next;
        }
        if (tried || !heap_root(where)->fun->enlarge_p(heap_root(where), h))
                return LERR_OOM;
        orreturn(heap_root(where)->fun->enlarge(h, &where));
        tried = true;
        goto again;
}

@* Segments. Every allocation in \Ls/ is a segment or is within a
segment: an arbitrary-size memory allocation. Three objects are
used internally to define segments:

A {\it pointer\/} is anything with a \CEE/ pointer in its sinister
half and an ignored cell in its dexter half.

A {\it segment\/} is such a pointer which points to an allocation.

An {\it interned segment\/} is an allocation that's small enough
to fit within the atom that would otherwise be a pointer. This can
only be achieved for objects which don't need the segment header
data of which there are two: plain segments and symbols.

Every segment (except interned segments) is included in a global
list via its \.{next} and \.{prev} pointers.

Note that \.{NULL} (|NULL|) and |NIL| are different, although they
will likely both have the numeric value zero.

@d pointer(O)               (A(O)->yin)
@d pointer_datum(O)         (A(O)->dex)
@d pointer_set_m(O,V)       (A(O)->yin = (V))
@d pointer_set_datum_m(O,V) (A(O)->dex = (V))
@d null_pointer_p(O)        (pointer(O) == NULL)
@#
@d segment_object(O)   ((segment *) pointer(O))
@d segment_base(O)     (intern_p(O) ? A(O)->buffer : segment_object(O)->base)
@d segment_length_c(O) (intern_p(O) ? A(O)->length : segment_object(O)->length)
@#
@d SEGMENT_MAX HALF_MAX
@<Type def...@>=
struct segment {
 struct segment *next, *prev;
        cell owner;
        half length, scan;
        byte base[];
};
typedef struct segment segment;

@ Any thread can allocate a segment (or clean them up during garbage
collection). |Allocations_Lock| is a mutex which ensure that no two
threads attempt to do so at the same time.

@<Global...@>=
shared segment *Allocations = NULL;
shared pthread_mutex_t Allocations_Lock;

@ @<Extern...@>=
extern shared segment *Allocations;
extern shared pthread_mutex_t Allocations_Lock;

@ @<Fun...@>=
error_code alloc_segment (half, intptr_t, segment  **);
error_code claim_segment (segment *, cell, cell_tag);
error_code new_pointer (address, cell *);
error_code new_segment_imp (heap *, half, intptr_t, cell_tag,
        cell_tag, cell *);
error_code segment_peek (cell, half, int, bool, cell *);
error_code segment_poke (cell, half, int, bool, cell);
error_code segment_resize_m (cell, half);

@ @<Initialise memory...@>=
orabort(init_osthread_mutex(&Allocations_Lock, false, false));

@ Before moving on, it is helpful to be able to create pointer
objects which aren't pointing to segments.

@c
error_code
new_pointer (address  o,
             cell    *ret)
{
        return new_atom((cell) o, NIL, FORM_POINTER, ret);
}

@ The main stage of allocating a segment is to obtain the memory
from the operating system and fill in the header absent links to
other segments.

@c
error_code
alloc_segment (half       length,
               intptr_t   align,
               segment  **ret)
{
        word rlength;
        segment *new;
        error_code reason;

        assert(length == -HEAP_CHUNK || (length >= 0 && length <= SEGMENT_MAX));
        if (length < 0)
                rlength = HEAP_CHUNK;
        else
                rlength = length + sizeof (segment);
        orreturn(alloc_mem(NULL, rlength, align, (void **) &new));
        if (length < 0)
                new->length = HEAP_LENGTH;
        else
                new->length = length;
        *ret = new;
        return LERR_NONE;
}

@ Saving the allocation in the global list is done here after the
caller has locked the |Allocations_Lock| mutex. The atom and its
tag are updated here after the list has been updated but while the
lock is still held to ensure that nothing tries to follow pointers
that aren't there yet.

@c
error_code
claim_segment (segment *area,
               cell     owner,
               cell_tag ntag)
{
        assert(Allocations != NULL);
        area->next = Allocations;
        area->prev = Allocations->prev;
        Allocations->prev->next = area;
        Allocations->prev = area;
        area->owner = owner;
        A(owner)->yin = area;
        A(owner)->dex = NIL;
        TAG_SET_M(owner, ntag); /* Do this last so the atom remains opaque
                                        until ready. */
        return LERR_NONE;
}

@ To create the new segment first the length and proposed tag are
checked to see if a full allocation is needed. If so the allocations
are all performed and claiming the lock is left until the last
possible moment.

@d new_segment(L,A,R) /* Length, Align, R */ new_segment_imp(Heap_Thread,
        (L), (A), FORM_SEGMENT, FORM_SEGMENT_INTERN, (R))
@c
error_code
new_segment_imp (heap     *where,
                 half      length,
                 intptr_t  align,
                 cell_tag  ntag,
                 cell_tag  itag,
                 cell     *ret)
{
        cell holder;
        segment *area;
        error_code reason;

        if (itag != FORM_NONE) {
                if (length > INTERN_MAX)
                        goto new_allocation;
                orreturn(new_atom_imp(where, NIL, NIL, itag, ret));
                A(*ret)->length = length;
        } else {
new_allocation:
                orreturn(new_atom_imp(where, NIL, NIL, FORM_NONE, &holder));
                orreturn(alloc_segment(length, align, &area));
                pthread_mutex_lock(&Allocations_Lock);
                reason = claim_segment(area, holder, ntag);
                pthread_mutex_unlock(&Allocations_Lock);
                if (failure_p(reason))
                        return reason;
                *ret = holder;
        }
        return LERR_NONE;
}

@ A segment can be resized ``in-place'' however this may mean
converting to or from an interned segment if the allocation size
crosses the |INTERN_MAX| boundary.

@c
error_code
segment_resize_m (cell o,
                  half nlength)
{
        half i, olength;
        word rlength;
        byte *new, *old;
        segment *embiggen;
        error_code reason;

        assert((segment_p(o) || arraylike_p(o)));
        olength = segment_length_c(o);
        if (nlength == olength)
                return LERR_NONE; /* Not an error. */
        if (!segment_p(o) || (nlength | olength) > INTERN_MAX) {
                @<Resize an allocated segment@>
        } else if (nlength <= INTERN_MAX) {
                if (olength <= INTERN_MAX)
                        A(o)->length = nlength;
                else {
                        @<Intern a previously allocated segment@>
                }
        } else {
                @<Allocate a segment for a previously interned segment@>
        }
        return LERR_NONE;
}

@ If a plain segment is being reduced enough the tag of the atom
is changed and the allocation is left without an owner to be cleaned
up by the garbage collector. The contents are copied as far as they
will fit.

@<Intern a previously allocated segment@>=
TAG_SET_M(o, FORM_SEGMENT_INTERN); /* Do this first to turn the atom opaque. */
old = segment_object(o)->base;
new = A(o)->buffer;
for (i = 0; i < nlength; i++)
        new[i] = old[i];
A(o)->length = nlength;

@ When a segment has outgrown its internment a new allocation is
made and the amount of space they shared is copied into it before
modifying the the atom's tag and contents to point to it.

@<Allocate a segment for a previously interned segment@>=
olength = segment_length_c(o);
old = segment_base(o);
orreturn(alloc_segment(nlength, 0, &embiggen));
new = embiggen->base;
for (i = 0; i < olength; i++)
        new[i] = old[i];
pthread_mutex_lock(&Allocations_Lock);
orreturn(claim_segment(embiggen, o, FORM_SEGMENT));
pthread_mutex_unlock(&Allocations_Lock);

@ Resizing a segment which was not and will not be interned is
performed by the backend memory allocator as far as the allocation
and its contents are concerned. The atom is changed to point to the
``new'' allocation however there is no ``old'' allocation --- this
is taken care of by the allocator --- except that the address may
have changed.

TODO: Check whether the lock should be held (or the allocation
removed from the list while locked) for the duration of |alloc_mem|.

@.TODO@>
@<Resize an allocated segment@>=
rlength = nlength + sizeof (segment);
old = (byte *) pointer(o);
if (pthread_mutex_lock(&Allocations_Lock) != 0)
        return LERR_INTERNAL;
orreturn(alloc_mem(pointer(o), rlength, 0, (void **) &embiggen));
if (embiggen != (segment *) old) {
        embiggen->next->prev = embiggen;
        embiggen->prev->next = embiggen;
}
pointer_set_m(o, embiggen);
pthread_mutex_unlock(&Allocations_Lock);
embiggen->length = nlength;

@ Data within a segment is read in words of 1, 2, 4 or 8 bytes. The
address to read from need not be aligned to a multiple of the size
of word being read, which may cause a bus fault on some architectures.

The word is interpreted as unsigned.

@c
error_code
segment_peek (cell  o,
              half  index, /* Always byte address? */
              int   width, /* 1, 2, 4, 8 */
              bool  lilliput,
              cell *ret)
{
        byte *s;
        uintmax_t v;
        error_code reason;

        assert(!heap_other_p(ATOM_TO_HEAP(o)));
        assert(segment_p(o));
        assert(index >= 0 && index < segment_length_c(o));
        assert(width == 1 || width == 2 || width == 4 || width == 8);
        s = segment_base(o);
        if (lilliput)
                switch (width) {
                case 1: v = ((uint8_t *) s)[index];@+ break;
                case 2: v = le16toh(*((uint16_t *) (s + index)));@+ break;
                case 4: v = le32toh(*((uint32_t *) (s + index)));@+ break;
                case 8: v = le64toh(*((uint64_t *) (s + index)));@+ break;
                }
        else
                switch (width) {
                case 1: v = ((uint8_t *) s)[index];@+ break;
                case 2: v = be16toh(*((uint16_t *) (s + index)));@+ break;
                case 4: v = be32toh(*((uint32_t *) (s + index)));@+ break;
                case 8: v = be64toh(*((uint64_t *) (s + index)));@+ break;
                }
        if (v > WORD_MAX) {
                orreturn(new_int(2, false, ret));
                int_buffer_c(*ret)[1] = *(word *) &v;
                return LERR_NONE;
        } else
                return new_int_c(v, ret);
}

@ Writing to a segment is the same but backwards.

@c
error_code
segment_poke_m (cell  o,
                half  index, /* Always byte address? */
                int   width, /* 1, 2, 4, 8 */
                bool  lilliput,
                cell  lvalue)
{
        byte *s;
        uintmax_t cvalue;

        assert(!heap_other_p(ATOM_TO_HEAP(o)));
        assert(segment_p(o));
        assert(index >= 0 && index < segment_length_c(o));
        assert(width == 1 || width == 2 || width == 4 || width == 8);
        assert(integer_p(lvalue));
        assert(false);
        cvalue = A(lvalue)->value & ((2 ^ (8 * width)) - 1);
        s = segment_base(o);
        if (lilliput)
                switch (width) {
                case 1: ((uint8_t *) s)[index] = cvalue;@+ break;
                case 2: *((uint16_t *) (s + index)) = htole16(cvalue);@+ break;
                case 4: *((uint32_t *) (s + index)) = htole32(cvalue);@+ break;
                case 8: *((uint64_t *) (s + index)) = htole64(cvalue);@+ break;
                }
        else
                switch (width) {
                case 1: ((uint8_t *) s)[index] = cvalue;@+ break;
                case 2: *((uint16_t *) (s + index)) = htobe16(cvalue);@+ break;
                case 4: *((uint32_t *) (s + index)) = htobe32(cvalue);@+ break;
                case 8: *((uint64_t *) (s + index)) = htobe64(cvalue);@+ break;
                }
        return LERR_NONE;
}

@** Objects.

@* Integers. Few mathematical routines are required in the core of
\Ls/, chiefly the ability to add and subtract small numbers, however
thought must be given to how memory will be organised for large
integers so that they're compatible with the subset implemented in
here.

To this end there are two integer formats used internally by \Ls/:
{\it fixed width\/} integers which do not use any allocated storage
and {\it variable width\/} integers which do.

Fixed width integers are described briefly above in the introduction
to atoms --- 4 bits of an address are reserved to indicate that a
value is really a fixed width integer and the remaining bits (12,
28 or 60) encode a signed integer value. Two macros |fix| and
|fixed_value| store and access the value of a fixed width integer.

Variable width integers are stored in multiples of {\it words\/},
which are signed integers the same size as a cell. If a single word
is enough then the space within the atom is used without the need
for a segment allocation.

This chapter also includes an assortment of numerical routines not
directly related to integer objects.

@d INT_LENGTH_MAX    (HALF_MAX / sizeof (cell))
@d int_vcast(O)      ((word *) &A(O)->value)
@d int_scast(O)      ((word *) segment_base(O))
@d int_buffer_c(O)   (null_pointer_p(O) ? int_vcast(O) : int_scast(O))
@d int_length_c(O)   (null_pointer_p(O) ? 1
        : segment_length_c(O) / sizeof (word))
@d int_negative_p(O) ((integer_heap_p(O) ? int_buffer_c(O)[0]
        : fixed_value(O)) < 0)
@#
@d fix(V)          (FIXED | ASL((V), FIXED_SHIFT))
@d fixed_value(V)  (ASR((V), FIXED_SHIFT))
@<Fun...@>=
error_code new_int_c (intmax_t, cell *);
error_code new_int (intmax_t, bool, cell *);
bool cmpis_p (cell, cell);
bool int_eq_p (cell, cell);
bool int_eq_p_imp (cell, cell);
error_code int_length (cell, cell *);
error_code int_to_symbol (cell, cell *);
error_code int_value (cell, word *);
error_code int_cmp (cell, cell, cell *);
error_code int_normalise (cell, cell *);
error_code int_add (cell, cell, cell *);
error_code int_sub (cell, cell, cell *);
error_code int_mul (cell, cell, cell *);
@#
int high_bit (uintmax_t);

@ To ensure that the sign bits are maintained when shifting numbers
left and right the macros |ASL| and |ASR| ensure that an arithmetic
(sign-preserving) shift is used regardless of the architecture.

@<Hacks...@>=
#define ASL(V,I) ((V) << (I))
#if ((-1) >> 1) == -1
#define ASR(V,I) ((V) >> (I))
#else
#define ASR(V,I) ((V) >= 0) ? ((V) = (V) >> (I)) : ((V) = ~((~(V)) >> (I)))
#endif

@ Returns a value representing the highest bit set in a number.

@c
int
high_bit (uintmax_t o)
{
        int i = CELL_BITS;

        while (--i)@+
                if (o & (1ull << i))
                        return i;
        assert(o == 0 || o == 1);
        return o - 1;
}

@ If a \CEE/ integer is small enough to fit within the space of a
fixed integer then |new_int_c| returns one without allocation,
otherwise the integer is being created from a
word\footnote{$^1$}{Technically |intmax_t| might not be the same
as |intptr_t|; this should be looked into.} so of course it will
fit within the single word available to an atom.

@c
error_code
new_int_c (intmax_t  value,
           cell     *ret)
{
        if (value >= FIXED_MIN && value <= FIXED_MAX) {
                *ret = fix(value);
                return LERR_NONE;
        }
        return new_atom((cell) NULL, (cell) value, FORM_INTEGER, ret);
}

@ Integers larger than a single word are created by initialising
the storage with |new_int| and setting it to an initial value of 0
or -1 (all bits set).

@c
error_code
new_int (intmax_t  length,
         bool      negative,
         cell     *ret)
{
        error_code reason;
        assert(length > 1 && length < (intmax_t) INT_LENGTH_MAX);
        orreturn(new_segment_imp(Heap_Thread, length * sizeof (cell),
                sizeof (word), FORM_INTEGER, FORM_NONE, ret));
        memset(segment_base(*ret), -negative, length);
        return LERR_NONE;
}

@ The converse of |new_int_c| is |int_value| which extracts the
value from any integer into a \CEE/ variable, if it fits. The macro
|or_int_value_bounds| is used when the integer is about to be used
to check that a value is within the boundaries of, eg.,~an array
and the error |LERR_OUT_OF_BOUNDS| is more appropriate than the
usual |LERR_LIMIT|.

@d or_int_value_bounds(O,R) if ((reason = int_value((O), (R))) == LERR_LIMIT)
        return LERR_OUT_OF_BOUNDS;
else if (failure_p(reason))
        return reason /* nb.~no semicolon. */
@c
error_code
int_value (cell  o,
           word *ret)
{
        assert(integer_p(o));
        if (fixed_p(o))
                *ret = fixed_value(o);
        else if (null_pointer_p(o))
                *ret = A(o)->value;
        else
                return LERR_LIMIT;
        return LERR_NONE;
}

@ The length of an integer is the number of words of storage it
uses.

@c
error_code
int_length (cell  o,
            cell *ret)
{
        assert(integer_p(o));
        if (fixed_p(o))
                *ret = 0;
        else if (null_pointer_p(o))
                *ret = 1;
        else
                return new_int_c(int_length_c(o), ret);
        return LERR_NONE;
}

@ Normalising an integer removes excess leading zero/sign words.
This is optional but can save  space.

@c
error_code
int_normalise (cell  o,
               cell *ret)
{
        half length;
        word *pint;
        error_code reason;

        assert(integer_p(o));
        if (fixed_p(o)) {
                *ret = o;
                return LERR_NONE;
        }
        length = int_length_c(o);
        pint = int_buffer_c(o);
        if (int_negative_p(o))
                while (length > 1 && *pint == -1)
                        length--, pint++;
        else
                while (length > 1 && !*pint)
                        length--, pint++;
        if (length > 1) {
                orreturn(new_segment_imp(Heap_Thread, length * sizeof (cell),
                        sizeof (word), FORM_INTEGER, FORM_NONE, ret));
                memmove(int_buffer_c(*ret), pint, length);
                return LERR_NONE;
        } else
                return new_int_c(*pint, ret);
}

@ Like symbols numbers are uniquely themselves but unlike symbols
they're not symbols. When an integer needs to be used in a place
where a symbol is expected (eg.~as the key to a hashtable entry)
this function constructs a symbol from the integer's value. The
binary representation of the number becomes the label of the symbol
so in most cases the symbol will be unprintable.

Leading zero/sign words are skipped, so unnormalised and normalised
integers convert to the same symbol.

@c
error_code
int_to_symbol (cell  o,
               cell *ret)
{
        bool negative;
        word *ib, *last, value;

        assert(integer_p(o));
        if (fixed_p(o)) {
                value = fixed_value(o);@t\4@>
small_integer:@;
                return new_symbol_buffer((byte *) &value, sizeof (word),
                        NULL, ret);
        } else if (null_pointer_p(o)) {
                value = A(o)->value;
                goto small_integer;
        } else {
                ib = int_buffer_c(o);
                last = ib + int_length_c(o);
                negative = *ib < 0;
                value = 0;
                for (; *ib == -negative; ib++) {
                        if (ib == last)
                                goto small_integer;
                        else if (*ib != -negative)
                                break;
                }
                return new_symbol_buffer((byte *) ib,
                        (last - ib) * sizeof (word), NULL, ret);
        }
}

@ The \Ls/ core needs integer support for some simple arithmetic
(below) and these comparison routines. This first comparison routine
implements \.{is?}, which is similar in spirit but not in scope to
\.{eq?} in Scheme, the difference chiefly being that integers are
compared {\it numerically\/} while all other objects' {\it identities\/}
are compared.

@c
bool
cmpis_p (cell yin,
         cell yang)
{
        if (integer_heap_p(yin) && integer_heap_p(yang))
                return int_eq_p_imp(yin, yang);
        else
                return yin == yang;
}

@ On the other hand \Ls/' equality routine is {\it only\/} applicable
to integers.

@c
bool
int_eq_p (cell yin,
          cell yang)
{
        assert(integer_p(yin));
        assert(integer_p(yang));
        if (fixed_p(yin) && fixed_p(yang))
                return yin == yang;
        else if (integer_heap_p(yin) && integer_heap_p(yang))
                return int_eq_p_imp(yin, yang);
        else
                return false;
}

@ Integers are compared for equality word-by-word starting with the
least significant. To account for potentially unnormalised integers
of different lengths the excess words of the longer integer are
compared to 0, or -1 if the integers are negative.

@c
bool
int_eq_p_imp (cell yin,
              cell yang)
{
        bool negative;
        word *pg, *pn;
        half lg, ln;

        assert(integer_heap_p(yin));
        assert(integer_heap_p(yang));
        if ((ln = int_length_c(yin)) == 1)
                pn = &(A(yin)->value);
        else
                pn = ((word *) segment_base(yin)) + ln - 1;
        if ((lg = int_length_c(yang)) == 1)
                pg = &(A(yang)->value);
        else
                pg = ((word *) segment_base(yang)) + lg - 1;
@#
        while (1) {
                negative = *pg < 0;
                if (*pn-- != *pg--)
                        return false;
                ln--;
                lg--;
                if (ln == 0)
                        goto finish_yin;
                negative = *(pn + 1) < 0;
                if (lg == 0)
                        goto finish_yang;
        }
@#
finish_yang:
        lg = ln;@+
        pg = pn;
finish_yin:
        if (negative) {
                for (; lg > 0; lg--)
                        if (*pg-- != -1)
                                return false;
        } else {
                for (; lg > 0; lg--)
                        if (*pg--)
                                return false;
        }
        return true;
}

@ This routine returns -1, 0 or 1 respectively if |yin| is less
than, equal to or greater than |yang|.

@d int_cmp_hack(N) (((N) * 2) + 1) /* -1 becomes -1, 0 becomes 1 */
@c
error_code
int_cmp (cell  yin,
         cell  yang,
         cell *ret)
{
        half lyin, lyang;
        word negative, *pyin, *pyang, vyin, vyang;

        assert(integer_p(yin));
        assert(integer_p(yang));

        if (fixed_p(yin)) {
                vyin = fixed_value(yin);
                pyin = &vyin;
                lyin = 1;
        } else {
                pyin = int_buffer_c(yin);
                lyin = int_length_c(yin);
        }

        if (fixed_p(yang)) {
                vyang = fixed_value(yang);
                pyang = &vyang;
                lyang = 1;
        } else {
                pyang = int_buffer_c(yang);
                lyang = int_length_c(yang);
        }

        negative = -(*pyin < 0);
        if (negative && *pyang >= 0) { /* |yin < yang| */
                *ret = fix(-1);
                return LERR_NONE;
        } else if (!negative && *pyang < 0) { /* |yin > yang| */
                *ret = fix(1);
                return LERR_NONE;
        }

        while (lyin > 1 && *pyin == negative)
                pyin++, lyin--; /* Skip leading 0s. */
        while (lyang > 1 && *pyang == negative)
                pyang++, lyang--;

        if (lyin < lyang) {
                *ret = fix(-int_cmp_hack(negative));
                return LERR_NONE;
        } else if (lyin > lyang) {
                *ret = fix(int_cmp_hack(negative));
                return LERR_NONE;
        }

        while (lyin--) { /* Same length, same sign; first difference wins. */
                vyin = *pyin++;
                vyang = *pyang++;
                if (vyin == vyang)
                        continue;
                if (vyin < vyang)
                        *ret = fix(-int_cmp_hack(negative));
                else
                        *ret = fix(int_cmp_hack(negative));
                return LERR_NONE;
        }
        *ret = fix(0);
        return LERR_NONE;
}

@ Only the three basic algebraic routines of addition, subtraction
and multiplication are necessary. Non-standard functions built in
to GCC and Clang, among others, are used in place of the regular
\CEE/ operators. These trap overflow using appropriate CPU instructions
which is shorter and faster than relying on explicit checks of the
operands and/or result.

TODO: These hacks should be actual hacks which check for the presence
of the built-in routines and define substitutes if they are not.

@.TODO@>
@<Hacks...@>=
#define ckd_add(r,x,y) @[__builtin_add_overflow((x), (y), (r))@]
#define ckd_sub(r,x,y) @[__builtin_sub_overflow((x), (y), (r))@]
#define ckd_mul(r,x,y) @[__builtin_mul_overflow((x), (y), (r))@]

@ The addition routine works with all integers. It creates a buffer
one word longer than the longest of the two addends and then adds
the two arguments into it one word at a time starting at the least
significant word. The result is then normalised and returned.

One integer is copied into the newly allocated space and then the
other added to it rather than both being added together. I can't
think of a good reason why, now.

Because fixed-width integers always have four bits to spare they
can be added together much more quickly than going through the full
variable-width algorithm.

@c
error_code
int_add (cell  yin,
         cell  yang,
         cell *ret)
{
        cell result;
        half lyin, lyang;
        word carry, *next, *presult, *pyin, *pyang, vyin, vyang;
        error_code reason;

        assert(integer_p(yin));
        assert(integer_p(yang));
        if (fixed_p(yin)) {
                vyin = fixed_value(yin);
                if (fixed_p(yang))
                        return new_int_c(vyin + fixed_value(yang), ret);
                pyin = &vyin;
                lyin = 1;
        } else {
                pyin = int_buffer_c(yin);
                lyin = int_length_c(yin);
        }
        if (fixed_p(yang)) {
                vyang = fixed_value(yang);
                pyang = &vyang;
                lyang = 1;
        } else {
                pyang = int_buffer_c(yang);
                lyang = int_length_c(yang);
        }

        if (lyin > lyang)
                orreturn(new_int(lyin + 1, int_negative_p(yin), &result));
        else
                orreturn(new_int(lyang + 1, int_negative_p(yin), &result));
        presult = int_buffer_c(result);
        next = presult + int_length_c(result);
        memmove(next - lyin, pyin, lyin);
        carry = 0;
        for (; lyang; lyang--) {
                next--;
                carry = ckd_add(next, *next, carry);
                carry |= ckd_add(next, *next, pyang[lyang - 1]);
        }
        if (carry)
                *(--next) += carry;
        return int_normalise(result, ret);
}

@ The subtraction routine is the same except for using subtraction
instead of addition.

@c
error_code
int_sub (cell  yin,
         cell  yang,
         cell *ret)
{
        cell result;
        half lyin, lyang;
        word carry, *next, *presult, *pyin, *pyang, vyin, vyang;
        error_code reason;

        assert(integer_p(yin));
        assert(integer_p(yang));
        if (fixed_p(yin)) {
                vyin = fixed_value(yin);
                if (fixed_p(yang))
                        return new_int_c(vyin - fixed_value(yang), ret);
                pyin = &vyin;
                lyin = 1;
        } else {
                pyin = int_buffer_c(yin);
                lyin = int_length_c(yin);
        }
        if (fixed_p(yang)) {
                vyang = fixed_value(yang);
                pyang = &vyang;
                lyang = 1;
        } else {
                pyang = int_buffer_c(yang);
                lyang = int_length_c(yang);
        }

        if (lyin > lyang)
                orreturn(new_int(lyin + 1, int_negative_p(yin), &result));
        else
                orreturn(new_int(lyang + 1, int_negative_p(yin), &result));
        presult = int_buffer_c(result);
        next = presult + int_length_c(result);
        memmove(next - lyin, pyin, lyin);
        carry = 0;
        for (; lyang; lyang--) {
                next--;
                carry = ckd_sub(next, *next, carry);
                carry |= ckd_sub(next, *next, pyang[lyang - 1]);
        }
        if (carry)
                *(--next) -= carry;
        return int_normalise(result, ret);
}

@ Multiplication accepts any integer as an argument but large
integers are not supported. If both multiplicands are fixed-width
integers then normal multiplication is attempted and if the result
still fits within a fixed width integer it's returned. Otherwise
the error |LERR_UNSUPPORTED| is raised which is expected to be
trapped and full multiplication implemented at a higher level.

@c
error_code
int_mul (cell  yin,
         cell  yang,
         cell *ret)
{
        word result;

        assert(integer_p(yin));
        assert(integer_p(yang));
        if (yin == fix(0) || yang == fix(0)) {
                *ret = fix(0);
                return LERR_NONE;
        } else if (yin == fix(1)) {
                *ret = yang;
                return LERR_NONE;
        } else if (yang == fix(1)) {
                *ret = yin;
                return LERR_NONE;
        }

        if (!fixed_p(yin) || !fixed_p(yang))
                return LERR_UNIMPLEMENTED;

        if (ckd_mul(&result, fixed_value(yin), fixed_value(yang)))
                return LERR_UNIMPLEMENTED;

        return new_int_c(result, ret);
}

@* Arrays. A sequence of zero or more cells is an {\it array\/}.
It's assumed that callers accessing an array's elements have checked
that their index value is within bounds.

Arrays in \Ls/ are segments and due to how segments are stored the
atom pointing to the array data has a spare cell with no purpose.
To make use of this spare space it's called the array's {\it offset\/}
and holds an integer which can be subtracted from a normal array
reference index to find the real offset in memory (ie.~from
zero)\footnote{$^1$}{I don't anticipate this feature finding much
use but the space is there.}. Nothing in \Ls/' core uses this feature
except to expose the value for calculation with at a higher level.

@d ARRAY_MAX HALF_MAX
@d array_base(O) ((cell *) segment_base(O))
@d array_length_c(O) (segment_length_c(O) / (half) sizeof (cell))
@d array_offset_c(O) (pointer_datum(O))
@<Fun...@>=
error_code new_array_imp (half, cell, cell, cell_tag, cell *);
error_code array_resize_m (cell, half, cell);

@ Most arrays are normal arrays with --- at creation their slots
are initialised to |NIL| and they're created with |new_array|.

Some objects are defined in terms of underlying an array store and
begin with their contents uninitialised.

@d new_array(L,O,R) /* Length, Offset, R */
        new_array_imp((L), (O), NIL, FORM_ARRAY, (R))
@c
error_code
new_array_imp (half      length,
               cell      offset,
               cell      fill,
               cell_tag  form,
               cell     *ret)
{
        error_code reason;

        assert(length >= 0 && length <= ARRAY_MAX);
        assert(integer_p(offset));
        orreturn(new_segment_imp(Heap_Thread, length * sizeof (cell),
                sizeof (cell), form, FORM_NONE, ret));
        pointer_set_datum_m(*ret, offset);
        if (defined_p(fill))
                while (length > 0)
                        array_base(*ret)[--length] = fill;
        return LERR_NONE;
}

@ Arrays can be resized in-place. Ultimately this relies on the
system memory allocator resizing an allocation without changing (or
by copying) the shared data and then initialising any remaining new
cells, usually to |NIL|.

@c
error_code
array_resize_m (cell o,
                half nlength,
                cell fill)
{
        half olength;
        error_code reason;

        assert(arraylike_p(o));
        assert(nlength >= 0 && nlength <= ARRAY_MAX);
        olength = array_length_c(o);
        orreturn(segment_resize_m(o, nlength * sizeof (cell)));
        if (defined_p(fill))
                while (nlength > olength)
                        array_base(o)[--nlength] = fill;
        return LERR_NONE;
}

@* Hashtables. A significant user of arrays is the {\it hashtable\/}
for associating a value with a key. A hashtable works by calculating
the {\it hash\/} value of the key to locate an initial array index
and then decreasing\footnote{$^1$}{Or increasing or indeed any
consistent algorithm.} the index until the correct key or an unused
array slot is located.

The hash value calculated for each key is an unsigned 32 bit integer.
A similar function is used depending on whether the length of the
buffer is known or is a zero terminated \CEE/-string.

@<Type def...@>=
typedef uint32_t hash;

@ @c
hash
hash_buffer (byte *buf,
             half  length)
{
        hash r = 0;
        half i;

        assert(length >= 0);
        r = 0;
        for (i = 0; i < length; i++)
                r = 33 * r + (unsigned char) (*buf++);
        return r;
}

hash
hash_cstr (byte *buf,
           half *length)
{
        hash r = 0;
        byte *p = buf;

        while (*p != '\0')
                r = 33 * r + (unsigned char) (*p++);
        *length = p - buf;
        return r;
}

@ The array underlying a hashtable is always created with a total
of $2^n$ slots, plus a {\it footer\/}, so that hashtable entries
are always based on an offset of zero, of two additional cells.
When a new hashtable is created one of these cells is set to the
number of slots in the array which can be used, set to 70\% of the
total slots available (rounded down). The other is set to zero
representing the number of entries which have been removed from the
hashtable or {\it blocked\/}.

A value of 70\% ensures that there will still be ``holes'' even
when the hashtable is nearly full, limiting how much of the array
needs to be scanned to find the correct slot. The smallest hashtable
above zero which can be created has 16 slots and in this case 15
slots are made available to leave a single one-slot hole, anticipating,
with prejudice not benchmarks, that at such a small size a full
array scan will not be expensive.

@d HASHTABLE_TINY     16
@d HASHTABLE_MAX      ((HALF_MAX >> 1) + 1)
@d HASHTABLE_MAX_FREE (hashtable_default_free(HASHTABLE_MAX))
@#
@d hashtable_default_free(L) (((L) == HASHTABLE_TINY)@|
        ? (HASHTABLE_TINY - 1) /* Guarantee at least one |NIL|. */@t\iII@>
        : ((7 * (1ull << high_bit(L))) / 10))
                /* $\lfloor70\%\rfloor$ */
@#
@d hashtable_length_c(O)        (array_length_c(O) - 2)
@d hashtable_base(O)            (array_base(O))
@d hashtable_blocked_c(O)       (fixed_value(array_base(O)[array_length_c(O) - 2]))
@d hashtable_blocked_p(O)       (hashtable_blocked_c(O) >= 1)
@d hashtable_free_c(O)          (fixed_value(array_base(O)[array_length_c(O) - 1]))
@d hashtable_free_p(O)          (hashtable_free_c(O) > 0)
@d hashtable_unused_c(O)        (hashtable_free_c(O) + hashtable_blocked_c(O))
@d hashtable_used_c(O)          (hashtable_length_c(O) - hashtable_unused_c(O))
@#
@d hashtable_set_blocked_m(O,V) (array_base(O)[array_length_c(O) - 2] = fix(V))
@d hashtable_set_free_m(O,V)    (array_base(O)[array_length_c(O) - 1] = fix(V))
@<Fun...@>=
hash hash_cstr (byte *, half *);
hash hash_buffer (byte *, half);
@#
bool hashtable_match_paired (cell, void *);
bool hashtable_match_raw (cell, void *);
error_code copy_hashtable (cell, cell *);
error_code copy_hashtable_imp (cell, cell);
error_code hashtable_enlarge_m (cell);
error_code hashtable_erase_m (cell, cell, bool);
error_code hashtable_reduce_m (cell);
error_code hashtable_save_m (cell, cell, bool);
error_code hashtable_scan (cell, hash, void *, half *);
error_code hashtable_search (cell, cell, cell *);
error_code hashtable_search_raw (cell, hash, byte *, half, cell *);
error_code hashtable_to_list (cell, int, cell *);
error_code new_hashtable (half, cell *);
hash hashtable_key_paired (cell);
hash hashtable_key_raw (cell);

@ At base a new hashtable is an array set to |NIL| with the free
and blocked slots set appropriately. This primary constructor
increases the desired length (which is an optional argument to the
constructor at run time) to the next power of two and calculates
the initial free count.

@d new_hashtable_imp(L,F,R) do@+ { /* Length, Free, R */
        assert(((L) == 0 && (F) == 0) || ((F) < (L)));
        orreturn(new_array_imp((L) + 2, fix(0), NIL, FORM_HASHTABLE, (R)));
        hashtable_set_blocked_m(*(R), 0);
        hashtable_set_free_m(*(R), (F));
}@+ while (0)
@c
error_code
new_hashtable (half  slots,
               cell *ret)
{
        half nfree, rlength;
        error_code reason;

        assert(slots >= 0
                && slots <= (half) hashtable_default_free(HASHTABLE_MAX));
        if (slots == 0)
                rlength = nfree = 0;
        else {
                if (slots <= (half) hashtable_default_free(HASHTABLE_TINY)) {
                        rlength = HASHTABLE_TINY;
                        nfree = hashtable_default_free(HASHTABLE_TINY);
                } else {
                        rlength = 1 << high_bit(slots);
                        nfree = hashtable_default_free(rlength);
                        while (nfree < slots) {
                                rlength <<= 1;
                                nfree = hashtable_default_free(rlength);
                        }
                        if (rlength > HASHTABLE_MAX)
                                return LERR_LIMIT;
                }
                assert(nfree >= slots && nfree < rlength);
        }
        new_hashtable_imp(rlength, nfree, ret);
        return LERR_NONE;
}

@ Ordinarily the object stored in a hashtable slot is a pair
containing the key and the value. In one case the object being
stored is the key itself and there is no pair. These two functions
are used when comparing with a value in an occupied slot so obtain
the key symbol's hash.

@c
hash
hashtable_key_paired (cell o)
{
        assert(pair_p(o) && symbol_p(A(o)->sin));
        return symbol_hash_c(A(o)->sin);
}

hash
hashtable_key_raw (cell o)
{
        assert(symbol_p(o));
        return symbol_hash_c(o);
}

@ Some of the algorithms used to implement hashtables copy the
contents of one hashtable into another. The copying part is performed
by |copy_hashtable_imp| after the new hashtable has been constructed,
where it is guaranteed to have been created large enough to fit it
all. The algorithm scans each array slot in the source hashtable
and if there's a live entry in it inserts it into the new hashtable.
The number of free slots in the new hashtable is updated afterwards.

The scanning algorithm at the heart of this function is a duplicate
of the main scanning algorithm in |hashtable_scan|.

@c
error_code
copy_hashtable_imp (cell old,
                    cell new)
{ /* nb.~|new| is not a ``|cell *|'' and must have already been allocated. */
        half i, j, nfree;
        cell pos, value;
        hash hval;
        hash (*hashfn)(cell);

        assert(hashtable_p(old));
        assert(hashtable_p(new));
        nfree = hashtable_free_c(new);
        assert(nfree >= hashtable_used_c(old));
        if (old == Symbol_Table)
                hashfn = hashtable_key_raw;
        else
                hashfn = hashtable_key_paired;
        for (i = 0; i < hashtable_length_c(old); i++) {
                value = hashtable_base(old)[i];
                if (!null_p(value) && defined_p(value)) { /* Slot in |old|. */
                        hval = hashfn(value);
                        j = hval % hashtable_length_c(new);
                        while (1) { /* Find a (guaranteed) slot in |new|. */
                                pos = hashtable_base(new)[j];
                                if (null_p(pos))
                                        break;
                                if (j == 0)
                                        j = hashtable_length_c(new) - 1;
                                else
                                        j--;
                        }
                        hashtable_base(new)[j] = value;
                        nfree--;
                }
        }
        hashtable_set_free_m(new, nfree);
        return LERR_NONE;
}

@ A function which can be exposed at run-time to simply copy a
hashtable is an obvious, light wrapper around the above.

@c
error_code
copy_hashtable (cell  o,
                cell *ret)
{
        cell new;
        error_code reason;

        orreturn(new_hashtable(hashtable_used_c(o), &new));
        orassert(copy_hashtable_imp(o, new));
        *ret = new;
        return LERR_NONE;
}

@ To insert a new entry into a hashtable that's full the hashtable
is first enlarged using the copying algorithm above. To maintain
the fiction that the hashtable is enlarged in-place the atom (passed
in via |o|) holding the original hashtable is mutated to reference
the new one.

@c
error_code
hashtable_enlarge_m (cell o)
{
        atom tmp;
        cell new;
        half nfree, nlength;
        error_code reason;

        assert(hashtable_p(o));
        if (hashtable_length_c(o) == 0)
                nlength = HASHTABLE_TINY;
        else
                nlength = hashtable_length_c(o) * 2;
        if (nlength > HASHTABLE_MAX)
                return LERR_LIMIT;
        nfree = hashtable_default_free(nlength);
        new_hashtable_imp(nlength, nfree, &new);
        copy_hashtable_imp(o, new);
        tmp = *A(new); /* No need to swap the tag. */
        *A(new) = *A(o);
        *A(o) = tmp;
        segment_object(new)->owner = new;
        segment_object(o)->owner = o;
        return LERR_NONE;
}

@ Going the other way, when enough entries have been removed from
a hashtable it can be reduced to the next size down. This is
essentially the same as |hashtable_enlarge_m| (with a slightly more
complex check to determine the size to reduce to) except that whereas
the previous function will always attempt to enlarge the hashtable,
|hashtable_reduce_m| will silently do nothing if there's no need to.

@c
error_code
hashtable_reduce_m (cell o)
{
        atom tmp;
        cell new;
        half nfree, nlength, olength;
        error_code reason;

        assert(hashtable_p(o));
        olength = hashtable_length_c(o);
        assert(olength > 0);
        if (hashtable_used_c(o) == 0)
                nfree = nlength = 0;
        else if (olength == HASHTABLE_TINY)
                return LERR_NONE;
        else {
                assert(olength % 2 == 0);
                nlength = olength / 2;
                nfree = hashtable_default_free(nlength);
                if (hashtable_used_c(o) > nfree)
                        return LERR_NONE;
        }
        new_hashtable_imp(nlength, nfree, &new);
        copy_hashtable_imp(o, new);
        tmp = *A(new); /* No need to swap the tag. */
        *A(new) = *A(o);
        *A(o) = tmp;
        segment_object(new)->owner = new;
        segment_object(o)->owner = o;
        return LERR_NONE;
}

@ Ordinary hashtables are used to associate a symbol with any \Ls/
object, except in one case. As will be explained in the chapter on
symbols there is one hashtable called the symbol table which
associates each symbol with itself.

This hashtable is searched when attempting to define a new symbol
from a memory buffer to see if it has already been created so the
key which is passed to the search function is not a symbol but a
pointer to this pre-symbol structure.

@<Type def...@>=
typedef struct {
        byte *buf;
        half  length;
} hashtable_raw;

@ And of course there are two comparison callback functions, one
for each type of hashtable.

@c
bool
hashtable_match_paired (cell  each,
                        void *ctx)
{
        assert(pair_p(each) && symbol_p(A(each)->sin));
        assert(symbol_p((cell) ctx));
        return A(each)->sin == C(ctx);
}

bool
hashtable_match_raw (cell  each,
                     void *ctx)
{
        hashtable_raw *proto = ctx;
        int i;

        assert(symbol_p(each));
        if (symbol_length_c(each) != proto->length)
                return false;
        for (i = 0; i < proto->length; i++)
                if (symbol_buffer_c(each)[i] != proto->buf[i])
                        return false;
        return true;
}

@ The central part of a hashtable is this algorithm to determine
the array index at which the object is, or should be.

To find the correct index take key's hash modulo the length of the
hashtable. If there's an object there and it matches that being
sought then the search is over. Alternatively there may be a |NIL|
indicating the key was not present in this hashtable and either
this is its correct location or the hashtable is full.

If neither condition was true decrease the index by one and look
again, wrapping around to the back of the array when passing zero.
The correct object or |NIL| is guaranteed to come eventually.

When removing an entry from a hashtable it's replaced with |UNDEFINED|
until the hashtable is reduced. It can't be replaced with |NIL| or
future searches which were previously blocked by it will see the
new hole.

Unusually |hashtable_scan| will always set the return value, either
to the correct index or -1. The error code indicates whether or not
the key was found at all by raising |LERR_MISSING| regardless of
whether the hashtable is full.

@c
error_code
hashtable_scan (cell  o,
                hash  hval,
                void *ctx,
                half *ret)
{
        cell at;
        bool (*matchfn)(cell, void *);

        assert(hashtable_p(o));
        if (hashtable_length_c(o) == 0) {
                *ret = -1;
                return LERR_MISSING;
        }
        if (o == Symbol_Table)
                matchfn = hashtable_match_raw;
        else
                matchfn = hashtable_match_paired;
        *ret = hval % hashtable_length_c(o); /* Default index value. */
        while (1) { /* At least one |NIL| is guaranteed to be present. */
                at = hashtable_base(o)[*ret];
                if (null_p(at) || (defined_p(at) && matchfn(at, ctx)))
                        break;
                if (*ret == 0)
                        *ret = hashtable_length_c(o) - 1;
                else
                        (*ret)--;
        }
        if (null_p(at)) {
                if (!hashtable_free_p(o))
                        *ret = -1;
                return LERR_MISSING;
        } else
                return LERR_NONE;
}

@ Searching either kind of hashtable is the same except for packing
the raw buffer data into a |hashtable_raw| structure. An absent
value is not an error here. This rather odd twisting of the API
stems from a time when these functions returned the value half of
the pair and could be improved (TODO).

@.TODO@>
@c
error_code
hashtable_search (cell  o,
                  cell  label,
                  cell *ret)
{
        half idx;
        error_code reason;

        assert(hashtable_p(o));
        assert(symbol_p(label));
        reason = hashtable_scan(o, symbol_hash_c(label), (void *) label, &idx);
        if (reason == LERR_MISSING) {
                *ret = UNDEFINED;
                return LERR_NONE;
        } else if (failure_p(reason))
                return reason;
        *ret = hashtable_base(o)[idx];
        return LERR_NONE;
}

error_code
hashtable_search_raw (cell  o,
                      hash  hval,
                      byte *buf,
                      half  length,
                      cell *ret)
{
        hashtable_raw proto;
        half idx;
        error_code reason;

        proto.length = length;
        proto.buf = buf;
        reason = hashtable_scan(o, hval, (void *) &proto, &idx);
        if (reason == LERR_MISSING) {
                *ret = UNDEFINED;
                return LERR_NONE;
        } else if (failure_p(reason))
                return reason;
        *ret = hashtable_base(o)[idx];
        return LERR_NONE;
}

@ Inserting anew and replacing an existing associating in a hashtable
is the same except for whether its presence or absence is an error.
When inserting if the hashtable is full and the key not found then
the hashtable is enlarged.

@c
error_code
hashtable_save_m (cell o,
                  cell datum,
                  bool replace)
{
        hashtable_raw proto;
        half idx;
        hash hval;
        void *ctx;
        error_code reason;

        assert(hashtable_p(o));
        if (o == Symbol_Table) {
                assert(symbol_p(datum));
                hval = symbol_hash_c(datum);
                proto.length = -1; /* Match nothing. */
                ctx = &proto;
        } else {
                assert(pair_p(datum) && symbol_p(A(datum)->sin));
                hval = symbol_hash_c(A(datum)->sin);
                ctx = (void *) A(datum)->sin;
        }
again:
        reason = hashtable_scan(o, hval, ctx, &idx);
        if (reason == LERR_MISSING) {
                if (replace)
                        return reason;
                else if (idx == -1) {
                        orreturn(hashtable_enlarge_m(o));
                        goto again;
                }
        } else if (failure_p(reason))
                return reason;
        else if (!replace)
                return LERR_EXISTS;
        assert(!failure_p(reason) || hashtable_free_p(o));
        assert(idx >= 0 && idx < hashtable_length_c(o));
        hashtable_base(o)[idx] = datum;
        hashtable_set_free_m(o, hashtable_free_c(o) - 1);
        return LERR_NONE;
}

@ Removing an entry from a hashtable replaces it with |UNDEFINED|
and increases the count of blocked slots. If it crosses a threshold
|hashtable_reduce_m| to the next size down will reduce the size of
the hashtable, removing it (and any others).

@c
error_code
hashtable_erase_m (cell o,
                   cell label,
                   bool relax)
{
        half idx;
        error_code reason;

        assert(hashtable_p(o));
        assert(symbol_p(label));
        reason = hashtable_scan(o, symbol_hash_c(label), (void *) label, &idx);
        if (reason == LERR_MISSING)
                return relax ? LERR_NONE : LERR_MISSING;
        assert(!failure_p(reason));
        hashtable_base(o)[idx] = UNDEFINED;
        hashtable_set_blocked_m(o, hashtable_blocked_c(o) + 1);
        return hashtable_reduce_m(o);
}

@ This page intentionally left blank.

@d HASHTABLE_ASIS  0
@d HASHTABLE_LABEL 1
@d HASHTABLE_VALUE 2
@c
#if 0
error_code
hashtable_to_list (cell  o,
                   int   preprocess,
                   cell *ret)
{
        assert(hashtable_p(o));
        acc = NIL;
        if (preprocess == HASHTABLE_LABEL)
                pp = lsinx;
        else if (preprocess == HASHTABLE_VALUE)
                pp = ldexx;
        else
                pp = lasisx;
        for (i = 0; i < hashtable_length_c(o); i++) {
                next = hashtable_base(o)[i];
                if (null_p(next) || !defined_p(next))
                        continue;
                orreturn(cons(pp(next), acc, &acc));
        }
        *ret = acc;
        return LERR_NONE;
}
#endif

@* Symbols. Most of the time symbols are one or more printable
letters or other characters, used in particular to bind objects to
a readable name, but in fact they can be zero or more bytes of any
value, even zero or any reserved or special character. This sequence
of bytes is the symbol's {\it label\/}. A symbol also has a {\it
hash\/} associated with it calculated over the bytes of this label.

If a symbol's label is short enough then it's interned in a heap
atom rather than allocating a segment, and the hash value is not
cached but recalculated whenever it's needed.

Every symbol is saved in the symbol table. When a new symbol is
being created from a span of memory its hash value is calculated
and then the symbol table is searched to see if that symbol has
already been created, which is returned instead of creating a new
one.

@d SYMBOL_MAX (HALF_MAX - sizeof (symbol))
@d symbol_object(O) ((symbol *) segment_base(O))
@d symbol_buffer_c(O) (symbol_intern_p(O)
        ? A(O)->buffer
        : symbol_object(O)->label)
@d symbol_hash_c(O) (symbol_intern_p(O)
        ? hash_buffer(A(O)->buffer, A(O)->length)
        : symbol_object(O)->hash_value)
@d symbol_length_c(O) (symbol_intern_p(O) ? A(O)->length
        : segment_length_c(O) - (half) sizeof (symbol))
@<Type def...@>=
typedef struct {
        hash hash_value; /* Cache the hash value of long symbols. */
        byte label[]; /* This is {\it bytes\/} not characters. */
} symbol;

@ @<Global...@>=
shared cell Symbol_Table = NIL;

@ @<Extern...@>=
extern shared cell Symbol_Table;

@ @<Fun...@>=
error_code new_symbol_buffer (byte *, half, bool *, cell *);
error_code new_symbol_imp (hash, byte *, half, bool *, cell *);
error_code new_symbol_segment (cell, half, half, cell *);

@ @<Initialise symbol...@>=
orabort(new_hashtable(0, &Symbol_Table));

@ Most new symbols are created using one of these three front ends,
|new_symbol_cstr| for a buffer with a terminating zero byte which
is {\it not\/} included in the symbol and |new_symbol_const| for
symbols created from constant \CEE/-strings who's length is known
to the \CEE/ compiler.

@d new_symbol_cstr(O,R) new_symbol_buffer((byte *) (O), -1, NULL, (R))
@d new_symbol_const(O,R) new_symbol_buffer((byte *) (O), sizeof (O) - 1,
        NULL, (R))
@c
error_code
new_symbol_buffer (byte *buf,
                   half  length,
                   bool *fresh,
                   cell *ret)
{
        hash hval;

        assert(length >= -1 && length < (half) SYMBOL_MAX);
        if (length == -1)
                hval = hash_cstr((byte *) buf, &length);
        else
                hval = hash_buffer((byte *) buf, length);
        return new_symbol_imp(hval, buf, length, fresh, ret);
}

@ TODO: Turn this into another macro.

@.TODO@>
@c
error_code
new_symbol_segment (cell  o,
                   half  offset,
                   half  length,
                   cell *ret)
{
        assert(segment_p(o));
        assert(offset >= 0);
        assert(length >= 0);
        assert(length + offset <= segment_length_c(o));
        return new_symbol_buffer(segment_base(o) + offset, length, NULL, ret);
}

@ To create a symbol from a buffer who's length and hash are known
first search the symbol table to see if a symbol with that label
already exists and return it, otherwise allocate a new (possibly
interned) segment, save it in the symbol table and return that.

@c
error_code
new_symbol_imp (hash  hval,
                byte *buf,
                half  length,
                bool *fresh,
                cell *ret)
{
        cell sym;
        bool ignore;
        error_code reason;

        assert(length >= 0 && length < (half) SYMBOL_MAX);
        if (fresh == NULL)
                fresh = &ignore;
        orreturn(hashtable_search_raw(Symbol_Table, hval, buf, length,
                &sym));
        if (defined_p(sym)) {
                *fresh = false;
                *ret = sym;
                return LERR_NONE;
        }
        *fresh = true;
        if (length >= INTERN_MAX) {
                orreturn(new_segment_imp(Heap_Thread, length + sizeof (symbol),
                        0, FORM_SYMBOL, FORM_NONE, &sym));
                symbol_object(sym)->hash_value = hval;
        } else {
                orreturn(new_atom(NIL, NIL, FORM_SYMBOL_INTERN, &sym));
                A(sym)->length = length;
        }
        memmove(symbol_buffer_c(sym), buf, length);
        orreturn(hashtable_save_m(Symbol_Table, sym, false));
        *ret = sym;
        return LERR_NONE;
}

@* Environment. All of the objects presented so far are united by
the common theme of being implemented using low level constructs
to ``look behind the curtain'' of \Ls/' objects. Environment objects
are the odd one out by being based on plain \Ls/ objects, they are
included here because they are fundamental. In fact all of other
objects mostly exists here to provide the support that environment
objects need.

An environment is built out of a pair. One half of the pair points
to a {\it previous\/} environment (circular connections are not
allowed; an environment cannot point back to itself) and the other
to a hashtable of symbol-to-value bindings.

Any environment who's previous environment is |NIL| is a {\it root
environment\/}. One of these is defined during \Ls/' initialisation,
referred to as {\it the\/} root environment and saved in |Root|.

@d env_layer(O)    (A(O)->dex)
@d env_previous(O) (A(O)->sin)
@d env_root_p(O)   (environment_p(O) && null_p(env_previous(O)))
@<Global...@>=
shared cell Root = NIL;
unique cell Environment= NIL;

@ @<Extern...@>=
extern shared cell Root;
extern unique cell Environment;

@ @<Fun...@>=
error_code new_env (cell, cell *);
cell env_get_root (cell);
error_code env_save_m (cell, cell, cell, bool);
error_code env_search (cell, cell, cell *);

@ @<Initialise run-time...@>=
orabort(new_empty_env(&Root));
Environment = Root;

@ A new environment is created by extending an existing environment,
a new root or empty environment is created by extending |NIL|.

@d new_empty_env(R) (new_env(NIL, (R)))
@c
error_code
new_env (cell  o,
         cell *ret)
{
        cell tmp;
        error_code reason;

        assert(null_p(o) || environment_p(o));
        orreturn(new_hashtable(0, &tmp));
        orreturn(new_atom(o, tmp, FORM_ENVIRONMENT, ret));
        return LERR_NONE;
}

@ Locate an environment's root however deep in the hierarchy.

@c
cell
env_get_root (cell o)
{
        assert(environment_p(o));
        while (!env_root_p(o))
                o = env_previous(o);
        return o;
}

@ Inserting or replacing a binding in an environment.

@d env_save_m_imp(E,D,R) /* Environment, Datum, Replace? */
        hashtable_save_m(env_layer(E), (D), (R))
@c
error_code
env_save_m (cell o,
            cell label,
            cell value,
            bool replace)
{
        cell tmp;
        error_code reason;

        assert(environment_p(o));
        assert(symbol_p(label));
        assert(defined_p(value));
        orreturn(cons(label, value, &tmp));
        return env_save_m_imp(o, tmp, replace);
}

@ Searching an environment for a binding searches each level of the
hierarchy in turn until the binding is found or the root environment
is passed. The value that was bound, and not the pair saved into
the hashtable, is returned.

@c
error_code
env_search (cell  o,
            cell  label,
            cell *ret)
{
        cell tmp;
        error_code reason;

        assert(environment_p(o));
        assert(symbol_p(label));
        for (; !null_p(o); o = env_previous(o)) {
                orreturn(hashtable_search(env_layer(o), label, &tmp));
                if (defined_p(tmp)) {
                        assert(pair_p(tmp));
                        *ret = A(tmp)->dex;
                        return LERR_NONE;
                }
        }
        return LERR_MISSING;
}

@* SCOW. Very little thought has gone into this object so not much
description will either.

There is one built in scow for threads, to hold a |pthread_t|.

@d LSCOW_PTHREAD_T 0
@<Type def...@>=
typedef struct {
        int length, align;
} scow;

@ @<Global...@>=
shared scow *SCOW_Attributes = NULL;
shared int SCOW_Length = 1; /* To fit |pthread_t| */

@ @<Extern...@>=
extern shared scow *SCOW_Attributes;
extern shared int SCOW_Length;

@ @<Fun...@>=
error_code register_scow (int, int, int *);
error_code new_scow (int, intmax_t, cell *);
bool scow_id_p (cell, int);
half scow_length (cell);

@ @<Initialise for...@>=
orabort(alloc_mem(NULL, SCOW_Length * sizeof (scow), 0,
        (void **) &SCOW_Attributes));

@** I/O. None.

@* Runes (Characters). Not defined.

@d ascii_p(O) ((O) >= 0x00 && (O) <= 0x7f)
@d ascii_space_p(O) ((O) == ' ' || (O) == '\t' || (O) == '\n')
@d ascii_digit_p(O) ((O) >= '0' && (O) <= '9')
@d ascii_hex_p(O) (((O) & 0xdf) >= 'A' && ((O) & 0xdf) <= 'F')
@d ascii_printable_p(O) ((O) >= 0x21 && (O) <= 0x7e)
@d ascii_upcase_p(O) ((O) >= 'A' && (O) <= 'Z')
@d ascii_downcase_p(O) ((O) >= 'a' && (O) <= 'z')
@d ascii_upcase(O) (ascii_downcase_p(O) ? (O) - 0x20 : (O))
@d ascii_downcase(O) (ascii_upcase_p(O) ? (O) + 0x20 : (O))

@** Virtual Machine.

Table ID = XX YYYY,YYYY YYZZ,ZZZZ

XX shifted left |OBJECTDB_SPLIT_GAP|.

@d ADDRESS_INVALID       INTPTR_MAX
@#
@d CODE_PAGE_LENGTH      0x1000000l /* $2^{24}$ */
@d CODE_PAGE_WIDTH       24
@d CODE_PAGE_MASK        (CODE_PAGE_LENGTH - 1)
@d CODE_PAGE_MAX         (CODE_PAGE_LENGTH - 1)
@d INSTRUCTION_LENGTH    (CODE_PAGE_LENGTH / sizeof (instruction))
@#
@d OBJECTDB_SPLIT_BOTTOM 0x00ffc0
@d OBJECTDB_SPLIT_TOP    0x030000
@d OBJECTDB_SPLIT_GAP    6 /* to |0x3000000| */
@d OBJECTDB_TABLE        0x03ffc0
@d OBJECTDB_ROW          0x00003f
@d OBJECTDB_TABLE_LENGTH (1 << 12)
@d OBJECTDB_ROW_LENGTH   (1 << 6)
@d OBJECTDB_MAX          (OBJECTDB_TABLE_LENGTH * OBJECTDB_ROW_LENGTH)
@<Type def...@>=
typedef uintptr_t address; /* |void *| would also be acceptable but for
                                arithmetic. */
@#
typedef int32_t instruction;

@ @<Global...@>=
shared cell Program_ObjectDB = NIL; /* Array of multiples of |OBJECTDB_ROW_LENGTH|. */
shared half Program_ObjectDB_Free = 0; /* Multiple of |OBJECTDB_ROW_LENGTH|. */
shared cell Program_Export_Table = NIL; /* Pairs of (name . index). */
shared address *Program_Export_Base = NULL; /* Array indexed in to. */
shared half Program_Export_Free = 0; /* Next available array slot. */
shared pthread_mutex_t Program_Lock; /* Global lock for all of the above. */
@#
unique address Ip = ADDRESS_INVALID; /* Current (or previous) instruction. */
shared address Empty_Trap_Handler[LERR_LENGTH] = {0};
unique address *Trap_Handler = Empty_Trap_Handler;
unique address Trap_Ip = ADDRESS_INVALID;
unique error_code Trapped = LERR_NONE;
@#
#ifdef LLTEST
shared long Interpret_Count = 0, Interpret_Limit = 0;
#endif

@ @<Extern...@>=
extern shared cell Program_ObjectDB, Program_Export_Table;
extern shared half Program_ObjectDB_Free, Program_Export_Free;
extern shared address *Program_Export_Base;
extern shared pthread_mutex_t Program_Lock;
@#
extern shared address Empty_Trap_Handler[];
extern unique address Ip, *Trap_Handler, Trap_Ip;
extern unique error_code Trapped;
@#
extern shared long Interpret_Count, Interpret_Limit;

@
@d instruction_page(O) ((O) & ~CODE_PAGE_MASK)

@<Fun...@>=
error_code init_vm (void);
error_code vm_locate_entry (cell, address *);

@ @<Initialise program...@>=
for (i = 0; i < LERR_LENGTH; i++)
        Empty_Trap_Handler[i] = ADDRESS_INVALID;
Trap_Handler = (address *) Empty_Trap_Handler;
@#
orabort(init_osthread_mutex(&Program_Lock, false, false));
orabort(new_array(0, fix(0), &Program_ObjectDB));
orabort(alloc_mem(NULL, CODE_PAGE_LENGTH, 1 << CODE_PAGE_WIDTH,
        (void **) &Program_Export_Base));
assert((address) Program_Export_Base == instruction_page((address)
        Program_Export_Base));
orabort(new_hashtable(0, &Program_Export_Table));

@ @(initialise.c@>=
error_code
init_vm (void)
{
        address atmp, adefault;
        cell copy[3], eval[3], list[3];
        cell ltmp, sig_copy, sig_eval, sig_list;
        cell sig[SIGNATURE_LENGTH];
        char btmp[1024], *bptr; /* Way more space than necessary. */
        int i, j, k;
        error_code reason;

        assert(!VM_Ready);
        @<Initialise error symbols@>@;
        @<Initialise assembler symbols@>@;
        @<Initialise \Ls/ primitives@>@;
        @<Initialise evaluator and other bytecode@>@;
        @<Link \Ls/ primitives to installed bytecode@>@;
        VM_Ready = true;
        return LERR_NONE;
}

@ @c
error_code
vm_locate_entry (cell     label,
                 address *ret)
{
        cell loffset;
        word coffset;
        error_code reason;

        assert(symbol_p(label));
        orreturn(hashtable_search(Program_Export_Table, label, &loffset));
        if (undefined_p(loffset))
                return LERR_MISSING;
        orreturn(int_value(A(loffset)->dex, &coffset));
        assert(coffset >= 0 && coffset < Program_Export_Free);
        *ret = Program_Export_Base[coffset];
        return LERR_NONE;
}

@* Registers. There are too many general registers. They have no
run-time state associated with them except a name.

@d register_id_c(O) (A(O)->sin)
@d register_label_c(O) (A(O)->dex)
@#
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
@d LR_GENERAL       42

@ Some global state isn't represented by a register, perhaps these
should be: |Root|, |SCOW_Attributes|, |Threads|. More?

@d LR_Scrap         43
@d LR_Accumulator   44
@d LR_Argument_List 45
@d LR_Control_Link  46 /* Special: push/pop */
@d LR_Environment   47 /* Typed: environment? */
@d LR_Expression    48
@d LR_Root          49
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
unique cell *Register[LR_CELL + 1] = {NULL}; /* The registers. */
shared cell Register_Table[LR_LENGTH] = {NIL}; /* Run-time register objects. */
@#
unique cell Scrap = NIL;
unique cell Accumulator = NIL;
unique cell Argument_List = NIL;
unique cell Control_Link = NIL;
unique cell Expression = NIL;
unique cell Trap_Arg1 = NIL;
unique cell Trap_Arg2 = NIL;
unique cell Trap_Result = NIL;
unique cell VM_Arg1 = NIL;
unique cell VM_Arg2 = NIL;
unique cell VM_Result = NIL;
unique cell General[LR_GENERAL + 1] = {NIL};

@ @<Extern...@>=
extern shared cell Register_Table[];
extern unique cell General[], *Register[];
extern unique cell Accumulator, Argument_List, Control_Link,
        Expression, Scrap, Trap_Arg1, Trap_Arg2, Trap_Result, VM_Arg1,
        VM_Arg2, VM_Result;

@ @<(Re-)Initialise thread register pointers@>=
Register[LR_Scrap] = &Scrap;
Register[LR_Accumulator] = &Accumulator;
Register[LR_Argument_List] = &Argument_List;
Register[LR_Environment] = &Environment;
Register[LR_Root] = &Root;
Register[LR_Expression] = &Expression;
Register[LR_Control_Link] = &Control_Link;
Register[LR_Arg1] = &VM_Arg1;
Register[LR_Arg2] = &VM_Arg2;
Register[LR_Result] = &VM_Result;
Register[LR_Trap_Arg1] = &Trap_Arg1;
Register[LR_Trap_Arg2] = &Trap_Arg2;
Register[LR_Trap_Result] = &Trap_Result;
for (i = 0; i <= LR_GENERAL; i++)
        Register[i] = General + i;

@ @<Data...@>=
shared char *Register_Label[LR_LENGTH] = {
        [LR_Scrap]        = "VM:Temp",@|
        [LR_Accumulator]  = "VM:Accumulator",@|
        [LR_Argument_List]= "VM:Argument-List",@|
        [LR_Control_Link] = "VM:Control-Link",@|
        [LR_Environment]  = "VM:Environment",@|
        [LR_Root]         = "VM:Root",@|
        [LR_Expression]   = "VM:Expression",@|
        [LR_Heap_Shared]  = "VM:Heap-Shared",@|
        [LR_Heap_Thread]  = "VM:Heap-Thread",@|
        [LR_Heap_Trap]    = "VM:Heap-Trap",@|
        [LR_Symbol_Table] = "VM:Symbol-Table",@|
        [LR_Trap_Arg1]    = "VM:Trap-Arg1",@|
        [LR_Trap_Arg2]    = "VM:Trap-Arg2",@|
        [LR_Trap_Result]  = "VM:Trap-Result",@|
        [LR_Arg1]         = "VM:Arg1",@|
        [LR_Arg2]         = "VM:Arg2",@|
        [LR_Result]       = "VM:Result",@|
        [LR_Trap_Ip]      = "VM:Trap-Ip",@|
        [LR_Trapped]      = "VM:Trapped",@|
        [LR_Trap_Handler] = "VM:Trap-Handler",@|
        [LR_Ip]           = "VM:Ip",@|
@#
        [LR_r0]           = "VM:R0",@|
        [LR_r1]           = "VM:R1",@|
        [LR_r2]           = "VM:R2",@|
        [LR_r3]           = "VM:R3",@|
        [LR_r4]           = "VM:R4",@|
        [LR_r5]           = "VM:R5",@|
        [LR_r6]           = "VM:R6",@|
        [LR_r7]           = "VM:R7",@|
        [LR_r8]           = "VM:R8",@|
        [LR_r9]           = "VM:R9",@|
        [LR_r10]          = "VM:R10",@|
        [LR_r11]          = "VM:R11",@|
        [LR_r12]          = "VM:R12",@|
        [LR_r13]          = "VM:R13",@|
        [LR_r14]          = "VM:R14",@|
        [LR_r15]          = "VM:R15",@|
        [LR_r16]          = "VM:R16",@|
        [LR_r17]          = "VM:R17",@|
        [LR_r18]          = "VM:R18",@|
        [LR_r19]          = "VM:R19",@|
        [LR_r20]          = "VM:R20",@|
        [LR_r21]          = "VM:R21",@|
        [LR_r22]          = "VM:R22",@|
        [LR_r23]          = "VM:R23",@|
        [LR_r24]          = "VM:R24",@|
        [LR_r25]          = "VM:R25",@|
        [LR_r26]          = "VM:R26",@|
        [LR_r27]          = "VM:R27",@|
        [LR_r28]          = "VM:R28",@|
        [LR_r29]          = "VM:R29",@|
        [LR_r30]          = "VM:R30",@|
        [LR_r31]          = "VM:R31",@|
        [LR_r32]          = "VM:R32",@|
        [LR_r33]          = "VM:R33",@|
        [LR_r34]          = "VM:R34",@|
        [LR_r35]          = "VM:R35",@|
        [LR_r36]          = "VM:R36",@|
        [LR_r37]          = "VM:R37",@|
        [LR_r38]          = "VM:R38",@|
        [LR_r39]          = "VM:R39",@|
        [LR_r40]          = "VM:R40",@|
        [LR_r41]          = "VM:R41",@|
        [LR_r42]          = "VM:R42",@|
};

@ @<Initialise ass...@>=
for (i = 0; i < LR_LENGTH; i++) {
        orreturn(new_symbol_cstr(Register_Label[i], &ltmp));
        orreturn(new_atom(fix(i), ltmp, FORM_REGISTER, Register_Table + i));
        orreturn(env_save_m(Root, ltmp, Register_Table[i], false));
}

@ Six commonly-used registers are bound to an additional short
names for convenience.

@<Initialise ass...@>=
orabort(new_symbol_const("VM:Acc", &ltmp));
orabort(env_save_m(Root, ltmp, Register_Table[LR_Accumulator], false));
orabort(new_symbol_const("VM:Args", &ltmp));
orabort(env_save_m(Root, ltmp, Register_Table[LR_Argument_List], false));
orabort(new_symbol_const("VM:Clink", &ltmp));
orabort(env_save_m(Root, ltmp, Register_Table[LR_Control_Link], false));
orabort(new_symbol_const("VM:Env", &ltmp));
orabort(env_save_m(Root, ltmp, Register_Table[LR_Environment], false));
orabort(new_symbol_const("VM:Expr", &ltmp));
orabort(env_save_m(Root, ltmp, Register_Table[LR_Expression], false));
orabort(new_symbol_const("VM:Tmp", &ltmp));
orabort(env_save_m(Root, ltmp, Register_Table[LR_Scrap], false));

@* Opcodes.

@d opcode_id_c(O)        (A(O)->sin)
@d opcode_label_c(O)     (A(O)->dex)
@d opcode_object(O)      (&Op[fixed_value(opcode_id_c(O))])
@d opcode_signature_c(O) (&opcode_object(O)->arg0)
@<Type def...@>=
typedef struct {
        cell   owner;
        char   arg0;
        char   arg1;
        char   arg2;
} opcode_table;

@ @<Type def...@>=
typedef enum {
        OP_HALT, /* Instruction 0 for uninitialised memory. */
        OP_ADD,
        OP_ADDRESS,
        OP_ARRAY_P,
        OP_BODY,
        OP_BRANCH,
        OP_CAR,
        OP_CDR,
        OP_CLOSURE,
        OP_CLOSURE_P,
        OP_CMP,
        OP_CMPEQ_P,
        OP_CMPGE_P,
        OP_CMPGT_P,
        OP_CMPIS_P,
        OP_CMPLE_P,
        OP_CMPLT_P,
        OP_CONS,
        OP_DEFINE_M,
        OP_DELIMIT,
        OP_EXISTS_P,
        OP_EXTEND,
        OP_TABLE,
        OP_INTEGER_P,
        OP_JOIN,
        OP_JUMP,
        OP_LENGTH,
        OP_LOAD,
        OP_LOOKUP,
        OP_MUL,
        OP_OPEN,
        OP_PAIR_P,
        OP_PEEK,
        OP_PEEK2,
        OP_PEEK4,
        OP_PEEK8,
        OP_PEND,
        OP_POKE_M,
        OP_POKE2_M,
        OP_POKE4_M,
        OP_POKE8_M,
        OP_PRIMITIVE_P,
        OP_REPLACE_M,
        OP_RESUMPTION_P,
        OP_SEGMENT_P,
        OP_SIGNATURE,
        OP_SPORK,
        OP_SUB,
        OP_SYMBOL,
        OP_SYMBOL_P,
        OP_TRAP,
        OP_WIDEBRANCH,
        OP_WIDESPORK,
        OPCODE_LENGTH
} opcode;

@
@d NARG 0 /* No argument. */
@d AADD 1 /* An address. */
@d ALOB 2 /* An \Ls/ object. */
@d ALOT 3 /* A tiny \Ls/ object. */
@d AREG 4 /* A register. */
@d ARGH 5 /* A trap code (symbol, encoded as an 8-bit iny). */
@<Global...@>=
shared opcode_table Op[OPCODE_LENGTH] = {@|
        [OP_RESUMPTION_P]   = { NIL, AREG, ALOB, NARG },@|
        [OP_PRIMITIVE_P]    = { NIL, AREG, ALOB, NARG },@|
        [OP_WIDEBRANCH]     = { NIL, AADD, NARG, NARG },@|
        [OP_CLOSURE_P]      = { NIL, AREG, ALOB, NARG },@|
        [OP_INTEGER_P]      = { NIL, AREG, ALOB, NARG },@|
        [OP_REPLACE_M]      = { NIL, AREG, ALOB, NARG },@|
        [OP_SIGNATURE]      = { NIL, AREG, ALOB, NARG },@|
        [OP_WIDESPORK]      = { NIL, AADD, NARG, NARG },@|
        [OP_SEGMENT_P]      = { NIL, AREG, ALOB, NARG },@|
        [OP_DEFINE_M]       = { NIL, AREG, ALOB, NARG },@|
        [OP_EXISTS_P]       = { NIL, AREG, ALOT, ALOT },@|
        [OP_SYMBOL_P]       = { NIL, AREG, ALOB, NARG },@|
        [OP_ADDRESS]        = { NIL, AREG, ALOB, NARG },@|
        [OP_ARRAY_P]        = { NIL, AREG, ALOB, NARG },@|
        [OP_CLOSURE]        = { NIL, AREG, ALOT, ALOT },@|
        [OP_CMPEQ_P]        = { NIL, AREG, ALOT, ALOT },@|
        [OP_CMPGE_P]        = { NIL, AREG, ALOT, ALOT },@|
        [OP_CMPGT_P]        = { NIL, AREG, ALOT, ALOT },@|
        [OP_CMPIS_P]        = { NIL, AREG, ALOT, ALOT },@|
        [OP_CMPLE_P]        = { NIL, AREG, ALOT, ALOT },@|
        [OP_CMPLT_P]        = { NIL, AREG, ALOT, ALOT },@|
        [OP_DELIMIT]        = { NIL, AREG, NARG, NARG },@|
        [OP_POKE2_M]        = { NIL, AREG, ALOT, ALOT },@|
        [OP_POKE4_M]        = { NIL, AREG, ALOT, ALOT },@|
        [OP_POKE8_M]        = { NIL, AREG, ALOT, ALOT },@|
        [OP_BRANCH]         = { NIL, AREG, AADD, NARG },@|
        [OP_EXTEND]         = { NIL, AREG, ALOB, NARG },@|
        [OP_LENGTH]         = { NIL, AREG, ALOB, NARG },@|
        [OP_LOOKUP]         = { NIL, AREG, ALOT, ALOT },@|
        [OP_PAIR_P]         = { NIL, AREG, ALOB, NARG },@|
        [OP_POKE_M]         = { NIL, AREG, ALOT, ALOT },@|
        [OP_SYMBOL]         = { NIL, AREG, ALOT, ALOT },@|
        [OP_PEEK2]          = { NIL, AREG, ALOT, ALOT },@|
        [OP_PEEK4]          = { NIL, AREG, ALOT, ALOT },@|
        [OP_PEEK8]          = { NIL, AREG, ALOT, ALOT },@|
        [OP_SPORK]          = { NIL, AREG, AADD, NARG },@|
        [OP_TABLE]          = { NIL, AREG, ALOB, NARG },@|
        [OP_BODY]           = { NIL, AREG, ALOB, NARG },@|
        [OP_CONS]           = { NIL, AREG, ALOT, ALOT },@|
        [OP_HALT]           = { NIL, NARG, NARG, NARG },@|
        [OP_JOIN]           = { NIL, AREG, ALOB, NARG },@|
        [OP_JUMP]           = { NIL, AADD, NARG, NARG },@|
        [OP_LOAD]           = { NIL, AREG, ALOB, NARG },@|
        [OP_OPEN]           = { NIL, AREG, ALOB, NARG },@|
        [OP_PEEK]           = { NIL, AREG, ALOT, ALOT },@|
        [OP_PEND]           = { NIL, AREG, AADD, NARG },@|
        [OP_TRAP]           = { NIL, ARGH, NARG, NARG },@|
        [OP_ADD]            = { NIL, AREG, ALOT, ALOT },@|
        [OP_CAR]            = { NIL, AREG, ALOB, NARG },@|
        [OP_CDR]            = { NIL, AREG, ALOB, NARG },@|
        [OP_CMP]            = { NIL, AREG, ALOT, ALOT },@|
        [OP_MUL]            = { NIL, AREG, ALOT, ALOT },@|
        [OP_SUB]            = { NIL, AREG, ALOT, ALOT },@/
};

@ @<Extern...@>=
extern shared opcode_table Op[];

@ @<Data...@>=
shared char *Opcode_Label[OPCODE_LENGTH] = {@|
        [OP_RESUMPTION_P]   = "VM:RESUMPTION?",@|
        [OP_PRIMITIVE_P]    = "VM:PRIMITIVE?",@|
        [OP_WIDEBRANCH]     = "VM:WIDEBRANCH",@|
        [OP_CLOSURE_P]      = "VM:CLOSURE?",@|
        [OP_INTEGER_P]      = "VM:INTEGER?",@|
        [OP_REPLACE_M]      = "VM:REPLACE!",@|
        [OP_SIGNATURE]      = "VM:SIGNATURE",@|
        [OP_WIDESPORK]      = "VM:WIDESPORK",@|
        [OP_SEGMENT_P]      = "VM:SEGMENT?",@|
        [OP_DEFINE_M]       = "VM:DEFINE!",@|
        [OP_EXISTS_P]       = "VM:EXISTS?",@|
        [OP_SYMBOL_P]       = "VM:SYMBOL?",@|
        [OP_ADDRESS]        = "VM:ADDRESS",@|
        [OP_ARRAY_P]        = "VM:ARRAY?",@|
        [OP_CLOSURE]        = "VM:CLOSURE",@|
        [OP_CMPEQ_P]        = "VM:CMPEQ?",@|
        [OP_CMPGE_P]        = "VM:CMPGE?",@|
        [OP_CMPGT_P]        = "VM:CMPGT?",@|
        [OP_CMPIS_P]        = "VM:CMPIS?",@|
        [OP_CMPLE_P]        = "VM:CMPLE?",@|
        [OP_CMPLT_P]        = "VM:CMPLT?",@|
        [OP_DELIMIT]        = "VM:DELIMIT",@|
        [OP_POKE2_M]        = "VM:POKE2!",@|
        [OP_POKE4_M]        = "VM:POKE4!",@|
        [OP_POKE8_M]        = "VM:POKE8!",@|
        [OP_BRANCH]         = "VM:BRANCH",@|
        [OP_EXTEND]         = "VM:EXTEND",@|
        [OP_LENGTH]         = "VM:LENGTH",@|
        [OP_LOOKUP]         = "VM:LOOKUP",@|
        [OP_PAIR_P]         = "VM:PAIR?",@|
        [OP_POKE_M]         = "VM:POKE!",@|
        [OP_SYMBOL]         = "VM:SYMBOL",@|
        [OP_PEEK2]          = "VM:PEEK2",@|
        [OP_PEEK4]          = "VM:PEEK4",@|
        [OP_PEEK8]          = "VM:PEEK8",@|
        [OP_SPORK]          = "VM:SPORK",@|
        [OP_TABLE]          = "VM:TABLE",@|
        [OP_BODY]           = "VM:BODY",@|
        [OP_CONS]           = "VM:CONS",@|
        [OP_HALT]           = "VM:HALT",@|
        [OP_JOIN]           = "VM:JOIN",@|
        [OP_JUMP]           = "VM:JUMP",@|
        [OP_LOAD]           = "VM:LOAD",@|
        [OP_OPEN]           = "VM:OPEN",@|
        [OP_PEEK]           = "VM:PEEK",@|
        [OP_PEND]           = "VM:PEND",@|
        [OP_TRAP]           = "VM:TRAP",@|
        [OP_ADD]            = "VM:ADD",@|
        [OP_CAR]            = "VM:CAR",@|
        [OP_CDR]            = "VM:CDR",@|
        [OP_CMP]            = "VM:CMP",@|
        [OP_MUL]            = "VM:MUL",@|
        [OP_SUB]            = "VM:SUB",@/
};

@ @<Initialise ass...@>=
for (i = 0; i < OPCODE_LENGTH; i++) {
        orabort(new_symbol_cstr(Opcode_Label[i], &ltmp));
        orabort(new_atom(fix(i), ltmp, FORM_OPCODE, &Op[i].owner));
        orabort(env_save_m(Root, ltmp, Op[i].owner, false));
}

@* Run-time primitives.

@<Type def...@>=
typedef error_code @[@] (*primitive_fn)(cell, cell *);

typedef struct {
        cell    signature;
        cell    owner;
        address wrapper;
        primitive_fn action;
} primitive;

@ @d primitive_object(O) (&Primitive[fixed_value(A(O)->sin)])
@d primitive_address_c(O) (primitive_object(O)->wrapper)
@d primitive_signature_c(O) (primitive_object(O)->signature)
@<Type def...@>=
typedef enum {
        PRIMITIVE_ADD,
        PRIMITIVE_SUB,
        PRIMITIVE_MUL,

        PRIMITIVE_ARRAY_LENGTH,
        PRIMITIVE_ARRAY_OFFSET,
        PRIMITIVE_ARRAY_P,
        PRIMITIVE_ARRAY_REF,
        PRIMITIVE_ARRAY_RESIZE_M,
        PRIMITIVE_ARRAY_SET_M,
        PRIMITIVE_BOOLEAN_P,
        PRIMITIVE_CAR,
        PRIMITIVE_CDR,
        PRIMITIVE_CONS,
        PRIMITIVE_DO,
        PRIMITIVE_FALSE_P,
        PRIMITIVE_IS_P,
        PRIMITIVE_LAMBDA,
        PRIMITIVE_NEW_ARRAY,
        PRIMITIVE_NEW_SEGMENT,
        PRIMITIVE_NULL_P,
        PRIMITIVE_PAIR_P,
        PRIMITIVE_SEGMENT_LENGTH,
        PRIMITIVE_SEGMENT_P,
        PRIMITIVE_SEGMENT_RESIZE_M,
        PRIMITIVE_NEW_SYMBOL_SEGMENT,
        PRIMITIVE_SYMBOL_HASH,
        PRIMITIVE_SYMBOL_P,
        PRIMITIVE_SYMBOL_SEGMENT,
        PRIMITIVE_SYS_READ,
        PRIMITIVE_SYS_WRITE,
        PRIMITIVE_TRUE_P,
        PRIMITIVE_VOV,
        PRIMITIVE_CURRENT_ENVIRONMENT,
        PRIMITIVE_ROOT_ENVIRONMENT,

        PRIMITIVE_VOID_P,
        PRIMITIVE_INTEGER_P,

        PRIMITIVE_LENGTH
} primitive_code;
@#
enum {
        SIGNATURE_0,
        SIGNATURE_1,
        SIGNATURE_2,
        SIGNATURE_3,
        SIGNATURE_CL,
        SIGNATURE_ECL,
        SIGNATURE_LENGTH
};

@ @d PO(P,S,F) [(P)] = { (S), NIL, ADDRESS_INVALID, (F) }
@<Global...@>=
shared primitive Primitive[PRIMITIVE_LENGTH] = {
        PO(PRIMITIVE_ADD,                 SIGNATURE_2,   NULL),@/

        PO(PRIMITIVE_LAMBDA,              SIGNATURE_CL,  NULL),@/
        PO(PRIMITIVE_VOV,                 SIGNATURE_CL,  NULL),@/
        PO(PRIMITIVE_CAR,                 SIGNATURE_1,   NULL),@/
        PO(PRIMITIVE_ARRAY_LENGTH,        SIGNATURE_1,   NULL /*| primp_array_length |*/),@/
        PO(PRIMITIVE_CURRENT_ENVIRONMENT, SIGNATURE_0,   NULL),@/
        PO(PRIMITIVE_ROOT_ENVIRONMENT,    SIGNATURE_0,   NULL),@/
};

@ @<Extern...@>=
extern shared primitive Primitive[];

@ @<Data...@>=
shared char *Primitive_Label[PRIMITIVE_LENGTH] = {
        [PRIMITIVE_ADD]                 = "+",
        [PRIMITIVE_SUB]                 = "-",
        [PRIMITIVE_MUL]                 = "*",

        [PRIMITIVE_CURRENT_ENVIRONMENT] = "current-environment",
        [PRIMITIVE_ROOT_ENVIRONMENT]    = "root-environment",
        [PRIMITIVE_ARRAY_LENGTH]        = "array/length",
        [PRIMITIVE_ARRAY_OFFSET]        = "array/offset",
        [PRIMITIVE_ARRAY_P]             = "array?",
        [PRIMITIVE_ARRAY_REF]           = "array/ref",
        [PRIMITIVE_ARRAY_RESIZE_M]      = "array/resize!",
        [PRIMITIVE_ARRAY_SET_M]         = "array/set!",
        [PRIMITIVE_BOOLEAN_P]           = "boolean?",
        [PRIMITIVE_CAR]                 = "car",
        [PRIMITIVE_CDR]                 = "cdr",
        [PRIMITIVE_CONS]                = "cons",
        [PRIMITIVE_DO]                  = "do",
        [PRIMITIVE_FALSE_P]             = "false?",
        [PRIMITIVE_IS_P]                = "is?",
        [PRIMITIVE_LAMBDA]              = "lambda",
        [PRIMITIVE_NEW_ARRAY]           = "new-array",
        [PRIMITIVE_NEW_SEGMENT]         = "new-segment",
        [PRIMITIVE_NULL_P]              = "null?",
        [PRIMITIVE_PAIR_P]              = "pair?",
        [PRIMITIVE_SEGMENT_LENGTH]      = "segment/length",
        [PRIMITIVE_SEGMENT_P]           = "segment?",
        [PRIMITIVE_SEGMENT_RESIZE_M]    = "segment/resize!",
        [PRIMITIVE_NEW_SYMBOL_SEGMENT]  = "segment->symbol",
        [PRIMITIVE_SYMBOL_HASH]         = "symbol/hash",
        [PRIMITIVE_SYMBOL_P]            = "symbol?",
        [PRIMITIVE_SYMBOL_SEGMENT]      = "symbol/segment",
        [PRIMITIVE_SYS_READ]            = "sys/read",
        [PRIMITIVE_SYS_WRITE]           = "sys/write",
        [PRIMITIVE_TRUE_P]              = "true?",
        [PRIMITIVE_VOV]                 = "vov",

        [PRIMITIVE_VOID_P]              = "void?",
        [PRIMITIVE_INTEGER_P]           = "integer?",
};

@ @<Global...@>=
shared address Interpret_Closure = ADDRESS_INVALID;

@ @<Extern...@>=
extern shared address Interpret_Closure;

@ @<Initialise \Ls/...@>=
orreturn(new_symbol_const("eval", &sig_eval));
orreturn(cons(sig_eval, NIL, &sig_eval));
orreturn(new_symbol_const("copy", &sig_copy));
orreturn(cons(sig_copy, NIL, &sig_copy));
orreturn(new_symbol_const("copy-list", &sig_list));
orreturn(cons(sig_list, NIL, &sig_list));
@#
orreturn(cons(fix(0), sig_copy, copy + 0));
orreturn(cons(fix(1), sig_copy, copy + 1));
orreturn(cons(fix(2), sig_copy, copy + 2));
orreturn(cons(fix(0), sig_list, list + 0));
orreturn(cons(fix(1), sig_list, list + 1));
orreturn(cons(fix(2), sig_list, list + 2));
orreturn(cons(fix(0), sig_eval, eval + 0));
orreturn(cons(fix(1), sig_eval, eval + 1));
orreturn(cons(fix(2), sig_eval, eval + 2));
orreturn(cons(fix(3), sig_eval, eval + 3));
@#
sig[SIGNATURE_0] = NIL;
@#
orreturn(cons(eval[0], NIL, sig + SIGNATURE_1));
@#
orreturn(cons(eval[1], NIL, sig + SIGNATURE_2));
orreturn(cons(eval[0], sig[SIGNATURE_2], sig + SIGNATURE_2));
@#
orreturn(cons(eval[2], NIL, sig + SIGNATURE_3));
orreturn(cons(eval[1], sig[SIGNATURE_3], sig + SIGNATURE_3));
orreturn(cons(eval[0], sig[SIGNATURE_3], sig + SIGNATURE_3));
@#
orreturn(cons(list[1], NIL, sig + SIGNATURE_CL));
orreturn(cons(copy[0], sig[SIGNATURE_CL], sig + SIGNATURE_CL));
@#
orreturn(cons(list[2], NIL, sig + SIGNATURE_ECL));
orreturn(cons(copy[1], sig[SIGNATURE_ECL], sig + SIGNATURE_ECL));
orreturn(cons(eval[0], sig[SIGNATURE_ECL], sig + SIGNATURE_ECL));
@#
for (i = 0; i < PRIMITIVE_LENGTH; i++) {
        Primitive[i].signature = sig[Primitive[i].signature];
        orreturn(new_symbol_cstr(Primitive_Label[i], &ltmp));
        orreturn(new_atom(fix(i), ltmp, FORM_PRIMITIVE, &Primitive[i].owner));
        orreturn(env_save_m(Root, ltmp, Primitive[i].owner, false));
}

@ @d PRIMITIVE_PREFIX "!Primitive/"
@d PRIMITIVE_DEFAULT "!Primitive.Default"
@d PRIMITIVE_INTERPRET "!Interpret-Closure"
@<Link \Ls/...@>=
k = 11 + 7; /* |strlen(PRIMITIVE_WRAPPER)| */
memmove(btmp, PRIMITIVE_DEFAULT, k);
orreturn(new_symbol_buffer((byte *) btmp, k, NULL, &ltmp));
orreturn(vm_locate_entry(ltmp, &adefault));
@#
k = 11; /* |strlen(PRIMITIVE_PREFIX)| */
btmp[k - 1] = '/'; /* |memmove(btmp, PRIMITIVE_PREFIX, k)| */
for (i = 0; i < PRIMITIVE_LENGTH; i++) {
        bptr = btmp + k;
        for (j = 0; Primitive_Label[i][j]; j++, bptr++)
                *bptr = Primitive_Label[i][j];
        orreturn(new_symbol_buffer((byte *) btmp, k + j, NULL, &ltmp));
        reason = vm_locate_entry(ltmp, &atmp);
        if (reason == LERR_MISSING)
                Primitive[i].wrapper = adefault;
        else if (failure_p(reason))
                return reason;
        else
                Primitive[i].wrapper = atmp;
}
orreturn(new_symbol_const(PRIMITIVE_INTERPRET, &ltmp));
orreturn(vm_locate_entry(ltmp, &Interpret_Closure));

@* Stack. Based on list or array.

@<Fun...@>=
error_code init_stack_array (cell *);
error_code init_stack_list (cell *);
error_code stack_array_enlarge (cell *);
error_code stack_array_peek (cell *, cell *);
error_code stack_array_pop (cell *, cell *);
error_code stack_array_push (cell *, cell);
error_code stack_array_reduce (cell *);
error_code stack_list_pop_imp (cell *, bool, cell *);
error_code stack_list_push (cell *, cell);

@ @<Initialise run-time ...@>=
orreturn(init_stack_array(&Control_Link));

@ @c
error_code
init_stack_list (cell *ret)
{
        *ret = NIL;
        return LERR_NONE;
}

@ @c
error_code
stack_list_push (cell *stack,
                 cell  value)
{
        error_code reason;

        orreturn(cons(value, *stack, stack));
        return LERR_NONE;
}

@ @d stack_list_pop(S,R) stack_list_pop_imp((S), true, (R))
@d stack_list_peek(S,R) stack_list_pop_imp((S), false, (R))
@c
error_code
stack_list_pop_imp (cell *stack,
                    bool  popping,
                    cell *ret)
{
        if (null_p(*stack))
                return LERR_UNDERFLOW;
        else if (!pair_p(*stack))
                return LERR_INCOMPATIBLE;
        *ret = A(*stack)->sin;
        if (popping)
                *stack = A(*stack)->dex;
        return LERR_NONE;
}

@ @c
error_code
init_stack_array (cell *ret)
{
        error_code reason;
        orreturn(new_array(1 + (32 * CELL_BYTES), fix(0), ret));
        array_base(*ret)[0] = fix(1);
        return LERR_NONE;
}

@ @d stack_array_p(O) (array_p(O) && array_length_c(O) > 0
        && fixed_p(array_base(O)[0]) && fixed_value(array_base(O)[0]) > 0
        && fixed_value(array_base(O)[0]) <= array_length_c(O))

@ @c
error_code
stack_array_push (cell *stack,
                  cell  value)
{
        half sp;
        assert(stack_array_p(*stack));
        sp = fixed_value(array_base(*stack)[0]);
        if (sp == array_length_c(*stack))
                return LERR_OVERFLOW;
        array_base(*stack)[sp++] = value;
        array_base(*stack)[0] = fix(sp);
        return LERR_NONE;
}

@ @c
error_code
stack_array_pop (cell *stack,
                 cell *ret)
{
        half sp;
        assert(stack_array_p(*stack));
        sp = fixed_value(array_base(*stack)[0]);
        if (sp == 1)
                return LERR_UNDERFLOW;
        *ret = array_base(*stack)[--sp];
        array_base(*stack)[0] = fix(sp);
        return LERR_NONE;
}

@ @c
error_code
stack_array_peek (cell *stack,
                  cell *ret)
{
        half sp;
        assert(stack_array_p(*stack));
        sp = fixed_value(array_base(*stack)[0]);
        if (sp == 1)
                return LERR_UNDERFLOW;
        *ret = array_base(*stack)[sp - 1];
        return LERR_NONE;
}

@ @c
error_code
stack_array_enlarge (cell *stack)
{
        half nlength;
        assert(stack_array_p(*stack));
        nlength = array_length_c(*stack) + 64;
        return array_resize_m(*stack, nlength, NIL);
}

@ @c
error_code
stack_array_reduce (cell *stack)
{
        half nlength;
        assert(stack_array_p(*stack));
        assert(array_length_c(*stack) > 65);
        nlength = array_length_c(*stack) + 64;
        return array_resize_m(*stack, nlength, NIL);
}

@* Interpreter.

@d IB(I,B)  ((int32_t) (((char *) &(I))[B]))
@d UB(I,B)  ((uint32_t) (((unsigned char *) &(I))[B]))
@#
@d MODE(I)  ((UB((I), 0) >> 6) & 0x03)
@d OP(I)    ((UB((I), 0) >> 0) & 0x3f)
@#
@d SINT(I)  ((int16_t) (be32toh(I) & 0xffff))
@d UINT(I)  ((uint16_t) (be32toh(I) & 0xffff))
@#
@d TBLLO(I) ((UB((I), 2) << 8) | UB((I), 3))
@d TBLHI(I) ((UB((I), 1) & 0xc0) << 10)
@d TABLE(I) (TBLHI(I) | TBLLO(I))
@#
@d REG(I,B) (UB((I), (B)) & 0x3f)
@d POP(I,B) (UB((I), (B)) & 0x80)
@#
@d BYTECODE_ADDRESS_DIRECT   0 /* Unsigned 16/24 bit offset; unused. */
@d BYTECODE_ADDRESS_INDIRECT 1 /* Unsigned 16/24 bit offset to |PROGRAM_EXPORT_BASE|
                                has pointer-size address. */
@d BYTECODE_ADDRESS_RELATIVE 2 /* Signed 16 bit delta. */
@d BYTECODE_ADDRESS_REGISTER 3 /* Integer in a register */
@d BYTECODE_FIRST_REGISTER   2 /* These are not backwards. */
@d BYTECODE_SECOND_REGISTER  1
@d BYTECODE_OBJECT_CONSTANT  0 /* Small fixed integers also; ignore low byte */
@d BYTECODE_OBJECT_INTEGER   1 /* 16 bit signed. */
@d BYTECODE_OBJECT_REGISTER  2 /* Ignore low byte */
@d BYTECODE_OBJECT_TABLE     3 /* Index into global table. */
@d BYTECODE_CONSTANT_INTEGER 0x80
@d BYTECODE_CONSTANT_SPECIAL 0x00
@<Fun...@>=
error_code interpret (void);
error_code interpret_address16 (instruction, address *);
error_code interpret_address24 (instruction, address *);
error_code interpret_argument (instruction, int, cell *);
int32_t interpret_int16 (instruction, bool);
int32_t interpret_int24 (instruction, bool);
error_code interpret_register (instruction, int, cell *);
error_code interpret_save (instruction, cell);
error_code interpret_solo_argument (instruction, cell *);
error_code interpret_tiny_object (instruction, int, cell *);
@
@d pins(O) for (int _i = 0; _i < 4; _i++)
        printf("%02hhx", ((char *) (O))[_i])
@d psym(O) for (half _i = 0; _i < symbol_length_c(O); _i++)
        putchar(symbol_buffer_c(O)[_i]);
@c
error_code
interpret (void)
{
        address link;
        instruction ins; /* Register? A copy of the current instruction. */
        int width;
        error_code reason;

        Trapped = LERR_NONE;
        while (!failure_p(Trapped)) {
                reason = LERR_NONE;
                if (Ip < 0 || Ip >= ADDRESS_INVALID) {
                        ins = 0;
                        reason = LERR_ADDRESS;
                        goto Trap;
                }
                ins = *(instruction *) Ip;
                Ip += sizeof (instruction);
Reinterpret:
#ifdef LLTEST
#if 0
                printf("%7lu %p: ", Interpret_Count, (void *) (Ip - sizeof (instruction)));
                pins(&ins); putchar(' '); psym(opcode_label_c(Op[OP(ins)].owner)); putchar('\n');
#endif
                Interpret_Count++;
                if (Interpret_Limit && Interpret_Count >= Interpret_Limit)
                        return LERR_LENGTH; /* Cheeky. */
#endif
                switch (OP(ins)) { @<Carry out an operation@> }
        }
Halt:
        return reason;
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
        case 1: regp = MODE(ins) & BYTECODE_FIRST_REGISTER;@+ break;
        case 2: regp = MODE(ins) & BYTECODE_SECOND_REGISTER;@+ break;
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
                return new_pointer(Ip, ret);
        case LR_Trap_Ip:
                if (POP(ins, argc + 1))
                        return LERR_INCOMPATIBLE;
                return new_pointer(Trap_Ip, ret);
        case LR_Trapped:
                if (POP(ins, argc + 1))
                        return LERR_INCOMPATIBLE;
                *ret = Error[Trapped];
                return LERR_NONE;
        case LR_Control_Link:
                if (POP(ins, argc + 1))
                        return stack_array_pop(Register[REG(ins, argc + 1)], ret);
                else
                        return stack_array_peek(Register[REG(ins, argc + 1)], ret);
        default:
                if (argc && POP(ins, argc + 1))
                        return stack_list_pop(Register[REG(ins, argc + 1)], ret);
                else
                        *ret = *Register[REG(ins, argc + 1)];
                return LERR_NONE;
        }
}

@ @c
error_code
interpret_solo_argument (instruction  ins,
                         cell        *ret)
{
        long index;
        int16_t value;

        switch(MODE(ins)) {
        case BYTECODE_OBJECT_CONSTANT:@;
                return interpret_tiny_object(ins, 1, ret);
        case BYTECODE_OBJECT_INTEGER:@;
                value = SINT(ins);
                return new_int_c(value, ret);
        case BYTECODE_OBJECT_REGISTER:@;
                return interpret_register(ins, 1, ret);
        case BYTECODE_OBJECT_TABLE:@;
                index = TABLE(ins);
                if (index > Program_ObjectDB_Free)
                        return LERR_OUT_OF_BOUNDS;
                *ret = array_base(Program_ObjectDB)[index];
                return LERR_NONE;
        default:
                return LERR_INTERNAL;
        }
}

@ @c
error_code
interpret_tiny_object (instruction  ins,
                       int          argc,
                       cell        *ret)
{
        char value;
        bool wasfix;

        assert(argc >= 1 && argc <= 2);
        value = UB(ins, argc + 1);
        wasfix = value & 0x80;
        value = ((value & 0x7f) | ((value & 0x40) << 1));
        if (wasfix)
                *ret = fix(value);
        else {
                if (value)
                        value = (value * 2) - 1;
                if (!valid_p(value))
                        return LERR_INCOMPATIBLE;
                else
                        *ret = value;
        }
        return LERR_NONE;
}

@ @c
error_code
interpret_address16 (instruction  ins,
                     address     *ret)
{
        address from, to, ivia;
        cell rvia;
        error_code reason;

        from = Ip - sizeof (instruction);
        switch (MODE(ins)) {
        case BYTECODE_ADDRESS_DIRECT:@;
                to = interpret_int16(ins, false) | instruction_page(from);
                break;
        case BYTECODE_ADDRESS_RELATIVE:@;
                to = interpret_int16(ins, true) + from;
                if (instruction_page(to) != instruction_page(from))
                        return LERR_OUT_OF_BOUNDS;
                break;
        case BYTECODE_ADDRESS_INDIRECT:@;
                ivia = interpret_int16(ins, false);
                if (ivia >= (address) Program_Export_Free)
                        return LERR_OUT_OF_BOUNDS;
                to = Program_Export_Base[ivia];
                break;
        case BYTECODE_ADDRESS_REGISTER:@;
                orreturn(interpret_register(ins, 1, &rvia));
                assert(pointer_p(rvia));
                to = (address) pointer(rvia);
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
        address from, to, ivia;
        cell rvia;
        error_code reason;

        from = Ip - sizeof (instruction);
        switch (MODE(ins)) {
        case BYTECODE_ADDRESS_DIRECT:@;
                to = interpret_int24(ins, false) | instruction_page(from);
                break;
        case BYTECODE_ADDRESS_RELATIVE:@;
                to = interpret_int24(ins, true) + from;
                if (instruction_page(to) != instruction_page(from))
                        return LERR_OUT_OF_BOUNDS;
                break;
        case BYTECODE_ADDRESS_INDIRECT:@;
                ivia = interpret_int24(ins, false);
                if (ivia >= (address) Program_Export_Free)
                        return LERR_OUT_OF_BOUNDS;
                to = Program_Export_Base[ivia];
                break;
        case BYTECODE_ADDRESS_REGISTER:@;
                orreturn(interpret_register(ins, 0, &rvia));
                assert(pointer_p(rvia));
                to = (address) pointer(rvia);
                break;
        }
        *ret = to;
        return LERR_NONE;
}

@ @c
int32_t
interpret_int16 (instruction ins,
                 bool        sign)
{
        int32_t rval;
        rval = sign ? SINT(ins) : UINT(ins);
        return rval;
}

@ @c
int32_t
interpret_int24 (instruction ins,
                 bool        sign)
{
        int32_t rval;
        rval = (UB(ins, 1) << 16) | UINT(ins);
        if (sign && (UB(ins, 1) & 0x80))
                rval |= 0xff000000;
        return rval;
}

@ @c
@.TODO@>
error_code
interpret_save (instruction ins,
                cell        result)
{
        switch (REG(ins, 1)) {
        case LR_Ip:@; /* Could be mutable, but why? */
        case LR_Root:@;
        case LR_Symbol_Table:@;
        case LR_Trap_Handler:@; /* TODO */
        case LR_Trap_Ip:@;
        case LR_Trapped:@;
                return LERR_IMMUTABLE;
        case LR_Control_Link:@;
                return stack_array_push(Register[REG(ins, 1)], result);
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

@ @<Carry out...@>=
default:
        if (OP(ins) >= 0 && OP(ins) < OPCODE_LENGTH)
                reason = LERR_UNIMPLEMENTED;
        else
                reason = LERR_INSTRUCTION;
        goto Trap;
case OP_TRAP:
        ortrap(interpret_argument(ins, 1, &VM_Arg1));
        assert(fixed_p(VM_Arg1));
        reason = fixed_value(VM_Arg1);
Trap:
        Trapped = failure_p(reason) ? reason : LERR_INTERNAL;
        if (Trap_Handler[reason] == ADDRESS_INVALID)
                goto Halt;
        else {
                Trapped = LERR_NONE;
                Trap_Ip = Ip;
                Trap_Arg1 = VM_Arg1;
                Trap_Arg2 = VM_Arg2;
                Trap_Result = VM_Result;
                Ip = Trap_Handler[reason];
        }
        break;
@#
case OP_HALT:@;
        reason = LERR_NONE;
        goto Halt;

@ @<Carry out...@>=
case OP_JUMP:@;
        ortrap(interpret_address24(ins, &Ip));
        break;
case OP_BRANCH:@; /* Although using |interpret_argument| we know arg 0
                        must be a register. */
        ortrap(interpret_argument(ins, 0, &VM_Result));
        if (POP(ins, 1)) {
                if (false_p(VM_Result))
                        ortrap(interpret_address16(ins, &Ip));
        } else {
                if (true_p(VM_Result))
                        ortrap(interpret_address16(ins, &Ip));
        }
        break;
case OP_WIDEBRANCH:@;
        if (true_p(Accumulator))
                ortrap(interpret_address24(ins, &Ip));
        break;

@ @<Carry out...@>=
case OP_LOAD:@;
        ortrap(interpret_solo_argument(ins, &VM_Result));
        ortrap(interpret_save(ins, VM_Result));
        break;
case OP_PEND:@;
        ortrap(interpret_address16(ins, &link));
        orassert(new_pointer(link, &VM_Result));
        ortrap(interpret_save(ins, VM_Result));
        break;

@ @<Carry out...@>=
case OP_PAIR_P:
        ortrap(interpret_solo_argument(ins, &VM_Arg1));
        VM_Result = predicate(pair_p(VM_Arg1));
        ortrap(interpret_save(ins, VM_Result));
        break;
case OP_ARRAY_P:
        ortrap(interpret_solo_argument(ins, &VM_Arg1));
        VM_Result = predicate(segment_p(VM_Arg1));
        ortrap(interpret_save(ins, VM_Result));
        break;
case OP_SEGMENT_P:
        ortrap(interpret_solo_argument(ins, &VM_Arg1));
        VM_Result = predicate(segment_p(VM_Arg1));
        ortrap(interpret_save(ins, VM_Result));
        break;
case OP_SYMBOL_P:
        ortrap(interpret_solo_argument(ins, &VM_Arg1));
        VM_Result = predicate(symbol_p(VM_Arg1));
        ortrap(interpret_save(ins, VM_Result));
        break;
case OP_CLOSURE_P:
        ortrap(interpret_solo_argument(ins, &VM_Arg1));
        VM_Result = predicate(closure_p(VM_Arg1));
        ortrap(interpret_save(ins, VM_Result));
        break;
case OP_PRIMITIVE_P:
        ortrap(interpret_solo_argument(ins, &VM_Arg1));
        VM_Result = predicate(primitive_p(VM_Arg1));
        ortrap(interpret_save(ins, VM_Result));
        break;
case OP_RESUMPTION_P:
        ortrap(interpret_solo_argument(ins, &VM_Arg1));
        VM_Result = LFALSE;
        ortrap(interpret_save(ins, VM_Result));
        break;
case OP_INTEGER_P:
        ortrap(interpret_solo_argument(ins, &VM_Arg1));
        VM_Result = predicate(integer_p(VM_Arg1));
        ortrap(interpret_save(ins, VM_Result));
        break;

@ These two functions have different signatures.

@<Carry out...@>=
case OP_EXISTS_P:@;
case OP_LOOKUP:@;
        ortrap(interpret_argument(ins, 1, &VM_Arg1)); /* Table */
        ortrap(interpret_argument(ins, 2, &VM_Arg2)); /* Label */
        if (environment_p(VM_Arg1)) {
                reason = env_search(VM_Arg1, VM_Arg2, &VM_Result);
                if (reason == LERR_MISSING && OP(ins) == OP_EXISTS_P)
                        VM_Result = LFALSE;
                else if (failure_p(reason))
                        goto Trap;
                else if (OP(ins) == OP_EXISTS_P)
                        VM_Result = LTRUE;
        } else {
                ortrap(hashtable_search(VM_Arg1, VM_Arg2, &VM_Result));
                if (OP(ins) == OP_EXISTS_P)
                        VM_Result = predicate(defined_p(VM_Result));
        }
        ortrap(interpret_save(ins, VM_Result));
        break;
case OP_EXTEND:@;
        ortrap(interpret_solo_argument(ins, &VM_Arg1));
        ortrap(new_env(VM_Arg1, &VM_Result));
        ortrap(interpret_save(ins, VM_Result));
        break;
case OP_TABLE:@;
        ortrap(interpret_solo_argument(ins, &VM_Arg1));
        assert(fixed_p(VM_Arg1));
        assert(fixed_value(VM_Arg1) >= 0
                && fixed_value(VM_Arg1) <= (word) HASHTABLE_MAX_FREE);
        ortrap(new_hashtable(fixed_value(VM_Arg1), &VM_Result));
        ortrap(interpret_save(ins, VM_Result));
        break;
case OP_DEFINE_M:@;
case OP_REPLACE_M:@;
        ortrap(interpret_argument(ins, 0, &VM_Arg1)); /* Table */
        ortrap(interpret_argument(ins, 1, &VM_Arg2)); /* Datum */
        if (environment_p(VM_Arg1))
                ortrap(env_save_m_imp(VM_Arg1, VM_Arg2,
                        OP(ins) == OP_REPLACE_M));
        else
                ortrap(hashtable_save_m(VM_Arg1, VM_Arg2,
                        OP(ins) == OP_REPLACE_M));
        break;

@ The CONS opcode calls cons.

@<Carry out...@>=
case OP_CONS:@;
        ortrap(interpret_argument(ins, 1, &VM_Arg1));
        ortrap(interpret_argument(ins, 2, &VM_Arg2));
        assert(defined_p(VM_Arg1) && defined_p(VM_Arg2)); /* |cons| is a
                                                macro without an assertion. */
        ortrap(cons(VM_Arg1, VM_Arg2, &VM_Result));
        ortrap(interpret_save(ins, VM_Result));
        break;
case OP_CAR:@;
        ortrap(interpret_solo_argument(ins, &VM_Arg1));
        assert(pair_p(VM_Arg1));
        VM_Result = A(VM_Arg1)->sin;
        ortrap(interpret_save(ins, VM_Result));
        break;
case OP_CDR:@;
        ortrap(interpret_solo_argument(ins, &VM_Arg1));
        assert(pair_p(VM_Arg1));
        VM_Result = A(VM_Arg1)->dex;
        ortrap(interpret_save(ins, VM_Result));
        break;

@ Everything but numbers are \.{is?\/}-identical based on pointer
equality à la \.{eq?\/} in scheme. Integers and runes base identity
on their {\it value\/} (and form) not their address. Numerically
identical integers are is?-identical to each other, and runes are
\.{is?\/}-identical to each other, but an integer will never
\.{is?\/}-match a rune.

No idea what to say about floats yet.

@<Carry out...@>=
case OP_CMPIS_P:@;
        ortrap(interpret_argument(ins, 1, &VM_Arg1)); /* Yin */
        ortrap(interpret_argument(ins, 2, &VM_Arg2)); /* Yang */
        VM_Result = predicate(cmpis_p(VM_Arg1, VM_Arg2));
        ortrap(interpret_save(ins, VM_Result));
        break;

@ @<Carry out...@>=
case OP_CMP:
case OP_CMPGT_P:
case OP_CMPGE_P:
case OP_CMPEQ_P:
case OP_CMPLE_P:
case OP_CMPLT_P:
        ortrap(interpret_argument(ins, 1, &VM_Arg1)); /* Yin */
        ortrap(interpret_argument(ins, 2, &VM_Arg2)); /* Yang */
        ortrap(int_cmp(VM_Arg1, VM_Arg2, &VM_Result));
        switch(OP(ins)) {
        case OP_CMP:
                break; /* This is fine. */
        case OP_CMPGT_P: /* Yin (<:-1),(=:0),(>:+1) Yang? */
                VM_Result = predicate(fixed_value(VM_Result) > 0);@+
                break;
        case OP_CMPGE_P:
                VM_Result = predicate(fixed_value(VM_Result) >= 0);@+
                break;
        case OP_CMPEQ_P:
                VM_Result = predicate(fixed_value(VM_Result) == 0);@+
                break;
        case OP_CMPLE_P:
                VM_Result = predicate(fixed_value(VM_Result) <= 0);@+
                break;
        case OP_CMPLT_P:
                VM_Result = predicate(fixed_value(VM_Result) < 0);@+
                break;
        }
        ortrap(interpret_save(ins, VM_Result));
        break;

@ @<Type def...@>=
enum {
        CLOSURE_ADDRESS,
        CLOSURE_BODY,
        CLOSURE_ENVIRONMENT,
        CLOSURE_SIGNATURE,
        CLOSURE_LENGTH
};

@ @<Fun...@>=
error_code new_closure (cell, cell, cell *);
error_code closure_body (cell, cell *);
error_code closure_address (cell, cell *);
error_code closure_environment (cell, cell *);
error_code closure_signature (cell, cell *);

@ @c
error_code
new_closure (cell  sign,
             cell  body,
             cell *ret)
{
        cell start;
        error_code reason;

        assert(null_p(sign) || pair_p(sign));
        assert(null_p(body) || pair_p(body));
        orreturn(new_pointer(Interpret_Closure, &start));
        orreturn(new_array_imp(CLOSURE_LENGTH, fix(0), NIL, FORM_CLOSURE, ret));
        array_base(*ret)[CLOSURE_ADDRESS] = start;
        array_base(*ret)[CLOSURE_BODY] = body;
        array_base(*ret)[CLOSURE_SIGNATURE] = sign;
        array_base(*ret)[CLOSURE_ENVIRONMENT] = Environment;
        return LERR_NONE;
}

@ @c
error_code
closure_address (cell  o,
                 cell *ret)
{
        assert(closure_p(o));
        *ret = array_base(o)[CLOSURE_ADDRESS];
        return LERR_NONE;
}

@ @c
error_code
closure_body (cell  o,
              cell *ret)
{
        assert(closure_p(o));
        *ret = array_base(o)[CLOSURE_BODY];
        return LERR_NONE;
}

@ @c
error_code
closure_environment (cell  o,
                     cell *ret)
{
        assert(closure_p(o));
        *ret = array_base(o)[CLOSURE_ENVIRONMENT];
        return LERR_NONE;
}

@ @c
error_code
closure_signature (cell  o,
                   cell *ret)
{
        assert(closure_p(o));
        *ret = array_base(o)[CLOSURE_SIGNATURE];
        return LERR_NONE;
}

@ arg1: (nargs . reversed-formals) or (signature-list . reversed-formals)?
arg2: body

@<Carry out...@>=
case OP_CLOSURE:@;
        ortrap(interpret_argument(ins, 1, &VM_Arg1)); /* Signature */
        ortrap(interpret_argument(ins, 2, &VM_Arg2)); /* Body */
        ortrap(new_closure(VM_Arg1, VM_Arg2, &VM_Result));
        ortrap(interpret_save(ins, VM_Result));
        break;
case OP_OPEN:@;
        ortrap(interpret_solo_argument(ins, &VM_Arg1));
        assert(primitive_p(VM_Arg1) || closure_p(VM_Arg1));
        if (primitive_p(VM_Arg1)) { /* Root? */
                reason = LERR_UNIMPLEMENTED;
                goto Trap;
        } else
                ortrap(closure_environment(VM_Arg1, &VM_Result));
        ortrap(interpret_save(ins, VM_Result));
        break;
case OP_ADDRESS:@;
        ortrap(interpret_solo_argument(ins, &VM_Arg1));
        assert(primitive_p(VM_Arg1) || closure_p(VM_Arg1));
        if (primitive_p(VM_Arg1))
                ortrap(new_pointer(primitive_address_c(VM_Arg1), &VM_Result));
        else
                ortrap(closure_address(VM_Arg1, &VM_Result));
        ortrap(interpret_save(ins, VM_Result));
        break;
case OP_BODY:@;
        ortrap(interpret_solo_argument(ins, &VM_Arg1));
        assert(primitive_p(VM_Arg1) || closure_p(VM_Arg1));
        if (primitive_p(VM_Arg1)) { /* Root? */
                reason = LERR_UNIMPLEMENTED;
                goto Trap;
        } else
                ortrap(closure_body(VM_Arg1, &VM_Result));
        ortrap(interpret_save(ins, VM_Result));
        break;
case OP_SIGNATURE:@;
        ortrap(interpret_solo_argument(ins, &VM_Arg1));
        assert(primitive_p(VM_Arg1) || closure_p(VM_Arg1));
        if (primitive_p(VM_Arg1))
                VM_Result = primitive_signature_c(VM_Arg1);
        else
                ortrap(closure_signature(VM_Arg1, &VM_Result));
        ortrap(interpret_save(ins, VM_Result));
        break;

@ @<Carry out...@>=
case OP_LENGTH:@;
        ortrap(interpret_solo_argument(ins, &VM_Arg1));
        if (segment_p(VM_Arg1))
                new_int_c(segment_length_c(VM_Arg1), &VM_Result);
        else if (symbol_p(VM_Arg1))
                new_int_c(symbol_length_c(VM_Arg1), &VM_Result);
        else if (array_p(VM_Arg1))
                new_int_c(array_length_c(VM_Arg1), &VM_Result);
        else if (fixed_p(VM_Arg1))
                VM_Result = fix(0);
        else if (integer_p(VM_Arg1))
                ortrap(int_length(VM_Arg1, &VM_Result));
        else
                assert(!"unreachable");
        ortrap(interpret_save(ins, VM_Result));
        break;

@ Unusually this opcode takes 3 arguments and always puts its result
in the accumulator.

@<Carry out...@>=
case OP_SYMBOL:@;
        ortrap(interpret_argument(ins, 0, &VM_Result));
        ortrap(interpret_argument(ins, 1, &VM_Arg1));
        ortrap(interpret_argument(ins, 2, &VM_Arg2));
        assert(fixed_p(VM_Arg1));
        assert(fixed_p(VM_Arg2));
        ortrap(new_symbol_segment(VM_Result, fixed_value(VM_Arg1),
                fixed_value(VM_Arg2), &VM_Result));
        Accumulator = VM_Result;
        break;

@ @<Carry out...@>=
case OP_PEEK8:
        width = 8;
        goto PEEK;
case OP_PEEK4:
        width = 4;
        goto PEEK;
case OP_PEEK2:
        width = 2;
        goto PEEK;
case OP_PEEK:
        width = 1;
PEEK:
        ortrap(interpret_argument(ins, 1, &VM_Arg1)); /* Segment */
        ortrap(interpret_argument(ins, 2, &VM_Arg2)); /* Offset */
        ortrap(segment_peek(VM_Arg1, fixed_value(VM_Arg2), width, false,
                &VM_Result));
        ortrap(interpret_save(ins, VM_Result));
        break;

@ @<Carry out...@>=
case OP_POKE8_M:
        width = 8;
        goto POKE;
case OP_POKE4_M:
        width = 4;
        goto POKE;
case OP_POKE2_M:
        width = 2;
        goto POKE;
case OP_POKE_M:
        width = 1;
POKE:
        ortrap(interpret_argument(ins, 0, &VM_Result)); /* Segment */
        ortrap(interpret_argument(ins, 1, &VM_Arg1)); /* Offset */
        ortrap(interpret_argument(ins, 2, &VM_Arg2)); /* Value */
        ortrap(segment_poke_m(VM_Result, fixed_value(VM_Arg1), width,
                false, VM_Arg2));
        break;

@ @<Carry out...@>=
case OP_ADD:
        ortrap(interpret_argument(ins, 1, &VM_Arg1)); /* Yin */
        ortrap(interpret_argument(ins, 2, &VM_Arg2)); /* Yang */
        ortrap(int_add(VM_Arg1, VM_Arg2, &VM_Result));
        ortrap(interpret_save(ins, VM_Result));
        break;
case OP_SUB:
        ortrap(interpret_argument(ins, 1, &VM_Arg1)); /* Yin */
        ortrap(interpret_argument(ins, 2, &VM_Arg2)); /* Yang */
        ortrap(int_sub(VM_Arg1, VM_Arg2, &VM_Result));
        ortrap(interpret_save(ins, VM_Result));
        break;

@ @<Carry out...@>=
case OP_MUL:
        ortrap(interpret_argument(ins, 1, &VM_Arg1)); /* Yin */
        ortrap(interpret_argument(ins, 2, &VM_Arg2)); /* Yang */
        ortrap(int_mul(VM_Arg1, VM_Arg2, &VM_Result));
        ortrap(interpret_save(ins, VM_Result));
        break;

@* Assembly Statement Parser.

@

@d ARGUMENT_BACKWARD_ADDRESS 0
@d ARGUMENT_ERROR            1
@d ARGUMENT_FAR_ADDRESS      2
@d ARGUMENT_FORWARD_ADDRESS  3
@d ARGUMENT_OBJECT           4
@d ARGUMENT_REGISTER         5
@d ARGUMENT_REGISTER_POPPING 6
@d ARGUMENT_RELATIVE         7
@d ARGUMENT_TABLE            8
@d ARGUMENT_LENGTH           9
@#
@d STATEMENT_LOCAL_LABEL 0
@d STATEMENT_FAR_LABEL   1
@d STATEMENT_INSTRUCTION 2
@d STATEMENT_COVEN       3
@d STATEMENT_COMMENT     6
@d STATEMENT_LENGTH      7
@#
@d pstas_source_byte(P,I) (segment_base((P)->source)[(P)->start + (I)])
@<Fun...@>=
error_code new_statement_imp (cell, cell *);
error_code parse_segment_to_statement (cell, cell, cell, cell *, cell *);
error_code pstas_any_symbol (statement_parser *,
        error_code (*)(statement_parser *, half, half), half);
error_code pstas_argument (statement_parser *, half);
error_code pstas_argument_address (statement_parser *, half);
error_code pstas_argument_address_first (statement_parser *, half);
error_code pstas_argument_encode_error (statement_parser *, half, half);
error_code pstas_argument_encode_register (statement_parser *, bool,
        byte *, half, half);
error_code pstas_argument_encode_symbol (statement_parser *,
        half, half);
error_code pstas_argument_error (statement_parser *, half);
error_code pstas_argument_far_address (statement_parser *, half);
error_code pstas_argument_local_address (statement_parser *, half);
error_code pstas_argument_number (statement_parser *, bool, int, bool, half);
error_code pstas_argument_object (statement_parser *, bool, half);
error_code pstas_argument_register (statement_parser *, half);
error_code pstas_argument_signed_number (statement_parser *, bool, bool, half);
error_code pstas_argument_special (statement_parser *, bool, half);
error_code pstas_far_label (statement_parser *, half);
error_code pstas_instruction (statement_parser *, half);
error_code pstas_instruction_encode (statement_parser *, bool, byte *,
        half, half);
error_code pstas_invalid (statement_parser *, half);
error_code pstas_line_comment (statement_parser *, half);
error_code pstas_local_label (statement_parser *, half);
error_code pstas_maybe_no_argument (statement_parser *, half);
error_code pstas_pre_argument_list (statement_parser *, half);
error_code pstas_pre_instruction (statement_parser *, half);
error_code pstas_pre_next_argument (statement_parser *, half);
error_code pstas_pre_trailing_comment (statement_parser *, half);
error_code pstas_real_comment (statement_parser *, half);
error_code statement_append_comment_m (cell, cell);
error_code statement_argument (cell, cell, cell *);
error_code statement_comment (cell, cell *);
error_code statement_far_label (cell, cell *);
bool statement_has_comment_p (cell);
bool statement_has_far_label_p (cell);
bool statement_has_instruction_p (cell);
bool statement_has_local_label_p (cell);
error_code statement_instruction (cell, cell *);
bool statement_integer_fits_p (cell, int, cell);
error_code statement_local_label (cell, cell *);
error_code statement_set_argument_m (cell, int, int, cell);
error_code statement_set_far_label_m (cell, cell);
error_code statement_set_instruction_m (cell, cell);
error_code statement_set_local_label_m (cell, cell);

@ @d new_statement(R) new_statement_imp(NIL, (R))
@c
error_code
new_statement_imp (cell  op,
                   cell *ret)
{
        error_code reason;
        assert(null_p(op) || opcode_p(op));
        orreturn(new_array_imp(STATEMENT_LENGTH, fix(0), NIL,
                FORM_STATEMENT, ret));
        array_base(*ret)[STATEMENT_INSTRUCTION] = op;
        return LERR_NONE;
}

@ @c
error_code
statement_far_label (cell  o,
                     cell *ret)
{
        assert(statement_p(o));
        *ret = array_base(o)[STATEMENT_FAR_LABEL];
        return LERR_NONE;
}

bool
statement_has_far_label_p (cell o)
{
        assert(statement_p(o));
        return !null_p(array_base(o)[STATEMENT_FAR_LABEL]);
}

error_code
statement_set_far_label_m (cell o,
                           cell label)
{
        assert(statement_p(o));
        assert(symbol_p(label));
        assert(null_p(array_base(o)[STATEMENT_FAR_LABEL]));
        array_base(o)[STATEMENT_FAR_LABEL] = label;
        return LERR_NONE;
}

@ @c
error_code
statement_local_label (cell  o,
                       cell *ret)
{
        assert(statement_p(o));
        *ret = array_base(o)[STATEMENT_LOCAL_LABEL];
        return LERR_NONE;
}

bool
statement_has_local_label_p (cell o)
{
        assert(statement_p(o));
        return !null_p(array_base(o)[STATEMENT_LOCAL_LABEL]);
}

error_code
statement_set_local_label_m (cell o,
                             cell label)
{
        assert(statement_p(o));
        assert(fixed_p(label)
                && fixed_value(label) >= 0 && fixed_value(label) <= 9);
        assert(null_p(array_base(o)[STATEMENT_LOCAL_LABEL]));
        array_base(o)[STATEMENT_LOCAL_LABEL] = label;
        return LERR_NONE;
}

@ @c
error_code
statement_instruction (cell  o,
                       cell *ret)
{
        assert(statement_p(o));
        *ret = array_base(o)[STATEMENT_INSTRUCTION];
        return LERR_NONE;
}

bool
statement_has_instruction_p (cell o)
{
        assert(statement_p(o));
        return !null_p(array_base(o)[STATEMENT_INSTRUCTION]);
}

error_code
statement_set_instruction_m (cell o,
                             cell op)
{
        assert(statement_p(o));
        assert(opcode_p(op));
        assert(null_p(array_base(o)[STATEMENT_INSTRUCTION]));
        array_base(o)[STATEMENT_INSTRUCTION] = op;
        return LERR_NONE;
}

@ @c
error_code
statement_argument (cell  o,
                    cell  id,
                    cell *ret)
{
        assert(statement_p(o));
        assert(fixed_p(id) && fixed_value(id) >= 0 && fixed_value(id) <= 2);
        *ret = array_base(o)[STATEMENT_COVEN + fixed_value(id)];
        return LERR_NONE;
}

error_code
statement_set_argument_m (cell o,
                          int  id,
                          int  cat,
                          cell object)
{
        assert(statement_p(o));
        assert(id >= 0 && id <= 2);
        assert(cat >= 0 && cat < ARGUMENT_LENGTH);
        assert(!special_p(o) || valid_p(object));
        return new_atom(fix(cat), object, FORM_ARGUMENT,
                array_base(o) + STATEMENT_COVEN + id);
}

@ @c
@.TODO@>
bool
statement_integer_fits_p (cell o,
                          int  argid,
                          cell number)
{
        char signature;
        cell op;

        assert(statement_p(o));
        assert(statement_has_instruction_p(o));
        assert(integer_p(number));
        statement_instruction(o, &op);
        signature = opcode_signature_c(op)[argid];
        assert(signature == ALOT || signature == ALOB);
        if (!fixed_p(number))
                return false; /* TODO: Not correct on 16 bit */
        if (signature == ALOT)
                return fixed_value(number) >= -64 && fixed_value(number) <= 63;
        else
                return fixed_value(number) >= -32768 && fixed_value(number) <= 32767;
}

@ @c
bool
statement_has_comment_p (cell o)
{
        assert(statement_p(o));
        return !null_p(array_base(o)[STATEMENT_COMMENT]);
}

error_code
statement_comment (cell  o,
                   cell *ret)
{
        assert(statement_p(o));
        *ret = array_base(o)[STATEMENT_COMMENT];
        return LERR_NONE;
}

error_code
statement_append_comment_m (cell o,
                            cell text)
{
        cell tmp;
        error_code reason;
        assert(statement_p(o));
        assert(pair_p(text)); /* Triplet: (segment offset length) */
        orreturn(cons(text, array_base(o)[STATEMENT_COMMENT], &tmp));
        array_base(o)[STATEMENT_COMMENT] = tmp;
        return LERR_NONE;
}

@ @<Type def...@>=
typedef struct {
        cell  partial;
        cell  source;
        char *signature;
        int   argument;
        half  consume;
        half  start;
        half  length;
        half  end;
} statement_parser;

@ @c
error_code
parse_segment_to_statement (cell  source,
                            cell  start,
                            cell  length,
                            cell *consume,
                            cell *ret)
{
        byte first;
        word value;
        statement_parser pstate = {0};
        error_code reason;

        assert(segment_p(source));
        pstate.source = source;

        orassert(int_value(start, &value));
        assert(value >= 0 && value < segment_length_c(source));
        pstate.start = value;

        orassert(int_value(length, &value));
        assert(value >= 1 && pstate.start + value <= segment_length_c(source));
        pstate.length = value;

        pstate.end = pstate.start + pstate.length;
        orreturn(new_statement(&pstate.partial));
        switch ((first = pstas_source_byte(&pstate, 0))) {
        case '#':
        case ';':
        case '\'':
                reason = pstas_line_comment(&pstate, 0);
                break;

        case ' ':
        case '\t':
        case '\n':
                reason = pstas_pre_instruction(&pstate, 0);
                break;

        default:
                if (ascii_digit_p(first))
                        reason = pstas_local_label(&pstate, 0);
                else if (ascii_printable_p(first))
                        reason = pstas_far_label(&pstate, 0);
                else
                        reason = pstas_invalid(&pstate, 0);
                break;
        }
        if (failure_p(reason))
                return reason;
        orreturn(new_int_c(pstate.consume, consume));
        *ret = pstate.partial;
        return LERR_NONE;
}

@ @c
error_code
pstas_invalid (statement_parser *pstate @[unused@],
               half offset @[unused@])
{
assert(!"invalid\n");
        return LERR_UNIMPLEMENTED;
}

@ @c
error_code
pstas_line_comment (statement_parser *pstate,
                    half offset)
{
        byte leader;
        half i;

        leader = pstas_source_byte(pstate, offset);
        i = offset;
next_leader:
        if (i == pstate->end) {
                pstate->consume = i;
                return LERR_NONE;
        } else if (pstas_source_byte(pstate, i) == leader) {
                i++;
                goto next_leader;
        }

next_space:
        if (i == pstate->end) {
                pstate->consume = i;
                return LERR_NONE;
        }
        switch (pstas_source_byte(pstate, i)) {
        case ' ':
        case '\t':
                i++;
                goto next_space;
        case '\n':
                pstate->consume = i + 1;
                return LERR_NONE;
        default:
                if (ascii_printable_p(pstas_source_byte(pstate, i)))
                        return pstas_real_comment(pstate, i);
                else
                        return pstas_invalid(pstate, i);
        }
}

@ @c
error_code
pstas_local_label (statement_parser *pstate,
                   half offset)
{
        half hoffset;
        byte h;
        cell label;
        error_code reason;

        hoffset = offset + 1;
        if (hoffset == pstate->end)
                return pstas_invalid(pstate, hoffset);
        h = pstas_source_byte(pstate, hoffset);
        if (h != 'h' && h != 'H')
                return pstas_invalid(pstate, hoffset);
        label = fix(pstas_source_byte(pstate, offset) - '0');
        orassert(statement_set_local_label_m(pstate->partial, label));
        return pstas_pre_instruction(pstate, hoffset + 1);
}

@ @c
error_code
pstas_far_label (statement_parser *pstate,
                 half offset)
{
        cell label;
        half i, j;
        error_code reason;

        j = i = offset + 1;
next_label:
        if (i == pstate->end) {
complete_line:
                orreturn(new_symbol_segment(pstate->source,
                        pstate->start + offset, j - offset, &label));
                orassert(statement_set_far_label_m(pstate->partial, label));
                pstate->consume = i;
                return LERR_NONE;
        }
        switch (pstas_source_byte(pstate, i)) {
        case ' ':
        case '\t':
                orreturn(new_symbol_segment(pstate->source,
                        pstate->start + offset, i - offset, &label));
                orassert(statement_set_far_label_m(pstate->partial, label));
                return pstas_pre_instruction(pstate, i);
        case '\n':
                j = i++;
                goto complete_line;
        default:
                if (ascii_printable_p(pstas_source_byte(pstate, i))) {
                        i++;
                        goto next_label;
                } else
                        return pstas_invalid(pstate, i);
        }
}

@ @c
error_code
pstas_pre_instruction (statement_parser *pstate,
                       half offset)
{
        if (offset == pstate->end) {
                offset--;
                goto finish_line;
        }
        if (pstas_source_byte(pstate, offset) == '\n')
                goto finish_line;
        while (pstas_source_byte(pstate, offset) == ' '
            || pstas_source_byte(pstate, offset) == '\t')
                offset++;
        if (pstas_source_byte(pstate, offset) == '\n') {
finish_line:
                pstate->consume = offset + 1;
                return LERR_NONE;
        }
        if (ascii_printable_p(pstas_source_byte(pstate, offset)))
                return pstas_instruction(pstate, offset);
        else
                return pstas_invalid(pstate, offset);
}

@ @c
error_code
pstas_instruction (statement_parser *pstate,
                   half offset)
{
        bool pop_p;
        byte b;
        byte label[24];
        half i, out;

        if (offset == pstate->end)
                return pstas_invalid(pstate, offset);
        pop_p = (pstas_source_byte(pstate, offset) == '=');
        i = offset + pop_p;
        label[0] = 'V';
        label[1] = 'M';
        label[2] = ':';
        out = 3;
next_byte:
        if (out == 24 || i == pstate->end)
                return pstas_instruction_encode(pstate, false, label, out, i);

        switch ((b = pstas_source_byte(pstate, i))) {
        case ' ':
        case '\t':
                return pstas_instruction_encode(pstate, true, label, out, i);
        case '\n':
                return pstas_instruction_encode(pstate, false, label, out, i);
        default:
                if (ascii_printable_p(pstas_source_byte(pstate, i))) {
                        label[out++] = ascii_upcase(b);
                        i++;
                        goto next_byte;
                } else
                        return pstas_invalid(pstate, i);
        }
}

@ @c
error_code
pstas_instruction_encode (statement_parser *pstate,
                          bool  more_p,
                          byte *label,
                          half  length,
                          half  offset)
{
        cell sop, lop;
        error_code reason;

        orreturn(new_symbol_buffer(label, length, NULL, &sop));
        reason = env_search(Environment, sop, &lop);
        if (reason == LERR_MISSING)
                return pstas_invalid(pstate, offset);
        if (failure_p(reason))
                return reason;
        if (!opcode_p(lop))
                return pstas_invalid(pstate, offset);
        orassert(statement_set_instruction_m(pstate->partial, lop));
        if (more_p)
                return pstas_pre_argument_list(pstate, offset);
        else
                return pstas_maybe_no_argument(pstate, offset);
}

@ @c
error_code
pstas_maybe_no_argument (statement_parser *pstate,
                         half offset)
{
        cell op;
        error_code reason;

        orassert(statement_instruction(pstate->partial, &op));
        assert(opcode_p(op));
        if (opcode_object(op)->arg0 == NARG) {
                return pstas_pre_trailing_comment(pstate, offset);
                pstate->consume = offset;
                return LERR_NONE;
        } else
                return pstas_invalid(pstate, offset);
}

@ @c
error_code
pstas_pre_argument_list (statement_parser *pstate,
                         half offset)
{
        cell op;
        half i;
        error_code reason;

        i = offset;
next_byte:
        if (i == pstate->end)
                return pstas_maybe_no_argument(pstate, i);
        switch (pstas_source_byte(pstate, i)) {
        case ' ':
        case '\t':
                i++;
                goto next_byte;
        case '\n':
                return pstas_maybe_no_argument(pstate, i);
        default:
                if (ascii_printable_p(pstas_source_byte(pstate, i))) {
                        orassert(statement_instruction(pstate->partial, &op));
                        pstate->signature = opcode_signature_c(op);
                        if (*pstate->signature == NARG)
                                return pstas_maybe_no_argument(pstate, i);
                        pstate->argument = 0;
                        return pstas_argument(pstate, i);
                } else
                        return pstas_invalid(pstate, i);
        }
}

@ @c
error_code
pstas_argument (statement_parser *pstate,
                half offset)
{
        if (offset == pstate->end)
                return pstas_invalid(pstate, offset);
        assert(*pstate->signature != NARG);
        switch (*pstate->signature) {
        case AADD: return pstas_argument_address(pstate, offset);
        case ALOB: return pstas_argument_object(pstate, true, offset);
        case AREG: return pstas_argument_register(pstate, offset);
        case ALOT: return pstas_argument_object(pstate, false, offset);
        case ARGH: return pstas_argument_error(pstate, offset);
        default: return LERR_INTERNAL;
        }
}

@ @c
error_code
pstas_argument_address (statement_parser *pstate,
                        half offset)
{
        if (offset == pstate->end)
                return pstas_invalid(pstate, offset);
        else if (pstas_source_byte(pstate, offset) == '@@')
                return pstas_argument_address_first(pstate, offset + 1);
        else
                return pstas_argument_register(pstate, offset);
}

@ @c
error_code
pstas_argument_address_first (statement_parser *pstate,
                              half offset)
{
        byte first;

        if (offset == pstate->end)
                return pstas_invalid(pstate, offset);
        first = pstas_source_byte(pstate, offset);
        if (ascii_digit_p(first))
                return pstas_argument_local_address(pstate, offset);
        else if (ascii_printable_p(first) && first != ',')
                return pstas_argument_far_address(pstate, offset);
        else
                return pstas_invalid(pstate, offset);
}

@ @c
error_code
pstas_argument_local_address (statement_parser *pstate,
                              half offset)
{
        int label;
        error_code reason;

        label = pstas_source_byte(pstate, offset) - '0';
        offset++;
        if (offset == pstate->end)
                return pstas_invalid(pstate, offset);
        switch (pstas_source_byte(pstate, offset)) {
        case 'b':
        case 'B':
                orassert(statement_set_argument_m(pstate->partial,
                        pstate->argument, ARGUMENT_BACKWARD_ADDRESS,
                        fix(label)));
                return pstas_pre_next_argument(pstate, offset + 1);
        case 'f':
        case 'F':
                orassert(statement_set_argument_m(pstate->partial,
                        pstate->argument, ARGUMENT_FORWARD_ADDRESS,
                        fix(label)));
                return pstas_pre_next_argument(pstate, offset + 1);
        default:
                return pstas_invalid(pstate, offset);
        }
}

@ @c
error_code
pstas_argument_far_address (statement_parser *pstate,
                            half offset)
{
        cell label;
        half i;
        error_code reason;

        i = offset;
next_byte:
        if (i == pstate->end) {
finish_address:
                orreturn(new_symbol_segment(pstate->source, pstate->start
                        + offset, i - offset, &label));
                orassert(statement_set_argument_m(pstate->partial,
                        pstate->argument, ARGUMENT_FAR_ADDRESS, label));
                return pstas_pre_next_argument(pstate, i);
        }
        switch (pstas_source_byte(pstate, i)) {
        case ',':
        case ' ':
        case '\t':
        case '\n':
                goto finish_address;
        default:
                if (ascii_printable_p(pstas_source_byte(pstate, i))) {
                        i++;
                        goto next_byte;
                } else
                        return pstas_invalid(pstate, i);
        }
}

@ @c
error_code
pstas_pre_next_argument (statement_parser *pstate,
                         half offset)
{
        byte sep;

        pstate->argument++;
        pstate->signature++;
        if (offset == pstate->end)
                sep = '\n';
        else
                sep = pstas_source_byte(pstate, offset);
        if (pstate->argument > 2 || *pstate->signature == NARG) {
                if (sep == ' ' || sep == '\t' || sep == '\n')
                        return pstas_pre_trailing_comment(pstate, offset);
        } else {
                if (sep == ',')
                        return pstas_argument(pstate, offset + 1);
        }
        return pstas_invalid(pstate, offset);
}

@ @c
error_code
pstas_pre_trailing_comment (statement_parser *pstate,
                            half offset)
{
        half i;

        i = offset;
next_byte:
        if (i == pstate->end) {
finish_line:
                pstate->consume = i;
                return LERR_NONE;
        }
        switch (pstas_source_byte(pstate, i)) {
        case ' ':
        case '\t':
                i++;
                goto next_byte;
        case '\n':
                i++;
                goto finish_line;
        default:
                if (ascii_printable_p(pstas_source_byte(pstate, i)))
                        return pstas_real_comment(pstate, offset);
                else
                        return pstas_invalid(pstate, offset);
        }
}

@ @c
error_code
pstas_real_comment (statement_parser *pstate,
                    half offset)
{
        cell tmp;
        half i, j;
        error_code reason;

        i = offset;
next_byte:
        if (i == pstate->end) {
finish_comment:
                j = i;
                while (ascii_space_p(pstas_source_byte(pstate, j - 1)))
                        j--;
                orreturn(cons(fix(j), NIL, &tmp));
                orreturn(cons(fix(j - offset), tmp, &tmp));
                orreturn(cons(pstate->source, tmp, &tmp));
                orreturn(statement_append_comment_m(pstate->partial, tmp));
                pstate->consume = i;
                return LERR_NONE;
        }
        switch (pstas_source_byte(pstate, i)) {
        default:
                if (!ascii_printable_p(pstas_source_byte(pstate, i)))
                        return pstas_invalid(pstate, i);
        case ' ':
        case '\t':
                i++;
                goto next_byte;
        case '\n':
                i++;
                goto finish_comment;
        }
}

@ Incorporates |pstas_argument_parse_register|.
@c
error_code
pstas_argument_register (statement_parser *pstate,
                         half offset)
{
        bool first, pop_p;
        byte b;
        byte label[24];
        half i, out;

        if (offset == pstate->end)
                return pstas_invalid(pstate, offset);
        pop_p = (pstas_source_byte(pstate, offset) == '=');
        i = offset + pop_p;
        label[0] = 'V';
        label[1] = 'M';
        label[2] = ':';
        out = 3;
        first = true;
next_byte:
        if (out == 24 || i == pstate->end)
                return pstas_argument_encode_register(pstate, pop_p, label, out, i);

        switch ((b = pstas_source_byte(pstate, i))) {
        case ',':
        case ' ':
        case '\t':
        case '\n':
                return pstas_argument_encode_register(pstate, pop_p, label, out, i);
        case '-':
        case '_':
                label[out++] = '-';
                first = true;
                i++;
                goto next_byte;
        default:
                if (ascii_printable_p(pstas_source_byte(pstate, i))) {
                        label[out++] = first
                                ? ascii_upcase(pstas_source_byte(pstate, i))
                                : ascii_downcase(pstas_source_byte(pstate, i));
                        first = false;
                        i++;
                        goto next_byte;
                } else
                        return pstas_invalid(pstate, i);
        }
}

@ @c
error_code
pstas_argument_encode_register (statement_parser *pstate,
                                bool  pop_p,
                                byte *label,
                                half  length,
                                half  offset)
{
        cell sreg, rreg;
        error_code reason;

        orreturn(new_symbol_buffer(label, length, NULL, &sreg));
        reason = env_search(Environment, sreg, &rreg);
        if (reason == LERR_MISSING)
                return pstas_invalid(pstate, offset);
        if (failure_p(reason))
                return reason;
        if (!register_p(rreg))
                return pstas_invalid(pstate, offset);
        orassert(statement_set_argument_m(pstate->partial,
                pstate->argument,
                pop_p ? ARGUMENT_REGISTER_POPPING : ARGUMENT_REGISTER, rreg));
        return pstas_pre_next_argument(pstate, offset);
}

@ @c
error_code
pstas_argument_error (statement_parser *pstate,
                      half offset)
{
        if (offset == pstate->end || pstas_source_byte(pstate, offset) != '\'')
                return pstas_invalid(pstate, offset);
        return pstas_any_symbol(pstate, pstas_argument_encode_error, offset + 1);
}

@ @c
error_code
pstas_argument_encode_error (statement_parser *pstate,
                             half length_offset,
                             half offset)
{
        cell lerr, serr;
        error_code reason;

        orreturn(new_symbol_segment(pstate->source, pstate->start + offset,
                length_offset - offset, &serr));
        reason = env_search(Environment, serr, &lerr);
        if (reason == LERR_MISSING)
                return pstas_invalid(pstate, length_offset);
        if (failure_p(reason))
                return reason;
        if (!error_p(lerr))
                return pstas_invalid(pstate, length_offset);
        orassert(statement_set_argument_m(pstate->partial,
                pstate->argument, ARGUMENT_ERROR, lerr));
        return pstas_pre_next_argument(pstate, length_offset);
}

@ @c
error_code
pstas_any_symbol (statement_parser *pstate,
                  error_code (*then)(statement_parser *, half, half),
                  half offset)
{
        half i;

        i = offset;
next_byte:
        if (i == pstate->end)
                return then(pstate, i, offset);
        switch (pstas_source_byte(pstate, i)) {
        case ',':
        case ' ':
        case '\t':
        case '\n':
                return then(pstate, i, offset);
        default:
                if (ascii_printable_p(pstas_source_byte(pstate, i))) {
                        i++;
                        goto next_byte;
                } else
                        return pstas_invalid(pstate, i);
        }
}

@ @c
error_code
pstas_argument_object (statement_parser *pstate,
                       bool full,
                       half offset)
{
        error_code reason;

        switch (pstas_source_byte(pstate, offset)) {
        case '-':
                return pstas_argument_signed_number(pstate, true, full, offset + 1);
        case '+':
                return pstas_argument_signed_number(pstate, false, full, offset + 1);
        case '#':
                return pstas_argument_special(pstate, full, offset + 1);
        case '(':
                if (offset + 1 == pstate->end
                    || pstas_source_byte(pstate, offset + 1) != ')')
                        return pstas_invalid(pstate, offset + 1);
                orassert(statement_set_argument_m(pstate->partial,
                        pstate->argument, ARGUMENT_OBJECT, NIL));
                return pstas_pre_next_argument(pstate, offset + 2);
        case '\'':
                if (full)
                        return pstas_any_symbol(pstate, pstas_argument_encode_symbol, offset + 1);
                else
                        return pstas_invalid(pstate, offset);
        default:
                if (ascii_digit_p(pstas_source_byte(pstate, offset)))
                        return pstas_argument_signed_number(pstate, false, full, offset);
                else
                        return pstas_argument_register(pstate, offset);
        }
}

@ @c
error_code
pstas_argument_encode_symbol (statement_parser *pstate,
                              half length_offset,
                              half offset)
{
        cell sym;
        error_code reason;

        orreturn(new_symbol_segment(pstate->source, pstate->start + offset,
                length_offset - offset, &sym));
        orassert(statement_set_argument_m(pstate->partial,
                pstate->argument, ARGUMENT_OBJECT, sym));
        return pstas_pre_next_argument(pstate, length_offset);
}

@ @c
error_code
pstas_argument_special (statement_parser *pstate,
                         bool full,
                         half offset)
{
        error_code reason;

        if (offset == pstate->end)
                return pstas_invalid(pstate, offset);
        switch (pstas_source_byte(pstate, offset)) {
        case 'b':
        case 'B':
                return pstas_argument_number(pstate, false, 2, full, offset + 1);
        case 'o':
        case 'O':
                return pstas_argument_number(pstate, false, 8, full, offset + 1);
        case 'd':
        case 'D':
                return pstas_argument_number(pstate, false, 10, full, offset + 1);
        case 'x':
        case 'X':
                return pstas_argument_number(pstate, false, 16, full, offset + 1);
        case 'f':
        case 'F':
                orassert(statement_set_argument_m(pstate->partial,
                        pstate->argument, ARGUMENT_OBJECT, LFALSE));
                return pstas_pre_next_argument(pstate, offset + 1);
        case 't':
        case 'T':
                orassert(statement_set_argument_m(pstate->partial,
                        pstate->argument, ARGUMENT_OBJECT, LTRUE));
                return pstas_pre_next_argument(pstate, offset + 1);
        case 'U':
                if (offset + 8 < pstate->end
                    && pstas_source_byte(pstate, offset + 1) == 'N'
                    && pstas_source_byte(pstate, offset + 2) == 'D'
                    && pstas_source_byte(pstate, offset + 3) == 'E'
                    && pstas_source_byte(pstate, offset + 4) == 'F'
                    && pstas_source_byte(pstate, offset + 5) == 'I'
                    && pstas_source_byte(pstate, offset + 5) == 'N'
                    && pstas_source_byte(pstate, offset + 6) == 'E'
                    && pstas_source_byte(pstate, offset + 8) == 'D') {
                        orassert(statement_set_argument_m(pstate->partial,
                                pstate->argument, ARGUMENT_OBJECT, UNDEFINED));
                        return pstas_pre_next_argument(pstate, offset + 9);
                } else
                        return pstas_invalid(pstate, offset);
        case 'V':
                if (offset + 3 < pstate->end
                    && pstas_source_byte(pstate, offset + 1) == 'O'
                    && pstas_source_byte(pstate, offset + 2) == 'I'
                    && pstas_source_byte(pstate, offset + 3) == 'D') {
                        orassert(statement_set_argument_m(pstate->partial,
                                pstate->argument, ARGUMENT_OBJECT, VOID));
                        return pstas_pre_next_argument(pstate, offset + 4);
                } else
                        return pstas_invalid(pstate, offset);
        default:
                return pstas_invalid(pstate, offset);
        }
}

@ @c
error_code
pstas_argument_signed_number (statement_parser *pstate,
                              bool negate,
                              bool full,
                              half offset)
{
        if (offset == pstate->end)
                return pstas_invalid(pstate, offset);
        if (pstas_source_byte(pstate, offset) == '#') {
                offset++;
                if (offset == pstate->end)
                                return pstas_invalid(pstate, offset);
                switch (pstas_source_byte(pstate, offset)) {
                case 'b':
                case 'B':
                        return pstas_argument_number(pstate, negate, 2, full, offset);
                case 'o':
                case 'O':
                        return pstas_argument_number(pstate, negate, 8, full, offset);
                case 'd':
                case 'D':
                        return pstas_argument_number(pstate, negate, 10, full, offset);
                case 'x':
                case 'X':
                        return pstas_argument_number(pstate, negate, 16, full, offset);
                default:
                        return pstas_invalid(pstate, offset);
                }
        } else if (ascii_digit_p(pstas_source_byte(pstate, offset)))
                return pstas_argument_number(pstate, negate, 10, full, offset);
        else
                return pstas_invalid(pstate, offset);
}

@ @c
error_code
pstas_argument_number (statement_parser *pstate,
                       bool negate,
                       int  base,
                       bool full,
                       half offset)
{
        byte b;
        cell lsum;
        int add, sum, max, min, shift, width;
        half i, j;
        error_code reason;

        sum = 0;
        if (full) {
                min = -32768;
                max = 32767;
        } else {
                min = -64;
                max = 63;
        }

        i = offset;
        switch (base) {
        case  2: width = 16; shift = 1; break;
        case  8: width = 6; shift = 3; break;
        case 10: width = 5; goto next_base10;
        case 16: width = shift = 4; break;
        }
next_digit:
        if (i == pstate->end)
                goto finish_number;
        b = pstas_source_byte(pstate, i);
        if (ascii_space_p(b) || b == ',')
                goto finish_number;
        else if (ascii_digit_p(b) || ascii_hex_p(b)) {
                if (i - offset == width)
                        return pstas_invalid(pstate, offset);
                if (b <= '9')
                        add = b - '0';
                else
                        add = 10 + (b & 0xdf) - 'A';
                if (add >= base)
                        return pstas_invalid(pstate, offset);
                sum = (sum << shift) | add;
                i++;
                goto next_digit;
        } else
                return pstas_invalid(pstate, offset);

next_base10:
        if (i == pstate->end)
                goto finish_base10;
        b = pstas_source_byte(pstate, i);
        if (ascii_space_p(b) || b == ',')
                goto finish_base10;
        else if (ascii_digit_p(b)) {
                if (i - offset == width)
                        return pstas_invalid(pstate, offset);
                i++;
                goto next_base10;
        } else
                return pstas_invalid(pstate, offset);

finish_base10:
        for (j = offset; j < i; j++) {
                sum *= 10;
                sum += pstas_source_byte(pstate, j) - '0';
        }

finish_number:
        if (negate)
                sum = -sum;
        if (sum < min || sum > max)
                return pstas_invalid(pstate, i);
        orreturn(new_int_c(sum, &lsum));
        orassert(statement_set_argument_m(pstate->partial,
                pstate->argument, ARGUMENT_OBJECT, lsum));
        return pstas_pre_next_argument(pstate, i);
}

@* Assembler.

@d ASSEMBLY_STATUS 0
@d ASSEMBLY_STATUS_IN_PROGRESS 0
@d ASSEMBLY_STATUS_READY       1
@d ASSEMBLY_STATUS_INSTALLED   2

@d ASSEMBLY_BODY 1
@d ASSEMBLY_LENGTH 2

@d ASSEMBLY_PROGRESS_BODY              1
@d ASSEMBLY_PROGRESS_NEXT_ADDRESS      2
@d ASSEMBLY_PROGRESS_FAR_ADDRESS       3
@d ASSEMBLY_PROGRESS_FAR_ARGUMENT      4
@d ASSEMBLY_PROGRESS_PENDING_LABEL     5
@d ASSEMBLY_PROGRESS_BACKWARD_ADDRESS  6
@d ASSEMBLY_PROGRESS_FORWARD_ARGUMENT  7
@d ASSEMBLY_PROGRESS_OBJECTDB          8
@d ASSEMBLY_PROGRESS_COMMENT_STATEMENT 9
@d ASSEMBLY_PROGRESS_PENDING_COMMENT   10
@d ASSEMBLY_PROGRESS_COMMENTARY        11
@d ASSEMBLY_PROGRESS_BLOB              12
@d ASSEMBLY_PROGRESS_LENGTH            13

@d ASSEMBLY_READY_BODY       1
@d ASSEMBLY_READY_EXPORT     2
@d ASSEMBLY_READY_REQUIRE    3
@d ASSEMBLY_READY_OBJECTDB   5
@d ASSEMBLY_READY_COMMENTARY 6
@d ASSEMBLY_READY_BLOB       7
@d ASSEMBLY_READY_LENGTH     8

@<Fun...@>=
error_code new_assembly_progress (cell *);
error_code new_assembly_buffer(byte *, word, cell *);
error_code new_assembly_segment (cell, cell *);
@#
error_code assembly_append_comment_separator_m (cell);
error_code assembly_append_far_argument_m (cell, cell, cell, int);
error_code assembly_append_forward_argument_m (cell, cell, cell, int);
error_code assembly_append_pending_comment_m (cell, cell);
error_code assembly_clear_forward_argument_list_m (cell, cell);
error_code assembly_comment_statement (cell, cell *);
error_code assembly_commentary (cell, cell, cell *);
error_code assembly_far_address (cell, cell, cell *);
error_code assembly_far_argument_list (cell, cell, cell *);
error_code assembly_forward_argument (cell, cell, cell *);
bool assembly_has_far_address_p (cell, cell);
bool assembly_has_pending_label_p (cell);
error_code assembly_install_object_m (cell, cell, half *);
error_code assembly_next_address (cell, cell *);
error_code assembly_object_table (cell o, cell *);
error_code assembly_pending_comment (cell, cell *);
error_code assembly_pending_label (cell, cell *);
error_code assembly_set_backward_address_m (cell, cell, cell);
error_code assembly_set_comment_statement_m (cell, cell);
error_code assembly_set_commentary_m (cell, cell, cell);
error_code assembly_set_far_address_m (cell, cell, cell);
error_code assembly_set_next_address_m (cell, cell);
error_code assembly_set_pending_comment_m (cell, cell);
error_code assembly_set_pending_label_m (cell, cell);
error_code assembly_set_statement_m (cell, word, cell);
@#
error_code assembly_append_line_m (cell, cell);
error_code assembly_append_statement_m (cell, cell, cell *);
error_code assembly_encode_ALOT (int, cell, instruction *);
error_code assembly_encode_AREG (int, cell, instruction *);
error_code assembly_finish_m (cell, cell *);
error_code assembly_fix_forward_links_m (cell, cell, cell);
error_code assembly_install_m (cell, cell *);
error_code assembly_validate_integer (int, bool, cell, word *);

@
@d assembly_in_progress_p(O) (assembly_p(O)
        && array_base(O)[ASSEMBLY_STATUS] == fix(ASSEMBLY_STATUS_IN_PROGRESS))
@d assembly_ready_p(O) (assembly_p(O)
        && array_base(O)[ASSEMBLY_STATUS] == fix(ASSEMBLY_STATUS_READY))
@d assembly_installed_p(O) (assembly_p(O)
        && array_base(O)[ASSEMBLY_STATUS] == fix(ASSEMBLY_STATUS_INSTALLED))
@c
error_code
new_assembly_progress (cell *ret)
{
        cell body, blob, far_address, far_argument;
        cell backward, forward, commentary, objectdb;
        error_code reason;

        orreturn(new_array(100, fix(0), &body));
        orreturn(new_hashtable(0, &far_address));
        orreturn(new_hashtable(0, &far_argument));
        orreturn(new_array(10, fix(0), &backward));
        orreturn(new_array(10, fix(0), &forward));
        orreturn(new_array(0, fix(0), &objectdb));
        orreturn(new_hashtable(0, &commentary));
        orreturn(new_segment(0, 0, &blob));
        orreturn(new_array_imp(ASSEMBLY_PROGRESS_LENGTH, fix(0), NIL,
                FORM_ASSEMBLY, ret));
        array_base(*ret)[ASSEMBLY_STATUS] = fix(ASSEMBLY_STATUS_IN_PROGRESS);
        array_base(*ret)[ASSEMBLY_PROGRESS_BODY] = body;
        array_base(*ret)[ASSEMBLY_PROGRESS_NEXT_ADDRESS] = fix(0);
        array_base(*ret)[ASSEMBLY_PROGRESS_FAR_ADDRESS] = far_address;
        array_base(*ret)[ASSEMBLY_PROGRESS_FAR_ARGUMENT] = far_argument;
        array_base(*ret)[ASSEMBLY_PROGRESS_BACKWARD_ADDRESS] = backward;
        array_base(*ret)[ASSEMBLY_PROGRESS_FORWARD_ARGUMENT] = forward;
        array_base(*ret)[ASSEMBLY_PROGRESS_OBJECTDB] = objectdb;
        array_base(*ret)[ASSEMBLY_PROGRESS_COMMENTARY] = commentary;
        array_base(*ret)[ASSEMBLY_PROGRESS_BLOB] = blob;
        return LERR_NONE;
}

@ @c
error_code
assembly_statement (cell  o,
                    word  lineno,
                    cell *ret)
{
        cell body;
        assert(assembly_p(o));
        assert(ASSEMBLY_BODY == ASSEMBLY_PROGRESS_BODY);
        body = array_base(o)[ASSEMBLY_BODY];
        assert(lineno >= 0 && lineno < array_length_c(body));
        *ret = array_base(body)[lineno];
        assert(statement_p(*ret));
        return LERR_NONE;
}

error_code
assembly_set_statement_m (cell o,
                          word lineno,
                          cell statement)
{
        cell body;
        word grow;
        error_code reason;

        assert(assembly_in_progress_p(o));
        assert(lineno >= 0);
        assert(statement_p(statement));
        body = array_base(o)[ASSEMBLY_PROGRESS_BODY];
        grow = array_length_c(body);
        while (grow <= lineno)
                if ((grow += 100) > CODE_PAGE_LENGTH)
                        return LERR_OUT_OF_BOUNDS;
        if (grow > array_length_c(body))
                orreturn(array_resize_m(body, grow, NIL));
        array_base(body)[lineno] = statement;
        return LERR_NONE;
}

@ @c
error_code
assembly_next_address (cell  o,
                       cell *ret)
{
        assert(assembly_in_progress_p(o));
        *ret = array_base(o)[ASSEMBLY_PROGRESS_NEXT_ADDRESS];
        assert(integer_p(*ret));
        return LERR_NONE;
}

error_code
assembly_set_next_address_m (cell o,
                             cell addr)
{
        assert(assembly_in_progress_p(o));
        assert(integer_p(addr)); /* |&& >= 0| but maybe not |< length|. */
        array_base(o)[ASSEMBLY_PROGRESS_NEXT_ADDRESS] = addr;
        return LERR_NONE;
}

@ @c
bool
assembly_has_far_address_p (cell o,
                            cell label)
{
        cell found;
        error_code reason;
        assert(assembly_in_progress_p(o));
        assert(symbol_p(label));
        orreturn(hashtable_search(array_base(o)[ASSEMBLY_PROGRESS_FAR_ADDRESS],
                label, &found));
        return defined_p(found);
}

@ @c
error_code
assembly_far_address (cell  o,
                      cell  label,
                      cell *ret)
{
        error_code reason;
        assert(assembly_in_progress_p(o));
        assert(symbol_p(label));
        orreturn(hashtable_search(array_base(o)[ASSEMBLY_PROGRESS_FAR_ADDRESS],
                label, ret));
        assert(pair_p(*ret));
        assert(integer_p(A(*ret)->dex));
        return LERR_NONE;
}

error_code
assembly_set_far_address_m (cell o,
                            cell label,
                            cell lineno)
{
        cell tuple;
        error_code reason;
        assert(assembly_in_progress_p(o));
        assert(symbol_p(label));
        assert(integer_p(lineno));
        orreturn(cons(label, lineno, &tuple));
        orreturn(hashtable_save_m(array_base(o)[ASSEMBLY_PROGRESS_FAR_ADDRESS],
                tuple, false));
        return LERR_NONE;
}

@ Hashtable of label : list of (line . argid) tuples.

@c
error_code
assembly_far_argument_list (cell  o,
                            cell  label,
                            cell *ret)
{
        cell found;
        error_code reason;

        assert(assembly_in_progress_p(o));
        assert(symbol_p(label));
        orreturn(hashtable_search(array_base(o)[ASSEMBLY_PROGRESS_FAR_ARGUMENT],
                label, &found));
        if (pair_p(found))
                *ret = A(found)->dex;
        else
                *ret = NIL;
        for (found = *ret; !null_p(found); found = A(found)->dex) {
                assert(pair_p(found));
                assert(pair_p(A(found)->sin));
                assert(integer_p(A(A(found)->sin)->sin));
                assert(integer_p(A(A(found)->sin)->dex));
        }
        return LERR_NONE;
}

error_code
assembly_append_far_argument_m (cell o,
                                cell label,
                                cell lineno,
                                int  argid)
{
        bool replace;
        cell found, tuple;
        error_code reason;

        assert(assembly_in_progress_p(o));
        assert(symbol_p(label));
        assert(integer_p(lineno));
        assert(argid <= 1);
        orreturn(cons(lineno, fix(argid), &tuple));
        orreturn(hashtable_search(array_base(o)[ASSEMBLY_PROGRESS_FAR_ARGUMENT],
                label, &found));
        replace = defined_p(found);
        if (replace) {
                assert(pair_p(found) && A(found)->sin == label);
                orreturn(cons(tuple, A(found)->dex, &tuple));
        } else
                orreturn(cons(tuple, NIL, &tuple));
        orreturn(cons(label, tuple, &tuple));
        return hashtable_save_m(array_base(o)[ASSEMBLY_PROGRESS_FAR_ARGUMENT],
                tuple, replace);
}

@ @c
bool
assembly_has_pending_label_p (cell o)
{
        assert(assembly_in_progress_p(o));
        return !null_p(array_base(o)[ASSEMBLY_PROGRESS_PENDING_LABEL]);
}

error_code
assembly_pending_label (cell  o,
                        cell *ret)
{
        assert(assembly_in_progress_p(o));
        *ret = array_base(o)[ASSEMBLY_PROGRESS_PENDING_LABEL];
        return LERR_NONE;
}

error_code
assembly_set_pending_label_m (cell o,
                              cell label)
{
        assert(assembly_in_progress_p(o));
        if (!null_p(label)) {
                assert((fixed_p(label)
                        && fixed_value(label) >= 0 && fixed_value(label) <= 9));
                assert(null_p(array_base(o)[ASSEMBLY_PROGRESS_PENDING_LABEL]));
        }
        array_base(o)[ASSEMBLY_PROGRESS_PENDING_LABEL] = label;
        return LERR_NONE;
}

@ Backward address. Array of 10 integers or NIL. TODO: flatten back/fore arrays.

@.TODO@>
@c
error_code
assembly_backward_address (cell  o,
                           cell  link,
                           cell *ret)
{
        assert(assembly_in_progress_p(o));
        assert(fixed_p(link)
                && fixed_value(link) >= 0 && fixed_value(link) <= 9);
        o = array_base(o)[ASSEMBLY_PROGRESS_BACKWARD_ADDRESS];
        *ret = array_base(o)[fixed_value(link)];
        return LERR_NONE;
}

error_code
assembly_set_backward_address_m (cell o,
                                 cell link,
                                 cell lineno)
{
        assert(assembly_in_progress_p(o));
        assert(fixed_p(link)
                && fixed_value(link) >= 0 && fixed_value(link) <= 9);
        assert(integer_p(lineno));
        o = array_base(o)[ASSEMBLY_PROGRESS_BACKWARD_ADDRESS];
        array_base(o)[fixed_value(link)] = lineno;
        return LERR_NONE;
}

@ Forward argument. Array of 10 lists of (lineno . argid) tuples.

@.TODO@>
@c
error_code
assembly_forward_argument (cell  o,
                           cell  link,
                           cell *ret)
{
        assert(assembly_in_progress_p(o));
        assert(fixed_p(link)
                && fixed_value(link) >= 0 && fixed_value(link) <= 9);
        o = array_base(o)[ASSEMBLY_PROGRESS_FORWARD_ARGUMENT];
        *ret = array_base(o)[fixed_value(link)];
        return LERR_NONE;
}

error_code
assembly_append_forward_argument_m (cell o,
                                    cell link,
                                    cell lineno,
                                    int  argid)
{
        cell linklist, tuple;
        error_code reason;

        assert(assembly_in_progress_p(o));
        assert(fixed_p(link)
                && fixed_value(link) >= 0 && fixed_value(link) <= 9);
        assert(integer_p(lineno));
        assert(argid >= 0 && argid <= 2);
        orreturn(cons(lineno, fix(argid), &tuple));
        linklist = array_base(o)[ASSEMBLY_PROGRESS_FORWARD_ARGUMENT];
        return cons(tuple, array_base(linklist)[fixed_value(link)],
                &array_base(linklist)[fixed_value(link)]);
}

error_code
assembly_clear_forward_argument_list_m (cell o,
                                        cell link)
{
        assert(assembly_in_progress_p(o));
        assert(fixed_p(link)
                && fixed_value(link) >= 0 && fixed_value(link) <= 9);
        o = array_base(o)[ASSEMBLY_PROGRESS_FORWARD_ARGUMENT];
        array_base(o)[fixed_value(link)] = NIL;
        return LERR_NONE;
}

@ @c
error_code
assembly_object_table (cell  o,
                       cell *ret)
{
        assert(assembly_in_progress_p(o));
        *ret = array_base(o)[ASSEMBLY_PROGRESS_OBJECTDB];
        return LERR_NONE;
}

@ @c
error_code
assembly_install_object_m (cell  o,
                           cell  object,
                           half *ret)
{
        cell objectdb;
        half i, length;

        assert(assembly_in_progress_p(o));
        assert(!special_p(o));
        objectdb = array_base(o)[ASSEMBLY_PROGRESS_OBJECTDB];
        length = array_length_c(objectdb);
        for (i = 0; i < length; i++) {
                if (cmpis_p(object, array_base(objectdb)[i])) {
                        *ret = i;
                        return LERR_NONE;
                }
        }
        array_resize_m(objectdb, length + 1, UNDEFINED);
        array_base(objectdb)[length] = object;
        *ret = length;
        return LERR_NONE;
}

@ @c
error_code
assembly_comment_statement (cell  o,
                            cell *ret)
{
        assert(assembly_in_progress_p(o));
        *ret = array_base(o)[ASSEMBLY_PROGRESS_COMMENT_STATEMENT];
        return LERR_NONE;
}

error_code
assembly_set_comment_statement_m (cell o,
                                  cell s)
{
        assert(assembly_in_progress_p(o));
        assert(null_p(s) || statement_p(s));
        array_base(o)[ASSEMBLY_PROGRESS_COMMENT_STATEMENT] = s;
        return LERR_NONE;
}

@ @c
error_code
assembly_pending_comment (cell  o,
                          cell *ret)
{
        assert(assembly_in_progress_p(o));
        *ret = array_base(o)[ASSEMBLY_PROGRESS_PENDING_COMMENT];
        return LERR_NONE;
}

error_code
assembly_set_pending_comment_m (cell o,
                                cell commentary)
{
        assert(assembly_in_progress_p(o));
        assert(null_p(commentary) || pair_p(commentary));
        array_base(o)[ASSEMBLY_PROGRESS_PENDING_COMMENT] = commentary;
        return LERR_NONE;
}

error_code
assembly_append_pending_comment_m (cell o,
                                   cell line)
{
        cell tuple;
        error_code reason;
        assert(assembly_in_progress_p(o));
        assert(defined_p(line));
        orreturn(cons(line, array_base(o)[ASSEMBLY_PROGRESS_PENDING_COMMENT],
                &tuple));
        array_base(o)[ASSEMBLY_PROGRESS_PENDING_COMMENT] = tuple;
        return LERR_NONE;
}

error_code
assembly_append_comment_separator_m (cell o)
{
        cell tuple;
        error_code reason;
        assert(assembly_in_progress_p(o));
        orreturn(cons(NIL, array_base(o)[ASSEMBLY_PROGRESS_PENDING_COMMENT],
                &tuple));
        array_base(o)[ASSEMBLY_PROGRESS_PENDING_COMMENT] = tuple;
        return LERR_NONE;
}

@ @c
error_code
assembly_commentary (cell  o,
                     cell  lineno,
                     cell *ret)
{
        cell table;
        error_code reason;
        assert(assembly_in_progress_p(o));
        if (integer_p(lineno))
                orreturn(int_to_symbol(lineno, &lineno));
        else
                assert(symbol_p(lineno));
        table = array_base(o)[ASSEMBLY_PROGRESS_COMMENTARY];
        orreturn(hashtable_search(table, lineno, ret));
        if (undefined_p(*ret))
                *ret = NIL;
        return LERR_NONE;
}

error_code
assembly_set_commentary_m (cell o,
                           cell lineno,
                           cell comment)
{
        cell table;
        error_code reason;
        assert(assembly_in_progress_p(o));
        if (integer_p(lineno))
                orreturn(int_to_symbol(lineno, &lineno));
        else
                assert(symbol_p(lineno));
        table = array_base(o)[ASSEMBLY_PROGRESS_COMMENTARY];
        orreturn(cons(lineno, comment, &comment));
        return hashtable_save_m(table, comment, false);
}

@ TODO: Blob accessors.

@.TODO@>

@ @c
error_code
assembly_append_line_m (cell o,
                        cell line)
{
        cell comment, label, lineno, previous;
        error_code reason;

        assert(assembly_in_progress_p(o));
        assert(statement_p(line));
        assembly_next_address(o, &lineno);
        statement_far_label(line, &label);
        if (!null_p(label)) {
                if (assembly_has_far_address_p(o, label))
                        return LERR_UNIMPLEMENTED; /* in use */
                assembly_set_comment_statement_m(o, NIL);
                assembly_set_far_address_m(o, label, lineno);
        }
        statement_local_label(line, &label);
        if (!null_p(label)) {
                assert(fixed_p(label)
                        && fixed_value(label) >= 0 && fixed_value(label) <= 9);
                assembly_set_comment_statement_m(o, NIL);
                assembly_set_pending_label_m(o, label);
        }
        if (statement_has_instruction_p(line)) {
                assembly_pending_comment(o, &comment);
                if (!null_p(comment)) {
                        assert(pair_p(comment));
                        if (null_p(A(comment)->sin))
                                comment = A(comment)->dex;
                        orreturn(assembly_set_commentary_m(o, lineno, comment));
                        assembly_set_pending_comment_m(o, NIL);
                }
                orreturn(assembly_append_statement_m(o, line, &line));
                assembly_set_comment_statement_m(o, line);
        } else if (statement_has_comment_p(line)) {
                statement_comment(line, &comment);
                assert(pair_p(comment));
                if (!null_p(A(comment)->sin))
                        comment = A(comment)->sin;
                assembly_comment_statement(o, &previous);
                if (null_p(previous))
                        orreturn(assembly_append_pending_comment_m(o, comment));
                else
                        orreturn(statement_append_comment_m(previous,
                                comment));
        } else {
                statement_comment(line, &comment);
                if (!null_p(comment) && !null_p(A(comment)->sin))
                        orreturn(assembly_append_comment_separator_m(o));
        }
        return LERR_NONE;
}

@ In practice line numbers all fit within the space of a fixed
integer except on 16 bit machines where a 24 bit address space
doesn't make much sense anyway. 16 bit support is not being considered
especially at this time.

@c
error_code
assembly_append_statement_m (cell  o,
                             cell  statement,
                             cell *ret)
{
        cell argument, delta, label, lineat, lineno, link, op;
        int i;
        word cdelta, clineno;
        half tablerow;
        error_code reason;

        assert(assembly_in_progress_p(o));
        assert(statement_p(statement));
        assembly_next_address(o, &lineno);

        if (assembly_has_pending_label_p(o)) {
                assembly_pending_label(o, &label);
                assert(fixed_p(label));
                orreturn(assembly_fix_forward_links_m(o, label, lineno));
        } else
                label = NIL;

        for (i = 0; i <= 2; i++) { /* Argument 2 can never have an address. */
                statement_argument(statement, fix(i), &argument);
                if (null_p(argument))
                        continue;
                assert(argument_p(argument));
                switch (fixed_value(A(argument)->sin)) {
                case ARGUMENT_FAR_ADDRESS:
                        orreturn(assembly_append_far_argument_m(o,
                                A(argument)->dex, lineno, i));
                        break;
                case ARGUMENT_FORWARD_ADDRESS:
                        orreturn(assembly_append_forward_argument_m(o,
                                A(argument)->dex, lineno, i));
                        break;
                case ARGUMENT_BACKWARD_ADDRESS:
                        link = A(argument)->dex;
                        assembly_backward_address(o, link, &lineat);
                        if (null_p(lineat))
                                return LERR_UNIMPLEMENTED;
                        assert(fixed_p(lineat) && fixed_p(lineno));
                        cdelta = fixed_value(lineat) - fixed_value(lineno);
                        orreturn(new_int_c(cdelta, &delta));
                        orreturn(statement_set_argument_m(statement,
                                i, ARGUMENT_RELATIVE, delta));
                        break;
                case ARGUMENT_REGISTER:
                case ARGUMENT_REGISTER_POPPING:
                        assert(register_p(A(argument)->dex));
                        break;
                case ARGUMENT_OBJECT:
                        orassert(statement_instruction(statement, &op));
                        if ((integer_p(A(argument)->dex)
                                    && statement_integer_fits_p(statement,
                                        i, A(argument)->dex))
                                  || (special_p(A(argument)->dex) && !fixed_p(A(argument)->dex)))
                                break;
                        else if (opcode_signature_c(op)[i] != ALOB)
                                return LERR_INCOMPATIBLE;
                        orreturn(assembly_install_object_m(o,
                                A(argument)->dex, &tablerow));
                        orreturn(new_int_c(tablerow, &link));
                        orreturn(statement_set_argument_m(statement,
                                i, ARGUMENT_TABLE, link));
                        break;
                }
        }

        assert(fixed_p(lineno));
        clineno = fixed_value(lineno);
        assert(clineno >= 0 && clineno < CODE_PAGE_MAX);
        assembly_set_statement_m(o, clineno, statement);
        if (!null_p(label)) {
                assembly_set_backward_address_m(o, label, lineno);
                assembly_set_pending_label_m(o, NIL);
        }
        orreturn(new_int_c(clineno + 1, &lineno));
        assembly_set_next_address_m(o, lineno);
        *ret = statement;
        return LERR_NONE;
}

@ @c
error_code
assembly_fix_forward_links_m (cell o,
                              cell link,
                              cell lineto)
{
        cell argid, delta, linefrom, statement, tuple, pending;
        word cdelta;
        error_code reason;

        assert(assembly_in_progress_p(o));
        assert(fixed_p(link));
        assert(integer_p(lineto));

        assembly_forward_argument(o, link, &pending);
        for (; !null_p(pending); pending = A(pending)->dex) {
                assert(pair_p(pending) && pair_p(A(pending)->sin));
                tuple = A(pending)->sin;
                linefrom = A(tuple)->sin;
                argid = A(tuple)->dex;
                assert(fixed_p(argid));
@#
                assert(fixed_p(linefrom) && fixed_p(lineto));
                cdelta = fixed_value(lineto) - fixed_value(linefrom);
                orreturn(new_int_c(cdelta, &delta));
@#
                assembly_statement(o, fixed_value(linefrom), &statement);
                assert(statement_p(statement));
                orreturn(statement_set_argument_m(statement,
                        fixed_value(argid), ARGUMENT_RELATIVE, delta));

        }
        return assembly_clear_forward_argument_list_m(o, link);
}

@ Check:

pending-label is |NIL|

forward-argument-table links are all |NIL|.

Change:

Add any pending comment to the table at epilogue.

Filter far addresses into exported and dependencies.

For all far-address
    If begins !, add to export
    Otherwise if there is no list of statements add it to requires
    Update matching statements to relative and remove from far-argument

If there are statements left in far-argument they are requirements.

@ @c
error_code
assembly_finish_m (cell  o,
                   cell *ret)
{
        cell far_address, far_argument, fromlist, exportdb, require;
        cell argid, body, comment, lineto, linefrom, next, statement, sym;
        cell table, tuple;
        word delta, i;
        error_code reason;

        assert(assembly_in_progress_p(o));
        if (assembly_has_pending_label_p(o))
                return LERR_UNIMPLEMENTED;
        table = array_base(o)[ASSEMBLY_PROGRESS_FORWARD_ARGUMENT];
        for (i = 0; i <= 9; i++)
                if (!null_p(array_base(table)[i]))
                        return LERR_UNIMPLEMENTED;
        @<Collect pending comments and reduce the code array@>@;
        @<Update in-page far links to relative@>@;
        @<Record remaining required far links@>@;
        orreturn(new_array_imp(ASSEMBLY_READY_LENGTH, fix(0), NIL,
                FORM_ASSEMBLY, ret));
        array_base(*ret)[ASSEMBLY_STATUS] = fix(ASSEMBLY_STATUS_READY);
        array_base(*ret)[ASSEMBLY_READY_BODY] = body;
        array_base(*ret)[ASSEMBLY_READY_EXPORT] = exportdb;
        array_base(*ret)[ASSEMBLY_READY_REQUIRE] = require;
        array_base(*ret)[ASSEMBLY_READY_OBJECTDB] = array_base(o)[ASSEMBLY_PROGRESS_OBJECTDB];
        array_base(*ret)[ASSEMBLY_READY_COMMENTARY] = array_base(o)[ASSEMBLY_PROGRESS_COMMENTARY];
        array_base(*ret)[ASSEMBLY_READY_BLOB] = array_base(o)[ASSEMBLY_PROGRESS_BLOB];
        return LERR_NONE;
}

@ @<Collect pending comments and reduce the code array@>=
orreturn(assembly_pending_comment(o, &comment));
if (!null_p(comment)) {
        orreturn(new_symbol_const("epilogue", &sym));
        assembly_set_commentary_m(o, sym, comment);
}
lineto = array_base(o)[ASSEMBLY_PROGRESS_NEXT_ADDRESS];
assert(fixed_p(lineto));
body = array_base(o)[ASSEMBLY_PROGRESS_BODY];
orreturn(array_resize_m(body, fixed_value(lineto), NIL));

@ @<Update in-page far links to relative@>=
far_address = array_base(o)[ASSEMBLY_PROGRESS_FAR_ADDRESS];
far_argument = array_base(o)[ASSEMBLY_PROGRESS_FAR_ARGUMENT];
orreturn(new_hashtable(0, &exportdb));
for (i = 0; i < hashtable_length_c(far_address); i++) {
        next = hashtable_base(far_address)[i];
        if (null_p(next) || !defined_p(next))
                continue;
        lineto = A(next)->dex;
        assert(fixed_p(lineto));
        if (symbol_buffer_c(A(next)->sin)[0] == '!') {
                orreturn(cons(A(next)->sin, lineto, &tuple));
                orreturn(hashtable_save_m(exportdb, tuple, false));
        }
        orreturn(hashtable_search(far_argument, A(next)->sin, &fromlist));
        if (undefined_p(fromlist))
                continue;
        assert(pair_p(fromlist) && A(fromlist)->sin == A(next)->sin);
        fromlist = A(fromlist)->dex;
        for (; !null_p(fromlist); fromlist = A(fromlist)->dex) {
                assert(pair_p(A(fromlist)->sin));
                tuple = A(fromlist)->sin;
                linefrom = A(tuple)->sin;
                assert(fixed_p(linefrom));
                argid = A(tuple)->dex;
                assert(fixed_p(argid));
                delta = fixed_value(lineto) - fixed_value(linefrom);
                assembly_statement(o, fixed_value(linefrom), &statement);
                statement_set_argument_m(statement,
                        fixed_value(argid), ARGUMENT_RELATIVE, fix(delta));
        }
        hashtable_erase_m(far_argument, A(next)->sin, false);
}

@ @<Record remaining required far links@>=
orreturn(new_hashtable(0, &require));
for (i = 0; i < hashtable_length_c(far_argument); i++) {
        next = hashtable_base(far_argument)[i];
        if (null_p(next) || !defined_p(next))
                continue;
        orreturn(cons(A(next)->sin, A(next)->dex, &tuple));
        orreturn(hashtable_save_m(require, tuple, false));
}

@ @c
error_code
assembly_install_m (cell  o,
                    cell *ret)
{
        address avalue, boffset, page, real;
        cell arg, blob, body, found, label, link, lins, objectdb, op, tmp;
        cell new_table, new_program, statement_halt;
        half i, ioffset, new_objectdb_length, next_export;
        instruction ins, ivalue;
        word ito, wvalue;
        opcode_table *opb;
        error_code reason;

        assert(assembly_ready_p(o));

        @<Prepare a new code page@>@;
        pthread_mutex_lock(&Program_Lock);
        @<Copy constant objects into |Program_ObjectDB|@>@;
        @<Look for required address symbols@>@;
        @<Add exported address symbols to a copy of |Program_Export_Table|@>@;
        @<Install instructions as bytecode and commentary@>@;

        Program_Export_Table = new_table;
        Program_Export_Free = next_export;
        Program_ObjectDB_Free = new_objectdb_length;
        *ret = new_program;
        pthread_mutex_unlock(&Program_Lock);
        return LERR_NONE;

Trap:
        while (new_objectdb_length > Program_ObjectDB_Free)
                array_base(Program_ObjectDB)[--new_objectdb_length] = NIL;
        pthread_mutex_unlock(&Program_Lock);
        free_mem((void *) page);
        return reason;
}

@ @<Prepare a new code page@>=
orreturn(alloc_mem(NULL, CODE_PAGE_LENGTH, CODE_PAGE_LENGTH, (void **) &page));
reason = new_array_imp(ASSEMBLY_PROGRESS_LENGTH, fix(0), NIL,
        FORM_ASSEMBLY, &new_program);
if (failure_p(reason)) {
        free_mem((void *) page);
        return reason;
}
array_base(new_program)[ASSEMBLY_STATUS] = fix(ASSEMBLY_STATUS_INSTALLED);
*((cell *) page) = new_program; /* Point to the program atom at offset 0. */
blob = array_base(o)[ASSEMBLY_READY_BLOB]; /* Copy binary data to the
                                                beginning of the page. */
memmove((void *) (page + sizeof (cell)), segment_base(blob),
        segment_length_c(blob));
ioffset = segment_length_c(blob) / sizeof (instruction);
if (segment_length_c(blob) % sizeof (instruction))
        ioffset++;
ioffset += sizeof (cell) / sizeof (instruction);
boffset = ioffset * sizeof (instruction);

@ Does not increment |Program_ObjectDB_Free| until the code page is completed.

TODO: memmove occasionally segfaults.

@<Copy constant objects into |Program_ObjectDB|@>=
objectdb = array_base(o)[ASSEMBLY_READY_OBJECTDB];
new_objectdb_length = Program_ObjectDB_Free;
i = new_objectdb_length + array_length_c(objectdb);
if (i > OBJECTDB_MAX) {
        reason = LERR_LIMIT;
        goto Trap;
}
if (i >= array_length_c(Program_ObjectDB))
        ortrap(array_resize_m(Program_ObjectDB, i, NIL));
new_objectdb_length = i;
memmove(array_base(Program_ObjectDB) + (Program_ObjectDB_Free * sizeof (cell)),
        array_base(objectdb), array_length_c(objectdb) * sizeof (cell));

@ Table of (label . list-of-statements). It might be marginally
more efficient to perform this scan (and the subsequent one) during
the process of building each instruction.

@<Look for required address symbols@>=
for (i = 0; i < hashtable_length_c(array_base(o)[ASSEMBLY_READY_REQUIRE]); i++) {
        label = hashtable_base(array_base(o)[ASSEMBLY_READY_REQUIRE])[i];
        if (null_p(label) || !defined_p(label))
                continue;
        ortrap(hashtable_search(Program_Export_Table, A(label)->sin, &found));
        if (undefined_p(found)) {
                reason = LERR_MISSING;
                goto Trap;
        }
}

@ Table of (label . address). No need to save/copy |Program_Export_Base|,
only the table and |Program_Export_Free|.

Links to the address' location in |Program_Export_Base| is saved
in the next free slot in |page|, beginning above the blob (and
back-link pointer that shouldn't be there): |boffset|/|ioffset|.

Page layout is:

        Pointer to program object

        Blob with padding to instruction-size boundary

        Program code, instruction 0 is at |0 + ioffset|.

The real address (ie. (0 + ioffset OR page)) is put in the next
free slot in |Program_Export_Base| and the hashtable is adjusted
to point to that offset in place of the bytecode offset (née address).

Does not increment |Program_Export_Free| until the code page is ready.

@<Add exported address symbols to a copy of |Program_Export_Table|@>=
ortrap(copy_hashtable(Program_Export_Table, &new_table));
next_export = Program_Export_Free;
for (i = 0; i < hashtable_length_c(array_base(o)[ASSEMBLY_READY_EXPORT]); i++) {
        label = hashtable_base(array_base(o)[ASSEMBLY_READY_EXPORT])[i];
        if (null_p(label) || undefined_p(label))
                continue;
@#
        assert(pair_p(label));
        assert(fixed_p(A(label)->dex)); /* destination offset from
                                                start of program code */
        ito = fixed_value(A(label)->dex);
        assert(ito >= 0 && (address) ito < INSTRUCTION_LENGTH);
        if ((address) ito >= INSTRUCTION_LENGTH - ioffset) {
                reason = LERR_OUT_OF_BOUNDS;
                goto Trap;
        }
@#
        real = ito * sizeof (instruction);
        real += boffset;
        real |= page;
        Program_Export_Base[next_export] = real; /* Real location. */
@#
        ortrap(new_int_c(next_export, &link)); /* Link offset in PEB. */
        ortrap(cons(A(label)->sin, link, &link));
        ortrap(hashtable_save_m(new_table, link, false)); /* Will conflict
                                        with |LERR_EXISTS| if necessary. */
@#
        next_export++;
}

@ @<Install instructions as bytecode and commentary@>=
body = array_base(o)[ASSEMBLY_READY_BODY];
ortrap(new_statement_imp(Op[OP_HALT].owner, &statement_halt));
for (i = 0; i < array_length_c(body); i++) {
        lins = array_base(body)[i];
        if (null_p(lins))
                lins = statement_halt;
        assert(statement_p(lins));
        statement_instruction(lins, &op);
        opb = opcode_object(op);
        ins = htobe32((fixed_value(opcode_id_c(op)) & 0xff) << 24);
        if (opb->arg0 == NARG) {
                assert(opb->arg1 == NARG && opb->arg2 == NARG);
                statement_argument(lins, fix(0), &arg);
                if (!null_p(arg)) {
                        reason = LERR_INCOMPATIBLE;
                        goto Trap;
                }
                goto finish_arguments;
        }
        @<Encode the first argument@>@;
        @<Encode the second argument@>@;
        @<Encode the third argument@>@;
finish_arguments:
        ((instruction *) (page | boffset))[i] = ins;
}

@ @<Encode the first argument@>=
statement_argument(lins, fix(0), &arg);
if (null_p(arg)) {
        reason = LERR_INCOMPATIBLE;
        goto Trap;
}
switch (opb->arg0) {
case AADD:
        @<Encode a single address argument and |break|@>
case ARGH:
        @<Encode an error identifier argument and |break|@>
case AREG:
        @<Encode the first register argument and |break|@>
default:
        reason = LERR_INTERNAL;
        goto Trap;
}

@ ie.~24 bits.

@<Encode a single address ...@>=
assert(opb->arg1 == NARG && opb->arg2 == NARG);
statement_argument(lins, fix(1), &tmp);
if (!null_p(tmp)) {
        reason = LERR_INCOMPATIBLE;
        goto Trap;
}
switch (fixed_value(A(arg)->sin)) {
case ARGUMENT_RELATIVE:
        ortrap(assembly_validate_integer(24, true, A(arg)->dex, &wvalue));
        if (wvalue < -i || wvalue == 0 || wvalue > array_length_c(body) - i) {
                reason = LERR_OUT_OF_BOUNDS;
                goto Trap;
        }
        wvalue *= sizeof (instruction);
        ins |= htobe32((wvalue & 0xffffff) | (BYTECODE_ADDRESS_RELATIVE << 30));
        break;
case ARGUMENT_FAR_ADDRESS:
        ortrap(vm_locate_entry(A(arg)->dex, &avalue));
        assert(instruction_page(avalue) != page);
        ins |= htobe32(ivalue & 0xffffff);
        ins |= htobe32(BYTECODE_ADDRESS_INDIRECT << 30);
        break;
default:
        ortrap(assembly_encode_AREG(0, arg, &ivalue)); /* Checks for argument type. */
        ins |= ivalue;
        ins |= htobe32(BYTECODE_ADDRESS_REGISTER << 30);
        break;
}
break;

@ TODO: Allow the error object to be obtained from a register.

@.TODO@>
@<Encode an error identifier ...@>=
assert(opb->arg1 == NARG && opb->arg2 == NARG);
if (A(arg)->sin != fix(ARGUMENT_ERROR) || !error_p(A(arg)->dex)) {
        reason = LERR_INCOMPATIBLE;
        goto Trap;
}
statement_argument(lins, fix(1), &tmp);
if (!null_p(tmp)) {
        reason = LERR_INCOMPATIBLE;
        goto Trap;
}
ortrap(assembly_validate_integer(7, true, error_id_c(A(arg)->dex), &wvalue));
ins |= htobe32((wvalue | 0x80) << 8);
break;

@ @<Encode the first register ...@>=
ortrap(assembly_encode_AREG(0, arg, &ivalue));
ins |= ivalue;
break;

@ Second argument.

@<Encode the second argument@>=
statement_argument(lins, fix(1), &arg);
if (opb->arg1 == NARG) {
        if (null_p(arg))
                goto finish_arguments;
        else {
                reason = LERR_INCOMPATIBLE;
                goto Trap;
        }
} else if (null_p(arg)) {
        reason = LERR_INCOMPATIBLE;
        goto Trap;
}
switch (opb->arg1) {
case AADD:
        @<Encode a 16-bit address and |break|@>
case ALOB:
        @<Encode a large object and |break|@>
case ALOT:
        @<Encode the middle ALOT and |break|@>
default:
        reason = LERR_INTERNAL;
        goto Trap;
}

@ 16-bit relative only. No 16 bit indirect jumps (yet?).

@<Encode a 16-bit address ...@>=
assert(opb->arg2 == NARG);
switch (fixed_value(A(arg)->sin)) {
case ARGUMENT_RELATIVE:
        ortrap(assembly_validate_integer(16, true, A(arg)->dex, &wvalue));
        if (wvalue < -i || wvalue == 0 || wvalue > array_length_c(body) - i) {
                reason = LERR_OUT_OF_BOUNDS;
                goto Trap;
        }
        wvalue *= sizeof (instruction);
        ins |= htobe32((wvalue & 0xffff) | (BYTECODE_ADDRESS_RELATIVE << 30));
        break;
case ARGUMENT_REGISTER:
case ARGUMENT_REGISTER_POPPING:
        ortrap(assembly_encode_AREG(1, arg, &ivalue));
        ins |= ivalue | htobe32((BYTECODE_ADDRESS_REGISTER << 30));
        break;
default:
        reason = LERR_INCOMPATIBLE;
        goto Trap;
}
break;

@ ALOB; anything: int, const, pair:reg/bool, pair:table/index

@<Encode a large object ...@>=
assert(opb->arg2 == NARG);
switch (fixed_value(A(arg)->sin)) {
case ARGUMENT_TABLE:
        assert(integer_p(A(arg)->dex)); // assembly table offset
        if (!fixed_p(A(arg)->dex)
                    || (wvalue = fixed_value(A(arg)->dex)) < 0
                    || wvalue > OBJECTDB_MAX) {
                reason = LERR_INCOMPATIBLE;
                goto Trap;
        } else if ((wvalue += Program_ObjectDB_Free) > OBJECTDB_MAX) {
                reason = LERR_OUT_OF_BOUNDS;
                goto Trap;
        }
        wvalue = (wvalue & (OBJECTDB_SPLIT_BOTTOM | OBJECTDB_ROW))
                | ((wvalue & (OBJECTDB_SPLIT_TOP)) << OBJECTDB_SPLIT_GAP);
        ins |= htobe32(wvalue | (BYTECODE_OBJECT_TABLE << 30));
        break;
case ARGUMENT_OBJECT:
        if (fixed_p(A(arg)->dex)
                    && fixed_value(A(arg)->dex) >= TINY_MIN
                    && fixed_value(A(arg)->dex) <= TINY_MAX) {
                ortrap(assembly_encode_ALOT(1, arg, &ivalue)); /* Checks for argument type. */
                ins |= ivalue;
        } else if (integer_p(A(arg)->dex)) {
                orassert(int_value(A(arg)->dex, &wvalue));
                assert(wvalue >= INT16_MIN && wvalue <= INT16_MAX);
                ins |= htobe32((wvalue & 0xffff) | (BYTECODE_OBJECT_INTEGER << 30));
        } else {
                assert(special_p(A(arg)->dex));
case ARGUMENT_REGISTER:
case ARGUMENT_REGISTER_POPPING:
                ortrap(assembly_encode_ALOT(1, arg, &ivalue)); /* Checks for argument type. */
                ins |= ivalue;
        }
        break;
default:
        reason = LERR_INCOMPATIBLE;
        goto Trap;
}
break;

@ @<Encode the middle ALOT ...@>=
assert(opb->arg2 == ALOT);
ortrap(assembly_encode_ALOT(1, arg, &ivalue));
ins |= ivalue;
break;

@ @<Encode the third argument@>=
if (opb->arg2 != NARG) {
        statement_argument(lins, fix(2), &arg);
        if (null_p(arg)) {
                reason = LERR_INCOMPATIBLE;
                goto Trap;
        }
        ortrap(assembly_encode_ALOT(2, arg, &ivalue));
        ins |= ivalue;
}

@ 24 bits are used to encode relative address offsets and the error
number to |OP_TRAP|. 16 bits encode relative offsets and any 16 bit
integer.

@c
error_code
assembly_validate_integer (int   width,
                           bool  signed_p,
                           cell  lvalue,
                           word *ret)
{
        word min, max, cvalue;
        error_code reason;

        switch (width) {
        case 7:
                assert(signed_p);
                min = ASR(INT8_MIN, 1);
                max = ASR(INT8_MAX, 1);
                break;
        case 16:
                min = signed_p ? INT16_MIN : 0;
                max = signed_p ? INT16_MAX : UINT16_MAX;
                break;
        case 24:
                min = ASR(signed_p ? INT32_MIN : 0, 8);
                max = ASR(signed_p ? INT32_MAX : UINT32_MAX, 8);
                break;
        }
        orreturn(int_value(lvalue, &cvalue));
        if (cvalue < min || cvalue > max)
                return LERR_INCOMPATIBLE;
        *ret = cvalue;
        return LERR_NONE;
}

@ @d TINY_MIN -0x40
  @d TINY_MAX  0x3f
  @d TINY_MASK 0x7f

@ @c
error_code
assembly_encode_ALOT (int          argc,
                      cell         argv,
                      instruction *ret)
{
        assert(argc >= 0 && argc <= 2);
        assert(argument_p(argv));
        if (A(argv)->sin != fix(ARGUMENT_OBJECT))
                return assembly_encode_AREG(argc, argv, ret);
        assert(special_p(A(argv)->dex));
        if (fixed_p(A(argv)->dex)) {
                assert((fixed_value(A(argv)->dex) >= TINY_MIN
                    && fixed_value(A(argv)->dex) <= TINY_MAX));
                argv = BYTECODE_CONSTANT_INTEGER | (fixed_value(A(argv)->dex) & TINY_MASK);
        } else
                argv = BYTECODE_CONSTANT_SPECIAL | (((A(argv)->dex + 1) / 2) & TINY_MASK);
        assert(BYTECODE_OBJECT_CONSTANT == 0);
        *ret = htobe32(argv << ((2 - argc) * 8));
        return LERR_NONE;
}

@ @c
error_code
assembly_encode_AREG (int          argc,
                      cell         argv,
                      instruction *ret)
{
        bool popping;

        assert(argc >= 0 && argc <= 2);
        assert(argument_p(argv));
        popping = A(argv)->sin == fix(ARGUMENT_REGISTER_POPPING);
        assert(popping || A(argv)->sin == fix(ARGUMENT_REGISTER));
        assert(register_p(A(argv)->dex));
        argv = fixed_value(register_id_c(A(argv)->dex)) | (popping << 7);
        argv <<= ((2 - argc) * 8);
        assert(BYTECODE_FIRST_REGISTER == BYTECODE_OBJECT_REGISTER);
        if (argc == 1)
                argv |= BYTECODE_FIRST_REGISTER << 30;
        else if (argc == 2)
                argv |= BYTECODE_SECOND_REGISTER << 30;
        *ret = htobe32(argv);
        return LERR_NONE;
}

@ @c
error_code
new_assembly_buffer (byte *source,
                     word  length,
                     cell *ret)
{
        cell dupe;
        error_code reason;

        assert(length <= HALF_MAX);
        orreturn(new_segment(length, 0, &dupe));
        memmove(segment_base(dupe), source, length);
        return new_assembly_segment(dupe, ret);
}

@ @c
error_code
new_assembly_segment (cell  source,
                      cell *ret)
{
        cell ass, statement;
        cell lconsume, llength, loffset;
        error_code reason;

        assert(segment_p(source));
        orreturn(new_int_c(segment_length_c(source), &llength));
        if (!fixed_p(llength))
                return LERR_LIMIT;
        orreturn(new_assembly_progress(&ass));
        loffset = fix(0);
        int l = 1;
        while (fixed_value(loffset) < segment_length_c(source)) {
                orreturn(parse_segment_to_statement(source, loffset,
                        llength, &lconsume, &statement));
                assert(fixed_p(lconsume) && lconsume != fix(0));
                orreturn(assembly_append_line_m(ass, statement));
#if 0
                printf("       %5d ", l);
                for (int i = fixed_value(loffset);
                     i < fixed_value(loffset) + fixed_value(lconsume);
                     i++)
                     if (segment_base(source)[i] != '\n')
                     putchar(segment_base(source)[i]);
                printf("\r0x%4x\n",
                (void *) ((fixed_value(array_base(ass)[ASSEMBLY_PROGRESS_NEXT_ADDRESS]) -1)
                * 4 + 8));
#endif
                llength = fix(fixed_value(llength) - fixed_value(lconsume));
                loffset = fix(fixed_value(loffset) + fixed_value(lconsume));
                l++;
        }
        return assembly_finish_m(ass, ret);
}

@* Evaluator.

@<Global...@>=
shared cell Evaluate_Program;

@ @<Data...@>=
#include "evaluate.c"

@ These symbols are defined in \.{evaluate.c}, which embeds the
contents of \.{evaluate.la} in a \CEE/ variable.

@<Extern...@>=
extern shared cell Evaluate_Program;
extern shared char Evaluate_Source[];
extern shared long Evaluate_Source_Length;

@ @<Initialise evaluator and other bytecode@>=
orreturn(new_assembly_buffer((byte *) Evaluate_Source,
        Evaluate_Source_Length, &ltmp));
orreturn(assembly_install_m(ltmp, &ltmp));
Evaluate_Program = ltmp;

@** Threads.

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

@ Why |Threads| and |Thread_DB|? I can't remember.

@<Global...@>=
shared osthread *Threads = NULL;
shared cell *Thread_DB = NULL;
shared int Thread_DB_Length = 0;
shared pthread_mutex_t Thread_DB_Lock;
shared pthread_barrier_t Thready;

@ @<Extern...@>=
extern shared osthread *Threads;
extern shared cell *Thread_DB;
extern shared int Thread_DB_Length;
extern shared pthread_mutex_t Thread_DB_Lock;
extern shared pthread_barrier_t Thready;

@ @<Fun...@>=
error_code init_osthread (void);
error_code init_osthread_mutex (pthread_mutex_t *, bool, bool);

@ @<Initialise threading@>=
orabort(init_osthread_mutex(&Thread_DB_Lock, false, true));
if (pthread_barrier_init(&Thready, NULL, 2))
        just_abort(LERR_INTERNAL, "failed to intialise Thread Ready barrier");
orabort(alloc_mem(NULL, Thread_DB_Length * sizeof (cell), 0,
        (void **) &Thread_DB));
SCOW_Attributes[LSCOW_PTHREAD_T].length = sizeof (osthread); /* Wrapper around
                                                                |pthread_t|. */
SCOW_Attributes[LSCOW_PTHREAD_T].align = sizeof (void *);

@ @c
error_code
init_osthread (void)
{
        int i;
        Thread_Ready = false;
        @<(Re-)Initialise thread register pointers@>@;
        Thread_Ready = true;
        return LERR_NONE;
}

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
@d llt_fixture_grow(O,L,D) (alloc_mem((O), Test_Fixture_Size * ((L) + (D)), 0,
        (void **) &(O)))
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
        llt_forward clean;     /* Cleaning up after. */                       \
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
error_code llt_appendf (llt_header *, char *, char **, char *, ...);
void llt_fixture__init_common (llt_header *, int, llt_thunk, llt_thunk,
        llt_thunk, llt_thunk);
void llt_fixture_free (llt_header *);
error_code llt_fixture_leak (llt_header *, int *);
error_code llt_list_suite (llt_header *);
error_code llt_load_tests (bool, llt_header **);
error_code llt_main (int, char **, bool);
int llt_perform_test (int *, llt_header *);
void llt_print_test (llt_header *);
error_code llt_run_suite (llt_header *);
error_code llt_skip_test (int *, llt_header *, char *);
error_code llt_sprintf (llt_header *, char **, char *, ...);
error_code llt_usage (char *, bool);
error_code llt_vsprintf (llt_header *, int, char **, char *, va_list);
bool tap_ok (llt_header *, char *, bool, cell);
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

        orreturn(init_mem());
        if (init)
                orreturn(init_vm());
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

        orreturn(alloc_mem(NULL, Test_Fixture_Size, 0,
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
@d LLT_RUN_PANIC    2
@#
@d orfail(E) if (failure_p(E)) return LLT_RUN_FAIL;
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
                        if (run == LLT_RUN_CONTINUE)
                                run = llt_perform_test(&t,
                                        llt_fixture_fetch(suite, i));
                        if (run != LLT_RUN_CONTINUE)
                                warnx("Unknown test failure");
                        else if (t != llt_fixture_fetch(suite, i)->tap_start
                                    + llt_fixture_fetch(suite, i)->taps)
                                warnx("Test tap mismatch: %d != %d", t,
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

        orreturn(llt_sprintf(testcase, &msg, "--- # SKIP %s", excuse));
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
int
llt_perform_test (int        *tap,
                  llt_header *testcase)
{
        bool allocating;
        int n, r;

        if (testcase->progress != LLT_PROGRESS_INIT)
                return LLT_RUN_ABORT;
@#
        n = testcase->prepare == NULL ? LLT_RUN_CONTINUE
                : testcase->prepare(testcase);
        if (n != LLT_RUN_CONTINUE)
                return n;
        testcase->progress = LLT_PROGRESS_PREPARE;
@#
        if (testcase->run == NULL)
                return LLT_RUN_ABORT;
        n = testcase->run(testcase);
        if (n != LLT_RUN_CONTINUE)
                return n;
        testcase->progress = LLT_PROGRESS_RUN;
@#
        if (testcase->validate == NULL)
                r = LLT_RUN_ABORT;
        else {
                if (Test_Memory != NULL) {
                        allocating = Test_Memory->active;
                        Test_Memory->active = false;
                }
                testcase->tap = *tap;
                r = testcase->validate(testcase);
                *tap = testcase->tap;
                if (Test_Memory != NULL)
                        Test_Memory->active = allocating;
        }
@#
        if (r < LLT_RUN_PANIC)
                n = testcase->clean == NULL ? LLT_RUN_CONTINUE
                        : testcase->clean(testcase);
        if (r != LLT_RUN_CONTINUE)
                return r;
        else
                return n;
}

@* Testing memory allocation. Those tests which need to mock the
core memory allocator point |Test_Memory| to an instance of this
object (eg.~created in |main| before calling |llt_main|) with
pointers to alternative allocation and release functions.

@ @<Type def...@>=
typedef struct {
        bool active; /* Whether |alloc_mem| should revert to these. */
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

@ @d LLT_PROGRESS_INIT   0
@d LLT_PROGRESS_PREPARE  1
@d LLT_PROGRESS_RUN      2
@d LLT_PROGRESS_VALIDATE 3
@d LLT_PROGRESS_CLEAN    4
@d LLT_PROGRESS_SKIP     5
@(testless.c@>=
void
llt_fixture__init_common (llt_header *fixture,
                          int         id,
                          llt_thunk   prepare,
                          llt_thunk   run,
                          llt_thunk   validate,
                          llt_thunk   clean)
{
        fixture->name = "";
        fixture->id = id;
        fixture->total = -1;
        fixture->leaks = NULL;
        fixture->perform = true;
        fixture->prepare = (llt_forward) prepare;
        fixture->run = (llt_forward) run;
        fixture->validate = (llt_forward) validate;
        fixture->clean = (llt_forward) clean;
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
llt_leak (llt_header  *fixture,
          size_t       length,
          void       **ret)
{
        int lid;
        error_code reason;

        if (fixture->leaks == NULL)
                lid = 1;
        else
                lid = (word) fixture->leaks[0];
        orreturn(alloc_mem(fixture->leaks, sizeof (void *) * (lid + 1),
                0, (void **) &fixture->leaks));
        fixture->leaks[0] = (void *) (intptr_t) lid;
        fixture->leaks[lid] = NULL;
        orreturn(alloc_mem(NULL, length, 0, ret));
        fixture->leaks[lid] = *ret;
        fixture->leaks[0] = (void *) (intptr_t) (lid + 1);
        return LERR_NONE;
}

@ Although nothing uses it the |llt_fixture_free| function will
clean up a fixture's memory allocations.

Ignores error returns but |free| doesn't fail anyway.

@(testless.c@>=
void
llt_fixture_free (llt_header *fixture)
{
        int i;

        if (fixture->leaks != NULL) {
                for (i = 0; i < (long) fixture->leaks[0]; i++)
                        if (fixture->leaks[i] != NULL)
                                free_mem(fixture->leaks[i]);
                free_mem(fixture->leaks);
        }
        fixture->leaks = NULL;
}

@ The main consumer of |llt_fixture_leak| is this wrapper around
\.{printf} and its two users |llt_sprintf| and |llt_appendf|.

@(testless.c@>=
error_code
llt_vsprintf (llt_header  *fixture,
              int          length,
              char       **ret,
              char        *fmt,
              va_list      args)
{
        char *buf;
        error_code reason;

        orreturn(llt_leak(fixture, length + 1, (void **) &buf));
        if (vsnprintf(buf, length + 1, fmt, args) < 0)
                return LERR_INTERNAL;
        *ret = buf;
        return LERR_NONE;
}

@ @(testless.c@>=
error_code
llt_sprintf (llt_header  *fixture,
             char       **ret,
             char        *fmt, ...)
{
        int length;
        va_list args;
        error_code reason;

        va_start(args, fmt);
        length = vsnprintf(NULL, 0, fmt, args);
        va_end(args);
        va_start(args, fmt);
        reason = llt_vsprintf(fixture, length, ret, fmt, args);
        va_end(args);
        return reason;
}

@ @(testless.c@>=
error_code
llt_appendf (llt_header  *fixture,
             char        *prior,
             char       **ret,
             char        *fmt, ...)
{
        char *append;
        int length;
        va_list args;
        error_code reason;

        va_start(args, fmt);
        length = vsnprintf(NULL, 0, fmt, args);
        va_end(args);
        va_start(args, fmt);
        reason = llt_vsprintf(fixture, length, &append, fmt, args);
        va_end(args);
        if (failure_p(reason))
                return reason;
        return llt_sprintf(fixture, ret, "%s%s", prior, append);
}

@* Objects Under Test.

@<Test fun...@>=
bool llt_out_match_p (cell, cell);

@ @(testless.c@>=
bool
llt_out_match_p (cell got,
                 cell want)
{
        if (special_p(want) || symbol_p(want))
                return got == want;
        if (special_p(got) || symbol_p(got))
                return false;
        if (T(got) != T(want))
                return false;
        if (pair_p(want))
                return pair_p(got)
                        && llt_out_match_p(A(got)->sin, A(want)->sin)
                        && llt_out_match_p(A(got)->dex, A(want)->dex);
        if (pointer_p(want)) {
                if (!pointer_p(got))
                        return false;
                if (pointer(got) != pointer(want))
                        return false;
                return llt_out_match_p(pointer_datum(got), pointer_datum(want));
        }
        if (closure_p(want)) {
                if (!closure_p(got))
                        return false;
                if (!llt_out_match_p(array_base(got)[CLOSURE_ADDRESS],
                            array_base(want)[CLOSURE_ADDRESS]))
                        return false;
                if (!llt_out_match_p(array_base(got)[CLOSURE_ENVIRONMENT],
                            array_base(want)[CLOSURE_ENVIRONMENT]))
                        return false;
                if (!llt_out_match_p(array_base(got)[CLOSURE_SIGNATURE],
                            array_base(want)[CLOSURE_SIGNATURE]))
                        return false;
                return llt_out_match_p(array_base(got)[CLOSURE_BODY],
                            array_base(want)[CLOSURE_BODY]);
        }
        if (environment_p(want)) {
                return got == want; /* TBD */
        }
        assert(!"unsupported match type");
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

@ @d tap_fail(C,T,M) tap_ok((C), (T), false, (M))
@d tap_pass(C,T,M) tap_ok((C), (T), true, (M))
@(testless.c@>=
bool
tap_ok (llt_header *testcase,
        char       *title,
        bool        result,
        cell        meta)
{
        assert(testcase->progress == LLT_PROGRESS_RUN
                || testcase->progress == LLT_PROGRESS_SKIP);
        testcase->meta = meta;
        testcase->ok = result ? LLT_RUN_CONTINUE : LLT_RUN_FAIL;
        if (result)
                tap_out("ok");
        else
                tap_out("not ok");
        tap_out(" %d - ", testcase->tap++);
        if (testcase->name != NULL)
                tap_out("%s: ", testcase->name);
        tap_out("%s\n", title);
        return result;
}

@ Like |tap_ok| but the unit result so far must be a success.

@d tap_and(C,T,R,M) ((th->ok == LLT_RUN_CONTINUE)
        ? tap_ok((C), (T), (R), (M))
        : tap_fail((C), (T), (M)))

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

        orreturn(llt_fixture_grow(suite, *count, 1));
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

@ @(t/insanity.c@>=
error_code
llt_Sanity__Halt (llt_header  *suite,
                  int         *count,
                  bool         full @[unused@],
                  llt_header **ret)
{
        llt_fixture *tc;
        error_code reason;
        instruction *ins;

        orreturn(llt_fixture_grow(suite, *count, 1));
        tc = (llt_fixture *) suite;
        llt_fixture__init_common((llt_header *) (tc + *count), *count,
                llt_Sanity__prepare,
                llt_Sanity__interpret,
                llt_Sanity__validate,
                NULL);
        tc[*count].name = "HALT";
        orreturn(llt_leak(suite, sizeof (instruction), (void **) &ins));
        ins[0] = htobe32(OP_HALT << 24);
        tc[*count].program = ins;
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

        return LLT_RUN_CONTINUE;
}

@ Nothing in \Ls/ is tested by this test although the parts used
by the test harness are exercised.

@(t/insanity.c@>=
int
llt_Sanity__noop (llt_header *testcase_ptr @[unused@])
{
        return LLT_RUN_CONTINUE;
}

@ @(t/insanity.c@>=
int
llt_Sanity__interpret (llt_header *testcase_ptr @[unused@])
{
        interpret();
        return LLT_RUN_CONTINUE;
}

@ @(t/insanity.c@>=
int
llt_Sanity__validate (llt_header *testcase_ptr)
{
        tap_ok(testcase_ptr, "done", true, NIL);
        tap_ok(testcase_ptr, "VPU is not trapped", !failure_p(Trapped), NIL);
        return testcase_ptr->ok;
}

@* Hashtable tests.

@d LLT_HASHTABLE_SEED (HASHTABLE_TINY + 1)
@d LLT_HASHTABLE_FACTOR 24
@(t/hashtable.c@>=
@<Test common preamble@>@;

int
main (int    argc,
      char **argv)
{@+
        return llt_main(argc, argv, false);@+
}

typedef struct {
        LLT_FIXTURE_HEADER@;
        word new_length; /* How long a hashtable to create. */
        word pre_length; /* The pre-test size actually created. */
        cell test_table; /* Prepared hashtable to run a test against. */
        cell test_datum; /* Combined key/value to test with. */
        bool test_replace; /* Replace flag to |hashtable_save_m|. */
        cell seed[LLT_HASHTABLE_SEED]; /* To insert prior to testing. */
} llt_fixture;

int Test_Fixture_Size = sizeof (llt_fixture);

error_code llt_Hashtable__New (llt_header *, int *, bool, llt_header **);
error_code llt_Hashtable__Save (llt_header *, int *, bool, llt_header **);

llt_initialise Test_Suite[] = {
        llt_Hashtable__New,
        llt_Hashtable__Save,
        NULL
};

@ To test hashtable creation a new hashtable of various sizes is
created and probed.

TODO: Remove boilerplate from \.{*\_\_New} functions.

@(t/hashtable.c@>=
int
llt_Hashtable__New_run (llt_header *th)
{
        llt_fixture *tc = (llt_fixture *) th;
        tc->reason = new_hashtable(tc->new_length, &tc->res);
        return LLT_RUN_CONTINUE;
}

int
llt_Hashtable__New_validate (llt_header *th)
{
        llt_fixture *tc = (llt_fixture *) th;
        char *title;
        error_code reason;

        tap_ok(th, "success", !failure_p(tc->reason), NIL);
        tap_and(th, "hashtable?", hashtable_p(tc->res), NIL);
        if (tc->new_length == 0)@/
                tap_and(th, "length is 0", hashtable_length_c(tc->res) == 0, NIL);
        else@/
                tap_and(th, "length is a power of 2", hashtable_length_c(tc->res)
                        == (1 << high_bit(hashtable_length_c(tc->res))), NIL);
        orassert(llt_sprintf(th, &title, "available slots >= %d",
                tc->new_length));
        tap_and(th, title, hashtable_free_c(tc->res)
                >= tc->new_length, NIL);
        return LLT_RUN_CONTINUE;
}

@.TODO@>
error_code
llt_Hashtable__New (llt_header  *suite,
                    int         *count,
                    bool         full @[unused@],
                    llt_header **ret)
{
        llt_fixture *tc;
        llt_header *th;
        error_code reason;
        int i;

        orreturn(llt_fixture_grow(suite, *count, HASHTABLE_TINY * 2 + 1));
        tc = (llt_fixture *) suite;
        for (i = 0; i < HASHTABLE_TINY * 2 + 1; i++) {
                tc = ((llt_fixture *) suite) + *count + i;
                th = (llt_header *) tc;
                llt_fixture__init_common(th, *count + i,
                        NULL,
                        llt_Hashtable__New_run,
                        llt_Hashtable__New_validate,
                        NULL);
                orreturn(llt_sprintf(th, &tc->name,
                        "new hashtable, length %d", i));
                tc->taps = 4;
                tc->new_length = i;
        }
        (*count) += HASHTABLE_TINY * 2 + 1;
        *ret = suite;
        return LERR_NONE;
}

@ @(t/hashtable.c@>=
error_code
llt_Hashtable__datumfn (half  idx,
                        cell  seed,
                        cell *ret)
{
        cell label;
        error_code reason;
        orreturn(int_to_symbol(fix(idx), &label));
        return cons(label, seed, ret);
}

@ Prepare tests which save into a hashtable by creating a hashtable
and preseeding it.

@(t/hashtable.c@>=
int
llt_Hashtable__Save_prepare (llt_header *th)
{
        llt_fixture *tc = (llt_fixture *) th;
        cell tmp;
        int i, j;

        orfail(new_hashtable(tc->new_length, &tc->test_table));
        tc->pre_length = hashtable_length_c(tc->test_table);
        for (i = 0; i < LLT_HASHTABLE_SEED; i++) {
                if (defined_p(tc->seed[i])) {
                        j = i * LLT_HASHTABLE_FACTOR;
                        orfail(llt_Hashtable__datumfn(j, tc->seed[i], &tmp));
                        orfail(hashtable_save_m(tc->test_table, tmp, false));
                }
        }
        return LLT_RUN_CONTINUE;
}

@ @(t/hashtable.c@>=
int
llt_Hashtable__Save_run (llt_header *th)
{
        llt_fixture *tc = (llt_fixture *) th;
        tc->reason = hashtable_save_m(tc->test_table, tc->test_datum,
                tc->test_replace);
        return LLT_RUN_CONTINUE;
}

@ When this routine was first written the key was passed to the
hashtable routines rather than being discovered within them which
allowed a simple scanning mechanism; the variable |hack| allows the
hashtable to be scanned in a similar manner.

@(t/hashtable.c@>=
int
llt_Hashtable__Save_validate_success (llt_header *th)
{
        llt_fixture *tc = (llt_fixture *) th;
        bool scanned;
        cell hack, found;
        int i, j;

        tap_ok(th, "success", !failure_p(tc->reason), fix(tc->reason));
        orfail(hashtable_search(tc->test_table, A(tc->test_datum)->sin, &found));
        tap_ok(th, "key is found", defined_p(found), found);
        tap_and(th, "saved datum is returned", found == tc->test_datum, found);
@#
        scanned = true;
        for (i = 0; scanned && i < LLT_HASHTABLE_SEED; i++) {
                if (defined_p(tc->seed[i])) {
                        j = i * LLT_HASHTABLE_FACTOR;
                        if (failure_p(llt_Hashtable__datumfn(j, NIL, &hack)))
                                return LLT_RUN_ABORT;
                        if (failure_p(hashtable_search(tc->test_table,
                                    A(hack)->sin, &found)))
                                scanned = false;
                        else if (!tc->test_replace)
                                scanned = pair_p(found)
                                        && A(found)->dex == tc->seed[i];
                }
        }
        tap_ok(th, "other entries remain unchanged", scanned, NIL);
        return LLT_RUN_CONTINUE;
}

@ @(t/hashtable.c@>=
int
llt_Hashtable__Save_validate_failure (llt_header *th)
{
        llt_fixture *tc = (llt_fixture *) th;
        cell found;

        tap_ok(th, "fails", tc->reason == tc->expect, NIL);
        orfail(hashtable_search(tc->test_table, A(tc->test_datum)->sin,
                &found));
        tap_ok(th, "nothing is saved", found != tc->test_datum, found);
        return LLT_RUN_CONTINUE;
}

@ @(t/hashtable.c@>=
error_code
llt_Hashtable__Save (llt_header  *suite,
                     int         *count,
                     bool         full @[unused@],
                     llt_header **ret)
{
        llt_fixture *tc;
        llt_header *th;
        error_code reason;
        int i, j;

        orreturn(llt_fixture_grow(suite, *count, 8));
        tc = (llt_fixture *) suite;
        for (i = 0; i < 8; i++) {
                tc = ((llt_fixture *) suite) + *count + i;
                th = (llt_header *) tc;

                llt_fixture__init_common(th, *count + i,
                        llt_Hashtable__Save_prepare,
                        llt_Hashtable__Save_run,
                        llt_Hashtable__Save_validate_success,
                        NULL);
                tc->taps = 4;
                tc->new_length = HASHTABLE_TINY - 1;
                tc->test_replace = false;
                for (j = 0; j < LLT_HASHTABLE_SEED; j++)
                        tc->seed[j] = UNDEFINED;
                orfail(llt_Hashtable__datumfn(2 * LLT_HASHTABLE_FACTOR,
                        fix(-1), &tc->test_datum));
        }

        tc = ((llt_fixture *) suite) + *count;
        tc[0].name = "save into hashtable, length 0";
        tc[0].new_length = 0;
        tc[1].name = "save into hashtable, empty";
        tc[2].name = "save into hashtable, seeded";
        for (i = 1; i < LLT_HASHTABLE_SEED; i += 2)
                tc[2].seed[i] = fix(i * 2);
        tc[3].name = "save into hashtable, replacing";
        for (i = 0; i < LLT_HASHTABLE_SEED; i += 2)
                tc[3].seed[i] = fix(i * 2);
        tc[3].test_replace = true;

        tc[4].name = "insert in full hashtable";
        tc[5].name = "replace in full hashtable";
        assert(LLT_HASHTABLE_SEED > HASHTABLE_TINY);
        tc[4].seed[0] = tc[5].seed[0] = fix(0);
        tc[4].seed[1] = tc[5].seed[1] = fix(2);
        for (i = 3; i < HASHTABLE_TINY - 1; i++)
                tc[4].seed[i] = tc[5].seed[i] = fix(i * 2);
        tc[4].seed[i] = fix(i * 2);
        tc[5].seed[2] = fix(4);
        tc[5].test_replace = true;

        tc[6].name = "insert in hashtable, conflicting";
        tc[6].seed[2] = fix(4);
        tc[6].validate = (llt_forward) llt_Hashtable__Save_validate_failure,
        tc[6].expect = LERR_EXISTS;
        tc[7].name = "replace in hashtable, missing";
        tc[7].validate = (llt_forward) llt_Hashtable__Save_validate_failure,
        tc[7].expect = LERR_MISSING;
        tc[7].test_replace = true;
        tc[6].taps = tc[7].taps = 2;

        (*count) += 8;
        *ret = suite;
        return LERR_NONE;
}

@* Evaluator tests.

@(t/evaluator.c@>=
@<Test common preamble@>@;

int
main (int    argc,
      char **argv)
{@+
        return llt_main(argc, argv, true);@+
}

typedef struct {
        LLT_FIXTURE_HEADER@;

        cell expression;
        cell want;
        cell save_environment;
        half interpret_limit;
} llt_fixture;

int Test_Fixture_Size = sizeof (llt_fixture);

error_code llt_Evaluator__Immediate (llt_header *, int *, bool, llt_header **);
error_code llt_Evaluator__Simple (llt_header *, int *, bool, llt_header **);
@#
int llt_Evaluator__prepare (llt_header *);
int llt_Evaluator__run (llt_header *);
int llt_Evaluator__validate (llt_header *);

llt_initialise Test_Suite[] = {
        llt_Evaluator__Immediate,
        llt_Evaluator__Simple,
        NULL
};

@ @(t/evaluator.c@>=
int
llt_Evaluator__prepare (llt_header *th)
{
        llt_fixture *tc = (llt_fixture *) th;
        address fin;
        cell extended, label, tmp;
        error_code reason;

        ortrap(new_symbol_const(LLT_LOOKUP_MISSING, &label));
        reason = env_search(Environment, label, &tmp);
        if (failure_p(reason) && reason != LERR_MISSING) {
                printf("# " LLT_LOOKUP_MISSING " is bound.\n");
                goto Trap;
        }
        tc->save_environment = Environment;
        ortrap(new_env(Environment, &extended));
        ortrap(new_symbol_const(LLT_LOOKUP_PRESENT, &label));
        ortrap(new_symbol_const(LLT_LOOKUP_CORRECT, &tmp));
        ortrap(env_save_m(extended, label, tmp, false));
@#
        Interpret_Count = 0;
        Interpret_Limit = tc->interpret_limit;
        ortrap(new_symbol_const(PROGRAM_EVALUATE, &label));
        ortrap(vm_locate_entry(label, &Ip));
        ortrap(new_symbol_const(PROGRAM_EXIT, &label));
        ortrap(vm_locate_entry(label, &fin));
        ortrap(new_pointer(fin, &label));
        ortrap(stack_array_push(&Control_Link, label));
@#
        Environment = extended;
        Expression = tc->expression;
        return LLT_RUN_CONTINUE;
Trap:
        return LLT_RUN_FAIL;
}

@ @(t/evaluator.c@>=
int
llt_Evaluator__run (llt_header *th)
{
        llt_fixture *tc = (llt_fixture *) th;
        tc->reason = interpret();
        return LLT_RUN_CONTINUE;
}

@ @(t/evaluator.c@>=
int
llt_Evaluator__validate (llt_header *th)
{
        llt_fixture *tc = (llt_fixture *) th;

        tap_ok(th, "success", !failure_p(tc->reason), fix(tc->reason));
        tap_ok(th, "correct result", Accumulator == tc->want, Accumulator);
        return LLT_RUN_CONTINUE;
}

@ @(t/evaluator.c@>=
int
llt_Evaluator__failure (llt_header *th)
{
        llt_fixture *tc = (llt_fixture *) th;

        tap_ok(th, "fails", tc->reason == tc->expect, fix(tc->reason));

        return LLT_RUN_CONTINUE;
}

@ @(t/evaluator.c@>=
int
llt_Evaluator__clean (llt_header *th @[unused@])
{
        Environment = ((llt_fixture *) th)->save_environment;
        return LLT_RUN_CONTINUE;
}

@ @(t/evaluator.c@>=
error_code
llt_Evaluator__Immediate (llt_header  *suite,
                          int         *count,
                          bool         full,
                          llt_header **ret)
{
        llt_fixture *tc;
        llt_header *th;
        error_code reason;
        int i;

        orreturn(llt_fixture_grow(suite, *count, 4));
        tc = (llt_fixture *) suite;
        for (i = 0; i < 4; i++) {
                tc = ((llt_fixture *) suite) + *count + i;
                th = (llt_header *) tc;
                llt_fixture__init_common(th, *count + i,
                        llt_Evaluator__prepare,
                        llt_Evaluator__run,
                        llt_Evaluator__validate,
                        llt_Evaluator__clean);
                tc->taps = 2;
                tc->expression = tc->want = NIL;
                tc->interpret_limit = 42;
        }
        tc = ((llt_fixture *) suite) + *count;

        tc[0].name = "evaluate nil";
        tc[0].want = tc[0].expression = NIL;

        tc[1].name = "evaluate constant";
        tc[1].want = tc[1].expression = fix(42);

        tc[2].name = "evaluate symbol, present";
        if (full) {
                orreturn(new_symbol_const(LLT_LOOKUP_CORRECT, &tc[2].want));
                orreturn(new_symbol_const(LLT_LOOKUP_PRESENT,
                        &tc[2].expression));
        }

        tc[3].name = "evaluate symbol, missing";
        tc[3].want = UNDEFINED;
        if (full)
                orreturn(new_symbol_const(LLT_LOOKUP_MISSING,
                        &tc[3].expression));
        tc[3].expect = LERR_MISSING;
        tc[3].validate = (llt_forward) llt_Evaluator__failure;
        tc[3].taps = 1;

        (*count) += 4;
        *ret = suite;
        return LERR_NONE;
}

@ @(t/evaluator.c@>=
error_code
llt_Evaluator__Simple (llt_header  *suite,
                       int         *count,
                       bool         full,
                       llt_header **ret)
{
        llt_fixture *tc;
        llt_header *th;
        error_code reason;
        int i;

        orreturn(llt_fixture_grow(suite, *count, 1));
        tc = (llt_fixture *) suite;
        for (i = 0; i < 1; i++) {
                tc = ((llt_fixture *) suite) + *count + i;
                th = (llt_header *) tc;
                llt_fixture__init_common(th, *count + i,
                        llt_Evaluator__prepare,
                        llt_Evaluator__run,
                        llt_Evaluator__validate,
                        llt_Evaluator__clean);
                tc->taps = 2;
                tc->expression = tc->want = NIL;
                tc->interpret_limit = 128;
        }
        tc = ((llt_fixture *) suite) + *count;

        tc[0].name = "evaluate (root-environment)";
        tc[0].want = Environment;
        if (full) {
                orreturn(new_symbol_const("root-environment", &tc[0].expression));
                orreturn(cons(tc[0].expression, NIL, &tc[0].expression));
        }

        (*count) += 1;
        *ret = suite;
        return LERR_NONE;
}

@* Reader tests.

@(t/reader.c@>=
#include <string.h>
@<Test common preamble@>@;

int
main (int    argc,
      char **argv)
{@+
        return llt_main(argc, argv, true);@+
}

typedef struct {
        LLT_FIXTURE_HEADER@;

        half interpret_limit;
        cell source;
        cell start_offset;
        cell want;
} llt_fixture;

int Test_Fixture_Size = sizeof (llt_fixture);

error_code llt_Reader__Simple (llt_header *, int *, bool, llt_header **);
@#
int llt_Reader__prepare (llt_header *);
int llt_Reader__run (llt_header *);
int llt_Reader__validate (llt_header *);
int llt_Reader__clean (llt_header *);
@#
@<Object constructors for reader tests@>@;

@ @(t/reader.c@>=
char LLT_Glyph_Tab[] = { 0xe2, 0xad, 0xbe, 0x00 }; /* \.{\#u2b7e} ---
                                                        horizontal tab key */
char LLT_Glyph_Newline[] = { 0xe2, 0x90, 0xa4, 0x00 }; /* \.{\#u2424} ---
                                                        symbol for newline */
@#
struct {
        char        *source;
        error_code (*build)(cell *);
} LLT_Reader_Rules[] = {@|
        { "42",                 llt_Reader__build_integer_42 },@|
        { "(42)",               llt_Reader__build_list_42 },@|
        { "(42 )",              llt_Reader__build_list_42 },@|
        { "()",                 llt_Reader__build_NIL },@|
        { "( )",                llt_Reader__build_NIL },@|
        { "(\t)",               llt_Reader__build_NIL },@|
        { "(\n\t)",             llt_Reader__build_NIL },@|
        { "#f",                 llt_Reader__build_FALSE },@|
        { "#t",                 llt_Reader__build_TRUE },@|
        { "(())",               llt_Reader__build_pair_NIL_NIL },@|
        { "( ())",              llt_Reader__build_pair_NIL_NIL },@|
        { "(() . ())",          llt_Reader__build_pair_NIL_NIL },@|
        { "symbol",             llt_Reader__build_symbol },@|
        { "long-symbol",        llt_Reader__build_long_symbol },@|
        { "(list)",             llt_Reader__build_list },@|
        { "(+)",                llt_Reader__build_list_tiny },@|
        { "(x y z)",            llt_Reader__build_xyz },@|
        { "(lambda () x y z)",  llt_Reader__build_application },@|
        { "((x y z) x y z)",    llt_Reader__build_list_nested },@|
        { "((x y z) . (x y z))",llt_Reader__build_list_nested },@|
        { NULL, NULL }
};

llt_initialise Test_Suite[] = {
        llt_Reader__Simple,
        NULL
};

@ @(t/reader.c@>=
int
llt_Reader__prepare (llt_header *th)
{
        llt_fixture *tc = (llt_fixture *) th;
        address fin;
        cell label;
        error_code reason;

        Interpret_Count = 0;
        Interpret_Limit = tc->interpret_limit;
        ortrap(new_symbol_const(PROGRAM_READ, &label));
        ortrap(vm_locate_entry(label, &Ip));
        ortrap(new_symbol_const(PROGRAM_EXIT, &label));
        ortrap(vm_locate_entry(label, &fin));
        ortrap(new_pointer(fin, &label));
        ortrap(stack_array_push(&Control_Link, label));
@#
        General[0] = tc->source;
        General[1] = tc->start_offset;
        return LLT_RUN_CONTINUE;
Trap:
        return LLT_RUN_FAIL;
}

@ @(t/reader.c@>=
int
llt_Reader__run (llt_header *th)
{
        llt_fixture *tc = (llt_fixture *) th;
        tc->reason = interpret();
        return LLT_RUN_CONTINUE;
}

@ @(t/reader.c@>=
int
llt_Reader__validate (llt_header *th)
{
        llt_fixture *tc = (llt_fixture *) th;

        tap_ok(th, "success", !failure_p(tc->reason), fix(tc->reason));
        tap_ok(th, "correct result", llt_out_match_p(Accumulator, tc->want),
                Accumulator);
        return LLT_RUN_CONTINUE;
}

@ @(t/reader.c@>=
int
llt_Reader__clean (llt_header *th @[unused@])
{
        return LLT_RUN_CONTINUE;
}

@ @(t/reader.c@>=
error_code
llt_Reader__Simple (llt_header  *suite,
                    int         *count,
                    bool         full,
                    llt_header **ret)
{
        llt_fixture *tc;
        llt_header *th;
        char *name;
        int i, length, rules;
        error_code reason;

        for (rules = 0; LLT_Reader_Rules[rules].source; rules++)
                ;
        orreturn(llt_fixture_grow(suite, *count, rules));
        tc = (llt_fixture *) suite;
        for (i = 0; i < rules; i++) {
                tc = ((llt_fixture *) suite) + *count + i;
                th = (llt_header *) tc;
                llt_fixture__init_common(th, *count + i,
                        llt_Reader__prepare,
                        llt_Reader__run,
                        llt_Reader__validate,
                        llt_Reader__clean);
                tc->taps = 2;
                tc->want = NIL;
                tc->interpret_limit = 2048;
                orreturn(llt_sprintf(th, &tc->name, "read `"));
                name = LLT_Reader_Rules[i].source;
                while (*name) { /* This is horrifically inefficient. */
                        switch (*name) {
                        case '\n':
                                orreturn(llt_appendf(th, tc->name, &tc->name,
                                        "%s", LLT_Glyph_Newline));
                                break;
                        case '\t':
                                orreturn(llt_appendf(th, tc->name, &tc->name,
                                        "%s", LLT_Glyph_Tab));
                                break;
                        default:
                                orreturn(llt_appendf(th, tc->name, &tc->name,
                                        "%c", *name));
                                break;
                        }
                        name++;
                }
                orreturn(llt_appendf(th, tc->name, &tc->name, "'"));
        }
        if (full)
                for (i = 0; i < rules; i++) {
                        tc = ((llt_fixture *) suite) + *count + i;
                        th = (llt_header *) tc;
                        length = strlen(LLT_Reader_Rules[i].source);
                        orreturn(new_segment(length, 0, &tc->source));
                        memmove(segment_base(tc->source),
                                LLT_Reader_Rules[i].source, length);
                        tc->start_offset = fix(0);
                        orreturn(LLT_Reader_Rules[i].build(&tc->want));
                }
        (*count) += rules;
        *ret = suite;
        return LERR_NONE;
}

@ @<Object constructors for reader tests@>=
error_code
llt_Reader__build_integer_42 (cell *ret)
{
        *ret = fix(42);
        return LERR_NONE;
}

error_code
llt_Reader__build_NIL (cell *ret)
{
        *ret = NIL;
        return LERR_NONE;
}

error_code
llt_Reader__build_FALSE (cell *ret)
{
        *ret = LFALSE;
        return LERR_NONE;
}

error_code
llt_Reader__build_TRUE (cell *ret)
{
        *ret = LTRUE;
        return LERR_NONE;
}

@ @<Object constructors for reader tests@>=
error_code
llt_Reader__build_pair_NIL_NIL (cell *ret)
{
        return cons(NIL, NIL, ret);
}

@ @<Object constructors for reader tests@>=
error_code
llt_Reader__build_symbol (cell *ret)
{
        return new_symbol_cstr("symbol", ret);
}

@ @<Object constructors for reader tests@>=
error_code
llt_Reader__build_long_symbol (cell *ret)
{
        return new_symbol_cstr("long-symbol", ret);
}

@ @<Object constructors for reader tests@>=
error_code
llt_Reader__build_list (cell *ret)
{
        cell tmp;
        error_code reason;
        orreturn(new_symbol_cstr("list", &tmp));
        return cons(tmp, NIL, ret);
}

@ @<Object constructors for reader tests@>=
error_code
llt_Reader__build_list_42 (cell *ret)
{
        return cons(fix(42), NIL, ret);
}

@ @<Object constructors for reader tests@>=
error_code
llt_Reader__build_list_tiny (cell *ret)
{
        cell tmp;
        error_code reason;
        orreturn(new_symbol_cstr("+", &tmp));
        return cons(tmp, NIL, ret);
}

@ @<Object constructors for reader tests@>=
error_code
llt_Reader__build_xyz (cell *ret)
{
        cell tmp, x, y, z;
        error_code reason;

        orreturn(new_symbol_cstr("x", &x));
        orreturn(new_symbol_cstr("y", &y));
        orreturn(new_symbol_cstr("z", &z));
        orreturn(cons(z, NIL, &tmp));
        orreturn(cons(y, tmp, &tmp));
        return cons(x, tmp, ret);
}

@ @<Object constructors for reader tests@>=
error_code
llt_Reader__build_list_nested (cell *ret)
{
        cell head, tail;
        error_code reason;
        orreturn(llt_Reader__build_xyz(&head));
        orreturn(llt_Reader__build_xyz(&tail));
        return cons(head, tail, ret);
}

@ @<Object constructors for reader tests@>=
error_code
llt_Reader__build_application (cell *ret)
{
        cell label, tmp;
        error_code reason;
        orreturn(llt_Reader__build_xyz(&tmp));
        orreturn(new_symbol_cstr("lambda", &label));
        orreturn(cons(NIL, tmp, &tmp));
        return cons(label, tmp, ret);
}

@* Closure tests.

@(t/closure.c@>=
#include <string.h>
@<Test common preamble@>@;

int
main (int    argc,
      char **argv)
{@+
        return llt_main(argc, argv, true);@+
}

typedef struct {
        LLT_FIXTURE_HEADER@;

        error_code (*build)(cell *);
        half  interpret_limit;
        char *csource;
        cell  lsource, ssource;
        cell  want;
} llt_fixture;

int Test_Fixture_Size = sizeof (llt_fixture);

error_code llt_Closure__Simple (llt_header *, int *, bool, llt_header **);
@#
int llt_Closure__prepare (llt_header *);
int llt_Closure__run (llt_header *);
int llt_Closure__validate (llt_header *);
int llt_Closure__clean (llt_header *);
@#
@<Object constructors for closure tests@>@;

@ @(t/closure.c@>=
struct {
        char        *source;
        error_code (*build)(cell *);
} LLT_Closure_Rules[] = {@|
        { "(lambda ())",        llt_Closure__build_ },@|
        { "(lambda x)",         llt_Closure__build__x },@|
        { "(lambda (x))",       llt_Closure__build_x },@|
        { "(lambda (x y))",     llt_Closure__build_xy },@|
        { "(lambda (x y . z))", llt_Closure__build_xy_z },@|
        { NULL, NULL }
};

llt_initialise Test_Suite[] = {
        llt_Closure__Simple,
        NULL
};

@ @(t/closure.c@>=
int
llt_Closure__prepare (llt_header *th)
{
        llt_fixture *tc = (llt_fixture *) th;
        address fin;
        cell label, jexit;
        int length;
        error_code reason;

        ortrap(tc->build(&tc->want));
        length = strlen(tc->csource);
        orreturn(new_segment(length, 0, &tc->ssource));
        memmove(segment_base(tc->ssource), tc->csource, length);
@#
        ortrap(new_symbol_const(PROGRAM_EXIT, &label));
        ortrap(vm_locate_entry(label, &fin));
        ortrap(new_pointer(fin, &jexit));
        ortrap(stack_array_push(&Control_Link, jexit));
        General[0] = tc->ssource;
        General[1] = fix(0);
        ortrap(new_symbol_const(PROGRAM_READ, &label));
        ortrap(vm_locate_entry(label, &Ip));
        Interpret_Count = Interpret_Limit = 0;
        ortrap(interpret());
        General[0] = General[1] = NIL;
        tc->lsource = Accumulator;
@#
        Interpret_Count = 0;
        Interpret_Limit = tc->interpret_limit;
        ortrap(stack_array_push(&Control_Link, jexit));
        ortrap(new_symbol_const(PROGRAM_EVALUATE, &label));
        ortrap(vm_locate_entry(label, &Ip));
        Expression = tc->lsource;
        return LLT_RUN_CONTINUE;
Trap:
        return LLT_RUN_FAIL;
}

@ @(t/closure.c@>=
int
llt_Closure__run (llt_header *th)
{
        llt_fixture *tc = (llt_fixture *) th;
        tc->reason = interpret();
        return LLT_RUN_CONTINUE;
}

@ @(t/closure.c@>=
int
llt_Closure__validate (llt_header *th)
{
        llt_fixture *tc = (llt_fixture *) th;

        tap_ok(th, "success", !failure_p(tc->reason), fix(tc->reason));
        tap_ok(th, "correct result",
                llt_out_match_p(Accumulator, tc->want), Accumulator);
        return LLT_RUN_CONTINUE;
}

@ @(t/closure.c@>=
int
llt_Closure__clean (llt_header *th @[unused@])
{
        return LLT_RUN_CONTINUE;
}

@ @(t/closure.c@>=
error_code
llt_Closure__Simple (llt_header  *suite,
                    int         *count,
                    bool         full @[unused@],
                    llt_header **ret)
{
        llt_fixture *tc;
        llt_header *th;
        error_code reason;
        int i, rules;

        for (rules = 0; LLT_Closure_Rules[rules].source; rules++)
                ;
        orreturn(llt_fixture_grow(suite, *count, rules));
        tc = (llt_fixture *) suite;
        for (i = 0; i < rules; i++) {
                tc = ((llt_fixture *) suite) + *count + i;
                th = (llt_header *) tc;
                llt_fixture__init_common(th, *count + i,
                        llt_Closure__prepare,
                        llt_Closure__run,
                        llt_Closure__validate,
                        llt_Closure__clean);
                orreturn(llt_sprintf(th, &tc->name, "construct closure `%s'",
                        LLT_Closure_Rules[i].source));
                tc->build = LLT_Closure_Rules[i].build;
                tc->csource = LLT_Closure_Rules[i].source;
                tc->taps = 2;
                tc->want = tc->lsource = tc->ssource = NIL;
                tc->interpret_limit = 2048;
        }
        (*count) += rules;
        *ret = suite;
        return LERR_NONE;
}

@ These build a closure to compare with the one built by the test.

@<Object constructors for closure tests@>=
error_code
llt_Closure__build_ (cell *ret)
{       /* \.{(lambda ())} remains \.{()}. */
        return new_closure(NIL, NIL, ret);
}

@ @<Object constructors for closure tests@>=
error_code
llt_Closure__build__x (cell *ret)
{       /* \.{(lambda x)} becomes \.{((x eval-list))}. */
        cell leval, sign, tmp, x;
        error_code reason;

        orreturn(new_symbol_const("eval-list", &leval));
        orreturn(new_symbol_const("x", &x));
        orreturn(cons(leval, NIL, &tmp));
        orreturn(cons(x, tmp, &tmp));
        orreturn(cons(tmp, NIL, &sign));
        return new_closure(sign, NIL, ret);
}

@ @<Object constructors for closure tests@>=
error_code
llt_Closure__build_x (cell *ret)
{       /* \.{(lambda (x))} becomes \.{((x eval))}. */
        cell eval, tmp, sign, x;
        error_code reason;

        orreturn(new_symbol_const("eval", &eval));
        orreturn(new_symbol_const("x", &x));
        orreturn(cons(eval, NIL, &tmp));
        orreturn(cons(x, tmp, &tmp));
        orreturn(cons(tmp, NIL, &sign));
        return new_closure(sign, NIL, ret);
}

@ @<Object constructors for closure tests@>=
error_code
llt_Closure__build_xy (cell *ret)
{       /* \.{(lambda (x y))} becomes \.{((x eval) (y eval))}. */
        cell eval, sign, x, xtmp, y, ytmp;
        error_code reason;

        orreturn(new_symbol_const("eval", &eval));
        orreturn(new_symbol_const("x", &x));
        orreturn(new_symbol_const("y", &y));
        orreturn(cons(eval, NIL, &eval));
        orreturn(cons(x, eval, &xtmp));
        orreturn(cons(y, eval, &ytmp));
        orreturn(cons(ytmp, NIL, &sign));
        orreturn(cons(xtmp, sign, &sign));
        return new_closure(sign, NIL, ret);
}

@ @<Object constructors for closure tests@>=
error_code
llt_Closure__build_xy_z (cell *ret)
{       /* \.{(lambda (x y . z))} becomes \.{((x eval) (y eval)
                                                (z eval-list))}. */
        cell eval, leval, sign, x, xtmp, y, ytmp, z, ztmp;
        error_code reason;

        orreturn(new_symbol_const("eval", &eval));
        orreturn(new_symbol_const("eval-list", &leval));
        orreturn(new_symbol_const("x", &x));
        orreturn(new_symbol_const("y", &y));
        orreturn(new_symbol_const("z", &z));
        orreturn(cons(eval, NIL, &eval));
        orreturn(cons(leval, NIL, &leval));
        orreturn(cons(x, eval, &xtmp));
        orreturn(cons(y, eval, &ytmp));
        orreturn(cons(z, leval, &ztmp));
        orreturn(cons(ztmp, NIL, &sign));
        orreturn(cons(ytmp, sign, &sign));
        orreturn(cons(xtmp, sign, &sign));
        return new_closure(sign, NIL, ret);
}

@** Index. And some remaining bits \AM\ pieces.

@d PROGRAM_EVALUATE "!Evaluate"
@d PROGRAM_EXIT     "!Exit"
@d PROGRAM_READ     "!Primitive/read-expression"
@d LLT_LOOKUP_MISSING "absent-binding"
@d LLT_LOOKUP_PRESENT "existing-binding"
@d LLT_LOOKUP_CORRECT "polo!"
@d LLT_LOOKUP_STALE   "marco"

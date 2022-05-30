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

@s assert return
@s new normal
@s sigjmp_buf void
@s siglongjmp return
%
@s int32_t int
@s int64_t int
@s intmax_t int
@s intptr_t int
@s uint32_t int
@s uint64_t int
@s uintptr_t int
%
@s line none
%
@s EditLine int
@s HistEvent int
@s History int

@** REPL. Uses editline to read lines and concatente them into a
rope which \Ls/ parses and evaluates.

@<REPL preamble@>=
#include <assert.h>
#include <limits.h>
#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdarg.h>
#include <stdlib.h>
#include <setjmp.h>
@#
#include <stdio.h>
@#
#include "lossless.h"
@#
#include <histedit.h>
@#
#include "barbaroi.h"
#include "repl.h"

@ @(repl.h@>=
@h
@<Function declarations@>@;
@<External symbols@>@;

@ @c
@<REPL preamble@>@;
@<Global variables@>@;

@ @<Fun...@>=
int main (int, char **);
char * prompt (EditLine *);

@ Arbitrary history size limit can be made dynamic later.

@d HISTORY_SIZE 1000
@<Global...@>=
EditLine *E;
History *H;

@ Extern for want of anything to put there yet.

@<Extern...@>=
extern EditLine *E;
extern History *H;

@ The main application --- initialise editline \AM\ \Ls/ and process
a line at a time.

@c
int
main (int    argc,
      char **argv)
{
        HistEvent event;
        int i, length;
        char *line = NULL;
        const wchar_t *wline;
        bool pending = false, valid;
        cell x;
        sigjmp_buf cleanup;
        Verror reason = LERR_NONE;

        @<Initialise editline@>@;
        mem_init(); /* Initialise \Ls/. */

        if (failure_p(reason = sigsetjmp(cleanup, 1))) goto die;

        Root = env_empty(&cleanup);
        for (i = 0; i < PRIMITIVE_LENGTH; i++) {
                x = symbol_new_const(Iprimitive[i].schema + PRIMITIVE_PREFIX);
                x = Iprimitive[i].box = atom(Theap, fix(i), x, FORM_PRIMITIVE, &cleanup);
                env_define_m(Root, primitive_label(x), x, &cleanup);
        }
        Environment = env_extend(Root, &cleanup);

        lprint("Initialising...\n%s\n", INITIALISE);
        stack_push(NIL, &cleanup);
#if 1
        SS(0, x = rope_new_buffer(false, false, INITIALISE,
                sizeof (INITIALISE) - 1, &cleanup));
        SS(0, x = lex_rope(SO(0), &cleanup));
        valid = true;
        SS(0, x = parse(SO(0), &valid, &cleanup));
        assert(valid);
        evaluate_program(SO(0), &cleanup);
#endif
        ACC = VOID;

stack_push(NIL, &cleanup);
        do {
                @<Read and dispatch a line@>
        }@; while (length);

        if (H != NULL)
                history_end(H);
        el_end(E);
}

@ @<Init...@>=
E = el_init(argv[0], stdin, stdout, stderr);
el_set(E, EL_PROMPT, &prompt);
el_set(E, EL_EDITOR, "emacs"); /* TODO: use environment. */
@#
H = history_init();
if ((H = history_init()) == NULL)
        fprintf(stderr, "WARNING: could not initialise history\n");
else {
        history(H, &event, H_SETSIZE, HISTORY_SIZE);
        el_set(E, EL_HIST, history, H);
}

@ Ugly but functional.

@<Read and dispatch a line@>=
wline = el_wgets(E, &length);
if (line != NULL)
        free(line);
line = malloc(length * 2);
assert(line != NULL);
wcsrtombs(line, &wline, length * 2, NULL);

if (failure_p(reason = sigsetjmp(cleanup, 1))) {
        switch (reason) {
        case LERR_UNCLOSED_OPEN:
                pending = true;
                break;
        default: die:
                fprintf(stderr, "FATAL %u: %s.\n",
                        reason, Ierror[reason].message);
                if (reason == LERR_USER) {
                        serial(ACC, SERIAL_DETAIL, 12, NIL, NULL, NULL);
                        lprint("\n");
                }
                abort();
        }
}
if (length > 0) {
        if (H != NULL)
                history(H, &event, H_ENTER, line);
        SS(0, x = rope_new_buffer(false, false, line, length, &cleanup));
        if (pending) {
        serial(User_Register, SERIAL_DETAIL, 4, NIL, NULL, &cleanup);
                SS(0, x = cons(SO(0), NIL, &cleanup));
                SS(0, x = cons(User_Register, x, &cleanup));
                SS(0, x = cons(symbol_new_const("rope/append"), x, &cleanup));
                evaluate_program(SO(0), &cleanup);
                SS(0, x = ACC);
#if 0
                cons("rope/append", USERREG, x ...
                SS(0, x = rope_append(User_Register, x,  &cleanup));
#endif
        }
        User_Register = x;
        x = lex_rope(x, &cleanup);
        SS(0, x);
        valid = true;
        x = parse(SO(0), &valid, &cleanup);
        if (valid) {
                ACC = VOID;
                evaluate_program(x, &cleanup);
                User_Register = NIL;
                pending = false;
        } else if (pair_p(lcdr(x)) && fix_value(lcar(lcar(lcdr(x)))) == LERR_SYNTAX &&@|
                    pair_p(lcdr(lcdr(x))) &&
                    fix_value(lcar(lcar(lcdr(lcdr(x))))) == LERR_UNCLOSED_OPEN &&
                    null_p(lcdr(lcdr(lcdr(x))))) {
                pending = true;
        } else {
                SS(0, x = lcdr(x));
                while (pair_p(x)) {
                        printf("  %d %s == ", fix_value(lcar(lcar(x))),
                                Ierror[fix_value(lcar(lcar(x)))].message);
                        serial(lcar(x), SERIAL_DETAIL, 4, NIL, NULL, &cleanup);
                        printf("\n");
                        SS(0, x = lcdr(x));
                }
                printf("\n");
                User_Register = NIL;
                pending = false;
        }
        printf("DONE ");
        serial(Accumulator, SERIAL_DETAIL, 12, NIL, NULL, &cleanup);
        printf("\n");
} else
        printf("\n");

@ @c
char *
prompt (EditLine *e @[Lunused@]) {
        return "OK ";
}

@** Index.

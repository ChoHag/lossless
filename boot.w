% Sorry human reader but first we need the preamble from lossless.w

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
\def\xor{\ooalign{$\hfil\ /\mkern0mu\ \hfil$\crcr$\ \leftrightarrow\ $}}

@** Initialising \Ls/.

@ @(boot.h@>=
@h
@<Function declarations@>@;
@<External symbols@>@;

@ @c
#include <err.h>
#include <fcntl.h>
#include <stdio.h>
@#
#include "lossless.h"
@<Global variables@>@;

@ @c
int
usage (int rv)
{
        printf("Nope.\n");
        return rv;
}

int
main (int    argc,
      char **argv)
{
        int ifd;
        address link;
        cell ass, entry, lfd, prog;
        error_code reason;

#ifdef GNU_IS_A_STEAMING_PILE
        if (argc != 2)
                return usage(1);
        ifd = open(argv[1], O_RDONLY | O_CLOEXEC);
        if (ifd == -1) {
                warn("open: %s", argv[1]);
                return usage(1);
        }
#else
        ifd = open("evaluate.la", O_RDONLY | O_CLOEXEC);
#endif

        mem_init();
        ortrap(env_root_init());
        ortrap(new_file_handle(ifd, &lfd));
        ortrap(new_assembly_file_handle(lfd, &ass));
        printf("Loaded.\n");
        ortrap(install_assembly(ass, &prog));

        ortrap(new_symbol_const("!Begin", &entry));
        ortrap(hashtable_search(Program_Export_Table, symbol_key(entry),
                env_match, (void *) entry, &entry));
        ortrap(int_value(ldex(entry), &link));
        Ip = Program_Export_Base[link];

        ortrap(new_symbol_const("pair?", &Expression));
        interpret();
        printf("ACC %p\n", Accumulator);

        return 42;

Trap:
        err(1, "bugger %u", reason);
}

@ @<Fun...@>=
@ @<Extern...@>=
@ @<Global...@>=

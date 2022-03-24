#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#undef form /* |form| is defined by perl as shorthand for |Perl_form|. */

#include "lossless.h"

#define llcatch(INSTR) do {                                                     \
        Verror reason;                                                          \
        sigjmp_buf catch;                                                       \
                                                                                \
        if (failure_p(reason = sigsetjmp(catch, 1)))                            \
                croak("Lossless error %d: %s", reason, Ierror[reason].message); \
        (INSTR);                                                                \
} while (0)

#define llassign(EXPR) llcatch(RETVAL = (EXPR))

MODULE = Lossless       PACKAGE = Lossless      PREFIX = lapi_

void mem_init ()

cell lapi_User_Register (cell o)

##
cell lapi_UNDEFINED ()

cell lapi_NIL ()

cell lapi_FALSE ()

cell lapi_TRUE ()

bool lapi_null_p (cell o)

bool lapi_false_p (cell o)

bool lapi_true_p (cell o)

##
bool lapi_pair_p (cell o)

cell lapi_cons (cell nsin, cell ndex, bool share = false)
        CODE:
                llassign(lapi_cons(share, nsin, ndex, &catch));
        OUTPUT: RETVAL

cell lapi_car (cell o)
        CODE:
                llassign(lapi_car(o, &catch));
        OUTPUT: RETVAL

cell lapi_cdr (cell o)
        CODE:
                llassign(lapi_cdr(o, &catch));
        OUTPUT: RETVAL

##
bool lapi_symbol_p (cell o)

cell sym (char *buf)
        CODE:
                llassign(symbol_new_buffer(buf, strlen(buf), &catch));
        OUTPUT: RETVAL

##
cell lapi_Accumulator (cell o)

cell evaluate (cell o)
        CODE:
                llcatch(evaluate(o, &catch));
                RETVAL = Accumulator;
        OUTPUT: RETVAL

##
cell lapi_env_search (cell o, cell e = NIL)
        CODE:
                llassign(env_search(e, o, true, &catch));
        OUTPUT: RETVAL

void lapi_env_define (cell n, cell v, cell e = NIL)
        CODE:
                llcatch(env_define(e, n, v, &catch));

void lapi_env_set (cell n, cell v, cell e = NIL)
        CODE:
                llcatch(env_set(e, n, v, &catch));

void lapi_env_unset (cell n, cell e = NIL)
        CODE:
                llcatch(env_unset(e, n, &catch));

void lapi_env_clear (cell n, cell e = NIL)
        CODE:
                llcatch(env_clear(e, n, &catch));

##
cell rope_new (SV *o, bool thread_sin = false, bool thread_dex = false)
        PREINIT:
                STRLEN length;
                char  *pstr;
                cell   r;
        CODE:
                pstr = SvPVbyte(o, length);
                llassign(rope_new_buffer(thread_sin, thread_dex, pstr,
                        length, &catch));
        OUTPUT: RETVAL

##
cell lex_rope (cell o)
        CODE:
                llassign(lex_rope(o, &catch));
        OUTPUT: RETVAL

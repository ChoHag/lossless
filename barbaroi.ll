(do



(define! (root-environment) REMark (vov ((A vov/args)) ((lambda ()))))

(define! (root-environment) -: REMark) (-: Now we have comments. :-)



(REMark These `comments' are of course real lossless expressions
        (full of things which the parser has reified as symbols)
        so they can't be used in a location where the value will
        be used, such as a function's arguments, but they can be
        anywhere in a sequence of instructions provided they are
        syntactically correct)

(-: Commentary on common variable names and abbreviations:

        Things which come in pairs with no inherent order or
        superiority: YIN & YANG or THIS & THAT.

        A couplet indicating directionality is SIN and DEX when
        which direction is which doesn't matter or LEFT and RIGHT
        when it does, while HITHER and YON suggest location or
        distance.

        One or more things is THAT and THOSE. Two or more are YAN,
        TAN and TETHER.

        On the other hand a LIST is processed in terms of the FIRST,
        NEXT (which used more or less interchangably) & all the
        REST. The list's TAIL may or may not be NIL. A list of
        things is a LIST-OF-THINGS when the plural THINGS is too
        visually similar to a THING.

        ARGS and ENV are used extensively in place of ARGUMENTS and
        ENVIRONMENT and often augmented with a description of
        who's environment or arguments are referred to.

:-)


(-: Grab-bag of various little utilities :-)

(define! (root-environment) quote (vov ((ARGS vov/args)) ARGS))

(define! (root-environment) caar   (lambda (O)           (car (car O))))
(define! (root-environment) cadr   (lambda (O)           (car (cdr O))))
(define! (root-environment) cdar   (lambda (O)           (cdr (car O))))
(define! (root-environment) cddr   (lambda (O)           (cdr (cdr O))))

(define! (root-environment) caaar  (lambda (O)      (car (car (car O)))))
(define! (root-environment) caadr  (lambda (O)      (car (car (cdr O)))))
(define! (root-environment) cadar  (lambda (O)      (car (cdr (car O)))))
(define! (root-environment) caddr  (lambda (O)      (car (cdr (cdr O)))))
(define! (root-environment) cdaar  (lambda (O)      (cdr (car (car O)))))
(define! (root-environment) cdadr  (lambda (O)      (cdr (car (cdr O)))))
(define! (root-environment) cddar  (lambda (O)      (cdr (cdr (car O)))))
(define! (root-environment) cdddr  (lambda (O)      (cdr (cdr (cdr O)))))

(define! (root-environment) caaaar (lambda (O) (car (car (car (car O))))))
(define! (root-environment) caaadr (lambda (O) (car (car (car (cdr O))))))
(define! (root-environment) caadar (lambda (O) (car (car (cdr (car O))))))
(define! (root-environment) caaddr (lambda (O) (car (car (cdr (cdr O))))))
(define! (root-environment) cadaar (lambda (O) (car (cdr (car (car O))))))
(define! (root-environment) cadadr (lambda (O) (car (cdr (car (cdr O))))))
(define! (root-environment) caddar (lambda (O) (car (cdr (cdr (car O))))))
(define! (root-environment) cadddr (lambda (O) (car (cdr (cdr (cdr O))))))
(define! (root-environment) cdaaar (lambda (O) (cdr (car (car (car O))))))
(define! (root-environment) cdaadr (lambda (O) (cdr (car (car (cdr O))))))
(define! (root-environment) cdadar (lambda (O) (cdr (car (cdr (car O))))))
(define! (root-environment) cdaddr (lambda (O) (cdr (car (cdr (cdr O))))))
(define! (root-environment) cddaar (lambda (O) (cdr (cdr (car (car O))))))
(define! (root-environment) cddadr (lambda (O) (cdr (cdr (car (cdr O))))))
(define! (root-environment) cdddar (lambda (O) (cdr (cdr (cdr (car O))))))
(define! (root-environment) cddddr (lambda (O) (cdr (cdr (cdr (cdr O))))))

(define! (root-environment) arity! ((lambda ()
        (define! (current-environment) (-arity!/validate! ARGS)
                (if (null? ARGS)
                        (do)
                        (do     (define! (current-environment) VAL (car ARGS))
                                (define! (current-environment) PREDICATE (cadr ARGS))
                                (if (PREDICATE VAL)
                                        (-arity!/validate! (cddr ARGS))
                                        (eval (list error (quote . arity) PREDICATE VAL))))))
        (lambda ARGS (-arity!/validate! ARGS)))))

(-: Generic list traversal :-)

(define! (root-environment) (list . list) list)

(define! (root-environment) list? ((lambda ()
        (define! (current-environment) -list? (lambda (OBJECT)
                (if (null? OBJECT)
                        #t
                        (if (pair? OBJECT)
                                (-list? (cdr OBJECT))
                                #f))))
        -list?)))

(define! (root-environment) (antifold BUILD FINISH LIST)
        (-: BUILD and FINISH should be a program with two and one
                arguments respectively of any type :-)
        (arity! BUILD so
                FINISH so
                LIST list?)
        (define! (current-environment) (-fold REST FIRST)
                (if (null? (cdr REST))
                        (BUILD (FINISH (car REST)) FIRST)
                        (-fold (cdr REST) (BUILD (car REST) FIRST))))
        (if (null? (cdr LIST))
                (FINISH (car LIST))
                (-fold (cdr LIST) (car LIST))))

(define! (root-environment) (manifold BUILD FINISH LIST)
        (arity! BUILD so
                FINISH so
                LIST list?)
        (define! (current-environment) (-fold FIRST REST)
                (if (null? (cdr REST))
                        (BUILD FIRST (lambda () (FINISH (car REST))))
                        (BUILD FIRST (lambda () (-fold (car REST) (cdr REST))))))
        (if (null? (cdr LIST))
                (FINISH (car LIST))
                (-fold (car LIST) (cdr LIST))))

(define! (root-environment) (back-penfold BUILD LIST)
        (antifold BUILD (lambda (LAST) LAST) LIST))

(define! (root-environment) (back-fold BUILD FIX LIST)
        (antifold BUILD (lambda (LAST) LAST) (cons FIX LIST)))

(define! (root-environment) (foldable BUILD FIX LIST)
        (manifold BUILD (lambda (LAST) (BUILD LAST (lambda () FIX))) LIST))

((lambda ()
        (define! (current-environment) (-fold/continue BUILD)
                (lambda (NEXT CONTINUE) (BUILD NEXT (CONTINUE))))

        (define! (root-environment) (penfold BUILD LIST)
                (manifold (-fold/continue BUILD) (lambda (LAST) LAST) LIST))

        (define! (root-environment) (fold BUILD FIX LIST)
                (foldable (-fold/continue BUILD) FIX LIST))))


(define! (root-environment) (map FN LIST)
        (arity! FN so
                LIST list?)
        (back-fold (lambda (NEXT REST) (cons (FN NEXT) REST)) () LIST))

(define! (root-environment) (filter PREDICATE LIST)
        (arity! PREDICATE so
                LIST list?)
        (fold (lambda (THIS THAT) (if (PREDICATE THIS) (cons THIS THAT) THAT))
                () LIST))



(-: ::::: :-)



(-: List construction and application :-)

(define! (root-environment) (append . LIST-OF-LISTS)
        (define! (current-environment) (next FIRST REST)
                (if (null? REST)
                        FIRST
                        (fold cons (next (car REST) (cdr REST)) FIRST)))
        (if (null? LIST-OF-LISTS)
                ()
                (next (car LIST-OF-LISTS) (cdr LIST-OF-LISTS))))

(define! (root-environment) apply ((lambda ()
        (define! (current-environment) (-apply/qcons THAT THOSE)
                (cons (cons quote THAT) THOSE))
        (lambda (PROGRAM . ARGS)
                (eval (cons (quote . PROGRAM)
                        (manifold
                                -apply/qcons
                                (lambda (LAST) (fold -apply/qcons () LAST))
                                ARGS)))))))



(-: Boolean logic operators :-)

(define! (root-environment) and ((lambda ()
        (define! (current-environment) -and (vov ((ARGS vov/args) (ENV vov/env))
                (arity! ARGS list?)
                (if (null? ARGS)
                        #t
                        (do     (define! (current-environment) VAL
                                        (eval (car ARGS) ENV))
                                (if VAL (if (null? (cdr ARGS))
                                                VAL
                                                (eval (cons -and (cdr ARGS)) ENV))
                                        #f)))))
        -and)))

(define! (root-environment) or ((lambda ()
        (define! (current-environment) -or (vov ((ARGS vov/args) (ENV vov/env))
                (arity! ARGS list?)
                (if (null? ARGS)
                        #f
                        (do     (define! (current-environment) VAL
                                        (eval (car ARGS) ENV))
                                (if VAL VAL
                                        (eval (cons -or (cdr ARGS)) ENV))))))
        -or)))

(define! (root-environment) (not OBJECT) (if OBJECT #f #t))

(define! (root-environment) (so OBJECT) (if OBJECT #t #f))



(-: Let there be let :-)

(-: TODO: Named let doesn't check whether one of the formals is NAME :-)

(define! (root-environment) let ((lambda ()
        (define! (current-environment) (-let/unwrap-bindings BINDINGS)
                (if (null? BINDINGS)
                        (cons ()())
                        (do     (define! (current-environment) NEXT
                                        (-let/unwrap-bindings (cdr BINDINGS)))
                                (cons   (cons (caar BINDINGS) (car NEXT))
                                        (cons (cadar BINDINGS) (cdr NEXT))))))
        (vov ((ARGS vov/args) (ENV vov/env))
                (define! (current-environment) (-let/build FORMALS BODY ENV)
                        (eval (append (list lambda FORMALS) BODY) ENV))
                (define! (current-environment) (-let/named NAME BINDINGS . BODY)
                        (define! (current-environment) SPLIT (-let/unwrap-bindings BINDINGS))
                        (define! (current-environment) EVAL-ENV (environment/extend ENV))
                        (define! (current-environment) -LET (-let/build (car SPLIT) BODY EVAL-ENV))
                        (eval (list define! EVAL-ENV NAME -LET))
                        (eval (cons -LET (cdr SPLIT)) EVAL-ENV))
                (define! (current-environment) (-let BINDINGS . BODY)
                        (define! (current-environment) SPLIT (-let/unwrap-bindings BINDINGS))
                        (eval (cons (-let/build (car SPLIT) BODY ENV) (cdr SPLIT)) ENV))
                (if (symbol? (car ARGS))
                        (apply -let/named ARGS)
                        (apply -let ARGS))))))



(-: A (small...) collection of complex predicates :-)

(define! (root-environment) (anti PREDICATE)
        (lambda (OBJECT)
                (not (PREDICATE OBJECT))))

(define! (root-environment) (maybe PREDICATE)
        (lambda (OBJECT)
                (or (null? OBJECT) (PREDICATE OBJECT))))

(define! (root-environment) truth? (anti false?))

(-: However that's needlessly complicated so use this equivalent instead :-)
(set! (root-environment) truth? so)

(define! (root-environment) something? (anti null?))


)

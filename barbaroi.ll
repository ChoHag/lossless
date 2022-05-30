(do



(define! (root-environment) REMark (vov ((E vov/env)) (do)))

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



(-: Essential pair, list and other core operators :-)

(define! (root-environment) (snoc a b) (cons b a)) (-: Mirror cons :-)

(define! (root-environment) (caar O)             (car (car O)))
(define! (root-environment) (cadr O)             (car (cdr O)))
(define! (root-environment) (cdar O)             (cdr (car O)))
(define! (root-environment) (cddr O)             (cdr (cdr O)))

(define! (root-environment) (caaar O)       (car (car (car O))))
(define! (root-environment) (caadr O)       (car (car (cdr O))))
(define! (root-environment) (cadar O)       (car (cdr (car O))))
(define! (root-environment) (caddr O)       (car (cdr (cdr O))))
(define! (root-environment) (cdaar O)       (cdr (car (car O))))
(define! (root-environment) (cdadr O)       (cdr (car (cdr O))))
(define! (root-environment) (cddar O)       (cdr (cdr (car O))))
(define! (root-environment) (cdddr O)       (cdr (cdr (cdr O))))

(define! (root-environment) (caaaar O) (car (car (car (car O)))))
(define! (root-environment) (caaadr O) (car (car (car (cdr O)))))
(define! (root-environment) (caadar O) (car (car (cdr (car O)))))
(define! (root-environment) (caaddr O) (car (car (cdr (cdr O)))))
(define! (root-environment) (cadaar O) (car (cdr (car (car O)))))
(define! (root-environment) (cadadr O) (car (cdr (car (cdr O)))))
(define! (root-environment) (caddar O) (car (cdr (cdr (car O)))))
(define! (root-environment) (cadddr O) (car (cdr (cdr (cdr O)))))
(define! (root-environment) (cdaaar O) (cdr (car (car (car O)))))
(define! (root-environment) (cdaadr O) (cdr (car (car (cdr O)))))
(define! (root-environment) (cdadar O) (cdr (car (cdr (car O)))))
(define! (root-environment) (cdaddr O) (cdr (car (cdr (cdr O)))))
(define! (root-environment) (cddaar O) (cdr (cdr (car (car O)))))
(define! (root-environment) (cddadr O) (cdr (cdr (car (cdr O)))))
(define! (root-environment) (cdddar O) (cdr (cdr (cdr (car O)))))
(define! (root-environment) (cddddr O) (cdr (cdr (cdr (cdr O)))))

(define! (root-environment) (list . LIST) LIST)

(define! (root-environment) list? ((lambda ()
        (define! (current-environment) -list? (lambda (OBJECT)
                (if (null? OBJECT)
                        #t
                        (if (pair? OBJECT)
                                (-list? (cdr OBJECT))
                                #f))))
        -list?)))

(-: Having to type (current-environment) everywhere is tiresome and
        ugly, these implement (define-here! LABEL VALUE) and its
        mutating analogue set-here! to save on keyboard wear :-)

(define! (root-environment) define-here! (vov ((ARGS vov/args) (ENV vov/env))
        (eval (cons define! (cons (list current-environment) ARGS)) ENV)))
(define! (root-environment) set-here! (vov ((ARGS vov/args) (ENV vov/env))
        (eval (cons set! (cons (list current-environment) ARGS)) ENV)))

(define! (root-environment) (not OBJECT) (if OBJECT #f #t))
(define! (root-environment) (so OBJECT) (if OBJECT #t #f))
(define! (root-environment) (defined? OBJECT) (not (void? OBJECT)))

(-: Compound predicates :-)

(define! (root-environment) (anti PREDICATE)
        (lambda (OBJECT)
                (not (PREDICATE OBJECT))))
(define! (root-environment) (maybe PREDICATE)
        (lambda (OBJECT)
                (or (null? OBJECT) (PREDICATE OBJECT))))

(-: Rudimentary signature validation/type assertion :-)

(define! (root-environment) signature/assert! ((lambda ()
        (define-here! (-signature/assert/validate! ARGS)
                (if (null? ARGS)
                        (do)
                        (do     (define-here! VAL (car ARGS))
                                (define-here! PREDICATE (cadr ARGS))
                                (if (PREDICATE VAL)
                                        (-signature/assert/validate! (cddr ARGS))
                                        (eval (list error 'arity PREDICATE VAL))))))
        (lambda ARGS (-signature/assert/validate! ARGS)))))



(-: Let there be let :-)

((lambda ()
        (-: Separate a list of binding pairs ((a b) (c d) etc.) into two
                lists of the labels (a c) and values (b d) :-)
        (define-here! (-let/unwrap-bindings BINDINGS)
                (if (null? BINDINGS)
                        (cons ()())
                        (do     (define-here! NEXT
                                        (-let/unwrap-bindings (cdr BINDINGS)))
                                (cons   (cons (caar BINDINGS) (car NEXT))
                                        (cons (cadar BINDINGS) (cdr NEXT))))))

        (-: An instance of named let extends the caller's environment
                and evaluates the constructed lambda expression in
                that --- this is the environment which will be
                closed over.

            The new program is bound to the desired name in that
                extended environment to make it available within
                the closure's scope. The program and its arguments
                are then evaluated in the caller's environment so
                that arguments referring to the same symbol as the
                let expression's name will be evaluated correctly.

            :-)

        (define-here! (-let/named LAMBDA NAME BINDINGS BODY CALLER-ENV)
                (define-here! FORMALS (car BINDINGS))
                (define-here! RUNNER-ENV (environment/extend CALLER-ENV))
                (define-here! SELF
                        (eval (cons LAMBDA (cons FORMALS BODY)) RUNNER-ENV))
                (eval (list define! RUNNER-ENV NAME SELF))
                (eval (cons SELF (cdr BINDINGS)) CALLER-ENV))

        (-: Plain let constructs a lambda expression and evaluates
                it with the arguments extracted from the let bindings
                in the caller's environment :-)

        (define-here! (-let/plain LAMBDA BINDINGS BODY CALLER-ENV)
                (define-here! FORMALS (car BINDINGS))
                (eval   (cons   (cons   LAMBDA
                                        (cons FORMALS BODY))
                                (cdr BINDINGS))
                        CALLER-ENV))

        (-: Validating variants of let are made possible using the
                validating lambda operators which are defined below;
                this program returns a new let-like operator :-)

        (define-here! (-let LAMBDA) (vov ((CALLER-ARGS vov/args) (CALLER-ENV vov/env))
                (signature/assert! CALLER-ARGS pair?)
                (if (symbol? (car CALLER-ARGS))
                        (do     (signature/assert!
                                        (cdr CALLER-ARGS) pair?
                                        (cadr CALLER-ARGS) list?)
                                (-let/named LAMBDA (car CALLER-ARGS)
                                        (-let/unwrap-bindings (cadr CALLER-ARGS))
                                        (cddr CALLER-ARGS)
                                        CALLER-ENV))
                        (do     (signature/assert! CALLER-ARGS list?)
                                (-let/plain LAMBDA
                                        (-let/unwrap-bindings (car CALLER-ARGS))
                                        (cdr CALLER-ARGS)
                                        CALLER-ENV)))))

        (-: This is all that we need for the plain let syntax, using
                plain lambda :-)

        (define! (root-environment) let (-let lambda))

        (do (-: When literate lossless comes along this section should
                be moved elsewhere :-)

                (-: The advanced lambda/let forms, and Lossless generally,
                        require programs for iterating over lists :-)

                (-: Also known fold-right and similar names the most common iteration :-)
                (define-here! (-walk FIX LIST EACH LAST)
                        (-: FIX is unused --- it's for signature compatibility
                                with klaw, below :-)
                        (if (pair? (cdr LIST))
                                (EACH (car LIST) (-walk FIX (cdr LIST) EACH LAST))
                                (LAST (car LIST) (cdr LIST))))

                (define-here! (-klaw FIX LIST EACH LAST)
                        (if (pair? (cdr LIST))
                                (-klaw (EACH FIX (car LIST)) (cdr LIST) EACH LAST)
                                (let ((TAIL (LAST FIX (car LIST))))
                                        (cons TAIL (cdr LIST)))))

                (define-here! (-walklaw DIRECTION CONTAINER EACH LAST FIX)
                        (if (null? EACH)
                                (set! (current-environment) EACH cons))
                        (if (null? LAST)
                                (set! (current-environment) LAST cons))
                        (-: signature/assert! (-: TODO: There is no (program?) predicate yet :-)
                                EACH    program?
                                LAST    program?
                                CONTAINER
                                        (maybe pair?))
                        (if (null? CONTAINER)
                                ()
                                (DIRECTION FIX CONTAINER EACH LAST)))

                (define! (root-environment) (walk/alt EACH LAST CONTAINER)
                        (-walklaw -walk CONTAINER EACH LAST ()))
                (define! (root-environment) (walk EACH CONTAINER)
                        (-walklaw -walk CONTAINER EACH EACH ()))
                (define! (root-environment) (klaw/alt EACH LAST FIX CONTAINER)
                        (-walklaw -klaw CONTAINER EACH LAST FIX))
                (define! (root-environment) (klaw EACH FIX CONTAINER)
                        (-walklaw -klaw CONTAINER EACH EACH FIX))

                (-: These are the two list iterators we especially needed :-)

                (define-here! (-append LIST)
                        (walk/alt
                                cons
                                (lambda (LAST NIL)
                                        (signature/assert! LAST list?)
                                        LAST)
                                LIST))

                (define! (root-environment) (append . LIST) (-append LIST))
                (define! (root-environment) (apply PROGRAM . LIST)
                        (-: This is nasty... :-)
                        (eval (cons PROGRAM
                                (walk   (lambda (NEXT REST)
                                                (cons (cons quote NEXT) REST))
                                        (-append LIST)))))

                (-: Also define here other common iterators :-)

                (define! (root-environment) (map PROGRAM LIST)
                        (signature/assert! LIST list?)
                        (walk (lambda (NEXT REST) (cons (PROGRAM NEXT) REST)) LIST))

                (define! (root-environment) (for-each PROGRAM LIST)
                        (signature/assert! LIST list?)
                        (klaw (lambda (FIX NEXT) (PROGRAM NEXT)) () LIST))

                (define! (root-environment) (reverse LIST)
                        (signature/assert! LIST list?)
                        (car (klaw snoc () LIST))))

        (-: vov is the most general operative constructor but rather
                unweildy for everyday use. It was inspired by John
                Shutt's vau so that's the face of the human-friendly
                constructor: (vau (BINDINGS) ENVIRONMENT BODY) :-)

        (define! (root-environment) vau (vov
                ((AUTHOR-ARGS vov/args) (AUTHOR-ENV vov/env))
                (apply (lambda (FORMAL-ARGS FORMAL-ENV . BODY)
                        (eval   (list   vov
                                        (list   '(CALLER-ARGS vov/arguments)
                                                (list FORMAL-ENV
                                                        'vov/environment))
                                        (list   apply
                                                (cons lambda
                                                        (cons FORMAL-ARGS BODY))
                                                'CALLER-ARGS))
                                AUTHOR-ENV)
                        ) AUTHOR-ARGS)))

        (-: Used to scan the formals for any which are a list (of
                two); those which are not are combined with the
                defined? predicate :-)

        (define-here! (-lambda/validating/expand-formal FORMAL)
                (if (pair? FORMAL)
                        (apply cons FORMAL)
                        (cons FORMAL defined?)))

        (-: Build an expression which will validate bound values :-)

        (define-here! (-lambda/validating/build-validator SIGNATURE)
                (cons signature/assert! (walk
                        (lambda (NEXT REST)
                                (cons (car NEXT) (cons (cdr NEXT) REST)))
                        SIGNATURE)))

        (-: Construct a program which validates its arguments :-)

        (define-here! (-lambda/validating LAMBDA FORMALS BODY CREATOR)
                (signature/assert! FORMALS list?)
                (if (null? FORMALS)
                        (eval (cons LAMBDA (cons () BODY)) CREATOR)
                        (do     (define-here! SIGNATURE
                                        (map -lambda/validating/expand-formal FORMALS))
                                (define-here! VALIDATOR
                                        (-lambda/validating/build-validator SIGNATURE))
                                (eval   (cons   LAMBDA
                                                (cons   (map car SIGNATURE)
                                                        (cons VALIDATOR BODY)))
                                        CREATOR))))

        (-: Construct a program which validates its return value :-)

        (define-here! (-lambda/validated LAMBDA FORMALS PREDICATE BODY CREATOR)
                (set! (current-environment) PREDICATE (eval PREDICATE CREATOR))
                (-: signature/assert! PREDICATE predicate?)
                (let ((IMP (eval (cons lambda (cons FORMALS BODY)) CREATOR)))
                        (LAMBDA ARGUMENTS
                                (let ((VALUE (apply IMP ARGUMENTS)))
                                        (signature/assert! VALUE PREDICATE)
                                        VALUE))))

        (-: Construct lambda and matching let forms for programs
                which validate their arguments (validating), return
                value (validated) or both (signed) :-)

        (define! (root-environment) lambda/validating
                (vau (FORMALS . BODY) CREATOR
                        (-lambda/validating lambda
                                FORMALS BODY CREATOR)))
        (define! (root-environment) let/validating (-let lambda/validating))

        (define! (root-environment) lambda/validated
                (vau (FORMALS PREDICATE . BODY) CREATOR
                        (-lambda/validated lambda
                                FORMALS PREDICATE BODY CREATOR)))
        (define! (root-environment) let/validated (-let lambda/validated))

        (define! (root-environment) lambda/signed
                (vau (FORMALS PREDICATE . BODY) CREATOR
                        (-lambda/validated lambda/validating
                                FORMALS PREDICATE BODY CREATOR)))
        (define! (root-environment) let/signed (-let lambda/signed))

        (-: TODO: decide what to wrt. evaluation and repeat for vau (NOT vov) :-)
        ))



(-: Boolean logic operators :-)

(define! (root-environment) and (let ()
        (define-here! (-and ARGS ENV)
                (if (null? ARGS)
                        #t
                        (let ((VAL (eval (car ARGS) ENV)))
                                (if VAL (if (null? (cdr ARGS))
                                                VAL
                                                (-and (cdr ARGS) ENV))
                                        #f))))
        (vov ((ARGS vov/args) (ENV vov/env))
                (signature/assert! ARGS list?)
                (-and ARGS ENV))))
(define! (root-environment) or (let ()
        (define-here! (-or ARGS ENV)
                (if (null? ARGS)
                        #f
                        (let ((VAL (eval (car ARGS) ENV)))
                                (if VAL VAL (-or (cdr ARGS) ENV)))))
        (vov ((ARGS vov/args) (ENV vov/env))
                (signature/assert! ARGS list?)
                (-or ARGS ENV))))


)

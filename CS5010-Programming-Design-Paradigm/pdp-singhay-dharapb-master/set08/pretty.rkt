;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-intermediate-lambda-reader.ss" "lang")((modname pretty) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f () #f)))
;; pretty.rkt : First question of problem set08

;; GOAL: To print the expressions in a required pretty way. The rules defining
;;       the pretty expressions are as follows:
;;       1.) The expression should be rendered on a single line if it fits 
;;           within the specified width.
;;       2.) Otherwise,the subexpressions should be rendered in a stacked
;;           fashion.
;;       3.) All subexpressions must fit within the space allotted minus the
;;           space for surrounding parentheses, if any.
;;       4.) There should be no spaces preceding a right parenthesis.
;;       5.) The algorithm may determine that the given expression cannot fit
;;           within the allotted space. In this case, the algorithm should raise
;;           an appropriate error, using an appropriate function error.

;; WHERE:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; LIBRARY
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(require rackunit)
(require "extras.rkt")
;(require profile)
;(require profile/analyzer)

(check-location "08" "pretty.rkt")

(provide
 expr-to-strings
 make-sum-exp
 sum-exp-exprs
 make-diff-exp
 diff-exp-exprs)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; CONSTANTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Numerical Constants
(define DEFAULT-ALIGNMENT 3)
(define ERROR "Not enough room")
(define W-EXCLUDING-PARENTHESIS 2)
(define ZERO 0)
(define EMPTY-STRING "")
(define SINGLE-SPACE " ")
(define SUM-OPRTR "+")
(define DIFF-OPRTR "-")
(define OPEN-PAREN "(")
(define CLOSE-PAREN ")")


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; DATA DEFINITIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-struct sum-exp (exprs))
;; A Sum-Exp is a (make-sum-exp NELOExpr)
;; INTERP:
;; NELOExpr     is a non-empty LOExpr.
;; TEMPLATE:
;; sum-exp-fn : Sum-Exp -> ??
#|
(define (sum-exp-fn s)
  (... (sum-exp-exprs s)))
|#

(define-struct diff-exp (exprs))
;; A Diff-Exp is a (make-diff-exp NELOExpr)
;; INTERP:
;; NELOExpr     is a non-empty LOExpr.
;; TEMPLATE:
;; diff-exp-fn : Diff-Exp -> ??
#|
(define (diff-exp-fn d)
  (... (diff-exp-exprs d)))
|#

;; An Expr is one of
;; -- Integer
;; -- (make-sum-exp NELOExpr)
;; -- (make-diff-exp NELOExpr)
;; Interpretation: a sum-exp represents a sum and a diff-exp
;; represents a difference calculation. 
;; TEMPLATE:
;; expr-fn : Expr -> ??
#|
(define (expr-fn lst)
 (cond
  [(integer? lst) ...]
  [(sum-exp? lst) ...]
  [(diff-exp? lst) ...]
  [else (... (e-fn (first lst))
             (expr-fn (rest lst)))]))
|#

;; A LOExpr is one of
;; -- empty
;; -- (cons Expr LOExpr)
;; TEMPLATE:
;; loe-fn : LOExpr -> ??
#|
(define (loe-fn lst)
 (cond
  [(empty? lst) ...]
  [else (... (e-fn (first lst))
             (loe-fn (rest lst)))]))
|#

;; A NELOExpr is a non-empty LOExpr.
;; -- (cons Expr LOExpr)
;; TEMPLATE:
;; ne-loe-fn : NELOExpr -> ??
#|
(define (ne-loe-fn ne-lst)
 (cond
  [(empty? (rest ne-lst)) (... (first ne-lst))]
  [else (... (first ne-lst)
             (ne-loe-fn (rest ne-lst)))]))
|#

;; EXAMPLES:

(define EXAMPLE-1
 (make-sum-exp (list 22 333 44)))

(define EXAMPLE-2
(make-sum-exp
 (list
  (make-diff-exp (list 22 3333 44))
  (make-diff-exp
   (list
    (make-sum-exp (list 66 67 68))
    (make-diff-exp (list 42 43))))
  (make-diff-exp (list 77 88)))))

(define EXAMPLE-3
(make-sum-exp
 (list
  (make-diff-exp (list 22 3333 44))
  (make-diff-exp
   (list
    (make-sum-exp (list 66 67 68))
    (make-diff-exp (list 42 43))))
  (make-diff-exp (list 77 88))
  (make-sum-exp
   (list
    (make-sum-exp (list 56 57 58))
    (make-diff-exp (list 96 97 98)))))))

(define EXAMPLE-4 (make-sum-exp
                      (list
                       (make-diff-exp (list 56 23))
                       987 786 8
                       (make-sum-exp
                        (list
                         (make-diff-exp (list 56)))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; MAIN FUNCTION
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; expr-to-strings : Expr NonNegInt -> ListOfString
;; GIVEN   : An expression and a width
;; RETURNS : A representation of the expression as a sequence of lines, with
;;           each line represented as a string of length not greater than
;;           the width.
;; EXAMPLE : see tests below
;; STRATEGY: Combine Simpler Functions / Call a more general function

(define (expr-to-strings expr width)
  (sub-pretty-str expr width ZERO))

;; TESTS CASES:
(begin-for-test
  (check-error (expr-to-strings EXAMPLE-2 5)
               "Should display the error message")
  (check-equal? (expr-to-strings EXAMPLE-1 13)
                (list "(+ 22 333 44)")
                "Should display the list of string where length of each string
                 is within the given width")
  (check-equal? (expr-to-strings EXAMPLE-2 100)
                (list "(+ (- 22 3333 44) (- (+ 66 67 68) (- 42 43)) (- 77 88))")
                "Should display the list of string where length of each string
                 is within the given width")
  (check-equal? (expr-to-strings EXAMPLE-2 50)
                (list "(+ (- 22 3333 44)"
                      "   (- (+ 66 67 68) (- 42 43))"
                      "   (- 77 88))")
                "Should display the list of string where length of each string
                 is within the given width")
  (check-equal? (expr-to-strings EXAMPLE-2 20)
                (list "(+ (- 22 3333 44)"
                      "   (- (+ 66 67 68)"
                      "      (- 42 43))"
                      "   (- 77 88))")
                "Should display the list of string where length of each string
                 is within the given width")
  (check-equal? (expr-to-strings EXAMPLE-2 13)
                (list "(+ (- 22"
                      "      3333"
                      "      44)"
                      "   (- (+ 66"
                      "         67"
                      "         68)"
                      "      (- 42"
                      "         43))"
                      "   (- 77 88))")
                "Should display the list of string where length of each string
                 is within the given width")
  (check-equal? (expr-to-strings EXAMPLE-3 14)
                (list "(+ (- 22"
                      "      3333"
                      "      44)"
                      "   (- (+ 66"
                      "         67"
                      "         68)"
                      "      (- 42"
                      "         43))"
                      "   (- 77 88)"
                      "   (+ (+ 56"
                      "         57"
                      "         58)"
                      "      (- 96"
                      "         97"
                      "         98)))")
                "Should display the list of string where length of each string
                 is within the given width")
  (check-equal? (expr-to-strings EXAMPLE-4 15)
                (list "(+ (- 56 23)"
                      "   987"
                      "   786"
                      "   8"
                      "   (+ (- 56)))")
                "Should display the list of string where length of each string
                 is within the given width")
  (check-error (expr-to-strings EXAMPLE-4 9)
               "Should return the error message"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; HELPER FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; sub-pretty-str : Expr NonNegInt NonNegInt -> ListOfString
;; GIVEN   : An expression, a width and a drop-level
;; WHERE   : drop-lvl, initially is 0, as increases as per the position of the
;;           expression encountered in the expression list
;; RETURNS : A representation of the expression as a sequence of lines, with
;;           each line represented as a string of length not greater than
;;           the width
;;           OR
;;           an error function if the given width is less than the maximum
;;           length of each of the strings from the list generated from the
;;           expr.
;; EXAMPLE : see tests below
;; STRATEGY: Combine Simpler Functions

(define (sub-pretty-str exp width drop-lvl)
  (if (>= width (max-rqd-width exp))
      (pretty-string exp width drop-lvl)
      (error ERROR)))

;; TESTS:
(begin-for-test
  (check-error
   (sub-pretty-str EXAMPLE-4 9 0)
   "The max length of any of the string is 12 greater than 9, teh given width"))

;; max-rqd-width : Expr -> NonNegInt
;; GIVEN   : An expression
;; RETURNS : The maximum width of the string from all the strings of the given
;;           list of strings excluding the parenthesis.
;; EXAMPLE : see tests below
;; STRATEGY: Use HOF foldr on ListOfString (pretty-string expr 0 0)

(define (max-rqd-width expr)
  (foldr
   (lambda (e rest) (max (string-length e) rest)) 
   ZERO
   (pretty-string expr ZERO ZERO)))

;; TESTS:
(begin-for-test
  (check-equal?
   (max-rqd-width EXAMPLE-4)
   12
   "Should return the max length of the list-of-string of EXAMPLE-4 is 12"))

;; pretty-string : Expr NonNegInt NonNegInt -> ListOfString
;; GIVEN   : An expression and a width
;; RETURNS : A representation of the expression as a sequence of lines, with
;;           each line represented as a string of length not greater than
;;           the width.
;; EXAMPLE : see tests below
;; STRATEGY: Use template of Expr on exp 

(define (pretty-string exp width drop-lvl)
  (cond
    [(integer? exp) (int-to-stack exp drop-lvl)]
    [else (sublist-expr-to-str (expr-operator exp)
                               (expr-exprs exp)
                               (sub-expr-to-str exp width drop-lvl)
                               width
                               drop-lvl)]))

;; TESTS:
(begin-for-test
  (check-equal?
   (pretty-string EXAMPLE-4 12 0)
   '("(+ (- 56 23)" "   987" "   786" "   8" "   (+ (- 56)))")
   "Should return the list of list of strings with the width less than
    or equal to 9 excluding the parenthesis"))

;; int-to-stack : Expr NonNegInt -> ListOfString
;; GIVEN   : An expression and a width
;; RETURNS : A representation of the expression as a sequence of lines, with
;;           each line represented as a string of length not greater than
;;           the width.
;; STRATEGY: Combine Simpler Functions

(define (int-to-stack exp d)
  (list (string-append (reqd-alignment d)
                       (number->string exp))))

;; reqd-alignment : NonNegInt -> String
;; GIVEN   : An expression and a width
;; RETURNS : A string that comprises of the indentation required to align that
;;           level of list if in a stack.
;; EXAMPLE : see tests below
;; STRATEGY: Combine Simpler Functions

(define (reqd-alignment d)
  (align-depth (depthwise-space d)))

;; TESTS:
(begin-for-test
  (check-equal? (reqd-alignment 2)
                "      "
                "Should return 6 spaces"))

;; depthwise-space : NonNegInt -> NonNegInt
;; GIVEN   : A drop-level or depth required for stacking
;; RETURNS : The count of the number of spaces required to indent that
;;           particular level.
;; STRATEGY: Combine Simpler Functions

(define (depthwise-space d)
  (* d DEFAULT-ALIGNMENT))

;; align-depth : NonNegInt -> String
;; GIVEN   : A width
;; RETURNS : The string of spaces required as per the width given.
;; STRATEGY: Combine Simpler Functions

(define (align-depth w)
  (if (> w ZERO)
      (string-append SINGLE-SPACE (align-depth (sub1 w)))
      EMPTY-STRING))

;; expr-operator : Expr -> String
;; GIVEN   : An expression
;; RETURNS : The string representation of the given operator.
;; EXAMPLE : see tests below
;; STRATEGY: Divide into cases on whether given expression is sum or diff

(define (expr-operator exp)
  (if (sum-exp? exp)
      SUM-OPRTR
      DIFF-OPRTR))

;; TESTS:
(begin-for-test
  (check-equal? (expr-operator EXAMPLE-1)
                "+"
                "Should returns string + for sum-exp"))

;; expr-exprs : Expr -> NELOExpr
;; GIVEN   : An expression
;; RETURNS : The non-empty list of the expression of the given operator.
;; EXAMPLE : see tests below
;; STRATEGY: Use template for Expr on expr
;;           + Divide into cases on whether given expression is sum or diff

(define (expr-exprs exp)
  (if (sum-exp? exp)
      (sum-exp-exprs exp)
      (diff-exp-exprs exp)))

;; TESTS:
(begin-for-test
  (check-equal? (expr-exprs EXAMPLE-1)
                (list 22 333 44)
                "Should return the expr-list"))

;; sub-expr-to-str : Expr NonNegInt NonNegInt -> ListOfString
;; GIVEN   : An expression a width and a depth-level
;; RETURNS : A representation of the entire expression in a single line.
;; HALTING MEASURE: ...
;; STRATEGY: Use template of Expr on exp

(define (sub-expr-to-str exp w d)
  (cond
    [(number? exp) (int-to-str exp)]
    [else (oprtr-exp-to-str (expr-operator exp) (expr-exprs exp) w d)]))

;; int-to-str : Expr -> ListOfString
;; GIVEN   : An expression
;; RETURNS : The list of string of the given integer expression.
;; STRATEGY: Combine Simpler Functions

(define (int-to-str exp)
  (list (number->string exp)))

;; oprtr-exp-to-str : String NELOExpr NonNegInt NonNegInt -> ListOfString
;; GIVEN   : An expression and a width
;; RETURNS : The list of string of the given expression in a single line 
;; STRATEGY: Combine Simpler Functions
;;           + Structural decomposition based on first and rest of ne-lst

(define (oprtr-exp-to-str oprtr ne-lst w d)
  (list (string-append OPEN-PAREN
                       oprtr
                       SINGLE-SPACE 
                       (first (sub-expr-to-string
                               (sub-expr-to-str (first ne-lst) w (add1 d))
                               (rest ne-lst)
                               w
                               (add1 d))))))

;; sub-expr-to-string : ListOfString LOExpr NonNegInt NonNegInt -> ListOfString
;; GIVEN   : An expression and a width
;; RETURNS : A representation of the expression as a sequence of lines, with
;;           each line represented as a string of length not greater than
;;           the width.
;; HALTING MEASURE: If rest-list is empty, then lst is the halting measure.
;;                  If rest-list is non-empty, then the function fails to halt.
;; TERMINATION ARGUMENT: if rest-list is empty, the close-the-list appends a
;;                       closing parenthesis and returns that ListOfString.
;; STRATEGY: Divide on cases on the LOExpr, rest-list whether it is empty or not
;;           Recur on (rest rest-list) and modified-first

(define (sub-expr-to-string modified-first rest-list w d)
  (cond
    [(empty? rest-list) (close-the-list modified-first)] 
    [else (sub-expr-to-string (list
                               (string-append (first modified-first)
                                              SINGLE-SPACE
                                              (first (sub-expr-to-str
                                                      (first rest-list)
                                                      w
                                                      d))))
                              (rest rest-list)
                              w
                              d)]))

;; close-the-list : ListOfString -> ListOfString
;; GIVEN   : An expression and a width
;; RETURNS : A representation of the expression as a sequence of lines, with
;;           each line represented as a string of length not greater than
;;           the width.
;; STRATEGY: Combine Simpler Functions

(define (close-the-list ne-lst)
  (reverse (cons (string-append (last ne-lst) CLOSE-PAREN)
                 (all-but-last-inv ne-lst))))

;; last : NonEmptyListOfX -> X
;; GIVEN   : a non-empty list of X
;; WHERE   : X can be any type of input
;; RETURNS : the last element X in the given NonEmptyListOfX
;; EXAMPLE : see tests below
;; STRATEGY: Combining Simpler Functions

(define (last ne-lst)
  (first (reverse ne-lst)))

;; TESTS
(begin-for-test
  (check-equal? (last (list 1 2 3 4))
                4
                "Should return 4")
  (check-equal? (last (list "one" "two" "three"))
                "three"
                "Should return three"))

;; all-but-last-inv : ListOfX -> ListOfX
;; GIVEN   : a list of X
;; WHERE   : X can be any type of input
;; RETURNS : a list of X with the last item truncated from the list
;; EXAMPLE : see tests below
;; STRATEGY: Combining Simpler Functions

(define (all-but-last-inv ne-lst)
  (rest (reverse ne-lst)))

;; TESTS   
(begin-for-test
  (check-equal?
   (all-but-last-inv (list 1 2 3 4))
   (list 3 2 1)
   "Should return the same list without the last element.")
  (check-equal?
   (all-but-last-inv (list "one" "two" "three"))
   (list "two" "one")
   "Should return the same list without the last element."))

;; sublist-expr-to-str :
;;           String NELOExpr ListOfString NonNegInt NonNegInt -> ListOfString
;; GIVEN   : An expression and a width
;; RETURNS : A representation of the expression as a sequence of lines, with
;;           each line represented as a string of length not greater than
;;           the width.
;; STRATEGY: Combine Simpler Functions

(define (sublist-expr-to-str oprtr ne-lst str-expr w d)
  (if (chck-expr-len-to-width? str-expr w)
      (expr-len-less-than-width str-expr d)
      (expr-len-grtr-than-or=-width oprtr ne-lst w d)))

;; TESTS:
(begin-for-test
  (check-equal? (sublist-expr-to-str (expr-operator EXAMPLE-1)
                                     (expr-exprs EXAMPLE-1)
                                     (sub-expr-to-str EXAMPLE-1 13 0)
                                     13
                                     0)
                '("(+ 22 333 44)")
                "Should return what it returns"))

;; chck-expr-len-to-width? : ListOfString NonNegInt -> Boolean
;; GIVEN   : An expression and a width
;; RETURNS : Checks whether the string-length of the single-line representation
;;           of the expression is less than the given width.
;; STRATEGY: Combine Simpler Functions

(define (chck-expr-len-to-width? exp w)
  (< (string-length (first exp)) (add1 w)))

;; expr-len-less-than-width : ListOfString NonNegInt -> ListOfString
;; GIVEN   : An expression and a depth-level
;; RETURNS : A representation of the expression as a string with proper and as
;;           per required indentation.
;; STRATEGY: Combine Simpler Functions

(define (expr-len-less-than-width exp d)
  (list (string-append (reqd-alignment d) (first exp))))

;; expr-len-grtr-than-or=-width :
;;          String NELOExpr NonNegInt NonNegInt -> ListOfString
;; GIVEN   : An expression and a width
;; RETURNS : A representation of the expression as a sequence of lines, with
;;           each line represented as a string of length not greater than
;;           the width.
;; STRATEGY: Combine Simpler Functions
;;           + structural decomposition on NELOExpr based on first and rest list

(define (expr-len-grtr-than-or=-width oprtr ne-lst w d)
  (append (first-expr-stack oprtr (first ne-lst) w d)
          (rest-expr-stack (rest ne-lst) w d)))

;; first-expr-stack : String NELOExpr NonNegInt NonNegInt -> ListOfString
;; GIVEN   : An expression and a width
;; RETURNS : A representation of the expression as a sequence of lines, with
;;           each line represented as a string of length not greater than
;;           the width.
;; STRATEGY: Structural decomposition on NELOExpr based on first and rest list

(define (first-expr-stack oprtr exp w d)
  (cons (string-append
         (reqd-alignment d)
         OPEN-PAREN
         oprtr
         SINGLE-SPACE 
         (first (pretty-string exp (calc-depthwise-width w d) ZERO)))
        (rest (pretty-string exp (calc-depthwise-width w d) (add1 d)))))

;; rest-expr-stack : LOExpr NonNegInt NonNegInt -> ListOfString
;; GIVEN   : An expression and a width
;; RETURNS : A representation of the expression as a sequence of lines, with
;;           each line represented as a string of length not greater than
;;           the width.
;; STRATEGY: Using the template of LOExpr on lst

(define (rest-expr-stack lst w d)
  (cond
    [(empty? lst) empty]
    [else (make-stack lst (calc-depthwise-width w d) (add1 d))]))

;; make-stack : NELOExpr NonNegInt NonNegInt -> ListOfString
;; GIVEN   : An expression and a width
;; RETURNS : A representation of the expression as a sequence of lines, with
;;           each line represented as a string of length not greater than
;;           the width.
;; STRATEGY: Combine Simpler Functions
;;           + Structural decomposition on NELOExpr based on first and rest list

(define (make-stack ne-lst w d)
  (make-sub-stack (pretty-string (first ne-lst) w d)
                  (rest ne-lst)
                  w
                  d))

;; make-sub-stack : ListOfString LOExpr NonNegInt NonNegInt -> ListOfString
;; GIVEN   : An expression and a width
;; RETURNS : A representation of the expression as a sequence of lines, with
;;           each line represented as a string of length not greater than
;;           the width.
;; HALTING MEASURE: If lst is empty, then lst is the halting measure.
;;                  If lst is non-empty, then the function fails to halt.
;; TERMINATION ARGUMENT: if lst is empty, the close-the-list appends a closing
;;                       parenthesis and returns that ListOfString.
;; STRATEGY: Using the template of LOExpr on lst 
;;           + Structural decomposition on NELOExpr based on first and rest list
;;           Recur on (rest lst) and modified exp

(define (make-sub-stack exp lst w d)
  (cond
    [(empty? lst) (close-the-list exp)] 
    [else
     (make-sub-stack (append exp (pretty-string (first lst) w d))
                     (rest lst)
                     w
                     d)]))

;; calc-depthwise-width : NonNegInt NonNegInt -> NonNegInt
;; GIVEN   : A width and a depth
;; RETURNS : A modified width as per the level's indentation and ignoring the
;;           width of parenthesis by subtracting level's indentation and the
;;           width of the two braces from the original width.
;; STRATEGY: Combine Simpler Functions

(define (calc-depthwise-width w d)
  (- w (depthwise-space d) W-EXCLUDING-PARENTHESIS))


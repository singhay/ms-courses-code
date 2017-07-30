;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-intermediate-lambda-reader.ss" "lang")((modname outlines) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f () #f)))
;; outlines.rkt : First 2 questions of problem set07.

;; GOAL: To check for a legal Flat Representation and to represent 
;;       outline in Flat Representation from Tree representation

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; LIBRARY
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(require rackunit)
(require "extras.rkt")

(check-location "07" "outlines.rkt")

(provide
 legal-flat-rep?
 tree-rep-to-flat-rep)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; CONSTANTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define ONE 1)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; DATA DEFINITIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; tree-representation

(define-struct section (heading los))
;; A Section is a (make-section String ListOfSection)
;; INTERP:
;; heading      is the header text of the section
;; los          is the list of subsections of the section
;; TEMPLATE:
;; section-fn : Section -> ??
#|
(define (section-fn s)
  (... (section-heading s)
       (section-los s)))
|#

;; ListOfSection is
;; -- empty
;; -- (cons Section ListOfSection)
;; An Outline is a ListOfSection
;; TEMPLATE:
;; outline-fn : ListOfSection -> ??
#|
(define (outline-fn lst)
 (cond
  [(empty? lst) ...]
  [else (... (section-fn (first lst))
             (outline-fn (rest lst)))]))
|# 
 
;; EXAMPLES:
(define TREE-REP-1
  (list 
   (make-section "The first section"
    (list
     (make-section "A subsection with no subsections" empty)
     (make-section "Another subsection"
      (list
       (make-section "This is a subsection of 1.2" empty)
       (make-section "This is another subsection of 1.2" empty)))
     (make-section "The last subsection of 1" empty)))
   (make-section "Another section"
    (list
     (make-section "More stuff" empty)
     (make-section "Still more stuff" empty)))))
(define TREE-REP-2
  (list 
    (make-section "1-ne-list"
      (list
        (make-section "1-1-e-list" empty)
        (make-section "1-2-ne-list"
          (list
            (make-section "1-2-1-e-list" empty)
            (make-section "1-2-2-e-list" empty)
            (make-section "1-2-3-e-list" empty)
            (make-section "1-2-4-e-list" empty)))
        (make-section "1-3-e-list"
            (list (make-section "1-3-1-e-list" empty)))))
    (make-section "2-ne-list"
      (list
        (make-section "2-1-e-list" empty)
        (make-section "2-2-e-list" empty)))))
(define TREE-REP-3
  (list 
    (make-section "1-ne-list"
      empty)
    (make-section "2-ne-list"
      (list
        (make-section "2-1-e-list" empty)
        (make-section "2-2-e-list" empty)))
    (make-section "3-e-list"
      empty)))

;; flat representation

(define-struct line (section-number heading))
;; A line is a (make-line NonEmpty-NumberedListOfSections String)
;; INTERP:
;; section-number is a non-empty numbered list of section and its 
;;                subsection, a list of natural numbers 
;; heading        is the section-header
;; TEMPLATE:
;; line-fn : Line -> ??
#|
(define (line-fn l)
 (... (line-section-number l)
      (line-heading l)))
|#

;; ListOfLine is
;; -- empty
;; -- (cons Line ListOfLine)
;; A Flat Representation (FlatRep) is a ListOfLine
;; TEMPLATE:
;; flat-rep-fn : ListOfLine -> ??
#|
(define (flat-rep-fn lst)
 (cond
  [(empty? lst) ...]
  [else (... (line-fn (first lst))
             (flat-rep-fn (rest lst)))]))
|#

;; EXAMPLE
(define FLAT-REP-1
  (list
   (make-line (list 1) "The first section")
   (make-line (list 1 1) "A subsection with no subsections")
   (make-line (list 1 2) "Another subsection")
   (make-line (list 1 2 1) "This is a subsection of 1.2")
   (make-line (list 1 2 2) "This is another subsection of 1.2")
   (make-line (list 1 3) "The last subsection of 1")
   (make-line (list 2) "Another section")
   (make-line (list 2 1) "More stuff")
   (make-line (list 2 2) "Still more stuff")))
(define FLAT-REP-2
  (list
   (make-line (list 1) "1-ne-list")
   (make-line (list 1 1) "1-1-e-list")
   (make-line (list 1 2) "1-2-ne-list")
   (make-line (list 1 2 1) "1-2-1-e-list")
   (make-line (list 1 2 2) "1-2-2-e-list")
   (make-line (list 1 2 3) "1-2-3-e-list")
   (make-line (list 1 2 4) "1-2-4-e-list")
   (make-line (list 1 3) "1-3-e-list")
   (make-line (list 1 3 1) "1-3-1-e-list")
   (make-line (list 2) "2-ne-list")
   (make-line (list 2 1) "2-1-e-list")
   (make-line (list 2 2) "2-2-e-list")))
(define FLAT-REP-3
  (list
   (make-line (list 1) "1-ne-list")
   (make-line (list 2) "2-ne-list")
   (make-line (list 2 1) "2-1-e-list")
   (make-line (list 2 2) "2-2-e-list")
   (make-line (list 3) "3-e-list")))
(define ILL-FLAT-REP-1
  (list
   (make-line (list 1 2) "1-ne-list")
   (make-line (list 2) "2-ne-list")
   (make-line (list 2 1) "2-2-e-list")
   (make-line (list 3) "3-e-list")))
(define ILL-FLAT-REP-2
  (list
   (make-line (list 2) "2-ne-list")
   (make-line (list 2 1) "2-1-e-list")
   (make-line (list 3) "3-e-list")))
(define ILL-FLAT-REP-3
  (list
   (make-line (list 7) "7-ne-list")
   (make-line (list 2 1) "2-1-e-list")
   (make-line (list 3) "3-e-list")))
(define ILL-FLAT-REP-4
  (list
   (make-line (list 1) "1-e-list")
   (make-line (list 6 1) "6-1-e-list")
   (make-line (list 3) "3-e-list")))
(define ILL-FLAT-REP-5
  (list
   (make-line (list 2) "2-ne-list")
   (make-line (list 1 2) "1-ne-list")
   (make-line (list 2 1) "2-2-e-list")
   (make-line (list 3) "3-e-list")))
(define FLAT-REP-4
  (list
   (make-line (list 1) "1-ne-list")
   (make-line (list 2) "2-ne-list")
   (make-line (list 2 1) "2-1-e-list")
   (make-line (list 2 2) "2-2-e-list")
   (make-line (list 2 2 1) "2-2-1-e-list")
   (make-line (list 2 2 1 1) "2-2-1-1-e-list")
   (make-line (list 2 2 1 2) "2-2-1-2-e-list")
   (make-line (list 2 2 1 3) "2-2-1-3-e-list")
   (make-line (list 2 2 1 3 1) "2-2-1-3-1-e-list")
   (make-line (list 2 2 1 3 2) "2-2-1-3-2-e-list")
   (make-line (list 2 2 2) "2-2-2-e-list")))
(define ILL-FLAT-REP-6
  (list
   (make-line (list 1) "1-ne-list")
   (make-line (list 2) "2-ne-list")
   (make-line (list 2 1) "2-1-e-list")
   (make-line (list 2 2) "2-2-e-list")
   (make-line (list 2 2 1) "2-2-1-e-list")
   (make-line (list 2 0 1 1) "2-2-1-1-e-list")
   (make-line (list 2 2 1 2) "2-2-1-2-e-list")
   (make-line (list 2 2 1 3) "2-2-1-3-e-list")
   (make-line (list 2 2 1 3 1) "2-2-1-3-1-e-list")
   (make-line (list 2 2 1 3 2) "2-2-1-3-2-e-list")
   (make-line (list 2 2 2) "2-2-2-e-list")))
(define ILL-FLAT-REP-7
  (list
   (make-line (list 1) "1-ne-list")
   (make-line (list 2) "2-ne-list")
   (make-line (list 2 1) "2-1-e-list")
   (make-line (list 2 2) "2-2-e-list")
   (make-line (list 2 2 1) "2-2-1-e-list")
   (make-line (list 2 2 1 2) "2-2-1-2-e-list")
   (make-line (list 2 2 1 3) "2-2-1-3-e-list")
   (make-line (list 2 2 1 3 1) "2-2-1-3-1-e-list")
   (make-line (list 2 2 1 3 2) "2-2-1-3-2-e-list")
   (make-line (list 2 2 2) "2-2-2-e-list")))
(define ILL-FLAT-REP-8
  (list
   (make-line (list 1) "1-e-list")
   (make-line (list 2) "2-ne-list")
   (make-line (list 2 1) "2-1-e-list")
   (make-line (list 2 2) "2-2-ne-list")
   (make-line (list 2 2 1) "2-2-1-ne-list")
   (make-line (list 2 2 1 1) "2-2-1-1-e-list")
   (make-line (list 2 2 1 2) "2-2-1-2-e-list")
   (make-line (list 2 2 1 3) "2-2-1-3-ne-list")
   (make-line (list 2 2 1 3 1) "2-2-1-3-1-e-list")
   (make-line (list 2 2 1 3 2) "2-2-1-3-2-e-list")
   (make-line (list 2 2 5) "2-2-5-e-list")
   (make-line (list 2 3) "2-3-e-list")))
(define ILL-FLAT-REP-9
  (list
   (make-line (list 3) "3-ne-list")
   (make-line (list 3 1) "3-1-ne-list")))
(define ILL-FLAT-REP-10
  (list
   (make-line (list 1) 1)
   (make-line (list 1 1) "1-1-e-list")))

;; PosInt is positive numbers from 1 to n

;; NonEmpty-NumberedListOfSections is
;; -- (cons PosInt ListOfPosInt)
;; TEMPLATE:
;; ne-lox-fn : NonEmpty-NumberedListOfSections -> ??
#|
(define (ne-nlos-fn ne-lst)
 (cond
  [(empty? (rest ne-lst)) (...(first ne-lst))]
  [else (... (first ne-lst)
             (ne-nlos-fn (rest ne-lst)))]))
|#

;; EXAMPLES:
(define LIST-POS-INT-1
  (list (list 1)
        (list 1 1)
        (list 1 2)
        (list 1 2 1)
        (list 1 2 2)
        (list 1 3)
        (list 2)
        (list 2 1)
        (list 2 2)))

;; ListOfPosInt is
;; -- empty
;; -- (cons PosInt ListOfPosInt)
;; TEMPLATE:
;; lopi-fn : ListOfPosInt -> ??
#|
(define (lox-fn lst)
 (cond
  [(empty? lst) ...]
  [else (... (pos-int-fn (first lst))
             (lopi-fn (rest lst)))]))
|#

;; ListOfX (lox) is
;; -- empty
;; -- (cons X ListOfX)
;; TEMPLATE:
;; lox-fn : ListOfX -> ??
#|
(define (lox-fn lst)
 (cond
  [(empty? lst) ...]
  [else (... (x-fn (first lst))
             (lox-fn (rest lst)))]))
|#

;; NonEmptyListOfX is
;; -- (cons X ListOfX)
;; TEMPLATE:
;; ne-lox-fn : NonEmptyListOfX -> ??
#|
(define (ne-lox-fn ne-lst)
 (cond
  [(empty? (rest ne-lst)) (...(first ne-lst))]
  [else (... (first ne-lst)
             (ne-lox-fn (rest ne-lst)))]))
|#

;; ListOfString (lostr) is
;; -- empty
;; -- (cons String ListOfString)
;; TEMPLATE:
;; lostr-fn : ListOfString -> ??
#|
(define (lostr-fn lst)
 (cond
  [(empty? lst) ...]
  [else (... (string-fn (first lst))
             (lostr-fn (rest lst)))]))
|#
;; EXAMPLES:
(define LIST-HEADING-1
  (list "1-ne-list"
        "2-ne-list"
        "2-1-e-list"
        "2-2-e-list"
        "3-e-list"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; MAIN FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; legal-flat-rep? : ListOfLine -> Boolean
;; GIVEN   : a list of lines, like the one above
;; RETURNS : true iff it is a legal flat representation of an outline.
;;           section-number in each line must be a list of natural numbers
;;           also section numbers must be in order,
;;           and it is not allowed to skip any section numbers
;;           section numbers start with 1 and "section numbers"
;;           includes subsections at all levels.
;;           and line-heading in each line should be String
;; EXAMPLE : see tests below
;; STRATEGY: Divide into Cases on flat-rep emptiness
(define (legal-flat-rep? flat-rep)
  (cond
    [(empty? flat-rep) true]
    [else (and (heading-str-check? (list-of-heading flat-rep))
               (sub-legal-flat-rep? (list-of-section-numbers flat-rep)
                                    empty
                                    true))]))
;; TESTS
(begin-for-test
  (check-true (legal-flat-rep? empty)
              "Should return true")
  (check-true (legal-flat-rep? FLAT-REP-1)
              "Should return true iff a flat-representation of outline
                 is given")
  (check-true (legal-flat-rep? FLAT-REP-2)
              "Should return true iff a flat-representation of outline
                 is given")
  (check-true (legal-flat-rep? FLAT-REP-3)
              "Should return true iff a flat-representation of outline
                 is given")
  (check-false (legal-flat-rep? ILL-FLAT-REP-1)
               "Should return true iff a flat-representation of outline
                 is given")
  (check-false (legal-flat-rep? ILL-FLAT-REP-2)
               "Should return true iff a flat-representation of outline
                 is given")
  (check-false (legal-flat-rep? ILL-FLAT-REP-3)
               "Should return true iff a flat-representation of outline
                 is given")
  (check-false (legal-flat-rep? ILL-FLAT-REP-4)
               "Should return true iff a flat-representation of outline
                 is given")
  (check-false (legal-flat-rep? ILL-FLAT-REP-5)
               "Illegal ordering of list, Should return False")
  (check-true (legal-flat-rep? FLAT-REP-4)
              "Legal structure, Should return True")
  (check-false (legal-flat-rep? ILL-FLAT-REP-6)
               "Illegal structure as it includes 0, Should return False")
  (check-false (legal-flat-rep? ILL-FLAT-REP-7)
               "Illegal structure as it skips a section, Should return False")
  (check-false (legal-flat-rep? ILL-FLAT-REP-8)
               "Illegal structure as it includes 0, Should return False")
  (check-false (legal-flat-rep? ILL-FLAT-REP-9)
               "Starts with 3, Should return False")
  (check-false (legal-flat-rep? ILL-FLAT-REP-10)
               "Should return false as one of the heading is not a String")) 
   
;; tree-rep-to-flat-rep : Outline -> FlatRep
;; GIVEN   : the representation of an outline as a list of Sections
;; RETURNS : the flat representation of the outline
;; EXAMPLE : see tests below
;; STRATEGY: Calling a more general function
(define (tree-rep-to-flat-rep outline)
  (trees-rep-to-flat-rep-intermediate outline (list 0)))
;; TESTS
(begin-for-test
  (check-equal? (tree-rep-to-flat-rep TREE-REP-1)
                FLAT-REP-1
                "Should return a flat-representation of the given outline")
  (check-equal? (tree-rep-to-flat-rep TREE-REP-2)
                FLAT-REP-2
                "Should return a flat-representation of the given outline")
  (check-equal? (tree-rep-to-flat-rep TREE-REP-3)
                FLAT-REP-3
                "Should return a flat-representation of the given outline")
  (check-equal? (tree-rep-to-flat-rep empty)
                empty
                "Should return a flat-representation of the given outline"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; HELPER FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; list-of-section-numbers : ListOfLine -> ListOfString
;; GIVEN   : a list of lines
;; RETURNS : returns the list of heading of each line
;;           in the given list of line
;; EXAMPLE : see tests below 
;; STRATEGY: Use HOF map on flat-rep list
(define (list-of-heading flat-rep)
  (map (lambda (line)
         (line-heading line))
       flat-rep))
;; TESTS:
(begin-for-test
  (check-equal? (list-of-heading FLAT-REP-3)
                LIST-HEADING-1
                "Should return the list of heading the from given
                 list of line"))

;; heading-str-check? : ListOfString -> Boolean
;; GIVEN   : a list of lines
;; RETURNS : true iff the given heading list has all the String elements(items)
;; EXAMPLE : see tests below 
;; STRATEGY: Use HOF andmap on lst
(define (heading-str-check? lst)
  (andmap (lambda(heading-str)
            (string? heading-str))
          lst))
;; TESTS:
(begin-for-test
  (check-true (heading-str-check? (list-of-heading FLAT-REP-3))
                "Returns true since the given list of heading is legal")
  (check-false (heading-str-check? (list "str1" 2 "str2"))
                "Returns false since the given list of heading is illegal"))

;; list-of-section-numbers : ListOfLine ->
;;                                     ListOf-NonEmpty-NumberedListOfSections
;; GIVEN   : a list of lines
;; RETURNS : returns the list of non-empty numberedListOfSections of each line
;;           in the given list of line
;; EXAMPLE : see tests below 
;; STRATEGY: Use HOF map on flat-rep list
(define (list-of-section-numbers flat-rep)
  (map (lambda (line)
         (line-section-number line))
       flat-rep))
;; TESTS:
(begin-for-test
  (check-equal? (list-of-section-numbers FLAT-REP-1)
                LIST-POS-INT-1
                "Should return the list of natural numbers from given
                 list of line"))

;; sub-legal-flat-rep? :
;;           NonEmpty-NumberedListOfSections ListOfPosInt Boolean -> Boolean
;; GIVEN   : two non-empty list of positive integer excluding zero,
;;           current and previous and a boolean, flag
;; WHERE   : current is the non-empty list of numberedListOfSections which is
;;           checked for the order of sub-sections to be in sequence
;;           & previous is the item of list just above the (first current)
;;           list with whom the comparison will be performed to check whether
;;           the sub-sections are in order or not, initially it will be empty
;;           & flag stores the cumulative answer for the whole number list to be
;;           legal
;; RETURNS : true iff it follows the rules of legal flat representation
;;           of an outline.
;; EXAMPLE : see tests below
;; STRATEGY: Use template for NonEmpty-NumberedListOfSections
;;           + cases on whether list of naturals number is empty or not
;;           and it starts with (list 1) as well as it does not
;;           skip any subsection in between.      
(define (sub-legal-flat-rep? current previous flag) 
  (cond
    [(empty? current) flag]
    [(= (length previous) (length (first current)))
     (increment-section current previous flag)]
    [(check-for-sequential-section? current previous)
     (add-new-sub-section current previous flag)]
    [(> (length previous) (length (first current)))
     (add-new-pre-section current previous flag)]   
    [else false]))
;; TESTS:
(begin-for-test
  (check-false 
   (sub-legal-flat-rep? empty
                        (list 2 2 1 3 2)
                        #false)
                        "Should return true")
  (check-true 
   (sub-legal-flat-rep? (list                      
                         (list 2 2 3))
                        (list 2 2 2)
                        #true)
                        "Should return true")
  (check-true 
   (sub-legal-flat-rep? (list                      
                         (list 2 2 1))
                        (list 2 2)
                        #true)
                        "Should return true")
  (check-true 
   (sub-legal-flat-rep? (list              
                         (list 2 2 2))
                        (list 2 2 1 3 2)
                        #true)
                        "Should return true"))

;; increment-section :
;;           NonEmpty-NumberedListOfSections ListOfPosInt -> Boolean
;; GIVEN   : two non-empty list of positive integer excluding zero, current
;; WHERE   : current is the non-empty list of numberedListOfSections to carry 
;;           out the comparison for the sequential section-order check
;;           & previous is the item of list just above the (first current)
;;           list with whom the comparison will be performed to check whether
;;           the sub-sections are in legal order or not
;; RETURNS : true iff the the first of current and the previous list complies to
;;           the rules of them being legal flat representation
;; EXAMPLE : see tests below
;; STRATEGY: Combining Simpler Functions
(define (check-for-sequential-section? current previous)
  (and
      (= (last (first current)) ONE)
      (= (add1 (length previous)) (length (first current)))))
;; TESTS:
(begin-for-test
  (check-true
   (check-for-sequential-section? (list (list 1 1)) (list 1))
   "A new section should start with 1 along with its parent 1"))

;; increment-section :
;;           NonEmpty-NumberedListOfSections ListOfPosInt Boolean -> Boolean
;; GIVEN   : two non-empty list of positive integer excluding zero, current and 
;;           previous and a boolean, flag
;; WHERE   : current is the non-empty list of numberedListOfSections to carry 
;;           out the comparison for the sequential section-order check
;;           & previous is the item of list just above the (first current)
;;           list with whom the comparison will be performed to check whether
;;           the sub-sections are in legal order or not
;;           & flag stores the cumulative answer for the whole number list to be
;;           legal
;; RETURNS : true iff it follows the rules of legal flat representation
;;           of an outline.
;; EXAMPLE :
    ; previous:(list 1), first current:(list 2)
    ; previous:(list 1 2), first current:(list 1 3)
    ; previous:(list 1 2 1 3 2), first current:(list 1 2 2)
;; STRATEGY: Combining Simpler Functions
(define (increment-section current previous flag)
  (sub-legal-flat-rep?
   (rest current)
   (first current) 
   (and
    flag
    (equal? (all-but-last (first current))
            (all-but-last previous))
    (= (last (first current)) (add1 (last previous))))))
;; TESTS
(begin-for-test
  (check-true
   (increment-section (list (list 2)) (list 1) #true)
   "Section after 1 should be 2"))

;; add-new-sub-section :
;;             NonEmpty-NumberedListOfSections ListOfPosInt Boolean -> Boolean
;; GIVEN   : two non-empty list of positive integer excluding zero, current and 
;;           previous and a boolean, flag
;; WHERE   : current is the non-empty list of numberedListOfSections to carry 
;;           out the comparison for the sequential section-order check
;;           & previous is the item of list just above the (first current)
;;           list with whom the comparison will be performed to check whether
;;           the sub-sections are in legal order or not
;;           & flag stores the cumulative answer for the whole number list to be
;;           legal
;; RETURNS : true iff it follows the rules of legal flat representation
;;           of an outline.
;; EXAMPLE :
    ; previous:empty, first current:(list 1)
    ; previous:(list 1), first current:(list 1 1)
    ; previous:(list 1 2), first current:(list 1 2 1)
;; STRATEGY: Combining Simpler Functions
(define (add-new-sub-section current previous flag)
  (sub-legal-flat-rep?
   (rest current)
   (first current)
   (and
    flag
    (equal? (all-but-last (first current))
            previous)
    (= (last (first current)) ONE))))
;; TESTS
(begin-for-test
  (check-true
   (add-new-sub-section (list (list 1 1)) (list 1) #true)
   "A new section should start with 1 along with its parent 1"))

;; add-new-pre-section :
;;            NonEmpty-NumberedListOfSections ListOfPosInt Boolean -> Boolean
;; GIVEN   : two non-empty list of positive integer excluding zero, current and 
;;           previous and a boolean, flag
;; WHERE   : current is the non-empty list of numberedListOfSections to carry 
;;           out the comparison for the sequential section-order check
;;           & previous is the item of list just above the (first current)
;;           list with whom the comparison will be performed to check whether
;;           the sub-sections are in legal order or not
;;           & flag stores the cumulative answer for the whole number list to be
;;           legal 
;; RETURNS : true iff it follows the rules of legal flat representation
;;           of an outline.
;; EXAMPLE :
    ; previous:(list 1 3), first current:(list 2)    
    ; previous:(list 2 2 1 3), first current:(list 2 3)
    ; previous:(list 2 2 1 3 2), first current:(list 2 2 2)
;; STRATEGY: Combining Simpler Functions
(define (add-new-pre-section current previous flag)
  (sub-legal-flat-rep?
   (rest current)
   (first current)
   (and
    flag
    (equal?
     (add1 (last (previous-list-upto-current-len previous
                                                 empty
                                                 (length (first current)))))
     (last (first current)))
    (equal?
     (all-but-last (previous-list-upto-current-len previous
                                                   empty
                                                   (length (first current))))
     (all-but-last (first current))))))
;; TESTS
(begin-for-test
  (check-true
   (add-new-pre-section (list (list 2)) (list 1 1) #true)
   "Another section after close of 1.1 should be 2"))

;; previous-list-upto-current-len : ListOfX ListOfX PosInt -> ListOfX
;; GIVEN   : two list(lst and new-list) of X and an index
;;           upto which given list is to be traversed.
;; WHERE   : new-list, initially empty, is same as the previous (lst) list
;;           but whose length will be equal to the given length (len)
;; RETURNS : A new list of X like the one given with
;;           same elements upto the given index starting from 1.
;; EXAMPLE : see tests below
;; STRATEGY: Divide on cases on comparing the length of the lst and new-list
(define (previous-list-upto-current-len lst new-list len)
  (cond
    [(= (length new-list) len) (reverse new-list)]
    [else (previous-list-upto-current-len
           (rest lst)
           (cons (first lst) new-list)
           len)]))
;; TESTS
(begin-for-test
  (check-equal?
   (previous-list-upto-current-len (list 1 2 3 4) empty 2)
   (list 1 2)
   "Should return a new list with elements from given list upto 2nd position")
  (check-equal?
   (previous-list-upto-current-len (list "one" "two" "three") empty 2)
   (list "one" "two")
   "Should return a new list with elements from given list upto 2nd position")
  (check-equal?
   (previous-list-upto-current-len (list "one" "two" "three") empty 0)
   empty
   "Should return empty"))

;; last : NonEmptyListOfX -> X
;; GIVEN   : a non-empty list of X
;; WHERE   : X can be any type of input
;; RETURNS : the last element X in the given NonEmptyListOfX
;; EXAMPLE : see tests below
;; STRATEGY: Combining Simpler Functions
(define (last lst)
  (first (reverse lst)))
;; TESTS
(begin-for-test
  (check-equal?
   (last (list 1 2 3 4))
   4
   "Should return 4")
   (check-equal?
   (last (list "one" "two" "three"))
   "three"
   "Should return three"))

;; trees-rep-to-flat-rep-intermediate :
;;                   ListOfSection ListOfNaturalNos -> ListOfLine
;; GIVEN   : a list of sections, outline and list of natural numbers, num-list
;; WHERE   : num-list, initially (list 0), used to represent the list of the 
;;           section number for a particular section-heading from the
;;           outline, which technically increases as and when the sections are
;;           being traversed in the given outline
;; RETURNS : returns the flat-representation of the given tree-representation
;; EXAMPLE : see tests below
;; STRATEGY: Use template for ListOfSection on outline
;;           + cases on whether list of section is empty or not.
(define (trees-rep-to-flat-rep-intermediate outline num-list)
  (cond
    [(empty? outline) empty]
    [else (cons
           (make-line (add1-last num-list)
                      (section-heading (first outline)))
           (tree-flat-recursive-call outline num-list))]))
;; TESTS:
(begin-for-test
  (check-equal? (trees-rep-to-flat-rep-intermediate TREE-REP-1 (list 0))
                FLAT-REP-1
                "Should return the given tree's flat represention."))

;; tree-flat-recursive-call :
;;                   ListOfSection ListOfNaturalNos -> ListOfLine
;; GIVEN   : a list of sections, outline and list of natural numbers, num-list
;; WHERE   : num-list, initially (list 0), used to represent the list of the 
;;           section number for a particular section-heading from the
;;           outline, which technically increases as and when the sections are
;;           being traversed in the given outline
;; RETURNS : returns the flat-representation of the given tree-representation
;; EXAMPLE : see tests below
;; STRATEGY: Divide on cases on whether list of section within the individual 
;;           section of the outline is empty or not.
(define (tree-flat-recursive-call outline num-list)
  (if (empty? (section-los (first outline)))
      (trees-rep-to-flat-rep-intermediate (rest outline)
                                          (add1-last num-list))
      (append
       (trees-rep-to-flat-rep-intermediate (section-los(first outline))
                                           (append (add1-last num-list)
                                                   (list 0)))
       (trees-rep-to-flat-rep-intermediate (rest outline)
                                           (add1-last num-list)))))

;; all-but-last : ListOfX -> ListOfX
;; GIVEN   : a list of X
;; WHERE   : X can be any type of input
;; RETURNS : a list of X with the last item truncated from the list
;; EXAMPLE : see tests below
;; STRATEGY: Combining Simpler Functions
(define (all-but-last lst)
  (reverse (rest (reverse lst))))
;; TESTS   
(begin-for-test
  (check-equal?
   (all-but-last (list 1 2 3 4))
   (list 1 2 3)
   "Should return the same list without the last element.")
  (check-equal?
   (all-but-last (list "one" "two" "three"))
   (list "one" "two")
   "Should return the same list without the last element."))

;; add1-last : ListOfX -> ListOfX
;; GIVEN   : a list of X
;; WHERE   : X can be of number type only
;; RETURNS : a list of X with the last item incremented by 1 from the list
;; EXAMPLE : see tests below
;; STRATEGY: Combining Simpler Functions
(define (add1-last num-list)
  (append (all-but-last num-list)
          (list (add1 (last num-list)))))
;; TESTS:
(begin-for-test
  (check-equal?
   (add1-last (list 1 2 3 4))
   (list 1 2 3 5)
   "Should return the same list with the last element incremented by 1."))
;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-intermediate-lambda-reader.ss" "lang")((modname class-lists) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f () #f)))

#|
   class-lists.rkt : First Question of Problem Set 05
   DESCRIPTION:
        Professor Felleisen and Professor Shivers each keep their class
    lists on slips of yellow and blue paper respectively, one student
    on each slip.
        One day they collided, and dropped all the slips containing
    their class lists on the stairs, where they got all mixed up.
   GOAL: Sort out each professors list from the mixed list using HOF.
|#

(require rackunit)
(require "extras.rkt")
(check-location "05" "class-lists.rkt")
(provide felleisen-roster
         shivers-roster
         make-slip
         slip-name1
         slip-name2
         slip-color)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; MAIN FUNCTIONS

;; felleisen-roster : ListOfSlips -> ListOfSlips
;; GIVEN   : a list of slips
;; RETURNS : a list of slips containing all the students in
;;           Professor Felleisen's class, without duplication.
;; WHERE   : duplication is calculated by the similarity in the
;;           first and last names of two slips at a time.
;; EXAMPLES: see tests below
;; STRATEGY: Calling a more general function
(define (felleisen-roster list-of-slips)
  (professor-roster FELLEISEN-SLIP-COLOR list-of-slips))
;; TESTS
(define EMPTY-LIST empty)
(begin-for-test
  (check-equal?
   (felleisen-roster LIST-OF-SLIPS)
   (cons SLIP-YELLOW-WangXi
         (cons SLIP-YELLOW-AkashSingh
               (cons SLIP-YELLOW-AkashKhurana empty)))
   "Should remove duplicate slip of Wang Xi and return a list
   of all the yellow slips.")
  (check-equal?
   (felleisen-roster EMPTY-LIST)
   empty
   "Should return empty since the input list is empty"))

;; shivers-roster: ListOfSlips -> ListOfSlips
;; GIVEN   : a list of slips
;; RETURNS : a list of slips containing all the students in 
;;           Professor Shivers' class, without duplication.
;; WHERE   : duplication is calculated by the similarity in the
;;           first and last names of two slips at a time.
;; EXAMPLES: see test below
;; STRATEGY: Calling a more general function
(define (shivers-roster list-of-slips)
  (professor-roster SHIVERS-SLIP-COLOR list-of-slips))
;; TESTS
(begin-for-test
  (check-equal?
   (shivers-roster LIST-OF-SLIPS)
   (cons SLIP-BLUE-AyushSingh
         (cons SLIP-BLUE-WangXi
               (cons SLIP-BLUE-AkashSingh empty)))
   "Should remove duplicate slip of Wang Xi and return a list
   of all the blue slips.")
  (check-equal?
   (shivers-roster EMPTY-LIST)
   empty
   "Should return empty since the input list is empty"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; CONSTANTS

; Professor Felleisen Slips
(define FELLEISEN-SLIP-COLOR "yellow")

; Professor Shivers Slips
(define SHIVERS-SLIP-COLOR "blue")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; DATA DEFINITIONS

(define-struct slip (color name1 name2))
;; A Slip is a (make-slip Color String String)
;; INTERPRETATION:
;;  A Color is one of
;;  -- "yellow"
;;  -- "blue"
;;  name1 is the first name of the student metioned on the slip.
;;  name2 is the last name of the student metioned on the slip.

;; TEMPLATE: 
#|
  (... (slip-color s)
       (slip-name1 s)
       (slip-name2 s))
|#
;; EXAMPLES:
;; (make-slip FELLEISEN-SLIP-COLOR "Xi" "Wang")
;; (make-slip SHIVERS-SLIP-COLOR "Wang" "Xi")

;; A List of Slips (ListOfSlips) is one of:
;; -- empty
;; -- (cons Slip ListOfSlips)

;; TEMPLATE:
;; ListOfSlips-fn : ListOfSlips -> ??
#|
(define (ListOfSlips-fn lst)
 (cond
  [(empty? lst) ...]
  [else (... (first lst)
             (ListOfSlips-fn (rest lst)))]))
|#

;; EXAMPLES for TESTING

; a simple student
(define SLIP-BLUE-AyushSingh
  (make-slip SHIVERS-SLIP-COLOR "Ayush" "Singh"))

; Different students with same first names
(define SLIP-YELLOW-AkashSingh
  (make-slip FELLEISEN-SLIP-COLOR "Akash" "Singh"))
(define SLIP-YELLOW-AkashKhurana
  (make-slip FELLEISEN-SLIP-COLOR "Akash" "Khurana"))

; Same Student but First and Last Names mixed
(define SLIP-YELLOW-XiWang
  (make-slip FELLEISEN-SLIP-COLOR "Xi" "Wang"))
(define SLIP-YELLOW-WangXi
  (make-slip FELLEISEN-SLIP-COLOR "Wang" "Xi"))
(define SLIP-BLUE-XiWang
  (make-slip SHIVERS-SLIP-COLOR "Xi" "Wang"))
(define SLIP-BLUE-WangXi
  (make-slip SHIVERS-SLIP-COLOR "Wang" "Xi"))

; Same Student on two different Slips
(define SLIP-YELLOW-SinghAkash
  (make-slip FELLEISEN-SLIP-COLOR "Singh" "Akash"))
(define SLIP-BLUE-AkashSingh
  (make-slip SHIVERS-SLIP-COLOR "Akash" "Singh"))

; Mixed List of Slips
(define LIST-OF-SLIPS
  (list
   SLIP-BLUE-AyushSingh
   SLIP-YELLOW-XiWang
   SLIP-YELLOW-WangXi
   SLIP-BLUE-XiWang
   SLIP-BLUE-WangXi
   SLIP-YELLOW-AkashSingh
   SLIP-BLUE-AkashSingh
   SLIP-YELLOW-AkashKhurana))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; HELPER FUNCTIONS

;; professor-roster : (Color -> String) ListOfSlips -> ListOfSlips
;; GIVEN   : a color and a list of slips(list-of-slips)
;; RETURNS : a list of slips without duplicates.
;; EXAMPLES: see tests below
;; STRATEGY: Combine Simpler Functions
(define (professor-roster color list-of-slips)
  (remove-duplicates
   (filter
    ; Slip -> Boolean
    ; RETURNS #true iff Slip color equals given color
    (lambda (slip)
      (color=? color (slip-color slip)))
    list-of-slips)))

;; color=? : String String -> Boolean
;; GIVEN   : 2 Colors (color and color-of-slip)
;; RETURNS : #true iff both given strings are equal.
;; EXAMPLES:
;; (color=? SHIVERS-SLIP-COLOR SHIVERS-SLIP-COLOR) = #true
;; (color=? FELLEISEN-SLIP-COLOR SHIVERS-SLIP-COLOR) = #false
;; STRATEGY: Combine Simpler Functions
(define (color=? color color-of-slip)
  (string=? color color-of-slip))

;; remove-duplicates : ListOfSlips -> ListOfSlips
;; GIVEN   : A List of All the Slips
;; RETURNS : A new List like the given one,
;;           without the duplicates
;; WHERE   : duplication is calculated by the similarity in the
;;           first and last names of two slips at a time.
;; EXAMPLES: see tests below
;; STRATEGY: Use template of ListOfSlips on list-of-slips
(define (remove-duplicates list-of-slips)
  (foldr
   ;; Slip ListOfSlips -> ListOfSlips
   ;; RETURNS a ListOfSlips like given without duplicates
   (lambda (current-slip rest-of-slips)
     (append
      (duplicate-check current-slip rest-of-slips)
      rest-of-slips))
   empty
   list-of-slips))  
;; TESTS
(begin-for-test
  (check-equal?
   (remove-duplicates LIST-OF-SLIPS)
   (cons SLIP-BLUE-AyushSingh
         (cons SLIP-BLUE-WangXi
               (cons SLIP-BLUE-AkashSingh
                     (cons SLIP-YELLOW-AkashKhurana '()))))
   "Should return a list containing of unique slips from 
    a list of mixed slips of both yellow and blue color")
  (check-equal?
   (remove-duplicates empty)
   empty
   "Should return empty since the input list is empty"))

;; duplicate-check : Slip ListofSlips -> ListOfSlips
;; GIVEN   : a slip(current-slip) and a ListOfSlips
;;           (rest-ofslips) containing rest of the slips.
;; RETURNS : a ListOfSlips of single element(current-slip)
;;           if duplicate is not found else empty.
;; EXAMPLES: see tests below
;; STRATEGY: Divide into cases based on
;;           whether next is empty or not
(define (duplicate-check current-slip rest-of-slips)
  (if (duplicate-slip-in-list? current-slip rest-of-slips)
      empty
      (list current-slip)))
;; TESTS
(begin-for-test
  (check-equal?
   (duplicate-check SLIP-YELLOW-XiWang
                    (list SLIP-YELLOW-WangXi
                          SLIP-YELLOW-AkashSingh))
   empty
   "Should return true since 'Xi Wang' and 'Wang Xi' are same.")
  (check-equal?
   (duplicate-check SLIP-YELLOW-XiWang
                    (list SLIP-YELLOW-AkashSingh))
   (list SLIP-YELLOW-XiWang)
   "Should return false since 'Xi Wang' is different from 'Akash Singh'"))

;; duplicate-slip-in-list? : Slip ListofSlips -> Boolean
;; GIVEN   : a slip(current-slip) and a ListOfSlips
;;           (rest-ofslips) containing rest of the slips.
;; RETURNS : True if current-slip duplicate is found in
;;           the given ListOfSLips(rest-of-slips).
;; EXAMPLES: see tests below
;; STRATEGY: Divide into cases based on
;;           whether next is empty or not
(define (duplicate-slip-in-list? current-slip rest-of-slips)
  (ormap
   ;; Slip -> Boolean
   ;; RETURNS true iff current-slip equals argument slip
   (lambda (slip)
     (duplicate-slips? current-slip slip))
   rest-of-slips))
;; TESTS
(begin-for-test
  (check-equal?
   (duplicate-slip-in-list?
    SLIP-YELLOW-XiWang LIST-OF-SLIPS)
   #true))

;; duplicate-slips? : Slip Slip -> Boolean
;; GIVEN   : 2 Slips(slip1 and slip2)
;; RETURNS : True if the GIVEN Slips are duplicate.
;; EXAMPLES: see tests below
;; STRATEGY: Divide into cases based on
;;           whether next is empty or not
(define (duplicate-slips? slip1 slip2)
  (or
   (first-names=? slip1 slip2)
   (first-last-names=? slip1 slip2)))
;; TESTS
(begin-for-test
  (check-equal?
   (duplicate-slips?
    SLIP-YELLOW-XiWang SLIP-YELLOW-SinghAkash)
   #false
   "Should return false")
   (check-equal?
   (duplicate-slips?
    SLIP-YELLOW-XiWang SLIP-YELLOW-XiWang)
   #true
   "Should return true"))
   
;; first-names=? : Slip Slip -> Boolean
;; GIVEN   : 2 different slips containing Student's First & Last Name
;; RETURNS : True iff the first name of first slip 
;;           and first name of second slip are same.
;; EXAMPLES: see tests below
;; STRATEGY: Combine Simpler Functions
(define (first-names=? student1 student2)
  (and
   (string=?
    (slip-name1 student1)
    (slip-name1 student2))
   (string=?
    (slip-name2 student1)
    (slip-name2 student2))))
;; TESTS
(begin-for-test
  (check-equal?
   (first-names=? SLIP-YELLOW-XiWang SLIP-YELLOW-XiWang)
   #true
   "Should return true since 'Xi Wang' and 'Wang Xi' are same.")
  (check-equal?
   (first-names=? SLIP-YELLOW-XiWang SLIP-YELLOW-WangXi)
   #false
   "Should return false since 'Xi Wang' and 'Wang Xi' are different."))

;; first-last-names=? : Slip Slip -> Boolean
;; GIVEN   : 2 different slips containing Student's First & Last Name
;; RETURNS : True iff the first name of first slip
;;           and last name of second slip are same.
;; EXAMPLES: see tests below
;; STRATEGY: Combine Simpler Functions
(define (first-last-names=? student1 student2)
  (and
   (string=?
    (slip-name1 student1)
    (slip-name2 student2))
   (string=?
    (slip-name2 student1)
    (slip-name1 student2))))
;; TESTS
(begin-for-test
  (check-equal?
   (first-last-names=? SLIP-YELLOW-XiWang SLIP-YELLOW-XiWang)
   #false
   "Should return false since 'Xi Wang' and 'Wang Xi' are different.")
  (check-equal?
   (first-last-names=? SLIP-YELLOW-XiWang SLIP-YELLOW-WangXi)
   #true
   "Should return true since 'Xi Wang' and 'Wang Xi' are same."))

(felleisen-roster LIST-OF-SLIPS)
(shivers-roster LIST-OF-SLIPS)

;; END
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
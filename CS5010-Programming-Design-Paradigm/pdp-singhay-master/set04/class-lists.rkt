;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-beginner-reader.ss" "lang")((modname class-lists) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f () #f)))
#|
   class-lists.rkt : Third and Last Question of Problem Set 04
   Description:
        Professor Felleisen and Professor Shivers each keep their class
    lists on slips of paper, one student on each slip. Prof. Felleisen
    keeps his list on slips of yellow paper. Professor Shivers keeps
    his list on slips of blue paper.
    Unfortunately, both professors are sloppy record-keepers.
    Sometimes they have more than one slip for the same student.
    Sometimes they record the student names first-name first;
    sometimes they record the names last-name first.
        One day, Professor Felleisen was walking up the stairs in WVH,
    talking to one of his graduate students. At the same time,
        Professor Shivers was walking down the stairs, all the time
    talking to one of his graduate students. They collided, and  
    dropped all the slips containing their class lists on the stairs,
    where they got all mixed up.
   GOAL: clean up this mess.
|#

(require rackunit)
(require "extras.rkt")
(check-location "04" "class-lists.rkt")
(provide felleisen-roster
         shivers-roster)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; MAIN FUNCTIONS

;; felleisen-roster : ListOfSlips -> ListOfSlips
;; GIVEN   : a list of slips
;; RETURNS : a list of slips containing all the students in
;;           Professor Felleisen's class, without duplication.
;; WHERE   : duplication is calculated by the similarity in the
;;           first and last names of two slips at a time.
;; EXAMPLES: see tests below
;; STRATEGY: Use template of ListOfSlips on LIST-OF-SLIPS
(define (felleisen-roster LIST-OF-SLIPS)
  (cond
    [(empty? LIST-OF-SLIPS) empty]
    [else
     (if
      (string=? (slip-color (first LIST-OF-SLIPS)) FELLEISEN-SLIP-COLOR)
      (remove-duplicate
       (append 
        (list (first LIST-OF-SLIPS))
        (felleisen-roster (rest LIST-OF-SLIPS))))
      (felleisen-roster (rest LIST-OF-SLIPS)))]))
;; TESTS
(define EMPTY-LIST empty)
(begin-for-test
  (check-equal?
   (felleisen-roster LIST-OF-SLIPS)
   (cons (make-slip "yellow" "Wang" "Xi")
         (cons (make-slip "yellow" "Akash" "Singh")
               (cons (make-slip "yellow" "Akash" "Khurana") '())))
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
;; STRATEGY: Use template of ListOfSlips on LIST-OF-SLIPS
(define (shivers-roster LIST-OF-SLIPS)
  (cond
    [(empty? LIST-OF-SLIPS) empty]
    [else
     (if
      (string=? (slip-color (first LIST-OF-SLIPS)) SHIVERS-SLIP-COLOR)
      (remove-duplicate
       (append 
        (list (first LIST-OF-SLIPS))
        (shivers-roster (rest LIST-OF-SLIPS))))
      (shivers-roster (rest LIST-OF-SLIPS)))]))
;; TESTS
(begin-for-test
  (check-equal?
   (shivers-roster LIST-OF-SLIPS)
   (cons (make-slip "blue" "Ayush" "Singh")
         (cons (make-slip "blue" "Wang" "Xi")
               (cons (make-slip "blue" "Akash" "Singh") '())))
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

;; A List of Slips (ListOfSlips) is one of:
;; -- empty
;; -- (cons Number ListOfSlips)

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

;; remove-duplicate : ListOfSlips-> ListOfSlips
;; GIVEN   : A List of All the Slips
;; RETURNS : A new List like the given one,
;;           without the duplicates
;; WHERE   : duplication is calculated by the similarity in the
;;           first and last names of two slips at a time.
;; EXAMPLES: see tests below
;; STRATEGY: Use template of ListOfSlips on LIST-OF-SLIPS
(define (remove-duplicate LIST-OF-SLIPS)
  (cond
    [(empty? LIST-OF-SLIPS) empty]
    [else
     (if
      (is-duplicate? (first LIST-OF-SLIPS) (rest LIST-OF-SLIPS))
      (remove-duplicate (rest LIST-OF-SLIPS))
      (append
       (list (first LIST-OF-SLIPS))
       (remove-duplicate (rest LIST-OF-SLIPS))))]))
;; TESTS
(begin-for-test
  (check-equal?
   (remove-duplicate LIST-OF-SLIPS)
   (cons (make-slip "blue" "Ayush" "Singh")
 (cons (make-slip "blue" "Wang" "Xi")
  (cons (make-slip "blue" "Akash" "Singh")
   (cons (make-slip "yellow" "Akash" "Khurana") '()))))
   "Should return a list containing of unique slips from 
    a list of mixed slips of both yellow and blue color")
  (check-equal?
   (remove-duplicate empty)
   empty
   "Should return empty since the input list is empty"))
    
;; is-duplicate? : Slip Slip -> Boolean
;; GIVEN   : 2 different slips containing Student's First & Last Name
;; RETURNS : Whether or not the GIVEN Slips are duplicate.
;; EXAMPLES: see tests below
;; STRATEGY: Divide into cases based on
;;           whether next is empty or not
(define (is-duplicate? previous next)
  (cond
    [(empty? next) false]
    [else
     (or
      (compare-first-first previous (first next))
      (compare-first-last previous (first next)))]))
;; TESTS
(begin-for-test
  (check-equal?
   (is-duplicate? SLIP-YELLOW-XiWang (list SLIP-YELLOW-WangXi))
   #true
   "Should return true since 'Xi Wang' and 'Wang Xi' are same.")
  (check-equal?
   (is-duplicate? SLIP-YELLOW-XiWang (list SLIP-YELLOW-XiWang))
   #true
   "Should return true since 'Xi Wang' and 'Xi Wang' are same.") 
  (check-equal?
   (is-duplicate? SLIP-YELLOW-XiWang (list SLIP-YELLOW-AkashSingh))
   #false
   "Should return false since 'Xi Wang' is different from 'Akash Singh'")
  (check-equal?
   (is-duplicate? SLIP-YELLOW-XiWang EMPTY-LIST)
   #false
   "Should return true since input list is empty."))

;; compare-first-last : Slip Slip -> Boolean
;; GIVEN   : 2 different slips containing Student's First & Last Name
;; RETURNS : True/False based whether the first name of first
;;           slip and first name of second slip are same or not.
;; EXAMPLES: see tests below
;; STRATEGY: Combine Simpler Functions
(define (compare-first-first student1 student2)
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
   (compare-first-first SLIP-YELLOW-XiWang SLIP-YELLOW-XiWang)
   #true
   "Should return true since 'Xi Wang' and 'Wang Xi' are same.")
  (check-equal?
   (compare-first-first SLIP-YELLOW-XiWang SLIP-YELLOW-WangXi)
   #false
   "Should return false since 'Xi Wang' and 'Wang Xi' are different."))

;; compare-first-last : Slip Slip -> Boolean
;; GIVEN   : 2 different slips containing Student's First & Last Name
;; RETURNS : True/False based whether the first name of first
;;           slip and last name of second slip are same or not.
;; EXAMPLES: see tests below
;; STRATEGY: Combine Simpler Functions
(define (compare-first-last student1 student2)
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
   (compare-first-last SLIP-YELLOW-XiWang SLIP-YELLOW-XiWang)
   #false
   "Should return false since 'Xi Wang' and 'Wang Xi' are different.")
  (check-equal?
   (compare-first-last SLIP-YELLOW-XiWang SLIP-YELLOW-WangXi)
   #true
   "Should return true since 'Xi Wang' and 'Wang Xi' are same."))
  
(felleisen-roster LIST-OF-SLIPS)
(shivers-roster LIST-OF-SLIPS)
(remove-duplicate LIST-OF-SLIPS)

;; END
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

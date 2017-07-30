;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-intermediate-lambda-reader.ss" "lang")((modname rainfall) (read-case-sensitive #t) (teachpacks ((lib "image.rkt" "teachpack" "2htdp") (lib "universe.rkt" "teachpack" "2htdp"))) (htdp-settings #(#t constructor repeating-decimal #f #t none #f ((lib "image.rkt" "teachpack" "2htdp") (lib "universe.rkt" "teachpack" "2htdp")) #f)))
;; rainfall.rkt : 3rd question of problem set07

;; GOAL: Producing the average of the non-negative values in the list
;;       of numbers representing daily rainfall amounts 
;;       up to the first -999 (if it shows up).
;; WHERE: the number -999 indicates the end of the data of interest


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; LIBRARY
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(require rackunit)
(require "extras.rkt")

(check-location "07" "rainfall.rkt")

(provide rainfall)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; CONSTANTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Numerical Constants
(define ZERO 0)
(define UPTO-LIMIT -999)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; DATA DEFINITIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; A ListOfDailyRainfallAmts (LODR) is one of:
;; -- empty
;; -- (cons Number ListOfDailyRainfallAmts)
;; TEMPLATE:
;; LODR-fn : ListOfDailyRainfallAmts -> ??
#|
(define (LODR-fn lst)
 (cond
  [(empty? lst) ...]
  [else (... (number-fn (first lst))
             (LODR-fn (rest lst)))]))
|# 
;; EXAMPLES:
(define EMPTY-LIST empty)
(define LIST-1 
  (list -2 3 14 -3 -8 13 19 19 0 -19 UPTO-LIMIT -90 9 10 -100))
(define LIST-2
  (list -2 3 14 -3 -8 13 19 19 -19 -99 -90 4 10 0 -100))
(define LIST-3
  (list UPTO-LIMIT))
(define LIST-4
  (list ZERO ZERO UPTO-LIMIT ZERO))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; MAIN FUNCTION
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; rainfall : ListOfDailyRainfallAmts -> NonNegInt
;; GIVEN    : a list of numbers which acounts to daily Rainfall amounts
;; RETURNS  : the average of all non-negative LIMITs in the given list
;;            up to the first UPTO-LIMIT (if it is encountered).
;; EXAMPLES : see tests below
;; STRATEGY : Call a more general function

(define (rainfall lst)
  (if (empty? lst)
      ZERO
      (sub-rainfall (list-of-nonnegint-upto-limit lst empty)
                    ZERO
                    (nonnegint-list-len
                     (list-of-nonnegint-upto-limit lst empty)))))

;; TESTS
(begin-for-test
  (check-equal? (rainfall LIST-1)
                34/3
                "Should return the average of 3,14,13,19,19 = 68/5")
  (check-equal? (rainfall LIST-2)
                41/4
                "Should return the average of 3,14,13,19,19,4,10 = 82/7")
  (check-equal? (rainfall EMPTY-LIST)
                ZERO
                "Should return 0 as average since input list is empty")
  (check-equal? (rainfall LIST-3)
                ZERO
                "Should return 0 as average since input list is empty")
  (check-equal? (rainfall LIST-4)
                ZERO
                "Should return 0 as average since input list is empty"))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; HELPER FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; sub-rainfall : ListOfDailyRainfallAmts NonNegInt NonNegInt -> NonNegInt
;; GIVEN    : a list of numbers which acounts to daily Rainfall amounts, lst
;;            sum of numbers, sum
;;            and length of the list, length-of-lst.
;; WHERE    : sum, initially 0, is the sum of numbers in the given non-negative
;;            integer list.
;;            length-of-lst is the length of the given list of non-negative 
;;            numbers, lst.
;; RETURNS  : the average of all non-negative numbers in the given list
;;            up to the first UPTO-LIMIT, if encounered.(-999 in this case).
;; EXAMPLES : (sub-rainfall (list-of-nonnegint-upto-limit LIST-1 empty)
;;                           ZERO ZERO) = 34/3
;; STRATEGY : Divide into Cases on list emptiness

(define (sub-rainfall lst sum length-of-lst)
  (cond
    [(empty? lst) (/ sum length-of-lst)]
    [else (sub-rainfall (rest lst)
                   (+ sum (first lst))
                   length-of-lst)]))

;; TESTS
(begin-for-test
  (check-equal?
   (sub-rainfall
    (list-of-nonnegint-upto-limit LIST-1 empty)
    ZERO
    (length (list-of-nonnegint-upto-limit LIST-1
                                          empty)))
   34/3
   "Should return the average of the non-negative numbers in
                 the list"))


;; nonnegint-list-len : ListOfNonNegInt -> NonNegInt
;; GIVEN    : a list of non-negative integers, lst
;; RETURNS  : length of the given list, lst 
;; EXAMPLES : see tests below
;; STRATEGY : Combining Simpler Functions
(define (nonnegint-list-len lst)
  (if (empty? lst) 
      1
      (length lst)))

;; TESTS:
(begin-for-test
  (check-equal?
   (nonnegint-list-len
    (list-of-nonnegint-upto-limit LIST-2
                                  empty))
   8
   "Should return the length of a non-empty list")
  (check-equal?
   (nonnegint-list-len
    (list-of-nonnegint-upto-limit empty
                                  empty))
   1
   "Should return 1 for an empty list"))


;; list-of-nonnegint-upto-limit :
;;                ListOfDailyRainfallAmts ListOfNonNegInt -> ListOfNonNegInt
;; GIVEN    : a list of numbers which acounts to daily Rainfall amounts, e
;;            and list of non-negative integers, new-list
;; WHERE    : new-list, initally empty, will be list of all non-negative
;;            integers in e and if the list, e contains threshold, -999 then it
;;            returns all non-negative integers above -999.
;; RETURNS  : A list of rainfall amounts containing of all non-negative numbers
;;            up to the first UPTO-LIMIT(-999 in this case), if encountered.
;; EXAMPLES : see tests below
;; STRATEGY : Divide into Cases on list emptiness and whether the threshold 
;;            has been encountered or not

(define (list-of-nonnegint-upto-limit lodr new-list)
  (cond
    [(empty? lodr) (reverse new-list)]
    [(= (first lodr) UPTO-LIMIT) (reverse new-list)]
    [else (else-new-list lodr new-list)]))

;; TESTS
(begin-for-test
  (check-equal?
   (list-of-nonnegint-upto-limit LIST-1 empty)
   (list 3 14 13 19 19 0)
   "Should return a list of all positive numbers before UPTO-LIMIT")
  (check-equal?
   (list-of-nonnegint-upto-limit LIST-2 empty)
   (list 3 14 13 19 19 4 10 0)
   "Should return a list of all positive numbers")
  (check-equal?
   (list-of-nonnegint-upto-limit EMPTY-LIST empty)
   empty
   "Should return a list of all positive numbers")
  (check-equal?
   (list-of-nonnegint-upto-limit LIST-3 empty)
   empty
   "Should return a list of all positive numbers")
  (check-equal?
   (list-of-nonnegint-upto-limit LIST-4 empty)
   (list 0 0)
   "Should return a list of all positive numbers"))


;; else-new-list :
;;                ListOfDailyRainfallAmts ListOfNonNegInt -> ListOfNonNegInt
;; GIVEN    : a list of numbers which acounts to daily Rainfall amounts, e
;;            and list of non-negative integers, new-list
;; WHERE    : new-list, initally empty, will be list of all non-negative
;;            integers in e and if the list, e contains threshold, -999 then it
;;            returns all non-negative integers above -999.
;; RETURNS  : A list of rainfall amounts containing of all non-negative numbers
;;            up to the first UPTO-LIMIT(-999 in this case), if encountered.
;; EXAMPLES : see tests below
;; STRATEGY : Combining Simpler Functions +
;;            Divide into Cases on integers encountered are non-negative
;;            integers or not.

(define (else-new-list lodr new-list)
  (list-of-nonnegint-upto-limit
   (rest lodr)
   (if (or (positive? (first lodr))
           (zero? (first lodr)))              
       (cons (first lodr)
             new-list)
       new-list)))

;; TESTS
(begin-for-test
  (check-equal?
   (else-new-list LIST-1 empty)
   (list 3 14 13 19 19 0)
   "Should return a list of all positive numbers before UPTO-LIMIT")
  (check-equal?
   (else-new-list LIST-2 empty)
   (list 3 14 13 19 19 4 10 0)
   "Should return a list of all positive numbers")
  (check-equal?
   (else-new-list LIST-3 empty)
   empty
   "Should return a list of all positive numbers"))
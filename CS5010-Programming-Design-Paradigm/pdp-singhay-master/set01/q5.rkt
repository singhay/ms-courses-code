;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-beginner-reader.ss" "lang")((modname q5) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f () #f)))
;; q5.rkt : Example 22 from Book HtDP2e,
;;          Fifth and Last Question of Problem Set 01. 

;; Goal: Delete String letter from the given input position of the string.

(require rackunit)
(require "extras.rkt")

(provide string-delete)

;; string-length : String -> exact-nonnegative-integer
;; RETURNS: Length of the GIVEN String.
;; EXAMPLES:
;;  (string-length "Apple") = 5

;; string-append : String ... -> String
;; RETURNS: A new mutable string that is as long as the sum of the given Strings' lengths,
;;          and that contains the concatenated characters of the given Strings'.
;;          If no strs are provided, the result is a zero-length string
;; EXAMPLES:
;;  (string-append "Apple" "Banana") = "AppleBanana"

;; substring : String start end -> String
;; RETURNS: A new mutable string that is (- end start) characters long, and
;;          that contains the same characters as str from start inclusive to end exclusive.
;; INTERPRETATIONS:
;;  str : string?
;;  start : exact-nonnegative-integer?
;;  end : exact-nonnegative-integer? = (string-length str)
;; WHERE:
;;  first position in a string corresponds to 0
;;  start and end argument <= length of str
;;  end >= start else exception is raised
;; EXAMPLES:
;;  (substring "Apple" 1 3) = "pp"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DATA DEFINITIONS: none

;; string-delete : String exact-nonnegative-integer -> String
;; GIVEN: A string and a number i
;; WHERE: i is a number between 0 (inclusive) and
;;        the length of the given string (exclusive)
;; RETURNS: String with the ith position deleted from the given string
;; EXAMPLES:
;; (string-delete "HelloWorld" 5) -> "HellWorld"
;; (string-delete "This is awesome" 9) -> "This is wesome"
;; DESIGN STRATEGY: Combine Simpler Functions

(define (string-delete str i)
  (cond
   [(> i (string-length str)) "i is out of bound"]    
   [(and (<= i (string-length str)) (not (string=? str ""))) 
   (string-append
    (substring str 0 (- i 1))
    (substring str i (string-length str))
    )]
   [(= (string-length str) 0) "Empty String! Can't delete anything from nothing :)"]
   ))

;; TESTS
(begin-for-test
  (check-equal? (string-delete "HelloWorld" 5) "HellWorld"
                "Should Return 'HellWorld' after Deleting fifth string from 'HelloWorld'")
  (check-equal? (string-delete "This is awesome" 9) "This is wesome"
                "Should Return 'This is wesome' after Deleting ninth string from 'This is awesome'")
  (check-equal? (string-delete "" 9) "i is out of bound"
                "Should throw error since input requests deletion at index greater than length of string")
  (check-equal? (string-delete "        " 6) "       "
                "Should Return '       ' after Deleting sixth string from '        '")
  ;Testing for deletions at the extremities
  (check-equal? (string-delete "Northeastern" 12) "Northeaster"
                "Should Return 'Northeaster' after Deleting last string from 'Northeastern'")
  (check-equal? (string-delete "MIT" 1) "IT"
                "Should Return 'IT' after Deleting first string from 'MIT'")
  (check-equal?(string-delete "" 0) "Empty String! Can't delete anything from nothing :)"
               "Throws error as input is requesting to delete from an empty string"))
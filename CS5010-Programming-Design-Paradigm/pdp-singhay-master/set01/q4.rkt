;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-beginner-reader.ss" "lang")((modname q4) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f () #f)))
;; q4.rkt : Example 21 from Book HtDP2e,
;;          Fourth Question of Problem Set 01. 

;; Goal: Insert "_" at the given input position of the string.

(require rackunit)
(require "extras.rkt")

(provide string-insert)

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

;; string-insert : String exact-nonnegative-integer -> String
;; GIVEN: A string and a number i
;; WHERE: i is a number between 0 and the length of the given string (inclusive)
;; RETURNS: String with "_" inserted at the ith position of the given string.
;; EXAMPLES:
;; (string-insert "HelloWorld" 5) -> "Hello_World"
;; (string-insert "This is awesome" 11) -> "This is awe_some"
;; DESIGN STRATEGY: Combine Simpler Functions

(define (string-insert str i)
  (cond
    [(> i (string-length str)) "index out of bound"]
    [   (and (<= i (string-length str)) (not (string=? str ""))) 
        (string-append (substring str 0 i) "_" (substring str i (string-length str)))]
    [(= (string-length str) 0) "_"]
  ))
 
;; TESTS
(begin-for-test  
  (check-equal? (string-insert "HelloWorld" 5) "Hello_World"
                "Should insert '_' after fifth String of 'HelloWorld'")
  (check-equal? (string-insert "This is awesome" 11) "This is awe_some"
                "Should insert '_' after eleventh String of 'This is awesome'")
  (check-equal? (string-insert "  " 10) "index out of bound"
                "Should throw error since insert index is out of maximum string length")
  (check-equal? (string-insert "" 0) "_"
                "Should insert '_' in the beginning of empty string ''")
  ; Testing for insertions at the extremities
  (check-equal? (string-insert "Northeastern" 0) "_Northeastern"
                "Should insert '_' before first String of 'Northeastern'")
  (check-equal? (string-insert "MIT" 3) "MIT_"
                "Should insert '_' after third String of 'MIT'"))

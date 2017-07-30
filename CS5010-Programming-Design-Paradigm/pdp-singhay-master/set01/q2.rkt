;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-beginner-reader.ss" "lang")((modname q2) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f () #f)))
;; q2.rkt : Example 15 from Book HtDP2e,
;;         Second Question of Problem Set 01. 

;; Goal: Extract the first String from a non-empty string.

(require rackunit)
(require "extras.rkt")

(provide string-first)

;; string-ith: String exact-nonnegative-integer -> String
;; RETURNS : Extracts the ith 1-letter substring from s.
;; INTERPRETATIONS:
;;  s : string
;;  i : natural-number
;; EXAMPLES:
;;   (string-ith "hello world" 1) = "e"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DATA DEFINITIONS: none

;; string-first : String -> String
;; RETURNS: The first 1-letter substring of the GIVEN String.
;; WHERE: Given String is non-empty.
;; EXAMPLES:
;; (string-first "Ayush") = "A"
;; (string-first "This is awesome") = "T"
;; DESIGN STRATEGY: Combine Simpler Functions

(define (string-first str)
  (string-ith str 0))

;; TESTS
(begin-for-test  
  (check-equal? (string-first "PDP") "P"
                "Should return 'P' as first String of 'PDP'")
  (check-equal? (string-first "Dis awesome") "D"
                "Should return 'D' as first String of 'Dis awesome'")
  (check-equal? (string-first "P234 567890") "P"
                "Should return 'P' as first String of 'P234 567890'"))
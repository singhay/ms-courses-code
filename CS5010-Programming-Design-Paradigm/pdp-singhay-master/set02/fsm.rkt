;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-beginner-reader.ss" "lang")((modname fsm) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f () #f)))
;; fsm.rkt : Inspired from Example 111 from Book HtDP2e,
;;           Second Question of Problem Set 02. 

;; Goal: To make a Finite State Machine.
;;       (a | b)* c (a | b)* d (e | f)*
(require rackunit)
(require "extras.rkt")
(check-location "02" "fsm.rkt")

(provide initial-state
         next-state
         accepting-state?
         error-state?)

;; IN-BUILT functions:
;; used from racket/base:
;; string=? : (string=? "Apple" "apple") = #false

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; DATA DEFINITION:
;; a State is one of the following
;; -- "A"
;; -- "B" 
;; -- "C"
;; -- "error"
;; INTERPRETATION:
;;  "A" is start state.
;;  "B" is a state between start and accept state
;;      from where path to accept state exists.
;;  "C" is accept state.
;;  "error" is error state.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; accepting-state? : State -> Boolean
;; GIVEN: a state of the machine
;; RETURNS: true iff the given state is a final (accepting) state
;; EXAMPLES:
;; (accepting-state? "B") = #false
;; DESIGN STRATEGY: Combine Simpler Functions
(define (accepting-state? response)
  (if (string=? response "C") true false))

;; error-state? : State -> Boolean
;; GIVEN: a state of the machine
;; RETURNS: true iff there is no path (empty or non-empty)
;;          from the given state to an accepting state
;; EXAMPLES:
;; (error-state? "success") = #false
;; DESIGN STRATEGY: Combine Simpler Functions
(define (error-state? response)
  (if (string=? response "error") true false))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; next-state : State MachineInput -> State
;; GIVEN: a state of the machine and a machine input
;; RETURNS: the state that should follow the given input.
;; EXAMPLES:
;; (next-state "A" "c") = "B"
;; (next-state "C" "f") = "C"
;; DESIGN STRATEGY: Use template for State on input.
(define (next-state current-state input)
  (cond
    [(string=? "A" current-state) (state-A input)]
    [(string=? "B" current-state) (state-B input)]
    [(string=? "C" current-state) (state-C input)]
    [(string=? "error" current-state) "error"])) 

;; state-A : MachineInput -> State
;; state-B : MachineInput -> State
;; state-C : MachineInput -> State
;; GIVEN: a machine input
;; RETURNS: the state that should follow the given input.
;; EXAMPLES:
;; (state-A "c") = "B"
;; (state-B "f") = "error"
;; (state-C "f") = "error"
;; DESIGN STRATEGY: Divide into Cases based on input to change State
;;                  and also stop from reaching a restricted State.
(define (state-A input)
  (cond
    [(string=? input "a") "A"]
    [(string=? input "b") "A"]
    [(string=? input "c") "B"]
    [(string=? "d" input) "error"]
    [(string=? "e" input) "error"]
    [(string=? "f" input) "error"]))

(define (state-B input)
  (cond
    [(string=? input "a") "B"]
    [(string=? input "b") "B"]
    [(string=? input "c") "error"]    
    [(string=? input "d") "C"]
    [(string=? "e" input) "error"]
    [(string=? "f" input) "error"])) 
  
(define (state-C input)
  (cond
    [(string=? input "a") "error"]
    [(string=? input "b") "error"]
    [(string=? input "c") "error"]
    [(string=? input "d") "error"]    
    [(string=? input "e") "C"]
    [(string=? input "f") "C"]))
  
;; initial-state : Number -> State
;; GIVEN: a number
;; RETURNS: a representation of the initial state
;;          of your machine.  The given number is ignored.
;; EXAMPLES: (initial-state 342324432) = "A"
;; DESIGN STRATEGY: none
(define (initial-state n) "A")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; TESTS
(begin-for-test
(check-equal? (accepting-state? (next-state (next-state (initial-state 0) "c") "d")) true)

(check-equal? (accepting-state? (next-state (next-state (next-state (initial-state 0) "c") "a") "d")) true)

(check-equal? (error-state? (next-state (next-state (next-state (initial-state 0) "a") "c") "d")) false)

(check-equal? (accepting-state? (next-state (next-state (next-state (next-state (initial-state 0) "c") "a") "b") "d")) true)

(check-equal? (error-state? (next-state (next-state (next-state (next-state (next-state (next-state (next-state (initial-state 0) "c") "a") "b") "f") "b") "d") "f")) true)

(check-equal? (accepting-state? (next-state (next-state (next-state (next-state (next-state (next-state (next-state (initial-state 0) "a") "b") "b") "d") "e") "d") "f")) false)

(check-equal? (error-state? (next-state (next-state (next-state (next-state (initial-state 0) "a") "c") "f") "d")) true)

(check-equal? (accepting-state? (next-state
                                 (next-state
                                  (next-state
                                   (next-state
                                    (next-state
                                     (next-state
                                      (next-state
                                       (next-state
                                        (next-state
                                         (next-state
                                          (next-state
                                           (initial-state 0)
                                           "a")
                                          "b")
                                         "a")
                                        "c")
                                       "b")
                                      "a")
                                     "a")
                                    "d")
                                   "f")
                                  "e")
                                 "e")) true)

(check-equal? (error-state? (next-state (next-state (next-state (next-state (next-state (next-state (initial-state 0) "e") "a") "c") "b") "d") "d")) true)

(check-equal? (accepting-state? (next-state (next-state (next-state (next-state (next-state (next-state (initial-state 0) "a") "b") "c") "d") "e") "f")) true)
(check-equal? (state-A "c") "B")
(check-equal? (state-B "e") "error")
(check-equal? (state-C "f") "C")) 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;END;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-beginner-reader.ss" "lang")((modname coffee-machine) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f () #f)))
;; coffee-machine.rkt : Third Question of Problem Set 02. 
;; Goal: To make a coffee vending machine.

(require rackunit)
(require "extras.rkt")
(check-location "02" "coffee-machine.rkt")

(provide initial-machine
         machine-next-state
         machine-output
         machine-remaining-coffee
         machine-remaining-chocolate
         machine-bank)

;; IN-BUILT functions used from:
;; racket/base:
;;  integer? : (integer? v) → boolean? , true if v is an Integer, false otherwise.
;;  string=? : (string=? str1 str2 ...+) → boolean? , true if all arguments are equal?
;;  cond : (cond [(> 5 9) 9][else 5]) = 5, Multiple Conditional Check
;;  and : (and expr ...) → boolean? , true iff both values are true
;;  if : (if (> 5 -5) "5 is large" "-5 is large"), Conditional Check

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; CONSTANTS
;; Price in cents
(define coffee-price 150)
(define hot-chocolate-price 60)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; DATA DEFINITIONS
(define-struct machine (cofe choc money credit))

;; A machine is a (make-machine PosInt PosInt PosInt PosInt)
;; cofe - number of coffee in the machine 
;; choc - number of coffee in the machine
;; money - amount of money in the machine's Bank, in  cents
;; credit - amount of money inserted by the customer into the machine, in cents

;; (define machine-fn m)
;;   (...
;;     (machine-cofe m)
;;     (machine-choc m)
;;     (machine-money m)
;;     (machine-credit m)))
;;
;; TEMPLATE:
;; CustomerInput is one of the following:
;;  A PosInt - amount to machine in cents
;;  "change" - request change
;;  "hot chocolate" - request hot chocolate
;;  "coffee" - request coffee
#|
(define (cust-fn input)
  (cond
    [(integer? input) ...]
    [(string=? input "change") ...]
    [(string=? input "coffee") ...]
    [(string=? input "hot chocolate")...]))
|#

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; initial-machine : NonNegInt NonNegInt -> MachineState
;; GIVEN: a number of cups of coffee and of hot chocolate
;; RETURNS: the state of a machine loaded with the given number of cups
;;          of coffee and of hot chocolate, with an empty bank.
;; EXAMPLES:
;; (initial-machine 3 4) = (make-machine 3 4 0 0)
;; DESIGN STRATEGY: none
(define (initial-machine num_coffee num_chocolate)
  (make-machine num_coffee num_chocolate 0 0))

;; machine-next-state : MachineState CustomerInput -> MachineState
;; GIVEN: a machine state and a customer input
;; RETURNS: the state of the machine that should follow the customer's input
;; EXAMPLES:
;; (machine-next-state (make-machine 3 4 0 0) 150) = (make-machine 3 4 0 150)
;; (machine-next-state (make-machine 3 4 0 175) "coffee") = (make-machine 2 4 150 25)
;; DESIGN STRATEGY: Divide into Cases based on Customer's Credit
(define (machine-next-state current-state input)
  (cond 
    [(< (machine-credit current-state) hot-chocolate-price) (state-1 current-state input)]
    [(>= (machine-credit current-state) coffee-price) (state-3 current-state input)]
    ; coffee-price Check is above 60 so as to limit state-2 input b/w 60 and 150    
    [(>= (machine-credit current-state) hot-chocolate-price ) (state-2 current-state input)]
    [else current-state]))

;; machine-output : MachineState CustomerInput -> MachineOutput
;; GIVEN: a machine state and a customer input
;; RETURNS: a MachineOutput that describes the machine's
;;          response to the customer input.
;; EXAMPLES:
;; (machine-output (make-machine 0 1 0 24) "hot chocolate") = "hot chocolate"
;; (machine-output (make-machine 0 0 0 24) "coffee") = "Out of Item"
;; DESIGN STRATEGY: Use Template CustomerInput on input
(define (machine-output current-state input)
  (cond
    [(integer? input) "Nothing"]
    [(string=? input "change") (dispense-change current-state)]
    [(string=? input "coffee") (dispense-coffee current-state)]
    [(string=? input "hot chocolate") (dispense-hot-chocolate current-state)]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; machine-remaining-coffee : MachineState -> NonNegInt
;; GIVEN: a machine state
;; RETURNS: the number of cups of coffee left in the machine
;; EXAMPLES:
;; (machine-remaining-coffee (make-machine 0 1 0 240)) = 0
;; DESIGN STRATEGY: Combine Simpler Functions
(define (machine-remaining-coffee current-state)
  (machine-cofe current-state))

;; machine-remaining-chocolate : MachineState -> NonNegInt
;; GIVEN: a machine state
;; RETURNS: the number of cups of hot chocolate left in the machine
;; EXAMPLES:
;; (machine-remaining-chocolate (make-machine 0 1 0 240)) = 1
;; DESIGN STRATEGY: Combine Simpler Functions
(define (machine-remaining-chocolate current-state)
  (machine-choc current-state))

;; machine-bank : MachineState -> NonNegInt
;; GIVEN: a machine state
;; RETURNS: the amount of money in the machine's bank, in cents
;; EXAMPLES:
;; (machine-bank (make-machine 0 1 150 240)) = 150
;; DESIGN STRATEGY: Combine Simpler Functions
(define (machine-bank current-state)
  (machine-money current-state))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; dispense-coffee : MachineState -> String
;; dispense-hot-chocolate : MachineState -> String
;; GIVEN: a machine state
;; RETURNS: MachineOutput based on Inventory and Credit
;; INTERPRETATION:
;; MachineOutput = "coffee"|"hot chocolate"|"Out of Item"|"Nothing"
;; EXAMPLES:
;; (dispense-coffee (make-machine 1 0 0 240)) = "coffee"
;; (dispense-hot-chocolate (make-machine 1 0 1000 25)) = "Out of Item"
;; DESIGN STRATEGY: Divide into Cases based on Customer's Credit and
;;                  Machine's Inventory of Coffee/Hot Chocolate.
(define (dispense-coffee current-state)
  (cond
    [(and (>= (machine-credit current-state) coffee-price)
          (> (machine-cofe current-state) 0))
     "coffee"] 
    [(= (machine-cofe current-state) 0) "Out of Item"]
    [else "Nothing"]))

(define (dispense-hot-chocolate current-state)
  (cond
    [(and (>= (machine-credit current-state) hot-chocolate-price)
          (> (machine-choc current-state) 0))
     "hot chocolate"]
    [(= (machine-choc current-state) 0) "Out of Item"]    
    [else "Nothing"]))    

;; dispense-change : MachineState -> PosInt
;; GIVEN: a machine state
;; RETURNS: The amount of Customer's Change left in the Machine 
;; EXAMPLES:
;; (dispense-change (make-machine 1 0 0 0 0 20)) = 20
;; (dispense-hot-chocolate (make-machine 1 0 1000 0 0 0)) = 0
;; DESIGN STRATEGY: Combine Simpler Functions
(define (dispense-change current-state)
  (if (= (machine-credit current-state) 0) "Nothing" (machine-credit current-state)))

;; add-money : MachineState PostInt -> MachineState
;; GIVEN: A MahineState and a Input
;; RETURNS: New State with GIVEN Input Money added to 
;;          the GIVEN MachineState's Customer's Credit
;; EXAMPLES:
;; (add-money (make-machine 0 0 0 0) 300) = (make-machine 0 0 0 300)
;; (add-money (make-machine 0 0 5 10) 25) = (make-machine 0 0 5 35)
;; DESIGN STRATEGY: Combine Simpler Functions
(define (add-money current-state input)
  (make-machine
   (machine-cofe current-state)
   (machine-choc current-state)
   (machine-money current-state)     
   (+ (machine-credit current-state) input)))

;; coffee-ordered : MachineState -> MachineState
;; hot-chocolate-ordered : MachineState -> MachineState
;; GIVEN:
;; RETURNS: MachineState like the given one, with updated Coffee/Hot Chocolate
;;          count, money in Machine Bank and Customer's Credit.
;;
;; EXAMPLES:
;; (coffee-ordered (make-machine 7 0 425 200)) = (make-machine 6 0 575 50)
;; (hot-chocolate-ordered (make-machine 0 4 425 200)) = (make-machine 0 3 485 140)
;; DESIGN STRATEGY: Divide into Cases based on Customer's Credit and
;;                  Machine's Inventory of Coffee/Hot Chocolate.
(define (coffee-ordered current-state)
  (cond
    [(and
      (>= (machine-credit current-state) coffee-price)
      (> (machine-remaining-coffee current-state) 0))
     (make-machine
      (- (machine-cofe current-state) 1)
      (machine-choc current-state)
      (+ (machine-money current-state) coffee-price)      
      (- (machine-credit current-state) coffee-price))]
    [else current-state]))

(define (hot-chocolate-ordered current-state)
  (cond
    [(and
      (>= (machine-credit current-state) hot-chocolate-price)
      (> (machine-remaining-chocolate current-state) 0))
     (make-machine
      (machine-cofe current-state)
      (- (machine-choc current-state) 1)
      (+ (machine-money current-state) hot-chocolate-price)
      (- (machine-credit current-state) hot-chocolate-price))]
    [else current-state]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; state-1 : MachineState CustomerInput -> MachineState
;; state-2 : MachineState CustomerInput -> MachineState
;; state-3 : MachineState CustomerInput -> MachineState
;; state-4 : MachineState CustomerInput -> MachineState
;; GIVEN: a machine state and a customer input
;; RETURNS: the state of the machine that should follow the customer's input
;; EXAMPLES:
;; (state-1 (make-machine 2 3 0 0) 500) = (make-machine 2 3 0 500)
;; (state-2 (make-machine 2 3 0 500) "hot chocolate") = (make-machine 2 2 60 440)
;; (state-3 (make-machine 2 2 60 440) "coffee") = (make-machine 1 2 210 290)
;; (state-4 (make-machine 1 2 210 290) 0) = (make-machine 1 2 210 290)
;; DESIGN STRATEGY: Use Template CustomerInput on input
(define (state-1 current-state input)
  (cond
    [(integer? input) (state-4 current-state input)]   
    [(string=? input "change") current-state]
    [(string=? input "coffee") current-state]
    [(string=? input "hot chocolate") current-state]))

(define (state-2 current-state input)
  (cond
    [(integer? input) (state-4 current-state input)]
    [(string=? input "coffee") current-state]
    [(string=? input "hot chocolate") (hot-chocolate-ordered current-state)]    
    [(string=? input "change") current-state])) 
 
(define (state-3 current-state input)
  (cond
    [(integer? input) (state-4 current-state input)] 
    [(string=? input "coffee") (coffee-ordered current-state)]
    [(string=? input "hot chocolate") (hot-chocolate-ordered current-state)]    
    [(string=? input "change") current-state]))

(define (state-4 current-state input)
  (cond
    [(= input 0) current-state]
    [(> input 0) (add-money current-state input)])) 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; TESTS
(begin-for-test
  (check-equal? (machine-output (machine-next-state (machine-next-state (machine-next-state (machine-next-state (machine-next-state (initial-machine 1 1) 25) 25) 25) "hot chocolate") "coffee") "change") 15
                "The Example mentioned in the Question")  
  (check-equal? (machine-output (machine-next-state (machine-next-state (initial-machine 0 1) 10) "coffee") "change") 10
                "Checking output on Coffee request when there is no coffee in machine but customer has inserted money, later custommer asks for change")
  (check-equal? (machine-output (machine-next-state (machine-next-state (machine-next-state (machine-next-state (initial-machine 1 1) 450) "hot chocolate") "hot chocolate") "coffee") "change") 240
                "Customer wants 2 hot-chocolate, After finding out there is only 1 available Customer instead orders coffee and asks for change afterwards")
  (check-equal? (machine-output (machine-next-state (machine-next-state (machine-next-state (machine-next-state (machine-next-state (initial-machine 2 0) 150) "coffee") 150) "coffee") "change") "change")"Nothing"
                "Checks what is returned on asking for change not one but two times when there if no Customer's Money inside Machine, it can't return Zero so it does Nothing")
  (check-equal? (machine-output (machine-next-state (machine-next-state (initial-machine 1 1) 150) "hot chocolate") "hot chocolate") "Out of Item"
                "Rudimentary Inventory test")
  (check-equal? (machine-output (machine-next-state (initial-machine 1 1) 150) "hot chocolate") "hot chocolate"
                "Rudimentary Inventory test")
  (check-equal? (machine-output (initial-machine 1 1) 56) "Nothing"
                "Machine Output Test")
  (check-equal? (machine-output (machine-next-state (machine-next-state (initial-machine 1 1) 120) "hot chocolate") "hot chocolate") "Out of Item"
                "Machine Output State Test on Count 1 Inventory")
  (check-equal? (machine-remaining-coffee (make-machine 0 1 0 240)) 0)
  (check-equal? (machine-remaining-chocolate (make-machine 0 1 0 240)) 1)
  (check-equal? (machine-bank (make-machine 0 1 0 240)) 0)
  (check-equal? (dispense-coffee (make-machine 0 1 0 240)) "Out of Item")
  (check-equal? (dispense-hot-chocolate (make-machine 0 1 0 240)) "hot chocolate")
  (check-equal? (dispense-change (make-machine 0 1 0 240)) 240)
  (check-equal? (coffee-ordered (make-machine 0 1 0 240)) (make-machine 0 1 0 240))
  (check-equal? (hot-chocolate-ordered (make-machine 0 1 0 240)) (make-machine 0 0 60 180))
  (check-equal? (state-1 (make-machine 0 1 0 240) 50) (make-machine 0 1 0 290))
  (check-equal? (state-2 (make-machine 0 1 0 240) "hot chocolate") (make-machine 0 0 60 180))
  (check-equal? (state-3 (make-machine 0 1 0 240) "coffee") (make-machine 0 1 0 240))
  (check-equal? (state-4 (make-machine 0 1 0 240) 0) (make-machine 0 1 0 240))) 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;END;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


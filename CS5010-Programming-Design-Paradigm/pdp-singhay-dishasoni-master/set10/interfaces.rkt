#lang racket

(require rackunit)
(require "extras.rkt")
(require "sets.rkt")
(require "WidgetWorks.rkt")
(require 2htdp/universe)   
(require 2htdp/image)

(provide CANVAS-WIDTH
         CANVAS-HEIGHT
         HALF-CANVAS-WIDTH
         HALF-CANVAS-HEIGHT
         EMPTY-CANVAS
         Toy<%>
         Target<%>
         PlaygroundState<%>
         TARGET-INITIAL-X
         TARGET-INITIAL-Y
         NEW-SQUARE-KEY-EVENT
         NEW-THROBBER-KEY-EVENT
         NEW-CLOCK-KEY-EVENT
         NEW-FOOTBALL-KEY-EVENT
         OTHER-KEY-EVENT)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; CONSTANTS

;; Canvas Dimensions
(define CANVAS-HEIGHT 600)
(define CANVAS-WIDTH 500)
(define HALF-CANVAS-WIDTH (/ CANVAS-WIDTH 2))
(define HALF-CANVAS-HEIGHT (/ CANVAS-HEIGHT 2))
(define EMPTY-CANVAS (empty-scene CANVAS-WIDTH CANVAS-HEIGHT))


;; Target Dimensions
(define TARGET-INITIAL-X HALF-CANVAS-WIDTH)
(define TARGET-INITIAL-Y HALF-CANVAS-HEIGHT)

;; KeyEvents
(define NEW-SQUARE-KEY-EVENT "s")
(define NEW-THROBBER-KEY-EVENT "t")
(define NEW-CLOCK-KEY-EVENT "w")
(define NEW-FOOTBALL-KEY-EVENT "f")
(define OTHER-KEY-EVENT "\b")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; DATA DEFINITION FOR LISTOFTOYS:

;; Toy<%> is a (make-block x y data)
;; INTERP:
;;  x    is the x-coordinate of the center of the toy
;;  y    is the y-coordinate of the center of the toy
;; data  some data related to the toy.  The interpretation of
    ;; this data depends on the class of the toy.
    ;; for a square, it is the velocity of the square (rightward is
    ;; positive)
    ;; for a throbber, it is the current radius of the throbber
    ;; for the clock, it is the current value of the clock
    ;; for a football, it is the current size of the football (in
    ;; arbitrary units; bigger is more)
;; TEMPLATE:
#|
  (define (toy-fn toy)
           (toy-x toy)
           (toy-y toy)
           (toy-data toy))
|#

;; A ListOfToy<%> is either
;; -- empty
;; -- (cons Toy<%> ListOfToy<%>)
;; TEMPLATE:
#|
  (define (lot-fn lobt)
           (toy-fn (first lot))
           (toy-fn (rest lot)))
|#
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; INTERFACES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define PlaygroundState<%>
  (interface (SWidget<%>) ;; this means: include all the methods in
                          ;; SWidget<%>. 
    
    ;; -> Integer
    ;; GIVEN:a target
    ;; RETURNS: the x and y coordinates of the target
    target-x
    target-y

     ;; -> Boolean
     ;; GIVEN:a target
     ;; RETURNS: true iff the target is selected
     ;; the default is false
     target-selected?

    ;; -> ListOfToy<%>
;    get-toys

))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define Toy<%> 
  (interface (SWidget<%>)  ;; this means: include all the methods in
                          ;;  SWidget<%>. 
 
    ;; -> Integer
    ;; GIVEN:a toy
    ;; RETURNS: the x or y position of the center of the toy
    toy-x
    toy-y

    ;; -> Integer
    ;; GIVEN:a toy
    ;; RETURNS: some data related to the toy.  The interpretation of
    ;; this data depends on the class of the toy.
    ;; for a square, it is the velocity of the square (rightward is
    ;; positive)
    ;; for a throbber, it is the current radius of the throbber
    ;; for the clock, it is the current value of the clock
    ;; for a football, it is the current size of the football (in
    ;; arbitrary units; bigger is more)
    toy-data
    ))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Target Interface implements the SWidget interface
;; Every Target% must implement Target<%>

(define Target<%>
  (interface (SWidget<%>) ;; this means: include all the methods in
                         ;; SWidget<%>. 
    
    ;; -> Integer
    ;; GIVEN: a target
    ;; RETURNS: the x and y coordinates of the target
    get-x
    get-y

    ;; -> Boolean
     ;; GIVEN:a target
     ;; RETURNS: true iff the target is selected
     ;; the default is false
    get-selected?
    )) 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

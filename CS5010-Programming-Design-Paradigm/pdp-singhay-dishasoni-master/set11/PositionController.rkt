#lang racket

;; displays as an outline rectangle with text showing the x and y
;; coordinates and velocity along these coordinates of the particle.

;; the rectangle is draggable

;; left,right arrow keys decrements or increments x-coordinate of the particle
;; by 5 up,down arrow keys decrements or increments y-coordinate of the
;; particle by 5

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; LIBRARIES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(require rackunit)
(require 2htdp/image)
(require "Model.rkt")
(require "extras.rkt")
(require 2htdp/universe)
(require "Interfaces.rkt")
(require "Controller.rkt")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; PROVIDE FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(provide PositionController%)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; CONSTANTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define POSITION-CHANGE-FACTOR 5)
(define POSITION-CONTROLLER-WIDTH 210)
(define POSITION-CONTROLLER-HEIGHT 60)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; CLASSES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; a PositionController% is a (new PositionController% [model Model<%>])

(define PositionController%
  (class* Controller% (Controller<%>)
    
    (inherit-field model x y)  
    (inherit-field particle-x particle-y particle-vx particle-vy)
    (inherit-field handler-selected? controller-selected? saved-mx saved-my)

    (define/override (width) POSITION-CONTROLLER-WIDTH)
    (define/override (height)POSITION-CONTROLLER-HEIGHT)
    
    (super-new)

    
    ;; after-key-event: KeyEvent -> Void
    ;; GIVEN: a keyevent
    ;; EFFECT : the position of the particle changes with the arrow keys
    ;; SRATEGY: cases on kev
    
    (define/override (after-key-event kev)
      (if controller-selected?
          (cond
            [(key=? LEFT-KEY-EVENT kev)
             (send model execute-command
                   (make-set-position
                    (- particle-x POSITION-CHANGE-FACTOR) particle-y))]
            [(key=? RIGHT-KEY-EVENT kev)
             (send model execute-command
                   (make-set-position
                    (+ particle-x POSITION-CHANGE-FACTOR) particle-y))]
            [(key=? UP-KEY-EVENT kev)
             (send model execute-command
                   (make-set-position
                    particle-x (- particle-y POSITION-CHANGE-FACTOR)))]
            [(key=? DOWN-KEY-EVENT kev)
             (send model execute-command
                   (make-set-position
                    particle-x (+ particle-y POSITION-CHANGE-FACTOR))
                   )])
          2345))


    ;; after-drag-inside-controller:Non Functional
    (define/override (after-drag-inside-controller mx my)
      "no functionality")
    
    ;; viewer-image->Image
    ;; RETURNS:the image of teh position controller
    ;; STRATEGY: Combining simpler functions
    (define/override (viewer-image)
         (data-image))

    ;; data-image->Image
    ;; RETURNS: a rectangle of a given width height displaying the  positions
    ;; and velocity of the particle
    ;; STRATEGY: Combining simpler functions 
    
    (define (data-image)
      (above
       (text "Arrow keys change position" 10
             (send this current-controller-color))
       (text (string-append
              "X = "
              (real->decimal-string particle-x) " "
              " Y = "
              (real->decimal-string particle-y))
             12
             (send this current-controller-color))
       (text (string-append
              "VX = "
              (real->decimal-string particle-vx) " "
              " VY = "
              (real->decimal-string particle-vy))
             12
             (send this current-controller-color))))
    ))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; TESTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define m (new Model%)) 
(define PositionCntrlr (new PositionController% [model m]))

(begin-for-test
  (check-equal? 
   (send PositionCntrlr after-drag-inside-controller 0 0)
   "no functionality") 
  (check-equal? (send PositionCntrlr after-key-event "up") 2345)

  ; Mouse Events inside Handler  
  (send PositionCntrlr after-button-down 300 250)
  (check-equal? (send PositionCntrlr for-test:x) 300)
  (check-equal? (send PositionCntrlr for-test:y) 250)
  (check-equal? (send PositionCntrlr for-test:particle-x) 75)
  (check-true (send PositionCntrlr for-test:controller-selected?))

  ; Key Events inside Controller  
  (send PositionCntrlr after-key-event LEFT-KEY-EVENT)
  (check-equal? (send PositionCntrlr for-test:particle-x) 70)
  (send PositionCntrlr after-key-event RIGHT-KEY-EVENT)
  (check-equal? (send PositionCntrlr for-test:particle-x) 75)
  (send PositionCntrlr after-key-event UP-KEY-EVENT)
  (check-equal? (send PositionCntrlr for-test:particle-y) 45)
  (send PositionCntrlr after-key-event DOWN-KEY-EVENT)
  (check-equal? (send PositionCntrlr for-test:particle-y) 50)
  
  (check-equal? 
   (send PositionCntrlr viewer-image)
   (send PositionCntrlr viewer-image)))


    
    
 


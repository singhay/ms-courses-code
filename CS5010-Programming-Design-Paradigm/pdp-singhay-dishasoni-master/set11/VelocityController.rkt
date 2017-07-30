#lang racket

;; displays as an outline rectangle with text showing the x and y
;; coordinates and velocity along these coordinates of the particle.

;; the rectangle is draggable

;; left,right arrow keys decrements or increments x-velocity of the particle
;; by 5 up,down arrow keys decrements or increments y-velocity of the
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

(provide VelocityController%)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; CONSTANTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define VELOCITY-CHANGE-FACTOR 5)
(define VELOCITY-CONTROLLER-WIDTH 210)
(define VELOCITY-CONTROLLER-HEIGHT 60)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; CLASSES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; a VelocityController% is a (new VelocityController% [model Model<%>])

(define VelocityController%
  (class* Controller% (Controller<%>)
    (inherit-field model x y)  
    (inherit-field particle-x particle-y particle-vx particle-vy)
    (inherit-field handler-selected? controller-selected? saved-mx saved-my)

    (define/override (width) VELOCITY-CONTROLLER-WIDTH)
    (define/override (height) VELOCITY-CONTROLLER-HEIGHT)
    
    (super-new)
    

    ;; after-key-event: KeyEvent -> Void
    ;; GIVEN: a keyevent
    ;; EFFECT : the velocities of the particle changes with the arrow keys
    ;; SRATEGY: cases on kev
    
    (define/override (after-key-event kev)
      (if controller-selected?
          (cond
            [(key=? LEFT-KEY-EVENT kev)
             (send model execute-command
                   (make-incr-velocity (* -1 VELOCITY-CHANGE-FACTOR) 0))]
            [(key=? RIGHT-KEY-EVENT kev)
             (send model execute-command
                   (make-incr-velocity VELOCITY-CHANGE-FACTOR 0))]
            [(key=? UP-KEY-EVENT kev)
             (send model execute-command
                   (make-incr-velocity 0 (* -1 VELOCITY-CHANGE-FACTOR)))]
            [(key=? DOWN-KEY-EVENT kev)
             (send model execute-command
                   (make-incr-velocity 0 VELOCITY-CHANGE-FACTOR)
                   )])
          3456))
   
  
    ;; viewer-image->Image
    ;; RETURNS:the image of teh position controller
    ;; STRATEGY: Combining simpler functions
    
    (define/override (viewer-image)
         (data-image))


    ;; after-drag-inside-controller:Non Functional
    (define/override (after-drag-inside-controller mx my)
      "no functionality")
    

   ;; Data-image->Image
    ;; RETURNS: a rectangle of a given width height displaying the  positions
    ;; and velocity of the particle
    ;; STRATEGY: Combining simpler functions
    
    (define (data-image)
      (above
       (text "Arrow keys change velocity" 10
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
(define VelocityCntrlr (new VelocityController% [model m]))

(begin-for-test
  (check-equal? 
   (send VelocityCntrlr after-drag-inside-controller 0 0)
   "no functionality") 
  (check-equal? (send VelocityCntrlr after-key-event "up") 3456)
  (send VelocityCntrlr after-button-down 300 250)
  (check-equal? (send VelocityCntrlr for-test:x) 300)
  (check-equal? (send VelocityCntrlr for-test:y) 250)
  (check-equal? (send VelocityCntrlr for-test:particle-vx) 0)
  (check-equal? (send VelocityCntrlr for-test:controller-selected?) #t)
  (send VelocityCntrlr after-key-event LEFT-KEY-EVENT)
  (check-equal? (send VelocityCntrlr for-test:particle-vx) -5)
  (send VelocityCntrlr after-key-event RIGHT-KEY-EVENT)
  (check-equal? (send VelocityCntrlr for-test:particle-vx) 0)
  (send VelocityCntrlr after-key-event UP-KEY-EVENT)
  (check-equal? (send VelocityCntrlr for-test:particle-vy) -5)
  (send VelocityCntrlr after-key-event DOWN-KEY-EVENT)
  (check-equal? (send VelocityCntrlr for-test:particle-vy) 0)
  (check-equal? 
   (send VelocityCntrlr viewer-image)
   (send VelocityCntrlr viewer-image)))
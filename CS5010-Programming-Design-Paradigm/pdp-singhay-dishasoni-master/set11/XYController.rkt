#lang racket

;; displays as an outline rectangle with text showing the x and y
;; coordinates and velocity along these coordinates of the particle.

;; the rectangle is draggable

;; left,right arrow keys decrements or increments x-coordinate
;; of the particle by 5
;; up,down arrow keys decrements or increments y-coordinate of
;; the particle by 5

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

(provide XYController%)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; CLASSES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; a XYController% is a (new XYController% [model Model<%>])

(define XYController%
  (class* Controller% (Controller<%>)
 
    (inherit-field model x y )  
    (inherit-field particle-x particle-y particle-vx particle-vy)
    (inherit-field handler-selected? controller-selected? saved-mx saved-my)
    (define/override (width) (+ (* 2 CONTROLLER-PADDING) PARTICLE-AREA-WIDTH))
    (define/override (height) (+ (* 2 CONTROLLER-PADDING) PARTICLE-AREA-HEIGHT))

    (field [pr-width PARTICLE-AREA-WIDTH])
    (field [pr-height PARTICLE-AREA-HEIGHT])
    (field [half-pr-width (/ pr-width 2)])
    (field [half-pr-height (/ pr-height 2)])
    
     
    (super-new)

   (send model register this)
    
    ;; after-button-down : NonNegInteger NonNegInteger -> Void
    ;; GIVEN: the location of a button-down event
    ;; EFFECT: makes the viewer selected
    ;; STRATEGY: Cases on whether the event is in this object

      (define/override (after-button-down mx my)
      (cond
        [(send this in-handler? mx my)
         (begin
            (set! handler-selected? true)
            (set! saved-mx (- mx x))
            (set! saved-my (- my y)))]
        [(in-particle-rectangle? mx my)
         (begin
            (set! controller-selected? true)
            (set! saved-mx (- mx particle-x))
            (set! saved-my (- my particle-y))
            (send model set-particle-selected true))]
        [else 3742]))   
    

     
    ;; after-drag-inside-controller : NonNegInteger NonNegInteger -> Void
    ;; GIVEN: the location of a button-down event
    ;; EFFECT: makes the particle dragged in the particle rectangle
    ;; STRATEGY: Cases on whether the event is in the particle rectangle

    (define/override (after-drag-inside-controller mx my)
      (if controller-selected?
          (begin
            (send model execute-command
                  (make-set-position
                   (- mx saved-mx ) (- my saved-my))))
          2744))
    
   ;; after-key-event: KeyEvent -> Void
    ;; GIVEN: a keyevent
    ;; EFFECT : no functionality
    
    (define/override (after-key-event kev)
      3456)


    ;; in-particle-rectangle? : NonNegInteger NonNegInteger -> Boolean
    ;; GIVEN: the mouse coordinates
    ;; RETURNS: true iff the mouse coordinates are in the inner particle
    ;; rectangle
    ;; STRATEGY: Combining simpler functions
    
    (define (in-particle-rectangle? mx my)
      (and
       (<= (- x half-pr-width) mx (+ x half-pr-width))
       (<= (- y half-pr-height) my (+ y half-pr-height))))

    ;; viewer-image->Image
    ;; RETURNS:the image of the image of the XY controller
    ;; STRATEGY: Combining simpler functions
    
    (define/override (viewer-image)
      (overlay (rectangle  pr-width  pr-height "outline" "blue")
      (place-image  (data-image) particle-x particle-y
                   (rectangle pr-width pr-height "outline" "blue"))))
      
        
    ;; data-image->Image
    ;; RETURNS: the particle image
    ;; STRATEGY: Combining simpler functions
    
    (define (data-image)
       (overlay
        (circle PARTICLE-RADIUS "solid" "black")
        (circle CIRCLE-RADIUS "solid" "red")))   
      ))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; TESTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define m (new Model%)) 
(define XYCntrlr (new XYController% [model m]))

(begin-for-test
  (check-equal? (send XYCntrlr after-button-down 1000 1000) 3742
                "Nothing is selected!")
  (check-equal? (send XYCntrlr after-drag-inside-controller 0 0) 2744
                "Nothing is selected!")

  ; Mouse Events inside Controller  
  (send XYCntrlr after-button-down 300 250)
  (check-true (send XYCntrlr for-test:controller-selected?))  
  (send XYCntrlr after-drag-inside-controller 320 260)
  (check-equal?
   (send XYCntrlr for-test:particle-x) 95)
  (check-equal?
   (send XYCntrlr for-test:particle-y) 60)

  ; Mouse Events inside Handler
  (send XYCntrlr after-button-down 205 180)
  
  (check-equal? (send XYCntrlr after-key-event "k") 3456)
  (check-equal? 
   (send XYCntrlr viewer-image)
   (send XYCntrlr viewer-image)))


    
    
 


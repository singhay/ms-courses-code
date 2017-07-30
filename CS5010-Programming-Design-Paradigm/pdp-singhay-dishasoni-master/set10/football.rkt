#lang racket

(require "interfaces.rkt")
(require "extras.rkt")
(require rackunit)
(require 2htdp/image)

(provide make-football)

(define RATE-OF-SIZE-CHANGE 2)
;; Football start at the center of the target and shrinks till size zero
;; instantaneously.
;; They are selectable and draggable.

;; A Football is a (new Football% [x Integer][y Integer]
;; these 3 are optional           [selected? Boolean][mx Integer][my Integer]
;;                                [scale-count PosInt])

;; A Football represents a football image.
(define Football%
  (class* object% (Toy<%>)
    
    ;; the init-fields are the values that may vary from one Football to
    ;; the next.
    
    ; the x and y position of the center of the Football
    (init-field x y)   
    
    ; is the football selected? Default is false.
    (init-field [selected? false]) 
    
    ;; if the Football is selected, the position of
    ;; the last button-down event inside the Football, relative to the
    ;; Football's center.  Else any value.
    (init-field [saved-mx 0] [saved-my 0])
        
    ; the Football's image scaling counter
    (init-field [scale-count 1])   

    ;; private data for objects of this class.
    ;; these can depend on the init-fields.
    
    ; image for displaying the Football
    (define (FOOTBALL-IMG) (bitmap "football.jpg"))
    (define(updated-football-scale)
            (if (> scale-count 0)
                (- scale-count (/ RATE-OF-SIZE-CHANGE 10))
                scale-count))
          (define(scaled-football-image)
            (if (> scale-count 0)
                (scale scale-count (FOOTBALL-IMG))
                empty-image))
           (define(scaled-ftbl-hiet)
            (image-height (scaled-football-image)))
           (define(scaled-ftbl-wdth)
            (image-width (scaled-football-image)))
          (define(hlf-ftbl-wdth) (/ (scaled-ftbl-wdth) 2))
          (define(limit-x) (- CANVAS-WIDTH (hlf-ftbl-wdth)))
           (define(hlf-ftbl-hiet) (/ (scaled-ftbl-hiet) 2))
           (define(limit-y) (- CANVAS-HEIGHT (hlf-ftbl-hiet)))
           (define(ftbl-area) (*
                       (scaled-ftbl-wdth)
                       (scaled-ftbl-hiet)))

    (super-new)
    
    ;; after-tick : Time -> Void
    ;; RETURNS: A Football like this one, but as it should be after a tick
    ;; a selected Football doesn't move.
    ;; STRATEGY: Cases on selected?
    (define/public (after-tick)
      (if selected?
          this
          (set! scale-count (updated-football-scale))))
    
    ;; after-key-event : KeyEvent -> Void
    ;; RETURNS: A world like this one, but as it should be after the
    ;; given key event.
    ;; DETAILS: a Football ignores key events
    (define/public (after-key-event kev)
      this)      
    
    ; after-button-down : Integer Integer -> Void
    ; GIVEN: the location of a button-down event
    ; STRATEGY: Cases on whether the event is in the Football
    (define/public (after-button-down mx my)
      (if (in-football? mx my)
         (begin
          (set! selected? true)
          (set! saved-mx (- mx x))
          (set! saved-my (- my y)))
        this))
    
    ; after-button-up : Integer Integer -> Void
    ; GIVEN: the location of a button-up event
    ; STRATEGY: Cases on whether the event is in the Football.
    ; If the Football is selected, then unselect it.
    (define/public (after-button-up mx my)
       (set! selected? false))
    
    ; after-drag : Integer Integer -> Void
    ; GIVEN: the location of a drag event
    ; STRATEGY: Cases on whether the Football is selected.
    ; If it is selected, move it so that the vector from the center to
    ; the drag event is equal to (mx, my)
    (define/public (after-drag mx my)
      (if selected?
         (begin
          (set! x (calculate-x mx))
          (set! y (calculate-y my)))
        this))     
    
    ; calculate-x : Integer -> Integer
    ; calculate-y : Integer ->Integer
    ; GIVEN: the x/y coordinate of the mouse event
    ; RETURNS: x/y coordinate of the target 
    ; STRATEGY: Cases on whether the position of target
    ;;          is within limits.
    (define (calculate-x mx)
      (local
        ((define x (- mx saved-mx)))
        (cond
          [(<= x (hlf-ftbl-wdth)) (hlf-ftbl-wdth)]
          [(>= x (limit-x)) (limit-x)]
          [else x])))
    
    (define (calculate-y my)
      (local
        ((define y (- my saved-my)))       
        (cond
          [(<= y (hlf-ftbl-hiet)) (hlf-ftbl-hiet)]
          [(>= y (limit-y)) (limit-y)]
          [else y])))
    
    ;; to-scene : Scene -> Scene
    ;; RETURNS: a scene like the given one, but with this Football painted
    ;; on it.
    (define/public (add-to-scene scene)
      (place-image (scaled-football-image) x y scene)) 
    
    ;; in-football? : Integer Integer -> Boolean
    ;; GIVEN: a location on the canvas
    ;; RETURNS: true iff the location is inside this Football.
    (define (in-football? other-x other-y)
      (and (<= (abs (- x other-x)) (hlf-ftbl-wdth))
           (<= (abs (- y other-y)) (hlf-ftbl-hiet))))   

    ;; toy-x : -> Integer
    ;; toy-y : -> Integer
    ;; RETURNS the respective x/y position of the square
    (define/public (toy-x) x)   
    (define/public (toy-y) y)

    ;; toy-data : -> Integer
    ;; RETURNS the area of football  
    (define/public (toy-data) (ftbl-area))
    
    ;; test methods, to probe the Football state.  Note that we don't have
    ;; a probe for radius.       
    (define/public (for-test:x) x)
    (define/public (for-test:y) y)
    (define/public (for-test:selected?) selected?)
    (define/public (for-test:ftbl-area) (ftbl-area))
    ))

;; make-football : PosInt PostInt -> Toy<%>
;; GIVEN: an x and a y position
;; RETURNS: an object representing a football at the given position.
(define (make-football x y)
  (new Football% [x x][y y]))




;; Tests for Football

(begin-for-test
  (local
    ((define FOOTBALL (make-football TARGET-INITIAL-X
                                TARGET-INITIAL-Y))

     (define FOOTBALL-SEL (new Football% 
                            [x TARGET-INITIAL-X]
                            [y TARGET-INITIAL-Y]
                            [selected? true]))

     (define FOOTBALL-SEL-1 (new Football% 
                            [x 71]
                            [y 80]
                            [selected? true]))

     (define FOOTBALL-SEL-2 (new Football% 
                            [x 429]
                            [y 520]
                            [selected? true]))

     (define FOOTBALL-AFTER-TICK (new Football% 
                            [x TARGET-INITIAL-X]
                            [y TARGET-INITIAL-Y]
                            [scale-count 0.8]))

     (define FOOTBALL-NEG-SCALE (new Football% 
                            [x TARGET-INITIAL-X]
                            [y TARGET-INITIAL-Y]
                            [scale-count -1])))

    (send FOOTBALL after-button-down 800 800)
    (check-equal?
        (send FOOTBALL for-test:selected?)
        false "Football should not be selected on button down outside the image")

    (send FOOTBALL after-button-up 800 800)
    (check-equal?
        (send FOOTBALL for-test:selected?)
        false "Football selected should not change on button up outside the image")
    
    (send FOOTBALL after-button-down TARGET-INITIAL-X TARGET-INITIAL-Y)
    (check-equal?
        (send FOOTBALL for-test:selected?) true "Football should be selected on button down")

    (send FOOTBALL after-button-up TARGET-INITIAL-X TARGET-INITIAL-Y)
    (check-equal?
        (send FOOTBALL for-test:selected?) false "Football should be un-selected on button up")
    
    (send FOOTBALL after-drag TARGET-INITIAL-X TARGET-INITIAL-Y)
    (check-equal?
        (send FOOTBALL for-test:x)
        TARGET-INITIAL-X "Football with selected false should be dragged in x direction")
    (check-equal?
        (send FOOTBALL for-test:y)
        TARGET-INITIAL-Y "Football with selected false should be dragged in y direction")
    
    (send FOOTBALL-SEL after-drag TARGET-INITIAL-X TARGET-INITIAL-Y)
    (check-equal?
        (send FOOTBALL-SEL for-test:x)
        TARGET-INITIAL-X "Football with selected true should be dragged in x direction")
    (check-equal?
        (send FOOTBALL-SEL for-test:y)
        TARGET-INITIAL-Y "Football with selected true should be dragged in y direction")

    (send FOOTBALL-NEG-SCALE after-drag TARGET-INITIAL-X TARGET-INITIAL-Y)
    (check-equal?
        (send FOOTBALL-NEG-SCALE for-test:x)
        TARGET-INITIAL-X "Football with selected true should be dragged in x direction")
    (check-equal?
        (send FOOTBALL-NEG-SCALE for-test:y)
        TARGET-INITIAL-Y "Football with selected true should be dragged in y direction")

    (send FOOTBALL-SEL after-drag -100 -100)
    (check-equal?
        (send FOOTBALL-SEL for-test:x)
        (send FOOTBALL-SEL-1 toy-x) "Football can only be dragged within canvas")
    (check-equal?
        (send FOOTBALL-SEL for-test:y)
        (send FOOTBALL-SEL-1 toy-y) "Football can only be dragged within canvas")

    (send FOOTBALL-SEL after-drag 800 800)
    (check-equal?
        (send FOOTBALL-SEL for-test:x)
        (send FOOTBALL-SEL-2 toy-x) "Football can only be dragged within canvas")
    (check-equal?
        (send FOOTBALL-SEL for-test:y)
        (send FOOTBALL-SEL-2 toy-y) "Football can only be dragged within canvas")

    (check-equal?
           (send FOOTBALL after-key-event OTHER-KEY-EVENT)
           FOOTBALL "No effect on football object after-key-event")
    
    (check-equal? 
           (send FOOTBALL-SEL after-tick)
           FOOTBALL-SEL "A selected football should not change after tick")

    (check-equal? (send FOOTBALL toy-data)
                (* (image-width (bitmap "football.jpg"))
                   (image-height (bitmap "football.jpg"))))

    
    (check-equal? (send FOOTBALL add-to-scene EMPTY-CANVAS)
                  (place-image (bitmap "football.jpg")
                               TARGET-INITIAL-X TARGET-INITIAL-Y
                               EMPTY-CANVAS))
    
    (send FOOTBALL after-tick)
    (check-equal?
     (send FOOTBALL for-test:ftbl-area)
     (send FOOTBALL-AFTER-TICK toy-data) "After tick the area should have grown")

    (send FOOTBALL-NEG-SCALE after-tick)
    (check-equal?
    (send FOOTBALL-NEG-SCALE for-test:ftbl-area)
    0) "After negative scale the football should disappear"))
    

#lang racket

(require "interfaces.rkt")   
(require 2htdp/image)
(require rackunit)
(require "extras.rkt")

(provide new-target)


;; Target Dimensions
(define TARGET-RADIUS 10)
(define TARGET-MODE "outline")
(define TARGET-COLOR "green")
(define TARGET-IMG (circle TARGET-RADIUS TARGET-MODE TARGET-COLOR))
(define TARGET-MIN TARGET-RADIUS)
(define TARGET-X-MAX (- CANVAS-WIDTH TARGET-RADIUS))
(define TARGET-Y-MAX (- CANVAS-HEIGHT TARGET-RADIUS))

;; A Target is a (new Target% [x Integer][y Integer]
;; these 3 are optional       [selected? Boolean][mx Integer][my Integer])
;; REPRESENTS: a green circle of radius 10 in outline mode.

(define Target%
  (class* object% (Target<%>)
    
    (init-field
      x                         ; Integer, x pixels of center from left
      y)                        ; Integer, y pixels of center from top
    
    ; is the target selected? Default is false.
    (init-field [selected? false]) 
    
    ;; if the target is selected, the position of
    ;; the last button-down event inside the target, relative to the
    ;; target's center. Default is 0.
    (init-field [saved-mx 0] [saved-my 0])
    
    (super-new)
    
    ;; get-x : -> Integer
    ;; get-y : -> Integer
    ;; GIVEN: A target
    ;; RETURNS : the x/y coordinate of the target
    (define/public (get-x)
      x)
    (define/public (get-y)
      y)
    
    ;; get-selected? -> Boolean
    ;; GIVEN: A target
    ;; RETURNS : true iff the target is selected
    (define/public (get-selected?)
      selected?)
    
    ;; add-to-scene : Scene -> Scene
    ;; GIVEN:A scene
    ;; RETURNS: a scene like the given one, but with this target painted
    ;; on it.
    (define/public (add-to-scene scene)
      (place-image TARGET-IMG x y scene))   
    
    ;; after-button-down : Nat Nat -> Void
    ;; GIVEN:  the mouse coordinates of a location
    ;; WHERE: the button-down event has occurred
    ;; RETURNS: the target after the button-down event has occurred
    ;; STRATEGY: Cases on whether the event is in the target
    (define/public (after-button-down mx my)
      (if (in-target? mx my)
     (begin
          (set! selected? true)
          (set! saved-mx (- mx x))
          (set! saved-my (- my y)))
        this))
   
    ;; after-button-up : Nat Nat -> Void
    ;; GIVEN:  the mouse coordinates of a location
    ;; WHERE: the button-up event has occurred
    ;; RETURNS: the target after the button-up event has occurred
    ;; STRATEGY: Cases on whether the event is in the target.
    ;; If the target is selected, then unselect it.
    (define/public (after-button-up mx my)
    (set! selected? false)
        this)
    
    ;; after-drag : Nat Nat -> Void
    ;; GIVEN: the location of a drag event
    ;; WHERE: the button-up event has occurred
    ;; RETURNS: the target after the button-up event has occurred
    ;; STRATEGY: Cases on whether the target is selected.
    ;; If it is selected, move it so that the vector from the center to
    ;; the drag event is equal to (mx, my)
    (define/public (after-drag mx my)
      (if selected?
     (begin
          (set! x (calculate-x mx))
          (set! y (calculate-y my)))
        this)) 
    
    ; calculate-x : Nat -> Integer
    ; calculate-y : Nat ->Integer
    ; GIVEN: the x/y coordinate of the mouse event
    ; RETURNS: x/y coordinate of the target after the drag-event 
    ; STRATEGY: Cases on whether the position of target
    ;;          is within limits.

    (define (calculate-x mx)
      (local
        ((define x (- mx saved-mx)))
      (cond
        [(<= x TARGET-MIN) TARGET-MIN]
        [(>= x TARGET-X-MAX) TARGET-X-MAX]
        [else x])))
    
    (define (calculate-y my)
      (local
        ((define y (- my saved-my)))
      (cond
        [(<= y TARGET-MIN) TARGET-MIN]
        [(>= y TARGET-Y-MAX) TARGET-Y-MAX]
        [else y])))    
    
    ;; in-target? : Nat Nat -> Boolean
    ;; GIVEN: a location on the canvas
    ;; RETURNS: true iff the location is inside this target.
    ;; STRATEGY:Combine simpler functions
    (define (in-target? other-x other-y)
      (<= (+ (sqr (- x other-x)) (sqr (- y other-y)))
          (sqr TARGET-RADIUS)))
    
    ;; the target doesn't have any other behaviors
    
    ;; after-tick :  -> Target
    ;; RETURNS: A Target like this one, but as it should be after the
    ;; given mouse event.
    ;; DETAILS: target ignores mouse events
    (define/public (after-tick) this)
    
    ;; after-key-event : KeyEvent -> Target
    ;; GIVEN: a keyevent
    ;; RETURNS: A Target like this one, but as it should be after the
    ;; given key event.
    ;; DETAILS: target ignores key events
    (define/public (after-key-event kev) this)
    
    ;; after-mouse-event : KeyEvent -> Target
    ;; GIVEN: a keyevent
    ;; RETURNS: A Target like this one, but as it should be after the
    ;; given mouse event.
    ;; DETAILS: target ignores mouse events
    
    (define/public (after-mouse-event mev) this)


    ;; Test methods
    (define/public (for-test:x)      x)
    (define/public (for-test:y)      y)
    (define/public (for-test:selected?)   selected?)
    ))

;; new-target : -> SWidget<%>
;; RETURNS a new target placed at the center of the canvas initially

(define (new-target)
  (new Target% [x TARGET-INITIAL-X]
               [y TARGET-INITIAL-Y]))


(begin-for-test
  (local
    ((define TARGET-SEL (new Target%
                        [x HALF-CANVAS-WIDTH]
                        [y HALF-CANVAS-HEIGHT]
                        [selected? true]))
     (define TARGET (new-target)) 
     (define TARGET-SEL-1 (new Target%
                        [x TARGET-RADIUS]
                        [y TARGET-RADIUS]
                        [selected? true]))
     (define TARGET-SEL-2 (new Target%
                        [x HALF-CANVAS-WIDTH]
                        [y HALF-CANVAS-HEIGHT]
                        [selected? true])))
     (send TARGET get-x)
    (check-equal?
           (send TARGET for-test:x)TARGET-INITIAL-X
         "the clock's x position")
    (send TARGET get-y)
    (check-equal?
           (send TARGET for-test:y)TARGET-INITIAL-Y
         "the clock's y position")
     (send TARGET get-selected?)
    (check-equal?
           (send TARGET for-test:selected?)false
         "the clock's ticks")
    (check-equal?
        (send TARGET after-tick)
        TARGET)
     (check-equal?
        (send TARGET after-mouse-event "drag")
        TARGET)
  (check-equal?
        (send TARGET-SEL after-key-event OTHER-KEY-EVENT)
       TARGET-SEL)

    (send TARGET-SEL after-button-up HALF-CANVAS-WIDTH HALF-CANVAS-HEIGHT)  
    (check-equal?
        (send TARGET-SEL for-test:selected?) false
        "the clock should be unselected")

     (send TARGET-SEL after-button-up 80 100)
    (check-equal?
        (send TARGET-SEL for-test:selected?) false
        "the clock should be unselected")

    (send TARGET-SEL after-button-down 800 800)
    (check-equal?
        (send TARGET-SEL for-test:selected?) false
        "the unselected clock shoule remain unselected")

    (send TARGET-SEL after-button-down HALF-CANVAS-WIDTH HALF-CANVAS-HEIGHT)
    (check-equal?
        (send TARGET-SEL for-test:selected?) true
        "the clock should be selected after button down")
    
      (send TARGET-SEL after-button-down HALF-CANVAS-WIDTH HALF-CANVAS-HEIGHT)          
  (send TARGET-SEL after-drag -1 -2)
    (check-equal?
           (send TARGET-SEL for-test:x) TARGET-RADIUS
         "the clock is dragged to a new x position")
    (check-equal?
           (send TARGET-SEL for-test:y) TARGET-RADIUS
         "the clock is dragged to a new y position")
   (send TARGET-SEL after-drag 700 800)
    (check-equal?
           (send TARGET-SEL for-test:x) (- CANVAS-WIDTH TARGET-RADIUS)
         "the clock is dragged to a new x position")
    (check-equal?
           (send TARGET-SEL for-test:y) (- CANVAS-HEIGHT TARGET-RADIUS)
         "the clock is dragged to a new y position")
    

    (check-equal? (send TARGET-SEL-1 add-to-scene EMPTY-CANVAS)
               (place-image TARGET-IMG
                            TARGET-RADIUS
                            TARGET-RADIUS
                            EMPTY-CANVAS)) 
   (send TARGET-SEL-2 after-drag 20 40)

     (check-equal?
           (send TARGET-SEL-2 for-test:x) 20
         "the clock is dragged to a new x position")
    (check-equal?
           (send TARGET-SEL-2 for-test:y)40
         "the clock is dragged to a new y position")

      (send TARGET after-button-up TARGET-INITIAL-X TARGET-INITIAL-Y)  
   (send TARGET after-drag TARGET-INITIAL-X TARGET-INITIAL-Y)
        (check-equal?
           (send TARGET for-test:x)TARGET-INITIAL-X
         "the unselected clock is not dragged")
    (check-equal?
           (send TARGET for-test:y)TARGET-INITIAL-Y
         "the unselected clock is not dragged")))
#lang racket

(require rackunit)
(require "extras.rkt")
(require "interfaces.rkt")   
(require 2htdp/image)
(require "sets.rkt")

(provide make-throbber)

;; Throbber Dimensions
(define THROBBER-INITIAL-RADIUS 5)
(define THROBBER-FINAL-RADIUS 20)
(define THROBBER-MODE "solid")
(define THROBBER-COLOR "green")
(define RATE-OF-SIZE-CHANGE 2)

;; Throbber start at the center of the target and increases/decreases in size
;; instantaneously.
;; They are selectable and draggable.

;; A Throbber is a (new Throbber% [x Integer][y Integer][r Integer][s Integer]
;; these 3 are optional           [selected? Boolean][mx Integer][my Integer])  
;; REPRESENTS: a green circle of initial radius 5 in solid mode.
(define Throbber%
  (class* object% (Toy<%>)
    
    ;; the init-fields are the values that may vary from one throbber to
    ;; the next.
    
    ; the x and y position of the center of the throbber
    (init-field x y)   
    
    ; radius of the throbber
    (init-field [r THROBBER-INITIAL-RADIUS])

    ; speed of throbber size increase/decrease
    (init-field [s RATE-OF-SIZE-CHANGE])
    
    ; is the throbber selected? Default is false.
    (init-field [selected? false]) 
    
    ;; if the throbber is selected, the position of
    ;; the last button-down event inside the throbber, relative to the
    ;; throbber's center.  Else any value.
    (init-field [saved-mx 0] [saved-my 0])
    
    ;; private data for objects of this class.
    ;; these can depend on the init-fields. 
    
    (super-new)
    
    ;; after-tick : -> Void
    ;; RETURNS: A throbber like this one, but as it should be after a tick
    ;; a selected throbber doesn't move.
    ;; STRATEGY: Cases on selected?
   (define/public (after-tick)
      (local ((define rate-of-size-change
                (cond [(>= (+ s r) 20) (- s)]
                      [(<= (+ s r) 5) (abs s)]
                      [else s])))
        (if selected?
            this
            (begin
             (set! r (+ rate-of-size-change r))
             (set! s rate-of-size-change)))))
 
 
    
    ;; after-key-event : KeyEvent -> Throbber
    ;; GIVEN: a keyevent
    ;; RETURNS: A Throbber like this one, but as it should be after the
    ;; given key event.
    ;; DETAILS: throbber ignores key events
    (define/public (after-key-event kev)
      this)      
    
    ; after-button-down : Nat Nat -> Void
    ; GIVEN: the location of a button-down event
    ; RETURNS: the throbber after getting selected if the mouse coordinates
    ; are inside the throbber
    ; STRATEGY: Cases on whether mouse event is in the throbber
    (define/public (after-button-down mx my)
      (if (in-throbber? mx my)
          (begin
          (set! selected? true)
          (set! saved-mx (- mx x))
          (set! saved-my (- my y)))
        this))
    
    ; after-button-up : Nat Nat -> Void
    ; GIVEN: the location of a button-up event
    ; RETURNS: the throbber after getting unselected 
    (define/public (after-button-up mx my)
          (set! selected? false))

    ; after-drag : Nat Nat -> Void
    ; GIVEN: the location of a drag event
    ; RETURNS:
    ; STRATEGY: Cases on whether the throbber is selected.
    ; If it is selected, move it so that the vector from the center to
    ; the drag event is equal to (mx, my)
    (define/public (after-drag mx my)
      (if selected?
      (begin
          (set! x (calculate-x mx))
          (set! y (calculate-y my)))
        this))   

    
    ; calculate-x : Nat -> Nat
    ; calculate-y : Nat ->Nat
    ; GIVEN: the x/y coordinate of the mouse event
    ; RETURNS: x/y coordinate of the target 
    ; STRATEGY: Cases on whether the position of target
    ;;          is within limits.
    (define (calculate-x mx)
      (local
        ((define x (- mx saved-mx))
         (define x-limit (- CANVAS-WIDTH r)))
      (cond
        [(<= x r) r]
        [(>= x x-limit) x-limit]
        [else x])))
   
    (define (calculate-y my)
      (local
        ((define y (- my saved-my))
         (define y-limit (- CANVAS-HEIGHT r)))      
      (cond
        [(<= y r) r]
        [(>= y y-limit) y-limit]
        [else y])))

    ;; to-scene : Scene -> Scene
    ;; RETURNS: a scene like the given one, but with this throbber painted
    ;; on it.
    (define/public (add-to-scene scene)
      (place-image (circle r THROBBER-MODE THROBBER-COLOR) x y scene))
    
    ;; in-throbber? : Integer Integer -> Boolean
    ;; GIVEN: a location on the canvas
    ;; RETURNS: true iff the location is inside this throbber.
    ;; STRATEGY:Combine simpler functions
    (define (in-throbber? other-x other-y)
      (<= (+ (sqr (- x other-x)) (sqr (- y other-y)))
          (sqr r)))

    
    ;; toy-x : -> Integer
    ;; toy-y : -> Integer
    ;; GIVEN:a toy
    ;; RETURNS the respective x/y position of the square
    (define/public (toy-x) x)    
    (define/public (toy-y) y)

    ;; toy-data : -> Integer
    ;; GIVEN:a toy
    ;; RETURNS the radius of the Throbber    
    (define/public (toy-data) r)
    
    ;; test methods, to probe the throbber state. 

    (define/public (for-test:x)      x)
    (define/public (for-test:y)      y)
    (define/public (for-test:selected?)   selected?)
    (define/public (for-test:radius) r)
    (define/public (for-test:speed) s)
    
    ))

;; make-throbber: PosInt PosInt -> Toy<%>
;; GIVEN: an x and a y position
;; RETURNS: an object representing a throbber at the given position.
(define (make-throbber target-center-x target-center-y)
  (new Throbber% [x target-center-x][y target-center-y]))



;; Tests for throbber
(begin-for-test
   (local
    ((define THROBBER (make-throbber TARGET-INITIAL-X TARGET-INITIAL-Y))
(define THROBBER-SEL (new Throbber% 
       [x TARGET-INITIAL-X]
       [y TARGET-INITIAL-Y]
       [selected? true]))
(define THROBBER-AFTER-TICK (new Throbber% [x TARGET-INITIAL-X]
                                           [y TARGET-INITIAL-Y]
                                           [r (+ THROBBER-INITIAL-RADIUS
                                                 RATE-OF-SIZE-CHANGE)]))
(define THROBBER-MAX (new Throbber% 
       [x TARGET-INITIAL-X]
       [y TARGET-INITIAL-Y]
       [selected? true]
       [r 18][s 5]
       [saved-mx 1]
       [saved-my 1]))
(define THROBBER-FOR-DRAG (new Throbber% 
       [x TARGET-INITIAL-X]
       [y TARGET-INITIAL-Y]
       [selected? true]
       [r 18][s 5]
       [saved-mx 1]
       [saved-my 1]))
(define THROBBER-IMAGE
                (place-image
                 (circle THROBBER-INITIAL-RADIUS  THROBBER-MODE THROBBER-COLOR)
                             TARGET-INITIAL-X TARGET-INITIAL-Y
                             EMPTY-CANVAS))

(define THROBBER-MIN (new Throbber% 
       [x TARGET-INITIAL-X]
       [y TARGET-INITIAL-Y]
       [selected? true]
       [r 7][s -5])))

 (check-equal?
   (send THROBBER after-key-event OTHER-KEY-EVENT)
        THROBBER)
    (send THROBBER after-tick) 
 (check-equal? (send THROBBER for-test:radius)
               (+ THROBBER-INITIAL-RADIUS
                    RATE-OF-SIZE-CHANGE) "changes the radius of the throbber")
       
 (send THROBBER-MAX after-tick) 
   
 (check-equal? (send THROBBER-MAX for-test:radius) 18
               "the maximum radius the throbber can have")
 (check-equal? (send THROBBER-MAX for-test:speed) 5
               "should give the speed of the throbber")
    (send THROBBER-MIN after-tick)     
 
  (check-equal? (send THROBBER-MIN for-test:radius) 7
               "the maximum radius the throbber can have")
  (check-equal? (send THROBBER-MIN for-test:speed) -5
               "should give the speed of the throbber")
       (send THROBBER toy-x)
    (check-equal?
           (send THROBBER for-test:x)TARGET-INITIAL-X
         "the throbber's x position")
    (send THROBBER toy-y)
    (check-equal?
           (send THROBBER for-test:y)TARGET-INITIAL-Y
         "the throbber's y position")
     (send THROBBER toy-data)
    (check-equal?
           (send THROBBER for-test:radius)7
         "the throbber's ticks")
     (send THROBBER-MAX after-button-up TARGET-INITIAL-X TARGET-INITIAL-Y)  
    (check-equal?
        (send THROBBER-MAX for-test:selected?) false
        "the throbber should be unselected")

    (send THROBBER-MAX after-button-up 80 100)
    (check-equal?
        (send THROBBER-MAX for-test:selected?) false
        "the throbber should be unselected")

    (send THROBBER-MAX after-button-down 800 800)
    (check-equal?
        (send THROBBER-MAX for-test:selected?) false
        "the unselected throbber shoule remain unselected")

    (send THROBBER-MAX after-button-down TARGET-INITIAL-X TARGET-INITIAL-Y)
    (check-equal?
        (send THROBBER-MAX for-test:selected?) true
        "the clock should be selected after button down")

     (send THROBBER-MIN after-drag -1 -2)
    (check-equal?
           (send THROBBER-MIN for-test:x) 7
         "the throbber is dragged to a new x position")
    (check-equal?
           (send THROBBER-MIN for-test:y) 7
         "the throbber is dragged to a new y position")
   (send THROBBER-MIN after-drag 700 800)
    (check-equal?
           (send THROBBER-MIN for-test:x) (- CANVAS-WIDTH 7)
         "the throbber is dragged to a new x position")
    (check-equal?
           (send THROBBER-MIN for-test:y) (- CANVAS-HEIGHT 7)
         "the throbber is dragged to a new y position")
   (send THROBBER-FOR-DRAG after-drag 20 40)

     (check-equal?
           (send THROBBER-FOR-DRAG for-test:x) 19
         "the throbber is dragged to a new x position")
    (check-equal?
           (send THROBBER-FOR-DRAG for-test:y)39
         "the throbber is dragged to a new y position")
    
    (send THROBBER after-button-up TARGET-INITIAL-X TARGET-INITIAL-Y)  
   (send THROBBER after-drag TARGET-INITIAL-X TARGET-INITIAL-Y)
        (check-equal?
           (send THROBBER for-test:x)TARGET-INITIAL-X
         "the unselected throbber is not dragged")
    (check-equal?
           (send THROBBER for-test:y)TARGET-INITIAL-Y
         "the unselected throbber is not dragged")
      (check-equal? (send THROBBER-SEL add-to-scene EMPTY-CANVAS)
              THROBBER-IMAGE "displays of the state after tick")
    
  ))
 
 

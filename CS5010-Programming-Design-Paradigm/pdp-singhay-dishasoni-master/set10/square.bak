#lang racket

(require rackunit)
(require "extras.rkt")
(require "interfaces.rkt")   
(require 2htdp/image)

(provide make-square-toy)

;;CONSTANTS

;; Square Dimensions
(define SQUARE-SIDE 40)
(define SQUARE-MODE "outline")
(define SQUARE-COLOR "blue")
(define SQUARE-IMG (square SQUARE-SIDE SQUARE-MODE SQUARE-COLOR))
(define HALF-SQUARE-SIDE (/ SQUARE-SIDE 2))
(define MAX-X-SQUARE (- CANVAS-WIDTH HALF-SQUARE-SIDE))
(define MAX-Y-SQUARE (- CANVAS-HEIGHT HALF-SQUARE-SIDE))



;; Square start at the center of the target and travels rightward
;; instantaneously.
;; They are selectable and draggable.

;; A Square is a (new Square% [x Integer][y Integer][s Integer]
;; these 3 are optional       [selected? Boolean][mx Integer][my Integer])
;; REPRESENTS: a blue square of size 40x40 in outline mode.

(define Square%
  (class* object% (Toy<%>)
    
    ;; the init-fields are the values that may vary from one square to
    ;; the next.
    
    ; the x and y position of the center of the square
    (init-field x y speed)   
    
    ; is the square selected? Default is false.
    (init-field [selected? false]) 
    
    ;; if the square is selected, the position of
    ;; the last button-down event inside the square, relative to the
    ;; square's center.  Else any value.
    (init-field [saved-mx 0] [saved-my 0])        
    
    (super-new)
    
   ;; after-tick : Square -> Void
    ;; GIVEN: a square
    ;; RETURNS: a square like this one, but as it should be after a tick
    ;; a selected square doesn't move.
    ;; STRATEGY: Cases on selected?
    (define/public (after-tick)
      (local
        ((define sp
           (if
            (or
             (>=(+ x speed) MAX-X-SQUARE)
             (<=(+ x speed) HALF-SQUARE-SIDE))
            (- speed)
            speed))
         (define calculated-x
           (cond
             [(<=(+ x speed) HALF-SQUARE-SIDE) HALF-SQUARE-SIDE]
             [(>=(+ x speed) MAX-X-SQUARE) MAX-X-SQUARE]
             [else (+ x speed)])))
        (if selected?
            this
            (begin
              (set! speed sp)
              (set! x calculated-x)
            ))))
    
    ;; after-key-event : KeyEvent -> Square
    ;; RETURNS: A world like this one, but as it should be after the
    ;; given key event.
    ;; DETAILS: a square ignores key events
    (define/public (after-key-event kev)
      this)      
    
    ; after-button-down : Integer Integer -> Void
    ; GIVEN: the location of a button-down event
    ; STRATEGY: Cases on whether the event is in the square
    (define/public (after-button-down mx my)
      (if (in-square? mx my)
          (begin
          (set! selected? true)
          (set! saved-mx (- mx x))
          (set! saved-my (- my y)))
        this))
    
    ; after-button-up : Integer Integer -> Void
    ; GIVEN: the location of a button-up event
    ; STRATEGY: Cases on whether the event is in the square.
    ; If the square is selected, then unselect it.
    (define/public (after-button-up mx my)
      (set! selected? false))
    
    ; after-drag : Integer Integer -> Void
    ; GIVEN: the location of a drag event
    ; STRATEGY: Cases on whether the square is selected.
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
        [(<= x HALF-SQUARE-SIDE) HALF-SQUARE-SIDE]
        [(>= x MAX-X-SQUARE) MAX-X-SQUARE]
        [else x])))
 
    (define (calculate-y my)
      (local
        ((define y (- my saved-my)))      
      (cond
        [(<= y HALF-SQUARE-SIDE) HALF-SQUARE-SIDE]
        [(>= y MAX-Y-SQUARE) MAX-Y-SQUARE]
        [else y])))
    
    ;; to-scene : Scene -> Scene
    ;; RETURNS: a scene like the given one, but with this square painted
    ;; on it.
    (define/public (add-to-scene scene)
      (place-image SQUARE-IMG x y scene))
    
    ;; in-square? : Integer Integer -> Boolean
    ;; GIVEN: a location on the canvas
    ;; RETURNS: true iff the location is inside this square.
    
    (define (in-square? other-x other-y)
      (and (<= (abs (- x other-x))
               (/ SQUARE-SIDE 2))
           (<= (abs (- y other-y))
               (/ SQUARE-SIDE 2))))

    ;; toy-x : -> Integer
    ;; toy-y : -> Integer
    ;; RETURNS the respective x/y position of the square
    (define/public (toy-x) x)    
    (define/public (toy-y) y)

    ;; toy-data : -> Integer
    ;; RETURNS the speed of square
    (define/public (toy-data) speed)

    ;; test methods, to probe the Square state.  
    (define/public (for-test:x)      x)
    (define/public (for-test:y)      y)
    (define/public (for-test:selected?)   selected?)
    (define/public (for-test:speed) speed)
    
    
    ))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; make-square-toy : PosInt PosInt PosInt -> Toy<%>
;; GIVEN: an x and a y position, and a speed
;; RETURNS: an object representing a square toy at the given position,
;;          travelling right at the given speed. 
(define (make-square-toy x y s)
  (new Square% [x x][y y][speed s]))

(begin-for-test
  (local
    ((define SPEED-10 10)
     (define SQUARE
       (make-square-toy TARGET-INITIAL-X TARGET-INITIAL-Y SPEED-10))
     (define SQUARE-SEL (new Square% 
                          [x TARGET-INITIAL-X]
                          [y TARGET-INITIAL-Y]
                          [selected? true]
                          [speed SPEED-10]))
 (define SQUARE-SEL-1 (new Square% 
                          [x 5]
                          [y HALF-SQUARE-SIDE]
                          [selected? false]
                          [speed SPEED-10]))
(define SQUARE-SEL-2 (new Square% 
                          [x (- MAX-X-SQUARE 5)]
                          [y MAX-Y-SQUARE]
                          [selected? false]
                          [speed SPEED-10]))
(define SQUARE-AFTER-TICK (new Square% 
                          [x (+ SPEED-10 TARGET-INITIAL-X)]
                          [y TARGET-INITIAL-Y]
                          [speed SPEED-10]))
(define SQUARE-NEAR-BOUNDARY (new Square% 
                          [x MAX-X-SQUARE]
                          [y MAX-Y-SQUARE]
                          [speed SPEED-10]))
(define SQUARE-NEAR-BOUNDARY-AFTER-TICK (new Square% 
                          [x MAX-X-SQUARE]
                          [y MAX-Y-SQUARE]
                          [speed (- SPEED-10)]))
(define SQUARE-FOR-DRAG (new Square% 
                          [x TARGET-INITIAL-X]
                          [y TARGET-INITIAL-Y]
                          [speed SPEED-10])))
    

    
      (send SQUARE toy-x)
    (check-equal?
           (send SQUARE for-test:x)TARGET-INITIAL-X
         "the clock's x position")
    (send SQUARE toy-y)
    (check-equal?
           (send SQUARE for-test:y)TARGET-INITIAL-Y
         "the clock's y position")
     (send SQUARE toy-data)
    (check-equal?
           (send SQUARE for-test:speed)SPEED-10 
         "the clock's ticks")
      (send SQUARE after-button-down TARGET-INITIAL-X TARGET-INITIAL-Y) 
    (check-equal?
        (send SQUARE after-tick)
        SQUARE)

  (check-equal?
        (send SQUARE after-key-event OTHER-KEY-EVENT)
        SQUARE)

    (send SQUARE-SEL after-button-up TARGET-INITIAL-X TARGET-INITIAL-Y)  
    (check-equal?
        (send SQUARE-SEL for-test:selected?) false
        "the clock should be unselected")

    (send SQUARE after-button-up 80 100)
    (check-equal?
        (send SQUARE for-test:selected?) false
        "the clock should be unselected")

    (send SQUARE after-button-down 800 800)
    (check-equal?
        (send SQUARE for-test:selected?) false
        "the unselected clock shoule remain unselected")

    (send SQUARE after-button-down TARGET-INITIAL-X TARGET-INITIAL-Y)
    (check-equal?
        (send SQUARE for-test:selected?) true
        "the square should be selected after button down")
    (send SQUARE-SEL after-tick)
    (check-equal?
        (send SQUARE-SEL for-test:x) (+ SPEED-10 TARGET-INITIAL-X)
        "the square should move in right direction")
    (check-equal?
        (send SQUARE-SEL for-test:speed) SPEED-10
        "should give the square speed on next tick")

    (check-equal?
    (send SQUARE-SEL-2 for-test:x) (- MAX-X-SQUARE 5))

    (check-equal?
    (send SQUARE-SEL-2 for-test:speed) 10)

    (check-equal?
    (send SQUARE-SEL-2 for-test:selected?) false)

    (send SQUARE-SEL-2 after-tick)

    
    (check-equal?
        (send SQUARE-SEL-2 for-test:x) MAX-X-SQUARE
        "the square should move in right direction")

    (check-equal?
        (send SQUARE-SEL-2 for-test:speed) (* -1 SPEED-10)
        "should give the square speed on next tick")

    (send SQUARE-SEL-1 after-tick)

    (check-equal?
        (send SQUARE-SEL-1 for-test:x) HALF-SQUARE-SIDE
        "the square should move in left direction")

    (check-equal?
        (send SQUARE-SEL-1 for-test:speed) (* -1 SPEED-10)
        "should give the square speed on next tick")
    
    (send SQUARE-SEL after-button-down TARGET-INITIAL-X TARGET-INITIAL-Y)
 (send SQUARE-SEL after-drag -1 -2)
    (check-equal?
           (send SQUARE-SEL for-test:x) HALF-SQUARE-SIDE
         "the clock is dragged to a new x position")
    (check-equal?
           (send SQUARE-SEL for-test:y) HALF-SQUARE-SIDE
         "the clock is dragged to a new y position")
     
     (send SQUARE-SEL after-tick)
    (check-equal?
        (send SQUARE-SEL for-test:x) HALF-SQUARE-SIDE
        "the square should move in right direction")
    (check-equal?
        (send SQUARE-SEL for-test:speed) SPEED-10
        "should give the square speed on next tick")
    
    (send SQUARE-NEAR-BOUNDARY after-button-down MAX-X-SQUARE MAX-Y-SQUARE)
   (send SQUARE-NEAR-BOUNDARY after-drag 700 800)
    (check-equal?
           (send SQUARE-NEAR-BOUNDARY for-test:x) MAX-X-SQUARE
         "the clock is dragged to a new x position")
    (check-equal?
           (send SQUARE-NEAR-BOUNDARY for-test:y) MAX-Y-SQUARE
         "the clock is dragged to a new y position")
    
  
    (send SQUARE-NEAR-BOUNDARY-AFTER-TICK after-tick)
    (check-equal?
        (send SQUARE-NEAR-BOUNDARY-AFTER-TICK for-test:x)
        (+ MAX-X-SQUARE  (* -1 SPEED-10))
        "the square should move in right direction")
    (check-equal?
        (send SQUARE-NEAR-BOUNDARY-AFTER-TICK for-test:speed)
        (* -1 SPEED-10) "should give the square speed on next tick")


    (send SQUARE-FOR-DRAG after-button-down 250 300)
    (check-equal? (send SQUARE-FOR-DRAG for-test:selected?) true)
    (send SQUARE-FOR-DRAG after-drag 180 100)
     (check-equal?
           (send SQUARE-FOR-DRAG  for-test:x) 180
         "the clock is dragged to a new x position")

    (send SQUARE-SEL after-button-down 20 40)
    (send SQUARE-SEL after-drag 20 40)
     (check-equal?
           (send SQUARE-SEL  for-test:x) 20
         "the clock is dragged to a new x position")
    (send SQUARE after-button-up TARGET-INITIAL-X TARGET-INITIAL-Y)  
   (send SQUARE after-drag TARGET-INITIAL-X TARGET-INITIAL-Y)
        (check-equal?
           (send SQUARE for-test:x)TARGET-INITIAL-X
         "the unselected clock is not dragged")
    (check-equal?
           (send SQUARE for-test:y)TARGET-INITIAL-Y
         "the unselected clock is not dragged")
    (check-equal? (send SQUARE add-to-scene EMPTY-CANVAS)
                (place-image SQUARE-IMG
                             TARGET-INITIAL-X TARGET-INITIAL-Y
                             EMPTY-CANVAS)))

    )

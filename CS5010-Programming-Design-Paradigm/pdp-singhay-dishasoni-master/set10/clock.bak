#lang racket

(require rackunit)
(require "extras.rkt")
(require "interfaces.rkt")   
(require 2htdp/image)
(require "sets.rkt")

(provide make-clock)

;; Clock Attributes

(define CLOCK-SIZE 40)
(define CLOCK-COLOR "black")
(define RATE-OF-SIZE-CHANGE 2)

;; Clock start at the center of the target and shows incrementing ticks
;; instantaneously.
;; They are selectable and draggable.

;; A Clock is a (new Clock% [x Integer][y Integer]
;; these 3 are optional     [selected? Boolean][mx Integer][my Integer]
;;                          [ticks PosInt])
;; REPRESENTS: the number of ticks since it was created.
(define Clock%
  (class* object% (Toy<%>)
    
    ;; the init-fields are the values that may vary from one Clock to
    ;; the next.
    
    ; the x and y position of the center of the Clock
    (init-field x y)   
    
    ; is the throbber selected? Default is false.
    (init-field [selected? false]) 
    
    ;; if the Clock is selected, the position of
    ;; the last button-down event inside the Clock, relative to the
    ;; Clock's center.  Else any value.
    (init-field [saved-mx 0] [saved-my 0])
    
    ;; the number of ticks since clock was created
    (init-field [ticks 1])
    
    ;; private data for objects of this class.
    ;; these can depend on the init-fields.
    
    ; image for displaying the Clock
    
     (define (CLOCK-IMG)(text (number->string ticks) CLOCK-SIZE CLOCK-COLOR))
     (define (hlf-clk-hiet) (/ (image-height (CLOCK-IMG)) 2))
     (define (hlf-clk-wdth) (/ (image-width (CLOCK-IMG)) 2))
    
    (super-new)
    
    ;; after-tick : Time -> Void
    ;; RETURNS: A Clock like this one, but as it should be after a tick
    ;; a selected Clock doesn't move.
    ;; STRATEGY: Cases on selected?
    (define/public (after-tick)
     (set! ticks (add1 ticks)))
          
    
    ;; after-key-event : KeyEvent -> Void
    ;; RETURNS: A world like this one, but as it should be after the
    ;; given key event.
    ;; DETAILS: a Clock ignores key events
    (define/public (after-key-event kev)
      this)      
    
    ; after-button-down : Integer Integer -> Void
    ; GIVEN: the location of a button-down event
    ; STRATEGY: Cases on whether the event is in the Clock
    (define/public (after-button-down mx my)
      (if (in-clock? mx my)
         (begin
          (set! selected? true)
          (set! saved-mx (- mx x))
          (set! saved-my (- my y)))
        this))
    
    ; after-button-up : Nat Nat -> Void
    ; GIVEN: the location of a button-up event
    ; RETURNS: the clock unselected
    (define/public (after-button-up mx my)
       (set! selected? false))

    
    ; after-drag : Nat Nat -> Void
    ; GIVEN: the location of a drag event
    ; RETURNS:the Clock dragged to a new location
    ; STRATEGY: Cases on whether the Clock is selected.
    ; If it is selected, move it so that the vector from the center to
    ; the drag event is equal to (mx, my)
    (define/public (after-drag mx my)
      (if selected?
          (begin
          (set! x (calculate-x mx))
          (set! y (calculate-y my)))
        this))
    
    ; calculate-x : Nat -> Nat
    ; calculate-y : Nat -> Nat
    ; GIVEN: the x/y coordinate of the mouse event
    ; RETURNS: x/y coordinate of the clock 
    ; STRATEGY: Cases on whether the position of target
    ;;          is within limits.
    (define (calculate-x mx)
      (local
        ((define x (- mx saved-mx))
         (define limit (- CANVAS-WIDTH (hlf-clk-wdth))))
        (cond
          [(<= x (hlf-clk-wdth)) (hlf-clk-wdth)]
          [(>= x limit) limit]
          [else x])))
    
    (define (calculate-y my)
      (local
        ((define y (- my saved-my))
         (define limit (- CANVAS-HEIGHT (hlf-clk-hiet))))
        (cond
          [(<= y (hlf-clk-hiet)) (hlf-clk-hiet)]
          [(>= y limit) limit]
          [else y])))
    
    ;; to-scene : Scene -> Scene
    ;; RETURNS: a scene like the given one, but with this Clock painted
    ;; on it.
    (define/public (add-to-scene scene)
      (place-image (CLOCK-IMG) x y scene))
    
    ;; in-Clock? : Integer Integer -> Boolean
    ;; GIVEN: a location on the canvas
    ;; RETURNS: true iff the location is inside this Clock.
    (define (in-clock? other-x other-y)
      (and (<= (abs (- x other-x))
               (hlf-clk-wdth))
           (<= (abs (- y other-y))
              (hlf-clk-hiet))))
    
    ;; toy-x : -> Nat
    ;; toy-y : -> Nat
    ;; GIVEN: a clock
    ;; RETURNS the respective x/y position of the clock
    (define/public (toy-x) x)    
    (define/public (toy-y) y)

    ;; toy-data : -> Integer
    ;; GIVEN: a clock
    ;; RETURNS the number of ticks
    (define/public (toy-data) ticks)
    
    ;; test methods, to probe the Clock state.  
    (define/public (for-test:x)      x)
    (define/public (for-test:y)      y)
    (define/public (for-test:selected?)   selected?)
    (define/public (for-test:ticks) ticks)
    
    ))

;; make-clock : PosInt PostInt -> Toy<%>
;; GIVEN: an x and a y position
;; RETURNS: an object representing a clock at the given position.
(define (make-clock x y)
  (new Clock% [x x][y y]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Tests for Clock

(define CLOCK-IMAGE
                (place-image (text (number->string 2) CLOCK-SIZE CLOCK-COLOR)
                             TARGET-INITIAL-X TARGET-INITIAL-Y
                             EMPTY-CANVAS))


(define CLOCK-IM (text (number->string 2) CLOCK-SIZE CLOCK-COLOR))
(define WIDTH-CLOCK-IM (/ (image-width CLOCK-IM)  2))
(define HEIGHT-CLOCK-IM (/ (image-height CLOCK-IM)  2))
(define WIDTH-CLOCK-IMA (- CANVAS-WIDTH (/ (image-width CLOCK-IM)  2)))
(define HEIGHT-CLOCK-IMA (- CANVAS-HEIGHT(/ (image-height CLOCK-IM)  2)))





(begin-for-test
  (local
    ((define CLOCK (make-clock TARGET-INITIAL-X TARGET-INITIAL-Y))
     (define CLOCK-SEL (new Clock% 
                         [x TARGET-INITIAL-X]
                         [y TARGET-INITIAL-Y]
                         [selected? true]
                         [saved-mx 1]
                         [saved-my 1]
                         [ticks 2]))
    (define CLOCK-FOR-DRAG (new Clock% 
                         [x TARGET-INITIAL-X]
                         [y TARGET-INITIAL-Y]
                         [selected? true]
                         [saved-mx 1]
                         [saved-my 1]
                         [ticks 2]))

    (define CLOCK-AFTER-TICK (new Clock% 
                         [x TARGET-INITIAL-X]
                         [y TARGET-INITIAL-Y]
                         [ticks 2])))

  
      (send CLOCK-SEL toy-x)
    (check-equal?
           (send CLOCK-SEL for-test:x)TARGET-INITIAL-X
         "the clock's x position")
    (send CLOCK-SEL toy-y)
    (check-equal?
           (send CLOCK-SEL for-test:y)TARGET-INITIAL-Y
         "the clock's y position")
     (send CLOCK-SEL toy-data)
    (check-equal?
           (send CLOCK-SEL for-test:ticks)2
         "the clock's ticks")

  (check-equal?
        (send CLOCK after-key-event OTHER-KEY-EVENT)
        CLOCK)

    (send CLOCK-SEL after-button-up TARGET-INITIAL-X TARGET-INITIAL-Y)  
    (check-equal?
        (send CLOCK-SEL for-test:selected?) false
        "the clock should be unselected")

    (send CLOCK-SEL after-tick)
    (check-equal?
        (send CLOCK-SEL for-test:ticks) 3
        "the clock tick should increase by 1")

    (send CLOCK after-button-up 80 100)
    (check-equal?
        (send CLOCK for-test:selected?) false
        "the clock should be unselected")

    (send CLOCK after-button-down 800 800)
    (check-equal?
        (send CLOCK for-test:selected?) false
        "the unselected clock shoule remain unselected")

    (send CLOCK after-button-down TARGET-INITIAL-X TARGET-INITIAL-Y)
    (check-equal?
        (send CLOCK for-test:selected?) true
        "the clock should be selected after button down")
    
  
  (check-equal? (send CLOCK-AFTER-TICK add-to-scene EMPTY-CANVAS)
              CLOCK-IMAGE "displays of the state after tick")
   (send CLOCK-SEL after-button-down TARGET-INITIAL-X TARGET-INITIAL-Y)          
  (send CLOCK-SEL after-drag -1 -2)
    (check-equal?
           (send CLOCK-SEL for-test:x) WIDTH-CLOCK-IM
         "the clock is dragged to a new x position")
    (check-equal?
           (send CLOCK-SEL for-test:y) HEIGHT-CLOCK-IM
         "the clock is dragged to a new y position")
   (send CLOCK-SEL after-drag 700 800)
    (check-equal?
           (send CLOCK-SEL for-test:x) WIDTH-CLOCK-IMA
         "the clock is dragged to a new x position")
    (check-equal?
           (send CLOCK-SEL for-test:y) HEIGHT-CLOCK-IMA
         "the clock is dragged to a new y position")
   (send CLOCK-FOR-DRAG after-drag 20 40)

     (check-equal?
           (send CLOCK-FOR-DRAG for-test:x) 19
         "the clock is dragged to a new x position")
    (check-equal?
           (send CLOCK-FOR-DRAG for-test:y)39
         "the clock is dragged to a new y position")
    
    (send CLOCK after-button-up TARGET-INITIAL-X TARGET-INITIAL-Y)  
   (send CLOCK after-drag TARGET-INITIAL-X TARGET-INITIAL-Y)
        (check-equal?
           (send CLOCK for-test:x)TARGET-INITIAL-X
         "the unselected clock is not dragged")
    (check-equal?
           (send CLOCK for-test:y)TARGET-INITIAL-Y
         "the unselected clock is not dragged")))
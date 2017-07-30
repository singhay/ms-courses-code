#lang racket
#|
  FILENAME  : toys.rkt
  CO-AUTHORS: Ayush Singh(singhay) and Disha Soni(dishasoni)

  Program to represent a Toy factory making diffrent toys.  The child 
  interacts with the toy by dragging the target (using smooth drag, as usual) 
  and by typing characters into the system. Each of the characters listed 
  below causes  a new toy to be created with its center located at the center 
  of the target. Toys are also moveable using smooth drag.

  GOAL : To simulate a toy with multiple attributed functionalities on a canvas.
  INSTRUCTIONS:
   start the program with (run 0.1 10)
   Use the following keyPress to add new toys:
   1. "s", a new square-shaped toy pops up.
   2. "t", a new throbber appears.
   3. "w", a clock appears.
   4. "f", a football appears.
|#

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; LIBRARIES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(require rackunit)
(require "extras.rkt")
(require "sets.rkt")
(require 2htdp/universe)   
(require 2htdp/image) 
(check-location "09" "toys.rkt")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; PROVIDE FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(provide run
         Toy<%>
         make-world
         make-clock         
         make-throbber
         make-football
         make-square-toy
         PlaygroundState<%>)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; MAIN FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; make-world : PosInt -> PlaygroundState<%>
;; RETURNS    : a world with a target, but no toys, and in which any
;; square toys created in the future will travel at the given speed (in
;; pixels/tick).
(define (make-world square-speed)
  (make-playground-state empty (new-target) square-speed))

;; run     : PosNum PosInt -> PlaygroundState<%> 
;; GIVEN   : a frame rate (in seconds/tick) and a square-speed (in pixels/tick),
;;           creates and runs a world in which square toys travel at given speed
;; EFFECT  : runs a copy of an initial world
;; RETURNS : the final state of the world.
;; USAGE   : (run 0.5 10)
;; STRATEGY: Combining Simpler Functions
(define (run rate square-speed)
  (big-bang (make-world square-speed)
            (on-tick
             (lambda (w) (send w after-tick))
             rate)
            (on-draw
             (lambda (w) (send w to-scene)))
            (on-key
             (lambda (w kev)
               (send w after-key-event kev)))
            (on-mouse
             (lambda (w mx my mev)
               (send w after-mouse-event mx my mev)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; CONSTANTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Canvas Dimensions
(define CANVAS-HEIGHT 600)
(define CANVAS-WIDTH 500)
(define HALF-CANVAS-WIDTH (/ CANVAS-WIDTH 2))
(define HALF-CANVAS-HEIGHT (/ CANVAS-HEIGHT 2))
(define EMPTY-CANVAS (empty-scene CANVAS-WIDTH CANVAS-HEIGHT))

;; Target Dimensions
(define TARGET-RADIUS 10)
(define TARGET-MODE "outline")
(define TARGET-COLOR "green")
(define TARGET-IMG (circle TARGET-RADIUS TARGET-MODE TARGET-COLOR))
(define TARGET-INITIAL-X HALF-CANVAS-WIDTH)
(define TARGET-INITIAL-Y HALF-CANVAS-HEIGHT)
(define TARGET-MIN TARGET-RADIUS)
(define TARGET-X-MAX (- CANVAS-WIDTH TARGET-RADIUS))
(define TARGET-Y-MAX (- CANVAS-HEIGHT TARGET-RADIUS))

;; Throbber Dimensions
(define THROBBER-INITIAL-RADIUS 5)
(define THROBBER-FINAL-RADIUS 10)
(define THROBBER-MODE "solid")
(define THROBBER-COLOR "green")

;; Square Dimensions
(define SQUARE-SIDE 40)
(define SQUARE-MODE "outline")
(define SQUARE-COLOR "blue")
(define SQUARE-IMG (square SQUARE-SIDE SQUARE-MODE SQUARE-COLOR))
(define HALF-SQUARE-SIDE (/ SQUARE-SIDE 2))
(define MAX-X-SQUARE (- CANVAS-WIDTH HALF-SQUARE-SIDE))
(define MAX-Y-SQUARE (- CANVAS-HEIGHT HALF-SQUARE-SIDE))

;; Clock Attributes
(define CLOCK-COLOR "black")
(define CLOCK-SIZE 40)

;; Football
(define RATE-OF-SIZE-CHANGE 2)

;; KeyEvents
(define NEW-SQUARE-KEY-EVENT "s")
(define NEW-THROBBER-KEY-EVENT "t")
(define NEW-CLOCK-KEY-EVENT "w")
(define NEW-FOOTBALL-KEY-EVENT "f")
(define OTHER-KEY-EVENT "\b")

;; MouseEvents
(define BUTTON-DOWN-EVENT "button-down")
(define DRAG-EVENT "drag")
(define BUTTON-UP-EVENT "button-up")
(define OTHER-MOUSE-EVENT "enter")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; DATA DEFINITIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; A Widget is an object whose class implements Widget<%>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; INTERFACES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Every Toy that lives in the PlaygroundState must implement the Widget<%>
;; interface.
(define Widget<%>
  (interface ()
    
    ; -> Widget
    ; GIVEN: no arguments
    ; RETURNS: the state of this object that should follow at time t+1.
    after-tick          
    
    ; Integer Integer -> Widget
    ; GIVEN: a location
    ; RETURNS: the state of this object that should follow the
    ; specified mouse event at the given location.
    after-button-down
    after-button-up
    after-drag
    
    ; KeyEvent -> Widget
    ; GIVEN: a key event and a time
    ; RETURNS: the state of this object that should follow the
    ; given key event
    after-key-event     
    
    ; Scene -> Scene
    ; GIVEN: a scene
    ; RETURNS: a scene like the given one, but with this object
    ; painted on it.
    add-to-scene
    ))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; The World implements the WorldState<%> interface
;; Every PlaygroundState% must implement WorldState<%>
(define WorldState<%>
  (interface ()
    
    ; -> World
    ; GIVEN: no arguments
    ; RETURNS: the state of the world at the next tick
    after-tick          
    
    ; Integer Integer MouseEvent-> World
    ; GIVEN: a location
    ; RETURNS: the state of the world that should follow the
    ; given mouse event at the given location.
    after-mouse-event
    
    
    ; KeyEvent : KeyEvent -> Widget
    ; GIVEN: a key event
    ; RETURNS: the state of the world that should follow the
    ; given key event
    after-key-event     
    
    ; -> Scene
    ; GIVEN: a scene
    ; RETURNS: a scene that depicts this World
    to-scene
    ))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Playground implements the WorldState<%> interface
;; Every Playground% must implement PlaygroundState<%>
(define PlaygroundState<%>
  (interface (WorldState<%>) ;; includes all the methods in
    ;; WorldState<%>. 
    
    ;; -> Integer
    ;; RETURNS: the x and y coordinates of the target
    target-x
    target-y
    
    ;; -> Boolean
    ;; Is the target selected?
    target-selected?
    
    ;; -> ListOfToy<%>
    get-toys
    
    ))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Target Interface implements the Widget interface
;; Every Target% must implement Target<%>

(define Target<%>
  (interface (Widget<%>) ;; this means: include all the methods in
                         ;; Widget<%>. 
    
    ;; -> Integer
    ;; RETURN: the x and y coordinates of the target
    get-x
    get-y

    ;; -> Boolean
    ;; Is the target selected?
    get-selected?)) 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Toy implements the Widget<%> interface
;; Every Toy% must implement Toy<%>
(define Toy<%> 
  (interface (Widget<%>)  ;; this means: include all the methods in
    ;;  Widget<%>. 
    
    ;; -> Int
    ;; RETURNS: the x or y position of the center of the toy
    toy-x
    toy-y
    
    ;; -> Int
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; CLASSES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; A PlaygroundState% is a (new PlaygroundState% [toys ListOfToy<%>] 
;;                                               [target Target<%>]
;;                                               [speed PosInt])
;; A Playground contains list of all the toys it contains along with a target
;; and the speed of squares.

(define PlaygroundState%
  (class* object% (PlaygroundState<%>)    
    
    (init-field toys)   ;  ListOfToy<%>
    (init-field target) ;  Target<%>
    (init-field speed)  ;  Speed of the square
    
    (super-new)
    
    ;; after-tick : -> World
    ;; Use HOFC map on the Widget's in this World
    (define/public (after-tick)
      (make-playground-state
       (map
        (lambda (toy) (send toy after-tick))
        toys)
       (send target after-tick)
       speed))
    
    ;; to-scene : -> Scene
    ;; Use HOFC foldr on the Widget's in this World
    (define/public (to-scene)
      (foldr
       (lambda (toy scene)
         (send toy add-to-scene scene))
       EMPTY-CANVAS
       (cons target toys)))
    
    ;; after-key-event : KeyEvent PosInt -> WorldState
    ;; STRATEGY: Cases on kev    
    (define/public (after-key-event kev)
      (make-playground-state 
       (cond
         [(key=? kev NEW-SQUARE-KEY-EVENT) (new-square)]
         [(key=? kev NEW-THROBBER-KEY-EVENT) (new-throbber)]
         [(key=? kev NEW-CLOCK-KEY-EVENT) (new-clock)]
         [(key=? kev NEW-FOOTBALL-KEY-EVENT) (new-football)]
         [else
          (map (lambda (toy) (send toy after-key-event kev)) toys)])
       target speed))
    
    ;; after-mouse-event : Nat Nat MouseEvent -> WorldState
    ;; STRATEGY: Cases on mev
    (define/public (after-mouse-event mx my mev)
      (cond
        [(mouse=? mev "button-down")
         (after-button-down mx my)]
        [(mouse=? mev "drag")
         (after-drag mx my)]
        [(mouse=? mev "button-up")
         (after-button-up mx my)]
        [else this]))
    
    ;; the next few functions are local functions, not in the interface.

    ;; after-button-down : Nat Nat -> WorldState
    ;; STRATEGY: Cases on mev
    (define (after-button-down mx my)
      (make-playground-state
       (map
        (lambda (toy) (send toy after-button-down mx my))
        toys)
        (send target after-button-down mx my)
        speed))
    
    ;; after-button-up : Nat Nat -> WorldState
    ;; STRATEGY: Cases on mev
    (define (after-button-up mx my)
      (make-playground-state
       (map
        (lambda (toy) (send toy after-button-up mx my))
        toys)
        (send target after-button-up mx my)
        speed))

    ;; after-drag : Nat Nat -> WorldState
    ;; STRATEGY: Cases on mev
    (define (after-drag mx my)
      (make-playground-state
       (map
        (lambda (toy) (send toy after-drag mx my))
        toys)
        (send target after-drag mx my)
        speed))

    ;; target-x -> Integer    
    ;; target-y -> Integer
    ;; RETURN: the x/y coordinate of the target
    (define/public (target-x)
      (send target get-x))
    (define/public (target-y)
      (send target get-y))
     
    ;; target-selected? -> Boolean
    ;; Is the target selected?
    (define/public (target-selected?)
      (send target get-selected?))

    ;; -> ListOfToy<%>
    ;; RETURNS a new list of toys with respective new toy added
    (define (new-square)
      (cons
           (make-square-toy (send target get-x)
                            (send target get-y)
                            speed)
           toys))
    (define (new-throbber)
      (cons (make-throbber (send target get-x)
                           (send target get-y))
                toys))
    (define (new-clock)
      (cons (make-clock (send target get-x)
                        (send target get-y))
                toys)) 
    (define (new-football)
      (cons (make-football (send target get-x)
                           (send target get-y))
                toys))

    ;; test methods, to probe the target state.
    (define/public (get-toys) toys)
    (define/public (get-speed) speed)
    (define/public (get-target) target)
    ))

;; make-playground-state -> ListOfToy<%> Target<%> PosInt -> PlaygroundState<%>
;; RETURNS a Playground state with all the toys in the world with the target
;; placed at the center of canvas with a square-speed of the squares to be added
(define (make-playground-state toys target square-speed)
  (new PlaygroundState% [toys toys][target target][speed square-speed]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; We will have a class for each kind of shape

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
    ;; RETURNS : the x/y coordinate as target
    (define/public (get-x)
      x)
    (define/public (get-y)
      y)
    
    ;; selected? -> Boolean
    ;; RETURNS : true iff the target is selected
    (define/public (get-selected?)
      selected?)
    
    ;; to-scene : Scene -> Scene
    ;; RETURNS: a scene like the given one, but with this target painted
    ;; on it.
    (define/public (add-to-scene scene)
      (place-image TARGET-IMG x y scene))   
    
    ; after-button-down : Integer Integer -> Target
    ; GIVEN: the location of a button-down event
    ; STRATEGY: Cases on whether the event is in the target
    (define/public (after-button-down mx my)
      (if (in-target? mx my)
          (new Target%
               [x x][y y]
               [selected? true]
               [saved-mx (- mx x)]
               [saved-my (- my y)])
          this))
    
    ; after-button-up : Integer Integer -> Target
    ; GIVEN: the location of a button-up event
    ; STRATEGY: Cases on whether the event is in the target.
    ; If the target is selected, then unselect it.
    (define/public (after-button-up mx my)
      (if (in-target? mx my)
          (new Target%
               [x x][y y]
               [selected? false]
               [saved-mx saved-mx]
               [saved-my saved-my])
          this))   
    
    ; after-drag : Integer Integer -> Target
    ; GIVEN: the location of a drag event
    ; STRATEGY: Cases on whether the target is selected.
    ; If it is selected, move it so that the vector from the center to
    ; the drag event is equal to (mx, my)
    (define/public (after-drag mx my)
      (if selected?
          (new Target%
               [x (calculate-x mx)]
               [y (calculate-y my)]
               [selected? true]
               [saved-mx saved-mx]
               [saved-my saved-my])
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
    
    ;; in-target? : Integer Integer -> Boolean
    ;; GIVEN: a location on the canvas
    ;; RETURNS: true iff the location is inside this target.
    (define (in-target? other-x other-y)
      (<= (+ (sqr (- x other-x)) (sqr (- y other-y)))
          (sqr TARGET-RADIUS)))
    
    ;; the target doesn't have any other behaviors
    (define/public (after-tick) this)    
    (define/public (after-key-event kev) this)
    (define/public (after-mouse-event mev) this)    
    
    ))

;; new-target : -> Toy<%>
;; RETURNS a new toy placed at the center of the canvas
(define (new-target)
  (new Target% [x TARGET-INITIAL-X]
               [y TARGET-INITIAL-Y]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
    
    ;; after-tick : Time -> Square
    ;; RETURNS: A square like this one, but as it should be after a tick
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
            (new Square%
                 [x calculated-x]
                 [y y]
                 [speed sp]
                 [selected? selected?]
                 [saved-mx saved-mx]
                 [saved-my saved-my]))))
    
    ;; after-key-event : KeyEvent -> Square
    ;; RETURNS: A world like this one, but as it should be after the
    ;; given key event.
    ;; DETAILS: a square ignores key events
    (define/public (after-key-event kev)
      this)      
    
    ; after-button-down : Integer Integer -> Square
    ; GIVEN: the location of a button-down event
    ; STRATEGY: Cases on whether the event is in the square
    (define/public (after-button-down mx my)
      (if (in-square? mx my)
          (new Square%
               [x x][y y]
               [selected? true]
               [speed speed]
               [saved-mx (- mx x)]
               [saved-my (- my y)])
          this))
    
    ; after-button-up : Integer Integer -> Square
    ; GIVEN: the location of a button-up event
    ; STRATEGY: Cases on whether the event is in the square.
    ; If the square is selected, then unselect it.
    (define/public (after-button-up mx my)
      (if (in-square? mx my)
          (new Square%
               [x x][y y]
               [selected? false]
               [speed speed]
               [saved-mx saved-mx]
               [saved-my saved-my])
          this))   
    
    ; after-drag : Integer Integer -> Square
    ; GIVEN: the location of a drag event
    ; STRATEGY: Cases on whether the square is selected.
    ; If it is selected, move it so that the vector from the center to
    ; the drag event is equal to (mx, my)
    (define/public (after-drag mx my)
      (if selected?
          (new Square%
               [x (calculate-x mx)]
               [y (calculate-y my)]
               [selected? true]
               [speed speed]
               [saved-mx saved-mx]
               [saved-my saved-my])
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

    ;; test methods, to probe the Square state.  Note that we don't have
    ;; a probe for side length.    
    ;; -> (list Int Int Boolean Int)
    (define/public (square-state) (list x y selected? speed))
    
    ))

;; make-square-toy : PosInt PosInt PosInt -> Toy<%>
;; GIVEN: an x and a y position, and a speed
;; RETURNS: an object representing a square toy at the given position,
;;          travelling right at the given speed. 
(define (make-square-toy x y s)
  (new Square% [x x][y y][speed s]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
    
    ; image for displaying the Throbber
    (field [THROBBER-IMG (circle r THROBBER-MODE THROBBER-COLOR)])    
    
    (super-new)
    
    ;; after-tick : Time -> Throbber
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
            (new Throbber%
                 [x x][y y]
                 [r (+ rate-of-size-change r)]
                 [s rate-of-size-change]
                 [selected? selected?]
                 [saved-mx saved-mx]
                 [saved-my saved-my]))))
    
    ;; after-key-event : KeyEvent -> Throbber
    ;; RETURNS: A world like this one, but as it should be after the
    ;; given key event.
    ;; DETAILS: throbber ignores key events
    (define/public (after-key-event kev)
      this)      
    
    ; after-button-down : Integer Integer -> Throbber
    ; GIVEN: the location of a button-down event
    ; STRATEGY: Cases on whether mouse event is in the throbber
    (define/public (after-button-down mx my)
      (if (in-throbber? mx my)
          (new Throbber%
               [x x][y y][r r][s s]
               [selected? true]
               [saved-mx (- mx x)]
               [saved-my (- my y)])
          this))
    
    ; after-button-up : Integer Integer -> Throbber
    ; GIVEN: the location of a button-up event
    ; STRATEGY: Cases on whether mouse event is in the throbber.
    ; If the throbber is selected, then unselect it.
    (define/public (after-button-up mx my)
      (if (in-throbber? mx my)
          (new Throbber%
               [x x][y y][r r][s s]
               [selected? false]
               [saved-mx saved-mx]
               [saved-my saved-my])
          this))   
    
    ; after-drag : Integer Integer -> Throbber
    ; GIVEN: the location of a drag event
    ; STRATEGY: Cases on whether the throbber is selected.
    ; If it is selected, move it so that the vector from the center to
    ; the drag event is equal to (mx, my)
    (define/public (after-drag mx my)
      (if selected?
          (new Throbber%
               [x (calculate-x mx)]
               [y (calculate-y my)]
               [r r][s s]
               [selected? true]
               [saved-mx saved-mx]
               [saved-my saved-my])
          this))
    
    ; calculate-x : Integer -> Integer
    ; calculate-y : Integer ->Integer
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
      (place-image THROBBER-IMG x y scene))
    
    ;; in-throbber? : Integer Integer -> Boolean
    ;; GIVEN: a location on the canvas
    ;; RETURNS: true iff the location is inside this throbber.
    (define (in-throbber? other-x other-y)
      (<= (+ (sqr (- x other-x)) (sqr (- y other-y)))
          (sqr r)))

    ;; toy-x : -> Integer
    ;; toy-y : -> Integer
    ;; RETURNS the respective x/y position of the square
    (define/public (toy-x) x)    
    (define/public (toy-y) y)

    ;; toy-data : -> Integer
    ;; RETURNS the radius of the Throbber    
    (define/public (toy-data) r)
    
    ;; test methods, to probe the throbber state.  Note that we don't have
    ;; a probe for radius.
    ;; -> (list Int Int Boolean PosInt)
    (define/public (throbber-state) (list x y selected? r))
    
    ))

;; make-throbber: PosInt PosInt -> Toy<%>
;; GIVEN: an x and a y position
;; RETURNS: an object representing a throbber at the given position.
(define (make-throbber target-center-x target-center-y)
  (new Throbber% [x target-center-x][y target-center-y]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
    (field
     [CLOCK-IMG (text (number->string ticks) CLOCK-SIZE CLOCK-COLOR)]
     [hlf-clk-hiet (/ (image-height CLOCK-IMG) 2)]
     [hlf-clk-wdth (/ (image-width CLOCK-IMG) 2)])
    
    (super-new)
    
    ;; after-tick : Time -> Clock
    ;; RETURNS: A Clock like this one, but as it should be after a tick
    ;; a selected Clock doesn't move.
    ;; STRATEGY: Cases on selected?
    (define/public (after-tick)
      (new Clock%
           [x x]
           [y y]
           [selected? selected?]
           [saved-mx saved-mx]
           [saved-my saved-my]
           [ticks (add1 ticks)]))
    
    ;; after-key-event : KeyEvent -> Clock
    ;; RETURNS: A world like this one, but as it should be after the
    ;; given key event.
    ;; DETAILS: a Clock ignores key events
    (define/public (after-key-event kev)
      this)      
    
    ; after-button-down : Integer Integer -> Clock
    ; GIVEN: the location of a button-down event
    ; STRATEGY: Cases on whether the event is in the Clock
    (define/public (after-button-down mx my)
      (if (in-clock? mx my)
          (new Clock%
               [x x][y y]
               [selected? true]
               [saved-mx (- mx x)]
               [saved-my (- my y)]
               [ticks ticks])
          this))
    
    ; after-button-up : Integer Integer -> Clock
    ; GIVEN: the location of a button-up event
    ; STRATEGY: Cases on whether the event is in the Clock.
    ; If the Clock is selected, then unselect it.
    (define/public (after-button-up mx my)
      (if (in-clock? mx my)
          (new Clock%
               [x x][y y]
               [selected? false]
               [saved-mx saved-mx]
               [saved-my saved-my]
               [ticks ticks])
          this))   
    
    ; after-drag : Integer Integer -> Clock
    ; GIVEN: the location of a drag event
    ; STRATEGY: Cases on whether the Clock is selected.
    ; If it is selected, move it so that the vector from the center to
    ; the drag event is equal to (mx, my)
    (define/public (after-drag mx my)
      (if selected?
          (new Clock%
               [x (calculate-x mx)]
               [y (calculate-y my)]
               [selected? true]
               [saved-mx saved-mx]
               [saved-my saved-my]
               [ticks ticks])
          this))  
    
    ; calculate-x : Integer -> Integer
    ; calculate-y : Integer ->Integer
    ; GIVEN: the x/y coordinate of the mouse event
    ; RETURNS: x/y coordinate of the target 
    ; STRATEGY: Cases on whether the position of target
    ;;          is within limits.
    (define (calculate-x mx)
      (local
        ((define x (- mx saved-mx))
         (define limit (- CANVAS-WIDTH hlf-clk-wdth)))
        (cond
          [(<= x hlf-clk-wdth) hlf-clk-wdth]
          [(>= x limit) limit]
          [else x])))
    
    (define (calculate-y my)
      (local
        ((define y (- my saved-my))
         (define limit (- CANVAS-HEIGHT hlf-clk-hiet)))
        (cond
          [(<= y hlf-clk-hiet) hlf-clk-hiet]
          [(>= y limit) limit]
          [else y])))
    
    ;; to-scene : Scene -> Scene
    ;; RETURNS: a scene like the given one, but with this Clock painted
    ;; on it.
    (define/public (add-to-scene scene)
      (place-image CLOCK-IMG x y scene))
    
    ;; in-Clock? : Integer Integer -> Boolean
    ;; GIVEN: a location on the canvas
    ;; RETURNS: true iff the location is inside this Clock.
    (define (in-clock? other-x other-y)
      (and (<= (abs (- x other-x))
               hlf-clk-wdth)
           (<= (abs (- y other-y))
               hlf-clk-hiet)))
    
    ;; toy-x : -> Integer
    ;; toy-y : -> Integer
    ;; RETURNS the respective x/y position of the square
    (define/public (toy-x) x)    
    (define/public (toy-y) y)

    ;; toy-data : -> Integer
    ;; RETURNS the number of ticks
    (define/public (toy-data) ticks)
    
    ;; test methods, to probe the Clock state.  Note that we don't have
    ;; a probe for radius.
    ;; -> (list Int Int Boolean PosInt)
    (define/public (clock-state) (list x y selected? ticks))
  
    ))

;; make-clock : PosInt PostInt -> Toy<%>
;; GIVEN: an x and a y position
;; RETURNS: an object representing a clock at the given position.
(define (make-clock x y)
  (new Clock% [x x][y y]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
    (field [FOOTBALL-IMG (bitmap "football.jpg")]
           [updated-football-scale
            (if (> scale-count 0)
                (- scale-count (/ RATE-OF-SIZE-CHANGE 10))
                scale-count)]
           [scaled-football-image
            (if (> scale-count 0)
                (scale scale-count FOOTBALL-IMG)
                empty-image)]
           [scaled-ftbl-hiet
            (image-height scaled-football-image)]
           [scaled-ftbl-wdth
            (image-width scaled-football-image)]
           [hlf-ftbl-wdth (/ scaled-ftbl-wdth 2)]
           [limit-x (- CANVAS-WIDTH hlf-ftbl-wdth)]
           [hlf-ftbl-hiet (/ scaled-ftbl-hiet 2)]
           [limit-y (- CANVAS-HEIGHT hlf-ftbl-hiet)]
           [ftbl-area (*
                       scaled-ftbl-wdth
                       scaled-ftbl-hiet)])

    (super-new)
    
    ;; after-tick : Time -> Football
    ;; RETURNS: A Football like this one, but as it should be after a tick
    ;; a selected Football doesn't move.
    ;; STRATEGY: Cases on selected?
    (define/public (after-tick)
      (if selected?
          this
          (new Football%
               [x x]
               [y y]
               [selected? selected?]
               [saved-mx saved-mx]
               [saved-my saved-my]
               [scale-count updated-football-scale])))
    
    ;; after-key-event : KeyEvent -> Football
    ;; RETURNS: A world like this one, but as it should be after the
    ;; given key event.
    ;; DETAILS: a Football ignores key events
    (define/public (after-key-event kev)
      this)      
    
    ; after-button-down : Integer Integer -> Football
    ; GIVEN: the location of a button-down event
    ; STRATEGY: Cases on whether the event is in the Football
    (define/public (after-button-down mx my)
      (if (in-football? mx my)
          (new Football%
               [x x][y y]
               [selected? true]
               [saved-mx (- mx x)]
               [saved-my (- my y)]
               [scale-count scale-count])
          this))
    
    ; after-button-up : Integer Integer -> Football
    ; GIVEN: the location of a button-up event
    ; STRATEGY: Cases on whether the event is in the Football.
    ; If the Football is selected, then unselect it.
    (define/public (after-button-up mx my)
      (if (in-football? mx my)
          (new Football%
               [x x][y y]
               [selected? false]
               [saved-mx saved-mx]
               [saved-my saved-my]
               [scale-count scale-count])
          this))   
    
    ; after-drag : Integer Integer -> Football
    ; GIVEN: the location of a drag event
    ; STRATEGY: Cases on whether the Football is selected.
    ; If it is selected, move it so that the vector from the center to
    ; the drag event is equal to (mx, my)
    (define/public (after-drag mx my)
      (if selected?
          (new Football%
               [x (calculate-x mx)]
               [y (calculate-y my)]
               [selected? true]
               [saved-mx saved-mx]
               [saved-my saved-my]
               [scale-count scale-count])
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
          [(<= x hlf-ftbl-wdth) hlf-ftbl-wdth]
          [(>= x limit-x) limit-x]
          [else x])))
    
    (define (calculate-y my)
      (local
        ((define y (- my saved-my)))       
        (cond
          [(<= y hlf-ftbl-hiet) hlf-ftbl-hiet]
          [(>= y limit-y) limit-y]
          [else y])))
    
    ;; to-scene : Scene -> Scene
    ;; RETURNS: a scene like the given one, but with this Football painted
    ;; on it.
    (define/public (add-to-scene scene)
      (place-image scaled-football-image x y scene)) 
    
    ;; in-football? : Integer Integer -> Boolean
    ;; GIVEN: a location on the canvas
    ;; RETURNS: true iff the location is inside this Football.
    (define (in-football? other-x other-y)
      (and (<= (abs (- x other-x)) hlf-ftbl-wdth)
           (<= (abs (- y other-y)) hlf-ftbl-hiet)))   

    ;; toy-x : -> Integer
    ;; toy-y : -> Integer
    ;; RETURNS the respective x/y position of the square
    (define/public (toy-x) x)   
    (define/public (toy-y) y)

    ;; toy-data : -> Integer
    ;; RETURNS the area of football  
    (define/public (toy-data) ftbl-area)
    
    ;; test methods, to probe the Football state.  Note that we don't have
    ;; a probe for radius.       
    ; -> (list Int Int Boolean PosInt)
    (define/public (football-state)
      (list x y selected? ftbl-area)))) 

;; make-football : PosInt PostInt -> Toy<%>
;; GIVEN: an x and a y position
;; RETURNS: an object representing a football at the given position.
(define (make-football x y)
  (new Football% [x x][y y]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;(run 0.5 10)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; TESTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; Testing Functions
(define (target=? trgt1 trgt2)
  (and
   (equal? (send trgt1 get-x) (send trgt2 get-x))
   (equal? (send trgt1 get-y) (send trgt2 get-y))
   (equal? (send trgt1 get-selected?) (send trgt2 get-selected?))))

(define (toy=? toy1 toy2)
  (cond
    [(and (is-a? toy1 Square%) (is-a? toy2 Square%)) (square=? toy1 toy2)]
    [(and (is-a? toy1 Throbber%) (is-a? toy2 Throbber%)) (throbber=? toy1 toy2)]
    [(and (is-a? toy1 Clock%) (is-a? toy2 Clock%)) (clock=? toy1 toy2)]
    [(and (is-a? toy1 Football%) (is-a? toy2 Football%)) (football=? toy1 toy2)]))

(define (square=? sqr1 sqr2)
  (and
   (equal? (send sqr1 toy-x) (send sqr2 toy-x))
   (equal? (send sqr1 toy-y) (send sqr2 toy-y))
   (equal? (send sqr1 toy-data) (send sqr2 toy-data))
   (set-equal? (send sqr1 square-state)
               (send sqr2 square-state))))

(define (throbber=? t1 t2)
  (and
   (equal? (send t1 toy-x) (send t2 toy-x))
   (equal? (send t1 toy-y) (send t2 toy-y))
   (equal? (send t1 toy-data) (send t2 toy-data))
   (set-equal? (send t1 throbber-state)
               (send t2 throbber-state))))

(define (clock=? clk1 clk2)
  (and
   (equal? (send clk1 toy-x) (send clk2 toy-x))
   (equal? (send clk1 toy-y) (send clk2 toy-y))
   (equal? (send clk1 toy-data) (send clk2 toy-data))
   (set-equal? (send clk1 clock-state)
               (send clk2 clock-state))))

(define (football=? ftbl1 ftbl2)
  (and
   (equal? (send ftbl1 toy-x) (send ftbl2 toy-x))
   (equal? (send ftbl1 toy-y) (send ftbl2 toy-y))
   (equal? (send ftbl1 toy-data) (send ftbl2 toy-data))
   (set-equal? (send ftbl1 football-state)
               (send ftbl2 football-state))))

(define (playground=? plgrnd1 plgrnd2)
  (and
   (andmap
    (lambda (tmp-plgrnd1 tmp-plgrnd2) (toy=? tmp-plgrnd1 tmp-plgrnd2))
    (send plgrnd1 get-toys)
    (send plgrnd2 get-toys))
   (target=? (send plgrnd1 get-target) (send plgrnd2 get-target))
   (= (send plgrnd1 get-speed)
      (send plgrnd2 get-speed))))

;;; Testing Constants
(define SPEED-10 10) 
(define TARGET (new-target)) 
(define TARGET-SEL (new Target%
                        [x HALF-CANVAS-WIDTH]
                        [y HALF-CANVAS-HEIGHT]
                        [selected? true]))
(define TARGET-SEL-1 (new Target%
                        [x TARGET-RADIUS]
                        [y TARGET-RADIUS]
                        [selected? true]))
(define TARGET-SEL-2 (new Target%
                        [x TARGET-X-MAX]
                        [y TARGET-Y-MAX]
                        [selected? true]))

(define THROBBER (make-throbber TARGET-INITIAL-X TARGET-INITIAL-Y))
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
       [r 18][s 5]))
(define THROBBER-MIN (new Throbber% 
       [x TARGET-INITIAL-X]
       [y TARGET-INITIAL-Y]
       [selected? true]
       [r 7][s -5]))
(define THROBBER-SEL-1 (new Throbber% 
       [x THROBBER-INITIAL-RADIUS]
       [y THROBBER-INITIAL-RADIUS]
       [selected? true]))
(define THROBBER-SEL-2 (new Throbber% 
       [x (- CANVAS-WIDTH THROBBER-INITIAL-RADIUS)]
       [y (- CANVAS-HEIGHT THROBBER-INITIAL-RADIUS)]
       [selected? true]))

(define SQUARE (make-square-toy TARGET-INITIAL-X TARGET-INITIAL-Y SPEED-10))
(define SQUARE-SEL (new Square% 
                          [x TARGET-INITIAL-X]
                          [y TARGET-INITIAL-Y]
                          [selected? true]
                          [speed SPEED-10]))
(define SQUARE-SEL-1 (new Square% 
                          [x HALF-SQUARE-SIDE]
                          [y HALF-SQUARE-SIDE]
                          [selected? true]
                          [speed SPEED-10]))
(define SQUARE-SEL-2 (new Square% 
                          [x MAX-X-SQUARE]
                          [y MAX-Y-SQUARE]
                          [selected? true]
                          [speed SPEED-10]))
(define SQUARE-AFTER-TICK (new Square% 
                          [x (+ SPEED-10 TARGET-INITIAL-X)]
                          [y TARGET-INITIAL-Y]
                          [speed SPEED-10]))
(define SQUARE-NEAR-BOUNDARY (new Square% 
                          [x MAX-X-SQUARE]
                          [y TARGET-INITIAL-Y]
                          [speed SPEED-10]))
(define SQUARE-NEAR-BOUNDARY-AFTER-TICK (new Square% 
                          [x MAX-X-SQUARE]
                          [y TARGET-INITIAL-Y]
                          [speed (- SPEED-10)]))
(define SQUARE-NEAR-ORIGIN (new Square% 
                          [x (- 15 HALF-SQUARE-SIDE)]
                          [y TARGET-INITIAL-Y]
                          [speed (- SPEED-10)]))
(define SQUARE-NEAR-ORIGIN-AFTER-TICK (new Square% 
                          [x HALF-SQUARE-SIDE]
                          [y TARGET-INITIAL-Y]
                          [speed SPEED-10]))
(define CLOCK (make-clock TARGET-INITIAL-X TARGET-INITIAL-Y))
(define CLOCK-SEL (new Clock% 
                         [x TARGET-INITIAL-X]
                         [y TARGET-INITIAL-Y]
                         [selected? true]))
(define CLOCK-AFTER-TICK (new Clock% 
                         [x TARGET-INITIAL-X]
                         [y TARGET-INITIAL-Y]
                         [ticks 2]))

(define FOOTBALL (make-football TARGET-INITIAL-X
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
                            [scale-count -1]))

(define WORLD
  (new PlaygroundState% [toys empty][target TARGET][speed SPEED-10]))
(define WORLD-TRGT-SEL
  (new PlaygroundState% [toys empty][target TARGET-SEL][speed SPEED-10]))
(define WORLD-WITH-ALL-TOYS-ONCE 
  (new PlaygroundState% [toys (list THROBBER SQUARE CLOCK FOOTBALL)]
       [target (new-target)]
       [speed SPEED-10]))

(define WORLD-WITH-ALL-TOYS-ONCE-SQUARE-SEL 
  (new PlaygroundState% 
       [toys (list THROBBER SQUARE-SEL CLOCK FOOTBALL)]
       [target (new-target)]
       [speed SPEED-10]))

(define WORLD-WITH-ALL-TOYS-ONCE-SQUARE-TRGT-SEL 
  (new PlaygroundState% 
       [toys (list THROBBER SQUARE-SEL CLOCK FOOTBALL)]
       [target TARGET-SEL]
       [speed SPEED-10]))

(define WORLD-WITH-ALL-TOYS-ONCE-AFTER-TICK
  (new PlaygroundState% [toys (list THROBBER-AFTER-TICK SQUARE-AFTER-TICK 
                                    CLOCK-AFTER-TICK FOOTBALL-AFTER-TICK)]
       [target TARGET]
       [speed SPEED-10]))

(define WORLD-WITH-ONE-THROBBER
  (new PlaygroundState% [toys (list THROBBER)]
                        [target (new-target)]
                        [speed SPEED-10]))
(define WORLD-WITH-ONE-CLOCK
  (new PlaygroundState% [toys (list CLOCK)]
                        [target (new-target)]
                        [speed SPEED-10]))
(define WORLD-WITH-ONE-SQUARE
  (new PlaygroundState% [toys (list SQUARE)]
                        [target (new-target)]
                        [speed SPEED-10]))
(define WORLD-WITH-ONE-SQUARE-SEL
  (new PlaygroundState% [toys (list SQUARE-SEL)]
                        [target (new-target)]
                        [speed SPEED-10]))
(define WORLD-WITH-ONE-SQUARE-TRGT-SEL
  (new PlaygroundState% [toys (list SQUARE-SEL)]
                        [target TARGET-SEL]
                        [speed SPEED-10]))
(define WORLD-WITH-ONE-FOOTBALL
  (new PlaygroundState% [toys (list FOOTBALL)]
                        [target (new-target)]
                        [speed SPEED-10]))
(define WORLD-WITH-ONE-SQUARE-SEL-AFTER-DRAG
  (new PlaygroundState% [toys (list SQUARE-SEL)]
                        [target (new-target)]
                        [speed SPEED-10]))
;;; Tests 
 
;; World Tests 
(begin-for-test
  ;; World MouseEvents
 
  (check playground=?  
          (send WORLD-WITH-ONE-SQUARE after-mouse-event
                TARGET-INITIAL-X TARGET-INITIAL-Y "button-down")  
          WORLD-WITH-ONE-SQUARE-TRGT-SEL
          "WORLD on button down")
  (check playground=? 
          (send WORLD-WITH-ONE-SQUARE after-mouse-event
                100 100 "button-down")  
          WORLD-WITH-ONE-SQUARE
          "WORLD on button down")
  (check playground=? 
         (send WORLD-WITH-ONE-SQUARE-SEL after-mouse-event
               TARGET-INITIAL-X TARGET-INITIAL-Y "drag")  
         WORLD-WITH-ONE-SQUARE-SEL-AFTER-DRAG
         "WORLD on drag") 
  (check playground=?  
          (send WORLD-WITH-ONE-SQUARE-SEL after-mouse-event
                TARGET-INITIAL-X TARGET-INITIAL-Y "button-up")  
          WORLD-WITH-ONE-SQUARE
          "WORLD on button-up")
  (check playground=? 
          (send WORLD-WITH-ONE-SQUARE after-mouse-event
                100 100 "button-up")  
          WORLD-WITH-ONE-SQUARE
          "WORLD on button up")
  
  ;; WORLD after tick
  (check playground=? 
         (send WORLD-WITH-ALL-TOYS-ONCE after-tick)  
         WORLD-WITH-ALL-TOYS-ONCE-AFTER-TICK)
    
  ;; World KeyEvents
  (check playground=?
        (make-world SPEED-10) 
        WORLD
        "Should return a world with only a target")
 (check playground=? 
        (send WORLD-WITH-ALL-TOYS-ONCE after-key-event OTHER-KEY-EVENT)  
        WORLD-WITH-ALL-TOYS-ONCE
        "Should return same world on other key event")
 (check playground=? 
        (send WORLD after-key-event NEW-THROBBER-KEY-EVENT)  
        WORLD-WITH-ONE-THROBBER
        "Should return a world with one throbber")
 (check playground=? 
        (send WORLD after-key-event NEW-CLOCK-KEY-EVENT)  
        WORLD-WITH-ONE-CLOCK
        "Should return a world with one clock")
 (check playground=? 
        (send WORLD after-key-event NEW-SQUARE-KEY-EVENT)   
        WORLD-WITH-ONE-SQUARE
        "Should return a world with one square")
 (check playground=? 
        (send WORLD after-key-event NEW-FOOTBALL-KEY-EVENT)  
        WORLD-WITH-ONE-FOOTBALL
        "Should return a world with one football")) 

;; Tests for Football
(begin-for-test
  (check football=?
        (send FOOTBALL after-button-down TARGET-INITIAL-X TARGET-INITIAL-Y)
        FOOTBALL-SEL)
  (check football=?
        (send FOOTBALL after-button-down 800 800)
        FOOTBALL)
  (check football=?
        (send FOOTBALL-SEL after-button-up TARGET-INITIAL-X TARGET-INITIAL-Y)
        FOOTBALL)
  (check football=?
        (send FOOTBALL after-button-up 800 800)
        FOOTBALL)
  (check football=?
        (send FOOTBALL after-drag TARGET-INITIAL-X TARGET-INITIAL-Y)
        FOOTBALL)
  (check football=?
        (send FOOTBALL-SEL after-drag TARGET-INITIAL-X TARGET-INITIAL-Y)
        FOOTBALL-SEL)
  (check football=?
        (send FOOTBALL-NEG-SCALE after-drag TARGET-INITIAL-X TARGET-INITIAL-Y)
        FOOTBALL-NEG-SCALE)
  (check football=?
        (send FOOTBALL-SEL after-drag -100 -100)
        FOOTBALL-SEL-1)
  (check football=?
        (send FOOTBALL-SEL after-drag 800 800)
        FOOTBALL-SEL-2)
 (check football=?
        (send FOOTBALL after-key-event OTHER-KEY-EVENT)
        FOOTBALL)
 (check football=? 
        (send FOOTBALL-SEL after-tick)
        FOOTBALL-SEL)
 (check football=? 
        (send FOOTBALL after-tick) 
        FOOTBALL-AFTER-TICK)
  (check football=?
        (send FOOTBALL after-button-down
              TARGET-INITIAL-X TARGET-INITIAL-Y)
        FOOTBALL-SEL) 
  (check-equal? (send FOOTBALL toy-data)
                (* (image-width (bitmap "football.jpg"))
                   (image-height (bitmap "football.jpg"))))
  (check-equal? (send FOOTBALL add-to-scene EMPTY-CANVAS)
                (place-image (bitmap "football.jpg")
                             TARGET-INITIAL-X TARGET-INITIAL-Y
                             EMPTY-CANVAS))) 

;; Tests for Square
(begin-for-test
  (check square=?
         (send SQUARE after-key-event OTHER-KEY-EVENT)
         SQUARE)
  (check square=?
         (send SQUARE-SEL after-tick)
         SQUARE-SEL)
  (check square=?
         (send SQUARE after-tick)
         SQUARE-AFTER-TICK)
  (check square=?
         (send SQUARE-NEAR-BOUNDARY after-tick)
         SQUARE-NEAR-BOUNDARY-AFTER-TICK)
  (check square=?
         (send SQUARE-NEAR-ORIGIN after-tick)
         SQUARE-NEAR-ORIGIN-AFTER-TICK)
  (check square=?
         (send SQUARE after-drag TARGET-INITIAL-X TARGET-INITIAL-Y)
         SQUARE)
  (check square=?
         (send SQUARE-SEL after-drag -100 -100)
         SQUARE-SEL-1)
  (check square=?
         (send SQUARE-SEL after-drag 800 800)
         SQUARE-SEL-2)
  (check-equal? (send (make-square-toy
                       TARGET-INITIAL-X TARGET-INITIAL-Y
                       SPEED-10) toy-data)
                SPEED-10)
  (check-equal? (send SQUARE add-to-scene EMPTY-CANVAS)
                (place-image SQUARE-IMG
                             TARGET-INITIAL-X TARGET-INITIAL-Y
                             EMPTY-CANVAS)))

;; Tests for Clock

(define CLOCK-IMAGE
                (place-image (text (number->string 2) CLOCK-SIZE CLOCK-COLOR)
                             TARGET-INITIAL-X TARGET-INITIAL-Y
                             EMPTY-CANVAS))
(define CLOCK-FOR-DRAG (new Clock% 
                         [x TARGET-INITIAL-X]
                         [y TARGET-INITIAL-Y]
                         [selected? true]
                         [saved-mx 1]
                         [saved-my 1]
                         [ticks 2]))

(define CLOCK-IM (text (number->string 2) CLOCK-SIZE CLOCK-COLOR))
(define WIDTH-CLOCK-IM (/ (image-width CLOCK-IM)  2))
(define HEIGHT-CLOCK-IM (/ (image-height CLOCK-IM)  2))
(define WIDTH-CLOCK-IMA (- CANVAS-WIDTH (/ (image-width CLOCK-IM)  2)))
(define HEIGHT-CLOCK-IMA (- CANVAS-HEIGHT(/ (image-height CLOCK-IM)  2)))


(define CLOCK-AFTER-DRAG-LEFT (new Clock%
               [x WIDTH-CLOCK-IM]
               [y HEIGHT-CLOCK-IM]
               [selected? true]
               [saved-mx 1]
               [saved-my 1]
               [ticks 2]))

(define CLOCK-AFTER-DRAG-RIGHT (new Clock%
               [x WIDTH-CLOCK-IMA]
               [y HEIGHT-CLOCK-IMA]
               [selected? true]
               [saved-mx 1]
               [saved-my 1]
               [ticks 2]))


(define CLOCK-AFTER-DRAG (new Clock%
               [x 19]
               [y 39]
               [selected? true]
               [saved-mx 1]
               [saved-my 1]
               [ticks 2]))



(begin-for-test

  (check clock=?
        (send CLOCK after-key-event OTHER-KEY-EVENT)
        CLOCK)
 (check-equal? (send (send CLOCK after-tick) toy-data)
               (send CLOCK-AFTER-TICK toy-data))
 (check clock=?
        (send CLOCK-SEL after-button-up TARGET-INITIAL-X TARGET-INITIAL-Y)
         CLOCK"the clock should be unselected")
  (check clock=?
        (send CLOCK after-button-up 80 100)
        CLOCK"the clock should be unselected")
(check clock=?
        (send CLOCK after-button-down TARGET-INITIAL-X TARGET-INITIAL-Y)
        CLOCK-SEL "the clock should be selected after button down")
  (check clock=?
        (send CLOCK after-button-down 800 800)
        CLOCK "the unselected clock shoule remain unselected")
  
  (check-equal? (send CLOCK-AFTER-TICK add-to-scene EMPTY-CANVAS)
              CLOCK-IMAGE "displays of the state after tick")
             
  (check clock=?
        (send CLOCK-FOR-DRAG after-drag -1 -2)
        CLOCK-AFTER-DRAG-LEFT "the clock is dragged to anew position")
   (check clock=?
        (send CLOCK-FOR-DRAG after-drag 700 800)
        CLOCK-AFTER-DRAG-RIGHT"the clock is dragged to a new position")
   (check clock=?
        (send CLOCK-FOR-DRAG after-drag 20 40)
        CLOCK-AFTER-DRAG"the clock is dragged to a new position")

  (check clock=?
        (send CLOCK after-drag TARGET-INITIAL-X TARGET-INITIAL-Y)
        CLOCK"the unselected clock is not dragged"))
  

;; Tests for throbber
(begin-for-test
 (check throbber=?
        (send THROBBER after-key-event OTHER-KEY-EVENT)
        THROBBER)
 (check throbber=?
        (send THROBBER after-tick) 
        THROBBER-AFTER-TICK)
 (check throbber=?
        (send THROBBER-MAX after-tick) 
        THROBBER-MAX)
 (check throbber=?
        (send THROBBER-MIN after-tick) 
        THROBBER-MIN)
 (check throbber=?
        (send THROBBER after-button-down TARGET-INITIAL-X TARGET-INITIAL-Y) 
        THROBBER-SEL)
 (check throbber=?
        (send THROBBER-SEL after-button-up TARGET-INITIAL-X TARGET-INITIAL-Y) 
        THROBBER)
 (check throbber=?
        (send THROBBER after-drag TARGET-INITIAL-X TARGET-INITIAL-Y) 
        THROBBER)
  (check throbber=?
        (send THROBBER-SEL after-drag TARGET-INITIAL-X TARGET-INITIAL-Y) 
        THROBBER-SEL)
  (check throbber=?
        (send THROBBER-SEL after-drag -100 -100) 
        THROBBER-SEL-1)
  (check throbber=?
        (send THROBBER-SEL after-drag 800 800) 
        THROBBER-SEL-2)
 (check throbber=?
        (send THROBBER after-button-down 100 100) 
        THROBBER)
 (check throbber=?
        (send THROBBER after-button-up 100 100) 
        THROBBER)
  (check throbber=?
        (send THROBBER after-drag 100 100) 
        THROBBER)
 (check-equal? (send (send THROBBER after-tick) toy-data)
               (+ THROBBER-INITIAL-RADIUS RATE-OF-SIZE-CHANGE)) 
 (check check-equal?
        (send THROBBER add-to-scene EMPTY-CANVAS)
        (place-image (circle THROBBER-INITIAL-RADIUS
                             THROBBER-MODE THROBBER-COLOR)
                     TARGET-INITIAL-X TARGET-INITIAL-Y
                     EMPTY-CANVAS)))

;; Tests for Target
(begin-for-test
   (check target=?
        (send TARGET after-tick)
        TARGET)
 (check target=?
        (send TARGET after-mouse-event OTHER-MOUSE-EVENT)
        TARGET)
 (check target=?
        (send TARGET after-key-event OTHER-KEY-EVENT)
        TARGET)
 (check target=?
        (send TARGET after-button-down TARGET-INITIAL-X TARGET-INITIAL-Y)
        TARGET-SEL)
 (check target=?
        (send TARGET-SEL after-button-up TARGET-INITIAL-X TARGET-INITIAL-Y)
        TARGET)
 (check target=?
        (send TARGET after-drag TARGET-INITIAL-X TARGET-INITIAL-Y)
        TARGET)
 (check target=?
        (send TARGET-SEL after-drag TARGET-INITIAL-X TARGET-INITIAL-Y)
        TARGET-SEL)
 (check target=?
        (send TARGET-SEL after-drag -100 -100)
        TARGET-SEL-1)
 (check target=?
        (send TARGET-SEL after-drag 800 800)
        TARGET-SEL-2)
 (check-equal? (send TARGET after-tick) TARGET)
 (check-equal? (send TARGET add-to-scene EMPTY-CANVAS)
               (place-image TARGET-IMG
                            HALF-CANVAS-WIDTH
                            HALF-CANVAS-HEIGHT
                            EMPTY-CANVAS))) 

;; Tests for Playground
(begin-for-test
  (check-equal? (send WORLD target-x)
                HALF-CANVAS-WIDTH)
  (check-equal? (send WORLD target-y)
                HALF-CANVAS-HEIGHT)
  (check-equal? (send WORLD target-selected?)
                false)
  (check-equal? (send WORLD get-toys)
                empty)
  (check-equal? (send WORLD-WITH-ONE-THROBBER get-toys)
                (list THROBBER))
  (check-equal? (send WORLD after-mouse-event
                      TARGET-INITIAL-X TARGET-INITIAL-Y OTHER-MOUSE-EVENT)
                WORLD)
  (check-equal? (send WORLD-WITH-ONE-THROBBER to-scene)
                (place-image (circle THROBBER-INITIAL-RADIUS
                                     THROBBER-MODE
                                     THROBBER-COLOR)
                             HALF-CANVAS-WIDTH
                             HALF-CANVAS-HEIGHT
                             (place-image TARGET-IMG
                                          TARGET-INITIAL-X
                                          TARGET-INITIAL-Y
                                          EMPTY-CANVAS)))) 
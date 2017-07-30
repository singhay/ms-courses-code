;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-beginner-abbr-reader.ss" "lang")((modname screensaver-3) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f () #f)))
;; screensaver-3.rkt : First Question of Problem Set 04. 
;; Description:
;   The screensaver is a universe program that displays zero or more
;   rectangles that move around a canvas.
;   The rectangles bounce smoothly off the edge of the canvas.
;   Bouncing is defined as follows: if the rectangle in its normal
;   motion would hit or go past one side of the canvas at the next
;   tick, then instead at the next tick it should appear tangent to
;   the edge of the canvas, travelling at the same speed, but in the
;   opposite direction. If the rectangle would go past a corner, then
;   both the x- and y- velocities are reversed. We call this a
;   perfect bounce.
;   Each rectangle is displayed as an outline blue rectangle 60 pixels
;   wide and 50 pixels high. In addition, the rectangle's current
;   velocity is displayed as a string (vx, vy) in the center of the
;   rectangle.
;   The space bar pauses or unpauses the entire simulation.
;   The simulation is initially PAUSED.
;   The canvas is 400 pixels wide and 300 pixels high.
;   The two rectangles are initially centered at positions (200,100)
;   and (200,200), and have velocities of (-12, 20) and (23, -14),
;   respectively.
;   The rectangle is selectable and draggable.
;   Depressing the mouse button within the rectangle causes the
;   rectangle to be "selected". When the rectangle is selected, it
;   and its velocity are displayed in red instead of blue.
;   The location where the mouse grabbed the rectangle should be
;   indicated by an outline red circle of radius 5 pixels.
;   Simply pressing the mouse button, without moving the mouse,
;   should not cause the rectangle to move on the canvas.
;   Once the rectangle has been selected, you should be able to drag
;   it around the Universe canvas with the mouse. As you drag it,
;   the position of the mouse within the rectangle
;   (as indicated by the red circle), should not change.
;   When the mouse button is released, the rectangle should go back
;   to its unselected state (outline blue) in its new location.
;   All of this works whether or not the simulation is paused.
;; Goal: To start the screensaver.
;; start with (screensaver 0.5)
;; Add new rectangle by pressing "n" button on keyboard.
;; Change Y Velocity by selecting the rectangle and
;; pressing the up to increase and down to decrease.
;; Change X Velocity by selecting the rectangle and
;; pressing the right to increase and left to decrease.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; LIBRARY
(require rackunit)
(require "extras.rkt")
(check-location "04" "screensaver-3.rkt") 
(require 2htdp/image)
(require 2htdp/universe)
(provide screensaver
         initial-world
         world-after-tick
         world-after-key-event
         rect-after-key-event
         world-rects         
         world-paused?
         rect-x
         rect-y
         rect-vx
         rect-vy
         world-after-mouse-event
         rect-after-mouse-event
         rect-selected?
         new-rectangle)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; MAIN FUNCTION

;; screensaver : PosReal -> WorldState
;; GIVEN   : the speed of the simulation, in seconds/tick
;; EFFECT  : runs the simulation, starting with the initial
;;           state as specified in the problem set.
;; RETURNS : the final state of the world
;; EXAMPLES: (screensaver 10) = simulation at 10 seconds/tick
;; STRATEGY: Combine Simpler Functions
(define (screensaver seconds-per-tick)
  (big-bang (initial-world seconds-per-tick) 
            (on-draw world-to-scene)            
            (on-tick world-after-tick seconds-per-tick)
            (on-key world-after-key-event)
            (on-mouse world-after-mouse-event)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; CONSTANTS

;; dimensions of the rectangle
(define RECTANGLE-WIDTH 60)
(define RECTANGLE-HEIGHT 50)
(define HALF-RECTANGLE-WIDTH (/ RECTANGLE-WIDTH 2))
(define HALF-RECTANGLE-HEIGHT (/ RECTANGLE-HEIGHT 2))
(define MODE "outline")
(define SELECTED-COLOR "red")
(define NORMAL-COLOR "blue")

;; dimensions of the canvas
(define CANVAS-WIDTH 400)
(define HALF-CANVAS-WIDTH (/ CANVAS-WIDTH 2))
(define CANVAS-HEIGHT 300)
(define HALF-CANVAS-HEIGHT (/ CANVAS-HEIGHT 2))
(define EMPTY-CANVAS (empty-scene CANVAS-WIDTH CANVAS-HEIGHT))

;; Limits of Rectangle Movement
(define X-ORIGIN HALF-RECTANGLE-WIDTH) 
(define X-BOUNDARY (- CANVAS-WIDTH HALF-RECTANGLE-WIDTH))
(define Y-ORIGIN HALF-RECTANGLE-HEIGHT)
(define Y-BOUNDARY (- CANVAS-HEIGHT HALF-RECTANGLE-HEIGHT))

;; Velocity Display Properties
(define VELOCITY-FONT-SIZE 12)

;; Dimensions of the Cursor
(define CURSOR-DOT-RADIUS 5)
(define CURSOR-DOT (circle CURSOR-DOT-RADIUS MODE SELECTED-COLOR))

;; KeyEvents
(define pause-key-event " ")
(define non-pause-key-event "q")
(define ADD-NEW-RECTANGLE-EVENT "n")
(define INCR-RECTANGLE-YVELOCITY-EVENT "up")
(define DECR-RECTANGLE-YVELOCITY-EVENT "down")
(define DECR-RECTANGLE-XVELOCITY-EVENT "left")
(define INCR-RECTANGLE-XVELOCITY-EVENT "right")  
(define OTHER-KEY-EVENT "\r")

;; MouseEvents
(define BUTTON-DOWN-EVENT "button-down")
(define DRAG-EVENT "drag")
(define BUTTON-UP-EVENT "button-up") 
(define OTHER-EVENT "enter")

;; Incremental Counter
(define INCR-BY-2 2)

;; Definitions to be used for Test Cases
;; Initialization constants
(define ZERO 0)
(define INITIAL-RECT-12-X 200)
(define INITIAL-RECT-1-Y 100)
(define INITIAL-RECT-1-VX -12)
(define INITIAL-RECT-1-VY 20)
(define INITIAL-RECT-2-VX 23)
(define INITIAL-RECT-2-VY -14)
(define MOUSE-X-36 36)
(define MOUSE-Y-48 48)
(define X-30 30)
(define X-40 40)
(define X-35 35)
(define Y-45 45)
(define X-36 36)
(define Y-48 48)
(define DX-4 4)
(define DY-9 9)
(define VX-NEG-23 -23) 
(define VY-14 14)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DATA DEFINITIONS 

(define-struct rect (x y vx vy selected? dx dy))
;; A Rectangle is a
;; (make-rect NonNegInt NonNegInt Int Int Boolean Int Int)
;; INTERP:
;; x, y      gives the respective X&Y position of rectangle's center.
;; vx, vy    gives the respective X&Y velocity of the rectangle.
;; selected? gives the status whether rectangle is selected via
;;           mouse button down or not.
;; dx, dy    gives the respective X&Y offset of the selected position
;;           from the center of the rectangle.

;; TEMPLATE:
;; rectangle-fn : Rectangle -> ??
#|
(define (rect-fn r)
 (... (rect-x r) (rect-y r)
      (rect-vx r) (rect-vy r)
      (rect-selected? r)      
      (rect-dx r) (rect-dy r)))
|#

;; A List of Rectangles (ListOfRectangles) is one of:
;; -- empty
;; -- (cons Number ListOfRectangles)

;; TEMPLATE:
;; ListOfRectangles-fn : ListOfRectangles -> ??
#|
(define (ListOfRectangles-fn lst)
 (cond
  [(empty? lst) ...]
  [else (... (first lst)
             (ListOfRectangles-fn (rest lst)))]))
|#

(define-struct world (rects paused?))
;; A World is a (make-world ListOfRectangles Boolean)
;; INTERP:
;; rects   is the list of all the rectangles present in screensaver. 
;; paused? describes whether or not the world is paused.

;; TEMPLATE:
;; world-fn : World -> ??
#|
(define (world-fn w)
   (... (world-rects w)
        (world-paused? w)))
|#

;; EXAMPLES of Rectangle for TESTS
;  First Rectangle used to Initialize the World
(define INITIAL-RECT-1 
  (make-rect
   INITIAL-RECT-12-X
   INITIAL-RECT-1-Y
   INITIAL-RECT-1-VX
   INITIAL-RECT-1-VY
   false
   ZERO ZERO))

;  First Selected Rectangle used to Initialize the World
(define INITIAL-RECT-1-SELECTED
  (make-rect
   INITIAL-RECT-12-X
   INITIAL-RECT-1-Y
   INITIAL-RECT-1-VX
   INITIAL-RECT-1-VY
   true
   ZERO ZERO))

;  Second Rectangle used to Initialize the World
(define INITIAL-RECT-2
  (make-rect
   INITIAL-RECT-12-X
   INITIAL-RECT-12-X
   INITIAL-RECT-2-VX
   INITIAL-RECT-2-VY
   false
   ZERO ZERO))

;  Second Selected Rectangle used to Initialize the World
(define INITIAL-RECT-2-SELECTED
  (make-rect
   INITIAL-RECT-12-X
   INITIAL-RECT-12-X
   INITIAL-RECT-2-VX
   INITIAL-RECT-2-VY
   true
   ZERO ZERO))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; initial-world : Any -> WorldState
;; GIVEN   : any value (ignored)
;; RETURNS : the initial world specified in the problem set
;; EXAMPLES: see tests below
;; STRATEGY: Combine Simpler Functions
(define (initial-world any) 
  (make-world (list empty) true))
;; TESTS
(begin-for-test
  (check-equal?
   (initial-world X-30)
   (make-world (list empty) true)
   "Should return a new PAUSED world with empty ListOfRectangles."))

;; world-to-scene : WorldState -> Scene
;; GIVEN   : a world state(w) comprising of ListOfRectangles field.
;; RETURNS : a Scene that portrays the given world.
;; EXAMPLES: see tests below
;; STRATEGY: Use template for World on w
(define (world-to-scene w)
  (place-rects (world-rects w)))  
;; TESTS 
(begin-for-test
  (check-equal?
   (world-to-scene WORLD-INITIAL-RECT12-PLAYED)
   (place-rects (world-rects WORLD-INITIAL-RECT12-PLAYED))
   "Should return a rendered world with all the rectangles
    from the ListOfRectangles placed in it."))
   
;; world-after-tick : WorldState -> WorldState
;; GIVEN   : a world state(w).
;; RETURNS : the world state that should follow the given
;;           world state after a tick.
;; EXAMPLES: see tests below
;; STRATEGY: Use Template for World on w, and
;;           then cases on if the world is paused.
(define (world-after-tick w)
  (if (world-paused? w)
    w
    (make-world
     (rects-after-tick (world-rects w)) 
     (world-paused? w))))
;; TESTS
(begin-for-test
  (check-equal?
   (world-after-tick WORLD-INITIAL-RECT12-PAUSED)
   WORLD-INITIAL-RECT12-PAUSED
   "Should return the same world since the World is Paused.")
  (check-equal?
   (world-after-tick WORLD-INITIAL-RECT12-PLAYED)
   (make-world
    LIST-OF-RECTANGLES-AFTER-TICK
    false)
   "Should return World State comprising of updated Rectangles."))

;; world-after-key-event : WorldState KeyEvent -> WorldState
;; GIVEN   : a world state(w) and a KeyEvent(kev).
;; RETURNS : the world that should follow the given world
;;           after the given key event.
;;           on n key, adds new rectangle to world
;;           on space, toggle paused?
;; EXAMPLES: see tests below
;; STRATEGY: cases on KeyEvent kev 
(define (world-after-key-event w kev)
  (cond
    [(key=? kev "n") (add-rectangle-to-world w)]
    [(key=? kev " ") (world-with-paused-toggled w)]
    [else
     (make-world
      (rects-after-key-event (world-rects w) kev)
      (world-paused? w))]))

;; TESTS
(begin-for-test
  (check-equal?
   (world-after-key-event
    WORLD-INITIAL-RECT12-PLAYED ADD-NEW-RECTANGLE-EVENT)
   (add-rectangle-to-world WORLD-INITIAL-RECT12-PLAYED)
   "Should return a new world with a new rectangle added.")  
  (check-equal?
   (world-after-key-event
    WORLD-INITIAL-RECT12-PLAYED pause-key-event)
   (world-with-paused-toggled WORLD-INITIAL-RECT12-PLAYED)
   "Should return a new world but paused.")
  (check-equal?
   (world-after-key-event
    WORLD-INITIAL-RECT12-PLAYED non-pause-key-event)
   WORLD-INITIAL-RECT12-PLAYED
   "Should return the same state as input."))

;; rect-after-key-event : Rectangle KeyEvent -> Rectangle
;; GIVEN   : a Rectangle(rect) and a KeyEvent(kev).
;; RETURNS : the state of the rectangle that should follow the given 
;;           rectangle after incrementing/decrementing the velocity
;;           of rectangle by 2 pixels/tick based on the given KeyEvent. 
;; EXAMPLES: see tests below
;; STRATEGY: cases on KeyEvent kev 
(define (rect-after-key-event rect kev)
  (cond
    [(key=? kev "up") (vy-decremented rect)]
    [(key=? kev "down") (vy-incremented rect)]
    [(key=? kev "left") (vx-decremented rect)]
    [(key=? kev "right") (vx-incremented rect)]
    [else rect])) 
;; TESTS
(begin-for-test
  (check-equal?
   (rect-after-key-event INITIAL-RECT-1 INCR-RECTANGLE-YVELOCITY-EVENT)
   (vy-decremented INITIAL-RECT-1)
   "Should return a same rectangle with Y velocity
    decreased by 2 pixels/tick.")
  (check-equal?
   (rect-after-key-event INITIAL-RECT-1 INCR-RECTANGLE-XVELOCITY-EVENT)
   (vx-incremented INITIAL-RECT-1)
   "Should return a same rectangle with Y velocity
    increased by 2 pixels/tick.")
  (check-equal?
   (rect-after-key-event INITIAL-RECT-1 DECR-RECTANGLE-YVELOCITY-EVENT)
   (vy-incremented INITIAL-RECT-1)
   "Should return a same rectangle with Y velocity
    increased by 2 pixels/tick.")
  (check-equal?
   (rect-after-key-event INITIAL-RECT-1 DECR-RECTANGLE-XVELOCITY-EVENT)
   (vx-decremented INITIAL-RECT-1)
   "Should return a same rectangle with Y velocity
    increased by 2 pixels/tick.")
  (check-equal?
   (rect-after-key-event INITIAL-RECT-1 OTHER-KEY-EVENT)
   INITIAL-RECT-1
   "Should return a same rectangle."))

;; world-after-mouse-event : WorldState Int Int MouseEvent -> WorldState
;; GIVEN   : a World(w), the x(mx) and y(mx) coordinates
;;           of a MouseEvent, and the MouseEvent(mev).
;; RETURNS : the world that should follow the given world
;;           after the given MouseEvent.
;; EXAMPLES: see tests below
;; STRATEGY: Use Template of World on w 
(define (world-after-mouse-event w mx my mev)
  (make-world
   (rects-after-mouse-event (world-rects w) mx my mev)
   (world-paused? w)))
;; TESTS
(begin-for-test
  (check-equal? 
   (world-after-mouse-event
    WORLD-INITIAL-RECT12-PAUSED
    MOUSE-X-36
    MOUSE-Y-48
    BUTTON-DOWN-EVENT)
   (make-world
    (rects-after-mouse-event
     LIST-OF-RECTANGLES
     MOUSE-X-36
     MOUSE-Y-48
     BUTTON-DOWN-EVENT)
    true)
   "Should return a Paused World.")
  (check-equal?
   (world-after-mouse-event
    WORLD-INITIAL-RECT12-PLAYED
    MOUSE-X-36
    MOUSE-Y-48
    BUTTON-DOWN-EVENT)
   (make-world
    (rects-after-mouse-event
     LIST-OF-RECTANGLES
     MOUSE-X-36
     MOUSE-Y-48
     BUTTON-DOWN-EVENT)
    false)
   "Should return a world with Retangles made based on whether
    they are selected and placed at MOUSE-X-36, MOUSE-Y-48 and
    paused since mouseEvent is button-down."))

;; rect-after-mouse-event : Rectangle Int Int MouseEvent -> Rectangle
;; GIVEN   : a Rectangle(rect), the x(mx) and y(mx) coordinates
;;           of a MouseEvent, and the MouseEvent(mev).
;; RETURNS : the rectangle that should follow the given
;;           rectangle after the given the MouseEvent.
;; EXAMPLE : see tests below
;; STRATEGY: Divide into Cases on KeyEvent mev
(define (rect-after-mouse-event r mx my mev)
  (cond
    [(empty? r) r]
    [(mouse=? mev "button-down") (rect-after-button-down r mx my)]
    [(mouse=? mev "drag") (rect-after-drag r mx my)]
    [(mouse=? mev "button-up") (rect-after-button-up r)]
    [else r]))
;; TESTS
(begin-for-test
  (check-equal?
   (rect-after-mouse-event
    INITIAL-RECT-1
    MOUSE-X-36
    MOUSE-Y-48
    BUTTON-DOWN-EVENT)
   (rect-after-button-down INITIAL-RECT-1 MOUSE-X-36 MOUSE-Y-48)
   "Should return same Rectangle except rect-mx set to MOUSE-X-36
    rect-my set to MOUSE-Y-48 and rect-dx and rect-dy set to
    (- (rect-x INITIAL-RECT-1) MOUSE-X-36) and (- (rect-y INITIAL-RECT-1) MOUSE-Y-48)
    correspondingly with rect-selected? set to #true")
  (check-equal?
   (rect-after-mouse-event
    INITIAL-RECT-1
    MOUSE-X-36
    MOUSE-Y-48
    DRAG-EVENT)
   (rect-after-drag INITIAL-RECT-1 MOUSE-X-36 MOUSE-Y-48)
   "Should return a new Rectangle placed at (MOUSE-X-36,MOUSE-Y-48)
    with rect-selected? set to #true")
  (check-equal?
   (rect-after-mouse-event 
    INITIAL-RECT-1
    MOUSE-X-36
    MOUSE-Y-48
    BUTTON-UP-EVENT)
   (rect-after-button-up INITIAL-RECT-1)
   "Should return Rectangle placed at (MOUSE-X-36,MOUSE-Y-48)
    with rect-selected? set to #false")
  (check-equal?
   (rect-after-mouse-event 
    INITIAL-RECT-1
    MOUSE-X-36
    MOUSE-Y-48
    OTHER-EVENT)
   INITIAL-RECT-1
   "Should Return Input Rectangle since it was ignored due
    to an input other than button-down, drag, and button-up.")
  (check-equal?
   (rect-after-mouse-event 
    empty
    MOUSE-X-36
    MOUSE-Y-48
    OTHER-EVENT)
   empty
   "Should Return same Rectangle given."))

;; new-rectangle : NonNegInt NonNegInt Int Int -> Rectangle
;; GIVEN   : 2 non-negative integers x and y,
;;           and 2 integers vx and vy
;; RETURNS : a rectangle centered at (x,y), which will travel with
;;           velocity (vx, vy).
;; EXAMPLE : see tests below
;; STRATEGY: Combine Simpler Functions
(define (new-rectangle x y vx vy)
 (make-rect x y vx vy false ZERO ZERO))
;; TESTS
(define LIST-OF-RECTANGLES-AFTER-TICK
  (list (new-rectangle 30 59 23 14)
        (new-rectangle 30 59 23 14)
        (new-rectangle 30 59 23 14)))
(begin-for-test
  (check-equal?
   (new-rectangle
    INITIAL-RECT-12-X
    INITIAL-RECT-12-X
    INITIAL-RECT-2-VX
    INITIAL-RECT-2-VY)
   (make-rect
    INITIAL-RECT-12-X
    INITIAL-RECT-12-X
    INITIAL-RECT-2-VX
    INITIAL-RECT-2-VY
    false ZERO ZERO)
   "Should return a new rectangle with x(200), y(200), vx(23),
    vy(-14),selected?(#false always), and both offset ZERO(0)"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; HELPER FUNCTIONS:

;; world-with-paused-toggled : World -> World
;; GIVEN   : a world(w) comprising paused? field.
;; RETURNS : a world just like the given one,
;;           but with paused? toggled.
;; EXAMPLE : see tests below
;; STRATEGY: use template for World on w
(define (world-with-paused-toggled w)
  (make-world
   (world-rects w)
   (not (world-paused? w))))

;; TESTS
(begin-for-test
  (check-equal?
   (world-with-paused-toggled
    WORLD-INITIAL-RECT12-PAUSED)
   (make-world
    LIST-OF-RECTANGLES
    false)
   "Return a new World like the given world,
    but with world-paused? set to true.")
  (check-equal?
   (world-with-paused-toggled
    WORLD-INITIAL-RECT12-PLAYED)
   (make-world
    LIST-OF-RECTANGLES
    true)
   "Return a new World like the given world,
    but with world-paused? set to false."))

;; rects-after-mouse-event : ListOfRectangles Int Int MouseEvent -> ListOfRectangles
;; GIVEN   : a ListOfRectangles(LOR), the x(mx) and y(mx) coordinates
;;           of a MouseEvent, and the MouseEvent(mev).
;; RETURNS : a ListOfRectangles that should follow the given
;;           ListOfRectangles after the given MouseEvent.
;; EXAMPLE : see tests below
;; STRATEGY: Use template for ListOfRectangles on LOR
(define (rects-after-mouse-event LOR mx my mev)
  (cond
    [(empty? LOR) empty]
    [else
     (append
      (list (rect-after-mouse-event (first LOR) mx my mev))
      (rects-after-mouse-event (rest LOR) mx my mev))]))
;; TESTS
(define NEW-RECT-XY-ORIG
  (new-rectangle X-35 Y-45 VX-NEG-23 VY-14))
(define XY-ORIG-SELECTED-VX-DY
  (make-rect X-35 Y-45 VX-NEG-23 VY-14 true DX-4 DY-9))
(define LIST-OF-RECTANGLES
  (list (new-rectangle X-35 Y-45 VX-NEG-23 VY-14)
        (new-rectangle X-35 Y-45 VX-NEG-23 VY-14)
        (new-rectangle X-35 Y-45 VX-NEG-23 VY-14)))
(define LIST-OF-RECTANGLES-1-SELECTED
  (list XY-ORIG-SELECTED-VX-DY
        (new-rectangle X-35 Y-45 VX-NEG-23 VY-14)
        (new-rectangle X-35 Y-45 VX-NEG-23 VY-14)))

;; EXAMPLES of World for TESTS
;  Paused World
(define WORLD-INITIAL-RECT12-PAUSED
  (make-world
   LIST-OF-RECTANGLES
   true))

;  Played World
(define WORLD-INITIAL-RECT12-PLAYED
  (make-world
   LIST-OF-RECTANGLES
   false))

;  Played World with First Rectangle Selected
(define WORLD-INITIAL-RECT1SEL2-PLAYED
  (make-world
    LIST-OF-RECTANGLES-1-SELECTED
   false))
 
(begin-for-test
  (check-equal?
   (rects-after-mouse-event
    LIST-OF-RECTANGLES-1-SELECTED X-35 Y-45 BUTTON-DOWN-EVENT)
   (append
    (list (rect-after-mouse-event
           (first LIST-OF-RECTANGLES-1-SELECTED)
           X-35 Y-45 BUTTON-DOWN-EVENT))
    (list (rect-after-mouse-event
           (new-rectangle X-35 Y-45 VX-NEG-23 VY-14)
           X-35 Y-45 BUTTON-DOWN-EVENT))
    (list (rect-after-mouse-event
           (new-rectangle X-35 Y-45 VX-NEG-23 VY-14)
           X-35 Y-45 BUTTON-DOWN-EVENT)))
   "Should return a ListOfRectangles with a cursor dot placed at (35,45)
    on the rectangle upon which button down event was performed. "))
  
;; rect-after-button-down : Rectangle Integer Integer -> Rectangle
;; GIVEN   : a Rectangle(rect), the x(mx) and y(mx) 
;;           coordinates of a MouseEvent.
;; RETURNS : the Rectangle following a button-down at the
;;           given location(x(mx) and y(mx) coordinates).
;; EXAMPLE : see tests below 
;; STRATEGY: Use template for Rectangle on rect
(define (rect-after-button-down rect x y)
  (if (in-rect? rect x y)
      (make-rect
       (rect-x rect) (rect-y rect) (rect-vx rect) (rect-vy rect)
       true
       (- (rect-x rect) x) (- (rect-y rect) y))
      rect))
;; TESTS
(define RECT-X-ORIG-Y-ORIG-BTNDWN
  (make-rect 40 36 -23 -14 true -30 6))
(begin-for-test
  (check-equal?
   (rect-after-button-down
    RECT-X-ORIG-Y-ORIG 70 30)
    RECT-X-ORIG-Y-ORIG-BTNDWN
   "Should return a new rectangle with rect-selected?
    set to #true same x&y coordinates as original and
    updated mx(70), my(30), dx(40-70), and dy(36-30)")
  (check-equal?
   (rect-after-button-down RECT-X-ORIG-Y-ORIG ZERO ZERO)
   RECT-X-ORIG-Y-ORIG
   "Should return a same rectangle")
  (check-equal?
   (rect-after-button-down RECT-X-ORIG-Y-ORIG 170 200)
   RECT-X-ORIG-Y-ORIG
   "Should return the same Rectangle since input mouse
    coordinates are out of Rectangle Bounding Box"))

;; rect-after-drag : Rectangle Integer Integer -> Rectangle
;; GIVEN   : a Rectangle(rect), the x(mx) and y(mx) 
;;           coordinates of a MouseEvent.
;; RETURNS : the Rectangle following a drag at the at the
;;           given location(x(mx) and y(mx) coordinates).
;; EXAMPLE : see tests below
;; STRATEGY: Use template for Rectangle on rect
(define (rect-after-drag rect x y) 
  (if (rect-selected? rect)
      (make-rect
       (+ x (rect-dx rect)) (+ y (rect-dy rect))
       (rect-vx rect) (rect-vy rect)
       true
       (rect-dx rect) (rect-dy rect)) 
      rect))
;; TESTS
(define RECT-X-ORIG-Y-ORIG-BTNDRAG
  (make-rect 40 36 -23 -14 true ZERO ZERO))
(define RECT-X-ORIG-Y-ORIG-BTNDRAGED
  (make-rect 170 30 -23 -14 true ZERO ZERO))
(begin-for-test
  (check-equal? 
   (rect-after-drag RECT-X-ORIG-Y-ORIG-BTNDRAG 170 30)
   RECT-X-ORIG-Y-ORIG-BTNDRAGED
   "Should return a new rectangle
    with rect-selected? set to true")
  (check-equal?
   (rect-after-drag RECT-X-ORIG-Y-ORIG 170 30)
   RECT-X-ORIG-Y-ORIG
   "Should return the same rectangle
    with rect-selected? set to false"))

;; rect-after-button-up : Rectangle -> Rectangle
;; GIVEN   : A Rectangle(rect)
;; RETURNS : the Rectangle following a button-up
;; EXAMPLE : see tests below
;; STRATEGY: Use template for Rectangle on rect
(define (rect-after-button-up rect) 
  (if (rect-selected? rect)
      (make-rect
       (rect-x rect) (rect-y rect)
       (rect-vx rect) (rect-vy rect)
       false
       ZERO ZERO)
      rect))
;; TESTS
(begin-for-test
  (check-equal?
   (rect-after-button-up RECT-X-ORIG-Y-ORIG-SELECTED)
   RECT-X-ORIG-Y-ORIG
   "Should return the same rectangle
    with rect-selected? set to false")
  (check-equal?
   (rect-after-button-up RECT-X-ORIG-Y-ORIG)
   RECT-X-ORIG-Y-ORIG
   "Should return the same Rectangle"))

;; in-rect?: Rectangle Integer Integer -> Boolean
;; GIVEN   : a Rectangle(rect), the x(mx) and y(mx)
;;           coordinates of a MouseEvent.
;; RETURNS : true iff the given coordinate is inside
;;           the bounding box of the given Rectangle.
;; EXAMPLES: see tests below
;; STRATEGY: Use template for Rectangle on rect
(define (in-rect? rect x y) 
  (and
    (<= 
      (- (rect-x rect) HALF-RECTANGLE-WIDTH)
      x
      (+ (rect-x rect) HALF-RECTANGLE-WIDTH))
    (<= 
      (- (rect-y rect) HALF-RECTANGLE-HEIGHT)
      y
      (+ (rect-y rect) HALF-RECTANGLE-HEIGHT))))
;; TESTS
(begin-for-test
  (check-equal?
   (in-rect? RECT-X-ORIG-Y-ORIG 170 30)
   false
   "Should return #false since X Coordinate
    is way off the Image Coordinates")
  (check-equal?
   (in-rect? RECT-X-ORIG-Y-ORIG 10 50)
   true
   "Should return #true since both X and Y
    Coordinates are within Image Bounding Box"))

;; rects-after-key-event : ListOfRectangles KeyEvent -> ListOfRectangles
;; GIVEN   : a ListOfRectangles(LOR), a KeyEvent(kev).
;; RETURNS : true iff the given coordinate is inside
;;           the bounding box of the given Rectangle.
;; EXAMPLES: see tests below
;; STRATEGY: Use template for ListOfRectangles on LOR
(define (rects-after-key-event LOR kev)
  (cond
    [(empty? LOR) empty]
    [else
     (append           
      (list 
       (if
        (and (not (empty? (first LOR))) (rect-selected? (first LOR)))
        (rect-after-key-event (first LOR) kev)
        (first LOR)))
      (rects-after-key-event (rest LOR) kev))]))
;; TESTS
(begin-for-test
  (check-equal?
   (rects-after-key-event LIST-OF-RECTANGLES-1-SELECTED INCR-RECTANGLE-YVELOCITY-EVENT)
   (append
    (list
     (rect-after-key-event (first LIST-OF-RECTANGLES-1-SELECTED) "up"))
     (rest LIST-OF-RECTANGLES-1-SELECTED))
   "Should return a new list with updates rectangle in response
    to the KeyEvent up which should increment Y velocity of selected
    rectangle."))   

;; vx-incremented : Rectangle -> Rectangle
;; vx-decremented : Rectangle -> Rectangle
;; vy-incremented : Rectangle -> Rectangle
;; vy-decremented : Rectangle -> Rectangle
;; GIVEN   : a Rectangle(rect).
;; RETURNS : a Rectangle with its X or Y Velocity
;;           Incremented or Decremented by 2 pixels.
;;           the bounding box of the given Rectangle.
;; EXAMPLES: see tests below
;; STRATEGY: Use template for Rectangle on rect
(define (vx-incremented rect) 
  (make-rect
   (rect-x rect)
   (rect-y rect)
   (+ (rect-vx rect) INCR-BY-2)
   (rect-vy rect)
   (rect-selected? rect)
   (rect-dx rect)
   (rect-dy rect)))
(define (vx-decremented rect)
    (make-rect
   (rect-x rect)
   (rect-y rect)
   (- (rect-vx rect) INCR-BY-2)
   (rect-vy rect)
   (rect-selected? rect)
   (rect-dx rect)
   (rect-dy rect)))
(define (vy-incremented rect)
  (make-rect
   (rect-x rect)
   (rect-y rect)
   (rect-vx rect)
   (+ (rect-vy rect) INCR-BY-2)
   (rect-selected? rect)
   (rect-dx rect)
   (rect-dy rect)))
(define (vy-decremented rect)
  (make-rect
   (rect-x rect)
   (rect-y rect)
   (rect-vx rect)
   (- (rect-vy rect) INCR-BY-2)
   (rect-selected? rect)
   (rect-dx rect)
   (rect-dy rect)))
;; TESTS
(begin-for-test
  (check-equal?
   (vx-incremented NEW-RECT-XY-ORIG)
   (make-rect
    X-35 Y-45
    (+ VX-NEG-23 INCR-BY-2)
    VY-14
    false
    ZERO
    ZERO)
   "Should return a same rectangle with X velocity
    increased by 2 pixels/tick.")
  (check-equal?
   (vx-decremented NEW-RECT-XY-ORIG)
   (make-rect
    X-35 Y-45
    (- VX-NEG-23 INCR-BY-2)
    VY-14
    false
    ZERO
    ZERO)
   "Should return a same rectangle with X velocity
    decreased by 2 pixels/tick.")
  (check-equal?
   (vy-incremented NEW-RECT-XY-ORIG)
   (make-rect
    X-35 Y-45
    VX-NEG-23
    (+ VY-14 INCR-BY-2)    
    false
    ZERO
    ZERO)
   "Should return a same rectangle with Y velocity
    increased by 2 pixels/tick.")
  (check-equal?
   (vy-decremented NEW-RECT-XY-ORIG)
   (make-rect
    X-35 Y-45
    VX-NEG-23
    (- VY-14 INCR-BY-2)    
    false
    ZERO
    ZERO)
   "Should return a same rectangle with Y velocity
    decreased by 2 pixels/tick."))

;; add-rectangle-to-world : WorldState -> WorldState
;; GIVEN   : a world state(w)
;; RETURNS : a world state(w) like the given one with a new
;;           rectangle added to it at the center of the scene.
;; EXAMPLES: see tests below
;; STRATEGY: Use template for World on w
(define (add-rectangle-to-world w)
  (make-world
   (append
    (list (new-rectangle
           HALF-CANVAS-WIDTH
           HALF-CANVAS-HEIGHT
           ZERO ZERO))
    (world-rects w)) 
   (world-paused? w)))
;; TESTS
(begin-for-test
  (check-equal?
   (add-rectangle-to-world WORLD-INITIAL-RECT12-PLAYED)
   (make-world
    (append
     (list (new-rectangle
            HALF-CANVAS-WIDTH
            HALF-CANVAS-HEIGHT
            ZERO ZERO))
     (world-rects WORLD-INITIAL-RECT12-PLAYED)) 
    (world-paused? WORLD-INITIAL-RECT12-PLAYED))
   "Should return a new world with one new rectangle added to it."))
  
;; place-rects : ListOfRectangles -> Scene
;; GIVEN   : a ListOfRectangles(LOR)
;; RETURNS : a Scene with the GIVEN ListOfRectangles
;;           placed on an empty scene.
;; EXAMPLES: see tests below
;; STRATEGY: Use template for ListOfRectangles on LOR
(define (place-rects LOR) 
  (cond
    [(empty? LOR) EMPTY-CANVAS]
    [else
     (place-rect
      (first LOR)
      (place-rects (rest LOR)))]))
;; TESTS 
(begin-for-test
  (check-equal? (place-rects LIST-OF-RECTANGLES-1-SELECTED)
                 (place-dot-at XY-ORIG-SELECTED-VX-DY
                  (place-rect-scene NEW-RECT-XY-ORIG
                   (place-rect-scene NEW-RECT-XY-ORIG EMPTY-CANVAS)))
                "Should return a scene with all the rectangles inherent
                 in the given ListOfRectangles drawn on EMPTY-CANVAS."))
                 
;; place-rect : Rectangle Scene -> Scene
;; GIVEN   : a Rectangle(rect) and a Scene(scene)
;; RETURNS : A Scene with the GIVEN Rectangle or a CURSOR-DOT
;;           placed on Rectangle using mouse coordinates 
;;           inherent in Rectangle on the the given scene.
;; EXAMPLES: see tests below
;; STRATEGY: Divide into Cases on whether
;;           rect is empty or selected?
(define (place-rect rect scene)
  (cond
    [(empty? rect) EMPTY-CANVAS]
    [else
     (if
      (rect-selected? rect)
      (place-dot-at rect scene)
      (place-rect-scene rect scene))])) 
;; TESTS
(begin-for-test
  (check-equal?
   (place-rect
    NEW-RECT-XY-ORIG
    EMPTY-CANVAS)
   (place-rect-scene NEW-RECT-XY-ORIG EMPTY-CANVAS)
   "Should return an Image with a rectangle(60x50) blue in color
    placed at (34,45) on an empty scene of dimensions 400x300")
  (check-equal?
   (place-rect
    XY-ORIG-SELECTED-VX-DY
    EMPTY-CANVAS)
   (place-dot-at XY-ORIG-SELECTED-VX-DY EMPTY-CANVAS)
   "Should return an Image with a dot(radius 5) and 
    rectangle(60x50) both red in color placed at 
    (34,45) on an empty scene of dimensions 400x300")
  (check-equal?
   (place-rect
    empty
    EMPTY-CANVAS)
   EMPTY-CANVAS
   "Should return an Empty Canvas"))

;; place-rect-scene : Rectangle Scene -> Scene
;; GIVEN   : a Rectangle(rect) and a Scene(scene)
;; RETURNS : a scene like the given one, but with 
;;           the given Rectangle along with its velocity
;;           in form (vx,vy) painted on the scene.
;; EXAMPLES: see test below
;; STRATEGY: Use template for Rectangle on rect
(define (place-rect-scene rect scene)
  (place-image
       (rect-velocity-image
        (rect-vx rect) (rect-vy rect) 
        (rect-selected? rect))
       (rect-x rect) (rect-y rect) 
       scene))
;; TESTS
(begin-for-test
  (check-equal?
   (place-rect-scene
    NEW-RECT-XY-ORIG
    EMPTY-CANVAS)
   (place-image
       (rect-velocity-image VX-NEG-23 VY-14 false)
       X-35 Y-45
       EMPTY-CANVAS)
   "Should return an Image with a rectangle(60x50) blue in color
    placed at (34,45) on an empty scene of dimensions 400x300")
  (check-equal? 
   (place-rect-scene
     XY-ORIG-SELECTED-VX-DY
    EMPTY-CANVAS)
   (place-image
       (rect-velocity-image VX-NEG-23 VY-14 true)
       X-35 Y-45
       EMPTY-CANVAS)
   "Should return an Image with a rectangle(60x50) red in color 
    placed at (34,45) on an empty scene of dimensions 400x300"))

;; place-dot-at : Rectangle Scene -> Scene
;; GIVEN   : a Rectangle(rect) comprising offset(dx,dy)
;;           and coordinates(x,y) and a Scene(scene).
;; RETURNS : a Scene with a CURSOR-DOT placed on top Rectangle 
;;           at position clicked upon calculated using offset
;;           and coordinates which itself is placed on GIVEN scene.
;; EXAMPLES: see tests below          
;; STRATEGY: Use template for Rectangle on rect
(define (place-dot-at rect scene)
  (place-image
   CURSOR-DOT
   (- (rect-x rect) (rect-dx rect))
   (- (rect-y rect) (rect-dy rect))
   (place-rect-scene rect scene)))
;; TESTS
(begin-for-test
  (check-equal?
   (place-dot-at
    XY-ORIG-SELECTED-VX-DY
    EMPTY-CANVAS)
   (place-image
    CURSOR-DOT
    (- X-35 DX-4)
    (- Y-45 DY-9)
    (place-rect-scene XY-ORIG-SELECTED-VX-DY EMPTY-CANVAS)) 
   "Should return a new rectangle(60x50) and dot(radius 5),
    both red in color placed at (0,0) on an empty scene of  
    dimensions 400x300 with a rectangle placed at (34,45)"))

;; rect-velocity-image : Rectangle -> Image
;; GIVEN   : a Rectangle(rect) comprising velocity(vx,vy)
;; RETURNS : An Image with the velocity fields inherent in the
;;           GIVEN Rectangle are placed in the form (vx,vy)
;;           at the center of the GIVEN Rectangle.
;; EXAMPLES: see tests below 
;; STRATEGY: Combine Simpler Functions
(define (rect-velocity-image vx vy selected?)
  (overlay
   (velocity-image vx vy selected?)
   (rectangle-image (selected-color selected?))))
;; TESTS
(begin-for-test
  (check-equal?
   (rect-velocity-image
    X-36
    Y-48
    true)
   (overlay
    (velocity-image
     X-36
     Y-48
     true)
    (rectangle-image (selected-color true)))
   "Should return Image (36,48) placed right at the center of
    a rectangle of dimensions 60x50, both being red in color")
  (check-equal?
   (rect-velocity-image
    X-36
    Y-48
    false)
   (overlay
    (velocity-image
     X-36
     Y-48
     false)
    (rectangle-image (selected-color false)))
   "Should return Image (36,48) placed right at the center of
    a rectangle of dimensions 60x50, both being blue in color"))

;; velocity-image : Integer Integer -> Image
;; GIVEN   : X and Y Velocity
;; RETURNS : Image formed from the GIVEN Velocities
;;           in the form of (X Velocity, Y Velocity)
;; EXAMPLES: see tests below
;; STRATEGY: Combine Simpler Functions
(define (velocity-image vx vy selected?)
  (text (string-append "("
                       (number->string vx) ","
                       (number->string vy) ")")
        VELOCITY-FONT-SIZE
        (selected-color selected?)))
;; TESTS
(begin-for-test
  (check-equal?
   (velocity-image
    X-36
    Y-48
    true)
   (text (string-append "("
                       (number->string X-36) ","
                       (number->string Y-48) ")")
        VELOCITY-FONT-SIZE
        (selected-color true))
   "Should return Image version of (36,48) in red color")
   (check-equal?
   (velocity-image
    X-36
    Y-48
    false)
   (text (string-append "("
                       (number->string X-36) ","
                       (number->string Y-48) ")")
        VELOCITY-FONT-SIZE
        (selected-color false))
   "Should return Image version of (36,48) in blue color"))

;; selected-color : Boolean -> String
;; GIVEN   : A flag
;; RETURNS : Color based on flag value
;; INTERP  :
;;  flag   : True, selected color is NORMAL-COLOR
;;           False, selected color is SELECTED-COLOR
;; EXAMPLES:
;;           (selected-color true) => "red"
;;           (selected-color false) => "blue"
;; STRATEGY: Combine Simpler Functions
(define (selected-color flag)
  (if flag SELECTED-COLOR NORMAL-COLOR))
;; TESTS
(begin-for-test
  (check-equal? (selected-color true) SELECTED-COLOR
                "Should return 'red' when flag is true")
  (check-equal? (selected-color false) NORMAL-COLOR
                "Should return 'blue' when flag is true"))

;; rectangle-image : String -> Image
;; GIVEN   : A Color
;; RETURNS : Image of an Rectangle with the GIVEN Color 
;; WHERE   :
;;  Color  : NORMAL-COLOR, selected color is Blue
;;           SELECTED-COLOR, selected color is Red
;; EXAMPLES:
;; (rectangle-image "red") => (rectangle 60 50 "outline" "red")
;; (rectangle-image "blue") => (rectangle 60 50 "outline" "blue")
;; STRATEGY: Combine Simpler Functions
(define (rectangle-image color)
  (rectangle RECTANGLE-WIDTH RECTANGLE-HEIGHT MODE color)) 
;; TESTS
(begin-for-test
  (check-equal?
   (rectangle-image SELECTED-COLOR)
   (rectangle RECTANGLE-WIDTH RECTANGLE-HEIGHT MODE SELECTED-COLOR)
                "Image of a rectangle red in color")
  (check-equal?
   (rectangle-image NORMAL-COLOR)
   (rectangle RECTANGLE-WIDTH RECTANGLE-HEIGHT MODE NORMAL-COLOR)
                "Image of a rectangle blue in color"))

;; rects-after-tick : ListOfRectangles -> ListOfRectangles
;; GIVEN   : a ListOfRectangles(LOR)
;; RETURNS : a ListOfRectangles following the GIVEN 
;;           ListOfRectangles after tick.
;; EXAMPLES: see tests below
;; STRATEGY: Use template for ListOfRectangles on LOR
(define (rects-after-tick LOR)
  (cond
    [(empty? LOR) empty] 
    [else
     (append
      (list (rect-after-tick (first LOR)))
      (rects-after-tick (rest LOR)))])) 
;; TESTS
(begin-for-test
  (check-equal?
   (rects-after-tick LIST-OF-RECTANGLES-1-SELECTED)
   (append
    (list (rect-after-tick XY-ORIG-SELECTED-VX-DY))
    (list (rect-after-tick (new-rectangle X-35 Y-45 VX-NEG-23 VY-14)))
    (list (rect-after-tick (new-rectangle X-35 Y-45 VX-NEG-23 VY-14)))) 
   "Should return a new list with updates rectangle in response
    to the KeyEvent up which should increment Y velocity of selected
    rectangle.")) 

;; rect-after-tick : Rectangle -> Rectangle
;; GIVEN   : A Rectangle(rect) comprising X and Y Coordinates
;; RETURNS : A Rectangle like the given one but moved by
;;           the given velocity while velocity is inverted
;;           in corresponding direction if applicable.
;; EXAMPLES: see tests below
;; STRATEGY: Divide into Cases on rect's empty or selected?
(define (rect-after-tick rect)
  (cond
    [(empty? rect) rect]
    [else 
     (if (rect-selected? rect)
         rect
         (velocity-inverted rect))]))
;; TESTS
(define UNTOUCHED-LIMITS
  (make-rect (/ CANVAS-WIDTH 2) (/ CANVAS-WIDTH 2) INITIAL-RECT-2-VX INITIAL-RECT-2-VY false ZERO ZERO))
(define UNTOUCHED-LIMITS-MOVED
  (make-rect (+ (/ CANVAS-WIDTH 2) INITIAL-RECT-2-VX) (- (/ CANVAS-WIDTH 2) (- INITIAL-RECT-2-VY)) INITIAL-RECT-2-VX INITIAL-RECT-2-VY false ZERO ZERO))
(define TOUCHED-X-ORIGIN
  (make-rect ZERO (/ CANVAS-WIDTH 2) INITIAL-RECT-2-VX INITIAL-RECT-2-VY false ZERO ZERO))
(define TOUCHED-X-ORIGIN-INV
  (make-rect X-ORIGIN (- (/ CANVAS-WIDTH 2) (- INITIAL-RECT-2-VY)) VX-NEG-23 INITIAL-RECT-2-VY false  ZERO ZERO))
(define TOUCHED-Y-ORIGIN
  (make-rect (/ CANVAS-WIDTH 2) INITIAL-RECT-1-VY INITIAL-RECT-2-VX INITIAL-RECT-2-VY false  ZERO ZERO))
(define TOUCHED-Y-ORIGIN-INV
  (make-rect (+ (/ CANVAS-WIDTH 2) INITIAL-RECT-2-VX) Y-ORIGIN INITIAL-RECT-2-VX VY-14 false  ZERO ZERO)) 
(define TOUCHED-X-BOUNDARY
  (make-rect (- CANVAS-WIDTH HALF-RECTANGLE-WIDTH 1) (/ CANVAS-WIDTH 2) INITIAL-RECT-2-VX INITIAL-RECT-2-VY false  ZERO ZERO))
(define TOUCHED-X-BOUNDARY-INV
  (make-rect X-BOUNDARY (- (/ CANVAS-WIDTH 2) (- INITIAL-RECT-2-VY)) VX-NEG-23 INITIAL-RECT-2-VY false  ZERO ZERO))
(define TOUCHED-Y-BOUNDARY
  (make-rect (/ CANVAS-WIDTH 2) (* CANVAS-WIDTH 2) INITIAL-RECT-2-VX INITIAL-RECT-2-VY false  ZERO ZERO))
(define TOUCHED-Y-BOUNDARY-INV
  (make-rect (+ (/ CANVAS-WIDTH 2) INITIAL-RECT-2-VX) Y-BOUNDARY INITIAL-RECT-2-VX VY-14 false  ZERO ZERO))

(define RECT-X-ORIG-Y-ORIG
  (make-rect X-40 X-36 VX-NEG-23 INITIAL-RECT-2-VY false  ZERO ZERO))
(define RECT-X-ORIG-Y-ORIG-INV
  (make-rect X-ORIGIN Y-ORIGIN INITIAL-RECT-2-VX VY-14 false  ZERO ZERO))
(define RECT-X-ORIG-Y-ORIG-SELECTED
  (make-rect X-40 X-36 VX-NEG-23 INITIAL-RECT-2-VY true  ZERO ZERO))
(define RECT-X-ORIG-Y-ORIG-SELECTED-INV
  (make-rect X-40 X-36 VX-NEG-23 INITIAL-RECT-2-VY true ZERO ZERO))

(define RECT-X-ORIG-Y-BOUND
  (make-rect X-40 (- CANVAS-HEIGHT HALF-RECTANGLE-HEIGHT 1) VX-NEG-23 VY-14 false  ZERO ZERO))
(define RECT-X-ORIG-Y-BOUND-INV
  (make-rect X-ORIGIN Y-BOUNDARY INITIAL-RECT-2-VX INITIAL-RECT-2-VY false  ZERO ZERO))

(define RECT-X-BOUND-Y-ORIG
  (make-rect (- CANVAS-WIDTH HALF-RECTANGLE-WIDTH 1) X-36 X-40 INITIAL-RECT-2-VY false  ZERO ZERO))
(define RECT-X-BOUND-Y-ORIG-INV
  (make-rect X-BOUNDARY Y-ORIGIN (- X-40) VY-14 false  ZERO ZERO))

(define RECT-X-BOUND-Y-BOUND
  (make-rect (- CANVAS-WIDTH HALF-RECTANGLE-WIDTH 1) (- CANVAS-HEIGHT HALF-RECTANGLE-HEIGHT 1) X-40 VY-14 false  ZERO ZERO))
(define RECT-X-BOUND-Y-BOUND-INV
  (make-rect X-BOUNDARY Y-BOUNDARY (- X-40) INITIAL-RECT-2-VY false  ZERO ZERO))
(begin-for-test
  (check-equal?
   (rect-after-tick empty)
   empty
   "Should return the same Rectangle as given.")
  (check-equal?
   (rect-after-tick UNTOUCHED-LIMITS)
   UNTOUCHED-LIMITS-MOVED
   "Usual Rectangle movement inside the Limits.") 
  (check-equal?
   (rect-after-tick RECT-X-ORIG-Y-ORIG-SELECTED)
   RECT-X-ORIG-Y-ORIG-SELECTED-INV
   "Rectangle is about to touch on both X&Y Origin
    on next step, so both velocities Inverted."))

;; velocity-inverted : Rectangle -> Rectangle
;; GIVEN   : A Rectangle(rect) comprising X and Y Coordinates
;; RETURNS : A Rectangle like the given one but moved by
;;           the given velocity while velocity is inverted
;;           in corresponding direction if applicable.
;; EXAMPLES: see tests below
;; STRATEGY: Divide into Cases on rect's X and Y Coordinates
(define (velocity-inverted rect)
  (make-rect
   (if (touched-x-limits? rect) (x-origin-or-boundary rect)
       (+ (rect-x rect) (rect-vx rect)))
   (if (touched-y-limits? rect) (y-origin-or-boundary rect)
       (+ (rect-y rect) (rect-vy rect)))
   (if (touched-x-limits? rect) (- (rect-vx rect)) (rect-vx rect))
   (if (touched-y-limits? rect) (- (rect-vy rect)) (rect-vy rect))   
   (rect-selected? rect)
   (rect-dx rect)
   (rect-dy rect)))
;; TESTS
(begin-for-test
  (check-equal?
   (velocity-inverted UNTOUCHED-LIMITS)
   UNTOUCHED-LIMITS-MOVED
   "Usual Rectangle movement inside the Limits.") 
  (check-equal?
   (velocity-inverted RECT-X-ORIG-Y-ORIG)
   RECT-X-ORIG-Y-ORIG-INV
   "Rectangle is about to touch on both X&Y Origin
    on next step, so both velocities Inverted.")
  (check-equal?
   (velocity-inverted RECT-X-BOUND-Y-ORIG)
   RECT-X-BOUND-Y-ORIG-INV
   "Corner of X Boundary and Y Origin, so velocities
    should invert X should be 370 while Y should be 25.")  
  (check-equal?
   (velocity-inverted RECT-X-ORIG-Y-BOUND)
   RECT-X-ORIG-Y-BOUND-INV
   "Corner of X Origin and Y Boundary, so velocities
    should invert X should be 30 while Y should be 275.")
  (check-equal?
   (velocity-inverted RECT-X-BOUND-Y-BOUND)
   RECT-X-BOUND-Y-BOUND-INV
   "Corner of X&Y Boundary, so velocities should invert
    X should be 370 while Y should be 275.")
  (check-equal? 
   (velocity-inverted TOUCHED-X-ORIGIN)
   TOUCHED-X-ORIGIN-INV
   "Touched X Origin so inverse X velocity
    and put Rectangle on X Origin.")
  (check-equal? 
   (velocity-inverted TOUCHED-X-BOUNDARY)
   TOUCHED-X-BOUNDARY-INV
   "Touched X Boundary so inverse X velocity
    and put Rectangle on X Boundary.")
  (check-equal?
   (velocity-inverted TOUCHED-Y-ORIGIN)
   TOUCHED-Y-ORIGIN-INV
   "Touched Y Origin so inverse Y velocity
    and put Rectangle on Y Origin.")
  (check-equal?
   (velocity-inverted TOUCHED-Y-BOUNDARY)
   TOUCHED-Y-BOUNDARY-INV
   "Touched Y Boundary so inverse Y velocity
    and put Rectangle on Y Boundary."))
   

;; touched-x-limits? : Rectangle -> Boolean
;; touched-y-limits? : Rectangle -> Boolean
;; GIVEN   : A Rectangle with specific x and y position
;; RETURNS : A Boolean based on whether rectangle touches 
;;           Origin or Boundary of the corresponding axis
;; EXAMPLES:
;; (touched-x-limits? TOUCHED-X-ORIGIN) => #true
;; (touched-y-limits? UNTOUCHED-LIMITS) => #false
;; STRATEGY: Use template for Rectangle on rect
(define (touched-x-limits? rect) 
  (or
   (<= (+ (rect-x rect) (rect-vx rect)) X-ORIGIN)
   (>= (+ (rect-x rect) (rect-vx rect)) X-BOUNDARY))) 
(define (touched-y-limits? rect)
  (or 
   (<= (+ (rect-y rect) (rect-vy rect)) Y-ORIGIN)
   (>= (+ (rect-y rect) (rect-vy rect)) Y-BOUNDARY)))
;; TESTS
;; X-Origin: HALF-RECTANGLE-WIDTH
;; Y-Origin: HALF-RECTANGLE-HEIGHT
;; X-Boundary: (- CANVAS-WIDTH HALF-RECTANGLE-WIDTH)
;; Y-Boundary: (- CANVAS-HEIGHT HALF-RECTANGLE-HEIGHT)
(begin-for-test
  (check-equal?
   (touched-x-limits? TOUCHED-X-ORIGIN)
   true
   "Should return #true since Rectangle
    is touching X-Axis Origin")
  (check-equal?
   (touched-y-limits? TOUCHED-Y-ORIGIN)
   true
   "Should return #true since Rectangle
    is touching Y-Axis Origin")
  (check-equal?
   (touched-x-limits? TOUCHED-X-BOUNDARY)
   true
   "Should return #true since Rectangle
    is touching X-Axis Boundary")
  (check-equal?
   (touched-y-limits? TOUCHED-Y-BOUNDARY)
   true
   "Should return #true since Rectangle
    is touching Y-Axis Boundary")
  (check-equal?
   (touched-x-limits? UNTOUCHED-LIMITS)
   false
   "Should return #false since Rectangle
    is not touching X-Axis Origin")
  (check-equal?
   (touched-y-limits? UNTOUCHED-LIMITS)
   false
   "Should return #false since Rectangle
    is not touching X-Axis Origin"))

;; x-origin-or-boundary : Rectangle -> PosInt
;; y-origin-or-boundary : Rectangle -> PosInt
;; GIVEN   : a Rectangle(rect) comprising X&Y Coordinates
;; RETURNS : X/Y Orgin or Boundary Constant based on
;;           whether Rectangle touches Orgin or Boundary
;;           on its next step with its X&Y velocity.
;; EXAMPLES:
;; (x-origin-or-boundary TOUCHED-X-BOUNDARY) = X-BOUNDARY
;; (y-origin-or-boundary TOUCHED-Y-ORIGIN) = Y-ORIGIN
;; STRATEGY: Use tempplate of Rectangle on rect
(define (x-origin-or-boundary rect)
(if (<= (+ (rect-x rect) (rect-vx rect)) X-ORIGIN)
    X-ORIGIN
    X-BOUNDARY))
(define (y-origin-or-boundary rect)
(if (<= (+ (rect-y rect) (rect-vy rect)) Y-ORIGIN)
    Y-ORIGIN
    Y-BOUNDARY))
;; TESTS
(begin-for-test
  (check-equal?
   (x-origin-or-boundary TOUCHED-X-ORIGIN)
   X-ORIGIN
   "Should return X-ORIGIN since Rectangle
    is touching X-Axis Origin")
  (check-equal?
   (y-origin-or-boundary TOUCHED-Y-ORIGIN)
   Y-ORIGIN
   "Should return Y-ORIGIN since Rectangle
    is touching Y-Axis Origin")
  (check-equal?
   (x-origin-or-boundary TOUCHED-X-BOUNDARY)
   X-BOUNDARY
   "Should return X-BOUNDARY since Rectangle
    is touching X-Axis Boundary")
  (check-equal?
   (y-origin-or-boundary TOUCHED-Y-BOUNDARY)
   Y-BOUNDARY
   "Should return Y-BOUNDARY since Rectangle
    is touching Y-Axis Boundary"))
   
(screensaver 0.2)

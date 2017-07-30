;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-intermediate-lambda-reader.ss" "lang")((modname screensaver-5) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f () #t)))
;; screensaver-5.rkt : Second Question of Problem Set 05. 
;; DESCRIPTION: 
;   Screensaver is a universe program that displays zero or more
;   rectangles that bounce smoothly off the edge or move around.
;   New rectangles are initially centered at Origin.
;   The rectangle is selectable and draggable using mouse gestures.
;; GOAL: To start the screensaver in a PAUSED state.
;; INSTRUCTIONS:
;   start with (screensaver 0.5)
;   The space bar pauses or unpauses the entire simulation.
;   Add new rectangle by pressing "n" button on keyboard.
;   Change Velocity of rectangle by up/down/left/right arrow keys.
;   Pen Down/Up by selecting the rectangle via mouse and
;   pressing "d"/"u" key respectively on keyboard.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; LIBRARY
(require rackunit)
(require "extras.rkt")
(check-location "05" "screensaver-5.rkt") 
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
         new-rectangle
         rect-pen-down?)

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
(define PEN-DOT-RADIUS 1)
(define PEN-MODE "solid")
(define PEN-COLOR "black")
(define PEN-DOT (circle PEN-DOT-RADIUS PEN-MODE PEN-COLOR))

;; Dimensions of the Cursor
(define CURSOR-DOT-RADIUS 5)
(define CURSOR-DOT (circle CURSOR-DOT-RADIUS MODE SELECTED-COLOR))

;; KeyEvents
(define PAUSE-KEY-EVENT " ")
(define NON-PAUSE-KEY-EVENT "q")
(define ADD-NEW-RECTANGLE-EVENT "n")
(define INCR-RECTANGLE-YVELOCITY-EVENT "down")
(define DECR-RECTANGLE-YVELOCITY-EVENT "up")
(define DECR-RECTANGLE-XVELOCITY-EVENT "left")
(define INCR-RECTANGLE-XVELOCITY-EVENT "right")
(define PEN-DOWN-KEY-EVENT "d")
(define PEN-UP-KEY-EVENT "u")
(define OTHER-KEY-EVENT "\r")

;; MouseEvents
(define BUTTON-DOWN-EVENT "button-down")
(define DRAG-EVENT "drag")
(define BUTTON-UP-EVENT "button-up") 
(define OTHER-EVENT "enter")

;; Incremental Counter
(define INCR-BY-2 2)
(define DECR-BY-2 (- INCR-BY-2))

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
(define Y-59 59)
(define X-35 35)
(define Y-45 45)
(define X-36 36)
(define Y-48 48)
(define DX-4 4)
(define DY-9 9)
(define VX-NEG-23 (- INITIAL-RECT-2-VX)) 
(define VY-14 (- INITIAL-RECT-2-VY))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DATA DEFINITIONS 

;; A Point is a (make-posn x y)
;; EXAMPLES:
;; (make-posn ZERO ZERO) Point at Origin
;; (make-posn (- X-40 X-30) X-30) Point at (10,30)

;; A List of Points (ListOfPoints) is one of:
;; -- empty
;; -- (cons Point ListOfPoints)
;; TEMPLATE:
;; ListOfPoints-fn : ListOfPoints -> ??
#|
(define (ListOfPoints-fn lst)
 (cond
  [(empty? lst) ...]
  [else (... (first lst)
             (ListOfPoints-fn (rest lst)))]))
|#
;; EXAMPLES:
;; (list (make-posn ZERO ZERO) (make-posn (- X-40 X-30) X-30))
;; (list (make-posn ZERO ZERO) (make-posn (- X-40 X-30) X-30)
;;       (make-posn Y-59 ZERO) (make-posn ZERO HALF-CANVAS-HEIGHT))

(define-struct rect (x y vx vy selected? dx dy pen-down? points))
;; A Rectangle is a
;; (make-rect NonNegInt NonNegInt Int Int Boolean Int Int Boolean ListOfPoints)
;; INTERP:
;; x, y      gives the respective X&Y position of the center of rectangle.
;; vx, vy    gives the respective X&Y velocity of the rectangle.
;; selected? gives status of rectangle in true/false being selected by
;            mouse button press.
;; dx, dy    gives the respective X&Y offset of the selected position
;;           from the center of the rectangle.
;; pen-down? gives status of rectangle in true/false whether pen is down or up.
;; points    is a list of all the points marked by the rectangle.
;; TEMPLATE:
;; rectangle-fn : Rectangle -> ??
#|
(define (rect-fn r)
 (... (rect-x r) (rect-y r)
      (rect-vx r) (rect-vy r)
      (rect-selected? r)      
      (rect-dx r) (rect-dy r)
      (rect-pen-down? r)
      (rect-points r)))
|#
;; EXAMPLE:
;; (make-rect ZERO ZERO VX-NEG-23 VY-14 false 0 0 true
;;            (list (make-posn ZERO ZERO) (make-posn X-36 Y-48)))

;; A List of Rectangles (ListOfRectangles) is one of:
;; -- empty
;; -- (cons Rectangle ListOfRectangles)
;; TEMPLATE:
;; ListOfRectangles-fn : ListOfRectangles -> ??
#|
(define (ListOfRectangles-fn lst)
 (cond
  [(empty? lst) ...]
  [else (... (first lst)
             (ListOfRectangles-fn (rest lst)))]))
|#
;; EXAMPLE:
;; (list INITIAL-RECT-1
;;       INITIAL-RECT-2
;;       INITIAL-RECT-1-SELECTED
;;       INITIAL-RECT-2-SELECTED)

(define-struct world (rects paused?))
;; A World is a (make-world ListOfRectangle Boolean Image)
;; INTERP:
;; rects   is a list all the rectangles present in the screen saver. 
;; paused? describes whether or not the world is paused.

;; TEMPLATE:
;; world-fn : World -> ??
#|(define (world-fn w)
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
   ZERO ZERO
   false
   empty))

;  First Selected Rectangle used to Initialize the World
(define INITIAL-RECT-1-SELECTED
  (make-rect
   INITIAL-RECT-12-X
   INITIAL-RECT-1-Y
   INITIAL-RECT-1-VX
   INITIAL-RECT-1-VY
   true
   ZERO ZERO
   false
   empty))

;  Second Rectangle used to Initialize the World
(define INITIAL-RECT-2
  (make-rect
   INITIAL-RECT-12-X
   INITIAL-RECT-12-X
   INITIAL-RECT-2-VX
   INITIAL-RECT-2-VY
   false
   ZERO ZERO
   false
   empty))

;  Second Selected Rectangle used to Initialize the World
(define INITIAL-RECT-2-SELECTED
  (make-rect
   INITIAL-RECT-12-X
   INITIAL-RECT-12-X
   INITIAL-RECT-2-VX
   INITIAL-RECT-2-VY
   true
   ZERO ZERO
   false
   empty))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; FUNCTIONS

;; initial-world : Any -> WorldState
;; GIVEN   : any value (ignored)
;; RETURNS : the initial world specified in the problem set
;; EXAMPLES: see tests below
;; STRATEGY: Combine Simpler Functions
(define (initial-world any) 
  (make-world empty true)) 
;; TESTS
(begin-for-test
  (check-equal?
   (initial-world X-30)
   (make-world empty true)
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
    WORLD-INITIAL-RECT12-PLAYED PAUSE-KEY-EVENT)
   (world-with-paused-toggled WORLD-INITIAL-RECT12-PLAYED)
   "Should return a new world but paused.")
  (check-equal?
   (world-after-key-event
    WORLD-INITIAL-RECT12-PLAYED NON-PAUSE-KEY-EVENT)
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
  (if (rect-selected? rect)
      (cond
        [(key=? kev "up") (velocity-vary rect false DECR-BY-2)]
        [(key=? kev "down") (velocity-vary rect false INCR-BY-2)]
        [(key=? kev "left") (velocity-vary rect true DECR-BY-2)]
        [(key=? kev "right") (velocity-vary rect true INCR-BY-2)]
        [(key=? kev "d") (toggle-pen-down rect true)]
        [(key=? kev "u") (toggle-pen-down rect false)]
        [else rect])
      rect))  
;; TESTS  
(begin-for-test  
  (check-equal?
   (rect-after-key-event INITIAL-RECT-1-SELECTED INCR-RECTANGLE-YVELOCITY-EVENT)
   (velocity-vary INITIAL-RECT-1-SELECTED false INCR-BY-2)
   "Should return a same rectangle with Y velocity
    decreased by 2 pixels/tick.")
  (check-equal?
   (rect-after-key-event INITIAL-RECT-1-SELECTED INCR-RECTANGLE-XVELOCITY-EVENT)
   (velocity-vary INITIAL-RECT-1-SELECTED true INCR-BY-2)
   "Should return a same rectangle with X velocity
    increased by 2 pixels/tick.")
  (check-equal?
   (rect-after-key-event INITIAL-RECT-1-SELECTED DECR-RECTANGLE-YVELOCITY-EVENT)
   (velocity-vary INITIAL-RECT-1-SELECTED false DECR-BY-2)
   "Should return a same rectangle with Y velocity
    increased by 2 pixels/tick.")
  (check-equal?
   (rect-after-key-event INITIAL-RECT-1-SELECTED DECR-RECTANGLE-XVELOCITY-EVENT)
   (velocity-vary INITIAL-RECT-1-SELECTED true DECR-BY-2) 
   "Should return a same rectangle with Y velocity
    increased by 2 pixels/tick.")
  (check-equal?
   (rect-after-key-event INITIAL-RECT-1-SELECTED PEN-DOWN-KEY-EVENT)
   (toggle-pen-down INITIAL-RECT-1-SELECTED true)
   "Should return a same rectangle with pen-down? set to True.")
  (check-equal?
   (rect-after-key-event INITIAL-RECT-1-SELECTED PEN-UP-KEY-EVENT)
   (toggle-pen-down INITIAL-RECT-1-SELECTED false)
   "Should return a same rectangle with pen-down? set to False.")
  (check-equal?
   (rect-after-key-event INITIAL-RECT-1-SELECTED OTHER-KEY-EVENT)
   INITIAL-RECT-1-SELECTED
   "Should return a same rectangle")  
  (check-equal?
   (rect-after-key-event INITIAL-RECT-1 PEN-UP-KEY-EVENT)
   INITIAL-RECT-1
   "Should return a same rectangle")) 

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
  (make-rect x y vx vy
             false
             ZERO ZERO
             false
             empty))
;; TESTS
(define LIST-OF-RECTANGLES-AFTER-TICK
  (list (new-rectangle X-30 Y-59 INITIAL-RECT-2-VX VY-14)
        (new-rectangle X-30 Y-59 INITIAL-RECT-2-VX VY-14)
        (new-rectangle X-30 Y-59 INITIAL-RECT-2-VX VY-14)))
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
    false ZERO ZERO
    false
    empty)
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

;; toggle-pen-down : Rectangle Boolean -> Rectangle
;; GIVEN   : a Rectangle(rect) and a flag that stores whether
;;           pen is down for that rectangle.
;; RETURNS : a Rectangle like the one given with pen-down? toggled.
;; EXAMPLES: see tests below
;; STRATEGY: Use template for Rectangle on rect
(define (toggle-pen-down rect pen-down?)  
  (make-rect
   (rect-x rect)
   (rect-y rect)
   (rect-vx rect)
   (rect-vy rect)
   (rect-selected? rect)
   (rect-dx rect)
   (rect-dy rect)
   pen-down?
   (rect-points rect)))
;; TESTS
(begin-for-test
  (check-equal?
   (toggle-pen-down INITIAL-RECT-1 true)
   (make-rect
    (rect-x INITIAL-RECT-1)
    (rect-y INITIAL-RECT-1)
    (rect-vx INITIAL-RECT-1)
    (rect-vy INITIAL-RECT-1)
    (rect-selected? INITIAL-RECT-1)
    (rect-dx INITIAL-RECT-1)
    (rect-dy INITIAL-RECT-1)
    true
    (rect-points INITIAL-RECT-1))
   "Should return a new rectangle with same field value except
    pen-down? set to true"))

;; rects-after-mouse-event : ListOfRectangles Int Int MouseEvent -> ListOfRectangles
;; GIVEN   : a ListOfRectangles(LOR), the x(mx) and y(mx) coordinates
;;           of a MouseEvent, and the MouseEvent(mev).
;; RETURNS : a ListOfRectangles that should follow the given
;;           ListOfRectangles after the given MouseEvent.
;; EXAMPLE : see tests below
;; STRATEGY: Use HOF map on LOR
(define (rects-after-mouse-event LOR mx my mev)
  (map
   ;; Rectangle -> Rectangle
   ;; RETURNS a rectangle that should follow
   ;; given rectangle post mouse event
   (lambda (rect)
     (rect-after-mouse-event rect mx my mev))
   LOR))
;; TESTS
(define NEW-RECT-XY-ORIG
  (new-rectangle X-35 Y-45 VX-NEG-23 VY-14))
(define XY-ORIG-SELECTED-VX-DY
  (make-rect X-35 Y-45 VX-NEG-23 VY-14 true DX-4 DY-9 false
             empty))

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
;; GIVEN   : a Rectangle(rect), the x(mx) and y(my) 
;;           coordinates of a MouseEvent.
;; RETURNS : the Rectangle following a button-down at the
;;           given location x(mx) and y(my) coordinates).
;; EXAMPLE : see tests below 
;; STRATEGY: Divide into cases on mouse click (mx,my) is in-rect?
;;           or not, and then use template for Rectangle on rect.
(define (rect-after-button-down rect mx my)
  (if (in-rect? rect mx my)
      (make-rect
       (rect-x rect) (rect-y rect) (rect-vx rect) (rect-vy rect)
       true
       (- (rect-x rect) mx) (- (rect-y rect) my)
       (rect-pen-down? rect)
       (rect-points rect))
      rect))
;; TESTS
(define RECT-X-ORIG-Y-ORIG-BTNDWN
  (make-rect X-40 X-36 VX-NEG-23 INITIAL-RECT-2-VY true (- X-30) (- X-36 X-30) false empty))
(begin-for-test
  (check-equal?
   (rect-after-button-down
    RECT-X-ORIG-Y-ORIG (+ X-40 X-30) X-30)
   RECT-X-ORIG-Y-ORIG-BTNDWN
   "Should return a new rectangle with rect-selected?
    set to #true same x&y coordinates as original and
    updated mx(70), my(30), dx(40-70), and dy(36-30)")
  (check-equal?
   (rect-after-button-down RECT-X-ORIG-Y-ORIG ZERO ZERO)
   RECT-X-ORIG-Y-ORIG
   "Should return a same rectangle")
  (check-equal?
   (rect-after-button-down RECT-X-ORIG-Y-ORIG (- HALF-CANVAS-WIDTH X-30) (/ CANVAS-WIDTH 2))
   RECT-X-ORIG-Y-ORIG
   "Should return the same Rectangle since input mouse
    coordinates are out of Rectangle Bounding Box"))

;; rect-after-drag : Rectangle Integer Integer -> Rectangle
;; GIVEN   : a Rectangle(rect), the x(mx) and y(my) 
;;           coordinates of a MouseEvent.
;; RETURNS : the Rectangle following a drag at the at the
;;           given location(x(mx) and y(mx) coordinates).
;; EXAMPLE : see tests below
;; STRATEGY: Divide into cases on Rectangle is selected?
;;           or not, then use template for Rectangle on rect.
(define (rect-after-drag rect mx my) 
  (if (rect-selected? rect)
      (make-rect
       (+ mx (rect-dx rect)) (+ my (rect-dy rect))
       (rect-vx rect) (rect-vy rect)
       true
       (rect-dx rect) (rect-dy rect)
       (rect-pen-down? rect)
       (rect-points rect)) 
      rect))
;; TESTS
(define RECT-X-ORIG-Y-ORIG-BTNDRAG
  (make-rect X-40 X-36 VX-NEG-23 INITIAL-RECT-2-VY true ZERO ZERO false empty))
(define RECT-X-ORIG-Y-ORIG-BTNDRAGED
  (make-rect (- HALF-CANVAS-WIDTH X-30) X-ORIGIN VX-NEG-23 INITIAL-RECT-2-VY true ZERO ZERO false empty))
(begin-for-test
  (check-equal? 
   (rect-after-drag RECT-X-ORIG-Y-ORIG-BTNDRAG (- HALF-CANVAS-WIDTH X-30) X-ORIGIN)
   RECT-X-ORIG-Y-ORIG-BTNDRAGED
   "Should return a new rectangle
    with rect-selected? set to true")
  (check-equal?
   (rect-after-drag RECT-X-ORIG-Y-ORIG (- HALF-CANVAS-WIDTH X-30) X-ORIGIN)
   RECT-X-ORIG-Y-ORIG
   "Should return the same rectangle
    with rect-selected? set to false"))

;; rect-after-button-up : Rectangle -> Rectangle
;; GIVEN   : A Rectangle(rect)
;; RETURNS : the Rectangle following a button-up
;; EXAMPLE : see tests below
;; STRATEGY: Divide into cases on Rectangle is selected? or
;;           not, then use template for Rectangle on rect.
(define (rect-after-button-up rect) 
  (if (rect-selected? rect)
      (make-rect
       (rect-x rect) (rect-y rect)
       (rect-vx rect) (rect-vy rect)
       false
       ZERO ZERO
       (rect-pen-down? rect)
       (rect-points rect)) 
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
   (in-rect? RECT-X-ORIG-Y-ORIG (- HALF-CANVAS-WIDTH X-30) X-ORIGIN)
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
;; STRATEGY: Use HOF map on LOR
(define (rects-after-key-event LOR kev)
  (map
   ;; Rectangle -> Rectangle
   ;; RETURNS a rectangle that should follow
   ;; given rectangle post key event
   (lambda (rect)
     (rect-after-key-event rect kev))
   LOR))
;; TESTS
(begin-for-test
  (check-equal? 
   (rects-after-key-event LIST-OF-RECTANGLES-1-SELECTED DECR-RECTANGLE-YVELOCITY-EVENT)
   (cons
    (rect-after-key-event (first LIST-OF-RECTANGLES-1-SELECTED) "up")
    (rest LIST-OF-RECTANGLES-1-SELECTED))
   "Should return a new list with updates rectangle in response
    to the KeyEvent up which should increment Y velocity of selected
    rectangle."))

;; vx-vary : Rectangle Integer -> Rectangle
;; vy-vary : Rectangle Integer -> Rectangle
;; GIVEN   : a Rectangle(rect) and an Integer(delta).
;; RETURNS : a Rectangle with its X or Y Velocity
;;           Incremented or Decremented by delta pixels.
;; EXAMPLES: see tests below
;; STRATEGY: Call a more general function
#;(define (vx-vary rect delta)
  (velocity-vary rect true delta))  
#;(define (vy-vary rect delta)
  (velocity-vary rect false delta))
;; TESTS
#;(begin-for-test
  (check-equal?
   (vx-vary NEW-RECT-XY-ORIG INCR-BY-2)
   (make-rect
    X-35 Y-45
    (+ VX-NEG-23 INCR-BY-2)
    VY-14
    false
    ZERO
    ZERO
    false empty)
   "Should return a same rectangle with X velocity
    increased by 2 pixels/tick.")
  (check-equal?
   (vx-vary NEW-RECT-XY-ORIG (- INCR-BY-2))
   (make-rect
    X-35 Y-45
    (+ VX-NEG-23 (- INCR-BY-2))
    VY-14
    false
    ZERO
    ZERO
    false empty)
   "Should return a same rectangle with X velocity
    decreased by 2 pixels/tick.")
  (check-equal?
   (vy-vary NEW-RECT-XY-ORIG INCR-BY-2)
   (make-rect
    X-35 Y-45
    VX-NEG-23
    (+ VY-14 INCR-BY-2)    
    false
    ZERO
    ZERO
    false empty)
   "Should return a same rectangle with Y velocity
    increased by 2 pixels/tick.")
  (check-equal?
   (vy-vary NEW-RECT-XY-ORIG (- INCR-BY-2))
   (make-rect
    X-35 Y-45
    VX-NEG-23
    (+ VY-14 (- INCR-BY-2))    
    false
    ZERO
    ZERO
    false empty)
   "Should return a same rectangle with Y velocity
    decreased by 2 pixels/tick."))

;; velocity-vary : Rectangle Boolean Integer -> Rectangle
;; GIVEN: a Rectangle(rect), Boolean(x-or-y?) which tells either
;;        X or Y's velocity to be changed and an Integer(delta).
;; RETURNS : a Rectangle with its X or Y Velocity
;;           Incremented or Decremented by delta pixels.
;; EXAMPLES: see tests below
;; STRATEGY: Use template of Rectangle on rect
(define (velocity-vary rect x-or-y? delta) 
  (make-rect
   (rect-x rect)
   (rect-y rect)
   (if x-or-y?
       (+ (rect-vx rect) delta)
       (rect-vx rect))
   (if x-or-y?       
       (rect-vy rect)
       (+ (rect-vy rect) delta))
   (rect-selected? rect)
   (rect-dx rect)
   (rect-dy rect)
   (rect-pen-down? rect)
   (rect-points rect)))
;; TESTS
(begin-for-test
  (check-equal?
   (velocity-vary NEW-RECT-XY-ORIG true INCR-BY-2)
   (make-rect
    X-35 Y-45
    (+ VX-NEG-23 INCR-BY-2)
    VY-14
    false
    ZERO
    ZERO
    false empty)
   "Should return a same rectangle with X velocity
    increased by 2 pixels/tick."))

;; add-rectangle-to-world : WorldState -> WorldState
;; GIVEN   : a world state(w)
;; RETURNS : a world state(w) like the given one with a new
;;           rectangle added to it at the center of the scene.
;; EXAMPLES: see tests below
;; STRATEGY: Use template for World on w
(define (add-rectangle-to-world w)
  (make-world
   (cons
    (new-rectangle HALF-CANVAS-WIDTH
                   HALF-CANVAS-HEIGHT
                   ZERO ZERO)
    (world-rects w))  
   (world-paused? w)))  
;; TESTS
(begin-for-test
  (check-equal?
   (add-rectangle-to-world WORLD-INITIAL-RECT12-PLAYED)
   (make-world
    (cons (new-rectangle
           HALF-CANVAS-WIDTH
           HALF-CANVAS-HEIGHT
           ZERO ZERO)
          (world-rects WORLD-INITIAL-RECT12-PLAYED)) 
    (world-paused? WORLD-INITIAL-RECT12-PLAYED))
   "Should return a new world with one new rectangle added to it."))

;; place-rects : ListOfRectangles -> Scene
;; GIVEN   : a ListOfRectangles(LOR)
;; RETURNS : a Scene with the GIVEN ListOfRectangles
;;           placed on an empty scene.
;; EXAMPLES: see tests below
;; STRATEGY: Use HOF foldr on LOR
(define (place-rects LOR) 
  (foldr place-rect EMPTY-CANVAS LOR))
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
  (if (rect-selected? rect)
      (place-dot-at rect scene)
      (place-rect-scene rect scene)))             
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
    (34,45) on an empty scene of dimensions 400x300"))

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
   (place-points
    (rect-points rect)
    scene)))  
;; TESTS
(define RECT-35-45-NEG23-14-PENDOWN
  (make-rect X-35 Y-45 VX-NEG-23 VY-14
             false ZERO ZERO true
             empty))
(begin-for-test
  (check-equal?
   (place-rect-scene RECT-35-45-NEG23-14-PENDOWN EMPTY-CANVAS)
   (place-image
    (rect-velocity-image VX-NEG-23 VY-14 false)
    X-35 Y-45
    (place-points empty EMPTY-CANVAS))
   "Should return a scene where a new point with coordinates of
    rectangle's center is marked on an EMPTY-CANVAS")
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

;; rect-velocity-image : Rectangle Integer Integer Boolean -> Image
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

;; place-points : ListOfPoints Scene -> Scene
;; GIVEN   : a ListOfPoints(LOP) and a Scene(scene)
;; RETURNS : a Scene with the GIVEN ListOfPoints
;;           placed on an given scene.
;; EXAMPLES: see tests below
;; STRATEGY: Use HOF foldr on LOP
(define (place-points LOP scene)
  (foldr place-point scene LOP))
;; TESTS
(define POINT-35-45
  (make-posn X-35 Y-45))
(define POINT-36-48
  (make-posn X-36 Y-48))
(define POINT-30-59
  (make-posn X-30 Y-59))
(define LIST-OF-POINTS
  (list POINT-35-45
        POINT-36-48
        POINT-30-59))
(begin-for-test
  (check-equal?
   (place-points LIST-OF-POINTS EMPTY-CANVAS)
   (place-point
    POINT-35-45
    (place-point
     POINT-36-48
     (place-point
      POINT-30-59 EMPTY-CANVAS)))
   "Should return a scene where a new points marked from the input
    ListOfPoints on an EMPTY-CANVAS with a PEN-DOT marked at X&Y
    Coordinates inherent in the point data type.")
  (check-equal?
   (place-points empty EMPTY-CANVAS)
   EMPTY-CANVAS
   "Should return an EMPTY-CANVAS since input ListOfPoints is empty."))

;; place-point : Point Scene -> Scene
;; GIVEN   : a Point(point) and a Scene(scene)
;; RETURNS : A Scene with the GIVEN Point or a CURSOR-DOT
;;           placed on Rectangle using mouse coordinates 
;;           inherent in Rectangle on the the given scene.
;; EXAMPLES: see tests below
;; STRATEGY: Combine Simpler Functions
(define (place-point point scene)
  (place-image
   PEN-DOT 
   (posn-x point) (posn-y point)                
   scene))  
;; TESTS
(begin-for-test
  (check-equal?
   (place-point POINT-35-45 EMPTY-CANVAS)
   (place-image
    PEN-DOT
    X-35 Y-45
    EMPTY-CANVAS)
   "Should return a scene where a new point marked on an EMPTY-CANVAS
    with a PEN-DOT at (35,45) inherent in the point data type."))

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
;; STRATEGY: Use HOF map on LOR
(define (rects-after-tick LOR)
  (map rect-after-tick LOR))
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
         (rect-moved rect))])) 
;; TESTS
(define UNTOUCHED-LIMITS
  (make-rect (/ CANVAS-WIDTH 2) (/ CANVAS-WIDTH 2) INITIAL-RECT-2-VX INITIAL-RECT-2-VY false ZERO ZERO false empty))
(define UNTOUCHED-LIMITS-MOVED
  (make-rect (+ (/ CANVAS-WIDTH 2) INITIAL-RECT-2-VX) (- (/ CANVAS-WIDTH 2) (- INITIAL-RECT-2-VY)) INITIAL-RECT-2-VX INITIAL-RECT-2-VY false ZERO ZERO false empty))
(define TOUCHED-X-ORIGIN
  (make-rect ZERO (/ CANVAS-WIDTH 2) INITIAL-RECT-2-VX INITIAL-RECT-2-VY false ZERO ZERO false empty))
(define TOUCHED-X-ORIGIN-INV
  (make-rect X-ORIGIN (- (/ CANVAS-WIDTH 2) (- INITIAL-RECT-2-VY)) VX-NEG-23 INITIAL-RECT-2-VY false  ZERO ZERO false empty))
(define TOUCHED-Y-ORIGIN
  (make-rect (/ CANVAS-WIDTH 2) INITIAL-RECT-1-VY INITIAL-RECT-2-VX INITIAL-RECT-2-VY false  ZERO ZERO false empty))
(define TOUCHED-Y-ORIGIN-INV
  (make-rect (+ (/ CANVAS-WIDTH 2) INITIAL-RECT-2-VX) Y-ORIGIN INITIAL-RECT-2-VX VY-14 false  ZERO ZERO false empty)) 
(define TOUCHED-X-BOUNDARY
  (make-rect (- CANVAS-WIDTH HALF-RECTANGLE-WIDTH 1) (/ CANVAS-WIDTH 2) INITIAL-RECT-2-VX INITIAL-RECT-2-VY false  ZERO ZERO false empty))
(define TOUCHED-X-BOUNDARY-INV
  (make-rect X-BOUNDARY (- (/ CANVAS-WIDTH 2) (- INITIAL-RECT-2-VY)) VX-NEG-23 INITIAL-RECT-2-VY false  ZERO ZERO false empty))
(define TOUCHED-Y-BOUNDARY
  (make-rect (/ CANVAS-WIDTH 2) (* CANVAS-WIDTH 2) INITIAL-RECT-2-VX INITIAL-RECT-2-VY false  ZERO ZERO false empty))
(define TOUCHED-Y-BOUNDARY-INV
  (make-rect (+ (/ CANVAS-WIDTH 2) INITIAL-RECT-2-VX) Y-BOUNDARY INITIAL-RECT-2-VX VY-14 false  ZERO ZERO false empty))

(define RECT-X-ORIG-Y-ORIG
  (make-rect X-40 X-36 VX-NEG-23 INITIAL-RECT-2-VY false  ZERO ZERO false empty))
(define RECT-X-ORIG-Y-ORIG-INV
  (make-rect X-ORIGIN Y-ORIGIN INITIAL-RECT-2-VX VY-14 false  ZERO ZERO false empty))
(define RECT-X-ORIG-Y-ORIG-SELECTED
  (make-rect X-40 X-36 VX-NEG-23 INITIAL-RECT-2-VY true  ZERO ZERO false empty))
(define RECT-X-ORIG-Y-ORIG-SELECTED-INV
  (make-rect X-40 X-36 VX-NEG-23 INITIAL-RECT-2-VY true ZERO ZERO false empty))

(define RECT-X-ORIG-Y-BOUND
  (make-rect X-40 (- CANVAS-HEIGHT HALF-RECTANGLE-HEIGHT 1) VX-NEG-23 VY-14 false  ZERO ZERO false empty))
(define RECT-X-ORIG-Y-BOUND-INV
  (make-rect X-ORIGIN Y-BOUNDARY INITIAL-RECT-2-VX INITIAL-RECT-2-VY false  ZERO ZERO false empty))

(define RECT-X-BOUND-Y-ORIG
  (make-rect (- CANVAS-WIDTH HALF-RECTANGLE-WIDTH 1) X-36 X-40 INITIAL-RECT-2-VY false  ZERO ZERO false empty))
(define RECT-X-BOUND-Y-ORIG-INV
  (make-rect X-BOUNDARY Y-ORIGIN (- X-40) VY-14 false  ZERO ZERO false empty))

(define RECT-X-BOUND-Y-BOUND
  (make-rect (- CANVAS-WIDTH HALF-RECTANGLE-WIDTH 1) (- CANVAS-HEIGHT HALF-RECTANGLE-HEIGHT 1) X-40 VY-14 false  ZERO ZERO false empty))
(define RECT-X-BOUND-Y-BOUND-INV
  (make-rect X-BOUNDARY Y-BOUNDARY (- X-40) INITIAL-RECT-2-VY false  ZERO ZERO false empty))
; List of three Rectangles
(define LIST-OF-RECTANGLES
  (list (new-rectangle X-35 Y-45 VX-NEG-23 VY-14)
        (new-rectangle X-35 Y-45 VX-NEG-23 VY-14)
        (new-rectangle X-35 Y-45 VX-NEG-23 VY-14)))

; List of three Rectangles with one of them selected
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

;; rect-moved : Rectangle -> Rectangle
;; GIVEN   : A Rectangle(rect) comprising X and Y Coordinates
;; RETURNS : A Rectangle like the given one but moved by
;;           the given velocity while velocity is inverted
;;           in corresponding direction if applicable.
;; EXAMPLES: see tests below 
;; STRATEGY: Use template of Rectangle on rect
(define (rect-moved rect)
  (make-rect
   (rect-x-moved rect)
   (rect-y-moved rect)
   (rect-vx-varied rect)
   (rect-vy-varied rect)
   (rect-selected? rect)
   (rect-dx rect)
   (rect-dy rect)
   (rect-pen-down? rect)
   (rect-after-pen-down rect)))
;; TESTS
(define UNTOUCHED-LIMITS-PEN-DOWN
  (make-rect
   (rect-x UNTOUCHED-LIMITS)
   (rect-y UNTOUCHED-LIMITS)
   (rect-vx UNTOUCHED-LIMITS)
   (rect-vy UNTOUCHED-LIMITS)
   (rect-selected? UNTOUCHED-LIMITS)
   (rect-dx UNTOUCHED-LIMITS)
   (rect-dy UNTOUCHED-LIMITS)
   true
   empty))
(define UNTOUCHED-LIMITS-MOVED-PEN-DOWN
  (make-rect
   (rect-x UNTOUCHED-LIMITS-MOVED)
   (rect-y UNTOUCHED-LIMITS-MOVED)
   (rect-vx UNTOUCHED-LIMITS-MOVED)
   (rect-vy UNTOUCHED-LIMITS-MOVED)
   (rect-selected? UNTOUCHED-LIMITS-MOVED)
   (rect-dx UNTOUCHED-LIMITS-MOVED)
   (rect-dy UNTOUCHED-LIMITS-MOVED)
   true
   (cons (make-posn
          (rect-x UNTOUCHED-LIMITS)
          (rect-y UNTOUCHED-LIMITS))
         (rect-points UNTOUCHED-LIMITS-MOVED))))  
(begin-for-test
  (check-equal?
   (rect-moved UNTOUCHED-LIMITS-PEN-DOWN)
   UNTOUCHED-LIMITS-MOVED-PEN-DOWN
   "Usual Rectangle movement inside the Limits.")
  (check-equal?
   (rect-moved UNTOUCHED-LIMITS)
   UNTOUCHED-LIMITS-MOVED
   "Usual Rectangle movement inside the Limits.") 
  (check-equal?
   (rect-moved RECT-X-ORIG-Y-ORIG)
   RECT-X-ORIG-Y-ORIG-INV
   "Rectangle is about to touch on both X&Y Origin
    on next step, so both velocities Inverted.")
  (check-equal?
   (rect-moved RECT-X-BOUND-Y-ORIG)
   RECT-X-BOUND-Y-ORIG-INV
   "Corner of X Boundary and Y Origin, so velocities
    should invert X should be 370 while Y should be 25.")  
  (check-equal?
   (rect-moved RECT-X-ORIG-Y-BOUND)
   RECT-X-ORIG-Y-BOUND-INV
   "Corner of X Origin and Y Boundary, so velocities
    should invert X should be 30 while Y should be 275.")
  (check-equal?
   (rect-moved RECT-X-BOUND-Y-BOUND)
   RECT-X-BOUND-Y-BOUND-INV
   "Corner of X&Y Boundary, so velocities should invert
    X should be 370 while Y should be 275.")
  (check-equal? 
   (rect-moved TOUCHED-X-ORIGIN)
   TOUCHED-X-ORIGIN-INV
   "Touched X Origin so inverse X velocity
    and put Rectangle on X Origin.")
  (check-equal? 
   (rect-moved TOUCHED-X-BOUNDARY)
   TOUCHED-X-BOUNDARY-INV
   "Touched X Boundary so inverse X velocity
    and put Rectangle on X Boundary.")
  (check-equal?
   (rect-moved TOUCHED-Y-ORIGIN)
   TOUCHED-Y-ORIGIN-INV
   "Touched Y Origin so inverse Y velocity
    and put Rectangle on Y Origin.")
  (check-equal?
   (rect-moved TOUCHED-Y-BOUNDARY)
   TOUCHED-Y-BOUNDARY-INV
   "Touched Y Boundary so inverse Y velocity
    and put Rectangle on Y Boundary."))

;; rect-x-moved : Rectangle -> Integer
;; rect-y-moved : Rectangle -> Integer
;; rect-vx-varied : Rectangle -> Integer
;; rect-vy-varied : Rectangle -> Integer
;; GIVEN   : A Rectangle with specific x,y position and velocity
;; RETURNS : A Rectangle that should follow the given rectangle
;;           after the next tick.
;; EXAMPLES: see tests below
;; STRATEGY: Use template for Rectangle on rect's
;;           X&Y Coordinates and Velocties.
(define (rect-x-moved rect) 
  (cond
    [(<= (+ (rect-x rect) (rect-vx rect)) X-ORIGIN) X-ORIGIN]
    [(>= (+ (rect-x rect) (rect-vx rect)) X-BOUNDARY) X-BOUNDARY]
    [else (+ (rect-x rect) (rect-vx rect))]))
(define (rect-y-moved rect)
  (cond 
    [(<= (+ (rect-y rect) (rect-vy rect)) Y-ORIGIN) Y-ORIGIN]
    [(>= (+ (rect-y rect) (rect-vy rect)) Y-BOUNDARY) Y-BOUNDARY]
    [else (+ (rect-y rect) (rect-vy rect))]))
(define (rect-vx-varied rect) 
  (if
   (or
    (<= (+ (rect-x rect) (rect-vx rect)) X-ORIGIN)
    (>= (+ (rect-x rect) (rect-vx rect)) X-BOUNDARY))
   (- (rect-vx rect))
   (rect-vx rect)))
(define (rect-vy-varied rect)
  (if
   (or 
    (<= (+ (rect-y rect) (rect-vy rect)) Y-ORIGIN)
    (>= (+ (rect-y rect) (rect-vy rect)) Y-BOUNDARY))
   (- (rect-vy rect))
   (rect-vy rect)))
;; TESTS
;; X-Origin: HALF-RECTANGLE-WIDTH
;; Y-Origin: HALF-RECTANGLE-HEIGHT
;; X-Boundary: (- CANVAS-WIDTH HALF-RECTANGLE-WIDTH)
;  Y-Boundary: (- CANVAS-HEIGHT HALF-RECTANGLE-HEIGHT)
(begin-for-test
  (check-equal?
   (rect-x-moved TOUCHED-X-ORIGIN)
   X-ORIGIN
   "Should return #true since Rectangle
    is touching X-Axis Origin")
  (check-equal?
   (rect-y-moved TOUCHED-Y-ORIGIN)
   Y-ORIGIN
   "Should return #true since Rectangle
    is touching Y-Axis Origin")
  (check-equal?
   (rect-x-moved TOUCHED-X-BOUNDARY)
   X-BOUNDARY
   "Should return #true since Rectangle
    is touching X-Axis Boundary")
  (check-equal?
   (rect-y-moved TOUCHED-Y-BOUNDARY)
   Y-BOUNDARY
   "Should return #true since Rectangle
    is touching Y-Axis Boundary")
  (check-equal?
   (rect-x-moved UNTOUCHED-LIMITS)
   (+ HALF-CANVAS-WIDTH INITIAL-RECT-2-VX)
   "Should return #false since Rectangle
    is not touching X-Axis Origin") 
  (check-equal?
   (rect-y-moved UNTOUCHED-LIMITS)
   (- HALF-CANVAS-WIDTH VY-14)
   "Should return #false since Rectangle
    is not touching X-Axis Origin")) 
 
;; rect-after-pen-down : Rectangle -> ListOfPoints
;; GIVEN   : A Rectangle with x,y position and ListOfPoints
;; RETURNS : A Rectangle that should contain new points placed
;;           at Rectangle's X&Y Coordinates based on whether
;;           or not pen-down?.
;; EXAMPLES: see tests below
;; STRATEGY: Use template for Rectangle on rect's
;;           pen-down?, X&Y Coordinates and ListOfPoints.
(define (rect-after-pen-down rect)
  (if (rect-pen-down? rect)
      (cons (make-posn (rect-x rect) (rect-y rect))
            (rect-points rect))
      (rect-points rect)))
;; TESTS
(begin-for-test
  (check-equal?
   (rect-after-pen-down INITIAL-RECT-1)
   empty
   "Rectangle is not pen down, so return original points")
  (check-equal?
   (rect-after-pen-down UNTOUCHED-LIMITS-PEN-DOWN)
   (cons
    (make-posn
     (rect-x UNTOUCHED-LIMITS-PEN-DOWN)
     (rect-y UNTOUCHED-LIMITS-PEN-DOWN))
    (rect-points UNTOUCHED-LIMITS-PEN-DOWN))
   "Since pen-down? is true, a new point with the coordintes
    of UNTOUCHED-LIMITS-PEN-DOWN is added and a ListOfPoints
    is returned."))

;(screensaver 0.2)
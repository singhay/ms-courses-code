;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-beginner-reader.ss" "lang")((modname screensaver-2) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f () #f)))
;; screensaver-2.rkt : Second and Last Question of Problem Set 03. 
;; Description:
;   The screensaver is a universe program that displays two
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
;; start with (screensaver 10)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require rackunit)
(require "extras.rkt")
(check-location "03" "editor.rkt")
(require 2htdp/image)
(require 2htdp/universe)
(provide screensaver
         initial-world
         world-after-tick
         world-after-key-event
         world-rect1
         world-rect2
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
;;; MAIN FUNCTION.

;; screensaver : PosReal -> WorldState
;; GIVEN: the speed of the simulation, in seconds/tick
;; EFFECT: runs the simulation, starting with the initial state as
;; specified in the problem set.
;; RETURNS: the final state of the world
;; STRATEGY: Combine Simpler Functions
(define (screensaver initial-pos)
  (big-bang (initial-world initial-pos)
            (on-draw world-to-scene)            
            (on-tick world-after-tick initial-pos)
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
(define RECTANGLE-IMAGE
  (rectangle
   RECTANGLE-WIDTH
   RECTANGLE-HEIGHT
   MODE
   NORMAL-COLOR))

;; dimensions of the canvas
(define CANVAS-WIDTH 400)
(define CANVAS-HEIGHT 300)
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

;; KeyEvents
(define pause-key-event " ")
(define non-pause-key-event "q")   


;; MouseEvents
(define button-down-event "button-down")
(define drag-event "drag")
(define button-up-event "button-up")
(define other-event "enter")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DATA DEFINITIONS 

(define-struct rect (x y vx vy selected? mx my dx dy))
;; A Rectangle is a (make-rectangle NonNegInt NonNegInt Int Int)
;; Interpretation:
;; x, y give the respective X&Y position of the rectangle.
;; vx, vy gives the respective X&Y velocity of the rectangle.
;; mx, my gives the respective X&Y position of cursor on the scene.
;; dx, dy gives the respective X&Y offset of the selected position
;;        from the center of the rectangle.

;; TEMPLATE:
;; rectangle-fn : Rectangle -> ??
#|
(define (rect-fn r)
 (... (rect-x r) (rect-y r)
      (rect-vx r) (rect-vy r)
      (rect-selected? r)
      (rect-mx r) (rect-my r)
      (rect-dx r) (rect-dy r)))
|#

(define-struct world (rect1 rect2 paused?))
;; A World is a (make-world Rectangle Rectangle Boolean)
;; Interpretation:
;; rect1 is rectangle no. 1 to be used in the screen saver. 
;; rect2 is rectangle no. 1 to be used in the screen saver. 
;; paused? describes whether or not the rect is paused.

;; TEMPLATE:
;; world-fn : World -> ??
#|(define (world-fn w)
   (... (world-rect1 w)
        (world-rect2 w)
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
   ZERO ZERO ZERO ZERO))

;  First Selected Rectangle used to Initialize the World
(define INITIAL-RECT-1-SELECTED
  (make-rect
   INITIAL-RECT-12-X
   INITIAL-RECT-1-Y
   INITIAL-RECT-1-VX
   INITIAL-RECT-1-VY
   true
   ZERO ZERO ZERO ZERO))

;  Second Rectangle used to Initialize the World
(define INITIAL-RECT-2
  (make-rect
   INITIAL-RECT-12-X
   INITIAL-RECT-12-X
   INITIAL-RECT-2-VX
   INITIAL-RECT-2-VY
   false
   ZERO ZERO ZERO ZERO))

;  Second Selected Rectangle used to Initialize the World
(define INITIAL-RECT-2-SELECTED
  (make-rect
   INITIAL-RECT-12-X
   INITIAL-RECT-12-X
   INITIAL-RECT-2-VX
   INITIAL-RECT-2-VY
   true
   ZERO ZERO ZERO ZERO))

;; EXAMPLES of World for TESTS
;  Paused World
(define WORLD-INITIAL-RECT12-PAUSED
  (make-world
   INITIAL-RECT-1
   INITIAL-RECT-2
   true))

;  Played World
(define WORLD-INITIAL-RECT12-PLAYED
  (make-world
   INITIAL-RECT-1
   INITIAL-RECT-2
   false))

;  Played World with First Rectangle Selected
(define WORLD-INITIAL-RECT1SEL2-PLAYED
  (make-world
   INITIAL-RECT-1-SELECTED
   INITIAL-RECT-2
   false))

;  Played World with Second Rectangle Selected
(define WORLD-INITIAL-RECT12SEL-PLAYED
  (make-world
   INITIAL-RECT-1
   INITIAL-RECT-2-SELECTED
   false))

;  Played World with First and Second Rectangles Selected
(define WORLD-INITIAL-RECT1SEL2SEL-PLAYED
  (make-world
   INITIAL-RECT-1-SELECTED
   INITIAL-RECT-2-SELECTED
   false))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; initial-world : Any -> WorldState
;; GIVEN: any value (ignored)
;; RETURNS: the initial world specified in the problem set
;; EXAMPLES: see tests below
;; STRATEGY: Combine Simpler Functions
(define(initial-world any) 
  (make-world INITIAL-RECT-1 INITIAL-RECT-2 true))
(begin-for-test
  (check-equal?
   (initial-world ZERO)
   (make-world INITIAL-RECT-1 INITIAL-RECT-2 true)
   "Should return an initialized World with two rectangles
    having coordinates and velocity as mentioned in question."))

;; world-to-scene : World -> Scene
;; RETURNS: a Scene that portrays the given world.
;; EXAMPLES: see tests below
;; STRATEGY: Use template for World on w
(define (world-to-scene w)
  (place-rect
    (world-rect1 w)
    (place-rect
      (world-rect2 w)
      EMPTY-CANVAS)))
;; TESTS
(begin-for-test
  (check-equal?
   (world-to-scene
    WORLD-INITIAL-RECT12-PLAYED)
   (place-rect
    INITIAL-RECT-1
    (place-rect
     INITIAL-RECT-2
     EMPTY-CANVAS))
   "Should return two blue rectangles(60x50) with respective
    velocties placed in their centers on an empty scene(400x300).")
  (check-equal?
   (world-to-scene
    WORLD-INITIAL-RECT1SEL2-PLAYED)
   (place-rect
    INITIAL-RECT-1-SELECTED
    (place-rect
     INITIAL-RECT-2
     EMPTY-CANVAS))
   "Should return first rectangle(60x50) blue and second red with  
    velocties placed in their centers on an empty scene(400x300).")
  (check-equal?
   (world-to-scene
    WORLD-INITIAL-RECT12SEL-PLAYED)
   (place-rect
    INITIAL-RECT-1
    (place-rect
     INITIAL-RECT-2-SELECTED
     EMPTY-CANVAS))
   "Should return first rectangle(60x50) red and second blue with  
    velocties placed in their centers on an empty scene(400x300).")
  (check-equal?
   (world-to-scene
    WORLD-INITIAL-RECT1SEL2SEL-PLAYED)
   (place-rect
    INITIAL-RECT-1-SELECTED
    (place-rect
     INITIAL-RECT-2-SELECTED
     EMPTY-CANVAS))
   "Should return two red rectangles(60x50) with respective
    velocties placed in their centers on an empty scene(400x300)."))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; world-after-tick : WorldState -> WorldState
;; RETURNS: the world state that should follow the given world state
;;          after a tick.
;; EXAMPLES: see tests below
;; STRATEGY: Use Template for World on w, and
;;           then cases on if the world is paused.
(define (world-after-tick w)
  (if (world-paused? w)
    w
    (make-world
     (rect-limit-check (world-rect1 w))
     (rect-limit-check (world-rect2 w))
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
    (rect-limit-check INITIAL-RECT-1)
    (rect-limit-check INITIAL-RECT-2)
    false)
   "Should return World State comprising of updated Rectangles."))

;; world-after-key-event : WorldState KeyEvent -> WorldState
;; GIVEN: a world w
;; RETURNS: the world that should follow the given world
;;          after the given key event.
;;          on space, toggle paused?-- ignore all others
;; EXAMPLES: see tests below
;; STRATEGY: cases on KeyEvent kev 
(define (world-after-key-event w kev)
  (cond
    [(key=? kev " ") (world-with-paused-toggled w)]
    [else w]))
;; TESTS
(begin-for-test
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

;; world-after-mouse-event :WorldState Int Int MouseEvent->WorldState
;; GIVEN: A World, the x- and y-coordinates of a mouse event,
;;        and the mouse event.
;; RETURNS: the world that should follow the given world
;;          after the given mouse event.
;; EXAMPLES: see tests below
;; DESIGN STRATEGY: Use Template of World on w
(define (world-after-mouse-event w mx my mev)
  (make-world
   (rect-after-mouse-event (world-rect1 w) mx my mev)
   (rect-after-mouse-event (world-rect2 w) mx my mev)
   (world-paused? w)))
;; TESTS
;; button-down: represent case for button-up, drag
;;              and other types of mouseEvents.
(begin-for-test
  (check-equal?
   (world-after-mouse-event
    WORLD-INITIAL-RECT12-PAUSED
    MOUSE-X-36
    MOUSE-Y-48
    button-down-event)
   (make-world
    (rect-after-mouse-event
     INITIAL-RECT-1
     MOUSE-X-36
     MOUSE-Y-48
     button-down-event)
    (rect-after-mouse-event
     INITIAL-RECT-2
     MOUSE-X-36
     MOUSE-Y-48
     button-down-event)
    true)
   "Should return a Paused World.")
  (check-equal?
   (world-after-mouse-event
    WORLD-INITIAL-RECT12-PLAYED
    MOUSE-X-36
    MOUSE-Y-48
    button-down-event)
   (make-world
    (rect-after-mouse-event
     INITIAL-RECT-1
     MOUSE-X-36
     MOUSE-Y-48
     button-down-event)
    (rect-after-mouse-event
     INITIAL-RECT-2
     MOUSE-X-36
     MOUSE-Y-48
     button-down-event)
    false)
   "Should return a world with Retangles made based on whether
    they are selected and placed at MOUSE-X-36, MOUSE-Y-48 and
    paused since mouseEvent is button-down."))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; world-with-paused-toggled : World -> World
;; GIVEN: a world comprising paused? field
;; RETURNS: a world just like the given one,
;;          but with paused? toggled
;; EXAMPLE: see tests below
;; STRATEGY: use template for World on w
(define (world-with-paused-toggled w)
  (make-world
   (world-rect1 w)
   (world-rect2 w)
   (not (world-paused? w))))
;; TESTS
(begin-for-test
  (check-equal?
   (world-with-paused-toggled
    WORLD-INITIAL-RECT12-PAUSED)
   (make-world
    INITIAL-RECT-1
    INITIAL-RECT-2
    false)
   "Return a new World like the given world,
    but with world-paused? set to true.")
  (check-equal?
   (world-with-paused-toggled
    WORLD-INITIAL-RECT12-PLAYED)
   (make-world
    INITIAL-RECT-1
    INITIAL-RECT-2
    true)
   "Return a new World like the given world,
    but with world-paused? set to false."))

;; rect-after-mouse-event : Rectangle Int Int MouseEvent -> Rectangle
;; GIVEN: A rectangle, the x- and y-coordinates
;;        of a mouse event, and the mouse event.
;; RETURNS: the rectangle that should follow the given
;;          rectangle after the given mouse event.
;; EXAMPLE: see tests below
;; STRATEGY: Divide into Cases on Mouse KeyEvent
(define (rect-after-mouse-event r mx my mev)
  (cond
    [(mouse=? mev "button-down") (rect-after-button-down r mx my)]
    [(mouse=? mev "drag") (rect-after-drag r mx my)]
    [(mouse=? mev "button-up") (rect-after-button-up r)]
    [else r]))
;; TESTS
;; how many tests do we need here?
;; 3 mouse events (+ a test for the else clause)
;; event inside cat or not.
(begin-for-test
  (check-equal?
   (rect-after-mouse-event
    INITIAL-RECT-1
    MOUSE-X-36
    MOUSE-Y-48
    button-down-event)
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
    drag-event)
   (rect-after-drag INITIAL-RECT-1 MOUSE-X-36 MOUSE-Y-48)
   "Should return a new Rectangle placed at (MOUSE-X-36,MOUSE-Y-48)
    with rect-selected? set to #true")
  (check-equal?
   (rect-after-mouse-event 
    INITIAL-RECT-1
    MOUSE-X-36
    MOUSE-Y-48
    button-up-event)
   (rect-after-button-up INITIAL-RECT-1)
   "Should return Rectangle placed at (MOUSE-X-36,MOUSE-Y-48)
    with rect-selected? set to #false")
  (check-equal?
   (rect-after-mouse-event 
    INITIAL-RECT-1
    MOUSE-X-36
    MOUSE-Y-48
    other-event)
   INITIAL-RECT-1
   "Should Return Input Rectangle since it was ignored due
    to an input other than button-down, drag, and button-up."))

;; new-rectangle : NonNegInt NonNegInt Int Int -> Rectangle
;; GIVEN: 2 non-negative integers x and y, and 2 integers vx and vy
;; RETURNS: a rectangle centered at (x,y), which will travel with
;;          velocity (vx, vy).
;; EXAMPLE: see tests below
;; STRATEGY: Combine Simpler Functions
(define (new-rectangle x y vx vy)
 (make-rect x y vx vy false ZERO ZERO ZERO ZERO))
;; TESTS
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
    false ZERO ZERO ZERO ZERO)
   "Should return a new rectangle with x(200), y(200), vx(23),
    vy(-14),selected?(#false always), and rest everything ZERO(0)"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; HELPER functions:

;; place-rect : Rectangle Scene -> Scene
;; GIVEN: A Rectangle and a Scene
;; RETURNS: A Scene with the GIVEN Rectangle or a CURSOR-DOT placed
;;          on Rectangle using mouse coordinates inherent in 
;;          Rectangle on the the given scene.
;; EXAMPLE:  
;; (place-rect XY-ORIG-SELECTED-VX-DY EMPTY-CANVAS) =>
;;   (place-rect-scene NEW-RECT-XY-ORIG EMPTY-CANVAS)
;; STRATEGY: Combine Simpler Functions
;;           Use template for Rectangle on rect
(define (place-rect rect scene)
  (if (rect-selected? rect)
      (place-dot-at rect scene)
      (place-rect-scene rect scene)
      ))
;; TESTS
(define X-35 35)
(define Y-45 45)
(define X-36 36)
(define Y-48 48)
(define DX-4 4)
(define DY-9 9)
(define VX-NEG-23 -23)
(define VY-14 14)
(define NEW-RECT-XY-ORIG (new-rectangle X-35 Y-45 VX-NEG-23 VY-14))
(define XY-ORIG-SELECTED-VX-DY
  (make-rect  X-35 Y-45 VX-NEG-23 VY-14 true X-36 Y-48 DX-4 DY-9))
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
;; RETURNS: a scene like the given one, but with 
;;          the given Rectangle painted on it.
;; EXAMPLE: see test below
;; STRATEGY: Combine Simpler Functions,
;;           Use template for Rectangle on rect
(define (place-rect-scene rect scene)
  (place-image
       (rect-vel-image
        (rect-vx rect)
        (rect-vy rect)
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
       (rect-vel-image VX-NEG-23 VY-14 false)
       X-35 Y-45
       EMPTY-CANVAS)
   "Should return an Image with a rectangle(60x50) blue in color
    placed at (34,45) on an empty scene of dimensions 400x300")
  (check-equal? 
   (place-rect-scene
     XY-ORIG-SELECTED-VX-DY
    EMPTY-CANVAS)
   (place-image
       (rect-vel-image VX-NEG-23 VY-14 true)
       X-35 Y-45
       EMPTY-CANVAS)
   "Should return an Image with a rectangle(60x50) red in color 
    placed at (34,45) on an empty scene of dimensions 400x300"))

;; place-dot-at : Rectangle Scene -> Scene
;; RETURNS: A Scene with a CURSOR-DOT plaed on top a
;;          Rectangle which itself is placed on given scene.
;; EXAMPLE: see tests below          
;; STRATEGY: Combine Simpler Functions,
;;           Use template for Rectangle on rect
(define (place-dot-at rect scene)
  (place-image
   CURSOR-DOT
   (rect-mx rect)
   (rect-my rect)
   (place-rect-scene rect scene)))
;; TESTS
(begin-for-test
  (check-equal?
   (place-dot-at
    XY-ORIG-SELECTED-VX-DY
    EMPTY-CANVAS)
   (place-image
    CURSOR-DOT
    X-36
    Y-48
    (place-rect-scene XY-ORIG-SELECTED-VX-DY EMPTY-CANVAS))
   "Should return a new rectangle(60x50) and dot(radius 5),
    both red in color placed at (0,0) on an empty scene of 
    dimensions 400x300 with a rectangle placed at (34,45)")) 

;; rect-velocity-image : Rectangle -> Image
;; RETURNS: An Image with the velocity fields inherent in the
;;          GIVEN Rectangle are placed in the form (vx,vy)
;;          at the center of the GIVEN Rectangle.
;; EXAMPLES:
;; (rect-velocity-image X-35 Y-45) =>
;; (overlay (velocity-image X-35 Y-45) RECTANGLE-IMAGE)
;; STRATEGY: Combine Simpler Functions
(define (rect-vel-image vx vy selected?)
  (overlay
   (velocity-image vx vy selected?)
   (rectangle-image (selected-color selected?))))
;; TESTS
(begin-for-test
  (check-equal?
   (rect-vel-image
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
   (rect-vel-image
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
;; GIVEN: X Velocity and Velocity
;; RETURNS: Image formed from the GIVEN Velocities
;;          in the form of (X Velocity, Y Velocity)
;; EXAMPLES:
;; (velocity-image X-35 Y-45) =>
;; (text "(35,45)" VELOCITY-FONT-SIZE RECTANGLE-COLOR)
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

;; rect-after-button-down : Rectangle Integer Integer -> Rectangle
;; GIVEN: A Rectangle, X and Y Coordinates of Mouse
;; RETURNS: the Rectangle following a button-down at the given location.
;; EXAMPLE: see tests below 
;; STRATEGY: Combine Simpler Functions,
;;           Use template for Rectangle on rect
(define (rect-after-button-down rect x y)
  (if (in-rect? rect x y)
      (make-rect
       (rect-x rect) (rect-y rect) (rect-vx rect) (rect-vy rect)
       true
       x y (- (rect-x rect) x) (- (rect-y rect) y))
      rect))
;; TESTS
(define RECT-X-ORIG-Y-ORIG-BTNDWN
  (make-rect 40 36 -23 -14 true 70 30 -30 6))
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
;; GIVEN: A Rectangle, X and Y Coordinates of Mouse
;; RETURNS: the rect following a drag at the given location
;; EXAMPLE: see tests below
;; STRATEGY: Use template for Rectangle on rect
(define (rect-after-drag rect x y) 
  (if (rect-selected? rect)
      (make-rect
       (+ x (rect-dx rect)) (+ y (rect-dy rect))
       (rect-vx rect) (rect-vy rect)
       true
       x y (rect-dx rect) (rect-dy rect)) 
      rect))
;; TESTS
(define RECT-X-ORIG-Y-ORIG-BTNDRAG
  (make-rect 40 36 -23 -14 true ZERO ZERO -130 6))
(define RECT-X-ORIG-Y-ORIG-BTNDRAGED
  (make-rect 40 36 -23 -14 true 170 30 -130 6))
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
;; GIVEN: A Rectangle
;; RETURNS: the rect following a button-up at the given location
;; EXAMPLE: see tests below
;; STRATEGY: Use template for Rectangle on rect
(define (rect-after-button-up rect) 
  (if (rect-selected? rect)
      (make-rect
       (rect-x rect) (rect-y rect)
       (rect-vx rect) (rect-vy rect)
       false
       ZERO ZERO ZERO ZERO)
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

;; in-rect? : Rectangle Integer Integer -> Boolean
;; RETURNS true iff the given coordinate is inside
;;         the bounding box of the given Rectangle.
;; EXAMPLES: see tests below
;; STRATEGY: Combine Simpler Functions,
;;           Use template for Rectangle on rect
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

;; rect-limit-check : Rectangle -> Rectangle
;; GIVEN: A Rectangle with X and Y Coordinates
;; RETURNS: A Rectangle like the given one but moved by
;;          the given velocity while velocity is inverted
;;          in corresponding direction if applicable.
;; EXAMPLES:
;; (rect-limit-check RECT-X-ORIG-Y-ORIG) => RECT-X-ORIG-Y-ORIG-INV
;; STRATEGY: Divide into Cases on rect
(define (rect-limit-check rect)
  (if (rect-selected? rect)
      rect  
      (cond
        [(within-limits? rect) (rect-after-tick rect)]
        [(and
          (touched-xorigin-boundary? rect)
          (touched-yorigin-boundary? rect))
         (rect-both-inverted rect true true)]
        [(and
          (touched-xend-boundary? rect)
          (touched-yorigin-boundary? rect))
         (rect-both-inverted rect false true)]
        [(and
          (touched-xorigin-boundary? rect)
          (touched-yend-boundary? rect))
         (rect-both-inverted rect true false)]
        [(and
          (touched-xend-boundary? rect)
          (touched-yend-boundary? rect))
         (rect-both-inverted rect false false)]    
        [(touched-xorigin-boundary? rect)
         (rect-vx-inverted rect true)] 
        [(touched-xend-boundary? rect)
         (rect-vx-inverted rect false)]
        [(touched-yorigin-boundary? rect)
         (rect-vy-inverted rect true)] 
        [(touched-yend-boundary? rect)
         (rect-vy-inverted rect false)])))

;; TESTS
(define UNTOUCHED-LIMITS
  (make-rect 200 200 23 -14 false ZERO ZERO ZERO ZERO))
(define TOUCHED-X-ORIGIN
  (make-rect 7 200 23 -14 false ZERO ZERO ZERO ZERO))
(define TOUCHED-X-ORIGIN-INV
  (make-rect 30 186 -23 -14 false ZERO ZERO ZERO ZERO))
(define TOUCHED-Y-ORIGIN
  (make-rect 200 20 23 -14 false ZERO ZERO ZERO ZERO))
(define TOUCHED-Y-ORIGIN-INV
  (make-rect 223 25 23 14 false ZERO ZERO ZERO ZERO)) 
(define TOUCHED-X-BOUNDARY
  (make-rect 400 200 23 -14 false ZERO ZERO ZERO ZERO))
(define TOUCHED-X-BOUNDARY-INV
  (make-rect 370 186 -23 -14 false ZERO ZERO ZERO ZERO))
(define TOUCHED-Y-BOUNDARY
  (make-rect 200 400 23 -14 false ZERO ZERO ZERO ZERO))
(define TOUCHED-Y-BOUNDARY-INV
  (make-rect 223 275 23 14 false ZERO ZERO ZERO ZERO))

(define RECT-X-ORIG-Y-ORIG
  (make-rect 40 36 -23 -14 false ZERO ZERO ZERO ZERO))
(define RECT-X-ORIG-Y-ORIG-INV
  (make-rect 30 25 23 14 false ZERO ZERO ZERO ZERO))
(define RECT-X-ORIG-Y-ORIG-SELECTED
  (make-rect 40 36 -23 -14 true ZERO ZERO ZERO ZERO))

(define RECT-X-ORIG-Y-BOUND
  (make-rect 40 271 -23 14 false ZERO ZERO ZERO ZERO))
(define RECT-X-ORIG-Y-BOUND-INV
  (make-rect 30 275 23 -14 false ZERO ZERO ZERO ZERO))

(define RECT-X-BOUND-Y-ORIG
  (make-rect 350 36 40 -14 false ZERO ZERO ZERO ZERO))
(define RECT-X-BOUND-Y-ORIG-INV
  (make-rect 370 25 -40 14 false ZERO ZERO ZERO ZERO))

(define RECT-X-BOUND-Y-BOUND
  (make-rect 350 271 40 14 false ZERO ZERO ZERO ZERO))
(define RECT-X-BOUND-Y-BOUND-INV
  (make-rect 370 275 -40 -14 false ZERO ZERO ZERO ZERO))
(begin-for-test
  (check-equal?
   (rect-limit-check RECT-X-ORIG-Y-ORIG)
   RECT-X-ORIG-Y-ORIG-INV
   "Rectangle is about to touch on both X&Y Origin
    on next step, so both velocities Inverted.")
  (check-equal?
   (rect-limit-check RECT-X-BOUND-Y-ORIG)
   RECT-X-BOUND-Y-ORIG-INV
   "Corner of X Boundary and Y Origin, so velocities
    should invert X should be 370 while Y should be 25.")  
  (check-equal?
   (rect-limit-check RECT-X-ORIG-Y-BOUND)
   RECT-X-ORIG-Y-BOUND-INV
   "Corner of X Origin and Y Boundary, so velocities
    should invert X should be 30 while Y should be 275.")
  (check-equal?
   (rect-limit-check RECT-X-BOUND-Y-BOUND)
   RECT-X-BOUND-Y-BOUND-INV
   "Corner of X&Y Boundary, so velocities should invert
    X should be 370 while Y should be 275.")
  (check-equal?
   (rect-limit-check TOUCHED-X-ORIGIN)
   TOUCHED-X-ORIGIN-INV
   "Touched X Origin so inverse X velocity
    and put Rectangle on X Origin.")
  (check-equal? 
   (rect-limit-check TOUCHED-X-BOUNDARY)
   TOUCHED-X-BOUNDARY-INV
   "Touched X Boundary so inverse X velocity
    and put Rectangle on X Boundary.")
  (check-equal?
   (rect-limit-check TOUCHED-Y-ORIGIN)
   TOUCHED-Y-ORIGIN-INV
   "Touched Y Origin so inverse Y velocity
    and put Rectangle on Y Origin.")
  (check-equal?
   (rect-limit-check TOUCHED-Y-BOUNDARY)
   TOUCHED-Y-BOUNDARY-INV
   "Touched Y Boundary so inverse Y velocity
    and put Rectangle on Y Boundary."))

;; within-limits? : Rectangle -> Boolean
;; GIVEN: A Rectangle with specified coordinate
;; RETURNS: True iff given rectangle's X and Y Coordinates
;;          wont touch any boundaries in the next step,
;;          false otherwise.
;; EXAMPLES:
;; (within-limits? TOUCHED-Y-ORIGIN) => #false
;; (within-limits? RECT-X-BOUND-Y-BOUND) => #false
;; STRATEGY: Use Template for Rectangle on rect
(define (within-limits? rect) 
  (and
      (and
        (> (+ (rect-x rect) (rect-vx rect)) X-ORIGIN)
        (> (+ (rect-y rect) (rect-vy rect)) Y-ORIGIN))
      (and
        (< (+ (rect-x rect) (rect-vx rect)) X-BOUNDARY)        
        (< (+ (rect-y rect) (rect-vy rect)) Y-BOUNDARY))))
;; TESTS
(begin-for-test 
  (check-equal?
   (within-limits? UNTOUCHED-LIMITS)
   true
   "Should return #true since Rectangle is within all Boundaries")
  (check-equal?
   (within-limits? TOUCHED-Y-ORIGIN)
   false
   "Should return #false since Rectangle
    will Reach Y Origin in the next Step")
  (check-equal?
      (within-limits? RECT-X-ORIG-Y-ORIG)
   false
   "Should return #false since Rectangle
    will Reach X&Y Origin in the next Step")
  (check-equal?
      (within-limits? TOUCHED-Y-BOUNDARY)
   false
   "Should return #false since Rectangle
    will Reach Y Boundary in the next Step")
  (check-equal?
      (within-limits? TOUCHED-X-BOUNDARY)
   false
   "Should return #false since Rectangle
    will Reach X Boundary in the next Step")
  (check-equal?
      (within-limits? RECT-X-BOUND-Y-BOUND)
   false
   "Should return #false since Rectangle
    will Reach X&Y Boundaries in the next Step"))

;; touched-xorigin-boundary? : Rectangle -> Boolean
;; touched-xend-boundary? : Rectangle -> Boolean
;; touched-yorigin-boundary? : Rectangle -> Boolean
;; touched-yend-boundary? : Rectangle -> Boolean
;; GIVEN: A Rectangle with specific x and y position
;; RETURNS: A Boolean based on whether rectangle touches 
;;          Origin or Boundary of the corresponding axis
;; EXAMPLES:
;; (touched-xorigin-boundary? TOUCHED-X-ORIGIN) => #true
;; (touched-yorigin-boundary? UNTOUCHED-LIMITS) => #false
;; STRATEGY: Use template for Rectangle on rect
(define (touched-xorigin-boundary? rect) 
  (<= (+ (rect-x rect) (rect-vx rect)) X-ORIGIN)) 
(define (touched-xend-boundary? rect)
  (>= (+ (rect-x rect) (rect-vx rect)) X-BOUNDARY))
(define (touched-yorigin-boundary? rect)
  (<= (+ (rect-y rect) (rect-vy rect)) Y-ORIGIN))
(define (touched-yend-boundary? rect)
  (>= (+ (rect-y rect) (rect-vy rect)) Y-BOUNDARY))
;; TESTS
;; X-Origin: 30, Y-Origin: 25
;; X-Boundary: 370, Y-Boundary: 275
(begin-for-test
  (check-equal?
   (touched-xorigin-boundary? TOUCHED-X-ORIGIN)
   true
   "Should return #true since Rectangle
    is touching X-Axis Origin")
  (check-equal?
   (touched-yorigin-boundary? TOUCHED-Y-ORIGIN)
   true
   "Should return #true since Rectangle
    is touching Y-Axis Origin")
  (check-equal?
   (touched-xend-boundary? TOUCHED-X-BOUNDARY)
   true
   "Should return #true since Rectangle
    is touching X-Axis Boundary")
  (check-equal?
   (touched-yend-boundary? TOUCHED-Y-BOUNDARY)
   true
   "Should return #true since Rectangle
    is touching Y-Axis Boundary")
  (check-equal?
   (touched-xorigin-boundary? UNTOUCHED-LIMITS)
   false
   "Should return #false since Rectangle
    is not touching X-Axis Origin")
  (check-equal?
   (touched-yorigin-boundary? UNTOUCHED-LIMITS)
   false
   "Should return #false since Rectangle
    is not touching X-Axis Origin")
  (check-equal?
   (touched-xend-boundary? UNTOUCHED-LIMITS)
   false
   "Should return #false since Rectangle
    is not touching X-Axis Boundary")
  (check-equal?
   (touched-yend-boundary? UNTOUCHED-LIMITS)
   false
   "Should return #false since Rectangle
    is not touching Y-Axis Boundary"))

;; rect-after-tick : Rectangle -> Rectangle
;; GIVEN: A Rectangle
;; RETURNS: A Rectangle like the one GIVEN, but displaced by
;;          the inherent velocity in both X and Y directions.
;; EXAMPLES: see tests below
;; STRATEGY: Combine Simpler Functions,
;;           Use template for Rectangle on rect
(define (rect-after-tick rect)
  (new-rectangle
   (+ (rect-x rect) (rect-vx rect))
   (+ (rect-y rect)  (rect-vy rect))
   (rect-vx rect)
   (rect-vy rect)))
;; TESTS
(define RECT-NEG-VY
  (make-rect 70 200 23 -14 false ZERO ZERO ZERO ZERO))
(define RECT-NEG-VY-MOVD
  (make-rect 93 186 23 -14 false ZERO ZERO ZERO ZERO))

(define RECT-NEG-VX
  (make-rect 200 200 -23 14 true ZERO ZERO ZERO ZERO))
(define RECT-NEG-VX-MOVD
  (make-rect 177 214 -23 14 false ZERO ZERO ZERO ZERO))

(define RECT-POS-VXY
  (make-rect 200 200 23 14 false ZERO ZERO ZERO ZERO))
(define RECT-POS-VXY-MOVD
  (make-rect 223 214 23 14 false ZERO ZERO ZERO ZERO))

(define RECT-NEG-VXY
  (make-rect 200 200 -23 -14 true ZERO ZERO ZERO ZERO))
(define RECT-NEG-VXY-MOVD
  (make-rect 177 186 -23 -14 false ZERO ZERO ZERO ZERO))
(begin-for-test
  (check-equal?
   (rect-after-tick RECT-NEG-VY)
   RECT-NEG-VY-MOVD
   "Should Place Rectangle 70+23
    on X Axis and 200+(-14) on Y Axis")
  (check-equal?
   (rect-after-tick RECT-NEG-VX)
   RECT-NEG-VX-MOVD
   "Should Place Rectangle 200+(-23)
    on X Axis and 200+14 on Y Axis")
  (check-equal?
   (rect-after-tick RECT-POS-VXY)
   RECT-POS-VXY-MOVD
   "Should Place Rectangle 200+23 on
    X Axis and 200+14 on Y Axis")
  (check-equal?
   (rect-after-tick RECT-NEG-VXY)
   RECT-NEG-VXY-MOVD
   "Should Place Rectangle 200+(-23)
    on X Axis and 200+(-14) on Y Axis"))

;; rect-vx-inverted : Rectangle Boolean -> Rectangle
;; rect-vy-inverted : Rectangle Boolean -> Rectangle
;; GIVEN: A Rectangle with a flag
;; RETURNS: A Rectangle like the given one with x or y
;;          distance moved and velocities inverted.
;; WHERE:
;; flag: True, Rectangle is at Origin
;        False, Rectangle is at the Boundary
;; EXAMPLES: see tests below
;; STRATEGY: Combine Simpler Functions,
;;           Use template for Rectangle on rect
(define (rect-vx-inverted r xorigin?)
  (new-rectangle
   (if xorigin?
       HALF-RECTANGLE-WIDTH
       X-BOUNDARY)
   (+ (rect-y r)  (rect-vy r))
   (- (rect-vx r)) 
   (rect-vy r)))
(define (rect-vy-inverted r yorigin?)
  (new-rectangle 
   (+ (rect-x r) (rect-vx r))
   (if yorigin?
       Y-ORIGIN
       Y-BOUNDARY) 
   (rect-vx r) 
   (- (rect-vy r))))
;; TESTS
(define RECT-X-ORIG
  (make-rect 35 200 -23 -14 false ZERO ZERO ZERO ZERO))
(define RECT-X-ORIG-INV
  (make-rect 30 186 23 -14 false ZERO ZERO ZERO ZERO))

(define RECT-X-BOUND
  (make-rect 370 200 23 -14 false ZERO ZERO ZERO ZERO))
(define RECT-X-BOUND-INV
  (make-rect 370 186 -23 -14 false ZERO ZERO ZERO ZERO))

(define RECT-Y-ORIG
  (make-rect 70 30 23 -14 false ZERO ZERO ZERO ZERO))
(define RECT-Y-ORIG-INV
  (make-rect 93 25 23 14 false ZERO ZERO ZERO ZERO))

(define RECT-Y-BOUND
  (make-rect 70 270 23 34 false ZERO ZERO ZERO ZERO))
(define RECT-Y-BOUND-INV
  (make-rect 93 275 23 -34 false ZERO ZERO ZERO ZERO))
(begin-for-test
  (check-equal?
   (rect-vx-inverted RECT-X-ORIG true)
   RECT-X-ORIG-INV
   "Should Invert X Velocity and Place Rectangle on the Origin")
  (check-equal?
   (rect-vx-inverted RECT-X-BOUND false)
   RECT-X-BOUND-INV
   "Should Invert X Velocity and Place Rectangle on the Boundary")
  (check-equal?
   (rect-vy-inverted RECT-Y-ORIG true)
   RECT-Y-ORIG-INV
   "Should Invert Y Velocity and Place Rectangle on the Origin")
  (check-equal?
   (rect-vy-inverted RECT-Y-BOUND false)
   RECT-Y-BOUND-INV
   "Should Invert Y Velocity and Place Rectangle on the Boundary"))

;; rect-both-inverted : Rectangle -> Rectangle
;; GIVEN: A Rectangle with two flags
;; RETURNS: A Rectangle like the given one with x and y
;;          distance moved and both velocities inverted.
;; WHERE:
;; flag: True, Rectangle is at Origin
;        False, Rectangle is at the Boundary
;; EXAMPLES: see tests below
;; STRATEGY: Combine Simpler Functions,
;;           Use template for Rectangle on rect
(define (rect-both-inverted r xorigin? yorigin?)
  (new-rectangle 
   (if xorigin?
       HALF-RECTANGLE-WIDTH
       X-BOUNDARY)
   (if yorigin?
       Y-ORIGIN
       Y-BOUNDARY) 
   (- (rect-vx r))
   (- (rect-vy r))))
;; TESTS
(begin-for-test
  (check-equal?
   (rect-both-inverted
    RECT-X-ORIG-Y-ORIG
    true
    true) 
   RECT-X-ORIG-Y-ORIG-INV
   "Should place Rectangle at X and Y Orgin
    while Inverting Rectangle's X and Y Velocity")
  (check-equal?
   (rect-both-inverted
    RECT-X-ORIG-Y-BOUND
    true
    false)
   RECT-X-ORIG-Y-BOUND-INV
   "Should place Rectangle at X and Y Orgin
    while Inverting Rectangle's X and Y Velocity")
  (check-equal?
   (rect-both-inverted
    RECT-X-BOUND-Y-ORIG
    false
    true)
   RECT-X-BOUND-Y-ORIG-INV
   "Should place Rectangle at X Boundary and Y Orgin
    while Inverting Rectangle's X and Y Velocity")
  (check-equal?
   (rect-both-inverted
    RECT-X-BOUND-Y-BOUND
    false
    false)
   RECT-X-BOUND-Y-BOUND-INV
   "Should place Rectangle at X and Y Boundary
    while Inverting Rectangle's X and Y Velocity"))

;; selected-color : Boolean -> String
;; GIVEN: A flag
;; RETURNS: Color based on flag value
;; WHERE:
;; flag: True, selected color is NORMAL-COLOR
;;       False, selected color is SELECTED-COLOR
;; EXAMPLES:
;; (selected-color true) => "red"
;; (selected-color false) => "blue"
;; STRATEGY: Combine Simpler Functions
(define (selected-color flag)
  (if flag  SELECTED-COLOR NORMAL-COLOR))
;; TESTS
(begin-for-test
  (check-equal? (selected-color true) SELECTED-COLOR
                "Should return 'red' when flag is true")
  (check-equal? (selected-color false) NORMAL-COLOR
                "Should return 'blue' when flag is true"))

;; rectangle-image : String -> Image
;; GIVEN: A Color
;; RETURNS: Image of an Rectangle with the GIVEN Color 
;; WHERE:
;; flag: True, selected color is NORMAL-COLOR
;;       False, selected color is SELECTED-COLOR
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
 
(screensaver 0.2)

;; END
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
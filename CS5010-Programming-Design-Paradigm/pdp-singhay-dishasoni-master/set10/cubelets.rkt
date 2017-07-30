#lang racket

#|
  FILENAME  : cubelets.rkt
  CO-AUTHORS: Ayush Singh(singhay) and Disha Soni(dishasoni)

  Program to represent a Toy factory inspired by Cubelets, square blocks that 
  stick together upon contact with each other and never part once together.
  When a block is moved using  button-down following drag, all its teammates 
  move along with it. Only the selected block accumulates teammates.

  GOAL: To simulate a toy with multiple attributed functionalities on a canvas.
  INSTRUCTIONS: start with (run framerate).  Typically: (run 0.25)
                press "b" to add a new block and drag to play with it.
|#

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; LIBRARIES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(require rackunit)
(require "sets.rkt")
(require 2htdp/image)
(require "extras.rkt")
(require 2htdp/universe) 
(require "WidgetWorks.rkt")
(check-location "10" "cubelets.rkt")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; PROVIDE FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(provide Block<%>
         make-block)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; CONSTANTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Canvas Dimensions
(define CANVAS-HEIGHT 600)
(define CANVAS-WIDTH 500)
(define HALF-CANVAS-WIDTH (/ CANVAS-WIDTH 2))
(define HALF-CANVAS-HEIGHT (/ CANVAS-HEIGHT 2))
(define EMPTY-CANVAS (empty-scene CANVAS-WIDTH CANVAS-HEIGHT))

;; Block Dimensions
(define BLOCK-INIT-X (/ CANVAS-WIDTH 2))
(define BLOCK-INIT-Y (/ CANVAS-HEIGHT 2))
(define BLOCK-SIDE 20)
(define BLOCK-SIDE-HALF (/ BLOCK-SIDE 2))
(define BLOCK-MAX-X (- CANVAS-WIDTH BLOCK-SIDE-HALF))
(define BLOCK-MAX-Y (- CANVAS-HEIGHT BLOCK-SIDE-HALF))
(define BLOCK-MODE "outline")
(define BLOCK-COLOR "green")
(define BLOCK-SLCTD-COLOR "red")
(define BLOCK-IMG (square BLOCK-SIDE BLOCK-MODE BLOCK-COLOR))
(define BLOCK-SLCTD-IMG (square BLOCK-SIDE BLOCK-MODE BLOCK-SLCTD-COLOR))

;; KeyEvents
(define NEW-BLOCK-KEY-EVENT "b")
(define OTHER-KEY-EVENT "\b")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; DATA DEFINITIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; A Block is an object whose class implements Block<%>

;; Block<%> is a (make-block x y team)
;; INTERP:
;;  x    is the x-coordinate of the center of the block
;;  y    is the y-coordinate of the center of the block
;;  team is a list of blocks contains the teammates of the block
;; TEMPLATE:
#|
  (define (block-fn block)
           (block-x block)
           (block-y block)
           (get-team block))
|#

;; A ListOfBlock<%> is either
;; -- empty
;; -- (cons Block<%> ListOfBlock<%>)
;; TEMPLATE:
#|
  (define (lob-fn lob)
           (block-fn (first lob))
           (lob-fn (rest lob)))
|#

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; INTERFACES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; The Block<%> interface extends the SWidget<%> interface
;; Every Block% Class must implement Block<%> Interface

(define Block<%>
  (interface (SWidget<%>) ;; this means: include all the methods in
                          ;; SWidget<%>. 
    
    ;; get-team : -> ListOfBlock<%>
    ;; RETURNS: the teammates of this block
    get-team
    
    ;; add-teammate: Block<%> -> Void
    ;; EFFECT: adds the given block to this block's team
    add-teammate
    
    ;; block-x : -> Integer
    ;; block-y : -> Integer
    ;; RETURNS: the x or y coordinates of this block
    block-x
    block-y

    ;; Block<%> -> Boolean
    ;; does this block intersect the other one?
    intersects?

    ;; Block<%> -> Boolean
    ;; Would a block with the given x,y,team intersect this one?
    intersect-responder

    ;; -> Void 
    ;; EFFECT: sets the offset of this relative to the leader
    update-offset

    ;; -> Void
    ;; EFFECT: sets the position of center of the block
    move-team
                    
    ;; -> Void
    ;; EFFECT: Updates the list of world-blocks in all the blocks
    update-world-blocks
                    
    ;; -> Void
    ;; EFFECT: Updates world-blocks with the given block list 
    update-this-world-blocks
    )) 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; CLASSES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; The BlockFactory<%> interface extends the SWidget<%> interface.
;; A BlockFactory% class is a (new BlockFactory% [x Integer] [y Integer]
;; x,y and world-blocks are optional             [world-blocks ListOfBlock<%>]
;;                                               [world StatefulWorld<%>])
;; accepts "b" key events and adds them to the world.
;; gets the world as an init-field

(define BlockFactory%
  (class* object% (SWidget<%>)

    (init-field world)             ; the world to which the factory adds balls
    (init-field [x BLOCK-INIT-X])  ; X position of the last button down
    (init-field [y BLOCK-INIT-Y])  ; Y position of the last button down

    ; List of all the blocks in the world
    (init-field [world-blocks empty])
    
    (super-new)

    ; KeyEvent : KeyEvent -> Void
    ; GIVEN: a key event
    ; EFFECT: updates this widget to the state it should have
    ; following the given key event
    (define/public (after-key-event kev)
      (local
        ((define b (new Block% [x x][y y][world-blocks world-blocks])))
      (cond
        [(key=? kev NEW-BLOCK-KEY-EVENT)
         (begin (send world add-stateful-widget b)
                (send b update-world-blocks)
                (set! world-blocks (cons b world-blocks)))])))
    
    ; Integer Integer -> Void
    ; GIVEN: a location
    ; EFFECT: updates this widget to the state it should have
    ; following the specified mouse event at the given location.
    (define/public (after-button-down mx my)
      (begin (set! x mx)
             (set! y my)))
    
    ;; the Block Factory has no other behavior
    (define/public (after-tick) this)    
    (define/public (after-button-up mx my) this)
    (define/public (after-drag mx my) this)
    (define/public (add-to-scene s) s)
    ))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; A Block starts at the center of the CANVAS if no button down
;; else it starts at the last button down/up position.
;; They are selectable and draggable.

;; A Block% is a (new Block% [x Integer][y Integer] 
;; all these are optional    [team ListOfBlock<%>][world-blocks ListOfBlock<%>]
;; except x,y                [selected? Boolean][mx Integer][my Integer])
;; REPRESENTS: a green square of size 20x20 in outline mode.

(define Block%
  (class* object% (Block<%>)
  
    ;; the init-fields are the values that may vary from
    ;; one block to the next.
     
    ; the x and y position of the center of the block
    (init-field x y)
    
    ; List of all the teammates, Default is empty.
    (init-field [team empty])
    
    ; List of all the blocks in the world
    (init-field [world-blocks empty])    

    ; is the block selected? Default is false.
    (init-field [selected? false])
    
    ;; if the block is selected, the position of
    ;; the last button-down event inside the block, relative to the
    ;; block's center.  Else any value.
    (init-field [saved-mx 0] [saved-my 0])             
    
    (super-new)             
    
    ;; after-button-down : Integer Integer -> Void
    ;; GIVEN: the location of a button-down event
    ;; STRATEGY: Cases on whether the event is in the block
    (define/public (after-button-down mx my)
      (if (in-block? mx my) 
          (begin
            (set! selected? true)
            (set! saved-mx (- mx x))
            (set! saved-my (- my y))
            (for-each (lambda (b) (send b update-offset x y)) team))
          this))
    
    ;; after-button-up : Integer Integer -> Void
    ;; GIVEN   : the location of a button-up event
    ;; STRATEGY: Cases on whether the event is in the block.
    ;;           If the block is selected, then unselect it.
    (define/public (after-button-up mx my)
      (set! selected? false))   
    
    ;; after-drag : Integer Integer -> Void
    ;; GIVEN   : the location of a drag event
    ;; STRATEGY: Cases on whether the block is selected.
    ;; If it is selected, move it so that the vector from the center to
    ;; the drag event is equal to (mx, my)
    (define/public (after-drag mx my)
      (if selected?
          (begin
            (set! x (next-x-pos mx)) 
            (set! y (next-y-pos my))
            (for-each (lambda (b) (intersects? b))
                       (set-diff world-blocks (cons this team)))
            (for-each (lambda (b) (send b move-team x y)) team))
          this))   
      
    ;; to-scene : Scene -> Scene 
    ;; RETURNS  : a scene like the given one, but 
    ;;            with this block painted on it.
    (define/public (add-to-scene scene)
      (place-image
       (if selected? BLOCK-SLCTD-IMG BLOCK-IMG)
       x y scene))

    ;; Block<%> -> Void
    ;; STRATEGY: Divide into Cases on whether this intersects with other-b
    (define/public (intersects? other-b)
      (local
        ((define other-b-team (send other-b get-team)))
        (cond
          [(send other-b intersect-responder x y)
           (begin
             (update-team-helper this other-b other-b-team)
             (update-team-helper other-b this team)
             (update-team-of-team other-b other-b-team team)
             (update-team-of-team this team other-b-team)          
             (send other-b update-offset x y)
             (for-each (lambda (b) (send b update-offset x y)) team))])))
   
    ;; Integer^2 -> Boolean
    ;; EFFECT: checks if given x/y are a certain dist. from this
    (define/public (intersect-responder other-x other-y)
      (in-this? other-x other-y BLOCK-SIDE))
    
    ;; -> Void 
    ;; EFFECT: sets the offset of this relative to the leader
    (define/public (update-offset other-x other-y)
      (begin
        (set! saved-mx (- other-x x))
        (set! saved-my (- other-y y))))
    
    ;; -> Void
    ;; EFFECT: sets the position of center of the block
    (define/public (move-team other-x other-y)
      (begin
        (set! x (- other-x saved-mx))
        (set! y (- other-y saved-my))))
    
    ;; block-x : -> Integer
    ;; block-y : -> Integer
    ;; RETURNS : the x or y coordinates of this block
    (define/public (block-x) x)    
    (define/public (block-y) y)

    ;; get-team : -> ListOfBlock<%>
    ;; RETURNS  : the teammates of this block
    (define/public (get-team) team)

    ;; add-teammate : Block<%> -> Void
    ;; EFFECT : adds the given block to this block's team
    (define/public (add-teammate b)
      (cond
        [(not (my-member? b (cons this team)))
         (set! team (cons b team))])) 

    ;; -> Void
    ;; EFFECT: Updates the list of world-blocks in all the blocks
    (define/public (update-world-blocks) 
      (begin
        (set! world-blocks (cons this world-blocks))
        (for-each
         (lambda (b) (send b update-this-world-blocks world-blocks))
         (set-minus world-blocks this))))

    ;; -> Void
    ;; EFFECT: Updates world-blocks with the given block list 
    (define/public (update-this-world-blocks updated-blocks)
      (set! world-blocks updated-blocks))  
    
    ;; the next few functions are local functions, not in the interface.
    
    ;; next-x-pos : Integer -> Integer
    ;; next-y-pos : Integer ->Integer
    ;; GIVEN   : the x/y coordinate of the mouse event
    ;; RETURNS : x/y coordinate of the target 
    ;; STRATEGY: Generalizing over another function
    (define (next-x-pos mx)
      (next-pos-calc x mx saved-mx BLOCK-MAX-X))
 
    (define (next-y-pos my)
      (next-pos-calc y my saved-my BLOCK-MAX-Y))

    ;; -> Void
    ;; EFFECT: Adds lst and block-2 as teammate of block-1 team
    (define (update-team-helper block-1 block-2 lst)
      (for-each (lambda (b) (send block-1 add-teammate b))
                (cons block-2 lst)))

    ;; -> Void
    ;; EFFECT: Adds block as teammate in inner-lst to outer-lst
    (define (update-team-of-team block inner-lst outer-lst)
      (for-each (lambda (b)
                  (begin (send b add-teammate block)
                         (update-team-of-team-helper b inner-lst)))
                outer-lst))

    ;; -> Void
    ;; EFFECT: Adds blocks in list as teammate to block
    (define (update-team-of-team-helper block list)
      (for-each (lambda (b) (send block add-teammate b)) list))
    
    ;; Integer^4 -> Integer
    ;; STRATEGY: Cases on whether the position of Block is within limits.
    (define (next-pos-calc pos m-pos offst max)
      (local
        ((define pos (- m-pos offst)))      
        (cond
          [(<= pos BLOCK-SIDE-HALF) BLOCK-SIDE-HALF]
          [(>= pos max) max]
          [else pos])))
    
    ;; in-block? : Integer^2 -> Boolean
    ;; GIVEN   : a location on the canvas
    ;; RETURNS : true iff the location is inside this block.
    ;; STRATEGY: Generalizing over another function.
    (define (in-block? other-x other-y)
      (in-this? other-x other-y BLOCK-SIDE-HALF))

    ;; -> Boolean
    ;; RETURNS: true iff distance between given x,y and this' x,y
    ;;          are less than given dist
    (define (in-this? other-x other-y dist)
      (and (<= (abs (- x other-x)) dist)
           (<= (abs (- y other-y)) dist)))    
 
    ;; the ball ignores key and tick events
    (define/public (after-tick) this)
    (define/public (after-key-event kev) this)  
    ))

;; make-block : NonNegInt NonNegInt ListOfBlock<%> -> Block<%>
;; GIVEN  : an x and y position, and a list of blocks
;; WHERE  : the list of blocks is the list of blocks already on the playground.
;; RETURNS: a new block, at the given position, with no teammates 
(define (make-block x y lob)
  (new Block% [x x][y y][team lob]))
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; MAIN FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (initial-world)
  (local
    ((define the-world (make-world CANVAS-WIDTH CANVAS-HEIGHT))
     (define the-factory (new BlockFactory% [world the-world])))
    (begin
      ;; put the factory in the world
      (send the-world add-stateful-widget the-factory)           
      the-world)))

;; Constant made up just to evaluate initial-world for test coverage
(define INITIAL-WORLD (initial-world))

;; run : PosNum -> WorldState<%>
;; RETURNS: the final state of the world
(define (run frame-rate)
  (send INITIAL-WORLD run frame-rate))

;(run 0.5)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; TESTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(begin-for-test
  (local
    ((define X 400)
     (define Y 200)
     (define w (make-world CANVAS-WIDTH CANVAS-HEIGHT))
     (define bF (new BlockFactory% [world w]))
     (define b (make-block HALF-CANVAS-WIDTH HALF-CANVAS-HEIGHT empty))
     (define b1 (make-block X Y (list b)))
     (define b2 (make-block X Y (list b b1)))
     (define b3 (make-block X Y (list b b1 b2)))
     (define b3-sel (new Block% [x X] [y Y] [team (list b)]
                         [selected? true][world-blocks (list b b1 b2 b3)]))
     (define b-sel (new Block% [x X]
                        [y Y][selected? true]))
     (define b-min (new Block% [x X] 
                        [y Y][selected? true][saved-mx 20])))
    (check-equal? (send b block-x) HALF-CANVAS-WIDTH
                  "should return the x coordiate of b")
    (check-equal? (send b block-y) HALF-CANVAS-HEIGHT
                  "should return the y coordiate of b")
    (check-equal? (send b-sel get-team) empty
                  "should return the team of b-sel")
    (check-equal? (send b1 block-x) X
                  "should return the x coordiate of b")
    (check-equal? (send b1 block-y) Y
                  "should return the y coordiate of b")
    (check-equal? (send b1 get-team) (list b)
                  "should return the team of b1")    
    (check-equal? (send b2 block-x) X
                  "should return the x coordiate of b")
    (check-equal? (send b2 block-y) Y
                  "should return the y coordiate of b")
    (check-equal? (send b2 get-team) (list b b1)
                  "should return the team of b2")
    (check-equal? (send b3 block-x) X
                  "should return the x coordiate of b") 
    (check-equal? (send b3 block-y) Y
                  "should return the y coordiate of b")
    (check-equal? (send b3-sel get-team) (list b)
                  "should return the team of b3-sel")
    (send b add-teammate b1)
    (check-equal? (send b get-team) (list b1)
                  "should return the team of b with b1")
    (send bF after-key-event NEW-BLOCK-KEY-EVENT)
    (send bF after-button-down HALF-CANVAS-WIDTH HALF-CANVAS-HEIGHT)
    (send w add-stateful-widget b)
    (send w add-stateful-widget b1)
    (send b-sel after-button-down HALF-CANVAS-WIDTH HALF-CANVAS-HEIGHT)
    (send b1 after-button-down X Y)
    (send b1 after-button-up HALF-CANVAS-WIDTH HALF-CANVAS-HEIGHT)
    (send b3-sel after-drag HALF-CANVAS-WIDTH HALF-CANVAS-HEIGHT)
    (send b3-sel after-drag X Y)
    (send b3 after-drag HALF-CANVAS-WIDTH HALF-CANVAS-HEIGHT)
    (send b-min after-drag 10 30)
    (send b3 add-to-scene EMPTY-CANVAS)
    (send b3-sel add-to-scene EMPTY-CANVAS)
    (send b after-tick)
    (send b after-key-event NEW-BLOCK-KEY-EVENT)
    (send bF after-tick)    
    (send bF after-button-up HALF-CANVAS-WIDTH HALF-CANVAS-HEIGHT)
    (send bF after-drag HALF-CANVAS-WIDTH HALF-CANVAS-HEIGHT)
    (send bF add-to-scene EMPTY-CANVAS)
    (send b3 intersects? b3-sel)
    (send b3-sel update-world-blocks)
    (send b3 update-this-world-blocks (list b b1 b2 b3))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; END OF PROGRAM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-intermediate-lambda-reader.ss" "lang")((modname robot) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f () #f)))
;; robot.rkt : Second question of problem set08

;; GOAL: To return a path from given start to target position avoiding
;;       all the obstructions in the way

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; LIBRARY
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(require rackunit)
(require "extras.rkt")
(require "sets.rkt")
(check-location "08" "robot.rkt")

(provide path
         eval-plan)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; CONSTANTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Numerical
(define ONE 1)
(define OFFSET 3)

;; Boolean
(define TRUE #true)
(define FALSE #false)

;; Directions
(define NORTH -1)
(define SOUTH 1)
(define EAST 1)
(define WEST -1)
(define NORTH-EAST "ne")
(define SOUTH-EAST "se")
(define SOUTH-WEST "sw")
(define NORTH-WEST "nw")

;; List
(define NULL-LIST (list (list "null" 0)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; DATA DEFINITIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (make-position x y) (list x y))
(define (position-x position) (first position))
(define (position-y position) (second position))
;; A Position is a (list Integer Integer)
;; (list x y) represents the position (x,y).
;; Note: this is not to be confused with the built-in data type Posn.
;; TEMPLATE:
;; position-fn : Position -> ??
#|
(define (position-fn s)
  (... (position-x s)
       (position-y s)))
|#
;; EXAMPLES
;; (make-position 0 0)
;; A ListOfPosition is a
;; -- empty
;; (cons Position ListOfPosition)
;; TEMPLATE:
;; LOP-fn : ListOfPosition -> ??
#|
(define (LOP-fn lst)
 (cond
  [(empty? lst) ...]
  [else (... (position-fn (first lst))
             (LOP-fn (rest lst)))]))
|# 
;; EXAMPLES
;; (list (list -3 6) (list 7 6))
(define wall1
  '((0 3)(2 3)(4 3)
         (0 5)     (4 5)
         (0 7)(2 7)(4 7)))
(define two-walls
  '((0 3)(4 3)
         (0 5)(4 5)
         (0 7)(4 7)
         (0 9)(4 9)
         (0 11)(4 11)))

(define (make-move direction distance) (list direction distance))
(define (move-direction move) (first move))
(define (move-distance move) (second move))
;; A Move is a (list Direction PosInt)
;; Interp: a move of the specified number of steps in the indicated
;; direction. 
;; A Direction is one of
;; -- "ne"
;; -- "se"
;; -- "sw"
;; -- "nw"
;; TEMPLATE:
;; move-fn : Move -> ??
#|
(define (move-fn s)
  (... (move-direction s)
       (move-distance s)))
|#

;; A Plan is a ListOfMove
;; WHERE: the list does not contain two consecutive moves in the same
;; direction.
;; INTERP: the moves are to be executed from the first in the list to
;; the last in the list.
;; A ListOfMove is a
;; -- empty
;; (cons Position ListOfPosition)
;; TEMPLATE:
;; LOM-fn : ListOfMove -> ??
#|
(define (LOM-fn lst)
 (cond
  [(empty? lst) ...]
  [else (... (move-fn (first lst))
             (LOM-fn (rest lst)))]))
|# 
;; EXAMPLES:
(define WALL1-PATH
  (list
   (list "nw" 2)
   (list "sw" 3)
   (list "se" 1)
   (list "sw" 1)
   (list "se" 2)
   (list "ne" 1)
   (list "se" 1)
   (list "ne" 1)
   (list "se" 1)
   (list "ne" 1)))

(define TWO-WALLS-PATH
  (list
   (list "se" 1)
   (list "sw" 1)
   (list "se" 1)
   (list "sw" 1)
   (list "se" 1)
   (list "sw" 1)
   (list "se" 2)
   (list "ne" 1)
   (list "se" 1)
   (list "ne" 1)
   (list "se" 1)
   (list "ne" 1)
   (list "se" 1)
   (list "ne" 2)
   (list "nw" 2)
   (list "ne" 1)
   (list "nw" 1)
   (list "ne" 2)))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; MAIN FUNCTION
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; path    : Position Position ListOfPosition -> MaybePlan
;; GIVEN   :
;;           1. the starting position of the robot (start),
;;           2. the target position that robot is supposed to reach (trgt)
;;           3. A list of the blocks on the board (lob)
;; RETURNS : a plan that, when executed, will take the robot from the 
;;           starting position to the target position without passing over 
;;           any of the blocks, or false if no such sequence of moves exists.
;; EXAMPLES: see tests below
;; STRATEGY: Use template of General Recursion on start and trgt
(define (path start trgt lob)
  (cond
    [(equal? start trgt) empty]
    [(invalid-target? start trgt) FALSE]    
    [else (final-plan start trgt lob)]))
;; TESTS
(begin-for-test
  (check-equal?
   (path (list 1 1) (list 1 1) empty)
   empty)
  (check-equal?
   (path (list 1 1) (list 5 5) empty)
   (list (list "se" 4)))
  (check-equal?
   (path (list 2 5) (list 2 6) empty)
   #f)
  (check-equal?
   (path (list 2 5) (list 4 9) wall1)
   #f)
  (check-equal? 
   (path (list 2 5) (list 4 9) (rest wall1))
   WALL1-PATH)
  (check-equal?
   (path (list -3 6) (list 7 6) two-walls)
   TWO-WALLS-PATH))

;; eval-plan : Position ListOfPosition Plan ->  MaybePosition
;; GIVEN   :
;;           1. the starting position of the robot(start),
;;           2. A list of the blocks on the board(lob)
;;           3. A plan for the robot's motion(path)
;; RETURNS : The position of the robot at the end of executing the plan, 
;;           or false if the plan sends the robot to or through any block.
;; EXAMPLES: see tests below
;; STRATEGY: Divide into Cases on path emptiness, on empty case check if
;;           the next move of robot towards target would encounter a block
(define (eval-plan start lob path)
  (cond
    [(empty? path) start]
    [(boolean? path) path]
    [else
     (local
       ((define next (move-robot start (first path))))
       (if (my-member? next lob)
           FALSE
           (eval-plan next lob (rest path))))]))  
;; TESTS
(begin-for-test
  (check-equal?
   (eval-plan
    (list 0 0)
    (list (list 1 1))
    (path (list 0 0) (list 1 1) (list (list 1 1))))
   #f)
  (check-equal?
   (eval-plan
    (list 0 0)
    (list (list 1 1))
    (path (list 0 0) (list 1 1) (list (list "se" 1))))
   #f)
  (check-equal?
   (eval-plan
    (list 2 5)
    (rest wall1)
    (path (list 2 5) (list 4 9) (rest wall1)))
   (list 4 9))
  (check-equal?
   (eval-plan (list -3 6)
              two-walls
              (path (list -3 6) (list 7 6) two-walls))
   (list 7 6)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; LAYERS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; FINDING PATH

;; direct-traverse : Position Position -> ListOfPositions
;; GIVEN   : Starting (strt) and Target(trgt) position
;; RETURNS : A List of Positions which logs robot's movement
;;           from start to target.
;; EXAMPLES: see test below               
;; STRATEGY: Combining simpler functions
(define (direct-traverse strt trgt)
  (local
    ((define east? (>= (position-x trgt) (position-x strt)))
     (define south? (>= (position-y trgt) (position-y strt))))
    (make-robot-move strt trgt empty)))
;; TESTS
(begin-for-test
  (check-equal?
   (direct-traverse (list 0 0) (list 3 3))
   (list
    (list 0 0)
    (list 1 1)
    (list 2 2)
    (list 3 3)))
  (check-equal?
   (direct-traverse (list 3 4) (list 4 5))
   (list
    (list 3 4)
    (list 4 5))))

;; final-plan : Position Position ListOfPositions -> MaybePlan
;; GIVEN   :
;;           1. the starting position of the robot (start),
;;           2. the target position that robot is supposed to reach (trgt)
;;           3. A list of the blocks on the board (lob)
;; RETURNS : a plan that, when executed, will take the robot from the 
;;           starting position to the target position without passing over 
;;           any of the blocks, or false if no such sequence of moves exists.
;; EXAMPLES: see tests below              
;; STRATEGY: Combining simpler functions
(define (final-plan strt trgt lob)
  (make-plan
   (cond
     [(and (on-same-diagonal? strt trgt)
           (no-block? strt trgt lob))
      (direct-traverse strt trgt)]    
     [else (find-path strt trgt lob empty)])
   NULL-LIST))
;; TESTS
(begin-for-test
  (check-equal?
   (final-plan (list 0 0) (list 3 3) wall1)
   (list (list "se" 3)))
  (check-equal?
   (final-plan (list 2 5) (list 4 9) wall1)
   #f))

;; final-plan : Position ListOfPositions -> ListOfPositions
;; GIVEN   :
;;           1. the originating position of the robot (orig),
;;           2. A list of the blocks on the board (lob)
;; RETURNS : all the neighbors of orig that are accessible 
;;           in one unit move from given position without 
;;           hitting blocks in the given list of blocks.
;; EXAMPLES: see tests below              
;; STRATEGY: Combining simpler functions
(define (neighbors orig lob)
  (remove-all
   empty
   (list
    (if (bounded-member? orig NORTH EAST lob)
        (orig-move orig NORTH EAST) empty)
    (if (bounded-member? orig SOUTH EAST lob)
        (orig-move orig SOUTH EAST) empty)
    (if (bounded-member? orig NORTH WEST lob)
        (orig-move orig NORTH WEST) empty) 
    (if (bounded-member? orig SOUTH WEST lob)
        (orig-move orig SOUTH WEST) empty))))
;; TESTS
(begin-for-test
  (check-equal?
   (neighbors (list 0 0) empty)
   (list
    (list -1 1)
    (list 1 1)
    (list -1 -1)
    (list 1 -1)))
  (check-equal?
   (neighbors (list -4 1) wall1)
   (list
    (list -3 2)
    (list -3 0))))

;; bounded-member? : Position String String ListOfPosition -> Boolean
;; GIVEN   :
;;           1. the originating position of the robot (orig),
;;           2. Vertical direction (vert) value
;;           3. Horizontal direction (hori) value
;;           4. A list of the blocks on the board (lob)
;; RETURNS : true if list of blocks is empty or if orig is both within bounds
;;           and not hitting a block on its next move
;; EXAMPLES: see tests below              
;; STRATEGY: Divide into Cases on lob emptiness and then combine
;;           simpler functions on orig
(define (bounded-member? orig vert hori lob)
  (if (empty? lob) #t
      (and
       (in-bound? (orig-move orig vert hori) lob)
       (not (my-member? (orig-move orig vert hori) lob)))))
;; TESTS
(begin-for-test
  (check-true
   (bounded-member? (list -4 1) 1 1 wall1)))

;; find-path : Position Position ListOfPosition ListOfPosition -> MaybePlan
;; GIVEN   :
;;           1. The starting position (strt),
;;           2. The position of the target (trgt),
;;           3. A list of the blocks on the board (lob),
;;           4. A list of the squares already traversed (alrdy_trvrsd)
;; RETURNS : A path from start(strt) to target(trgt) OR
;;           returns #false if there is no such path
;; HALTING MEASURE : If next is already present in alrdy_trvrsed, then next is
;;           a halting measure else the program fails to stop.
;; TERMINATION ARGUMENT : Since at every recursive call, next contains the
;;           neighbors of a node and if those neighbours are already present
;;           in the invariant then function would cease to run since there
;;           are no more nodes to explore.
;; EXAMPLES: see tests below              
;; STRATEGY: Divide into Cases on equality of start and target, if not 
;;           then divide into cases on tmp_trgt being boolean or not
(define (find-path strt trgt lob alrdy_trvrsd)
  (cond
    [(set-equal? strt trgt) (list trgt)]
    [else (local ((define next
                    (set-diff (neighbors strt lob) alrdy_trvrsd))
                  (define tmp_trgt
                    (find-path/list next trgt lob
                                    (set-union next alrdy_trvrsd)))) 
            (cond
              [(boolean? tmp_trgt) FALSE] 
              [else (cons strt tmp_trgt)]))])) 
;; TESTS
(begin-for-test
  (check-equal?
   (find-path (list 0 0) (list 1 1) empty empty)
   (list
    (list 0 0)
    (list 1 1))))

; if there is no path, the function produces #false
;; find-path/list :
;;           ListOfPosition Position ListOfPosition ListOfPosition -> MaybePlan
;; GIVEN   :
;;           1. The list of starting positions (lon),
;;           2. The position of the target (trgt),
;;           3. A list of the blocks on the board (lob),
;;           4. A list of the squares already traversed (alrdy_trvrsd)
;; RETURNS : A path from a node in lon to given target (trgt) OR
;;           returns #false if there is no such path
;; EXAMPLES: see tests below              
;; STRATEGY: Divide into Cases on lob emptiness, target already present in the
;;           given list of starting positions, if not then divide into cases on
;;           tmp_trgt being boolean or not
(define (find-path/list lon trgt lob alrdy_trvrsd)
  (cond
    [(empty? lon) FALSE]
    [(my-member? trgt lon) (find-path trgt trgt lob alrdy_trvrsd)]
    [else (local ((define tmp_trgt
                    (find-path (first lon) trgt lob alrdy_trvrsd)))
            (cond
              [(boolean? tmp_trgt)
               (find-path/list (rest lon) trgt lob alrdy_trvrsd)]
              [else tmp_trgt]))]))
;; TESTS
(begin-for-test
  (check-equal?
   (find-path/list (list (list 0 0) (list 2 2)) (list 1 1) empty empty)
   (list
    (list 0 0)
    (list 1 1))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; MAKING PLANS

;; make-plan : MaybeListOfPosition Plan -> MaybePlan
;; GIVEN   :
;;           1. A list of the position of squares on the board (lob)
;;              representing trail of robot froms start to target,
;;              which can also be boolean if no such path exists
;;           2. A Plan as invariant which gets build up during program execution
;; RETURNS : A plan which takes robot from start to given target (trgt) OR
;;           returns #false if there is no such path
;; EXAMPLES: see tests below              
;; STRATEGY: Divide into Cases on whether lop is boolean or not 
(define (make-plan lop plan)
  (if (boolean? lop)
      lop
      (remove (list "null" 0)
              (make-valid-plan lop plan))))
;; TESTS
(begin-for-test
  (make-plan (list (list 0 0) (list 1 1)) NULL-LIST)
  (list (list "se" 1)))

;; make-valid-plan : MaybeListOfPosition Plan -> MaybePlan
;; GIVEN   :
;;           1. A list of the position of squares on the board (lob)
;;              representing trail of robot froms start to target,
;;              which can also be boolean if no such path exists
;;           2. A Plan as invariant which gets build up during program execution
;; RETURNS : A plan which takes robot from start to given target (trgt) OR
;;           returns #false if there is no such path
;; EXAMPLES: see tests below              
;; STRATEGY: Divide into Cases on whether length of lop is ONE or not
(define (make-valid-plan lop plan)
  (cond
    [(= (length lop) ONE) (reverse plan)]
    [else 
     (make-plan
      (rest lop)
      (sub-plan lop plan))]))
;; TESTS
(begin-for-test
  (make-valid-plan (list (list 0 0) (list 1 1)) NULL-LIST)
  (list (list "se" 1)))

;; sub-plan : MaybeListOfPosition Plan -> MaybePlan
;; GIVEN   :
;;           1. A list of the position of squares on the board (lob)
;;              representing trail of robot froms start to target,
;;              which can also be boolean if no such path exists
;;           2. A Plan as invariant which gets build up during program execution
;; RETURNS : A plan which takes robot from start to given target (trgt) OR
;;           returns #false if there is no such path
;; EXAMPLES: see tests below              
;; STRATEGY: Divide into Cases on whether length of lop is ONE or not
(define (sub-plan lop plan)
  (local
    ((define move-diagonal (make-path-1 (first lop) (second lop))))
    (if (equal? (move-direction move-diagonal)
                (move-direction (first plan)))
        (cons (make-move (move-direction (first plan))
                    (+ ONE (move-distance (first plan))))
              (rest plan))
        (cons move-diagonal plan))))
;; TESTS
(begin-for-test
  (check-equal?
   (sub-plan (list (list 0 0) (list 1 1)) NULL-LIST)
   (list
    (list "se" 1)
    (list "null" 0))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; HELPER FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; max-horizontal : Position ListOfPosition -> Position
;; min-horizontal : Position ListOfPosition -> Position
;; max-vertical : Position ListOfPosition -> Position
;; min-vertical : Position ListOfPosition -> Position
;; GIVEN   : The current max and a list of positions
;; WHERE   : current_max is an invariant compared with the list of positions
;;           and updated accordingly.
;; RETURNS : The maximum or minimum element in respective X and Y directions
;; EXAMPLES: see tests below              
;; STRATEGY: Divide into Cases on emptiness of lst, if empty then divide into
;;           cases comparing (first (first lst)) with (first current_max)
(define (max-horizontal current_max lst)
  (cond
    [(empty? lst) current_max]
    [else (if (> (first (first lst)) (first current_max))
              (max-horizontal (first lst) (rest lst))
              (max-horizontal current_max (rest lst)))])) 

(define (min-horizontal current_min lst) 
  (cond
    [(empty? lst) current_min]
    [else (if (< (first (first lst)) (first current_min))
              (min-horizontal (first lst) (rest lst))
              (min-horizontal current_min (rest lst)))]))

(define (max-vertical current_max lst)
  (cond
    [(empty? lst) current_max]
    [else (if (> (second (first lst)) (second current_max))
              (max-vertical (first lst) (rest lst))
              (max-vertical current_max (rest lst)))]))

(define (min-vertical current_min lst)
  (cond
    [(empty? lst) current_min]
    [else (if (< (second (first lst)) (second current_min))
              (min-vertical (first lst) (rest lst))
              (min-vertical current_min (rest lst)))]))
;; TESTS
(begin-for-test
  (check-equal?
   (max-horizontal (list -999999999 0) wall1)
  (list 4 3))
  (check-equal?
   (min-horizontal (list 1000000000 0) wall1)
  (list 0 3))
  (check-equal?
   (max-vertical (list 0 -999999999) wall1)
  (list 0 7))
  (check-equal?
   (min-vertical (list 0 1000000000) wall1)
  (list 0 3))) 

;; x-upper-bound : ListOfPosition -> Integer
;; x-lower-bound : ListOfPosition -> Integer
;; y-upper-bound : ListOfPosition -> Integer
;; y-lower-bound : ListOfPosition -> Integer
;; GIVEN   : a list of positions
;; RETURNS : The maximum or minimum X or Y in respective X and Y directions
;; EXAMPLES: see tests below              
;; STRATEGY: Combining Simpler Functions
(define (x-upper-bound lob)
  (+ (first (max-horizontal (list -999999999 0) lob)) OFFSET))
(define (x-lower-bound lob)
  (- (first (min-horizontal (list 1000000000 0) lob)) OFFSET))
(define (y-upper-bound lob)
  (+ (second (max-vertical (list 0 -999999999) lob)) OFFSET))
(define (y-lower-bound lob)
  (- (second (min-vertical (list 0 1000000000) lob)) OFFSET)) 
;; TESTS
(begin-for-test
  (check-equal?
   (x-upper-bound wall1)
   7)
  (check-equal?
   (x-lower-bound wall1)
   -3)
  (check-equal?
   (y-upper-bound wall1)
   10)
  (check-equal?
   (y-lower-bound wall1)
   0))

;; in-bound? : Position ListOfPosition -> Boolean
;; GIVEN   : a position and a list of positions
;; RETURNS : true iff given position is within respective X and Y directions
;; EXAMPLES: (in-bound? (list 0 0) wall1) = #true         
;; STRATEGY: Combining Simpler Functions
(define (in-bound? pos lob)
  (and
   (>= (x-upper-bound lob) (first pos))
   (<= (x-lower-bound lob) (first pos))
   (>= (y-upper-bound lob) (second pos))
   (<= (y-lower-bound lob) (second pos)))) 

;; orig-move : Position Integer Integer -> Boolean
;; GIVEN   : a position and two integers(x and y)
;; RETURNS : given position moved by given X and Y distances
;; EXAMPLES: (orig-move (list 0 0) 1 1) = (list 1 1)       
;; STRATEGY: Combining Simpler Functions
(define (orig-move orig x y)
  (list
   (+ (first orig) x)
   (+ (second orig) y)))

;; orig-move : Position Position -> Boolean
;; GIVEN   : two position (strt and trgt)
;; RETURNS : true iff target is reachable from strt
;; EXAMPLES: (orig-move (list 0 0) 1 1) = (list 1 1)       
;; STRATEGY: Combining Simpler Functions
(define (invalid-target? strt trgt)
  (not (even?
        (+ (- (position-x trgt) (position-x strt))
           (- (position-y trgt) (position-y strt))))))

;; on-same-diagonal? : Position Position -> Boolean
;; GIVEN   : two position (strt and trgt)
;; RETURNS : true iff target is reachable from strt
;; EXAMPLES: (on-same-diagonal? (list 0 0) 1 1) = #true
;; STRATEGY: Combining Simpler Functions
(define (on-same-diagonal? strt trgt)
  (=
   (abs (- (position-x trgt) (position-x strt)))
   (abs (- (position-y trgt) (position-y strt)))))

;; make-path-1 : Position Position -> Move
;; GIVEN    : Start Position and a Target position
;; RETURNS  : A Position with the given start moved by distance
;;            and direction inherent in given move
;; EXAMPLES : see tests below
;; STRATEGY : Combine Simpler Functions
(define (make-path-1 strt trgt)
  (local
    ((define east? (> (position-x trgt) (position-x strt)))
     (define south? (> (position-y trgt) (position-y strt))))
    (if (on-same-diagonal? strt trgt)
        (make-path-2 (abs (- (position-x trgt) (position-x strt))) east? south?)
        FALSE)))
(begin-for-test
  (check-equal?
   (make-path-1 (list 0 0) (list 5 5))
   (list "se" 5))
  (check-false (make-path-1 (list 0 0) (list 5 4))))

;; make-path-2 : Integer Boolean Boolean -> Move
;; GIVEN    : Start Position and a Target position
;; RETURNS  : A Move in the direction by the given distance
;; EXAMPLES : see tests below
;; STRATEGY : Divide into Cases on boolean value of east? south?
(define (make-path-2 dist east? south?)
  (cond
    [(and east? south?)
     (list "se" dist)]
    [(and east? (not south?))
     (list "ne" dist)]
    [(and (not east?) south?)
     (list "sw" dist)]
    [(and (not east?) (not south?))
     (list "nw" dist)]))
;; TESTS
(begin-for-test
  (check-equal?
   (make-path-2 5 #t #t)
   (list "se" 5)))

;; move-robot : Position Move -> Position
;; GIVEN    : Start Position and a move to be operated on Start
;; RETURNS  : A Position with the given start moved by distance
;;            and direction inherent in given move
;; EXAMPLES : (move-robot (list 0 0) (list "se" 5) = (list 5 5)
;; STRATEGY : Combine Simpler Functions
(define (move-robot strt move)
  (local
    ((define dist (move-distance move))
     (define x (position-x strt))
     (define y (position-y strt))
     (define dir (move-direction move)))
    (cond
      [(string=? dir "se")
       (list (+ x dist) (+ y dist))]
      [(string=? dir "ne")
       (list (+ x dist) (+ y (- dist)))]
      [(string=? dir "sw")
       (list (+ x (- dist)) (+ y dist))]
      [(string=? dir "nw")
       (list (+ x (- dist)) (+ y (- dist)))]))) 
;; TESTS
(begin-for-test
  (check-equal?
   (move-robot (list 0 0) (list "se" 5))
   (list 5 5)))

;; no-block? : Position Position ListOfPosition -> Boolean
;; GIVEN   : 
;; RETURNS : true iff there are no blocks b/w start and trgt
;; EXAMPLES: see tests below
;; STRATEGY: Combine Simpler Functions
(define (no-block? strt trgt lob)
  (not (is-move-blocked? strt trgt lob)))
;; TESTS
(begin-for-test
  (check-true
   (no-block? (list 0 0) (list 0 2) wall1))
  (check-false
   (no-block? (list 0 1) (list 3 4) (list (list 1 2)))))

;; is-move-blocked? : Position Position PosInt -> Boolean
;; GIVEN   : Start(strt) and Target(trgt) position,
;;           a list of positions(path)
;; RETURNS : true iff robot's path from start to target is blocked
;; EXAMPLES: see tests below
;; STRATEGY: Divide into Cases on equality of strt and trgt and then check 
;;           if on moving in trgt's direction would encounter a block
(define (is-move-blocked? strt trgt lob)
  (local
    ((define dir-x (if (> (position-x trgt) (position-x strt)) ONE -1))
     (define dir-y (if (> (position-y trgt) (position-y strt)) ONE -1))
     (define next (list (+ (position-x strt) dir-x)
                        (+ (position-y strt) dir-y))))
    (cond
      [(equal? strt trgt) #f]
      [else (if (my-member? next lob)
                #t
                (is-move-blocked? next trgt lob))])))
;; TESTS
(begin-for-test
  (check-false
   (is-move-blocked? (list 0 0) (list 0 2) wall1))
  (check-true
   (is-move-blocked? (list 0 1) (list 3 4) (list (list 1 2)))))

;; make-robot-move : Position Position ListOfPosition -> ListOfPosition
;; GIVEN   : Start(strt) and Target(trgt) position and a list of positions(path)
;; WHERE   : path is an invariant which gets updated along the
;;           course of program run.
;; RETURNS : A List of Positions which logs robot's movement
;;           from start to target.
;; EXAMPLES: see test below               
;; STRATEGY: Divide into Cases on equality of strt and trgt
(define (make-robot-move strt trgt path)
  (local
    ((define dir-x (if (> (position-x trgt) (position-x strt)) ONE -1))
     (define dir-y (if (> (position-y trgt) (position-y strt)) ONE -1))
     (define next (make-position (+ (position-x strt) dir-x)
                                 (+ (position-y strt) dir-y))))
    (cond
      [(equal? strt trgt) (reverse (cons trgt path))]
      [else (make-robot-move
             next
             trgt
             (cons strt path))])))
;; TEST
(begin-for-test
  (check-equal?
   (make-robot-move (list 0 0) (list 2 2) empty)
   (list
    (list 0 0)
    (list 1 1)
    (list 2 2))))

;;; END
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; TESTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



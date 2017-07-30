;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-intermediate-lambda-reader.ss" "lang")((modname trees) (read-case-sensitive #t) (teachpacks ((lib "image.rkt" "teachpack" "2htdp") (lib "universe.rkt" "teachpack" "2htdp"))) (htdp-settings #(#t constructor repeating-decimal #f #t none #f ((lib "image.rkt" "teachpack" "2htdp") (lib "universe.rkt" "teachpack" "2htdp")) #f)))
;; trees.rkt : First and Only Question of Problem Set 06. 

;; GOAL: Create a program to manipulate trees on a canvas.

;; INSTRUCTIONS:
;   start with (run 0.5)
;   Hitting "t" at any time creates a new root node.
;   Hitting "n" while a node is selected adds a new son.
;   Hitting "d" while a node is selected deletes the node
;    and its whole subtree.
;   Hitting "l" any time (whether a node is selected or not)
;    deletes every node whose center is in the left half of the canvas.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; LIBRARY
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(require rackunit)
(require "extras.rkt")
(check-location "06" "trees.rkt") 
(require 2htdp/image)
(require 2htdp/universe)
(provide run
         tree-to-root
         tree-to-sons
         initial-world
         world-to-trees
         node-to-center
         node-to-selected?       
         world-after-key-event
         world-after-mouse-event) 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; MAIN FUNCTION
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; run     : Any -> World
;; GIVEN   : any value
;; EFFECT  : runs a copy of an initial world
;; RETURNS : the final state of the world. The given value is ignored.
;; USAGE   : (run 0.5)
;; STRATEGY: Combining Simpler Functions
(define (run seconds-per-tick)
  (big-bang (initial-world seconds-per-tick)
            (on-draw world-to-scene)
            (on-key world-after-key-event)
            (on-mouse world-after-mouse-event))) 


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; CONSTANTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; dimensions of the canvas
(define CANVAS-WIDTH 500)
(define HALF-CANVAS-WIDTH (/ CANVAS-WIDTH 2))
(define CANVAS-HEIGHT 400)
(define HALF-CANVAS-HEIGHT (/ CANVAS-HEIGHT 2))
(define EMPTY-CANVAS (empty-scene CANVAS-WIDTH CANVAS-HEIGHT))

;; dimensions of the node
(define NODE-RADIUS 10)
(define NORMAL-MODE "outline")
(define SELECTED-MODE "solid")
(define NODE-COLOR "green")
(define NODE (circle NODE-RADIUS NORMAL-MODE NODE-COLOR))
(define NEW-NODE-OFFSET (* 3 NODE-RADIUS))

;; Node-connecting line color
(define LINE-COLOR "blue")

;; KeyEvents
(define ADD-NEW-NODE-KEY-EVENT "t")
(define ADD-NEW-SON-KEY-EVENT "n")
(define DELETE-NODE-KEY-EVENT "d")
(define DELETE-LEFT-NODE-KEY-EVENT "l")
(define OTHER-KEY-EVENT "\b")

;; MouseEvents
(define BUTTON-DOWN-EVENT "button-down")
(define DRAG-EVENT "drag")
(define BUTTON-UP-EVENT "button-up")
(define OTHER-MOUSE-EVENT "enter")

;; Numerical Constants
(define ZERO 0)
(define ONE 1)
(define TWO 2)
(define THREE (+ ONE TWO))
(define FOUR (+ TWO TWO))
(define NEG-THREE (- THREE))
(define FORTY (* FOUR 10))
(define THIRTY (* THREE 10))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DATA DEFINITIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-struct root (location selected? offset))
;; A Root is a
;; (make-root Posn Boolean Posn)
;; INTERP:
;; location  gives the respective X&Y position of the center of root.
;; selected? gives status of tree in true/false being selected by
;            mouse button press.
;; offset    gives the respective X&Y offset of the selected position
;;           from the center of the root.
;; TEMPLATE:
;; root-fn : root -> ??
#|
(define (root-fn n)
 (... (root-location n)
      (root-selected? n)      
      (root-offset n)))
|#
;; EXAMPLES:
(define NODE-ON-INITIAL-WORLD
  (make-root (make-posn HALF-CANVAS-WIDTH (- FORTY THIRTY))
             false
             (make-posn ZERO ZERO)))
(define NODE-2
  (make-root (make-posn (- CANVAS-WIDTH (* TWO THREE))
                        (+ (* THREE THIRTY) (- FORTY THIRTY)))
             false
             (make-posn (- ONE) THREE)))
(define NODE-3
  (make-root (make-posn HALF-CANVAS-WIDTH FORTY)
             false
             (make-posn (- ONE) FORTY)))
(define NODE-4
  (make-root (make-posn (- HALF-CANVAS-HEIGHT THREE) FORTY)
             false
             (make-posn
              (- (+ (* (- FORTY THIRTY)(- FORTY THIRTY)) FOUR))
              FORTY)))
(define CHILD-NODE-1
  (make-root (make-posn HALF-CANVAS-WIDTH FORTY)
             false
             (make-posn ZERO THIRTY)))
(define NODE-ON-INITIAL-WORLD-SLCTD
  (make-root (make-posn HALF-CANVAS-WIDTH (- FORTY THIRTY))
             true
             (make-posn ZERO ZERO)))
(define NODE-AFTER-SLCTD-DRAG
  (make-root (make-posn HALF-CANVAS-WIDTH (- FORTY THIRTY))
             true
             (make-posn NEG-THREE NEG-THREE)))
(define CHILD-NODE-1-AFTER-SLCTD-DRAG
  (make-root (make-posn HALF-CANVAS-WIDTH FORTY)
             false
             (make-posn NEG-THREE (- THIRTY THREE))))
(define CHILD-NODE-1-SLCTD
  (make-root (make-posn HALF-CANVAS-WIDTH FORTY)
             true
             (make-posn ZERO THIRTY)))
(define CHILD-NODE-1-1
  (make-root (make-posn HALF-CANVAS-WIDTH (+ FORTY THIRTY))
             false
             (make-posn ZERO (* TWO THIRTY))))

(define-struct tree (root sons))
;; A Tree is a
;; (make-tree root ListOfTrees)
;; INTERP:
;; root    is the parent root of its sons in its list, sons
;; sons    is a ListOfTrees under the root.
;; TEMPLATE:
;; tree-fn : Tree -> ??
#|
(define (tree-fn t)
 (... (tree-root t)
      (tree-sons t)))
|#
;; EXAMPLES:
(define TREE-IN-INITIAL-WORLD
  (make-tree NODE-ON-INITIAL-WORLD empty))
(define TREE-2
  (make-tree NODE-ON-INITIAL-WORLD (list NODE-2 NODE-3 NODE-4)))

;; A ListOfTrees (LOT) is one of:
;; -- empty
;; -- (cons Tree ListOfTrees)
;; TEMPLATE:
;; LOT-fn : ListOfTrees -> ??
#|
(define (LOT-fn lst)
 (cond
  [(empty? lst) ...]
  [else (... (tree-fn (first lst))
             (LOT-fn (rest lst)))]))
|# 
;; EXAMPLES:
(define TREE-LIST-1 empty)
(define TREE-LIST-2 (list TREE-IN-INITIAL-WORLD))
(define TREE-LIST-3 (list TREE-2))

(define-struct world (trees))
;; A World is a
;; (make-world ListOfTrees)
;; INTERP:
;; trees is a list all the trees present in the world. 
;; TEMPLATE:
;; world-fn : World -> ??
#|(define (world-fn w)
   (... (world-trees w))
|#
;; EXAMPLES of trees for TESTS
(define INITIAL-WORLD
  (make-world empty))

(define INITIAL-WORLD-TREE
  (make-tree (make-root
              (make-posn HALF-CANVAS-WIDTH NODE-RADIUS)
              false
              (make-posn ZERO ZERO))
             empty))

(define INITIAL-WORLD-TREE-CHILD
  (make-tree (make-root
              (make-posn HALF-CANVAS-WIDTH NODE-RADIUS)
              false
              (make-posn ZERO ZERO))
             (list TREE-IN-INITIAL-WORLD)))

(define INITIAL-WORLD-WITH-TREE 
  (make-world (list INITIAL-WORLD-TREE)))

(define INITIAL-WORLD-TREE-ROOT (tree-root INITIAL-WORLD-TREE))

(define WORLD-AFTER-T-KEY-PRESS
  (make-world TREE-LIST-2))
(define WORLD-AFTER-L-KEY-PRESS
  (make-world
   (list
    (make-tree NODE-ON-INITIAL-WORLD
               (list
                (make-tree CHILD-NODE-1 empty))))))
(define FIRST-NODE-ON-INITIAL-WORLD
  (make-world (list
               (make-tree NODE-ON-INITIAL-WORLD-SLCTD empty))))
(define WORLD-AFTER-N-KEY-PRESS
  (make-world
   (list
    (make-tree NODE-ON-INITIAL-WORLD-SLCTD
               (list
                (make-tree CHILD-NODE-1 empty))))))
(define WORLD-AFTER-BUTTON-DOWN
  (make-world
   (list
    (make-tree NODE-AFTER-SLCTD-DRAG
               (list
                (make-tree CHILD-NODE-1-AFTER-SLCTD-DRAG empty))))))
(define WORLD-BEFORE-N-KEY-ON-CHILD
  (make-world
   (list
    (make-tree NODE-ON-INITIAL-WORLD
               (list
                (make-tree CHILD-NODE-1-SLCTD empty))))))
(define WORLD-AFTER-N-KEY-ON-CHILD
  (make-world
   (list
    (make-tree NODE-ON-INITIAL-WORLD
               (list
                (make-tree CHILD-NODE-1-SLCTD
                           (list
                            (make-tree CHILD-NODE-1-1 empty))))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; HELPER FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; root-x  : root -> Integer
;; root-y  : root -> Integer
;; GIVEN   : a root
;; RETURNS : posn-x/posn-y of the
;;           root-location from the given root.
;; EXAMPLES: see tests below
;; STRATEGY: Use Template of Root on root 
(define (root-x root)
  (posn-x (root-location root)))
(define (root-y root)
  (posn-y (root-location root)))
;; TESTS
#;(begin-for-test
  (check-equal? (root-x NODE-ON-INITIAL-WORLD)
                HALF-CANVAS-WIDTH
                "Should return the posn-x of the node-location")
  (check-equal? (root-y NODE-ON-INITIAL-WORLD)
                (- FORTY THIRTY)
                "Should return the posn-y of the node-location"))

;; root-offset-x  : root -> Integer
;; root-offset-y  : root -> Integer
;; GIVEN          : a root
;; RETURNS        : posn-x/posn-y of the
;;                  root-offset from the given root.
;; EXAMPLES       : see tests below
;; STRATEGY       : Use Template of Root on root 
(define (root-offset-x root)
  (posn-x (root-offset root)))
(define (root-offset-y root)
  (posn-y (root-offset root)))
;; TESTS
#;(begin-for-test
  (check-equal? (root-offset-x NODE-ON-INITIAL-WORLD) 
                ZERO
                "Should return the posn-x of the node-location")
  (check-equal? (root-offset-y NODE-ON-INITIAL-WORLD)
                ZERO
                "Should return the posn-y of the node-location"))

;; tree-to-root : Tree -> Root
;; GIVEN        : a tree
;; RETURNS      : the root of the tree
;; EXAMPLES     : see tests below
;; STRATEGY     : Use Template of Tree on tree
(define (tree-to-root tree)
  (tree-root tree))
;; TESTS
#;(begin-for-test
  (check-equal? (tree-to-root TREE-2)
                NODE-ON-INITIAL-WORLD
                "Should return the root node of the given subtree"))

;; tree-to-sons : Tree -> ListOfTree
;; GIVEN        : a tree
;; RETURNS      : the sons of the tree
;; EXAMPLES     : see tests below
;; STRATEGY     : Use Template of Tree on tree
(define (tree-to-sons tree)
  (tree-sons tree))
;; TESTS
#;(begin-for-test
  (check-equal? (tree-to-sons TREE-2)
                (list NODE-2 NODE-3 NODE-4)
                "Should return the sons of the tree passed"))

;; node-to-center : Root -> Posn
;; GIVEN          : a root
;; RETURNS        : the center of the given root as it is to be 
;;                  displayed on the scene.
;; EXAMPLES       : see tests below
;; STRATEGY       : Use Template of Root on root
(define (node-to-center node)
  (root-location node))
;; TESTS
#;(begin-for-test
  (check-equal? (node-to-center NODE-ON-INITIAL-WORLD)
                (make-posn HALF-CANVAS-WIDTH (- FORTY THIRTY))
                "Should return the location of the center of the node"))

;; node-to-selected? : Root -> Boolean
;; GIVEN   : a Root (root)
;; RETURNS : returns the value of selected? of the given root
;; EXAMPLES: see tests below
;; STRATEGY: Use Template of Root on root
(define (node-to-selected? root)
  (root-selected? root))
;; TESTS
#;(begin-for-test
  (check-equal?
   (node-to-selected? NODE-ON-INITIAL-WORLD)
   (root-selected? NODE-ON-INITIAL-WORLD)
   "Should return the selected? field from the data field
    of the given root."))

;; world-to-trees : World -> ListOTrees
;; GIVEN          : a World
;; RETURNS        : THE list of all the trees in the given world.
;; EXAMPLES       : see tests below
;; STRATEGY       : Combining simpler functions
(define (world-to-trees w)
  (world-trees w))
;; TESTS:
#;(begin-for-test
  (check-equal? (world-to-trees INITIAL-WORLD)
                '()
                "Should return the list of trees in the given world"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; initial-world
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; initial-world : Any -> WorldState
;; GIVEN         : any value (ignored)
;; RETURNS       : the initial world specified in the problem set
;; EXAMPLES      : see tests below
;; STRATEGY      : Combine Simpler Functions of World on w
(define (initial-world any) 
  (make-world empty)) 
;; TESTS
#;(begin-for-test
  (check-equal? (initial-world 0.5)
                INITIAL-WORLD
                "Should return the initial-world as specified in the problem"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; world-to-scene
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define IMAGE-OF-WORLD-AFTER-N-KEY-ON-CHILD
  (place-image (circle NODE-RADIUS
                       NORMAL-MODE
                       NODE-COLOR)
               HALF-CANVAS-WIDTH
               (- FORTY THIRTY)
               (scene+line
                (place-image (circle NODE-RADIUS
                                     SELECTED-MODE
                                     NODE-COLOR)
                             HALF-CANVAS-WIDTH
                             FORTY
                             (scene+line
                              (place-image (circle NODE-RADIUS
                                                   NORMAL-MODE
                                                   NODE-COLOR)
                                           HALF-CANVAS-WIDTH
                                           (+ FORTY THIRTY)
                                           EMPTY-CANVAS)
                              HALF-CANVAS-WIDTH FORTY
                              HALF-CANVAS-WIDTH (+ FORTY THIRTY)
                              LINE-COLOR))
                HALF-CANVAS-WIDTH (- FORTY THIRTY)
                HALF-CANVAS-WIDTH FORTY
                LINE-COLOR)))

;; world-to-scene : World -> Scene
;; GIVEN          : a World
;; RETURNS        : a scene with list of all the trees in the given world.
;; EXAMPLES       : see tests below
;; STRATEGY       : Combining simpler functions
(define (world-to-scene w)
  (place-trees (world-trees w)))
;; TESTS
#;(begin-for-test
  (check-equal? (world-to-scene WORLD-AFTER-N-KEY-ON-CHILD)
                (place-trees (world-trees WORLD-AFTER-N-KEY-ON-CHILD))
                "Should return a scene for the passed world w")
  (check-equal? (world-to-scene WORLD-AFTER-N-KEY-ON-CHILD)
                IMAGE-OF-WORLD-AFTER-N-KEY-ON-CHILD
                "Should return a scene for the passed world w"))

;; place-trees : ListOfTrees -> Scene
;; GIVEN   : a ListOfTrees(LOT)
;; RETURNS : a Scene with the GIVEN ListOfTrees
;;           placed on an EMPTY-CANVAS.
;; EXAMPLES: see tests below
;; STRATEGY: Using HOF foldr on LOT
(define (place-trees LOT) 
  (foldr place-tree
         EMPTY-CANVAS
         LOT))   
;; TESTS
#;(begin-for-test
  (check-equal?
   (place-trees (world-trees WORLD-AFTER-N-KEY-ON-CHILD))
   (foldr place-tree EMPTY-CANVAS (world-trees WORLD-AFTER-N-KEY-ON-CHILD))
   "Should return a Scene with the GIVEN ListOfTrees placed on an empty scene"))

;; place-tree : Tree Scene -> Scene
;; GIVEN   : a Tree(tree) and a Scene(scene)
;; RETURNS : A Scene with the GIVEN Tree or a SELECTED-TREE
;;           if the passed mouse coordinates co-incident with
;;           the offset of the Tree on the the given scene.
;; EXAMPLES: see tests below
;; STRATEGY: Combining Simpler Functions and Using Template of Tree on tree
(define (place-tree tree scene)
  (place-image
   (tree-image
    (selected-mode (root-selected? (tree-root tree)))) 
   (root-x (tree-root tree))
   (root-y (tree-root tree))
   (place-child-tree tree scene)))              
;; TESTS
#;(begin-for-test
  (check-equal?
   (place-tree TREE-IN-INITIAL-WORLD EMPTY-CANVAS)
   (place-image
    (tree-image
     (selected-mode (root-selected? (tree-root TREE-IN-INITIAL-WORLD)))) 
    (root-x (tree-root TREE-IN-INITIAL-WORLD))
    (root-y (tree-root TREE-IN-INITIAL-WORLD))
    (place-child-tree TREE-IN-INITIAL-WORLD EMPTY-CANVAS))
   "Should return a scene with given tree place on the scene"))

;; place-child-tree : Tree Scene -> Scene
;; GIVEN   : a Tree(tree) and a Scene(scene)
;; RETURNS : A Scene with the GIVEN Tree or a SELECTED-TREE
;;           if the passed mouse coordinates are co-incident with
;;           the offset of the Tree on the the given scene.
;; EXAMPLES: see tests below
;; STRATEGY: Using HOF foldr on (tree-sons tree)
(define (place-child-tree tree scene)
  (foldr
   ;; Tree Scene -> Scene
   (lambda (t scene)
     (place-line
      (root-x (tree-root tree))
      (root-y (tree-root tree)) 
      t
      scene))
   scene (tree-sons tree)))
;; TESTS
#;(begin-for-test
  (check-equal?
   (place-child-tree INITIAL-WORLD-TREE-CHILD EMPTY-CANVAS)
   (foldr (lambda (TREE-IN-INITIAL-WORLD scene)
            (place-line
             (root-x (tree-root INITIAL-WORLD-TREE-CHILD))
             (root-y (tree-root INITIAL-WORLD-TREE-CHILD)) 
             TREE-IN-INITIAL-WORLD
             scene))
          EMPTY-CANVAS (tree-sons INITIAL-WORLD-TREE-CHILD))
   "Should return the a scene consisting of child trees drawn on canvas."))

;; place-line : Integer Integer Tree Scene -> Scene
;; GIVEN   : the posn-x and posn-y of the parent root, the child Tree root,
;;           and the Scene
;; RETURNS : the scene followed after connecting the parent root with its
;;           child roots by a blue-colored line
;; EXAMPLES: see tests below
;; STRATEGY: Combining Simpler Functions and Using Template of Tree on tree
(define (place-line x y tree scene)
  (scene+line
   (place-tree tree scene)
   x y 
   (root-x (tree-root tree))
   (root-y (tree-root tree))
   LINE-COLOR))
;; TESTS
#;(begin-for-test
  (check-equal?
   (place-line HALF-CANVAS-WIDTH
               NODE-RADIUS
               INITIAL-WORLD-TREE
               EMPTY-CANVAS)
   (scene+line (place-tree INITIAL-WORLD-TREE EMPTY-CANVAS)
               HALF-CANVAS-WIDTH NODE-RADIUS
               (root-x (tree-root INITIAL-WORLD-TREE))
               (root-y (tree-root INITIAL-WORLD-TREE))
               LINE-COLOR)
   "Should return a blue line connecting parent node and son."))

;; tree-image : String -> Image
;; GIVEN   : A mode
;; RETURNS : Image of an Tree with the GIVEN mode
;; WHERE   :
;;  mode   : NORMAL-COLOR, selected mode is "outline"
;;           SELECTED-COLOR, selected mode is "solid"
;; EXAMPLES: see tests below
;; STRATEGY: Combining Simpler Functions
(define (tree-image mode)
  (circle NODE-RADIUS
          mode
          NODE-COLOR)) 
;; TESTS
#;(begin-for-test
  (check-equal?
   (tree-image SELECTED-MODE)
   (circle NODE-RADIUS SELECTED-MODE NODE-COLOR)
   "Should return a solid green circle with radius 10"))

;; selected-mode : Boolean -> String
;; GIVEN   : A flag true iff the root is selected by the mouse
;; RETURNS : mode of the tree based on flag value
;; INTERP  :
;;  flag   : False, selected mode is NORMAL-COLOR
;;           True, selected mode is SELECTED-COLOR
;; EXAMPLES: see tests below
;; STRATEGY: Divinding into cases on flag
(define (selected-mode flag)
  (if flag
      SELECTED-MODE
      NORMAL-MODE))
;; TESTS
#;(begin-for-test
  (check-equal?
   (selected-mode true)
   SELECTED-MODE
   "Should return 'solid'")
  (check-equal?
   (selected-mode false)
   NORMAL-MODE
   "Should return 'outline'"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; world-after-key-event
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; world-after-key-event : WorldState KeyEvent -> WorldState
;; GIVEN   : a WorldState(w) and a KeyEvent(kev).
;; RETURNS : the world that should follow the given world
;;           after the given key event.
;;           on t key press, adds new tree to world
;;           on n key press on a selected node, adds new son
;;           on d key press on a selected node, deletes that node and
;;                                              its subtree
;;           on l key press, the nodes in the left side of the canvas
;;                           and all its subtree irrespective of their
;;                           position in the canvas are deleted
;; EXAMPLES: see tests below
;; STRATEGY: Divide into cases on KeyEvent kev  
(define (world-after-key-event w kev)
  (cond
    [(key=? kev ADD-NEW-NODE-KEY-EVENT) (add-tree-to-world w)]
    [(key=? kev ADD-NEW-SON-KEY-EVENT) (add-new-son w)]
    [(key=? kev DELETE-NODE-KEY-EVENT) (delete-sons w)]
    [(key=? kev DELETE-LEFT-NODE-KEY-EVENT) (delete-left-trees w)]
    [else w]))
;; TESTS
#;(begin-for-test
  (check-equal? (world-after-key-event INITIAL-WORLD
                                       ADD-NEW-NODE-KEY-EVENT)
                WORLD-AFTER-T-KEY-PRESS
                "Should return world after t key press")
  (check-equal? (world-after-key-event FIRST-NODE-ON-INITIAL-WORLD
                                       ADD-NEW-SON-KEY-EVENT)
                WORLD-AFTER-N-KEY-PRESS
                "Should return world after n key press")
  (check-equal? (world-after-key-event WORLD-AFTER-N-KEY-PRESS
                                       DELETE-NODE-KEY-EVENT)
                INITIAL-WORLD
                "Should return world after d key press")
  (check-equal? (world-after-key-event WORLD-AFTER-L-KEY-PRESS
                                       DELETE-LEFT-NODE-KEY-EVENT)
                (make-world
                 (list
                  (make-tree NODE-ON-INITIAL-WORLD
                             (list
                              (make-tree CHILD-NODE-1
                                         empty)))))
                "Should return world after l key press")
  (check-equal? (world-after-key-event WORLD-AFTER-N-KEY-PRESS
                                       OTHER-KEY-EVENT)
                WORLD-AFTER-N-KEY-PRESS
                "Should return the same world after an unspecified key press")
  (check-equal? (world-after-key-event WORLD-BEFORE-N-KEY-ON-CHILD
                                       ADD-NEW-SON-KEY-EVENT)
                WORLD-AFTER-N-KEY-ON-CHILD
                "Should return world after n key press"))

;; add-tree-to-world : WorldState -> WorldState
;; GIVEN   : a WorldState(w)
;; RETURNS : a WorldState(w) like the given one with a new
;;           tree added to it at the topmost center of the scene.
;; EXAMPLES: see tests below
;; STRATEGY: Use Template of World on w
(define (add-tree-to-world w)
  (make-world
   (cons
    (new-tree ZERO)
    (world-trees w))))
;; TESTS
#;(begin-for-test
  (check-equal?
   (add-tree-to-world INITIAL-WORLD)
   (make-world
    (cons
     (new-tree ZERO)
     (world-trees INITIAL-WORLD)))
   "Add a new tree to the world scene"))

;; new-tree : Integer -> Tree
;; GIVEN   : an integer value, which will be ignored
;; RETURNS : a new Tree that will be added at the topmost center
;;           part of the scene with the given offset
;; EXAMPLES: see tests below
;; STRATEGY: Combining simpler functions of Tree on tree
(define (new-tree zero)
  INITIAL-WORLD-TREE)
;; TESTS
#;(begin-for-test
  (check-equal?
   (new-tree ZERO)
   INITIAL-WORLD-TREE
   "Return a new tree"))

;; add-new-son : WorldState -> WorldState
;; GIVEN   : a WorldState(w)
;; RETURNS : a new WorldState(w) like the given one with
;;           the child nodes added to the selected node.
;; EXAMPLES: see tests below
;; STRATEGY: Use Template of World on w
(define (add-new-son w)
  (make-world
   (added-sons-in-trees (world-trees w))))
;; TESTS 
#;(begin-for-test
  (check-equal?
   (add-new-son INITIAL-WORLD)
   (make-world
    (added-sons-in-trees (world-trees INITIAL-WORLD)))
   "Return a new worldstate with the child node added to the
     tree.")) 

;; added-sons-in-trees : ListOfTrees -> ListOfTrees
;; GIVEN   : a ListOfTrees (lot)
;; RETURNS : a new ListOfTrees (lot) with the added child
;;           nodes to the respective selected parent node.
;; EXAMPLES: see tests below
;; STRATEGY: Using HOF map on lot
(define (added-sons-in-trees lot)
  (map
   ;; Tree -> Tree
   (lambda (tree) (added-sons-in-tree tree))
   lot))
;; TESTS
#;(begin-for-test
  (check-equal?
   (added-sons-in-trees (world-trees WORLD-AFTER-N-KEY-ON-CHILD))
   (map
    (lambda (tree) (added-sons-in-tree tree))
    (world-trees WORLD-AFTER-N-KEY-ON-CHILD))
   "Should return a list of tree rest of
    the sons added in the tree"))

;; added-sons-in-tree : Tree -> Tree
;; GIVEN   : a Tree, tree
;; RETURNS : a new Tree if selected will have a child 
;;           node added to its list of child nodes.
;; EXAMPLES: see tests below
;; STRATEGY: Use Template of Tree on tree
(define (added-sons-in-tree tree) 
  (make-tree (tree-root tree)
             (if (root-selected? (tree-root tree))
                 (cons (new-son tree)
                       (added-sons-in-trees (tree-sons tree)))
                 (added-sons-in-trees (tree-sons tree)))))  
;; TESTS
(define INITIAL-WORLD-TREE-SELECTED
  (make-tree NODE-ON-INITIAL-WORLD-SLCTD (list INITIAL-WORLD-TREE)))
#;(begin-for-test 
  (check-equal?
   (added-sons-in-tree INITIAL-WORLD-TREE)
   (make-tree (tree-root INITIAL-WORLD-TREE)
              (added-sons-in-trees (tree-sons INITIAL-WORLD-TREE)))
   "Should return a new tree added to the previous list of trees")
  (check-equal?
   (added-sons-in-tree INITIAL-WORLD-TREE-SELECTED)
   (make-tree (tree-root INITIAL-WORLD-TREE-SELECTED) 
              (cons (new-son INITIAL-WORLD-TREE-SELECTED)
                    (added-sons-in-trees
                     (tree-sons INITIAL-WORLD-TREE-SELECTED)))) 
   "Should return a new tree added to the previous list of trees")) 

;; new-son : Tree -> Tree
;; GIVEN   : a Tree, tree
;; RETURNS : a new Tree of the child node with it's location and offset
;;           relative to the max of the rightmost son as per the given
;;           requirement
;; EXAMPLES: see tests below
;; STRATEGY: Combining simpler functions
(define (new-son tree)
  (make-tree
   (make-root (new-son-location tree)
              false
              (new-son-offset tree))    
   empty))
;; TESTS
#;(begin-for-test
  (check-equal?
   (new-son TREE-IN-INITIAL-WORLD)
   (make-tree
    (make-root (new-son-location TREE-IN-INITIAL-WORLD)
               false
               (new-son-offset TREE-IN-INITIAL-WORLD))    
    empty)
   "Should return a new Tree with the updated data node of the new son."))

;; new-son-location : Tree -> Posn
;; GIVEN   : a Tree, tree
;; RETURNS : a new relative location of the root
;; EXAMPLES: see tests below
;; STRATEGY: Combining simpler functions
(define (new-son-location tree)
  (make-posn (+ (rightmost-son-location-x tree)
                NEW-NODE-OFFSET)
             (+ (root-y (tree-root tree))
                NEW-NODE-OFFSET))) 
;; TESTS
#;(begin-for-test
  (check-equal?
   (new-son-location TREE-IN-INITIAL-WORLD)
   (make-posn (+ (rightmost-son-location-x TREE-IN-INITIAL-WORLD)
                 NEW-NODE-OFFSET)
              (+ (root-y (tree-root TREE-IN-INITIAL-WORLD))
                 NEW-NODE-OFFSET))
   "Should return the new location of the node with the
    offsets to the current location of the parent."))

;; new-son-offset : Tree -> Posn
;; GIVEN   : a Tree, tree
;; RETURNS : a new relative offset of the root
;; EXAMPLES: see tests below
;; STRATEGY: Combining simpler functions
(define (new-son-offset tree)
  (make-posn
   (+ (- (rightmost-son-location-x tree) (root-x (tree-root tree)))
      (root-offset-x (tree-root tree))
      NEW-NODE-OFFSET)  
   (+ (root-offset-y (tree-root tree))
      NEW-NODE-OFFSET)))
;; TESTS
#;(begin-for-test
  (check-equal?
   (new-son-offset TREE-IN-INITIAL-WORLD)
   (make-posn
    (+ (- (rightmost-son-location-x TREE-IN-INITIAL-WORLD)
          (root-x (tree-root TREE-IN-INITIAL-WORLD)))
       (root-offset-x (tree-root TREE-IN-INITIAL-WORLD))
       NEW-NODE-OFFSET)  
    (+ (root-offset-y (tree-root TREE-IN-INITIAL-WORLD))
       NEW-NODE-OFFSET))
   "Should return the new offset of the node with the
    updated offsets to the current parent."))

;; rightmost-son-location-x : Tree -> Integer
;; GIVEN   : a Tree(tree)
;; RETURNS : the x-coordinate of the rightmost son
;;           of the Tree, tree
;; EXAMPLES: see tests below
;; STRATEGY: Using HOF foldr on (tree-sons tree)
(define (rightmost-son-location-x tree)
  (foldr
   compare-child-location-x
   (- (root-x (tree-root tree)) NEW-NODE-OFFSET)
   (tree-sons tree))) 
;; TESTS
#;(begin-for-test
  (check-equal?
   (rightmost-son-location-x TREE-IN-INITIAL-WORLD)
   (foldr
    compare-child-location-x
    (- (root-x (tree-root TREE-IN-INITIAL-WORLD)) NEW-NODE-OFFSET)
    (tree-sons TREE-IN-INITIAL-WORLD))
   "Should return the x postion to the rightmost
    child of the tree."))

;; compare-child-location-x : Tree Integer -> Integer
;; GIVEN   : a tree and offset
;; RETURNS : maximum x-co-ordinate of the rightmost child-root of
;;           the Tree, tree
;; EXAMPLES: see tests below
;; STRATEGY: Divide into cases and Use Template of Tree on tree
(define (compare-child-location-x tree current-max)
  (if (> (root-x (tree-root tree)) current-max)
      (root-x (tree-root tree))
      current-max))  
;; TESTS
#;(begin-for-test
  (check-equal? (compare-child-location-x TREE-IN-INITIAL-WORLD 220)
                HALF-CANVAS-WIDTH
                "Should return the maximum x-co-ordinate of the rightmost
                 child-node of the tree")
  (check-equal? (compare-child-location-x TREE-2 324)
                324
                "Should return the maximum x-co-ordinate of the rightmost
                 child-node of the tree"))

;; root-to-selected? : Tree -> Boolean
;; GIVEN   : a Tree (tree)
;; RETURNS : returns the value of selected? of the given tree
;; EXAMPLES: see tests below
;; STRATEGY: Use Template of Tree on tree
(define (root-to-selected? tree)
  (root-selected? (tree-root tree)))
;; TESTS
#;(begin-for-test
  (check-equal?
   (root-to-selected? TREE-IN-INITIAL-WORLD)
   (root-selected? (tree-root TREE-IN-INITIAL-WORLD))
   "Should return the selected? field from the data field
    of the given tree."))

;; delete-sons : WorldState -> WorldState
;; GIVEN   : a WorldState (w)
;; RETURNS : a new WorldState, w that follows after the selected tree and 
;;           its subtree have been deleted from it
;; EXAMPLES: see tests below
;; STRATEGY: Combining simpler functions of World on w
(define (delete-sons w)
  (make-world
   (deleted-sons root-to-selected? (world-trees w))))
;; TESTS
#;(begin-for-test
  (check-equal?
   (delete-sons INITIAL-WORLD)
   (make-world
    (deleted-sons root-to-selected? (world-trees INITIAL-WORLD)))
   "Should return a new world like the given one with all the
    subtrees and it's parent deleted from it."))

;; deleted-sons : (Tree -> Boolean) ListOfTrees -> ListOfTrees
;; GIVEN   : a general function and list of trees
;; RETURNS : list of trees after the selected tree and its subtree has
;;           been deleted from it
;; EXAMPLES: see tests below
;; STRATEGY: Using HOF map on (sons-to-be-removed filter-fn trees)
(define (deleted-sons filter-fn trees)
  (map
   ;; Tree -> Tree
   (lambda (tree) (delete-sons-of-sons filter-fn tree))
   (sons-to-be-removed filter-fn trees)))
;; TESTS
#;(begin-for-test
  (check-equal?
   (deleted-sons root-to-selected? (world-trees WORLD-AFTER-N-KEY-ON-CHILD))
   (map
    (lambda (tree) (delete-sons-of-sons root-to-selected? tree))
    (sons-to-be-removed root-to-selected?
                        (world-trees WORLD-AFTER-N-KEY-ON-CHILD)))
   "Should return a list of trees with the selected tree and its
    subtree deleted from it.")) 

;; sons-to-be-removed : (Tree -> Boolean) ListOfTrees -> ListOfTrees
;; GIVEN   : a general function and list of trees
;; RETURNS : list of trees after the selected tree and its subtree has
;;           been deleted from it
;; EXAMPLES: see tests below
;; STRATEGY: Using HOF filter on trees
(define (sons-to-be-removed filter-fn trees)
  (filter
   ;; Tree -> Tree
   (lambda (tree) (not (filter-fn tree))) 
   trees))
;; TESTS
#;(begin-for-test
  (check-equal?
   (sons-to-be-removed root-to-selected?
                       (world-trees WORLD-AFTER-N-KEY-ON-CHILD))
   (filter
    (lambda (tree) (not (root-to-selected? tree))) 
    (world-trees WORLD-AFTER-N-KEY-ON-CHILD))
   "Should return a list of trees with the selected
    tree and its subtrees deleted.")) 

;; delete-sons-of-sons : (Tree -> Boolean) Tree -> Tree
;; GIVEN   : a general function and a tree
;; RETURNS : a tree after the selected node and it's subtree are deleted
;; EXAMPLES: see tests below
;; STRATEGY: Combining simpler functions of Tree on tree
(define (delete-sons-of-sons filter-fn tree)
  (make-tree
   (tree-root tree)
   (deleted-sons-of-sons filter-fn tree)))
;; TESTS
#;(begin-for-test
  (check-equal?
   (delete-sons-of-sons root-to-selected? TREE-IN-INITIAL-WORLD)
   (make-tree
    (tree-root TREE-IN-INITIAL-WORLD)
    (deleted-sons-of-sons root-to-selected? TREE-IN-INITIAL-WORLD))
   "Should return the selected node with all its subtrees deleted."))

;; deleted-sons-of-sons : (Tree -> Boolean) Tree -> ListOfTrees
;; GIVEN   : a general function and a tree
;; RETURNS : a list of trees after deleting the particular subtree
;;           of the selected node
;; EXAMPLES: see tests below
;; STRATEGY: Using HOF filter on (sons-of-sons-to-be-removed filter-fn tree)
(define (deleted-sons-of-sons filter-fn tree)
  (filter
   ;; Tree -> Boolean
   (lambda (tree) (not (filter-fn tree)))
   (sons-of-sons-to-be-removed filter-fn tree)))
;; TESTS
#;(begin-for-test
  (check-equal?
   (deleted-sons-of-sons root-to-selected? INITIAL-WORLD-TREE-CHILD)
   (filter
    (lambda (tree) (not (root-to-selected? tree)))
    (sons-of-sons-to-be-removed root-to-selected? INITIAL-WORLD-TREE-CHILD))
   "Should return a list of trees after deleting subtree")) 

;; sons-of-sons-to-be-removed : (Tree -> Boolean) Tree -> ListOfTrees
;; GIVEN   : a general function and a tree
;; RETURNS : a list of trees after deleting the particular subtree
;;           of the selected node
;; EXAMPLES: see tests below
;; STRATEGY: Using HOF map on (tree-sons tree) 
(define (sons-of-sons-to-be-removed filter-fn tree) 
  (map
   ;; Tree -> Tree
   (lambda (tree)
     (delete-sons-of-sons filter-fn tree)) 
   (tree-sons tree))) 
;; TESTS
#;(begin-for-test
  (check-equal?
   (sons-of-sons-to-be-removed root-to-selected? INITIAL-WORLD-TREE-CHILD)
   (map (lambda (tree)
          (delete-sons-of-sons root-to-selected? tree)) 
        (tree-sons INITIAL-WORLD-TREE-CHILD))
   "Should return a List of Trees"))

;; left-half-node? : Tree -> Boolean
;; GIVEN   : a Tree, t
;; RETURNS : true iff the given node is located
;;           in the left half of the canvas
;; EXAMPLES: see tests below
;; STRATEGY: Use Template of Tree on tree
(define (left-half-node? tree)
  (< (root-x (tree-root tree))
     HALF-CANVAS-WIDTH))
;; TESTS
#;(begin-for-test
  (check-equal?
   (left-half-node? INITIAL-WORLD-TREE)
   (< (root-x (tree-root INITIAL-WORLD-TREE)) HALF-CANVAS-WIDTH)
   "Should return true.")) 

;; delete-left-trees : WorldState -> WorldState
;; GIVEN   : a WorldState, w
;; RETURNS : a new WorldState like the given one with all the trees
;;           whose center in the left half of canvas along with their
;;           subtrees, irrespective of the subtree's position are deleted.
;; EXAMPLES: see tests below
;; STRATEGY: Combining simpler functions of World on w
(define (delete-left-trees w)
  (make-world
   (deleted-sons left-half-node?
                 (world-trees w))))
;; TESTS
#;(begin-for-test
  (check-equal?
   (delete-left-trees INITIAL-WORLD)
   (make-world
    (deleted-sons left-half-node?
                  (world-trees INITIAL-WORLD)))
   "Should delete all the trees in the left half."))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; world-after-mouse-event
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; world-after-mouse-event : WorldState Int Int MouseEvent -> WorldState
;; GIVEN   : a World(w), the x(mx) and y(mx) coordinates
;;           of a MouseEvent, and the MouseEvent(mev).
;; RETURNS : the world that should follow the given world
;;           after the given MouseEvent.
;; EXAMPLES: see tests below
;; STRATEGY: Use Template of World on w 
(define (world-after-mouse-event w mx my mev)
  (make-world
   (trees-after-mouse-event (world-trees w) mx my mev false)))
;; TESTS
#;(begin-for-test
  (check-equal? (world-after-mouse-event WORLD-AFTER-L-KEY-PRESS
                                         (+ HALF-CANVAS-WIDTH THREE)
                                         (+ (- FORTY THIRTY) THREE)
                                         BUTTON-DOWN-EVENT)
                WORLD-AFTER-BUTTON-DOWN
                "Should return world after button-down mouse event")
  (check-equal? (world-after-mouse-event WORLD-AFTER-L-KEY-PRESS
                                         ZERO
                                         ZERO
                                         BUTTON-UP-EVENT)
                WORLD-AFTER-L-KEY-PRESS
                "Should return world after button-up mouse event")
  (check-equal? (world-after-mouse-event WORLD-AFTER-L-KEY-PRESS
                                         ZERO
                                         ZERO
                                         DRAG-EVENT)
                WORLD-AFTER-L-KEY-PRESS
                "Should return world after drag mouse event")
  (check-equal? (world-after-mouse-event WORLD-AFTER-L-KEY-PRESS
                                         ZERO
                                         ZERO
                                         OTHER-MOUSE-EVENT)
                WORLD-AFTER-L-KEY-PRESS
                "Should return world after unspecified mouse event")
  (check-equal? (world-after-mouse-event FIRST-NODE-ON-INITIAL-WORLD
                                         (+ HALF-CANVAS-WIDTH
                                            (- FORTY THIRTY))
                                         (- FORTY THIRTY)
                                         DRAG-EVENT)
                (make-world (list
                             (make-tree
                              (make-root
                               (make-posn (+ HALF-CANVAS-WIDTH
                                             (- FORTY THIRTY))
                                          (- FORTY THIRTY))
                               true
                               (make-posn ZERO ZERO))
                              empty)))
                "Should return world after drag mouse event"))

;; trees-after-mouse-event : ListOfTrees Int Int MouseEvent Boolean
;;                                                              -> ListOfTrees
;; GIVEN   : a ListOfTrees(LOT), the x(mx) and y(mx) coordinates
;;           of a MouseEvent, and the MouseEvent(mev) and a boolean
;;           to check to move tree along with its sons.
;; RETURNS : a ListOfTrees that should follow the given
;;           ListOfTrees after the given MouseEvent.
;; EXAMPLE : see tests below
;; STRATEGY: Use HOF map on trees
(define (trees-after-mouse-event trees mx my mev move-tree?)
  (map
   ;; Tree -> Tree
   ;; RETURNS a tree that should follow
   ;; given tree post mouse event
   (lambda (tree)
     (tree-after-mouse-event tree mx my mev move-tree?))
   trees))
;; TESTS
#;(begin-for-test
  (check-equal?
   (trees-after-mouse-event (world-trees WORLD-AFTER-N-KEY-ON-CHILD)
                            FOUR THREE DRAG-EVENT true)
   (map
    (lambda (tree)
      (tree-after-mouse-event tree FOUR THREE DRAG-EVENT true))
    (world-trees WORLD-AFTER-N-KEY-ON-CHILD))
   "Should return lot1 after mouse event.")) 

;; tree-after-mouse-event : Tree Int Int MouseEvent Boolean -> Tree
;; GIVEN   : a Tree(tree), the x(mx) and y(mx) coordinates
;;           of a MouseEvent, and the MouseEvent(mev) and a boolean
;;           to check for moved parent.
;; RETURNS : the tree that should follow the given
;;           tree after the given the MouseEvent.
;; EXAMPLE : see tests below
;; STRATEGY: Combining simpler functions of Tree on tree
(define (tree-after-mouse-event tree mx my mev move-tree?)
  (make-tree
   (root-after-mouse-event (tree-root tree) 
                           mx my mev
                           move-tree?)
   (trees-after-mouse-event (tree-sons tree)
                            mx my mev
                            (tree-root-updated?
                             mx my mev
                             move-tree? (tree-root tree)))))
;; TESTS
#;(begin-for-test
  (check-equal?
   (tree-after-mouse-event INITIAL-WORLD-TREE FOUR THREE DRAG-EVENT true)
   (make-tree
    (root-after-mouse-event (tree-root INITIAL-WORLD-TREE)
                            FOUR THREE DRAG-EVENT
                            true)
    (trees-after-mouse-event (tree-sons INITIAL-WORLD-TREE)
                             FOUR THREE DRAG-EVENT
                             (tree-root-updated?
                              FOUR THREE DRAG-EVENT
                              true (tree-root INITIAL-WORLD-TREE))))
   "Should return a tree dragged 4 unit in x direction
    and 3 unit in y direction"))

;; tree-root-updated? : Int Int MouseEvent Boolean Root -> Boolean
;; GIVEN   : the x(mx) and y(mx) coordinates of a MouseEvent,
;;           and the MouseEvent(mev) and a boolean to check for
;;           moved parent and a Root (root).
;; RETURNS : truee iff if the parent tree has been moved/dragged 
;;           from it's original position.
;; EXAMPLE : see tests below
;; STRATEGY: Combining simpler functions
(define (tree-root-updated? mx my mev move-tree? root)
  (or move-tree?
      (not (equal?
            (root-after-mouse-event
             root mx my mev move-tree?)
            root)))) 
;; TESTS 
#;(begin-for-test
  (check-equal?
   (tree-root-updated? FOUR THREE DRAG-EVENT true INITIAL-WORLD-TREE-ROOT)
   true
   "Should return true since move-tree? is true")
  (check-equal?
   (tree-root-updated? FOUR THREE DRAG-EVENT false INITIAL-WORLD-TREE-ROOT)
   false
   "Should return false since move-tree? is false"))

;; root-after-mouse-event : Root Int Int MouseEvent Boolean -> Root
;; GIVEN   : a Root (root), the x(mx) and y(mx) coordinates
;;           of a MouseEvent, and the MouseEvent(mev) and a boolean
;;           to check for moved parent.
;; RETURNS : the Root that should follow the given
;;           tree after the given the MouseEvent.
;; EXAMPLE : see tests below
;; STRATEGY: Divide into Cases on MouseEvent mev
(define (root-after-mouse-event root mx my mev move-tree?)
  (cond [(mouse=? mev "button-down")
         (tree-after-button-down root mx my)]
        [(mouse=? mev "button-up")
         (tree-after-button-up root)]
        [(mouse=? mev "drag")
         (tree-after-drag root mx my move-tree?)]
        [else root]))
;; TESTS
#;(begin-for-test
  (check-equal?
   (root-after-mouse-event INITIAL-WORLD-TREE-ROOT FOUR THREE 
                           BUTTON-DOWN-EVENT true)
   (tree-after-button-down INITIAL-WORLD-TREE-ROOT FOUR THREE)
   "Should return a new node with the selected? set to true")
  (check-equal?
   (root-after-mouse-event INITIAL-WORLD-TREE-ROOT FOUR THREE
                           BUTTON-UP-EVENT true)
   (tree-after-button-up INITIAL-WORLD-TREE-ROOT)
   "Should return the same node with selected? set to false.")
  (check-equal?
   (root-after-mouse-event INITIAL-WORLD-TREE-ROOT FOUR THREE
                           DRAG-EVENT true)
   (tree-after-drag INITIAL-WORLD-TREE-ROOT FOUR THREE true)
   "Should return the node after dragging to FOUR,THREE")
  (check-equal?
   (root-after-mouse-event INITIAL-WORLD-TREE-ROOT FOUR THREE
                           OTHER-MOUSE-EVENT true)
   INITIAL-WORLD-TREE-ROOT
   "Should return the same node"))

;; root-offset-after-button-down : Root Int Int -> Posn
;; GIVEN   : a Root (root), the x(mx) and y(mx) coordinates
;;           of a MouseEvent, and the MouseEvent(mev).
;; RETURNS : the new Root offset posn that should follow the given
;;           node after the given the MouseEvent.
;; EXAMPLE : see tests below
;; STRATEGY: Combining simpler functions.
(define (root-offset-after-button-down root mx my)
  (make-posn (- (root-x root) mx)
             (- (root-y root) my)))
;; TESTS
#;(begin-for-test
  (check-equal?
   (root-offset-after-button-down INITIAL-WORLD-TREE-ROOT FOUR THREE)
   (make-posn (- (root-x INITIAL-WORLD-TREE-ROOT) FOUR)
              (- (root-y INITIAL-WORLD-TREE-ROOT) THREE))
   "Should return a new posn with difference between current location
    of center of node and the mouse click."))

;; tree-after-button-down : Root Integer Integer -> Root
;; GIVEN   : a Root (root), the x(mx) and y(my) 
;;           coordinates of a MouseEvent.
;; RETURNS : the new Root following a button-down at the
;;           given location x(mx) and y(my) coordinates).
;; EXAMPLE : see tests below 
;; STRATEGY: Combining simpler functions of Root on root.
(define (tree-after-button-down root mx my)
  (make-root (root-location root)
             (in-tree? root mx my)
             (root-offset-after-button-down root mx my)))
;; TESTS
#;(begin-for-test
  (check-equal?
   (tree-after-button-down INITIAL-WORLD-TREE-ROOT FOUR THREE)
   (make-root (root-location INITIAL-WORLD-TREE-ROOT)
              (in-tree? INITIAL-WORLD-TREE-ROOT FOUR THREE)
              (root-offset-after-button-down INITIAL-WORLD-TREE-ROOT
                                             FOUR THREE))
   "Should return a node with selected? enumerated using in-tree? function
   and a new offset calculated using bode-oofset-after-button-down function."))

;; tree-after-button-up : Root -> Root
;; GIVEN   : A Root (root)
;; RETURNS : the Root following a button-up
;; EXAMPLE : see tests below
;; STRATEGY: Combining simpler functions of Root on root.
(define (tree-after-button-up root)
  (make-root (root-location root)
             false
             (root-offset root)))
;; TESTS
#;(begin-for-test
  (check-equal?
   (tree-after-button-up INITIAL-WORLD-TREE-ROOT)
   (make-root (root-location INITIAL-WORLD-TREE-ROOT)
              false
              (root-offset INITIAL-WORLD-TREE-ROOT))
   "Should return a node just like the one given with
   selected? flag set to false"))

;; root-location-after-drag : Integer Integer Root -> Posn
;; GIVEN   : a Root(node), the x(mx) and y(my) 
;;           coordinates of a MouseEvent.
;; RETURNS : the location of the Root in posn following a drag at the 
;;           at the given location(x(mx) and y(mx) coordinates).
;; EXAMPLE : see tests below
;; STRATEGY: Combining simpler functions of Root on root.
(define (root-location-after-drag root mx my)
  (make-posn (+ (posn-x (root-offset root)) mx)
             (+ (posn-y (root-offset root)) my)))  
;; TESTS
#;(begin-for-test
  (check-equal?
   (root-location-after-drag INITIAL-WORLD-TREE-ROOT FOUR THREE)
   (make-posn (+ (posn-x (root-offset INITIAL-WORLD-TREE-ROOT)) FOUR)
              (+ (posn-y (root-offset INITIAL-WORLD-TREE-ROOT)) THREE))
   "Should return a posn where x = given world offset of x + FOUR
    and y = given world offset of y + THREE"))

;; tree-after-drag : Root Integer Integer Boolean -> Root
;; GIVEN   : a Root(root), the x(mx) and y(my) 
;;           coordinates of a MouseEvent and a boolean
;;           to check for moved parent.
;; RETURNS : the Root following a drag at the at the
;;           given location(x(mx) and y(mx) coordinates).
;; EXAMPLE : see tests below
;; STRATEGY: Combining simpler functions of Root on root.
(define (tree-after-drag root mx my move-tree?)
  (if (or move-tree? (root-selected? root))
      (make-root (root-location-after-drag root mx my)
                 (root-selected? root)
                 (root-offset root)) 
      root)) 
;; TESTS
#;(begin-for-test
  (check-equal?
   (tree-after-drag INITIAL-WORLD-TREE-ROOT FOUR THREE true)
   (make-root (root-location-after-drag INITIAL-WORLD-TREE-ROOT FOUR THREE)
              (root-selected? INITIAL-WORLD-TREE-ROOT)
              (root-offset INITIAL-WORLD-TREE-ROOT))
   "Should return a root displaced FOUR in x and THREE in y direction")
  (check-equal?
   (tree-after-drag INITIAL-WORLD-TREE-ROOT FOUR THREE false)
   INITIAL-WORLD-TREE-ROOT
   "Should return the same root since move-tree? is false"))

;; in-tree?: Tree Integer Integer -> Boolean
;; GIVEN   : a Tree(tree), the x(x) and y(y)
;;           coordinates of a MouseEvent.
;; RETURNS : true iff the given coordinate is inside
;;           the bounding box of the given Tree.
;; EXAMPLES: see tests below
;; STRATEGY: Combine Simpler Functions 
(define (in-tree? tree x y)  
  (<= (distance-of-click-from-circle
       (root-x tree) (root-y tree)
       x y)
      NODE-RADIUS))
;; TESTS
#;(begin-for-test
  (check-equal?
   (in-tree? INITIAL-WORLD-TREE-ROOT FOUR THREE) 
   false
   "Should return false")
  (check-equal?
   (in-tree? INITIAL-WORLD-TREE-ROOT
             HALF-CANVAS-WIDTH NODE-RADIUS)
   true
   "Should return true"))

;; distance-of-click-from-circle : Integer Integer Integer Integer -> PosInt
;; GIVEN   : X(tree-x) & Y(tree-y) Coordinates of Tree,
;;           the x(x) and y(y) coordinates of a MouseEvent.
;; RETURNS : true iff the given coordinate is inside
;;           the bounding box of the given Tree.
;; EXAMPLES: see tests below
;; STRATEGY: Combining Simpler Function
(define (distance-of-click-from-circle tree-x tree-y x y)
  (sqrt(+ (sqr(- tree-x x))
          (sqr(- tree-y y)))))
;; TESTS
#;(begin-for-test
  (check-equal?
   (distance-of-click-from-circle HALF-CANVAS-WIDTH
                                  HALF-CANVAS-HEIGHT
                                  (+ HALF-CANVAS-WIDTH FOUR)
                                  (+ HALF-CANVAS-HEIGHT THREE))
   5
   "Should return sqrt(sqr(FOUR)+sqr(THREE)) = 5"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;(run 0.2)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; END
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
#lang racket


(require "interfaces.rkt")
(require 2htdp/universe)   
(require rackunit)
(require "extras.rkt")
(require 2htdp/image)
(require "square.rkt")
(require "target.rkt")
(require "clock.rkt")
(require "football.rkt")
(require "throbber.rkt")
(require "WidgetWorks.rkt")

(provide make-playground)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; A PlaygroundState% is a (new PlaygroundState% [sworld statefullWorld<%>] 
;;                                               [speed integer])
;; A Playground contains list of all the toys it contains along with a target
;; and the speed of squares.

(define PlaygroundState%
  (class* object% (PlaygroundState<%>)
    
    (init-field sworld speed) 

   (init-field [target (new-target)]) ;  Target<%>

       
    (super-new)
    
    ;; after-tick : -> PlaygroundState
    ;; RETURNS: A Playground like this one, but as it should be after the
    ;; tick.
    ;; STRATEGY: Use HOFC map on the SWidget's in this Playground
    (define/public (after-tick)this)
     
    
    ;; to-scene : -> Scene
    ;; GIVEN: a scene
    ;; RETURNS: the scene with toys and target
    ;; STRATEGY:Use HOFC foldr on the Widget's in this Playground
    (define/public (add-to-scene s)s)
      
    ;; after-key-event : KeyEvent -> PlaygroundState
    ;; GIVEN: a keyevent
    ;; RETURNS: the playground that should follow the keyevent
    ;; STRATEGY: Cases on kev    
    (define/public (after-key-event kev)
       (cond
         [(key=? kev NEW-SQUARE-KEY-EVENT)
         (send sworld add-stateful-widget
               (make-square-toy (target-x) (target-y) speed))]
        [(key=? kev NEW-THROBBER-KEY-EVENT)
         (send sworld add-stateful-widget
               (make-throbber (target-x) (target-y)))]
        [(key=? kev NEW-CLOCK-KEY-EVENT)
         (send sworld add-stateful-widget
               (make-clock (target-x) (target-y)))]
        [(key=? kev NEW-FOOTBALL-KEY-EVENT)
         (send sworld add-stateful-widget
               (make-football (target-x) (target-y)))])) 
      
    
    ;; after-mouse-event : Nat Nat MouseEvent -> PlaygroundState
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

    ;; after-button-down : Nat Nat -> PlaygroundState
    ;; STRATEGY: Cases on mev
    (define/public(after-button-down mx my) this)
     
    
    ;; after-button-up : Nat Nat -> PlaygroundState
    ;; STRATEGY: Cases on mev
    (define/public (after-button-up mx my) this)
     
    ;; after-drag : Nat Nat -> PlaygroundState
    ;; GIVEN: the location 
    ;; STRATEGY: Cases on mev
    (define/public (after-drag mx my) this)
   

    ;; target-x -> Integer    
    ;; target-y -> Integer
    ;; GIVEN: a target
    ;; RETURN: the x/y coordinate of the target
    (define/public (target-x)
      (send target get-x))
    (define/public (target-y)
      (send target get-y))
     
    ;; target-selected? -> Boolean
    ;; GIVEN: a target
    ;; RETURNS: true iff the target is the target selected?
    (define/public (target-selected?)
      (send target get-selected?))

    ;; -> ListOfToy<%>
    ;; RETURNS a new list of toys with respective new toy added
    (define/public (get-toys)
      (get-field sobjs sworld))
    
    (define/public (initialise-world rate)
      (begin
      (send sworld add-stateful-widget this)
      (send sworld add-stateful-widget target)
      (send sworld run rate)))


    ;; Methods for tests
    (define/public (for-test:toys) (send this get-toys))
    (define/public (for-test:target-x) (send this target-x))
    (define/public (for-test:target-y) (send this target-y))
    ))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (make-playground square-speed)
  (new PlaygroundState% [sworld (make-world CANVAS-WIDTH CANVAS-HEIGHT)]
                        [speed square-speed]))





 
;; PlaygroundState Tests

(define SPEED-10 10)
(define PLAYGROUND
  (make-playground SPEED-10))

(begin-for-test
  (local
    ((define (playground-before) PLAYGROUND)
     (define PLAYGROUND-WITH-ONE-SQUARE  (make-playground SPEED-10))
     (define PLAYGROUND-WITH-ONE-THROBBER (make-playground SPEED-10))
     (define PLAYGROUND-WITH-ONE-CLOCK (make-playground SPEED-10))
     (define PLAYGROUND-WITH-ONE-FOOTBALL (make-playground SPEED-10)))
    (check-equal?
      (playground-before)
      (send PLAYGROUND after-tick))

    (check-equal?
     (send PLAYGROUND add-to-scene EMPTY-CANVAS)
                  EMPTY-CANVAS
    )

    (check-equal?
     (playground-before)
     (send PLAYGROUND after-button-down 100 100))

    (check-equal?
     (playground-before)
     (send PLAYGROUND after-button-up 100 100))

    (check-equal?
     (playground-before)
     (send PLAYGROUND after-drag 100 100))

    (check-equal?
     (playground-before)
     (send PLAYGROUND after-mouse-event 100 100 "button-down"))

    (check-equal?
     (playground-before)
     (send PLAYGROUND after-mouse-event 100 100 "drag"))

    (check-equal?
     (playground-before)
     (send PLAYGROUND after-mouse-event 100 100 "button-up"))

    (check-equal?
     (playground-before)
     (send PLAYGROUND after-mouse-event 100 100 "move"))


    (send PLAYGROUND-WITH-ONE-SQUARE after-key-event NEW-SQUARE-KEY-EVENT)
    (check-equal? (send (first (send PLAYGROUND-WITH-ONE-SQUARE for-test:toys)) toy-data)
                  (send (make-square-toy (send PLAYGROUND-WITH-ONE-SQUARE for-test:target-x)
                                         (send PLAYGROUND-WITH-ONE-SQUARE for-test:target-y)
                                         SPEED-10) toy-data))


    (send PLAYGROUND-WITH-ONE-THROBBER after-key-event NEW-THROBBER-KEY-EVENT)
    (check-equal? (send (first (send PLAYGROUND-WITH-ONE-THROBBER for-test:toys)) toy-data)
                  (send (make-throbber (send PLAYGROUND-WITH-ONE-THROBBER for-test:target-x)
                                         (send PLAYGROUND-WITH-ONE-THROBBER for-test:target-y))
                        toy-data))

    (send PLAYGROUND-WITH-ONE-CLOCK after-key-event NEW-CLOCK-KEY-EVENT)
    (check-equal? (send (first (send PLAYGROUND-WITH-ONE-CLOCK for-test:toys)) toy-data)
                  (send (make-clock (send PLAYGROUND-WITH-ONE-CLOCK for-test:target-x)
                                         (send PLAYGROUND-WITH-ONE-CLOCK for-test:target-y))
                        toy-data))

    (send PLAYGROUND-WITH-ONE-CLOCK after-key-event NEW-CLOCK-KEY-EVENT)
    (check-equal? (send (first (send PLAYGROUND-WITH-ONE-CLOCK for-test:toys)) toy-data)
                  (send (make-clock (send PLAYGROUND-WITH-ONE-CLOCK for-test:target-x)
                                         (send PLAYGROUND-WITH-ONE-CLOCK for-test:target-y))
                        toy-data))

    (send PLAYGROUND-WITH-ONE-FOOTBALL after-key-event NEW-FOOTBALL-KEY-EVENT)
    (check-equal? (send (first (send PLAYGROUND-WITH-ONE-FOOTBALL for-test:toys)) toy-data)
                  (send (make-football (send PLAYGROUND-WITH-ONE-FOOTBALL for-test:target-x)
                                         (send PLAYGROUND-WITH-ONE-FOOTBALL for-test:target-y))
                        toy-data))

    (check-equal? (send PLAYGROUND target-selected?) false)
    
    
    ))

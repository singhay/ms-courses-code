#lang racket

;; the model consists of a particle, bouncing with its center from x=0
;; to x=150.  It accepts commands and reports when its status changes

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; LIBRARIES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(require rackunit)
(require 2htdp/image)
(require "extras.rkt")
(require "Interfaces.rkt")
(require "PerfectBounce.rkt")
(require "ParticleWorld.rkt")
(require "TestingController.rkt")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; PROVIDE FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(provide Model%)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; CLASSES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; a Model% is a (new Model% [particle-selected? Boolean][x nonNegInt]
;;                [y nonNegInt][ vx Integer][vy Integer]
;;                [controllers List])

(define Model%  
  (class* object% (Model<%>)
    
    ;; boundaries of the field
    (field [lo 0])
    (field [hi-x 150])
    (field [hi-y 100])
    
    ;; position and velocity of the object
    (init-field [x (/ (+ lo hi-x) 2)])
    (init-field [y (/ (+ lo hi-y) 2)])
    (init-field [vx 0])
    (init-field [vy 0])
    
    ; ListOfController<%>
    (init-field [controllers empty])   

    ; Flag to check if particle is selected?
    (init-field [particle-selected? false])
    
    (super-new)
    
    ;; after-tick-> Void
    ;; EFFECT: moves the object by v.
    ;; if the resulting x is >= 150 or <= 0 and y>=100 or y<=0
    ;; reports x and y at ever tick
    ;; reports velocity only when it changes

     (define/public (after-tick)
      (let ((the-particle (make-particle x y vx vy))
            (the-rect (make-rect lo hi-x lo hi-y)))
        (if (not particle-selected?)
            (new-particle-after-tick the-particle the-rect)
            3e32)))
    
    
    ;; new-particle-after-tick: Particle Rectangle -> Void
    ;; EFFECT: moves the object by v.
    ;; if the resulting x is >= 150 or <= 0 and y>=100 or y<=0
    ;; reports x and y at ever tick
    ;; reports velocity only when it changes

    (define/public (new-particle-after-tick p r)
      (let ((new-particle (particle-after-tick p r)))
        (begin
          (set! x (particle-x new-particle))
          (set! y (particle-y new-particle))
          (publish-position)
          (if (or (>= x hi-x) (<= x lo))
              (begin (set! vx (particle-vx new-particle)) (publish-velocity))
              "model.rkt after-tick")
          (if (or (>= y hi-y) (<= y lo))
              (begin (set! vy (particle-vy new-particle)) (publish-velocity))
              "model.rkt after-tick"))))

    ;; set-particle-selected: Boolean->Void
    ;; GIVEN: a boolean value true or false
    ;; EFFECT: sets the particle selected state
    
    (define/public (set-particle-selected b)
      (set! particle-selected? b))
    
    ;; register: Controller -> Void
    ;; GIVEN: a controller
    ;; EFFECT:register the new controller and send it some data
    
    (define/public (register c)
      (begin
        (set! controllers (cons c controllers))
        (send c receive-signal (make-report-position x y))
        (send c receive-signal (make-report-velocity vx vy))))
    
    ;; execute-command:Command -> Void
    ;; GIVEN: a command
    ;; EFFECT:decodes the command, executes it, and sends updates to the
    ;; controllers.
    
    (define/public (execute-command cmd)
      (cond
        [(set-position? cmd)
         (begin
           (set! x (calculate-x (set-position-x cmd)))
           (set! y (calculate-y (set-position-y cmd)))
           (publish-position))]
        [(incr-velocity? cmd)
         (begin
           (set! vx (+ vx (incr-velocity-dvx cmd)))
           (set! vy (+ vy (incr-velocity-dvy cmd)))
           (publish-velocity))]))
    

    ;; calculate-x: NonNegInteger->NonNegInteger
    ;; GIVEN: x coordinate of the controller
    ;; RETURNS: the x coordinate of the controller
    ;; STRATEGY: cond on x
    
    (define (calculate-x x)      
      (cond
        [(<= x 0) 0]
        [(>= x PARTICLE-AREA-WIDTH) PARTICLE-AREA-WIDTH]
        [else x]))
    
    ;; calculate-y: NonNegInteger->NonNegInteger
    ;; GIVEN: y coordinate of the controller
    ;; RETURNS: the y coordinate of the controller
    ;; STRATEGY: cond on y
    
    (define (calculate-y y)      
      (cond
        [(<= y 0) 0]
        [(>= y PARTICLE-AREA-HEIGHT) PARTICLE-AREA-HEIGHT]
        [else y]))  
    
    ;; report position or velocity to each controller:
    
    ;; publish-position->Void
    ;; EFFECT: report position to each controller
    
    (define (publish-position)
      (let ((msg (make-report-position x y)))
        (for-each
         (lambda (obs) (send obs receive-signal msg))
         controllers)
        ))
    
    ;; publish-velocity->Void
    ;; EFFECT: report velocity to each controller
    
    (define (publish-velocity)
      (let ((msg (make-report-velocity vx vy)))
        (for-each
         (lambda (obs) (send obs receive-signal msg))
         controllers)))
    
    ))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; TESTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define m (new Model%))
(define TestCntrlr (new TestingController% [model m]))
(define m1 (new Model% [controllers (list TestCntrlr)]
                [particle-selected? true]))
(begin-for-test
  (send m after-tick)
  (send m1 after-tick)
  (send m new-particle-after-tick
        (make-particle 10 20 30 -40)
        (make-rect 0 100 0 150))
  (send m new-particle-after-tick
        (make-particle 160 160 30 -40)
        (make-rect 0 100 0 150))
  (send m set-particle-selected #t)
  (send m execute-command (make-set-position 0 0))
  (send m execute-command (make-set-position 160 110))
  (send m execute-command (make-set-position 25 50))
  (send m execute-command (make-incr-velocity 0 0))
  (check-equal? (send TestCntrlr for-test:x) 300)
  (check-equal? (send TestCntrlr for-test:y) 250))

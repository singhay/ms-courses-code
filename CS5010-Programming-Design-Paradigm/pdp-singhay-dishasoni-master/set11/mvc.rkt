#lang racket

#|
  FILENAME    : mvc.rkt
  CO-AUTHORS  : Ayush Singh(singhay) and Disha Soni(dishasoni)
  GOAL        : To simulate a dimensionless particle bouncing in a
                150x100 rectangle.
  INSTRUCTIONS: start with (run framerate).  Typically: (run 0.25)
  A position controller using arrow keys to move the particle in x/y direction.
  A velocity controller using arrow keys to alter velocity of particle in
  x or y direction.
  Both the position and velocity controllers display both the position and
  velocity of the particle.

  An XY controller, which shows a representation of the particle bouncing in
  the rectangle. With this controller, the user can drag the particle using the
  mouse. Dragging the mouse causes the particle to follow the mouse pointer via
  a Smooth Drag.
  An X controller, which is like the XY controller, except that it displays only
  the x coordinate of the particle's motion. Dragging the mouse in the X 
  controller alters the particle's position in the x direction.
  A Y controller, which is like the X controller except that it works in
  the y direction.
|#

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; LIBRARIES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(require "extras.rkt")
(require "Model.rkt")
(require "Interfaces.rkt")
(require "ParticleWorld.rkt")
(check-location "11" "mvc.rkt")
(require "ControllerFactory.rkt")
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; PROVIDE FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(provide run)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; MAIN FUNCTION
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; run : PosReal -> Void
;; GIVEN: a frame rate, in sec/tick
;; EFFECT: Creates and runs the MVC simulation with the given frame rate.
 
(define (run rate)
  (let* ((m (new Model%))
         (w (make-world m CANVAS-WIDTH CANVAS-HEIGHT)))
    (begin
      (send w add-widget
            (new ControllerFactory% [m m][w w]))
      (send w run rate))))


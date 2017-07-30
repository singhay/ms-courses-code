#lang racket

#|
  FILENAME  : toys.rkt

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

(require rackunit)
(require "extras.rkt")
(require "sets.rkt")
(require "WidgetWorks.rkt")
(require 2htdp/universe)   
(require 2htdp/image)
(require "interfaces.rkt")
(require "playgroundState.rkt")
(require "square.rkt")
(require "target.rkt")
(require "clock.rkt")
(require "football.rkt")
(require "throbber.rkt")
(require "WidgetWorks.rkt")
(check-location "10" "toys.rkt")


(provide run
         Toy<%>
         make-world
         make-clock         
         make-throbber
         make-football
         make-square-toy
         PlaygroundState<%>
         Target<%>)


;run : PosNum PosInt -> Void
;GIVEN: a frame rate (in seconds/tick) and a square-speed (in pixels/tick),
;creates and runs a world in which square toys travel at the given
;speed.  Returns the final state of the world.
(define (run rate square-speed)
  (send (make-playground square-speed) initialise-world rate))
  




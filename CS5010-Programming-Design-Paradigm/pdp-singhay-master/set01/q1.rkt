;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-beginner-reader.ss" "lang")((modname q1) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f () #f)))
;; q1.rkt : Example 13 from Book HtDP2e,
;;          First Question of Problem Set 01. 

;; Goal: Find the distance of a point from the origin.

(require rackunit)
(require "extras.rkt")

(provide distance-to-origin)

;; sqr : PosReal -> PosReal
;; RETURNS: Square of GIVEN Number
;; EXAMPLES:
;;  (sqr 5) = 25

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DATA DEFINITIONS: none

;; distance-to-origin : Real Real -> PosReal
;; GIVEN: Coordinates of a Point (x,y) on the X and Y Axis
;; INTERPRETATIONS:
;;  x = the x-coordinate on the screen (in pixels from the left)
;;  y = the y-coordinate on the screen (in pixels from the top)
;;  (x,y) = pair of numbers representing exact location on the screen in pixels   
;; RETURNS: The distance of the Point (x,y) from the Origin assumed at (0,0)
;; EXAMPLES:
;; (distance-to-origin 0 0) = 0
;; (distance-to-origin -12 5) = 13
;; DESIGN STRATEGY: Combine Simpler Functions

(define (distance-to-origin x y)
  (sqrt
   (+
    (sqr x)
    (sqr y)
    )
   )
  )

;; TESTS
(begin-for-test
  (check-equal? (sqr 11) 121
               "Square of 11 is 121")
  (check-equal? (sqr 1) 1
               "Square of 1 is 1 itself.")  
  (check-equal? (distance-to-origin 3 4) 5
                "Point (3,4) should be 5px from the Origin")
  (check-equal? (distance-to-origin 12 5) 13
                "Point (12,5) should be 13px from the Origin")
  (check-equal? (distance-to-origin -12 5) 13
                "Point (-12,5) should be 5px from the Origin")
  (check-equal? (distance-to-origin -12 -5) 13
                "Point (-12,-5) should be 5px from the Origin")
  (check-equal? (distance-to-origin 8 0) 8
                "Point (8,0) should be 5px from the Origin")
  (check-equal? (distance-to-origin 0 19) 19
                "Point (0,19) should be 5px from the Origin")
  (check-equal? (distance-to-origin 0.798798798 67.54) #i67.54472355054602
                "Point (0.798798798,67.54) should be #i67.54472355054602 from the Origin"))

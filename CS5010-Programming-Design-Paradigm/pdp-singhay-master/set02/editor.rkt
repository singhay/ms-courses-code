;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-beginner-reader.ss" "lang")((modname editor) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f () #f)))
;; editor.rkt : Example 84 from Book HtDP2e,
;;              First Question of Problem Set 02. 

;; Goal: Design a text editor with a cursor that can navigate left and right in the text.
;;       Pressing Backspace deletes the key immediately to the left of the cursor.
;;       While the tab key ("\t") and the return key ("\r") are ignored.

(require rackunit)

(require 2htdp/universe)
(require "extras.rkt")
(check-location "02" "editor.rkt")
(provide make-editor
         editor-pre
         editor-post
         editor?
         edit)

;; IN-BUILT functions used from:
;; racket/base:
;;  substring : (substring "Apple" 1 3) = "pp"
;;  string-ith : (string-ith "hello world" 1) = "e"
;;  string-length : (string-length "Apple") = 5
;;  string-append : (string-append "Apple" "Banana") = "AppleBanana"
;;  cond : (cond [(> 5 9) 9][else 5]) = 5
;;  string=? : (string=? "Apple" "apple") = #false
;; racket/universe:
;;  key=? : (key=? KeyEvent "left") = #true

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; DATA DEFINITIONS:
(define-struct editor (pre post))
;; Editor is a (make-editor String String)
;; INTERP: pre is the portion of string before the cursor
;;   post is the portion of string after the cursor
;;
;; editor-fn : Editor -> ??
#|                   
(define (editor-fn e)
  (...
    (editor-pre e)
    (editor-post e)))
|#
;;
;; TEMPLATE:
;; KeyEvent is defined in the 2htdp/universe module. Every KeyEvent is a
;; string, but not every string is a legal key event.  The predicate for 
;; comparing mouse events is key=? .

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; string-first : String -> String
;; RETURNS: The first 1-letter substring of the GIVEN String.
;; EXAMPLES:
;; (string-first "Ayush") = "A"
;; (string-first "This is awesome") = "T"
;; DESIGN STRATEGY: Combine simpler functions
(define (string-first str)
  (cond
    [(string=? str "") ""]
    [else (string-ith str 0)]))

;; string-rest : String -> String
;; RETURNS: New string starting from the second character
;;          uptil last character of the GIVEN string
;; EXAMPLES:
;; (string-rest "Hello") = "ello"
;; DESIGN STRATEGY: Combine simpler functions
(define (string-rest str)
  (cond
    [(string=? str "") ""]  
    [else (substring str 1)]))

;; string-last : String -> String
;; RETURNS: The last 1-letter substring of the GIVEN String.
;; EXAMPLES:
;; (string-last "Ayush") = "h"
;; (string-last "This is awesome") = "e"
;; DESIGN STRATEGY: Combine Simpler Functions
(define (string-last str)
  (cond
    [(string=? str "") ""]
    [else (string-ith str (- (string-length str) 1))]))

;; string-remove-last : String -> String
;; GIVEN: 
;; RETURNS: New string formed after deleting the
;;          last character of the GIVEN string.
;; EXAMPLES:
;; (string-remove-last "Hello") = "Hell"
;; (string-remove-last "") = ""
;; (string-remove-last "X") = ""
;; DESIGN STRATEGY: Combine Simpler functions
(define (string-remove-last str)
    (cond
    [(string=? str "") ""]
    [(= (string-length str) 1) ""]    
    [else (substring str 0 (- (string-length str) 1))]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; move-left : Editor -> Editor
;; GIVEN: an editor
;; RETURNS: an editor like the given one, with cursor moved
;;          immediately to the left of the last character
;;          of the given pre field of given editor
;; EXAMPLES:
;; (move-left (make-editor "BaB" "ye")) = (make-editor "Ba" "Bye")
;; (move-left (make-editor "" "Hey")) = (make-editor "" "Hey")
;; DESIGN STRATEGY: Combine Simpler Functions
(define (move-left ed)
  (make-editor
   (string-remove-last (editor-pre ed))
   (string-append (string-last (editor-pre ed)) (editor-post ed))))

;; move-right : Editor -> Editor
;; GIVEN: an editor
;; RETURNS: an editor like the given one, with cursor moved
;;          immediately to the right of the first character
;;          of the given post field of given editor
;; EXAMPLES:
;; (move-right (make-editor "B" "aBye")) = (make-editor "Ba" "Bye")
;; (move-right (make-editor "Hey" "")) = (make-editor "Hey" "")
;; DESIGN STRATEGY: Combine Simpler Functions
(define (move-right ed)
  (make-editor
   (string-append (editor-pre ed) (string-first (editor-post ed)))
   (string-rest (editor-post ed))))

;; backspace : Editor -> Editor
;; GIVEN: an editor
;; RETURNS: an editor like the given one, with a character
;;          deleted immediately to the left of the
;;          cursor of the pre field of given editor 
;; EXAMPLES:
;; (backspace (make-editor "Hello" "World")) = (make-editor "Hell" "World")
;; (backspace (make-editor "" " Wicked")) = (make-editor "" " Wicked")
;; DESIGN STRATEGY: Combine Simpler Functions
(define (backspace ed)
  (make-editor
   (string-remove-last (editor-pre ed))
   (editor-post ed)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; edit : Editor KeyEvent -> String
;; GIVEN: an editor ed and a KeyEvent ke
;; RETURNS: an editor like the given one, with a single-character
;;          KeyEvent ke added to the end of the pre field of ed,
;;          unless ke denotes the backspace ("\b") key in that case
;;          it deletes the character immediately to the left of the cursor (if any).
;;          It ignores the tab key ("\t") and the return key ("\r").
;; INTERPRETATIONS:
;;  cursor: Imaginary object which divides Editor into
;;          two parts namely "editor-pre" & "editor-post"
;; EXAMPLES:
;; (edit "Hello" " World" "left") -> (make-editor "Hell" "o World")
;; (edit (edit "This " "is awesome" "right") "\b") -> (make-editor "This " "s awesome")
;; DESIGN STRATEGY: Dividing into cases on KeyEvent.

(define (edit ed ke)
  (if (editor? ed)
    (cond      
      [(key=? "left" ke) (move-left ed)]
      [(key=? "right" ke) (move-right ed)]
      [(key=? "\b" ke) (backspace ed)]
      [else ed])
    "Invalid Input"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; TESTS
(begin-for-test
(check-equal? (edit (make-editor "Hello" " World!") "right")
              (make-editor "Hello " "World!"))
(check-equal? (edit (edit (make-editor "Hello" " World!") "\b") "left")
              (make-editor "Hel" "l World!"))
(check-equal? (edit (make-editor "Hello" " World!") "\b")
              (make-editor "Hell" " World!"))
(check-equal? (edit (make-editor "Hello" " World!") "\r")
              (make-editor "Hello" " World!"))
(check-equal? (edit (make-editor "Hello" " World!") "\t")
              (make-editor "Hello" " World!"))
(check-equal? (edit (make-editor "H" " W") "left")
              (make-editor "" "H W"))
(check-equal? (edit (make-editor "H" " W") "right")
              (make-editor "H " "W"))
(check-equal? (edit (make-editor "H" " W") "\b")
              (make-editor "" " W"))
(check-equal? (edit (make-editor "" " W") "left")
              (make-editor "" " W"))
(check-equal? (edit (make-editor "H" "") "right")
              (make-editor "H" ""))
(check-equal? (edit (make-editor "" " W") "\b")
              (make-editor "" " W"))
(check-equal? (edit (make-editor "H" " W") "f1")
              (make-editor "H" " W"))
(check-equal? (edit (make-editor "H" " W") "5")
              (make-editor "H" " W"))
(check-equal? (edit (make-editor "H" " W") "\r")
              (make-editor "H" " W"))
(check-equal? (edit (make-editor "HW" "") "\b")
              (make-editor "H" ""))
(check-equal? (string-first "T")
              "T")
(check-equal? (string-first "Tsasa")
              "T")
(check-equal? (string-rest "Tsasa")
              "sasa")
(check-equal? (string-rest "")
              "")
(check-equal? (string-last "Tsasa")
              "a")
(check-equal? (string-last "")
              "")
(check-equal? (string-remove-last "Tsasa")
              "Tsas")
(check-equal? (string-remove-last "")
              "")
(check-equal? (move-left (make-editor "0" "sd"))
              (make-editor "" "0sd"))
(check-equal? (move-right (make-editor "0-" "sxccd"))
              (make-editor "0-s" "xccd"))
(check-equal? (backspace (make-editor "0" "sd"))
              (make-editor "" "sd")))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;END;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

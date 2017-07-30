;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-intermediate-lambda-reader.ss" "lang")((modname rosters) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f () #t)))
#|
   rosters.rkt : Third and Last Question of Problem Set 05
   GOAL: given a list of (student, class) pairs, produce the class roster
         for each class that has at least one student enrolled.
|#

(require rackunit)
(require "extras.rkt")
(require "sets.rkt")
(check-location "05" "rosters.rkt")
(provide make-enrollment
         enrollment-student
         enrollment-class
         make-roster
         roster-classname
         roster-students
         roster=?
         rosterset=?
         enrollments-to-rosters)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; DATA DEFINITIONS

;; A SetOf<X> is a ListOf<X> WITH NO DUPLICATES
;; Two SetOfX's are considered equal if they have the same members.

;; EXAMPLE:
;; SetOfEnrollment, SetOfClassRoster, SetOfClass, SetOfStudent, etc.

;--------------------------------------------------------------------

;; Student is unspecified, but you may assume that students may be
;; compared for equality with equal?

;; EXAMPLE:
(define STUDENT-JOHN "John")
(define STUDENT-FENG "Feng")
(define STUDENT-AMY "Amy")
(define STUDENT-KATHRYN "Kathryn")
 
;; A ListOfStudents (LOS) is either
;; -- empty
;; -- (cons Student empty)

;; TEMPLATE:
;; los-fn : LOS -> ??
;; (define (los-fn LOS)
;;   (cond
;;     [(empty? LOS) ...]
;;     [else (... (first LOS)
;;                (los-fn (rest LOS)))]))
 
;; EXAMPLES:
(define STUDENTS-EMPTY empty)
(define STUDENTS
  (list STUDENT-JOHN STUDENT-AMY STUDENT-AMY))
 
;; A SetOfStudent is a ListOfStudents without any duplicates.
 
;; EXAMPLE:
(define SET-OF-STUDENTS
  (list STUDENT-JOHN STUDENT-FENG STUDENT-AMY))
 
;--------------------------------------------------------------------
 
;; A Class is unspecified and hence can be Any data type
;; whose two elements can be compared using equal?
 
;; EXAMPLES:
(define CLASS-PDP "PDP")
(define CLASS-NETWORKS "Networks")
 
;; A ListOfClasses (LOC) is either
;; -- empty
;; -- (cons Class empty)
 
;; TEMPLATE:
;; loc-fn : LOC -> ??
;; (define (loc-fn LOC)
;;   (cond
;;     [(empty? LOC) ...]
;;     [else (... (first LOC)
;;             (los-fn (rest LOC)))]))
 
;; EXAMPLES:
(define CLASSES-EMPTY empty)
(define CLASSES (list CLASS-PDP CLASS-PDP))
 
;; A SetOfClass is a ListOfClasses without any duplicates.
 
;; EXAMPLE:
(define SET-OF-CLASSES (list CLASS-PDP CLASS-NETWORKS))
 
;--------------------------------------------------------------------
 
(define-struct roster (classname students))
;; A ClassRoster is a (make-roster Class SetOfStudent)
;; INTERPRETATION:
;; (make-roster c ss) represents that the students in 
;; class c are exactly the students in set ss.
;; TEMPLATE: 
;; classroster-fn : Roster -> ??
#|                  
(define (classroster-fn r)
  (...
    (classroster-classname r)
    (classroster-students r)))
|#
 
;; EXAMPLES:
(define ROSTER-1
  (make-roster CLASS-PDP
               (list STUDENT-JOHN STUDENT-FENG STUDENT-AMY)))
(define ROSTER-2
  (make-roster CLASS-NETWORKS
               (list STUDENT-KATHRYN STUDENT-AMY)))
(define ROSTER-3
  (make-roster CLASS-PDP
               (list STUDENT-AMY STUDENT-JOHN STUDENT-FENG)))
(define ROSTER-4
  (make-roster CLASS-PDP empty))
 
;; A ListOfRosters (LOR) is either
;; -- empty
;; -- (cons Roster LOR)
 
;; TEMPLATE:
;; lor-fn : LOR -> ??
;; (define (lor-fn roster-lst)
;;   (cond
;;     [(empty? roster-lst) ...]
;;     [else (...
;;             (roster-fn (first roster-lst))
;;             (lor-fn (rest roster-lst)))]))
 
;; EXAMPLES:
(define EMPTY-ROSTERS empty)
(define ROSTERS (list ROSTER-1 ROSTER-1))
 
;; A SetOfRoster is a ListOfRosters without any duplicates.
 
;; EXAMPLE:
(define SET-OF-ROSTER-1 (list ROSTER-1 ROSTER-3))
(define SET-OF-ROSTER-2 (list ROSTER-3 ROSTER-1))
(define SET-OF-ROSTER-3 (list ROSTER-1 ROSTER-2 ROSTER-3))
(define SET-OF-ROSTER-4 (list ROSTER-1 ROSTER-2))
 
;--------------------------------------------------------------------
 
(define-struct enrollment (student class))
;; An Enrollment is a (make-enrollment Student Class)  
;; INTERPRETATION:
;; An Enrollment is a (make-enrollment Student Class)
;; (make-enrollment s c) represents the assertion that
;; student s is enrolled in class c.
 
;; TEMPLATE:
;; enrollment-fn : Enrollment -> ??
#|                  
(define (enrollment-fn e)
  (...
    (enrollment-student e)
    (enrollment-class e)))
|#
 
;; EXAMPLE:
(define ENROLLMENT-PDP-JOHN
  (make-enrollment STUDENT-JOHN CLASS-PDP))
(define ENROLLMENT-NETWORK-KATHRYN
  (make-enrollment STUDENT-KATHRYN CLASS-NETWORKS))

;; A ListofEnrollments (LOE) is either
;; -- empty
;; -- (cons Enrollment LOE)
 
;; TEMPLATE:
;; loe-fn : LOE -> ??
;; (define (loe-fn LOE)
;;   (cond
;;     [(empty? LOE) ...]
;;     [else (...
;;             (enrollment-fn (first LOE))
;;             (loe-fn (rest LOE)))]))
;;
 
;; EXAMPLES:
(define EMPTY-ENROLLMENTS empty)
(define ENROLLMENTS
  (list
   ENROLLMENT-PDP-JOHN
   ENROLLMENT-NETWORK-KATHRYN))

;; A SetOfEnrollment is a ListOfEnrollments without any duplicates.
 
;; EXAMPLE:
(define SET-OF-ENROLLMENTS
  (list (make-enrollment STUDENT-JOHN CLASS-PDP)
        (make-enrollment STUDENT-KATHRYN CLASS-NETWORKS)
        (make-enrollment STUDENT-FENG CLASS-PDP)
        (make-enrollment STUDENT-AMY CLASS-PDP)
        (make-enrollment STUDENT-AMY CLASS-NETWORKS)))
(define SET-OF-ROSTERS
  (list (make-enrollment STUDENT-JOHN CLASS-PDP)
        (make-enrollment STUDENT-FENG CLASS-PDP)
        (make-enrollment STUDENT-AMY CLASS-PDP)))
;--------------------------------------------------------------------
;; FUNCTIONS imported from "sets.rkt"

;; note: empty is a SetOf<X>

;; my-member? : X SetOf<X> -> Boolean
;; RETURNS true iff X is a member of SetOf<X>
;; strategy: HO Function Combination

;; subset? : SetOf<X> SetOf<X> -> Boolean
;; RETURNS true iff SetOf<X> is a subset of SetOf<X>
;; strategy: HO Function Combination
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; MAIN FUNCTIONS

;; roster=? : ClassRoster ClassRoster -> Boolean
;; GIVEN   : 2 ClassRosters (class-roster-1 and class-roster-2)
;; RETURNS : true iff the two arguments represent the same roster. 
;; EXAMPLES: see tests below
;; STRATEGY: Use template for ClassRoster on
;;           class-roster-1 and class-roster-2
(define (roster=? class-roster-1 class-roster-2)
  (and
   (equal?  (roster-classname class-roster-1)
            (roster-classname class-roster-2))
   (subset? (roster-students class-roster-2)
            (roster-students class-roster-1))
   (subset? (roster-students class-roster-1)
            (roster-students class-roster-2))))
;; TESTS
(begin-for-test
  (check-equal? (roster=? ROSTER-1 ROSTER-3)
                true)
  (check-equal? (roster=? ROSTER-1 ROSTER-2)
                false)
  (check-equal? (roster=? ROSTER-1 ROSTER-4)
                false))

;; rosterset=? : SetOfClassRoster SetOfClassRoster -> Boolean
;; GIVEN   : 2 Sets of ClassRoster
;; RETURNS : true iff the two arguments represent
;;           the same set of rosters.
;; EXAMPLES: see tests below
;; STRATEGY: Use HOF andmap on set-of-roster-1 and set-of-roster-2
(define (rosterset=? set-of-roster-1 set-of-roster-2)
  (and
   (andmap
    ;; ClassRoster -> Boolean
    ;; RETURNS true iff roster-1 is present in set-of-roster-2
    (lambda (roster-1)
      (roster-in-set-of-roster? roster-1 set-of-roster-2))
    set-of-roster-1)
   (andmap
    ;; ClassRoster -> Boolean
    ;; RETURNS true iff roster-2 is present in set-of-roster-1
    (lambda (roster-2)
      (roster-in-set-of-roster? roster-2 set-of-roster-1))
    set-of-roster-2))) 
;; TESTS
(begin-for-test
  (check-equal?
   (rosterset=? SET-OF-ROSTER-1 SET-OF-ROSTER-2)
   true)
  (check-equal?
   (rosterset=? SET-OF-ROSTER-1 SET-OF-ROSTER-3)
   false)
  (check-equal?
   (rosterset=? SET-OF-ROSTER-3 SET-OF-ROSTER-4)
   true))

;; enrollments-to-rosters: SetOfEnrollment -> SetOfClassRoster
;; GIVEN   : a set of enrollments
;; RETURNS : the set of class rosters for the given enrollments.
;; EXAMPLES: see test below
;; STRATEGY: Use HOF map on set-of-enrollments
(define (enrollments-to-rosters set-of-enrollments)
  (map
   ;; Class -> ClassRoster
   ;; RETURNS a ClassRoster with Classname and a SetOfStudent.
   (lambda (class)
     (final-roster class set-of-enrollments))
   (remove-duplicates set-of-enrollments)))
;; TESTS
(begin-for-test
  (set-equal?
   (enrollments-to-rosters
    SET-OF-ENROLLMENTS)
   SET-OF-ROSTERS)) 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; HELPER FUNCTIONS

;; roster-in-set-of-roster? : ClassRoster SetOfClassRoster -> Boolean
;; GIVEN   : A ClassRoster(roster-1) and a SetOfClassRoster
;; RETURNS : true if given ClassRoster is present in
;;           the given SetOfClassRoster.
;; EXAMPLES: see tests below
;; STRATEGY: Use HOF ormap on set-of-roster-2
(define (roster-in-set-of-roster? roster-1 set-of-roster-2)
  (ormap
   ;; ClassRoster -> Boolean
   ;; RETURNS true iff roster-1 is equal to roster-2
   (lambda (roster-2) (roster=? roster-1 roster-2))
   set-of-roster-2)) 
;; TESTS
(begin-for-test
  (check-equal?
   (roster-in-set-of-roster? ROSTER-1 SET-OF-ROSTER-1)
   #true
   "Should return true since roster-1 is present in SET-OF-ROSTER-1")
  (check-equal?
   (roster-in-set-of-roster? ROSTER-2 SET-OF-ROSTER-1)
   #false
   "Should return true since roster-2 is present in SET-OF-ROSTER-1"))

;; final-roster : Class SetOfEnrollment -> ClassRoster
;; GIVEN   : a class and a set of enrollments
;; RETURNS : a class roster of the given class.
;; EXAMPLES: see tests below
;; STRATEGY: Combine Simpler Functions.
(define (final-roster class set-of-enrollments)
  (make-roster
   class
   (make-set-of-students class set-of-enrollments)))
;; TESTS
(begin-for-test
  (check-equal?
   (final-roster CLASS-PDP SET-OF-ENROLLMENTS)
   (make-roster
    CLASS-PDP
    (list STUDENT-JOHN STUDENT-FENG STUDENT-AMY))
   "Should return a roster of PDP class with 
    Students as John, Feng and Amy"))
   
;; make-set-of-students : Class SetOfEnrollment -> SetOfStudent
;; GIVEN   : a class and a set of enrollments
;; RETURNS : a set of students all belonging to the given class.
;; EXAMPLES: see tests below
;; STRATEGY: Use HOF map on the result of 
;;           (filter-set-of-students class set-of-enrollments). 
(define (make-set-of-students class set-of-enrollments)
  (map
   ;; Enrollment -> Student
   ;; RETURNS Student from the given enrollment
   (lambda (enrollment) (enrollment-student enrollment))
   (filter-set-of-students class set-of-enrollments)))
;; TESTS
(begin-for-test
  (check-equal?
   (make-set-of-students CLASS-PDP SET-OF-ENROLLMENTS)
   (list STUDENT-JOHN STUDENT-FENG STUDENT-AMY)
   "Should return John, Feng and Amy"))

;; filter-set-of-students : Class SetOfEnrollment -> SetOfEnrollment
;; GIVEN   : a class and a set of enrollments
;; RETURNS : a set of enrollments all belonging to the given class
;; EXAMPLES: see tests below
;; STRATEGY : Use HOF filter on set-of-enrollments
(define (filter-set-of-students class set-of-enrollments)
  (filter
   ;; Enrollment -> Boolean
   ;; RETURNS true iff argument class equals
   ;;         class from the given enrollment
   (lambda (enrollment)
     (equal? (enrollment-class enrollment) class))
   set-of-enrollments))
;; TESTS
(begin-for-test
  (set-equal?
   (filter-set-of-students CLASS-PDP SET-OF-ENROLLMENTS)
   (list (make-enrollment STUDENT-JOHN CLASS-PDP)
         (make-enrollment STUDENT-FENG CLASS-PDP)
         (make-enrollment STUDENT-AMY CLASS-PDP))))

;; remove-duplicates : SetOfEnrollment -> SetOfClass
;; GIVEN   : a set of enrollments
;; RETURNS : a set of unique classes from given SetOfEnrollment
;; EXAMPLES: see tests below
;; STRATEGY: Use HOF foldr on set-of-enrollments
(define (remove-duplicates set-of-enrollments)
  (foldr
   ;; Enrollment SetOfEnrollment -> SetOfClass
   ;; RETURNS a List of Unique Classes
   (lambda (enrollment rest-of-set)
     (append
      (unique-classes-from-set
       (enrollment-class enrollment) rest-of-set)
      rest-of-set))
   empty
   set-of-enrollments))
;; TESTS
(begin-for-test
  (check-equal?
   (remove-duplicates SET-OF-ENROLLMENTS)
   SET-OF-CLASSES)
  (check-equal?
   (remove-duplicates empty)
   empty
   "Should return empty since the input list is empty"))

;; unique-classes-from-set : String SetOfClass -> SetOfClass
;; GIVEN   : a class and a set of class
;; RETURNS : a set of class like the given one without duplicates.
;; EXAMPLES: see tests below
;; STRATEGY: Divide into cases based on
;;           whether next is empty or not
(define (unique-classes-from-set class set-of-class)
  (if
   (duplicate-class-in-list? class set-of-class)
   empty
   (list class)))
;; TESTS
(begin-for-test
  (check-equal?
   (unique-classes-from-set
    CLASS-PDP
    (list CLASS-PDP CLASS-PDP CLASS-NETWORKS))
   empty
   "Should remove one PDP from original list")
  (set-equal?
   (unique-classes-from-set CLASS-PDP (list CLASS-NETWORKS))
   (list CLASS-PDP)))

;; duplicate-class-in-list? : String SetOfClass -> Boolean
;; GIVEN   : a set of class
;; RETURNS : True if any duplicate of current-class is found
;;           in the given set of class.
;; EXAMPLES: see tests below
;; STRATEGY: Use HOF foldr on set-of-enrollments
(define (duplicate-class-in-list? current-class set-of-class)
  (ormap
   ;; String -> Boolean
   ;; RETURNS true iff given class is equal to current-class
   (lambda (class) (equal? class current-class))
   set-of-class)) 
;; TESTS
(begin-for-test
  (check-equal?
   (duplicate-class-in-list?
    CLASS-PDP
    (list CLASS-PDP CLASS-PDP CLASS-NETWORKS))
   #true
   "return #true since PDP is an element of given list")
  (check-equal?
   (duplicate-class-in-list? CLASS-PDP (list CLASS-NETWORKS))
   #false
   "return #false since PDP is not an element of given list"))

;;; END
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

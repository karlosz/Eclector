(cl:in-package #:eclector.reader.test)

(def-suite* :eclector.reader.macro-functions
    :in :eclector.reader)

(test read-rational/smoke
  "Smoke test for the READ-RATIONAL reader macro function."

  (mapc (lambda (input-base-preserve-expected)
          (destructuring-bind
                (input base eclector.reader:*preserve-whitespace* expected)
              input-base-preserve-expected
            (flet ((do-it ()
                     (with-input-from-string (stream input)
                       (eclector.reader::read-rational stream base))))
              (case expected
                (end-of-file
                 (signals end-of-file (do-it)))
                (eclector.reader:digit-expected
                 (signals eclector.reader:digit-expected (do-it)))
                (t
                 (is (eql expected (do-it))))))))
        '(;; Error cases
          (" "      10 nil eclector.reader:digit-expected)
          ("x"      10 nil eclector.reader:digit-expected)
          ("- "     10 nil eclector.reader:digit-expected)
          ("-x"     10 nil eclector.reader:digit-expected)
          ("1x"     10 nil eclector.reader:digit-expected)
          ("1#"     10 t   eclector.reader:digit-expected)
          ("1/"     10 nil end-of-file)
          ("1/ "    10 nil eclector.reader:digit-expected)
          ("1/x"    10 nil eclector.reader:digit-expected)
          ("1/1x"   10 nil eclector.reader:digit-expected)
          ("1/1#"   10 nil eclector.reader:digit-expected)
          ;; Good inputs
          ("1"      10 nil 1)
          ("-1"     10 nil -1)
          ("1 "     10 nil 1)
          ("-1 "    10 nil -1)
          ("1 "     10 t   1)
          ("-1 "    10 t   -1)
          ("12"     10 nil 12)
          ("-12"    10 nil -12)
          ("12 "    10 nil 12)
          ("-12 "   10 nil -12)
          ("12 "    10 t   12)
          ("-12 "   10 t   -12)
          ("12("    10 nil 12)
          ("-12("   10 nil -12)
          ("1/2"    10 nil 1/2)
          ("-1/2"   10 nil -1/2)
          ("1/2 "   10 nil 1/2)
          ("-1/2 "  10 nil -1/2)
          ("1/2 "   10 t   1/2)
          ("-1/2 "  10 t   -1/2)
          ("1/2("   10 nil 1/2)
          ("-1/2("  10 nil -1/2)
          ("1/23"   10 nil 1/23)
          ("-1/23"  10 nil -1/23)
          ("1/23 "  10 nil 1/23)
          ("-1/23 " 10 nil -1/23)
          ("1/23 "  10 t   1/23)
          ("-1/23 " 10 t   -1/23)
          ;; Base
          ("1"      10 nil 1)
          ("10"     10 nil 10)
          ("a"      10 nil eclector.reader:digit-expected)
          ("z"      10 nil eclector.reader:digit-expected)

          ("1"      16 nil 1)
          ("10"     16 nil 16)
          ("a"      16 nil 10)
          ("z"      16 nil eclector.reader:digit-expected)

          ("1"      36 nil 1)
          ("10"     36 nil 36)
          ("a"      36 nil 10)
          ("z"      36 nil 35))))

(test sharpsign-plus-minus/smoke
  "Smoke test for the SHARPSIGN-{PLUS,MINUS} functions."

  (mapc (lambda (input-parameter-context-expected)
          (destructuring-bind
                (input parameter *read-suppress*
                 plus-expected &optional minus-expected)
              input-parameter-context-expected
            (flet ((do-it (which)
                     (with-input-from-string (stream input)
                       (ecase which
                         (:plus  (eclector.reader::sharpsign-plus
                                  stream #\+ parameter))
                         (:minus (eclector.reader::sharpsign-minus
                                  stream #\- parameter))))))
              (case plus-expected
                (type-error
                 (signals type-error (do-it :plus))
                 (signals type-error (do-it :minus)))
                (eclector.reader:single-feature-expected
                 (signals eclector.reader:single-feature-expected (do-it :plus))
                 (signals eclector.reader:single-feature-expected (do-it :minus)))
                (eclector.reader:numeric-parameter-supplied-but-ignored
                 (signals eclector.reader:numeric-parameter-supplied-but-ignored
                   (do-it :plus))
                 (signals eclector.reader:numeric-parameter-supplied-but-ignored
                   (do-it :minus)))
                (t
                 (is (equal plus-expected  (do-it :plus)))
                 (is (equal minus-expected (do-it :minus))))))))
        '(;; Errors
          ("1"                   nil nil type-error)
          ("(1)"                 nil nil type-error)
          ("(not :foo :bar)"     nil nil eclector.reader:single-feature-expected)
          ("(not 1)"             nil nil type-error)
          ("(and 1)"             nil nil type-error)
          ("(or 1)"              nil nil type-error)
          ;; Warnings
          ("(and) 1"             1   nil eclector.reader:numeric-parameter-supplied-but-ignored)
          ;; Valid
          ("common-lisp 1"       nil nil 1   nil)
          ("(not common-lisp) 1" nil nil nil 1)
          ("(and) 1"             nil nil 1   nil)
          ("(or) 1"              nil nil nil 1)
          ("(not (not (and))) 1" nil nil 1   nil)
          ;; With *read-supress* bound to t
          ("(and) 1"             nil t   nil nil)
          ;; In which package is the guarded expression read?
          ("(and) foo"           nil nil foo nil))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Reader macros for sharpsign equals and sharpsign sharpsign.

(test sharpsign-equal/sharpsign
  "Smoke test for the SHARPSIGN-{EQUAL,SHARPSIGN} functions."

  (mapc (lambda (input-expected)
          (destructuring-bind (input expected) input-expected
            (flet ((do-it ()
                     (with-input-from-string (stream input)
                       (eclector.reader:read stream))))
              (case expected
                (eclector.reader:numeric-parameter-not-supplied-but-required
                 (signals eclector.reader:numeric-parameter-not-supplied-but-required
                   (do-it)))
                (eclector.reader:sharpsign-equals-label-defined-more-than-once
                 (signals eclector.reader:sharpsign-equals-label-defined-more-than-once
                   (do-it)))
                (eclector.reader:sharpsign-sharpsign-undefined-label
                 (signals eclector.reader:sharpsign-sharpsign-undefined-label
                   (do-it)))
                (recursive-cons
                 (let ((result (do-it)))
                   (is-true (consp result))
                   (is (eq result (car result)))))
                (t
                 (is (equalp expected (do-it))))))))
        '(;; sharpsign equals errors
          ("#="             eclector.reader:numeric-parameter-not-supplied-but-required)
          ("(#1=1 #1=2)"    eclector.reader:sharpsign-equals-label-defined-more-than-once)
          ;; sharpsign sharpsign errors
          ("##"             eclector.reader:numeric-parameter-not-supplied-but-required)
          ("#1#"            eclector.reader:sharpsign-sharpsign-undefined-label)
          ("(#1=1 #2#)"     eclector.reader:sharpsign-sharpsign-undefined-label)
          ;;
          ("(#1=1)"         (1))
          ("(#1=1 #1#)"     (1 1))
          ("(#1=1 #1# #1#)" (1 1 1))
          ("#1=(#1#)"       recursive-cons)
          ;; There was problem leading to unrelated expressions of the
          ;; forms (nil) and (t) being replaced by the fixup
          ;; processor.
          ("(#1=1 (nil))"   (1 (nil)))
          ("(#1=((nil)))"   (((nil))))
          ("(#1=1 (t))"     (1 (t)))
          ("(#1=((t)))"     (((t)))))))
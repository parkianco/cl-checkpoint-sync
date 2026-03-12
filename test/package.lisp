;;;; test/package.lisp - Test package for CL-CHECKPOINT-SYNC

(defpackage #:cl-checkpoint-sync/test
  (:use #:cl #:cl-checkpoint-sync)
  (:export #:run-tests))

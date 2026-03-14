;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;; SPDX-License-Identifier: BSD-3-Clause

;;;; test/package.lisp - Test package for CL-CHECKPOINT-SYNC

(defpackage #:cl-checkpoint-sync/test
  (:use #:cl #:cl-checkpoint-sync)
  (:export #:run-tests))

;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;; SPDX-License-Identifier: Apache-2.0

;;;; test/package.lisp - Test package for CL-CHECKPOINT-SYNC

(defpackage #:cl-checkpoint-sync/test
  (:use #:cl #:cl-checkpoint-sync)
  (:export #:run-tests))

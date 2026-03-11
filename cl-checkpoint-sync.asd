;;;; CL-CHECKPOINT-SYNC - ASDF System Definition
;;;;
;;;; Checkpoint-based fast sync for blockchain clients.
;;;; Pure Common Lisp implementation with no external dependencies.

(asdf:defsystem #:cl-checkpoint-sync
  :name "CL-CHECKPOINT-SYNC"
  :description "Checkpoint-based fast sync for blockchain state synchronization"
  :version "0.1.0"
  :author "CLPIC Contributors"
  :license "BSD-3-Clause"
  :homepage "https://github.com/clpic/cl-checkpoint-sync"
  :bug-tracker "https://github.com/clpic/cl-checkpoint-sync/issues"
  :source-control (:git "https://github.com/clpic/cl-checkpoint-sync.git")

  :depends-on ()  ; Pure CL - no external dependencies

  :serial t
  :components
  ((:file "package")
   (:module "src"
    :serial t
    :components
    ((:file "util")           ; Utilities (hex encoding, merkle, copy-hash)
     (:file "crypto")         ; SHA256, signature verification stubs
     (:file "types")          ; Core type definitions
     (:file "source")         ; Source discovery and validation
     (:file "download")       ; Checkpoint download with resume
     (:file "verification")   ; Proof and signature verification
     (:file "finality")       ; PoW/PoS/Hybrid finality providers
     (:file "weak-subjectivity")  ; WS period calculation and validation
     (:file "state")          ; State reconstruction
     (:file "bootstrap")      ; Bootstrap and sync management
     )))

  :in-order-to ((asdf:test-op (asdf:test-op #:cl-checkpoint-sync/test))))

(asdf:defsystem #:cl-checkpoint-sync/test
  :name "CL-CHECKPOINT-SYNC Tests"
  :description "Test suite for cl-checkpoint-sync"
  :depends-on (#:cl-checkpoint-sync)
  :serial t
  :components
  ((:module "test"
    :serial t
    :components
    ((:file "package")
     (:file "test-util")
     (:file "test-types")
     (:file "test-verification")
     (:file "test-download")
     (:file "test-finality"))))
  :perform (asdf:test-op (o c)
             (uiop:symbol-call :cl-checkpoint-sync/test :run-tests)))

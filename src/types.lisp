;;;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;;;; SPDX-License-Identifier: BSD-3-Clause

;;;; CL-CHECKPOINT-SYNC - Core Types
;;;;
;;;; Type definitions for checkpoints, states, proofs, and bundles.

(in-package #:cl-checkpoint-sync)

;;;; ============================================================================
;;;; CONDITIONS
;;;; ============================================================================

(define-condition checkpoint-error (error)
  ((message :initarg :message :reader checkpoint-error-message))
  (:report (lambda (c s) (format s "Checkpoint error: ~A" (checkpoint-error-message c)))))

(define-condition checkpoint-download-error (checkpoint-error)
  ((url :initarg :url :reader checkpoint-download-error-url)
   (status :initarg :status :reader checkpoint-download-error-status))
  (:report (lambda (c s)
             (format s "Download error from ~A: ~A (status ~A)"
                     (checkpoint-download-error-url c)
                     (checkpoint-error-message c)
                     (checkpoint-download-error-status c)))))

(define-condition checkpoint-verification-error (checkpoint-error)
  ((checkpoint :initarg :checkpoint :reader checkpoint-verification-error-checkpoint))
  (:report (lambda (c s)
             (format s "Verification failed: ~A" (checkpoint-error-message c)))))

(define-condition checkpoint-source-error (checkpoint-error)
  ((source :initarg :source :reader checkpoint-source-error-source))
  (:report (lambda (c s)
             (format s "Source error (~A): ~A"
                     (checkpoint-source-error-source c)
                     (checkpoint-error-message c)))))

(define-condition ws-checkpoint-expired-error (checkpoint-error)
  ((epoch :initarg :epoch :reader ws-checkpoint-expired-error-epoch)
   (current-epoch :initarg :current-epoch :reader ws-checkpoint-expired-error-current))
  (:report (lambda (c s)
             (format s "WS checkpoint expired: epoch ~D, current ~D"
                     (ws-checkpoint-expired-error-epoch c)
                     (ws-checkpoint-expired-error-current c)))))

;;;; ============================================================================
;;;; CHECKPOINT
;;;; ============================================================================

(defstruct (checkpoint
            (:constructor %make-checkpoint)
            (:copier nil)
            (:predicate checkpoint-p))
  "A blockchain checkpoint representing a verified state snapshot.

   Slots:
   - slot: Slot number of the checkpoint
   - epoch: Epoch number
   - block-root: 32-byte block hash
   - state-root: 32-byte state hash
   - timestamp: Unix timestamp when created
   - finalized-p: Whether this checkpoint is finalized"
  (slot 0 :type (integer 0 *) :read-only t)
  (epoch 0 :type (integer 0 *) :read-only t)
  (block-root (make-array 32 :element-type '(unsigned-byte 8) :initial-element 0)
   :type (simple-array (unsigned-byte 8) (32)) :read-only t)
  (state-root (make-array 32 :element-type '(unsigned-byte 8) :initial-element 0)
   :type (simple-array (unsigned-byte 8) (32)) :read-only t)
  (timestamp 0 :type (integer 0 *) :read-only t)
  (finalized-p nil :type boolean))

(defun make-checkpoint (&key (slot 0) (epoch 0) block-root state-root
                             (timestamp (current-timestamp)) (finalized-p nil))
  "Create a new checkpoint."
  (%make-checkpoint
   :slot slot
   :epoch epoch
   :block-root (if block-root
                   (coerce block-root '(simple-array (unsigned-byte 8) (32)))
                   (make-array 32 :element-type '(unsigned-byte 8) :initial-element 0))
   :state-root (if state-root
                   (coerce state-root '(simple-array (unsigned-byte 8) (32)))
                   (make-array 32 :element-type '(unsigned-byte 8) :initial-element 0))
   :timestamp timestamp
   :finalized-p finalized-p))

(defun checkpoint-valid-p (cp)
  "Check if a checkpoint is structurally valid."
  (and (checkpoint-p cp)
       (>= (checkpoint-slot cp) 0)
       (= (length (checkpoint-block-root cp)) 32)
       (= (length (checkpoint-state-root cp)) 32)
       (not (zero-hash-p (checkpoint-block-root cp)))))

;;;; ============================================================================
;;;; CHECKPOINT HEADER
;;;; ============================================================================

(defstruct (checkpoint-header
            (:constructor %make-checkpoint-header)
            (:copier nil)
            (:predicate checkpoint-header-p))
  "Checkpoint block header with essential fields.

   Slots:
   - slot: Slot number
   - proposer-index: Validator who proposed the block
   - parent-root: Hash of parent block
   - state-root: Post-state root
   - body-root: Hash of block body"
  (slot 0 :type (integer 0 *) :read-only t)
  (proposer-index 0 :type (integer 0 *) :read-only t)
  (parent-root (make-array 32 :element-type '(unsigned-byte 8) :initial-element 0)
   :type (simple-array (unsigned-byte 8) (32)) :read-only t)
  (state-root (make-array 32 :element-type '(unsigned-byte 8) :initial-element 0)
   :type (simple-array (unsigned-byte 8) (32)) :read-only t)
  (body-root (make-array 32 :element-type '(unsigned-byte 8) :initial-element 0)
   :type (simple-array (unsigned-byte 8) (32)) :read-only t))

(defun make-checkpoint-header (&key (slot 0) (proposer-index 0)
                                    parent-root state-root body-root)
  "Create a checkpoint header."
  (%make-checkpoint-header
   :slot slot
   :proposer-index proposer-index
   :parent-root (or parent-root (make-array 32 :element-type '(unsigned-byte 8) :initial-element 0))
   :state-root (or state-root (make-array 32 :element-type '(unsigned-byte 8) :initial-element 0))
   :body-root (or body-root (make-array 32 :element-type '(unsigned-byte 8) :initial-element 0))))

;;;; ============================================================================
;;;; CHECKPOINT STATE
;;;; ============================================================================

(defstruct (checkpoint-state
            (:constructor %make-checkpoint-state)
            (:copier nil)
            (:predicate checkpoint-state-p)
            (:conc-name cps-))
  "Checkpoint state summary.

   Slots:
   - root: State root hash
   - validators-root: Hash of validator set
   - balances-root: Hash of balances"
  (root (make-array 32 :element-type '(unsigned-byte 8) :initial-element 0)
   :type (simple-array (unsigned-byte 8) (32)) :read-only t)
  (validators-root (make-array 32 :element-type '(unsigned-byte 8) :initial-element 0)
   :type (simple-array (unsigned-byte 8) (32)) :read-only t)
  (balances-root (make-array 32 :element-type '(unsigned-byte 8) :initial-element 0)
   :type (simple-array (unsigned-byte 8) (32)) :read-only t))

(defun make-checkpoint-state (&key root validators-root balances-root)
  "Create a checkpoint state."
  (%make-checkpoint-state
   :root (or root (make-array 32 :element-type '(unsigned-byte 8) :initial-element 0))
   :validators-root (or validators-root (make-array 32 :element-type '(unsigned-byte 8) :initial-element 0))
   :balances-root (or balances-root (make-array 32 :element-type '(unsigned-byte 8) :initial-element 0))))


;;;; ============================================================================
;;;; CHECKPOINT PROOF
;;;; ============================================================================

(defstruct (checkpoint-proof
            (:constructor %make-checkpoint-proof)
            (:copier nil)
            (:predicate checkpoint-proof-p))
  "Merkle proof for a checkpoint.

   Slots:
   - branch: List of 32-byte sibling hashes
   - index: Leaf index in tree
   - leaf: 32-byte leaf value
   - root: Expected root hash"
  (branch nil :type list :read-only t)
  (index 0 :type (integer 0 *) :read-only t)
  (leaf (make-array 32 :element-type '(unsigned-byte 8) :initial-element 0)
   :type (simple-array (unsigned-byte 8) (32)) :read-only t)
  (root (make-array 32 :element-type '(unsigned-byte 8) :initial-element 0)
   :type (simple-array (unsigned-byte 8) (32)) :read-only t))

(defun make-checkpoint-proof (&key branch (index 0) leaf root)
  "Create a checkpoint proof."
  (%make-checkpoint-proof
   :branch branch
   :index index
   :leaf (or leaf (make-array 32 :element-type '(unsigned-byte 8) :initial-element 0))
   :root (or root (make-array 32 :element-type '(unsigned-byte 8) :initial-element 0))))

;;;; ============================================================================
;;;; CHECKPOINT BUNDLE
;;;; ============================================================================

(defstruct (checkpoint-bundle
            (:constructor %make-checkpoint-bundle)
            (:copier nil)
            (:predicate checkpoint-bundle-p))
  "Complete checkpoint bundle with state and proof.

   Slots:
   - checkpoint: The checkpoint
   - state: Associated state
   - proof: Merkle proof"
  (checkpoint nil :type (or null checkpoint) :read-only t)
  (state nil :type (or null checkpoint-state) :read-only t)
  (proof nil :type (or null checkpoint-proof) :read-only t))

(defun make-checkpoint-bundle (&key checkpoint state proof)
  "Create a checkpoint bundle."
  (%make-checkpoint-bundle
   :checkpoint checkpoint
   :state state
   :proof proof))

;;;; ============================================================================
;;;; WEAK SUBJECTIVITY CHECKPOINT
;;;; ============================================================================

(defstruct (ws-checkpoint
            (:constructor %make-ws-checkpoint)
            (:copier nil)
            (:predicate ws-checkpoint-p))
  "Weak subjectivity checkpoint for PoS chains.

   Slots:
   - block-root: Block root at WS checkpoint
   - state-root: State root at WS checkpoint
   - epoch: Epoch of the checkpoint"
  (block-root (make-array 32 :element-type '(unsigned-byte 8) :initial-element 0)
   :type (simple-array (unsigned-byte 8) (32)) :read-only t)
  (state-root (make-array 32 :element-type '(unsigned-byte 8) :initial-element 0)
   :type (simple-array (unsigned-byte 8) (32)) :read-only t)
  (epoch 0 :type (integer 0 *) :read-only t))

(defun make-ws-checkpoint (&key block-root state-root (epoch 0))
  "Create a weak subjectivity checkpoint."
  (%make-ws-checkpoint
   :block-root (or block-root (make-array 32 :element-type '(unsigned-byte 8) :initial-element 0))
   :state-root (or state-root (make-array 32 :element-type '(unsigned-byte 8) :initial-element 0))
   :epoch epoch))

;;;; ============================================================================
;;;; DATA CHUNK
;;;; ============================================================================

(defstruct (data-chunk
            (:constructor %make-data-chunk)
            (:copier nil)
            (:predicate data-chunk-p))
  "A chunk of data for resumable downloads.

   Slots:
   - index: Chunk index
   - data: Chunk bytes
   - hash: Hash of chunk data"
  (index 0 :type (integer 0 *) :read-only t)
  (data #() :type (simple-array (unsigned-byte 8) (*)) :read-only t)
  (hash nil :type (or null (simple-array (unsigned-byte 8) (32))) :read-only t))

(defun make-data-chunk (&key (index 0) data hash)
  "Create a data chunk."
  (let ((chunk-data (or data (make-array 0 :element-type '(unsigned-byte 8)))))
    (%make-data-chunk
     :index index
     :data chunk-data
     :hash (or hash (sha256 chunk-data)))))

;;;; ============================================================================
;;;; VERIFICATION RESULT
;;;; ============================================================================

(defstruct (verification-result
            (:constructor %make-verification-result)
            (:copier nil)
            (:predicate verification-result-p))
  "Result of a verification operation.

   Slots:
   - valid-p: Whether verification passed
   - error: Error message if failed"
  (valid-p nil :type boolean)
  (error nil :type (or null string)))

(defun make-verification-result (&key (valid-p nil) error)
  "Create a verification result."
  (%make-verification-result :valid-p valid-p :error error))

;;;; ============================================================================
;;;; PRINT METHODS
;;;; ============================================================================

(defmethod print-object ((obj checkpoint) stream)
  (print-unreadable-object (obj stream :type t)
    (format stream "slot=~D epoch=~D~@[ finalized~]"
            (checkpoint-slot obj)
            (checkpoint-epoch obj)
            (checkpoint-finalized-p obj))))

(defmethod print-object ((obj ws-checkpoint) stream)
  (print-unreadable-object (obj stream :type t)
    (format stream "epoch=~D root=~A"
            (ws-checkpoint-epoch obj)
            (bytes-to-hex (subseq (ws-checkpoint-block-root obj) 0 8)))))

(defmethod print-object ((obj data-chunk) stream)
  (print-unreadable-object (obj stream :type t)
    (format stream "index=~D size=~D"
            (data-chunk-index obj)
            (length (data-chunk-data obj)))))

;;;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;;;; SPDX-License-Identifier: Apache-2.0

;;;; CL-CHECKPOINT-SYNC - Verification Module
;;;;
;;;; Checkpoint and proof verification.

(in-package #:cl-checkpoint-sync)

;;;; ============================================================================
;;;; CHECKPOINT VERIFICATION
;;;; ============================================================================

(defun verify-checkpoint (checkpoint &key trusted-root)
  "Verify a checkpoint's validity.

   Arguments:
   - CHECKPOINT: checkpoint to verify
   - TRUSTED-ROOT: optional trusted state root to verify against

   Returns: verification-result"
  (cond
    ((not (checkpoint-p checkpoint))
     (make-verification-result :valid-p nil :error "Not a valid checkpoint"))
    ((not (checkpoint-valid-p checkpoint))
     (make-verification-result :valid-p nil :error "Checkpoint structure invalid"))
    ((and trusted-root
          (not (equalp (checkpoint-state-root checkpoint) trusted-root)))
     (make-verification-result :valid-p nil :error "State root mismatch"))
    (t
     (make-verification-result :valid-p t))))

(defun verify-checkpoint-proof (proof)
  "Verify a Merkle proof.

   Arguments:
   - PROOF: checkpoint-proof to verify

   Returns: verification-result"
  (unless (checkpoint-proof-p proof)
    (return-from verify-checkpoint-proof
      (make-verification-result :valid-p nil :error "Not a valid proof")))
  (let* ((branch (checkpoint-proof-branch proof))
         (index (checkpoint-proof-index proof))
         (leaf (checkpoint-proof-leaf proof))
         (expected-root (checkpoint-proof-root proof))
         (depth (length branch)))
    (if (verify-merkle-branch leaf branch expected-root depth index)
        (make-verification-result :valid-p t)
        (make-verification-result :valid-p nil :error "Merkle proof invalid"))))

(defun verify-state-root (state-root expected-root)
  "Verify a state root matches expected.

   Arguments:
   - STATE-ROOT: 32-byte state root hash
   - EXPECTED-ROOT: expected 32-byte hash

   Returns: t if match, nil otherwise"
  (and (= (length state-root) 32)
       (= (length expected-root) 32)
       (equalp state-root expected-root)))


(defun batch-verify-checkpoints (checkpoints)
  "Verify multiple checkpoints.

   Arguments:
   - CHECKPOINTS: list of checkpoints

   Returns: list of verification-results"
  (mapcar (lambda (cp) (verify-checkpoint cp)) checkpoints))

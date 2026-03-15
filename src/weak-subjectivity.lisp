;;;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;;;; SPDX-License-Identifier: Apache-2.0

;;;; CL-CHECKPOINT-SYNC - Weak Subjectivity Module
;;;;
;;;; Weak subjectivity period calculation and validation for PoS chains.

(in-package #:cl-checkpoint-sync)

;;;; ============================================================================
;;;; CONSTANTS
;;;; ============================================================================

(defvar *slots-per-epoch* 32
  "Number of slots per epoch.")

(defvar *seconds-per-slot* 12
  "Seconds per slot.")

(defvar *min-validator-withdrawability-delay* 256
  "Minimum epochs before validator can withdraw.")

(defvar *ws-safety-factor* 2
  "Safety factor for WS period calculation.")

;;;; ============================================================================
;;;; WS PERIOD CALCULATION
;;;; ============================================================================

(defun compute-ws-period (validator-count &key (churn-limit 4))
  "Compute the weak subjectivity period in epochs.

   Arguments:
   - VALIDATOR-COUNT: number of active validators
   - CHURN-LIMIT: maximum validator churn per epoch

   Returns: weak subjectivity period in epochs"
  (let* ((days-to-corrupt (/ validator-count (* churn-limit 3)))
         (epochs-to-corrupt (* days-to-corrupt 225)))  ; ~225 epochs/day
    (floor (* epochs-to-corrupt *ws-safety-factor*))))

(defun validate-ws-checkpoint (ws-checkpoint current-epoch)
  "Validate a weak subjectivity checkpoint.

   Arguments:
   - WS-CHECKPOINT: ws-checkpoint to validate
   - CURRENT-EPOCH: current epoch number

   Returns: verification-result"
  (unless (ws-checkpoint-p ws-checkpoint)
    (return-from validate-ws-checkpoint
      (make-verification-result :valid-p nil :error "Not a valid WS checkpoint")))
  (let ((ws-epoch (ws-checkpoint-epoch ws-checkpoint)))
    (cond
      ((> ws-epoch current-epoch)
       (make-verification-result :valid-p nil :error "WS checkpoint from future"))
      ((zero-hash-p (ws-checkpoint-block-root ws-checkpoint))
       (make-verification-result :valid-p nil :error "Invalid block root"))
      (t
       (make-verification-result :valid-p t)))))

(defun is-within-ws-period-p (ws-checkpoint current-epoch ws-period)
  "Check if current epoch is within the WS period.

   Arguments:
   - WS-CHECKPOINT: ws-checkpoint
   - CURRENT-EPOCH: current epoch
   - WS-PERIOD: weak subjectivity period in epochs

   Returns: t if within period"
  (let ((ws-epoch (ws-checkpoint-epoch ws-checkpoint)))
    (<= (- current-epoch ws-epoch) ws-period)))

(defun ws-checkpoint-expired-p (ws-checkpoint current-epoch ws-period)
  "Check if a WS checkpoint has expired.

   Arguments:
   - WS-CHECKPOINT: ws-checkpoint to check
   - CURRENT-EPOCH: current epoch
   - WS-PERIOD: weak subjectivity period in epochs

   Returns: t if expired"
  (not (is-within-ws-period-p ws-checkpoint current-epoch ws-period)))

;;;; ============================================================================
;;;; WS CHECKPOINT STORAGE
;;;; ============================================================================

(defvar *ws-checkpoint-store* (make-hash-table :test 'equal)
  "In-memory store for WS checkpoints.")

(defun store-ws-checkpoint (key ws-checkpoint)
  "Store a WS checkpoint.

   Arguments:
   - KEY: string key for the checkpoint
   - WS-CHECKPOINT: checkpoint to store"
  (setf (gethash key *ws-checkpoint-store*) ws-checkpoint))

(defun load-ws-checkpoint (key)
  "Load a WS checkpoint.

   Arguments:
   - KEY: string key

   Returns: ws-checkpoint or nil"
  (gethash key *ws-checkpoint-store*))

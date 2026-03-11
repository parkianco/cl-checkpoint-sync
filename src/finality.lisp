;;;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;;;; SPDX-License-Identifier: BSD-3-Clause

;;;; CL-CHECKPOINT-SYNC - Finality Module
;;;;
;;;; Finality providers for PoW, PoS, and hybrid consensus.

(in-package #:cl-checkpoint-sync)

;;;; ============================================================================
;;;; FINALITY PROVIDER
;;;; ============================================================================

(defstruct (finality-provider
            (:constructor %make-finality-provider)
            (:copier nil)
            (:predicate finality-provider-p))
  "Provider for finality checking.

   Slots:
   - type: :pow, :pos, or :hybrid
   - depth: confirmation depth for PoW
   - epochs: finalization epochs for PoS"
  (type :pow :type keyword)
  (depth 6 :type (integer 1 *))
  (epochs 2 :type (integer 1 *)))

(defun make-pow-finality-provider (&key (depth 6))
  "Create a PoW finality provider.

   Arguments:
   - DEPTH: number of confirmations required"
  (%make-finality-provider :type :pow :depth depth))

(defun make-pos-finality-provider (&key (epochs 2))
  "Create a PoS finality provider.

   Arguments:
   - EPOCHS: number of epochs for finalization"
  (%make-finality-provider :type :pos :epochs epochs))

(defun make-hybrid-finality-provider (&key (depth 6) (epochs 2))
  "Create a hybrid finality provider.

   Arguments:
   - DEPTH: PoW confirmation depth
   - EPOCHS: PoS finalization epochs"
  (%make-finality-provider :type :hybrid :depth depth :epochs epochs))

;;;; ============================================================================
;;;; FINALITY CHECKING
;;;; ============================================================================

(defun check-finality (provider checkpoint current-height)
  "Check if a checkpoint is finalized.

   Arguments:
   - PROVIDER: finality-provider
   - CHECKPOINT: checkpoint to check
   - CURRENT-HEIGHT: current chain height/slot

   Returns: t if finalized"
  (let ((cp-height (checkpoint-slot checkpoint)))
    (case (finality-provider-type provider)
      (:pow
       (>= (- current-height cp-height) (finality-provider-depth provider)))
      (:pos
       (checkpoint-finalized-p checkpoint))
      (:hybrid
       (and (>= (- current-height cp-height) (finality-provider-depth provider))
            (checkpoint-finalized-p checkpoint)))
      (otherwise nil))))

(defun get-finalized-checkpoint (provider checkpoints current-height)
  "Get the most recent finalized checkpoint.

   Arguments:
   - PROVIDER: finality-provider
   - CHECKPOINTS: list of checkpoints (sorted by slot descending)
   - CURRENT-HEIGHT: current chain height/slot

   Returns: finalized checkpoint or nil"
  (find-if (lambda (cp) (check-finality provider cp current-height))
           checkpoints))

(defun finality-depth (provider)
  "Get the finality depth/epochs for a provider.

   Arguments:
   - PROVIDER: finality-provider

   Returns: depth value"
  (case (finality-provider-type provider)
    (:pow (finality-provider-depth provider))
    (:pos (finality-provider-epochs provider))
    (:hybrid (max (finality-provider-depth provider)
                  (finality-provider-epochs provider)))
    (otherwise 6)))

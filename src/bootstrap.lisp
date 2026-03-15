;;;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;;;; SPDX-License-Identifier: Apache-2.0

;;;; CL-CHECKPOINT-SYNC - Bootstrap Module
;;;;
;;;; Checkpoint sync management and bootstrapping.

(in-package #:cl-checkpoint-sync)

;;;; ============================================================================
;;;; SYNC MANAGER
;;;; ============================================================================

(defstruct (checkpoint-sync-manager
            (:constructor %make-checkpoint-sync-manager)
            (:copier nil)
            (:predicate checkpoint-sync-manager-p))
  "Manager for checkpoint synchronization.

   Slots:
   - sources: source-registry for checkpoint sources
   - finality: finality-provider
   - download-config: download configuration
   - status: current sync status (:idle, :syncing, :complete, :error)
   - current-checkpoint: currently syncing checkpoint
   - error: error message if status is :error"
  (sources nil :type (or null source-registry))
  (finality nil :type (or null finality-provider))
  (download-config nil :type (or null download-config))
  (status :idle :type keyword)
  (current-checkpoint nil :type (or null checkpoint))
  (error nil :type (or null string)))

(defun make-checkpoint-sync-manager (&key sources finality download-config)
  "Create a checkpoint sync manager.

   Arguments:
   - SOURCES: source-registry
   - FINALITY: finality-provider
   - DOWNLOAD-CONFIG: download-config"
  (%make-checkpoint-sync-manager
   :sources (or sources (make-source-registry))
   :finality (or finality (make-pow-finality-provider))
   :download-config (or download-config (make-download-config))))

;;;; ============================================================================
;;;; SYNC OPERATIONS
;;;; ============================================================================

(defun start-sync (manager)
  "Start checkpoint synchronization.

   Arguments:
   - MANAGER: checkpoint-sync-manager

   Returns: manager with updated status"
  (setf (checkpoint-sync-manager-status manager) :syncing)
  (setf (checkpoint-sync-manager-error manager) nil)
  manager)

(defun stop-sync (manager)
  "Stop checkpoint synchronization.

   Arguments:
   - MANAGER: checkpoint-sync-manager

   Returns: manager with updated status"
  (setf (checkpoint-sync-manager-status manager) :idle)
  manager)

(defun get-sync-status (manager)
  "Get current sync status.

   Arguments:
   - MANAGER: checkpoint-sync-manager

   Returns: plist with status info"
  (list :status (checkpoint-sync-manager-status manager)
        :checkpoint (checkpoint-sync-manager-current-checkpoint manager)
        :error (checkpoint-sync-manager-error manager)))

;;;; ============================================================================
;;;; BOOTSTRAP FUNCTIONS
;;;; ============================================================================

(defun bootstrap-from-checkpoint (checkpoint &key state-dir)
  "Bootstrap node state from a checkpoint.

   Arguments:
   - CHECKPOINT: verified checkpoint to bootstrap from
   - STATE-DIR: directory for state files

   Returns: verification-result"
  (declare (ignore state-dir))
  (unless (checkpoint-p checkpoint)
    (return-from bootstrap-from-checkpoint
      (make-verification-result :valid-p nil :error "Invalid checkpoint")))
  (unless (checkpoint-finalized-p checkpoint)
    (return-from bootstrap-from-checkpoint
      (make-verification-result :valid-p nil :error "Checkpoint not finalized")))
  ;; Bootstrap would initialize state here
  (make-verification-result :valid-p t))

(defun sync-from-checkpoint (manager ws-checkpoint)
  "Sync from a weak subjectivity checkpoint.

   Arguments:
   - MANAGER: checkpoint-sync-manager
   - WS-CHECKPOINT: ws-checkpoint to sync from

   Returns: verification-result"
  (unless (ws-checkpoint-p ws-checkpoint)
    (return-from sync-from-checkpoint
      (make-verification-result :valid-p nil :error "Invalid WS checkpoint")))
  (start-sync manager)
  ;; Sync process would:
  ;; 1. Validate WS checkpoint
  ;; 2. Find trusted sources
  ;; 3. Download checkpoint data
  ;; 4. Verify and reconstruct state
  (setf (checkpoint-sync-manager-status manager) :complete)
  (make-verification-result :valid-p t))

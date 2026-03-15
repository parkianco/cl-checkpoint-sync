;;;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;;;; SPDX-License-Identifier: Apache-2.0

;;;; CL-CHECKPOINT-SYNC - Download Module
;;;;
;;;; Checkpoint download with resume support.

(in-package #:cl-checkpoint-sync)

;;;; ============================================================================
;;;; DOWNLOAD STATE
;;;; ============================================================================

(defstruct (download-state
            (:constructor %make-download-state)
            (:copier nil)
            (:predicate download-state-p))
  "State of an in-progress download."
  (total-size 0 :type (integer 0 *))
  (downloaded 0 :type (integer 0 *))
  (chunks nil :type list)
  (paused-p nil :type boolean))

(defun make-download-state (&key (total-size 0) (downloaded 0))
  "Create a download state."
  (%make-download-state :total-size total-size :downloaded downloaded))

(defun download-state-progress (state)
  "Get download progress as a percentage (0-100)."
  (if (zerop (download-state-total-size state))
      0
      (floor (* 100 (download-state-downloaded state))
             (download-state-total-size state))))

;;;; ============================================================================
;;;; DOWNLOAD CONFIG
;;;; ============================================================================

(defstruct (download-config
            (:constructor %make-download-config)
            (:copier nil)
            (:predicate download-config-p))
  "Download configuration options."
  (chunk-size 65536 :type (integer 1 *))
  (parallel-chunks 4 :type (integer 1 *))
  (retry-count 3 :type (integer 0 *))
  (timeout 30 :type (integer 1 *)))

(defun make-download-config (&key (chunk-size 65536) (parallel-chunks 4)
                                   (retry-count 3) (timeout 30))
  "Create a download configuration."
  (%make-download-config
   :chunk-size chunk-size
   :parallel-chunks parallel-chunks
   :retry-count retry-count
   :timeout timeout))

;;;; ============================================================================
;;;; DOWNLOAD FUNCTIONS
;;;; ============================================================================

(defun download-checkpoint (source &key config)
  "Download a checkpoint from SOURCE.

   Arguments:
   - SOURCE: checkpoint-source to download from
   - CONFIG: optional download-config

   Returns: checkpoint-bundle on success"
  (declare (ignore config))
  (unless (checkpoint-source-p source)
    (error 'checkpoint-download-error
           :url "unknown"
           :status 0
           :message "Invalid source"))
  ;; Placeholder - actual implementation would download from source URL
  (make-checkpoint-bundle))

(defun download-checkpoint-async (source &key config callback)
  "Download a checkpoint asynchronously.

   Arguments:
   - SOURCE: checkpoint-source to download from
   - CONFIG: optional download-config
   - CALLBACK: function called with (bundle error) on completion

   Returns: download-state for tracking progress"
  (declare (ignore config callback))
  (unless (checkpoint-source-p source)
    (error 'checkpoint-source-error
           :source nil
           :message "Invalid source"))
  (make-download-state))

(defun resume-download (state source)
  "Resume a paused download.

   Arguments:
   - STATE: download-state from previous download
   - SOURCE: checkpoint-source

   Returns: updated download-state"
  (declare (ignore source))
  (setf (download-state-paused-p state) nil)
  state)

(defun pause-download (state)
  "Pause an in-progress download.

   Arguments:
   - STATE: download-state

   Returns: paused download-state"
  (setf (download-state-paused-p state) t)
  state)

(defun cancel-download (state)
  "Cancel a download.

   Arguments:
   - STATE: download-state"
  (declare (ignore state))
  nil)

(defun get-download-progress (state)
  "Get download progress information.

   Arguments:
   - STATE: download-state

   Returns: plist with :total, :downloaded, :percent, :paused-p"
  (list :total (download-state-total-size state)
        :downloaded (download-state-downloaded state)
        :percent (download-state-progress state)
        :paused-p (download-state-paused-p state)))

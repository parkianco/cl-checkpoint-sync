;;;; CL-CHECKPOINT-SYNC - Standalone Package Definition
;;;;
;;;; Checkpoint-based fast sync for blockchain clients.
;;;; Provides snapshot-based state synchronization with download/verification.

(defpackage #:cl-checkpoint-sync
  (:nicknames #:checkpoint-sync #:cpsync)
  (:use #:cl)
  (:export
   ;; ========== TYPES ==========
   ;; Core checkpoint types
   #:checkpoint
   #:checkpoint-p
   #:make-checkpoint
   #:checkpoint-slot
   #:checkpoint-epoch
   #:checkpoint-block-root
   #:checkpoint-state-root
   #:checkpoint-timestamp
   #:checkpoint-finalized-p
   #:checkpoint-valid-p

   ;; Checkpoint header
   #:checkpoint-header
   #:checkpoint-header-p
   #:make-checkpoint-header
   #:checkpoint-header-slot
   #:checkpoint-header-proposer-index
   #:checkpoint-header-parent-root
   #:checkpoint-header-state-root
   #:checkpoint-header-body-root

   ;; Checkpoint state
   #:checkpoint-state
   #:checkpoint-state-p
   #:make-checkpoint-state
   #:checkpoint-state-root
   #:checkpoint-state-validators-root
   #:checkpoint-state-balances-root

   ;; Checkpoint proof
   #:checkpoint-proof
   #:checkpoint-proof-p
   #:make-checkpoint-proof
   #:checkpoint-proof-branch
   #:checkpoint-proof-index
   #:checkpoint-proof-leaf
   #:checkpoint-proof-root

   ;; Checkpoint bundle
   #:checkpoint-bundle
   #:checkpoint-bundle-p
   #:make-checkpoint-bundle
   #:checkpoint-bundle-checkpoint
   #:checkpoint-bundle-state
   #:checkpoint-bundle-proof

   ;; Weak subjectivity checkpoint
   #:ws-checkpoint
   #:ws-checkpoint-p
   #:make-ws-checkpoint
   #:ws-checkpoint-block-root
   #:ws-checkpoint-state-root
   #:ws-checkpoint-epoch

   ;; Data chunk for downloads
   #:data-chunk
   #:data-chunk-p
   #:make-data-chunk
   #:data-chunk-index
   #:data-chunk-data
   #:data-chunk-hash

   ;; ========== SOURCE DISCOVERY ==========
   #:checkpoint-source
   #:checkpoint-source-p
   #:make-checkpoint-source
   #:checkpoint-source-url
   #:checkpoint-source-type
   #:checkpoint-source-priority
   #:checkpoint-source-trusted-p

   #:source-registry
   #:make-source-registry
   #:register-source
   #:unregister-source
   #:get-sources
   #:get-trusted-sources
   #:rank-sources
   #:validate-source
   #:discover-sources

   ;; ========== DOWNLOAD ==========
   #:download-state
   #:download-state-p
   #:make-download-state
   #:download-state-total-size
   #:download-state-downloaded
   #:download-state-progress

   #:download-checkpoint
   #:download-checkpoint-async
   #:resume-download
   #:pause-download
   #:cancel-download
   #:get-download-progress

   #:download-config
   #:make-download-config
   #:download-config-chunk-size
   #:download-config-parallel-chunks
   #:download-config-retry-count
   #:download-config-timeout

   ;; ========== VERIFICATION ==========
   #:verify-checkpoint
   #:verify-checkpoint-proof
   #:verify-state-root
   #:verify-merkle-branch
   #:verify-signature
   #:batch-verify-checkpoints

   #:verification-result
   #:verification-result-p
   #:make-verification-result
   #:verification-result-valid-p
   #:verification-result-error

   ;; ========== FINALITY ==========
   #:finality-provider
   #:make-pow-finality-provider
   #:make-pos-finality-provider
   #:make-hybrid-finality-provider
   #:check-finality
   #:get-finalized-checkpoint
   #:finality-depth

   ;; ========== WEAK SUBJECTIVITY ==========
   #:compute-ws-period
   #:validate-ws-checkpoint
   #:is-within-ws-period-p
   #:store-ws-checkpoint
   #:load-ws-checkpoint
   #:ws-checkpoint-expired-p

   ;; ========== STATE RECONSTRUCTION ==========
   #:reconstruct-state
   #:apply-state-diff
   #:verify-reconstructed-state

   ;; ========== BOOTSTRAP ==========
   #:bootstrap-from-checkpoint
   #:sync-from-checkpoint
   #:checkpoint-sync-manager
   #:make-checkpoint-sync-manager
   #:start-sync
   #:stop-sync
   #:get-sync-status

   ;; ========== UTILITIES ==========
   #:bytes-to-hex
   #:hex-to-bytes
   #:compute-merkle-root
   #:copy-hash

   ;; ========== CONDITIONS ==========
   #:checkpoint-error
   #:checkpoint-download-error
   #:checkpoint-verification-error
   #:checkpoint-source-error
   #:ws-checkpoint-expired-error))

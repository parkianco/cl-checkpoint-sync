;;;; CL-CHECKPOINT-SYNC - Source Discovery and Management
;;;;
;;;; Checkpoint source discovery, validation, and ranking.

(in-package #:cl-checkpoint-sync)

;;;; ============================================================================
;;;; CHECKPOINT SOURCE
;;;; ============================================================================

(defstruct (checkpoint-source
            (:constructor %make-checkpoint-source)
            (:copier nil)
            (:predicate checkpoint-source-p))
  "A source for downloading checkpoints.

   Slots:
   - url: Source URL
   - type: Source type (:http :p2p :ipfs :s3 :local)
   - priority: Priority for source selection (higher = preferred)
   - trusted-p: Whether source is trusted
   - last-success: Timestamp of last successful download
   - failure-count: Number of consecutive failures
   - latency-ms: Average latency in milliseconds"
  (url "" :type string :read-only t)
  (type :http :type (member :http :p2p :ipfs :s3 :local) :read-only t)
  (priority 0 :type integer)
  (trusted-p nil :type boolean)
  (last-success 0 :type (integer 0 *))
  (failure-count 0 :type (integer 0 *))
  (latency-ms 0 :type (integer 0 *)))

(defun make-checkpoint-source (&key url (type :http) (priority 0) (trusted-p nil))
  "Create a checkpoint source."
  (%make-checkpoint-source
   :url url
   :type type
   :priority priority
   :trusted-p trusted-p))

;;;; ============================================================================
;;;; SOURCE REGISTRY
;;;; ============================================================================

(defstruct (source-registry
            (:constructor %make-source-registry)
            (:copier nil)
            (:predicate source-registry-p))
  "Registry of checkpoint sources.

   Slots:
   - sources: Hash table of URL -> source
   - trusted-sources: List of trusted source URLs
   - lock: Mutex for thread safety"
  (sources (make-hash-table :test 'equal) :type hash-table)
  (trusted-sources nil :type list)
  (lock (sb-thread:make-mutex :name "source-registry-lock") :read-only t))

(defun make-source-registry ()
  "Create a new source registry."
  (%make-source-registry))

(defun register-source (registry source)
  "Register a checkpoint source.

   Arguments:
   - REGISTRY: Source registry
   - SOURCE: Checkpoint source to register

   Returns: T on success"
  (sb-thread:with-mutex ((source-registry-lock registry))
    (setf (gethash (checkpoint-source-url source)
                   (source-registry-sources registry))
          source)
    (when (checkpoint-source-trusted-p source)
      (pushnew (checkpoint-source-url source)
               (source-registry-trusted-sources registry)
               :test #'equal))
    t))

(defun unregister-source (registry url)
  "Unregister a checkpoint source.

   Arguments:
   - REGISTRY: Source registry
   - URL: Source URL to unregister

   Returns: T if removed, NIL if not found"
  (sb-thread:with-mutex ((source-registry-lock registry))
    (let ((removed (remhash url (source-registry-sources registry))))
      (setf (source-registry-trusted-sources registry)
            (remove url (source-registry-trusted-sources registry) :test #'equal))
      removed)))

(defun get-sources (registry &key type)
  "Get all sources from registry.

   Arguments:
   - REGISTRY: Source registry
   - TYPE: Optional type filter

   Returns: List of sources"
  (sb-thread:with-mutex ((source-registry-lock registry))
    (let ((sources nil))
      (maphash (lambda (url source)
                 (declare (ignore url))
                 (when (or (null type)
                           (eq (checkpoint-source-type source) type))
                   (push source sources)))
               (source-registry-sources registry))
      sources)))

(defun get-trusted-sources (registry)
  "Get all trusted sources.

   Arguments:
   - REGISTRY: Source registry

   Returns: List of trusted sources"
  (sb-thread:with-mutex ((source-registry-lock registry))
    (loop for url in (source-registry-trusted-sources registry)
          for source = (gethash url (source-registry-sources registry))
          when source collect source)))

(defun rank-sources (sources)
  "Rank sources by quality (priority, latency, failure count).

   Arguments:
   - SOURCES: List of sources

   Returns: Sorted list (best first)"
  (sort (copy-list sources)
        (lambda (a b)
          (let ((score-a (compute-source-score a))
                (score-b (compute-source-score b)))
            (> score-a score-b)))))

(defun compute-source-score (source)
  "Compute a score for source ranking.

   Arguments:
   - SOURCE: Checkpoint source

   Returns: Numeric score (higher is better)"
  (let ((score (checkpoint-source-priority source)))
    ;; Bonus for trusted
    (when (checkpoint-source-trusted-p source)
      (incf score 1000))
    ;; Penalty for failures
    (decf score (* 100 (checkpoint-source-failure-count source)))
    ;; Penalty for high latency
    (decf score (floor (checkpoint-source-latency-ms source) 100))
    ;; Bonus for recent success
    (when (> (checkpoint-source-last-success source) 0)
      (let ((age (- (current-timestamp) (checkpoint-source-last-success source))))
        (when (< age 3600)  ; Within last hour
          (incf score 100))))
    score))

(defun validate-source (source &key (timeout 5000))
  "Validate that a source is reachable.

   Arguments:
   - SOURCE: Checkpoint source
   - TIMEOUT: Timeout in milliseconds

   Returns: (values reachable-p latency-ms)"
  (declare (ignore timeout))
  ;; Placeholder - in production, would make HTTP request
  (case (checkpoint-source-type source)
    (:local
     (values t 0))
    (otherwise
     ;; Would check connectivity here
     (values t 100))))

(defun discover-sources (&key (type :http) (trusted-only nil))
  "Discover checkpoint sources.

   Arguments:
   - TYPE: Source type to discover
   - TRUSTED-ONLY: Only return trusted sources

   Returns: List of discovered sources

   Note: Placeholder - in production would query DNS, DHT, etc."
  (declare (ignore type trusted-only))
  ;; Placeholder: return empty list
  ;; In production, would discover from:
  ;; - DNS TXT records
  ;; - DHT queries
  ;; - Hardcoded bootstrap sources
  nil)

;;;; ============================================================================
;;;; SOURCE HEALTH TRACKING
;;;; ============================================================================

(defun record-source-success (source latency-ms)
  "Record a successful operation on a source.

   Arguments:
   - SOURCE: Checkpoint source
   - LATENCY-MS: Operation latency"
  (setf (checkpoint-source-last-success source) (current-timestamp))
  (setf (checkpoint-source-failure-count source) 0)
  ;; Exponential moving average for latency
  (setf (checkpoint-source-latency-ms source)
        (floor (+ (* 0.8 (checkpoint-source-latency-ms source))
                  (* 0.2 latency-ms)))))

(defun record-source-failure (source)
  "Record a failed operation on a source.

   Arguments:
   - SOURCE: Checkpoint source"
  (incf (checkpoint-source-failure-count source)))

(defun source-healthy-p (source &key (max-failures 5))
  "Check if a source is healthy.

   Arguments:
   - SOURCE: Checkpoint source
   - MAX-FAILURES: Maximum consecutive failures

   Returns: T if healthy"
  (< (checkpoint-source-failure-count source) max-failures))

;;;; ============================================================================
;;;; PRINT METHODS
;;;; ============================================================================

(defmethod print-object ((obj checkpoint-source) stream)
  (print-unreadable-object (obj stream :type t)
    (format stream "~A ~A~@[ trusted~]"
            (checkpoint-source-type obj)
            (checkpoint-source-url obj)
            (checkpoint-source-trusted-p obj))))

(defmethod print-object ((obj source-registry) stream)
  (print-unreadable-object (obj stream :type t)
    (format stream "~D sources (~D trusted)"
            (hash-table-count (source-registry-sources obj))
            (length (source-registry-trusted-sources obj)))))

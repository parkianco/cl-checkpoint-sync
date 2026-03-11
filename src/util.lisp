;;;; CL-CHECKPOINT-SYNC - Utilities
;;;;
;;;; Common utility functions for the checkpoint sync library.

(in-package #:cl-checkpoint-sync)

;;;; ============================================================================
;;;; HEX ENCODING
;;;; ============================================================================

(defun bytes-to-hex (bytes)
  "Convert a byte array to hexadecimal string.

   Arguments:
   - BYTES: Array of unsigned bytes

   Returns: Lowercase hex string"
  (with-output-to-string (s)
    (loop for byte across bytes
          do (format s "~2,'0x" byte))))

(defun hex-to-bytes (hex-string)
  "Convert a hexadecimal string to byte array.

   Arguments:
   - HEX-STRING: String of hex characters (with or without 0x prefix)

   Returns: Simple array of unsigned bytes"
  (let* ((str (if (and (>= (length hex-string) 2)
                       (string= (subseq hex-string 0 2) "0x"))
                  (subseq hex-string 2)
                  hex-string))
         (len (length str))
         (bytes (make-array (floor len 2) :element-type '(unsigned-byte 8))))
    (loop for i from 0 below (floor len 2)
          do (setf (aref bytes i)
                   (parse-integer str :start (* i 2) :end (+ (* i 2) 2) :radix 16)))
    bytes))

;;;; ============================================================================
;;;; HASH UTILITIES
;;;; ============================================================================

(defun copy-hash (hash)
  "Create a copy of a 32-byte hash.

   Arguments:
   - HASH: 32-byte array

   Returns: New array with same contents"
  (when hash
    (let ((copy (make-array 32 :element-type '(unsigned-byte 8))))
      (replace copy hash)
      copy)))

(defun hash-equal-p (hash1 hash2)
  "Check if two hashes are equal.

   Arguments:
   - HASH1, HASH2: 32-byte arrays

   Returns: T if equal, NIL otherwise"
  (and hash1 hash2
       (= (length hash1) (length hash2) 32)
       (loop for i from 0 below 32
             always (= (aref hash1 i) (aref hash2 i)))))

(defun zero-hash-p (hash)
  "Check if a hash is all zeros.

   Arguments:
   - HASH: Byte array

   Returns: T if all zeros"
  (and hash (every #'zerop hash)))

;;;; ============================================================================
;;;; MERKLE TREE
;;;; ============================================================================

(defun compute-merkle-root (leaves)
  "Compute the Merkle root of a list of 32-byte leaves.

   Arguments:
   - LEAVES: List of 32-byte arrays

   Returns: 32-byte root hash

   Note: Uses SHA256 from crypto.lisp"
  (if (null leaves)
      (make-array 32 :element-type '(unsigned-byte 8) :initial-element 0)
      (let ((current (mapcar #'copy-hash leaves)))
        ;; Pad to power of 2
        (loop while (not (zerop (logand (length current) (1- (length current)))))
              do (push (make-array 32 :element-type '(unsigned-byte 8) :initial-element 0)
                       (cdr (last current))))
        ;; Build tree bottom-up
        (loop while (> (length current) 1)
              do (setf current
                       (loop for (left right) on current by #'cddr
                             collect (hash-pair left (or right left)))))
        (first current))))

(defun hash-pair (left right)
  "Hash two 32-byte values together.

   Arguments:
   - LEFT, RIGHT: 32-byte arrays

   Returns: 32-byte hash"
  (let ((combined (make-array 64 :element-type '(unsigned-byte 8))))
    (replace combined left)
    (replace combined right :start1 32)
    (sha256 combined)))

(defun verify-merkle-branch (leaf branch root depth index)
  "Verify a Merkle branch proof.

   Arguments:
   - LEAF: 32-byte leaf value
   - BRANCH: List of 32-byte sibling hashes
   - ROOT: Expected 32-byte root
   - DEPTH: Tree depth
   - INDEX: Leaf index

   Returns: T if proof is valid, NIL otherwise"
  (when (and leaf branch root (= (length branch) depth))
    (let ((computed leaf))
      (loop for i from 0 below depth
            for sibling in branch
            do (setf computed
                     (if (logbitp i index)
                         (hash-pair sibling computed)
                         (hash-pair computed sibling))))
      (hash-equal-p computed root))))

;;;; ============================================================================
;;;; BYTE UTILITIES
;;;; ============================================================================

(defun read-uint64-le (bytes &optional (offset 0))
  "Read an unsigned 64-bit little-endian integer.

   Arguments:
   - BYTES: Byte array
   - OFFSET: Starting position

   Returns: Integer value"
  (loop for i from 0 below 8
        sum (ash (aref bytes (+ offset i)) (* i 8))))

(defun write-uint64-le (value bytes &optional (offset 0))
  "Write an unsigned 64-bit little-endian integer.

   Arguments:
   - VALUE: Integer to write
   - BYTES: Destination byte array
   - OFFSET: Starting position"
  (loop for i from 0 below 8
        do (setf (aref bytes (+ offset i)) (ldb (byte 8 (* i 8)) value))))

(defun read-uint32-le (bytes &optional (offset 0))
  "Read an unsigned 32-bit little-endian integer."
  (loop for i from 0 below 4
        sum (ash (aref bytes (+ offset i)) (* i 8))))

(defun write-uint32-le (value bytes &optional (offset 0))
  "Write an unsigned 32-bit little-endian integer."
  (loop for i from 0 below 4
        do (setf (aref bytes (+ offset i)) (ldb (byte 8 (* i 8)) value))))

;;;; ============================================================================
;;;; TIME UTILITIES
;;;; ============================================================================

(defun current-timestamp ()
  "Get current Unix timestamp."
  (- (get-universal-time) 2208988800))  ; Adjust from 1900 to 1970 epoch

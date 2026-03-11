;;;; CL-CHECKPOINT-SYNC - Cryptographic Primitives
;;;;
;;;; SHA256 and signature verification stubs.
;;;; SHA256 is implemented inline for standalone operation.

(in-package #:cl-checkpoint-sync)

;;;; ============================================================================
;;;; SHA256 IMPLEMENTATION
;;;; ============================================================================

(defconstant +sha256-k+
  #(#x428a2f98 #x71374491 #xb5c0fbcf #xe9b5dba5
    #x3956c25b #x59f111f1 #x923f82a4 #xab1c5ed5
    #xd807aa98 #x12835b01 #x243185be #x550c7dc3
    #x72be5d74 #x80deb1fe #x9bdc06a7 #xc19bf174
    #xe49b69c1 #xefbe4786 #x0fc19dc6 #x240ca1cc
    #x2de92c6f #x4a7484aa #x5cb0a9dc #x76f988da
    #x983e5152 #xa831c66d #xb00327c8 #xbf597fc7
    #xc6e00bf3 #xd5a79147 #x06ca6351 #x14292967
    #x27b70a85 #x2e1b2138 #x4d2c6dfc #x53380d13
    #x650a7354 #x766a0abb #x81c2c92e #x92722c85
    #xa2bfe8a1 #xa81a664b #xc24b8b70 #xc76c51a3
    #xd192e819 #xd6990624 #xf40e3585 #x106aa070
    #x19a4c116 #x1e376c08 #x2748774c #x34b0bcb5
    #x391c0cb3 #x4ed8aa4a #x5b9cca4f #x682e6ff3
    #x748f82ee #x78a5636f #x84c87814 #x8cc70208
    #x90befffa #xa4506ceb #xbef9a3f7 #xc67178f2)
  "SHA256 round constants.")

(defconstant +sha256-h0+
  #(#x6a09e667 #xbb67ae85 #x3c6ef372 #xa54ff53a
    #x510e527f #x9b05688c #x1f83d9ab #x5be0cd19)
  "SHA256 initial hash values.")

(declaim (inline sha256-rotr sha256-ch sha256-maj sha256-sigma0 sha256-sigma1
                 sha256-sum0 sha256-sum1))

(defun sha256-rotr (x n)
  "Rotate right for 32-bit words."
  (declare (type (unsigned-byte 32) x)
           (type (integer 0 31) n))
  (logior (ash x (- n)) (logand #xFFFFFFFF (ash x (- 32 n)))))

(defun sha256-ch (x y z)
  (declare (type (unsigned-byte 32) x y z))
  (logxor (logand x y) (logand (lognot x) z)))

(defun sha256-maj (x y z)
  (declare (type (unsigned-byte 32) x y z))
  (logxor (logand x y) (logand x z) (logand y z)))

(defun sha256-sigma0 (x)
  (declare (type (unsigned-byte 32) x))
  (logxor (sha256-rotr x 2) (sha256-rotr x 13) (sha256-rotr x 22)))

(defun sha256-sigma1 (x)
  (declare (type (unsigned-byte 32) x))
  (logxor (sha256-rotr x 6) (sha256-rotr x 11) (sha256-rotr x 25)))

(defun sha256-sum0 (x)
  (declare (type (unsigned-byte 32) x))
  (logxor (sha256-rotr x 7) (sha256-rotr x 18) (ash x -3)))

(defun sha256-sum1 (x)
  (declare (type (unsigned-byte 32) x))
  (logxor (sha256-rotr x 17) (sha256-rotr x 19) (ash x -10)))

(defun sha256-pad-message (message)
  "Pad message according to SHA256 spec."
  (let* ((len (length message))
         (bit-len (* len 8))
         (padded-len (* 64 (ceiling (+ len 9) 64)))
         (padded (make-array padded-len :element-type '(unsigned-byte 8) :initial-element 0)))
    (replace padded message)
    (setf (aref padded len) #x80)
    ;; Write length as big-endian 64-bit at end
    (loop for i from 0 below 8
          do (setf (aref padded (- padded-len 1 i))
                   (ldb (byte 8 (* i 8)) bit-len)))
    padded))

(defun sha256-process-block (block h)
  "Process one 64-byte block."
  (let ((w (make-array 64 :element-type '(unsigned-byte 32))))
    ;; Expand message into schedule
    (loop for i from 0 below 16
          do (setf (aref w i)
                   (logior (ash (aref block (* i 4)) 24)
                           (ash (aref block (+ (* i 4) 1)) 16)
                           (ash (aref block (+ (* i 4) 2)) 8)
                           (aref block (+ (* i 4) 3)))))
    (loop for i from 16 below 64
          do (setf (aref w i)
                   (logand #xFFFFFFFF
                           (+ (sha256-sum1 (aref w (- i 2)))
                              (aref w (- i 7))
                              (sha256-sum0 (aref w (- i 15)))
                              (aref w (- i 16))))))
    ;; Working variables
    (let ((a (aref h 0)) (b (aref h 1)) (c (aref h 2)) (d (aref h 3))
          (e (aref h 4)) (f (aref h 5)) (g (aref h 6)) (hh (aref h 7)))
      (declare (type (unsigned-byte 32) a b c d e f g hh))
      ;; Main loop
      (loop for i from 0 below 64
            do (let* ((t1 (logand #xFFFFFFFF
                                  (+ hh (sha256-sigma1 e) (sha256-ch e f g)
                                     (aref +sha256-k+ i) (aref w i))))
                      (t2 (logand #xFFFFFFFF
                                  (+ (sha256-sigma0 a) (sha256-maj a b c)))))
                 (setf hh g g f f e (logand #xFFFFFFFF (+ d t1))
                       d c c b b a a (logand #xFFFFFFFF (+ t1 t2)))))
      ;; Add to hash
      (setf (aref h 0) (logand #xFFFFFFFF (+ (aref h 0) a))
            (aref h 1) (logand #xFFFFFFFF (+ (aref h 1) b))
            (aref h 2) (logand #xFFFFFFFF (+ (aref h 2) c))
            (aref h 3) (logand #xFFFFFFFF (+ (aref h 3) d))
            (aref h 4) (logand #xFFFFFFFF (+ (aref h 4) e))
            (aref h 5) (logand #xFFFFFFFF (+ (aref h 5) f))
            (aref h 6) (logand #xFFFFFFFF (+ (aref h 6) g))
            (aref h 7) (logand #xFFFFFFFF (+ (aref h 7) hh))))))

(defun sha256 (message)
  "Compute SHA256 hash of MESSAGE.

   Arguments:
   - MESSAGE: Byte array or string

   Returns: 32-byte hash array"
  (let* ((bytes (if (stringp message)
                    (map '(vector (unsigned-byte 8)) #'char-code message)
                    message))
         (padded (sha256-pad-message bytes))
         (h (copy-seq +sha256-h0+)))
    ;; Process each 64-byte block
    (loop for i from 0 below (length padded) by 64
          do (sha256-process-block (subseq padded i (+ i 64)) h))
    ;; Convert to bytes
    (let ((result (make-array 32 :element-type '(unsigned-byte 8))))
      (loop for i from 0 below 8
            do (loop for j from 0 below 4
                     do (setf (aref result (+ (* i 4) j))
                              (ldb (byte 8 (* (- 3 j) 8)) (aref h i)))))
      result)))

;;;; ============================================================================
;;;; DOUBLE SHA256
;;;; ============================================================================

(defun sha256d (message)
  "Compute double SHA256 (SHA256(SHA256(message))).

   Arguments:
   - MESSAGE: Byte array or string

   Returns: 32-byte hash array"
  (sha256 (sha256 message)))

;;;; ============================================================================
;;;; SIGNATURE VERIFICATION (PLACEHOLDER)
;;;; ============================================================================

(defun verify-signature (public-key message signature)
  "Verify a cryptographic signature (placeholder).

   Arguments:
   - PUBLIC-KEY: Public key bytes
   - MESSAGE: Message that was signed
   - SIGNATURE: Signature to verify

   Returns: T if valid, NIL otherwise

   Note: This is a placeholder. In production, integrate with
   secp256k1 or BLS signature verification."
  (declare (ignore message))
  ;; Placeholder: check that key and signature are well-formed
  (and public-key
       signature
       (>= (length public-key) 32)
       (>= (length signature) 64)))

(defun verify-aggregate-signature (public-keys message signature)
  "Verify an aggregate signature (placeholder).

   Arguments:
   - PUBLIC-KEYS: List of public keys
   - MESSAGE: Message that was signed
   - SIGNATURE: Aggregate signature

   Returns: T if valid, NIL otherwise"
  (declare (ignore message))
  (and public-keys
       signature
       (> (length public-keys) 0)
       (>= (length signature) 64)))

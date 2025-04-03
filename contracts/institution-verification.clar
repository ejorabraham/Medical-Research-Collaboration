;; Institution Verification Contract
;; This contract validates legitimate research entities

(define-data-var admin principal tx-sender)

;; Map to store verified institutions
(define-map verified-institutions principal bool)

;; Error codes
(define-constant ERR_UNAUTHORIZED u1)
(define-constant ERR_ALREADY_VERIFIED u2)
(define-constant ERR_NOT_FOUND u3)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin))
)

;; Add a new verified institution
(define-public (verify-institution (institution principal))
  (begin
    (asserts! (is-admin) (err ERR_UNAUTHORIZED))
    (asserts! (is-none (map-get? verified-institutions institution)) (err ERR_ALREADY_VERIFIED))

    (map-set verified-institutions institution true)
    (ok true)
  )
)

;; Revoke verification status
(define-public (revoke-verification (institution principal))
  (begin
    (asserts! (is-admin) (err ERR_UNAUTHORIZED))
    (asserts! (is-some (map-get? verified-institutions institution)) (err ERR_NOT_FOUND))

    (map-delete verified-institutions institution)
    (ok true)
  )
)

;; Check if an institution is verified
(define-read-only (is-verified (institution principal))
  (default-to false (map-get? verified-institutions institution))
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-admin) (err ERR_UNAUTHORIZED))
    (var-set admin new-admin)
    (ok true)
  )
)


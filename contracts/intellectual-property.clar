;; Intellectual Property Contract
;; Manages rights to discoveries and innovations

(define-data-var admin principal tx-sender)

;; Map to store verified institutions
(define-map verified-institutions principal bool)

;; IP asset structure
(define-map ip-assets uint
  {
    title: (string-utf8 100),
    description: (string-utf8 500),
    creators: (list 10 principal),
    owner: principal,
    creation-date: uint,
    hash: (buff 32),
    license-type: (string-utf8 50)
  }
)

;; License agreements
(define-map license-agreements uint
  {
    ip-id: uint,
    licensee: principal,
    terms: (string-utf8 500),
    start-date: uint,
    end-date: uint
  }
)

;; Counters
(define-data-var ip-id-counter uint u0)
(define-data-var license-id-counter uint u0)

;; Error codes
(define-constant ERR_UNAUTHORIZED u1)
(define-constant ERR_NOT_FOUND u2)
(define-constant ERR_INVALID_INPUT u3)

;; Admin functions to manage verified institutions
(define-public (add-verified-institution (institution principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err ERR_UNAUTHORIZED))
    (map-set verified-institutions institution true)
    (ok true)
  )
)

(define-public (remove-verified-institution (institution principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err ERR_UNAUTHORIZED))
    (map-delete verified-institutions institution)
    (ok true)
  )
)

;; Check if institution is verified
(define-private (is-verified-institution (institution principal))
  (default-to false (map-get? verified-institutions institution))
)

;; Register new intellectual property
(define-public (register-ip
    (title (string-utf8 100))
    (description (string-utf8 500))
    (creators (list 10 principal))
    (ip-hash (buff 32))
    (license-type (string-utf8 50)))
  (let ((new-id (var-get ip-id-counter)))
    (asserts! (is-verified-institution tx-sender) (err ERR_UNAUTHORIZED))

    (map-set ip-assets new-id
      {
        title: title,
        description: description,
        creators: creators,
        owner: tx-sender,
        creation-date: block-height,
        hash: ip-hash,
        license-type: license-type
      }
    )

    (var-set ip-id-counter (+ new-id u1))
    (ok new-id)
  )
)

;; Transfer IP ownership
(define-public (transfer-ip-ownership (ip-id uint) (new-owner principal))
  (let ((ip (map-get? ip-assets ip-id)))
    (asserts! (is-some ip) (err ERR_NOT_FOUND))
    (asserts! (is-eq (get owner (unwrap-panic ip)) tx-sender) (err ERR_UNAUTHORIZED))
    (asserts! (is-verified-institution new-owner) (err ERR_UNAUTHORIZED))

    (map-set ip-assets ip-id
      (merge (unwrap-panic ip)
        {
          owner: new-owner
        }
      )
    )
    (ok true)
  )
)

;; Create a license agreement
(define-public (create-license
    (ip-id uint)
    (licensee principal)
    (terms (string-utf8 500))
    (duration uint))
  (let (
      (new-id (var-get license-id-counter))
      (ip (map-get? ip-assets ip-id))
    )
    (asserts! (is-some ip) (err ERR_NOT_FOUND))
    (asserts! (is-eq (get owner (unwrap-panic ip)) tx-sender) (err ERR_UNAUTHORIZED))
    (asserts! (is-verified-institution licensee) (err ERR_UNAUTHORIZED))

    (map-set license-agreements new-id
      {
        ip-id: ip-id,
        licensee: licensee,
        terms: terms,
        start-date: block-height,
        end-date: (+ block-height duration)
      }
    )

    (var-set license-id-counter (+ new-id u1))
    (ok new-id)
  )
)

;; Get IP details
(define-read-only (get-ip-details (ip-id uint))
  (map-get? ip-assets ip-id)
)

;; Get license details
(define-read-only (get-license-details (license-id uint))
  (map-get? license-agreements license-id)
)


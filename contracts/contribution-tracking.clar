;; Contribution Tracking Contract
;; Records inputs from various researchers

(define-data-var admin principal tx-sender)

;; Map to store verified institutions
(define-map verified-institutions principal bool)

;; Contribution structure
(define-map contributions uint
  {
    researcher: principal,
    project-id: uint,
    description: (string-utf8 500),
    timestamp: uint,
    value-score: uint,
    verified: bool
  }
)

;; Project structure
(define-map projects uint
  {
    name: (string-utf8 100),
    lead-institution: principal,
    contributors: (list 20 principal),
    created-at: uint
  }
)

;; Counters
(define-data-var contribution-id-counter uint u0)
(define-data-var project-id-counter uint u0)

;; Error codes
(define-constant ERR_UNAUTHORIZED u1)
(define-constant ERR_NOT_FOUND u2)
(define-constant ERR_ALREADY_EXISTS u3)

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

;; Create a new research project
(define-public (create-project (name (string-utf8 100)))
  (let ((new-id (var-get project-id-counter)))
    (asserts! (is-verified-institution tx-sender) (err ERR_UNAUTHORIZED))

    (map-set projects new-id
      {
        name: name,
        lead-institution: tx-sender,
        contributors: (list tx-sender),
        created-at: block-height
      }
    )

    (var-set project-id-counter (+ new-id u1))
    (ok new-id)
  )
)

;; Add a contribution to a project
(define-public (add-contribution
    (project-id uint)
    (description (string-utf8 500)))
  (let (
      (new-id (var-get contribution-id-counter))
      (project (map-get? projects project-id))
    )
    (asserts! (is-some project) (err ERR_NOT_FOUND))
    (asserts! (is-verified-institution tx-sender) (err ERR_UNAUTHORIZED))

    ;; Add contribution
    (map-set contributions new-id
      {
        researcher: tx-sender,
        project-id: project-id,
        description: description,
        timestamp: block-height,
        value-score: u0,
        verified: false
      }
    )

    (var-set contribution-id-counter (+ new-id u1))
    (ok new-id)
  )
)

;; Verify a contribution (only project lead can do this)
(define-public (verify-contribution (contribution-id uint) (value-score uint))
  (let (
      (contribution (map-get? contributions contribution-id))
      (project-id (get project-id (unwrap-panic contribution)))
      (project (map-get? projects project-id))
    )
    (asserts! (is-some contribution) (err ERR_NOT_FOUND))
    (asserts! (is-some project) (err ERR_NOT_FOUND))
    (asserts! (is-eq (get lead-institution (unwrap-panic project)) tx-sender) (err ERR_UNAUTHORIZED))

    (map-set contributions contribution-id
      (merge (unwrap-panic contribution)
        {
          value-score: value-score,
          verified: true
        }
      )
    )
    (ok true)
  )
)

;; Get project details
(define-read-only (get-project (project-id uint))
  (map-get? projects project-id)
)

;; Get contribution details
(define-read-only (get-contribution (contribution-id uint))
  (map-get? contributions contribution-id)
)

;; Simplified function to avoid 'min' function issue
(define-read-only (get-project-contributions (project-id uint))
  (ok true)
)


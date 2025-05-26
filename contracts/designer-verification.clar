;; Designer Verification Contract
;; Validates and manages product designers in the circular design ecosystem

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_DESIGNER_EXISTS (err u101))
(define-constant ERR_DESIGNER_NOT_FOUND (err u102))
(define-constant ERR_INVALID_CREDENTIALS (err u103))

;; Designer data structure
(define-map designers
  { designer-id: principal }
  {
    name: (string-ascii 100),
    certification-level: uint,
    specialization: (string-ascii 50),
    verified: bool,
    registration-date: uint
  }
)

;; Designer credentials tracking
(define-map designer-credentials
  { designer-id: principal }
  {
    education: (string-ascii 200),
    experience-years: uint,
    certifications: (list 10 (string-ascii 100)),
    portfolio-hash: (string-ascii 64)
  }
)

;; Register a new designer
(define-public (register-designer
  (name (string-ascii 100))
  (specialization (string-ascii 50))
  (education (string-ascii 200))
  (experience-years uint)
  (certifications (list 10 (string-ascii 100)))
  (portfolio-hash (string-ascii 64)))
  (let ((designer-id tx-sender))
    (asserts! (is-none (map-get? designers { designer-id: designer-id })) ERR_DESIGNER_EXISTS)
    (map-set designers
      { designer-id: designer-id }
      {
        name: name,
        certification-level: u1,
        specialization: specialization,
        verified: false,
        registration-date: block-height
      }
    )
    (map-set designer-credentials
      { designer-id: designer-id }
      {
        education: education,
        experience-years: experience-years,
        certifications: certifications,
        portfolio-hash: portfolio-hash
      }
    )
    (ok designer-id)
  )
)

;; Verify a designer (only contract owner)
(define-public (verify-designer (designer-id principal) (certification-level uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-some (map-get? designers { designer-id: designer-id })) ERR_DESIGNER_NOT_FOUND)
    (map-set designers
      { designer-id: designer-id }
      (merge
        (unwrap-panic (map-get? designers { designer-id: designer-id }))
        { verified: true, certification-level: certification-level }
      )
    )
    (ok true)
  )
)

;; Get designer information
(define-read-only (get-designer (designer-id principal))
  (map-get? designers { designer-id: designer-id })
)

;; Check if designer is verified
(define-read-only (is-designer-verified (designer-id principal))
  (match (map-get? designers { designer-id: designer-id })
    designer (get verified designer)
    false
  )
)

;; Get designer credentials
(define-read-only (get-designer-credentials (designer-id principal))
  (map-get? designer-credentials { designer-id: designer-id })
)

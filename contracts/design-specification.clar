;; Design Specification Contract
;; Records and manages circular design principles and specifications

(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_DESIGN_NOT_FOUND (err u201))
(define-constant ERR_INVALID_DESIGNER (err u202))
(define-constant ERR_DESIGN_EXISTS (err u203))

;; Design specification data structure
(define-map design-specifications
  { design-id: uint }
  {
    designer-id: principal,
    product-name: (string-ascii 100),
    circular-principles: (list 10 (string-ascii 100)),
    sustainability-score: uint,
    recyclability-rating: uint,
    durability-rating: uint,
    repairability-rating: uint,
    design-hash: (string-ascii 64),
    creation-date: uint,
    approved: bool
  }
)

;; Design metadata
(define-map design-metadata
  { design-id: uint }
  {
    description: (string-ascii 500),
    materials-list: (list 20 (string-ascii 50)),
    manufacturing-process: (string-ascii 200),
    expected-lifespan: uint,
    end-of-life-strategy: (string-ascii 200)
  }
)

(define-data-var next-design-id uint u1)

;; Create a new design specification
(define-public (create-design-specification
  (product-name (string-ascii 100))
  (circular-principles (list 10 (string-ascii 100)))
  (sustainability-score uint)
  (recyclability-rating uint)
  (durability-rating uint)
  (repairability-rating uint)
  (design-hash (string-ascii 64))
  (description (string-ascii 500))
  (materials-list (list 20 (string-ascii 50)))
  (manufacturing-process (string-ascii 200))
  (expected-lifespan uint)
  (end-of-life-strategy (string-ascii 200)))
  (let ((design-id (var-get next-design-id))
        (designer-id tx-sender))
    ;; Verify designer is registered (simplified check)
    (asserts! (not (is-eq designer-id 'SP000000000000000000002Q6VF78)) ERR_INVALID_DESIGNER)

    (map-set design-specifications
      { design-id: design-id }
      {
        designer-id: designer-id,
        product-name: product-name,
        circular-principles: circular-principles,
        sustainability-score: sustainability-score,
        recyclability-rating: recyclability-rating,
        durability-rating: durability-rating,
        repairability-rating: repairability-rating,
        design-hash: design-hash,
        creation-date: block-height,
        approved: false
      }
    )

    (map-set design-metadata
      { design-id: design-id }
      {
        description: description,
        materials-list: materials-list,
        manufacturing-process: manufacturing-process,
        expected-lifespan: expected-lifespan,
        end-of-life-strategy: end-of-life-strategy
      }
    )

    (var-set next-design-id (+ design-id u1))
    (ok design-id)
  )
)

;; Approve a design specification
(define-public (approve-design (design-id uint))
  (begin
    (asserts! (is-some (map-get? design-specifications { design-id: design-id })) ERR_DESIGN_NOT_FOUND)
    (map-set design-specifications
      { design-id: design-id }
      (merge
        (unwrap-panic (map-get? design-specifications { design-id: design-id }))
        { approved: true }
      )
    )
    (ok true)
  )
)

;; Get design specification
(define-read-only (get-design-specification (design-id uint))
  (map-get? design-specifications { design-id: design-id })
)

;; Get design metadata
(define-read-only (get-design-metadata (design-id uint))
  (map-get? design-metadata { design-id: design-id })
)

;; Calculate overall circular design score
(define-read-only (calculate-circular-score (design-id uint))
  (match (map-get? design-specifications { design-id: design-id })
    design (ok (/ (+ (get sustainability-score design)
                     (get recyclability-rating design)
                     (get durability-rating design)
                     (get repairability-rating design)) u4))
    ERR_DESIGN_NOT_FOUND
  )
)

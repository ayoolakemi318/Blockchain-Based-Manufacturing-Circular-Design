;; End-of-Life Planning Contract
;; Manages product disposal strategies and circular economy principles

(define-constant ERR_UNAUTHORIZED (err u500))
(define-constant ERR_PLAN_NOT_FOUND (err u501))
(define-constant ERR_INVALID_STRATEGY (err u502))
(define-constant ERR_PLAN_EXISTS (err u503))

;; End-of-life plan data structure
(define-map eol-plans
  { plan-id: uint }
  {
    design-id: uint,
    planner: principal,
    primary-strategy: (string-ascii 50),
    recovery-rate: uint,
    recycling-rate: uint,
    reuse-potential: uint,
    disposal-method: (string-ascii 100),
    estimated-cost: uint,
    environmental-benefit: uint,
    plan-date: uint,
    implemented: bool
  }
)

;; Material recovery strategies
(define-map material-recovery
  { plan-id: uint, material-type: (string-ascii 50) }
  {
    recovery-method: (string-ascii 100),
    recovery-percentage: uint,
    processing-cost: uint,
    market-value: uint,
    environmental-impact: uint
  }
)

;; Disposal tracking
(define-map disposal-records
  { record-id: uint }
  {
    plan-id: uint,
    product-batch: (string-ascii 100),
    disposal-date: uint,
    actual-recovery-rate: uint,
    disposal-facility: (string-ascii 100),
    verification-hash: (string-ascii 64)
  }
)

(define-data-var next-plan-id uint u1)
(define-data-var next-record-id uint u1)

;; Create end-of-life plan
(define-public (create-eol-plan
  (design-id uint)
  (primary-strategy (string-ascii 50))
  (recovery-rate uint)
  (recycling-rate uint)
  (reuse-potential uint)
  (disposal-method (string-ascii 100))
  (estimated-cost uint)
  (environmental-benefit uint))
  (let ((plan-id (var-get next-plan-id)))
    ;; Validate rates (0-100 scale)
    (asserts! (<= recovery-rate u100) ERR_INVALID_STRATEGY)
    (asserts! (<= recycling-rate u100) ERR_INVALID_STRATEGY)
    (asserts! (<= reuse-potential u100) ERR_INVALID_STRATEGY)

    (map-set eol-plans
      { plan-id: plan-id }
      {
        design-id: design-id,
        planner: tx-sender,
        primary-strategy: primary-strategy,
        recovery-rate: recovery-rate,
        recycling-rate: recycling-rate,
        reuse-potential: reuse-potential,
        disposal-method: disposal-method,
        estimated-cost: estimated-cost,
        environmental-benefit: environmental-benefit,
        plan-date: block-height,
        implemented: false
      }
    )

    (var-set next-plan-id (+ plan-id u1))
    (ok plan-id)
  )
)

;; Add material recovery strategy
(define-public (add-material-recovery
  (plan-id uint)
  (material-type (string-ascii 50))
  (recovery-method (string-ascii 100))
  (recovery-percentage uint)
  (processing-cost uint)
  (market-value uint)
  (environmental-impact uint))
  (begin
    (asserts! (is-some (map-get? eol-plans { plan-id: plan-id })) ERR_PLAN_NOT_FOUND)
    (asserts! (<= recovery-percentage u100) ERR_INVALID_STRATEGY)

    (map-set material-recovery
      { plan-id: plan-id, material-type: material-type }
      {
        recovery-method: recovery-method,
        recovery-percentage: recovery-percentage,
        processing-cost: processing-cost,
        market-value: market-value,
        environmental-impact: environmental-impact
      }
    )
    (ok true)
  )
)

;; Record actual disposal
(define-public (record-disposal
  (plan-id uint)
  (product-batch (string-ascii 100))
  (actual-recovery-rate uint)
  (disposal-facility (string-ascii 100))
  (verification-hash (string-ascii 64)))
  (let ((record-id (var-get next-record-id)))
    (asserts! (is-some (map-get? eol-plans { plan-id: plan-id })) ERR_PLAN_NOT_FOUND)

    (map-set disposal-records
      { record-id: record-id }
      {
        plan-id: plan-id,
        product-batch: product-batch,
        disposal-date: block-height,
        actual-recovery-rate: actual-recovery-rate,
        disposal-facility: disposal-facility,
        verification-hash: verification-hash
      }
    )

    (var-set next-record-id (+ record-id u1))
    (ok record-id)
  )
)

;; Mark plan as implemented
(define-public (implement-plan (plan-id uint))
  (begin
    (asserts! (is-some (map-get? eol-plans { plan-id: plan-id })) ERR_PLAN_NOT_FOUND)
    (map-set eol-plans
      { plan-id: plan-id }
      (merge
        (unwrap-panic (map-get? eol-plans { plan-id: plan-id }))
        { implemented: true }
      )
    )
    (ok true)
  )
)

;; Get end-of-life plan
(define-read-only (get-eol-plan (plan-id uint))
  (map-get? eol-plans { plan-id: plan-id })
)

;; Get material recovery strategy
(define-read-only (get-material-recovery (plan-id uint) (material-type (string-ascii 50)))
  (map-get? material-recovery { plan-id: plan-id, material-type: material-type })
)

;; Get disposal record
(define-read-only (get-disposal-record (record-id uint))
  (map-get? disposal-records { record-id: record-id })
)

;; Calculate circular economy score
(define-read-only (calculate-circularity-score (plan-id uint))
  (match (map-get? eol-plans { plan-id: plan-id })
    plan
    (let ((base-score (+ (get recovery-rate plan)
                        (get recycling-rate plan)
                        (get reuse-potential plan))))
      (ok (/ base-score u3)))
    ERR_PLAN_NOT_FOUND
  )
)

;; Calculate economic value of recovery
(define-read-only (calculate-recovery-value (plan-id uint))
  (match (map-get? eol-plans { plan-id: plan-id })
    plan
    (ok (if (> (get environmental-benefit plan) (get estimated-cost plan))
          (- (get environmental-benefit plan) (get estimated-cost plan))
          u0))
    ERR_PLAN_NOT_FOUND
  )
)

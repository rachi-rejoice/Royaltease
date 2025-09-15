;; Automated Royalty Distribution Smart Contract

;; Error Constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-WORK (err u101))
(define-constant ERR-INVALID-STAKEHOLDER (err u102))
(define-constant ERR-INVALID-SHARE (err u103))
(define-constant ERR-SHARES-EXCEED-100 (err u104))
(define-constant ERR-INSUFFICIENT-FUNDS (err u105))
(define-constant ERR-TRANSFER-FAILED (err u106))

;; Data Maps
(define-map works uint 
  { 
    creator: principal,
    title: (string-ascii 100),
    royalty-rate: uint,
    total-earnings: uint,
    stakeholder-count: uint
  }
)

(define-map work-stakeholders 
  { work-id: uint, stakeholder: principal } 
  { share: uint }
)

(define-map earnings principal uint)

;; Contract Variables
(define-data-var work-counter uint u0)
(define-data-var contract-owner principal tx-sender)

;; Read-only functions
(define-read-only (get-work-details (work-id uint))
  (map-get? works work-id)
)

(define-read-only (get-stakeholder-share (work-id uint) (stakeholder principal))
  (map-get? work-stakeholders { work-id: work-id, stakeholder: stakeholder })
)

(define-read-only (get-earnings (account principal))
  (default-to u0 (map-get? earnings account))
)

;; Public functions
(define-public (register-work (title (string-ascii 100)) (royalty-rate uint))
  (let 
    (
      (work-id (var-get work-counter))
    )
    (asserts! (< royalty-rate u101) (err ERR-INVALID-SHARE))
    (map-set works work-id
      {
        creator: tx-sender,
        title: title,
        royalty-rate: royalty-rate,
        total-earnings: u0,
        stakeholder-count: u1
      }
    )
    ;; Set creator as initial stakeholder
    (map-set work-stakeholders 
      { work-id: work-id, stakeholder: tx-sender }
      { share: u100 }
    )
    (var-set work-counter (+ work-id u1))
    (ok work-id)
  )
)

(define-public (add-stakeholder (work-id uint) (stakeholder principal) (share uint))
  (let
    (
      (work (unwrap! (map-get? works work-id) (err ERR-INVALID-WORK)))
      (creator-share (unwrap! (get-stakeholder-share work-id (get creator work)) (err ERR-INVALID-WORK)))
    )
    (asserts! (is-eq (get creator work) tx-sender) (err ERR-NOT-AUTHORIZED))
    (asserts! (< share u101) (err ERR-INVALID-SHARE))
    (asserts! (>= (get share creator-share) share) (err ERR-SHARES-EXCEED-100))
    
    ;; Update creator's share
    (map-set work-stakeholders 
      { work-id: work-id, stakeholder: (get creator work) }
      { share: (- (get share creator-share) share) }
    )
    
    ;; Add new stakeholder
    (map-set work-stakeholders 
      { work-id: work-id, stakeholder: stakeholder }
      { share: share }
    )
    
    ;; Update work stakeholder count
    (map-set works work-id
      (merge work { stakeholder-count: (+ (get stakeholder-count work) u1) })
    )
    
    (ok true)
  )
)

(define-public (distribute-royalty (work-id uint) (amount uint))
  (let
    (
      (work (unwrap! (map-get? works work-id) (err ERR-INVALID-WORK)))
      (royalty-amount (/ (* amount (get royalty-rate work)) u100))
    )
    (asserts! (>= (stx-get-balance tx-sender) royalty-amount) (err ERR-INSUFFICIENT-FUNDS))
    
    ;; Transfer royalty to contract
    (match (stx-transfer? royalty-amount tx-sender (as-contract tx-sender))
      success
        (begin
          ;; Update work total earnings
          (map-set works work-id
            (merge work { total-earnings: (+ (get total-earnings work) royalty-amount) })
          )
          
          ;; Distribute to stakeholders
          (match (distribute-share work-id (get creator work) royalty-amount)
            share-success (ok royalty-amount)
            share-error (err ERR-TRANSFER-FAILED)
          )
        )
      error (err ERR-TRANSFER-FAILED)
    )
  )
)

(define-public (withdraw-earnings)
  (let
    (
      (user-earnings (get-earnings tx-sender))
    )
    (asserts! (> user-earnings u0) (err ERR-INSUFFICIENT-FUNDS))
    (map-set earnings tx-sender u0)
    (match (as-contract (stx-transfer? user-earnings (as-contract tx-sender) tx-sender))
      success (ok user-earnings)
      error (err ERR-TRANSFER-FAILED)
    )
  )
)

;; Private functions
(define-private (distribute-share (work-id uint) (stakeholder principal) (amount uint))
  (let
    (
      (stake (unwrap! (get-stakeholder-share work-id stakeholder) (err ERR-INVALID-STAKEHOLDER)))
      (share-amount (/ (* amount (get share stake)) u100))
    )
    (map-set earnings 
      stakeholder
      (+ (get-earnings stakeholder) share-amount)
    )
    (ok true)
  )
)

;; Initialize contract
(begin
  (var-set work-counter u0)
  (var-set contract-owner tx-sender)
)
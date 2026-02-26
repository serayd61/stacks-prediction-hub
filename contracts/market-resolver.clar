;; title: market-resolver
;; version: 1.0.0
;; summary: Oracle-based market resolution with dispute mechanism
;; description: Authorized resolvers, dispute period (144 blocks), emergency resolution

;; ============================================================
;; Constants
;; ============================================================

(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u300))
(define-constant ERR-MARKET-NOT-FOUND (err u301))
(define-constant ERR-ALREADY-RESOLVED (err u302))
(define-constant ERR-NOT-RESOLVER (err u303))
(define-constant ERR-DISPUTE-ACTIVE (err u304))
(define-constant ERR-NO-DISPUTE (err u305))
(define-constant ERR-DISPUTE-EXPIRED (err u306))
(define-constant ERR-INVALID-OUTCOME (err u307))
(define-constant ERR-ALREADY-DISPUTED (err u308))
(define-constant ERR-DISPUTE-PERIOD-OVER (err u309))
(define-constant ERR-DISPUTE-PERIOD-ACTIVE (err u310))

(define-constant DISPUTE-PERIOD u144) ;; ~1 day in blocks
(define-constant DISPUTE-BOND u1000000) ;; 1 STX bond for disputes

;; ============================================================
;; Data Variables
;; ============================================================

(define-data-var resolution-nonce uint u0)

;; ============================================================
;; Data Maps
;; ============================================================

(define-map authorized-resolvers principal bool)

(define-map resolutions uint {
    market-id: uint,
    market-type: (string-ascii 20),
    resolver: principal,
    proposed-outcome: uint,
    resolved-at: uint,
    dispute-end: uint,
    disputed: bool,
    finalized: bool
})

(define-map disputes uint {
    disputer: principal,
    reason: (string-utf8 256),
    bond-amount: uint,
    resolved: bool,
    upheld: bool
})

;; ============================================================
;; Authorization
;; ============================================================

(define-public (add-resolver (resolver principal))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (map-set authorized-resolvers resolver true)
        (ok true))
)

(define-public (remove-resolver (resolver principal))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (map-set authorized-resolvers resolver false)
        (ok true))
)

;; ============================================================
;; Public Functions
;; ============================================================

(define-public (propose-resolution (market-id uint) (market-type (string-ascii 20)) (outcome uint))
    (let (
        (resolution-id (var-get resolution-nonce))
        (is-resolver (default-to false (map-get? authorized-resolvers tx-sender)))
    )
    (asserts! is-resolver ERR-NOT-RESOLVER)
    (map-set resolutions resolution-id {
        market-id: market-id,
        market-type: market-type,
        resolver: tx-sender,
        proposed-outcome: outcome,
        resolved-at: block-height,
        dispute-end: (+ block-height DISPUTE-PERIOD),
        disputed: false,
        finalized: false
    })
    (var-set resolution-nonce (+ resolution-id u1))
    (ok resolution-id))
)

(define-public (dispute-resolution (resolution-id uint) (reason (string-utf8 256)))
    (let (
        (resolution (unwrap! (map-get? resolutions resolution-id) ERR-MARKET-NOT-FOUND))
    )
    (asserts! (not (get disputed resolution)) ERR-ALREADY-DISPUTED)
    (asserts! (not (get finalized resolution)) ERR-ALREADY-RESOLVED)
    (asserts! (<= block-height (get dispute-end resolution)) ERR-DISPUTE-PERIOD-OVER)
    (try! (stx-transfer? DISPUTE-BOND tx-sender (as-contract tx-sender)))
    (map-set resolutions resolution-id (merge resolution { disputed: true }))
    (map-set disputes resolution-id {
        disputer: tx-sender,
        reason: reason,
        bond-amount: DISPUTE-BOND,
        resolved: false,
        upheld: false
    })
    (ok true))
)

(define-public (resolve-dispute (resolution-id uint) (upheld bool))
    (let (
        (resolution (unwrap! (map-get? resolutions resolution-id) ERR-MARKET-NOT-FOUND))
        (dispute (unwrap! (map-get? disputes resolution-id) ERR-NO-DISPUTE))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (get disputed resolution) ERR-NO-DISPUTE)
    (map-set disputes resolution-id (merge dispute {
        resolved: true,
        upheld: upheld
    }))
    ;; If dispute upheld, return bond to disputer
    (if upheld
        (try! (as-contract (stx-transfer? DISPUTE-BOND tx-sender (get disputer dispute))))
        true)
    (ok true))
)

(define-public (finalize-resolution (resolution-id uint))
    (let (
        (resolution (unwrap! (map-get? resolutions resolution-id) ERR-MARKET-NOT-FOUND))
    )
    (asserts! (not (get finalized resolution)) ERR-ALREADY-RESOLVED)
    (asserts! (> block-height (get dispute-end resolution)) ERR-DISPUTE-PERIOD-ACTIVE)
    (asserts! (not (get disputed resolution)) ERR-DISPUTE-ACTIVE)
    (map-set resolutions resolution-id (merge resolution { finalized: true }))
    (ok true))
)

(define-public (emergency-resolve (resolution-id uint) (new-outcome uint))
    (let (
        (resolution (unwrap! (map-get? resolutions resolution-id) ERR-MARKET-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (map-set resolutions resolution-id (merge resolution {
        proposed-outcome: new-outcome,
        finalized: true,
        disputed: false
    }))
    (ok true))
)

;; ============================================================
;; Read-Only Functions
;; ============================================================

(define-read-only (get-resolution (resolution-id uint))
    (map-get? resolutions resolution-id)
)

(define-read-only (get-dispute (resolution-id uint))
    (map-get? disputes resolution-id)
)

(define-read-only (is-authorized-resolver (resolver principal))
    (default-to false (map-get? authorized-resolvers resolver))
)

(define-read-only (is-finalized (resolution-id uint))
    (let (
        (resolution (unwrap! (map-get? resolutions resolution-id) ERR-MARKET-NOT-FOUND))
    )
    (ok (get finalized resolution)))
)

(define-read-only (get-resolution-count)
    (var-get resolution-nonce)
)

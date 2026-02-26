;; title: binary-market
;; version: 1.0.0
;; summary: Binary yes/no prediction market with CPMM pricing
;; description: Create markets, buy yes/no shares, resolve outcomes, claim winnings

;; ============================================================
;; Constants
;; ============================================================

(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-MARKET-NOT-FOUND (err u101))
(define-constant ERR-MARKET-CLOSED (err u102))
(define-constant ERR-MARKET-NOT-RESOLVED (err u103))
(define-constant ERR-INSUFFICIENT-FUNDS (err u104))
(define-constant ERR-INVALID-OUTCOME (err u105))
(define-constant ERR-ALREADY-CLAIMED (err u106))
(define-constant ERR-MARKET-ALREADY-RESOLVED (err u107))
(define-constant ERR-ZERO-AMOUNT (err u108))
(define-constant ERR-MARKET-EXPIRED (err u109))

(define-constant PRECISION u1000000)
(define-constant PLATFORM-FEE u20000) ;; 2% fee

;; ============================================================
;; Data Variables
;; ============================================================

(define-data-var market-nonce uint u0)

;; ============================================================
;; Data Maps
;; ============================================================

(define-map markets uint {
    creator: principal,
    description: (string-utf8 256),
    yes-pool: uint,
    no-pool: uint,
    total-volume: uint,
    end-block: uint,
    resolved: bool,
    outcome: bool,
    created-at: uint
})

(define-map user-shares { market-id: uint, user: principal } {
    yes-shares: uint,
    no-shares: uint
})

(define-map claimed { market-id: uint, user: principal } bool)

;; ============================================================
;; Private Functions
;; ============================================================

(define-private (calculate-cpmm-output (input-amount uint) (input-pool uint) (output-pool uint))
    (let (
        (fee (/ (* input-amount PLATFORM-FEE) PRECISION))
        (net-input (- input-amount fee))
        (numerator (* net-input output-pool))
        (denominator (+ input-pool net-input))
    )
    (/ numerator denominator))
)

(define-private (get-or-default-shares (market-id uint) (user principal))
    (default-to { yes-shares: u0, no-shares: u0 }
        (map-get? user-shares { market-id: market-id, user: user }))
)

;; ============================================================
;; Public Functions
;; ============================================================

(define-public (create-market (description (string-utf8 256)) (duration uint) (initial-liquidity uint))
    (let (
        (market-id (var-get market-nonce))
        (half-liquidity (/ initial-liquidity u2))
    )
    (asserts! (> initial-liquidity u0) ERR-ZERO-AMOUNT)
    (try! (stx-transfer? initial-liquidity tx-sender (as-contract tx-sender)))
    (map-set markets market-id {
        creator: tx-sender,
        description: description,
        yes-pool: half-liquidity,
        no-pool: half-liquidity,
        total-volume: u0,
        end-block: (+ block-height duration),
        resolved: false,
        outcome: false,
        created-at: block-height
    })
    (var-set market-nonce (+ market-id u1))
    (ok market-id))
)

(define-public (buy-yes (market-id uint) (amount uint))
    (let (
        (market (unwrap! (map-get? markets market-id) ERR-MARKET-NOT-FOUND))
        (yes-pool (get yes-pool market))
        (no-pool (get no-pool market))
        (shares-out (calculate-cpmm-output amount no-pool yes-pool))
        (current-shares (get-or-default-shares market-id tx-sender))
    )
    (asserts! (> amount u0) ERR-ZERO-AMOUNT)
    (asserts! (not (get resolved market)) ERR-MARKET-CLOSED)
    (asserts! (<= block-height (get end-block market)) ERR-MARKET-EXPIRED)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set markets market-id (merge market {
        yes-pool: (- yes-pool shares-out),
        no-pool: (+ no-pool amount),
        total-volume: (+ (get total-volume market) amount)
    }))
    (map-set user-shares { market-id: market-id, user: tx-sender }
        (merge current-shares { yes-shares: (+ (get yes-shares current-shares) shares-out) }))
    (ok shares-out))
)

(define-public (buy-no (market-id uint) (amount uint))
    (let (
        (market (unwrap! (map-get? markets market-id) ERR-MARKET-NOT-FOUND))
        (yes-pool (get yes-pool market))
        (no-pool (get no-pool market))
        (shares-out (calculate-cpmm-output amount yes-pool no-pool))
        (current-shares (get-or-default-shares market-id tx-sender))
    )
    (asserts! (> amount u0) ERR-ZERO-AMOUNT)
    (asserts! (not (get resolved market)) ERR-MARKET-CLOSED)
    (asserts! (<= block-height (get end-block market)) ERR-MARKET-EXPIRED)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set markets market-id (merge market {
        yes-pool: (+ yes-pool amount),
        no-pool: (- no-pool shares-out),
        total-volume: (+ (get total-volume market) amount)
    }))
    (map-set user-shares { market-id: market-id, user: tx-sender }
        (merge current-shares { no-shares: (+ (get no-shares current-shares) shares-out) }))
    (ok shares-out))
)

(define-public (resolve-market (market-id uint) (outcome bool))
    (let (
        (market (unwrap! (map-get? markets market-id) ERR-MARKET-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender (get creator market)) ERR-NOT-AUTHORIZED)
    (asserts! (not (get resolved market)) ERR-MARKET-ALREADY-RESOLVED)
    (map-set markets market-id (merge market {
        resolved: true,
        outcome: outcome
    }))
    (ok true))
)

(define-public (claim-winnings (market-id uint))
    (let (
        (market (unwrap! (map-get? markets market-id) ERR-MARKET-NOT-FOUND))
        (shares (get-or-default-shares market-id tx-sender))
        (winning-shares (if (get outcome market)
            (get yes-shares shares)
            (get no-shares shares)))
        (is-claimed (default-to false (map-get? claimed { market-id: market-id, user: tx-sender })))
    )
    (asserts! (get resolved market) ERR-MARKET-NOT-RESOLVED)
    (asserts! (not is-claimed) ERR-ALREADY-CLAIMED)
    (asserts! (> winning-shares u0) ERR-ZERO-AMOUNT)
    (map-set claimed { market-id: market-id, user: tx-sender } true)
    (try! (as-contract (stx-transfer? winning-shares tx-sender tx-sender)))
    (ok winning-shares))
)

;; ============================================================
;; Read-Only Functions
;; ============================================================

(define-read-only (get-market (market-id uint))
    (map-get? markets market-id)
)

(define-read-only (get-user-shares (market-id uint) (user principal))
    (get-or-default-shares market-id user)
)

(define-read-only (get-yes-price (market-id uint))
    (let (
        (market (unwrap! (map-get? markets market-id) ERR-MARKET-NOT-FOUND))
        (yes-pool (get yes-pool market))
        (no-pool (get no-pool market))
        (total (+ yes-pool no-pool))
    )
    (ok (/ (* no-pool PRECISION) total)))
)

(define-read-only (get-no-price (market-id uint))
    (let (
        (market (unwrap! (map-get? markets market-id) ERR-MARKET-NOT-FOUND))
        (yes-pool (get yes-pool market))
        (no-pool (get no-pool market))
        (total (+ yes-pool no-pool))
    )
    (ok (/ (* yes-pool PRECISION) total)))
)

(define-read-only (get-market-count)
    (var-get market-nonce)
)

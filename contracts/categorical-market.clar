;; title: categorical-market
;; version: 1.0.0
;; summary: Multi-outcome prediction market with up to 5 outcomes
;; description: Shares per outcome, resolution, proportional payout distribution

;; ============================================================
;; Constants
;; ============================================================

(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u200))
(define-constant ERR-MARKET-NOT-FOUND (err u201))
(define-constant ERR-MARKET-CLOSED (err u202))
(define-constant ERR-MARKET-NOT-RESOLVED (err u203))
(define-constant ERR-INVALID-OUTCOME (err u204))
(define-constant ERR-ALREADY-CLAIMED (err u205))
(define-constant ERR-MARKET-ALREADY-RESOLVED (err u206))
(define-constant ERR-ZERO-AMOUNT (err u207))
(define-constant ERR-TOO-MANY-OUTCOMES (err u208))
(define-constant ERR-TOO-FEW-OUTCOMES (err u209))
(define-constant ERR-MARKET-EXPIRED (err u210))
(define-constant ERR-NO-WINNINGS (err u211))

(define-constant MAX-OUTCOMES u5)
(define-constant PRECISION u1000000)
(define-constant PLATFORM-FEE u25000) ;; 2.5% fee

;; ============================================================
;; Data Variables
;; ============================================================

(define-data-var market-nonce uint u0)

;; ============================================================
;; Data Maps
;; ============================================================

(define-map cat-markets uint {
    creator: principal,
    description: (string-utf8 256),
    num-outcomes: uint,
    total-pot: uint,
    end-block: uint,
    resolved: bool,
    winning-outcome: uint,
    created-at: uint
})

(define-map outcome-pools { market-id: uint, outcome: uint } uint)

(define-map user-outcome-shares { market-id: uint, user: principal, outcome: uint } uint)

(define-map cat-claimed { market-id: uint, user: principal } bool)

;; ============================================================
;; Private Functions
;; ============================================================

(define-private (get-pool-amount (market-id uint) (outcome uint))
    (default-to u0 (map-get? outcome-pools { market-id: market-id, outcome: outcome }))
)

(define-private (get-user-outcome-amount (market-id uint) (user principal) (outcome uint))
    (default-to u0 (map-get? user-outcome-shares { market-id: market-id, user: user, outcome: outcome }))
)

(define-private (deduct-fee (amount uint))
    (let (
        (fee (/ (* amount PLATFORM-FEE) PRECISION))
    )
    (- amount fee))
)

;; ============================================================
;; Public Functions
;; ============================================================

(define-public (create-categorical-market
    (description (string-utf8 256))
    (num-outcomes uint)
    (duration uint)
    (initial-liquidity uint))
    (let (
        (market-id (var-get market-nonce))
        (per-outcome (/ initial-liquidity num-outcomes))
    )
    (asserts! (>= num-outcomes u2) ERR-TOO-FEW-OUTCOMES)
    (asserts! (<= num-outcomes MAX-OUTCOMES) ERR-TOO-MANY-OUTCOMES)
    (asserts! (> initial-liquidity u0) ERR-ZERO-AMOUNT)
    (try! (stx-transfer? initial-liquidity tx-sender (as-contract tx-sender)))
    (map-set cat-markets market-id {
        creator: tx-sender,
        description: description,
        num-outcomes: num-outcomes,
        total-pot: initial-liquidity,
        end-block: (+ block-height duration),
        resolved: false,
        winning-outcome: u0,
        created-at: block-height
    })
    ;; Initialize pools for each outcome
    (map-set outcome-pools { market-id: market-id, outcome: u0 } per-outcome)
    (map-set outcome-pools { market-id: market-id, outcome: u1 } per-outcome)
    (if (>= num-outcomes u3)
        (map-set outcome-pools { market-id: market-id, outcome: u2 } per-outcome)
        true)
    (if (>= num-outcomes u4)
        (map-set outcome-pools { market-id: market-id, outcome: u3 } per-outcome)
        true)
    (if (>= num-outcomes u5)
        (map-set outcome-pools { market-id: market-id, outcome: u4 } per-outcome)
        true)
    (var-set market-nonce (+ market-id u1))
    (ok market-id))
)

(define-public (buy-outcome-shares (market-id uint) (outcome uint) (amount uint))
    (let (
        (market (unwrap! (map-get? cat-markets market-id) ERR-MARKET-NOT-FOUND))
        (net-amount (deduct-fee amount))
        (current-pool (get-pool-amount market-id outcome))
        (current-user-shares (get-user-outcome-amount market-id tx-sender outcome))
    )
    (asserts! (> amount u0) ERR-ZERO-AMOUNT)
    (asserts! (< outcome (get num-outcomes market)) ERR-INVALID-OUTCOME)
    (asserts! (not (get resolved market)) ERR-MARKET-CLOSED)
    (asserts! (<= block-height (get end-block market)) ERR-MARKET-EXPIRED)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set outcome-pools { market-id: market-id, outcome: outcome }
        (+ current-pool net-amount))
    (map-set user-outcome-shares { market-id: market-id, user: tx-sender, outcome: outcome }
        (+ current-user-shares net-amount))
    (map-set cat-markets market-id (merge market {
        total-pot: (+ (get total-pot market) net-amount)
    }))
    (ok net-amount))
)

(define-public (resolve-categorical-market (market-id uint) (winning-outcome uint))
    (let (
        (market (unwrap! (map-get? cat-markets market-id) ERR-MARKET-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender (get creator market)) ERR-NOT-AUTHORIZED)
    (asserts! (not (get resolved market)) ERR-MARKET-ALREADY-RESOLVED)
    (asserts! (< winning-outcome (get num-outcomes market)) ERR-INVALID-OUTCOME)
    (map-set cat-markets market-id (merge market {
        resolved: true,
        winning-outcome: winning-outcome
    }))
    (ok true))
)

(define-public (claim-categorical-winnings (market-id uint))
    (let (
        (market (unwrap! (map-get? cat-markets market-id) ERR-MARKET-NOT-FOUND))
        (winning-outcome (get winning-outcome market))
        (user-shares (get-user-outcome-amount market-id tx-sender winning-outcome))
        (winning-pool (get-pool-amount market-id winning-outcome))
        (total-pot (get total-pot market))
        (is-claimed (default-to false (map-get? cat-claimed { market-id: market-id, user: tx-sender })))
        (payout (if (> winning-pool u0)
            (/ (* user-shares total-pot) winning-pool)
            u0))
    )
    (asserts! (get resolved market) ERR-MARKET-NOT-RESOLVED)
    (asserts! (not is-claimed) ERR-ALREADY-CLAIMED)
    (asserts! (> payout u0) ERR-NO-WINNINGS)
    (map-set cat-claimed { market-id: market-id, user: tx-sender } true)
    (try! (as-contract (stx-transfer? payout tx-sender tx-sender)))
    (ok payout))
)

;; ============================================================
;; Read-Only Functions
;; ============================================================

(define-read-only (get-categorical-market (market-id uint))
    (map-get? cat-markets market-id)
)

(define-read-only (get-outcome-pool (market-id uint) (outcome uint))
    (get-pool-amount market-id outcome)
)

(define-read-only (get-user-shares-for-outcome (market-id uint) (user principal) (outcome uint))
    (get-user-outcome-amount market-id user outcome)
)

(define-read-only (get-outcome-price (market-id uint) (outcome uint))
    (let (
        (market (unwrap! (map-get? cat-markets market-id) ERR-MARKET-NOT-FOUND))
        (outcome-pool (get-pool-amount market-id outcome))
        (total-pot (get total-pot market))
    )
    (ok (if (> total-pot u0)
        (/ (* outcome-pool PRECISION) total-pot)
        u0)))
)

(define-read-only (get-categorical-market-count)
    (var-get market-nonce)
)

;; title: liquidity-engine
;; version: 1.0.0
;; summary: AMM liquidity engine for prediction markets
;; description: Provide/remove liquidity, automated share pricing, LP rewards

;; ============================================================
;; Constants
;; ============================================================

(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u400))
(define-constant ERR-POOL-NOT-FOUND (err u401))
(define-constant ERR-ZERO-AMOUNT (err u402))
(define-constant ERR-INSUFFICIENT-LIQUIDITY (err u403))
(define-constant ERR-POOL-EXISTS (err u404))
(define-constant ERR-INSUFFICIENT-BALANCE (err u405))
(define-constant ERR-ZERO-LIQUIDITY (err u406))

(define-constant PRECISION u1000000)
(define-constant LP-FEE-RATE u5000) ;; 0.5% LP fee
(define-constant MIN-LIQUIDITY u100000) ;; Minimum liquidity to maintain

;; ============================================================
;; Data Variables
;; ============================================================

(define-data-var pool-nonce uint u0)
(define-data-var total-fees-collected uint u0)

;; ============================================================
;; Data Maps
;; ============================================================

(define-map liquidity-pools uint {
    market-id: uint,
    token-a-reserve: uint,
    token-b-reserve: uint,
    total-lp-tokens: uint,
    fee-collected: uint,
    active: bool,
    created-at: uint
})

(define-map lp-balances { pool-id: uint, provider: principal } uint)

(define-map lp-rewards { pool-id: uint, provider: principal } uint)

;; ============================================================
;; Private Functions
;; ============================================================

(define-private (min-of (a uint) (b uint))
    (if (<= a b) a b)
)

(define-private (get-lp-balance (pool-id uint) (provider principal))
    (default-to u0 (map-get? lp-balances { pool-id: pool-id, provider: provider }))
)

(define-private (get-lp-reward (pool-id uint) (provider principal))
    (default-to u0 (map-get? lp-rewards { pool-id: pool-id, provider: provider }))
)

(define-private (calculate-lp-fee (amount uint))
    (/ (* amount LP-FEE-RATE) PRECISION)
)

;; ============================================================
;; Public Functions
;; ============================================================

(define-public (create-pool (market-id uint) (initial-a uint) (initial-b uint))
    (let (
        (pool-id (var-get pool-nonce))
        (initial-lp-tokens (+ initial-a initial-b))
    )
    (asserts! (> initial-a u0) ERR-ZERO-AMOUNT)
    (asserts! (> initial-b u0) ERR-ZERO-AMOUNT)
    (try! (stx-transfer? (+ initial-a initial-b) tx-sender (as-contract tx-sender)))
    (map-set liquidity-pools pool-id {
        market-id: market-id,
        token-a-reserve: initial-a,
        token-b-reserve: initial-b,
        total-lp-tokens: initial-lp-tokens,
        fee-collected: u0,
        active: true,
        created-at: block-height
    })
    (map-set lp-balances { pool-id: pool-id, provider: tx-sender } initial-lp-tokens)
    (var-set pool-nonce (+ pool-id u1))
    (ok pool-id))
)

(define-public (add-liquidity (pool-id uint) (amount-a uint) (amount-b uint))
    (let (
        (pool (unwrap! (map-get? liquidity-pools pool-id) ERR-POOL-NOT-FOUND))
        (reserve-a (get token-a-reserve pool))
        (reserve-b (get token-b-reserve pool))
        (total-lp (get total-lp-tokens pool))
        (lp-a (/ (* amount-a total-lp) reserve-a))
        (lp-b (/ (* amount-b total-lp) reserve-b))
        (new-lp-tokens (min-of lp-a lp-b))
        (current-lp (get-lp-balance pool-id tx-sender))
    )
    (asserts! (get active pool) ERR-POOL-NOT-FOUND)
    (asserts! (> amount-a u0) ERR-ZERO-AMOUNT)
    (asserts! (> amount-b u0) ERR-ZERO-AMOUNT)
    (try! (stx-transfer? (+ amount-a amount-b) tx-sender (as-contract tx-sender)))
    (map-set liquidity-pools pool-id (merge pool {
        token-a-reserve: (+ reserve-a amount-a),
        token-b-reserve: (+ reserve-b amount-b),
        total-lp-tokens: (+ total-lp new-lp-tokens)
    }))
    (map-set lp-balances { pool-id: pool-id, provider: tx-sender }
        (+ current-lp new-lp-tokens))
    (ok new-lp-tokens))
)

(define-public (remove-liquidity (pool-id uint) (lp-amount uint))
    (let (
        (pool (unwrap! (map-get? liquidity-pools pool-id) ERR-POOL-NOT-FOUND))
        (reserve-a (get token-a-reserve pool))
        (reserve-b (get token-b-reserve pool))
        (total-lp (get total-lp-tokens pool))
        (current-lp (get-lp-balance pool-id tx-sender))
        (amount-a (/ (* lp-amount reserve-a) total-lp))
        (amount-b (/ (* lp-amount reserve-b) total-lp))
        (total-return (+ amount-a amount-b))
    )
    (asserts! (> lp-amount u0) ERR-ZERO-AMOUNT)
    (asserts! (<= lp-amount current-lp) ERR-INSUFFICIENT-BALANCE)
    (asserts! (>= (- total-lp lp-amount) MIN-LIQUIDITY) ERR-INSUFFICIENT-LIQUIDITY)
    (try! (as-contract (stx-transfer? total-return tx-sender tx-sender)))
    (map-set liquidity-pools pool-id (merge pool {
        token-a-reserve: (- reserve-a amount-a),
        token-b-reserve: (- reserve-b amount-b),
        total-lp-tokens: (- total-lp lp-amount)
    }))
    (map-set lp-balances { pool-id: pool-id, provider: tx-sender }
        (- current-lp lp-amount))
    (ok { amount-a: amount-a, amount-b: amount-b }))
)

(define-public (swap (pool-id uint) (amount-in uint) (is-a-to-b bool))
    (let (
        (pool (unwrap! (map-get? liquidity-pools pool-id) ERR-POOL-NOT-FOUND))
        (reserve-a (get token-a-reserve pool))
        (reserve-b (get token-b-reserve pool))
        (fee (calculate-lp-fee amount-in))
        (net-in (- amount-in fee))
        (amount-out (if is-a-to-b
            (/ (* net-in reserve-b) (+ reserve-a net-in))
            (/ (* net-in reserve-a) (+ reserve-b net-in))))
    )
    (asserts! (get active pool) ERR-POOL-NOT-FOUND)
    (asserts! (> amount-in u0) ERR-ZERO-AMOUNT)
    (try! (stx-transfer? amount-in tx-sender (as-contract tx-sender)))
    (try! (as-contract (stx-transfer? amount-out tx-sender tx-sender)))
    (if is-a-to-b
        (map-set liquidity-pools pool-id (merge pool {
            token-a-reserve: (+ reserve-a net-in),
            token-b-reserve: (- reserve-b amount-out),
            fee-collected: (+ (get fee-collected pool) fee)
        }))
        (map-set liquidity-pools pool-id (merge pool {
            token-a-reserve: (- reserve-a amount-out),
            token-b-reserve: (+ reserve-b net-in),
            fee-collected: (+ (get fee-collected pool) fee)
        })))
    (var-set total-fees-collected (+ (var-get total-fees-collected) fee))
    (ok amount-out))
)

(define-public (claim-lp-rewards (pool-id uint))
    (let (
        (pool (unwrap! (map-get? liquidity-pools pool-id) ERR-POOL-NOT-FOUND))
        (current-lp (get-lp-balance pool-id tx-sender))
        (total-lp (get total-lp-tokens pool))
        (pool-fees (get fee-collected pool))
        (user-share (/ (* current-lp pool-fees) total-lp))
        (already-claimed (get-lp-reward pool-id tx-sender))
        (claimable (- user-share already-claimed))
    )
    (asserts! (> claimable u0) ERR-ZERO-AMOUNT)
    (map-set lp-rewards { pool-id: pool-id, provider: tx-sender }
        (+ already-claimed claimable))
    (try! (as-contract (stx-transfer? claimable tx-sender tx-sender)))
    (ok claimable))
)

;; ============================================================
;; Read-Only Functions
;; ============================================================

(define-read-only (get-pool (pool-id uint))
    (map-get? liquidity-pools pool-id)
)

(define-read-only (get-provider-lp-balance (pool-id uint) (provider principal))
    (get-lp-balance pool-id provider)
)

(define-read-only (get-spot-price (pool-id uint))
    (let (
        (pool (unwrap! (map-get? liquidity-pools pool-id) ERR-POOL-NOT-FOUND))
        (reserve-a (get token-a-reserve pool))
        (reserve-b (get token-b-reserve pool))
    )
    (ok (/ (* reserve-b PRECISION) reserve-a)))
)

(define-read-only (get-pool-count)
    (var-get pool-nonce)
)

(define-read-only (get-total-fees)
    (var-get total-fees-collected)
)

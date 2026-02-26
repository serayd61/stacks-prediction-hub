;; title: rewards-distributor
;; version: 1.0.0
;; summary: Rewards for market creators and active traders
;; description: Points system, weekly distributions, leaderboard tracking

;; ============================================================
;; Constants
;; ============================================================

(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u500))
(define-constant ERR-USER-NOT-FOUND (err u501))
(define-constant ERR-ZERO-AMOUNT (err u502))
(define-constant ERR-ALREADY-CLAIMED (err u503))
(define-constant ERR-NO-REWARDS (err u504))
(define-constant ERR-EPOCH-NOT-ENDED (err u505))
(define-constant ERR-INVALID-TIER (err u506))

(define-constant POINTS-PER-TRADE u10)
(define-constant POINTS-PER-MARKET-CREATED u50)
(define-constant POINTS-PER-RESOLUTION u25)
(define-constant BLOCKS-PER-WEEK u1008) ;; ~7 days in blocks

;; ============================================================
;; Data Variables
;; ============================================================

(define-data-var current-epoch uint u0)
(define-data-var epoch-start-block uint block-height)
(define-data-var reward-pool uint u0)
(define-data-var total-points-this-epoch uint u0)

;; ============================================================
;; Data Maps
;; ============================================================

(define-map user-profiles principal {
    total-points: uint,
    total-trades: uint,
    markets-created: uint,
    total-volume: uint,
    tier: uint
})

(define-map epoch-points { epoch: uint, user: principal } uint)

(define-map epoch-claimed { epoch: uint, user: principal } bool)

(define-map epoch-total-points uint uint)

(define-map leaderboard-position { epoch: uint, user: principal } uint)

;; ============================================================
;; Private Functions
;; ============================================================

(define-private (get-or-create-profile (user principal))
    (default-to {
        total-points: u0,
        total-trades: u0,
        markets-created: u0,
        total-volume: u0,
        tier: u0
    } (map-get? user-profiles user))
)

(define-private (get-epoch-user-points (epoch uint) (user principal))
    (default-to u0 (map-get? epoch-points { epoch: epoch, user: user }))
)

(define-private (calculate-tier (total-points uint))
    (if (>= total-points u10000) u4    ;; Diamond
        (if (>= total-points u5000) u3  ;; Gold
            (if (>= total-points u1000) u2  ;; Silver
                (if (>= total-points u100) u1  ;; Bronze
                    u0))))              ;; Unranked
)

;; ============================================================
;; Public Functions
;; ============================================================

(define-public (record-trade (user principal) (volume uint))
    (let (
        (profile (get-or-create-profile user))
        (current-ep (var-get current-epoch))
        (user-epoch-pts (get-epoch-user-points current-ep user))
        (new-total-points (+ (get total-points profile) POINTS-PER-TRADE))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> volume u0) ERR-ZERO-AMOUNT)
    (map-set user-profiles user (merge profile {
        total-points: new-total-points,
        total-trades: (+ (get total-trades profile) u1),
        total-volume: (+ (get total-volume profile) volume),
        tier: (calculate-tier new-total-points)
    }))
    (map-set epoch-points { epoch: current-ep, user: user }
        (+ user-epoch-pts POINTS-PER-TRADE))
    (var-set total-points-this-epoch (+ (var-get total-points-this-epoch) POINTS-PER-TRADE))
    (ok POINTS-PER-TRADE))
)

(define-public (record-market-creation (user principal))
    (let (
        (profile (get-or-create-profile user))
        (current-ep (var-get current-epoch))
        (user-epoch-pts (get-epoch-user-points current-ep user))
        (new-total-points (+ (get total-points profile) POINTS-PER-MARKET-CREATED))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (map-set user-profiles user (merge profile {
        total-points: new-total-points,
        markets-created: (+ (get markets-created profile) u1),
        tier: (calculate-tier new-total-points)
    }))
    (map-set epoch-points { epoch: current-ep, user: user }
        (+ user-epoch-pts POINTS-PER-MARKET-CREATED))
    (var-set total-points-this-epoch (+ (var-get total-points-this-epoch) POINTS-PER-MARKET-CREATED))
    (ok POINTS-PER-MARKET-CREATED))
)

(define-public (fund-reward-pool (amount uint))
    (begin
        (asserts! (> amount u0) ERR-ZERO-AMOUNT)
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        (var-set reward-pool (+ (var-get reward-pool) amount))
        (ok amount))
)

(define-public (advance-epoch)
    (let (
        (current-ep (var-get current-epoch))
        (epoch-start (var-get epoch-start-block))
    )
    (asserts! (>= block-height (+ epoch-start BLOCKS-PER-WEEK)) ERR-EPOCH-NOT-ENDED)
    (map-set epoch-total-points current-ep (var-get total-points-this-epoch))
    (var-set current-epoch (+ current-ep u1))
    (var-set epoch-start-block block-height)
    (var-set total-points-this-epoch u0)
    (ok (+ current-ep u1)))
)

(define-public (claim-epoch-rewards (epoch uint))
    (let (
        (user-pts (get-epoch-user-points epoch tx-sender))
        (total-epoch-pts (default-to u0 (map-get? epoch-total-points epoch)))
        (pool (var-get reward-pool))
        (is-claimed (default-to false (map-get? epoch-claimed { epoch: epoch, user: tx-sender })))
        (reward (if (> total-epoch-pts u0)
            (/ (* user-pts pool) total-epoch-pts)
            u0))
    )
    (asserts! (not is-claimed) ERR-ALREADY-CLAIMED)
    (asserts! (> reward u0) ERR-NO-REWARDS)
    (asserts! (< epoch (var-get current-epoch)) ERR-EPOCH-NOT-ENDED)
    (map-set epoch-claimed { epoch: epoch, user: tx-sender } true)
    (var-set reward-pool (- pool reward))
    (try! (as-contract (stx-transfer? reward tx-sender tx-sender)))
    (ok reward))
)

(define-public (update-leaderboard (epoch uint) (user principal) (position uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (map-set leaderboard-position { epoch: epoch, user: user } position)
        (ok true))
)

;; ============================================================
;; Read-Only Functions
;; ============================================================

(define-read-only (get-user-profile (user principal))
    (map-get? user-profiles user)
)

(define-read-only (get-user-epoch-points (epoch uint) (user principal))
    (get-epoch-user-points epoch user)
)

(define-read-only (get-current-epoch)
    (var-get current-epoch)
)

(define-read-only (get-reward-pool)
    (var-get reward-pool)
)

(define-read-only (get-leaderboard-rank (epoch uint) (user principal))
    (default-to u0 (map-get? leaderboard-position { epoch: epoch, user: user }))
)

(define-read-only (get-epoch-info (epoch uint))
    (ok {
        total-points: (default-to u0 (map-get? epoch-total-points epoch)),
        reward-pool: (var-get reward-pool),
        current-epoch: (var-get current-epoch)
    })
)

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-voted (err u102))
(define-constant err-voting-ended (err u103))
(define-constant err-not-authorized (err u104))
(define-constant err-invalid-proposal (err u105))
(define-constant err-voting-not-started (err u106))

(define-data-var proposal-counter uint u0)
(define-data-var voting-duration uint u1440)
(define-data-var min-votes-required uint u10)
(define-data-var approval-threshold uint u60)

(define-map proposals
  { proposal-id: uint }
  {
    title: (string-ascii 100),
    description: (string-ascii 500),
    proposer: principal,
    created-at: uint,
    voting-end: uint,
    total-votes: uint,
    yes-votes: uint,
    no-votes: uint,
    status: (string-ascii 20)
  }
)

(define-map voters
  { proposal-id: uint, voter: principal }
  { vote: bool, voted-at: uint }
)

(define-map authorized-users
  principal
  { role: (string-ascii 20), authorized: bool }
)

(define-map user-reputation
  principal
  { score: uint, proposals-created: uint, votes-cast: uint }
)

(define-public (initialize-contract)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set authorized-users contract-owner { role: "admin", authorized: true })
    (ok true)
  )
)

(define-public (authorize-user (user principal) (role (string-ascii 20)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set authorized-users user { role: role, authorized: true })
    (ok true)
  )
)

(define-public (revoke-authorization (user principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set authorized-users user { role: "", authorized: false })
    (ok true)
  )
)

(define-public (create-proposal 
  (title (string-ascii 100)) 
  (description (string-ascii 500))
)
  (let
    (
      (user-auth (map-get? authorized-users tx-sender))
      (proposal-id (+ (var-get proposal-counter) u1))
      (current-height burn-block-height)
    )
    (asserts! (is-some user-auth) err-not-authorized)
    (asserts! (get authorized (unwrap-panic user-auth)) err-not-authorized)
    (asserts! (> (len title) u0) err-invalid-proposal)
    (asserts! (> (len description) u0) err-invalid-proposal)
    
    (map-set proposals
      { proposal-id: proposal-id }
      {
        title: title,
        description: description,
        proposer: tx-sender,
        created-at: current-height,
        voting-end: (+ current-height (var-get voting-duration)),
        total-votes: u0,
        yes-votes: u0,
        no-votes: u0,
        status: "active"
      }
    )
    
    (var-set proposal-counter proposal-id)
    
    (ok proposal-id)
  )
)

(define-public (vote-on-proposal (proposal-id uint) (vote bool))
  (let
    (
      (proposal (map-get? proposals { proposal-id: proposal-id }))
      (user-auth (map-get? authorized-users tx-sender))
      (existing-vote (map-get? voters { proposal-id: proposal-id, voter: tx-sender }))
      (current-height burn-block-height)
    )
    (asserts! (is-some proposal) err-not-found)
    (asserts! (is-some user-auth) err-not-authorized)
    (asserts! (get authorized (unwrap-panic user-auth)) err-not-authorized)
    (asserts! (is-none existing-vote) err-already-voted)
    
    (let ((prop-data (unwrap-panic proposal)))
      (asserts! (< current-height (get voting-end prop-data)) err-voting-ended)
      (asserts! (is-eq (get status prop-data) "active") err-voting-not-started)
      
      (map-set voters
        { proposal-id: proposal-id, voter: tx-sender }
        { vote: vote, voted-at: current-height }
      )
      
      (map-set proposals
        { proposal-id: proposal-id }
        (merge prop-data
          {
            total-votes: (+ (get total-votes prop-data) u1),
            yes-votes: (if vote 
                        (+ (get yes-votes prop-data) u1) 
                        (get yes-votes prop-data)),
            no-votes: (if vote 
                       (get no-votes prop-data) 
                       (+ (get no-votes prop-data) u1))
          }
        )
      )
      
      (ok true)
    )
  )
)

(define-public (finalize-proposal (proposal-id uint))
  (let
    (
      (proposal (map-get? proposals { proposal-id: proposal-id }))
      (current-height burn-block-height)
    )
    (asserts! (is-some proposal) err-not-found)
    
    (let ((prop-data (unwrap-panic proposal)))
      (asserts! (>= current-height (get voting-end prop-data)) err-voting-not-started)
      (asserts! (is-eq (get status prop-data) "active") err-voting-ended)
      
      (let
        (
          (total-votes (get total-votes prop-data))
          (yes-votes (get yes-votes prop-data))
          (approval-rate (if (> total-votes u0)
                          (/ (* yes-votes u100) total-votes)
                          u0))
          (new-status (if (and 
                           (>= total-votes (var-get min-votes-required))
                           (>= approval-rate (var-get approval-threshold)))
                       "approved"
                       "rejected"))
        )
        
        (map-set proposals
          { proposal-id: proposal-id }
          (merge prop-data { status: new-status })
        )
        
        (ok true)
      )
    )
  )
)

(define-public (update-voting-parameters 
  (new-duration uint) 
  (new-min-votes uint) 
  (new-threshold uint)
)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> new-duration u0) err-invalid-proposal)
    (asserts! (<= new-threshold u100) err-invalid-proposal)
    
    (var-set voting-duration new-duration)
    (var-set min-votes-required new-min-votes)
    (var-set approval-threshold new-threshold)
    
    (ok true)
  )
)

(define-private (update-user-reputation 
  (user principal) 
  (score-delta uint) 
  (proposals-delta uint) 
  (votes-delta uint)
)
  (let
    (
      (current-rep (default-to 
                     { score: u0, proposals-created: u0, votes-cast: u0 }
                     (map-get? user-reputation user)))
    )
    (map-set user-reputation user
      {
        score: (+ (get score current-rep) score-delta),
        proposals-created: (+ (get proposals-created current-rep) proposals-delta),
        votes-cast: (+ (get votes-cast current-rep) votes-delta)
      }
    )
    (ok true)
  )
)

(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals { proposal-id: proposal-id })
)

(define-read-only (get-user-vote (proposal-id uint) (voter principal))
  (map-get? voters { proposal-id: proposal-id, voter: voter })
)

(define-read-only (get-user-authorization (user principal))
  (map-get? authorized-users user)
)

(define-read-only (get-user-reputation (user principal))
  (map-get? user-reputation user)
)

(define-read-only (get-voting-parameters)
  {
    duration: (var-get voting-duration),
    min-votes: (var-get min-votes-required),
    threshold: (var-get approval-threshold)
  }
)

(define-read-only (get-proposal-count)
  (var-get proposal-counter)
)

(define-read-only (is-voting-active (proposal-id uint))
  (match (map-get? proposals { proposal-id: proposal-id })
    proposal-data
      (and 
        (is-eq (get status proposal-data) "active")
        (< burn-block-height (get voting-end proposal-data))
      )
    false
  )
)

(define-read-only (calculate-approval-rate (proposal-id uint))
  (match (map-get? proposals { proposal-id: proposal-id })
    proposal-data
      (let
        (
          (total (get total-votes proposal-data))
          (yes (get yes-votes proposal-data))
        )
        (if (> total u0)
          (some (/ (* yes u100) total))
          (some u0)
        )
      )
    none
  )
)

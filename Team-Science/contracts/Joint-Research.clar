;; Decentralized Think Tank Smart Contract
;; A comprehensive platform for collaborative research, proposals, and knowledge sharing

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-OWNER-ONLY (err u100))
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-EXISTS (err u102))
(define-constant ERR-INSUFFICIENT-STAKE (err u103))
(define-constant ERR-VOTING-ENDED (err u104))
(define-constant ERR-ALREADY-VOTED (err u105))
(define-constant ERR-NOT-MEMBER (err u106))
(define-constant ERR-INVALID-DURATION (err u107))
(define-constant ERR-PROPOSAL-NOT-ACTIVE (err u108))
(define-constant ERR-INSUFFICIENT-FUNDS (err u109))
(define-constant ERR-ALREADY-MEMBER (err u110))
(define-constant ERR-INVALID-REPUTATION (err u111))

;; Minimum stake required to become a member
(define-constant MIN-STAKE u1000000) ;; 1 STX
(define-constant PROPOSAL-COST u500000) ;; 0.5 STX to create a proposal
(define-constant MAX-PROPOSAL-DURATION u10080) ;; 1 week in blocks (assuming 10min blocks)
(define-constant MIN-PROPOSAL-DURATION u144) ;; 1 day in blocks
(define-constant REPUTATION-DECAY-FACTOR u95) ;; 5% decay per period

;; Data Variables
(define-data-var next-member-id uint u1)
(define-data-var next-proposal-id uint u1)
(define-data-var next-research-id uint u1)
(define-data-var treasury-balance uint u0)
(define-data-var total-members uint u0)
(define-data-var platform-fee uint u50) ;; 0.5% fee for platform operations

;; Member structure
(define-map members 
    { member-id: uint }
    {
        address: principal,
        stake: uint,
        reputation: uint,
        join-block: uint,
        is-active: bool,
        proposals-created: uint,
        votes-cast: uint,
        research-contributions: uint
    }
)

;; Address to member-id mapping
(define-map member-by-address 
    { address: principal }
    { member-id: uint }
)

;; Proposal structure
(define-map proposals
    { proposal-id: uint }
    {
        title: (string-ascii 100),
        description: (string-ascii 500),
        creator: uint,
        funding-requested: uint,
        voting-end-block: uint,
        yes-votes: uint,
        no-votes: uint,
        total-voters: uint,
        status: (string-ascii 20), ;; "active", "passed", "failed", "executed"
        created-block: uint,
        category: (string-ascii 50)
    }
)

;; Vote tracking
(define-map votes
    { proposal-id: uint, member-id: uint }
    { vote: bool, weight: uint }
)

;; Research paper structure
(define-map research-papers
    { research-id: uint }
    {
        title: (string-ascii 100),
        abstract: (string-ascii 1000),
        author: uint,
        co-authors: (list 10 uint),
        ipfs-hash: (string-ascii 100),
        peer-reviews: uint,
        average-rating: uint,
        publication-block: uint,
        category: (string-ascii 50),
        is-open-access: bool
    }
)

;; Peer review structure
(define-map peer-reviews
    { research-id: uint, reviewer-id: uint }
    {
        rating: uint, ;; 1-10 scale
        review-hash: (string-ascii 100),
        submitted-block: uint
    }
)

;; Collaboration tracking
(define-map collaborations
    { collaboration-id: uint }
    {
        title: (string-ascii 100),
        description: (string-ascii 500),
        leader: uint,
        members: (list 20 uint),
        start-block: uint,
        end-block: (optional uint),
        status: (string-ascii 20) ;; "active", "completed", "cancelled"
    }
)

(define-data-var next-collaboration-id uint u1)

;; Member functions
(define-public (join-think-tank (stake-amount uint))
    (let 
        (
            (sender-principal tx-sender)
            (member-id (var-get next-member-id))
        )
        (asserts! (>= stake-amount MIN-STAKE) ERR-INSUFFICIENT-STAKE)
        (asserts! (is-none (map-get? member-by-address { address: sender-principal })) ERR-ALREADY-MEMBER)
        
        ;; Transfer stake to contract
        (try! (stx-transfer? stake-amount sender-principal (as-contract tx-sender)))
        
        ;; Create member record
        (map-set members
            { member-id: member-id }
            {
                address: sender-principal,
                stake: stake-amount,
                reputation: u100, ;; Starting reputation
                join-block: block-height,
                is-active: true,
                proposals-created: u0,
                votes-cast: u0,
                research-contributions: u0
            }
        )
        
        ;; Create address mapping
        (map-set member-by-address
            { address: sender-principal }
            { member-id: member-id }
        )
        
        ;; Update counters
        (var-set next-member-id (+ member-id u1))
        (var-set total-members (+ (var-get total-members) u1))
        
        (ok member-id)
    )
)

(define-public (increase-stake (additional-amount uint))
    (let 
        (
            (member-info (unwrap! (get-member-by-address tx-sender) ERR-NOT-MEMBER))
            (member-id (get member-id member-info))
            (current-member (unwrap! (map-get? members { member-id: member-id }) ERR-NOT-FOUND))
        )
        ;; Transfer additional stake
        (try! (stx-transfer? additional-amount tx-sender (as-contract tx-sender)))
        
        ;; Update member stake
        (map-set members
            { member-id: member-id }
            (merge current-member { stake: (+ (get stake current-member) additional-amount) })
        )
        
        (ok (+ (get stake current-member) additional-amount))
    )
)

;; Proposal functions
(define-public (create-proposal 
    (title (string-ascii 100))
    (description (string-ascii 500))
    (funding-requested uint)
    (duration uint)
    (category (string-ascii 50))
)
    (let 
        (
            (member-info (unwrap! (get-member-by-address tx-sender) ERR-NOT-MEMBER))
            (member-id (get member-id member-info))
            (proposal-id (var-get next-proposal-id))
            (voting-end (+ block-height duration))
        )
        (asserts! (and (>= duration MIN-PROPOSAL-DURATION) (<= duration MAX-PROPOSAL-DURATION)) ERR-INVALID-DURATION)
        
        ;; Pay proposal creation fee
        (try! (stx-transfer? PROPOSAL-COST tx-sender (as-contract tx-sender)))
        
        ;; Create proposal
        (map-set proposals
            { proposal-id: proposal-id }
            {
                title: title,
                description: description,
                creator: member-id,
                funding-requested: funding-requested,
                voting-end-block: voting-end,
                yes-votes: u0,
                no-votes: u0,
                total-voters: u0,
                status: "active",
                created-block: block-height,
                category: category
            }
        )
        
        ;; Update member stats
        (let ((current-member (unwrap! (map-get? members { member-id: member-id }) ERR-NOT-FOUND)))
            (map-set members
                { member-id: member-id }
                (merge current-member 
                    { 
                        proposals-created: (+ (get proposals-created current-member) u1),
                        reputation: (+ (get reputation current-member) u10)
                    }
                )
            )
        )
        
        ;; Update treasury and counters
        (var-set treasury-balance (+ (var-get treasury-balance) PROPOSAL-COST))
        (var-set next-proposal-id (+ proposal-id u1))
        
        (ok proposal-id)
    )
)

(define-public (vote-on-proposal (proposal-id uint) (vote-yes bool))
    (let 
        (
            (member-info (unwrap! (get-member-by-address tx-sender) ERR-NOT-MEMBER))
            (member-id (get member-id member-info))
            (current-member (unwrap! (map-get? members { member-id: member-id }) ERR-NOT-FOUND))
            (proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) ERR-NOT-FOUND))
            (vote-weight (calculate-vote-weight (get stake current-member) (get reputation current-member)))
        )
        (asserts! (<= block-height (get voting-end-block proposal)) ERR-VOTING-ENDED)
        (asserts! (is-eq (get status proposal) "active") ERR-PROPOSAL-NOT-ACTIVE)
        (asserts! (is-none (map-get? votes { proposal-id: proposal-id, member-id: member-id })) ERR-ALREADY-VOTED)
        
        ;; Record vote
        (map-set votes
            { proposal-id: proposal-id, member-id: member-id }
            { vote: vote-yes, weight: vote-weight }
        )
        
        ;; Update proposal vote counts
        (let 
            (
                (new-yes-votes (if vote-yes (+ (get yes-votes proposal) vote-weight) (get yes-votes proposal)))
                (new-no-votes (if (not vote-yes) (+ (get no-votes proposal) vote-weight) (get no-votes proposal)))
            )
            (map-set proposals
                { proposal-id: proposal-id }
                (merge proposal 
                    {
                        yes-votes: new-yes-votes,
                        no-votes: new-no-votes,
                        total-voters: (+ (get total-voters proposal) u1)
                    }
                )
            )
        )
        
        ;; Update member stats
        (map-set members
            { member-id: member-id }
            (merge current-member 
                {
                    votes-cast: (+ (get votes-cast current-member) u1),
                    reputation: (+ (get reputation current-member) u5)
                }
            )
        )
        
        (ok true)
    )
)

(define-public (finalize-proposal (proposal-id uint))
    (let 
        (
            (proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) ERR-NOT-FOUND))
        )
        (asserts! (> block-height (get voting-end-block proposal)) ERR-VOTING-ENDED)
        (asserts! (is-eq (get status proposal) "active") ERR-PROPOSAL-NOT-ACTIVE)
        
        (let 
            (
                (total-votes (+ (get yes-votes proposal) (get no-votes proposal)))
                (approval-threshold (/ (* total-votes u60) u100)) ;; 60% threshold
                (new-status (if (>= (get yes-votes proposal) approval-threshold) "passed" "failed"))
            )
            (map-set proposals
                { proposal-id: proposal-id }
                (merge proposal { status: new-status })
            )
            
            ;; If passed and funding requested, transfer funds
            (if (and (is-eq new-status "passed") (> (get funding-requested proposal) u0))
                (begin
                    (asserts! (>= (var-get treasury-balance) (get funding-requested proposal)) ERR-INSUFFICIENT-FUNDS)
                    (let ((creator-address (get address (unwrap! (map-get? members { member-id: (get creator proposal) }) ERR-NOT-FOUND))))
                        (try! (as-contract (stx-transfer? (get funding-requested proposal) tx-sender creator-address)))
                        (var-set treasury-balance (- (var-get treasury-balance) (get funding-requested proposal)))
                        (map-set proposals { proposal-id: proposal-id } (merge proposal { status: "executed" }))
                        (ok true)
                    )
                )
                (ok true)
            )
        )
    )
)

;; Research paper functions
(define-public (submit-research-paper
    (title (string-ascii 100))
    (abstract (string-ascii 1000))
    (co-authors (list 10 uint))
    (ipfs-hash (string-ascii 100))
    (category (string-ascii 50))
    (is-open-access bool)
)
    (let 
        (
            (member-info (unwrap! (get-member-by-address tx-sender) ERR-NOT-MEMBER))
            (member-id (get member-id member-info))
            (research-id (var-get next-research-id))
        )
        ;; Create research paper record
        (map-set research-papers
            { research-id: research-id }
            {
                title: title,
                abstract: abstract,
                author: member-id,
                co-authors: co-authors,
                ipfs-hash: ipfs-hash,
                peer-reviews: u0,
                average-rating: u0,
                publication-block: block-height,
                category: category,
                is-open-access: is-open-access
            }
        )
        
        ;; Update member reputation and stats
        (let ((current-member (unwrap! (map-get? members { member-id: member-id }) ERR-NOT-FOUND)))
            (map-set members
                { member-id: member-id }
                (merge current-member 
                    {
                        research-contributions: (+ (get research-contributions current-member) u1),
                        reputation: (+ (get reputation current-member) u25)
                    }
                )
            )
        )
        
        ;; Update counter
        (var-set next-research-id (+ research-id u1))
        
        (ok research-id)
    )
)

(define-public (submit-peer-review 
    (research-id uint)
    (rating uint)
    (review-hash (string-ascii 100))
)
    (let 
        (
            (member-info (unwrap! (get-member-by-address tx-sender) ERR-NOT-MEMBER))
            (member-id (get member-id member-info))
            (research (unwrap! (map-get? research-papers { research-id: research-id }) ERR-NOT-FOUND))
        )
        (asserts! (and (>= rating u1) (<= rating u10)) ERR-INVALID-REPUTATION)
        (asserts! (not (is-eq member-id (get author research))) ERR-OWNER-ONLY) ;; Can't review own paper
        
        ;; Submit review
        (map-set peer-reviews
            { research-id: research-id, reviewer-id: member-id }
            {
                rating: rating,
                review-hash: review-hash,
                submitted-block: block-height
            }
        )
        
        ;; Update research paper stats
        (let 
            (
                (current-reviews (get peer-reviews research))
                (current-avg (get average-rating research))
                (new-avg (/ (+ (* current-avg current-reviews) rating) (+ current-reviews u1)))
            )
            (map-set research-papers
                { research-id: research-id }
                (merge research 
                    {
                        peer-reviews: (+ current-reviews u1),
                        average-rating: new-avg
                    }
                )
            )
        )
        
        ;; Update reviewer reputation
        (let ((current-member (unwrap! (map-get? members { member-id: member-id }) ERR-NOT-FOUND)))
            (map-set members
                { member-id: member-id }
                (merge current-member { reputation: (+ (get reputation current-member) u15) })
            )
        )
        
        (ok true)
    )
)

;; Collaboration functions
(define-public (create-collaboration
    (title (string-ascii 100))
    (description (string-ascii 500))
    (initial-members (list 20 uint))
)
    (let 
        (
            (member-info (unwrap! (get-member-by-address tx-sender) ERR-NOT-MEMBER))
            (member-id (get member-id member-info))
            (collaboration-id (var-get next-collaboration-id))
        )
        (map-set collaborations
            { collaboration-id: collaboration-id }
            {
                title: title,
                description: description,
                leader: member-id,
                members: initial-members,
                start-block: block-height,
                end-block: none,
                status: "active"
            }
        )
        
        (var-set next-collaboration-id (+ collaboration-id u1))
        (ok collaboration-id)
    )
)

;; Treasury functions
(define-public (fund-treasury)
    (let ((amount (stx-get-balance tx-sender)))
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        (var-set treasury-balance (+ (var-get treasury-balance) amount))
        (ok amount)
    )
)

;; Administrative functions (only owner)
(define-public (set-platform-fee (new-fee uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
        (var-set platform-fee new-fee)
        (ok true)
    )
)

;; Helper functions
(define-private (calculate-vote-weight (stake uint) (reputation uint))
    (+ 
        (/ stake u100000) ;; Stake weight (1 vote per 0.1 STX)
        (/ reputation u10)  ;; Reputation weight
    )
)

(define-private (get-member-by-address (address principal))
    (map-get? member-by-address { address: address })
)

;; Read-only functions
(define-read-only (get-member-info (member-id uint))
    (map-get? members { member-id: member-id })
)

(define-read-only (get-member-by-principal (address principal))
    (match (map-get? member-by-address { address: address })
        member-ref (map-get? members { member-id: (get member-id member-ref) })
        none
    )
)

(define-read-only (get-proposal (proposal-id uint))
    (map-get? proposals { proposal-id: proposal-id })
)

(define-read-only (get-research-paper (research-id uint))
    (map-get? research-papers { research-id: research-id })
)

(define-read-only (get-collaboration (collaboration-id uint))
    (map-get? collaborations { collaboration-id: collaboration-id })
)

(define-read-only (get-vote (proposal-id uint) (member-id uint))
    (map-get? votes { proposal-id: proposal-id, member-id: member-id })
)

(define-read-only (get-peer-review (research-id uint) (reviewer-id uint))
    (map-get? peer-reviews { research-id: research-id, reviewer-id: reviewer-id })
)

(define-read-only (get-treasury-balance)
    (var-get treasury-balance)
)

(define-read-only (get-platform-stats)
    {
        total-members: (var-get total-members),
        treasury-balance: (var-get treasury-balance),
        next-proposal-id: (var-get next-proposal-id),
        next-research-id: (var-get next-research-id),
        platform-fee: (var-get platform-fee)
    }
)

(define-read-only (is-member (address principal))
    (is-some (map-get? member-by-address { address: address }))
)
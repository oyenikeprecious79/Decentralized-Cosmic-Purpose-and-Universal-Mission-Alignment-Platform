;; Cosmic Service Opportunity Contract
;; Connects individuals with opportunities to serve universal evolution

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u400))
(define-constant ERR-INVALID-INPUT (err u401))
(define-constant ERR-SERVICE-NOT-FOUND (err u402))
(define-constant ERR-ALREADY-APPLIED (err u403))
(define-constant ERR-SERVICE-FULL (err u404))
(define-constant ERR-NOT-QUALIFIED (err u405))

;; Data Variables
(define-data-var service-counter uint u0)
(define-data-var application-counter uint u0)

;; Data Maps
(define-map service-opportunities
  { service-id: uint }
  {
    creator: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    service-type: (string-ascii 50),
    required-skills: (string-ascii 200),
    consciousness-requirement: uint,
    max-participants: uint,
    current-participants: uint,
    duration-blocks: uint,
    cosmic-impact-level: uint,
    creation-time: uint,
    start-time: uint,
    end-time: uint,
    status: (string-ascii 20),
    total-applications: uint,
    is-active: bool
  }
)

(define-map service-applications
  { service-id: uint, applicant: principal }
  {
    application-time: uint,
    motivation: (string-ascii 300),
    relevant-experience: (string-ascii 300),
    consciousness-level: uint,
    commitment-level: uint,
    status: (string-ascii 20),
    reviewer: (optional principal),
    review-time: (optional uint),
    review-notes: (optional (string-ascii 200))
  }
)

(define-map service-participation
  { service-id: uint, participant: principal }
  {
    start-time: uint,
    contribution-hours: uint,
    impact-rating: uint,
    completion-status: (string-ascii 20),
    feedback: (string-ascii 300),
    cosmic-growth: uint
  }
)

(define-map user-service-profile
  { user: principal }
  {
    services-created: uint,
    services-completed: uint,
    total-service-hours: uint,
    cosmic-service-score: uint,
    specializations: (string-ascii 200),
    availability-status: (string-ascii 20),
    last-activity: uint
  }
)

;; Private Functions
(define-private (calculate-cosmic-impact (service-type (string-ascii 50)) (participants uint) (duration uint))
  (let (
    (type-multiplier (if (is-eq service-type "consciousness") u3
      (if (is-eq service-type "healing") u2
        (if (is-eq service-type "education") u2
          u1
        )
      )
    ))
    (scale-factor (+ u1 (/ participants u5)))
    (duration-factor (+ u1 (/ duration u1000)))
  )
    (* (* type-multiplier scale-factor) duration-factor)
  )
)

(define-private (is-valid-service-type (service-type (string-ascii 50)))
  (or
    (is-eq service-type "consciousness")
    (is-eq service-type "healing")
    (is-eq service-type "education")
    (is-eq service-type "environmental")
    (is-eq service-type "technological")
    (is-eq service-type "artistic")
    (is-eq service-type "research")
  )
)

(define-private (meets-requirements (applicant-consciousness uint) (required-consciousness uint))
  (>= applicant-consciousness required-consciousness)
)

;; Public Functions

;; Create a service opportunity
(define-public (create-service-opportunity
  (title (string-ascii 100))
  (description (string-ascii 500))
  (service-type (string-ascii 50))
  (required-skills (string-ascii 200))
  (consciousness-requirement uint)
  (max-participants uint)
  (duration-blocks uint)
)
  (let (
    (service-id (+ (var-get service-counter) u1))
    (creator tx-sender)
    (cosmic-impact (calculate-cosmic-impact service-type max-participants duration-blocks))
  )
    (asserts! (> (len title) u5) ERR-INVALID-INPUT)
    (asserts! (> (len description) u20) ERR-INVALID-INPUT)
    (asserts! (is-valid-service-type service-type) ERR-INVALID-INPUT)
    (asserts! (and (>= consciousness-requirement u1) (<= consciousness-requirement u100)) ERR-INVALID-INPUT)
    (asserts! (and (> max-participants u0) (<= max-participants u100)) ERR-INVALID-INPUT)
    (asserts! (> duration-blocks u0) ERR-INVALID-INPUT)

    (map-set service-opportunities
      { service-id: service-id }
      {
        creator: creator,
        title: title,
        description: description,
        service-type: service-type,
        required-skills: required-skills,
        consciousness-requirement: consciousness-requirement,
        max-participants: max-participants,
        current-participants: u0,
        duration-blocks: duration-blocks,
        cosmic-impact-level: cosmic-impact,
        creation-time: block-height,
        start-time: (+ block-height u144),
        end-time: (+ block-height duration-blocks),
        status: "open",
        total-applications: u0,
        is-active: true
      }
    )

    (var-set service-counter service-id)

    ;; Update creator profile
    (let ((creator-profile (default-to
      { services-created: u0, services-completed: u0, total-service-hours: u0, cosmic-service-score: u0, specializations: "", availability-status: "available", last-activity: u0 }
      (map-get? user-service-profile { user: creator })
    )))
      (map-set user-service-profile
        { user: creator }
        (merge creator-profile {
          services-created: (+ (get services-created creator-profile) u1),
          last-activity: block-height
        })
      )
    )

    (ok service-id)
  )
)

;; Apply for service opportunity
(define-public (apply-for-service
  (service-id uint)
  (motivation (string-ascii 300))
  (relevant-experience (string-ascii 300))
  (consciousness-level uint)
  (commitment-level uint)
)
  (let (
    (applicant tx-sender)
    (service-data (unwrap! (map-get? service-opportunities { service-id: service-id }) ERR-SERVICE-NOT-FOUND))
  )
    (asserts! (> (len motivation) u20) ERR-INVALID-INPUT)
    (asserts! (and (>= consciousness-level u1) (<= consciousness-level u100)) ERR-INVALID-INPUT)
    (asserts! (and (>= commitment-level u1) (<= commitment-level u10)) ERR-INVALID-INPUT)
    (asserts! (is-eq (get status service-data) "open") ERR-INVALID-INPUT)
    (asserts! (< (get current-participants service-data) (get max-participants service-data)) ERR-SERVICE-FULL)
    (asserts! (is-none (map-get? service-applications { service-id: service-id, applicant: applicant })) ERR-ALREADY-APPLIED)
    (asserts! (meets-requirements consciousness-level (get consciousness-requirement service-data)) ERR-NOT-QUALIFIED)

    (map-set service-applications
      { service-id: service-id, applicant: applicant }
      {
        application-time: block-height,
        motivation: motivation,
        relevant-experience: relevant-experience,
        consciousness-level: consciousness-level,
        commitment-level: commitment-level,
        status: "pending",
        reviewer: none,
        review-time: none,
        review-notes: none
      }
    )

    ;; Update service application count
    (map-set service-opportunities
      { service-id: service-id }
      (merge service-data {
        total-applications: (+ (get total-applications service-data) u1)
      })
    )

    (ok true)
  )
)

;; Review service application
(define-public (review-application
  (service-id uint)
  (applicant principal)
  (approved bool)
  (review-notes (string-ascii 200))
)
  (let (
    (reviewer tx-sender)
    (service-data (unwrap! (map-get? service-opportunities { service-id: service-id }) ERR-SERVICE-NOT-FOUND))
    (application-data (unwrap! (map-get? service-applications { service-id: service-id, applicant: applicant }) ERR-INVALID-INPUT))
  )
    (asserts! (is-eq reviewer (get creator service-data)) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status application-data) "pending") ERR-INVALID-INPUT)

    (map-set service-applications
      { service-id: service-id, applicant: applicant }
      (merge application-data {
        status: (if approved "approved" "rejected"),
        reviewer: (some reviewer),
        review-time: (some block-height),
        review-notes: (some review-notes)
      })
    )

    ;; If approved, add to participants
    (if approved
      (begin
        (map-set service-participation
          { service-id: service-id, participant: applicant }
          {
            start-time: block-height,
            contribution-hours: u0,
            impact-rating: u0,
            completion-status: "active",
            feedback: "",
            cosmic-growth: u0
          }
        )

        ;; Update participant count
        (map-set service-opportunities
          { service-id: service-id }
          (merge service-data {
            current-participants: (+ (get current-participants service-data) u1)
          })
        )
      )
      true
    )

    (ok true)
  )
)

;; Complete service participation
(define-public (complete-service-participation
  (service-id uint)
  (contribution-hours uint)
  (feedback (string-ascii 300))
)
  (let (
    (participant tx-sender)
    (participation-data (unwrap! (map-get? service-participation { service-id: service-id, participant: participant }) ERR-INVALID-INPUT))
  )
    (asserts! (is-eq (get completion-status participation-data) "active") ERR-INVALID-INPUT)
    (asserts! (> contribution-hours u0) ERR-INVALID-INPUT)

    (map-set service-participation
      { service-id: service-id, participant: participant }
      (merge participation-data {
        contribution-hours: contribution-hours,
        completion-status: "completed",
        feedback: feedback,
        cosmic-growth: (/ contribution-hours u10)
      })
    )

    ;; Update user profile
    (let ((user-profile (default-to
      { services-created: u0, services-completed: u0, total-service-hours: u0, cosmic-service-score: u0, specializations: "", availability-status: "available", last-activity: u0 }
      (map-get? user-service-profile { user: participant })
    )))
      (map-set user-service-profile
        { user: participant }
        (merge user-profile {
          services-completed: (+ (get services-completed user-profile) u1),
          total-service-hours: (+ (get total-service-hours user-profile) contribution-hours),
          cosmic-service-score: (+ (get cosmic-service-score user-profile) (/ contribution-hours u10)),
          last-activity: block-height
        })
      )
    )

    (ok true)
  )
)

;; Rate service participation
(define-public (rate-participation
  (service-id uint)
  (participant principal)
  (impact-rating uint)
)
  (let (
    (rater tx-sender)
    (service-data (unwrap! (map-get? service-opportunities { service-id: service-id }) ERR-SERVICE-NOT-FOUND))
    (participation-data (unwrap! (map-get? service-participation { service-id: service-id, participant: participant }) ERR-INVALID-INPUT))
  )
    (asserts! (is-eq rater (get creator service-data)) ERR-NOT-AUTHORIZED)
    (asserts! (and (>= impact-rating u1) (<= impact-rating u10)) ERR-INVALID-INPUT)
    (asserts! (is-eq (get completion-status participation-data) "completed") ERR-INVALID-INPUT)

    (map-set service-participation
      { service-id: service-id, participant: participant }
      (merge participation-data {
        impact-rating: impact-rating
      })
    )

    (ok true)
  )
)

;; Read-only Functions

;; Get service opportunity details
(define-read-only (get-service-opportunity (service-id uint))
  (map-get? service-opportunities { service-id: service-id })
)

;; Get application details
(define-read-only (get-application (service-id uint) (applicant principal))
  (map-get? service-applications { service-id: service-id, applicant: applicant })
)

;; Get participation details
(define-read-only (get-participation (service-id uint) (participant principal))
  (map-get? service-participation { service-id: service-id, participant: participant })
)

;; Get user service profile
(define-read-only (get-user-service-profile (user principal))
  (map-get? user-service-profile { user: user })
)

;; Get total services count
(define-read-only (get-total-services)
  (var-get service-counter)
)

;; Check if service is available
(define-read-only (is-service-available (service-id uint))
  (match (map-get? service-opportunities { service-id: service-id })
    service-data
    (and
      (is-eq (get status service-data) "open")
      (< (get current-participants service-data) (get max-participants service-data))
      (get is-active service-data)
    )
    false
  )
)

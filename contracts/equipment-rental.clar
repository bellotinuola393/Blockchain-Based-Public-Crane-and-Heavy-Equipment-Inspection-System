;; Equipment Rental Contract
;; Manages rental of heavy equipment between government departments

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u500))
(define-constant ERR-EQUIPMENT-NOT-FOUND (err u501))
(define-constant ERR-INVALID-INPUT (err u502))
(define-constant ERR-RENTAL-NOT-FOUND (err u503))
(define-constant ERR-EQUIPMENT-NOT-AVAILABLE (err u504))
(define-constant ERR-INSUFFICIENT-FUNDS (err u505))

;; Data Variables
(define-data-var next-equipment-id uint u1)
(define-data-var next-rental-id uint u1)

;; Data Maps
(define-map rental-equipment
  { equipment-id: (string-ascii 20) }
  {
    equipment-type: (string-ascii 50),
    manufacturer: (string-ascii 50),
    model: (string-ascii 50),
    year: uint,
    owner-department: (string-ascii 100),
    daily-rate: uint,
    hourly-rate: uint,
    status: (string-ascii 20),
    location: (string-ascii 200),
    condition: (string-ascii 50),
    last-maintenance: uint,
    created-at: uint
  }
)

(define-map rental-agreements
  { rental-id: uint }
  {
    equipment-id: (string-ascii 20),
    renter-department: (string-ascii 100),
    renter-contact: principal,
    start-date: uint,
    end-date: uint,
    rental-type: (string-ascii 20),
    total-cost: uint,
    deposit: uint,
    status: (string-ascii 20),
    pickup-location: (string-ascii 200),
    return-location: (string-ascii 200),
    created-at: uint
  }
)

(define-map department-budgets
  { department: (string-ascii 100) }
  { available-budget: uint }
)

(define-map department-managers
  { manager: principal }
  { department: (string-ascii 100) }
)

(define-map equipment-availability
  { equipment-id: (string-ascii 20) }
  { available-from: uint, available-until: uint }
)

;; Authorization checks
(define-private (is-department-manager (caller principal))
  (or (is-eq caller CONTRACT-OWNER)
      (is-some (map-get? department-managers { manager: caller }))))

;; Register equipment for rental
(define-public (register-rental-equipment
  (equipment-id (string-ascii 20))
  (equipment-type (string-ascii 50))
  (manufacturer (string-ascii 50))
  (model (string-ascii 50))
  (year uint)
  (owner-department (string-ascii 100))
  (daily-rate uint)
  (hourly-rate uint)
  (location (string-ascii 200)))
  (let ((current-time (unwrap-panic (get-block-info? time (- block-height u1)))))

    (asserts! (is-department-manager tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> (len equipment-id) u0) ERR-INVALID-INPUT)
    (asserts! (> (len equipment-type) u0) ERR-INVALID-INPUT)
    (asserts! (> year u1900) ERR-INVALID-INPUT)
    (asserts! (< year u2030) ERR-INVALID-INPUT)
    (asserts! (> daily-rate u0) ERR-INVALID-INPUT)
    (asserts! (is-none (map-get? rental-equipment { equipment-id: equipment-id })) ERR-EQUIPMENT-NOT-AVAILABLE)

    (map-set rental-equipment
      { equipment-id: equipment-id }
      {
        equipment-type: equipment-type,
        manufacturer: manufacturer,
        model: model,
        year: year,
        owner-department: owner-department,
        daily-rate: daily-rate,
        hourly-rate: hourly-rate,
        status: "available",
        location: location,
        condition: "good",
        last-maintenance: current-time,
        created-at: current-time
      })

    ;; Set initial availability
    (map-set equipment-availability
      { equipment-id: equipment-id }
      { available-from: current-time, available-until: (+ current-time u31536000) }) ;; 1 year

    (ok equipment-id)))

;; Request equipment rental
(define-public (request-rental
  (equipment-id (string-ascii 20))
  (renter-department (string-ascii 100))
  (start-date uint)
  (end-date uint)
  (rental-type (string-ascii 20))
  (pickup-location (string-ascii 200)))
  (let ((equipment-data (unwrap! (map-get? rental-equipment { equipment-id: equipment-id }) ERR-EQUIPMENT-NOT-FOUND))
        (rental-id (var-get next-rental-id))
        (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
        (rental-days (/ (- end-date start-date) u86400))
        (total-cost (if (is-eq rental-type "daily")
                      (* rental-days (get daily-rate equipment-data))
                      (* (/ (- end-date start-date) u3600) (get hourly-rate equipment-data))))
        (deposit (/ total-cost u2))) ;; 50% deposit

    (asserts! (is-department-manager tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status equipment-data) "available") ERR-EQUIPMENT-NOT-AVAILABLE)
    (asserts! (> start-date current-time) ERR-INVALID-INPUT)
    (asserts! (> end-date start-date) ERR-INVALID-INPUT)
    (asserts! (> (len renter-department) u0) ERR-INVALID-INPUT)

    ;; Check department budget
    (let ((dept-budget (get available-budget (default-to { available-budget: u0 }
                                            (map-get? department-budgets { department: renter-department })))))
      (asserts! (>= dept-budget total-cost) ERR-INSUFFICIENT-FUNDS)

      ;; Deduct from budget
      (map-set department-budgets
        { department: renter-department }
        { available-budget: (- dept-budget total-cost) }))

    (map-set rental-agreements
      { rental-id: rental-id }
      {
        equipment-id: equipment-id,
        renter-department: renter-department,
        renter-contact: tx-sender,
        start-date: start-date,
        end-date: end-date,
        rental-type: rental-type,
        total-cost: total-cost,
        deposit: deposit,
        status: "pending",
        pickup-location: pickup-location,
        return-location: pickup-location,
        created-at: current-time
      })

    (var-set next-rental-id (+ rental-id u1))
    (ok rental-id)))

;; Approve rental request
(define-public (approve-rental (rental-id uint))
  (let ((rental-data (unwrap! (map-get? rental-agreements { rental-id: rental-id }) ERR-RENTAL-NOT-FOUND)))
    (asserts! (is-department-manager tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status rental-data) "pending") ERR-INVALID-INPUT)

    ;; Update rental status
    (map-set rental-agreements
      { rental-id: rental-id }
      (merge rental-data { status: "approved" }))

    ;; Update equipment status
    (let ((equipment-data (unwrap-panic (map-get? rental-equipment { equipment-id: (get equipment-id rental-data) }))))
      (map-set rental-equipment
        { equipment-id: (get equipment-id rental-data) }
        (merge equipment-data { status: "rented" })))

    (ok true)))

;; Complete rental return
(define-public (complete-return
  (rental-id uint)
  (return-condition (string-ascii 50))
  (damage-cost uint))
  (let ((rental-data (unwrap! (map-get? rental-agreements { rental-id: rental-id }) ERR-RENTAL-NOT-FOUND))
        (current-time (unwrap-panic (get-block-info? time (- block-height u1)))))

    (asserts! (is-department-manager tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status rental-data) "approved") ERR-INVALID-INPUT)

    ;; Update rental status
    (map-set rental-agreements
      { rental-id: rental-id }
      (merge rental-data { status: "completed" }))

    ;; Update equipment status and condition
    (let ((equipment-data (unwrap-panic (map-get? rental-equipment { equipment-id: (get equipment-id rental-data) }))))
      (map-set rental-equipment
        { equipment-id: (get equipment-id rental-data) }
        (merge equipment-data {
          status: "available",
          condition: return-condition
        })))

    ;; Handle damage costs if any
    (if (> damage-cost u0)
      (let ((dept-budget (get available-budget (default-to { available-budget: u0 }
                                              (map-get? department-budgets { department: (get renter-department rental-data) })))))
        (if (>= dept-budget damage-cost)
          (map-set department-budgets
            { department: (get renter-department rental-data) }
            { available-budget: (- dept-budget damage-cost) })
          true)) ;; Handle insufficient funds for damages
      true)

    (ok true)))

;; Set department budget
(define-public (set-department-budget
  (department (string-ascii 100))
  (budget uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> (len department) u0) ERR-INVALID-INPUT)
    (asserts! (> budget u0) ERR-INVALID-INPUT)

    (map-set department-budgets
      { department: department }
      { available-budget: budget })

    (ok true)))

;; Add department manager
(define-public (add-department-manager
  (manager principal)
  (department (string-ascii 100)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> (len department) u0) ERR-INVALID-INPUT)

    (map-set department-managers { manager: manager } { department: department })
    (ok true)))

;; Get equipment information
(define-read-only (get-rental-equipment (equipment-id (string-ascii 20)))
  (map-get? rental-equipment { equipment-id: equipment-id }))

;; Get rental agreement
(define-read-only (get-rental-agreement (rental-id uint))
  (map-get? rental-agreements { rental-id: rental-id }))

;; Check equipment availability
(define-read-only (is-equipment-available
  (equipment-id (string-ascii 20))
  (start-date uint)
  (end-date uint))
  (let ((equipment-data (unwrap! (map-get? rental-equipment { equipment-id: equipment-id }) (err false)))
        (availability (map-get? equipment-availability { equipment-id: equipment-id })))
    (ok (and (is-eq (get status equipment-data) "available")
             (match availability
               avail-data (and (>= start-date (get available-from avail-data))
                              (<= end-date (get available-until avail-data)))
               true)))))

;; Update equipment condition
(define-public (update-equipment-condition
  (equipment-id (string-ascii 20))
  (new-condition (string-ascii 50)))
  (let ((equipment-data (unwrap! (map-get? rental-equipment { equipment-id: equipment-id }) ERR-EQUIPMENT-NOT-FOUND)))
    (asserts! (is-department-manager tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> (len new-condition) u0) ERR-INVALID-INPUT)

    (map-set rental-equipment
      { equipment-id: equipment-id }
      (merge equipment-data { condition: new-condition }))

    (ok true)))

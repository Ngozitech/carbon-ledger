;; Define constants
(define-constant admin-address tx-sender)
(define-constant error-admin-only (err u100))
(define-constant error-unauthorized (err u101))
(define-constant error-invalid-certificate (err u102))
(define-constant error-certificate-expired (err u103))
(define-constant error-not-certificate-owner (err u104))
(define-constant error-invalid-parameters (err u105))

;; Define data maps for carbon credit certificates and management
(define-map verifiers principal bool)
(define-map certificates 
    uint ;; certificate-id
    {
        holder: principal,
        producer: principal,
        carbon-amount: uint,
        issuance-time: uint, ;; block height
        validity-period: uint, ;; block height
        region: (string-ascii 50),
        method: (string-ascii 20),
        project-id: (string-ascii 34),
        verified: bool
    }
)

(define-map certificate-holders 
    principal 
    (list 500 uint)) ;; List of certificate IDs owned by address

(define-map transaction-history
    { certificate-id: uint, history-index: uint } ;; Composite key
    { sender: principal, receiver: principal, block-time: uint })

(define-map history-counters uint uint) ;; Maps certificate-id to current history index

(define-data-var current-certificate-id uint u0)

;; Authorization functions
(define-public (add-verifier (verifier principal))
    (begin
        (asserts! (is-eq tx-sender admin-address) error-admin-only)
        (asserts! (not (is-eq verifier admin-address)) error-invalid-parameters) ;; Prevent admin from being verifier
        (asserts! (not (default-to false (map-get? verifiers verifier))) error-invalid-parameters) ;; Check if already registered
        (ok (map-set verifiers verifier true))))

(define-public (deactivate-verifier (verifier principal))
    (begin
        (asserts! (is-eq tx-sender admin-address) error-admin-only)
        (asserts! (default-to false (map-get? verifiers verifier)) error-invalid-parameters) ;; Check if verifier exists
        (ok (map-set verifiers verifier false))))

;; Core carbon credit certificate functions
(define-public (issue-certificate
    (producer principal)
    (carbon-amount uint)
    (region (string-ascii 50))
    (method (string-ascii 20))
    (project-id (string-ascii 34)))
    (let
        (
            (certificate-id (+ (var-get current-certificate-id) u1))
            (validity-period (+ block-height u144)) ;; Set to ~24 hours for testing
        )
        ;; Input validation
        (asserts! (default-to false (map-get? verifiers tx-sender)) error-unauthorized)
        (asserts! (not (is-eq producer tx-sender)) error-invalid-parameters) ;; Producer cannot be verifier
        (asserts! (validate-carbon-amount carbon-amount) error-invalid-parameters)
        (asserts! (validate-region region) error-invalid-parameters)
        (asserts! (validate-method method) error-invalid-parameters)
        (asserts! (validate-project-id project-id) error-invalid-parameters)
        
        ;; Create new certificate after validation
        (map-set certificates certificate-id {
            holder: producer,
            producer: producer,
            carbon-amount: carbon-amount,
            issuance-time: block-height,
            validity-period: validity-period,
            region: region,
            method: method,
            project-id: project-id,
            verified: true
        })
        
        ;; Update certificate ID counter
        (var-set current-certificate-id certificate-id)
        (ok certificate-id)
    )
)

;; Simple transfer function with transaction logging
(define-public (transfer-certificate (certificate-id uint) (recipient principal))
    (match (map-get? certificates certificate-id)
        certificate
        (begin
            (asserts! (is-eq (get holder certificate) tx-sender) error-not-certificate-owner)
            (asserts! (not (is-certificate-expired certificate-id)) error-certificate-expired)
            (asserts! (not (is-eq recipient tx-sender)) error-invalid-parameters) ;; Cannot transfer to self
            (asserts! (not (is-eq recipient (get producer certificate))) error-invalid-parameters) ;; Cannot transfer back to producer
            (map-set certificates certificate-id (merge certificate {holder: recipient}))
            ;; Log the transfer
            (record-transfer certificate-id (get holder certificate) recipient)
            (ok true))
        error-invalid-certificate))

;; Record transfer helper
(define-private (record-transfer (certificate-id uint) (sender principal) (receiver principal))
    (let (
            (current-index (default-to u0 (map-get? history-counters certificate-id)))
            (new-index (mod (+ current-index u1) u100)) ;; Circular buffer from 0 to 99
        )
        ;; Store the history entry with composite key {certificate-id, history-index: new-index}
        (map-set transaction-history { certificate-id: certificate-id, history-index: new-index }
            { sender: sender, receiver: receiver, block-time: block-height })
        ;; Update the history counter for this certificate-id
        (map-set history-counters certificate-id new-index)))

;; Read-only functions
(define-read-only (get-certificate (certificate-id uint))
    (map-get? certificates certificate-id))

(define-read-only (is-verifier (address principal))
    (default-to false (map-get? verifiers address)))

(define-read-only (is-certificate-expired (certificate-id uint))
    (match (map-get? certificates certificate-id)
        certificate (> block-height (get validity-period certificate))
        false))

;; Function to get the latest history index for a certificate
(define-read-only (get-history-count (certificate-id uint))
    (default-to u0 (map-get? history-counters certificate-id)))

;; Function to get a specific transfer history entry
(define-read-only (get-transfer-history (certificate-id uint) (history-index uint))
    (map-get? transaction-history { certificate-id: certificate-id, history-index: history-index }))

;; Input validation functions
(define-private (validate-carbon-amount (amount uint))
    (and (> amount u0) (<= amount u1000000))) ;; Max 1 million carbon units per certificate

(define-private (validate-region (reg (string-ascii 50)))
    (and 
        (> (len reg) u0)
        (<= (len reg) u50)))

(define-private (validate-method (meth (string-ascii 20)))
    (and 
        (> (len meth) u0)
        (<= (len meth) u20)))

(define-private (validate-project-id (id (string-ascii 34)))
    (and 
        (> (len id) u0)
        (<= (len id) u34)))
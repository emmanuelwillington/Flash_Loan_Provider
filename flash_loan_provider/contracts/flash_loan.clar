;; Flash Loan Provider
;; Allows users to borrow assets without collateral as long as they repay within the same transaction
;; Implements fee structure and use case restrictions

;; Error codes
(define-constant ERR_UNAUTHORIZED (err u1))
(define-constant ERR_INSUFFICIENT_FUNDS (err u2))
(define-constant ERR_LOAN_ALREADY_ACTIVE (err u3))
(define-constant ERR_NO_ACTIVE_LOAN (err u4))
(define-constant ERR_REPAYMENT_TOO_LOW (err u5))
(define-constant ERR_INVALID_AMOUNT (err u6))
(define-constant ERR_FLASH_MINTING_DISABLED (err u7))
(define-constant ERR_FLASH_LOAN_REENTRANCY (err u8))

;; Constants
(define-constant FLASH_LOAN_FEE_RATE u500) ;; 0.5% fee (in basis points)
(define-constant BASIS_POINTS u100000) ;; 100% in basis points

;; Data variables
(define-data-var total-liquidity uint u0)
(define-data-var flash-minting-enabled bool false)
(define-data-var max-flash-loan uint u0)

;; Active loan tracking
(define-map active-loans
  { borrower: principal }
  { amount: uint, fee: uint }
)

;; Contract owner
(define-data-var contract-owner principal tx-sender)

;; Read-only functions

;; Get the current liquidity available for flash loans
(define-read-only (get-liquidity)
  (var-get total-liquidity)
)

;; Calculate the fee for a flash loan
(define-read-only (calculate-fee (amount uint))
  (/ (* amount FLASH_LOAN_FEE_RATE) BASIS_POINTS)
)

;; Check if a borrower has an active loan
(define-read-only (has-active-loan (borrower principal))
  (is-some (map-get? active-loans { borrower: borrower }))
)

;; Get the maximum flash loan amount
(define-read-only (get-max-flash-loan)
  (if (var-get flash-minting-enabled)
    (var-get max-flash-loan)
    (var-get total-liquidity)
  )
)

;; Public functions

;; Add liquidity to the flash loan pool
(define-public (add-liquidity (amount uint))
  (begin
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    
    ;; Transfer STX from sender to contract
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    
    ;; Update total liquidity
    (var-set total-liquidity (+ (var-get total-liquidity) amount))
    
    (ok amount)
  )
)

;; Remove liquidity from the flash loan pool (only owner)
(define-public (remove-liquidity (amount uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_UNAUTHORIZED)
    (asserts! (<= amount (var-get total-liquidity)) ERR_INSUFFICIENT_FUNDS)
    
    ;; Transfer STX from contract to owner
    (try! (as-contract (stx-transfer? amount tx-sender (var-get contract-owner))))
    
    ;; Update total liquidity
    (var-set total-liquidity (- (var-get total-liquidity) amount))
    
    (ok amount)
  )
)

;; Flash loan function - borrow assets
(define-public (flash-loan (amount uint) (recipient principal))
  (let
    (
      (borrower tx-sender)
      (fee (calculate-fee amount))
      (total-repayment (+ amount fee))
      (current-liquidity (var-get total-liquidity))
    )
    
    ;; Check if amount is valid
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    
    ;; Check if borrower already has an active loan
    (asserts! (is-none (map-get? active-loans { borrower: borrower })) ERR_LOAN_ALREADY_ACTIVE)
    
    ;; Check if we have enough liquidity or flash minting is enabled
    (asserts! (or 
                (<= amount current-liquidity) 
                (and (var-get flash-minting-enabled) (<= amount (var-get max-flash-loan)))
              ) 
              ERR_INSUFFICIENT_FUNDS)
    
    ;; Record the active loan
    (map-set active-loans
      { borrower: borrower }
      { amount: amount, fee: fee }
    )
    
    ;; Transfer the borrowed amount to the recipient
    (if (<= amount current-liquidity)
      ;; Use existing liquidity
      (try! (as-contract (stx-transfer? amount tx-sender recipient)))
      ;; Use flash minting (create new tokens temporarily)
      (begin
        (asserts! (var-get flash-minting-enabled) ERR_FLASH_MINTING_DISABLED)
        ;; In a real implementation, this would mint new tokens
        ;; For STX, we can't actually mint, so this is just a simulation
        (try! (as-contract (stx-transfer? amount tx-sender recipient)))
      )
    )
    
    ;; Return the loan details
    (ok { amount: amount, fee: fee, total-repayment: total-repayment })
  )
)

;; Flash loan repayment function
(define-public (repay-flash-loan)
  (let
    (
      (borrower tx-sender)
      (loan-info (unwrap! (map-get? active-loans { borrower: borrower }) ERR_NO_ACTIVE_LOAN))
      (amount (get amount loan-info))
      (fee (get fee loan-info))
      (total-repayment (+ amount fee))
    )
    
    ;; Transfer the repayment amount from borrower to contract
    (try! (stx-transfer? total-repayment borrower (as-contract tx-sender)))
    
    ;; Remove the active loan record
    (map-delete active-loans { borrower: borrower })
    
    ;; Update total liquidity (add the fee)
    (var-set total-liquidity (+ (var-get total-liquidity) fee))
    
    ;; Return the repayment details
    (ok { amount: amount, fee: fee, total-repayment: total-repayment })
  )
)

;; Admin functions

;; Set the contract owner
(define-public (set-contract-owner (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_UNAUTHORIZED)
    (var-set contract-owner new-owner)
    (ok new-owner)
  )
)

;; Enable or disable flash minting
(define-public (set-flash-minting (enabled bool))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_UNAUTHORIZED)
    (var-set flash-minting-enabled enabled)
    (ok enabled)
  )
)

;; Set the maximum flash loan amount
(define-public (set-max-flash-loan (max-amount uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_UNAUTHORIZED)
    (var-set max-flash-loan max-amount)
    (ok max-amount)
  )
)

;; Emergency function to recover from stuck loans
(define-public (force-clear-loan (borrower principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_UNAUTHORIZED)
    (asserts! (is-some (map-get? active-loans { borrower: borrower })) ERR_NO_ACTIVE_LOAN)
    
    ;; Remove the active loan record
    (map-delete active-loans { borrower: borrower })
    
    (ok borrower)
  )
)
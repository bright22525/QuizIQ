;; QuizIQ Smart Contract
;; A decentralized quiz platform on Stacks

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-insufficient-payment (err u103))
(define-constant err-quiz-not-active (err u104))

;; Data Variables
(define-data-var quiz-counter uint u0)
(define-data-var platform-fee uint u1000000) ;; 1 STX in microSTX

;; Data Maps
(define-map quizzes 
  { quiz-id: uint }
  {
    creator: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    reward-pool: uint,
    entry-fee: uint,
    is-active: bool,
    created-at: uint
  }
)

(define-map quiz-questions
  { quiz-id: uint, question-id: uint }
  {
    question: (string-ascii 200),
    option-a: (string-ascii 100),
    option-b: (string-ascii 100),
    option-c: (string-ascii 100),
    option-d: (string-ascii 100),
    correct-answer: (string-ascii 1) ;; "A", "B", "C", or "D"
  }
)

(define-map user-submissions
  { quiz-id: uint, user: principal }
  {
    answers: (list 10 (string-ascii 1)),
    score: uint,
    submitted-at: uint,
    reward-claimed: bool
  }
)

(define-map quiz-participants
  { quiz-id: uint }
  { participant-count: uint }
)

;; Private Functions
(define-private (is-contract-owner)
  (is-eq tx-sender contract-owner)
)

;; Public Functions

;; Create a new quiz
(define-public (create-quiz 
  (title (string-ascii 100))
  (description (string-ascii 500))
  (entry-fee uint)
  (current-block uint)
)
  (let
    (
      (quiz-id (+ (var-get quiz-counter) u1))
    )
    (begin
      (is-eq title title)
      (is-eq description description)
      (is-eq entry-fee entry-fee)
      (is-eq current-block current-block)
      ;; Transfer platform fee to contract owner
      (try! (stx-transfer? (var-get platform-fee) tx-sender contract-owner))
      ;; Store quiz data
      (map-set quizzes
        { quiz-id: quiz-id }
        {
          creator: tx-sender,
          title: title,
          description: description,
          reward-pool: u0,
          entry-fee: entry-fee,
          is-active: true,
          created-at: current-block
        }
      )
      ;; Initialize participant count
      (map-set quiz-participants
        { quiz-id: quiz-id }
        { participant-count: u0 }
      )
      ;; Update counter
      (var-set quiz-counter quiz-id)
      (ok quiz-id)
    )
  )
)

;; Add question to quiz
(define-public (add-question
  (quiz-id uint)
  (question-id uint)
  (question (string-ascii 200))
  (option-a (string-ascii 100))
  (option-b (string-ascii 100))
  (option-c (string-ascii 100))
  (option-d (string-ascii 100))
  (correct-answer (string-ascii 1))
)
  (let
    (
      (checked-quiz-id quiz-id)
      (checked-question-id question-id)
      (checked-question question)
      (checked-option-a option-a)
      (checked-option-b option-b)
      (checked-option-c option-c)
      (checked-option-d option-d)
      (checked-correct-answer correct-answer)
      (quiz-data (unwrap! (map-get? quizzes { quiz-id: checked-quiz-id }) err-not-found))
    )
    (begin
      ;; Check if caller is quiz creator
      (asserts! (is-eq tx-sender (get creator quiz-data)) err-owner-only)
      ;; Add question
      (map-set quiz-questions
        { quiz-id: checked-quiz-id, question-id: checked-question-id }
        {
          question: checked-question,
          option-a: checked-option-a,
          option-b: checked-option-b,
          option-c: checked-option-c,
          option-d: checked-option-d,
          correct-answer: checked-correct-answer
        }
      )
      (ok true)
    )
  )
)

;; Join quiz (pay entry fee)
(define-public (join-quiz (quiz-id uint))
  (let
    (
      (quiz-data (unwrap! (map-get? quizzes { quiz-id: quiz-id }) err-not-found))
      (entry-fee (get entry-fee quiz-data))
      (creator (get creator quiz-data))
    )
    (begin
      ;; Check if quiz is active
      (asserts! (get is-active quiz-data) err-quiz-not-active)
      
      ;; Transfer entry fee to quiz creator
      (if (> entry-fee u0)
        (try! (stx-transfer? entry-fee tx-sender creator))
        true
      )
      
      ;; Update reward pool
      (map-set quizzes
        { quiz-id: quiz-id }
        (merge quiz-data { reward-pool: (+ (get reward-pool quiz-data) entry-fee) })
      )
      
      (ok true)
    )
  )
)

;; Submit quiz answers
(define-public (submit-answers
  (quiz-id uint)
  (answers (list 10 (string-ascii 1)))
  (current-block uint)
)
  (let
    (
      (checked-quiz-id quiz-id)
      (checked-answers answers)
      (checked-current-block current-block)
      (quiz-data (unwrap! (map-get? quizzes { quiz-id: checked-quiz-id }) err-not-found))
    )
    (begin
      ;; Check if quiz is active
      (asserts! (get is-active quiz-data) err-quiz-not-active)
      ;; Store submission
      (map-set user-submissions
        { quiz-id: checked-quiz-id, user: tx-sender }
        {
          answers: checked-answers,
          score: u0, ;; Score will be calculated separately
          submitted-at: checked-current-block,
          reward-claimed: false
        }
      )
      (ok true)
    )
  )
)

;; Update platform fee (owner only)
(define-public (update-platform-fee (new-fee uint))
  (let ((checked-new-fee new-fee))
    (begin
      (asserts! (is-contract-owner) err-owner-only)
      (var-set platform-fee checked-new-fee)
      (ok true)
    )
  )
)

;; Deactivate quiz (creator only)
(define-public (deactivate-quiz (quiz-id uint))
  (let
    (
      (quiz-data (unwrap! (map-get? quizzes { quiz-id: quiz-id }) err-not-found))
    )
    (begin
      ;; Check if caller is quiz creator or contract owner
      (asserts! 
        (or (is-eq tx-sender (get creator quiz-data)) (is-contract-owner))
        err-owner-only
      )
      
      ;; Deactivate quiz
      (map-set quizzes
        { quiz-id: quiz-id }
        (merge quiz-data { is-active: false })
      )
      
      (ok true)
    )
  )
)

;; Read-only functions

;; Get quiz details
(define-read-only (get-quiz (quiz-id uint))
  (map-get? quizzes { quiz-id: quiz-id })
)

;; Get question details
(define-read-only (get-question (quiz-id uint) (question-id uint))
  (map-get? quiz-questions { quiz-id: quiz-id, question-id: question-id })
)

;; Get user submission
(define-read-only (get-user-submission (quiz-id uint) (user principal))
  (map-get? user-submissions { quiz-id: quiz-id, user: user })
)

;; Get current quiz counter
(define-read-only (get-quiz-counter)
  (var-get quiz-counter)
)

;; Get platform fee
(define-read-only (get-platform-fee)
  (var-get platform-fee)
)

;; Get contract owner
(define-read-only (get-contract-owner)
  contract-owner
)

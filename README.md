# QuizIQ Smart Contract

A decentralized quiz platform built on the Stacks blockchain using Clarity.

## Overview

QuizIQ enables anyone to create, join, and participate in quizzes with on-chain rewards. The contract manages quiz creation, question management, user submissions, and reward distribution in a trustless, transparent manner.

## Features

- **Quiz Creation:** Anyone can create a quiz by paying a platform fee.
- **Question Management:** Quiz creators can add questions and specify correct answers.
- **Participation:** Users can join quizzes by paying an entry fee.
- **Submission:** Participants submit answers on-chain.
- **Reward Pool:** Entry fees are pooled and can be distributed to winners.
- **Admin Controls:** Platform fee and quiz deactivation are managed by the contract owner.

## Key Functions

- `create-quiz(title, description, entry-fee, current-block)`: Create a new quiz.
- `add-question(quiz-id, question-id, question, option-a, option-b, option-c, option-d, correct-answer)`: Add a question to a quiz.
- `join-quiz(quiz-id)`: Join a quiz by paying the entry fee.
- `submit-answers(quiz-id, answers, current-block)`: Submit answers to a quiz.
- `update-platform-fee(new-fee)`: Update the platform fee (owner only).
- `deactivate-quiz(quiz-id)`: Deactivate a quiz (creator or owner only).
- Read-only functions for fetching quiz, question, and user submission details.

## Data Structures

- **quizzes:** Stores quiz metadata and state.
- **quiz-questions:** Stores questions and options for each quiz.
- **user-submissions:** Tracks user answers, scores, and reward claims.
- **quiz-participants:** Tracks the number of participants per quiz.

## Usage

1. **Deploy the contract** to your Stacks devnet/testnet/mainnet.
2. **Create a quiz** by calling `create-quiz` with the required parameters.
3. **Add questions** using `add-question`.
4. **Join a quiz** as a participant using `join-quiz`.
5. **Submit answers** with `submit-answers`.
6. **Query quiz and user data** using the read-only functions.

## Development

- Written in [Clarity](https://docs.stacks.co/write-smart-contracts/clarity-lang).
- Compatible with [Clarinet](https://docs.hiro.so/clarinet/get-started) for local development and testing.

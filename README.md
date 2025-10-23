# 📚 Community-Driven Syllabus Protocol

A decentralized smart contract enabling students and faculty to propose and vote on curriculum changes in educational institutions.

## 🌟 Features

- 📝 **Proposal Creation**: Authorized users can create curriculum change proposals
- 🗳️ **Democratic Voting**: Community voting on proposed changes
- 👥 **Role-Based Access**: Separate authorization for students, faculty, and admins
- 📊 **Reputation System**: Track user engagement and contributions
- ⏰ **Time-Based Voting**: Configurable voting periods
- 🎯 **Approval Thresholds**: Customizable approval requirements

## 🚀 Getting Started

### Prerequisites

- Clarinet installed
- Stacks wallet for testing

### Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/Community-Driven-Syllabus-Protocol
cd Community-Driven-Syllabus-Protocol
```

2. Run tests
```bash
clarinet test
```

## 📖 Usage

### 🔧 Contract Initialization

First, initialize the contract and set up authorized users:

```clarity
(contract-call? .Syllabus initialize-contract)
(contract-call? .Syllabus authorize-user 'ST1STUDENT "student")
(contract-call? .Syllabus authorize-user 'ST1FACULTY "faculty")
```

### ✍️ Creating Proposals

Authorized users can create curriculum proposals:

```clarity
(contract-call? .Syllabus create-proposal 
  "Add Machine Learning Course" 
  "Propose adding ML fundamentals to CS curriculum"
)
```

### 🗳️ Voting on Proposals

Vote on existing proposals (true = yes, false = no):

```clarity
(contract-call? .Syllabus vote-on-proposal u1 true)
```

### 🏁 Finalizing Proposals

After voting period ends, finalize the proposal:

```clarity
(contract-call? .Syllabus finalize-proposal u1)
```

## 🔍 Read-Only Functions

### Get Proposal Details
```clarity
(contract-call? .Syllabus get-proposal u1)
```

### Check User's Vote
```clarity
(contract-call? .Syllabus get-user-vote u1 'ST1STUDENT)
```

### View User Reputation
```clarity
(contract-call? .Syllabus get-user-reputation 'ST1STUDENT)
```

### Get Voting Parameters
```clarity
(contract-call? .Syllabus get-voting-parameters)
```

## ⚙️ Configuration

### Update Voting Parameters (Admin Only)

```clarity
(contract-call? .Syllabus update-voting-parameters 
  u2880  ; voting duration in blocks (2 days)
  u15    ; minimum votes required
  u65    ; approval threshold (65%)
)
```

## 📊 Data Structures

### Proposals
- `title`: Short description of the proposal
- `description`: Detailed explanation
- `proposer`: Address of the proposal creator
- `created-at`: Block height when created
- `voting-end`: Block height when voting ends
- `total-votes`: Total number of votes cast
- `yes-votes`: Number of approval votes
- `no-votes`: Number of rejection votes
- `status`: Current status (active, approved, rejected)

### User Roles
- `admin`: Full contract control
- `faculty`: Can create and vote on proposals
- `student`: Can vote on proposals

## 🛡️ Security Features

- Role-based authorization system
- One vote per user per proposal
- Time-limited voting periods
- Owner-only administrative functions
- Input validation for all parameters

## 🧪 Testing

Run the test suite:

```bash
clarinet test
```

Check contract syntax:

```bash
clarinet check
```

## 📈 Reputation System

Users earn reputation points through:
- Creating proposals: +5 points
- Voting on proposals: +1 point
- Having proposals approved: +10 bonus points

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## 📄 License

MIT License - see LICENSE file for details

## 🙋‍♀️ Support

For questions or issues, please open a GitHub issue or contact the development team.

---

*Built with ❤️ using Clarity and Stacks blockchain*

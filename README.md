# Blockchain-Based Public Crane and Heavy Equipment Inspection System

A comprehensive smart contract system for managing public crane and heavy equipment inspections, certifications, maintenance, and safety monitoring on the Stacks blockchain.

## System Overview

This system consists of five interconnected smart contracts that manage different aspects of heavy equipment operations:

1. **Crane Inspection Contract** - Conducts safety inspections of tower cranes and mobile cranes
2. **Operator Certification Contract** - Verifies licenses and training for heavy equipment operators
3. **Maintenance Scheduling Contract** - Tracks maintenance schedules for government-owned equipment
4. **Safety Monitoring Contract** - Ensures construction sites follow safety protocols
5. **Equipment Rental Contract** - Manages rental of heavy equipment between departments

## Key Features

### Crane Inspection System
- Register cranes with detailed specifications
- Schedule and conduct safety inspections
- Track inspection history and compliance status
- Generate inspection certificates
- Monitor crane operational status

### Operator Certification
- Register equipment operators
- Issue and renew certifications
- Track training records
- Verify operator qualifications
- Manage certification expiration

### Maintenance Scheduling
- Schedule preventive maintenance
- Track maintenance history
- Monitor equipment condition
- Generate maintenance reports
- Alert for overdue maintenance

### Safety Monitoring
- Monitor construction site safety compliance
- Track safety incidents
- Generate safety reports
- Enforce safety protocols
- Manage safety certifications

### Equipment Rental
- Manage equipment inventory
- Process rental requests
- Track equipment usage
- Calculate rental costs
- Monitor equipment availability

## Contract Architecture

Each contract is designed to be independent while maintaining data consistency across the system. The contracts use standardized data structures and error handling patterns.

### Data Types
- Equipment records with unique identifiers
- Operator profiles with certification status
- Inspection records with timestamps
- Maintenance schedules with priority levels
- Safety incident reports

### Security Features
- Role-based access control
- Input validation and sanitization
- Comprehensive error handling
- Audit trail for all operations
- Immutable record keeping

## Getting Started

### Prerequisites
- Clarinet CLI installed
- Node.js and npm
- Stacks wallet for testing

### Installation

\`\`\`bash
git clone <repository-url>
cd crane-inspection-system
npm install
\`\`\`

### Testing

\`\`\`bash
npm test
\`\`\`

### Deployment

\`\`\`bash
clarinet deploy
\`\`\`

## Usage Examples

### Register a Crane
\`\`\`clarity
(contract-call? .crane-inspection register-crane
"CRANE-001"
"Tower Crane"
"Liebherr"
"280 EC-H 12"
u2023)
\`\`\`

### Schedule Inspection
\`\`\`clarity
(contract-call? .crane-inspection schedule-inspection
"CRANE-001"
u1704067200
"annual-safety")
\`\`\`

### Certify Operator
\`\`\`clarity
(contract-call? .operator-certification issue-certification
'SP1HTBVD3JG9C05J7HBJTHGR0GGW7KX0RQ2XQGF2
"crane-operator"
u1735689600)
\`\`\`

## API Reference

Detailed API documentation for each contract is available in the respective contract files.

## Contributing

Please read CONTRIBUTING.md for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions, please open an issue in the GitHub repository.

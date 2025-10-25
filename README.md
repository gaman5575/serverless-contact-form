# serverless-contact-form

A serverless web application built with AWS Lambda, API Gateway, DynamoDB, and S3, automated with Terraform. The application processes contact form submissions, stores data in DynamoDB, and serves a static frontend from S3, with CloudWatch alarms and SNS notifications for monitoring and API key security.

## Architecture
- **AWS Lambda**: Processes form data (Node.js 20.x).
- **API Gateway**: Exposes a POST endpoint (`/submit`) with API key authentication.
- **DynamoDB**: Stores form submissions (`ContactForm` table).
- **S3**: Hosts a static HTML form.
- **CloudWatch & SNS**: Monitors Lambda errors with email alerts.

## Setup
1. Deploy infrastructure using `terraform apply` (see `main.tf`).
2. Upload `index.html` to an S3 bucket with static website hosting.
3. Test with:
   ```bash
   curl -X POST https://<api-id>.execute-api.ap-south-1.amazonaws.com/prod/submit -H "Content-Type: application/json" -H "x-api-key: <key>" -d '{"name":"Amit","email":"amit@example.com","message":"Hello!"}'

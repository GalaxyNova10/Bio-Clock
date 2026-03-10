# Bio-Clock Architecture

## System Overview

Bio-Clock is a predictive food spoilage platform powered by **Amazon Nova Pro** on **AWS Bedrock**.
It uses a Flutter Web frontend with a fully serverless AWS backend.

## Architecture Diagram

```
┌─────────────────────┐
│   Flutter Web App   │
│  (Dart / Material)  │
└──────────┬──────────┘
           │ HTTPS (REST)
           ▼
┌─────────────────────┐
│   API Gateway       │
│   (Zero-CORS via    │
│    Lambda Proxy)    │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────────────────────────────┐
│          AWS Lambda (Python 3.10)           │
│  ┌─────────────────────────────────────┐    │
│  │  lambda_handler.py                  │    │
│  │  ─ Auth (Cognito)                   │    │
│  │  ─ Scan Analyze (Rekognition →      │    │
│  │    Nova Pro Converse API)           │    │
│  │  ─ Inventory CRUD (DynamoDB)        │    │
│  │  ─ In-house ML Fallback Engine      │    │
│  └─────────────────────────────────────┘    │
└──────────┬──────────┬───────────┬───────────┘
           │          │           │
     ┌─────▼──┐  ┌────▼────┐  ┌──▼──────────┐
     │Cognito │  │DynamoDB │  │  Bedrock     │
     │User    │  │(Single  │  │  (Nova Pro)  │
     │Pool    │  │ Table)  │  │              │
     └────────┘  └─────────┘  └──────────────┘
                       ▲
                       │
               ┌───────┴───────┐
               │  S3 Bucket    │
               │  (Scan Imgs)  │
               └───────────────┘
```

## Key Services

| Service | Role |
|---------|------|
| **Flutter Web** | Cross-platform UI with camera capture, inventory, auth |
| **API Gateway** | REST API with Lambda proxy integration (Zero-CORS) |
| **AWS Lambda** | Single handler for all routes: auth, scan, inventory |
| **Amazon Bedrock** | Nova Pro v1 Converse API for food analysis |
| **Amazon Rekognition** | Label detection on food images |
| **DynamoDB** | Single-table design (PK/SK) for inventory + stats |
| **Amazon Cognito** | User authentication (email/password) |
| **Amazon S3** | Image storage for scan uploads |

## Zero-CORS Architecture

Instead of relying on browser-side CORS preflight, Bio-Clock uses a **Lambda Proxy Integration**
pattern where CORS headers are injected directly in every Lambda response via the `create_response()`
helper. This prevents browser-side CORS blocks entirely—no OPTIONS preflight failures possible.

---
title: DataDog Lambda Instrumentation Guide
category: AWS Integrations
last_updated: 2025-10-09
tags: [lambda, serverless, apm, instrumentation]
---

# DataDog Lambda Instrumentation Guide

Comprehensive guide for instrumenting AWS Lambda functions with DataDog monitoring, APM, and distributed tracing.

## Instrumentation Methods

### 1. DataDog Lambda Extension (Recommended)

The DataDog Lambda Extension is the preferred method for modern Lambda instrumentation.

**Advantages**:

- No VPC or internet gateway required
- Async log and metric forwarding (no performance impact)
- Simplified configuration
- Automatic trace correlation
- Lower latency than Forwarder

**How it Works**:

- Runs as a Lambda extension (sidecar process)
- Buffers logs, metrics, and traces
- Sends data directly to DataDog during and after invocation
- No additional Lambda functions required

### 2. DataDog Forwarder (Legacy)

An older pattern using a separate Lambda function to forward CloudWatch logs.

**When to Use**:

- Already deployed and working
- Need to collect logs from non-Lambda sources
- Extension not available in your region

**Disadvantages**:

- Requires CloudWatch log subscription
- Additional Lambda function to manage
- Higher latency for data arrival
- More complex VPC networking

### 3. Manual Instrumentation

Direct use of DataDog SDKs without extension or forwarder.

**When to Use**:

- Custom instrumentation requirements
- Non-standard runtimes
- Testing and development

## CDK Implementation Patterns

### Pattern 1: DataDog CDK Constructs (Recommended)

Install the DataDog CDK constructs:

```bash
npm install --save datadog-cdk-constructs-v2
```

Basic implementation:

```typescript
import { Datadog } from 'datadog-cdk-constructs-v2';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import { Secret } from 'aws-cdk-lib/aws-secretsmanager';

export class MyStack extends Stack {
  constructor(scope: Construct, id: string, props: StackProps) {
    super(scope, id, props);

    // Retrieve DataDog API key from Secrets Manager
    const datadogApiKey = Secret.fromSecretNameV2(
      this,
      'DatadogApiKey',
      'datadog/api-key'
    );

    // Create Lambda function
    const myFunction = new lambda.Function(this, 'MyFunction', {
      runtime: lambda.Runtime.PYTHON_3_11,
      handler: 'index.handler',
      code: lambda.Code.fromAsset('lambda'),
      environment: {
        // Your application config
      }
    });

    // Add DataDog instrumentation
    const datadog = new Datadog(this, 'Datadog', {
      pythonLayerVersion: 95,        // Check for latest: https://github.com/DataDog/datadog-lambda-python/releases
      extensionLayerVersion: 58,     // Check for latest: https://github.com/DataDog/datadog-lambda-extension/releases
      apiKeySecret: datadogApiKey,
      site: 'datadoghq.com',
      env: 'production',
      service: 'survivor-atlas',
      version: '1.2.3',
      enableDatadogTracing: true,
      enableDatadogLogs: true,
      enableDatadogASM: false,       // Application Security Management (additional cost)
      tags: 'team:data-platform,cost-center:engineering'
    });

    // Add DataDog to the function
    datadog.addLambdaFunctions([myFunction]);
  }
}
```

### Pattern 2: Manual Layer Addition

For more control, manually add Lambda layers:

```typescript
const myFunction = new lambda.Function(this, 'MyFunction', {
  runtime: lambda.Runtime.PYTHON_3_11,
  handler: 'datadog_lambda.handler.handler',  // DataDog wrapper handler
  code: lambda.Code.fromAsset('lambda'),
  layers: [
    // DataDog Lambda Library Layer
    lambda.LayerVersion.fromLayerVersionArn(
      this,
      'DatadogLayer',
      `arn:aws:lambda:${this.region}:464622532012:layer:Datadog-Python311:95`
    ),
    // DataDog Extension Layer
    lambda.LayerVersion.fromLayerVersionArn(
      this,
      'DatadogExtension',
      `arn:aws:lambda:${this.region}:464622532012:layer:Datadog-Extension:58`
    )
  ],
  environment: {
    // DataDog configuration
    DD_API_KEY_SECRET_ARN: datadogApiKey.secretArn,
    DD_SITE: 'datadoghq.com',
    DD_ENV: 'production',
    DD_SERVICE: 'survivor-atlas',
    DD_VERSION: '1.2.3',
    DD_TAGS: 'team:data-platform,cost-center:engineering',

    // Feature flags
    DD_TRACE_ENABLED: 'true',
    DD_LOGS_INJECTION: 'true',
    DD_SERVERLESS_LOGS_ENABLED: 'true',
    DD_CAPTURE_LAMBDA_PAYLOAD: 'false',  // Set true to capture request/response (increases costs)

    // Your application environment variables
    DD_LAMBDA_HANDLER: 'index.handler'  // Original handler
  }
});

// Grant permission to read API key from Secrets Manager
datadogApiKey.grantRead(myFunction);
```

## Runtime-Specific Configuration

### Python 3.11

```typescript
const pythonFunction = new lambda.Function(this, 'PythonFunction', {
  runtime: lambda.Runtime.PYTHON_3_11,
  handler: 'datadog_lambda.handler.handler',
  code: lambda.Code.fromAsset('lambda'),
  environment: {
    DD_LAMBDA_HANDLER: 'app.handler',  // Your actual handler
    DD_TRACE_ENABLED: 'true',
    DD_LOGS_INJECTION: 'true'
  }
});
```

Python code with manual instrumentation:

```python
from datadog_lambda.wrapper import datadog_lambda_wrapper
from datadog_lambda.metric import lambda_metric
from ddtrace import tracer

@datadog_lambda_wrapper
def handler(event, context):
    # Custom metric
    lambda_metric(
        'survivor.atlas.api.requests',
        1,
        tags=['endpoint:generate_url']
    )

    # Custom span
    with tracer.trace('custom.operation'):
        result = do_work()

    return result
```

### Node.js 18.x

```typescript
const nodeFunction = new lambda.Function(this, 'NodeFunction', {
  runtime: lambda.Runtime.NODEJS_18_X,
  handler: '/opt/nodejs/node_modules/datadog-lambda-js/handler.handler',
  code: lambda.Code.fromAsset('lambda'),
  environment: {
    DD_LAMBDA_HANDLER: 'index.handler',  // Your actual handler
    DD_TRACE_ENABLED: 'true',
    DD_LOGS_INJECTION: 'true'
  }
});
```

Node.js code:

```javascript
const { datadog } = require('datadog-lambda-js');
const { sendDistributionMetric } = require('datadog-lambda-js');
const tracer = require('dd-trace');

exports.handler = datadog(async (event, context) => {
  // Custom metric
  sendDistributionMetric(
    'survivor.atlas.api.latency',
    123.45,
    'endpoint:generate_url'
  );

  // Custom span
  const span = tracer.startSpan('custom.operation');
  const result = await doWork();
  span.finish();

  return result;
});
```

## Distributed Tracing

### Tracing Across Lambda Functions

When one Lambda calls another, propagate trace context:

**Invoking Lambda**:

```python
import boto3
import json
from ddtrace import tracer

lambda_client = boto3.client('lambda')

# Get current trace context
trace_context = tracer.current_trace_context()

# Add trace headers to payload
response = lambda_client.invoke(
    FunctionName='downstream-function',
    InvocationType='Event',
    Payload=json.dumps({
        'data': event,
        '_datadog': {
            'x-datadog-trace-id': str(trace_context.trace_id),
            'x-datadog-parent-id': str(trace_context.span_id)
        }
    })
)
```

**Receiving Lambda**:

```python
from ddtrace import tracer

def handler(event, context):
    # Extract trace context
    if '_datadog' in event:
        dd_context = event['_datadog']
        # DataDog SDK will automatically continue the trace

    # Your business logic
    return {'status': 'success'}
```

### Tracing API Gateway -> Lambda

DataDog automatically traces API Gateway to Lambda if both are instrumented:

- API Gateway access logs with trace ID
- Lambda function with DataDog layer
- Trace correlation happens automatically

### Tracing EventBridge -> Lambda

Enable EventBridge tracing:

```typescript
const rule = new events.Rule(this, 'MyRule', {
  eventPattern: {
    source: ['custom.app']
  },
  targets: [new targets.LambdaFunction(myFunction, {
    // EventBridge will propagate trace context
    retryAttempts: 2
  })]
});
```

## Custom Metrics

### Distribution Metrics (Recommended)

Use distributions for percentile calculations:

```python
from datadog_lambda.metric import lambda_metric

lambda_metric(
    'survivor.atlas.file.size',
    file_size_bytes,
    tags=['partner:espn', 'file_type:json']
)
```

### Gauges and Counters

```python
# Gauge (latest value)
lambda_metric('survivor.atlas.active.connections', 42)

# Counter (increment)
lambda_metric('survivor.atlas.errors', 1, tags=['error_type:timeout'])
```

## Logging Best Practices

### Structured Logging

```python
import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    # Structured log - will be parsed by DataDog
    logger.info(json.dumps({
        'message': 'Processing request',
        'partner': 'espn',
        'file_count': 5,
        'status': 'success'
    }))
```

### Log Correlation

DataDog automatically injects trace IDs into logs when `DD_LOGS_INJECTION=true`.

### Log Sampling

For high-volume functions, sample logs to reduce costs:

```python
import random

def handler(event, context):
    # Only log 10% of requests
    if random.random() < 0.1:
        logger.info('Sampled log entry')
```

## Performance Optimization

### Cold Start Impact

DataDog layers add ~20-50ms to cold start time:

- Python: ~30ms
- Node.js: ~20ms
- Extension: ~10-15ms

**Mitigation**:

- Use provisioned concurrency for latency-sensitive functions
- Consider manual instrumentation for ultra-low-latency requirements
- Monitor cold start percentage in DataDog

### Memory Overhead

- Lambda library layer: ~10-20MB
- Extension: ~15-25MB
- Total overhead: ~30-45MB

**Recommendations**:

- Add 64-128MB to function memory allocation
- Monitor memory usage in DataDog Lambda metrics

## Cost Optimization

### APM Trace Sampling

Don't trace every invocation for high-volume functions:

```typescript
environment: {
  DD_TRACE_SAMPLE_RATE: '0.1'  // Sample 10% of traces
}
```

### Log Exclusion

Exclude verbose or unnecessary logs:

```typescript
environment: {
  DD_LOGS_ENABLED: 'true',
  DD_LOGS_INJECTION: 'true',
  // Exclude debug logs from being sent to DataDog
  LOG_LEVEL: 'INFO'
}
```

In DataDog UI, create exclusion filters:

- Exclude logs matching `status:info` for non-critical functions
- Exclude high-frequency DEBUG logs
- Retain ERROR and WARN logs

### Payload Capture

Disable request/response payload capture unless debugging:

```typescript
environment: {
  DD_CAPTURE_LAMBDA_PAYLOAD: 'false'  // Default, reduces costs
}
```

## Troubleshooting

### Missing Metrics or Traces

1. Check CloudWatch logs for DataDog extension errors
2. Verify API key has correct permissions
3. Confirm layer versions are compatible with runtime
4. Check function timeout (should be > 3 seconds for extension flush)

### High Costs

1. Review trace sampling rate (should be < 1.0 for high-volume functions)
2. Check log exclusion filters in DataDog
3. Disable payload capture if enabled
4. Consider disabling DataDog for dev/test environments

### Trace Gaps

1. Ensure all functions in call chain have DataDog layers
2. Verify trace context propagation in custom code
3. Check for async invocations (use Step Functions for complex workflows)

## Security Considerations

### API Key Management

- NEVER hardcode API keys
- Store in AWS Secrets Manager
- Grant least-privilege IAM permissions: `secretsmanager:GetSecretValue`
- Rotate API keys regularly

### Log Scrubbing

Remove sensitive data from logs:

```python
import re

def scrub_pii(message):
    # Scrub emails
    message = re.sub(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b', '[EMAIL]', message)
    # Scrub SSNs
    message = re.sub(r'\b\d{3}-\d{2}-\d{4}\b', '[SSN]', message)
    return message

logger.info(scrub_pii(user_input))
```

## Resources

- [DataDog Lambda Layer Versions (Python)](https://github.com/DataDog/datadog-lambda-python/releases)
- [DataDog Lambda Layer Versions (Node.js)](https://github.com/DataDog/datadog-lambda-js/releases)
- [DataDog Extension Releases](https://github.com/DataDog/datadog-lambda-extension/releases)
- [DataDog CDK Constructs Documentation](https://github.com/DataDog/datadog-cdk-constructs)

---

**Last Updated**: 2025-10-09
**Category**: AWS Integrations
**Related**: ecs-fargate-monitoring.md, api-gateway-monitoring.md, distributed-tracing.md

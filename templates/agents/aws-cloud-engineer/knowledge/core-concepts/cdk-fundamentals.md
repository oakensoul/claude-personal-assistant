---
title: AWS CDK Fundamentals
category: core-concepts
tags: [cdk, constructs, stacks, infrastructure-as-code]
last_updated: 2025-10-09
---

# AWS CDK Fundamentals

## Overview

AWS Cloud Development Kit (CDK) is an infrastructure-as-code framework that lets you define cloud infrastructure using familiar programming languages (TypeScript, Python, Java, C#, Go).

## Key Concepts

### Constructs

Constructs are the basic building blocks of CDK apps. They represent cloud resources and can encapsulate multiple resources as reusable components.

#### L1 Constructs (CFN Resources)

**What**: Direct 1:1 mapping to CloudFormation resources

**When to use**:
- L2/L3 constructs don't exist for the resource
- Need precise control over CloudFormation properties
- Working with new AWS features not yet in L2

**Example**:
```typescript
import { CfnBucket } from 'aws-cdk-lib/aws-s3';

new CfnBucket(this, 'MyBucket', {
  bucketName: 'my-bucket',
  versioningConfiguration: {
    status: 'Enabled',
  },
});
```

**Characteristics**:
- Prefixed with `Cfn` (e.g., `CfnBucket`)
- Properties match CloudFormation exactly
- No helper methods or defaults
- Requires more code

#### L2 Constructs (Intent-based)

**What**: AWS-curated constructs with sensible defaults and helper methods

**When to use**:
- Most common use case (80-90% of resources)
- Want sensible defaults and less boilerplate
- Benefit from helper methods and typed properties

**Example**:
```typescript
import { Bucket, BucketEncryption } from 'aws-cdk-lib/aws-s3';

new Bucket(this, 'MyBucket', {
  versioned: true,
  encryption: BucketEncryption.S3_MANAGED,
  removalPolicy: RemovalPolicy.RETAIN,
});
```

**Characteristics**:
- Sensible defaults (encryption, logging, etc.)
- Helper methods (`.addLifecycleRule()`, `.grantRead()`)
- Type-safe configuration
- Less verbose than L1

#### L3 Constructs (Patterns)

**What**: High-level patterns combining multiple resources into common architectures

**When to use**:
- Implementing well-known architectural patterns
- Want opinionated best practices
- Rapid prototyping

**Example**:
```typescript
import { ApplicationLoadBalancedFargateService } from 'aws-cdk-lib/aws-ecs-patterns';

new ApplicationLoadBalancedFargateService(this, 'Service', {
  cluster: cluster,
  taskImageOptions: {
    image: ContainerImage.fromRegistry('amazon/amazon-ecs-sample'),
  },
});
```

**Characteristics**:
- Combines multiple L2 constructs
- Opinionated best practices
- Less configuration flexibility
- Fastest to implement

### Stacks

Stacks are the unit of deployment in CDK. Each stack produces a CloudFormation template.

**Basic Stack**:
```typescript
import { Stack, StackProps } from 'aws-cdk-lib';
import { Construct } from 'constructs';

export class MyStack extends Stack {
  constructor(scope: Construct, id: string, props?: StackProps) {
    super(scope, id, props);

    // Define resources here
  }
}
```

**Stack Best Practices**:

1. **Organize by lifecycle**: Group resources that change together
2. **Separate environments**: Different stacks for dev/staging/prod
3. **Cross-stack references**: Use exports/imports for shared resources
4. **Explicit dependencies**: Use `addDependency()` when needed

### Apps

The app is the root construct containing all stacks.

**Basic App**:
```typescript
import { App } from 'aws-cdk-lib';
import { MyStack } from './my-stack';

const app = new App();

new MyStack(app, 'DevStack', {
  env: {
    account: '123456789012',
    region: 'us-east-1',
  },
});

new MyStack(app, 'ProdStack', {
  env: {
    account: '987654321098',
    region: 'us-east-1',
  },
});
```

## Stack Organization Patterns

### Single Stack

**When**: Simple application with few resources

```typescript
class AllInOneStack extends Stack {
  constructor(scope: Construct, id: string) {
    super(scope, id);

    const vpc = new Vpc(this, 'VPC');
    const cluster = new Cluster(this, 'Cluster', { vpc });
    const service = new FargateService(this, 'Service', { cluster });
  }
}
```

**Pros**: Simple, fewer cross-stack references
**Cons**: Long deployment times, hard to manage large apps

### Multi-Stack by Layer

**When**: Separate infrastructure layers with different update frequencies

```typescript
// Network stack (changes rarely)
class NetworkStack extends Stack {
  public readonly vpc: Vpc;

  constructor(scope: Construct, id: string) {
    super(scope, id);
    this.vpc = new Vpc(this, 'VPC');
  }
}

// Application stack (changes frequently)
class ApplicationStack extends Stack {
  constructor(scope: Construct, id: string, props: { vpc: Vpc }) {
    super(scope, id);

    const cluster = new Cluster(this, 'Cluster', { vpc: props.vpc });
    const service = new FargateService(this, 'Service', { cluster });
  }
}

// App
const network = new NetworkStack(app, 'Network');
const application = new ApplicationStack(app, 'Application', {
  vpc: network.vpc,
});
```

**Pros**: Independent deployments, faster updates
**Cons**: More complex, cross-stack dependencies

### Multi-Stack by Environment

**When**: Separate environments (dev/staging/prod)

```typescript
interface StackConfig {
  environment: string;
  account: string;
  region: string;
  instanceType: InstanceType;
}

const configs: Record<string, StackConfig> = {
  dev: {
    environment: 'dev',
    account: '123456789012',
    region: 'us-east-1',
    instanceType: InstanceType.of(InstanceClass.T3, InstanceSize.SMALL),
  },
  prod: {
    environment: 'prod',
    account: '987654321098',
    region: 'us-east-1',
    instanceType: InstanceType.of(InstanceClass.M5, InstanceSize.LARGE),
  },
};

Object.entries(configs).forEach(([name, config]) => {
  new ApplicationStack(app, `${name}-Stack`, config);
});
```

**Pros**: Environment isolation, same code for all environments
**Cons**: Requires multi-account setup

## Cross-Stack References

### Using Exports

**Exporting from one stack**:
```typescript
class NetworkStack extends Stack {
  public readonly vpc: Vpc;

  constructor(scope: Construct, id: string) {
    super(scope, id);

    this.vpc = new Vpc(this, 'VPC');

    // Export VPC ID
    new CfnOutput(this, 'VpcId', {
      value: this.vpc.vpcId,
      exportName: 'NetworkVpcId',
    });
  }
}
```

**Importing in another stack**:
```typescript
class ApplicationStack extends Stack {
  constructor(scope: Construct, id: string) {
    super(scope, id);

    // Import VPC by ID
    const vpcId = Fn.importValue('NetworkVpcId');
    const vpc = Vpc.fromLookup(this, 'VPC', { vpcId });
  }
}
```

### Using Direct References (Preferred)

**Preferred method** (type-safe, automatic dependencies):

```typescript
const network = new NetworkStack(app, 'Network');
const application = new ApplicationStack(app, 'Application', {
  vpc: network.vpc, // Direct reference
});
```

CDK automatically:
- Creates CloudFormation exports/imports
- Sets up stack dependencies
- Ensures correct deployment order

## Configuration Management

### Environment Variables

```typescript
const dbPassword = process.env.DB_PASSWORD;
if (!dbPassword) {
  throw new Error('DB_PASSWORD environment variable required');
}

new Secret(this, 'DbPassword', {
  secretStringValue: SecretValue.unsafePlainText(dbPassword),
});
```

### Context Values

**cdk.json**:
```json
{
  "context": {
    "environment": "production",
    "features": {
      "enableCaching": true
    }
  }
}
```

**Accessing in code**:
```typescript
const environment = this.node.tryGetContext('environment');
const enableCaching = this.node.tryGetContext('features')?.enableCaching;
```

### Configuration Classes

```typescript
interface AppConfig {
  environment: 'dev' | 'staging' | 'prod';
  vpc: {
    cidr: string;
    maxAzs: number;
  };
  database: {
    instanceType: InstanceType;
    multiAz: boolean;
  };
}

const configs: Record<string, AppConfig> = {
  dev: {
    environment: 'dev',
    vpc: { cidr: '10.0.0.0/16', maxAzs: 2 },
    database: {
      instanceType: InstanceType.of(InstanceClass.T3, InstanceSize.SMALL),
      multiAz: false,
    },
  },
  prod: {
    environment: 'prod',
    vpc: { cidr: '10.1.0.0/16', maxAzs: 3 },
    database: {
      instanceType: InstanceType.of(InstanceClass.M5, InstanceSize.LARGE),
      multiAz: true,
    },
  },
};
```

## CDK CLI Commands

### Synthesize

Generate CloudFormation template without deploying:

```bash
cdk synth                    # Synth all stacks
cdk synth MyStack            # Synth specific stack
cdk synth --json             # Output as JSON
```

### Deploy

Deploy stacks to AWS:

```bash
cdk deploy                   # Deploy all stacks
cdk deploy MyStack           # Deploy specific stack
cdk deploy --all             # Deploy all explicitly
cdk deploy --require-approval never  # No approval prompts
cdk deploy --profile prod    # Use specific AWS profile
```

### Diff

Compare deployed stack with local changes:

```bash
cdk diff                     # Diff all stacks
cdk diff MyStack             # Diff specific stack
```

### Destroy

Delete stacks from AWS:

```bash
cdk destroy                  # Destroy all stacks
cdk destroy MyStack          # Destroy specific stack
cdk destroy --force          # No confirmation prompts
```

### Bootstrap

Prepare AWS account for CDK deployments:

```bash
cdk bootstrap                # Bootstrap default account/region
cdk bootstrap aws://123456789012/us-east-1  # Specific account/region
cdk bootstrap --profile prod # Use specific profile
```

## Best Practices

### Use L2 Constructs by Default

**Good**:
```typescript
new Bucket(this, 'MyBucket', {
  versioned: true,
  encryption: BucketEncryption.S3_MANAGED,
});
```

**Avoid** (unless necessary):
```typescript
new CfnBucket(this, 'MyBucket', {
  versioningConfiguration: { status: 'Enabled' },
  bucketEncryption: { /* ... */ },
});
```

### Use Constants for Resource Names

**Good**:
```typescript
const BUCKET_NAME = 'my-app-data-bucket';

new Bucket(this, 'DataBucket', {
  bucketName: BUCKET_NAME,
});

new BucketPolicy(this, 'DataBucketPolicy', {
  bucket: Bucket.fromBucketName(this, 'Bucket', BUCKET_NAME),
});
```

**Avoid** (magic strings):
```typescript
new Bucket(this, 'DataBucket', {
  bucketName: 'my-app-data-bucket',
});

new BucketPolicy(this, 'DataBucketPolicy', {
  bucket: Bucket.fromBucketName(this, 'Bucket', 'my-app-data-bucket'),
});
```

### Use Removal Policies Explicitly

```typescript
new Bucket(this, 'DataBucket', {
  removalPolicy: RemovalPolicy.RETAIN, // Explicit: keep bucket on stack delete
});

new Bucket(this, 'TempBucket', {
  removalPolicy: RemovalPolicy.DESTROY, // Explicit: delete bucket on stack delete
  autoDeleteObjects: true,              // Also delete objects
});
```

### Use Stack Dependencies

**Explicit dependencies**:
```typescript
const network = new NetworkStack(app, 'Network');
const database = new DatabaseStack(app, 'Database', { vpc: network.vpc });
const application = new ApplicationStack(app, 'Application', {
  vpc: network.vpc,
  database: database.cluster,
});

// Explicit dependency (if needed)
application.addDependency(database);
```

### Tag All Resources

```typescript
import { Tags } from 'aws-cdk-lib';

const stack = new MyStack(app, 'MyStack');

Tags.of(stack).add('Project', 'my-project');
Tags.of(stack).add('Environment', 'production');
Tags.of(stack).add('ManagedBy', 'cdk');
Tags.of(stack).add('CostCenter', 'engineering');
```

## Common Patterns

### VPC with Public and Private Subnets

```typescript
const vpc = new Vpc(this, 'VPC', {
  maxAzs: 2,
  natGateways: 1,
  subnetConfiguration: [
    {
      cidrMask: 24,
      name: 'Public',
      subnetType: SubnetType.PUBLIC,
    },
    {
      cidrMask: 24,
      name: 'Private',
      subnetType: SubnetType.PRIVATE_WITH_EGRESS,
    },
  ],
});
```

### Lambda Function with API Gateway

```typescript
const handler = new Function(this, 'Handler', {
  runtime: Runtime.NODEJS_18_X,
  code: Code.fromAsset('lambda'),
  handler: 'index.handler',
});

const api = new RestApi(this, 'Api');
const integration = new LambdaIntegration(handler);
api.root.addMethod('GET', integration);
```

### RDS Database with Secret

```typescript
const dbSecret = new Secret(this, 'DbSecret', {
  generateSecretString: {
    secretStringTemplate: JSON.stringify({ username: 'admin' }),
    generateStringKey: 'password',
    excludePunctuation: true,
  },
});

const database = new DatabaseInstance(this, 'Database', {
  engine: DatabaseInstanceEngine.postgres({
    version: PostgresEngineVersion.VER_15,
  }),
  vpc,
  credentials: Credentials.fromSecret(dbSecret),
  multiAz: true,
  storageEncrypted: true,
});
```

### S3 Bucket with Lifecycle Rules

```typescript
const bucket = new Bucket(this, 'DataBucket', {
  versioned: true,
  lifecycleRules: [
    {
      // Move to Infrequent Access after 30 days
      transitions: [
        {
          storageClass: StorageClass.INFREQUENT_ACCESS,
          transitionAfter: Duration.days(30),
        },
      ],
    },
    {
      // Move to Glacier after 90 days
      transitions: [
        {
          storageClass: StorageClass.GLACIER,
          transitionAfter: Duration.days(90),
        },
      ],
    },
    {
      // Delete after 365 days
      expiration: Duration.days(365),
    },
  ],
});
```

## Testing CDK Code

### Snapshot Tests

```typescript
import { Template } from 'aws-cdk-lib/assertions';
import { MyStack } from '../lib/my-stack';

test('Stack creates expected resources', () => {
  const stack = new MyStack(app, 'TestStack');
  const template = Template.fromStack(stack);

  expect(template.toJSON()).toMatchSnapshot();
});
```

### Fine-Grained Assertions

```typescript
test('Stack creates S3 bucket with versioning', () => {
  const stack = new MyStack(app, 'TestStack');
  const template = Template.fromStack(stack);

  template.hasResourceProperties('AWS::S3::Bucket', {
    VersioningConfiguration: {
      Status: 'Enabled',
    },
  });
});
```

### Resource Count Tests

```typescript
test('Stack creates exactly one VPC', () => {
  const stack = new MyStack(app, 'TestStack');
  const template = Template.fromStack(stack);

  template.resourceCountIs('AWS::EC2::VPC', 1);
});
```

## Related Knowledge

- **patterns/multi-stack-architectures.md** - Advanced stack organization
- **patterns/custom-constructs.md** - Creating reusable constructs
- **patterns/configuration-management.md** - Managing environment configs
- **patterns/testing-strategies.md** - Comprehensive testing approaches

---

**Category**: Core Concepts
**Last Updated**: 2025-10-09
**Status**: Complete

---
title: Multi-Stack Architecture Patterns
category: patterns
tags: [cdk, stacks, architecture, organization]
last_updated: 2025-10-09
---

# Multi-Stack Architecture Patterns

## Overview

Organizing CDK applications into multiple stacks provides better separation of concerns, faster deployments, and independent lifecycle management. This guide covers common multi-stack patterns and when to use them.

## Why Multiple Stacks?

### Benefits

1. **Independent Deployments**: Deploy infrastructure layers independently
2. **Faster Updates**: Update application code without redeploying network infrastructure
3. **Separation of Concerns**: Organize by lifecycle, team ownership, or environment
4. **Cross-Stack Sharing**: Share resources like VPCs across multiple applications
5. **Reduced Blast Radius**: Limit impact of failed deployments

### Trade-offs

1. **Complexity**: More stacks = more to manage
2. **Cross-Stack Dependencies**: Requires careful dependency management
3. **Deployment Ordering**: Must deploy in correct order
4. **CloudFormation Limits**: Stack limits (200 resources, 60 outputs per stack)

## Pattern 1: Layer-Based Stacks

**Organize by infrastructure layer and update frequency**

### Structure

```
NetworkStack (changes rarely)
  └── VPC, Subnets, NAT Gateways, VPC Endpoints

DataStack (changes occasionally)
  └── RDS, DynamoDB, S3 buckets, Secrets

ApplicationStack (changes frequently)
  └── ECS Services, Lambda Functions, API Gateway

MonitoringStack (changes occasionally)
  └── CloudWatch Dashboards, Alarms, SNS Topics
```

### Implementation

```typescript
// network-stack.ts
export class NetworkStack extends Stack {
  public readonly vpc: Vpc;
  public readonly privateSubnets: ISubnet[];

  constructor(scope: Construct, id: string, props?: StackProps) {
    super(scope, id, props);

    // VPC with public and private subnets
    this.vpc = new Vpc(this, 'VPC', {
      maxAzs: 3,
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

    this.privateSubnets = this.vpc.privateSubnets;

    // Export VPC ID for reference
    new CfnOutput(this, 'VpcId', {
      value: this.vpc.vpcId,
      exportName: `${this.stackName}-VpcId`,
    });
  }
}

// data-stack.ts
export interface DataStackProps extends StackProps {
  vpc: Vpc;
}

export class DataStack extends Stack {
  public readonly database: DatabaseCluster;
  public readonly bucket: Bucket;

  constructor(scope: Construct, id: string, props: DataStackProps) {
    super(scope, id, props);

    // Aurora Serverless cluster
    this.database = new DatabaseCluster(this, 'Database', {
      engine: DatabaseClusterEngine.auroraPostgres({
        version: AuroraPostgresEngineVersion.VER_15_2,
      }),
      writer: ClusterInstance.serverlessV2('Writer'),
      vpc: props.vpc,
      vpcSubnets: { subnetType: SubnetType.PRIVATE_WITH_EGRESS },
      serverlessV2MinCapacity: 0.5,
      serverlessV2MaxCapacity: 2,
    });

    // S3 bucket for data storage
    this.bucket = new Bucket(this, 'DataBucket', {
      versioned: true,
      encryption: BucketEncryption.S3_MANAGED,
      removalPolicy: RemovalPolicy.RETAIN,
    });

    // Export database endpoint
    new CfnOutput(this, 'DatabaseEndpoint', {
      value: this.database.clusterEndpoint.socketAddress,
      exportName: `${this.stackName}-DatabaseEndpoint`,
    });
  }
}

// application-stack.ts
export interface ApplicationStackProps extends StackProps {
  vpc: Vpc;
  database: DatabaseCluster;
  bucket: Bucket;
}

export class ApplicationStack extends Stack {
  constructor(scope: Construct, id: string, props: ApplicationStackProps) {
    super(scope, id, props);

    // ECS Cluster
    const cluster = new Cluster(this, 'Cluster', {
      vpc: props.vpc,
    });

    // Fargate Service
    const service = new ApplicationLoadBalancedFargateService(this, 'Service', {
      cluster,
      taskImageOptions: {
        image: ContainerImage.fromAsset('./app'),
        environment: {
          DATABASE_HOST: props.database.clusterEndpoint.hostname,
          BUCKET_NAME: props.bucket.bucketName,
        },
      },
    });

    // Grant permissions
    props.database.connections.allowDefaultPortFrom(service.service);
    props.bucket.grantReadWrite(service.taskDefinition.taskRole);
  }
}

// app.ts
const app = new App();

const network = new NetworkStack(app, 'NetworkStack', {
  env: { account: '123456789012', region: 'us-east-1' },
});

const data = new DataStack(app, 'DataStack', {
  vpc: network.vpc,
  env: { account: '123456789012', region: 'us-east-1' },
});

const application = new ApplicationStack(app, 'ApplicationStack', {
  vpc: network.vpc,
  database: data.database,
  bucket: data.bucket,
  env: { account: '123456789012', region: 'us-east-1' },
});

// Explicit dependencies
data.addDependency(network);
application.addDependency(data);
```

### When to Use

- Large applications with distinct infrastructure layers
- Resources with different update frequencies
- Team ownership boundaries align with layers
- Need to update application code without touching infrastructure

### Deployment

```bash
# Initial deployment (in order)
cdk deploy NetworkStack
cdk deploy DataStack
cdk deploy ApplicationStack

# Update application only
cdk deploy ApplicationStack

# Update all stacks
cdk deploy --all
```

## Pattern 2: Environment-Based Stacks

**Separate stacks per environment (dev, staging, prod)**

### Structure

```
DevNetworkStack, DevDataStack, DevApplicationStack
StagingNetworkStack, StagingDataStack, StagingApplicationStack
ProdNetworkStack, ProdDataStack, ProdApplicationStack
```

### Implementation

```typescript
// config.ts
export interface EnvironmentConfig {
  name: string;
  account: string;
  region: string;
  vpc: {
    cidr: string;
    maxAzs: number;
    natGateways: number;
  };
  database: {
    serverlessV2MinCapacity: number;
    serverlessV2MaxCapacity: number;
    multiAz: boolean;
  };
  application: {
    desiredCount: number;
    cpu: number;
    memory: number;
  };
}

export const environments: Record<string, EnvironmentConfig> = {
  dev: {
    name: 'dev',
    account: '123456789012',
    region: 'us-east-1',
    vpc: {
      cidr: '10.0.0.0/16',
      maxAzs: 2,
      natGateways: 1,
    },
    database: {
      serverlessV2MinCapacity: 0.5,
      serverlessV2MaxCapacity: 1,
      multiAz: false,
    },
    application: {
      desiredCount: 1,
      cpu: 256,
      memory: 512,
    },
  },
  staging: {
    name: 'staging',
    account: '234567890123',
    region: 'us-east-1',
    vpc: {
      cidr: '10.1.0.0/16',
      maxAzs: 2,
      natGateways: 1,
    },
    database: {
      serverlessV2MinCapacity: 0.5,
      serverlessV2MaxCapacity: 2,
      multiAz: true,
    },
    application: {
      desiredCount: 2,
      cpu: 512,
      memory: 1024,
    },
  },
  prod: {
    name: 'prod',
    account: '345678901234',
    region: 'us-east-1',
    vpc: {
      cidr: '10.2.0.0/16',
      maxAzs: 3,
      natGateways: 3,
    },
    database: {
      serverlessV2MinCapacity: 1,
      serverlessV2MaxCapacity: 4,
      multiAz: true,
    },
    application: {
      desiredCount: 4,
      cpu: 1024,
      memory: 2048,
    },
  },
};

// app.ts
const app = new App();

Object.entries(environments).forEach(([envName, config]) => {
  const network = new NetworkStack(app, `${envName}-Network`, {
    config: config.vpc,
    env: { account: config.account, region: config.region },
  });

  const data = new DataStack(app, `${envName}-Data`, {
    vpc: network.vpc,
    config: config.database,
    env: { account: config.account, region: config.region },
  });

  const application = new ApplicationStack(app, `${envName}-Application`, {
    vpc: network.vpc,
    database: data.database,
    config: config.application,
    env: { account: config.account, region: config.region },
  });

  data.addDependency(network);
  application.addDependency(data);
});
```

### When to Use

- Multi-environment deployments (dev/staging/prod)
- Different AWS accounts per environment
- Environment-specific configurations (instance sizes, capacity)
- Want to deploy same infrastructure to multiple environments

### Deployment

```bash
# Deploy dev environment
cdk deploy dev-Network dev-Data dev-Application

# Deploy staging environment
cdk deploy staging-Network staging-Data staging-Application

# Deploy to prod
cdk deploy prod-Network prod-Data prod-Application

# Deploy specific environment
cdk deploy --all --context environment=prod
```

## Pattern 3: Service-Based Stacks

**Organize by microservice or application component**

### Structure

```
SharedStack (VPC, ALB, ECS Cluster)
  ├── UserServiceStack (User microservice)
  ├── OrderServiceStack (Order microservice)
  ├── PaymentServiceStack (Payment microservice)
  └── NotificationServiceStack (Notification microservice)
```

### Implementation

```typescript
// shared-stack.ts
export class SharedStack extends Stack {
  public readonly vpc: Vpc;
  public readonly cluster: Cluster;
  public readonly loadBalancer: ApplicationLoadBalancer;

  constructor(scope: Construct, id: string, props?: StackProps) {
    super(scope, id, props);

    this.vpc = new Vpc(this, 'VPC', { maxAzs: 2 });
    this.cluster = new Cluster(this, 'Cluster', { vpc: this.vpc });

    this.loadBalancer = new ApplicationLoadBalancer(this, 'ALB', {
      vpc: this.vpc,
      internetFacing: true,
    });
  }
}

// service-stack.ts
export interface ServiceStackProps extends StackProps {
  vpc: Vpc;
  cluster: Cluster;
  loadBalancer: ApplicationLoadBalancer;
  serviceName: string;
  containerPort: number;
  pathPattern: string;
  priority: number;
}

export class ServiceStack extends Stack {
  constructor(scope: Construct, id: string, props: ServiceStackProps) {
    super(scope, id, props);

    // DynamoDB table for service
    const table = new Table(this, 'Table', {
      partitionKey: { name: 'id', type: AttributeType.STRING },
      billingMode: BillingMode.PAY_PER_REQUEST,
    });

    // Fargate task definition
    const taskDefinition = new FargateTaskDefinition(this, 'TaskDef');
    const container = taskDefinition.addContainer('Container', {
      image: ContainerImage.fromAsset(`./services/${props.serviceName}`),
      environment: {
        TABLE_NAME: table.tableName,
      },
      logging: LogDriver.awsLogs({ streamPrefix: props.serviceName }),
    });
    container.addPortMappings({ containerPort: props.containerPort });

    // Fargate service
    const service = new FargateService(this, 'Service', {
      cluster: props.cluster,
      taskDefinition,
      desiredCount: 2,
    });

    // Grant DynamoDB access
    table.grantReadWriteData(taskDefinition.taskRole);

    // Add to load balancer
    const listener = props.loadBalancer.addListener('Listener', {
      port: 80,
    });

    listener.addTargets('Targets', {
      port: props.containerPort,
      targets: [service],
      healthCheck: {
        path: '/health',
        interval: Duration.seconds(30),
      },
      priority: props.priority,
      conditions: [ListenerCondition.pathPatterns([props.pathPattern])],
    });
  }
}

// app.ts
const app = new App();

const shared = new SharedStack(app, 'Shared');

const userService = new ServiceStack(app, 'UserService', {
  vpc: shared.vpc,
  cluster: shared.cluster,
  loadBalancer: shared.loadBalancer,
  serviceName: 'user-service',
  containerPort: 3000,
  pathPattern: '/users/*',
  priority: 10,
});

const orderService = new ServiceStack(app, 'OrderService', {
  vpc: shared.vpc,
  cluster: shared.cluster,
  loadBalancer: shared.loadBalancer,
  serviceName: 'order-service',
  containerPort: 3000,
  pathPattern: '/orders/*',
  priority: 20,
});

userService.addDependency(shared);
orderService.addDependency(shared);
```

### When to Use

- Microservices architecture
- Independent team ownership per service
- Different deployment schedules per service
- Services share common infrastructure (VPC, load balancer)

### Deployment

```bash
# Deploy shared infrastructure first
cdk deploy Shared

# Deploy individual services
cdk deploy UserService
cdk deploy OrderService

# Deploy all services
cdk deploy --all --exclude Shared
```

## Pattern 4: Regional Multi-Stack

**Deploy same infrastructure to multiple regions**

### Structure

```
US-East-1:
  - NetworkStack-us-east-1
  - ApplicationStack-us-east-1

EU-West-1:
  - NetworkStack-eu-west-1
  - ApplicationStack-eu-west-1
```

### Implementation

```typescript
// config.ts
export interface RegionConfig {
  region: string;
  account: string;
  isPrimary: boolean;
}

export const regions: RegionConfig[] = [
  { region: 'us-east-1', account: '123456789012', isPrimary: true },
  { region: 'eu-west-1', account: '123456789012', isPrimary: false },
  { region: 'ap-southeast-1', account: '123456789012', isPrimary: false },
];

// app.ts
const app = new App();

regions.forEach(regionConfig => {
  const network = new NetworkStack(app, `Network-${regionConfig.region}`, {
    env: {
      account: regionConfig.account,
      region: regionConfig.region,
    },
  });

  const application = new ApplicationStack(
    app,
    `Application-${regionConfig.region}`,
    {
      vpc: network.vpc,
      isPrimary: regionConfig.isPrimary,
      env: {
        account: regionConfig.account,
        region: regionConfig.region,
      },
    }
  );

  application.addDependency(network);
});
```

### When to Use

- Global application requiring low latency in multiple regions
- Disaster recovery / high availability across regions
- Compliance requirements for data residency

### Deployment

```bash
# Deploy to all regions
cdk deploy --all

# Deploy to specific region
cdk deploy Network-us-east-1 Application-us-east-1
```

## Cross-Stack Reference Patterns

### Pattern A: Direct Property Reference (Preferred)

**Type-safe, automatic dependency management**

```typescript
const network = new NetworkStack(app, 'Network');
const application = new ApplicationStack(app, 'Application', {
  vpc: network.vpc, // Direct reference
});
```

CDK handles:

- CloudFormation exports/imports
- Stack dependencies
- Deployment order

### Pattern B: CloudFormation Exports

**When stacks deployed separately or by different teams**

```typescript
// Exporting stack
new CfnOutput(this, 'VpcId', {
  value: this.vpc.vpcId,
  exportName: 'SharedVpcId',
});

// Importing stack
const vpcId = Fn.importValue('SharedVpcId');
const vpc = Vpc.fromLookup(this, 'VPC', { vpcId });
```

**Warning**: Cannot delete exporting stack while importing stack exists

### Pattern C: SSM Parameter Store

**For loose coupling between stacks**

```typescript
// Exporting stack
new StringParameter(this, 'VpcIdParameter', {
  parameterName: '/network/vpc-id',
  stringValue: this.vpc.vpcId,
});

// Importing stack
const vpcId = StringParameter.valueForStringParameter(
  this,
  '/network/vpc-id'
);
const vpc = Vpc.fromLookup(this, 'VPC', { vpcId });
```

**Benefits**:

- Can delete exporting stack
- No CloudFormation export limits
- Can update values independently

## Best Practices

### 1. Limit Stack Size

Keep stacks under CloudFormation limits:

- Max 200 resources per stack
- Max 60 outputs per stack
- Max 100 parameters per stack

### 2. Organize by Lifecycle

Group resources that change together into same stack.

### 3. Use Explicit Dependencies

```typescript
application.addDependency(network);
application.addDependency(database);
```

### 4. Name Stacks Consistently

```
{Project}-{Environment}-{Layer}

Examples:
- MyApp-Prod-Network
- MyApp-Prod-Data
- MyApp-Prod-Application
```

### 5. Tag All Stacks

```typescript
Tags.of(stack).add('Project', 'my-app');
Tags.of(stack).add('Environment', 'production');
Tags.of(stack).add('ManagedBy', 'cdk');
```

### 6. Use Stack Props Interfaces

```typescript
export interface DataStackProps extends StackProps {
  vpc: Vpc;
  environment: string;
}
```

### 7. Export Outputs Strategically

Only export what other stacks need:

```typescript
// Good: Export essentials
new CfnOutput(this, 'VpcId', {
  value: this.vpc.vpcId,
  exportName: 'VpcId',
});

// Avoid: Over-exporting
// Don't export everything "just in case"
```

## Anti-Patterns to Avoid

### 1. Too Many Stacks

**Problem**: Over-fragmenting into too many small stacks
**Solution**: Balance between modularity and manageability

### 2. Circular Dependencies

**Problem**:

```typescript
// Stack A depends on Stack B
// Stack B depends on Stack A
```

**Solution**: Restructure or combine stacks

### 3. Hardcoded Values

**Problem**:

```typescript
const vpcId = 'vpc-12345'; // Hardcoded
```

**Solution**: Use CloudFormation exports or parameters

### 4. Exporting Everything

**Problem**: Exporting all resource IDs "just in case"
**Solution**: Only export what's actually needed

## Related Knowledge

- **core-concepts/cdk-fundamentals.md** - CDK basics
- **patterns/cross-stack-references.md** - Advanced cross-stack patterns
- **patterns/custom-constructs.md** - Creating reusable constructs

---

**Category**: Patterns
**Last Updated**: 2025-10-09
**Status**: Complete

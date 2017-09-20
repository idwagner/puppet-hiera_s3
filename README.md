# hiera_s3

#### Table of Contents

1. [Description](#description)
1. [Setup](#setup)
    * [AWS SDK](#aws-sdk)
    * [Hiera Configuration](#hiera-configuration)
    * [Sample Configuration](#sample-configuration)
1. [Usage and Examples](#usage)
1. [Limitations](#limitations)
1. [Development](#development)

## Description

This provides an S3 backend to Hiera.

Hiera_s3 will attempt to parse a found key as YAML, but will fallback to a string value gracefully. Optionally, you can specify a (replicated) bucket as a failover. Using a failover bucket, connection errors and other S3 errors on a GetObject from primary bucket will be retried on the failover bucket.

## Setup

### AWS SDK

This module depends on the aws-sdk-s3 gem, which can be loaded with puppetserver, or puppet:

``` puppetserver gem install aws-sdk-s3```

``` puppet apply -e "package {'aws-sdk-s3': provider => 'puppet_gem'}"```


### Hiera Configuration

#### Hiera Required options
 - s3_primary_bucket: S3 bucket Name
 - s3_primary_region: Primary bucket region

#### Hiera Optional options
 - s3_prefix: a prefix to the lookup key
 - s3_failover_bucket: Failover bucket Name. Not used if not set. This will let you specify another bucket to use if the first fails
 - s3_failover_region: Failover bucket region. Only Required if s3_failover_bucket is set.


 #### Sample Configuration

 ```yaml
 ---
 version: 5
 defaults:  
   datadir: hieradata
   data_hash: yaml_data

 hierarchy:
   - name: "S3 Hiera"
     lookup_key: s3_hiera_lookup_key
     options:
       s3_prefix: "hiera/%{group}/"
       s3_primary_bucket: my_bucket
       s3_primary_region: us-west-2
       s3_failover_bucket: replicated_bucket
       s3_failover_region: us-east-1

 ```
## Usage

### Normal lookup
```
$ env FACTER_group=webserver puppet lookup --explain my_password
Searching for "my_password"
 Environment Data Provider (hiera configuration version 5)
   Hierarchy entry "S3 Hiera"
     Found key: "my_password" value: "P4ssw0rd!"
     Looking for s3://my_bucket/hiera/webserver/my_password

```

### Failover lookup
```
$ env FACTER_group=webserver puppet lookup --explain my_password

Warning: Error: s3_hiera_lookup_key while getting object: Access
Denied [my_password] - (Primary bucket failure). Trying Secondary

Searching for "my_password"
 Environment Data Provider (hiera configuration version 5)
   Hierarchy entry "S3 Hiera"
     Found key: "my_password" value: "P4ssw0rd!"
     Looking for s3://my_bucket/hiera/webserver/my_password
     Looking for s3://replicated_bucket/hiera/webserver/my_password
```

## Limitations

This has had limited testing, but should be compatible on Linux and Windows.

## Development

Fork on GutHub.

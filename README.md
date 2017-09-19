# puppet-hiera_s3
Puppet Hiera (v5) lookup function for AWS s3

This will try to parse a found S3 object as YAML, but will fallback to a string. Optionally, you can specify a (replicated) bucket as a failover. A S3 NoSuchKey on the primary will return not_found, but S3 exceptions such as AccessDenied or connection errors will get retried on the failover.


## Hiera Configuration:

#### Required
 - s3_primary_bucket: S3 bucket Name
 - s3_primary_region: Primary bucket region

#### Optional
 - s3_prefix: a prefix to the lookup key
 - s3_failover_bucket: Failover bucket Name. Not used if not set. This will let you specify another bucket to use if the first fails
 - s3_failover_region: Failover bucket region. Only Required if s3_failover_bucket is set.


## Sample Configuration
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

## Normal lookup
```
$ env FACTER_group=webserver puppet lookup --explain my_password
Searching for "my_password"
  Environment Data Provider (hiera configuration version 5)
    Hierarchy entry "S3 Hiera"
      Found key: "my_password" value: "P4ssw0rd!"
      Looking for s3://my_bucket/hiera/webserver/my_password

```

## Failover lookup
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

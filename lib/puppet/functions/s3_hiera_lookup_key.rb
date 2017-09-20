# Puppet Hiera v5 function to use an AWS S3 backend.
# This will try to parse a found S3 object as yaml, but will fallback to a string
#
# Hiera Configuration options:
# Required:
#   s3_primary_bucket: S3 bucket Name (string)
# Optional:
#   s3_prefix: a prefix to the lookup key
#   s3_primary_region: Primary bucket region. Defaults to us-east-1. It is best
#                      to match the bucket region correctly to prevent redirects
#                      and or preventable s3 failures
#   s3_failover_bucket: Failover bucket. Not used if not set. This will let you
#                       specify another bucket to use if the first fails
#   s3_failover_region: Failover bucket region. Defaults to us-east-1. It is best
#                      to match the bucket region correctly to prevent redirects
#                      and or preventable s3 failures

Puppet::Functions.create_function(:s3_hiera_lookup_key) do

  require 'aws-sdk-s3'

  dispatch :s3_hiera_lookup_key do
    param 'String[1]', :key
    param 'Hash[String[1],Any]', :options
    param 'Puppet::LookupContext', :context
  end

  def s3_hiera_lookup_key(key, options, context)
    return context.cached_value(key) if context.cache_has_key(key)


    if not options.include?('s3_primary_bucket')
      raise ArgumentError, "'s3_primary_bucket': must be defined as an option"
    end

    if not options.include?('s3_primary_region')
      raise ArgumentError, "'s3_primary_region': must be defined as an option"
    end

    if options.include?('s3_failover_bucket') and not options.include?('s3_failover_region')
      raise ArgumentError, "'s3_failover_region': must be defined if s3_failover_bucket is"
    end

    # Key Prefix is also optional
    s3_prefix = options.include?('s3_prefix') ? options['s3_prefix'] : ''
    lookup_key = "#{s3_prefix}#{key}"


    begin
      raw_data = retrieve_s3_key(options['s3_primary_bucket'],
                                 lookup_key,
                                 options['s3_primary_region'],
                                 context)
    rescue Exception => e
      # Note: retrieve_s3_key catches NoSuchKey exception (returns nil)
      if options.include?('s3_failover_bucket')
        # Try failover bucket, without error handling
        Puppet.warning("#{e} [#{key}] - (Primary bucket failure). Trying Secondary")
        raw_data = retrieve_s3_key(options['s3_failover_bucket'],
                                   lookup_key,
                                   options['s3_failover_region'],
                                   context)
      else
        raise Puppet::DataBinding::LookupError, "Error: s3_hiera_lookup_key while getting object: #{e.message}"
      end
    end

    if not raw_data
      return context.not_found
    end

    # Try to load this as a YAML object. If failure, data will be handled as a string
    begin
      data = YAML.load(raw_data)
    rescue YAML::SyntaxError => ex
      data = raw_data
    end

    # Finally process the interpolation for mixed data types
    context.cache(key, process_interpolation(data, context))

  end


  def retrieve_s3_key(bucket, key, aws_region, context)

    s3 = Aws::S3::Client.new( region: aws_region )

    context.explain() { "Looking for s3://#{bucket}/#{key}"}
    begin
      s3_object = s3.get_object(
        bucket: bucket,
        key: key
      )
    rescue Aws::S3::Errors::NoSuchKey
      return nil
    rescue Exception => e
      raise Puppet::DataBinding::LookupError, "Error: s3_hiera_lookup_key while getting object: #{e.message}"
    end

    s3_object.body.read

  end


  def process_interpolation(value, context)
    #
    case value
    when String
      context.interpolate(value)
    when Hash
      result = {}
      value.each_pair { |k, v| result[context.interpolate(k)] = context.interpolate(v) }
      result
    when Array
      value.map { |v| context.interpolate(v) }
    else
      value
    end
  end

end

require 'register_common/adapters/kinesis_adapter'
require 'register_common/adapters/s3_adapter'
require 'register_transformer_dk/config/settings'

module RegisterTransformerDk
  module Config
    module Adapters
      KINESIS_ADAPTER = RegisterCommon::Adapters::KinesisAdapter.new(credentials: AWS_CREDENTIALS)
      S3_ADAPTER = RegisterCommon::Adapters::S3Adapter.new(credentials: AWS_CREDENTIALS)
      REDIS_ADAPTER = RegisterCommon::Adapters::Redis.new(
        host: ENV.fetch('REDIS_HOST'),
        port: ENV.fetch('REDIS_PORT'),
      )
      SET_CLIENT = RegisterCommon::Services::SetClientRedis.new(redis_adapter: REDIS_ADAPTER)
    end
  end
end

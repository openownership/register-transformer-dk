# frozen_string_literal: true

require 'register_common/services/stream_client_kinesis'
require 'register_sources_bods/services/publisher'
require 'register_sources_dk/structs/deltagerperson'
require 'register_sources_oc/services/resolver_service'

require_relative '../bods_mapping/record_processor'
require_relative '../config/adapters'
require_relative '../config/settings'
require_relative '../record_deserializer'

module RegisterTransformerDk
  module Apps
    class Transformer
      def initialize(bods_publisher: nil, entity_resolver: nil, s3_adapter: nil, bods_mapper: nil)
        bods_publisher ||= RegisterSourcesBods::Services::Publisher.new
        entity_resolver ||= RegisterSourcesOc::Services::ResolverService.new
        s3_adapter ||= RegisterTransformerDk::Config::Adapters::S3_ADAPTER
        @bods_mapper = bods_mapper || RegisterTransformerDk::BodsMapping::RecordProcessor.new(
          entity_resolver:,
          bods_publisher:
        )
        @stream_client = RegisterCommon::Services::StreamClientKinesis.new(
          credentials: RegisterTransformerDk::Config::AWS_CREDENTIALS,
          stream_name: ENV.fetch('DK_STREAM', 'dk_stream'),
          s3_adapter:,
          s3_bucket: ENV.fetch('BODS_S3_BUCKET_NAME', nil)
        )
        @consumer_id = 'RegisterTransformerDk'
        @deserializer = RegisterTransformerDk::RecordDeserializer.new
      end

      def call
        stream_client.consume(consumer_id) do |record_data|
          dk_record = deserializer.deserialize record_data
          bods_mapper.process(dk_record)
        end
      end

      private

      attr_reader :bods_mapper, :stream_client, :consumer_id, :deserializer
    end
  end
end

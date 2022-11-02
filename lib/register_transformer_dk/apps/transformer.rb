require 'register_transformer_dk/config/settings'
require 'register_transformer_dk/config/adapters'
require 'register_transformer_dk/bods_mapping/record_processor'
require 'register_transformer_dk/record_deserializer'
require 'register_sources_bods/services/publisher'
require 'register_sources_dk/structs/deltagerperson'
require 'register_sources_oc/services/resolver_service'
require 'register_common/services/stream_client_kinesis'

$stdout.sync = true

module RegisterTransformerDk
  module Apps
    class Transformer
      def initialize(bods_publisher: nil, entity_resolver: nil, s3_adapter: nil, bods_mapper: nil, deserializer: nil)
        bods_publisher ||= RegisterSourcesBods::Services::Publisher.new
        entity_resolver ||= RegisterSourcesOc::Services::ResolverService.new
        s3_adapter ||= RegisterTransformerDk::Config::Adapters::S3_ADAPTER
        @bods_mapper = bods_mapper || RegisterTransformerDk::BodsMapping::RecordProcessor.new(
          entity_resolver: entity_resolver,
          bods_publisher: bods_publisher
        )
        @stream_client = RegisterCommon::Services::StreamClientKinesis.new(
          credentials: RegisterTransformerDk::Config::AWS_CREDENTIALS,
          stream_name: ENV.fetch('DK_STREAM', 'dk_stream'),
          s3_adapter: s3_adapter,
          s3_prefix: 'large-dk',
          s3_bucket: ENV['BODS_S3_BUCKET_NAME'],
        )
        @consumer_id = "RegisterTransformerDk"
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

      def handle_records(records)
        records.each do |record|
          bods_mapper.process dk_record
        end
      end
    end
  end
end

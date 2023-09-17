require 'register_transformer_dk/config/settings'
require 'register_transformer_dk/config/adapters'

require 'register_common/services/bulk_transformer'

require 'register_sources_bods/services/publisher'
require 'register_sources_oc/services/resolver_service'

require 'register_transformer_dk/bods_mapping/record_processor'
require 'register_transformer_dk/record_deserializer'

module RegisterTransformerDk
  module Apps
    class TransformerBulk
      def self.bash_call(args)
        s3_prefix = args.last

        TransformerBulk.new.call(s3_prefix)
      end

      def initialize(bulk_transformer: nil, s3_bucket: nil, bods_mapper: nil)
        @bods_mapper = bods_mapper || RegisterTransformerDk::BodsMapping::RecordProcessor.new(
          entity_resolver: RegisterSourcesOc::Services::ResolverService.new,
          bods_publisher: RegisterSourcesBods::Services::Publisher.new,
        )

        @bulk_transformer = bulk_transformer || RegisterCommon::Services::BulkTransformer.new(
          s3_adapter: Config::Adapters::S3_ADAPTER,
          s3_bucket: s3_bucket || ENV.fetch('BODS_S3_BUCKET_NAME'),
          set_client: Config::Adapters::SET_CLIENT,
        )

        @deserializer = RegisterTransformerDk::RecordDeserializer.new
      end

      def call(s3_prefix)
        bulk_transformer.call(s3_prefix) do |rows|
          process_rows rows
        end
      end

      private

      attr_reader :bods_mapper, :bulk_transformer, :deserializer

      def process_rows(rows)
        records = rows.map do |record_data|
          deserializer.deserialize record_data
        end

        records.each do |record|
          bods_mapper.process record
        end
      end
    end
  end
end

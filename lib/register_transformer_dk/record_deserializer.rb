require 'json'
require 'stringio'

require 'register_common/decompressors/gzip_reader'
require 'register_sources_dk/structs/deltagerperson'

module RegisterTransformerDk
  class RecordDeserializer
    def initialize(zip_reader: RegisterCommon::Decompressors::GzipReader.new)
      @zip_reader = zip_reader
    end

    def deserialize(record_data)
      serialized_json =
        begin
          zip_reader.open_stream(StringIO.new(record_data)) { |unzipped| unzipped.read }
        rescue
          record_data # older records may not be compressed
        end
      deserialize_from_json serialized_json
    end

    private

    attr_reader :zip_reader

    def deserialize_from_json(record_data)
      record = JSON.parse(record_data, symbolize_names: true)
      RegisterSourcesDk::Deltagerperson[**record]
    end
  end
end

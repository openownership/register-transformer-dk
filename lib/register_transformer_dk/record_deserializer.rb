require 'json'
require 'stringio'

require 'register_common/decompressors/gzip_reader'
require 'register_sources_dk/structs/deltagerperson'

module RegisterTransformerDk
  class RecordDeserializer
    def initialize(zip_reader: RegisterCommon::Decompressors::GzipReader.new)
      @zip_reader = zip_reader
    end

    def deserialize(record)
      serialized_json = zip_reader.open_stream(StringIO.new(record)) { |unzipped| unzipped.read }
      deserialize_from_json serialized_json
    end

    private

    attr_reader :zip_reader

    def deserialize_from_json(record)
      record = JSON.parse(record_data, symbolize_names: true)
      RegisterSourcesDk::Deltagerperson[**record]
    end
  end
end

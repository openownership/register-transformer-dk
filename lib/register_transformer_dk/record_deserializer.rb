# frozen_string_literal: true

require 'json'

require 'register_sources_dk/structs/deltagerperson'

module RegisterTransformerDk
  class RecordDeserializer
    def deserialize(record_data)
      deserialize_from_json record_data
    end

    private

    def deserialize_from_json(record_data)
      record = JSON.parse(record_data, symbolize_names: true)
      RegisterSourcesDk::Deltagerperson[**record]
    end
  end
end

require 'active_support/core_ext/string/conversions'

require 'register_sources_bods/structs/interest'

require_relative 'utils'

module RegisterTransformerDk
  module BodsMapping
    class InterestParser
      def initialize(utils: nil)
        @utils = utils || Utils.new
      end

      def call(i)
        interest_type = nil

        case i.type
        when 'EJERANDEL_PROCENT'
          interest_type = 'shareholding'
        when 'EJERANDEL_STEMMERET_PROCENT'
          interest_type = 'voting-rights'
        end

        return if interest_type.blank?

        share_percentage = utils.most_recent(i.vaerdier).vaerdi.to_f * 100.0

        RegisterSourcesBods::Interest[{
          type: interest_type,
          share: {
            exact: share_percentage,
            minimum: share_percentage,
            maximum: share_percentage,
          }
        }]
      end

      private

      attr_reader :utils
    end
  end
end

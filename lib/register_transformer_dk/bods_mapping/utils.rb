# frozen_string_literal: true

module RegisterTransformerDk
  module BodsMapping
    class Utils
      def most_recent(items)
        return unless items.all?

        sort_by_period(items).first
      end

      def sort_by_period(items)
        items.sort do |x, y|
          # Convert to strings to handle `nil` values
          y.periode.gyldigFra.to_s <=> x.periode.gyldigFra.to_s
        end
      end
    end
  end
end

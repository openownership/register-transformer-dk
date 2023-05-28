require 'register_sources_bods/enums/entity_types'
require 'register_sources_bods/enums/statement_types'
require 'register_sources_bods/structs/address'
require 'register_sources_bods/structs/entity_statement'
require 'register_sources_bods/structs/identifier'
require 'register_sources_bods/structs/jurisdiction'
require 'register_sources_bods/constants/publisher'
require 'register_sources_bods/mappers/resolver_mappings'

require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/object/try'
require 'active_support/core_ext/time'
require 'active_support/core_ext/string/conversions'

require 'register_sources_oc/structs/resolver_request'

require_relative 'utils'

module RegisterTransformerDk
  module BodsMapping
    class ChildEntityStatement
      ID_PREFIX = 'openownership-register-'.freeze

      include RegisterSourcesBods::Mappers::ResolverMappings

      def self.call(relation, utils: nil, entity_resolver: nil)
        new(relation, utils:, entity_resolver:).call
      end

      def initialize(relation, utils: nil, entity_resolver: nil)
        @relation = relation
        @entity_resolver = entity_resolver
        @utils = utils || Utils.new
      end

      def call
        RegisterSourcesBods::EntityStatement[{
          statementID: statement_id,
          statementType: RegisterSourcesBods::StatementTypes['entityStatement'],
          isComponent: false,
          addresses:,
          name: company_name || name,
          entityType: RegisterSourcesBods::EntityTypes['registeredEntity'],
          incorporatedInJurisdiction: incorporated_in_jurisdiction,
          identifiers: [
            RegisterSourcesBods::Identifier.new(
              scheme: 'DK-CVR',
              schemeName: 'Danish Central Business Register',
              id: company_number,
            ),
            open_corporates_identifier,
          ].compact,
          foundingDate: founding_date,
          dissolutionDate: dissolution_date,
          publicationDetails: publication_details,
        }.compact]
      end

      private

      attr_reader :entity_resolver, :utils, :relation

      def company_number
        relation[:company].cvrNummer.to_s
      end

      def company_name
        @company_name ||= utils.most_recent(relation[:company].navne).navn
      end

      def resolver_response
        return @resolver_response if @resolver_response

        @resolver_response = entity_resolver.resolve(
          RegisterSourcesOc::ResolverRequest.new(
            company_number:,
            jurisdiction_code: 'dk',
            name: company_name,
          ),
        )
      end

      def statement_id
        'TODO'
      end

      def publication_details
        RegisterSourcesBods::PublicationDetails.new(
          publicationDate: Time.now.utc.to_date.to_s, # TODO: fix publication date
          bodsVersion: RegisterSourcesBods::BODS_VERSION,
          license: RegisterSourcesBods::BODS_LICENSE,
          publisher: RegisterSourcesBods::PUBLISHER,
        )
      end
    end
  end
end

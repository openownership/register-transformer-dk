require 'xxhash'

require 'register_sources_bods/constants/publisher'
require 'register_sources_bods/structs/interest'
require 'register_sources_bods/structs/entity_statement'
require 'register_sources_bods/structs/ownership_or_control_statement'
require 'register_sources_bods/structs/publication_details'
require 'register_sources_bods/structs/share'
require 'register_sources_bods/structs/source'
require 'register_sources_bods/structs/subject'

require_relative 'interest_parser'
require_relative 'utils'

module RegisterTransformerDk
  module BodsMapping
    class OwnershipOrControlStatement
      UnsupportedSourceStatementTypeError = Class.new(StandardError)

      ID_PREFIX = 'openownership-register-'.freeze

      def self.call(dk_record, **kwargs)
        new(dk_record, **kwargs).call
      end

      def initialize(
        dk_record,
        relation:,
        entity_resolver: nil,
        source_statement: nil,
        target_statement: nil,
        interest_parser: nil,
        utils: nil
      )
        @dk_record = dk_record
        @relation = relation
        @source_statement = source_statement
        @target_statement = target_statement
        @interest_parser = interest_parser || InterestParser.new
        @entity_resolver = entity_resolver
        @utils = utils || Utils.new
      end

      def call
        RegisterSourcesBods::OwnershipOrControlStatement[{
          statementID: statement_id,
          statementType: statement_type,
          statementDate: statement_date,
          isComponent: false,
          subject:,
          interestedParty: interested_party,
          interests:,
          publicationDetails: publication_details,
          source:,
        }.compact]
      end

      private

      attr_reader :interest_parser, :entity_resolver, :source_statement, :target_statement,
                  :dk_record, :relation, :utils

      def data
        dk_record.data
      end

      # when Structs::Relationship
      def statement_id
        ID_PREFIX + hasher(
          {
            id: 'TODO_ID', # obj.id,
            updated_at: statement_date,
            source_id: source_statement.statementID,
            target_id: target_statement.statementID,
          }.to_json,
        )
      end

      def statement_type
        RegisterSourcesBods::StatementTypes['ownershipOrControlStatement']
      end

      def statement_date
        relation[:last_updated].present? ? Date.parse(relation[:last_updated]).to_s : nil
      end

      def subject
        RegisterSourcesBods::Subject.new(
          describedByEntityStatement: target_statement.statementID,
        )
      end

      def interests
        relation[:interests].map do |interest|
          RegisterSourcesBods::Interest[
            interest.to_h.merge(
              {
                startDate: relation[:start_date].presence,
                endDate: relation[:end_date].presence,
              }.compact,
            )
          ]
        end
      end

      def interested_party
        case source_statement.statementType
        when RegisterSourcesBods::StatementTypes['personStatement']
          RegisterSourcesBods::InterestedParty[{
            describedByPersonStatement: source_statement.statementID,
          }]
        when RegisterSourcesBods::StatementTypes['entityStatement']
          case source_statement.entityType
          when RegisterSourcesBods::EntityTypes['unknownEntity']
            RegisterSourcesBods::InterestedParty[{
              unspecified: source_statement.unspecifiedEntityDetails,
            }.compact]
          when RegisterSourcesBods::EntityTypes['legalEntity']
            RegisterSourcesBods::InterestedParty[{
              describedByEntityStatement: source_statement.statementID,
            }]
          else
            RegisterSourcesBods::InterestedParty[{}] # TODO: raise error
          end
        else
          raise UnsupportedSourceStatementTypeError
        end
      end

      def publication_details
        RegisterSourcesBods::PublicationDetails.new(
          publicationDate: Time.now.utc.to_date.to_s,
          bodsVersion: RegisterSourcesBods::BODS_VERSION,
          license: RegisterSourcesBods::BODS_LICENSE,
          publisher: RegisterSourcesBods::PUBLISHER,
        )
      end

      def source
        RegisterSourcesBods::Source.new(
          type: RegisterSourcesBods::SourceTypes['officialRegister'],
          description: 'DK Centrale Virksomhedsregister',
          url: "http://distribution.virk.dk/cvr-permanent",
          retrievedAt: Time.now.utc.to_date.to_s, # TODO: fix publication date, # TODO: add retrievedAt to record iso8601
          assertedBy: nil, # TODO: if it is a combination of sources (DK and OpenCorporates), is it us?
        )
      end

      def hasher(data)
        XXhash.xxh64(data).to_s
      end
    end
  end
end

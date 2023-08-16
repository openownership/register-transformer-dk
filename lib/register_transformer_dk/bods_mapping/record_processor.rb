# NOTE: some of the logic in this importer is based on the OC script:
# https://gist.github.com/skenaja/cf843d127e8937b5f79fa6d0e81d1543

require_relative 'interest_parser'

require 'register_transformer_dk/bods_mapping/person_statement'
require 'register_transformer_dk/bods_mapping/child_entity_statement'
require 'register_transformer_dk/bods_mapping/ownership_or_control_statement'

require_relative 'utils'

module RegisterTransformerDk
  module BodsMapping
    class RecordProcessor
      def initialize(
        entity_resolver: nil,
        interest_parser: nil,
        person_statement_mapper: BodsMapping::PersonStatement,
        child_entity_statement_mapper: BodsMapping::ChildEntityStatement,
        ownership_or_control_statement_mapper: BodsMapping::OwnershipOrControlStatement,
        bods_publisher: nil,
        utils: nil
      )
        @entity_resolver = entity_resolver
        @bods_publisher = bods_publisher
        @interest_parser = interest_parser || InterestParser.new
        @person_statement_mapper = person_statement_mapper
        @child_entity_statement_mapper = child_entity_statement_mapper
        @ownership_or_control_statement_mapper = ownership_or_control_statement_mapper
        @utils = utils || Utils.new
      end

      def process(dk_record)
        # A record here conforms to the `Vrdeltagerperson` data type from the DK data source

        return if dk_record.fejlRegistreret # ignore if errors discovered

        return unless dk_record.enhedstype == 'PERSON'

        relations = relations_with_real_owner_status(dk_record)
        return if relations.blank?

        parent_entity = map_parent_entity(dk_record)
        parent_entity = bods_publisher.publish(parent_entity)

        relationships = relations.map do |relation|
          child_entity = map_child_entity(relation)
          child_entity = bods_publisher.publish(child_entity)

          map_relationships(dk_record, child_entity, parent_entity, relation)
        end

        relationships.each { |relationship| bods_publisher.publish(relationship).to_h }
      end

      private

      attr_reader :entity_resolver, :interest_parser, :person_statement_mapper, :utils,
                  :child_entity_statement_mapper, :ownership_or_control_statement_mapper, :bods_publisher

      def map_parent_entity(dk_record)
        person_statement_mapper.call(dk_record)
      end

      def map_child_entity(relation)
        child_entity_statement_mapper.call(relation, entity_resolver:)
      end

      def map_relationships(dk_record, child_entity, parent_entity, relation)
        ownership_or_control_statement_mapper.call(
          dk_record,
          relation:,
          entity_resolver:,
          source_statement: parent_entity,
          target_statement: child_entity,
          interest_parser:,
        )
      end

      def relations_with_real_owner_status(dk_record)
        dk_record.virksomhedSummariskRelation.each_with_object([]) do |item, acc|
          next if item.virksomhed.fejlRegistreret # ignore if errors discovered

          real_owner_role = nil
          interests = []
          is_indirect = false

          item.organisationer.each do |o|
            o.medlemsData.each do |md|
              md.attributter.each do |a|
                next unless a.type == 'FUNKTION'

                real_owner_role = utils.most_recent(
                  a.vaerdier.select { |v| v.vaerdi == 'Reel ejer' },
                )
                interests = md.attributter.map { |a| interest_parser.call a }.compact
                is_indirect = indirect?(md.attributter)
              end
            end

            break if real_owner_role.present?
          end

          next if real_owner_role.blank?

          acc << {
            last_updated: real_owner_role.sidstOpdateret,
            start_date: real_owner_role.periode.gyldigFra,
            end_date: real_owner_role.periode.gyldigTil,
            company: item.virksomhed,
            interests:,
            is_indirect:,
          }
        end
      end

      def indirect?(attributes)
        special_ownership = attributes.find { |a| a.type == 'SÆRLIGE_EJERFORHOLD' }
        return false if special_ownership.blank?

        utils.most_recent(special_ownership.vaerdier).vaerdi == 'Har indirekte besiddelser'
      end
    end
  end
end

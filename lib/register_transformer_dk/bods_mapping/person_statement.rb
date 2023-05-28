require 'xxhash'
require 'register_sources_bods/constants/publisher'
require 'register_sources_bods/structs/person_statement'
require 'register_sources_bods/structs/publication_details'
require 'register_sources_bods/structs/source'

require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/object/try'
require 'countries'
require 'iso8601'

require_relative 'utils'

module RegisterTransformerDk
  module BodsMapping
    class PersonStatement
      ID_PREFIX = 'openownership-register-'.freeze

      def self.call(dk_record)
        new(dk_record).call
      end

      def initialize(dk_record, utils: nil)
        @dk_record = dk_record
        @utils = utils || Utils.new
      end

      def call
        RegisterSourcesBods::PersonStatement[{
          statementID: statement_id,
          statementType: statement_type,
          # statementDate: statement_date,
          isComponent: is_component,
          personType: person_type,
          unspecifiedPersonDetails: unspecified_person_details,
          names:,
          identifiers:,
          nationalities:,
          placeOfBirth: place_of_birth, # not implemented in register
          birthDate: birth_date,
          deathDate: death_date,
          placeOfResidence: place_of_residence,
          taxResidencies: tax_residencies,
          addresses:,
          hasPepStatus: has_pep_status,
          pepStatusDetails: pep_status_details,
          publicationDetails: publication_details,
          source:,
          annotations:,
          replacesStatements: replaces_statements,
        }.compact]
      end

      private

      attr_reader :dk_record, :utils

      def statement_id
        obj_id = "TODO" # TODO: implement object id
        self_updated_at = "something" # TODO: implement self_updated_at
        ID_PREFIX + hasher("openownership-register/entity/#{obj_id}/#{self_updated_at}")
      end

      def statement_type
        RegisterSourcesBods::StatementTypes['personStatement']
      end

      def statement_date
        # NOT IMPLEMENTED
      end

      def person_type
        RegisterSourcesBods::PersonTypes['knownPerson'] # TODO: KNOWN_PERSON, ANONYMOUS_PERSON, UNKNOWN_PERSON
      end

      def identifiers
        [
          RegisterSourcesBods::Identifier.new(
            id: dk_record.enhedsNummer.to_s,
            schemeName: 'DK Centrale Virksomhedsregister',
          ),
        ]
      end

      def unspecified_person_details
        # { reason, description }
      end

      def names
        [
          RegisterSourcesBods::Name.new(
            type: RegisterSourcesBods::NameTypes['individual'],
            fullName: utils.most_recent(dk_record.navne).navn,
          ),
        ]
      end

      def nationalities
        latest_address = utils.most_recent(dk_record.beliggenhedsadresse)
        nationality = latest_address.try(&:landekode)
        return unless nationality

        country = ISO3166::Country[nationality]
        return nil if country.blank?

        [
          RegisterSourcesBods::Country.new(name: country.name, code: country.alpha2),
        ]
      end

      def place_of_birth
        # NOT IMPLEMENTED IN REGISTER
      end

      def birth_date
        # NOT IMPLEMENTED IN REGISTER
      end

      def death_date
        # NOT IMPLEMENTED IN REGISTER
      end

      def place_of_residence
        # NOT IMPLEMENTED IN REGISTER
      end

      def tax_residencies
        # NOT IMPLEMENTED IN REGISTER
      end

      def addresses
        latest_address = utils.most_recent(dk_record.beliggenhedsadresse)

        return if latest_address.blank?

        address =
          if latest_address.fritekst
            latest_address.fritekst
          else
            co_name = "c/o #{latest_address.conavn}" if latest_address.conavn

            street_numbers = [latest_address.husnummerFra, latest_address.husnummerTil].compact.join('-')

            street_address_excl_floor = [
              latest_address.vejnavn.try(:strip).presence,
              street_numbers,
            ].compact.map(&:strip).map(&:presence).compact.join(' ')

            street_address_excl_postbox = [
              street_address_excl_floor,
              latest_address.etage.try(:strip).presence,
            ].compact.join(', ')

            [
              co_name,
              street_address_excl_postbox,
              latest_address.postboks.try(:strip).presence && "Postboks #{latest_address.postboks}",
              latest_address.postdistrikt.try(:strip).presence,
              latest_address.postnummer.try(:to_s),
            ].compact.join(', ')
          end

        return [] if address.blank?

        nationality = latest_address.try(&:landekode)
        return unless nationality

        country = try_parse_country_name_to_code(nationality)

        return [] if country.blank? # TODO: check this

        [
          RegisterSourcesBods::Address.new(
            type: RegisterSourcesBods::AddressTypes['registered'], # TODO: check this
            address:,
            # postCode: nil,
            country:,
          ),
        ]
      end

      def try_parse_country_name_to_code(name)
        return nil if name.blank?

        return ISO3166::Country[name].try(:alpha2) if name.length == 2

        country = ISO3166::Country.find_country_by_name(name)

        return country.alpha2 if country

        country = ISO3166::Country.find_country_by_alpha3(name)

        return country.alpha2 if country
      end

      def has_pep_status
        # NOT IMPLEMENTED IN REGISTER
      end

      def pep_status_details
        # NOT IMPLEMENTED IN REGISTER
      end

      def statement_date
        # UNIMPLEMENTED IN REGISTER (only for ownership or control statements)
      end

      def is_component
        false
      end

      def replaces_statements
        # UNIMPLEMENTED IN REGISTER
      end

      def publication_details
        # UNIMPLEMENTED IN REGISTER
        RegisterSourcesBods::PublicationDetails.new(
          publicationDate: Time.now.utc.to_date.to_s, # TODO: fix publication date
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
          retrievedAt: Time.now.utc.to_date.to_s, # TODO: fix publication date, # TODO: add retrievedAt to dk_record iso8601
          assertedBy: nil, # TODO: if it is a combination of sources (DK and OpenCorporates), is it us?
        )
      end

      def annotations
        # UNIMPLEMENTED IN REGISTER
      end

      def replaces_statements
        # UNIMPLEMENTED IN REGISTER
      end

      def hasher(dk_record)
        XXhash.xxh64(dk_record).to_s
      end
    end
  end
end

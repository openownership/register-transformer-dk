# frozen_string_literal: true

require 'active_support/testing/time_helpers'

require 'register_transformer_dk/bods_mapping/record_processor'
require 'register_sources_dk/structs/deltagerperson'

RSpec.describe RegisterTransformerDk::BodsMapping::RecordProcessor do
  include ActiveSupport::Testing::TimeHelpers

  subject do
    described_class.new(
      entity_resolver:,
      interest_parser:,
      person_statement_mapper:,
      child_entity_statement_mapper:,
      ownership_or_control_statement_mapper:,
      bods_publisher:
    )
  end

  let(:entity_resolver) { double 'entity_resolver' }
  let(:dk_record) do
    data = {
      navne: [
        {
          navn: 'Danish Person 1',
          periode: {
            gyldigFra: nil,
            gyldigTil: nil
          }
        }
      ],
      beliggenhedsadresse: [
        {
          landekode: 'DK',
          fritekst: nil,
          husnummerFra: 1,
          husnummerTil: nil,
          etage: nil,
          conavn: nil,
          postboks: nil,
          vejnavn: 'Example Vej',
          postnummer: 1234,
          postdistrikt: 'Example Town',
          periode: {
            gyldigFra: '2015-01-01',
            gyldigTil: nil
          }
        }
      ],
      virksomhedSummariskRelation: [
        {
          virksomhed: {
            enhedstype: 'VIRKSOMHED',
            fejlRegistreret: false,
            sidstOpdateret: '2015-01-02T00:00:00.000+02:00',
            cvrNummer: 1_234_567,
            navne: [
              {
                navn: 'Danish Company 1',
                periode: {
                  gyldigFra: '2015-01-01',
                  gyldigTil: '2015-01-02'
                }
              },
              {
                navn: 'Renamed Danish Company 1',
                periode: {
                  gyldigFra: '2015-01-02',
                  gyldigTil: nil
                }
              }
            ]
          },
          organisationer: [
            {
              medlemsData: [
                {
                  attributter: [
                    {
                      type: 'EJERANDEL_PROCENT',
                      vaerdier: [
                        {
                          vaerdi: '0.5'
                        }
                      ]
                    },
                    {
                      type: 'EJERANDEL_STEMMERET_PROCENT',
                      vaerdier: [
                        {
                          vaerdi: '0.5'
                        }
                      ]
                    },
                    {
                      type: 'FUNKTION',
                      vaerdier: [
                        {
                          vaerdi: 'Reel ejer',
                          periode: {
                            gyldigFra: '2015-01-01',
                            gyldigTil: nil
                          },
                          sidstOpdateret: '2015-01-02T00:00:00.000+02:00'
                        }
                      ]
                    }
                  ]
                }
              ]
            }
          ]
        }
      ],
      fejlRegistreret: false,
      enhedsNummer: 1,
      enhedstype: 'PERSON',
      sidstOpdateret: '2015-01-02T00:00:00.000+01:00'
    }
    RegisterSourcesDk::Deltagerperson[data]
  end
  let(:interest_parser) { double 'interest_parser' }
  let(:person_statement_mapper) { double 'person_statement_mapper' }
  let(:child_entity_statement_mapper) { double 'child_entity_statement_mapper' }
  let(:ownership_or_control_statement_mapper) { double 'ownership_or_control_statement_mapper' }
  let(:bods_publisher) { double 'bods_publisher' }

  before { travel_to Time.at(1_663_187_854) }
  after { travel_back }

  it 'processes record' do
    expect(interest_parser).to receive(:call).with(
      dk_record.virksomhedSummariskRelation[0].organisationer[0].medlemsData[0].attributter[0]
    )
    expect(interest_parser).to receive(:call).with(
      dk_record.virksomhedSummariskRelation[0].organisationer[0].medlemsData[0].attributter[1]
    )
    expect(interest_parser).to receive(:call).with(
      dk_record.virksomhedSummariskRelation[0].organisationer[0].medlemsData[0].attributter[2]
    )

    relation = {
      company: dk_record.virksomhedSummariskRelation[0].virksomhed,
      end_date: nil,
      interests: [],
      is_indirect: false,
      last_updated: '2015-01-02T00:00:00.000+02:00',
      start_date: '2015-01-01'
    }

    parent_entity = double 'parent_entity'
    expect(person_statement_mapper).to receive(:call).with(
      dk_record
    ).and_return parent_entity

    child_entity = double 'child_entity'
    expect(child_entity_statement_mapper).to receive(:call).with(
      relation,
      entity_resolver:
    ).and_return child_entity

    source_statement = double 'source_statement'
    target_statement = double 'target_statement'

    ownership_or_control_statement = double 'ownership_or_control_statement'
    expect(ownership_or_control_statement_mapper).to receive(:call).with(
      dk_record,
      relation:,
      entity_resolver:,
      source_statement:,
      target_statement:,
      interest_parser:
    ).and_return ownership_or_control_statement

    expect(bods_publisher).to receive(:publish).with(parent_entity).and_return source_statement
    expect(bods_publisher).to receive(:publish).with(child_entity).and_return target_statement
    expect(bods_publisher).to receive(:publish).with(ownership_or_control_statement)

    subject.process dk_record
  end
end

require 'active_support/testing/time_helpers'

require 'register_transformer_dk/bods_mapping/ownership_or_control_statement'
require 'register_sources_dk/structs/virksomhed'
require 'register_sources_dk/structs/deltagerperson'

RSpec.describe RegisterTransformerDk::BodsMapping::OwnershipOrControlStatement do
  include ActiveSupport::Testing::TimeHelpers

  subject do
    described_class.new(
      dk_record,
      relation:,
      entity_resolver:,
      source_statement:,
      target_statement:,
    )
  end

  let(:entity_resolver) { double 'entity_resolver' }
  let(:relation) do
    {
      company: RegisterSourcesDk::Virksomhed[{
        enhedstype: "VIRKSOMHED",
        fejlRegistreret: false,
        sidstOpdateret: "2015-01-02T00:00:00.000+02:00",
        cvrNummer: 1_234_567,
        navne: [
          {
            navn: "Danish Company 1",
            periode: {
              gyldigFra: "2015-01-01",
              gyldigTil: "2015-01-02",
            },
          },
          {
            navn: "Renamed Danish Company 1",
            periode: {
              gyldigFra: "2015-01-02",
              gyldigTil: nil,
            },
          },
        ],
      }],
      interests: [
        RegisterSourcesBods::Interest[{
          type: 'voting-rights',
          share: {
            exact: 50.0,
            minimum: 50.0,
            maximum: 50.0,
          },
        }],
      ],
    }
  end
  let(:dk_record) do
    data = {
      navne: [
        {
          navn: "Danish Person 1",
          periode: {
            gyldigFra: nil,
            gyldigTil: nil,
          },
        },
      ],
      beliggenhedsadresse: [
        {
          landekode: "DK",
          fritekst: nil,
          husnummerFra: 1,
          husnummerTil: nil,
          etage: nil,
          conavn: nil,
          postboks: nil,
          vejnavn: "Example Vej",
          postnummer: 1234,
          postdistrikt: "Example Town",
          periode: {
            gyldigFra: "2015-01-01",
            gyldigTil: nil,
          },
        },
      ],
      virksomhedSummariskRelation: [
        {
          virksomhed: {
            enhedstype: "VIRKSOMHED",
            fejlRegistreret: false,
            sidstOpdateret: "2015-01-02T00:00:00.000+02:00",
            cvrNummer: 1_234_567,
            navne: [
              {
                navn: "Danish Company 1",
                periode: {
                  gyldigFra: "2015-01-01",
                  gyldigTil: "2015-01-02",
                },
              },
              {
                navn: "Renamed Danish Company 1",
                periode: {
                  gyldigFra: "2015-01-02",
                  gyldigTil: nil,
                },
              },
            ],
          },
          organisationer: [
            {
              medlemsData: [
                {
                  attributter: [
                    {
                      type: "EJERANDEL_PROCENT",
                      vaerdier: [
                        {
                          vaerdi: "0.5",
                        },
                      ],
                    },
                    {
                      type: "EJERANDEL_STEMMERET_PROCENT",
                      vaerdier: [
                        {
                          vaerdi: "0.5",
                        },
                      ],
                    },
                    {
                      type: "FUNKTION",
                      vaerdier: [
                        {
                          vaerdi: "Reel ejer",
                          periode: {
                            gyldigFra: "2015-01-01",
                            gyldigTil: nil,
                          },
                          sidstOpdateret: "2015-01-02T00:00:00.000+02:00",
                        },
                      ],
                    },
                  ],
                },
              ],
            },
          ],
        },
      ],
      fejlRegistreret: false,
      enhedsNummer: 1,
      enhedstype: "PERSON",
      sidstOpdateret: "2015-01-02T00:00:00.000+01:00",
    }
    RegisterSourcesDk::Deltagerperson[data]
  end
  let(:source_statement) do
    double 'source_statement', statementID: 'sourceID', statementType: 'entityStatement', entityType: 'legalEntity'
  end
  let(:target_statement) do
    double 'target_statement', statementID: 'targetID'
  end

  before { travel_to Time.at(1_663_187_854) }
  after { travel_back }

  it 'maps successfully' do
    result = subject.call

    expect(result).to be_a RegisterSourcesBods::OwnershipOrControlStatement
    expect(result.to_h).to eq(
      {
        interestedParty: {
          describedByEntityStatement: "sourceID",
        },
        interests: [
          { share: { exact: 50.0, maximum: 50.0, minimum: 50.0 }, type: "voting-rights" },
        ],
        isComponent: false,
        statementType: "ownershipOrControlStatement",
        subject: {
          describedByEntityStatement: "targetID",
        },
        source: {
          assertedBy: nil,
          description: "DK Centrale Virksomhedsregister",
          retrievedAt: "2022-09-14",
          type: "officialRegister",
          url: "http://distribution.virk.dk/cvr-permanent",
        },
      },
    )
  end
end

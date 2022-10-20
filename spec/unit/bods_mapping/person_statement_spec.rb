require 'active_support/testing/time_helpers'

require 'register_transformer_dk/bods_mapping/person_statement'
require 'register_sources_dk/structs/deltagerperson'

RSpec.describe RegisterTransformerDk::BodsMapping::PersonStatement do
  include ActiveSupport::Testing::TimeHelpers

  subject { described_class.new(dk_record) }

  before { travel_to Time.at(1663187854) }
  after { travel_back }

  let(:dk_record) do
    data = {
      "navne": [
        {
          "navn": "Danish Person 1",
          "periode": {
            "gyldigFra": nil,
            "gyldigTil": nil
          }
        }
      ],
      "beliggenhedsadresse": [
        {
          "landekode": "DK",
          "fritekst": nil,
          "husnummerFra": 1,
          "husnummerTil": nil,
          "etage": nil,
          "conavn": nil,
          "postboks": nil,
          "vejnavn": "Example Vej",
          "postnummer": 1234,
          "postdistrikt": "Example Town",
          "periode": {
            "gyldigFra": "2015-01-01",
            "gyldigTil": nil
          }
        }
      ],
      "virksomhedSummariskRelation": [
        {
          "virksomhed": {
            "enhedstype": "VIRKSOMHED",
            "fejlRegistreret": false,
            "sidstOpdateret": "2015-01-02T00:00:00.000+02:00",
            "cvrNummer": 1234567,
            "navne": [
              {
                "navn": "Danish Company 1",
                "periode": {
                  "gyldigFra": "2015-01-01",
                  "gyldigTil": "2015-01-02"
                }
              },
              {
                "navn": "Renamed Danish Company 1",
                "periode": {
                  "gyldigFra": "2015-01-02",
                  "gyldigTil": nil
                }
              }
            ]
          },
          "organisationer": [
            {
              "medlemsData": [
                {
                  "attributter": [
                    {
                      "type": "EJERANDEL_PROCENT",
                      "vaerdier": [
                        {
                          "vaerdi": "0.5"
                        }
                      ]
                    },
                    {
                      "type": "EJERANDEL_STEMMERET_PROCENT",
                      "vaerdier": [
                        {
                          "vaerdi": "0.5"
                        }
                      ]
                    },
                    {
                      "type": "FUNKTION",
                      "vaerdier": [
                        {
                          "vaerdi": "Reel ejer",
                          "periode": {
                            "gyldigFra": "2015-01-01",
                            "gyldigTil": nil
                          },
                          "sidstOpdateret": "2015-01-02T00:00:00.000+02:00"
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
      "fejlRegistreret": false,
      "enhedsNummer": 1,
      "enhedstype": "PERSON",
      "sidstOpdateret": "2015-01-02T00:00:00.000+01:00"
    }
    RegisterSourcesDk::Deltagerperson[data]
  end

  it 'maps successfully' do
    result = subject.call

    expect(result).to be_a RegisterSourcesBods::PersonStatement
    expect(result.to_h).to eq({
      addresses: [
        {
          address: "Example Vej 1, Example Town, 1234",
          country: "DK",
          type: "registered"
        }
      ],
      identifiers: [
        { id: "1", schemeName: "DK Centrale Virksomhedsregister" }
      ],
      isComponent: false,
      names: [
        { fullName: "Danish Person 1", type: "individual" }
      ],
      nationalities: [
        { code: "DK", name: "Denmark" }
      ],
      personType: "knownPerson",
      publicationDetails: {
        bodsVersion: "0.2", 
        license: "https://register.openownership.org/terms-and-conditions",
        publicationDate: "2022-09-14",
        publisher: {
          name: "OpenOwnership Register",
          url: "https://register.openownership.org"
        }
      },
      source: {
        assertedBy: nil,
        description: "DK Centrale Virksomhedsregister",
        retrievedAt: "2022-09-14",
        type: "officialRegister",
        url: "http://distribution.virk.dk/cvr-permanent"
      },
      statementID: "openownership-register-2042754144729635384",
      statementType: "personStatement",
    })
  end
end

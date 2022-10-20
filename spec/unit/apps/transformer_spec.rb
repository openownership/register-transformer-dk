require 'json'
require 'register_transformer_dk/apps/transformer'

RSpec.describe RegisterTransformerDk::Apps::Transformer do
  subject do
    described_class.new(
      bods_publisher: bods_publisher,
      entity_resolver: entity_resolver,
      bods_mapper: bods_mapper
    )
  end

  let(:bods_publisher) { double 'bods_publisher' }
  let(:entity_resolver) { double 'entity_resolver' }
  let(:bods_mapper) { double 'bods_mapper' }

  describe '#call' do
    it 'consumes and processes each record' do
      record_data = {
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
      expect(stream_client).to receive(:consume).with('RegisterTransformerDk').and_yield(
        record_data.to_json
      )

      expect(bods_mapper).to receive(:process)
    end
  end
end

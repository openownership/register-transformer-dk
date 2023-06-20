require 'active_support/testing/time_helpers'

require 'register_transformer_dk/bods_mapping/child_entity_statement'
require 'register_sources_dk/structs/virksomhed'
require 'register_sources_oc/structs/resolver_response'

RSpec.describe RegisterTransformerDk::BodsMapping::ChildEntityStatement do
  include ActiveSupport::Testing::TimeHelpers

  subject { described_class.new(relation, entity_resolver:) }

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
    }
  end

  before { travel_to Time.at(1_663_187_854) }
  after { travel_back }

  it 'maps successfully' do
    expect(entity_resolver).to receive(:resolve).with(
      RegisterSourcesOc::ResolverRequest[{
        company_number: '1234567',
        jurisdiction_code: "dk",
        name: "Renamed Danish Company 1",
      }.compact],
    ).and_return RegisterSourcesOc::ResolverResponse[{
      resolved: true,
      reconciliation_response: nil,
      company_number: '1234567',
      # name: "Renamed Danish Company 1",
      company: {
        company_number: '1234567',
        jurisdiction_code: 'gb',
        name: "Foo Bar Limited",
        company_type: 'company_type',
        incorporation_date: '2020-01-09',
        dissolution_date: '2021-09-07',
        restricted_for_marketing: nil,
        registered_address_in_full: 'registered address',
        registered_address_country: "United Kingdom",
      },
    }]

    result = subject.call

    expect(result).to be_a RegisterSourcesBods::EntityStatement
    expect(result.to_h).to eq(
      {
        addresses: [
          { address: "registered address", type: "registered" },
        ],
        dissolutionDate: "2021-09-07",
        entityType: "registeredEntity",
        foundingDate: "2020-01-09",
        name: "Renamed Danish Company 1",
        identifiers: [
          {
            id: "1234567",
            scheme: "DK-CVR",
            schemeName: "Danish Central Business Register",
          },
          {
            id: "https://opencorporates.com/companies//1234567",
            schemeName: "OpenCorporates",
            uri: "https://opencorporates.com/companies//1234567",
          },
        ],
        isComponent: false,
        statementType: "entityStatement",
      },
    )
  end
end

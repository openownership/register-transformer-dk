require 'register_transformer_dk/bods_mapping/interest_parser'
require 'register_sources_dk/structs/attributter'

RSpec.describe RegisterTransformerDk::BodsMapping::InterestParser do
  subject { described_class.new }

  describe '#call' do
    context 'when type is EJERANDEL_PROCENT' do
      let(:attributter) do
        RegisterSourcesDk::Attributter[{
          "type": "EJERANDEL_PROCENT",
          "vaerdier": [
            {
              "vaerdi": "0.5"
            }
          ]
        }]
      end

      it 'returns interest' do
        expect(subject.call(attributter)).to eq(
          RegisterSourcesBods::Interest[{
            type: 'shareholding',
            share: {
              exact: 50.0,
              minimum: 50.0,
              maximum: 50.0,
            }
          }]
        )
      end
    end

    context 'when type is EJERANDEL_STEMMERET_PROCENT' do
      let(:attributter) do
        RegisterSourcesDk::Attributter[{
          "type": "EJERANDEL_STEMMERET_PROCENT",
          "vaerdier": [
            {
              "vaerdi": "0.5"
            }
          ]
        }]
      end

      it 'returns interest' do
        expect(subject.call(attributter)).to eq(
          RegisterSourcesBods::Interest[{
            type: 'voting-rights',
            share: {
              exact: 50.0,
              minimum: 50.0,
              maximum: 50.0,
            }
          }]
        )
      end
    end
  end
end

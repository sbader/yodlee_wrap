require "yodlee_wrap"

describe YodleeWrap::Response do
  let(:error_response) {
    {
      "errorCode"=>"Y402",
      "errorMessage"=>"Something went wrong here.",
      "referenceCode"=>"_3932d208-345a-400f-a273-83619b8b548b"
    }
  }

  let(:success_hash_response) {
    {}
  }

  let(:success_array_response) {
    [{}]
  }

  context 'you can access the error_code and error_message when it exists' do
    subject { YodleeWrap::Response.new error_response, 400 }
    it { is_expected.not_to be_success }
    it { is_expected.to be_fail }
    it "is expected to return the errorMessage provided by yodlee" do
      expect(subject.error_message).to eq(error_response['errorMessage'])
    end
    it "also makes the status accessible" do
      expect(subject.status).to eq 400
    end
  end

  context 'When operation is a success and returns hash' do
    subject { YodleeWrap::Response.new(success_hash_response, 200) }
    it { is_expected.to be_success }
    it { is_expected.not_to be_fail }
    it 'is expected to return nil for error' do
      expect(subject.error_code).to be_nil
    end
  end

  context 'When operation is a success and return array' do
    subject { YodleeWrap::Response.new(success_array_response, 200) }
    it { is_expected.to be_success }
    it { is_expected.not_to be_fail }
    it 'is expected to return nil for error' do
      expect(subject.error_code).to be_nil
    end
  end
end

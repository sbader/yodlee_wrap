require "spec_helper"
require "yodlee_wrap/config"

describe YodleeWrap::Config do
  describe "#base_url=" do
    it "can set value" do
      YodleeWrap::Config.cobranded_username = 'some_username'
      expect(YodleeWrap::Config.cobranded_username).to eq('some_username')
    end
  end

  describe "#cobranded_password=" do
    it "can set value" do
      YodleeWrap::Config.cobranded_password = 'some password'
      expect(YodleeWrap::Config.cobranded_password).to eq('some password')
    end
  end

  describe "#proxy_url=" do
    it "can set value" do
      YodleeWrap::Config.webhook_endpoint = 'http://someurl'
      expect(YodleeWrap::Config.webhook_endpoint).to eq('http://someurl')
    end
  end

  describe "#logger="do
    let(:logger) { Logger.new(STDOUT) }
    it "can set value" do
      YodleeWrap::Config.logger = logger
      expect(YodleeWrap::Config.logger).to eq(logger)
    end
  end

end

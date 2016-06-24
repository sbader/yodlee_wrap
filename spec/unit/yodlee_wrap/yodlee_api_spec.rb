require "yodlee_wrap"
require "yodlee_wrap/config"

describe YodleeWrap::YodleeApi do

  context 'Given a new uninitialized YodleeApi object' do
    before {
      YodleeWrap::Config.cobranded_username=nil
      YodleeWrap::Config.cobranded_password=nil
    }
    subject { YodleeWrap::YodleeApi.new }

    it 'should return nil for cobranded_auth' do
      expect(subject.cobranded_auth).to be_nil
    end

    it 'should return nil for user_auth' do
      expect(subject.user_auth).to be_nil
    end

    it 'should return nil for session_token' do
      expect(subject.cobranded_session_token).to be_nil
    end

    it 'should return nil for user_session_token' do
      expect(subject.user_session_token).to be_nil
    end
  end

  context 'Given a Yodleeicious::Config with nil configuration' do
    context 'When a new YodleeApi instance is created with no configuration' do
      before {
        YodleeWrap::Config.cobranded_username = nil
        YodleeWrap::Config.cobranded_password = nil
        YodleeWrap::Config.webhook_endpoint = nil
      }
      subject { YodleeWrap::YodleeApi.new }

      it 'no cobranded_username is set' do
        expect(subject.cobranded_username).to be_nil
      end

      it 'no cobranded_password is set' do
        expect(subject.cobranded_password).to be_nil
      end

      it 'no websocket_endpoint is set' do
        expect(subject.webhook_endpoint).to be_nil
      end

    end
  end

  context 'Given a Yodleeicious::Config with a configuration' do
    context 'When a new YodleeApi instance is created with the global configuration set' do
      before {
        YodleeWrap::Config.cobranded_username='user name'
        YodleeWrap::Config.cobranded_password='password'
        YodleeWrap::Config.webhook_endpoint='something_something'
      }
      subject { YodleeWrap::YodleeApi.new }

      it 'cobranded_username is set' do
        expect(subject.cobranded_username).to eq('user name')
      end

      it 'cobranded_password is set' do
        expect(subject.cobranded_password).to eq('password')
      end

      it 'webhook_endpoint is set' do
        expect(subject.webhook_endpoint).to eq('something_something')
      end
    end
  end

  context 'Given a Yodleeicious::Config with nil configuration' do
    context 'When a new YodleeApi instance is created and provided a configuration' do
      before {
        YodleeWrap::Config.cobranded_username = nil
        YodleeWrap::Config.cobranded_password = nil
        YodleeWrap::Config.webhook_endpoint = nil
      }
      let(:config) {
        {
          cobranded_username: "some_username",
          cobranded_password: "some_password",
          webhook_endpoint: "something/something"
        }
      }

      subject { YodleeWrap::YodleeApi.new(config) }

      it 'the provided cobranded_username is set' do
        expect(subject.cobranded_username).to eq(config[:cobranded_username])
      end

      it 'the provided cobranded_password is set' do
        expect(subject.cobranded_password).to eq(config[:cobranded_password])
      end

      it 'the provided proxy_url is set' do
        expect(subject.webhook_endpoint).to eq(config[:webhook_endpoint])
      end
    end
  end

  context 'Given a Yodleeicious::Config with set config values' do
    context 'When a new YodleeApi instance is created and provided a configuration' do
      before {
        YodleeWrap::Config.cobranded_username = 'user name'
        YodleeWrap::Config.cobranded_password = 'password'
        YodleeWrap::Config.webhook_endpoint = 'socks5h://somehostname'
      }
      let(:config) {
       {
         cobranded_username: "some_username",
         cobranded_password: "some_password",
         webhook_endpoint: "socks5h://127.0.0.1:1080"
       }
      }

      subject { YodleeWrap::YodleeApi.new(config) }


      it 'the provided cobranded_username is set' do
        expect(subject.cobranded_username).to eq(config[:cobranded_username])
      end

      it 'the provided cobranded_password is set' do
        expect(subject.cobranded_password).to eq(config[:cobranded_password])
      end

      it 'the provided proxy_url is set' do
        expect(subject.webhook_endpoint).to eq(config[:webhook_endpoint])
      end
    end
  end

  context 'Given a Yodleeicious::Config with nil config values' do
    context 'When a new YodleeApi instance is configured with no proxy_url' do
      before {
        YodleeWrap::Config.cobranded_username=nil
        YodleeWrap::Config.cobranded_password=nil
        YodleeWrap::Config.webhook_endpoint = nil
      }
      let(:config) {
        {
          cobranded_username: "some_username",
          cobranded_password: "some_password"
        }
      }

      subject { YodleeWrap::YodleeApi.new(config) }

      it 'no webhook_endpoint is set' do
        expect(subject.webhook_endpoint).to be_nil
      end
    end
  end

  # describe '#should_retry_get_mfa_response?' do
  #   let (:api) { YodleeWrap::YodleeApi.new }
  #   let (:response) { instance_double("YodleeWrap::Response") }
  #
  #   context 'Given get mfa response has failed' do
  #     before { allow(response).to receive(:success?).and_return(false) }
  #     before { allow(response).to receive(:body).and_return({}) }
  #     subject { api.should_retry_get_mfa_response?(response,0,1) }
  #     it { is_expected.to be_falsy }
  #   end
  #
  #   context 'Given get mfa response is success' do
  #     before { allow(response).to receive(:success?).and_return(true) }
  #
  #     context 'Given an error code is returned' do
  #       before { allow(response).to receive(:body).and_return({ 'errorCode' => 100 }) }
  #       subject { api.should_retry_get_mfa_response?(response,0,1) }
  #       it { is_expected.to be_falsy }
  #     end
  #
  #     context 'Given no error code is returned' do
  #       context 'Given the MFA message is available' do
  #         before { allow(response).to receive(:body).and_return({ 'isMessageAvailable' => true }) }
  #         subject { api.should_retry_get_mfa_response?(response,0,1) }
  #         it { is_expected.to be_falsy }
  #       end
  #
  #       context 'Given the MFA message is not available' do
  #         before { allow(response).to receive(:body).and_return({ 'isMessageAvailable' => false }) }
  #         context 'Given all the trys have been used up' do
  #           subject { api.should_retry_get_mfa_response?(response,1,1) }
  #           it { is_expected.to be_falsy }
  #         end
  #
  #         context 'Given the trys have not been used up' do
  #           subject { api.should_retry_get_mfa_response?(response,0,2) }
  #           it { is_expected.to be_truthy }
  #         end
  #       end
  #     end
  #   end
  # end

  # describe '#should_retry_get_site_refresh_info' do
  #   let (:api) { YodleeWrap::YodleeApi.new }
  #   let (:response) { double("response") }
  #
  #   context 'Given get mfa response has failed' do
  #     before { allow(response).to receive(:success?).and_return(false) }
  #     subject { api.should_retry_get_site_refresh_info?(response,0,1) }
  #     it { is_expected.to be_falsy }
  #   end
  #
  #   context 'Given get mfa response is success' do
  #     before { allow(response).to receive(:success?).and_return(true) }
  #
  #     context 'Given an code 801 is returned' do
  #       before { allow(response).to receive(:body).and_return({ 'code' => 801 }) }
  #       subject { api.should_retry_get_site_refresh_info?(response,0,1) }
  #       it { is_expected.to be_truthy }
  #     end
  #
  #     context 'Given not 801 and not 0 code is returned' do
  #       before { allow(response).to receive(:body).and_return({ 'code' => 5 }) }
  #       subject { api.should_retry_get_site_refresh_info?(response,0,1) }
  #       it { is_expected.to be_falsy }
  #     end
  #
  #     context 'Given a code 0 is returned' do
  #       context 'Given a siteRefreshStatus of REFRESH_COMPLETED' do
  #         before { allow(response).to receive(:body).and_return({ 'code' => 0, "siteRefreshStatus" => { "siteRefreshStatus" => "REFRESH_COMPLETED" }}) }
  #         subject { api.should_retry_get_site_refresh_info?(response,0,1) }
  #         it { is_expected.to be_falsy }
  #       end
  #
  #       context 'Given a siteRefreshStatus of REFRESH_TIMED_OUT' do
  #         before { allow(response).to receive(:body).and_return({ 'code' => 0, "siteRefreshStatus" => { "siteRefreshStatus" => "REFRESH_TIMED_OUT" }}) }
  #         subject { api.should_retry_get_site_refresh_info?(response,0,1) }
  #         it { is_expected.to be_falsy }
  #       end
  #
  #       context 'Given a siteRefreshStatus of LOGIN_SUCCESS' do
  #         before { allow(response).to receive(:body).and_return({ 'code' => 0, "siteRefreshStatus" => { "siteRefreshStatus" => "LOGIN_SUCCESS" }}) }
  #         subject { api.should_retry_get_site_refresh_info?(response,0,1) }
  #         it { is_expected.to be_falsy }
  #       end
  #
  #       context 'Given a siteRefreshStatus of REFRESH_TRIGGERED' do
  #         before { allow(response).to receive(:body).and_return({ 'code' => 0, "siteRefreshStatus" => { "siteRefreshStatus" => "REFRESH_TRIGGERED" }}) }
  #         subject { api.should_retry_get_site_refresh_info?(response,0,1) }
  #         it { is_expected.to be_truthy }
  #       end
  #
  #       context 'Given a siteRefreshStatus of REFRESH_TRIGGERED' do
  #         before { allow(response).to receive(:body).and_return({ 'code' => 0, "siteRefreshStatus" => { "siteRefreshStatus" => "REFRESH_TRIGGERED" }}) }
  #         context 'Given trys have been used up' do
  #           subject { api.should_retry_get_site_refresh_info?(response,1,1) }
  #           it { is_expected.to be_falsy }
  #         end
  #       end
  #     end
  #   end
  # end
end

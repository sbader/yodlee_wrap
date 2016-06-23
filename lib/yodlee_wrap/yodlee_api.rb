require 'json'

module YodleeWrap
  class YodleeApi
    attr_reader :base_url, :cobranded_username, :cobranded_password, :proxy_url,
                :logger, :cobranded_auth, :user_auth, :cobrand_name, :webhook_endpoint

    def initialize(config = {})
      configure(config)
    end

    def configure(config = {})
      validate(config)
      @cobrand_name = config[:cobrand_name] || YodleeWrap::Config.cobrand_name || 'restserver'
      @cobranded_username = config[:cobranded_username] || YodleeWrap::Config.cobranded_username
      @cobranded_password = config[:cobranded_password] || YodleeWrap::Config.cobranded_password
      @webhook_endpoint = config[:webhook_endpoint] || YodleeWrap::Config.webhook_endpoint
      @logger = config[:logger] || YodleeWrap::Config.logger

      info_log "YodleeApi configured with base_url=#{base_url} cobranded_username=#{cobranded_username} logger=#{logger}"
    end

    def validate(config)
      [:cobranded_username, :cobranded_password, :logger].each do |key|
        if config.key?(key) && config[key].nil?
          fail 'Invalid config provided to YodleeApi. Values may not be nil/blank.'
        end
      end
    end

    def cobranded_login
      params = {
        cobrandParam: {
          cobrand: {
            cobrandLogin: cobranded_username,
            cobrandPassword: cobranded_password
          }
        }
      }
      response = execute_api '/v1/cobrand/login', params

      @cobranded_auth = response.success? ? response.body : nil

      response
    end

    def user_params(username, password)
      {
        userParam: {
          user: {
            loginName: username,
            password: password,
            locale: 'en_US'
          }
        }
      }
    end

    def user_login(username:, password:)
      params = user_params(username, password)
      response = cobranded_session_execute_api('/v1/user/login', params)
      @user_auth = response.success? ? response.body : nil
      response
    end

    def register_user(username:, password:, options: {}, subscribe: true)
      params = user_params(username, password).merge(options)
      response = cobranded_session_execute_api('/v1/user/register', params)
      @user_auth = response.success? ? response.body : nil
      subscribe_user_to_refresh if response.success? && subscribe
      response
    end

    # subscribe user to webhook refresh notifications
    def subscribe_user_to_refresh
      params = {
        event: {
          callbackUrl: webhookEndpoint
        }
      }
      user_session_execute_api('v1/cobrand/config/notifications/events/REFRESH', params)
    end

    def unregister_user
      response = user_session_execute_api('v1/user/unregister')
      @user_auth = nil if response.success?
    end

    def logout_user
      user_session_execute_api('/v1/user/logout')
    end

    def login_or_register_user(username:, password:, subscribe: true)
      info_log "Attempting to log in #{username}"
      response = user_login(username: username, password: password)

      # TODO: look into what other errors could occur here
      if response.fail? && response.error_code == 'Y002'
        info_log "Invalid credentials for #{username}. Attempting to register"
        response = register_user(username: username, password: password, subscribe: subscribe)
      else
        info_log response.error_message
      end

      @user_auth = response.success? ? response.body : nil

      response
    end

    def get_provider_details(provider_id)
      user_session_execute_api("/v1/providers/#{provider_id}")
    end

    def add_provider_account(provider_id, provider_params)
      user_session_execute_api("v1/providers/#{provider_id}", provider_params)
    end

    def delete_provider_account(provider_account_id)
      user_session_execute_api("v1/providers/providerAccounts/#{provider_account_id}")
    end

    # After an account has been added, use the returned provider_account_id
    # to get updates about the provider account.
    def get_provider_account_status(provider_account_id)
      user_session_execute_api("v1/providers/#{provider_account_id}")
    end

    def update_provider_account(provider_account_id, provider_params)
      user_session_execute_api("v1/providers/providerAccounts?providerAccountIds=#{provider_account_id}", provider_params)
    end

    def cobranded_session_execute_api(uri, params = {})
      params = {
        Authorization: {
          cobSession: cobranded_session_token
        }
      }.merge(params)

      execute_api(uri, params)
    end

    def user_session_execute_api(uri, params = {})
      params = {
        userSessionToken: user_session_token
      }.merge(params)

      cobranded_session_execute_api(uri, params)
    end

    def execute_api(uri, params = {})
      debug_log "calling #{uri} with #{params}"
      ssl_opts = { verify: false }
      connection = Faraday.new(url: base_url, ssl: ssl_opts, request: { proxy: proxy_opts })
      params = { cobrandName: cobrandName }.merge(params)

      response = connection.post("#{base_url}#{uri}", params)
      debug_log "response=#{response.status} success?=#{response.success?} body=#{response.body}"

      Response.new(JSON.parse(response.body)) if response.status == 200
    end

    def cobranded_session_token
      return nil if cobranded_auth.nil?
      cobranded_auth.fetch('session', {}).fetch('cobSession', nil)
    end

    def user_session_token
      return nil if user_auth.nil?
      user_auth.fetch('session', {}).fetch('userSession', nil)
    end

    def debug_log(msg)
      logger.debug(msg)
    end

    def info_log(msg)
      logger.info(msg)
    end

    def base_url
      "https://developer.api.yodlee.com/ysl/#{cobrand_name}"
    end
  end
end

require 'json'
require 'byebug'

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
      info_log "YodleeApi configured with cobrand_name=#{cobrand_name} cobranded_username=#{cobranded_username} logger=#{logger}"
    end

    def validate(config)
      [:cobrand_name, :cobranded_username, :cobranded_password, :logger].each do |key|
        if config.key?(key) && config[key].nil?
          fail 'Invalid config provided to YodleeApi. Values may not be nil/blank.'
        end
      end
    end

    def cobranded_login
      params = {
        cobrand: {
          cobrandLogin: cobranded_username,
          cobrandPassword: cobranded_password,
          locale: "en_US"
        }
      }
      response = execute_api(:post, '/v1/cobrand/login', params)

      @cobranded_auth = response.success? ? response.body : nil

      response
    end

    def user_params(username, password, email)
      {
        user: {
          loginName: username,
          email: email,
          password: password,
          locale: 'en_US'
        }
      }
    end

    def login_user(username:, password:)
      params = user_params(username, password, nil)
      response = cobranded_session_execute_api(:post, '/v1/user/login', params)
      @user_auth = response.success? ? response.body : nil
      response
    end

    def register_user(username:, password:, email:, options: {}, subscribe: true)
      params = user_params(username, password, email).merge(options)
      response = cobranded_session_execute_api(:post, '/v1/user/register', params)
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
      user_session_execute_api(:post, 'v1/cobrand/config/notifications/events/REFRESH', params)
    end

    def unregister_user
      response = user_session_execute_api(:delete, 'v1/user/unregister')
      @user_auth = nil if response.success?
    end

    def logout_user
      user_session_execute_api(:post, '/v1/user/logout')
    end

    def login_or_register_user(username:, password:, email:, subscribe: true)
      info_log "Attempting to log in #{username}"
      response = login_user(username: username, password: password)
      # TODO: look into what other errors could occur here
      if response.fail? && response.error_code == 'Y002'
        info_log "Invalid credentials for #{username}. Attempting to register"
        response = register_user(username: username, password: password, email: email, subscribe: subscribe)
      else
        info_log response.error_message
      end
      @user_auth = response.success? ? response.body : nil

      response
    end

    def get_transactions
      user_session_execute_api(:get, "/v1/transactions")
    end

    def get_provider_details(provider_id)
      user_session_execute_api(:get, "/v1/providers/#{provider_id}")
    end

    def add_provider_account(provider_id, provider_params)
      user_session_execute_api(:post, "/v1/providers/providerAccounts?providerId=#{provider_id}", provider_params)
    end

    def delete_provider_account(provider_account_id)
      user_session_execute_api(:delete, "/v1/providers/providerAccounts/#{provider_account_id}")
    end

    # After an account has been added, use the returned provider_account_id
    # to get updates about the provider account.
    # default to getting mfa questions if they are available.
    def get_provider_account_status(provider_account_id)
      user_session_execute_api(:get, "/v1/providers/providerAccounts/#{provider_account_id}?include=credentials")
    end

    # Get all provider accounts for the currently logged in user.
    def get_all_provider_accounts
      user_session_execute_api(:get, '/v1/providers/providerAccounts')
    end

    def get_statements
      user_session_execute_api(:get, '/v1/statements')
    end

    def update_provider_account(provider_account_id, provider_params)
      user_session_execute_api(:put, "/v1/providers/providerAccounts?providerAccountIds=#{provider_account_id}", provider_params)
    end

    def cobranded_session_execute_api(method, url, params = {})
      execute_api(method, url, params, cobranded_auth_header)
    end

    def user_session_execute_api(method, url, params = {})
      execute_api(method, url, params, user_auth_header)
    end

    def cobranded_auth_header
      "cobSession=#{cobranded_session_token}"
    end

    def user_auth_header
      cobranded_auth_header + ",userSession=#{user_session_token}"
    end

    def execute_api(method, url, params, auth_header = "")
      debug_log "calling #{url} with #{params}"
      ssl_opts = { verify: false }
      connection = Faraday.new(url: base_url, ssl: ssl_opts, request: { proxy: [] })
      response = connection.send(method) do |request|
        request.url "#{base_url}#{url}"
        request.headers['Authorization'] = auth_header
        request.body = params.to_json unless params.empty?
        request.headers['Content-Type'] = 'application/json' unless params.empty?
      end
      debug_log "response=#{response.status} success?=#{response.success?} body=#{response.body}"
      body = JSON.parse(response.body) if response.body
      Response.new(body, response.status)
    end

    def cobranded_session_token
      return nil if cobranded_auth.nil?
      cobranded_auth.fetch('session', {}).fetch('cobSession', nil)
    end

    def user_session_token
      return nil if user_auth.nil?
      user_auth.fetch('user', {}).fetch('session', {}).fetch('userSession')
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

module YodleeWrap
  class Response
    attr_accessor :body, :status, :error_code, :error_message

    def initialize(body, status)
      @body = body
      @status = status
      @error_code = body.fetch('errorCode') if fail?
      @error_message = body.fetch('errorMessage') if fail?
    end

    def success?
      !fail?
    end

    def fail?
      body.is_a?(Hash) && !(body.fetch('errorCode', nil)).nil?
    end

    # Determine if the PROVIDER has mfa
    def mfa?
      if body.is_a?(Hash) && body['provider'] && body['provider'].length == 1
        body['provider'].first['mfaType'].present?
      end
    end

    def mfa_type
      return nil unless body['provider']
      body['provider'].first['mfaType'] if mfa?
    end

    def refresh_status
      return nil unless body['providerAccount']
      body['providerAccount']['refreshInfo']['status']
    end

    def additional_status
      return nil unless body['providerAccount']
      body['providerAccount']['refreshInfo']['additionalStatus']
    end

    def add_in_progress?
      return false unless body['providerAccount']
      refresh_status == 'IN_PROGRESS' && additional_status == 'USER_INPUT_REQUIRED'
    end

    def mfa_available?
      return false unless body['providerAccount']
      body['providerAccount']['loginForm'] && body['providerAccount']['loginForm']['formType'] != 'login'
    end

    def add_successful?
      return false unless body['providerAccount']
      ['SUCCESS', 'PARTIAL_SUCCESS'].include? refresh_status
    end

    def add_failed?
      return false unless body['providerAccount']
      refresh_status == 'FAILED'
    end

    def provider_account_id
      return nil unless body['providerAccount']
      body['providerAccount']['id']
    end
  end
end

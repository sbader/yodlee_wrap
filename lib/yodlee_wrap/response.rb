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

    def mfa?
      if body.is_a?(Hash) && body['provider'] && body['provider'].length == 1
        body['provider'].first['mfaType']
      end
    end

    def mfa_type
      body['provider'].first['mfaType'] if mfa?
    end
  end
end

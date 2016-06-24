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
  end
end

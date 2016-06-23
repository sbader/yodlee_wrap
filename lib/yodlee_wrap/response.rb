module YodleeWrap
  class Response
    attr_accessor :body

    def initialize(body)
      @body = body
    end

    def success?
      !fail?
    end

    def fail?
      body.is_a?(Hash) && (body.fetch('errorCode'))
    end

    def error_code
      body.fetch('errorCode') if fail?
    end

    def error_message
      body.fetch('errorMessage') if fail?
    end
  end
end

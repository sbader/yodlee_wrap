

module YodleeWrap
  class Config
    class << self
      attr_accessor :cobranded_username, :cobrand_name, :cobranded_password,
                    :proxy_url, :logger, :webhook_endpoint
    end

    self.logger = Logger.new(STDOUT)
    self.logger.level = Logger::WARN

  end
end

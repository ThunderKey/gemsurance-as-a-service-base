class ApplicationService
  include GaasHelper

  mattr_accessor :logger
  self.logger = Rails.logger
  def logger() self.class.logger; end
end

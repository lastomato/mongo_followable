module Mongo
  CONFIG = { :authorization => false, :history => false }

  class Railtie < Rails::Railtie
    config.after_initialize do
      CONFIG.merge!(Rails.application.config.mongo_followable) if Rails.application.config.respond_to?(:mongo_followable)
    end
  end
end
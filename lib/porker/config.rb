require 'singleton'
require 'logger'
require 'redis'

module Porker
  class Config
    include Singleton

    attr_accessor :dir, :env, :logger, :store

    @@defaults = {
      env: 'production',
      dir: '/u/beau/porker/current',
      logger: Logger.new("./log/porker.log"),
      store: Redis.new(:db => 1)
    }

    def self.defaults
      @@defaults
    end

    def initialize
      reset
    end

    def reset
      @@defaults.each_pair { |k, v| send("#{k}=", v) }
    end
  end
end

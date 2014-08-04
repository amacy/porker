require "porker/version"

module Porker
  autoload :Bot,        'porker/bot'
  autoload :Markovator, 'porker/markovator'
  autoload :Config,     'porker/config'

  def self.env
    config.env
  end

  def self.dir
    config.dir
  end

  def self.logger
    config.logger
  end

  def self.store
    config.store
  end

  def self.config
    Config.instance
  end
end

require "porker/version"

module Porker
  autoload :Bot,        'porker/bot'
  autoload :Markovator, 'porker/markovator'
  autoload :Config,     'porker/config'
  autoload :Library,    'porker/library'
  autoload :Sentence,   'porker/sentence'
  autoload :Transition, 'porker/transition'
  autoload :Word,       'porker/word'

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

require 'cinch'

module Porker
  class Bot < Cinch::Bot
    def self.create
      new do
        configure do |c|
          pass = "#{ENV['PORKER_USERNAME']} #{ENV['PORKER_PASSWORD']}"
          c.port     = 6697
          c.ssl.use  = true #Porker.env == 'production'
          c.server   = Porker.env == 'production' ? "irc.flowdock.com" : "irc.freenode.net"
          c.password = Porker.env == 'production' ? pass : "thebananaistasty"
          c.nick     = Porker.env == 'production' ? "porker" : "porkr"
          c.channels = Porker.env == 'production' ? [] : []
        end

        on :channel, '!threshold' do |m|
          threshold = m.message.split(' ')[1]
          Porker.config.threshold = threshold.to_f
        end

        on :channel, /shut.*pork/ do |m|
          m.reply "I'll shut up"
          Porker.config.threshold = 1
        end

        on :channel, /^[^!]/ do |m|
          if Porker.config.threshold < 1
            response = Porker::Markovator.respond(m.message, false)
            m.reply response unless response.nil?
          end

          Porker::Markovator.store(m.message)
        end

        on :private, "!reset" do |m|
          Porker::Library.clear!
        end
      end
    end

  end
end

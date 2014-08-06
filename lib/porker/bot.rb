require 'cinch'

module Porker
  class Bot < Cinch::Bot

    HELP_TEXT = <<-HELP
I'm glad that you can admit that you are an idiot, idiot
!op               Make yourself operator
!porker           Me talk pretty one day
!porker <subject> Me talk pretty bout <subject>
HELP

    def self.create
      new do

        if Porker.env == 'production'
          # @logger = Cinch::Logger::NullLogger.new
        end

        configure do |c|
          pass = "#{ENV['PORKER_USERNAME']} #{ENV['PORKER_PASSWORD']}"
          c.port     = 6697
          c.ssl.use  = true #Porker.env == 'production'
          c.server   = Porker.env == 'production' ? "irc.flowdock.com" : "irc.freenode.net"
          c.password = Porker.env == 'production' ? pass : "thebananaistasty"
          c.nick     = Porker.env == 'production' ? "porker" : "porkr"
          c.channels = Porker.env == 'production' ? [] : []
        end

        on :channel, "!help" do |m|
          m.user.send HELP_TEXT
        end

        on :channel, ["!op","!ops"] do |m|
          m.channel.op(m.user)
        end

        on :channel, /^[^!]/ do |m|
          response = Porker::Markovator.respond(m.message, false, 0.9)
          m.reply response unless response.nil?
          Porker::Markovator.store(m.message)
        end

        on :private, "!redeploy" do |m|
          Porker.logger.info "#{m.user.nick} asked for a redeploy..."
          `cd #{Porker.config.dir} && git pull --rebase && kill #{$$} && bundle exec ./script/start production &`
          exit
        end

        on :channel, "!reset" do |m|
          Porker::Transition.clear!
        end

        on :channel, /^!(markov|porker)/ do |m|
          message = m.message.strip
          if ["!markov","!porker"].include?(m)
            m.reply Porker::Markovator.respond
          else
            m.reply Porker::Markovator.command(message)
          end
        end

      end
    end

  end
end

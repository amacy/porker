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
          @logger = Cinch::Logger::NullLogger.new
        end

        configure do |c|
          c.server   = Porker.env == 'production' ? "irc.colo" : "mjw.dev"
          c.ssl      = false
          c.port     = 6697
          c.password = "thebananaistasty"
          c.nick     = Porker.env == 'production' ? "porker" : "porkie"
          c.channels = Porker.env == 'production' ? ["#sfops","#doa","#trojan"] : ["#testingzone"]
        end

        on :channel, "!help" do |m|
          m.user.send HELP_TEXT
        end

        on :channel, ["!op","!ops"] do |m|
          m.channel.op(m.user)
        end

        on :channel, /^[^!]/ do |m|
          Porker::Markovator.store(m.message)
          response = Porker::Markovator.respond(m.message)
          m.reply response unless response.nil?
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

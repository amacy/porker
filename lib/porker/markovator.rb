module Porker
  class Markovator
    class << self

      def store(line)
        previous_word = Word.start
        line.strip.split(' ').each do |text|
          word = Word.new(text)

          if word.invalid?
            previous_word = Word.start
            next
          end

          word.follows previous_word
          previous_word = word
        end

        previous_word.preceeds Word.end unless previous_word == Word.start
      end

      def command(seed)
        word = seed.split[1]
        Porker::Markovator.respond(word)
      end

      def respond(seed = nil, always_return_sentence = false)
        Porker.logger.info("Heard: #{seed}")
        always_return_sentence = true if seed.split.include?('pork')
        word = Word.new((seed && seed.split.sample) || Transition.seed)
        return Sentence.failure if word.blank?

        sentence = Sentence.new(word)
        # make sure this word isn't a dead end
        followup = Transition.next(word, true)
        if followup.blank? || followup.end?
          if seed.nil? || seed == ''
            followup.never_follows word  #repair corpus
          end

          if seed.nil? || seed == '' || always_return_sentence
            return respond # try again
          else
            Porker.logger.info("Only one word response, not good enough. #{sentence}")
            return Sentence.failure
          end
        end

        # ok, we've got two words, that's a decent showing.
        sentence << followup
        word = followup
        while sentence.incomplete?
          word = Transition.next(word)
          break if word == Word.end
          sentence << word
        end

        Porker.logger.info "I am #{sentence.confidence} confident I want to say: #{sentence}"
        return unless sentence.confidence > Porker.config.threshold
        sentence.to_s
      end
    end
  end
end

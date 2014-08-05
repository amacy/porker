module Porker
  class Markovator

    MAXIMUM_SENTENCE_LENGTH  = 50

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
        true
      end

      def command(seed)
        word = seed.split[1]
        Porker::Markovator.respond(word)
      end

      def respond(seed = nil, always_return_sentence = false)
        word = Word.new((seed && seed.split.sample) || Transition.seed)
        return Sentence.failure if word.blank?

        sentence = Sentence.new(word)
        # make sure this word isn't a dead end
        second_word = Transition.next(word, true)
        if second_word.blank?
          second_word.never_follows word if (seed == '' || seed.nil?) #repair corpus

          if (seed == '' || seed.nil?) || always_return_sentence
            return respond # try again
          else
            return Sentence.failure
          end
        end

        # ok, we've got two words, that's a decent showing.
        sentence << second_word
        while sentence.length < MAXIMUM_SENTENCE_LENGTH
          word = Transition.next(word)

          # if that word ends the sentence, no more words
          break if word == Word.end
          sentence << word
        end

        Porker.logger.info "I am #{sentence.confidence} confident I want to say: #{sentence}"
        return unless sentence.confidence > 1
        sentence.to_s
      end
    end
  end
end

module Porker
  class Markovator

    BEGIN_TOKEN              = "__BEGIN__"
    END_TOKEN                = "__END__"
    SENTENCE_FAILURE_MESSAGE = "no u"
    MAXIMUM_SENTENCE_LENGTH  = 50

    class << self

      def store(line)
        previous_word = BEGIN_TOKEN
        line.strip.split(' ').each do |word|
          word = word.strip.gsub(/[?!,.]$/,'')

          # act like we're starting on a new line if we've hit wacky punctuation.
          if word =~ /[^a-zA-Z0-9\'_-]/ || (word.nil? || word == '')
            previous_word = BEGIN_TOKEN
            next
          end

          # +1 to previous_word -> word
          increment_transition(previous_word, word)

          previous_word = word
        end

        # last word ended the sentence, so get rid of it.
        increment_transition(previous_word, END_TOKEN) unless previous_word == BEGIN_TOKEN

        true
      end

      def command(message)
        word = message.split[1]
        Porker::Markovator.sentence(word)
      end

      def sentence(given_first_word=nil, always_return_sentence=false)
        # try to assign a first word
        first_word = given_first_word || random_transition_for_word(BEGIN_TOKEN,true)

        return SENTENCE_FAILURE_MESSAGE if (first_word.nil? || first_word == '')

        # make sure this word isn't a dead end
        second_word = random_transition_for_word(first_word,true)
        if (second_word.nil? || second_word == '')
          # self-repair
          delete_transition(first_word, second_word) if (given_first_word.nil? || given_first_word == '')

          # try again
          if (given_first_word.nil? || given_first_word == '') || always_return_sentence
            return sentence
          else
            return SENTENCE_FAILURE_MESSAGE
          end
        end

        # ok, we've got two words, that's a decent showing.
        sentence_words = [first_word, second_word]

        word = second_word

        while sentence_words.length < MAXIMUM_SENTENCE_LENGTH
          # get a random word
          word = random_transition_for_word(word)

          # if that word ends the sentence, no more words
          if word == END_TOKEN
            break
          else
            sentence_words << word
          end
        end
        sentence_words.join(' ')
      end

      private

      def random_transition_for_word(word, exclude_end_token=false)
        unhashed_zset = Porker.store.zrange("porker/markovator/words/#{word}", 0, -1, :with_scores => true)

        candidates = {}
        (unhashed_zset.length/2).times do |n|
          word_i = n*2; score_i = word_i+1
          z_word, z_score = unhashed_zset[word_i], unhashed_zset[score_i].last.to_i
          next if exclude_end_token && z_word == END_TOKEN
          candidates[z_word] = z_score
        end

        Porker.logger.info "Candidates for #{word}: #{candidates.keys.join(",")}"

        if !exclude_end_token && (candidates.nil? || candidates == '')
          Porker.logger.warn "No candidates for word: #{word} (not even #{END_TOKEN})"
          return END_TOKEN
        end

        weighted_randoms = candidates.collect {|k,v| [k] * v.to_i }.flatten
        weighted_randoms[rand(weighted_randoms.length)]
      end

      def increment_transition(word, next_word)
        Porker.store.zincrby("porker/markovator/words/#{word}", 1, next_word)
      end

      def delete_transition(word, next_word)
        Porker.store.zrem("porker/markovator/words/#{word}", next_word)
      end

    end
  end
end

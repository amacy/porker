module Porker
  class Sentence
    attr_reader :words

    MAXIMUM_SENTENCE_LENGTH = 50

    def initialize(words = [])
      @words = [*words] || []
    end

    def <<(word)
      @words << word
    end

    def length
      words.length
    end

    def incomplete?
      !complete? && length < MAXIMUM_SENTENCE_LENGTH
    end

    def complete?
      words.include?('__END__')
    end

    def confidence
      selected = 0; possible = 0;
      words.each do |word|
        selected += word.confidence || 1
        possible += word.pool || 1
      end
      selected / possible.to_f
    end

    def to_s
      words.join(' ')
    end

    def self.failure
      Porker.logger.info('no u')
      nil
    end

  end
end

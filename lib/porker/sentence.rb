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
      score = 0
      words.each{|word| score += word.confidence.to_i }
      score / words.length.to_f
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

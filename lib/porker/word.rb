module Porker
  class Word
    attr_reader :text, :confidence

    def initialize(text, confidence = nil)
      @text = text.to_s.strip.gsub(/[?!,.]$/,'')
      @confidence = confidence
    end

    def self.start
      new('__BEGIN__')
    end

    def self.end
      new('__END__')
    end

    def self.first(seed)
      new(seed || Transition.next(Word.start, true))
    end

    def preceeds(word)
      Transition.increment(self, word)
    end

    def follows(word)
      Transition.increment(word, self)
    end

    def never_follows(word)
      Transition.delete(word, self)
    end

    def invalid?
      text =~ /[^a-zA-Z0-9\'_-]/ || blank?
    end

    def blank?
      text.nil? || text == ''
    end

    def to_s
      text
    end

    def ==(word)
      text == word.text
    end
  end
end

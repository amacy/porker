module Porker
  class Word
    attr_reader :text, :confidence, :pool

    def initialize(text, confidence = nil, pool = nil)
      @text = text.to_s.strip.gsub(/[?!,.]$/,'')
      @confidence = confidence
      @pool = pool
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

    def end?
      text == '__END__'
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
      if word.is_a?(Word)
        text == word.text
      else
        text == word
      end
    end
  end
end

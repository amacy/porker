module Porker
  class Transition
    attr_reader :word, :range, :exclude_end

    def initialize(word, exclude_end_token=false)
      @word = word
      @exclude_end = exclude_end_token
    end

    def self.seed
      Transition.next Word.start, true
    end

    def self.next(seed, exclude_end_token=false)
      new(seed, exclude_end_token).next
    end

    def next
      Porker.logger.info "#{word}:#{word.confidence}:#{word.pool} - #{ candidates.map{|k,v| "#{k}:#{v}" } }"

      if !exclude_end && (candidates.empty?)
        Porker.logger.warn "No candidates for word: #{word} (not even #{Word.end})"
        return Word.end
      end

      weighted_randoms = candidates.collect{|k,v| [k] * v.to_i }.flatten
      selected = weighted_randoms[rand(weighted_randoms.length)]
      Word.new selected, candidates[selected], weighted_randoms.length
    end

    def self.increment(word, next_word, amount = 1)
      Porker.store.zincrby("porker/markovator/words/#{word.text}", amount, next_word.text)
    end

    def self.delete(word, next_word)
      Porker.store.zrem("porker/markovator/words/#{word.text}", next_word.text)
    end

    def self.clear!
      Porker.store.flushdb
    end

    private

    def candidates
      @candidates ||= begin
        options = {}
        range.each do |candidate, weight|
          weight_class = options[weight] || []
          weight_class << candidate
          options[weight] = weight_class
        end

        filter = {}
        options.keys.sort{|x,y| y <=> x }.first(10).each do |weight|
          options[weight].each do |candidate|
            filter = filter.merge(candidate => weight)
          end
        end
        filter
      end
    end

    def range
      @range ||= Porker.store.zrange("porker/markovator/words/#{word.text}", 0, -1, :with_scores => true)
    end
  end
end

require 'epub/parser'
require 'json'
require 'porker'

module Porker
  class Library
    def self.import_epub(path)
      book = EPUB::Parser.parse(path)

      book.spine.items.each do |document|
        page = document.content_document.nokogiri
        page.text.split("\n").each do |content|
          line = content.strip.gsub('"','')
          next if line.length < 1
          next if line == book.metadata.title
          next if line.include?('{')
          next if line[0] == '?'

          content.split('.').each do |sentence|
            Porker.logger.info("I: #{sentence}")
            Porker::Markovator.store(sentence)
          end
        end
      end
      true
    end

    def self.import_pdb(path)
      data = JSON.parse File.open(path).read
      data.each_pair do |key, candidates|
        word = Word.new(key)
        candidates.each do |text, amount|
          transition = Word.new(text)
          Transition.increment(word, transition, amount)
        end
      end
    end

    def self.export(path)
      data = {}
      Porker.store.keys.each do |key|
        word = key.split('/').last
        series = Porker.store.zrange(key, 0, -1, :with_scores => true)

        probabilities = {}
        series.each{|text, n| probabilities[text] = n }
        data[word] = probabilities
      end

      File.open(path, 'w') {|file| file.write(data.to_json) }
    end

    def self.clear!
      Porker.store.flushdb
    end
  end
end

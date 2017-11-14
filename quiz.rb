#!/usr/bin/env ruby -Eutf-8:utf-8

require 'open-uri'

class Verse < Struct.new(:text, :ref, :duff_chapter)
  def english_url
    "http://labs.bible.org/api/?passage=#{ref.sub(' ', '+')}"
  end

  def english
    @english ||= open(english_url).read.chomp
  end

  def text_monotonic
    #FIXME: should remove breathing marks and iota subscripts first
    text.unicode_normalize(:nfd).gsub(/\p{In Combining Diacritical Marks}+/, "\u0301")
  end

  def say_text
    #FIXME: try espeak as well as Mac's say
    `say -v Melina "#{text_monotonic}"`
  end
end

class Quiz
  attr_reader :verses, :chapter, :chapter_starts

  def initialize
    @verses = []
    @chapter = 0
    @chapter_starts = {1 => 0, 2 => 0}

    File.read('reader_duff.md').each_line do |line|
      case line
      when /^## (\d+)/
        @chapter = $1.to_i
        @chapter_starts[chapter] = @verses.length
      when /^* (.*?) \((.*?)\)/
        @verses << Verse.new($1, $2, @chapter)
      end
    end
  end

  def self.instance
    @instance ||= new
  end

  def random_verse(max_chapter)
    verses[rand(chapter_starts[max_chapter + 1])]
  end
end

if __FILE__ == $0

  max_chapter = (ARGV[0] || 6).to_i
  quiz = Quiz.instance

  puts "Use Ctrl+C or Ctrl+Break to quit."
  loop do
    verse = quiz.random_verse(max_chapter)
    prompt, answer = verse.text, verse.english
    direction = rand < 0.5 ? :en_el : :el_en
    prompt, answer = answer, prompt if direction == :en_el
    puts prompt
    print '> '
    verse.say_text if direction == :el_en
    STDIN.gets
    puts answer
    verse.say_text if direction == :en_el
    puts
  end
end

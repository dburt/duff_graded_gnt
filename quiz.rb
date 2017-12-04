#!/usr/bin/env ruby -Eutf-8:utf-8

require 'open-uri'

class Verse < Struct.new(:text, :ref, :duff_chapter, :id)
  def english_url
    "http://labs.bible.org/api/?formatting=plain&passage=#{ref.sub(' ', '+')}"
  end

  def english
    @english ||= open(english_url).read.chomp + " (NET Bible ©1996-2016 Biblical Studies Press)"
  end

  def text_monotonic
    text.unicode_normalize(:nfd).
      gsub(/[\u0345\u0312-\u0315]/, '').  # remove iota subscript and breathing marks
      gsub(/\p{In Combining Diacritical Marks}+/, "\u0301")  # make all accents oxia
  end

  def say_text
    Speaker.say text_monotonic
  end
end

class Speaker
  def self.say(text)
    system(*command, text)
  end

  def self.command
    @command ||= begin
      if system('espeak', '--version')
        %w[espeak -v el -s 130]
      elsif system('say', '')
        %w[say -v Melina]
      else
        'false'
      end
    end
  end
end

class Question
  attr_reader :direction
  def initialize(verse, direction = nil)
    @verse = verse
    @direction = direction || (rand < 0.5 ? :en_el : :el_en)
  end
  def method_missing(meth, *args)
    if @verse.respond_to?(meth)
      @verse.send(meth, *args)
    else
      raise
    end
  end
  def prompt
    @direction == :el_en ? text : english
  end
  def answer
    @direction == :el_en ? english : text
  end
end

class Quiz
  attr_reader :verses, :chapter, :chapter_starts

  def initialize
    @verses = []
    @chapter = 0
    @chapter_starts = {1 => 0, 2 => 0}

    ensure_reader_exists

    File.read('reader_duff.md').each_line do |line|
      case line
      when /^## (\d+)/
        @chapter = $1.to_i
        @chapter_starts[chapter] = @verses.length
      when /^* (.*?) \((.*?)\)/
        @verses << Verse.new($1, $2, @chapter, @verses.count)
      end
    end
  end

  def ensure_reader_exists
    unless File.exist?('reader_duff.md')
      system './graded.rb'
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

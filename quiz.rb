#!/usr/bin/ruby -Eutf-8:utf-8

require 'open-uri'

class Verse < Struct.new(:text, :ref, :duff_chapter)
  def english_url
    "http://labs.bible.org/api/?passage=#{ref.sub(' ', '+')}"
  end
  def english
    @english ||= open(english_url).read.chomp
  end
end

max_chapter = (ARGV[0] || 6).to_i

verses = []
chapter = 0
chapter_starts = {1 => 0, 2 => 0}

File.read('reader_duff.md').each_line do |line|
	case line
	when /^## (\d+)/
		chapter = $1.to_i
		chapter_starts[chapter] = verses.length
	when /^* (.*?) \((.*?)\)/
		verses << Verse.new($1, $2, chapter)
	end
end

loop do
  verse = verses[rand(chapter_starts[max_chapter + 1])]
  prompt, answer = verse.text, verse.english
  prompt, answer = answer, prompt if rand < 0.5
  puts prompt
  print '> '
  STDIN.gets
  puts answer
  puts
end


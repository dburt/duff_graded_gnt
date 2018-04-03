#!/usr/bin/ruby -w

require 'pathname'
require 'set'

require './graded'
include DuffGradedGNT

# Rank lemmas by frequency

vocab_frequency = Hash.new {|h, k| h[k] = 0 }
each_morphgnt_line do |path, line, m|
  vocab_frequency[m[MX['lemma']]] += 1
end; nil
vocab_rank = {}
sorted_freq = vocab_frequency.sort_by {|lemma, count| count }.reverse; nil
sorted_freq_counts = sorted_freq.map {|lemma, count| count }; nil
sorted_freq.each do |lemma, count|
  vocab_rank[lemma] = 
    if lemma[0] == lemma[0].downcase
      sorted_freq_counts.index(count) + 1
    else
      0
    end
end; nil

# How big a vocabulary (highest-frequency first) is required to read various percentages of words in each book?

book_lemma_freqs = Hash.new {|h, k| h[k] = [] }
each_morphgnt_line do |path, line, m|
  #book_name = path.basename.to_s[3, 3]
  book_name = BOOKS[ m[MX['passage_book']].to_i ]
  book_lemma_freqs[book_name] << vocab_rank[m[MX['lemma']]]
end; nil
f = File.open("book_lemma_freqs.csv", "w")
f.puts "book,80%,90%,95%,97%,99%,100%"
book_lemma_freqs.each do |book, lemma_freqs|
  lemma_freqs.sort!
  f.puts "#{book},#{lemma_freqs[lemma_freqs.length * 0.80]},#{lemma_freqs[lemma_freqs.length * 0.90]},#{lemma_freqs[lemma_freqs.length * 0.95]},#{lemma_freqs[lemma_freqs.length * 0.97]},#{lemma_freqs[lemma_freqs.length * 0.99]},#{lemma_freqs.last}"
end; nil
f.close
puts File.read("book_lemma_freqs.csv")

# How many extra lemmas do you have to learn on top of Duff and excluding proper nouns, to be able to read every word in each book?

vocab_by_book = Hash.new {|h, k| h[k] = Set.new }
each_morphgnt_line do |path, line, m|
  #book_name = path.basename.to_s[3, 3]
  book_name = BOOKS[ m[MX['passage_book']].to_i ]
  vocab_by_book[book_name] << m[MX['lemma']]
end; nil
duff_vocab = vocab.values.flatten; nil
vocab_by_book.each do |book, lemmas|
  to_learn = (lemmas - duff_vocab).select {|lemma| lemma[0] == lemma[0].downcase }
  puts "#{book}: #{to_learn.count}"
end; nil
puts "Total: #{ (vocab_by_book.values.map(&:to_a).flatten.uniq - duff_vocab).select {|lemma| lemma[0] == lemma[0].downcase }.count }"

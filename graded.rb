#!/usr/bin/ruby -w

require 'json'
require 'rubygems'
require 'fastercsv'

morph_line_pattern = /
  ((\d\d)(\d\d)(\d\d))
  \ (A-|C-|D-|I-|N-|P-|RA|RD|RI|RP|RR|V-|X-)
  \ ((1|2|3|-)(P|I|F|A|X|Y|-)(A|M|P|-)(I|D|S|O|N|P|-)(N|G|D|A|V|-)(S|P|-)(M|F|N|-)(C|S|-))
  \ (\S+)
  \ (\S+)
  \ (\S+)
  \ (\S+)
/ux

morph_line_pattern_matches = %w(
  passage
  passage_book
  passage_chapter
  passage_verse
  part_of_speech
  parsing
  parsing_person
  parsing_tense
  parsing_voice
  parsing_mood
  parsing_case
  parsing_number
  parsing_gender
  parsing_degree
  text_incl_punctuation
  word
  normalized_word
  lemma
)

chapter_rules = {
  1 => [
    /--------/,   # conjunction, particle
    /----NSM-/,   # undeclined proper nouns
  ],
  2 => [
    /.PAI-.--/,     # present active indicative verbs
    /----(N|A).M-/,   # nominative + accusative, masculine nouns and article
    # NOTE: part of speech is restricted by vocab rather than pattern
  ],
  3 => [
    /----...-/,   # nouns and article of all cases and genders
  ],
  6 => [
    /.(P|F|I|A)AI-.--/,   # present/future/imperfect/aorist active indicative
    # FIXME: except eimi (introduced in ch. 5, still only present active indicative) (solution: make the chs.6-7 rules a custom matcher class)
  ],
  7 => [
    /2(P|A)AD-.--/,   # 2nd person present/aorist active imperative
    /-(P|A)AN----/,   # present/aorist active infinitive
    /-(P|A)APN.M-/,   # present/aorist active participles: nominative masculine only
  ],
  8 => [
    /.(P|F|I|A)MI-.--/,   # present/future/imperfect/aorist middle indicative
    /2(P|A)MD-.--/,   # 2nd person present/aorist middle imperative
    /-(P|A)MN----/,   # present/aorist middle infinitive
    /-(P|A)MPN.M-/,   # present/aorist middle participles: nominative masculine only
    # FIXME: eimi tense/mood catch-up from chs. 5 and 6
  ],
  14 => [
    /-(P|A)(A|M)P...-/,   # present/aorist active/middle participles (all pgn)
  ],
  15 => [
    # passive wherever we already know active and middle
    /.(P|F|I|A)PI-.--/,   # present/future/imperfect/aorist passive indicative
    /2(P|A)PD-.--/,   # 2nd person present/aorist passive imperative
    /-(P|A)PN----/,   # present/aorist passive infinitive
    /-(P|A)PP...-/,   # present/aorist passive participles
  ],
  16 => [
    # perfect/pluperfect active/middle/passive indicative/participle
    /...I-.--/,   # all indicative verbs
    /-..P...-/,   # all participles
    # /2..D-.--/,   # 2nd person imperatives (?)
    # /-..N----/,   # all infinitives (?)
  ],
  17 => [
    /...S-.--/,   # present/aorist(/etc.?) active/middle/passive subjunctive
  ],
  18 => [
    /3..D-.--/,   # 3rd person imperatives!
  ],
  20 => [
    /...O-.--/,   # optative mood
    /----..../,   # adverbs and comparative/superlative adjectives
  ],
}

vocab = JSON.load(File.read('duff_vocab.json'))
morphgnt = File.read('sblgnt/78-Phm-morphgnt.txt')

mx = morph_line_pattern_matches.each_with_index.inject({}) do |memo, (name, i)|
  memo[name] = i + 1  # 1-based like MatchData
  memo
end

duff_chapter_required_for_parsing = Hash.new do |h, parsing|
  h[parsing] = catch(:found) do
    1.upto(20) do |chapter|
      patterns = chapter_rules[chapter]
      patterns.each do |pattern|
        if pattern =~ parsing
          throw :found, chapter
        end
      end if patterns
    end
  end
end

duff_chapter_required_for_vocab = Hash.new do |h, lemma|
  h[lemma] = catch(:found) do
    '01'.upto('20') do |chapter|
      if vocab[chapter].include?(lemma)
        throw :found, chapter.to_i
      end
    end
  end
end

def duff_chapter_required(morph_line)
  m = morph_line_pattern.match(morph_line)
  ch_p = duff_chapter_required_for_parsing[m[mx['parsing']]]
  ch_v = duff_chapter_required_for_vocab[m[mx['lemma']]]
  return nil if ch_p.nil? || ch_v.nil?
  [ch_p, ch_v].max
end

FasterCSV(STDOUT) do |csv|
  csv << morph_line_pattern_matches + %w[duff_parsing_chapter duff_vocab_chapter]
  morphgnt.each_line do |line|
    m = morph_line_pattern.match(line)
    next STDERR.puts "Unmatched line: #{line}" unless m
    ch_p = duff_chapter_required_for_parsing[m[mx['parsing']]]
    ch_v = duff_chapter_required_for_vocab[m[mx['lemma']]]
    csv << m.to_a[1..-1] + [ch_p, ch_v]
    #puts [
    #  m[mx['passage_chapter']].to_i,
    #  m[mx['passage_verse']].to_i,
    #  duff_chapter_required_for_parsing[m[mx['parsing']]],
    #  duff_chapter_required_for_vocab[m[mx['lemma']]],
    #]
  end
end

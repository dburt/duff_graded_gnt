#!/usr/bin/ruby -w

require 'json'

module DuffGradedGNT

  MORPH_LINE_PATTERN = /
    ((\d\d)(\d\d)(\d\d))
    \ (A-|C-|D-|I-|N-|P-|RA|RD|RI|RP|RR|V-|X-|..)
    \ ((1|2|3|-)(P|I|F|A|X|Y|-)(A|M|P|-)(I|D|S|O|N|P|-)(N|G|D|A|V|-)(S|P|-)(M|F|N|-)(C|S|-))
    \ (\S+)
    \ (\S+)
    \ (\S+)
    \ (\S+)
  /ux

  MORPH_LINE_PATTERN_MATCHES = %w(
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

  CHAPTER_RULES = {
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
      /.(X|Y).I-.--/,   # perfect/pluperfect indicative
      /-X.P...-/,       # perfect participles
      /-X.N...-/,       # perfect infinitive (Note on p. 180)
    ],
    17 => [
      /.(P|A).S-.--/,   # present/aorist active/middle/passive subjunctive
    ],
    18 => [
      /3(P|A).D-.--/,   # 3rd person imperatives!
    ],
    20 => [
      /.(P|A).O-.--/,   # optative mood
      /----..../,   # adverbs and comparative/superlative adjectives
    ],
  }

  MX = MORPH_LINE_PATTERN_MATCHES.each_with_index.inject({}) do |memo, (name, i)|
    memo[name] = i + 1  # 1-based like MatchData
    memo
  end

  BOOKS = %w[
    Mt Mk Lk Jn Ac
    Ro 1Co 2Co Ga Eph Php Col 1Th 2Th 1Ti 2Ti Tit Phm
    Heb Jas 1Pe 2Pe 1Jn 2Jn 3Jn Jud Rev
  ]

  # LXX
  BOOKS = %w[ Gen Exod Lev Num Deut JoshB JoshA JudgesB JudgesA Ruth 1Sam 2Sam 1Kings 2Kings 1Chron 2Chron 1Esdras 2Esdras Esther Judith TobitBA TobitS 1Macc 2Macc 3Macc 4Macc Psalms Odes Proverbs Qoheleth Canticles Job Wisdom Sirach PsSol Hosea Micah Amos Joel Jonah Obadiah Nahum Habakkuk Zeph Haggai Zech Malachi Isaiah Jer Baruch EpJer Lam Ezek BelOG BelTh DanielOG DanielTh SusOG SusTh ]

  def vocab
    @vocab ||= JSON.load(File.read('duff_vocab.json'))
  end

  def duff_chapter_required_for_parsing(parsing)
    @duff_chapter_required_for_parsing ||= {}
    @duff_chapter_required_for_parsing[parsing] ||= catch(:found) do
      1.upto(20) do |chapter|
        patterns = CHAPTER_RULES[chapter]
        patterns.each do |pattern|
          if pattern =~ parsing
            throw :found, chapter
          end
        end if patterns
      end
      nil
    end
  end

  def duff_chapter_required_for_vocab(lemma)
    @duff_chapter_required_for_vocab ||= {}
    @duff_chapter_required_for_vocab[lemma] ||= catch(:found) do
      '01'.upto('20') do |chapter|
        if vocab[chapter].include?(lemma)
          throw :found, chapter.to_i
        end
      end
      nil
    end
  end

  def duff_chapter_required(morph_line)
    m = MORPH_LINE_PATTERN.match(morph_line)
    ch_p = duff_chapter_required_for_parsing(m[MX['parsing']])
    ch_v = duff_chapter_required_for_vocab(m[MX['lemma']])
    return nil if ch_p.nil? || ch_v.nil?
    [ch_p, ch_v].max
  end

  def human_ref(passage)
    "#{BOOKS[passage[0, 2].to_i - 1]} #{passage[2, 2].to_i}:#{passage[4, 2].to_i}"
  end

  def each_morphgnt_line
    Pathname.glob('lxx.txt').sort.each do |path|
      STDERR.puts path.basename
      path.read.each_line do |line|
        m = MORPH_LINE_PATTERN.match(line)
        next STDERR.puts "Unmatched line: #{line}" unless m
        yield path, line, m
      end
    end
  end

end

if $0 == __FILE__

  require 'pathname'
  begin
    require 'csv'
  rescue LoadError  # Ruby 1.8
    require 'rubygems'
    require 'fastercsv'
    CSV = FasterCSV
    def CSV(*args, &blk) FasterCSV(*args, &blk) end
  end

  include DuffGradedGNT

  reader = Hash.new {|h, k| h[k] = [] }
  verse = ""
  ch_max = 0
  previous_line_passage = nil

  print("\xef\xbb\xbf")  # UTF-8 byte-order mark for Microsoft Excel
  CSV.open("morphgnt_duff.csv", "w") do |csv|  #, :encoding => 'u'
    csv <<
      ['file'] +
      MORPH_LINE_PATTERN_MATCHES +
      %w[duff_parsing_chapter duff_vocab_chapter]

    each_morphgnt_line do |path, line, m|
      if previous_line_passage && m[MX['passage']] != previous_line_passage
        reader[ch_max] << [verse, previous_line_passage] if ch_max < 99
        ch_max = 0
        verse = ""
      end

      ch_p = duff_chapter_required_for_parsing(m[MX['parsing']])
      ch_v = duff_chapter_required_for_vocab(m[MX['lemma']])
      csv << [path.basename] + m.to_a[1..-1] + [ch_p, ch_v]

      ch_max = [ch_max, ch_p || 99, ch_v || 99].max
      verse << m[MX['text_incl_punctuation']] << " "
      previous_line_passage = m[MX['passage']]
    end
  end

  File.open("reader_duff.md", "w") do |f|
    f.puts "# Graded Reader for Duff's Elements"
    f.puts
    f.puts "Verses readable without help after completing each Duff chapter."
    f.puts
    f.puts "[Credit](https://github.com/dburt/duff_graded_gnt)"
    reader.sort.each do |ch, verses|
      f.puts
      f.puts "## #{ch}"
      f.puts
      verses.each do |words, ref|
        f.puts "* #{words} (#{human_ref(ref)})"
      end
    end
  end

end

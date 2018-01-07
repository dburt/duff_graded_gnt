#!/usr/bin/env ruby

require_relative 'graded'

module LXXMorph
  MORPH_LINE_PATTERN = /
    (\S+)
    \ ([NVARCXIMPD]..)
    -
    ( ([-NGDAV])([-SDP])([-MFN])([-CS])-- | ([PIFAXY])([AMP])([IDSONP])([-123])([-SDP])- | ([PIFAXY])([AMP])([IDSONP])([NGDAV])([SDP])([MFN]) )
    \ (\S+)
    (\ .*)?
  /ux

  MORPH_LINE_PATTERN_MATCHES = %w(
    word
    part_of_speech
    parsing
      n_case
      n_number
      n_gender
      n_degree
      v_tense
      v_voice
      v_mood
      v_person
      v_number
      p_tense
      p_voice
      p_mood
      p_case
      p_number
      p_gender
    lemma
    prefixes
  )

  MX = MORPH_LINE_PATTERN_MATCHES.each_with_index.inject({}) do |memo, (name, i)|
    memo[name] = i + 1  # 1-based like MatchData
    memo
  end
end

if __FILE__ == $0

  include LXXMorph

  chapter = verse = nil

  Dir['lxxmorph-unicode/*.*.txt'].each do |book_filename|
    book_number = book_filename[/\d+/]
    STDERR.print '.'
    File.open(book_filename) do |f|
      f.each_line do |line|
        case line
        when /^(\w+) (\d+:)?(\d+)$/
          chapter = ($2 || 1).to_i
          verse = $3.to_i
        when MORPH_LINE_PATTERN
          m = line.match MORPH_LINE_PATTERN
          parsing = "#{m[MX['v_person']] || '-'}#{m[MX['v_tense']] || m[MX['p_tense']] || '-'}#{m[MX['v_voice']] || m[MX['p_voice']] || '-'}#{m[MX['v_mood']] || m[MX['p_mood']] || '-'}#{m[MX['n_case']] || m[MX['p_case']] || '-'}#{m[MX['n_number']] || m[MX['v_number']] || m[MX['p_number']] || '-'}#{m[MX['n_gender']] || m[MX['p_gender']] || '-'}#{m[MX['n_degree']] || '-'}"
          word = m[MX['word']]
          puts "#{book_number}#{"%02d" % chapter}#{"%02d" % verse} #{m[MX['part_of_speech']]} #{parsing} #{word} #{word} #{word} #{m[MX['lemma']]}"
        when /^\s*$/
        else
          puts "unrecognized: #{line}"
        end
      end
    end
  end
end

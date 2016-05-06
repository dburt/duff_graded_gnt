#!/usr/bin/ruby

#
# Draw the Duff chapter required for each word in the Greek New Testament
# as an image with one coloured pixel per word.
#
# Uses a particular tab-separated output from graded.rb.
#

require 'rubygems'
require 'chunky_png'

class Drawing
    def initialize(width, height, &block)
        @png = ChunkyPNG::Image.new(width, height, ChunkyPNG::Color::WHITE)
    end
    def draw(opts)
        @png[opts[:x], opts[:y]] = ChunkyPNG::Color(opts[:color])
    end
    def save(filename)
        @png.save(filename)
    end
end

pat = /(\d+)\t(\d+)\t(\d+)\t(\w+) (\d+)/
color_map = {
    0  => "#f6f",
    1  => "#ff0",
    2  => "#ef0",
    3  => "#df0",
    4  => "#cf0",
    5  => "#bf0",
    6  => "#af0",
    7  => "#9f0",
    8  => "#8f0",
    9  => "#7f0",
    10 => "#6f6",
    11 => "#5d6",
    12 => "#4b7",
    13 => "#397",
    14 => "#278",
    15 => "#158",
    16 => "#049",
    17 => "#039",
    18 => "#02a",
    19 => "#01a",
    20 => "#00b",
    99 => "#000"
}
prev_match = //.match("")
book = -1
word = -1
drawing = Drawing.new(19470, 27)
ARGF.each_line do |line|
    match = pat.match(line)
    next unless match

    if match[4] != prev_match[4]  # new book
        book += 1
        word = 0
    elsif match[5] != prev_match[5]  # new chapter
        word += 1  # leave a gap
        print "#{match[4]}#{match[5]} "
        STDOUT.flush
    end

    drawing.draw :y => book, :x => word, :color => color_map[match[3].to_i]

    prev_match = match
    word += 1
end
drawing.save("duff.png")

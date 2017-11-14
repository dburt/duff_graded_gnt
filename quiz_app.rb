#!/usr/bin/env ruby

require 'sinatra'
require_relative 'quiz'

get '/' do
  "<p>What chapter of Duff are you up to?</p>" +
    (3..20).map {|n| "<a href='/level/#{n}'>#{n}</a> " }.join
end

get '/level/:n' do
  max_chapter = params[:n].to_i
  return "Choose a chapter between 3 and 20." unless max_chapter.between?(3, 20)
  verse = Quiz.instance.random_verse(max_chapter)
  verse.to_json
  [:text, :english, :text_monotonic, :ref, :duff_chapter].inject({}) do |memo, attr|
    memo[attr] = verse.send(attr)
    memo
  end.to_json
  question = Question.new(verse)
  <<-END
    <form method='post'>
      <input type="hidden" name="id" value="#{question.id}"/>
      <input type="hidden" name="direction" value="#{question.direction}"/>
      <p>#{question.prompt}</p>
      <p><input name="answer"/></p>
      <p><input type="submit"/></p>
    </form>
  END
end

post '/level/:n' do
  max_chapter = params[:n].to_i
  ans = params[:answer]
  v = Quiz.instance.verses[params[:id].to_i]
  q = Question.new(v, params[:direction].to_sym)
  <<-END
    <p>#{q.prompt}</p>
    <p>#{ans}</p>
    <p>#{q.answer}</p>
    <a href="#{request.path}">Next</a>
  END
end

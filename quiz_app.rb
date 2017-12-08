#!/usr/bin/env ruby

require 'sinatra'
require_relative 'quiz'

get '/' do
  erb :index
end

get '/level/:n' do
  max_chapter = params[:n].to_i
  return "Choose a chapter between 3 and 20." unless max_chapter.between?(3, 20)
  verse = Quiz.instance.random_verse(max_chapter)
  [:text, :english, :text_monotonic, :ref, :duff_chapter].inject({}) do |memo, attr|
    memo[attr] = verse.send(attr)
    memo
  end.to_json
  @q = Question.new(verse)
  erb :question
end

post '/level/:n' do
  max_chapter = params[:n].to_i
  @ans = params[:answer]
  v = Quiz.instance.verses[params[:id].to_i]
  @q = Question.new(v, params[:direction].to_sym)
  erb :answer
end


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
  q = Question.new(verse)
  <<-END
    <form method='post'>
      <input type="hidden" name="id" value="#{q.id}"/>
      <input type="hidden" name="direction" value="#{q.direction}"/>
      <p>Q: #{q.prompt}</p>
      <div id="say" lang="el">#{q.text_monotonic if q.direction == :el_en}</div>
      <p>A: <input name="answer"/></p>
      <p><input type="submit"/></p>
    </form>
    #{say_script}
  END
end

post '/level/:n' do
  max_chapter = params[:n].to_i
  ans = params[:answer]
  v = Quiz.instance.verses[params[:id].to_i]
  q = Question.new(v, params[:direction].to_sym)
  <<-END
    <p>Q: #{q.prompt}</p>
    <p>A (you): #{ans}</p>
    <p>A (Bible): #{q.answer}</p>
    <div id="say" lang="el">#{q.text_monotonic if q.direction == :en_el}</div>
    <a href="#{request.path}">Next</a>
    #{say_script}
  END
end

def say_script
  <<-END
    <style>#say {font-size: 0} #say::after {content: '▶'; font-size: 20px}</style>
    <script>
      function say() {
        var utterance = new SpeechSynthesisUtterance(document.getElementById('say').innerText);
        utterance.lang = 'el';
        speechSynthesis.cancel();
        speechSynthesis.speak(utterance);
      }
      say()
      document.getElementById('say').addEventListener('click', function(ev) { say(); }, false);
    </script>
  END
end

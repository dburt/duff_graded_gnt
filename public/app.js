function say() {
  if ($('#say').length == 0){
    return;
  }
  var utterance = new SpeechSynthesisUtterance($('#say').innerText);
  utterance.lang = 'el';
  speechSynthesis.cancel();
  speechSynthesis.speak(utterance);
}

$(function() {
  say()
  $('#say button').click(function(ev) { say(); });  
})

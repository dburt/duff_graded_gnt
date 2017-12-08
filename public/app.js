function say() {
  if ($('#say').length == 0 || !greekVoiceAvailable()){
    return;
  }

  var utterance = new SpeechSynthesisUtterance($('#say .text').text());
  utterance.lang = 'el';
  speechSynthesis.cancel();
  speechSynthesis.speak(utterance);
}

function greekVoiceAvailable() {
  var voices = speechSynthesis.getVoices();
  for (i = 0; i < voices.length ; i++) {
    if (voices[i].lang.substr(0, 2) == 'el') {
      return true;
    }
  }
  return false
}

$(function() {
  $('#say button').click(function(ev) { say(); });  
  if (greekVoiceAvailable()) {
    say()
  }
  else {
    $('#say').append('No Greek voice found. Install a Greek voice in your operating system\'s speech synthesis (TTS) to enable voice.');
    $('#say button').attr('disabled', true);
  }
})

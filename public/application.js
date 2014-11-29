$(document).ready(function() {
  $('#hit_form input').click(function() {
   $.ajax({
    type: 'POST',
    url: '/game/player/hit',
    // data: {} # leave this out because we don't have a data element.

   }).done(function(msg){
     alert(msg); 
   });

   return false;
  });
});


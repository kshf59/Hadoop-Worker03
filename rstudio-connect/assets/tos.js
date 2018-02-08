$( document ).ready(function() {
  // En/disable now that the button event is done in JS.
  var oldClick = $('#customBtn').attr('onclick');
  $( '#customBtn').attr('onclick', "if($('input#ckbkAgree').is(':checked')){ " + oldClick + "  }else{alert('You must accept the Terms of Service to login')}");

  $( "input#ckbkAgree" ).change(function() {
    if(this.checked) {
      document.cookie="rsconnect.beta.tos.v1=True";
      $( "#signInButton" ).removeClass('disabled');
    } else {
      document.cookie="rsconnect.beta.tos.v1=False";
      $( "#signInButton" ).addClass('disabled');
    }
  });

  var tosValue = document.cookie.replace(/(?:(?:^|.*;\s*)rsconnect.beta.tos.v1\s*\=\s*([^;]*).*$)|^.*$/, "$1");
  
  if (tosValue === "" || tosValue == "False") {
    $( "input#ckbkAgree" ).prop( "checked", false);
    $( "#signInButton" ).addClass('disabled');
  } else {
    $( "input#ckbkAgree" ).prop( "checked", true);
    $( "#signInButton" ).removeClass('disabled');
  }

});

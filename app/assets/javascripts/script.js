$(document).ready(function() {
  $('.menu-dropdown').dropdown();

  /*
    To simulate the group loan product
      In the form:
        #weekly_principal
        #weekly_interest
        #duration
    
      In the calculator 
        #total_principal
        #percentage_interest
        #calculator_duration
  */

  $("#simulate_group_loan_product").click(function(){
    console.log("I am fucking clicked");
    console.log("Total principal is " + parseFloat( $("#total_principal input").val()  ) );
    console.log("Total percentage is " + parseFloat( $("#percentage_interest input").val()  ) );
    console.log("Total duration is " + parseInt(  $("#calculator_duration input").val()  ));
    
    var total_principal = parseFloat( $("#total_principal input").val()  );
    var percentage_interest = parseFloat( $("#percentage_interest input").val()  );
    var loan_duration =  parseInt(  $("#calculator_duration input").val() );
    
    var weekly_principal = total_principal/loan_duration; 
    var weekly_interest = weekly_principal * percentage_interest/100;
    
    console.log("the calculated weekly principal is " + weekly_principal);
    console.log("The calculated weekly interest is "+ weekly_interest);
    $("#weekly_principal").val(weekly_principal);
    $("#weekly_interest").val( weekly_interest );
    $("#duration").val( loan_duration );
    
    
    
/*    var total_principal = parseFloat( $("#total_principal").value()  );*/
  })

});
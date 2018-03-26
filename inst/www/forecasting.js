$(document).ready(function(){
      $("#submitbutton").on("click", function(){

       alert("clicked ");
        var configfile = $("#configfile")[0].files[0];
          alert("config ");
        var inputfile = $("#inputfile")[0].files[0];
        alert("input ");
        if(!configfile){
          alert("No config file selected.");
          return;
        }
        if(!inputfile){
          alert("No input file selected.");
          return;
        }

        //disable the button during upload
        $("#submitbutton").attr("disabled", "disabled");
          alert("disabled");
        //perform the request
        var req = ocpu.call("forecasting", {
          inputFile: inputfile
          configFile: configfile
        }, function(session){
          $("#printlink").attr("href", session.getLoc() + "R/.val/print")
          $("#rdalink").attr("href", session.getLoc() + "R/.val/rda")
          $("#csvlink").attr("href", session.getLoc() + "R/.val/csv")
          $("#tablink").attr("href", session.getLoc() + "R/.val/tab")
          $("#jsonlink").attr("href", session.getLoc() + "R/.val/json")
          $("#mdlink").attr("href", session.getLoc() + "R/.val/md")
        });
        
        alert("session done");
        
        //if R returns an error, alert the error message
        req.fail(function(){
          alert("Server error: " + req.responseText);
        });
        
        //after request complete, re-enable the button 
        req.always(function(){
          $("#submitbutton").removeAttr("disabled")
        });        
      });       
    });
        alert("done");
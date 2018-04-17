// App Script
// ocpu.seturl("//kkdhuiyu.ocpu.io/Forecasting/R")
ocpu.seturl("http://opencpu.halobicloud.com/ocpu/apps/kkdhuiyu/Forecasting/R")


// tidy data from prism 
var inputs = prism.pane.rows.slice(0, -1);

var values = []
var starty =parseInt(inputs[0].data[1].value.slice(0,4));
var startm = parseInt(inputs[0].data[1].value.slice(4,6));
var startd = parseInt(inputs[0].data[1].value.slice(6,8));
var endy =  parseInt(inputs[inputs.length -1].data[1].value.slice(0,4));
var endm =  parseInt(inputs[inputs.length -1].data[1].value.slice(4,6));
var endd = parseInt(inputs[inputs.length -1].data[1].value.slice(6,8));

for (i = 0 ; i <inputs.length ; i++){
    if(inputs[i].data[2].value ==""){
        values.push(0.0);
    }else{
   values.push(parseFloat(inputs[i].data[2].value));
    }
}

// toggle 
$('#history_data').click(function(){
    $("#input").toggle();
});

$('#forecasting_header').click(function(){
    $("#forecasting").toggle();
});
$('#decomposition_header').click(function(){
    $("#decomposition").toggle();
});

// show data in table
var table = $('#inputTable');
 var row, cell;
 row = $( '<tr />' );
    table.append( row );
 for( i=0; i<values.length; i++){
     if(i%12 ===0 && i!==0){
    row = $( '<tr />' );
    table.append( row );
     }
     
     cell = $('<td>'+parseInt(values[i])+'           </td       >');
      row.append( cell );
     }
 
// function for plotting 
function forecast(){
   // get algorithm selected
      var algo = $('#algorithms').find(":selected").val();
      
      
        //request 1: plot
        var req =$("#plotdiv").rplot("plot_forecasting", {
          mydata : values,
          algo: algo,
          starty: starty,
          startm: startm,
          endy: endy,
          endm:endm,
          startd:startd,
          endd:endd,
          freq:"day"
          
        }, function(session){
        });
        
        req.fail(function(){
          alert("Server error: " + req.responseText);
        });
        req.always(function(){
        });


     // request 2: summary 
        var req2 = ocpu.call("printsummary", {
         mydata : values,
          algo: algo,
          starty: starty,
          startm: startm,
          endy: endy,
          endm:endm,
          startd:startd,
          endd:endd,
          freq:"day"
          
        }, function(session){
          $("#csvlink").attr("href", session.getLoc() + "R/.val/csv")

        });
        req2.fail(function(){
          alert("Server error: " + req.responseText);
        });
        req2.always(function(){
        
        });
        
         // request 3: model method 
        var req3 = ocpu.call("print_model", {
         mydata : values,
          algo: algo,
          starty: starty,
          startm: startm,
          endy: endy,
          endm:endm,
          startd:startd,
          endd:endd,
          freq:"day"
          
        }, function(session){
             session.getConsole(function(output){
        text = "Model: " + output.slice(output.lastIndexOf("forecast"),);
        $("#model_method").text(text);
      });
         

        });
        req3.fail(function(){
          alert("Server error: " + req.responseText);
        });
        req3.always(function(){
        
        });
        
        //request 4: plot decomposition 
        var req =$("#decomp_plot").rplot("plot_decomposition", {
          mydata : values,
          algo: algo,
          starty: starty,
          startm: startm,
          endy: endy,
          endm:endm,
          startd:startd,
          endd:endd,
          freq:"day"
          
        }, function(session){
        });
        
        req.fail(function(){
          alert("Server error: " + req.responseText);
        });
        req.always(function(){
        });

    
}

$("#plotbutton").on("click",forecast);
$( document ).ready(forecast()); 
// App Script End

// Prism data
var prism= {
 "pane" : {
	"name": "YQMD",
	"uniqueName": "[Time].[YQMD]",
	"columns": [
		{
			"name": "id",
			"caption": ""
		},
		{
			"name": "name",
			"caption": "YQMD"
		},
		{
			"name": "col0",
			"caption": "2017 : Sales",
			"fractionDigits": "0"
		}
	],
	"rows": [
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201704].&[2017-04-02T00:00:00]",
					"id": "0"
				},
				{
					"value": "20170402"
				},
				{
					"value": "54"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201704].&[2017-04-03T00:00:00]",
					"id": "1"
				},
				{
					"value": "20170403"
				},
				{
					"value": "19"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201704].&[2017-04-04T00:00:00]",
					"id": "2"
				},
				{
					"value": "20170404"
				},
				{
					"value": "271"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201704].&[2017-04-05T00:00:00]",
					"id": "3"
				},
				{
					"value": "20170405"
				},
				{
					"value": "62"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201704].&[2017-04-06T00:00:00]",
					"id": "4"
				},
				{
					"value": "20170406"
				},
				{
					"value": "667"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201704].&[2017-04-07T00:00:00]",
					"id": "5"
				},
				{
					"value": "20170407"
				},
				{
					"value": "170"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201704].&[2017-04-08T00:00:00]",
					"id": "6"
				},
				{
					"value": "20170408"
				},
				{
					"value": "21"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201704].&[2017-04-09T00:00:00]",
					"id": "7"
				},
				{
					"value": "20170409"
				},
				{
					"value": "331"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201704].&[2017-04-10T00:00:00]",
					"id": "8"
				},
				{
					"value": "20170410"
				},
				{
					"value": "5"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201704].&[2017-04-11T00:00:00]",
					"id": "9"
				},
				{
					"value": "20170411"
				},
				{
					"value": "15"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201704].&[2017-04-12T00:00:00]",
					"id": "10"
				},
				{
					"value": "20170412"
				},
				{
					"value": "17"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201704].&[2017-04-13T00:00:00]",
					"id": "11"
				},
				{
					"value": "20170413"
				},
				{
					"value": "122"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201704].&[2017-04-14T00:00:00]",
					"id": "12"
				},
				{
					"value": "20170414"
				},
				{
					"value": "18"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201704].&[2017-04-15T00:00:00]",
					"id": "13"
				},
				{
					"value": "20170415"
				},
				{
					"value": "2712"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201704].&[2017-04-16T00:00:00]",
					"id": "14"
				},
				{
					"value": "20170416"
				},
				{
					"value": "22"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201704].&[2017-04-17T00:00:00]",
					"id": "15"
				},
				{
					"value": "20170417"
				},
				{
					"value": "143"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201704].&[2017-04-18T00:00:00]",
					"id": "16"
				},
				{
					"value": "20170418"
				},
				{
					"value": "602"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201704].&[2017-04-19T00:00:00]",
					"id": "17"
				},
				{
					"value": "20170419"
				},
				{
					"value": "186"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201704].&[2017-04-20T00:00:00]",
					"id": "18"
				},
				{
					"value": "20170420"
				},
				{
					"value": "24"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201704].&[2017-04-21T00:00:00]",
					"id": "19"
				},
				{
					"value": "20170421"
				},
				{
					"value": "18"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201704].&[2017-04-22T00:00:00]",
					"id": "20"
				},
				{
					"value": "20170422"
				},
				{
					"value": "18"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201704].&[2017-04-23T00:00:00]",
					"id": "21"
				},
				{
					"value": "20170423"
				},
				{
					"value": "23"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201704].&[2017-04-24T00:00:00]",
					"id": "22"
				},
				{
					"value": "20170424"
				},
				{
					"value": "338"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201704].&[2017-04-25T00:00:00]",
					"id": "23"
				},
				{
					"value": "20170425"
				},
				{
					"value": "149"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201704].&[2017-04-26T00:00:00]",
					"id": "24"
				},
				{
					"value": "20170426"
				},
				{
					"value": "157"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201704].&[2017-04-27T00:00:00]",
					"id": "25"
				},
				{
					"value": "20170427"
				},
				{
					"value": "30"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201704].&[2017-04-28T00:00:00]",
					"id": "26"
				},
				{
					"value": "20170428"
				},
				{
					"value": "58"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201704].&[2017-04-29T00:00:00]",
					"id": "27"
				},
				{
					"value": "20170429"
				},
				{
					"value": "807"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201704].&[2017-04-30T00:00:00]",
					"id": "28"
				},
				{
					"value": "20170430"
				},
				{
					"value": "268"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201705].&[2017-05-01T00:00:00]",
					"id": "29"
				},
				{
					"value": "20170501"
				},
				{
					"value": "25"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201705].&[2017-05-02T00:00:00]",
					"id": "30"
				},
				{
					"value": "20170502"
				},
				{
					"value": "146"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201705].&[2017-05-03T00:00:00]",
					"id": "31"
				},
				{
					"value": "20170503"
				},
				{
					"value": "44"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201705].&[2017-05-04T00:00:00]",
					"id": "32"
				},
				{
					"value": "20170504"
				},
				{
					"value": "75"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201705].&[2017-05-05T00:00:00]",
					"id": "33"
				},
				{
					"value": "20170505"
				},
				{
					"value": "538"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201705].&[2017-05-06T00:00:00]",
					"id": "34"
				},
				{
					"value": "20170506"
				},
				{
					"value": "577"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201705].&[2017-05-07T00:00:00]",
					"id": "35"
				},
				{
					"value": "20170507"
				},
				{
					"value": "101"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201705].&[2017-05-08T00:00:00]",
					"id": "36"
				},
				{
					"value": "20170508"
				},
				{
					"value": "119"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201705].&[2017-05-09T00:00:00]",
					"id": "37"
				},
				{
					"value": "20170509"
				},
				{
					"value": "38"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201705].&[2017-05-10T00:00:00]",
					"id": "38"
				},
				{
					"value": "20170510"
				},
				{
					"value": "88"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201705].&[2017-05-11T00:00:00]",
					"id": "39"
				},
				{
					"value": "20170511"
				},
				{
					"value": "149"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201705].&[2017-05-12T00:00:00]",
					"id": "40"
				},
				{
					"value": "20170512"
				},
				{
					"value": "43"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201705].&[2017-05-13T00:00:00]",
					"id": "41"
				},
				{
					"value": "20170513"
				},
				{
					"value": "10"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201705].&[2017-05-14T00:00:00]",
					"id": "42"
				},
				{
					"value": "20170514"
				},
				{
					"value": "68"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201705].&[2017-05-15T00:00:00]",
					"id": "43"
				},
				{
					"value": "20170515"
				},
				{
					"value": "77"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201705].&[2017-05-16T00:00:00]",
					"id": "44"
				},
				{
					"value": "20170516"
				},
				{
					"value": "8"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201705].&[2017-05-17T00:00:00]",
					"id": "45"
				},
				{
					"value": "20170517"
				},
				{
					"value": "185"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201705].&[2017-05-18T00:00:00]",
					"id": "46"
				},
				{
					"value": "20170518"
				},
				{
					"value": "23"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201705].&[2017-05-19T00:00:00]",
					"id": "47"
				},
				{
					"value": "20170519"
				},
				{
					"value": "27"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201705].&[2017-05-20T00:00:00]",
					"id": "48"
				},
				{
					"value": "20170520"
				},
				{
					"value": "2898"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201705].&[2017-05-21T00:00:00]",
					"id": "49"
				},
				{
					"value": "20170521"
				},
				{
					"value": "819"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201705].&[2017-05-22T00:00:00]",
					"id": "50"
				},
				{
					"value": "20170522"
				},
				{
					"value": "507"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201705].&[2017-05-23T00:00:00]",
					"id": "51"
				},
				{
					"value": "20170523"
				},
				{
					"value": "35"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201705].&[2017-05-24T00:00:00]",
					"id": "52"
				},
				{
					"value": "20170524"
				},
				{
					"value": "12"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201705].&[2017-05-25T00:00:00]",
					"id": "53"
				},
				{
					"value": "20170525"
				},
				{
					"value": "82"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201705].&[2017-05-26T00:00:00]",
					"id": "54"
				},
				{
					"value": "20170526"
				},
				{
					"value": "74"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201705].&[2017-05-27T00:00:00]",
					"id": "55"
				},
				{
					"value": "20170527"
				},
				{
					"value": "111"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201705].&[2017-05-28T00:00:00]",
					"id": "56"
				},
				{
					"value": "20170528"
				},
				{
					"value": "6"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201705].&[2017-05-29T00:00:00]",
					"id": "57"
				},
				{
					"value": "20170529"
				},
				{
					"value": "247"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201705].&[2017-05-30T00:00:00]",
					"id": "58"
				},
				{
					"value": "20170530"
				},
				{
					"value": "75"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201705].&[2017-05-31T00:00:00]",
					"id": "59"
				},
				{
					"value": "20170531"
				},
				{
					"value": ""
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201706].&[2017-06-01T00:00:00]",
					"id": "60"
				},
				{
					"value": "20170601"
				},
				{
					"value": "128"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201706].&[2017-06-02T00:00:00]",
					"id": "61"
				},
				{
					"value": "20170602"
				},
				{
					"value": "42"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201706].&[2017-06-03T00:00:00]",
					"id": "62"
				},
				{
					"value": "20170603"
				},
				{
					"value": "273"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201706].&[2017-06-04T00:00:00]",
					"id": "63"
				},
				{
					"value": "20170604"
				},
				{
					"value": "258"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201706].&[2017-06-05T00:00:00]",
					"id": "64"
				},
				{
					"value": "20170605"
				},
				{
					"value": "123"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201706].&[2017-06-06T00:00:00]",
					"id": "65"
				},
				{
					"value": "20170606"
				},
				{
					"value": "49"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201706].&[2017-06-07T00:00:00]",
					"id": "66"
				},
				{
					"value": "20170607"
				},
				{
					"value": "93"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201706].&[2017-06-08T00:00:00]",
					"id": "67"
				},
				{
					"value": "20170608"
				},
				{
					"value": "68"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201706].&[2017-06-09T00:00:00]",
					"id": "68"
				},
				{
					"value": "20170609"
				},
				{
					"value": "93"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201706].&[2017-06-10T00:00:00]",
					"id": "69"
				},
				{
					"value": "20170610"
				},
				{
					"value": "675"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201706].&[2017-06-11T00:00:00]",
					"id": "70"
				},
				{
					"value": "20170611"
				},
				{
					"value": "104"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201706].&[2017-06-12T00:00:00]",
					"id": "71"
				},
				{
					"value": "20170612"
				},
				{
					"value": "19"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201706].&[2017-06-13T00:00:00]",
					"id": "72"
				},
				{
					"value": "20170613"
				},
				{
					"value": "2266"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201706].&[2017-06-14T00:00:00]",
					"id": "73"
				},
				{
					"value": "20170614"
				},
				{
					"value": "82"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201706].&[2017-06-15T00:00:00]",
					"id": "74"
				},
				{
					"value": "20170615"
				},
				{
					"value": "95"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201706].&[2017-06-16T00:00:00]",
					"id": "75"
				},
				{
					"value": "20170616"
				},
				{
					"value": "495"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201706].&[2017-06-17T00:00:00]",
					"id": "76"
				},
				{
					"value": "20170617"
				},
				{
					"value": "55"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201706].&[2017-06-18T00:00:00]",
					"id": "77"
				},
				{
					"value": "20170618"
				},
				{
					"value": "69"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201706].&[2017-06-19T00:00:00]",
					"id": "78"
				},
				{
					"value": "20170619"
				},
				{
					"value": "6"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201706].&[2017-06-20T00:00:00]",
					"id": "79"
				},
				{
					"value": "20170620"
				},
				{
					"value": "14"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201706].&[2017-06-21T00:00:00]",
					"id": "80"
				},
				{
					"value": "20170621"
				},
				{
					"value": "637"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201706].&[2017-06-22T00:00:00]",
					"id": "81"
				},
				{
					"value": "20170622"
				},
				{
					"value": "70"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201706].&[2017-06-23T00:00:00]",
					"id": "82"
				},
				{
					"value": "20170623"
				},
				{
					"value": "82"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201706].&[2017-06-24T00:00:00]",
					"id": "83"
				},
				{
					"value": "20170624"
				},
				{
					"value": "11"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201706].&[2017-06-25T00:00:00]",
					"id": "84"
				},
				{
					"value": "20170625"
				},
				{
					"value": "22"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201706].&[2017-06-26T00:00:00]",
					"id": "85"
				},
				{
					"value": "20170626"
				},
				{
					"value": "27"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201706].&[2017-06-27T00:00:00]",
					"id": "86"
				},
				{
					"value": "20170627"
				},
				{
					"value": "70"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201706].&[2017-06-28T00:00:00]",
					"id": "87"
				},
				{
					"value": "20170628"
				},
				{
					"value": "22"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201706].&[2017-06-29T00:00:00]",
					"id": "88"
				},
				{
					"value": "20170629"
				},
				{
					"value": "31"
				}
			],
			"selected": false
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017].&[20172].&[201706].&[2017-06-30T00:00:00]",
					"id": "89"
				},
				{
					"value": "20170630"
				},
				{
					"value": "569"
				}
			],
			"selected": true
		},
		{
			"data": [
				{
					"value": "[Time].[YQMD].[Year].&[2017]",
					"id": "0"
				},
				{
					"value": "2017"
				},
				{
					"value": "42421"
				}
			],
			"selected": false
		}
	]
},
 "context": {
	"plugin": null,
	"view": {
		"id": "view:tabset=4a1a72a7-935d-47bc-88bc-50b477944525;id=153856124",
		"uniqueId": 2,
		"name": "Forecasting",
		"connectionString": "Provider=MSOLAP;Data Source=LOCALHOST;Persist Security Info=False;Integrated Security=SSPI;Initial Catalog=Beverage;Connect Timeout=60;Timeout=60;customdata=jasper.jia",
		"paneId": "001",
		"timeHierarchyIndex": 0,
		"userName": "jasper.jia",
		"userDomain": "halo.nz",
		"userType": "Administrator",
		"userEmail": null,
		"url": "http://localhost/HaloTrunk/?view=Users%7cjasper.jia%7cForecasting"
	},
	"hierarchies": [
		{
			"periodicity": "Period",
			"dateRangeCount": 0,
			"dateRangeLag": 0,
			"isoDates": [],
			"type": "Time",
			"name": "YQMD",
			"uniqueName": "[Time].[YQMD]",
			"levelName": "Date",
			"levelUniqueName": "[Time].[YQMD].[Date]",
			"dimensionName": "Time",
			"memberNames": [
				"20170630"
			],
			"memberUniqueNames": [
				"[Time].[YQMD].[Year].&[2017].&[20172].&[201706].&[2017-06-30T00:00:00]"
			]
		},
		{
			"type": "Measures",
			"name": "Measures",
			"uniqueName": "[Measures]",
			"levelName": null,
			"levelUniqueName": null,
			"dimensionName": "Measures",
			"memberNames": [
				""
			],
			"memberUniqueNames": [
				"[Measures].[Sales]"
			]
		},
		{
			"type": "Standard",
			"name": "Package Size",
			"uniqueName": "[Package Size].[Package Size]",
			"levelName": "Package Size",
			"levelUniqueName": "[Package Size].[Package Size].[Package Size]",
			"dimensionName": "Package Size",
			"memberNames": [
				"1/2 BBL"
			],
			"memberUniqueNames": [
				"[Package Size].[Package Size].&[1/2 BBL]"
			]
		},
		{
			"type": "Standard",
			"name": "Categories",
			"uniqueName": "[Product].[Categories]",
			"levelName": "SKU",
			"levelUniqueName": "[Product].[Categories].[SKU]",
			"dimensionName": "Product",
			"memberNames": [
				"All"
			],
			"memberUniqueNames": [
				"[Product].[Categories].[All]"
			]
		}
	],
	"cube": {
		"server": "LOCALHOST",
		"catalog": "Beverage",
		"cube": "Sales"
	}
} }
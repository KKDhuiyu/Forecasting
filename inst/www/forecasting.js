function forecast_R_plot(values, algo, starty, startm, startd, endy, endm, endd, freq) {
    $("#plotdiv").empty();
    //        request 1: plot
    var req = $("#plotdiv").rplot("plot_forecasting", {
        mydata: values,
        algo: algo,
        starty: starty,
        startm: startm,
        endy: endy,
        endm: endm,
        startd: startd,
        endd: endd,
        freq: "day"

    }, function (session) {});

    req.fail(function () {
        alert("Server error: " + req.responseText);
    });
    req.always(function () {});

}

function model_name_print(values, algo, starty, startm, startd, endy, endm, endd, freq) {
    // request 3: model method 
    var req3 = ocpu.call("print_model", {
        mydata: values,
        algo: algo,
        starty: starty,
        startm: startm,
        endy: endy,
        endm: endm,
        startd: startd,
        endd: endd,
        freq: "day"

    }, function (session) {
        session.getConsole(function (output) {
            text = "Model: " + output.slice(output.lastIndexOf("forecast"), );
            $("#model_method").text(text);
        });


    });
    req3.fail(function () {
        alert("Server error: " + req3.responseText);
    });
    req3.always(function () {

    });
}

function decomposition_R_plot(values, algo, starty, startm, startd, endy, endm, endd, freq) {
    //request 4: plot decomposition 
    var req = $("#decomp_plot").rplot("plot_decomposition", {
        mydata: values,
        algo: algo,
        starty: starty,
        startm: startm,
        endy: endy,
        endm: endm,
        startd: startd,
        endd: endd,
        freq: "day"

    }, function (session) {});

    req.fail(function () {
        alert("Server error: " + req4.responseText);
    });
    req.always(function () {});
}

function set_toggle() {
    // toggle 
    $('#history_data').click(function () {
        $("#input").toggle();
    });

    $('#forecasting_header').click(function () {
        $("#forecasting").toggle();
    });
    $('#decomposition_header').click(function () {
        $("#decomposition").toggle();
    });

}

function show_table(values) {
    // show data in table
    var table = $('#inputTable');
    var row, cell;
    row = $('<tr />');
    table.append(row);
    for (i = 0; i < values.length; i++) {
        if (i % 12 === 0 && i !== 0) {
            row = $('<tr />');
            table.append(row);
        }

        cell = $('<td>' + parseInt(values[i]) + '           </td       >');
        row.append(cell);
    }
}
// function for plotting 
function plot_daily_charts(values, algo, starty, startm, startd, endy, endm, endd, freq, s_date, e_date, null_list) {

    var algo = $('#algorithms').find(":selected").val();
    // request 2: summary 
    var req2 = ocpu.call("get_csv", {
        mydata: values,
        algo: algo,
        starty: starty,
        startm: startm,
        endy: endy,
        endm: endm,
        startd: startd,
        endd: endd,
        freq: "day"

    }, function (session) {

        $("#csvlink").attr("href", session.getLoc() + "R/.val/csv");
        // d3.js
        Plotly.d3.csv(session.getLoc() + "R/.val/csv", function (err, rows) {

            function unpack1(rows, key, e_date) {
                return rows.map(function (row) {
                    if (new Date(row['Date']) <= e_date) {

                        return row[key];
                    } else {
                        return null;
                    }
                });
            }

            function unpack2(rows, key, e_date) {
                return rows.map(function (row) {
                    if (new Date(row['Date']) >= e_date) {

                        return row[key];
                    } else {
                        return null;
                    }
                });
            }
            var history_date = unpack1(rows, 'Date', e_date);
            var history_data = unpack1(rows, 'Value', e_date);
            var forecast_date = unpack2(rows, 'Date', e_date);
            var forecast_data = unpack2(rows, 'Value', e_date);

            for (i = 0; i < null_list.length; i++) {
                history_data[null_list[i]] = null;
            }
            ////////////////////////


            // high chart plot
            var history_highchart = [];
            var forecast_highchart = [];

            for (i = 0; i < history_data.length; i++) {
                if (history_date[i] !== null) {
                    history_highchart.push([new Date(history_date[i]).getTime(), parseFloat(history_data[i])]);
                }
            }
            for (i = 0; i < forecast_data.length; i++) {
                if (forecast_date[i] !== null) {
                    forecast_highchart.push([new Date(forecast_date[i]).getTime(), parseFloat(forecast_data[i])]);
                }
            }

            Highcharts.chart('testDiv', {
                chart: {
                    zoomType: 'x'
                },
                title: {
                    text: starty.toString() + "-" + startm.toString() + "-" + startd.toString() + " to " + endy.toString() + "-" + endm.toString() + "-" + endd.toString() + " Data and Its 30 Days' Forecasting"
                },
                subtitle: {
                    text: document.ontouchstart === undefined ? 'Click and drag in the plot area to zoom in' : 'Pinch the chart to zoom in'
                },
                xAxis: {
                    type: 'datetime'
                },
                yAxis: {
                    title: {
                        text: 'Sales'
                    }
                },
                legend: {
                    enabled: true
                },
                plotOptions: {
                    area: {
                        fillColor: {
                            linearGradient: {
                                x1: 0,
                                y1: 0,
                                x2: 0,
                                y2: 1
                            },
                            stops: [
                            [0, Highcharts.getOptions().colors[0]],
                            [1, Highcharts.Color(Highcharts.getOptions().colors[0]).setOpacity(0).get('rgba')]
                        ]
                        },
                        marker: {
                            radius: 2
                        },
                        lineWidth: 1,
                        states: {
                            hover: {
                                lineWidth: 1
                            }
                        },
                        threshold: null
                    }
                },

                series: [{
                    // type: 'area',
                    name: 'History Data',
                    data: history_highchart,
                    marker: {
                        enabled: true,
                        radius: 2
                    }
            }, {
                    // type: 'area',
                    name: 'Forecasting Data',
                    data: forecast_highchart
            }]
            });



            ///////////////
            var trace1 = {
                type: "scatter",
                mode: 'lines+markers',
                name: "History",
                x: unpack1(rows, 'Date', e_date),
                y: history_data,
                line: {
                    color: '#17BECF'
                }
            }

            var trace2 = {
                type: "scatter",
                mode: 'lines+markers',
                name: "Forecasting",
                x: unpack2(rows, 'Date', e_date),
                y: unpack2(rows, 'Value', e_date),
                line: {
                    color: '#7F7F7F'
                }
            }


            var data = [trace1, trace2];

            var layout = {
                title: starty.toString() + "-" + startm.toString() + "-" + startd.toString() + " to " + endy.toString() + "-" + endm.toString() + "-" + endd.toString() + " Data and Its 30 Days' Forecasting",
                xaxis: {
                    range: [s_date, e_date + 30],
                    type: 'date'
                },
                yaxis: {
                    autorange: true,
                    range: [86.8700008333, 138.870004167],
                    type: 'linear'
                },

                legend: {
                    "orientation": "h",
                    xanchor: "center",
                    x: 0.5
                }
            };

            Plotly.newPlot('plotdiv', data, layout);
        })

        //d3.js done.
    });
    req2.fail(function () {
        alert("Server error: " + req2.responseText);
    });
    req2.always(function () {

    });

}

function generate_view(prism) {
    ocpu.seturl("https://opencpu.halobicloud.com/ocpu/apps/kkdhuiyu/Forecasting/R")


    // tidy data from prism 
    var inputs = prism.pane.rows.slice(0, -1);
    var values = [];
    var starty = parseInt(inputs[0].data[1].value.slice(0, 4));
    var startm = parseInt(inputs[0].data[1].value.slice(4, 6));
    var startd = parseInt(inputs[0].data[1].value.slice(6, 8));
    var endy = parseInt(inputs[inputs.length - 1].data[1].value.slice(0, 4));
    var endm = parseInt(inputs[inputs.length - 1].data[1].value.slice(4, 6));
    var endd = parseInt(inputs[inputs.length - 1].data[1].value.slice(6, 8));
    var e_date = new Date(endy.toString() + "-" + endm.toString() + "-" + endd.toString());
    var s_date = new Date(starty.toString() + "-" + startm.toString() + "-" + startd.toString());
    var null_list = [];
    var freq = prism.context.hierarchies[0].levelName;
    for (i = 0; i < inputs.length; i++) {
        if (inputs[i].data[2].value == "") {
            values.push(0.0);
            null_list.push(i);
        } else {
            values.push(parseFloat(inputs[i].data[2].value));
        }
    }


    $(document).ready(show_table(values));
    $(document).ready(set_toggle());
    $(document).ready(decomposition_R_plot(values, $('#algorithms').find(":selected").val(), starty, startm, startd, endy, endm, endd, freq));
    $(document).ready(model_name_print(values, $('#algorithms').find(":selected").val(), starty, startm, startd, endy, endm, endd, freq));
    $(document).ready(plot_daily_charts(values, $('#algorithms').find(":selected").val(), starty, startm, startd, endy, endm, endd, freq, s_date, e_date, null_list));
    $("#plotbutton").on("click", plot_daily_charts(values, $('#algorithms').find(":selected").val(), starty, startm, startd, endy, endm, endd, freq, s_date, e_date, null_list));
    $("#plotbutton").on("click", model_name_print(values, $('#algorithms').find(":selected").val(), starty, startm, startd, endy, endm, endd, freq));

}

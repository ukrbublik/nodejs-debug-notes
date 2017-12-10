var listenPort = 5000;

var cycle = require('cycle'); //buggy lib used by winston@2.x
var opn = require('opn');
var express = require('express');
var app = express();
var http = require('http').Server(app);

app.get('/', function(req, res, next) {
    res.sendFile(__dirname + '/index.html');
});

app.post('/runCpuIntensiveTask', function(req, res, next) {
    runCpuIntensiveTask();
    res.json({'res': "ok"});
});

function runCpuIntensiveTask() {
    let a = new Array();
    a[20000000] = a;
    //"cycle" lib handles sparsed arrays badly
    // (it lacks "if (value[i] !== undefined) " at line 84)
    let res = cycle.decycle(a);
}

if (process.argv.indexOf('prof') != -1) {
    runCpuIntensiveTask();
} else {
    http.listen(listenPort, function() {
        console.log("Listening on port "+listenPort);        
        opn('http://localhost:'+listenPort+'/');
    });
}
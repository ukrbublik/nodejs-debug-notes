var listenPort = 5001;

var opn = require('opn');
var express = require('express');
var app = express();
var http = require('http').Server(app);

app.get('/', function(req, res, next) {
    res.sendFile(__dirname + '/index.html');
});

app.post('/infLoop', function(req, res, next) {
    infLoopFunc();
    //code will never get here
    res.json({'res': "ok"});
});

function infLoopFunc() {
    //this will lock server
    while(1) {;}
}

http.listen(listenPort, function() {
    console.log("Listening on port "+listenPort);
    opn('http://localhost:'+listenPort+'/');
});

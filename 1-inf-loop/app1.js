var listenPort = 5001;

var opn = require('opn');
var express = require('express');
var app = express();
var http = require('http').Server(app);

app.get('/', function(req, res, next) {
    res.sendFile(__dirname + '/index.html');
});

app.post('/infLoop', function(req, res, next) {
    while(1) {;}
    res.json({'res': "ok"});
});

http.listen(listenPort, function() {
    console.log("Listening on port "+listenPort);
    opn('http://localhost:'+listenPort+'/');
});

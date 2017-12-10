var listenPort = 5002;
var workerId = 0;
var workerPrc = null;

var opn = require('opn');
var child_process = require('child_process');
var express = require('express');
var app = express();
var http = require('http').Server(app);
var io = require('socket.io')(http);

app.get('/', function(req, res, next) {
  res.sendFile(__dirname + '/index.html');
});

app.post('/recreateWorker', function(req, res, next) {
  console.log("Killing worker "+workerId);
  workerPrc.kill(1);
  createWorker();
  res.json({'res': "ok"});
});

function createWorker() {
  workerId++;
  let fullPath = __dirname + '/worker.js';
  workerPrc = child_process.fork(fullPath, [], {});
  console.log("Worker "+workerId+" created");
}

io.on('connection', function(client) {  
  console.log('+ client', client.id);

  client.on('disconnect', function() {
    console.warn('- client', client.id);
  });

  client.on('error', function(err) {
    console.error('! error', err);
  });
});

http.listen(listenPort, function() {
  console.log("Listening on port "+listenPort);
  createWorker();
  opn('http://localhost:'+listenPort+'/');
});


//console.log("I am worker");

//Stay alive for 5min
setTimeout(() => {
    console.log("I am worker and I am dying...");
}, 1000*60*5);

process.on('exit', () => {});


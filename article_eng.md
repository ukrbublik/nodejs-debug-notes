# Optimizing Node.js app - case from the trenches

(Translation of russian article: [https://habr.com/ru/post/344672/](https://habr.com/ru/post/344672/))

As you know, Node.js single-threaded architecture can make it hard to achieve and maintain high application performance. To do so, one must avoid bottlenecks that can lead to performance drops and stealing valuable CPU resource from the server app.

This article will explain how to monitor CPU loads of node.js app, how to locate code parts that cause high resource consumption as well as how to address issues with 100% CPU load.

![nodejs cpu burn](https://qualidadeeti.files.wordpress.com/2015/11/burning-cpu.jpg)

## 1. CPU Profiling Tools

Luckily, there is a number of available tools to analyze and visualize hot spots of CPU load.

### Chrome DevTools Inspector

As a first options, we'll look at Chrome DevTools profiler that connects to Node.js app via WebSocket (standard `9229` port).

Launch node.js app with `--inspect` flag (a default `9229` port will be used unless you specify `--inspect=<port> flag`).
In case you have a Node.js server app running within a Docker container, you should launch it with `--inspect=0.0.0.0:9229` and open this port in Dockerfile or docker-compose.yml.
Launch `chrome://inspect` in your browser.
![inspector](https://github.com/ukrbublik/nodejs-debug-notes/blob/master/resources/0-a-inspector.png?raw=true)

Find your application in "Remote target" list and press "inspect". A window similar to standard "browser" version of Chrome DevTools should open. We are looking for "Profiler" tab that can record CPU profile of an app while it's running:
![profiler](https://github.com/ukrbublik/nodejs-debug-notes/blob/master/resources/0-b-profiler.png?raw=true)

Once recording has been completed, the Profiler will display the info in convenient table-tree view with details on each function runtime - in ms and % of the overall recording time (see below).

Let's try it with a sample app can be cloned from [here](https://github.com/ukrbublik/nodejs-debug-notes/tree/master/0-profiling).
It exploits a bottleneck in the [cycle](https://www.npmjs.com/package/cycle) library (that in turn is used in another popular library [winston v2.x](https://github.com/winstonjs/winston/tree/2.x)) to emulate JS code with high CPU loads.
We'll compare how original cycle library runs against my [corrected version](https://github.com/ukrbublik/nodejs-debug-notes/blob/master/0-profiling/fixed_cycle.js#L84).
To begin with, you should install the app and launch it with `npm run inspect`. Open the inspector and start recording the CPU profile. In the opened page http://localhost:5000/ select "Run CPU intensive task" and once completed (you should see "ok" alert) stop recording of CPU profile. Now you should see an overview of most greedy functions - in our case these are `runOrigDecycle()` and `runFixedDecycle()`. You can compare their shares, %:
![cpu profile tree](https://github.com/ukrbublik/nodejs-debug-notes/blob/master/resources/0-c-cpu-profile-tree-2.png?raw=true)

### Node.js Profiler

Another good option is using in-built Node.js profiler to create reports on CPU performance. Unlike inspector, it can provide data for the whole application run time .

Launch node.js app with `--prof` flag.
A file named like `isolate-0xXXXXXXX-v8.log` shall appear in the application folder that will register so called "ticks". Such data is illegible but can be made readable through running `node --prof-process <file isolate-0xXXXXXXX -v8.log>`. You can find a sample of such report for test application [here](https://raw.githubusercontent.com/ukrbublik/nodejs-debug-notes/master/resources/0-d-prof-report.txt). To generate a report yourself, simply run `npm run prof`.

There are also npm packages that allow profiling - such as [v8-profiler](https://github.com/node-inspector/v8-profiler), that provides JS interface for V8 profiler API as well as node-inspector (that became obsolete after the release of in-built Chrome DevTools profiler).


## 2. Dealing with blocking JS code without inspector

Let's assume that your code contains an infinite loop or some problem that fully blocks running node.js code on the server. In such case the only node.js thread will be blocked, server will stop responding to requests and CPU load will jump to 100%. Unless the inspector was already running before server had been blocked , you won't be able to locate the faulty code.

Here you can try the [gdb](https://www.gnu.org/software/gdb/) debugger.

For Docker container you should use this flag for run command :
`--cap-add=SYS_PTRACE`
And install packages:
`apt-get install libc6-dbg libc-dbg gdb valgrind`
Now you have to connect to node.js process (need to know its pid):
`sudo gdb -p <pid>`

After you connect, run the following commands:
```
b v8::internal::Runtime_StackGuard
p 'v8::Isolate::GetCurrent'()
p 'v8::Isolate::TerminateExecution'($1)
c
p 'v8::internal::Runtime_DebugTrace'(0, 0, (void *)($1))
quit
```

I won't describe in detail what is the purpose of each command, but I will briefly mention that they use some of the internal features of [V8 engine](https://github.com/v8/v8).

As a result of above mentioned commands, running of blocking JS code in the current "tick" will be terminated and the application will continue to run (if you are using Express, the application will be able to further process requests), while the standard node.js output stream will contain stack trace.

Stack trace will be [rather long](https://github.com/ukrbublik/nodejs-debug-notes/blob/master/resources/1-gdb-stack-trace.txt) but may contain useful information - stack of JS functions invocations.

Lines like these should help identifying the faulty code :
```js
--------- s o u r c e   c o d e ---------
function infLoopFunc() {\x0a    //this will lock server\x0a    while(1) {;}\x0a}
-----------------------------------------
```

For your convenience, I created a script that saves the stack into a separate log file: [loop-terminator.sh](https://github.com/ukrbublik/nodejs-debug-notes/blob/master/1-break-inf-loop/loop-terminator.sh).

Here is a more [vivid example](https://github.com/ukrbublik/nodejs-debug-notes/tree/master/1-break-inf-loop) of how it can be used in an actual application.


## 3. Update Node.js and npm packages!

Sometimes it's not your fault :)

I found a weird bug in node.js < v8.5.0 (checked on 8.4.0 and 8.3.0), that under certain circumstances causes 100% load of a single CPU core. [Here](https://github.com/ukrbublik/nodejs-debug-notes/tree/master/2-ws-bug) you can find the code to reproduce the issue.

What happens is the application launches WebSocket server (using [socket-io](https://socket.io/)) and a single child process with `child_process.fork()`. The following steps guarantee 100% load for a single CPU core :

1. Client connects to WebSocket server
2. Child process is being killed and the new one is spawned
3. Client disconnects from WebSocket server

Meanwhile, the application keeps running and Express is responding to requests. The bug is most likely located in libuv rather than in node.js itself. I had no luck locating the true source of the bug or commit that would fix it in changelogs. Some googling showed there were similar bugs in older versions:
[https://github.com/joyent/libuv/issues/1099](https://github.com/joyent/libuv/issues/1099)
[https://github.com/nodejs/node-v0.x-archive/issues/6271](https://github.com/nodejs/node-v0.x-archive/issues/6271)

The solution is simple - update node.js to v8.5.0 or higher.


## 4. Use child processes

When your server application contains code that causes significant CPU loads, it might be smart to isolate it within a separate child process. For instance, it might be server-side rendering of a React app.

Create a separate Node.js application and launch it from the core one with [child_process.fork()](https://nodejs.org/api/child_process.html#child_process_child_process_fork_modulepath_args_options). Use `IPC` channel to connect these processes. It is rather easy to set up a communication flow between the processes - as `ChildProcess` is a child of `EventEmitter`. While a feasible solution, remember it is not recommended to spawn a lot of node.js child processes.


When considering performance optimization, remember another important indicator such as RAM consumption. While there are a number of tools and methods to locate and analyze memory leaks, it sounds like a topic for a separate article.


(Full source code of samples used in this article can be found here: [https://github.com/ukrbublik/nodejs-debug-notes](https://github.com/ukrbublik/nodejs-debug-notes))

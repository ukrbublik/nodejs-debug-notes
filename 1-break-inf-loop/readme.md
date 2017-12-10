Install gdb:  
 `sudo apt-get install libc6-dbg gdb valgrind`  
Install packages:  
 `npm i`

Start server:  
 `npm run start`  
Browser with url `http://localhost:5001/` should be opened.  

At page click "Make inf loop".  
Server should be fully blocked with 100% CPU usage (see `htop`).

To break inf loop run:  
 `npm run terminate-loop`  
Stack trace should be saved to `gdb-logs` dir.  
You can find guilty piece of code here.  
(Also server can continue working)

---

See `loop-terminator.sh`

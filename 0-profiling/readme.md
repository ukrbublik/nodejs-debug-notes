Install packages:  
 `npm i`

Start server in inspect mode:  
 `npm run inspect`  
Browser with url `http://localhost:5000/` should be opened.  
Open inspector `chrome:://inspect`, click `Run CPU intensive task` and record CPU profile.
(See detailed instructions on app's html page)

or

Start app in prof mode:  
 `npm run prof`  
App will run without starting server, execute CPU intensive task and close.
Profile report will be generated automatically and put in `prof-reports` dir.  
You can investigate it for `runCpuIntensiveTask()` call.

---

More info:  
https://nodejs.org/uk/docs/guides/simple-profiling/  
https://nodejs.org/en/docs/inspector/  


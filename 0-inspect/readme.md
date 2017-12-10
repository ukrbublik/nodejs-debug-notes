Install packages:  
 `npm i`

Start server in inspect mode:  
 `npm run inspect`  
Browser with url `http://localhost:5001/` should be opened. 
Open inspector `chrome:://inspect`, click `Run CPU intensive task` and record CPU profile.


Start app in prof mode:  
 `npm run prof`  
Profile report will be generated automaticalled and put in `prof-reports` dir.  
You can investigate it for `runCpuIntensiveTask()` call.

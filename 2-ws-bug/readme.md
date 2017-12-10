For nodejs < 8.5.0 (tested on 8.4.0)

Install packages:  
 `npm i`  
Use nodejs < 8.5.0:  
 `nvm install 8.4.0`  
 `nvm use 8.4.0`

Start server:  
 `npm run start`  
Browser with url `http://localhost:5002/` should be opened.  
Socket connection should be automatically established (first button will have name "Connected" and be disabled).  

After WS is connected, press "Recreate worker", then "Disconnect".  
You will get 100% load of 1 CPU core on server (see `htop`).

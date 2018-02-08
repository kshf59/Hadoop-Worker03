# app-tag-settings

This is the component for the app-tag-settings tab. 

The current architecture splits the app settings tabs across several components. As of 4/2017, they can be 
found here:

-  `controller/appsettings.js`
-  `controllers/access.js`
-  `controllers/appinfo.js`
-  `controllers/output.js` 
-  `controllers/procs.js`
-  `components/documents/variants/*`
-  `/modules/runtime/*`

In the future, we may consolidate them into one or two components (angular/redux).

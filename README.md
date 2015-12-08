# cf-google-drive
Using Google Drive API + Service Account + Coldfusion

Accessing Google Drive API with Service Account and Coldfusion

Found jensbits https://github.com/jensbits/CF-GA-service and made a ColdFusion Drive service built from this since there's not much in the way of CF Drive.  Some of the functions in cfdrive.cfc are written specifically for my app's requirements...so do as you wish to them...hopefully someone can use this and save hours of work...


Set up credentials for accessing Google Drive as a service:
-----------------------------------------------

1. Create your project in the Google console: https://code.google.com/apis/console

2. Go to API's & Auth and turn on Drive API

3. Go to Credentials (under API's) and click Create a New Client ID.

4. Select Service Account from the pop up.

5. Save the .p12 file it will prompt you to download to a non-browsable place on your webserver. Feel free to rename it but keep the .p12 extension.

6. The service account email address will be under the Service Account setting box as Email Address and be in the form of xxxxxxxxxxxxxx@developer.gserviceaccount.com (the really long email). 



Add the .jar files to the CF server
-----------------------------------

1. Add the Google Drive API client library .jar files to the CF server in the WEB-INF/lib folder.  The files can be found here: https://developers.google.com/api-client-library/java/apis/drive/v2  The readme.html will list the dependencies.

2. Restart the CF server (if you installed the .jar files directly on the server).

Save the cfdrive.cfc to your web root
-----------------------------------------

1. Save the cfdrive file to your web root or where you keep your com objects.

2. init() the cfdrive object. This can be done as an application variable. The pathToKeyFile = expandPath("/your-path-to-key-file/your-key-name.p12"). Make sure this is non-browsable!

3. Call any existing method I've written or write your own...



Usage in cfscript
-------------------
```javascript

application.cfdrive = createObject("component", "services.cfdrive").init(
                                        serviceAccountID:"",
                                        serviceAccountEmail:"",
                                        pathToKeyFile:expandPath("PATH_TO_YOUR.p12"), 
                                        applicationName:"The Real Donald Trump");

//Example 1
var g=application.cfdrive.buildDrive();
var title="Donald Trump 2016 Presentation"; 
var filename="fascist-talking-points.pdf"; 	//i.e. the absolute path to bigotry and hatred
var mimeType="application/pdf"; 			
var muricaResponse = application.cfdrive.insertFile(title,filename,mimeType);
WriteDump(var=muricaResponse;

//Example 2
var fileId=muricaResponse.getId();
var file=application.cfdrive.getFile(fileId); 
writeDump(var=file);

//Example 3...see https://developers.google.com/drive/v2/reference/permissions
var msg="New File Uploaded message or some other nifty message...";
var role='writer';
var value='some-email@donaldtrump.sucks';
var type='user';

//Example 4
jsonPermissionResponse=application.cfdrive.insertPermission(fileId,msg,role,value,type);
writeDump(var=jsonPermissionResponse);

//Example 5
jsonPropertyResponse=application.cfdrive.insertProperty(fileId,'status','pending','PUBLIC');
writeDump(var=jsonPropertyResponse);

//Example 6: Now let's see the dumps changes after the aforementioned changes...
fileStruct = application.cfdrive.getFile(fileId);
json_response = application.cfdrive.filterDriveResponse(fileStruct);
writeDump(var=json_response);
```


Resources
-------------------
*https://developers.google.com/resources/api-libraries/documentation/drive/v2/java/latest/

*https://developers.google.com/api-client-library/java/apis/drive/v2

*https://github.com/jensbits/CF-GA-service


Questions
-------------------
email me at paulcommons at gmail dot com
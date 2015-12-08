<cfcomponent displayname="cfdrive" output="false">
   <cffunction name="init" access="public" output="false" returntype="Cfdrive">
      <cfargument name="serviceAccountId" type="string" required="true" />
      <cfargument name="serviceAccountEmail" type="string" required="true" />
      <cfargument name="pathToKeyFile" type="string" required="true" />
      <cfargument name="applicationName" type="string" required="true" />
      <cfscript>
         variables.serviceAccountId         = arguments.serviceAccountId;
         variables.serviceAccountEmail      = arguments.serviceAccountEmail;
         variables.pathToKeyFile            = arguments.pathToKeyFile;
         variables.applicationName		   = arguments.applicationName;
         variables.HTTP_Transport           = createObject("java", "com.google.api.client.http.javanet.NetHttpTransport").init();
         variables.JSON_Factory             = createObject("java", "com.google.api.client.json.jackson2.JacksonFactory").init();
         variables.HTTP_Request_Initializer = createObject("java", "com.google.api.client.http.HttpRequestInitializer");
         variables.File_Content			   = createObject("java", "com.google.api.client.http.FileContent");
         variables.Credential_Builder       = createObject("java", "com.google.api.client.googleapis.auth.oauth2.GoogleCredential$Builder");
         variables.Drive_Scopes         	   = createObject("java", "com.google.api.services.drive.DriveScopes");
         variables.Drive_Builder            = createObject("java", "com.google.api.services.drive.Drive$Builder").init(
         variables.HTTP_Transport, 
         variables.JSON_Factory, 
         javaCast("null", ""));
         variables.Drive_File	           = createObject("java", "com.google.api.services.drive.model.File");
         variables.Permission	           = createObject("java", "com.google.api.services.drive.model.Permission");
         variables.Parents	          	   = createObject("java", "com.google.api.services.drive.model.ParentReference");
         variables.Property	               = createObject("java", "com.google.api.services.drive.model.Property");
         variables.Collections              = createObject("java", "java.util.Collections");
         variables.File_Obj                 = createObject("java", "java.io.File");
         variables.Arrays                   = createObject("java", "java.util.Arrays");
         variables.credential 			   = "";
         variables.service                  = "";
      </cfscript>
      <cfreturn this />
   </cffunction>


   <cffunction name="buildDrive" access="public" output="false" returntype="struct" hint="creates drive object">
      <cfset local = {} />
      <cfset local.credential = "" />
      <cfset local.returnStruct = {} />
      <cfset local.returnStruct.success = true />
      <cfset local.returnStruct.error = "" />
      <!--- Access tokens issued by the Google OAuth 2.0 Authorization Server expire in one hour. 
         When an access token obtained using the assertion flow expires, then the application should 
         generate another JWT, sign it, and request another access token. 
         "https://www.googleapis.com/auth/drive","https://www.googleapis.com/auth/analytics"
         https://developers.google.com/accounts/docs/OAuth2ServiceAccount --->
      <cftry>
         <cfset local.credential = Credential_Builder
         .setTransport(variables.HTTP_Transport)
         .setJsonFactory(variables.JSON_Factory)
         .setServiceAccountId(variables.serviceAccountEmail)
         .setServiceAccountScopes(Collections.singleton(variables.Drive_Scopes.DRIVE))
         .setServiceAccountPrivateKeyFromP12File(variables.File_Obj.Init(variables.pathToKeyFile))
         .build() />
         <cfcatch type="any">
            <cfset local.returnStruct.error = "Credential Object Error: " & cfcatch.message & " - " & cfcatch.detail />
            <cfset local.returnStruct.success = false />
         </cfcatch>
      </cftry>
      <cfif  local.returnStruct.success>
         <cftry>
            <cfset variables.service = variables.Drive_Builder
            .setApplicationName(variables.applicationName)
            .setHttpRequestInitializer(local.credential)
            .build() />
            <cfcatch type="any">
               <cfset local.returnStruct.error = "Drive Object Error: " & cfcatch.message & " - " & cfcatch.detail />
               <cfset local.returnStruct.success = false />
            </cfcatch>
         </cftry>
      </cfif>
      <cfreturn local />
   </cffunction>


   <cffunction name="getAccessToken" access="public" output="false" returntype="any" hint="">
      <cfargument name="build" type="struct" required="true" />
      <cfset local = {} />
      <cfset local.results = {} />
      <cfset local.results.error = "" />
      <cftry>
         <cfset local.results = build.credential.getAccessToken() />
         <cfcatch type="any">
            <cfset local.results.error = cfcatch.message & " " & cfcatch.detail />
         </cfcatch>
      </cftry>
      <cfreturn local.results />
   </cffunction>
   <cffunction name="getFile" access="public" output="false" returntype="struct" hint="">
      <cfargument name="fileId" type="string" required="true" />
      <cfset local = {} />
      <cfset local.results = {} />
      <cfset local.results.error = "" />
      <cftry>
         <cfset local.results = variables.service.files().get(fileId).execute()/>
         <cfcatch type="any">
            <cfset local.results.error = cfcatch.message & " " & cfcatch.detail />
         </cfcatch>
      </cftry>
      <cfreturn local.results />
   </cffunction>


   <cffunction name="getFileByTypeFromFolder" access="public" output="false" returntype="struct" hint="">
      <cfargument name="parentId" type="string" required="true" />
      <cfargument name="fileType" type="string" required="true" />
      <cfset local = {} />
      <cfset local.results = {} />
      <cfset local.results.error = "" />
      <cftry>
         <cfset local.results = variables.service.files().list().setQ("'"&parentId&"' in parents and properties has {key='fileType' and value='#fileType#' and visibility='PUBLIC'}").execute()/>
         <cfscript>
            if (!ArrayIsEmpty(local.results["items"])) {
            local.results = local.results.getItems().get(0);
            }
         </cfscript>
         <cfcatch type="any">
            <cfset local.results.error = cfcatch.message & " " & cfcatch.detail />
         </cfcatch>
      </cftry>
      <cfreturn local.results />
   </cffunction>


   <cffunction name="deleteFileById" access="public" returntype="any">
      <cfargument name="fileId" type="string" required="true" />
      <cfset local = {} />
      <cfset local.results = {} />
      <cfset local.results.error = "" />
      <cftry>
         <cfset local.results = variables.service.files().delete(fileId).execute() />
         <cfset local.results = {removed: true}>
         <cfcatch type="any">
            <cfset local.results.error = cfcatch.message & " " & cfcatch.detail />
         </cfcatch>
      </cftry>
      <cfreturn local.results />
   </cffunction>


   <cffunction name="getFolderOrCreate" access="public" output="false" returntype="struct" hint="">
      <cfargument name="folderName" type="string" required="true" />
      <cfargument name="parentId" type="string" required="false" />
      <cfset local.folder = {}/>
      <cftry>
         <cfif !isdefined("parentId")>
         <cfset folder = variables.service.files().list().setQ("mimeType = 'application/vnd.google-apps.folder' and 'root' in parents and title = '" & folderName & "'").execute()/>
         <cfelse>
         <cfset folder = variables.service.files().list().setQ("mimeType = 'application/vnd.google-apps.folder' and '" & parentId & "' in parents and title = '" & folderName & "'").execute()/>
         </cfif>
         <cfscript>
            if (ArrayIsEmpty(folder["items"])) { // if not found
            if (isdefined("parentId")) { // insert into parent folder
            folder = insertFolder(folderName, parentId);
            } else { // create in root
            folder = insertFolder(folderName);
            }
            } else {
            folder = folder.getItems().get(0);
            }
         </cfscript>
         <cfcatch type="any">
            <cfset local.folder.error = cfcatch.message & " " & cfcatch.detail />
         </cfcatch>
      </cftry>
      <cfreturn folder />
   </cffunction>


   <cffunction name="getFolderByPath" access="public" output="true" returntype="struct" hint="">
      <cfargument name="clientName"   type="string" required="true" />
      <cfargument name="companyName"  type="string" required="true" />
      <cfargument name="locationName" type="string" required="true" />
      <cfargument name="employeeName" type="string" required="true" />
      <cftry>
         <cfscript>
            var clientFolder = getFolderOrCreate(clientName);
            var clientFolderId = clientFolder.getId();
            var companyFolder = getFolderOrCreate(companyName, clientFolderId);
            var companyFolderId = companyFolder.getId();
            var locationFolder = getFolderOrCreate(locationName, companyFolderId);
            var locationFolderId = locationFolder.getId();
            var employeeFolder = getFolderOrCreate(employeeName, locationFolderId);
            var employeeFolderId = employeeFolder.getId();
         </cfscript>
         <cfcatch type="any">
            <cfset local.results.error = cfcatch.message & " " & cfcatch.detail />
         </cfcatch>
      </cftry>
      <cfreturn {
      clientFolder:   {id: clientFolderId},
      companyFolder:  {id: companyFolderId},
      locationFolder: {id: locationFolderId},
      employeeFolder: {id: employeeFolderId}
      } />
   </cffunction>


   <cffunction name="updateFileTitleAndHierarchy" access="public" output="false" returntype="struct" hint="">
      <cfargument name="fileId" type="string" required="true" />
      <cfargument name="title" type="string" required="true" />
      <cfargument name="clientId" type="string" required="false" />
      <cfargument name="companyId" type="string" required="false" />
      <cfargument name="locationId" type="string" required="false" />
      <cfargument name="employeeId" type="string" required="false" />
      <cfset local = {} />
      <cfset local.results = {} />
      <cfset local.results.error = "" />
      <cftry>
         <cfset gfile = variables.service.files().get(fileId).execute()/>
         <cfset gfile.setTitle(title)>
         <cfset local.results = variables.service.files().update(fileId, gfile).execute()/>
         <cfif isdefined("clientId")>
         <cfset newParent=createObject("java", "com.google.api.services.drive.model.ParentReference").init().setId(clientId)>
         <cfset parentResults = variables.service.parents().insert(local.results['id'],newParent).execute()/>
         </cfif>
         <cfif isdefined("companyId")>
         <cfset newParent=createObject("java", "com.google.api.services.drive.model.ParentReference").init().setId(companyId)>
         <cfset parentResults = variables.service.parents().insert(local.results['id'],newParent).execute()/>
         </cfif>
         <cfif isdefined("locationId")>
         <cfset newParent=createObject("java", "com.google.api.services.drive.model.ParentReference").init().setId(locationId)>
         <cfset parentResults = variables.service.parents().insert(local.results['id'],newParent).execute()/>
         </cfif>
         <cfif isdefined("employeeId")>
         <cfset newParent=createObject("java", "com.google.api.services.drive.model.ParentReference").init().setId(employeeId)>
         <cfset parentResults = variables.service.parents().insert(local.results['id'],newParent).execute()/>
         </cfif>
         <cfcatch type="any">
            <cfset local.results.error = cfcatch.message & " " & cfcatch.detail />
         </cfcatch>
      </cftry>
      <cfreturn local.results />
   </cffunction>


   <cffunction name="dirList" access="public" output="false" returntype="struct" hint="">
      <cfset local = {} />
      <cfset local.results = {} />
      <cfset local.results.items = ArrayNew(3) />
      <cfset local.results.error = "" />
      <cftry>
         <cfset local.results.items = variables.service.files().list().setQ("mimeType = 'application/vnd.google-apps.folder' ").execute()/>
         <cfcatch type="any">
            <cfset local.results.error = cfcatch.message & " " & cfcatch.detail />
         </cfcatch>
      </cftry>
      <cfreturn local.results />
   </cffunction>
   <cffunction name="listFiles" access="public" output="false" returntype="struct" hint="">
      <cfset local = {} />
      <cfset local.results = {} />
      <cfset local.results.items = ArrayNew(3) />
      <cfset local.results.error = "" />
      <cftry>
         <cfset local.results.items = variables.service.files().list().execute().getItems()/>
         <cfcatch type="any">
            <cfset local.results.error = cfcatch.message & " " & cfcatch.detail />
         </cfcatch>
      </cftry>
      <cfreturn local.results />
   </cffunction>


   <cffunction name="listFilesInFolder" access="public" output="false" returntype="struct" hint="I list all files directly within the folder ID provided">
      <cfargument name="fileId" type="string" required="true" />
      <cfset local = {} />
      <cfset local.results = {} />
      <cfset local.results.error = "" />
      <cftry>
         <cfset local.results = variables.service.files().list().setQ("'"&fileId&"' in parents").execute()/>
         <cfcatch type="any">
            <cfset local.results.error = cfcatch.message & " " & cfcatch.detail />
         </cfcatch>
      </cftry>
      <cfreturn local.results />
   </cffunction>
   <cffunction name="listPending" access="public" output="false" returntype="struct" hint="I list all files with pending status in a given folder">
      <cfargument name="baseFolder" type="string" required="true" />
      <cfargument name="all" type="boolean" required="false" default=false/>
      <cfset local = {} />
      <cfset local.results = {} />
      <cfset local.results.error = "" />
      <cftry>
         <cfif all>
            <cfset local.results = variables.service.files().list().setQ("properties has {key='status' and value='pending' and visibility='PUBLIC'}").execute()/>
            <cfelse>
            <cfset local.results = variables.service.files().list().setQ("properties has {key='status' and value='pending' and visibility='PUBLIC'} and '"&baseFolder&"' in parents").execute()/>
         </cfif>
         <cfcatch type="any">
            <cfset local.results.error = cfcatch.message & " " & cfcatch.detail />
         </cfcatch>
      </cftry>
      <cfreturn local.results />
   </cffunction>


   <cffunction name="generateId" access="public" output="false" returntype="struct" hint="">
      <cfset local = {} />
      <cfset local.results = {} />
      <cfset local.results.error = "" />
      <cftry>
         <cfset local.results = variables.service.files().generateIds().setSpace("drive").setMaxResults(1).execute() />
         <cfcatch type="any">
            <cfset local.results.error = cfcatch.message & " " & cfcatch.detail />
         </cfcatch>
      </cftry>
      <cfreturn local.results />
   </cffunction>


   <cffunction name="downloadToBrowser" access="public">
      <cfargument name="downloadUrl" type="string" required="true" />
      <cfargument name="mimeType" type="string" required="true" />
      <cfargument name="fileName" type="string" required="true" />
      <cfset fname=ReReplace(fileName,"[[:space:]]","_","ALL")>
      <cfset tempDir  = getTempDirectory() />
      <cfset tempFile = getFileFromPath(getTempFile(tempDir, fname)) />
      <cfhttp result="get" url="#downloadUrl#" method="get" getAsBinary="yes" />
      <cfheader name="Content-Disposition" value="attachment; filename=#fname#" />
      <cfcontent type="text/plain" reset="true" variable="#ToBinary(ToBase64(get.fileContent))#"/>
   </cffunction>


   <cffunction name="downloadFile" access="public" hint="">
      <cfargument name="fileId" type="string" required="true" />
      <cfset local = {}/>
      <cfset local.download = variables.service.files().get(fileId).executeMediaAsInputStream() />
      <cfdump var="#local.download.read()#" abort="true">
      <cfheader name="Content-Disposition" value="attachment; filename=test.pdf" />
      <cfcontent type="application/pdf" reset="true" variable="#ToBinary(ToBase64(local.download.toByteArray()))#"/>
   </cffunction>


   <cffunction name="getExportLinks" access="public" output="false" returntype="struct" hint="">
      <cfargument name="fileId" type="string" required="true" />
      <cfset local = {} />
      <cfset local.results = {} />
      <cfset local.results.error = "" />
      <cftry>
         <cfset local.file = variables.service.files().get(fileId).execute()/>
         <cfset local.results=local.file.getExportLinks()>
         <cfcatch type="any">
            <cfset local.results.error = cfcatch.message & " " & cfcatch.detail />
         </cfcatch>
      </cftry>
      <cfreturn local.results />
   </cffunction>


   <cffunction name="getDownloadUrl" access="public" output="false" returntype="struct" hint="">
      <cfargument name="fileId" type="string" required="true" />
      <cfset local = {} />
      <cfset local.results = {} />
      <cfset local.results.error = "" />
      <cftry>
         <cfset local.results = variables.service.files().get(fileId).execute().getWebContentLink()/>
         <cfset local.results = local.results.getWebContentLink()>
         <cfcatch type="any">
            <cfset local.results.error = cfcatch.message & " " & cfcatch.detail />
         </cfcatch>
      </cftry>
      <cfreturn local.results />
   </cffunction>


   <cffunction name="getThumbnailUrl" access="public" output="false" returntype="struct" hint="">
      <cfargument name="fileId" type="string" required="true" />
      <cfset local = {} />
      <cfset local.results = {} />
      <cfset local.file = {} />
      <cfset local.results.error = "" />
      <cftry>
         <cfset local.file = variables.service.files().get(fileId).execute()/>
         <cfset local.results.title = local.file.getTitle()>
         <cfset local.results.thumbnailLink = local.file.getThumbnailLink()>
         <cfset local.results.downloadLink = local.file.getDownloadUrl()>
         <cfcatch type="any">
            <cfset local.results.error = cfcatch.message & " " & cfcatch.detail />
         </cfcatch>
      </cftry>
      <cfreturn local.results />
   </cffunction>


   <cffunction name="updateFileId" access="public" output="false" returntype="struct" hint="">
      <cfargument name="fileId" type="string" required="true" />
      <cfargument name="title" type="string" required="true" />
      <cfset local = {} />
      <cfset local.results = {} />
      <cfset local.results.error = "" />
      <cftry>
         <cfset body = createObject("java", "com.google.api.services.drive.model.File").init()
         .setTitle(title)
         .setMimeType("application/vnd.google-apps.folder")
         .setDescription("")
         .setId(fileId) />
         <cfset local.results = variables.service.files().insert(body).execute()/>
         <cfcatch type="any">
            <cfset local.results.error = cfcatch.message & " " & cfcatch.detail />
         </cfcatch>
      </cftry>
      <cfreturn local.results />
   </cffunction>


   <cffunction name="insertFile" access="public" output="false" returntype="struct" hint="">
      <cfargument name="title" type="string" required="true" />
      <cfargument name="filename" type="string" required="true" />
      <cfargument name="mimeType" type="string" required="true" />
      <cfargument name="clientId" type="string" required="false" />
      <cfargument name="companyId" type="string" required="false" />
      <cfargument name="locationId" type="string" required="false" />
      <cfargument name="employeeId" type="string" required="false" />
      <cfset local = {} />
      <cfset local.results = {} />
      <cfset local.results.error = "" />
      <cftry>
         <cfset body = createObject("java", "com.google.api.services.drive.model.File").init()
         .setTitle(title)
         .setMimeType(mimeType)
         .setDescription("")
         .set("ocr",true)
         />
         <cfset fileContent = createObject("java", "java.io.File").init(filename)>
         <cfset mediaContent = createObject("java", "com.google.api.client.http.FileContent").init(mimeType,fileContent)>
         <cfset local.results = variables.service.files().insert(body,mediaContent).execute()/>
         <cfif isdefined("clientId")>
         <cfset newParent=createObject("java", "com.google.api.services.drive.model.ParentReference").init().setId(clientId)>
         <cfset parentResults = variables.service.parents().insert(local.results['id'],newParent).execute()/>
         </cfif>
         <cfif isdefined("companyId")>
         <cfset newParent=createObject("java", "com.google.api.services.drive.model.ParentReference").init().setId(companyId)>
         <cfset parentResults = variables.service.parents().insert(local.results['id'],newParent).execute()/>
         </cfif>
         <cfif isdefined("locationId")>
         <cfset newParent=createObject("java", "com.google.api.services.drive.model.ParentReference").init().setId(locationId)>
         <cfset parentResults = variables.service.parents().insert(local.results['id'],newParent).execute()/>
         </cfif>
         <cfif isdefined("employeeId")>
         <cfset newParent=createObject("java", "com.google.api.services.drive.model.ParentReference").init().setId(employeeId)>
         <cfset parentResults = variables.service.parents().insert(local.results['id'],newParent).execute()/>
         </cfif>
         <cfcatch type="any">
            <cfset local.results.error = cfcatch.message & " " & cfcatch.detail />
         </cfcatch>
      </cftry>
      <cfreturn local.results />
   </cffunction>


   <cffunction name="insertPermission" access="public" output="false" returntype="struct" hint="">
      <cfargument name="fileId" type="string" required="true" />
      <cfargument name="msg" type="string" required="false" default="" />
      <cfargument name="role" type="string" required="true" default="writer" />
      <cfargument name="v" type="string" required="false" default="paul.commons@retrotax-aci.com" />
      <cfargument name="type" type="string" required="true" default="user" />
      <cfset local = {} />
      <cfset local.results = {} />
      <cfset local.results.error = "" />
      <cflog
         text = "in insertPermission #v#"
         type = "information"
         application = "yes"
         file = "retro"
         log = "log type">
      <cftry>
         <cfset permission = createObject("java", "com.google.api.services.drive.model.Permission").init()
         .setType(type)
         .setRole(role)
         .setValue(v)
         .set('sendNotificationEmails',true) />
         <cfset local.results = variables.service.permissions().insert(fileId,permission).setEmailMessage(msg).setSendNotificationEmails(true).execute()/>
         <cfcatch type="any">
            <cfset local.results.error = cfcatch.message & " " & cfcatch.detail />
            <cflog
               text = "#local.results.error#"
               type = "information"
               application = "yes"
               file = "retro"
               log = "log type">
         </cfcatch>
      </cftry>
      <cfreturn local.results />
   </cffunction>


   <cffunction name="insertProperty" access="public" output="false" returntype="struct" hint="">
      <cfargument name="fileId" type="string" required="true" />
      <cfargument name="key" type="string" required="true" />
      <cfargument name="value" type="string" required="true" />
      <cfargument name="visibility" type="string" required="false" default="PUBLIC"/>
      <cfset local = {} />
      <cfset local.results = {} />
      <cfset local.results.error = "" />
      <cftry>
         <cfset property = createObject("java", "com.google.api.services.drive.model.Property").init()
         .setKey(key)
         .setVisibility(visibility)
         .setValue(value) />
         <cfset local.results = variables.service.properties().insert(fileId,property).execute()/>
         <cfcatch type="any">
            <cfset local.results.error = cfcatch.message & " " & cfcatch.detail />
         </cfcatch>
      </cftry>
      <cfreturn local.results />
   </cffunction>


   <cffunction name="updateProperty" access="public" output="false" returntype="struct" hint="">
      <cfargument name="fileId" type="string" required="true" />
      <cfargument name="key" type="string" required="true" />
      <cfargument name="value" type="string" required="true" />
      <cfargument name="visibility" type="string" required="false" default="PUBLIC"/>
      <cfset local = {} />
      <cfset local.results = {} />
      <cfset local.results.error = "" />
      <cftry>
         <cfset property = variables.service.properties().get(fileId,key).setVisibility(visibility).execute()/>
         <cfset property.setValue(value).setVisibility(visibility) />
         <cfset local.results = variables.service.properties().insert(fileId,property).execute()/>
         <cfcatch type="any">
            <cfset local.results.error = cfcatch.message & " " & cfcatch.detail />
         </cfcatch>
      </cftry>
      <cfreturn local.results />
   </cffunction>


   <cffunction name="insertFolder" access="public" output="true" returntype="struct" hint="">
      <cfargument name="title" type="string" required="true" />
      <cfargument name="parentId" type="string" required="false" />
      <cfset local = {} />
      <cfset local.results = {} />
      <cfset local.results.error = "" />
      <cftry>
         <cfset body = createObject("java", "com.google.api.services.drive.model.File").init().setTitle(title).setMimeType("application/vnd.google-apps.folder")/>
         <cfif isdefined("parentId")>
         <cfset newParent=createObject("java", "com.google.api.services.drive.model.ParentReference").init().setId(parentId).setKind("drive##fileLink")>
         <cfscript>
            body.setParents([newParent]);
            //return body;
         </cfscript>
         </cfif>
         <cfset local.results = variables.service.files().insert(body).execute()/>
         <cfcatch type="any">
            <cfset local.results.error = cfcatch.message & " " & cfcatch.detail />
         </cfcatch>
      </cftry>
      <cfreturn local.results />
   </cffunction>

   
   <cffunction name="filterDriveResponse" access="public" output="false" returntype="any" hint="I filter drive JSON response so its more friendly to clients and does not include unnecessary fields">
      <cfargument name="file" type="any" required="true" />
      <cfset local = {} />
      <cfset local.results = {} />
      <cfset local.results.error = "" />
      <cftry>
         <cfscript>
            //https://developers.google.com/drive/v2/reference/files
            r={};
            if(structkeyexists(file,"id")){r['id']=file['id'];}
            if(structkeyexists(file,"alternateLink")){r['alternateLink']=file['alternateLink'];}
            if(structkeyexists(file,"createdDate")){r['createdDate']=file['createdDate'].toString();}
            if(structkeyexists(file,"description")){r['description']=file['description'];}
            if(structkeyexists(file,"downloadUrl")){r['downloadUrl']=file['downloadUrl'];}
            if(structkeyexists(file,"title")){r['title']=file['title'];}
            if(structkeyexists(file,"mimeType")){r['mimeType']=file['mimeType'];}
            if(structkeyexists(file,"labels")){r['labels']=file['labels'];}
            if(structkeyexists(file,"createdDate")){r['createdDate']=file['createdDate'];}
            if(structkeyexists(file,"modifiedDate")){r['modifiedDate']=file['modifiedDate'];}
            if(structkeyexists(file,"indexableText")){r['indexableText']=file['indexableText'];}
            if(structkeyexists(file,"fileExtension")){r['fileExtension']=file['fileExtension'];}
            if(structkeyexists(file,"md5Checksum")){r['md5Checksum']=file['md5Checksum'];}
            if(structkeyexists(file,"fileSize")){r['fileSize']=file['fileSize'];}
            if(structkeyexists(file,"embedLink")){r['embedLink']=file['embedLink'];}
            if(structkeyexists(file,"parents")){r['parents']=file['parents'];}
            if(structkeyexists(file,"exportLinks")){r['exportLinks']=file['exportLinks'];}
            if(structkeyexists(file,"originalFilename")){r['originalFilename']=file['originalFilename'];}
            if(structkeyexists(file,"thumbnailLink")){r['thumbnailLink']=file['thumbnailLink'];}
            if(structkeyexists(file,"webContentLink")){r['webContentLink']=file['webContentLink'];}
            if(structkeyexists(file,"thumbnail")){r['thumbnail']=file['thumbnail'];}
            if(structkeyexists(file,"webViewLink")){r['webViewLink']=file['webViewLink'];}
            if(structkeyexists(file,"iconLink")){r['iconLink']=file['iconLink'];}
            if(structkeyexists(file,"properties")){r['properties']=file['properties'];}
            if(structkeyexists(file,"version")){r['version']=file['version'];}
            if(structkeyexists(file,"fullFileExtension")){r['fullFileExtension']=file['fullFileExtension'];}
         </cfscript>
         <cfset local.results = r>
         <cfcatch type="any">
            <cfset local.results.error = cfcatch.message & " " & cfcatch.detail />
         </cfcatch>
      </cftry>
      <cfreturn local.results />
   </cffunction>
</cfcomponent>
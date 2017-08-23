USING Progress.Json.JsonParser.
USING Progress.Json.ObjectModel.ObjectModelParser.
USING Progress.Json.ObjectModel.JsonConstruct.
USING Progress.Json.ObjectModel.JsonObject.


/*------------------------------------------------------------------------

  File: CallBackListener.w

  Description: A HTTP methods for receiving M-Pesa responses on CallBackURL 
               or ResultURL and for receiving queue timeouts on QueueTimeOutURL.

  Input Parameters:
      <none>

  Output Parameters:
      <none>

  Author: James Bowen

  Created: 23/08/2017

------------------------------------------------------------------------*/
/*           This .W file was created with the Progress AppBuilder.     */
/*----------------------------------------------------------------------*/

/* Create an unnamed pool to store all the widgets created 
     by this procedure. This is a good default which assures
     that this procedure's triggers and internal procedures 
     will execute in this procedure's storage, and that proper
     cleanup will occur on deletion of the procedure. */
CREATE WIDGET-POOL.



/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE Procedure
&Scoped-define DB-AWARE no



/* *********************** Procedure Settings ************************ */

/* Settings for THIS-PROCEDURE
   Type: Procedure
   Allow: 
   Frames: 0
   Add Fields to: Neither
   Other Settings: CODE-ONLY
 */

/* *************************  Create Window  ************************** */

/* DESIGN Window definition (used by the UIB) 
  CREATE WINDOW Procedure ASSIGN
         HEIGHT             = 14.14
         WIDTH              = 60.6.
/* END WINDOW DEFINITION */
                                                                        */

/* ************************* Included-Libraries *********************** */

{src/web2/wrap-cgi.i}


 




/* ************************  Main Code Block  *********************** */

/* Process the latest Web event. */
RUN process-web-request.


/* **********************  Internal Procedures  *********************** */

&IF DEFINED(EXCLUDE-invalidHTTPRequest) = 0 &THEN

PROCEDURE invalidHTTPRequest :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
    
    output-http-header("Status":U, "501"). 
    output-http-header("":U, ""). 

    return .
END PROCEDURE.

&ENDIF

&IF DEFINED(EXCLUDE-process-web-request) = 0 &THEN

PROCEDURE process-web-request :
/*------------------------------------------------------------------------------
  Purpose:     Process the web request.
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
    
    &SCOPED-DEFINE x32KSize 32768
        
    define variable formInputBlob as memptr no-undo.
    define variable formInput     as longchar no-undo.

    define variable serverResponse as class JsonObject NO-UNDO.
    define variable myParser       as class ObjectModelParser NO-UNDO.
    
    set-size(formInputBlob) = 0.
  
  /** Simple debug message. check the webSpeed Agent Logfile..**/
    MESSAGE 
        get-cgi("CONTENT_LENGTH")
        get-cgi("CONTENT_TYPE")
        get-cgi("QUERY_STRING")
        get-cgi("REQUEST_METHOD").
        
    /** JSON string was posted to the transaction server. 
        The AVM determines the value by checking if the 
        content-type HTTP header is either "application/json" or "text/json".  **/        
        
    MESSAGE "IS-JSON? " WEB-CONTEXT:IS-JSON.        
    
    /** If it's not a POST requet then we are not interested.**/
    if REQUEST_METHOD ne "POST":U or not WEB-CONTEXT:IS-JSON then 
    do:
      run invalidHTTPRequest.         
      return.
    end.

    
    
    IF WEB-CONTEXT:FORM-INPUT eq ? then
    do:
        run invalidHTTPRequest.         
        return.
    end.        
    
    /** if the content length greater or equal to 32K in size, we need to handle it.**/
    if CONTENT_LENGTH ge {&x32KSize} then
    do:
        formInputBlob = WEB-CONTEXT:FORM-LONG-INPUT.
        
        copy-lob from object formInputBlob to object formInput.
        set-size(formInputBlob) = 0.
    end.
    else
        formInput = WEB-CONTEXT:FORM-INPUT .    
        
        
    /** Since we are dealing with a JSON string, JSON is expected 
        to be in a UTF-8 codepage. lets process do a code page convert if the 
        ABL session is not UTF-8.**/        
        
    if session:cpinternal ne "UTF-8" then 
    do: 
        message "Warning: Webspeed Agent is not configured for UTF-8."   
        formInput = codepage-convert(formInput,"UTF-8").
    end.
    
    
    /** For delevlopement purpose export the JSON responce to a file **/
    copy-lob from object formInput to file "formInput.json".
    
    
    myParser = NEW ObjectModelParser().
    
    serverResponse = CAST(myParser:Parse(formInput ), JsonObject).
    
    /** Handle the JSON object here, see Progress Documentation for more details...**/ 
    
    
    
    
    
    
    
    output-http-header("Status":U, "200"). 
    output-content-type("application\json":U).
    
    {&out} '~{"ResponseCode":"000000","ResponseDesc":"success"}'.        

    return.    
END PROCEDURE.

&ENDIF


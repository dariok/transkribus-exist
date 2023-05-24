xquery version "3.1";

module namespace trp = "http://exist-db.org/lib/tr-exist";

import module namespace hc = "http://expath.org/ns/http-client";

(:~
 : functions for interacting with Transkribus
 :)

declare variable $trp:rest := 'https://transkribus.eu/TrpServer/rest';

(:~
 : log in to Transkribus
 : @param $user (xs:string) The user name
 : @param $pass (xs:string) The password
 : @return (element()) Transkribus’ login info
 :)
declare function trp:login ( $user as xs:string, $pass as xs:string ) as item() {
  let $response := try {
    hc:send-request(<hc:request
        method="POST"
        href="{$trp:rest}/auth/login">
          <hc:body  media-type="application/x-www-form-urlencoded" method="text">{
            'user=' || encode-for-uri($user) || '&amp;pw=' || encode-for-uri($pass)
          }</hc:body>
        </hc:request>)
  } catch * {
    <trp:error>{$err:code || ": " || $err:description}</trp:error>
  }

  return if ( count($response) eq 2 )
    then $response[2]/*
    else $response
};

(:~
 : list the contents of a collection
 : @param $login (element()) the Transkribus login info
 : @param $collection (xs:string) the ID of the collection
 : @return (element()) the documents within the collection
 :)
declare function trp:list-collection-contents ( $login as element(), $collection as xs:string ) as element(collection) {
  let $url := 'collections/' || $collection || '/list'
    , $response := trp:get($login, $url)

  return if ( count($response) eq 2 ) then
      let $parsed := $response[2] => util:base64-decode() => parse-json()
      return
        <collection>{
          for $n in 1 to array:size($parsed) return
            <document>
              <title>{ $parsed($n)?title }</title>
              <docId>{ $parsed($n)?docId }</docId>
            </document>
        }</collection>
    else error($response)
};

(:~
 : trigger the export of a document
 : @param $login (element()) the Transkribus login info
 : @param $collection (xs:int) the collection ID
 : @param $docId (xs:int) the document ID
 :)
declare function trp:trigger-export ( $login as element(), $collection as xs:int, $docId as xs:int ) as xs:int {
  (: get document metadate and extract page count :)
  let $pagesRequest := '/collections/' || $collection || '/' || $docId || '/fulldoc.xml'
    , $metadata := trp:get($login, $pagesRequest)
    , $numberOfPages := $metadata//pageList/pages => count()

  let $url := 'collections/' || $collection || '/' || $docId || '/export'
    , $requestJson := '{
        "commonPars": {
          "pages": "1-' || $numberOfPages || '"
        }
      }'
    , $body := <hc:body media-type="application/json" method="text">{
        $requestJson
      }</hc:body>

  return (trp:post($login, $url, $body))[2]
};

(: ~
 : get the full set of metadata for a document
 : @param $login (element()) Transkribus login data
 : @param $collection (xs:int) the collection ID
 : @param $docId (xs:int) the document ID
 : @return (map(*)) document metadata
 :)
declare function trp:get-document-metadata ( $login as element(trpUserLogin), $collection as xs:int, $docId as xs:int ) as map(*) {
  let $url := ("collections", $collection, $docId, "fulldoc") => string-join('/')
    , $reply := trp:get-json($login, $url)
  
  return if ( $reply instance of map(*) )
    then $reply
    else error( xs:QName("trp:error"), $reply )
};

(:~
 : get the status of a job
 : @param $login (element()) Transkribus login data
 : @param $jobId (xs:int) the ID of the job to check
 : @return (xs:string) the status
 :)
 declare function trp:get-job-status ( $login as element(trpUserLogin), $jobId as xs:int )  {
  trp:get-json($login, 'jobs/' || $jobId)
 };

declare %private function trp:get ( $login as element(), $restPart as xs:string ) as item()* {
  trp:connect($login//sessionId, "GET", $restPart, (), '')
};

declare %private function trp:get-json ( $login as element(), $restPart as xs:string ) as map(*) {
  let $result := trp:connect($login//sessionId, "GET", $restPart, (), 'text/plain')
  return try {
    parse-json(($result)[2])
  } catch * {
    error( xs:QName("trp:error"), <trp:error>{ $result }</trp:error> )
  }
};

declare %private function trp:post ( $login as element(), $restPart as xs:string, $body as element(hc:body) ) as item()* {
  trp:connect($login//sessionId, "POST", $restPart, $body, '')
};

declare %private function trp:connect ( $sessionID as xs:string, $method as xs:string, $restPart as xs:string, $body as element(hc:body)?, $overrideType as xs:string? ) as item()* {
  let $result := try
    {
      hc:send-request(
        <hc:request method="{$method}" href="{$trp:rest}/{$restPart}">
          {
            if ( exists($overrideType) )
              then attribute override-media-type { $overrideType }
              else ()
          }
          <hc:header name="JSESSIONID" value="{$sessionID}; Expires=null; Domain=transkribus.eu; Path=/TrpServer; Secure; HttpOnly" />
            { $body }
        </hc:request>
      )
    } catch * {
      <trp:error>{$err:code || ': '  || $err:description}</trp:error>
    }
  
  return if ( $result instance of element(trp:error) )
    then error ( xs:QName("trp:error"), $result )
    else if ( $result instance of element(html) and contains($result//*:title, '401') )
    then error( xs:QName("trp:login"), "not logged in" )
    else $result
};

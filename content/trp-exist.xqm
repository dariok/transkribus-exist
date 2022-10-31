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
declare function trp:login ( $user as xs:string, $pass as xs:string ) as element() {
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

declare %private function trp:get ( $login as element(), $restPart as xs:string ) as item()* {
  trp:connect($login//sessionId, "GET", $restPart, ())
};

declare %private function trp:post ( $login as element(), $restPart as xs:string, $body as element(hc:body) ) as item()* {
  trp:connect($login//sessionId, "POST", $restPart, $body)
};

declare %private function trp:connect ( $sessionID as xs:string, $method as xs:string, $restPart as xs:string, $body as element(hc:body)? ) as item()* {
  try {
    hc:send-request(
      <hc:request method="{$method}" href="{$trp:rest}/{$restPart}">
        <hc:header name="JSESSIONID" value="{$sessionID}; Expires=null; Domain=transkribus.eu; Path=/TrpServer; Secure; HttpOnly" />
          { $body }
      </hc:request>)
  } catch * {
    <trp:error>{$err:code || ': '  || $err:description}</trp:error>
  }
};

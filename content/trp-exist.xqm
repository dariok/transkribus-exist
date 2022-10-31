xquery version "3.1";

module namespace trp = "http://exist-db.org/lib/tr-exist";

import module namespace hc = "http://expath.org/ns/http-client";

(:~
 : functions for interacting with Transkribus
 :)

declare variable $trp:rest := "https://transkribus.eu/TrpServer/rest";

(:~
 : log in to Transkribus
 : @param $user (xs:string) The user name
 : @param $pass (xs:string) The password
 : @return (element()) Transkribus’ login info
 :)
declare function trp:login ( $user as xs:string, $pass as xs:string ) as element()+ {
  let $response := try {
    hc:send-request(<hc:request
        override-media-type="application/octet-stream"
        method="POST"
        href="{$trp:rest}/auth/login">
          <hc:body  media-type="application/x-www-form-urlencoded" method="text">{
            'user=' || encode-for-uri($user) || '&amp;pw=' || encode-for-uri($pass)
          }</hc:body>
        </hc:request>)
  } catch * {
    <trp:error>{$err:code || ": " || $err:description}</trp:error>
  }

  return if ( $response instance of element() )
    then $response
    else <trp:response>{util:base64-decode($response[2])}</trp:response>
};

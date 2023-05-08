xquery version "3.1";

module namespace trp-utils = "http://exist-db.org/lib/tr-exist-utils";

import module namespace trp = "http://exist-db.org/lib/tr-exist" at "/db/apps/trp-exist/trp-exist.xqm";

declare namespace http   = "http://expath.org/ns/http-client";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace rest   = "http://exquery.org/ns/restxq";

declare
  %rest:GET
  %rest:path("/trpex/login")
  %rest:query-param("user", "{$user}", "")
  %rest:query-param("pass", "{$pass}", "")
function trp-utils:login ( $user as xs:string*, $pass as xs:string* ) as item() {
    trp:login($user, $pass)//sessionId/string()
};

declare
  %rest:GET
  %rest:path("/trpex/compare/{$collectionId}/{$docId}/{$page}/latest")
  %rest:query-param("sessionId", "{$sessionId}", "")
  %output:method("html")
function trp-utils:compare-last-text-version-rest ( $sessionId as xs:string*, $collectionId as xs:int*, $docId as xs:int*, $page as xs:int* ) as element() {
  let $page := trp-utils:compare-last-text-versions (
        <trpUserLogin>
          <sessionId>{$sessionId}</sessionId>
        </trpUserLogin>,
        $collectionId,
        $docId,
        $page
      )
  return
    <html>
      <head>
        <title>{$docId}</title>
        <style>
          .lineid {{ vertical-align: top; padding-top: 5px; }}
          .lineok {{ background-color: lightblue; }}
          .lineip {{ background-color: palevioletred; }}
          .linegt {{ background-color: lightgreen; }}
        </style>
      </head>
      <body>
        <h1>{$collectionId} – {$docId}</h1>
          <div>
            <h2>{$page/@file => string()}</h2>
            <table>
              <tr>
                <th>Line ID</th>
                <th>Text</th>
              </tr>
              {
                for $line in $page/line return
                  <tr>
                    <td class="lineid">{ string($line/@id) }</td>
                    <td>
                      {
                        if ( $line/l2 ) then
                          <table>
                              <tr class="lineip">
                                <td>{ string($line/l1/@status) }</td>
                                {
                                  for $w in $line/l1//word return <td>{$w}</td>
                                }
                              </tr>
                              <tr class="linegt">
                                <td>{ string($line/l2/@status) }</td>
                                {
                                  for $w in $line/l2//word return <td>{$w}</td>
                                }
                              </tr>
                          </table>
                        else (
                          attribute class { 'lineok' },
                          $line/node()
                        )
                      }
                    </td>
                  </tr>
              }
            </table>
          </div>
      </body>
    </html>
};

declare function trp-utils:compare-last-text-versions ( $login as element(), $collection as xs:int, $docId as xs:int ) {
  let $md := trp:get-document-metadata($login, $collection, $docId)
    , $transcripts := array:for-each (
        $md?pageList?pages,
        function ( $page ) {
          (
            $page?tsList?transcripts(1),
            $page?tsList?transcripts(2)
          )
        }
      )
      
  return array:for-each(
    $transcripts,
    function ( $pageTranscript ) {
      trp-utils:compare($pageTranscript)
    }
  )
};

declare function trp-utils:compare-last-text-versions ( $login as element(), $collection as xs:int, $docId as xs:int, $page as xs:int ) {
  let $md := trp:get-document-metadata($login, $collection, $docId)
    , $page := $md?pageList?pages($page)
    , $transcripts :=
        (
          $page?tsList?transcripts(1),
          $page?tsList?transcripts(2)
        )
  return trp-utils:compare($transcripts)
};

declare %private function trp-utils:compare ( $info as map()+ ) {
  let $d1 := doc($info[1]?url)
    , $d2 := doc($info[2]?url)

  return <page file="{$info[1]?fileName}">
    {
      for-each-pair($d1//*:TextLine, $d2//*:TextLine,
        function ( $a, $b ) {
          if ( $a/*:TextEquiv/*:Unicode = $b/*:TextEquiv/*:Unicode ) then
            <line id="{$a/@id}">{ $a/*:TextEquiv/*:Unicode/text() }</line>
          else
            <line id="{$a/@id}">
              <l1 status="{$info[1]?status}">
                <text>{$a/*:TextEquiv/*:Unicode/text()}</text>
                <words>{
                  for $word in $a//*:Word return
                    <word id="{$word/@id}" order="{$word/@custom => substring(21) => substring-before(';')}">
                      { $word//*:Unicode/text() }
                    </word>
                }</words></l1>
              <l2 status="{$info[2]?status}">
                <text>{$b/*:TextEquiv/*:Unicode/text()}</text>
                <words>{
                  for $word in $b//*:Word return
                    <word id="{$word/@id}" order="{$word/@custom => substring(21) => substring-before(';')}">
                      { $word//*:Unicode/text() }
                    </word>
                }</words>
              </l2>
            </line>
        } 
      )
    }
  </page>
};

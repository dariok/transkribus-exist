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
  %rest:path("/trpex/compare/{$collectionId}/{$docId}/{$page}/latest.xml")
  %rest:query-param("sessionId", "{$sessionId}", "")
function trp-utils:compare-latest-xml ( $sessionId as xs:string*, $collectionId as xs:int*, $docId as xs:int*, $page as xs:int* ) as element() {
  trp-utils:compare-last-text-versions (
      <trpUserLogin>
        <sessionId>{$sessionId}</sessionId>
      </trpUserLogin>,
      $collectionId,
      $docId,
      $page
    )
};

declare
  %rest:GET
  %rest:path("/trpex/compare/{$collectionId}/{$docId}/{$page}/latest")
  %rest:query-param("sessionId", "{$sessionId}", "")
  %output:method("html")
function trp-utils:compare-last-text-version-rest ( $sessionId as xs:string*, $collectionId as xs:int*, $docId as xs:int*, $page as xs:int* ) as element() {
  try {
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
              <h2>{ string($page/@file) }</h2>
              <p>
                <a href="../1/latest?sessionId={ $sessionId }">1</a> &lt;&lt;
                {
                  if ( number($page/@current) gt 2 )
                    then
                      let $previousPage := number($page/@current) - 1
                      return <a href="../{ $previousPage }/latest?sessionId={ $sessionId }">{ $previousPage }</a>
                    else ()
                }
                [{ string($page/@current) } of { string($page/@max) }]
                {
                  if ( number($page/@current) lt number($page/@max) )
                    then
                      let $nextPage := number($page/@current) + 1
                      return <a href="../{ $nextPage }/latest?sessionId={ $sessionId }">{ $nextPage }</a>
                    else ()
                }
                >>
                <a href="../{ string($page/@max) }/latest?sessionId={ $sessionId }">{ string($page/@max) }</a>
                </p>
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
                              <tr>
                                <td>
                                  <b title="{ string-join($line/l1/@*[not(name() = 'id')], ' – ') }">
                                    { xs:int(number($line/l1/@id)) }
                                  </b>
                                </td>
                                {
                                  for $w in $line/l1//word return
                                    <td>
                                      {
                                        attribute class {
                                          if ( $line/l2//word[@order = $w/@order] = $w )
                                            then "linegt"
                                            else "lineip"
                                        },
                                        if ( $line/l2//word[@order = $w/@order] != $w )
                                          then attribute title { ($w => string-to-codepoints()) ! trp-utils:dec-to-hex(.) => string-join('-') }
                                          else (),
                                        translate($w, '&#xFEFF;', '¥')
                                      }
                                    </td>
                                }
                              </tr>
                              <tr>
                                <td>
                                  <b title="{ string-join($line/l2/@*[not(name() = 'id')], ' – ') }">
                                    { xs:int(number($line/l2/@id)) }
                                  </b>
                                </td>
                                {
                                  for $w in $line/l2//word return
                                    <td>
                                      {
                                        attribute class {
                                          if ( $line/l1//word[@order = $w/@order] = $w )
                                            then "linegt"
                                            else "lineip"
                                        },
                                        if ( $line/l1//word[@order = $w/@order] != $w )
                                          then attribute title { ($w => string-to-codepoints()) ! trp-utils:dec-to-hex(.) => string-join('-') }
                                          else (),
                                        translate($w, "&#xFEFF;", '¥')
                                      }
                                    </td>
                                }
                              </tr>
                            </table>
                          else (
                            attribute class { 'lineok' },
                            attribute data-style { $line/@style },
                            $line/node()
                          )
                        }
                      </td>
                    </tr>
                }
              </table>
            </div>
          <script src="function.js"></script>
        </body>
      </html>
  } catch * {
    util:parse-html($err:description)/*
  }
};

declare function trp-utils:compare-last-text-versions ( $login as element(), $collection as xs:int, $docId as xs:int ) {
  let $md := trp:get-document-metadata($login, $collection, $docId)

  return try {
    let $transcripts := if ( $md instance of map(*) )
      then array:for-each (
          $md?pageList?pages,
          function ( $page ) {
            (
              $page?tsList?transcripts(1),
              $page?tsList?transcripts(2)
            )
          }
        )
      else error ( xs:QName('trp:error'), $md )
        
    return array:for-each(
      $transcripts,
      function ( $pageTranscript ) {
        trp-utils:compare($pageTranscript)
      }
    )
  } catch * {
    util:log("error", "caught you"),
    <html>
      <head><title>Error</title></head>
      <body>
        {
          if ( contains($err:description, 'Status 401') )
          then <h1>Not logged in</h1>
          else $err:description
        }
      </body>
    </html>
  }
};

declare function trp-utils:compare-last-text-versions ( $login as element(), $collection as xs:int, $docId as xs:int, $page as xs:int ) {
  let $md := trp:get-document-metadata($login, $collection, $docId)
  
  return try {
    let $pages := if ( $md instance of map(*) ) 
          then $md?pageList?pages($page)
          else error ( xs:QName("trp:error"), $md )
      , $max := array:size($md?pageList?pages)
      , $transcripts := map {
          "page": $page,
          "max":  $max,
          "d1":   $pages?tsList?transcripts(1),
          "d2":   $pages?tsList?transcripts(2)
        }
    return trp-utils:compare($transcripts)
  } catch * {
    <html>
      <head><title>Error</title></head>
      <body>
        {
          if ( contains($err:description, 'Status 401') )
          then <h1>Not logged in</h1>
          else $err:description
        }
      </body>
    </html>
  }
};

declare %private function trp-utils:compare ( $info as map() ) {
  let $d1 := doc($info?d1?url)
    , $d2 := doc($info?d2?url)

  return <page file="{$info?d1?fileName}" max="{ $info?max }" current="{ $info?page }">
    {
      for-each-pair($d1//*:TextLine, $d2//*:TextLine,
        function ( $a, $b ) {
          let $style := analyze-string($a/@custom, 'textStyle \{(.+)\}')/*:match/*:group

          return if ( $a/*:TextEquiv/*:Unicode = $b/*:TextEquiv/*:Unicode ) then
            <line id="{$a/@id}" style="{$style}">{ $a/*:TextEquiv/*:Unicode/text() }</line>
          else
            <line id="{$a/@id}">
              <l1 status="{$info?d1?status}" tool="{$info?d1?toolName}" id="{$info?d1?tsId}">
                <text>{$a/*:TextEquiv/*:Unicode/text()}</text>
                <words>{
                  for $word at $pos in tokenize($a/*:TextEquiv/*:Unicode/text(), ' ') return
                    <word order="{ $pos }">
                      { $word }
                    </word>
                }</words></l1>
              <l2 status="{$info?d2?status}" tool="{$info?d2?toolName}" id="{$info?d2?tsId}">
                <text>{$b/*:TextEquiv/*:Unicode/text()}</text>
                <words>{
                  for $word at $pos in tokenize($b/*:TextEquiv/*:Unicode/text(), ' ') return
                    <word order="{ $pos }">
                      { $word }
                    </word>
                }</words>
              </l2>
            </line>
        } 
      )
    }
  </page>
};

declare %private function trp-utils:dec-to-hex ( $in as xs:int ) {
  let $internal := string-join(trp-utils:dec-to-hex-helper($in),'')
  return if ( string-length($internal) mod 2 = 1 )
    then '0' || $internal
    else $internal
};

declare %private function trp-utils:dec-to-hex-helper ( $in as xs:int ) {
  let $hex := '0123456789ABCDEF'
  return (
    if ( $in ge 16 )
      then trp-utils:dec-to-hex-helper($in idiv 16)
      else '',
    substring($hex, ($in mod 16) + 1, 1)
  )
};

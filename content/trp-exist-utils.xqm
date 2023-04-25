xquery version "3.1";

module namespace trp-utils = "http://exist-db.org/lib/tr-exist-utils";

import module namespace trp = "http://exist-db.org/lib/tr-exist" at "/db/apps/trp-exist/trp-exist.xqm";

declare function trp-utils:compare-last-text-versions ( $login as element(), $collection as xs:int, $docId as xs:int ) {
  let $md := trp:get-document-metadata($login, $collection, $docId)
    , $transcripts := array:for-each (
        $md?pageList?pages,
        function ( $page ) {
          (
            $page?tsList?transcripts(1)?url,
            $page?tsList?transcripts(2)?url
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

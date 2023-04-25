xquery version "3.1";

module namespace trp-utils = "http://exist-db.org/lib/tr-exist-utils";

import module namespace trp = "http://exist-db.org/lib/tr-exist" at "/db/apps/trp-exist/trp-exist.xqm";

declare function trp-utils:compare-last-text-versions ( $login as element(), $collection as xs:int, $docId as xs:int ) {
  let $md := trp:get-document-metadata($login, $collection, $docId)
    , $transcripts := array:for-each (
        $md?pageList?pages,
        function ( $page ) {
          (
            $page?imgFileName,
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
          $page?imgFileName,
          $page?tsList?transcripts(1)?url,
          $page?tsList?transcripts(2)?url
        )
  return trp-utils:compare($transcripts)
};

declare %private function trp-utils:compare ( $info as xs:string+ ) {
  let $d1 := doc($info[2])
    , $d2 := doc($info[3])

  return <page file="{$info[1]}">
    {
      for-each-pair($d1//*:TextLine/*:TextEquiv/*:Unicode, $d2//*:TextLine/*:TextEquiv/*:Unicode,
        function ( $a, $b ) {
          if ( $a = $b ) then
            <line>{ $a/text() }</line>
          else
            <line>
              <l1>{ $a/text() }</l1>
              <l2>{ $b/text() }</l2>
            </line>
        } 
      )
    }
  </page>
};

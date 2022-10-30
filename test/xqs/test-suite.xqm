xquery version "3.1";

(:~ This library module contains XQSuite tests for the Transkribus-eXist app.
 :
 : @author Dario Kampkaspar
 : @version 0.1.0
 : @see https://www.ulb.tu-darmstadt.de/die_bibliothek/einrichtungen/zeid/index.en.jsp
 :)

module namespace tests = "http://exist-db.org//trp-exist/tests";

declare namespace test="http://exist-db.org/xquery/xqsuite";



declare
    %test:name('one-is-one')
    %test:assertTrue
    function tests:tautology() {
        1 = 1
};

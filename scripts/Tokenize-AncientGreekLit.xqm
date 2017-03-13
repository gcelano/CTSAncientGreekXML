xquery version "3.0" encoding "utf-8";

(: This Library has been written and run with BaseX 8.6.1 by Giuseppe G. Celano.
 : It is published under a CC BY-NC 4.0 license.     
 :)

declare namespace lp="http://l-processor.org";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

(: keep whitespaces as they are in the XML document :)
declare option db:chop 'false';

(:~
 : Selects well-formed XML texts from a folder containing XML files,
 : which may also be contained in other folders
 :
 : @author  Giuseppe G. A. Celano 
 : @version 1.0 
 : @param   $path is the path of the folder where you have all the XML files
 : @return  the path of the well-formed XML texts
 :) 
declare function lp:XML-texts($path as xs:string?) as xs:string*
{ 
for $t in file:list($path, true(), "*grc*xml")
return
try {doc($path || "/" || $t)/document-uri(.)} 
catch * {}
};

(:~
 : Selects only Perseus CTS-compliant texts
 :
 : @author  Giuseppe G. A. Celano 
 : @version 1.0 
 : @param   $path is the path of the folder where you have all the XML files
 : @return  the path of the cts-compliant texts
 :) 
declare function lp:CTS-texts($path as xs:string?) as xs:string*
{
for $t in lp:XML-texts($path)
let $cts:= doc($t)[.//tei:refsDecl[@n="CTS"]]
return 
$cts/document-uri(.)   
};

(:~
 : Modify those elements that split orthographic words at either its beginning
 : or its end. For example, ἑτέρ<supplied reason="lost">ωθεν becomes
 : <supplied reason="lost">ἑτέρωθεν. This query is likely to require refinement
 : by addition of further rules.
 :
 : @author  Giuseppe G. A. Celano 
 : @version 1.0 
 : @param   $path is the path of the folder where you have XML/CTS-compliant files
 : @return  the document node of a document
 :) 
declare  function lp:treat-int($path as xs:string) as document-node()?
{
let $ope := unparsed-text($path)
let $tre :=

replace($ope, "(\p{L}*)(\])(\p{L}*)( )" , "$1$3$2$4") =>
replace("( )(\p{L}*)(\[)(\p{L}*)" , "$1$3$2$4") =>

replace("( )?(\p{L}*)(<add>)(\p{L})" , "$1$3$2$4") =>
replace("(\p{L})(</add>)(\p{L}*)()?" , "$1$3$2$4") =>

replace('( )?(\p{L}*)(<supplied>|<supplied reason="lost">)(\p{L})' , "$1$3$2$4") =>
replace("(\p{L})(</supplied>)(\p{L}*)()?" , "$1$3$2$4") =>

replace('( )?(\p{L}*)(<del>|<del status="unremarkable">)(\p{L})' , "$1$3$2$4") =>
replace("(\p{L})(</del>)(\p{L}*)()?" , "$1$3$2$4") =>

replace('( )?(\p{L}*)(<seg>|<seg type="noparse">)(\p{L})' , "$1$3$2$4") =>
replace("(\p{L})(</seg>)(\p{L}*)()?" , "$1$3$2$4") =>

replace('( )?(\p{L}*)(<unclear>)(\p{L})' , "$1$3$2$4") =>
replace("(\p{L})(</unclear>)(\p{L}*)()?" , "$1$3$2$4")

return
parse-xml($tre)
};

(:~
 : Tokenize a text by whitespaces. The texts of some elements are ignored,
 : as in note elements. The goal is to identify the text and leave out
 : 'comments' about it. Since this distinction is not always clear-cut, 
 : the content of some 'editorial' elements, such as 'add', is retained 
 : but signaled in the output in @tag. The query could be modified in order to
 : add more elements to be signaled in @tag.  
 :
 : @author  Giuseppe G. A. Celano 
 : @version 1.0 
 : @param   $path is the path of the folder where you have all 
 :          the XML/CTS-compliant files
 : @return  the element containing an entire tokenized text.  
 :)
declare function lp:space-tokenize($path as xs:string?) as element()?
{
let $p := lp:treat-int($path)
let $n := replace($p/document-uri(.), "(.*)(/)(.*)", "$3")
let $t :=                             
 <one>{for $sp in $p//tei:text//text()(: ignored elements follow :)
                                      [not(./ancestor::tei:note)] 
                                      [not(./ancestor::tei:bibl)]
                                      [not(./ancestor::tei:gloss)]
                                      [not(./ancestor::tei:interpGrp)]
                                      [not(./ancestor::tei:bibl)]                                      
       let $ce := $sp/(ancestor::tei:div[not(@type="edition")] 
                       union ancestor::tei:l)/@n
       let $as := $sp/ (: element names appearing in @tag follow :)
       (ancestor::tei:del union ancestor::tei:add union ancestor::tei:unclear
        union ancestor::tei:supplied union ancestor::tei:surplus union 
        ancestor::seg[@type="noparse"]
        union ancestor::tei:sic union ancestor::tei:corr)
       /name(.)
       where $ce        
       return
       if (exists($as)) then
       <src p="{string-join($ce, ".")}" tag="{$as}">{$sp}</src>
       else
       <src p="{string-join($ce, ".")}">{$sp}</src>
       }</one>  
return
<text file-name="{$n}" author="{$p/tei:TEI/
                                   tei:teiHeader/
                                   tei:fileDesc/
                                   tei:titleStmt/tei:author}" 
                       title="{$p/tei:TEI/
                                  tei:teiHeader/
                                  tei:fileDesc/
                                  tei:titleStmt/tei:title}"
                       text-cts="{$p//tei:div[@type='edition']/@n}" 
                       date-of-conversion="{replace(xs:string(current-date()), 
                       "(\+)(.*)", "")}">
{
 for $tk in $t/src
 for $l at $count in tokenize(normalize-space($tk), (" "))
 return
 if ($tk/@tag) then
 <t p="{$tk/@p}" n="{$count}" tag="{$tk/@tag}">{normalize-unicode($l, "NFC")}</t>
 else
 <t p="{$tk/@p}" n="{$count}">{normalize-unicode($l, "NFC")}</t>
}
</text>
};

(:~
 : Tokenize texts by punctuation identified by RegEx "P"
 :
 : @author  Giuseppe G. A. Celano 
 : @version 1.0 
 : @param   $path is the path of the folder where you have all
 :          the XML/CTS-compliant files
 : @return  the element containing an entire tokenized text 
 :)
declare function lp:punct-tokenize($path as xs:string?) as element()?
{
 let $g := lp:space-tokenize($path)
 return
 <text text-cts="{$g/@text-cts}" file-name="{$g/@file-name}" 
  author="{$g/@author}" title="{$g/@title}" date-of-conversion="{$g/@date-of-conversion}">
 {
  for $t in $g//t
  let $o := $t/@tag
  return
    for $l at $c in analyze-string($t, "\p{P}")/(fn:match union fn:non-match) 
    return
    if ($l = (",", ".", ";", "·")) then 
    element t {$t/@p, attribute join {"b"}, if ($o) then $o else (), data($l)} 
    else if ($c = 1 and $l/local-name(.) = "match") then 
    element t {$t/@p, attribute join {"a"}, if ($o) then $o else (), data($l)}
    else if ($c > 1 and $l/local-name(.) = "match") then 
    element t {$t/@p, attribute join {"b"}, if ($o) then $o else (), data($l)}  
    else element t {$t/@*, data($l)}
 }
 </text>
};

(:~
 : Add running id to each orthographic word. The count starts again as @passage
 : changes. 
 :
 : @author  Giuseppe G. A. Celano 
 : @version 1.0 
 : @param   $path is the path of the folder where you have all
 :          the XML/CTS-compliant files
 : @return  the element containing an entire text with word ids 
 :)
declare function lp:running-id-word($text as element()?) as element()?
{
 <text text-cts="{$text/@text-cts}" file-name="{$text/@file-name}" 
  author="{$text/@author}" title="{$text/@title}" date-of-conversion="{$text/@date-of-conversion}"> 
 { 
  for tumbling window $w in $text/t
  start $s when true()
  end $e next $u when $e/@p != $u/@p
  return
   for $a at $count in $w
   let $r := $a/@join
   let $o := $a/@tag
   return
   element t {attribute p {$a/@p}, attribute n {$count}, if ($r) then $r else (),
   if ($o) then $o else (), 
   $a/text()}

 }
 </text>
};

(:~
 : Add occurrence id to each orthographic word
 :
 : @author  Giuseppe G. A. Celano 
 : @version 1.0 
 : @param   $path is the path of the folder where you have all
 :          the XML/CTS-compliant files
 : @return  the element containing an entire text with occurrence ids. 
 :)
declare function lp:occurence-id-word($text as element()?) as element()?
{
 <text text-cts="{$text/@text-cts}" file-name="{$text/@file-name}" 
  author="{$text/@author}" title="{$text/@title}" date-of-conversion="{$text/@date-of-conversion}"> 
 { 
  for tumbling window $w in $text/t
  start $s when true()
  end $e next $u when $e/@p != $u/@p
  return
   let $e := distinct-values($w)
   for $b in $e
   for $a at $count in $w[. = $b]
   order by $a/xs:integer(@n)
   let $r := $a/@join
   let $o := $a/@tag
   return
   element t {attribute p {$a/@p}, $a/@n,
              attribute a {"[" || $count || "]"}, 
              if ($r) then $r else (),
              if ($o) then $o else (),
              $a/text()}
 }
 </text>
};

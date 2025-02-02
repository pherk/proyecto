xquery version "1.0";

module namespace search = "http://chlt.es/ns/proyecto/search";

declare namespace tei = "http://www.tei-c.org/ns/1.0";
(: declare base-uri "http://www.w3.org/1999/xhtml"; :)

import module namespace tei-to-html = "http://chlt.es/ns/tei-to-html" at "tei-to-html.xqm";
import module namespace proyecto = "http://chlt.es/ns/proyecto" at "proyecto.xqm";
import module namespace config   = "http://chlt.es/ns/proyecto/config" at "config.xqm";
import module namespace kwic="http://exist-db.org/xquery/kwic";

declare option exist:serialize 'method=xhtml media-type=text/html indent=yes';

declare function local:sequence-to-table($seq) {
(: assumes all items in $seq have the same simple element structure determined by the structure of the first item :)
  <table border="1">
     <thead>
        <tr>
        {for $node in $seq[1]/*
         return <th>{name($node)}</th>
        }
        </tr>
     </thead>
      {for $row in $seq
       return
         <tr>
            {for $node in $seq[1]/*
             let $data := $row/*[name(.)=name($node)]
             return <td>{$data}</td> 
        } 
         </tr>
      }
   </table>
};

declare function local:mk-option-list($prio, $query) {
  let $all := ('texto','articulo','orador','name')
  let $options : = ($prio, $all[.!=$prio])
  return 
    for $o in $options
    return 
        <option>{$o}</option>
};

declare function local:prepareQuery($q)
{
    if (not($q))
    then 'empty'
    else $q
};

declare function search:make-body-text($query) {
let $pq   := local:prepareQuery($query)
let $hits :=  collection($config:data-tei)//tei:div[ft:query(., $pq)][count(./tei:div)=0]
let $ordered-hits :=
    for $hit in $hits
    order by ft:score($hit) descending
    return $hit
let $hit-count := count($hits)
return
    <div>
        <h2>{$hit-count} results for "{$query}"</h2>
        <ol>
        {
        for $hit in $ordered-hits
        let $snippet := kwic:summarize($hit, <config xmlns="" width="30"/>)
        let $doc     := util:document-name($hit)
        let $section := $hit/@xml:id/string()
        let $title   := proyecto:title-doc-section($doc, $section)
        return
            <li>
                <a href="index.html?action=view-section&amp;doc={$doc}&amp;id={$section}">{$title}</a>
                <blockquote>{$snippet}</blockquote>
            </li>
        }
        </ol>
    </div>
};

declare function search:make-body-art($query) {
(: match cases:
   single digit preceded by 0
   number (more than one digit)
      preceded by nothing ('0*) or numbers followed by ':'
      followed by ' ', ':' or EOS 
:)
let $qregex       := concat('constitucion.xml#art-([0-9]+)-([0-9]+)-(0*|([0-9]+:)+)', $query, '( |:|$)')
let $hitsD :=  for $doc in collection($config:data-tei-diarios)
         return 
           $doc//tei:div[@type=('articulo','arthead','artitem','discurso','discutido','resumen','resultat')][matches(@corresp, $qregex)]
let $noHitsDiario := count($hitsD)
let $hitsA :=  doc(concat($config:data-tei, "/ActasComision.xml"))//tei:div[@type=('articulo','resumen')][matches(@corresp, $qregex)]
let $noHitsActas  := count($hitsA)
let $ohitsD :=
    for $d in $hitsD/../tei:head/tei:date/@when
    let $doc := util:document-name($d)
    let $day := $d/../../../@xml:id/string()
    return <hit>
         <date>
           <a href="index.html?action=view-section&amp;doc={$doc}&amp;id={$day}">{data($d)}</a>
         </date>
         <Comision></Comision>
         <Actas_secretas>{             
            local:showHitsInDiarios($doc, $hitsD[../tei:head/tei:date/@when=$d][substring(@xml:id,1,9) = 'Diario-AS'])
         }</Actas_secretas>
         <Cortes>{
            local:showHitsInDiarios($doc, $hitsD[../tei:head/tei:date/@when=$d][substring(@xml:id,1,9)!= 'Diario-AS'])
        }</Cortes></hit>
let $ohitsA :=
    for $d in $hitsA/../tei:head/tei:date/@when 
    let $doc     := util:document-name($d)
    let $day := concat('Actas-',$d)
    return <hit>
        <date>
          <a href="index.html?action=view-section&amp;doc={$doc}&amp;id={$day}">{data($d)}</a>
        </date>
        <Comision>{
            local:showHitsInActas($doc, $hitsA[../tei:head/tei:date/@when=$d])
        }</Comision>
        <Actas_secretas></Actas_secretas>
        <Cortes></Cortes></hit>

let $ohits := for $hit in ($ohitsA,$ohitsD)
              order by $hit/date/a
              return $hit

return
    <div>
        <h3>searching for '{$qregex}'</h3>
        <h3>{$noHitsActas} results  in Actas</h3>
        <h3>{$noHitsDiario} results in Diario de Sesiones</h3>
        {local:sequence-to-table($ohits)}
    </div>
};

declare function local:showHitsInDiarios($doc, $hits)
{
    for $hit in $hits
    let $section := $hit/@xml:id/string()
    return <action>{
       if ($hit/@type = ('resumen','resultat')) then
         (<a href="index.html?action=view-section&amp;doc={$doc}&amp;id={$section}">{
             concat(local:get-oradores($hit), $hit/@ana/string())
            }</a>,<span>! </span>)
       else if ($hit/@type='discurso') then
         (<a href="index.html?action=view-section&amp;doc={$doc}&amp;id={$section}">{local:get-orador($hit)}</a>,<span> - </span>)
       else if ($hit/@type=('discutido')) then
         (<a href="index.html?action=view-section&amp;doc={$doc}&amp;id={$section}">{local:get-oradores($hit)}</a>,<span> - </span>)
       else if ($hit/@type=('articulo','arthead')) then
         (<a href="index.html?action=view-section&amp;doc={$doc}&amp;id={$section}">leido</a>,<span> > </span>)
       else if ($hit/@type=('artitem')) then
         (<a href="index.html?action=view-section&amp;doc={$doc}&amp;id={$section}">leido paráffo</a>,<span> > </span>)         
       else 
          <a href="index.html?action=view-section&amp;doc={$doc}&amp;id={$section}">unclear</a>
      }</action>
};

declare function local:showHitsInActas($doc, $hits)
{
    for $hit in $hits
    let $section := $hit/@xml:id/string()
    return <action>{
        if ($hit/@type = 'resumen') then
            <a href="index.html?action=view-section&amp;doc={$doc}&amp;id={$section}">resumen</a>
        else if ($hit/@type = 'articulo') then
            <a href="index.html?action=view-section&amp;doc={$doc}&amp;id={$section}">propuesto</a>
        else 
            <a href="index.html?action=view-section&amp;doc={$doc}&amp;id={$section}">unclear</a>
    }</action>
};

declare function local:get-orador($div)
{
  $div/tei:p/tei:name[@type='orador']
};

declare function local:get-oradores($div)
{
  let $os := $div/tei:p/tei:name[@type='orador']
  let $n  := count($os)
  return
      if ($n>1)
      then string-join($os, ', ')
      else if ($n=1)
      then $os
      else 'var.Dip. '
};

declare function local:get-art-no($div) {
  (: TODO: remove assumtion constitucion at first position :)
  let $cntxt := tokenize($div/@corresp,' ')
  let $art   := tokenize($cntxt[1],'#')
  let $artn  := tokenize($art[2],'-')[4]
  return
    concat('Art. ', $artn, ' ', substring($cntxt[1],1,1))
};

declare function search:make-body-orador($query) {
let $pq   := local:prepareQuery($query)
let $hitsD :=  collection($config:data-tei-diarios)//tei:name[matches(.,$pq,'i')][@type='orador']
let $noHitsDiario := count($hitsD)
let $ohitsD :=
    for $d in $hitsD/ancestor::tei:div[@type='dia']/tei:head/tei:date/@when
    let $doc := util:document-name($d)
    let $day := $d/ancestor::tei:div[@type='dia']
    return <hit>
         <date>
          <a  href="index.html?action=view-section&amp;doc={$doc}&amp;id={$day/@xml:id}">{data($d)}</a>
         </date>
         <discursos>{
           for $hit in $hitsD
           let $discurs := $hit/../..
           let $cntxt := local:get-art-no($discurs)
           let $match  := if (string-length($hit/string())=string-length($query)) then
                           '='
                          else
                           '*'
           where $d = $hit/ancestor::tei:div[@type='dia']/tei:head/tei:date/@when
           return
                 <a class="searchtp" data-tpcontent="{$hit/string()}"
                    href="index.html?action=view-section&amp;doc={$doc}&amp;id={$discurs/@xml:id}">{concat($cntxt,' ',$match)}</a>
         }</discursos>
         </hit>
let $ohits := for $hit in $ohitsD
              order by $hit/date
              return $hit
return
    <div>
        <h2>results for "{$query}"</h2>
        <h3>{$noHitsDiario} Discursos in Diario de Sesiones</h3>
        <span>Article numbers corrspond to Constitucion (c).
            Symbol after article numbers indicates:
           '=': exact match; '*': query matches substring.
           Tooltip shows name of Diputado as written in Diario.
        </span>
       {local:sequence-to-table($ohits)}
    </div>
};

declare function search:make-body-name($query) {
let $pq   := local:prepareQuery($query)
let $hitsD :=  collection($config:data-tei-diarios)//tei:name[matches(.,$pq,'i')][@type="person"]
let $noHitsDiario := count($hitsD)
let $hitsA :=  doc(concat($config:data-tei, "/ActaComision.xml"))//tei:name[matches(.,$pq,'i')]
let $noHitsActas  := count($hitsA)
let $ohitsD :=
    for $d in $hitsD/ancestor::tei:div[@type='dia']/tei:head/tei:date/@when
    let $doc := util:document-name($d)
    let $day := $d/ancestor::tei:div[@type='dia']
    return <hit>
         <date>
          <a  href="index.html?action=view-section&amp;doc={$doc}&amp;id={$day/@xml:id}">{data($d)}</a>
         </date>
         <Actas></Actas>
         <Diario>{
           for $hit in $hitsD
           let $div := $hit/ancestor::tei:div[1]
           let $title : = proyecto:derive-title($div)
           let $cntxt := if (substring($title,1,6)='Sesion') then
                           'Sesion'
                         else
                           $title
           let $match  := if (string-length($hit/string())=string-length($query)) then
                           '='
                          else
                           '*'
           where $d = $hit/ancestor::tei:div[@type='dia']/tei:head/tei:date/@when
           return
                 <a class="searchtp" data-tpcontent="{$hit/string()}"
                    href="index.html?action=view-section&amp;doc={$doc}&amp;id={$div/@xml:id}">{concat($cntxt,' ',$match)}</a>
         }</Diario>
         </hit>
let $ohitsA :=
    for $d in $hitsA/ancestor::tei:div[@type='dia']/tei:head/tei:date/@when
    let $doc := util:document-name($d)
    let $day := $d/ancestor::tei:div[@type='dia']
    return <hit>
         <date>
          <a  href="index.html?action=view-section&amp;doc={$doc}&amp;id={$day/@xml:id}">{data($d)}</a>
         </date>
         <Actas>{
           for $hit in $hitsA
           let $div := $hit/ancestor::tei:div[1]
           let $title : = proyecto:derive-title($div)
           let $cntxt := if (substring($title,1,6)='Sesion') then
                           'Sesion'
                         else
                           $title
           let $match  := if (string-length($hit/string())=string-length($query)) then
                           '='
                          else
                           '*'
           where $d = $hit/ancestor::tei:div[@type='dia']/tei:head/tei:date/@when
           return
                 <a class="searchtp" data-tpcontent="{$hit/string()}"
                    href="index.html?action=view-section&amp;doc={$doc}&amp;id={$div/@xml:id}">{concat($cntxt,' ',$match)}</a>
         }</Actas>
         <Diario></Diario>
         </hit>
let $ohits := for $hit in ($ohitsD,$ohitsA)
              order by $hit/date
              return $hit
return
    <div>
        <h2>The name "{$query}" is mentioned</h2>
        <h3>{$noHitsActas} times in Actas de Comision</h3>
        <h3>{$noHitsDiario} times in Diario de Sesiones</h3>
        <span>Links indicate context in document. P: Proyecto, C: Constitucion.
           '=': exact match; '*': query matches substring.
           Tooltip shows name as written in document.
        </span>
       {local:sequence-to-table($ohits)}
    </div>
};

declare function search:make-body-place($query) {
let $pq   := local:prepareQuery($query)
let $hitsD :=  collection($config:data-tei-diarios)//tei:name[matches(.,$pq,'i')][@type="place"]
let $noHitsDiario := count($hitsD)
let $hitsA :=  doc(concat($config:data-tei, "/ActasComision.xml"))//tei:name[matches(.,$pq,'i')][@type="place"]
let $noHitsActas  := count($hitsA)
let $ohitsD :=
    for $d in $hitsD/ancestor::tei:div[@type='dia']/tei:head/tei:date/@when
    let $doc := util:document-name($d)
    let $day := $d/ancestor::tei:div[@type='dia']
    return <hit>
         <date>
          <a  href="index.html?action=view-section&amp;doc={$doc}&amp;id={$day/@xml:id}">{data($d)}</a>
         </date>
         <Actas></Actas>
         <Diario>{
           for $hit in $hitsD
           let $div := $hit/ancestor::tei:div[1]
           let $title : = proyecto:derive-title($div)
           let $cntxt := if (substring($title,1,6)='Sesion') then
                           'Sesion'
                         else
                           $title
           let $match  := if (string-length($hit/string())=string-length($query)) then
                           '='
                          else
                           '*'
           where $d = $hit/ancestor::tei:div[@type='dia']/tei:head/tei:date/@when
           return
                 <a class="searchtp" data-tpcontent="{$hit/string()}"
                    href="index.html?action=view-section&amp;doc={$doc}&amp;id={$div/@xml:id}">{concat($cntxt,' ',$match)}</a>
         }</Diario>
         </hit>
let $ohitsA :=
    for $d in $hitsA/ancestor::tei:div[@type='dia']/tei:head/tei:date/@when
    let $doc := util:document-name($d)
    let $day := $d/ancestor::tei:div[@type='dia']
    return <hit>
         <date>
          <a  href="index.html?action=view-section&amp;doc={$doc}&amp;id={$day/@xml:id}">{data($d)}</a>
         </date>
         <Actas>{
           for $hit in $hitsA
           let $div := $hit/ancestor::tei:div[1]
           let $title : = proyecto:derive-title($div)
           let $cntxt := if (substring($title,1,6)='Sesion') then
                           'Sesion'
                         else
                           $title
           let $match  := if (string-length($hit/string())=string-length($query)) then
                           '='
                          else
                           '*'
           where $d = $hit/ancestor::tei:div[@type='dia']/tei:head/tei:date/@when
           return
                 <a class="searchtp" data-tpcontent="{$hit/string()}"
                    href="index.html?action=view-section&amp;doc={$doc}&amp;id={$div/@xml:id}">{concat($cntxt,' ',$match)}</a>
         }</Actas>
         <Diario></Diario>
         </hit>
let $ohits := for $hit in ($ohitsD,$ohitsA)
              order by $hit/date
              return $hit
return
    <div>
        <h2>The place "{$query}" is mentioned</h2>
        <h3>{$noHitsActas} times in Actas de Comision</h3>
        <h3>{$noHitsDiario} times in Diario de Sesiones</h3>
        <span>Links indicate context in document. P: Proyecto, C: Constitucion.
           '=': exact match; '*': query matches substring.
           Tooltip shows name as written in document.
        </span>
       {local:sequence-to-table($ohits)}
    </div>
};




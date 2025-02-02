xquery version "1.0";

(:~ Module: proyecto.xqm
 :
 :  This module contains Proyecto-specific functions
 :)

module namespace proyecto = "http://chlt.es/ns/proyecto";
import module namespace config = "http://chlt.es/ns/proyecto/config"     at "config.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

(: Header :)

declare function proyecto:showHeader($node, $doc) {
    if ($node/tei:teiHeader) then
        <ul>{
            for $desc in $node/tei:teiHeader/*
            let $descname := local-name($desc)
            return <li><a href="index.html?action=view-desc&amp;doc={$doc}&amp;id={$descname}">{proyecto:derive-desc-title($descname)}</a></li>
        }</ul>
    else ()
};


declare function proyecto:derive-desc-title($desc) {
    if ($desc eq 'fileDesc') then
       'File Descriptor'
    else if ($desc eq 'encodingDesc') then
       'Encoding Descriptor'
    else if ($desc eq 'profileDesc') then
       'Profile Descriptor'
    else if ($desc eq 'revisionDesc') then
       'Revision Descriptor'
    else ''
};

declare function proyecto:generate-toc-from-listPerson($node, $doc) {
    if ($node/tei:person) then
        <ul>{
            for $person in $node/tei:person
            return <li><a href="index.html?action=view-person&amp;doc={$doc}&amp;id={$person/@xml:id/string()}">{proyecto:derive-person-name($person)}</a></li>
        }</ul>
    else ()
};

declare function proyecto:derive-person-name($p) {
    let $name := 
        if ($p/tei:persName) then 
            string-join(for $node in $p/tei:persName/* return data($node), ' ') 
        else if (string-length(data($p)) gt 0) then 
            $p/@xml:id/string()
        else 
            concat('[error]')
    return $name
};

(: Content :)

declare function proyecto:doc-title($node) {
    let $doc := 
        if ($node/tei:TEI) then
            $node
        else 
            $node/ancestor::tei:TEI
   return string-join($doc/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title, ', ')
};

declare function proyecto:title-doc-section($docname, $section) {
    let $doc := proyecto:get-doc-from-name($docname)
    let $div := $doc/id($section)
    let $title := concat(proyecto:doc-title($doc), ', ', proyecto:derive-title($div))
    return 
        $title
};

declare function proyecto:get-doc-from-name($docname)
{
    doc(local:get-path-from-name($docname))
};

declare function local:get-path-from-name($name) {
    let $collpath := if (substring($name,1,6)='Diario' or $name='ActasSecretas.xml')
                    then    $config:data-tei-diarios
                    else    $config:data-tei
    let $docpath := concat($collpath, '/', $name)
    return 
      $docpath
};

declare function proyecto:resolve-section($docname, $section)
{
let $doc := proyecto:get-doc-from-name($docname)
(: 
 : art and pro ids
let $stoks := tokenize($section,'-')
let $sids  := if ($stoks[1]='pro')
    then stoks[6]
    else stoks[5]
let $idtoks := tokenize($sids, ':')
let $first  := $idtoks[1]
:)
return
    $doc/id($section)
};

declare function proyecto:combine-arthead-items($div)
{
    if ($div/@type =('arthead','artitem'))
    then  $div/../tei:div[@type = ('arthead','artitem')][@corresp=$div/@corresp]
    else  $div
};

declare function proyecto:get-pages-from-div($div) {
    let $firstpage := ($div/preceding::tei:pb)[last()]/@n/string()
    let $lastpage := if ($div//tei:pb) then ($div//tei:pb)[last()]/@n/string() else ()
    return
        if ($firstpage ne '' or $lastpage ne '') then 
            concat(' (', string-join(($firstpage, $lastpage), '-'), ')') 
        else ()
};

declare function local:div-nogos($type)
{   
    if ($type = ('discurso', 'discutido', 'artitem', 'resumen', 'resultat'))
    then false()
    else true()
};

declare function proyecto:generate-toc-from-divs($node, $doc) {
let $roots := count($node/tei:div[local:div-nogos(@type)])
return
    if ($roots=0)
    then ()
    else if ($roots=1)
    then local:generate-toc-from-divs($node, $doc, 1)
    else local:generate-toc-from-divs($node, $doc, 2)
};

declare function local:generate-toc-from-divs($node, $doc, $level) {
    if ($node/tei:div) then
        <ul>{
            for $div in $node/tei:div[local:div-nogos(@type)]
            return proyecto:toc-div($div, $doc, $level)
        }</ul>
    else ()
};

declare function proyecto:derive-title($div) {
    let $title := 
        if ($div/tei:head) then 
            string-join(for $node in $div/tei:head/node()[local-name(.)!='ref'] return data($node), ' ') 
        else if ($div/@type='mes') then 
            proyecto:format-month-header($div/@xml:id/string())
        else if ($div/@type=('articulo','arthead','artitem','discurso','discutido','resumen','resultat')) then 
            proyecto:format-diario-header($div, $div/@type)
        else if ($div/@type='part') then
            proyecto:format-pro-part-header($div/@xml:id/string())
        else if ($div/@type='pro-art') then
            proyecto:format-pro-art-header($div/@xml:id/string())
        else if (string-length(data($div)) gt 0) then
            $div/@xml:id/string()
        else 
            concat('[', $div/@type/string, ']')
    return $title
};

declare function proyecto:format-month-header($id) {
  (: "Name-Year-Month" :)
  let $parts := tokenize($id,'-')
  let $name  := $parts[1]
  let $year  := $parts[2]
  let $month := $parts[3]
  return
      concat('Sesiones de ', proyecto:format-month($month), ' de ', $year)

};

declare function proyecto:format-diario-header($div, $type) {
  let $pro := if (count($div/@corresp)=1) then
                 substring-after($div/@corresp,'proyecto.xml#')
              else
              	 'pro-p4-99-99-99'
  let $proid := tokenize($pro,' ')[1]
  let $parts := tokenize($proid,'-')
  let $prefix := if ($type='discurso') then
                   'Discurso: '
                 else if ($type='resumen') then
                   'Resumen: '
                 else 
                    ''
  return
     concat('Art. ', $parts[5], ' P')
};

declare function proyecto:format-pro-part-header($id) {
    if ($id) then
      concat('Parte ', substring($id,6), '.')
    else
      $id
};

declare function proyecto:format-pro-art-header($id) {
    if ($id) then
      concat('Articulos de Parte ', substring($id,6,1), '.')
    else
      $id
};

declare function proyecto:format-month($mno) {
    if      ($mno eq "01") then "Enero"
    else if ($mno eq "02") then "Februario"
    else if ($mno eq "03") then "Marzo"
    else if ($mno eq "04") then "Abril"
    else if ($mno eq "05") then "Maio"
    else if ($mno eq "06") then "Junio"
    else if ($mno eq "07") then "Julio"
    else if ($mno eq "08") then "Agosto"
    else if ($mno eq "09") then "Septiembre"
    else if ($mno eq "10") then "Octubre"
    else if ($mno eq "11") then "Noviembre"
    else if ($mno eq "12") then "Diciembre"
    else "invalid month"
};

declare function proyecto:toc-div($div, $doc, $level) {
    let $section := $div/@xml:id/string()
    let $title   := proyecto:derive-title($div)
    return
        if ($div/@type='pro-art')
        then  local:generate-toc-from-divs($div, $doc, $level+1)
        else
        <li>{if ((matches($section, 'Diario') or matches($section, 'Actas')
                  or matches($section, 'art') or matches($section, 'pro'))
                  and local:has-child-divs($div)) (: if children :)
            then (
                element {"input"} {
                    attribute {"type"} {"checkbox"},
                    attribute {"id"}   {$section},
                    if ($level=1) 
                    then attribute {"checked"} {"checked"}
                    else ()
                },
                <label for="{$section}">
                <a href="index.html?action=view-section&amp;doc={$doc}&amp;id={$section}">{$title}</a></label>
                )
            else
                <a style="margin-left:38px;font-weight:bold;"
                    href="index.html?action=view-section&amp;doc={$doc}&amp;id={$section}">{$title}</a>
            }
            { proyecto:get-pages-from-div($div) }
            { local:generate-toc-from-divs($div, $doc, $level+1) }
        </li>
};

declare function local:has-child-divs($div)
{
  let $no := count($div/tei:div[local:div-nogos(@type)])
  return
      $no>0
};
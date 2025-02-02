xquery version "1.0";

(:~ Module: tei-to-html.xqm
 :
 :  This module uses XQuery 'typeswitch' expression to transform TEI into HTML.
 :  It performs essentially the same function as XSLT stylesheets, but uses
 :  XQuery to do so.  If your project is already largely XQuery-based, you will 
 :  find it very easy to change and maintain this code, since it is pure XQuery.
 :
 :  This design pattern uses one function per TEI element (see
 :  the tei-to-html:dispatch() function starting on ~ line 47).  So if you 
 :  want to adjust how the module handles TEI div elements, for example, go to 
 :  tei-to-html:div().  If you need the module to handle a new element, just add 
 :  a function.  The length of the module may be daunting, but it is quite clearly
 :  structured.  
 :
 :  To use this module from other XQuery files, include the module 
 :     import module namespace render = "http://history.state.gov/ns/tei-to-html" at "../modules/tei-to-html.xqm";
 :  and pass the TEI fragment to tei-to-html:render() as
 :     tei-to-html:render($teiFragment, $options)
 :  where $options contains parameters and other info you might want your 
 :  tei-to-html functions to make use of in a parameters element:
 :     <parameters xmlns="">
 :         <param name="relative-image-path" value="/rest/db/punch/data/images/"/>
 :     </parameters>
 :)

module namespace tei-to-html = "http://chlt.es/ns/tei-to-html";

declare namespace tei="http://www.tei-c.org/ns/1.0";

(: A helper function in case no options are passed to the function :)
declare function tei-to-html:render($content as node()*) as element() {
    tei-to-html:render($content, ())
};

(: The main function for the tei-to-html module: Takes TEI content, turns it into HTML, and wraps the result in a div element :)
declare function tei-to-html:render($content as node()*, $options as element(parameters)*) as element() {
    <div class="document">
        { tei-to-html:dispatch($content, $options) }
    </div>
};

(: Typeswitch routine: Takes any node in a TEI content and either dispatches it to a dedicated 
 : function that handles that content (e.g. div), ignores it by passing it to the recurse() function
 : (e.g. text), or handles it directly (e.g. lb). :)
declare function tei-to-html:dispatch($node as node()*, $options) as item()* {
    typeswitch($node)
        case text() return $node
        case element(tei:TEI) return tei-to-html:recurse($node, $options)
        (: header :)
        case element(tei:teiHeader) return tei-to-html:recurse($node, $options)
        case element(tei:fileDesc) return tei-to-html:fileDesc($node, $options)
        case element(tei:encodingDesc) return tei-to-html:recurse($node, $options)
        case element(tei:profileDesc) return tei-to-html:recurse($node, $options)
        case element(tei:revisionDesc) return tei-to-html:revisionDesc($node, $options)
        case element(tei:change) return tei-to-html:change($node, $options)
        (: text :)
        case element(tei:text) return tei-to-html:recurse($node, $options)
        case element(tei:front) return tei-to-html:recurse($node, $options)
        case element(tei:body) return tei-to-html:recurse($node, $options)
        case element(tei:back) return tei-to-html:recurse($node, $options)
        case element(tei:div) return tei-to-html:div($node, $options)
        case element(tei:head) return tei-to-html:head($node, $options)
        case element(tei:p) return tei-to-html:p($node, $options)
        (: critical edition :)
        case element(tei:add) return tei-to-html:recurse($node, $options)
        case element(tei:choice) return tei-to-html:choice($node, $options)
        case element(tei:corr) return tei-to-html:recurse($node, $options)
        case element(tei:del) return tei-to-html:recurse($node, $options)   
        case element(tei:sic) return tei-to-html:recurse($node, $options)
        (: figures :)
        case element(tei:figure) return tei-to-html:figure($node, $options)
        case element(tei:graphic) return tei-to-html:graphic($node, $options)
        (: table :)
        case element(tei:table) return tei-to-html:table($node, $options)
        case element(tei:row) return tei-to-html:row($node, $options)
        case element(tei:cell) return tei-to-html:cell($node, $options)
        (: person :)
        case element(tei:particDesc) return tei-to-html:recurse($node, $options)
        case element(tei:listPerson) return tei-to-html:recurse($node, $options)  
        case element(tei:person) return tei-to-html:person($node, $options)
        case element(tei:persName) return tei-to-html:persName($node, $options)
        case element(tei:birth) return tei-to-html:birth($node, $options)       
        case element(tei:death) return tei-to-html:death($node, $options)       
        case element(tei:affiliation) return tei-to-html:affiliation($node, $options)   
        case element(tei:placeName) return tei-to-html:placeName($node, $options)   
        case element(tei:langKnowledge) return tei-to-html:langKnowledge($node, $options)   
        case element(tei:nationality) return tei-to-html:nationality($node, $options)   
        case element(tei:occupation) return tei-to-html:occupation($node, $options)   
        case element(tei:event) return tei-to-html:event($node, $options)   
        (: the rest alphabetically :)
        case element(tei:abbr) return tei-to-html:abbr($node, $options)
             
        case element(tei:g) return tei-to-html:g($node, $options)
        case element(tei:hi) return tei-to-html:hi($node, $options)
        case element(tei:label) return tei-to-html:label($node, $options)
        case element(tei:lb) return <br/>
        case element(tei:lg) return tei-to-html:lg($node, $options)
        case element(tei:l) return tei-to-html:l($node, $options)
        case element(tei:list) return tei-to-html:list($node, $options)
        case element(tei:item) return tei-to-html:item($node, $options)
        case element(tei:milestone) return tei-to-html:milestone($node, $options)
        case element(tei:name) return tei-to-html:name($node, $options)
        case element(tei:note) return tei-to-html:note($node, $options)
        case element(tei:pb) return tei-to-html:pb($node, $options)
        case element(tei:quote) return tei-to-html:quote($node, $options)
        case element(tei:ref) return tei-to-html:ref($node, $options)
        case element(tei:rs) return tei-to-html:rs($node, $options)
        case element(tei:said) return tei-to-html:said($node, $options)
        case element(tei:unclear) return tei-to-html:unclear($node, $options)
        default return tei-to-html:recurse($node, $options)
};

(: Recurses through the child nodes and sends them tei-to-html:dispatch() :)
declare function tei-to-html:recurse($node as node(), $options) as item()* {
    for $node in $node/node()
    return 
        tei-to-html:dispatch($node, $options)
};

declare function tei-to-html:corresp($node as element(tei:div), $options) as element()+ {
    let $links := tokenize($node/@corresp, ' ')
    for $link in $links
    return
      tei-to-html:make-link($link, $options)
};
    
declare function tei-to-html:make-link($link, $options) as element() {
    let $doc := substring-before($link, '#')
    let $pid := substring-after($link, '#')
    let $art := tokenize($pid,'-')
    let $target := concat('index.html?action=view-section&amp;doc=', $doc, '&amp;id=', $pid)
    let $type   := 'Art' 
    return
        element a { 
            attribute href { $target },
      (:      attribute title { $target }, :)
            attribute class { $type },
            attribute data-tptitle { $doc },
            attribute data-tpcontent { 'blabla' },
            $pid
            }
};

declare function tei-to-html:div($node as element(tei:div), $options) as element() {
  <span class="{$node/@type/string()}">{
    if ($node/@xml:id) then tei-to-html:xmlid($node, $options) else (),
    if ($node/@corresp) then tei-to-html:corresp($node, $options) else (),
(:  if ($node/@type='articulo')
    then
        (
        if ($node/tei:head) then tei-to-html:head($node/tei:head, $options) else (),
        <span class="bordered">
            {for $sub in $node/*[local-name(.) != 'head'] 
             return 
                 tei-to-html:dispatch($sub, $options)}
        </span>
        )
    else :) 
        tei-to-html:recurse($node, $options)
  }</span>
};

declare function tei-to-html:head($node as element(tei:head), $options) as element() {
    (: div heads :)
    if ($node/parent::tei:div) then
        let $type := $node/parent::tei:div/@type
        let $div-level := count($node/ancestor::div)
        return
            element {concat('h', $div-level + 2)} {tei-to-html:recurse($node, $options)}
    (: figure heads :)
    else if ($node/parent::tei:figure) then
        if ($node/parent::tei:figure/parent::tei:p) then
            <strong>{tei-to-html:recurse($node, $options)}</strong>
        else (: if ($node/parent::tei:figure/parent::tei:div) then :)
            <p><strong>{tei-to-html:recurse($node, $options)}</strong></p>
    (: list heads :)
    else if ($node/parent::tei:list) then
        <li>{tei-to-html:recurse($node, $options)}</li>
    (: table heads :)
    else if ($node/parent::tei:table) then
        <p class="center">{tei-to-html:recurse($node, $options)}</p>
    (: other heads? :)
    else
        tei-to-html:recurse($node, $options)
};

declare function tei-to-html:p($node as element(tei:p), $options) as element() {
    let $rend := $node/@rend
    return 
        if ($rend = ('right', 'center') ) then
            <p>{ attribute class {data($rend)} }{ tei-to-html:recurse($node, $options) }</p>
        else <p>{tei-to-html:recurse($node, $options)}</p>
};

declare function tei-to-html:hi($node as element(tei:hi), $options) as element()* {
    let $rend := $node/@rend
    return
        if ($rend = 'it') then
            <em>{tei-to-html:recurse($node, $options)}</em>
        else if ($rend = 'sc') then
            <span style="font-variant: small-caps;">{tei-to-html:recurse($node, $options)}</span>
        else 
            <span class="hi">{tei-to-html:recurse($node, $options)}</span>
};

(: ----------------------------------------------------------------------------------------- :)
(: teiHeader :)
declare function tei-to-html:fileDesc($node as element(tei:fileDesc), $options) as element() {
    <ul>
      {tei-to-html:titleStmt($node/tei:titleStmt, $options)}
      {tei-to-html:editionStmt($node/tei:editionStmt, $options)}
      {tei-to-html:sourceDesc($node/tei:sourceDesc, $options)}
    </ul>
};
declare function tei-to-html:titleStmt($node as element(tei:titleStmt), $options)  {
let $resps := $node/tei:respStmt
return
<li>Title: {$node/tei:title/text()}<br/>
    Author: {$node/tei:author/text()}<br/>
    Responsibility:
    <ul> 
    {for $resp in $resps
     return
         <li>{$resp/tei:resp}: {tei-to-html:name($resp/tei:name, $options)}</li>}
    </ul>
    Sponsor: {$node/tei:sponsor/text()}</li>
};

declare function tei-to-html:editionStmt($node as element(tei:editionStmt), $options)  {
<li>Date: {$node/tei:edition/tei:date/text()}</li>
};

declare function tei-to-html:sourceDesc($node as element(tei:sourceDesc), $options)  {
<li>Source: {tei-to-html:recurse($node,$options)}</li>
};

(:
      <fileDesc>
         </editionStmt>
         <publicationStmt>
           <pubPlace>Cadiz, Spain</pubPlace>
           <publisher>Constitucion Consortium</publisher>
           <address>
             <addrLine>Hans Artz</addrLine>
             <addrLine>1101 Cadiz, Jose de Torro 6, 2nd A</addrLine>
             <addrLine>Spain</addrLine>
             <addrLine>url:http://www.constitution.org</addrLine>
           </address>
           <date>2012-10-31</date>
         </publicationStmt>
         <sourceDesc>
           <biblStruct>
             <monogr>
               <author>La Comision, d. 1811</author>
               <title type="main">Actas de la Comision nombrada</title>
               <title type="subordinate">para<lb/>la formacion del proiecto de Constitucion.</title>
               <edition>Ed. facsimile</edition>
               <imprint>
                 <pubPlace>Cadiz</pubPlace>
                 <publisher>unknown</publisher>
                 <date>2 de Marco 1811</date>
               </imprint>
               <extent>xx? p. (1 vols) ; xx cm.</extent>
             </monogr>
           </biblStruct>
         </sourceDesc>
      </fileDesc>
:)
declare function tei-to-html:revisionDesc($node as element(tei:revisionDesc), $options) as element() {
    <ul>
       {tei-to-html:recurse($node, $options)}
    </ul>
};

declare function tei-to-html:change($node as element(tei:change), $options) as element() {
    <li>{if ($node/@when) then $node/@when/string() else 'no date'} by 
        {if ($node/@who)
        then 
            let $doc := substring-before($node/@who/string(), '#')
            let $pid := substring-after($node/@who/string(), '#')
            return
            <a href="index.html?action=view-person&amp;doc={$doc}&amp;id={$pid}"> {$pid} </a>
        else ' no resp '} 
        {concat(' - ', $node/text())}
    </li>
};


(: ----------------------------------------------------------------------------------------- :)
(: person :)

declare function tei-to-html:person($node as element(tei:person), $options) as element() {
    <div><h2>{if ($node/@xml:id) then tei-to-html:derive-person-name($node)  else 'no id'}</h2>
       <dl class="bioPerson">{tei-to-html:recurse($node, $options)}</dl>
    </div>
};

declare function tei-to-html:derive-person-name($p) {
    let $name := 
        if ($p/tei:persName) then 
            string-join(for $node in $p/tei:persName/* return data($node), ' ') 
        else if (string-length(data($p)) gt 0) then 
            $p/@xml:id/string()
        else 
            concat('[error]')
    return $name
};

declare function tei-to-html:persName($p as element(tei:persName), $options) as element()* {
(:    <dt>Name</dt>,
    <dd>{string-join(for $node in $p/node() return data($node), ' ')}</dd>
:)
  ()
};

declare function tei-to-html:birth($node as element(tei:birth), $options) as element()+ {
    <dt>Birth</dt>,
    <dd>{tei-to-html:recurse($node, $options)}</dd>
};

declare function tei-to-html:death($node as element(tei:death), $options) as element()+ {
    <dt>Death</dt>,
    <dd>{tei-to-html:recurse($node, $options)}</dd>
};

declare function tei-to-html:affiliation($node as element(tei:affiliation), $options) as element()+ {
    <dt>Affiliation</dt>,
    <dd>{tei-to-html:recurse($node, $options)}</dd>
};

declare function tei-to-html:placeName($place as element(tei:placeName), $option)  {
    concat(' in ', string-join(for $node in $place/node() return data($node), ', '))
};
declare function tei-to-html:langKnowledge($node as element(tei:langKnowledge), $options) as element()+ {
    <dt>Language</dt>,
    <dd>{tei-to-html:recurse($node, $options)}</dd>
};

declare function tei-to-html:nationality($node as element(tei:nationality), $options) as element()+ {
    <dt>Nationality</dt>,
    <dd>{tei-to-html:recurse($node, $options)}</dd>
};

declare function tei-to-html:occupation($node as element(tei:occupation), $options)  {
    <dt>Occupation</dt>,
    <dd>{tei-to-html:recurse($node, $options)}</dd> 
};

declare function tei-to-html:event($node as element(tei:event), $options)  {
  if ($node/@when) then (
    <dt>{$node/@when/string()}</dt>,
    <dd>{tei-to-html:recurse($node, $options)}</dd> )
  else (
    <dt>Biography</dt>,
    <dd>{tei-to-html:recurse($node, $options)}</dd> )
};

(: ----------------------------------------------------------------------------------------- :)
(: critical edition :)
declare function tei-to-html:add($node as element(tei:add), $options)  {
   tei-to-html:recurse($node, $options)
};
declare function tei-to-html:choice($node as element(tei:choice), $options)  {
   tei-to-html:recurse($node, $options)
};
declare function tei-to-html:corr($node as element(tei:corr), $options)  {
   tei-to-html:recurse($node, $options)
};
declare function tei-to-html:del($node as element(tei:del), $options)  {
   tei-to-html:recurse($node, $options)
};
declare function tei-to-html:sic($node as element(tei:sic), $options)  {
   tei-to-html:recurse($node, $options)
};
 
(: ----------------------------------------------------------------------------------------- :)
(: figure :)

declare function tei-to-html:figure($node as element(tei:figure), $options) {
    <div class="figure">{tei-to-html:recurse($node, $options)}</div>
};

declare function tei-to-html:graphic($node as element(tei:graphic), $options) {
    let $url := $node/@url
    let $head := $node/following-sibling::tei:head
    let $width := if ($node/@width) then $node/@width else '800px'
    let $relative-image-path := $options/*:param[@name='relative-image-path']/@value
    return
        <img src="{if (starts-with($url, '/')) then $url else concat($relative-image-path, $url)}" alt="{normalize-space($head[1])}" width="{$width}"/>
};

(: ----------------------------------------------------------------------------------------- :)
(: table :)

declare function tei-to-html:table($node as element(tei:table), $options) as element() {
    <table>{tei-to-html:recurse($node, $options)}</table>
};

declare function tei-to-html:row($node as element(tei:row), $options) as element() {
    let $label := $node/@role[. = 'label']
    return
        <tr>{if ($label) then attribute class {'label'} else ()}{tei-to-html:recurse($node, $options)}</tr>
};

declare function tei-to-html:cell($node as element(tei:cell), $options) as element() {
    let $label := $node/@role[. = 'label']
    return
        <td>{if ($label) then attribute class {'label'} else ()}{tei-to-html:recurse($node, $options)}</td>
};

(: ----------------------------------------------------------------------------------------- :)
(: rest :)

declare function tei-to-html:abbr($node as element(tei:abbr), $options) {
let $t := for $n in $node/node()
    return
        if (local-name($n)='g')
        then tei-to-html:g($n, $options)
        else $n
return 
    <span class="abbr">{$t}</span>
};

declare function tei-to-html:g($node as element(tei:g), $options)  {
    (
        <span class="glyph">{$node/string()}</span>,
        '. '
    )
};

declare function tei-to-html:item($node as element(tei:item), $options) as element()+ {
    if ($node/@xml:id) then tei-to-html:xmlid($node, $options) else (),
    <li>{tei-to-html:recurse($node, $options)}</li>
};

declare function tei-to-html:label($node as element(tei:label), $options) as element()+ {
    if ($node/parent::tei:list) then 
        (
        <dt>{$node/text()}</dt>,
        <dd>{$node/following-sibling::tei:item[1]}</dd>
        )
    else tei-to-html:recurse($node, $options)
};

declare function tei-to-html:list($node as element(tei:list), $options) as element() {
    <ul>{tei-to-html:recurse($node, $options)}</ul>
};

declare function tei-to-html:lg($node as element(tei:lg), $options) {
    <div class="lg">{tei-to-html:recurse($node, $options)}</div>
};

declare function tei-to-html:l($node as element(tei:l), $options) {
    let $rend := $node/@rend
    return
        if ($node/@rend eq 'i2') then 
            <div class="l" style="padding-left: 2em;">{tei-to-html:recurse($node, $options)}</div>
        else 
            <div class="l">{tei-to-html:recurse($node, $options)}</div>
};

declare function tei-to-html:milestone($node as element(tei:milestone), $options) {
    if ($node/@unit eq 'rule') then
        if ($node/@rend eq 'stars') then 
            <div style="text-align: center">* * *</div>
        else if ($node/@rend eq 'hr') then
            <hr style="margin: 7px;"/>
        else
            <hr/>
    else 
        <hr/>
};

declare function tei-to-html:name($node as element(tei:name), $options) {
    let $doc := substring-before($node/@ref/string(), '#')
    let $pid := substring-after($node/@ref/string(), '#')
    return
(:
        if ($rend eq 'sc') then 
            <span class="name" style="font-variant: small-caps;">{tei-to-html:recurse($node, $options)}</span>
        else 
:)
      <a href="index.html?action=view-person&amp;doc={$doc}&amp;id={$pid}">{tei-to-html:recurse($node, $options)}</a>
};

declare function tei-to-html:note($node as element(tei:note), $options) {
(: TODO bugs bugs :)
    if ($node/tei:p)
    then <span class="leftnote">{$node/*/text()}</span> 
    else <span class="leftnote">{tei-to-html:recurse($node, $options)}</span>
};

declare function tei-to-html:pb($node as element(tei:pb), $options) {
    if ($node/@xml:id) then tei-to-html:xmlid($node, $options) else (),
    if ($options/*:param[@name='show-page-breaks']/@value = 'true') then
        <span class="pagenumber">{ concat('[', $node/@n/string(),']') }</span>
    else ()
};

declare function tei-to-html:q($node as element(tei:q), $options) {
    <blockquote class="{$node/@rend/string()}">{tei-to-html:recurse($node, $options)}</blockquote>
};

declare function tei-to-html:quote($node as element(tei:quote), $options) {
    <blockquote>{tei-to-html:recurse($node, $options)}</blockquote>
};


declare function tei-to-html:ref($node as element(tei:ref), $options) {
    let $doc := substring-before($node/@target/string(), '#')
    let $pid := substring-after($node/@target/string(), '#')
    let $target := concat('index.html?action=view-section&amp;doc=', $doc, '&amp;id=', $pid)
    let $type   := 'tooltip'       (: $node/@type :)
    return
        element a { 
            attribute href { $target },
      (:      attribute title { $target }, :)
            attribute class { $type },
            attribute data-tptitle { 'Commision' },
            attribute data-tpcontent { 'La Nacion española es la reunion de todos los españoles de ambos emisferios.' },
            tei-to-html:recurse($node, $options) 
            }
};

declare function tei-to-html:rs($node as element(tei:rs), $options) {
     <div id="rs">{tei-to-html:recurse($node, $options)}</div>
};

declare function tei-to-html:said($node as element(tei:said), $options) as element() {
    <p class="said">{tei-to-html:recurse($node, $options)}</p>
};

declare function tei-to-html:unclear($node as element(tei:unclear), $options) {
     <span class="unclear">{tei-to-html:recurse($node, $options)}</span>
};


declare function tei-to-html:xmlid($node as element(), $options) as element() {
    <a name="{$node/@xml:id}"/>
};


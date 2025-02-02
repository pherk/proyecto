xquery version "3.0";

module namespace app="http://constitucion.org/exist/app/proyecto";

import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace i18n = "http://exist-db.org/xquery/i18n" at "i18n.xqm";

declare namespace tei = "http://www.tei-c.org/ns/1.0";

import module namespace tei-to-html = "http://chlt.es/ns/tei-to-html" at "tei-to-html.xqm";
import module namespace proyecto = "http://chlt.es/ns/proyecto" at "proyecto.xqm";
import module namespace search = "http://chlt.es/ns/proyecto/search" at "search.xqm";
import module namespace config="http://chlt.es/ns/proyecto/config" at "config.xqm";


declare function app:main($node as node(), $model as map(*), $action, $doc, $id, $type) {
    if ($action="view-doc-toc")
        then app:view-doc-toc($doc)
    else if ($action="view-section")
        then app:view-section($doc, $id)
    else if ($action="view-header")
        then app:view-header($doc)
    else if ($action="view-desc")
        then app:view-desc($doc, $id)
    else if ($action="view-person")
        then app:view-person($doc, $id)
    else if ($action="search")
        then app:doSearch($type, $id)
        else app:welcome()
};

declare function app:welcome()
{
let $breadcrumbs := ()
let $body :=
    <div>
        <h2><i18n:text key="welcome">Wellcome</i18n:text> to the Cádiz Digital Humanities Website</h2>
        <p>The site presents the digitized manuscripts and books documenting the
           development of the Constitucion Politica de la Monarquia Española during 1811 to 1812 in Cádiz.</p>
    </div>
let $content :=
    <div>
        {app:breadcrumbs($breadcrumbs)}
        {$body}
    </div>
return
    i18n:process($content, 'es', $config:data-i18n, 'en')
};

declare function app:listDocuments($node as node(), $model as map(*))
{
<div class="well sidebar-nav">
    <ul class="nav nav-list">
        <li class="nav-header">{<i18n:text key="Index">Index</i18n:text>}</li>
        {
            for $doc in xmldb:xcollection($config:data-tei)/tei:TEI
            let $title := $doc/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[not(@level) or @level="s"]
            let $file := util:document-name($doc)
            order by $file
            return
                <li><a href="{concat('index.html?action=view-doc-toc&amp;doc=', $file)}">{$title/text()} </a> </li>
        }
        <li class="nav-header">Diarios</li>
        {
            for $doc in xmldb:xcollection($config:data-tei-diarios)/tei:TEI
            let $title := $doc/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[not(@level) or @level="a"]
            let $file := util:document-name($doc)
            order by $file
            return
                <li><a href="{concat('index.html?action=view-doc-toc&amp;doc=', $file)}">{$title/text()}</a></li>
        }
    </ul>
</div>
};

declare function app:view-doc-toc($docname)
{
let $doc := proyecto:get-doc-from-name($docname)
let $text := $doc/tei:TEI/tei:text
let $title := string-join($doc/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title/text(), ': ')
let $listPerson := $doc/tei:TEI/tei:teiHeader/tei:profileDesc/tei:particDesc/tei:listPerson
let $breadcrumbs := ( <a href="">{$title}</a> )
let $body := if ($docname eq 'gente.xml') then
        <div class="css-treeview"><h2>{$title}</h2>{proyecto:generate-toc-from-listPerson($listPerson, $docname)}</div>
    else
       <div class="css-treeview"><h2>{$title}</h2>{proyecto:generate-toc-from-divs($text/tei:body, $docname)}</div>
let $content :=
    <div>
        {app:breadcrumbs($breadcrumbs)}
        {$body}
    </div>
return
    $content  
};

declare function app:view-section($docname, $section)
{
let $div := proyecto:resolve-section($docname, $section)
let $divs := proyecto:combine-arthead-items($div)
let $title := proyecto:doc-title(proyecto:get-doc-from-name($docname))
let $breadcrumbs := 
    (
    <a href="index.html?action=view-doc-toc&amp;doc={$docname}">{$title}</a>,
    <a href="">{proyecto:derive-title($div)}</a>
    )

let $tei-to-html := tei-to-html:render($divs, 
                    <parameters xmlns="">
                        <param name="relative-image-path" value="data/"/>
                        <param name="show-page-breaks" value="true"/>
                    </parameters>)

let $body := 
    if (not($tei-to-html//h2)) then <div><h2>{proyecto:derive-title($div)}</h2>{$tei-to-html}</div>
    else $tei-to-html
let $content :=
    <div>
        {app:breadcrumbs($breadcrumbs)}
        {$body}
    </div>
return
    $content 
};

declare function app:view-desc($docname, $descname)
{
let $doc   := proyecto:get-doc-from-name($docname)
let $desc  := if ($descname eq 'fileDesc') then
                  $doc/tei:TEI/tei:teiHeader/tei:fileDesc
              else if ($descname eq 'encodingDesc') then
                  $doc/tei:TEI/tei:teiHeader/tei:encodingDesc
              else if ($descname eq 'profileDesc') then
                  $doc/tei:TEI/tei:teiHeader/tei:profileDesc
              else if ($descname eq 'revisionDesc') then
                  $doc/tei:TEI/tei:teiHeader/tei:revisionDesc
              else 
                  $doc/tei:TEI/tei:teiHeader/tei:*
let $title := proyecto:doc-title($doc)
let $breadcrumbs := 
    (
    <a href="index.html?action=view-doc-toc&amp;doc={$docname}">{$title}</a>,
    <a href="">{proyecto:derive-desc-title($descname)}</a>
    )

let $tei-to-html := tei-to-html:render($desc, 
                    <parameters xmlns="">
                        <param name="relative-image-path" value="resources/images"/>
                        <param name="show-page-breaks" value="true"/>
                    </parameters>)

let $body := 
    if (not($tei-to-html//h2)) then <div><h2>{proyecto:derive-desc-title($descname)}</h2>{$tei-to-html}</div>
    else $tei-to-html
let $content :=
    <div>
        {app:breadcrumbs($breadcrumbs)}
        {$body}
    </div>
return
    $content 
};

declare function app:view-header($docname)
{
let $doc := proyecto:get-doc-from-name($docname)/tei:TEI
let $title := $doc/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title/text()
let $breadcrumbs := 
    (
        <a href="index.html?action=view-doc-toc&amp;doc={$docname}">{$title}</a>,
        <a href="">Header Info</a>
    )
let $body := 
    <div>
        <h2>{$title}</h2>
        <h3><i18n:text key="headerInfo">Header Information</i18n:text></h3>
        {proyecto:showHeader($doc, $docname)}
    </div>
let $content :=
    <div>
        {app:breadcrumbs($breadcrumbs)}
        {$body}
    </div>
return
    i18n:process($content,'es', $config:data-i18n,'en')
};

declare function app:view-person($docname, $pid)
{
let $doc := proyecto:get-doc-from-name($docname)
let $person := $doc/id($pid)
let $text   := if ($person) then $person else <p>Sorry, person {$pid} in '{$docname}' not found!</p>
let $title := proyecto:doc-title($doc)
let $breadcrumbs := 
    (
        <a href="index.html?action=view-doc-toc&amp;doc={$docname}">{$title}</a>,
        <a href="">{$pid}</a>
    )

let $tei-to-html := tei-to-html:render($text, 
                    <parameters xmlns="">
                        <param name="relative-image-path" value="resouces/images"/>
                        <param name="show-page-breaks" value="true"/>
                    </parameters>)

let $body := 
    if (not($tei-to-html//h2)) then <div><h2>{$title}</h2>{$tei-to-html}</div>
    else $tei-to-html
let $content :=
    <div>
        {app:breadcrumbs($breadcrumbs)}
        {$body}
    </div>
return
    $content
};


declare function app:search($node as node(), $model as map(*))
{
let $title    := <i18n:text key="search:">Search:</i18n:text>
let $o-text   := <i18n:text key="text">text</i18n:text>
let $o-article:= <i18n:text key="article">article</i18n:text>
let $o-speaker:= <i18n:text key="speaker">speaker</i18n:text>
let $o-name   := <i18n:text key="name">name</i18n:text>
let $o-place  := <i18n:text key="place">place</i18n:text>
let $submit   := <i18n:text key="submit">enviar</i18n:text>           (: todo enviar - i18n problem :)
let $box :=
    <div class="box bluebox">
        <form action="index.html" method="get">
            <h3>{$title}</h3>
            <div>
                <input type="hidden" name="action" value="search"/>
                <select name="type" class="ssearch">
                  <option id="text">{$o-text}</option>
                  <option id="article">{$o-article}</option>
                  <option id="speaker">{$o-speaker}</option>
                  <option id="name">{$o-name}</option>
                  <option id="place">{$o-place}</option>
                </select>
                <input class="isearch" type="text" name="id" size="15"/>
                <input class="gobox" type="submit" value="{$submit}"/>
            </div>
        </form>
    </div>
return
    i18n:process($box, 'es', $config:data-i18n, 'en')
};

declare function app:doSearch($type, $query)
{
let $title := 'Search'
let $breadcrumbs := <a href="">Search</a>

let $body :=
  if ($type = 'texto') then
    search:make-body-text($query)
  else if ($type = 'articulo') then
    search:make-body-art($query)
  else if ($type = 'orador') then
    search:make-body-orador($query)
  else if ($type = 'apellido') then
    search:make-body-name($query)
  else if ($type = 'lugar') then
    search:make-body-place($query)
  else 
       ('a')
    
let $content := 
    <div>
        {app:breadcrumbs($breadcrumbs)}
        {$body}
    </div>

return
    $content
};

declare function app:breadcrumbs($breadcrumbs as node()*) as element(ul)* {
    if ($breadcrumbs) then 
        let $breadcrumbDivider := ' &gt; '
        return
            <ul class="breadcrumb">
                <li><a href="index.html">Home</a> {$breadcrumbDivider}</li>
                {
                for $item at $count in $breadcrumbs
                return <li>{if ($count eq 1) then () else $breadcrumbDivider, $item}</li>
                }
            </ul>
    else ()
};

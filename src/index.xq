xquery version "1.0";

(: index.xq :)

(: This XQuery file provides links to the versions. :)

(: Since we want our results to be sent to the browser as HTML (as opposed to XML or text), 
 : we need to use this declaration :)
declare option exist:serialize 'method=xhtml media-type=text/html indent=yes';

(: Here the main routine of our XQuery begins: an HTML root element and its content.  
 : It is perfectly valid to embed your HTML inside an XQuery, with no XQuery expressions 
 :)
<html xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <title>Digital.Humanities@Cadiz: Proyecto eXist Website</title>
    </head>
    <body>
        <div>
            <h1>Wellcome to the Proyecto eXist Website</h1>
            <p>The site presents the digitized manuscripts and books documenting the
               development of the Constitucion Politica de la Monarquia Española during 1811 to 1812 in Cádiz.</p>
            <p>Improved presentation and usefulness of the site:
                <ul>
                    <li><a href="v5/list-docs.xq">Proyecto v5</a>: better linking the various documents
                        and advanced search function.</li>
                    <li><a href="v6/list-docs.xq">Proyecto v6</a>:
                        <ul>
                            <li>Diario 8/1811 to 3/1812 added</li>
                            <li>easy installation as xar package</li>
                            <li>file toc as css-tree</li>
                            <li>search function updated.</li>
                        </ul>
                    </li>
                    <li><a href="v7/list-docs.xq">Proyecto v7</a>:
                        <ul>
                            <li>i18n</li>
                        </ul>
                    </li>
                </ul>
            </p>
        </div>
    </body>
</html>
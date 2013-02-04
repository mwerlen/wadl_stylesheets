<?xml version="1.0" encoding="UTF-8"?>
<!--
  wadl_documentation.xsl (2008-12-09)

  An XSLT stylesheet for generating HTML documentation from WADL,
  by Mark Nottingham <mnot@yahoo-inc.com>.

  Copyright (c) 2006-2008 Yahoo! Inc.
  
  This work is licensed under the Creative Commons Attribution-ShareAlike 2.5 
  License. To view a copy of this license, visit 
    http://creativecommons.org/licenses/by-sa/2.5/ 
  or send a letter to 
    Creative Commons
    543 Howard Street, 5th Floor
    San Francisco, California, 94105, USA
-->
<!-- 
 * FIXME
    - Doesn't inherit query/header params from resource/@type
    - XML schema import, include, redefine don't import
-->
<!--
  * TODO
    - forms
    - link to or include non-schema variable type defs (as a separate list?)
    - @href error handling
-->

<xsl:stylesheet 
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
 xmlns:wadl="http://wadl.dev.java.net/2009/02"
 xmlns:xs="http://www.w3.org/2001/XMLSchema"
 xmlns:html="http://www.w3.org/1999/xhtml"
 xmlns:exsl="http://exslt.org/common"
 xmlns:ns="urn:namespace"
 extension-element-prefixes="exsl"
 xmlns="http://www.w3.org/1999/xhtml"
 exclude-result-prefixes="xsl wadl xs html ns"
 xmlns:fn="http://www.w3.org/2005/xpath-functions"
>

    <xsl:output 
        method="html" 
        encoding="UTF-8" 
        indent="yes"
        doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN"
        doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"
    />

    <xsl:variable name="wadl-ns">http://wadl.dev.java.net/2009/02</xsl:variable>

    
    <!-- expand @hrefs, @types into a full tree -->
    
    <xsl:variable name="resources">
        <xsl:apply-templates select="/wadl:application/wadl:resources" mode="expand"/>
    </xsl:variable>
		
    <xsl:template match="wadl:resources" mode="expand">
        <xsl:variable name="base">
            <xsl:choose>
                <xsl:when test="substring(@base, string-length(@base), 1) = '/'">
                    <xsl:value-of select="substring(@base, 1, string-length(@base) - 1)"/>
                </xsl:when>
                <xsl:otherwise><xsl:value-of select="@base"/></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:element name="resources" namespace="{$wadl-ns}">
            <xsl:for-each select="namespace::*">
                <xsl:variable name="prefix" select="name(.)"/>
                <xsl:if test="$prefix">
                    <xsl:attribute name="ns:{$prefix}"><xsl:value-of select="."/></xsl:attribute>
                </xsl:if>
            </xsl:for-each>
            <xsl:apply-templates select="@*|node()" mode="expand">
                <xsl:with-param name="base" select="$base"/>
            </xsl:apply-templates>            
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="wadl:resource[@type]" mode="expand" priority="1">
        <xsl:param name="base"></xsl:param>
        <xsl:variable name="uri" select="substring-before(@type, '#')"/>
        <xsl:variable name="id" select="substring-after(@type, '#')"/>
        <xsl:element name="resource" namespace="{$wadl-ns}">
			<xsl:attribute name="path"><xsl:value-of select="@path"/></xsl:attribute>
            <xsl:choose>
                <xsl:when test="$uri">
                    <xsl:variable name="included" select="document($uri, /)"/>
                    <xsl:copy-of select="$included/descendant::wadl:resource_type[@id=$id]/@*"/>
                    <xsl:attribute name="id"><xsl:value-of select="@type"/>#<xsl:value-of select="@path"/></xsl:attribute>
                    <xsl:apply-templates select="$included/descendant::wadl:resource_type[@id=$id]/*" mode="expand">
                        <xsl:with-param name="base" select="$uri"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="//resource_type[@id=$id]/@*"/>
                    <xsl:attribute name="id"><xsl:value-of select="$base"/>#<xsl:value-of select="@type"/>#<xsl:value-of select="@path"/></xsl:attribute>
                    <xsl:apply-templates select="//wadl:resource_type[@id=$id]/*" mode="expand">
                        <xsl:with-param name="base" select="$base"/>                        
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates select="node()" mode="expand">
                <xsl:with-param name="base" select="$base"/>
            </xsl:apply-templates>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="wadl:*[@href]" mode="expand">
        <xsl:param name="base"></xsl:param>
        <xsl:variable name="uri" select="substring-before(@href, '#')"/>
        <xsl:variable name="id" select="substring-after(@href, '#')"/>
        <xsl:element name="{local-name()}" namespace="{$wadl-ns}">
            <xsl:copy-of select="@*"/>
            <xsl:choose>
                <xsl:when test="$uri">
                    <xsl:attribute name="id"><xsl:value-of select="@href"/></xsl:attribute>
                    <xsl:variable name="included" select="document($uri, /)"/>
                    <xsl:apply-templates select="$included/descendant::wadl:*[@id=$id]/*" mode="expand">
                        <xsl:with-param name="base" select="$uri"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="id"><xsl:value-of select="$base"/>#<xsl:value-of select="$id"/></xsl:attribute>
                    <!-- xsl:attribute name="id"><xsl:value-of select="generate-id()"/></xsl:attribute -->
                    <xsl:attribute name="element"><xsl:value-of select="//wadl:*[@id=$id]/@element"/></xsl:attribute>
                    <xsl:attribute name="mediaType"><xsl:value-of select="//wadl:*[@id=$id]/@mediaType"/></xsl:attribute>                    
                    <xsl:attribute name="status"><xsl:value-of select="//wadl:*[@id=$id]/@status"/></xsl:attribute>                    
                    <xsl:attribute name="name"><xsl:value-of select="//wadl:*[@id=$id]/@name"/></xsl:attribute>                    
                    <xsl:apply-templates select="//wadl:*[@id=$id]/*" mode="expand">
                        <xsl:with-param name="base" select="$base"/>
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="node()[@id]" mode="expand">
        <xsl:param name="base"></xsl:param>
        <xsl:element name="{local-name()}" namespace="{$wadl-ns}">
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="id"><xsl:value-of select="$base"/>#<xsl:value-of select="@id"/></xsl:attribute>
            <!-- xsl:attribute name="id"><xsl:value-of select="generate-id()"/></xsl:attribute -->
            <xsl:apply-templates select="node()" mode="expand">
                <xsl:with-param name="base" select="$base"/>
            </xsl:apply-templates>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="@*|node()" mode="expand">
        <xsl:param name="base"></xsl:param>
        <xsl:copy>
            <xsl:apply-templates select="@*|node()" mode="expand">
                <xsl:with-param name="base" select="$base"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>

<!-- debug $resources
    <xsl:template match="/">
    <xsl:copy-of select="$resources"/>
    </xsl:template>
-->
        
    <!-- collect grammars (TODO: walk over $resources instead) -->
    
    <xsl:variable name="grammars">
        <xsl:copy-of select="/wadl:application/wadl:grammars/*[not(namespace-uri()=$wadl-ns)]"/>
        <xsl:apply-templates select="/wadl:application/wadl:grammars/wadl:include[@href]" mode="include-grammar"/>
        <xsl:apply-templates select="/wadl:application/wadl:resources/descendant::wadl:resource[@type]" mode="include-href"/>
        <xsl:apply-templates select="exsl:node-set($resources)/descendant::wadl:*[@href]" mode="include-href"/>
    </xsl:variable>
    
    <xsl:template match="wadl:include[@href]" mode="include-grammar">
        <xsl:variable name="included" select="document(@href, /)/*"></xsl:variable>
        <xsl:element name="wadl:include">
            <xsl:attribute name="href"><xsl:value-of select="@href"/></xsl:attribute>
            <xsl:copy-of select="$included"/> <!-- FIXME: xml-schema includes, etc -->
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="wadl:*[@href]" mode="include-href">
        <xsl:variable name="uri" select="substring-before(@href, '#')"/>
        <xsl:if test="$uri">
            <xsl:variable name="included" select="document($uri, /)"/>
            <xsl:copy-of select="$included/wadl:application/wadl:grammars/*[not(namespace-uri()=$wadl-ns)]"/>
            <xsl:apply-templates select="$included/descendant::wadl:include[@href]" mode="include-grammar"/>
            <xsl:apply-templates select="$included/wadl:application/wadl:resources/descendant::wadl:resource[@type]" mode="include-href"/>
            <xsl:apply-templates select="$included/wadl:application/wadl:resources/descendant::wadl:*[@href]" mode="include-href"/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="wadl:resource[@type]" mode="include-href">
        <xsl:variable name="uri" select="substring-before(@type, '#')"/>
        <xsl:if test="$uri">
            <xsl:variable name="included" select="document($uri, /)"/>
            <xsl:copy-of select="$included/wadl:application/wadl:grammars/*[not(namespace-uri()=$wadl-ns)]"/>
            <xsl:apply-templates select="$included/descendant::wadl:include[@href]" mode="include-grammar"/>
            <xsl:apply-templates select="$included/wadl:application/wadl:resources/descendant::wadl:resource[@type]" mode="include-href"/>
            <xsl:apply-templates select="$included/wadl:application/wadl:resources/descendant::wadl:*[@href]" mode="include-href"/>
        </xsl:if>
    </xsl:template>
    
    <!-- main template -->
        
    <xsl:template match="/wadl:application">   
        <document xmlns="http://maven.apache.org/XDOC/2.0"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/XDOC/2.0 http://maven.apache.org/xsd/xdoc-2.0.xsd">
            <body>
                <xsl:apply-templates select="wadl:doc"/>
				<section name="Sommaire" class="toc">
					<subsection name="Ressources">
                        <xsl:apply-templates select="exsl:node-set($resources)" mode="toc"/>
					</subsection>
					<subsection name="Representations">
                        <ul class="links">
                            <xsl:apply-templates select="exsl:node-set($resources)/descendant::wadl:representation" mode="toc"/>
                        </ul>
					</subsection>
                    <xsl:if test="descendant::wadl:fault">
					<subsection name="Erreurs">
                            <ul>
                                <xsl:apply-templates select="exsl:node-set($resources)/descendant::wadl:fault" mode="toc"/>
                            </ul>
					</subsection>
                    </xsl:if>
				</section>
				<section name="Ressources">
					<xsl:apply-templates select="exsl:node-set($resources)" mode="list"/>
				</section>
                <section name="Représentations">
					<xsl:apply-templates select="exsl:node-set($resources)/descendant::wadl:representation" mode="list"/>
					<subsection name="Autres représentations">
						<p>Toutes les représentations utilisées par ce WebService sont décrites dans le WADL associé.</p>
					</subsection>
				</section>
                <xsl:if test="exsl:node-set($resources)/descendant::wadl:fault">
					<section name="Erreurs">
						<xsl:apply-templates select="exsl:node-set($resources)/descendant::wadl:fault" mode="list"/>
					</section>
                </xsl:if>
            </body>
        </document>
    </xsl:template>

    <!-- Table of Contents -->

    <xsl:template match="wadl:resources" mode="toc">
        <xsl:variable name="base">
            <xsl:choose>
                <xsl:when test="substring(@base, string-length(@base), 1) = '/'">
                    <xsl:value-of select="substring(@base, 1, string-length(@base) - 1)"/>
                </xsl:when>
                <xsl:otherwise><xsl:value-of select="@base"/></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <ul class="links">
            <xsl:apply-templates select="wadl:resource" mode="toc">
                <xsl:with-param name="context"><xsl:value-of select="$base"/></xsl:with-param>
            </xsl:apply-templates>
        </ul>        
    </xsl:template>

    <xsl:template match="wadl:resource" mode="toc">
        <xsl:param name="context"/>
        <xsl:variable name="id"><xsl:call-template name="get-id"/></xsl:variable>
        <xsl:variable name="path"><xsl:value-of select="@path"/></xsl:variable>
        <xsl:variable name="name"><xsl:value-of select="$context"/><xsl:value-of select="@path"/></xsl:variable>
        <xsl:variable name="href"><xsl:value-of select="@path"/></xsl:variable>
		<xsl:if test="not(preceding-sibling::wadl:resource[@path=$path])">
			<li><a href="#{$href}"><xsl:value-of select="$name"/></a>
			<xsl:if test="../wadl:resource[@path=$path]/wadl:resource">
				<ul>
					<xsl:apply-templates select="wadl:resource" mode="toc">
						<xsl:with-param name="context" select="$name"/>
					</xsl:apply-templates>
				</ul>
			</xsl:if>
			</li>
		</xsl:if>
    </xsl:template>

    <xsl:template match="wadl:representation|wadl:fault" mode="toc">
        <xsl:variable name="id"><xsl:call-template name="get-id"/></xsl:variable>
		<xsl:variable name="element"><xsl:value-of select="@element"/></xsl:variable>
        <xsl:variable name="href" select="translate(@id,':','-')"/>
        <xsl:variable name="docTitle" select="./wadl:doc/@title"/>
        <xsl:choose>
            <xsl:when test="preceding::wadl:representation[@element=$element]"/>
            <xsl:when test="preceding::wadl:representation/wadl:doc[@title=$docTitle]">
				<xsl:message>Merging representation toc with doctitle : <xsl:value-of select="$docTitle"/></xsl:message>
			</xsl:when>
            <xsl:otherwise>               
                <li>
                    <a href="#{$id}">
                        <xsl:call-template name="representation-name"/>
                    </a>
                </li>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>        

    <!-- Listings -->
    
    <xsl:template match="wadl:resources" mode="list">
        <xsl:variable name="base">
            <xsl:choose>
                <xsl:when test="substring(@base, string-length(@base), 1) = '/'">
                    <xsl:value-of select="substring(@base, 1, string-length(@base) - 1)"/>
                </xsl:when>
                <xsl:otherwise><xsl:value-of select="@base"/></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:apply-templates select="wadl:resource" mode="list"/>
                
    </xsl:template>
    
    <xsl:template match="wadl:resource" mode="list">
        <xsl:param name="context"/>
        <xsl:variable name="path" select="@path"/>
		<xsl:variable name="id"><xsl:call-template name="get-id"/></xsl:variable>
		<xsl:variable name="name">
			<xsl:value-of select="$context"/><xsl:value-of select="@path"/>
			<xsl:for-each select="wadl:param[@style='matrix']">
				<span class="optional">;<xsl:value-of select="@name"/>=...</span>
			</xsl:for-each>
		</xsl:variable>
        <xsl:variable name="href" select="@path"/>
		<xsl:variable name="sectionName">
			<xsl:choose>
				<xsl:when test="wadl:doc[@title]"><xsl:value-of select="wadl:doc[@title][1]/@title"/></xsl:when>
				<xsl:otherwise>
					<xsl:copy-of select="$name"/>
					<xsl:for-each select="wadl:method[1]/wadl:request/wadl:param[@style='query']">
						<xsl:choose>
							<xsl:when test="@required='true'">
								<xsl:choose>
									<xsl:when test="preceding-sibling::wadl:param[@style='query']">&amp;</xsl:when>
									<xsl:otherwise>?</xsl:otherwise>
								</xsl:choose>
								<xsl:value-of select="@name"/>
							</xsl:when>
							<xsl:otherwise>
								<span class="optional">
									<xsl:choose>
										<xsl:when test="preceding-sibling::wadl:param[@style='query']">&amp;</xsl:when>
										<xsl:otherwise>?</xsl:otherwise>
									</xsl:choose>
									<xsl:value-of select="@name"/>
								</span>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:for-each>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<xsl:variable name="displaySectionName">
			<xsl:choose>
				<xsl:when test="preceding-sibling::wadl:resource[@path=$path]"/>
				<xsl:otherwise>
					<xsl:value-of select="$sectionName"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<xsl:variable name="displayMethod">
			<xsl:choose>
				<xsl:when test="preceding-sibling::wadl:resource[@path=$path]"/>
				<xsl:otherwise>
					Méthodes
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<xsl:variable name="hiddenClass">
			<xsl:if test="preceding-sibling::wadl:resource[@path=$path]">hidden</xsl:if>
		</xsl:variable>
		
		<a name="{$href}"/>
		<subsection name="{$displaySectionName}" class="resource" id="{$id}">
			<xsl:choose>
				<xsl:when test="not(wadl:method)">
					<xsl:apply-templates select="wadl:doc"/>
				</xsl:when>
				<xsl:otherwise>
					<div class="row-fluid resource">
						<xsl:choose>
							<xsl:when test="preceding-sibling::wadl:resource[@path=$path]">
							
								<h4 class="span8"></h4>
								<p class="clear"/>
								<!-- <div class="span8"> -->
									<xsl:apply-templates select="wadl:method"/>
									<xsl:apply-templates select="." mode="param-group">
										<xsl:with-param name="title"></xsl:with-param>
										<xsl:with-param name="style">template</xsl:with-param>
									</xsl:apply-templates>
									<xsl:apply-templates select="." mode="param-group">
										<xsl:with-param name="title"></xsl:with-param>
										<xsl:with-param name="style">matrix</xsl:with-param>
									</xsl:apply-templates>  
								<!-- </div> -->
							</xsl:when>
							<xsl:otherwise>
								<h4 class="span8"><xsl:value-of select="$displayMethod"/></h4>
								<p class="clear"/>
								<xsl:apply-templates select="wadl:method"/>
								<xsl:apply-templates select="." mode="param-group">
									<xsl:with-param name="title">Paramètres d'URL</xsl:with-param>
									<xsl:with-param name="style">template</xsl:with-param>
								</xsl:apply-templates>
								<xsl:apply-templates select="." mode="param-group">
									<xsl:with-param name="title">Matrice de paramètres</xsl:with-param>
									<xsl:with-param name="style">matrix</xsl:with-param>
								</xsl:apply-templates>  
							</xsl:otherwise>
						</xsl:choose>
					</div>
				</xsl:otherwise>
			</xsl:choose>
		</subsection>
		<xsl:if test="not(following-sibling::wadl:resource[@path=$path])">
			<div class="spacer"/>
		</xsl:if>
		<xsl:apply-templates select="wadl:resource" mode="list">
			<xsl:with-param name="context" select="$name"/>
		</xsl:apply-templates>      
    </xsl:template>
            
    <xsl:template match="wadl:method">
        <xsl:variable name="id"><xsl:call-template name="get-id"/></xsl:variable>
		<h5 id="{$id}" class="method"><xsl:value-of select="@name"/></h5>
            <xsl:apply-templates select="wadl:doc"/>                
            <xsl:apply-templates select="wadl:request"/>
            <xsl:apply-templates select="wadl:response"/>
    </xsl:template>

    <xsl:template match="wadl:request">
	    <xsl:if test="wadl:param">
			<h6>Requête</h6>
			<xsl:apply-templates select="wadl:doc"/>
		</xsl:if>
        <xsl:apply-templates select="." mode="param-inline">
            <xsl:with-param name="title">Paramètres de la requête</xsl:with-param>
            <xsl:with-param name="style">query</xsl:with-param>
        </xsl:apply-templates>
        <xsl:apply-templates select="." mode="param-group">
            <xsl:with-param name="title">Paramètres de l'entête</xsl:with-param>
            <xsl:with-param name="style">header</xsl:with-param>
        </xsl:apply-templates> 
        <xsl:if test="wadl:representation">
            <p class="method-representations"><em>Représentations de la requête:</em></p>
            <ul>
                <xsl:apply-templates select="wadl:representation"/>
            </ul>
        </xsl:if>
    </xsl:template>

    <xsl:template match="wadl:response">
	    <xsl:if test="wadl:doc|wadl:representation">
			<h6>Réponse</h6>
			<xsl:apply-templates select="wadl:doc"/>
		</xsl:if>
        <xsl:apply-templates select="." mode="param-group">
            <xsl:with-param name="title">Paramètres de la réponse</xsl:with-param>
            <xsl:with-param name="style">header</xsl:with-param>
        </xsl:apply-templates> 
        <xsl:if test="wadl:representation">
            <p class="method-representations"><em>Représentations de la réponse:</em></p>
            <ul>
                <xsl:apply-templates select="wadl:representation"/>
            </ul>
        </xsl:if>
        <xsl:if test="wadl:fault">
            <p class="method-representations"><em>potential faults:</em></p>
            <ul>
                <xsl:apply-templates select="wadl:fault"/>
            </ul>
        </xsl:if>
    </xsl:template>

    <xsl:template match="wadl:representation|wadl:fault">
        <xsl:variable name="id"><xsl:call-template name="get-id"/></xsl:variable>
		<xsl:variable name="element"><xsl:value-of select="@element"/></xsl:variable>
		<xsl:variable name="doctitle"><xsl:value-of select="wadl:doc/@title"/></xsl:variable>
		<xsl:choose>
            <xsl:when test="preceding-sibling::wadl:representation[@element=$element]"/>
            <xsl:when test="preceding-sibling::wadl:representation[not(@element)]/wadl:doc[@title=$doctitle]">
				<xsl:message>Merging siblings representations with doc : <xsl:value-of select="wadl:doc/@title"/></xsl:message>
			</xsl:when>
            <xsl:otherwise>       
				<li>
					<a href="#{$id}">
						<xsl:call-template name="representation-name"/>
					</a>
				</li>
			</xsl:otherwise>
		</xsl:choose>
    </xsl:template>    
    
    <xsl:template match="wadl:representation|wadl:fault" mode="list">
        <xsl:variable name="id"><xsl:call-template name="get-id"/></xsl:variable>
		<xsl:variable name="element"><xsl:value-of select="@element"/></xsl:variable>
		<xsl:variable name="doctitle"><xsl:value-of select="wadl:doc/@title"/></xsl:variable>
        <xsl:variable name="href" select="translate(@id,':','-')"/>
        <xsl:variable name="expanded-name">
            <xsl:call-template name="expand-qname">
                <xsl:with-param select="@element" name="qname"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="preceding::wadl:representation[@element=$element]"/>
            <xsl:when test="preceding-sibling::wadl:representation/wadl:doc[@title=$doctitle]">
				<xsl:message>Merging preceding representations (list) with doc : <xsl:value-of select="wadl:doc/@title"/></xsl:message>
			</xsl:when>
            <xsl:otherwise>
                <h3 id="{$id}">
                    <xsl:call-template name="representation-name"/>
                </h3>
                <xsl:apply-templates select="wadl:doc"/>
                <xsl:if test="@element or wadl:param">
                    <div class="representation row-fluid">
                        <xsl:if test="@element">
                            <h4 class="span8">XML Schema</h4>
							<p class="clear"/>
                            <xsl:call-template name="get-element">
                                <xsl:with-param name="context" select="."/>
                                <xsl:with-param name="qname" select="@element"/>
                            </xsl:call-template>
                        </xsl:if>        
                        <xsl:apply-templates select="." mode="param-group">
                            <xsl:with-param name="style">plain</xsl:with-param>
                        </xsl:apply-templates>
                        <xsl:apply-templates select="." mode="param-group">
                            <xsl:with-param name="title">Paramètres de l'entête</xsl:with-param>
                            <xsl:with-param name="style">header</xsl:with-param>
                        </xsl:apply-templates> 
										
						<h4 class="span4">Type mime</h4>
						<p class="clear"/>
						<ul>
							<li><xsl:value-of select="@mediaType"/></li>
							<xsl:for-each select="following-sibling::wadl:representation[@element=$element]">
								<li><xsl:value-of select="@mediaType"/></li>
							</xsl:for-each>
						</ul>	
                    </div>	
                </xsl:if>
				<xsl:if test="not(@element or wadl:param)">
					<h4>Type mime</h4>
					<!--ul>
						<li><xsl:value-of select="@mediaType"/></li>
						<xsl:for-each select="following-sibling::wadl:representation[wadl:doc/@title=$doctitle]">
							<li><xsl:value-of select="@mediaType"/></li>
						</xsl:for-each>
					</ul-->
					<pre>
						<xsl:value-of select="@mediaType"/>
						<xsl:for-each select="following-sibling::wadl:representation[wadl:doc/@title=$doctitle]">
<xsl:text>
</xsl:text>
							<xsl:value-of select="@mediaType"/>
						</xsl:for-each>
					</pre>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>        
    </xsl:template>
    
    <xsl:template match="wadl:*" mode="param-group">
        <xsl:param name="title"/>
        <xsl:param name="style"/>
        <xsl:if test="ancestor-or-self::wadl:*/wadl:param[@style=$style]">
        <h4 class="param span4"><xsl:value-of select="$title"/></h4>
        <table class="param-table">
            <tr>
                <th>Paramètre</th>
                <th>Valeur</th>
                <th>Description</th>
           </tr>
            <xsl:apply-templates select="ancestor-or-self::wadl:*/wadl:param[@style=$style]"/>
        </table>
        </xsl:if>       
    </xsl:template>
	
	<xsl:template match="wadl:*" mode="param-inline">
        <xsl:param name="title"/>
        <xsl:param name="style"/>
        <xsl:if test="ancestor-or-self::wadl:*/wadl:param[@style=$style]">
        <!--b><xsl:value-of select="$title"/></b-->
        <table class="param-table">
            <tr>
                <th>Paramètre</th>
                <th>Valeur</th>
                <th>Description</th>
           </tr>
            <xsl:apply-templates select="ancestor-or-self::wadl:*/wadl:param[@style=$style]"/>
        </table>
        </xsl:if>       
    </xsl:template>
    
    <xsl:template match="wadl:param">
        <tr>
            <td>
                <p><strong><xsl:value-of select="@name"/></strong></p>
            </td>
            <td>
                <p>
                <em><xsl:call-template name="link-qname"><xsl:with-param name="qname" select="@type"/></xsl:call-template></em>
                    <xsl:if test="@required='true'"> <small> (requis)</small></xsl:if>
                    <xsl:if test="@repeating='true'"> <small> (repetable)</small></xsl:if>            
                </p>
                <xsl:choose>
                    <xsl:when test="wadl:option">
                        <p><em>L'un des éléments suivants:</em></p>
                        <ul>
                            <xsl:apply-templates select="wadl:option"/>
                        </ul>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:if test="@default"><p>Defaut: <tt><xsl:value-of select="@default"/></tt></p></xsl:if>
                        <xsl:if test="@fixed"><p>Fixé: <tt><xsl:value-of select="@fixed"/></tt></p></xsl:if>
                    </xsl:otherwise>
                </xsl:choose>                        
            </td>
            <td>
                <xsl:apply-templates select="wadl:doc"/>
                <xsl:if test="wadl:option[wadl:doc]">
                    <dl>
                        <xsl:apply-templates select="wadl:option" mode="option-doc"/>
                    </dl>
                </xsl:if>
                <xsl:if test="@path">
                    <ul>
                        <li>XPath to value: <tt><xsl:value-of select="@path"/></tt></li>
                        <xsl:apply-templates select="wadl:link"/>
                    </ul>
                </xsl:if>
            </td>
        </tr>                
    </xsl:template>

    <xsl:template match="wadl:link">
        <li>
            lien: <a href="#{@resource_type}"><xsl:value-of select="@rel"/></a>            
        </li>
    </xsl:template>

    <xsl:template match="wadl:option">
        <li>
            <tt><xsl:value-of select="@value"/></tt>
            <xsl:if test="ancestor::wadl:param[1]/@default=@value"> <small> (defaut)</small></xsl:if>
        </li>
    </xsl:template>

    <xsl:template match="wadl:option" mode="option-doc">
            <dt>
                <tt><xsl:value-of select="@value"/></tt>
                <xsl:if test="ancestor::wadl:param[1]/@default=@value"> <small> (defaut)</small></xsl:if>
            </dt>
            <dd>
                <xsl:apply-templates select="wadl:doc"/>
            </dd>
    </xsl:template>    

    <xsl:template match="wadl:doc">
        <xsl:param name="inline">0</xsl:param>
        <!-- skip WADL elements -->
        <xsl:choose>
            <xsl:when test="node()[1]=text() and $inline=0">
                <p class="doc">
                    <i class="icon-circle-arrow-right"></i><xsl:apply-templates select="node()" mode="copy"/>
                </p>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="node()" mode="copy"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- utilities -->

    <xsl:template name="get-id">
        <xsl:choose>
            <xsl:when test="@id"><xsl:value-of select="@id"/></xsl:when>
            <xsl:when test="@element"><xsl:value-of select="@element"/></xsl:when>
            <xsl:otherwise><xsl:value-of select="generate-id()"/></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="get-namespace-uri">
        <xsl:param name="context" select="."/>
        <xsl:param name="qname"/>
        <xsl:variable name="prefix" select="substring-before($qname,':')"/>
        <xsl:variable name="qname-ns-uri" select="$context/namespace::*[name()=$prefix]"/>
        <!-- nasty hack to get around libxsl's refusal to copy all namespace nodes when pushing nodesets around -->
        <xsl:choose>
            <xsl:when test="$qname-ns-uri">
                <xsl:value-of select="$qname-ns-uri"/>                
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="exsl:node-set($resources)/*[1]/attribute::*[namespace-uri()='urn:namespace' and local-name()=$prefix]"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="get-element">
        <xsl:param name="context" select="."/>
        <xsl:param name="qname"/>
        <xsl:variable name="ns-uri">
            <xsl:call-template name="get-namespace-uri">
                <xsl:with-param name="context" select="$context"/>
                <xsl:with-param name="qname" select="$qname"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="localname" select="substring-after($qname, ':')"/>
        <xsl:variable name="definition" select="exsl:node-set($grammars)/descendant::xs:element[@name=$localname][ancestor-or-self::*[@targetNamespace=$ns-uri]]"/>
        <xsl:variable name="fullDefinition" select="exsl:node-set($grammars)/descendant::xs:complexType[@name=$localname][ancestor-or-self::*[@targetNamespace=$ns-uri]]"/>
		<xsl:variable name='source' select="$definition/ancestor-or-self::wadl:include[1]/@href"/>
        <pre><xsl:apply-templates select="$definition" mode="encode"/></pre>
        <pre><xsl:apply-templates select="$fullDefinition" mode="encode"/></pre>		
    </xsl:template>

    <xsl:template name="link-qname">
        <xsl:param name="context" select="."/>
        <xsl:param name="qname"/>
        <xsl:variable name="ns-uri">
            <xsl:call-template name="get-namespace-uri">
                <xsl:with-param name="context" select="$context"/>
                <xsl:with-param name="qname" select="$qname"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="localname" select="substring-after($qname, ':')"/>
        <xsl:choose>
            <xsl:when test="$ns-uri='http://www.w3.org/2001/XMLSchema'">
                <a href="http://www.w3.org/TR/xmlschema-2/#{$localname}"><xsl:value-of select="$localname"/></a>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="definition" select="exsl:node-set($grammars)/descendant::xs:*[@name=$localname][ancestor-or-self::*[@targetNamespace=$ns-uri]]"/>                
                <a href="{$definition/ancestor-or-self::wadl:include[1]/@href}" title="{$definition/descendant::xs:documentation/descendant::text()}"><xsl:value-of select="$localname"/></a>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="expand-qname">
        <xsl:param name="context" select="."/>
        <xsl:param name="qname"/>
        <xsl:variable name="ns-uri">
            <xsl:call-template name="get-namespace-uri">
                <xsl:with-param name="context" select="$context"/>
                <xsl:with-param name="qname" select="$qname"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:text>{</xsl:text>
        <xsl:value-of select="$ns-uri"/>
        <xsl:text>} </xsl:text> 
        <xsl:value-of select="substring-after($qname, ':')"/>
    </xsl:template>
        
    
    <xsl:template name="representation-name">
        <xsl:variable name="expanded-name">
            <xsl:call-template name="expand-qname">
                <xsl:with-param select="@element" name="qname"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="wadl:doc[@title]">
                <xsl:value-of select="wadl:doc[@title][1]/@title"/>
<!--                 <xsl:if test="@status or @mediaType or @element"> (</xsl:if>
                <xsl:if test="@status">Status Code </xsl:if><xsl:value-of select="@status"/>
                <xsl:if test="@status and @mediaType"> - </xsl:if>
                <xsl:value-of select="@mediaType"/>
                <xsl:if test="(@status or @mediaType) and @element"> - </xsl:if>
                <xsl:if test="@element">
                    <abbr title="{$expanded-name}"><xsl:value-of select="@element"/></abbr>
                </xsl:if>
                <xsl:if test="@status or @mediaType or @element">)</xsl:if> -->
            </xsl:when>
            <xsl:otherwise>
<!--                 <xsl:if test="@status">Status Code </xsl:if><xsl:value-of select="@status"/>
                <xsl:if test="@status and @mediaType"> - </xsl:if>
                <xsl:value-of select="@mediaType"/>
                <xsl:if test="@element"> (</xsl:if>
                <abbr title="{$expanded-name}"><xsl:value-of select="@element"/></abbr>
                <xsl:if test="@element">)</xsl:if> -->
				<xsl:value-of select="@element"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>                
        
    <!-- entity-encode markup for display -->

    <xsl:template match="*" mode="encode">
        <xsl:text>&lt;</xsl:text>
        <xsl:value-of select="name()"/><xsl:apply-templates select="attribute::*" mode="encode"/>
        <xsl:choose>
            <xsl:when test="*|text()">
                <xsl:text>&gt;</xsl:text>
                <xsl:apply-templates select="*|text()" mode="encode" xml:space="preserve"/>
                <xsl:text>&lt;/</xsl:text><xsl:value-of select="name()"/><xsl:text>&gt;</xsl:text>                
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>/&gt;</xsl:text>
            </xsl:otherwise>
        </xsl:choose>    
    </xsl:template>            
    
    <xsl:template match="@*" mode="encode">
        <xsl:text> </xsl:text><xsl:value-of select="name()"/><xsl:text>="</xsl:text><xsl:value-of select="."/><xsl:text>"</xsl:text>
    </xsl:template>    
    
    <xsl:template match="text()" mode="encode">
        <xsl:value-of select="." xml:space="preserve"/>
    </xsl:template>    

    <!-- copy HTML for display -->
    
    <xsl:template match="html:*" mode="copy">
        <!-- remove the prefix on HTML elements -->
        <xsl:element name="{local-name()}">
            <xsl:for-each select="@*">
                <xsl:attribute name="{local-name()}"><xsl:value-of select="."/></xsl:attribute>
            </xsl:for-each>
            <xsl:apply-templates select="node()" mode="copy"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="@*|node()[namespace-uri()!='http://www.w3.org/1999/xhtml']" mode="copy">
        <!-- everything else goes straight through -->
        <xsl:copy>
            <xsl:apply-templates select="@*|node()" mode="copy"/>
        </xsl:copy>
    </xsl:template>    

</xsl:stylesheet>

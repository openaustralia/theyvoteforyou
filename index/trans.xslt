<xsl:stylesheet version = '1.0' 
    xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
    xmlns:html="http://www.w3.org/1999/xhtml">

<xsl:template match="writtenanswers">

<html>
<head>
<title>Written answer</title>
</head>
<body>
        <xsl:apply-templates select="wrans">
            <xsl:sort order="descending" select="stamp/@coldate"/>
        </xsl:apply-templates>
</body>
</html>
</xsl:template>
 
<xsl:template match="wrans"> 
    <h1>
        <xsl:value-of select="stamp/@coldate"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="@title"/>
    </h1>
    <b>
        <xsl:apply-templates select="speech"/>
    </b>
    <a>
        <xsl:attribute name="href">
            <xsl:value-of select="page/@url"/>
        </xsl:attribute>
        Read the original source of this answer in Hansard
    </a>
</xsl:template>
  

<xsl:template match="speech"> 
    <p>
        <b>
            <a>
                <xsl:attribute name="href">
                    http://www.publicwhip.org.uk/<xsl:value-of select="@id"/>
                </xsl:attribute>
                <xsl:value-of select="@name"/>
            </a>:
        </b>
        <xsl:value-of select="."/>
    </p>
</xsl:template>

</xsl:stylesheet>


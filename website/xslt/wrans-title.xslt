<xsl:stylesheet version = '1.0' 
    xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
    xmlns:html="http://www.w3.org/1999/xhtml">

<!-- Title -->

<xsl:template match="publicwhip">
	<xsl:if test="count(wrans) = 1">
		<xsl:value-of select="wrans/@title"/>
		<xsl:text> - </xsl:text>
	</xsl:if> 
	<xsl:value-of select="wrans/stamp/@coldate"/>
	<xsl:if test="count(wrans) > 1">, Column
		<xsl:value-of select="wrans/stamp/@colnum"/>
	</xsl:if>
	- Written Answer<xsl:if test="count(wrans) > 1">s</xsl:if> 
</xsl:template>
 
</xsl:stylesheet>


<xsl:stylesheet version = '1.0' 
    xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
    xmlns:html="http://www.w3.org/1999/xhtml">

<!-- Full -->

<!--
Scratchpad of maybe useful stuff:
<xsl:import href="wrans-core.xslt"/> 
<xsl:value-of select="substring-after(@speakerid,'uk.org.publicwhip/member/')"/>
-->

<xsl:template match="publicwhip">
	<xsl:apply-templates select="wrans">
		<xsl:sort order="descending" select="stamp/@coldate"/>
	</xsl:apply-templates>
</xsl:template>
 
<xsl:template match="wrans"> 
	<xsl:if test="count(//publicwhip/wrans) > 1">
		<hr/>
		<h2>
			<xsl:value-of select="@title"/>
			- <xsl:value-of select="stamp/@coldate"/>
		</h2>
	</xsl:if>
	<xsl:apply-templates select="speech"/>
	<p>
		<a>
			<xsl:attribute name="href">wrans.php?id=<xsl:value-of select="@id"/></xsl:attribute>
			[ Permanent link to just this item ]
		</a>
		<a>
			<xsl:attribute name="href"><xsl:value-of select="page/@url"/></xsl:attribute>
			[ Original source of this answer in Hansard ]
		</a>
	</p>
	<xsl:if test="count(//publicwhip/wrans) > 1">
		<xsl:if test="position()=last()"><hr/> </xsl:if>
	</xsl:if>
</xsl:template>
  

<xsl:template match="speech"> 
    <p>
        <b>
            <a>
                <xsl:attribute name="href">mp.php?id=<xsl:value-of select="@speakerid"/></xsl:attribute>
                <xsl:value-of select="@speakername"/>
            </a>:
        </b>
		<xsl:apply-templates select="*" mode="innerhtml"/>
    </p>
</xsl:template>

<!-- Stuff to process the XHTML inside the XML fils, that is the actual body text -->
<xsl:template match="phrase[@class=&quot;offrep&quot;]" mode="innerhtml">
	<a><xsl:attribute name="href">wrans.php?id=uk.org.publicwhip/<xsl:value-of select="@id"/></xsl:attribute>
		<xsl:apply-templates select="@*|node()" mode="innerhtml"/>
	</a>
</xsl:template>

<xsl:template match="table|tr|td|th|caption|thead" mode="innerhtml">
	<xsl:copy><xsl:attribute name="class">innerhtml</xsl:attribute>
		<xsl:apply-templates select="@*|node()" mode="innerhtml"/>
	</xsl:copy>
</xsl:template>


<!-- This matches and copies all other tags in the inner HTML that we haven't matched above -->
<xsl:template match="@*|node()" mode="innerhtml">
	<xsl:copy>
		<xsl:apply-templates select="@*|node()" mode="innerhtml"/>
	</xsl:copy>
</xsl:template>

</xsl:stylesheet>


<xsl:stylesheet version = '1.0' 
    xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
    xmlns:html="http://www.w3.org/1999/xhtml">

<!-- Full -->

<!--
Scratchpad of maybe useful stuff:
<xsl:import href="wrans-core.xslt"/> 
<xsl:value-of select="substring-after(@id,'uk.org.publicwhip/member/')"/>
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
		</h2>
	</xsl:if>
	<xsl:apply-templates select="speech"/>
	<p>
		<a>
			<xsl:attribute name="href">
				wrans.php?id=<xsl:value-of select="@id"/>
			</xsl:attribute>
			[ Permanent link to just this item ]
		</a>
		<a>
			<xsl:attribute name="href">
				<xsl:value-of select="page/@url"/>
			</xsl:attribute>
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
                <xsl:attribute name="href">
                    mp.php?id=<xsl:value-of select="@id"/>
				</xsl:attribute>
                <xsl:value-of select="@displayname"/>
            </a>:
        </b>
        <xsl:copy-of select="*"/>
    </p>
</xsl:template>

</xsl:stylesheet>

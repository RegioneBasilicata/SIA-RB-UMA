<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xalan="org.apache.xalan.xslt.extensions.Redirect"
                extension-element-prefixes="xalan" version="1.0">

  <xsl:output method="text"/>

  <xsl:template match="descriptors">
    <xsl:for-each select="ejb-jar.xml">
      <xsl:call-template name="writeFile"/>
    </xsl:for-each>

    <xsl:for-each select="weblogic-ejb-jar.xml">
      <xsl:call-template name="writeFile"/>
    </xsl:for-each>

    <xsl:for-each select="weblogic-cmp-rdbms-jar.xml">
      <xsl:call-template name="writeFile"/>
    </xsl:for-each>

    <xsl:for-each select="application.xml">
      <xsl:call-template name="writeFile"/>
    </xsl:for-each>

  </xsl:template>

  <xsl:template name="writeFile">
    <xalan:write select="name()">
      <xsl:copy-of select="."/>
    </xalan:write>
  </xsl:template>

</xsl:stylesheet>

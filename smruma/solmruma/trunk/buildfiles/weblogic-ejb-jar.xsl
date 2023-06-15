<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xalan="org.apache.xalan.xslt.extensions.Redirect"
                extension-element-prefixes="xalan" version="1.0">

  <xsl:output method="text"/>

  <xsl:template match="/">
      <xsl:value-of select="/descriptors/weblogic-ejb-jar.xml"/>
  </xsl:template>

</xsl:stylesheet>

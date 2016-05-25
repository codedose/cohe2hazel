<?xml version="1.0" ?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
    <xsl:output method="xml" version="1.1" indent="yes" omit-xml-declaration="yes" />
    <xsl:strip-space elements="*" />

    <xsl:param name="networkFile" />
    <xsl:param name="cacheFile"/>

    <xsl:template match="/">
        <hazelcast xsi:schemaLocation="http://www.hazelcast.com/schema/config https://hazelcast.com/schema/config/hazelcast-config-3.6.xsd"
                   xmlns="http://www.hazelcast.com/schema/config"
                   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <xsl:apply-templates mode="copy" select="document($networkFile)/hazelcast/*"/>
            <xsl:apply-templates mode="copy" select="document($cacheFile)/hazelcast/*"/>
        </hazelcast>
    </xsl:template>

    <xsl:template match="*" mode="copy">
        <xsl:element name="{name()}" namespace="http://www.hazelcast.com/schema/config">
            <xsl:apply-templates select="@*|node()" mode="copy" />
        </xsl:element>
    </xsl:template>

    <xsl:template match="@*|text()|comment()" mode="copy">
        <xsl:copy/>
    </xsl:template>
</xsl:transform>
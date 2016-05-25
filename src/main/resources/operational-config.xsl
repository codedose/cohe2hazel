<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xpath-default-namespace="http://xmlns.oracle.com/coherence/coherence-operational-config">
    <xsl:output method="xml" version="1.1" indent="yes" omit-xml-declaration="yes" />
    <xsl:strip-space elements="*" />

    <xsl:template match="/">
        <hazelcast>
            <xsl:for-each select="//cluster-config">
                <xsl:call-template name="cluster-config"/>
            </xsl:for-each>
        </hazelcast>
    </xsl:template>

    <!-- coherence cluster config to hazelcast network -->
    <xsl:template name="cluster-config">
        <xsl:apply-templates select="member-identity"/>
        <network>
            <join>
                <xsl:apply-templates select="unicast-listener"/>
                <xsl:apply-templates select="multicast-listener"/>
            </join>
        </network>
    </xsl:template>

    <xsl:template match="text()"/>

    <xsl:template match="member-identity">
        <group>
            <name><xsl:value-of select="cluster-name"/></name>
            <password>dev-pass</password>
        </group>
    </xsl:template>

    <xsl:template match="unicast-listener">
        <tcp-ip enabled="false">
            <xsl:apply-templates select="well-known-addresses/address"/>
            <xsl:apply-templates select="well-known-addresses/socket-address"/>
        </tcp-ip>
    </xsl:template>

    <xsl:template match="address">
        <member><xsl:value-of select="."/></member>
    </xsl:template>

    <xsl:template match="socket-address">
        <xsl:if test="address != ''">
            <member><xsl:value-of select="address"/>
            <xsl:if test="port and port != ''">:<xsl:value-of select="port"/> </xsl:if>
            </member>
        </xsl:if>
    </xsl:template>

    <xsl:template match="multicast-listener">
        <multicast enabled="false">
            <multicast-group><xsl:value-of select="address"/></multicast-group>
            <multicast-port><xsl:value-of select="port"/></multicast-port>
            <xsl:if test="time-to-live">
                <multicast-time-to-live><xsl:value-of select="time-to-live"/></multicast-time-to-live>
            </xsl:if>
            <xsl:if test="join-timeout-milliseconds">
                <multicast-timeout-seconds><xsl:value-of select="number(join-timeout-milliseconds) div 1000"/></multicast-timeout-seconds>
            </xsl:if>
        </multicast>
    </xsl:template>
</xsl:stylesheet>

<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xpath-default-namespace="http://xmlns.oracle.com/coherence/coherence-cache-config"
                xmlns:utils="java:transformer.util.Utils"
                xmlns:func="http://com.codedose">
    <xsl:output method="xml" version="1.1" indent="yes" omit-xml-declaration="yes" exclude-result-prefixes="xsl utils func"/>
    <xsl:strip-space elements="*" />

    <xsl:template match="/">
        <hazelcast>
            <xsl:for-each select="//caching-scheme-mapping/cache-mapping">
                <xsl:call-template name="cache-mapping"/>
            </xsl:for-each>
        </hazelcast>
    </xsl:template>

    <xsl:template name="cache-mapping">
        <xsl:variable name="schemaNameNode" select="scheme-name"/>
        <xsl:variable name="schemaNode" select="//caching-schemes/*[scheme-name=$schemaNameNode]"/>

        <xsl:variable name="backingMapSchema" select="if (boolean($schemaNode//scheme-ref))
            then //caching-schemes/*[scheme-name=$schemaNode//scheme-ref]
            else $schemaNode/backing-map-scheme"/>

        <xsl:apply-templates select="$schemaNode">
            <xsl:with-param name="cacheMappingNode" select="."/>
            <xsl:with-param name="schemaNode" select="$schemaNode"/>
            <xsl:with-param name="backingMapSchemaNode" select="$backingMapSchema"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="text()"/>

    <xsl:template match="distributed-scheme">
        <xsl:param name="cacheMappingNode"/>
        <xsl:param name="schemaNode"/>
        <xsl:param name="backingMapSchemaNode"/>

        <xsl:call-template name="hazelcast-map">
            <xsl:with-param name="cacheMappingNode" select="$cacheMappingNode"/>
            <xsl:with-param name="schemaNode" select="$backingMapSchemaNode"/>
            <xsl:with-param name="backupCount" select="$schemaNode/backup-count"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="near-scheme" >
        <xsl:param name="cacheMappingNode"/>
        <xsl:param name="schemaNode"/>

        <xsl:variable name="frontSchema" select="
            if (boolean($schemaNode/front-scheme/scheme-ref))
            then //caching-schemes/*[scheme-name=$schemaNode/front-scheme/scheme-ref]
            else $schemaNode/front-scheme"/>

        <xsl:variable name="backSchema" select="
            if (boolean($schemaNode/back-scheme/scheme-ref))
            then //caching-schemes/*[scheme-name=$schemaNode/back-scheme/scheme-ref]
            else $schemaNode/back-scheme"/>

        <xsl:call-template name="hazelcast-map">
            <xsl:with-param name="cacheMappingNode" select="$cacheMappingNode"/>
            <xsl:with-param name="backupCount" select="$schemaNode/backup-count"/>
            <xsl:with-param name="schemaNode" select="$backSchema"/>
            <xsl:with-param name="subElement">
                <xsl:call-template name="hazelcast-nearcache-submap">
                    <xsl:with-param name="coherenceSchemaNode" select="$frontSchema"/>
                </xsl:call-template>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="replicated-scheme" >
        <xsl:param name="cacheMappingNode"/>
        <replicatedmap>
            <xsl:attribute name="name"><xsl:value-of select="$cacheMappingNode/cache-name"/></xsl:attribute>
            <in-memory-format>OBJECT</in-memory-format>
        </replicatedmap>
    </xsl:template>

    <xsl:template match="optimistic-scheme" >
        <xsl:param name="cacheMappingNode"/>
        <xsl:param name="schemaNode"/>
        <xsl:param name="backingMapSchemaNode"/>

        <xsl:call-template name="hazelcast-map">
            <xsl:with-param name="cacheMappingNode" select="$cacheMappingNode"/>
            <xsl:with-param name="schemaNode" select="$backingMapSchemaNode"/>
            <xsl:with-param name="backupCount" select="$schemaNode/backup-count"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="proxy-scheme" >
        <!--proxy-scheme-->
    </xsl:template>

    <xsl:template match="overflow-scheme" >
        <!-- overflow-scheme -->
    </xsl:template>

    <xsl:template match="transactional-scheme" >
        <xsl:param name="cacheMappingNode"/>
        <xsl:param name="schemaNode"/>
        <xsl:param name="backingMapSchemaNode"/>

        <xsl:call-template name="hazelcast-map">
            <xsl:with-param name="cacheMappingNode" select="$cacheMappingNode"/>
            <xsl:with-param name="schemaNode" select="$backingMapSchemaNode"/>
            <xsl:with-param name="backupCount" select="$schemaNode/backup-count"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="local-scheme">
        <!-- local-scheme -->
    </xsl:template>

    <xsl:template name="hazelcast-map">
        <xsl:param name="cacheMappingNode"/>
        <xsl:param name="schemaNode"/>
        <xsl:param name="backupCount"/>
        <xsl:param name="subElement" required="no" select="null"/>

        <map>
            <xsl:attribute name="name"><xsl:value-of select="$cacheMappingNode/cache-name"/></xsl:attribute>
            <xsl:call-template name="hazelcast-map-body">
                <xsl:with-param name="cacheMappingNode" select="$cacheMappingNode"/>
                <xsl:with-param name="schemaNode" select="$schemaNode"/>
                <xsl:with-param name="backupCount" select="func:getParameterValue($backupCount, $cacheMappingNode)"/>
            </xsl:call-template>

            <xsl:copy-of select="$subElement"/>
        </map>
    </xsl:template>

    <xsl:function name="func:getParameterValue">
        <xsl:param name="parametrizedValue"/>
        <xsl:param name="parameterDefinitionNode"/>
        <xsl:choose>
            <xsl:when test="utils:isParametrized($parametrizedValue)">
                <xsl:variable name="paramValue" select="$parameterDefinitionNode//init-param[param-name=utils:getParameterName($parametrizedValue)]/param-value"/>
                <xsl:value-of select="if (empty($paramValue)) then utils:getDefaultParametrizedValue($parametrizedValue) else $paramValue"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="utils:getDefaultParametrizedValue($parametrizedValue)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:template name="hazelcast-map-body" >
        <xsl:param name="cacheMappingNode" select="null"/>
        <xsl:param name="schemaNode"/>
        <xsl:param name="backupCount" select="null"/>
        <xsl:param name="isNearCache" select="false()"/>

        <in-memory-format>BINARY</in-memory-format>
        <!-- backup-count to backup-count -->
        <xsl:if test="$backupCount != null and $backupCount != ''">
            <!-- Mastering hazelcast 3.6 - the maximum number of backups is 6 -->
            <backup-count><xsl:value-of select="if(number($backupCount) &gt; 6) then 6 else $backupCount "/></backup-count>
        </xsl:if>
        <!-- high-units to max-size -->
        <xsl:if test="$schemaNode//high-units">
            <xsl:variable name="parameterValue" select="utils:getMBParameter(func:getParameterValue($schemaNode//high-units, $cacheMappingNode))"/>
            <xsl:variable name="unitFactor" select="if($schemaNode//unit-factor) then func:getParameterValue($schemaNode//unit-factor, $cacheMappingNode) else 1"/>

            <xsl:choose>
                <xsl:when test="$isNearCache">
                    <max-size>
                        <xsl:value-of select="$parameterValue div $unitFactor"/>
                    </max-size>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:if test="$schemaNode//unit-calculator[. = 'BINARY']">
                        <!-- Maximum used heap size in megabytes for each JVM -->
                        <!-- USED_HEAP_SIZE: Maximum used heap size in megabytes per map for each Hazelcast instance. Please note that this policy does not work when in-memory format is set to OBJECT, since the memory footprint cannot be determined when data is put as OBJECT -->
                        <max-size policy="USED_HEAP_SIZE">
                            <xsl:value-of select="$parameterValue div $unitFactor"/>
                        </max-size>
                    </xsl:if>
                    <xsl:if test="$schemaNode//unit-calculator[. = 'FIXED'] or not($schemaNode//unit-calculator)">
                        <!-- Maximum number of map entries in each JVM. This is the default policy. -->
                        <max-size policy="PER_NODE">
                            <xsl:value-of select="$parameterValue div $unitFactor"/>
                        </max-size>
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>


        </xsl:if>
        <!-- eviction-percentage to eviction-percentage -->
        <xsl:if test="$schemaNode//eviction-percentage">
            <eviction-percentage><xsl:value-of select="$schemaNode//eviction-percentage"/></eviction-percentage>
        </xsl:if>
        <!-- eviction-policy to eviction-policy -->
        <xsl:if test="$schemaNode//eviction-policy[. = 'LRU' or . = 'LFU']">
            <xsl:copy-of select="$schemaNode//eviction-policy"/>
        </xsl:if>
        <!-- expiry-delay to time-to-live-seconds -->
        <xsl:if test="$schemaNode//expiry-delay">
            <time-to-live-seconds><xsl:value-of select="utils:convertExpiryDelay(func:getParameterValue($schemaNode//expiry-delay, $cacheMappingNode))"/></time-to-live-seconds>
        </xsl:if>
    </xsl:template>

    <xsl:template name="hazelcast-nearcache-submap">
        <xsl:param name="coherenceSchemaNode"/>
        <near-cache>
            <xsl:call-template name="hazelcast-map-body">
                <xsl:with-param name="schemaNode" select="$coherenceSchemaNode"/>
                <xsl:with-param name="isNearCache" select="true()"/>
            </xsl:call-template>
        </near-cache>
    </xsl:template>

</xsl:stylesheet>

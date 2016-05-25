# cohe2hazel
Coherence to Hazelcast configuration migrating tool



--
## Migrating from Oracle Coherence to Hazelcast
### Migrating configuration
***
If your Coherence application is based on the XML configuration migration step can be partially automated using the cohe2hazel project.

The cohe2hazel project tries to transform the Coherence operational and the cache configuration files to the hazelcast.xml (hazelcast-config-3.6) configuration file. During the transformation a user’s operational file is transformed to the Hazelcast network section and a user’s cache file to the hazelcast map section. This transformation is especially helpful when your cache configuration contains a lot of cache definitions (also a parameterized one) . 

To execute the transformation you need to run ConfigTransformer class with proper input parameters, which are paths to both configuration files: your operational xml (for example tangosol-coherence.xml) and cache xml (coherence-cache.xml ).

ConfigTransformer main method performs 3 operations: 
- transforms operational xml and creates network.xml as an output 
- transforms cache xml and creates cache.xml as an output 
- merges previously created xml files into single one and creates output.xml as an output, 

Generated output.xml file is a base for main Hazelcast configuration. For more information please refer to Hazelcast documentation - configuration section

Currently, due to difference in the API of those two solutions it is not possible to automatically migrate the whole configuration so please be aware that the configuration will be migrated only in limited way. 

Rules/assumptions for Coherence configurations:
due to the fact that the transformation is based on XSLT, currently it assumes that main XML configuration elements have proper namespaces
for the operational file: <coherence ...
            xmlns="http://xmlns.oracle.com/coherence/coherence-operational-config" … >
for the cache file: <cache-config … xmlns="http://xmlns.oracle.com/coherence/coherence-cache-config" … >

multi file configuration is not supported, cache / operational configuration must be in a single file
within the cache configuration file only a single schema reference is allowed (recursive schemas are not supported)


### Operational / Networking:
***
Transformation of the Coherence operational file is currently very limited and supports only a basic identity, the unicast and multicast listeners section conversion.

- member-identity element is converted into Hazelcast <group> where name value is taken from cluster-name and the password is set to dev-pass as a default
- the unicast / multicast sections are converted into the Hazelcast <join> element
- for the Coherence unicast, basing on the well-known-addresses section and address / socket-address elements the Hazelcast <tcp-ip> members are extracted
- for the Coherence multicast-listener the Hazelcast multicast element is created with the following properties: multicast-group, -port, -time-to-live and timeout-seconds - if present
as a default both Hazelcast tcp-ip / multicast outputs are disabled (enabled="false")

### Caches:
***
All Coherence caches are transformed to Hazelcast <map> elements based on the following rules:
	
- all Hazelcast maps except replicated map will have in-memory-format set to binary. The replicated map has in-memory-format set to object
- Coherence distributed-scheme, optimistic-scheme and transactional-scheme are mapped to Hazelcast map 
- invocation-scheme, overflow-scheme, proxy-scheme currently are not transformed
- Coherence  near-scheme is converted to Hazelcast map with the near-cache section where the main map attributes are obtained from back-scheme and the near-cache from the front-scheme

migrating / resolving cache parameters:
- backup-count is converted to the same Hazelcast attribute backup-count
- high-units are converted to max-size where units number and the max-size policy is based on Coherence unit-calculator
- eviction-percentage is converted to the same Hazelcast attribute. Transformation is executed only for LRU, LFU types
- expiry-delay is converted to time-to-live-seconds, units are calculated to seconds

### Services:
***
Currently there is no way to automatically migrate Coherence services. A Coherence cache timeouts/threads count and other services parameters should be manually merged and moved to hazelcast client configuration. 

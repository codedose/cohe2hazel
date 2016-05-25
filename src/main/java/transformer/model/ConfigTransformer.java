package transformer.model;

import java.io.ByteArrayInputStream;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;

import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerConfigurationException;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;

import net.sf.saxon.TransformerFactoryImpl;

/**
 * Transforms Coherence xml file to Hazelcast xml one.
 * Coherence cache XML must have <cache-config xmlns="http://xmlns.oracle.com/coherence/coherence-cache-config"> as a root node.
 * Coherence operational XML must have <coherence xmlns="http://xmlns.oracle.com/coherence/coherence-operational-config>" as a root node.
 */
public class ConfigTransformer
{
   private final static TransformerFactory factory = TransformerFactoryImpl.newInstance();
   private final static String CACHE_TRANSFORMATION_FILE_NAME = "cache-config.xsl";
   private final static String OPERATIONAL_TRANSFORMATION_FILE_NAME = "operational-config.xsl";
   private final static String MERGE_TRANSFORMATION_FILE_NAME = "merge.xsl";
   private static final String OUTPUT_XML = "output.xml";
   private static final String CACHE_OUTPUT_XML = "cache.xml";
   private static final String OPERATIONAL_OUTPUT_XML = "network.xml";
   private final Transformer transformer;

   /**
    * @param args the command line arguments
    * args[0] - input coherence cache xml file path
    * args[1] - optional output xml file path
    */
   public static void main(String[] args) throws TransformerException, FileNotFoundException {
      if(args.length < 1) {
         throw new IllegalArgumentException("You need to pass coherence cache xml file path as a first argument and operational xml file path as a second one.");
      }

      final String coherenceOperationalFilePath = args[0];
      final String coherenceCacheFilePath = args[1];

      final FileInputStream coherenceOperationalXml = new FileInputStream(coherenceOperationalFilePath);
      final FileInputStream coherenceCacheXml = new FileInputStream(coherenceCacheFilePath);

      coherenceOperationalConfigTransformer().transform(coherenceCacheXml, new FileOutputStream(OPERATIONAL_OUTPUT_XML));
      coherenceCacheConfigTransformer().transform(coherenceOperationalXml, new FileOutputStream(CACHE_OUTPUT_XML));

      createHazelcastConfig();
   }

   private static void createHazelcastConfig() throws TransformerException, FileNotFoundException {
      mergeOutputFiles();
   }

   private static void mergeOutputFiles() throws TransformerException, FileNotFoundException {
      final Transformer mergeTransformer = factory.newTransformer(new StreamSource(loadResourceXSL(MERGE_TRANSFORMATION_FILE_NAME)));
      mergeTransformer.setParameter("cacheFile", CACHE_OUTPUT_XML);
      mergeTransformer.setParameter("networkFile", OPERATIONAL_OUTPUT_XML);
      mergeTransformer.transform(new StreamSource(new ByteArrayInputStream("<fake></fake>".getBytes())), new StreamResult(new FileOutputStream(OUTPUT_XML)));
   }

   public static ConfigTransformer coherenceCacheConfigTransformer() throws TransformerConfigurationException {
      return new ConfigTransformer(loadResourceXSL(CACHE_TRANSFORMATION_FILE_NAME));
   }

   public static ConfigTransformer coherenceOperationalConfigTransformer() throws TransformerConfigurationException {
      return new ConfigTransformer(loadResourceXSL(OPERATIONAL_TRANSFORMATION_FILE_NAME));
   }

   private ConfigTransformer(InputStream xsl) throws TransformerConfigurationException {
      transformer = factory.newTransformer(new StreamSource(xsl));
   }

   public void transform(InputStream coherenceXml, OutputStream outputStream) throws TransformerException {
      transformer.transform(new StreamSource(coherenceXml), new StreamResult(outputStream));
   }

   private static InputStream loadResourceXSL(String name) {
      return ConfigTransformer.class.getClassLoader().getResourceAsStream(name);
   }
}

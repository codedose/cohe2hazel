package transformer.util;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

import static java.util.Objects.isNull;


/**
 * Simple helper / utils used in xsl transformation.
 */
public class Utils {
   private final static Pattern PARAMETRIZED_VALUE = Pattern.compile("\\{(.*) (.+)\\}");
   private final static Pattern COHERENCE_EXPIRY_DELAY_PATTERN = Pattern.compile("([\\d]+[[.][\\d]+]?)([MS|ms|S|s|M|m|H|h|D|d]?)");

   public static boolean isParametrized(String value) {
      return PARAMETRIZED_VALUE.matcher(value).find();
   }

   /**
    * @param value - coherence node parametrized value ex "{backup-count 4}"
    * @return default value or original value if not parametrized
    * for "{backup-count 4}" returns "4"
    * for "1233" returns "1233"
    * for "{parameter 3" returns "{parameter 3
    */
   public static String getDefaultParametrizedValue(String value) {
      final Matcher m = PARAMETRIZED_VALUE.matcher(value);
      if(m.find()) {
        return m.group(2);
      }

      return value;
   }

   /**
    * @param value - coherence node parametrized value ex "{backup-count 4}"
    * @return parameter name
    * for "{parameter-name 3}" returns "parameter-name"
    * for "123321" returns null
    */
   public static String getParameterName(String value) {
      Matcher m = PARAMETRIZED_VALUE.matcher(value);
      if(m.find()) {
         return m.group(1);
      }

      return null;
   }

   /**
    * removes "MB" from input parameter and parses it to int
    */
   public static int getMBParameter(String value) {
      final String trimmedValue = value.trim();
      if(trimmedValue.endsWith("MB")) {
         return Integer.parseInt(trimmedValue.replace("MB", ""));
      }

      return Integer.parseInt(trimmedValue);
   }

   /*
   * Converts coherence expiry delay format to seconds
   * The value of this element must be in the following format:
   * [\d]+[[.][\d]+]?[MS|ms|S|s|M|m|H|h|D|d]?
   * where the first non-digits (from left to right) indicate the unit of time duration:
   * MS or ms (milliseconds)
   * S or s (seconds)
   * M or m (minutes)
   * H or h (hours)
   * D or d (days)
   */
   public static int convertExpiryDelay(String value) {
      final Matcher m = COHERENCE_EXPIRY_DELAY_PATTERN.matcher(value);
      if(m.find()) {
         final String numberPart = m.group(1);
         final String unitPart = m.group(2);

         if(isNull(unitPart)) {
            return Integer.parseInt(value);
         }

         final Double number = Double.parseDouble(numberPart);
         Double result = number;

         switch (unitPart.toLowerCase()) {
            case "ms": result = number * 1000; break;
            case "m": result = number * 60; break;
            case "h": result = number * 3600; break;
            case "d": result = number * 3600 * 24; break;
         }

         return result.intValue();
      }

      throw new IllegalArgumentException("Unknown format type. Check if passed string matches coherence delay pattern");
   }
}

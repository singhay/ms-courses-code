package WikiParser;

import org.xml.sax.*;
import org.xml.sax.helpers.DefaultHandler;

import javax.xml.parsers.ParserConfigurationException;
import javax.xml.parsers.SAXParser;
import javax.xml.parsers.SAXParserFactory;
import java.io.IOException;
import java.io.StringReader;
import java.net.URLDecoder;
import java.util.LinkedList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/** Parses Wikipages on each line. */
public class WikiParser {
	private static Pattern namePattern;
	private static Pattern linkPattern;
	static {
		// Keep only html pages not containing tilde (~).
		namePattern = Pattern.compile("^([^~]+)$");
		// Keep only html filenames ending relative paths and not containing tilde (~).
		linkPattern = Pattern.compile("^\\..*/([^~]+)\\.html$");
	}

	public static String parse(String line) throws IOException, InterruptedException {

        // Configure parser.
        SAXParserFactory spf = SAXParserFactory.newInstance();
        try {
            spf.setFeature("http://apache.org/xml/features/nonvalidating/load-external-dtd", false);
        } catch (ParserConfigurationException | SAXNotRecognizedException | SAXNotSupportedException ignored) {
        }
        SAXParser saxParser;
        List<String> linkPageNames = new LinkedList<>();
        // Each line formatted as (Wiki-page-name:Wiki-page-html).
        Integer delimLoc = line.indexOf(':');
        String pageName = line.substring(0, delimLoc);
        String html = line.substring(delimLoc + 1).replace("&", "&amp;");
        Matcher matcher = namePattern.matcher(pageName);
        Boolean skip = false;
        StringBuilder output = new StringBuilder();
        try {
            saxParser = spf.newSAXParser();
            XMLReader xmlReader = saxParser.getXMLReader();
            // Parser fills linkPageNames with linked page names.
            xmlReader.setContentHandler(new MainWikiParser(linkPageNames));

            if (!matcher.find()) {
                // Skip this html file, name contains (~).
                skip = true;
            }

            // Parse page and fill list of linked pages.
            linkPageNames.clear();
            try {
                xmlReader.parse(new InputSource(new StringReader(html)));
            } catch (Exception e) {
                // Discard ill-formatted pages.
                skip = true;
            }

        } catch (ParserConfigurationException | SAXException ignored) {
        }

        /**
         * Skip flag takes care of whether or not to discard the parsed value
         * Below conditional block does two main jobs as follows:
         * 1. Emit all nodes with "maybeDangling" from the list of Page Names for a page
         * 2. Emit the page itself initializing it with "initPageRank"
         */
        if (!skip) {
            output.append(pageName);
            for (String str : linkPageNames) {
                output.append("\t").append(str);
            }
        }
        return output.toString();
    }

	/** Parses a Wikipage, finding links inside bodyContent div element. */
	private static class MainWikiParser extends DefaultHandler {
		/** List of linked pages; filled by parser. */
		private List<String> linkPageNames;
		/** Nesting depth inside bodyContent div element. */
		private int count = 0;

		public MainWikiParser(List<String> linkPageNames) {
			super();
			this.linkPageNames = linkPageNames;
		}

		@Override
		public void startElement(String uri, String localName, String qName, Attributes attributes) throws SAXException {
			super.startElement(uri, localName, qName, attributes);
			if ("div".equalsIgnoreCase(qName) && "bodyContent".equalsIgnoreCase(attributes.getValue("id")) && count == 0) {
				// Beginning of bodyContent div element.
				count = 1;
			} else if (count > 0 && "a".equalsIgnoreCase(qName)) {
				// Anchor tag inside bodyContent div element.
				count++;
				String link = attributes.getValue("href");
				if (link == null) {
					return;
				}
				try {
					// Decode escaped characters in URL.
					link = URLDecoder.decode(link, "UTF-8");
				} catch (Exception e) {
					// Wiki-weirdness; use link as is.
				}
				// Keep only html filenames ending relative paths and not containing tilde (~).
				Matcher matcher = linkPattern.matcher(link);
				if (matcher.find()) {
					linkPageNames.add(matcher.group(1));
				}
			} else if (count > 0) {
				// Other element inside bodyContent div.
				count++;
			}
		}

		@Override
		public void endElement(String uri, String localName, String qName) throws SAXException {
			super.endElement(uri, localName, qName);
			if (count > 0) {
				// End of element inside bodyContent div.
				count--;
			}
		}
	}
}

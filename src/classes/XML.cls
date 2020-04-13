/*
MIT License

Copyright (c) 2020 zabroseric

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

/**
 * An Apex library that works to solve all xml serialization and deserialization issues.
 */
public class XML {

    private static String DEFAULT_ROOT_TAG = 'elements';
    private static String DEFAULT_ELEMENT_TAG = 'element';

    /**
     * Initialises the writer class and exposes the methods provided
     * for serialization of an object.
     *
     * @param obj
     *
     * @return
     */
    public static Writer serialize(Object obj)
    {
        return (new Writer()).write(obj);
    }

    /**
     * Initialises the reader class and exposes the methods provided
     * for deserialization of a string.
     *
     * @param xmlString
     *
     * @return
     */
    public static Reader deserialize(String xmlString)
    {
        return (new Reader()).read(xmlString);
    }

    /**
     * Initialises the reader class and exposes the methods provided
     * for deserialization of a string.
     *
     * The output will be casted to the apex type / class provided.
     *
     * @param xmlString
     * @param apexType
     *
     * @return
     */
    public static Reader deserialize(String xmlString, Type apexType)
    {
        return (new Reader()).read(xmlString).setType(apexType);
    }

    /**
     * The entry for the XML Writer class that serializes sobject, objects, lists, maps
     * and other types to a string.
     *
     * The class uses function chaining to write to the parameters and does
     * not expose these directly.
     */
    public class Writer {

        private Boolean suppressNulls = false;
        private String rootTag = DEFAULT_ROOT_TAG;
        private String elementTag = DEFAULT_ELEMENT_TAG;
        private Boolean showEncoding = false;
        private Map<String, String> attributes = new Map<String, String>();
        private Map<String, String> namespaces = new Map<String, String>();
        private Boolean detectRootTag = true;
        private Boolean pretty = false;

        private Object obj;

        /**
         * Pass the object for serialization.
         *
         * @param obj
         *
         * @return
         */
        public Writer write(Object obj)
        {
            this.obj = obj;
            return this;
        }

        /**
         * Converts the object to a string.
         *
         * @return
         */
        public override String toString()
        {
            detectSObjectTags();

            Dom.Document document = new DOMObj()
                .setObject(obj)
                .parse(rootTag, elementTag, namespaces, suppressNulls);

            // Set the attributes on the root node.
            for ( String key : attributes.keySet() ) {
                document.getRootElement().setAttribute(key, attributes.get(key));
            }

            String xmlString = document.toXmlString();

            // If we chose to hide the encoding, remove it.
            if ( !showEncoding ) {
                xmlString = xmlString.replace('<?xml version="1.0" encoding="UTF-8"?>', '');
            }

            // Flatten the elements if possible, so Elements / Element => Element
            if ( document.getRootElement().getChildElements().size() == 1 && rootTag == DEFAULT_ROOT_TAG ) {
                xmlString = xmlString.left(xmlString.length() - 3 - rootTag.length())
                    .replace('<' + elementTag + '>', '').replace('<' + rootTag, '<' + elementTag);
            }
            return pretty ? formatStringPretty(xmlString) : xmlString;
        }

        /**
         * Converts the object to a base 64 encoded string.
         *
         * @return
         */
        public String toBase64()
        {
            return EncodingUtil.base64Encode(Blob.valueOf(toString()));
        }

        /**
         * Debugs the resulting xml string.
         *
         * @return
         */
        public Writer debug()
        {
            System.debug('\r\n' + toString());
            return this;
        }

        /**
         * Ensure any nulls values are omitted in the resulting xml string.
         *
         * @return
         */
        public Writer suppressNulls()
        {
            this.suppressNulls = true;
            return this;
        }

        /**
         * Ensure any nulls values are kept in the resulting xml string.
         *
         * @return
         */
        public Writer showNulls()
        {
            this.suppressNulls = false;
            return this;
        }

        /**
         * Sets the output to be in a nicely formatted string.
         *
         * @return
         */
        public Writer pretty()
        {
            this.pretty = true;
            return this;
        }

        /**
         * Sets the output to be in a minified string.
         *
         * @return
         */
        public Writer minify()
        {
            this.pretty = false;
            return this;
        }

        /**
         * Shows xml encoding at the beginning of the xml.
         *
         * @return
         */
        public Writer showEncoding()
        {
            this.showEncoding = true;
            return this;
        }

        /**
         * Hides xml encoding at the beginning of the xml.
         *
         * @return
         */
        public Writer hideEncoding()
        {
            this.showEncoding = false;
            return this;
        }

        /**
         * Sets an attribute on the root node.
         *
         * @param key
         * @param value
         *
         * @return
         */
        public Writer setAttribute(String key, String value)
        {
            this.attributes.put(key, value);
            return this;
        }

        /**
         * Sets attributes on the root node.
         *
         * @param key
         * @param value
         *
         * @return
         */
        public Writer setAttributes(Map<String, String> attributes)
        {
            this.attributes = attributes;
            return this;
        }

        /**
         * Sets a namespace to be used.
         *
         * @param uri
         * @param prefix
         *
         * @return
         */
        public Writer setNamespace(String uri, String prefix)
        {
            this.namespaces.put(uri, prefix);
            this.attributes.put('xmlns:' + prefix, uri);
            return this;
        }

        /**
         * Sets namespace to be used.
         *
         * @param namespaces
         *
         * @return
         */
        public Writer setNamespaces(Map<String, String> namespaces)
        {
            for ( String uri : namespaces.keySet() ) {
                setNamespace(uri, namespaces.get(uri));
            }
            return this;
        }

        /**
         * Sets the root tag for the XML.
         * Note: Setting this will disable the automatic detection of the objects.
         *
         * @param rootTag
         *
         * @return
         */
        public Writer setRootTag(String rootTag)
        {
            this.rootTag = rootTag;
            this.detectRootTag = false;
            return this;
        }

        /**
         * Formats an xml string in pretty format.
         *
         * @param xmlString
         *
         * @return
         */
        private String formatStringPretty(String xmlString)
        {
            List<String> xmlStringSplit = xmlString.split('><');
            String xmlStringPretty = '';
            Integer indents = 0;

            // Iterate over the individual pieces of the split tags
            // detecting how many indents are required on every line.
            for ( String split : xmlStringSplit ) {
                if ( split.left(1) == '/' ) {
                    indents--;
                }

                for ( Integer i = 0; i < indents; i++ ) { xmlStringPretty += '   '; }
                xmlStringPretty += '<' + split + '>\r\n';

                if ( !split.contains('>') && !split.contains('<?xml') && split.left(1) != '/' ) {
                    indents++;
                }
            }

            xmlStringPretty = xmlStringPretty.trim();
            xmlStringPretty = xmlStringPretty.left(xmlStringPretty.length() - 1).right(xmlStringPretty.length() - 2);
            return xmlStringPretty;
        }

        /**
         * Detects and sets both the root and element tags based on any SObjects that can be found from
         * the object provided.
         */
        private void detectSObjectTags()
        {
            if ( obj instanceof List<SObject> ) {
                rootTag = ((List<SObject>) obj).getSObjectType().getDescribe().labelPlural;
                elementTag = ((List<SObject>) obj).getSObjectType().getDescribe().label;
            }
            else if ( obj instanceof Map<Id, SObject> ) {
                rootTag = ((Map<Id, SObject>) obj).getSObjectType().getDescribe().labelPlural;
                elementTag = ((Map<Id, SObject>) obj).getSObjectType().getDescribe().labelPlural;
            }
            else if ( obj instanceof SObject ) {
                rootTag = ((SObject) obj).getSObjectType().getDescribe().label;
            }
        }
    }

    /**
     * The entry for the XML Reader class that deserializes to objects, lists, maps
     * and other types from a string.
     *
     * The class uses function chaining to write to the parameters and does
     * not expose these directly.
     */
    public class Reader {

        private String xmlString;
        private Type apexType = null;
        private Set<String> arrayNodes = new Set<String>();

        /**
         * Pass the xml string for deserialization.
         *
         * @param xmlString
         *
         * @return
         */
        public Reader read(String xmlString)
        {
            this.xmlString = xmlString;
            return this;
        }

        /**
         * Converts the xml string to an Object.
         *
         * @return
         */
        public Object toObject()
        {
            Map<String, Object> objectMap;

            try {
                objectMap = (new DOMString())
                    .setString(xmlString)
                    .setArrayNodes(arrayNodes)
                    .parse()
                ;
            }
            catch (Exception e) {
                throw new XmlException('The XML string is invalid, value: ' + xmlString);
            }

            // If we haven't passed a type, return the map we have.
            if ( apexType == null ) {
                return objectMap;
            }

            // If the apex type is a partial key within the map, use this as the base for
            // our deserialization so we are able to correctly map to the type.
            else if ( objectMap.containsKey(apexType.getName().substringAfter('.')) ) {
                return JSON.deserialize(JSON.serialize(objectMap.get(apexType.getName().substringAfter('.'))), apexType);
            }

            // If the apex type we have is a list, get the first instance of a list
            // from the map.
            else if ( apexType.toString().startsWith('List') ) {
                return JSON.deserialize('[' + JSON.serialize(objectMap).substringAfter('[').substringBeforeLast(']') + ']', apexType);
            }

            // Otherwise just use the base deserialization.
            else {
                return JSON.deserialize(JSON.serialize(objectMap), apexType);
            }
        }

        /**
         * Converts the xml string to an Object and return this as a string.
         *
         * @return
         */
        public override String toString()
        {
            return String.valueOf(toObject());
        }

        /**
         * Converts the xml string to an Object and debug it.
         *
         * @return
         */
        public Reader debug()
        {
            System.debug(toString());
            return this;
        }

        /**
         * Set the type of object the xml string will be converted to.
         * If not provided, the object will be untyped.
         *
         * @param apexType
         *
         * @return
         */
        public Reader setType(Type apexType)
        {
            this.apexType = apexType;
            return this;
        }

        /**
         * Set xml nodes that should be treated as an array, even
         * if they have not been explicitly detected as an array.
         *
         * @param arrayNodes
         *
         * @return
         */
        public Reader setArrayNodes(Set<String> arrayNodes)
        {
            this.arrayNodes = arrayNodes;
            return this;
        }

        /**
         * Set an xml node that should be treated as an array, even
         * if they have not been explicitly detected as an array.
         *
         * @param node
         *
         * @return
         */
        public Reader setArrayNode(String node)
        {
            this.arrayNodes.add(node);
            return this;
        }
    }

    /**
     * Represents a DOM element that is accessed to serialize the xml content.
     * This DOM element calls itself recursively when accessing nested parameters.
     */
    public class DOMObj {

        private Boolean suppressNulls;
        private Object obj;
        private Map<String, String> namespaces = new Map<String, String>();

        /**
         * Parse the object for serialization.
         *
         * @param obj
         *
         * @return
         */
        public DOMObj setObject(Object obj)
        {
            this.obj = obj;
            return this;
        }

        /**
         * The entry point for the writer class.
         *
         * @param rootTag
         * @param elementTag
         * @param suppressNulls
         *
         * @return
         */
        public Dom.Document parse(String rootTag, String elementTag, Map<String, String> namespaces, Boolean suppressNulls)
        {
            this.obj = JSON.deserializeUntyped(JSON.serialize(this.obj, suppressNulls));
            this.namespaces = namespaces;
            this.suppressNulls = suppressNulls;

            Dom.Document document = new Dom.Document();
            Dom.XmlNode xmlNode = document.createRootElement(rootTag, null, null);

            // Detect the type of root object we have and parse it.
            if ( instanceOfList() && !isEmpty() ) {
                parseList(toList(), elementTag, xmlNode);
            }
            else if ( instanceOfMap() && !isEmpty() ) {
                parseMap(toMap(), xmlNode);
            }

            // Otherwise if we have primitive type, parse this.
            else if ( !(isEmpty() && suppressNulls) ) {
                xmlNode.addTextNode(toStringVal());
            }
            return document;
        }

        /**
         * Parse a map for iteration, if we have chosen to empty nodes
         * and the resulting node from children are empty, remove them.
         *
         * @param values
         * @param xmlNode
         *
         * @return
         */
        private Boolean parseMap(Map<String, Object> values, DOM.XmlNode xmlNode)
        {
            Boolean isEmptyChild = parseMulti(new List<String>(values.keySet()), values.values(), xmlNode);
            if ( isEmptyChild && xmlNode.getParent() != null ) { xmlNode.getParent().removeChild(xmlNode); }
            return isEmptyChild;
        }

        /**
         * Parse a list for iteration, if we have chosen to empty nodes
         * and the resulting node from children are empty, remove them.
         *
         * @param values
         * @param key
         * @param xmlNode
         *
         * @return
         */
        private Boolean parseList(List<Object> values, String key, DOM.XmlNode xmlNode)
        {
            Boolean isEmptyChild = parseMulti(new List<String>{key}, values, xmlNode);
            if ( isEmptyChild && xmlNode.getParent() != null ) { xmlNode.getParent().removeChild(xmlNode); }
            return isEmptyChild;
        }

        /**
         * Parse any type for iteration, this will iterate over the other parsing
         * methods for each of the nested elements.
         *
         * @param keys
         * @param values
         * @param xmlNode
         *
         * @return
         */
        private Boolean parseMulti(List<String> keys, List<Object> values, DOM.XmlNode xmlNode)
        {
            Integer notEmptyNumber = 0;

            for ( Integer i = 0; i < values.size(); i++ ) {
                // If we have a list, keep using the same key.
                String key = setNamespace(keys.get(keys.size() - 1 > i ? i : keys.size() - 1));

                // If the tag name starts with a numeric value, put an underscore at the beginning
                // This is useful when passing object maps so that the xml remains valid.
                key = key.left(1).isNumeric() ? '_' + key : key;

                DOMObj domElement = new DOMObj().setNullsSuppressed(suppressNulls)
                    .setNamespaces(namespaces).setObject(values.get(i));

                // If we have an empty list and have chosen not to suppress
                // nulls, ensure this is added to the xml.
                if ( domElement.instanceOfList() && domElement.isEmpty() && !suppressNulls ) {
                    xmlNode.addChildElement(key, null, null);
                }

                // Convert the lists / maps, iterate over these and determine if the
                // result was empty.
                else if ( domElement.instanceOfList() ) {
                    notEmptyNumber += parseList(domElement.toList(), key, xmlNode) ? 0 : 1;
                }
                else if ( domElement.instanceOfMap() ) {
                    notEmptyNumber += parseMap(
                        domElement.toMap(),
                        xmlNode.addChildElement(key, null, null)
                    ) ? 0 : 1;
                }

                // If we have a value don't iterate and just add the node.
                else if ( !domElement.isEmpty() ) {
                    xmlNode
                        .addChildElement(key, null, null)
                        .addTextNode(domElement.toStringVal());
                    notEmptyNumber += 1;
                }

                // If we have chosen not to suppress nulls, ensure an empty tag is there.
                else if ( !suppressNulls ) {
                    xmlNode.addChildElement(key, null, null);
                    notEmptyNumber += 1;
                }
            }

            // Return if the result was empty or not.
            return notEmptyNumber == 0 && suppressNulls;
        }

        /**
         * Replaces the tag name with the required prefix.
         *
         * @param tagName
         *
         * @return
         */
        private String setNamespace(String tagName)
        {
            if ( !tagName.contains('{') ) {
                return tagName;
            }

            for ( String uri : namespaces.keySet() ) {
                if ( tagName.contains('{' + uri + '}') ) {
                    return tagName.replace('{' + uri + '}', namespaces.get(uri) + ':');
                }
            }

            // If we can't find the tag, just remove the clark notation.
            return tagName.substringAfter('}');
        }

        /**
         * Determines if the current object should suppress nulls.
         *
         * @param suppressNulls
         *
         * @return
         */
        private DOMObj setNullsSuppressed(Boolean suppressNulls)
        {
            this.suppressNulls = suppressNulls;
            return this;
        }

        /**
         * Sets the namespaces that will be added to the xml.
         *
         * @param namespaces
         *
         * @return
         */
        private DOMObj setNamespaces(Map<String, String> namespaces)
        {
            this.namespaces = namespaces;
            return this;
        }

        /**
         * Returns if the current object is a list.
         *
         * @return
         */
        private Boolean instanceOfList()
        {
            return obj instanceof List<Object>;
        }

        /**
         * Returns if the current object is a map.
         *
         * @return
         */
        private Boolean instanceOfMap()
        {
            return obj instanceof Map<String, Object>;
        }

        /**
         * Converts the current object to a list.
         *
         * @return
         */
        private Map<String, Object> toMap()
        {
            return (Map<String, Object>) obj;
        }

        /**
         * Converts the current object to a map.
         *
         * @return
         */
        private List<Object> toList()
        {
            return (List<Object>) obj;
        }

        /**
         * Returns if the object we have is empty regardless of its type.
         *
         * @return
         */
        private Boolean isEmpty()
        {
            if ( obj instanceof Map<String, Object> ) { return ((Map<String, Object>) obj).isEmpty(); }
            if ( obj instanceof List<Object> ) { return ((List<Object>) obj).isEmpty(); }
            return obj == null || obj == '';
        }

        /**
         * Converts the object to a string value.
         *
         * @return
         */
        private String toStringVal()
        {
            if ( isEmpty() ) { return ''; }
            return String.valueOf(obj);
        }
    }

    /**
     * Represents a string that is used to deserialize the xml content.
     * This DOM string calls itself recursively when accessing nested values.
     */
    public class DOMString
    {
        private String xmlString;
        private Set<String> arrayNodes = new Set<String>();

        /**
         * Sets what nodes should be treated as arrays even if not detected as one.
         *
         * @param arrayNodes
         *
         * @return
         */
        public DOMString setArrayNodes(Set<String> arrayNodes)
        {
            this.arrayNodes = arrayNodes;
            return this;
        }

        /**
         * Set the xml string for deserialization.
         *
         * @param xmlString
         *
         * @return
         */
        public DOMString setString(String xmlString)
        {
            this.xmlString = xmlString;
            return this;
        }

        /**
         * Entry points for the reader class.
         *
         * @return
         */
        public Map<String, Object> parse()
        {
            XmlStreamReader reader = new XmlStreamReader(xmlString);
            return (Map<String, Object>) parseNested(reader, null);
        }

        /**
         * Uses to iterate over the current reader pointer and recursively call
         * itself as we go down the DOM tree.
         *
         * @param reader
         * @param elementName
         *
         * @return
         */
        private Object parseNested(XmlStreamReader reader, String elementName)
        {
            Map<String, Object> objectMap = new Map<String, Object>();
            Object objectCurrent;
            String tagName;

            Boolean hasNext = reader.hasNext();
            if ( hasNext ) { reader.next(); }

            while( hasNext ) {
                tagName = reader.getLocalName();

                if ( reader.getEventType() == XmlTag.START_ELEMENT ) {
                    objectCurrent = parseNested(reader, tagName);

                    // If we haven't come across this node, and we should make it array, create one.
                    if ( !objectMap.containsKey(tagName) && arrayNodes.contains(tagName) ) {
                        objectMap.put(tagName, new List<Object>{objectCurrent});
                    }
                    // If we haven't come across this node, by default create a map.
                    else if ( !objectMap.containsKey(tagName) ) {
                        objectMap.put(tagName, objectCurrent);
                    }
                    // if we have this node, and it's a list add to it.
                    else if ( objectMap.get(tagName) instanceof List<Object> ) {
                        ((List<Object>) objectMap.get(tagName)).add(objectCurrent);
                    }
                    // Otherwise turn our map into a list.
                    else {
                        objectMap.put(tagName, new List<Object>{
                            objectMap.get(tagName),
                            objectCurrent
                        });
                    }
                }

                // We we are ending our starting tag break this loop.
                else if ( reader.getEventType() == XmlTag.END_ELEMENT && elementName == reader.getLocalName() ) {
                    break;
                }

                // If we have text return that.
                else if ( reader.getEventType() == XmlTag.CHARACTERS ) {
                    return reader.getText();
                }

                hasNext = reader.hasNext();
                if ( hasNext ) { reader.next(); }
            }
            return objectMap.isEmpty() ? null : objectMap;
        }
    }
}
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

    private static final String DEFAULT_ROOT_NODE_NAME = 'elements';
    private static final String DEFAULT_NODE_NAME = 'element';
    private static final List<String> RESERVED_WORDS = new List<String>{
        'abstract', 'activate', 'and', 'any', 'array', 'as', 'asc', 'autonomous', 'begin', 'bigdecimal', 'blob', 'boolean', 'break', 'bulk', 'by', 'byte', 'case', 'cast', 'catch', 'char', 'class', 'collect', 'commit', 'const', 'continue', 'currency', 'date', 'datetime', 'decimal', 'default', 'delete', 'desc', 'do', 'double', 'else', 'end', 'enum', 'exception', 'exit', 'export', 'extends', 'false', 'final', 'finally', 'float', 'for', 'from', 'global', 'goto', 'group', 'having', 'hint', 'if', 'implements', 'import', 'in', 'inner', 'insert', 'instanceof', 'int', 'integer', 'interface', 'into', 'join', 'like', 'limit', 'list', 'long', 'loop', 'map', 'merge', 'new', 'not', 'null', 'nulls', 'number', 'object', 'of', 'on', 'or', 'outer', 'override', 'package', 'parallel', 'pragma', 'private', 'protected', 'public', 'retrieve', 'return', 'rollback', 'select', 'set', 'short', 'sObject', 'sort', 'static', 'string', 'super', 'switch', 'synchronized', 'system', 'testmethod', 'then', 'this', 'throw', 'time', 'transaction', 'trigger', 'true', 'try', 'undelete', 'update', 'upsert', 'using', 'virtual', 'void', 'webservice', 'when', 'where', 'while'
    };

    /**
     * Initialises the writer class and exposes the methods provided
     * for serialization of an object.
     *
     * @param obj Any object that is needing to be serialized
     *
     * @return An internal Writer class that provides access to additional functionality via method chaining
     */
    public static Writer serialize(Object obj)
    {
        return (new Writer()).write(obj);
    }

    /**
     * Initialises the reader class and exposes the methods provided
     * for deserialization of a string.
     *
     * @param xmlString An xml string that is needing to be deserialized
     *
     * @return An internal Reader class that provides access to additional functionality via method chaining
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
     * @param xmlString An xml string that is needing to be deserialized
     * @param apexType The type of object that the deserialization will be cast as
     *
     * @return An internal Reader class that provides access to additional functionality via method chaining
     */
    public static Reader deserialize(String xmlString, Type apexType)
    {
        return (new Reader()).read(xmlString).setType(apexType);
    }

    /**
    * ===============================================================================
     * The entry for the XML Writer class that serializes sobject, objects, lists, maps
     * and other types to a string.
     *
     * The class uses function chaining to write to the variables and does
     * not expose these directly.
     * ===============================================================================
     */
    public class Writer {

        private Boolean suppressNulls = false;
        private String rootNodeName = DEFAULT_ROOT_NODE_NAME;
        private String elementNodeName = DEFAULT_NODE_NAME;
        private Boolean showEncoding = false;
        private Map<String, String> rootAttributes = new Map<String, String>();
        private final Map<String, String> namespaces = new Map<String, String>();
        private Boolean detectRootNodeName = true;
        private Boolean beautify = false;
        private Boolean embedAttributes = false;

        private ObjectWrapper obj;

        /**
         * Pass the object for serialization.
         *
         * @param obj Any object that is needing to be serialized
         *
         * @return An internal Writer class that provides access to additional functionality via method chaining
         */
        public Writer write(Object obj)
        {
            this.obj = (new ObjectWrapper(obj));
            return this;
        }

        /**
         * Converts the object to a string.
         *
         * @return An internal Writer class that provides access to additional functionality via method chaining
         */
        public override String toString()
        {
            Dom.Document document = parse();
            String xmlString = document.toXmlString();

            // If we chose to hide the encoding, remove it.
            if (!showEncoding) {
                xmlString = xmlString.replace('<?xml version="1.0" encoding="UTF-8"?>', '');
            }

            // Flatten the elements if possible, so Elements / Element => Element
            if (document.getRootElement().getChildElements().size() == 1 && rootNodeName == DEFAULT_ROOT_NODE_NAME) {
                xmlString = xmlString
                    .replaceAll('<(/?)(' + rootNodeName + '|' + elementNodeName + ')([^>]*)>' +
                        '\\s*(<(/?)(' + rootNodeName + '|' + elementNodeName + ')([^>]*)>)?',
                        '<$1' + elementNodeName + '$3>');
            }

            // If there are rootAttributes in the closing nodes, remove them.
            xmlString = xmlString.replaceAll('</([^> ]+) [^>]+="[^>]+">', '</$1>');

            return beautify ? formatString(xmlString) : xmlString;
        }

        /**
         * Converts the object to a base 64 encoded string.
         *
         * @return An internal Writer class that provides access to additional functionality via method chaining
         */
        public String toBase64()
        {
            return EncodingUtil.base64Encode(Blob.valueOf(toString()));
        }

        /**
         * Debugs the resulting xml string.
         *
         * @return An internal Writer class that provides access to additional functionality via method chaining
         */
        public Writer debug()
        {
            System.debug('\r\n' + toString());
            return this;
        }

        /**
         * Ensure any nulls values are omitted in the resulting xml string.
         *
         * @return An internal Writer class that provides access to additional functionality via method chaining
         */
        public Writer suppressNulls()
        {
            this.suppressNulls = true;
            return this;
        }

        /**
         * Ensure any nulls values are kept in the resulting xml string.
         *
         * @return An internal Writer class that provides access to additional functionality via method chaining
         */
        public Writer showNulls()
        {
            this.suppressNulls = false;
            return this;
        }

        /**
         * Sets the output to be in a nicely formatted string.
         *
         * @return An internal Writer class that provides access to additional functionality via method chaining
         */
        public Writer beautify()
        {
            this.beautify = true;
            return this;
        }

        /**
         * Sets the output to be in a minified string.
         *
         * @return An internal Writer class that provides access to additional functionality via method chaining
         */
        public Writer minify()
        {
            this.beautify = false;
            return this;
        }

        /**
         * Shows xml encoding at the beginning of the xml.
         *
         * @return An internal Writer class that provides access to additional functionality via method chaining
         */
        public Writer showEncoding()
        {
            this.showEncoding = true;
            return this;
        }

        /**
         * Hides xml encoding at the beginning of the xml.
         *
         * @return An internal Writer class that provides access to additional functionality via method chaining
         */
        public Writer hideEncoding()
        {
            this.showEncoding = false;
            return this;
        }

        /**
         * Sets an attribute on the root node.
         *
         * @param key The attribute key
         * @param value The attribute value that is placed in quotes
         *
         * @return An internal Writer class that provides access to additional functionality via method chaining
         */
        public Writer addRootAttribute(String key, String value)
        {
            this.rootAttributes.put(key, value);
            return this;
        }

        /**
         * Sets attributes on the root node.
         *
         * @param rootAttributes A map of attributes with key, value pairs
         *
         * @return An internal Writer class that provides access to additional functionality via method chaining
         */
        public Writer setRootAttributes(Map<String, String> rootAttributes)
        {
            this.rootAttributes = rootAttributes;
            return this;
        }

        /**
         * Sets a namespace to be used.
         *
         * @param uri The namespace uri that will be set in the root node
         * @param prefix The prefix set on all nodes that mention the uri
         *
         * @return An internal Writer class that provides access to additional functionality via method chaining
         */
        public Writer addNamespace(String uri, String prefix)
        {
            this.namespaces.put(uri, prefix);
            this.rootAttributes.put('xmlns:' + prefix, uri);
            return this;
        }

        /**
         * Sets namespace to be used.
         *
         * @param namespaces A map of namespaces with uri, prefix pairs
         *
         * @return An internal Writer class that provides access to additional functionality via method chaining
         */
        public Writer setNamespaces(Map<String, String> namespaces)
        {
            for (String uri : namespaces.keySet()) {
                addNamespace(uri, namespaces.get(uri));
            }
            return this;
        }

        /**
         * Sets the root node name for the XML.
         * Note: Setting this will disable the automatic detection of the objects.
         *
         * @param rootNode The name of the root node that will be set
         *
         * @return An internal Writer class that provides access to additional functionality via method chaining
         */
        public Writer setRootNodeName(String rootNode)
        {
            this.rootNodeName = rootNode;
            this.detectRootNodeName = false;
            return this;
        }

        /**
         * Sets any attributes to be serialized into the node itself.
         *
         * @return An internal Writer class that provides access to additional functionality via method chaining
         */
        public Writer embedAttributes()
        {
            this.embedAttributes = true;
            return this;
        }

        /**
         * Sets any attributes nodes to be serialized into a separate child node.
         *
         * @return An internal Writer class that provides access to additional functionality via method chaining
         */
        public Writer splitAttributes()
        {
            this.embedAttributes = false;
            return this;
        }

        /**
         * Formats the xml string.
         *
         * @param xmlString An xml encoded string
         *
         * @return A formatted version of the xml encoded string
         */
        private String formatString(String xmlString)
        {
            List<String> xmlStringSplit = xmlString.split('><');
            String xmlStringFormatted = '';
            Integer indents = 0;

            // Iterate over the individual pieces of the split nodes
            // detecting how many indents are required on every line.
            for (String split : xmlStringSplit) {
                if (split.left(1) == '/') {
                    indents--;
                }

                for (Integer i = 0; i < indents; i++) {
                    xmlStringFormatted += '  ';
                }
                xmlStringFormatted += '<' + split + '>\r\n';

                if (!split.contains('>') && !split.contains('<?xml') && split.left(1) != '/' && split.right(1) != '/') {
                    indents++;
                }
            }

            xmlStringFormatted = xmlStringFormatted.trim();
            xmlStringFormatted = xmlStringFormatted.left(xmlStringFormatted.length() - 1).right(xmlStringFormatted.length() - 2);
            return xmlStringFormatted;
        }

        /**
         * The entry point for the write toString method.
         *
         * @return An XML Document representing the settings and object that was provided
         */
        private Dom.Document parse()
        {
            // Detects and sets both the root and element nodes based on any SObjects that can be found from
            // the object provided.
            if (!detectRootNodeName) {
                // Do nothing.
            } else if (obj.instanceOfSObjectMap() || obj.instanceOfSObjectList()) {
                rootNodeName = obj.getSObjectDescribe().labelPlural;
                elementNodeName = obj.getSObjectDescribe().label;
            } else if (obj.instanceOfSObject()) {
                rootNodeName = obj.getSObjectDescribe().label;
            }

            ObjectWrapper obj = obj.toUntyped();
            Dom.Document document = new Dom.Document();
            Dom.XmlNode xmlNode = document.createRootElement(rootNodeName, null, null);

            // If we have chosen to embed attributes, add them to the current node.
            if (embedAttributes && obj.hasAttributes()) {
                for (String attrKey : obj.getAttributes().keySet()) {
                    xmlNode.setAttribute(
                        attrKey,
                        obj.getAttributes().get(attrKey) != null ? String.valueOf(obj.getAttributes().get(attrKey)) : 'null'
                    );
                }
            }

            // Detect the type of root object we have and parse it.
            if (obj.instanceOfList() && !obj.isEmpty()) {
                parseList(obj.toList(), elementNodeName, xmlNode);
            } else if (obj.instanceOfMap() && !obj.isEmpty()) {
                parseMap(obj.toMap(), xmlNode);
            }

            // Otherwise if we have primitive type, parse this.
            else if (!(obj.isEmpty() && suppressNulls)) {
                xmlNode.addTextNode(parsePrimitive(obj));
            }

            // Set the attributes on the root node.
            for (String key : this.rootAttributes.keySet()) {
                String value = this.rootAttributes.get(key);

                if (embedAttributes || key.startsWith('xmlns:')) {
                    document.getRootElement().setAttribute(key, value);
                } else if (document.getRootElement().getChildElement('attributes', null) != null) {
                    document.getRootElement().getChildElement('attributes', null)
                        .addChildElement(key, null, null).addTextNode(value);
                } else {
                    document.getRootElement().addChildElement('attributes', null, null)
                        .addChildElement(key, null, null).addTextNode(value);
                }
            }

            return document;
        }

        /**
         * Provides a way to intercept the parsing of any primitive types and overwrite it.
         *
         * @param value An object wrapper containing the primitive type
         *
         * @return An evaluated string value from the object wrapper
         */
        private String parsePrimitive(ObjectWrapper value)
        {
            switch on value.getTypeName() {
                when 'Datetime' {
                    return value.toDatetime().formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS') + 'Z';
                }
                when else {
                    return value.toString();
                }
            }
        }

        /**
         * Parse a map for iteration, if we have chosen to empty nodes
         * and the resulting node from children are empty, remove them.
         *
         * @param values Key value pairs from the object that was parsed
         * @param xmlNode The existing XML document that has so far been created
         *
         * @return A boolean if the map is empty
         */
        private Boolean parseMap(Map<String, Object> values, Dom.XmlNode xmlNode)
        {
            Boolean isEmptyChild = parseMulti(new List<String>(values.keySet()), values.values(), xmlNode);
            if (isEmptyChild && xmlNode.getParent() != null) {
                xmlNode.getParent().removeChild(xmlNode);
            }
            return isEmptyChild;
        }

        /**
         * Parse a list for iteration, if we have chosen to empty nodes
         * and the resulting node from children are empty, remove them.
         *
         * @param values Values from the object that was parsed
         * @param key A key from which the object was set
         * @param xmlNode The existing XML document that has so far been created
         *
         * @return A boolean if the list is empty
         */
        private Boolean parseList(List<Object> values, String key, Dom.XmlNode xmlNode)
        {
            Boolean isEmptyChild = parseMulti(new List<String>{
                key
            }, values, xmlNode);
            if (isEmptyChild && xmlNode.getParent() != null) {
                xmlNode.getParent().removeChild(xmlNode);
            }
            return isEmptyChild;
        }

        /**
         * Parse any type for iteration, this will iterate over the other parsing
         * methods for each of the nested elements.
         *
         * @param keys Keys from the object that was parsed
         * @param values Values from the object that was parsed
         * @param xmlNode The existing XML document that has so far been created
         *
         * @return A boolean if the list is empty
         */
        private Boolean parseMulti(List<String> keys, List<Object> values, Dom.XmlNode xmlNode)
        {
            Integer notEmptyNumber = 0;

            for (Integer i = 0; i < values.size(); i++) {
                // If we have a list, keep using the same key.
                String key = setNamespace(keys.get(keys.size() - 1 > i ? i : keys.size() - 1));

                // If the node name starts with a numeric value, put an underscore at the beginning
                // This is useful when passing object maps so that the xml remains valid.
                key = key.left(1).isNumeric() ? '_' + key : key;

                ObjectWrapper obj = new ObjectWrapper(values.get(i));
                Dom.XmlNode childNode;

                // If we have chosen to embed attributes, add them to the node.
                if (embedAttributes && key == 'attributes') {
                    continue;
                }

                // VALIDATION:
                // Ensure we only have one either text or a child node when using the self keyword.
                if ((key == 'self' && !xmlNode.getChildren().isEmpty()) || ((obj.instanceOfMap() || obj.instanceOfList()) && !String.isEmpty(xmlNode.getText()))) {
                    System.debug(xmlNode.getText());
                    throw new XmlException('The object contains both the self keyword, and other child elements, please remove on of these.');
                }

                // If we have an empty list and have chosen not to suppress
                // nulls, ensure this is added to the xml.
                if (obj.instanceOfList() && obj.isEmpty() && !suppressNulls) {
                    childNode = xmlNode.addChildElement(key, null, null);
                }

                // Convert the lists / maps, iterate over these and determine if the
                // result was empty.
                else if (obj.instanceOfList()) {
                    notEmptyNumber += parseList(obj.toList(), key, xmlNode) ? 0 : 1;
                } else if (obj.instanceOfMap()) {
                    childNode = xmlNode.addChildElement(key, null, null);
                    notEmptyNumber += parseMap(obj.toMap(), childNode) ? 0 : 1;
                } else if (!obj.isEmpty() && key == 'self' && xmlNode.getChildren().isEmpty()) {
                    childNode = xmlNode.addTextNode(parsePrimitive(obj));
                    notEmptyNumber += 1;
                }
                // If we have a value don't iterate and just add the node.
                else if (!obj.isEmpty()) {
                    childNode = xmlNode
                        .addChildElement(key, null, null)
                        .addTextNode(parsePrimitive(obj));
                    notEmptyNumber += 1;
                }

                // If we have chosen not to suppress nulls, ensure an empty node is there.
                else if (!suppressNulls) {
                    childNode = xmlNode.addChildElement(key, null, null);
                    notEmptyNumber += 1;
                }

                // If we have chosen to embed attributes, add them to the node we have just added.
                if (embedAttributes && obj.hasAttributes()) {
                    for (String attrKey : obj.getAttributes().keySet()) {
                        childNode.setAttribute(attrKey, String.valueOf(obj.getAttributes().get(attrKey)));
                    }
                }
            }

            // Return if the result was empty or not.
            return notEmptyNumber == 0 && suppressNulls;
        }

        /**
         * Replaces the node name with the required prefix.
         *
         * @param nodeName The original name of the node
         *
         * @return A string of the new node name after considering the namespaces
         */
        private String setNamespace(String nodeName)
        {
            if (!nodeName.contains('{')) {
                return nodeName;
            }

            for (String uri : namespaces.keySet()) {
                if (nodeName.contains('{' + uri + '}')) {
                    return nodeName.replace('{' + uri + '}', namespaces.get(uri) + ':');
                }
            }

            // If we can't find the node, just remove the clark notation.
            return nodeName.substringAfter('}');
        }
    }

    /**
     * ===============================================================================
     * The entry for the XML Reader class that deserializes to objects, lists, maps
     * and other types from a string.
     *
     * The class uses function chaining to write to the variables and does
     * not expose these directly.
     * ===============================================================================
     */
    public class Reader {

        private String xmlString { get {return new Utils().replaceXMLReservedWords(xmlString, reservedWordSuffix);} set; }
        private Type apexType;
        private String apexTypeName;
        private Set<String> arrayNodes = new Set<String>();
        private Boolean showNamespaces = true;
        private List<String> rootNode = new List<String>();
        private String filterNamespace;
        private String reservedWordSuffix = '_x';

        /**
         * Pass the xml string for deserialization.
         *
         * @param xmlString An XML encoded string
         *
         * @return An internal Reader class that provides access to additional functionality via method chaining
         */
        public Reader read(String xmlString)
        {
            // Remove white space in blank nodes to correctly set them as nulls.
            this.xmlString = xmlString != null ? xmlString.replaceAll('>\\s+<', '><') : null;
            return this;
        }

        /**
         * Converts the xml string to an Object.
         *
         * @return An internal Reader class that provides access to additional functionality via method chaining
         */
        public Object toObject()
        {
            try {
                return toObjectInternal();
            } catch (JSONException e) {
                if (e.getMessage().contains('Expected List')) {
                    throw new XmlException('An array node has not been correctly set by value ' +
                        e.getMessage().replaceAll('.+(".+").+', '$1')
                    );
                }
                throw new XmlException(e.getMessage());
            }
        }

        /**
         * Converts the xml string to an Object.
         *
         * @return An internal Reader class that provides access to additional functionality via method chaining
         */
        private Object toObjectInternal()
        {
            Map<String, Object> objectMap;

            try {
                objectMap = parse();
            } catch (XmlPropagateException e) {
                throw e;
            } catch (Exception e) {
                throw new XmlException('The XML string is invalid, value: ' + xmlString);
            }

            // If we haven't passed a type, return the map we have.
            if (apexType == null) {
                return objectMap;
            }

            // If the type is deserializable and we have found the type as a key in the map,
            // return the value of this key.
            else if (((Type) Deserializable.class).isAssignableFrom(apexType) && new Utils().containsCaseInsensitive(objectMap, apexTypeName)) {
                return ((Deserializable) apexType.newInstance()).xmlDeserialize((Object) new Utils().getObjCaseInsensitive(objectMap, apexTypeName));
            }

            // Otherwise if the type is deserializable, pass the entire map.
            else if (((Type) Deserializable.class).isAssignableFrom(apexType)) {
                return ((Deserializable) apexType.newInstance()).xmlDeserialize(objectMap);
            }

            // If the apex type is a partial key with the map use that, this is useful for nested classes.
            else if (new Utils().containsCaseInsensitive(objectMap, apexTypeName)) {
                return JSON.deserialize(JSON.serialize(new Utils().getObjCaseInsensitive(objectMap, apexTypeName)), apexType);
            }

            // If the apex type we have is a list, get the list from the map.
            else if (apexType.toString().startsWith('List')) {
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
         * @return An internal Reader class that provides access to additional functionality via method chaining
         */
        public override String toString()
        {
            return String.valueOf(toObject());
        }

        /**
         * Converts the xml string to an Object and debug it.
         *
         * @return An internal Reader class that provides access to additional functionality via method chaining
         */
        public Reader debug()
        {
            System.debug(toString());
            return this;
        }

        /**
         * When one of the nodes contains a reserved word, this node will be renamed and a suffix
         * added so that it can be correctly managed.
         *
         * @param reservedWordSuffix A suffix string
         *
         * @return An internal Reader class that provides access to additional functionality via method chaining
         */
        public Reader setReservedWordSuffix(String reservedWordSuffix)
        {
            this.reservedWordSuffix = reservedWordSuffix;
            return this;
        }

        /**
         * Sets the root node that the deserialization should pass from.
         *
         * @param rootNode The name of the root node that will be set
         *
         * @return An internal Reader class that provides access to additional functionality via method chaining
         */
        public Reader setRootNode(String rootNode)
        {
            List<String> rootNodeArray = (rootNode != null ? rootNode : '').split('/');
            for (Integer i = rootNodeArray.size() - 1; i >= 0; i--) {
                if (String.isBlank(rootNodeArray.get(i))) {
                    rootNodeArray.remove(i);
                }
            }

            this.rootNode = rootNodeArray;
            return this;
        }

        /**
         * Set the type of object the xml string will be converted to.
         * If not provided, the object will be untyped.
         *
         * @param apexType Any object that we want converted to
         *
         * @return An internal Reader class that provides access to additional functionality via method chaining
         */
        public Reader setType(Type apexType)
        {
            this.apexType = apexType;

            if (apexType != null) {//fixes cases with namespace namespace.class.innerclass
                apexTypeName = apexType.getName();
                if (apexTypeName.contains('.')) apexTypeName = apexTypeName.substringAfterLast('.');
            }

            return this;
        }

        /**
         * Set xml nodes that should be treated as an array, even
         * if they have not been explicitly detected as an array.
         *
         * @param arrayNodes A set of node names
         *
         * @return An internal Reader class that provides access to additional functionality via method chaining
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
         * @param node A string containing one node name
         *
         * @return An internal Reader class that provides access to additional functionality via method chaining
         */
        public Reader addArrayNode(String node)
        {
            this.arrayNodes.add(node);
            return this;
        }

        /**
         * Filter the namespaces so that either namespaces that are empty
         * or that do not have a namespace are returned.
         *
         * @param filterNamespace A string value of the namespace
         *
         * @return An internal Reader class that provides access to additional functionality via method chaining
         */
        public Reader filterNamespace(String filterNamespace)
        {
            this.filterNamespace = filterNamespace;
            return this;
        }

        /**
         * Shows namespaces as clark notations.
         *
         * @return An internal Reader class that provides access to additional functionality via method chaining
         */
        public Reader showNamespaces()
        {
            this.showNamespaces = true;
            return this;
        }

        /**
         * Hide namespaces and show only the node name.
         *
         * @return An internal Reader class that provides access to additional functionality via method chaining
         */
        public Reader hideNamespaces()
        {
            this.showNamespaces = false;
            return this;
        }

        /**
         * Entry points for the reader toObject method.
         *
         * @return The resulting map from parsing an XML object
         */
        private Map<String, Object> parse()
        {
            XmlStreamReader xmlStreamReader = new XmlStreamReader(xmlString);
            xmlStreamReader.setCoalescing(true);
            return (Map<String, Object>) getNestedNodeValue(parseNested(xmlStreamReader, null), this.rootNode, 0);
        }

        /**
         * Recursively calls itself to drill into a nested value within an object.
         *
         * @param node The current node that is needing to be accessed.
         * @param path A list of paths comma delimited.
         * @param index The current index of the path
         *
         * @return The resulting object that has been parsed
         */
        private Map<String, Object> getNestedNodeValue(Object node, List<String> path, Integer index)
        {
            ObjectWrapper objectWrapper = new ObjectWrapper(node);
            Boolean isOutOfBounds = index >= path.size();
            String pathCurrent = '';

            if (!isOutOfBounds) {
                pathCurrent = path.get(index);
            } else if (index > 0) {
                pathCurrent = path.get(index - 1);
            } else {
                pathCurrent = DEFAULT_NODE_NAME;
            }


            // If the path is blank we are at our last entry.
            if (isOutOfBounds) {
                if (objectWrapper.instanceOfMap()) {
                    return (Map<String, Object>) node;
                }
                return new Map<String, Object>{
                    pathCurrent => node
                };
            }

            // Otherwise drill into the object further.
            if (objectWrapper.instanceOfMap()) {
                return getNestedNodeValue(((Map<String, Object>) node).get(pathCurrent), path, index + 1);
            }

            throw new XmlPropagateException('Cannot drill into the node "' + pathCurrent + '" set by the root node path /' + String.join(this.rootNode, '/'));
        }

        /**
         * Uses to iterate over the current reader pointer and recursively call
         * itself as we go down the DOM tree.
         *
         * @param reader The existing xml reader class and current position
         * @param elementName The current element that is being read
         *
         * @return The resulting object that has been parsed
         */
        private Object parseNested(XmlStreamReader reader, String elementName)
        {
            Map<String, Object> objectMap = new Map<String, Object>();
            Object objectCurrent;
            String nodeName;

            Boolean hasNext = reader.hasNext();
            if (hasNext) {
                reader.next();
            }

            while (hasNext) {
                // Add the clark notation to the node name if we have a namespace.
                nodeName = (showNamespaces && reader.getNamespace() != null ? '{' + reader.getNamespace() + '}' : '') + reader.getLocalName();

                // If we have a start element add this.
                if (reader.getEventType() == XmlTag.START_ELEMENT) {
                    // Add the attributes as a separate node to support deserialization.
                    Map<String, Object> attributeMap = new Map<String, Object>();
                    if (reader.getAttributeCount() > 0) {
                        for (Integer i = 0; i < reader.getAttributeCount(); i++) {
                            attributeMap.put(reader.getAttributeLocalName(i), reader.getAttributeValueAt(i));
                        }
                    }

                    objectCurrent = parseNested(reader, nodeName);

                    // If we have a map as our current node, add the attributes node / merge the values.
                    if (objectCurrent instanceof Map<String, Object> && !attributeMap.isEmpty()) {
                        Map<String, Object> objectCurrentMap = ((Map<String, Object>) objectCurrent);
                        if (objectCurrentMap.containsKey('attributes')) {
                            ((Map<String, Object>) objectCurrentMap.get('attributes')).putAll(attributeMap);
                        } else {
                            objectCurrentMap.put('attributes', attributeMap);
                        }
                    }

                    // If we haven't come across this node, and we should make it array, create one.
                    if (!objectMap.containsKey(nodeName) && arrayNodes.contains(nodeName)) {
                        objectMap.put(nodeName, new List<Object>{
                            objectCurrent
                        });
                    }
                    // If we haven't come across this node, by default create a map.
                    else if (!objectMap.containsKey(nodeName)) {
                        objectMap.put(nodeName, objectCurrent);
                    }
                    // If we have this node, and it's a list add to it.
                    else if (objectMap.get(nodeName) instanceof List<Object>) {
                        ((List<Object>) objectMap.get(nodeName)).add(objectCurrent);
                    }
                    // Otherwise turn our map into a list.
                    else {
                        objectMap.put(nodeName, new List<Object>{
                            objectMap.get(nodeName),
                            objectCurrent
                        });
                    }

                    // If we have chosen to filter the namespace remove the node we generated.
                    // This way we still loop through the reader.
                    if (filterNamespace != null && nodeName.contains('{') && !nodeName.contains(filterNamespace)) {
                        objectMap.remove(nodeName);
                    }

                }

                // We we are ending our starting node break this loop.
                else if (reader.getEventType() == XmlTag.END_ELEMENT && elementName == reader.getLocalName()) {
                    break;
                }

                // If we have text return and the namespace is valid, return it.
                else if (reader.getEventType() == XmlTag.CHARACTERS) {
                    return parseString(reader.getText());
                }

                hasNext = reader.hasNext();
                if (hasNext) {
                    reader.next();
                }
            }
            return objectMap.isEmpty() ? null : objectMap;
        }

        /**
         * Provides a way to intercept the parsing of strings and overwrite it.
         *
         * @param value A string containing any value.
         *
         * @return An evaluated string value from the object wrapper
         */
        private Object parseString(String value)
        {
            switch on new XML.ObjectWrapper(value).getTypeName() {
                when 'Boolean' {
                    return value == 'true';
                }
                when else {
                    return value;
                }
            }
        }
    }

    /**
     * ===============================================================================
     * An internal exception class that allows propagation of errors from inner
     * methods.
     * ===============================================================================
     */
    class XmlPropagateException extends Exception {

    }

    /**
     * ===============================================================================
     * The Deserializable interface is used when passing the apex type.
     * This allows the parsing of an map, list or string into the method.
     * ===============================================================================
     */
    public interface Deserializable {
        Object xmlDeserialize(Object objMap);
    }

    /**
    * ===============================================================================
     * The Utils class is a set of useful functions that can be used without
     * injecting another library.
     * ===============================================================================
     */
    private class Utils {

        /**
         * Determines if the key is contained within the map via a case-insensitive comparison.
         *
         * @param objs A map of objects being searched
         * @param key The search value
         *
         * @return A boolean if the value has been found
         */
        public Boolean containsCaseInsensitive(Map<String, Object> objs, String key)
        {
            return this.getObjCaseInsensitive(objs, key) != null;
        }

        /**
         * Returns the object of a map via a key that is insensitive.
         *
         * @param objs A map of objects being searched
         * @param key The search value
         *
         * @return The object that has been found, otherwise null will be returned
         */
        public Object getObjCaseInsensitive(Map<String, Object> objs, String key)
        {
            return objs.get(this.getKeyCaseInsensitive(objs, key));
        }

        /**
         * Returns the key of a map via a key that is insensitive.
         *
         * @param objs A map of objects being searched
         * @param key The search value
         *
         * @return The key of the object that has been found, otherwise null will be returned
         */
        public String getKeyCaseInsensitive(Map<String, Object> objs, String key)
        {
            return this.getKeySetCaseMap(objs).get(key.toLowerCase());
        }

        /**
         * Returns a key set map in the following format.
         * key lower case => key
         *
         * @param objs A map of objects being searched
         *
         * @return The map that has been parsed with keys lowercase
         */
        public Map<String, String> getKeySetCaseMap(Map<String, Object> objs)
        {
            Map<String, String> keySetCaseMap = new Map<String, String>();
            for (String key : objs.keySet()) {
                keySetCaseMap.put(key.toLowerCase(), key);
            }
            return keySetCaseMap;
        }

        /**
         * Returns a new XML string that replaces reserved words with a suffix.
         * This can be in the form:
         * - {Reservedword}
         * - {reservedword}
         *
         * @param str An xml encoded string
         * @param suffix A string that will be added to the end of the node names
         *
         * @return An xml encoded string with reserved words replaced
         */
        public String replaceXMLReservedWords(String str, String suffix)
        {
            if (str == null || suffix == null) {
                return str;
            }

            String reservedWordsRegex = String.join(RESERVED_WORDS, '|');
            String reservedUCWordsRegex = String.join(toUCWords(String.join(RESERVED_WORDS, ' ')).split(' '), '|');
            return str.replaceAll('<(/?(' + reservedWordsRegex + '|' + reservedUCWordsRegex + '))>', '<$1' + suffix + '>');
        }

        /**
         * Capitalizes the first letter of each word.
         *
         * @param str A standard string with words
         *
         * @return The string of words in title case
         */
        public String toUCWords(String str)
        {
            List<String> strWordArray = new List<String>();
            for (String strWord : str.split(' ')) {
                strWordArray.add(strWord.substring(0, 1).toUpperCase() + strWord.substring(1, strWord.length()));
            }
            return String.join(strWordArray, ' ');
        }
    }

    /**
    * ===============================================================================
     * The ObjectWrapper class is used to apply useful functions on top of the
     * object such as converting the type, detecting the type of object and sanitization.
     * ===============================================================================
     */
    @TestVisible
    private class ObjectWrapper {

        private final Object obj;

        /**
         * Parse the object for serialization.
         *
         * @param obj The original object that we want wrapped
         */
        public ObjectWrapper(Object obj)
        {
            this.obj = obj;
        }

        /**
         * Returns true if the current object has list of attributes that are in the form
         * attributes =>
         *  key => value
         *  key => value
         *
         * @return A boolean if the map has an attributes key
         */
        public Boolean hasAttributes()
        {
            return !getAttributes().isEmpty();
        }

        /**
         * Returns a map if the current object has list of attributes that are in the form
         * attributes =>
         *  key => value
         *  key => value
         *
         * @return A map of all attributes
         */
        public Map<String, Object> getAttributes()
        {
            if (!instanceOfMap()) {
                return new Map<String, Object>();
            }

            Map<String, Object> objMap = (Map<String, Object>) obj;
            if (objMap.containsKey('attributes') && new ObjectWrapper(objMap.get('attributes')).instanceOfMap()) {
                return (Map<String, Object>) objMap.get('attributes');
            }
            return new Map<String, Object>();
        }

        /**
         * Returns if the current object is a list.
         *
         * @return A boolean if the object is a list
         */
        public Boolean instanceOfList()
        {
            return obj instanceof List<Object>;
        }

        /**
         * Returns if the current object is a map.
         *
         * @return A boolean if the object is a map
         */
        public Boolean instanceOfMap()
        {
            return obj instanceof Map<String, Object>;
        }

        /**
         * Returns if the current object is a sobject list.
         *
         * @return A boolean if the object is a list of sobjects
         */
        public Boolean instanceOfSObjectList()
        {
            return obj instanceof List<SObject>;
        }

        /**
         * Returns if the current object is a sobject map.
         *
         * @return A boolean if the object is a map
         */
        public Boolean instanceOfSObjectMap()
        {
            return obj instanceof Map<Id, SObject>;
        }

        /**
         * Returns if the current object is an sobject.
         *
         * @return A boolean if the object is an sobject
         */
        public Boolean instanceOfSObject()
        {
            return obj instanceof SObject;
        }

        /**
         * If an sobject list, map, single sobject have been detected this can be used
         * to return the describe of this so we can get its name and other details.
         *
         * @return A describe of the sobject
         */
        public DescribeSObjectResult getSObjectDescribe()
        {
            if (instanceOfSObjectList()) {
                return toSObjectList().getSObjectType().getDescribe();
            } else if (instanceOfSObjectMap()) {
                return toSObjectMap().values().getSObjectType().getDescribe();
            } else {
                return toSObject().getSObjectType().getDescribe();
            }
        }

        /**
         * Returns if the object we have is empty regardless of its type.
         *
         * @return A boolean of if the object is empty
         */
        public Boolean isEmpty()
        {
            if (obj instanceof Map<String, Object>) {
                return ((Map<String, Object>) obj).isEmpty();
            }
            if (obj instanceof List<Object>) {
                return ((List<Object>) obj).isEmpty();
            }
            return obj == null || obj == '';
        }

        /**
         * Converts the current object to a list.
         *
         * @return The object cast as a map
         */
        public Map<String, Object> toMap()
        {
            return (Map<String, Object>) obj;
        }

        /**
         * Converts the current object to a list.
         *
         * @return The object cast as a list
         */
        public List<Object> toList()
        {
            return (List<Object>) obj;
        }

        /**
         * Converts the current object to an sobject map.
         *
         * @return The object cast as an sobject map
         */
        public Map<Id, SObject> toSObjectMap()
        {
            return (Map<Id, SObject>) obj;
        }

        /**
         * Converts the current object to a sobject list.
         *
         * @return The object cast as an sobject list
         */
        public List<SObject> toSObjectList()
        {
            return (List<SObject>) obj;
        }

        /**
         * Converts the current to an sobject.
         *
         * @return The object cast as an sobject
         */
        public SObject toSObject()
        {
            return (SObject) obj;
        }

        /**
         * Converts the object to a string value.
         *
         * @return The object cast as a string
         */
        public override String toString()
        {
            if (isEmpty()) {
                return '';
            }
            return String.valueOf(obj);
        }

        /**
         * Converts the object to a datetime value.
         *
         * @return The object cast as a datetime
         */
        public Datetime toDatetime()
        {
            return (Datetime) JSON.deserialize('"' + toString().replace(' ', 'T') + '"', Datetime.class);
        }

        /**
         * Converts the object to a time value.
         *
         * @return The object cast as a time
         */
        public Time toTime()
        {
            return (Time) JSON.deserialize('"' + toString() + '"', Time.class);
        }

        /**
         * Converts the object to a date value.
         *
         * @return The object cast as a date
         */
        public Date toDate()
        {
            return (Date) JSON.deserialize('"' + toString().replace('00:00:00', '').trim() + '"', Date.class);
        }

        /**
         * Converts the object to a boolean value.
         *
         * @return The object cast as a boolean
         */
        public Boolean toBoolean()
        {
            return obj.toString() == 'true';
        }

        /**
         * Converts the object to a id value.
         *
         * @return The object cast as an id
         */
        public Id toId()
        {
            return Id.valueOf(toString());
        }

        /**
         * Converts the object to a decimal value.
         *
         * @return The object cast as a decimal
         */
        public Decimal toDecimal()
        {
            return Decimal.valueOf(toString());
        }

        /**
         * Converts the object to a integer value.
         *
         * @return The object cast as a integer
         */
        public Integer toInteger()
        {
            return Integer.valueOf(toString());
        }

        /**
         * Converts the object to an untyped objected.
         *
         * @return The ObjectWrapper class
         */
        public ObjectWrapper toUntyped()
        {
            return new ObjectWrapper(JSON.deserializeUntyped(JSON.serialize(obj, false)));
        }

        /**
         * Gets the type of an object by looking at the structure of object and string.
         * The purpose of this detection, is due to the conversion of everything to a XML object, and converting primitive types to a string.
         *
         * Note: This does not detect the following types:
         * - Blob
         * - Long (set as integer)
         * - Double (set as integer / decimal depending on presence of decimal places)
         *
         * @return A string of the typename
         */
        public String getTypeName()
        {
            ObjectWrapper objUntyped = toUntyped();

            // Cannot detect type from null.
            if (obj == null) {
                return 'Null';
            }

            String objString = objUntyped.toString();

            // Any primitive types.
            if (String.isBlank(objString.replaceFirst('True|true|False|false', ''))) {
                return 'Boolean';
            }
            if (String.isBlank(objString.replaceFirst('[0-9]{4}-[0-9]{2}-[0-9]{2}', ''))) {
                return 'Date';
            }
            if (String.isBlank(objString.replaceFirst('[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}.[0-9]{3}((\\+[0-9]{4})|Z)', ''))) {
                return 'Datetime';
            }
            if (String.isBlank(objString.replaceFirst('[0-9A-Za-z]{18}|[0-9A-Za-z]{15}', ''))) {
                return 'Id';
            }
            if (String.isBlank(objString.replaceFirst('[0-9]{2}:[0-9]{2}:[0-9]{2}.[0-9]{3}Z', ''))) {
                return 'Time';
            }
            if (String.isBlank(objString.replaceFirst('-?[0-9]+', ''))) {
                return 'Integer';
            }
            if (String.isBlank(objString.replaceFirst('-?[0-9]+\\.[0-9]+', ''))) {
                return 'Decimal';
            }

            // Types we can detect.
            if (obj instanceof Map<String, Object>) {
                return 'Map';
            }
            if (obj instanceof List<Object>) {
                return 'List';
            }

            return 'String';
        }
    }
}

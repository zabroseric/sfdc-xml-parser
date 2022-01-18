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

    private static final String DEFAULT_ROOT_TAG = 'elements';
    private static final String DEFAULT_ELEMENT_TAG = 'element';
    private static final List<String> RESERVED_WORDS = new List<String>{'abstract', 'activate', 'and', 'any', 'array', 'as', 'asc', 'autonomous', 'begin', 'bigdecimal', 'blob', 'boolean', 'break', 'bulk', 'by', 'byte', 'case', 'cast', 'catch', 'char', 'class', 'collect', 'commit', 'const', 'continue', 'currency', 'date', 'datetime', 'decimal', 'default', 'delete', 'desc', 'do', 'double', 'else', 'end', 'enum', 'exception', 'exit', 'export', 'extends', 'false', 'final', 'finally', 'float', 'for', 'from', 'global', 'goto', 'group', 'having', 'hint', 'if', 'implements', 'import', 'in', 'inner', 'insert', 'instanceof', 'int', 'integer', 'interface', 'into', 'join', 'like', 'limit', 'list', 'long', 'loop', 'map', 'merge', 'new', 'not', 'null', 'nulls', 'number', 'object', 'of', 'on', 'or', 'outer', 'override', 'package', 'parallel', 'pragma', 'private', 'protected', 'public', 'retrieve', 'return', 'rollback', 'select', 'set', 'short', 'sObject', 'sort', 'static', 'string', 'super', 'switch', 'synchronized', 'system', 'testmethod', 'then', 'this', 'throw', 'time', 'transaction', 'trigger', 'true', 'try', 'undelete', 'update', 'upsert', 'using', 'virtual', 'void', 'webservice', 'when', 'where', 'while'};

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
        private String rootTag = DEFAULT_ROOT_TAG;
        private String elementTag = DEFAULT_ELEMENT_TAG;
        private Boolean showEncoding = false;
        private Map<String, String> rootAttributes = new Map<String, String>();
        private Map<String, String> namespaces = new Map<String, String>();
        private Boolean detectRootTag = true;
        private Boolean beautify = false;
        private Boolean embedAttributes = false;

        private ObjectWrapper obj;

        /**
         * Pass the object for serialization.
         *
         * @param obj
         *
         * @return
         */
        public Writer write(Object obj)
        {
            this.obj = (new ObjectWrapper(obj));
            return this;
        }

        /**
         * Converts the object to a string.
         *
         * @return
         */
        public override String toString()
        {
            Dom.Document document = parse();
            String xmlString = document.toXmlString();

            // If we chose to hide the encoding, remove it.
            if ( !showEncoding ) {
                xmlString = xmlString.replace('<?xml version="1.0" encoding="UTF-8"?>', '');
            }

            // Flatten the elements if possible, so Elements / Element => Element
            if ( document.getRootElement().getChildElements().size() == 1 && rootTag == DEFAULT_ROOT_TAG ) {
                xmlString = xmlString
                    .replaceAll('<(/?)(' + rootTag + '|' + elementTag + ')([^>]*)>' +
                        '\\s*(<(/?)(' + rootTag + '|' + elementTag + ')([^>]*)>)?',
                    '<$1' + elementTag + '$3>');
            }

            // If there are rootAttributes in the closing tags, remove them.
            xmlString = xmlString.replaceAll('</([^> ]+) [^>]+="[^>]+">', '</$1>');

            return beautify ? formatString(xmlString) : xmlString;
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
        public Writer beautify()
        {
            this.beautify = true;
            return this;
        }

        /**
         * Sets the output to be in a minified string.
         *
         * @return
         */
        public Writer minify()
        {
            this.beautify = false;
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
        public Writer addRootAttribute(String key, String value)
        {
            this.rootAttributes.put(key, value);
            return this;
        }

        /**
         * Sets attributes on the root node.
         *
         * @param rootAttributes
         *
         * @return
         */
        public Writer setRootAttributes(Map<String, String> rootAttributes)
        {
            this.rootAttributes = rootAttributes;
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
            this.rootAttributes.put('xmlns:' + prefix, uri);
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
         * Sets any attributes tags to be serialized into the tag.
         */
        public Writer embedAttributes()
        {
            this.embedAttributes = true;
            return this;
        }

        /**
         * Sets any attributes tags to be serialized into a separate child tag.
         */
        public Writer splitAttributes()
        {
            this.embedAttributes = true;
            return this;
        }

        /**
         * Formats the xml string.
         *
         * @param xmlString
         *
         * @return
         */
        private String formatString(String xmlString)
        {
            List<String> xmlStringSplit = xmlString.split('><');
            String xmlStringFormatted = '';
            Integer indents = 0;

            // Iterate over the individual pieces of the split tags
            // detecting how many indents are required on every line.
            for ( String split : xmlStringSplit ) {
                if ( split.left(1) == '/' ) {
                    indents--;
                }

                for ( Integer i = 0; i < indents; i++ ) { xmlStringFormatted += '  '; }
                xmlStringFormatted += '<' + split + '>\r\n';

                if ( !split.contains('>') && !split.contains('<?xml') && split.left(1) != '/' && split.right(1) != '/' ) {
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
         * @param rootTag
         * @param elementTag
         * @param suppressNulls
         *
         * @return
         */
        private Dom.Document parse()
        {
            // Detects and sets both the root and element tags based on any SObjects that can be found from
            // the object provided.
            if ( obj.instanceOfSObjectMap() || obj.instanceOfSObjectList() ) {
                rootTag = obj.getSObjectDescribe().labelPlural;
                elementTag = obj.getSObjectDescribe().label;
            }
            else if ( obj.instanceOfSObject() ) {
                rootTag = obj.getSObjectDescribe().label;
            }

            ObjectWrapper obj = obj.toUntyped();
            Dom.Document document = new Dom.Document();
            Dom.XmlNode xmlNode = document.createRootElement(rootTag, null, null);

            // If we have chosen to embed attributes, add them to the current node.
            if ( embedAttributes && obj.hasAttributes() )  {
                for ( String attrKey : obj.getAttributes().keySet() ) {
                    xmlNode.setAttribute(
                      attrKey,
                      obj.getAttributes().get(attrKey) != null ? String.valueOf(obj.getAttributes().get(attrKey)) : 'null'
                    );
                }
            }

            // Set the attributes on the root node.
            for ( String key : this.rootAttributes.keySet() ) {
                document.getRootElement().setAttribute(key, this.rootAttributes.get(key));
            }

            // Detect the type of root object we have and parse it.
            if ( obj.instanceOfList() && !obj.isEmpty() ) {
                parseList(obj.toList(), elementTag, xmlNode);
            }
            else if ( obj.instanceOfMap() && !obj.isEmpty() ) {
                parseMap(obj.toMap(), xmlNode);
            }

            // Otherwise if we have primitive type, parse this.
            else if ( !(obj.isEmpty() && suppressNulls) ) {
                xmlNode.addTextNode(obj.toString());
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

                ObjectWrapper obj = new ObjectWrapper(values.get(i));
                Dom.XmlNode childNode;

                // If we have chosen to embed attributes, add them to the tag.
                if ( embedAttributes && key == 'attributes' ) {
                    continue;
                }

                // If we have an empty list and have chosen not to suppress
                // nulls, ensure this is added to the xml.
                if ( obj.instanceOfList() && obj.isEmpty() && !suppressNulls ) {
                    childNode = xmlNode.addChildElement(key, null, null);
                }

                // Convert the lists / maps, iterate over these and determine if the
                // result was empty.
                else if ( obj.instanceOfList() ) {
                    notEmptyNumber += parseList(obj.toList(), key, xmlNode) ? 0 : 1;
                }
                else if ( obj.instanceOfMap() ) {
                    childNode = xmlNode.addChildElement(key, null, null);
                    notEmptyNumber += parseMap(obj.toMap(), childNode) ? 0 : 1;
                }

                // If we have a value don't iterate and just add the node.
                else if ( !obj.isEmpty() ) {
                    childNode = xmlNode
                        .addChildElement(key, null, null)
                        .addTextNode(obj.toString());
                    notEmptyNumber += 1;
                }

                // If we have chosen not to suppress nulls, ensure an empty tag is there.
                else if ( !suppressNulls ) {
                    childNode = xmlNode.addChildElement(key, null, null);
                    notEmptyNumber += 1;
                }

                // If we have chosen to embed attributes, add them to the node we have just added.
                if ( embedAttributes && obj.hasAttributes() && childNode != null )  {
                    for ( String attrKey : obj.getAttributes().keySet() ) {
                        childNode.setAttribute(attrKey, String.valueOf(obj.getAttributes().get(attrKey)));
                    }
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

        private String xmlString { get { return new Utils().replaceXMLReservedWords(xmlString, reservedWordSuffix); } set; }
        private Type apexType;
        private String apexTypeName;
        private Set<String> arrayNodes = new Set<String>();
        private Boolean showNamespaces = true;
        private String filterNamespace;
        private String reservedWordSuffix = '_x';

        /**
         * Pass the xml string for deserialization.
         *
         * @param xmlString
         *
         * @return
         */
        public Reader read(String xmlString)
        {
            // Remove white space in blank tags to correctly set them as nulls.
            this.xmlString = xmlString != null ? xmlString.replaceAll('>\\s+<', '><') : null;
            return this;
        }

        /**
         * Converts the xml string to an Object.
         *
         * @return
         */
        public Object toObject() {
            try {
                return toObjectInternal();
            } catch (JSONException e) {
                if ( e.getMessage().contains('Expected List') ) {
                    throw new XmlException('An array node has not been correctly set by value ' +
                        e.getMessage().replaceAll('.+(".+").+', '$1')
                    );
                }
                throw e;
            }
        }

        /**
         * Converts the xml string to an Object.
         *
         * @return
         */
        private Object toObjectInternal()
        {
            Map<String, Object> objectMap;

            try {
                objectMap = parse();
            }
            catch (Exception e) {
                throw new XmlException('The XML string is invalid, value: ' + xmlString);
            }
            System.debug(objectMap);

            // If we haven't passed a type, return the map we have.
            if ( apexType == null ) {
                return objectMap;
            }

            // If the type is deserializable and we have found the type as a key in the map,
            // return the value of this key.
            else if ( ((Type) Deserializable.class).isAssignableFrom(apexType) && new Utils().containsCaseInsensitive(objectMap, apexTypeName) ) {
                return ((Deserializable) apexType.newInstance()).xmlDeserialize((Object) new Utils().getObjCaseInsensitive(objectMap, apexTypeName));
            }

            // Otherwise if the type is deserializable, pass the entire map.
            else if ( ((Type) Deserializable.class).isAssignableFrom(apexType) ) {
                return ((Deserializable) apexType.newInstance()).xmlDeserialize(objectMap);
            }

            // If the apex type is a partial key with the map use that, this is useful for nested classes.
            else if ( new Utils().containsCaseInsensitive(objectMap, apexTypeName) ) {
                return JSON.deserialize(JSON.serialize(new Utils().getObjCaseInsensitive(objectMap, apexTypeName)), apexType);
            }

            // If the apex type we have is a list, get the list from the map.
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
         * When one of the tags contains a reserved word, this tag will be renamed and a suffix
         * added so that it can be correctly managed.
         *
         * @param reservedWordSuffix
         *
         * @return
         */
        public Reader setReservedWordSuffix(String reservedWordSuffix)
        {
            this.reservedWordSuffix = reservedWordSuffix;
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


            // If the apex type is a partial key with the map use that, this is useful for nested classes.
            if ( apexType != null && apexType.getName().contains('.') ) {
                apexTypeName = apexType.getName().substringAfter('.');
            }
            else if ( apexType != null ) {
                apexTypeName = apexType.getName();
            }
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

        /**
         * Filter the namespaces so that either namespaces that are empty
         * or that do not have a namespace are returned.
         *
         * @param filterNamespace
         *
         * @return
         */
        public Reader filterNamespace(String filterNamespace)
        {
            this.filterNamespace = filterNamespace;
            return this;
        }

        /**
         * Shows namespaces as clark notations.
         *
         * @return
         */
        public Reader showNamespaces()
        {
            this.showNamespaces = true;
            return this;
        }

        /**
         * Hide namespaces and show only the tag name.
         *
         * @return
         */
        public Reader hideNamespaces()
        {
            this.showNamespaces = false;
            return this;
        }

        /**
         * Entry points for the reader toObject method.
         *
         * @return
         */
        private Map<String, Object> parse()
        {
            XmlStreamReader xmlStreamReader = new XmlStreamReader(xmlString);
            xmlStreamReader.setCoalescing(true);
            return (Map<String, Object>) parseNested(xmlStreamReader, null);
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

            while ( hasNext ) {
                // Add the clark notation to the tag name if we have a namespace.
                tagName = ( showNamespaces && reader.getNamespace() != null ? '{' + reader.getNamespace() + '}' : '') + reader.getLocalName();

                // If we have a start element add this.
                if ( reader.getEventType() == XmlTag.START_ELEMENT ) {
                    // Add the attributes as a separate tag to support deserialization.
                    Map<String, Object> attributeMap = new Map<String, Object>();
                    if ( reader.getAttributeCount() > 0 ) {
                        for ( Integer i = 0; i < reader.getAttributeCount(); i++ ) {
                            attributeMap.put(reader.getAttributeLocalName(i), reader.getAttributeValueAt(i));
                        }
                    }

                    objectCurrent = parseNested(reader, tagName);

                    // If we have a map as our current tag, add the attributes tag / merge the values.
                    if ( objectCurrent instanceof Map<String, Object> && !attributeMap.isEmpty() ) {
                        Map<String, Object> objectCurrentMap = ((Map<String, Object>) objectCurrent);
                        if ( objectCurrentMap.containsKey('attributes') ) {
                            ((Map<String, Object>) objectCurrentMap.get('attributes')).putAll(attributeMap);
                        } else {
                            objectCurrentMap.put('attributes', attributeMap);
                        }
                    }

                    // If we haven't come across this node, and we should make it array, create one.
                    if ( !objectMap.containsKey(tagName) && arrayNodes.contains(tagName) ) {
                        objectMap.put(tagName, new List<Object>{objectCurrent});
                    }
                    // If we haven't come across this node, by default create a map.
                    else if ( !objectMap.containsKey(tagName) ) {
                        objectMap.put(tagName, objectCurrent);
                    }
                    // If we have this node, and it's a list add to it.
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

                    // If we have chosen to filter the namespace remove the node we generated.
                    // This way we still loop through the reader.
                    if ( filterNamespace != null && tagName.contains('{') && !tagName.contains(filterNamespace) ) {
                        objectMap.remove(tagName);
                    }

                }

                // We we are ending our starting tag break this loop.
                else if ( reader.getEventType() == XmlTag.END_ELEMENT && elementName == reader.getLocalName() ) {
                    break;
                }

                // If we have text return and the namespace is valid, return it.
                else if ( reader.getEventType() == XmlTag.CHARACTERS ) {
                    return reader.getText();
                }

                hasNext = reader.hasNext();
                if ( hasNext ) { reader.next(); }
            }
            return objectMap.isEmpty() ? null : objectMap;
        }
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
         * @param objs
         * @param key
         *
         * @return
         */
        public Boolean containsCaseInsensitive(Map<String, Object> objs, String key) {
            return this.getObjCaseInsensitive(objs, key) != null;
        }

        /**
         * Returns the object of a map via a key that is insensitive.
         *
         * @param objs
         * @param key
         *
         * @return
         */
        public Object getObjCaseInsensitive(Map<String, Object> objs, String key) {
            return objs.get(this.getKeyCaseInsensitive(objs, key));
        }

        /**
         * Returns the key of a map via a key that is insensitive.
         *
         * @param objs
         * @param key
         *
         * @return
         */
        public String getKeyCaseInsensitive(Map<String, Object> objs, String key) {
            return this.getKeySetCaseMap(objs).get(key.toLowerCase());
        }

        /**
         * Returns a key set map in the following format.
         * key lower case => key
         *
         * @param objs
         *
         * @return
         */
        public Map<String, String> getKeySetCaseMap(Map<String, Object> objs) {
            Map<String, String> keySetCaseMap = new Map<String, String>();
            for ( String key : objs.keySet() ) {
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
         * @param str
         * @param suffix
         *
         * @return
         */
        public String replaceXMLReservedWords(String str, String suffix) {
            if ( str == null || suffix == null ) {
                return str;
            }

            String reservedWordsRegex = String.join(RESERVED_WORDS, '|');
            String reservedUCWordsRegex = String.join(toUCWords(String.join(RESERVED_WORDS, ' ')).split(' '), '|');
            return str.replaceAll('<(/?(' + reservedWordsRegex + '|' + reservedUCWordsRegex + '))>', '<$1' + suffix + '>');
        }

        /**
         * Capitalizes the first letter of each word.
         *
         * @param str
         *
         * @return
         */
        public String toUCWords(String str) {
            List<String> strWordArray = new List<String>();
            for ( String strWord : str.split(' ') ) {
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
    private class ObjectWrapper {

        private Object obj;

        /**
         * Parse the object for serialization.
         *
         * @param obj
         *
         * @return
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
         * @return
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
         * @return
         */
        public Map<String, Object> getAttributes()
        {
            if ( !instanceOfMap() ) {
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
         * @return
         */
        public Boolean instanceOfList()
        {
            return obj instanceof List<Object>;
        }

        /**
         * Returns if the current object is a map.
         *
         * @return
         */
        public Boolean instanceOfMap()
        {
            return obj instanceof Map<String, Object>;
        }

        /**
         * Returns if the current object is a sobject list.
         *
         * @return
         */
        public Boolean instanceOfSObjectList()
        {
            return obj instanceof List<SObject>;
        }

        /**
         * Returns if the current object is a sobject map.
         *
         * @return
         */
        public Boolean instanceOfSObjectMap()
        {
            return obj instanceof Map<Id, SObject>;
        }

        /**
         * Returns if the current object is an sobject.
         *
         * @return
         */
        public Boolean instanceOfSObject()
        {
            return obj instanceof SObject;
        }

        /**
         * If an SObject list, map, single object have been detected this can be used
         * to return the describe of this so we can get its name and other details.
         *
         * @return
         */
        public DescribeSObjectResult getSObjectDescribe()
        {
            if ( instanceOfSObjectList() ) {
                return toSObjectList().getSObjectType().getDescribe();
            }
            else if ( instanceOfSObjectMap() ) {
                return toSObjectMap().values().getSObjectType().getDescribe();
            }
            else {
                return toSObject().getSObjectType().getDescribe();
            }
        }

        /**
         * Converts the current object to a list.
         *
         * @return
         */
        public Map<String, Object> toMap()
        {
            return (Map<String, Object>) obj;
        }

        /**
         * Converts the current object to a map.
         *
         * @return
         */
        public List<Object> toList()
        {
            return (List<Object>) obj;
        }

        /**
         * Converts the current object to a sobject list.
         *
         * @return
         */
        public Map<Id, SObject> toSObjectMap()
        {
            return (Map<Id, SObject>) obj;
        }

        /**
         * Converts the current object to a sobject map.
         *
         * @return
         */
        public List<SObject> toSObjectList()
        {
            return (List<SObject>) obj;
        }

        /**
         * Converts the current to an sobject.
         *
         * @return
         */
        public SObject toSObject()
        {
            return (SObject) obj;
        }

        /**
         * Returns if the object we have is empty regardless of its type.
         *
         * @return
         */
        public Boolean isEmpty()
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
        public override String toString()
        {
            if ( isEmpty() ) { return ''; }
            return String.valueOf(obj);
        }

        /**
         * Converts the object to an untyped objected.
         *
         * @return
         */
        public ObjectWrapper toUntyped()
        {
            return new ObjectWrapper(JSON.deserializeUntyped(JSON.serialize(obj, false)));
        }
    }
}
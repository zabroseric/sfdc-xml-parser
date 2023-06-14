# SFDC XML Parser

Built Status:
![coverage](https://img.shields.io/badge/coverage-100%25-yellowgreen)
![build](https://img.shields.io/badge/build-passing-success)
[![Maintainability](https://api.codeclimate.com/v1/badges/7dbda30d4ea9ddf96974/maintainability)](https://codeclimate.com/github/zabroseric/sfdc-xml-parser/maintainability)

![sfdc package](https://img.shields.io/badge/sfdc%20package-53.0-blue)
[![GitHub license](https://img.shields.io/github/license/zabroseric/sfdc-xml-parser.svg)](https://github.com/zabroseric/sfdc-xml-parser/blob/master/LICENSE)


|                                                                             Deploy to Salesforce Org                                                                             |
| :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------: |
| [![Deploy](https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png)](https://githubsfdeploy.herokuapp.com/?owner=zabroseric&repo=sfdc-xml-parser&ref=master) |

## Table of Contents

- [SFDC XML Parser](#sfdc-xml-parser)
  - [Table of Contents](#table-of-contents)
  - [Features](#features)
  - [Overview](#overview)
  - [Getting Started](#getting-started)
  - [Usage - Serialization](#usage---serialization)
    - [SObject](#sobject)
    - [SObject List](#sobject-list)
    - [Objects](#objects)
    - [Maps](#maps)
  - [Usage - Deserialization](#usage---deserialization)
    - [SObject](#sobject-1)
    - [SObject List](#sobject-list-1)
    - [Objects](#objects-1)
    - [Maps](#maps-1)
  - [References - Serialization](#references---serialization)
    - [Summary](#summary)
    - [toString](#tostring)
    - [toBase64](#tobase64)
    - [debug](#debug)
    - [showNulls (default) / suppressNulls](#shownulls-default--suppressnulls)
    - [minify (default) / beautify](#minify-default--beautify)
    - [hideEncoding (default) / showEncoding](#hideencoding-default--showencoding)
    - [addRootAttribute / setRootAttributes](#addrootattribute--setrootattributes)
    - [addNamespace / setNamespaces](#addnamespace--setnamespaces)
    - [setRootNodeName](#setrootnodename)
    - [splitAttributes (default) / embedAttributes](#splitattributes-default--embedattributes)
  - [References - Deserialization](#references---deserialization)
    - [Summary](#summary-1)
    - [toObject](#toobject)
    - [setType](#settype)
    - [toString](#tostring-1)
    - [debug](#debug-1)
    - [setReservedWordSuffix](#setreservedwordsuffix)
    - [filterNamespace](#filternamespace)
    - [showNamespaces (default) / hideNamespaces](#shownamespaces-default--hidenamespaces)
    - [addArrayNode / setArrayNodes](#addarraynode--setarraynodes)
    - [setRootNode](#setrootnode)
    - [sanitize (default) / unsanitize](#sanitize-default--unsanitize)
  - [Other Cool Things](#other-cool-things)
    - [Deserialization Interfaces](#deserialization-interfaces)
    - [Self Keyword](#self-keyword)
    - [Node Name Sanatization](#node-name-sanatization)
    - [Value Encoding](#value-encoding)
  - [Limitations](#limitations)
  - [Contributing](#contributing)

## Features

* Serialize / Deserialize SObjects
* Serialize / Deserialize Apex Classes
* Function Chaining
* SObject Node Detection
* Node Name and Value Sanitization
* Clark Notations
* Deserialization Interfaces
* Namespace Filtering
* Reserved Word Management

## Overview

Apex does not currently support XML serialization and deserialization. This functionality is useful when communicating with other systems that support only an XML format, storing files, or even generating HTML. The XML parser bridges this gap by managing the encoding by automatically mapping SObject fields, handling special characters and providing a wide range of flexibility during the encoding processes.

**Why not create something?**

Simple - By using a pre-built library like this, no additional development work is needed on your end. Future requirements are met, and the solution has been tested over a wide range of use-cases. Plus we use the solution ourselves in multiple projects. This means that as we or other community members require more functionality, the library is updated. Additionally, as edge cases are found during use, these are fixed.

## Getting Started

The XML Parser uses function chaining to change how the serialization/deserialization is handled. For example, you may want to format the XML in a pretty format with spacing and newlines to help with debugging. To do this, we can simply call the **beautify()** method as per the below:

```java
XML.serialize(contact).beautify().toString();
```

The result of serialization is as follows:

```xml
<Contact>
  <attributes>
    <type>Contact</type>
    <url>/services/data/v53.0/sobjects/Contact/0035j00000I09JaAAJ</url>
  </attributes>
  <Name>First1 Last1</Name>
  <Id>0035j00000I09JaAAJ</Id>
</Contact>
```

The usage section covers common use-cases of these, whereas a list of these can be seen in the [references](#references-serialization) section at the bottom of the readme.

## Usage - Serialization

Examples can be seen below of common serialization use-cases from handling SObjects, to lists and various functions that can be used.

### SObject

The root node is automatically detected, and attributes are added.

```java
Contact contact = new Contact(
    FirstName = 'First',
    LastName = 'Last'
);
insert contact;

String xmlString = XML.serialize(contact).beautify().toString();
```

Result

```xml
<Contact>
   <attributes>
      <type>Contact</type>
      <url>/services/data/v48.0/sobjects/Contact/0032w000005DrR2AAK</url>
   </attributes>
   <FirstName>First</FirstName>
   <LastName>Last</LastName>
   <Id>0032w000005DrR2AAK</Id>
</Contact>
```

### SObject List

The root node name is converted to a plural that contains child nodes as per the single SObject serialization.

```java
List<Contact> contacts = new List<Contact>{
    new Contact(
        FirstName = 'First1',
        LastName = 'Last1'
    ),
    new Contact(
        FirstName = 'First2',
        LastName = 'Last2'
    )
};
insert contacts;

String xmlString = XML.serialize(contacts).beautify().toString();
```

Result

```xml
<Contacts>
   <Contact>
      <attributes>
         <type>Contact</type>
         <url>/services/data/v48.0/sobjects/Contact/0032w000005DrQxAAK</url>
      </attributes>
      <FirstName>First1</FirstName>
      <LastName>Last1</LastName>
      <Id>0032w000005DrQxAAK</Id>
   </Contact>
   <Contact>
      <attributes>
         <type>Contact</type>
         <url>/services/data/v48.0/sobjects/Contact/0032w000005DrQyAAK</url>
      </attributes>
      <FirstName>First2</FirstName>
      <LastName>Last2</LastName>
      <Id>0032w000005DrQyAAK</Id>
   </Contact>
</Contacts>
```

### Objects

Classes / Objects can be serialized. If the root node name is not set, this will default to either **element** or **elements** depending on if we have a list of objects.

```java
Library libraryObject = new Library(
    new Catalog(
        new Books(
            new List<Book>{
                new Book('title1', new Authors(new List<String>{'Name1', 'Name2'}), '23.00'),
                new Book('title1', new Authors(new List<String>{'Name3', 'Name4'}), '23.00')
            }
        )
    )
);

String xmlString = XML.serialize(libraryObject).setRootNodeName('library').beautify().toString();
```

Result

```xml
<library>
   <catalog>
      <books>
         <book>
            <title>title1</title>
            <price>23.00</price>
            <authors>
               <author>Name1</author>
               <author>Name2</author>
            </authors>
         </book>
         <book>
            <title>title1</title>
            <price>23.00</price>
            <authors>
               <author>Name3</author>
               <author>Name4</author>
            </authors>
         </book>
      </books>
   </catalog>
</library>
```

### Maps

If we are wanting to work with a map/list of primitive types this operates similar to that of objects.

```java
String xmlString = XML.serialize(new Map<String, String>{
    'key1' => 'val1',
    'key2' => 'val2'
}).beautify().debug().toString();
```

Result

```xml
<elements>
   <key2>val2</key2>
   <key1>val1</key1>
</elements>
```

## Usage - Deserialization

### SObject

All fields that are common between the XML and SObject are deserialized.

```java
Contact contact = (Contact) XML.deserialize('<Contact><attributes><type>Contact</type><url>/services/data/v48.0/sobjects/Contact/0032w000005DrR2AAK</url></attributes><FirstName>First</FirstName><LastName>Last</LastName><Id>0032w000005DrR2AAK</Id></Contact>')
    .setType(Contact.class).toObject();
```

### SObject List

A list of SObjects are deserialized if the type is set as a **List&lt;SObject&gt;.class**

```java
List<Contact> contactResult = (List<Contact>) XML.deserialize('<Contacts><Contact><attributes><type>Contact</type><url>/services/data/v48.0/sobjects/Contact/0032w000005DrQxAAK</url></attributes><FirstName>First1</FirstName><LastName>Last1</LastName><Id>0032w000005DrQxAAK</Id></Contact><Contact><attributes><type>Contact</type><url>/services/data/v48.0/sobjects/Contact/0032w000005DrQyAAK</url></attributes><FirstName>First2</FirstName><LastName>Last2</LastName><Id>0032w000005DrQyAAK</Id></Contact></Contacts>')
    .setType(List<Contact>.class).toObject();
```

### Objects

Classes and objects can be deserialized in cases that models are used instead of objects.

```java
Library library = XML.deserialize('<library><catalog><books><book><title>title1</title><price>23.00</price><authors><author>Name1</author><author>Name2</author></authors></book><book><title>title1</title><price>23.00</price><authors><author>Name3</author><author>Name4</author></authors></book></books></catalog></library>', Library.class)
    .toObject();
```

### Maps

Similarly to serialization, a map/list of primitive types can be deserialized.

```java
Map<String, Object> objectMap = (Map<String, Object>) XML.deserialize('<elements><key2>val2</key2><key1>val1</key1></elements>')
    .setArrayNode('elements').toObject();
```

## References - Serialization

### Summary

- [toString](#tostring)
- [toBase64](#tobase64)
- [debug](#debug)
- [showNulls (default) / suppressNulls](#shownulls-default--suppressnulls)
- [minify (default) / beautify](#minify-default--beautify)
- [hideEncoding (default) / showEncoding](#hideencoding-default--showencoding)
- [addRootAttribute / setRootAttributes](#addrootattribute--setrootattributes)
- [addNamespace / setNamespaces](#addnamespace--setnamespaces)
- [setRootNodeName](#setrootnodename)
- [splitAttributes (default) / embedAttributes](#splitattributes-default--embedattributes)

### toString

Combines the other functions in the chain sequence to provide the resulting XML in string format.

```java
Contact contact = new Contact(
    FirstName = 'First',
    LastName = 'Last'
);

String xmlString = XML.serialize(contact)
    .setRootNodeName('NewNodeName') // function 1
    .showEncoding()       // function 2
    .beautify()           // function 3
    .toString();          // Result
```

The result in the **xmlString** variable is as follows:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<NewNodeName>
  <attributes>
    <type>Contact</type>
  </attributes>
  <FirstName>First</FirstName>
  <LastName>Last</LastName>
</NewNodeName>
```

### toBase64

Combines the other functions in the chain sequence as like the **toString** method, and encodes the XML result in base64 format.

```java
Contact contact = new Contact(
    FirstName = 'First',
    LastName = 'Last'
);

String xmlString = XML.serialize(contact)
    .setRootNodeName('NewNodeName') // function 1
    .showEncoding()       // function 2
    .beautify()           // function 3
    .toBase64();          // Result
```

The result in the **xmlString** variable is as follows:

```plaintext
PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4NCjxOZXdUYWc+DQogIDxhdHRyaWJ1dGVzPg0KICAgIDx0eXBlPkNvbnRhY3Q8L3R5cGU+DQogIDwvYXR0cmlidXRlcz4NCiAgPEZpcnN0TmFtZT5GaXJzdDwvRmlyc3ROYW1lPg0KICA8TGFzdE5hbWU+TGFzdDwvTGFzdE5hbWU+DQo8L05ld1RhZz4=
```

### debug

Prints the XML string to the console using the functions executed previously in the chain. Multiple debugs can be called in the same chain, with each executing independently of the other.

```java
Contact contact = new Contact(
    FirstName = 'First',
    LastName = 'Last'
);

String xmlString = XML.serialize(contact)
    .debug() // Debug 1
    .showEncoding().beautify().debug() // Debug 2
    .toString();
```

Debug 1

```xml
<Contact><attributes><type>Contact</type></attributes><FirstName>First</FirstName><LastName>Last</LastName></Contact>
```

Debug 2

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Contact>
   <attributes>
      <type>Contact</type>
   </attributes>
   <FirstName>First</FirstName>
   <LastName>Last</LastName>
</Contact>
```

### showNulls (default) / suppressNulls

When there are empty or null value node values, by default the value will be rendered within the respective XML node. However, if we want to hide null or empty values, it is possible to use the **suppressNulls** method.

The result is that any empty nodes are removed until all nodes have values in them.

```java
Library library = new Library(
    new Catalog(
        new Books(
            new List<Book>{
                new Book('title1', new Authors(new List<String>{'Name1', 'Name2'}), '23.00'),
                new Book('title5', new Authors(new List<String>{}), null)
            }
        )
    )
);

XML.serialize(library).suppressNulls().setRootNodeName('library').beautify().debug();
```

In the example, the second book does not have any authors. The result is that the author, authors nodes are suppressed alongside the price of the book.

```xml
<library>
   <catalog>
      <books>
         <book>
            <title>title1</title>
            <price>23.00</price>
            <authors>
               <author>Name1</author>
               <author>Name2</author>
            </authors>
         </book>
         <book>
            <title>title5</title>
         </book>
      </books>
   </catalog>
</library>
```

### minify (default) / beautify

By default the resulting XML has no spaces or new lines between nodes to help with readability. The default behaviour can be overridden by calling the **beautify** method to nicely format the resulting string.

```java
Contact contact = new Contact(
  FirstName = 'First',
  LastName = 'Last'
);

String xmlStringNormal = XML.serialize(contact).toString();
String xmlStringBeautify = XML.serialize(contact).beautify().toString();
```

The result is as follows:

xmlStringNormal

```xml
<Contact><attributes><type>Contact</type></attributes><FirstName>First</FirstName><LastName>Last</LastName></Contact>
```

xmlStringBeautify

```xml
<Contact>
  <attributes>
    <type>Contact</type>
  </attributes>
  <FirstName>First</FirstName>
  <LastName>Last</LastName>
</Contact>
```

### hideEncoding (default) / showEncoding

By default the header of the XML is omitted and only the body is present. However when needing to show the header and encoding, this can be done as per the example below:

```java
Contact contact = new Contact(
  FirstName = 'First',
  LastName = 'Last'
);

String xmlString = XML.serialize(contact).showEncoding().beautify().toString();
```

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Contact>
  <attributes>
    <type>Contact</type>
  </attributes>
  <FirstName>First</FirstName>
  <LastName>Last</LastName>
</Contact>
```

### addRootAttribute / setRootAttributes

When needing to provide additional attributes this can be set one at a time via the **addRootAttribute** method, or several at a time using the **setRootAttributes** method.

By default attributes are stored as a child attributes node, however, this can be overridden by the **embedAttributes** method.

```java
Contact contact = new Contact(
  FirstName = 'First',
  LastName = 'Last'
);

String xmlString = XML.serialize(contact).addRootAttribute('key1', 'value1').addRootAttribute('key2', 'value2').beautify().toString();
```

The result is two additional elements within the attributes node are present.

```xml
<Contact>
  <attributes>
    <type>Contact</type>
    <key1>value1</key1>
    <key2>value2</key2>
  </attributes>
  <FirstName>First</FirstName>
  <LastName>Last</LastName>
</Contact>
```

### addNamespace / setNamespaces

Clark notations support the ability to specify both the XML namespace and 'local name'.
For more information please see the link [here](http://www.jclark.com/xml/xmlns.htm).

An example of this can be seen below:

```java
XML.serialize(new List<Object>{
    new Map<String, String>{
        '{http://example.org}localname1' => 'val1',
        '{http://example.org}localname2' => 'val2'
    }
}).addNamespace('http://example.org', 'b').beautify().debug();
```

The result gets transformed to valid xml:

```xml
<element xmlns:b="http://example.org">
   <b:localname2>val2</b:localname2>
   <b:localname1>val1</b:localname1>
</element>
```

### setRootNodeName

Node names are automatically detected for SObjects. For all other situations of serialization, the default for this is **element**.

To override this functionality, a root node name can be specified.

```java
Contact contact = new Contact(
  FirstName = 'First',
  LastName = 'Last'
);

String xmlString = XML.serialize(contact).setRootNodeName('MyNode').beautify().toString();
```

```xml
<MyNode>
  <attributes>
    <type>Contact</type>
  </attributes>
  <FirstName>First</FirstName>
  <LastName>Last</LastName>
</MyNode>
```

### splitAttributes (default) / embedAttributes

By default, attributes are created as seperate child nodes on the parent. This is to support expected behaviour when serializing SObjects.

When overriding this default functionality, attributes will be stored as proper node attributes.

```java
Contact contact = new Contact(
  FirstName = 'First',
  LastName = 'Last'
);

String xmlString = XML.serialize(contact).embedAttributes().beautify().toString();
```

```xml
<Contact type="Contact">
  <FirstName>First</FirstName>
  <LastName>Last</LastName>
</Contact>
```

Further to this, any fields with the called **attributes** with a type of Map<String, Object> will be automatically embedded as attributes on the current node.

## References - Deserialization

### Summary

- [toObject](#toobject)
- [setType](#settype)
- [toString](#tostring-1)
- [debug](#debug-1)
- [setReservedWordSuffix](#setreservedwordsuffix)
- [filterNamespace](#filternamespace)
- [showNamespaces](#shownamespaces-default--hidenamespaces)
- [hideNamespaces](#shownamespaces-default--hidenamespaces)
- [addArrayNode](#addarraynode--setarraynodes)
- [setArrayNodes](#addarraynode--setarraynodes)
- [setRootNode](#setrootnode)
- [sanitize (default) / unsanitize](#sanitize-default--unsanitize)

### toObject

Combines the result of the previous functions in the chain sequence to produce an object specified in the **toType** method. The return result will need to be cast manually.

```java
Contact contact = (Contact) XML.deserialize('<Contact><attributes><type>Contact</type></attributes><FirstName>First</FirstName><LastName>Last</LastName></Contact>').setType(Contact.class).toObject();

// => Contact:{FirstName=First, LastName=Last}
```

### setType

Deserializes the XML to a specified type, whether this is an SObject, Object, List, Map ..etc. If any errors occur during the mapping process relevant exceptions will be thrown.

```java
Contact contact = (Contact) XML.deserialize('<Contact><attributes><type>Contact</type></attributes><FirstName>First</FirstName><LastName>Last</LastName></Contact>').setType(Contact.class).toObject();

// => Contact:{FirstName=First, LastName=Last}

Contact contact = (Contact) XML.deserialize('<Contact><attributes><type>Contact</type></attributes><FirstName>First</FirstName><LastName>Last</LastName></Contact>').setType(Integer.class).toObject();

// => System.XmlException: Can not deserialize: unexpected array at [line:1, column:1]
```

### toString

Deserializes the XML string to the specified type and calls the objects toString method.

```java
String str = XML.deserialize('<Contact><attributes><type>Contact</type></attributes><FirstName>First</FirstName><LastName>Last</LastName></Contact>').setType(Contact.class).toString();

// => Contact:{FirstName=First, LastName=Last}
```

### debug

Prints the current object using its toString method to the console using the functions executed previously in the chain. Multiple debugs can be called in the same chain, with executing independently of the other.

```java
class CompleteDate {
  public Date date_xyz;
  public Time time_xyz;
}

CompleteDate completeDate = (CompleteDate) XML.deserialize(
  '<CompleteDate>' +
  '   <Date>2019-01-28</Date>' +
  '   <Time>11:00:09Z</Time>' +
  '</CompleteDate>'
).setType(CompleteDate.class)
  .debug()                            // Debug 1
  .setReservedWordSuffix('_xyz')
  .debug()                            // Debug 2
  .toObject();

// => CompleteDate:[date_xyz=null, time_xyz=null]
// => CompleteDate:[date_xyz=2019-01-28 00:00:00, time_xyz=11:00:09.000Z]
```

### setReservedWordSuffix

When the XML data contains reserved words in Apex, the default suffix of **_x** is added. However, if you would like to add your own custom suffix, you can do so via the following:

```java
class CompleteDate {
  public Date date_xyz;
  public Time time_xyz;
}

CompleteDate completeDate = (CompleteDate) XML.deserialize(
  '<CompleteDate>' +
  '   <Date>2019-01-28</Date>' +
  '   <Time>11:00:09Z</Time>' +
  '</CompleteDate>'
).setType(CompleteDate.class)
  .debug()
  .setReservedWordSuffix('_xyz')
  .debug()
  .toObject();
```

For a list of these, please see the reserved word table [here](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_reserved_words.htm).

### filterNamespace

Clark notations can be used to specify namespaces and local names. These nodes can be filtered by defining the local names you would like to keep.

For more information on Clark notation please see the link [here](http://www.jclark.com/xml/xmlns.htm).

```java
Map<String, Map<String, String>> embeddedMap = (Map<String, Map<String, String>>) XML.deserialize(
  '<element xmlns:b="http://example.org">' +
  '   <b:localname2>val2</b:localname2>' +
  '   <b:localname1>val1</b:localname1>' +
  '</element>'
)
  .setType(Map<String, Map<String, String>>.class)
  .filterNamespace('localname2')
  .toObject();

// => {element={{http://example.org}localname2=val2}}
```

### showNamespaces (default) / hideNamespaces

Namespaces are by default preserved when deserializing. If these are required to be hidden, this can be done by calling the **hideNamespaces** method.

```java
Map<String, Map<String, String>> embeddedMap = (Map<String, Map<String, String>>) XML.deserialize(
  '<element xmlns:b="http://example.org">' +
    '   <b:localname2>val2</b:localname2>' +
    '   <b:localname1>val1</b:localname1>' +
    '</element>'
)
  .setType(Map<String, Map<String, String>>.class)
  .hideNamespaces()
  .toObject();

// => {element={localname1=val1, localname2=val2}}
```

### addArrayNode / setArrayNodes

As reflection is not fully supported in Apex, the library cannot detect if a element should be treated as a List or Map. As a solution, we can specify what nodes should be treated as an array when deserialized.

In the below example, the books node is detected as a map as there is only one child node. If the **setArrayNodes**, the deserialization will treat the books node as an array.

```java
Library library = (Library) XML.deserialize(
  '<library>' +
  '   <catalog>' +
  '      <books>' +
  '         <book>' +
  '            <title>title5</title>' +
  '            <price />' +
  '            <authors />' +
  '         </book>' +
  '      </books>' +
  '   </catalog>' +
  '</library>', Library.class)
     .setArrayNodes(new Set<String>{'book'}).toObject();
```


### setRootNode

In the situations there are nodes that we want to ignore, we can specify a Xpath decendant to start from.

In the below example, the books node is detected as a map as there is only one child node. If the **setArrayNodes**, the deserialization will treat the books node as an array.

```java
Map<String, Object> objElements = (Map<String, Object>) XML.deserialize(
  '<Response>' +
  '  <Body>' +
  '    <Fields>' +
  '      <element1>First</element1>' +
  '      <element2>Last</element2>' +
  '    </Fields>' +
  '  </Body>' +
  '</Response>'
)
  .setRootNode('/Response/Body/Fields')
  .toObject();

// => {element1=First, element2=Last}
```


### sanitize (default) / unsanitize

When reading an XML string that is very large it's possible to disable the sanization in order to overcome regex expression limits, and help reduce heap and CPU limits.

Note: This should only be changed if you are confident that both the XML string is minified and the node names do not contain any reserved words.

An example of how this can be changed, can be seen below:

```java
Map<String, Object> objElements = (Map<String, Object>) XML.deserialize(myVeryBigXMLString)
  .unsanitize()
  .toObject();
```


## Other Cool Things

### Deserialization Interfaces

By default, deserialization is handled through the native Apex JSON functionality. However, if the apex object extends the XML.Deserialize interface, the default behaviour will be overridden and the xmlDeserialize method is called.

The method will be passed either a list, map or primitive data type based on what is located inside current the XML node.

An example of this can be seen below:

```java
public class Book implements XML.Deserializable {
    public String title;
    public String price;

    public Book xmlDeserialize(Object obj)
    {
        title = (String) ((Map<String, Object>) objMap).get('title');
        price = (String) ((Map<String, Object>) objMap).get('price');
        return this;
    }
}

Book book = (Book) XML.deserialize('<Book><title>Title ABC</title><price>23.00</price></Book>', Book.class);
```

### Self Keyword

When needing to serialize a text node with attributes, this is possible using a class with both the attributes and self variables.
In the example below, we are creating part of an html table. Here we call the embed attribute method and set self as an Object, however, this can be any type.

```java
class TableRow {
  List<TableCell> td = new List<TableCell>{new TableCell(123), new TableCell('abc')};
}

class TableCell {
  Map<String, Object> attributes = new Map<String, Object>{
    'style' => 'padding:0;'
  };
  Object self; 
  
  public TableCell(Object value) {
    this.self = value;
  }
}

String xmlString = XML.serialize(new TableRow()).setRootNodeName('tr').embedAttributes().beautify().toString();
System.debug(xmlString);

```

The result is a table row containing cells with attributes.

```xml
<tr>
  <td style="padding:0;">123</td>
  <td style="padding:0;">abc</td>
</tr>
```

### Node Name Sanatization

There are a lot of requirements when it comes to handling XML encoding both within the names and values themselves. In the example of node names, these cannot start with a number. To prevent errors, keys starting with numbers are automatically prefixed with an underscore.

```apex
String xmlString = XML.serialize(new Map<String, String>{
  '12345' => 'value'
}).beautify().toString();
```

```xml
<element>
  <_12345>value</_12345>
</element>
```

### Value Encoding

In addition to node name sanitization, text values containing special characters are required to be encoded.

Please see an example of this working:

```java
String xmlString = XML.serialize(new Map<String, String>{
  'key' => '<value&'
}).beautify().toString();
```

```xml
<element>
  <key>&_lt;value&_amp;</key>
</element>
```

## Limitations

Unfortunately, Apex does not fully support class reflection. This limits the ability to abstract and support additional functionality that would otherwise be possible in other languages. However, as updates are being made the time, the library will be updated accordingly.

## Contributing

If you would like to extend or make changes to the library, it would be great to share it with others.
Just make sure that any changes follow the current formatting standards, are covered under unit tested and are well documented.

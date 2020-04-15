# SFDC XML Parser

Built Status: 
![coverage](https://img.shields.io/badge/coverage-100%25-yellowgreen)
![build](https://img.shields.io/badge/build-passing-success)
[![Maintainability](https://api.codeclimate.com/v1/badges/7dbda30d4ea9ddf96974/maintainability)](https://codeclimate.com/github/zabroseric/sfdc-xml-parser/maintainability)

![sfdc package](https://img.shields.io/badge/sfdc%20package-47.0-blue)
[![GitHub license](https://img.shields.io/github/license/zabroseric/sfdc-xml-parser.svg)](https://github.com/zabroseric/sfdc-xml-parser/blob/master/LICENSE)

| Deploy to SFDX Scratch Org | Deploy to Salesforce Org |
|:---:| :---: |
| [![Deploy](https://deploy-to-sfdx.com/dist/assets/images/DeployToSFDX.svg)](https://deploy-to-sfdx.com) | [![Deploy](https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png)](https://githubsfdeploy.herokuapp.com/?owner=zabroseric&repo=sfdc-xml-parser&ref=master) |

## Overview
When working with Apex there are often limitations that you would often expect to be resolved with larger frameworks. One of which is the ability to easily work with various APIs using XML. Although JSON is a defacto standard these days for web integration, it can be difficult to sole rely on this, especially when integrating with older or larger ERP systems. In an effort to fill this gap in functionality, the xml parser library provides conversion between objects, sobjects and primitive types back-and-fourth to XML. The intention is to provide easy parsing of XML, without manually mapping from XML or writing to XML nodes directly.

## Features
* Function Chaining
* SObject Tag Detection
* Serialise / Deserialize Apex Objects
* Tag and Value Sanitization

## Usage
The methods below show examples of common cases when parsing xml, and how you may go around this. Check out the [Cool Stuff](#cool-stuff) area for details on various pieces of functionality that can be used to alter the xml characteristics.

### Serialization
#### SObject
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

#### SObject List
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

#### Objects
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

String xmlString = XML.serialize(libraryObject).setRootTag('library').beautify().toString();
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

#### Maps
Optionally, we're able to specify the default root and element.
If one isn't specified the default is: <elements><element></element></elements>
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

### Deserialization
#### SObject
```java
Contact contact = (Contact) XML.deserialize('<Contact><attributes><type>Contact</type><url>/services/data/v48.0/sobjects/Contact/0032w000005DrR2AAK</url></attributes><FirstName>First</FirstName><LastName>Last</LastName><Id>0032w000005DrR2AAK</Id></Contact>')
    .setType(Contact.class).toObject();
```

#### SObject List
```java
List<Contact> contactResult = (List<Contact>) XML.deserialize('<Contacts><Contact><attributes><type>Contact</type><url>/services/data/v48.0/sobjects/Contact/0032w000005DrQxAAK</url></attributes><FirstName>First1</FirstName><LastName>Last1</LastName><Id>0032w000005DrQxAAK</Id></Contact><Contact><attributes><type>Contact</type><url>/services/data/v48.0/sobjects/Contact/0032w000005DrQyAAK</url></attributes><FirstName>First2</FirstName><LastName>Last2</LastName><Id>0032w000005DrQyAAK</Id></Contact></Contacts>')
    .setType(List<Contact>.class).toObject();
```

#### Objects
```java
Library library = XML.deserialize('<library><catalog><books><book><title>title1</title><price>23.00</price><authors><author>Name1</author><author>Name2</author></authors></book><book><title>title1</title><price>23.00</price><authors><author>Name3</author><author>Name4</author></authors></book></books></catalog></library>', Library.class)
    .toObject();
```

#### Maps
```java
Map<String, Object> objectMap = (Map<String, Object>) XML.deserialize('<elements><key2>val2</key2><key1>val1</key1></elements>')
    .setArrayNode('elements').toObject();
```

## <a name="cool-stuff"></a> Other Cool Stuff
#### Array Nodes
As true reflection is not support in Apex, there is no way to detect if an xml tag should truly be an array or a map. As a solution, we can specify what tags should be treated as an array when deserialized.

The below gives an example of a library, where the books tag will not be treated as an array as there is only one child element.
```xml
<library>
    <catalog>
        <books>
            <book>
                <title>title5</title>
                <price />
                <authors />
            </book>
        </books>
    </catalog>
</library>
```

If we specify the array nodes, the deserialization will work as required.
```java
Library library = (Library) XML.deserialize('<library><catalog><books><book><title>title5</title><price /><authors /></book></books></catalog></library>', Library.class)
        .setArrayNodes(new Set<String>{'book'}).toObject();
```


#### Debugging
Debugging can become a bit of a pain. We have the option of using checkpoints, debug logs and various other tools to help. In addition to this process, we can debug the serialized xml at any point before or after altering any settings using function chaining.

Using both the beautifying and encoding methods above we can achieve the following:

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

#### Suppressing Nulls
We needing to suppress empty tags, this doesn't just operate within the current tag but is able to work up the dom tree. In the example with the library, if we have a book that has no information in it, even if an empty object is assigned, the book will not be present within the xml.

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

XML.serialize(library).suppressNulls().setRootTag('library').beautify().debug();
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
            <title>title5</title>
         </book>
      </books>
   </catalog>
</library>
```

#### Clark Notations
Although the library does not work heavily off clark notations when writing xml, it does support the ability of specifying both the xml namespace and 'localname'.
For more information please see the link [here](http://www.jclark.com/xml/xmlns.htm).

An example of this can be seen below:
```java
XML.serialize(new List<Object>{
    new Map<String, String>{
        '{http://example.org}localname1' => 'val1',
        '{http://example.org}localname2' => 'val2'
    }
}).setNamespace('http://example.org', 'b').beautify().debug();
```

The result gets transformed to valid xml:
```xml
<element xmlns:b="http://example.org">
   <b:localname2>val2</b:localname2>
   <b:localname1>val1</b:localname1>
</element>
```

## To-Do List
* Array nodes can't be specified with their a full path name
* Custom element parsers
* Namespace filtering
* Deserialization interfaces

## Contributing
If you find that you need to extend the library and this would be great for others to have this, feel free to contribute!
Just make sure that any changes follow the current formatting standards, covered under unit tested and this is documented well.

After all it's all about helping each other out. :)
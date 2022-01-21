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
@IsTest
private class XMLTest {

    /*
    ---------------------------------------------
    -- SObject Tests
    ---------------------------------------------
     */
    @IsTest
    private static void serializeSObjectNullEntry()
    {
        Contact contact = new Contact(
            Id = null,
            FirstName = 'First',
            LastName = 'Last'
        );
        String xmlString = XML.serialize(contact).toString();
        System.assertEquals('<Contact><attributes><type>Contact</type></attributes><Id /><FirstName>First</FirstName><LastName>Last</LastName></Contact>', xmlString);
    }

    @IsTest
    private static void serializeSObject()
    {
        Contact contact = new Contact(
            FirstName = 'First',
            LastName = 'Last'
        );
        String xmlString = XML.serialize(contact).toString();
        System.assertEquals('<Contact><attributes><type>Contact</type></attributes><FirstName>First</FirstName><LastName>Last</LastName></Contact>', xmlString);
    }

    @IsTest
    private static void serializeSObjectRootTag()
    {
        Contact contact = new Contact(
          FirstName = 'First',
          LastName = 'Last'
        );
        String xmlString = XML.serialize(contact).setRootTag('NewTag').toString();
        System.assertEquals('<NewTag><attributes><type>Contact</type></attributes><FirstName>First</FirstName><LastName>Last</LastName></NewTag>', xmlString);
    }

    @IsTest
    private static void serializeSObjectRootAttributes()
    {
        Contact contact = new Contact(
          FirstName = 'First',
          LastName = 'Last'
        );
        String xmlString = XML.serialize(contact).addRootAttribute('key1', 'value1').addRootAttribute('key2', 'value2').toString();
        System.assertEquals('<Contact><attributes><type>Contact</type><key1>value1</key1><key2>value2</key2></attributes><FirstName>First</FirstName><LastName>Last</LastName></Contact>', xmlString);
    }

    @IsTest
    private static void serializeSObjects()
    {
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

        String xmlString = XML.serialize(contacts).toString();
        System.assertEquals('<Contacts><Contact><attributes><type>Contact</type></attributes><FirstName>First1</FirstName><LastName>Last1</LastName></Contact><Contact><attributes><type>Contact</type></attributes><FirstName>First2</FirstName><LastName>Last2</LastName></Contact></Contacts>', xmlString);
    }

    @IsTest
    private static void serializeSObjectsRootTag()
    {
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

        String xmlString = XML.serialize(contacts).setRootTag('NewTag').toString();
        System.assertEquals('<NewTag><element><attributes><type>Contact</type></attributes><FirstName>First1</FirstName><LastName>Last1</LastName></element><element><attributes><type>Contact</type></attributes><FirstName>First2</FirstName><LastName>Last2</LastName></element></NewTag>', xmlString);
    }

    @IsTest
    private static void serializeSObjectsRootAttributes()
    {
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

        String xmlString = XML.serialize(contacts).addRootAttribute('key1', 'value1').addRootAttribute('key2', 'value2').toString();
        System.assertEquals('<Contacts><Contact><attributes><type>Contact</type></attributes><FirstName>First1</FirstName><LastName>Last1</LastName></Contact><Contact><attributes><type>Contact</type></attributes><FirstName>First2</FirstName><LastName>Last2</LastName></Contact><attributes><key1>value1</key1><key2>value2</key2></attributes></Contacts>', xmlString);
    }

    @IsTest
    private static void serializeSObjectMap()
    {
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
        Id contactId1 = contacts.get(1).Id;
        Id contactId2 = contacts.get(0).Id;

        String xmlString = XML.serialize(new Map<Id, Contact>(contacts)).toString();
        System.assertEquals('<Contacts><_' + contactId1 + '><attributes><type>Contact</type><url>/services/data//sobjects/Contact/' + contactId1 + '</url></attributes><FirstName>First2</FirstName><LastName>Last2</LastName><Id>' + contactId1 + '</Id></_' + contactId1 + '><_' + contactId2 + '><attributes><type>Contact</type><url>/services/data//sobjects/Contact/' + contactId2 + '</url></attributes><FirstName>First1</FirstName><LastName>Last1</LastName><Id>' + contactId2 + '</Id></_' + contactId2 + '></Contacts>', xmlString.replaceAll('v[0-9]{2}\\.[0-9]', ''));
    }

    @IsTest
    private static void serializeSObjectMapStringId()
    {
        Id contactId1 = '0032w000004p2AbAAI';
        Id contactId2 = '0032w000004p2AbAAJ';

        List<Contact> contacts = new List<Contact>{
            new Contact(
                FirstName = 'First1',
                LastName = 'Last1',
                Id = contactId2
            ),
            new Contact(
                FirstName = 'First2',
                LastName = 'Last2',
                Id = contactId1
            )
        };

        String xmlString = XML.serialize(new Map<Id, Contact>(contacts)).toString();
        System.assertEquals('<Contacts><_' + contactId1 + '><attributes><type>Contact</type><url>/services/data//sobjects/Contact/' + contactId1 + '</url></attributes><FirstName>First2</FirstName><LastName>Last2</LastName><Id>' + contactId1 + '</Id></_' + contactId1 + '><_' + contactId2 + '><attributes><type>Contact</type><url>/services/data//sobjects/Contact/' + contactId2 + '</url></attributes><FirstName>First1</FirstName><LastName>Last1</LastName><Id>' + contactId2 + '</Id></_' + contactId2 + '></Contacts>', xmlString.replaceAll('v[0-9]{2}\\.[0-9]', ''));
    }

    @IsTest
    private static void serializeSObjectBase64()
    {
        Contact contact = new Contact(
            FirstName = 'First',
            LastName = 'Last'
        );

        String xmlString = XML.serialize(contact).toBase64();
        System.assertEquals('PENvbnRhY3Q+PGF0dHJpYnV0ZXM+PHR5cGU+Q29udGFjdDwvdHlwZT48L2F0dHJpYnV0ZXM+PEZpcnN0TmFtZT5GaXJzdDwvRmlyc3ROYW1lPjxMYXN0TmFtZT5MYXN0PC9MYXN0TmFtZT48L0NvbnRhY3Q+', xmlString);
    }

    @IsTest
    private static void serializeSObjectAttributesEmbedded()
    {
        Contact contact = new Contact(
            FirstName = 'First',
            LastName = 'Last'
        );

        String xmlString = XML.serialize(contact).embedAttributes().toString();
        System.assertEquals('<Contact type="Contact"><FirstName>First</FirstName><LastName>Last</LastName></Contact>', xmlString);
    }

    @IsTest
    private static void serializeSObjectsAttributesEmbedded()
    {
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
        Id contactId1 = contacts.get(0).Id;
        Id contactId2 = contacts.get(1).Id;

        String xmlString = XML.serialize(contacts).embedAttributes().toString();
        System.assertEquals('<Contacts><Contact type="Contact" url="/services/data//sobjects/Contact/' + contactId1 + '"><FirstName>First1</FirstName><LastName>Last1</LastName><Id>' + contactId1 + '</Id></Contact><Contact type="Contact" url="/services/data//sobjects/Contact/' + contactId2 + '"><FirstName>First2</FirstName><LastName>Last2</LastName><Id>' + contactId2 + '</Id></Contact></Contacts>', xmlString.replaceAll('v[0-9]{2}\\.[0-9]', ''));
    }

    @IsTest
    private static void serializeEmptyContactList()
    {
        String xmlString = XML.serialize(new List<Contact>()).toString();
        System.assertEquals('<Contacts></Contacts>', xmlString);
    }

    @IsTest
    private static void deserializeSObjectNullEntry()
    {
        Contact contact = new Contact(
            Id = null,
            FirstName = 'First',
            LastName = 'Last'
        );
        Contact contactResult = (Contact) XML.deserialize(XML.serialize(contact).toString()).setType(Contact.class).toObject();
        System.assertEquals(contact, contactResult);
    }

    @IsTest
    private static void deserializeReservedWordStandard()
    {
        SpecialBookDateTime_x specialBook = (SpecialBookDateTime_x) XML.deserialize(
        '<SpecialBookDateTime_x><Date>2019-01-28</Date><Time>11:00:09Z</Time></SpecialBookDateTime_x>'
        ).setType(SpecialBookDateTime_x.class).toObject();

        System.assertEquals(Date.newInstance(2019, 1, 28), specialBook.date_x);
        System.assertEquals(Time.newInstance(11, 0, 9, 0), specialBook.time_x);
    }

    @IsTest
    private static void deserializeReservedWordCustom()
    {
        SpecialBookDateTime_AnotherSuffix specialBook = (SpecialBookDateTime_AnotherSuffix) XML.deserialize(
        '<SpecialBookDateTime_AnotherSuffix><Date>2019-01-28</Date><Time>11:00:09Z</Time></SpecialBookDateTime_AnotherSuffix>'
        ).setType(SpecialBookDateTime_AnotherSuffix.class).setReservedWordSuffix('_AnotherSuffix').toObject();

        System.assertEquals(Date.newInstance(2019, 1, 28), specialBook.date_AnotherSuffix);
        System.assertEquals(Time.newInstance(11, 0, 9, 0), specialBook.time_AnotherSuffix);
    }

    @IsTest
    private static void deserializeSObject()
    {
        Contact contact = new Contact(
            FirstName = 'First',
            LastName = 'Last'
        );
        Contact contactResult = (Contact) XML.deserialize(XML.serialize(contact).toString()).setType(Contact.class).toObject();
        System.assertEquals(contact, contactResult);
    }

    @IsTest
    private static void deserializeSObjects()
    {
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

        List<Contact> contactResult = (List<Contact>) XML.deserialize(XML.serialize(contacts).toString()).setType(List<Contact>.class).toObject();
        System.assertEquals(contacts, contactResult);
    }
    @IsTest
    private static void deserializeSObjectWithIds()
    {
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

        List<Contact> contactResult = (List<Contact>) XML.deserialize(XML.serialize(contacts).toString()).setType(List<Contact>.class).toObject();
        System.assertEquals(contacts, contactResult);
    }

    /*
    ---------------------------------------------
    -- Generic Tests
    ---------------------------------------------
     */
    @IsTest
    private static void serializeEmptyString()
    {
        String xmlString = XML.serialize('').toString();
        System.assertEquals('<elements></elements>', xmlString);
    }

    @IsTest
    private static void serializeEmptyStringShowNulls()
    {
        String xmlString = XML.serialize('').showNulls().toString();
        System.assertEquals('<elements></elements>', xmlString);
    }

    @IsTest
    private static void serializeEmptyStringSuppressNulls()
    {
        String xmlString = XML.serialize('').suppressNulls().toString();
        System.assertEquals('<elements />', xmlString);
    }

    @IsTest
    private static void serializeNull()
    {
        String xmlString = XML.serialize(null).toString();
        System.assertEquals('<elements></elements>', xmlString);
    }

    @IsTest
    private static void serializeNullSuppressNulls()
    {
        String xmlString = XML.serialize(null).suppressNulls().toString();
        System.assertEquals('<elements />', xmlString);
    }

    @IsTest
    private static void serializeEmptyList()
    {
        String xmlString = XML.serialize(new List<String>()).toString();
        System.assertEquals('<elements></elements>', xmlString);
    }

    @IsTest
    private static void serializeEmptyListSuppressNulls()
    {
        String xmlString = XML.serialize(new List<String>()).suppressNulls().toString();
        System.assertEquals('<elements />', xmlString);
    }

    @IsTest
    private static void serializeChangeRootTag()
    {
        String xmlString = XML.serialize(new List<String>()).setRootTag('None').toString();
        System.assertEquals('<None></None>', xmlString);
    }

    @IsTest
    private static void serializeChangeRootTagSuppressNulls()
    {
        String xmlString = XML.serialize(new List<String>()).suppressNulls().setRootTag('None').toString();
        System.assertEquals('<None />', xmlString);
    }

    @IsTest
    private static void serializeSetXMLHeaderAttributes()
    {
        String xmlString = XML.serialize(new List<String>()).addRootAttribute('Attr', 'No Attributes').embedAttributes().toString();
        System.assertEquals('<elements Attr="No Attributes"></elements>', xmlString);
    }

    @IsTest
    private static void serializeSetXMLHeaderAttributesSuppressNulls()
    {
        String xmlString = XML.serialize(new List<String>()).embedAttributes().setRootAttributes(new Map<String, String>{'Attr' => 'No Attributes'}).suppressNulls().toString();
        System.assertEquals('<elements Attr="No Attributes" />', xmlString);
    }

    @IsTest
    private static void serializeShowEncoding()
    {
        String xmlString = XML.serialize(new List<String>()).showEncoding().toString();
        System.assertEquals('<?xml version="1.0" encoding="UTF-8"?><elements></elements>', xmlString);
    }

    @IsTest
    private static void serializeHideEncoding()
    {
        String xmlString = XML.serialize(new List<String>()).hideEncoding().toString();
        System.assertEquals('<elements></elements>', xmlString);
    }

    @IsTest
    private static void serializeShowEncodingOneElement()
    {
        String xmlString = XML.serialize(new List<String>{'a'}).showEncoding().toString();
        System.assertEquals('<?xml version="1.0" encoding="UTF-8"?><element>a</element>', xmlString);
    }

    @IsTest
    private static void serializeMapElementsTag()
    {
        String xmlString = XML.serialize(new Map<String, String>{
            'key1' => 'val1',
            'key2' => 'val2'
        }).toString();
        System.assertEquals('<elements><key2>val2</key2><key1>val1</key1></elements>', xmlString);
    }

    @IsTest
    private static void serializeMapElementTag()
    {
        String xmlString = XML.serialize(new Map<String, String>{
            'key1' => 'val1'
        }).toString();
        System.assertEquals('<element><key1>val1</key1></element>', xmlString);
    }

    @IsTest
    private static void deserializeEmptyNewLine()
    {
        Object obj = XML.deserialize('<element>\r\n</element>').toObject();
        System.assertEquals(new Map<String, String>{'element' => null}, obj);
    }

    @IsTest
    private static void deserializeOneElement()
    {
        Object obj = XML.deserialize('<element>a</element>').toObject();
        System.assertEquals(new Map<String, String>{'element' => 'a'}, obj);
    }

    @IsTest
    private static void deserializeSpecialCharacters()
    {
        Object obj = XML.deserialize('<element>&lt;&gt;</element>').toObject();
        System.assertEquals(new Map<String, String>{'element' => '<>'}, obj);
    }

    @IsTest
    private static void deserializeEmptyList()
    {
        Object obj = XML.deserialize('<elements></elements>').toObject();
        System.assertEquals(new Map<String, String>{'elements' => null}, obj);
    }

    @IsTest
    private static void deserializeEmptyListArrayNode()
    {
        Object obj = XML.deserialize('<elements></elements>').addArrayNode('elements').toObject();
        System.assertEquals(new Map<String, Object>{'elements' => new List<String>{null}}, obj);
    }

    @IsTest
    private static void deserializeEmptyListArrayNodeChild()
    {
        Object obj = XML.deserialize('<elements><element></element></elements>').addArrayNode('element').toObject();
        System.assertEquals(new Map<String, Object>{'elements' => new Map<String, Object>{'element' => new List<String>{null}}}, obj);
    }

    @IsTest
    private static void deserializeEmptyListArrayNodes()
    {
        Object obj = XML.deserialize('<elements><element>123</element></elements>').setArrayNodes(new Set<String>{'element', 'elements'}).toObject();
        System.assertEquals(new Map<String, Object>{'elements' => new List<Object>{new Map<String, Object>{'element' => new List<String>{'123'}}}}, obj);
    }

    @IsTest
    private static void deserializeEmptyListClose()
    {
        Object obj = XML.deserialize('<elements />').toObject();
        System.assertEquals(new Map<String, String>{'elements' => null}, obj);
    }

    @IsTest
    private static void deserializeNull()
    {
        try {
            Object obj = XML.deserialize(null).toObject();
            throw new XmlException('Error not thrown.');
        }
        catch (Exception e) {
            System.assertEquals('The XML string is invalid, value: null', e.getMessage());
        }
    }

    @IsTest
    private static void deserializeEmptyString()
    {
        try {
            Object obj = XML.deserialize('').toObject();
            throw new XmlException('Error not thrown.');
        }
        catch (Exception e) {
            System.assertEquals('The XML string is invalid, value: ', e.getMessage());
        }
    }

    @IsTest
    private static void deserializeInvalid()
    {
        try {
            Object obj = XML.deserialize('invalid').toObject();
            throw new XmlException('Error not thrown.');
        }
        catch (Exception e) {
            System.assertEquals('The XML string is invalid, value: invalid', e.getMessage());
        }
    }

    /*
    ---------------------------------------------
    -- Debugging
    ---------------------------------------------
     */
    @IsTest
    private static void serializeToFormattedStringList()
    {
        String xmlString = XML.serialize(new List<String>{
            'a',
            'b'
        }).beautify().toString();
        System.assertEquals('<elements>\r\n  <element>a</element>\r\n  <element>b</element>\r\n</elements>', xmlString);
    }

    @IsTest
    private static void serializeToStringMinifiedList()
    {
        String xmlString = XML.serialize(new List<String>{
            'a',
            'b'
        }).minify().toString();
        System.assertEquals('<elements><element>a</element><element>b</element></elements>', xmlString);
    }

    @IsTest
    private static void serializeToFormattedStringListMap()
    {
        String xmlString = XML.serialize(new List<Object>{
            new Map<String, String>{
                'a' => 'b',
                'c' => 'd'
            }
        }).beautify().toString();
        System.assertEquals('<element>\r\n  <c>d</c>\r\n  <a>b</a>\r\n</element>', xmlString);
    }

    @IsTest
    private static void serializeNamespace()
    {
        String xmlString = XML.serialize(new List<Object>{
            new Map<String, String>{
                '{http://example.org}a' => 'b',
                '{http://example.org}c' => 'd'
            }
        }).addNamespace('http://example.org', 'b').toString();
        System.assertEquals('<element xmlns:b="http://example.org"><b:c>d</b:c><b:a>b</b:a></element>', xmlString);
    }

    @IsTest
    private static void serializeNamespaces()
    {
        String xmlString = XML.serialize(new List<Object>{
            new Map<String, String>{
                '{http://example1.org}a' => 'b',
                '{http://example2.org}c' => 'd'
            }
        }).setNamespaces(new Map<String, String>{'http://example1.org' => 'p1', 'http://example2.org' => 'p2'}).toString();
        System.assertEquals('<element xmlns:p1="http://example1.org" xmlns:p2="http://example2.org"><p2:c>d</p2:c><p1:a>b</p1:a></element>', xmlString);
    }

    @IsTest
    private static void serializeNamespacesNotFound()
    {
        String xmlString = XML.serialize(new List<Object>{
            new Map<String, String>{
                '{http://example1.org}a' => 'b'
            }
        }).setNamespaces(new Map<String, String>{'http://example2.org' => 'p2'}).toString();
        System.assertEquals('<element xmlns:p2="http://example2.org"><a>b</a></element>', xmlString);
    }

    @IsTest
    private static void serializeToFormattedStringListMapEncoding()
    {
        String xmlString = XML.serialize(new List<Object>{
            new Map<String, String>{
                'a' => 'b',
                'c' => 'd'
            }
        }).showEncoding().beautify().toString();
        System.assertEquals('<?xml version="1.0" encoding="UTF-8"?>\r\n<element>\r\n  <c>d</c>\r\n  <a>b</a>\r\n</element>', xmlString);
    }

    @IsTest
    private static void serializeToFormattedStringString()
    {
        String xmlString = XML.serialize('abc').beautify().toString();
        System.assertEquals('<elements>abc</elements>', xmlString);
    }

    @IsTest
    private static void serializeDebug()
    {
        XML.serialize('abc').debug().beautify().debug();
    }

    @IsTest
    private static void serializeDeserializeHideNamespaces()
    {
        String xmlString = XML.serialize(new List<Object>{
            new Map<String, String>{
                '{http://example1.org}a' => 'b',
                '{http://example2.org}c' => 'd'
            }
        }).setNamespaces(new Map<String, String>{'http://example1.org' => 'p1', 'http://example2.org' => 'p2'}).toString();

        System.assertEquals(new Map<String, Object>{
            'element' => new Map<String, String>{
                'a' => 'b',
                'c' => 'd'
            }
        }, XML.deserialize(xmlString).hideNamespaces().toObject());
    }

    @IsTest
    private static void serializeDeserializeShowNamespaces()
    {
        String xmlString = XML.serialize(new List<Object>{
            new Map<String, String>{
                '{http://example1.org}a' => 'b',
                '{http://example2.org}c' => 'd'
            }
        }).setNamespaces(new Map<String, String>{'http://example1.org' => 'p1', 'http://example2.org' => 'p2'}).toString();

        System.assertEquals(new Map<String, Object>{
            'element' => new Map<String, String>{
                '{http://example1.org}a' => 'b',
                '{http://example2.org}c' => 'd'
            }
        }, XML.deserialize(xmlString).showNamespaces().toObject());
    }

    @IsTest
    private static void serializeDeserializeFilterNamespaces()
    {
        String xmlString = XML.serialize(new List<Object>{
            new Map<String, String>{
                '{http://example1.org}a' => 'b',
                '{http://example2.org}c' => 'd',
                'e' => 'f'
            }
        }).setNamespaces(new Map<String, String>{'http://example1.org' => 'p1', 'http://example2.org' => 'p2'}).toString();

        System.assertEquals(new Map<String, Object>{
            'element' => new Map<String, String>{
                '{http://example1.org}a' => 'b',
                'e' => 'f'
            }
        }, XML.deserialize(xmlString).filterNamespace('http://example1.org').toObject());
    }

    @IsTest
    private static void deserializeDebug()
    {
        XML.deserialize('<elements>abc</elements>').debug();
    }

    /*
    ---------------------------------------------
    -- Object Tests
    ---------------------------------------------
     */
    @IsTest
    public static void serializeObject()
    {
        Library library = new Library(
            new Catalog(
                new Books(
                    new List<Book>{
                        new Book('title1', new Authors(new List<String>{'Name1', 'Name2'}), '23.00'),
                        new Book('title2', new Authors(new List<String>{'Name3'}), '23.00'),
                        new Book('title5', new Authors(new List<String>{}), null)
                    }
                )
            )
        );

        String xmlString = XML.serialize(library).setRootTag('library').toString();
        System.assertEquals('<library><catalog><books><book><title>title1</title><price>23.00</price><authors><author>Name1</author><author>Name2</author></authors></book><book><title>title2</title><price>23.00</price><authors><author>Name3</author></authors></book><book><title>title5</title><price /><authors><author /></authors></book></books></catalog></library>', xmlString);
    }

    @IsTest
    public static void serializeObjectSuppressNulls()
    {
        Library library = new Library(
            new Catalog(
                new Books(
                    new List<Book>{
                        new Book('title1', new Authors(new List<String>{'Name1', 'Name2'}), '23.00'),
                        new Book('title2', new Authors(new List<String>{'Name3'}), '23.00'),
                        new Book('title5', new Authors(new List<String>{}), null)
                    }
                )
            )
        );

        String xmlString = XML.serialize(library).suppressNulls().setRootTag('library').toString();
        System.assertEquals('<library><catalog><books><book><title>title1</title><price>23.00</price><authors><author>Name1</author><author>Name2</author></authors></book><book><title>title2</title><price>23.00</price><authors><author>Name3</author></authors></book><book><title>title5</title></book></books></catalog></library>', xmlString);
    }

    @IsTest
    public static void serializeObjectChangeRoot()
    {
        Library library = new Library(
            new Catalog(
                new Books(
                    new List<Book>{
                        new Book('title1', new Authors(new List<String>{'Name1', 'Name2'}), '23.00'),
                        new Book('title2', new Authors(new List<String>{'Name3'}), '23.00'),
                        new Book('title5', new Authors(new List<String>{}), null)
                    }
                )
            )
        );

        String xmlString = XML.serialize(library).setRootTag('library').toString();
        System.assertEquals('<library><catalog><books><book><title>title1</title><price>23.00</price><authors><author>Name1</author><author>Name2</author></authors></book><book><title>title2</title><price>23.00</price><authors><author>Name3</author></authors></book><book><title>title5</title><price /><authors><author /></authors></book></books></catalog></library>', xmlString);
    }

    @IsTest
    public static void serializeDeserializeObject()
    {
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

        String xmlString = XML.serialize(libraryObject).setRootTag('Library').toString();
        System.assertEquals(String.valueOf(libraryObject), String.valueOf(XML.deserialize(xmlString, Library.class).toObject()));
    }

    @IsTest
    public static void serializeDeserializeObjectArrayNode()
    {
        Library libraryObject = new Library(
            new Catalog(
                new Books(
                    new List<Book>{
                        new Book('title1', new Authors(new List<String>{'Name1', 'Name2'}), '23.00'),
                        new Book('title2', new Authors(new List<String>{'Name3'}), '23.00'),
                        new Book('title5', null, null)
                    }
                )
            )
        );

        String xmlString = XML.serialize(libraryObject).setRootTag('Library').toString();
        System.assertEquals(String.valueOf(libraryObject),
            String.valueOf(XML.deserialize(xmlString, Library.class)
            .addArrayNode('author').toObject())
        );
    }

    @IsTest
    public static void serializeDeserializeObjectArrayNodes()
    {
        Library libraryObject = new Library(
            new Catalog(
                new Books(
                    new List<Book>{
                        new Book('title5', null, null)
                    }
                )
            )
        );

        String xmlString = XML.serialize(libraryObject).setRootTag('Library').toString();
        System.assertEquals(String.valueOf(libraryObject),
            String.valueOf(XML.deserialize(xmlString, Library.class)
            .setArrayNodes(new Set<String>{'author','book'}).toObject())
        );
    }

    @IsTest
    public static void serializeDeserializerBook()
    {
        Book bk = new Book('title5', null, '23.00');

        String xmlString = XML.serialize(bk).setRootTag('Book').toString();
        System.assertEquals(String.valueOf(bk),
            String.valueOf(XML.deserialize(xmlString, Book.class))
        );
    }

    @IsTest
    public static void serializeDeserializerBookUnknownRoot()
    {
        Book bk = new Book('title5', null, '23.00');

        String xmlString = XML.serialize(bk).setRootTag('Unknown').toString();
        System.assertEquals(String.valueOf(new Book()),
            String.valueOf(XML.deserialize(xmlString, Book.class))
        );
    }

    @IsTest
    public static void serializeDeserializerCatalogInvalid()
    {
        System.assertEquals(String.valueOf(new Catalog()),
            String.valueOf(XML.deserialize('<unknown />', Catalog.class))
        );
    }

    @IsTest
    public static void deserializeObject()
    {
        Library library = (Library) XML.deserialize(
        '<library><catalog><books><book><title>title1</title><price>23.00</price><authors><author>Name1</author><author>Name2</author></authors></book><book><title>title2</title><price>23.00</price><authors><author>Name3</author><author>Name4</author></authors></book><book><title>title5</title><price /><authors><author /></authors></book></books></catalog></library>'
        ).setType(Library.class).toObject();

        System.assertEquals('title1', library.catalog.books.book[0].title);
        System.assertEquals(JSON.serialize(new Authors(new List<String>{'Name1', 'Name2'})), JSON.serialize(library.catalog.books.book[0].authors));
        System.assertEquals('23.00', library.catalog.books.book[0].price);

        System.assertEquals('title2', library.catalog.books.book[1].title);
        System.assertEquals(JSON.serialize(new Authors(new List<String>{'Name3', 'Name4'})), JSON.serialize(library.catalog.books.book[1].authors));
        System.assertEquals('23.00', library.catalog.books.book[1].price);
    }

    @IsTest
    public static void deserializeObjectArrayNodeError()
    {
        try {
            XML.deserialize(
            '<library><catalog><books><book><title>title1</title><price>23.00</price><authors><author>Name1</author><author>Name2</author></authors></book><book><title>title2</title><price>23.00</price><authors><author>Name4</author></authors></book><book><title>title5</title><price /><authors><author /></authors></book></books></catalog></library>'
            ).setType(Library.class).toObject();
            System.assert(false);
        } catch (XmlException e) {
            System.assertEquals('An array node has not been correctly set by value "Name4"', e.getMessage());
        }
    }

    @IsTest
    public static void serializeObjectNoAttributes()
    {
        Library library = new Library(
          new Catalog(
            new Books(
              new List<Book>{
                new Book('title1', new Authors(new List<String>{'Name1', 'Name2'}), '23.00'),
                new Book('title2', new Authors(new List<String>{'Name3'}), '23.00'),
                new Book('title5', new Authors(new List<String>{}), null)
              }
            )
          )
        );

        String xmlString = XML.serialize(library).setRootTag('library').embedAttributes().toString();
        System.assertEquals('<library><catalog><books><book><title>title1</title><price>23.00</price><authors><author>Name1</author><author>Name2</author></authors></book><book><title>title2</title><price>23.00</price><authors><author>Name3</author></authors></book><book><title>title5</title><price /><authors><author /></authors></book></books></catalog></library>', xmlString);
    }

    @IsTest
    public static void serializeObjectAttributes()
    {
        BookWithStringAttributes book = new BookWithStringAttributes();
        book.attributes.put('key1', 'value1');
        book.attributes.put('key2', 'value2');
        book.title = 'title';

        String xmlString = XML.serialize(book).setRootTag('book').embedAttributes().toString();
        System.assertEquals('<book key2="value2" key1="value1"><title>title</title></book>', xmlString);
    }

    @IsTest
    public static void serializeObjectAttributeNumbers()
    {
        BookWithIntegerAttributes book = new BookWithIntegerAttributes();
        book.attributes.put('key1', 12);
        book.attributes.put('key2', 23);
        book.title = 'title';

        String xmlString = XML.serialize(book).setRootTag('book').embedAttributes().toString();
        System.assertEquals('<book key2="23" key1="12"><title>title</title></book>', xmlString);
    }

    @IsTest
    public static void serializeObjectAttributeEmpty()
    {
        BookWithStringAttributes book = new BookWithStringAttributes();
        book.attributes.put('key1', null);
        book.title = 'title';

        String xmlString = XML.serialize(book).setRootTag('book').embedAttributes().toString();
        System.assertEquals('<book key1="null"><title>title</title></book>', xmlString);
    }

    @IsTest
    public static void serializeObjectAttributesWithRoot()
    {
        BookWithStringAttributes book = new BookWithStringAttributes();
        book.attributes.put('key1', 'value1');
        book.title = 'title';

        String xmlString = XML.serialize(book).setRootTag('book').addRootAttribute('key2', 'value2').embedAttributes().toString();
        System.assertEquals('<book key1="value1" key2="value2"><title>title</title></book>', xmlString);
    }

    @IsTest
    public static void serializeObjectAttributesWithRootOverride()
    {
        BookWithStringAttributes book = new BookWithStringAttributes();
        book.attributes.put('key1', 'value1');
        book.title = 'title';

        String xmlString = XML.serialize(book).setRootTag('book').addRootAttribute('key1', 'value2').embedAttributes().toString();
        System.assertEquals('<book key1="value2"><title>title</title></book>', xmlString);
    }

    @IsTest
    public static void serializeObjectAttributesWithRootOverrideSelf()
    {
        BookWithStringAttributesSelf book = new BookWithStringAttributesSelf();
        book.attributes.put('key1', 'value1');
        book.self = 'title';

        String xmlString = XML.serialize(book).setRootTag('book').addRootAttribute('key2', 'value2').embedAttributes().toString();
        System.assertEquals('<book key1="value1" key2="value2">title</book>', xmlString);
    }

    @IsTest
    public static void serializeObjectdAttributesSelf()
    {
        BookWithStringAttributesSelf book1 = new BookWithStringAttributesSelf();
        book1.attributes.put('key1', 'value1');
        book1.self = 'title1';

        BookWithStringAttributesSelf book2 = new BookWithStringAttributesSelf();
        book2.attributes.put('key2', 'value2');
        book2.self = 'title2';

        String xmlString = XML.serialize(new List<BookWithStringAttributesSelf>{book1, book2}).setRootTag('books').embedAttributes().toString();
        System.assertEquals('<books><element key1="value1">title1</element><element key2="value2">title2</element></books>', xmlString);
    }

    @IsTest
    public static void serializeObjectAttributesSelfInvalid()
    {
        try {
            BookWithStringAttributesSelfInvalid book = new BookWithStringAttributesSelfInvalid();
            book.attributes.put('key1', 'value1');
            book.self = 'title';
            book.abc = 'abc123';
            String xmlString = XML.serialize(book).setRootTag('book').toString();
            System.assert(false, 'Exception expected to be thrown: ' + xmlString);
        } catch (XmlException e) {
            System.assert(e.getMessage().contains('self keyword'));
        }
    }

    @IsTest
    public static void deserializeObjectAttributesNotEmbedded()
    {
        BookWithStringAttributes book = (BookWithStringAttributes) XML.deserialize('<BookWithStringAttributes key1="value1"><title>title</title></BookWithStringAttributes>').setType(BookWithStringAttributes.class).toObject();

        System.assertNotEquals(null, book.attributes);
        System.assertEquals('value1', book.attributes.get('key1'));
        System.assertEquals('title', book.title);
    }

    @IsTest
    public static void deserializeObjectAttributesEmbedded()
    {
        BookWithStringAttributes book = (BookWithStringAttributes) XML.deserialize('<BookWithStringAttributes><attributes><key1>value1</key1></attributes><title>title</title></BookWithStringAttributes>').setType(BookWithStringAttributes.class).toObject();

        System.assertNotEquals(null, book.attributes);
        System.assertEquals('value1', book.attributes.get('key1'));
        System.assertEquals('title', book.title);
    }

    @IsTest
    public static void deserializeObjectAttributesCombination()
    {
        BookWithStringAttributes book = (BookWithStringAttributes) XML.deserialize('<BookWithStringAttributes key1="value1"><attributes><key2>value2</key2></attributes><title>title</title></BookWithStringAttributes>').setType(BookWithStringAttributes.class).toObject();

        System.assertNotEquals(null, book.attributes);
        System.assertEquals('value1', book.attributes.get('key1'));
        System.assertEquals('value2', book.attributes.get('key2'));
        System.assertEquals('title', book.title);
    }

    private class Library {
        public Catalog catalog;

        public Library() {}

        public Library(Catalog catalog)
        {
            this.catalog = catalog;
        }
    }

    private class Catalog {
        public Books books;

        public Catalog() {}

        public Catalog(Books books)
        {
            this.books = books;
        }
    }

    private class Books {
        public List<Book> book;

        public Books() {}

        public Books(List<Book> book)
        {
            this.book = book;
        }
    }

    private class Book implements XML.Deserializable {
        public String title;
        public Authors authors;
        public String price;

        public Book() {}

        public Book(String title, Authors authors, String price)
        {
            this.title = title;
            this.authors = authors;
            this.price = price;
        }

        public Book xmlDeserialize(Object objMap)
        {
            title = (String) ((Map<String, Object>) objMap).get('title');
            price = (String) ((Map<String, Object>) objMap).get('price');
            return this;
        }
    }

    private class Authors {
        public List<String> author;

        public Authors() {}

        public Authors(List<String> author)
        {
            this.author = author;
        }
    }

    class SpecialBookDateTime_x {
        public Date date_x;
        public Time time_x;
    }

    class SpecialBookDateTime_AnotherSuffix {
        public Date date_AnotherSuffix;
        public Time time_AnotherSuffix;
    }

    class BookWithStringAttributes {
        public Map<String, String> attributes = new Map<String, String>();
        public String title;
    }

    class BookWithIntegerAttributes {
        public Map<String, Integer> attributes = new Map<String, Integer>();
        public String title;
    }

    class BookWithStringAttributesSelf {
        public Map<String, String> attributes = new Map<String, String>();
        public String self;
    }

    class BookWithStringAttributesSelfInvalid {
        public Map<String, String> attributes = new Map<String, String>();
        public String self;
        public String abc;
    }
}
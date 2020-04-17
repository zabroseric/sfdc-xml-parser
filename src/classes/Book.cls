/**
 * Created by shaun on 17/04/2020.
 */

public with sharing class Book implements XML.Deserializable {

    public Book xmlDeserialize(Object obj) {
        return new Book();
    }

}
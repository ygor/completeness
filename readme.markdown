Welcome to Completeness
==========================

Completeness allows you to define when a model instance is complete.

How do I use it?
----------------

First include the library in your class:

    include Completeness

If you want your model to only be regarded as complete if it has a title and a description, you can do the following:

    define_completeness do
        check :title
        check :description
    end

By default an attribute is regarded to be complete if it is present. If you would like to use a different condition, use the 
:with parameter. 

    define_completeness do
        check :title, :with => lambda {|attribute_value| attribute_value != 'test'}
    end

You can also use :if, and :unless conditions. For example:

    define completeness do
        check :title
        check :description, :unless => {|r| r.scribble? }
    end

You can also specify multiple named completeness groups

    define_completeness :profile do
        check :first_name
        check :last_name
    end

    define_completeness :account do
        check :email,
        check :password
    end

To query a model instance for completeness, use

    @record.complete?
    
Or, if you have multiple groups, i.e. :profile, :organisation and :account, use

    @record.complete? :account # check for account group completeness
    @record.complete?(:account, :profile) #check for completeness of groups :account and :profile
    @record.complete? #check for completeness of all groups

After a complete? call, the method incomplete_attributes holds an array of incomplete attribute names.

I have not included a scoring mechanism, but adding that would be fairly easy :P
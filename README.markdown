 Import
=========

Hopes to help you, should you need to import products into spree.

As data sources for products can be quite varied, and also the needs of importing/updating be quite personal, this is more of a first step for you.

Edit at will, contribute if possible.

Format
-------

The implementation assumes tab delimited columns. But as it uses fastercsv, you can change that easily to komma or anything else.

Also we assume headers from an external source, which can be mapped to the spree equivalent. You'll have to change the mapping in lib/import.rb , also the image folder needs to be changed.

Adapt
-----

Actually we invision that you create your own class which subclasses from import and change the rake task to instantiate that. Taxonomy, variant and property handling are so diverse as to make a general approach impossible.

As is you use rake db:import to invoke the import.

Contribute
----------

So if you have good ideas or even code to contribute, great.
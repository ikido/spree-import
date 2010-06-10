 Important Notice
-------

As I have used this and my shop is running I have no use for this code anymore:

This Repository will be deleted next week (15.6)
-------

 Import
-------
Hopes to help you, should you need to import products into spree.

As data sources for products can be quite varied, and also the needs of importing/updating be quite personal, this is more of a first step for you.

But it works (at least for me) with rake db:import

Edit at will, contribute if possible.

Base Directoy
-------------
All data for the import is assumed under vendor/import. We'll call it the base directory (change in lib/import.rb)

Mapping
-------
Import assumes you have data from somewhere else, with headers that do not match the spree headers. A mapping.yml is assumed to exist in the base direcory. The mapping is a hash from the headers you have (string) to the spree headers (symbol). The spree headers you need are the ones you want setting, corresponding to the spree product/variant fields.

- name
- description
- web_price		will be used as price if mapped
- price			otherwise :price will be used (one of the two is mandatory)
- sku			your unique identifier
- image			the filename must be found somewhere under the base dir
- option 		used as the option type for a product and an option value for a variant (see below on variants)
- quantity 		the spree on_hand 
- category1 		category 1-3 can be used to set a 3 level category. If that doesn't fit your needs, override set_category 
- weight 		rest are self explanitory
- depth
- width
- height

Files
-----
All .txt files in the base directory will be loaded. 

The implementation assumes tab delimited columns. But as it uses fastercsv, you can change that easily to komma or anything else.

Images can anywhere under the base directory

Adapt
-----
This is meant as a starting point, though hopefully it should be easy to adapt.

The is a somewhat document MyImport class in lib/ which you can change to your needs.

Contribute
----------

So if you have good ideas or even code to contribute, great.

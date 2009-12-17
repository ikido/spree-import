# A MyImpport will be instantiated
# 
# add any functions that are specific to your project here
#

class MyImport < Import
# change to true if you want existing products to be cleared out (for developemnt)
 def remove_products?
   false
 end
 
  #override if you have your categories encoded in one field or in any other way
  def get_categories(row)
    super # return an array of strings
  end

  # this sets the taxon (category) on the product. row is an array of strings
  def set_taxonomy(product , row)  super end

  #can be overwritten, we just use the sku   return a product from the db or create a new
  def get_product( row ) super end

  # sets common attributes to product & variant 
  # call super to do the grunt work and add sprecifics
  def set_attributes_and_image( prod , row ) super end

  # just grab the :sku mapped attribute
  def set_sku(prod , row) super end
  
  # set weight, and height/width / depth
  def set_weight(prod , row) super end
  def set_dimensions(prod, row) super end

 # sets the availibility to yesterday (immideately available)
  def set_available(prod , row) super  end
  
  # use :web_price or :price mapped attribute
  def set_price(prod, row) super  end

  # adds a image from the :image attribute. For variants adds the image to the product too
  def add_image(prod , row ) super end
    
  # given the last product name, determine if the line at index is a variant
  # here a variants name starts with the product name, so we check for that 
  def is_line_variant?(name , index) super end

  # read all variants of the product (using is_line_variant? above)
  # uses the :option (mapped) attribute of the product row to find/create an OptionType
  # and the same :option attribute to create OptionValues on the Variants 
  def slurp_variants(prod , index) super end

  #make sure there is an admin user
  def check_admin_user(password="spree", email="spree@spreecommerce.com") super end     
  

end

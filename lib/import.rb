
require "fastercsv"

require 'active_support'
require 'action_controller'
require 'action_controller/test_process'
require 'app/models/product'

class Import
  
    def initialize()
      #Images are here
      @dir = "/Users/torsten/Desktop/Kaupaan/"
      
      # one root taxonomy
      @taxonomy = "Kategoriat"
      
      # assuming you have data from another software which generates csv (or tab delimited) data _with headers_
      # We want to map those "external" headers to the spree product names: That is the mapping below
      # mapping to nil, means that column is digarded (thus possibly saving you to remove colums from the import file)
      @mapping = {
        'Product ID' =>   :sku,
        'Product Code' => :name  ,
        'Description' =>  :description ,
        'Sell (Tax Inclusive)' =>   :price,
        'Pricing Level 1 (Selling Price)' =>  nil ,
        'Color' =>  nil,
        'Photo' => :image,
        'Height' =>   :height,
        'Width' =>   :width,
        'Length' =>   :depth,
        'Weight' =>   :weight,
        'Inventory Quantity' =>  :quantity ,
        'Web1' =>   :category,
        'VE1' => nil
      }
      file = FasterCSV.open(File.join(File.dirname(__FILE__), "..","feuer.txt" ),  { :col_sep => "\t"} ) 
      @header = file.shift
      @data = file.readlines
      #puts @header
      @header.each do |col|
        #puts "col=#{col}= mapped to =#{@mapping[col]}="
      end
  end
  
  def at_in( sym , row )
      index = @header.index(@mapping.index(sym))
      return nil unless index
      return row[index]
  end

  def set_taxonomy(product , row)
    cat_name = at_in(:category , row) # one level, simple taxonomy handling for now
    unless cat_name
      puts "NO CAT " + cat_name
      exit
    end
    root = Taxonomy.find_or_create_by_name(@taxonomy) 
    cat_root = root.root  # the root of a taxonomy is a taxon , usually with the same name (?)
    taxon = Taxon.find_or_create_by_name_and_parent_id_and_taxonomy_id(cat_name, cat_root.id, root.id)
    product.taxons << taxon 
  end
  
  #can be overwritten, we just use the sku   
  def get_product( row )
    puts "get product row:" + row.join("--")
    pro = Variant.find_by_sku( at_in(:sku , row ) )
    if pro
      puts "Found #{at_in(:sku,row)} "
      pro.product 
    else
      Product.new( )
    end
  end
  
  def remove_products
    while first = Product.first
      first.delete
    end
    while first = Variant.first
      first.delete
    end
  end

  def set_attributes_and_image( prod , row )
    #these are common attributes to product & variant (in fact prod delegates to master variant)
    # so it will be called with either
    if prod.class == Product
      prod.name             = at_in(:name,row) if at_in(:name,row)
      prod.description = at_in(:description, row) if at_in(:description, row)
    end
    prod.sku             = at_in(:sku,row) if at_in(:sku,row) 
    prod.weight             = at_in(:weight,row) if at_in(:weight,row) 
    prod.height             = at_in(:height,row) if at_in(:height,row) 
    prod.width             = at_in(:width,row) if at_in(:width,row) 
    prod.depth             = at_in(:depth,row) if at_in(:depth,row) 
    prod.available_on    = Time.now - 90000 unless prod.available_on # over a day, so to show immediately
    prod.price           = at_in(:price,row) if at_in(:price,row)
    file = at_in(:image,row)
    if file and prod.images.empty? # just one image per product for now  
      i = Image.new(:attachment => ActionController::TestUploadedFile.new(@dir + file, "image/jpg" ))                        
      i.viewable_type = "Product" 
      # link main image to the product
      i.viewable = prod
      prod.images << i 
    end
  end
  
  def is_line_variant?(name , index) #or file end
    #puts "variant product -#{name}-"
    return false if (index >= @data.length) 
    row = @data[index]
    return false if row == nil
    variant = at_in( :name, row ) 
    #puts "variant name -#{variant}-"
    return false unless name
    #puts "variant return #{ name == variant[ 0 ,  name.length ] }"
    return name == variant[ 0 ,  name.length ] 
  end
    
  def slurp_variants(prod , index)
    return index unless is_line_variant?(prod.name , index ) 
    #need an option type to create options, create dumy for now
    option_type  = OptionType.find_or_create_by_name_and_presentation("tuoksu", "Tuoksu") #FIXME
    while is_line_variant?(prod.name , index )
      #puts "variant slurp index " + index.to_s
      row = @data[index]
      #puts "variant row" + row.join("--")
      variant_name = at_in( :name, row )
      variant_name =  variant_name[prod.name.length ..  -1]
      variant_name.strip!
      #puts "variant name -" + variant_name + "-"
      option_value = OptionValue.create( :name         => variant_name, :presentation => variant_name,
                                        :option_type  => option_type )
      variant = Variant.create( :product => prod )  # create the new variant
      variant.option_values << option_value         # add the option value
      set_attributes_and_image( variant , row )     #set price and the other stuff
      prod.variants << variant                      #add the variant (not sure if needed)
      index += 1
    end
    return index 
  end
  
  def run
    #remove_products
    check_admin_user
    index = 0
    while index < @data.length
      row = @data[index]
      #puts "row is " + row.join("--")
      @mapping.each  do |key,val|
        #puts "Row:#{val} at #{@mapping.index(val)} is --#{@header.index(@mapping.index(val))}--value---"
        #puts "--#{at_in(val,row)}--" if @header.index(@mapping.index(val))
      end
      prod = get_product(row)
      set_attributes_and_image( prod , row )
      set_taxonomy(prod , row)
      #puts "saving -" + prod.description + "-  at " + at_in(:price,row) #if at_in(:price,row) == "0"
      prod.save!
      
#      pr = get_product( row )
#      puts "TAXONs #{pr.taxons}"
      
      puts "saved -" + prod.description + "-  at " + at_in(:price,row) #if at_in(:price,row) == "0"
      index = slurp_variants(prod , index + 1) #read variants if there are, returning the last read line
    end

  end

  def check_admin_user(password="spree", email="spree@spreecommerce.com")      
      return if  User.find_by_login(email)
      admin = User.create( attributes = { :password => password,:password_confirmation => password,
                                            :email => email,      :login => email } )
      # create an admin role and and assign the admin user to that role
      admin.roles << Role.find_or_create_by_name("admin") 
      admin.save!
  end

end

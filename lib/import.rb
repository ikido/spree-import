
require "fastercsv"

require 'active_support'
require 'action_controller'
require 'action_controller/test_process'
require 'app/models/product'
require 'yaml'

class Import
  
    def initialize()
      #Images are below SPREE/vendor/import/
      @dir = File.join(SPREE_ROOT, "vendor", "import" )      

      # one root taxonomy supported only. Must be set before (eg rake db:load_file)
      @taxonomy = Taxonomy.find(:first)
      throw "No Taxonomy found, create by sample data (rake db:load_file) or override set_taxonomy method" unless @taxonomy
      parent = @taxonomy.root  # the root of a taxonomy is a taxon , usually with the same name (?)
      if parent == nil 
        @taxonomy.save
      end

      # assuming you have data from another software which generates csv (or tab delimited) data _with headers_
      # We want to map those "external" headers to the spree product names: That is the mapping below
      # mapping to nil, means that column is digarded (thus possibly saving you to remove colums from the import file)
      @mapping = YAML.load_file(  File.join( @dir , "mapping.yml") )
      #or edit something like this
#      @mapping = {
#        'Product ID' =>   :sku,
#        'Product Code' => :name  ,
#        'Description' =>  :description ,
#        'Web Short' =>  :option ,
#        'Width' =>   :width,
#        'Length' =>   :depth,
#        'Weight' =>   :weight,
#        'Inventory Quantity' =>  :quantity ,
#        'Web1' =>   :category1,
#        'Web2' =>   :category2,
#        'Web3' =>   :category3,
#        'Web4' =>   :category4,
#        'VE1' => nil
#      }
  end
  
  def at_in( sym , row )
      index = @header.index(@mapping.index(sym))
      return nil unless index
      return row[index]
  end

  #override if you have your categories encoded in one field or in any other way
  def get_categories(row)
    categories = []
    cat = at_in(:category1 , row) # should invent some loop here
    categories << cat if cat
    cat = at_in(:category2 , row) # but we only support
    categories << cat if cat
    cat = at_in(:category3 , row) # three levels, so there you go
    categories << cat if cat
    categories
  end
  
  def set_taxonomy(product , row)
    categories = get_categories(row)
    throw "No category for SKU: #{at_in(:sku, row)} in row (#{row})" if categories.empty?
    #puts "Categories #{categories.join('/')}"
    #puts "Taxonomy #{@taxonomy} #{@taxonomy.name}"
    parent = @taxonomy.root  # the root of a taxonomy is a taxon , usually with the same name (?)
    #puts "Root #{parent} #{parent.id} #{parent.name}"
    categories.each do |cat|
      taxon = Taxon.find_by_name(cat)
      unless taxon
        puts "Creating -#{cat}-"
        taxon = Taxon.create!(:name => cat , :taxonomy_id => @taxonomy.id , :parent_id => parent.id ) 
      end
      parent = taxon
    #puts "Taxon #{cat} #{parent} #{parent.id} #{parent.name}"
    end
    product.taxons << parent 
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
    set_sku(prod , row)
    set_weight(prod , row)
    set_dimensions(prod, row)
    set_available(prod, row)
    set_price(prod, row)
    add_image( prod , row)
  end
  
  # lots of little setters. if you need to override
  def set_sku(prod , row)
    prod.sku   = at_in(:sku,row) if at_in(:sku,row) 
  end
  
  def set_weight(prod , row)
    prod.weight  = at_in(:weight,row) if at_in(:weight,row) 
  end
  
  def set_available(prod , row)
      prod.available_on    = Time.now - 90000 unless prod.available_on # over a day, so to show immediately
  end
  
  def set_price(prod, row)
    price = at_in(:web_price,row )
    price = at_in(:price,row ) unless price
    #puts "Setting price #{price}"
    prod.price = price if price
  end
  
  def     set_dimensions(prod, row)
    prod.height             = at_in(:height,row) if at_in(:height,row) 
    prod.width             = at_in(:width,row) if at_in(:width,row) 
    prod.depth             = at_in(:depth,row) if at_in(:depth,row) 
  end
  
  def add_image(prod , row )
    file_name = has_image(row)
    #puts "File :   #{file_name}"
    if file_name
      type = file_name.split(".").last
      i = Image.new(:attachment => ActionController::TestUploadedFile.new(file_name, "image/#{type}" ))                        
      i.viewable_type = "Product" 
      # link main image to the product
      i.viewable = prod
      prod.images << i 
      if prod.class == Variant
        i = Image.new(:attachment => ActionController::TestUploadedFile.new(file_name, "image/#{type}" ))                        
        i.viewable_type = "Product" 
        prod.product.images << i
      end
    end
  end
  
  def has_image(row)
    file_name = at_in(:image , row )
    file = find_file(file_name) 
    return file if file
    return find_file(file_name + "")
  end

  # use (rename to has_image) to have the image name same as the sku
  def has_image_sku(row)
    sku = at_in(:sku,row)
    return find_file( sku)
  end

  # recursively looks for the file_name you've given in you @dir directory
  # if not found as is, will add .* to the end and look again 
  def find_file name
    file = Dir::glob( File.join(@dir , "**", "*#{name}" ) ).first
    return file if file
    Dir::glob( File.join(@dir , "**", "*#{name}.*" ) ).first
  end

  #
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
    prod_row = @data[index - 1]
    option = at_in( :option , prod_row )
    option = prod.name unless option
    puts "Option type -#{option}-"
    option_type  = OptionType.find_or_create_by_name_and_presentation(option , "") 
    while is_line_variant?(prod.name , index )
      #puts "variant slurp index " + index.to_s
      row = @data[index]
      option_value = at_in( :option , row )
      option_value = at_in( :name , row ) unless option_value
      puts "variant option -#{option_value}-"
      option_value = OptionValue.create( :name         => option_value, :presentation => option_value,
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
    remove_products
    check_admin_user
    Dir.glob(File.join(@dir , '*.txt')).each do |file|
        puts "Importing " + file
        load_file( file )
    end
  end
  
  #If you want to write your own task or wrapper, this is the main entry point
  def load_file full_name
    file = FasterCSV.open( full_name ,  { :col_sep => "\t"} ) 
    @header = file.shift
    @data = file.readlines
    #puts @header
    @header.each do |col|
      #puts "col=#{col}= mapped to =#{@mapping[col]}="
    end
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

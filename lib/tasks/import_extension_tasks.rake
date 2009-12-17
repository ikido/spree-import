namespace :db do

  desc "Load a txt/csv file."
  task :import  => :environment do
    require 'my_import'
    MyImport.new.run
  end

  
  desc  "Removing shipping data"
  task :clear_shipping  => :environment do
    [ShippingCategory , ShippingMethod , ShippingRate].each do |clazz|
      while first = clazz.first  
        puts "Deleting + " +  (first.respond_to?(:name) ? first.name : first.to_s)
          first.delete
      end
    end
  end

end

namespace :spree do
  namespace :extensions do
    namespace :import do
      desc "Copies public assets of the Import to the instance public/ directory."
      task :update => :environment do
        is_svn_git_or_dir = proc {|path| path =~ /\.svn/ || path =~ /\.git/ || File.directory?(path) }
        Dir[ImportExtension.root + "/public/**/*"].reject(&is_svn_git_or_dir).each do |file|
          path = file.sub(ImportExtension.root, '')
          directory = File.dirname(path)
          puts "Copying #{path}..."
          mkdir_p RAILS_ROOT + directory
          cp file, RAILS_ROOT + path
        end
      end  
    end
  end
end
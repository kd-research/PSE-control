#!/usr/bin/env ruby -Ilib
require "bundler/setup"
require "sqlite3"
require "storage_loader"

module ActiveLoopTools
  module MetadataUpdater
    def self.update_metadata_files
      all_metadata = `find #{StorageLoader.get_absolute_path "."} -path '*/snapshots' -prune -o -name metadata.sqlite3 -print0`.split("\x0")
      puts "Found #{all_metadata.size} metadata files, update them? (Y/n)"
      if gets.chomp == "n"
        return
      end

      all_metadata.each do |metadata_file|
        Dir.chdir(File.dirname(metadata_file)) do
          puts "Updating metadata file in #{Dir.pwd}"
          update_metadata_file_loc
        end
      end
    end

    def self.new_loc(path)
      File.join(Dir.pwd, File.basename(path))
    end

    def self.update_metadata_file_loc
      # Check if metadata.sqlite3 exists
      unless File.exist? "metadata.sqlite3"
        raise "metadata.sqlite3 not found in #{Dir.pwd}"
      end

      # Connect to the database
      db = SQLite3::Database.new "metadata.sqlite3"
      rows = db.execute "SELECT id, file FROM parameters;"

      # Check if the files exist
      found, notfound = rows.partition { |_, file| File.exist?(new_loc(file)) }

      # Remove files not found from the database
      unless notfound.empty?
        puts "There are #{notfound.size} files not found, remove them from the database? (y/n)"

        if gets.chomp == "y"
          notfound.each do |id, _|
            db.execute "DELETE FROM parameters WHERE id = ?;", id
          end
        end
      end

      # Check if all files are already in the correct location
      if found.all? { |_, file| file == new_loc(file) }
        puts "All files are already in the correct location."
        return
      end

      # Update the database
      puts "There are #{found.size} files found, update the database? (y/n)"
      if gets.chomp == "n"
        return
      end

      found.each do |id, file|
        db.execute "UPDATE parameters SET file = ? WHERE id = ?;", [new_loc(file), id]
      end

      db.close
    end
  end
end

ActiveLoopTools::MetadataUpdater.update_metadata_files

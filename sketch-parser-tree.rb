require 'pp'
require 'zip/zip'
require 'json'
# require 'recursive-open-struct'
require 'tree'

# Require classes
require './array'
require './layer'

file = ""
destination = "./sketch/"

file_path = ARGV

log = false

if ARGV.empty?
  # puts "No file was referenced. Run the script with a file path (i e 'sketch-parser.rb File.sketch')"
else
  # puts "You inputted: #{file_path.first}"
  file = file_path.first
end

def extract_zip(file, destination)
  Zip::ZipFile.open(file) do |zip_file|
    # Clear and remove destination folder
    if Dir.exist?(destination)
      FileUtils.rm_rf(destination, :secure => true)
    end
    # Write files to destination folder
    zip_file.each do |f|
        f_path = File.join(destination, f.name)
        FileUtils.mkdir_p(File.dirname(f_path))
        zip_file.extract(f, f_path) unless File.exist?(f_path)
    end
  end
end

def parse_page
  fc = Dir.glob('./sketch/pages/*.json')
  # PP.pp(fc)
  
  page_hash = JSON.parse(File.read(fc.first))
  page_hash['layers'].each_with_index do |artboard, index|
    # puts "\n# # # # #\nArtboard: #{artboard['name']}\n# # # # #\n"
    layers = Array.new
    artboard['layers'].map do |layer|
      layers << Layer.new(layer)
    end
    
    # Try to output markup
    parse(Layer.new(artboard), layers)
  end
end

def parse(layer, layers)
  # Start recursive function build_dom
  root = build_dom(nil, layers)

  # Interpret DOM tree to add relevant wrappers, such as Grid and Flex containers

  # Output generated marup
  puts "\n# # # # # Finalized markup to:\n\n"
  puts "\n# # # #"
  puts root.print_tree

  return layers
end

##########
# TODO: LAYER GROUP MANAGEMENT
##########

def build_dom(layer = nil, layers) 
  # First iteration, there's no layer being passed in, so we assume the biggest one
  layer = layers.delete(layers.sort_by { |layer| layer.width * layer.height }.reverse.first) unless layer

  # These children are relevant when adding to the DOM tree
  children = layers.get_layer_children_within(layer).order_by_DOM
  
  # We're now parsing 'children' and adding it to the DOM tree,
  # what remains to be parsed is the remaining children in layers
  # So we remove the ones covered in this iteration
  children.each { |child| layers.delete(child) }
  
  # Initialize root node for this layers hierarchy,
  # this will host all first-level elements
  # a first-level element can be a new node that hosts its own first-level elements
  node = Tree::TreeNode.new(layer.name, layer)
  children.each { |child| node << build_dom(child, children) }
  
  return node
end

# Only run if the provided file exists
if File.exist?(file)
  extract_zip(file, destination)
  # Running parse_page
  parse_page
else
  puts "#{file} does not exist"
end
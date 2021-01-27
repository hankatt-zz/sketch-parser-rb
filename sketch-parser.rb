require 'pp'
require 'zip/zip'
require 'json'
require 'recursive-open-struct'

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

def parse(layer, layers)
  # Start recursive function write_markup_for
  markup = write_markup_for(layer, layers)

  # Output generated marup
  puts "\n# # # # # Finalized markup to:\n\n"

  # markup.each do |l|
  #   # puts l.class
  #   if l.class.eql?(Array)
  #     l.each do |layer|
  #       if layer.class.eql?(Array)
  #         layer.each do |ll|
  #           if ll.class.eql?(Array)
  #             ll.each do |lll|
  #               if lll.class.eql?(Array)
  #                 lll.each do |llll|
  #                   puts llll.inspect
  #                   if llll.class.eql?(Array)
  #                     puts 'array'
  #                   elsif llll.class.eql?(String)
  #                     puts llll
  #                   else
  #                     puts llll.name
  #                   end
  #                 end
  #               elsif lll.class.eql?(String)
  #                 puts lll
  #               else
  #                 puts lll.name
  #               end
  #             end
  #           elsif ll.class.eql?(String)
  #             puts ll
  #           else
  #             puts ll.name
  #           end
  #         end
  #       elsif layer.class.eql?(String)
  #         puts layer
  #       else
  #         puts layer.name
  #       end
  #     end
  #   end
  #   # if l.class.eql?(String)
  #   #   puts 'string'
  #   # end
  # end

  indent_r(markup)
  puts "\n# # # #"
  # puts markup

  return layers
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
    loop do
      remaining_layers = parse(Layer.new(artboard), layers)
    
      if remaining_layers.empty?
        break
      end
    end
  end
end

##########
# TODO: LAYER GROUP MANAGEMENT
##########

def write_markup_for(layer = nil, layers) 
  # First iteration, there's no layer being passed in, so we assume the biggest one
  layer = layers.delete(layers.sort_by { |layer| layer.width * layer.height }.reverse.first) unless layer

  # Retrieve first-level children of layer
  children = layers.get_layer_children_within(layer).order_by_DOM

  # Purge layers from the children
  children.each { |layer| layers.delete(layer) }

  if children.any?
    markup = Array.new # Initiatlize markup
    
    # Ignore opening artboard
    if !layer.is_artboard
      markup << layer.opening_tag # Open parent
    else
      markup << "<Layout.Column desktopWidth={#{layer.column_count}}>"
    end

    # Monitor if we have open Flex wrappers
    layer_group_is_open = false

    children.each_with_index do |child, index|
      isInline = child.is_inline_with(children[index+1])

      # Open inline layer group
      if isInline && !layer_group_is_open
        # puts "get_justify_content(#{child.name}, #{children[index+1].name}, #{layer.name})"
        props = get_justify_content(child, children[index+1], layer)
        markup << "<Flex#{props}>"
        layer_group_is_open = true
      end

      markup << write_markup_for(child, children)

      # Close inline layer group
      if layer_group_is_open && !isInline
        markup << "</Flex>"
        layer_group_is_open = false
      end
    end

    # Ignore opening artboard
    if !layer.is_artboard
      markup << layer.closing_tag # Close parent
    else
      markup << "</Layout.Column>"
    end
  else
    markup = Array.new << layer.tag
  end

  return markup.flatten # Clear it from an unnecessary wrapping array
end

# Only works for two entities in a row
# Need to work on managing multiple entities such as Avatar|Title <---space---> Button
# NEEDS TO BE MADE MORE DYNAMIC TO INTERPRET LAYER1, 2, ..N... # OF LAYERS
def get_justify_content(layer1, layer2, parent)
  # Returns <Flex> if items are horizontally inline
  # Returns 'spaceBetween' if one layer is snapping to the left, and the other to the right
  # Returns [can not determine] if layer1 and layer2 has unidentifiable spacing
  layers_spacing = layer2.x - (layer1.x + layer1.width) # If there's more than 30px between layer1 and layer2
  spacing_tolerance = 30
  # puts "layer2.x: #{layer2.x} - (layer1.x: #{layer1.x} + layer1.width: #{layer1.width}"

  # Could be spaceBetween
  if layers_spacing > spacing_tolerance 
    # Identify space between layer2 and the parents right side
    parent_right_side = parent.x + parent.width
    layer2_right_side = layer2.x + layer2.width
    
    interpreted_padding = parent_right_side - layer2_right_side # Interpreted padding from the right side
    expected_padding = layer1.x - parent.x # Should be same padding as layer1.x from parent.x
    tolerated_padding = expected_padding + 10 # But we need some tolerance

    if interpreted_padding <= tolerated_padding
      return ' spaceBetween'
    else
      return ' [can not determine!]'
    end
  end

  return ""
end

def indent_r(markup, indentation = "")
  if markup.class.eql?(Array)
    markup.map do |mu|
      indent_r(mu, indentation + "  ")
    end
  else
    if markup.include?("Flex")
      puts "#{indentation}  #{markup}"
    else
      puts "#{indentation.sub("  ", "")}#{markup}"
    end
  end
end

# Only run if the provided file exists
if File.exist?(file)
  extract_zip(file, destination)
  # Running parse_page
  parse_page
else
  puts "#{file} does not exist"
end
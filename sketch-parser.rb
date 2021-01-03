require 'pp'
require 'zip/zip'
require 'json'
require 'recursive-open-struct'

file = ""
destination = "./sketch/"

file_path = ARGV

log = false

class Array
  def has_layer_children_within(layer)
    select { |child| child.is_within(layer) }.any?
  end

  def get_layer_children_within(layer)
    select { |child| child.is_within(layer) }
  end

  def has_layers_inline_with(layer)
    select { |child| child.is_inline_with(layer) }.any?
  end
end

class Layer
  attr_reader :is_artboard, :name, :width, :height, :x, :y, :string

  def initialize(layer)
    # Allows for dot notation layer on, such as in 'is_within()' where we use layer1.width rather than layer1[:width]
    layer_struct = RecursiveOpenStruct.new(layer, recurse_over_arrays: true)

    @layers = layer_struct.layers
    @is_artboard = layer_struct._class.eql?("artboard")
    @name = layer_struct.name
    @height = Integer(layer_struct.frame.height)
    @width = Integer(layer_struct.frame.width)
    @x = @is_artboard ? 0 : Integer(layer_struct.frame.x)
    @y = @is_artboard ? 0 : Integer(layer_struct.frame.y)
    if layer_struct.attributedString
      @string = layer_struct.attributedString.string
    end
  end

  def is_inline_with(layer)
    if !layer.nil?
      if !is_stacked(layer)
        return (self.vertical_center - layer.vertical_center).abs < 5
      end
    end

    false
  end

  # The layers are on top of eachother
  def is_stacked(layer)
    if !layer.nil?
      is_within(layer) || layer.is_within(self)
    end

    false
  end

  # Strict enforces that the small has to be on top the large
  def is_within(layer)
    if !layer.nil?
      layerStartsWithinXBoundaries = self.x > layer.x && self.x < (layer.x + layer.width)
      layerStartsWithinYBoundaries = self.y > layer.y && self.y < (layer.y + layer.height)
      # puts "large is #{large.name} at x: #{large.x}, y: #{large.y} and small is #{small.name} at x: #{small.x}, y: #{small.y}"
      return layerStartsWithinXBoundaries && layerStartsWithinYBoundaries
    end

    false
  end

  def vertical_center
    height = self.height.to_f
    y_cord = self.y.to_f
    (height + y_cord) / 2
  end
end

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
  puts "\nFinalized markup to:\n"
  puts markup

  return layers
end

def parse_page
  fc = Dir.glob('./sketch/pages/*.json')
  # PP.pp(fc)

  page_hash = JSON.parse(File.read(fc.first))

  page_hash['layers'].each_with_index do |artboard, index|
    puts "\n# # # # #\nArtboard: #{artboard['name']}\n# # # # #\n"

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

def sort_layers(layers)
  # Order layers from top left -> right, as read and implemented
  layers.sort_by! { |layer| [layer.y, layer.x] }

  inline_layers = Array.new
  # Populate inline_layers
  layers.each_with_index do |layer, index|
    if layer.is_inline_with(layers[index+1]) && inline_layers.empty? # If two elements are inline, initiate the array if empty
      # puts "Writing #{layer.name} and #{layers[index+1].name} to inline_layers"
      inline_layers.push(layer, layers[index+1])
    end

    if !inline_layers.include?(layer) && inline_layers.has_layers_inline_with(layer) # If other layers are inline, is it inline with those?
      # puts "Writing #{layer.name} to inline_layers"
      inline_layers << layer
    end
  end

  # Apply inline_layers
  layers.dup.each_with_index do |layer, index|
    if inline_layers.include?(layer)
      inline_layers.sort_by! { |layer| [layer.x] }.each_with_index do |inline_layer, inline_index|
        layers[index+inline_index] = inline_layer
      end
      inline_layers = Array.new
      break
    end
  end

  return layers
end

def write_markup_for(layer = nil, layers)
  
  # First iteration, there's no layer being passed in, so we assume the biggest one
  layer = layers.delete(layers.sort_by { |layer| layer.width * layer.height }.reverse.first) unless layer
  # Retrieve first-level children of layer
  children = sort_layers(layers.get_layer_children_within(layer))
  # Purge layers from the children
  children.each { |layer| layers.delete(layer) }

  if children.any?
    markup = Array.new # Initiatlize markup
    
    # Ignore opening artboard
    if !layer.is_artboard
      markup << componetize(layer, 'opening') # Open parent
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
      markup << componetize(layer, 'closing') # Close parent
    end
  else
    markup = Array.new << componetize(layer)
  end

  return markup
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

def componetize(layer, openingOrClosing = nil)
  if layer.string
    layer_markup = ("<" << layer.name << ">" << layer.string << "<" << layer.name << "/>")
  elsif openingOrClosing.eql?('opening')
    layer_markup = "<" << layer.name << ">"
  elsif openingOrClosing.eql?('closing')
    layer_markup = "</" << layer.name << ">"
  else
    layer_markup = "<" << layer.name << "/>"
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
# Component mapping
require './componentMap'

class Layer
  attr_reader :column_count, :is_artboard, :width, :height, :x, :y, :string

  def initialize(layer)
    # Allows for dot notation layer on, such as in 'is_within()' where we use layer1.width rather than layer1[:width]
    # layer_struct = RecursiveOpenStruct.new(layer, recurse_over_arrays: true)

    @layers = layer["layers"] | []
    @is_artboard = layer["_class"].eql?("artboard")
    @name = layer["name"]
    if !layer["frame"].nil?
      @height = Integer(layer["frame"]["height"]) | 0
      @width = Integer(layer["frame"]["width"]) | 0
      @column_count = (((@width / 50).to_f)/2).ceil 
      @x = @is_artboard ? 0 : Integer(layer["frame"]["x"])
      @y = @is_artboard ? 0 : Integer(layer["frame"]["y"])
    end

    @string = nil
    if layer["attributedString"]
      @string = layer["attributedString"]["string"]
    elsif layer["overrideValues"]
      layer["overrideValues"].each do |overrideValue|
        if overrideValue["overrideName"].include?("stringValue")
          @string = overrideValue["value"]
        end
      end
    end
  end

  def name
    # smart_key is trying to match a key to the @name of a layer
    # @name's can include Sketch suffixes like copy, 2, etc, that are irrelevant and are in this way disregarded
    smart_key = ComponentMap::UIComponentName.keys.select { |key| @name.include?(key) }.first
    ComponentMap::UIComponentName[smart_key] || @name
  end

  def opening_tag
    ("<" << name << ">")
  end

  def closing_tag
    ("</" << name << ">")
  end

  def tag(opening = false, closing = false)
    if @string
      return ("<" << name << ">" << @string.sub("\n", " ") << "<" << name << "/>")
    else
      return ("<" << name << "/>")
    end
  end

  # The layers positioned along the same horizontal axis within a '5px' tolerance
  def is_inline_with(layer)
    if !layer.nil?
      #puts "Comparing #{self.name} with #{layer.name}\n"
      #puts "#{self.name} ->\nx: #{self.x}\ny: #{self.y}\nheight: #{self.height}\nwidth: #{self.width}\n\n#{layer.name} ->\nx: #{layer.x}\ny: #{layer.y}\nheight: #{layer.height}\nwidth: #{layer.width}\n\n"
      if !self.is_stacked(layer)
        #puts "#{self.name} has center at #{self.vertical_center} and #{layer.name} has center at #{layer.vertical_center}"
        #puts "#{(self.vertical_center - layer.vertical_center).abs}"
        #puts "Result is #{(self.vertical_center - layer.vertical_center).abs < 4}\n\n"
        return (self.vertical_center - layer.vertical_center).abs < 4
      end
    end

    false
  end

  # The layers are on top of eachother
  def is_stacked(layer)
    if !layer.nil?
      return self.is_within(layer) || layer.is_within(self)
    else
      return false
    end
  end

  # Strict enforces that the small has to be on top the large
  def is_within(layer)
    if !layer.nil?
      layerStartsWithinXBoundaries = self.x > layer.x && (self.x + self.width) < (layer.x + layer.width)
      layerStartsWithinYBoundaries = self.y > layer.y && (self.y + self.height) < (layer.y + layer.height)

      return layerStartsWithinXBoundaries && layerStartsWithinYBoundaries
    end

    false
  end
  
  def bottom_coordinate
    height = self.height.to_f
    y_cord = self.y.to_f
    (height + y_cord)
  end

  def vertical_center
    bottom_coordinate / 2
  end
end
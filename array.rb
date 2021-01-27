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

  def get_inline_layers
    inline_layers = Array.new
    self.each_with_index do |layer, index|
      if layer.is_inline_with(self[index+1]) && inline_layers.empty? # If two elements are inline, initiate the array if empty
        # puts "Writing #{layer.name} and #{layers[index+1].name} to inline_layers"
        inline_layers.push(layer, self[index+1])
      end

      if !inline_layers.include?(layer) && inline_layers.has_layers_inline_with(layer) # If other layers are inline, is it inline with those?
        # puts "Writing #{layer.name} to inline_layers"
        inline_layers.push(layer)
      end
    end

    inline_layers
  end

  def order_by_DOM
  # Order layers from top left -> right, as read and implemented
  self.sort_by! { |layer| [layer.y, layer.x] }

  # Filter out inline layers from layers
  inline_layers = self.get_inline_layers

  # Apply inline_layers
  self.dup.each_with_index do |layer, index|
    if inline_layers.include?(layer)
      inline_layers.sort_by! { |layer| [layer.x] }.each_with_index do |inline_layer, inline_index|
        self[index+inline_index] = inline_layer
      end
      inline_layers = Array.new
      break
    end
  end

  return self
end

  # Remove empty wrapping arrays, when array-in-array
  def flatten
    array = self
    while array.class.eql?(Array) && array[0].class.eql?(Array)
      array = array[0]
    end

    array
  end
end
# This script is used to generate walls for the Ve Tuong Project

require 'sketchup.rb'

# Create a class to generate walls
class WallTool
  def initialize
    @state = 'start'
    @ip1 = nil
    @ip2 = nil
    @drawn = false
    @wall_group = nil
    @walls = []
  end

  def activate
    @ip1 = Sketchup::InputPoint.new
    @ip2 = Sketchup::InputPoint.new
    reset(nil)
  end

  def deactivate(view)
    view.invalidate if @drawn
  end

  def reset(view)
    @state = 'start'
    @ip1.clear
    @ip2.clear
    @drawn = false
    @wall_group = nil
    @walls.clear
    view.invalidate if view
  end

  def onCancel(reason, view)
    reset(view)
  end

  def onMouseMove(flags, x, y, view)
    if @state == 'start'
      @ip1.pick(view, x, y)
      if @ip1.valid?
        view.tooltip = 'Starting point'
      else
        view.tooltip = 'Invalid point'
      end
    elsif @state == 'end'
      @ip2.pick(view, x, y, @ip1)
      if @ip2.valid?
        view.tooltip = 'Ending point'
      else
        view.tooltip = 'Invalid point'
      end
    end
    view.invalidate
  end

  def onLButtonDown(flags, x, y, view)
    if @state == 'start'
      @ip1.pick(view, x, y)
      if @ip1.valid?
        @state = 'end'
        Sketchup.status_text = 'Select end point.'
        Sketchup.vcb_label = 'End Length'
        Sketchup.vcb_value = @ip1.position.distance(@ip2.position)
      end
    elsif @state == 'end'
      @ip2.pick(view, x, y, @ip1)
      if @ip2.valid?
        self.create_wall(view, @ip1.position, @ip2.position)
        @ip1.copy!(@ip2)
        Sketchup.vcb_label = 'End Length'
        Sketchup.vcb_value = @ip1.position.distance(@ip2.position)
      end
    end
    view.lock_inference if @ip2.valid?
  end

  def create_wall(view, pt1, pt2)
    if @wall_group.nil?
      @wall_group = Sketchup.active_model.entities.add_group
      @wall_group.name = 'Walls'
      @walls << @wall_group
    end
    wall = @wall_group.entities.add_line(pt1, pt2)
    @walls << wall
    wall.material = 'white'
    @drawn = true
  end

  def onReturn(view)
    if @state == 'end' && @ip1.valid? && @ip2.valid?
      self.create_wall(view, @ip1.position, @ip2.position)
      self.reset(view)
    end
  end
end

# Create a menu item to activate the tool
UI.menu('Plugins').add_item('Draw Wall') {
  Sketchup.active_model.select_tool(WallTool.new)
}

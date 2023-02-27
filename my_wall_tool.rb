require "sketchup.rb"

module MyWallTool

  def self.activate_wall_tool
    Sketchup.active_model.select_tool(WallTool.new)
  end
  private_class_method :activate_wall_tool

  if !file_loaded?("my_wall_tool.rb")
    UI.menu("Plugins").add_item("My Wall Tool") {
      self.activate_wall_tool
    }
    file_loaded("my_wall_tool.rb")
  end

  class WallTool

    def activate
      @wall_face = nil
      @state = 0
      @first_point = nil
      @second_point = nil
      @thickness = 100.mm
      @height = 3000.mm
      @centered = true
      @left = false
      @right = false
    end

    def deactivate(view)
      view.invalidate if @drawn
    end

    def resume(view)
      view.invalidate if @drawn
    end

    def onCancel(reason, view)
      reset_tool
      view.invalidate if @drawn
    end

    def onMouseMove(flags, x, y, view)
      if @state == 1
        @second_point = Geom::Point3d.new(x, y, 0)
        draw_preview(view)
      end
    end

    def onLButtonDown(flags, x, y, view)
      case @state
      when 0
        @first_point = Geom::Point3d.new(x, y, 0)
        @state = 1
      when 1
        @second_point = Geom::Point3d.new(x, y, 0)
        create_wall
        reset_tool
      end
    end

    def onKeyDown(key, repeat, flags, view)
      case key
      when 32 # spacebar
        @centered = !@centered
        @left = false
        @right = false
        draw_dialog
        draw_preview(view)
      end
    end

    def draw_dialog
      prompts = ["Wall Thickness:", "Wall Height:", "Centered:", "Left:", "Right:"]
      defaults = [@thickness, @height, @centered, @left, @right]
      list = ["", "", "Yes|No", "Yes|No", "Yes|No"]
      results = UI.inputbox(prompts, defaults, list, "Wall Options")
      if results
        @thickness, @height, @centered, @left, @right = results
        draw_preview(view)
      end
    end

    def draw_preview(view)
      view.invalidate if @drawn
      @drawn = true
      draw_wall_preview(view)
      draw_text(view)
    end

    def draw_wall_preview(view)
      if @first_point && @second_point
        wall_vector = @second_point - @first_point
        wall_length = wall_vector.length
        wall_vector.normalize!
        wall_normal = Geom::Vector3d.new(0, 0, 1)
        wall_right = wall_vector.cross(wall_normal)
        wall_right.length = @thickness / 2.0
        if @centered
          wall_start = @first_point.offset(wall_vector, -wall_length / 2.0)
        elsif @left
          wall_start = @first_point.offset(wall_right, -1.0)
        elsif @right
          wall_start = @first_point.offset(wall_right, 1.0)
        end
        wall_end = wall_start.offset(wall_vector, wall_length)
        wall_points = []
        wall_points << wall_start.offset(wall_right.reverse)
        wall_points << wall_start.offset(wall_right)
        wall_points << wall_end.offset(wall_right)
        wall_points << wall_end.offset(wall_right.reverse)
        wall_face = view.model.active_entities.add_face(wall_points)
        wall_face.pushpull(-@height)
        wall_face.back_material = "white"
        @wall_face = wall_face
      end
    end

    def draw_text(view)
      if @wall_face
        wall_center = @wall_face.bounds.center
        text_point = Geom::Point3d.new(wall_center.x, wall_center.y, wall_center.z + @height / 2.0)
        text_vector = Geom::Vector3d.new(0, 0, 1)
        view.draw_text(text_point, "Wall", text_vector)
      end
    end

    def create_wall
      if @first_point && @second_point
        wall_vector = @second_point - @first_point
        wall_length = wall_vector.length
        wall_vector.normalize!
        wall_normal = Geom::Vector3d.new(0, 0, 1)
        wall_right = wall_vector.cross(wall_normal)
        wall_right.length = @thickness / 2.0
        if @centered
          wall_start = @first_point.offset(wall_vector, -wall_length / 2.0)
        elsif @left
          wall_start = @first_point.offset(wall_right, -1.0)
        elsif @right
          wall_start = @first_point.offset(wall_right, 1.0)
        end
        wall_end = wall_start.offset(wall_vector, wall_length)
        wall_points = []
        wall_points << wall_start.offset(wall_right.reverse)
        wall_points << wall_start.offset(wall_right)
        wall_points << wall_end.offset(wall_right)
        wall_points << wall_end.offset(wall_right.reverse)
        wall_face = Sketchup.active_model.active_entities.add_face(wall_points)
        wall_face.pushpull(-@height)
        wall_face.back_material = "white"
        @wall_face = wall_face
      end
    end

    def reset_tool
      @state = 0
      @first_point = nil
      @second_point = nil
      @drawn = false
    end

  end
end


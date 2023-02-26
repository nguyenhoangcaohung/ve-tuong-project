	require 'sketchup'
    require 'extensions'
	Dibac = SketchupExtension.new "Dibac", "Dibac/dibac_cmd"
    Dibac.version = '1.0'
	Dibac.creator = 'Dibac'
	Dibac.copyright='2012-Dibac'
    Dibac.description = "Plugin for architectural drawing."
    Sketchup.register_extension Dibac, true
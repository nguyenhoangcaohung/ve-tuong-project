=begin
 Copyright 2010, Jaime Díaz

 ESTE SOFTWARE SE ENTREGA "TAL CUAL", SIN NINGUNA GARANTÍA EXPRESA O IMPLÍCITA, 
 INCLUYENDO, SIN LIMITACIÓN, LAS GARANTÍAS DE COMERCIALIZACIÓN Y APTITUD 
 PARA UN PROPÓSITO PARTICULAR.
---------------------------------------------------------------------------------------------------
 Nombre        		:	Dibac 1.0
 Descripción   		:	Un conjunto de herramientas para crear distribuciones en planta y 3D
 -------------------------------- CLASES ---------------------------------------------------------		  		
 ObservadorApp	:	Llama a ObservadorTools con cada nuevo documento
 ObservadorTools :   Sobreescribe la funcion borrar 
 Dibac       			:   Clase Raiz. Contiene procedimientos comunes.
 Borrar       		:   Borrado inteligente de elementos de dibac.
 Muro         		:   Dibuja muros en planta
 Murop        		:   Dibuja muros paralelos a una arista.
 EstiraMuro       	:   Alarga muros y realiza las conexiones con otros
 Carpinteria   		:   Clase raiz de carpinterias, contiene las propiedades comunes
 Puerta        		:   Procedimientos particulares para colocar puertas
 Ventana     		:   Procedimientos particulares para colocar vntanas
 Armario    			:   Procedimientos particulares para colocar armarios
 CotaContinua		:   Acota automaticamente distribuciones interiores y fachadas
 ImprimeDibac		:   Imprime utilizando el gestor de impresion de Dibac
 TresDimensiones	:   Crea un modelo en 3D a partir de la distribucion en planta
					
 Fecha        		:	14/11/2010
 Tipo        			:	Tool
---------------------------------------------------------------------------------------------------
=end

#require "sketchup.rb"
#require 'LangHandler.rb'
class Dibac_Lenguaje

  def initialize
    @strings =Hash.new;
    self.ParseLangFile
	Dibac.description =GetString("....")
	$murocmd.tooltip = GetString("Wall")
	$murocmd.status_bar_text = GetString("Draw walls from point to point.")
	#Muro paralelo
	$muropcmd.tooltip = GetString("Paralell wall")
	$muropcmd.status_bar_text = GetString("Draw walls parallel to a edge.")
	#Estirar muros
	$Estiramurocmd.tooltip = GetString("Extend wall")
	$Estiramurocmd.status_bar_text = GetString("Extend / shorten walls.")
	#Puertas
	$puertacmd.tooltip = GetString("Door")
	$puertacmd.status_bar_text = GetString("Place doors in walls.")
	#Ventanas
	$ventanacmd.tooltip = GetString("Window")
	$ventanacmd.status_bar_text = GetString("Place windows in walls.")
	#Armarios
	$armariocmd.tooltip = GetString("Cabinet")
	$armariocmd.status_bar_text = GetString("Place cabinets in walls.")
	#Escaleras
	$escaleracmd.tooltip = GetString("Stair")
	$escaleracmd.status_bar_text = GetString("Draw stairs from point to point or by path.")
	#Acotado continuo
	$cotacontinuacmd.tooltip = GetString("Continuous dimension")
	$cotacontinuacmd.status_bar_text = GetString("Continuous interior dimensions between two points.")
	# 3D
	$tresdcmd.tooltip = GetString("Convert to 3D")	
	$tresdcmd.status_bar_text = GetString("Transforms the 2D model into a 3D model with height defined.")
	#Preferencias
	$preferenciascmd.tooltip = GetString("Options")
	$preferenciascmd.status_bar_text = GetString("Select language")
  end

  def ParseLangFile
	file_rec = Sketchup.find_support_file "Dibac.strings", "plugins//Dibac//resources//"+$DibacLenguaje
    if file_rec==nil || file_rec.length==0
      return false
    end
    langFile = File.open(file_rec, "r")
    entryString = ""
    inComment = false

    langFile.each do |line|
      #ignore simple comment lines - BIG assumption the whole line is a comment
      if !line.include?("//")
        #also ignore comment blocks
        if line.include?("/*")
          inComment = true
        end

        if inComment==true
          if line.include?("*/")
            inComment=false
          end
        else
          entryString += line
        end
      end

      if entryString.include?(";")
        #parse the string into key and value
        
        #remove the white space
        entryString.strip!

        #pull out the key
        keyvalue = entryString.split("\"=\"")
        
        #strip the leading quotation out
        key = keyvalue[0][(keyvalue[0].index("\"")+1)..(keyvalue[0].length+1)]
		result=keyvalue[1].to_s
 		#pull out the value
		result.gsub!(";", "")
        value = result.gsub("\"", "") 

        #add to @strings
        @strings[key]=value
        entryString = ""
      end
    end
	langFile.close
    return true
  end

  def GetString(key)
    #puts "GetString key = " + key.to_s
    retval = @strings[key]
    #puts "GetString retval = " + retval.to_s

    if retval!= nil
         retval.chomp!
    else
        retval = key
    end
    return retval
  end

   def unchecked (menu, item) # lo metemos aqui para aprovechar el objeto $DibacStrings
	menu.set_validation_proc(item)  {
		MF_UNCHECKED
	}
end


end

class Dibac_ObservadorApp < Sketchup::AppObserver

def onNewModel(model)
	model.tools.add_observer(Dibac_ObservadorTools.new)
end

def onOpenModel(model)
	model.tools.add_observer(Dibac_ObservadorTools.new)
end

end # de la clase ObservadorApp
   
class Dibac_ObservadorTools < Sketchup::ToolsObserver

def onActiveToolChanged(tools, tool_name, tool_id)
	Sketchup.active_model.select_tool Dibac_Borrar.new if tool_id == 21019
end

end # de la clase ObservadorTools

class Dibac_Base
=begin
 Clase	        		:	DibacBase
 Desciende de		:	
 Descripción   		:	Contiene funciones comunes a todos los descendientes
 Item de Menu  	:	
 Menú contextual	:	NO
 Uso         			:	
             		   
             		  
 Fecha        			:	14/11/2010
=end

def nolicencia
	return false if $clave != ''
	Dibac_Licencia::informacion
	return true
end	

def textoevaluacion(view)
	return if $clave == ''
	texto="Dibac: "+ Dibac.description + ' '
	if $clave =='promo' # No tiene licencia
		texto=texto+ $DibacStrings.GetString ("Cracked by Phan Ðình Tùng |")+" Phone: 0977027772 | Site: http://kientrucdn.com"
		x=view.corner(0)[0]
		y=view.corner(0)[1]
	else
		texto=texto+ $DibacStrings.GetString ("User")+": "+$usuario if $usuario != ''
		x=view.corner(2)[0]
		y=view.corner(2)[1]-30
	end	
	view.draw_text([x+2,y+12],texto)
end

def draw(view)
	textoevaluacion(view)
end	

def activate
	Sketchup.active_model.active_view.invalidate
	menu
end	

def deactivate(view)
	view.invalidate
end	

def escalera_3d(escalera)
	altura=escalera.get_attribute "escalera","3d"
	return if !altura
	cota=nil
	temp=[]
	escalera.entities.each do |p|
		temp.push p if p.get_attribute "escalera","escalon"
	end
	tabica=altura/temp.size
	temp.each do |p|
		if !p.deleted?
			peld=p.get_attribute "escalera","escalon"
			cota=p.edges[0].start.position.z if !cota
			extrusiona(p,peld*tabica)
		end
	end
	selborrar = []
	escalera.entities.each do |e|
		if e.typename == "Edge"
			if (e.faces.size == 3)
				#primero las horizontales dos normales verticales
				if e.start.position.z == e.end.position.z and e.faces[0].normal.z+e.faces[1].normal.z+e.faces[2].normal.z>1.999999
					selborrar.push e# if (e.faces[0].normal.dot(e.faces[1].normal) > 0.99999999) 
				end
			end
		end
	end
	escalera.entities.erase_entities selborrar if selborrar != []
	#UI.messagebox('primero')
	#borramos todas las lineas verticales mayores que la tabica
	selborrar=[]
	escalera.entities.each do |e|
		if e.typename=='Edge'
			if vertical(e)
				if e.length>tabica
					selborrar.push e
				end	
			end
		end
	end
	escalera.entities.erase_entities selborrar if selborrar!=[]
	#UI.messagebox('segundo')
	#borramos el plano del suelo
	selborrar=[]
	escalera.entities.each do |e|
		if e.typename=='Edge'
			if e.start.position.z==cota && e.end.position.z==cota && e.faces.size==1
				selborrar.push e
			end
		end
	end	
	escalera.entities.erase_entities selborrar
	#UI.messagebox('tercero')
	#borramos las que salgan de cero y tengan solo una cara para los laterales del primer peldaño
	selborrar=[]
	escalera.entities.each do |e|
		if e.typename=='Edge'
			if e.start.position.z==cota && e.faces.size==1 && vertical(e)
				borrar=false
				escalera.entities.each do |f|
					if f.typename=='Edge'
						borrar=true if f.start.position==e.end.position && vertical(f)
					end	
				end
				selborrar.push e if borrar 
			end
		end
	end	
	escalera.entities.erase_entities selborrar
	#UI.messagebox('Cuarto')
	#borramos lineas sueltas
	selborrar=[]
	escalera.entities.each do |e|
		if e.typename=='Edge'
			if e.faces.size==0
				selborrar.push e
			end
		end
	end	
	escalera.entities.erase_entities selborrar
	escalera.set_attribute "escalera","3d",false
end

def vertical (edge)
	if edge.start.position.x==edge.end.position.x && edge.start.position.y==edge.end.position.y
		return true
	else
		return false
	end	
end

def extrusiona (face, h)
	face.reverse! if face.normal.z < 0
	face.pushpull h, true
end

def long_valida(valor)
	return nil if !valor
	begin
        value=con_coma(valor).to_l
    rescue
        # Error parsing the text
        UI.beep
        value = nil
        Sketchup::set_status_text "", SB_VCB_VALUE
    end
	return value
end

def con_coma(text)
return text if $separador_listas==','
texto=''
for i in 0 .. text.length-1
	if text[i].chr=='.'
		texto=texto+','
	else
		texto=texto+text[i].chr
	end	
end	
return(texto)
end

def muestra_valor(t)
	Sketchup::set_status_text t, SB_VCB_VALUE
end

def borra_auxiliares
	if !@cl1.deleted?
		Sketchup.active_model.active_entities.erase_entities [@cl1, @cl2]
	end if @cl1	
end

def crea_auxiliares(pt)
	@cl1 = Sketchup.active_model.active_entities.add_cline pt, [0,0]
	@cl2 = Sketchup.active_model.active_entities.add_cline pt, [0,0]
	@cl1.direction = [$hv[0], $hv[1]]
	@cl2.direction = [-$hv[1], $hv[0]]
	@cl1.stipple = @cl2.stipple = "."
	@cl1.start = @cl1.end = @cl2.start = @cl2.end = nil
end

def mocheta_puerta(carp)
	ancho=ancho_carpinteria(carp)
	ptos = []
	# Buscamos los extremos desde el origen y los transformamos para colocarlos sobre la instancia 
	extremo1 = [0, 0, 0].transform! carp.transformation
	extremo2 = [ancho, 0, 0].transform! carp.transformation
	# Dibujamos una linea para tener vertices en las mochetas
	linea = Sketchup.active_model.active_entities.add_line extremo1, extremo2
	# Buscamos las mochetas en cada vertice
	linea.vertices.each do |ver|
		mocheta = nil
		ver.edges.each do |moch|
			# estan en el mismo grupo, componente o modelo
			if mismo_grupo(moch, carp)
				if perpendicular(linea, moch)
					ptos.push(moch.start.position) if !mocheta 
					mocheta = moch
				end
			end	
		end
		ptos.push(mocheta.end.position) if mocheta
	end
	Sketchup.active_model.active_entities.erase_entities linea
	return ptos
end

def a_numero(valor)
	valor=con_coma(valor.to_s)
	begin
		numero=valor.to_l
	rescue	
		numero = 0
	end
	return(numero)
end	

def angulo_recta(p1,p2)
	# devuelve el angulo con la horizontal de una recta dada por los extremos p1 y p2
	if p1[0] == p2[0] #iguales x
		if p1[1] < p2[1]
			return Math::PI/2
		else
			return Math::PI*3/2
		end	
	elsif p1[1] == p2[1]
		if p1[0] < p2[0]
			return 0.0
		else	
			return Math::PI
		end	
	else
		result = Math::atan((p2[1]-p1[1])/(p2[0]-p1[0]))
		result += Math::PI if p1[0] > p2[0] 
		result += Math::PI*2 if result < 0.0 
		return result
	end	
end

def perpendicular(linea1, linea2) # edges
	#verdadero si dos edges son perpendiculares
	return true	if (linea1.start.position-linea1.end.position).perpendicular? (linea2.start.position-linea2.end.position)
end

def angulo_inverso(angulo)
	if angulo < Math::PI
		return(angulo + Math::PI) 
	else 
		return(angulo - Math::PI)
	end
end	

def punto_en_segmento(pt, pt1, pt2)
	return false if !pt || !pt1 || !pt2
	return true if (pt-pt1).length+(pt-pt2).length < (pt1-pt2).length+0.0001
	return true if (pt-pt1).length < 0.0001
	return true if (pt-pt2).length < 0.0001
	return false
end

def punto_a_distancia(pt1, pt2, dist)
	return pt1 if dist==0
	@long = (pt1 - pt2).length
	return nil if @long == 0.0 
	return Geom.linear_combination  dist/@long, pt2, 1-(dist/@long), pt1
end

def punto_medio(pt1, pt2)
	return Geom.linear_combination 0.5, pt1, 0.5, pt2
end

def busca_cara(x, y, view)
	ph = view.pick_helper
	ph.do_pick x, y
	return ph.picked_edge
end

def otra_cara_perp (cara1,pt)
	return nil if cara1.faces.size != 1
	gru = 100000.0
	resultado = nil
	vec1 = cara1.start.position - cara1.end.position
	face = cara1.faces[0]
	face.edges.each do |e|
		if cara1 != e
			vec2 = e.start.position - e.end.position
			if vec1.parallel? vec2
				pt1 = pt.project_to_line e.line
				vec3 = pt - pt1
				if punto_en_segmento(pt1, e.start.position, e.end.position) #Está en la perpendicular
					# para que no haga muro con dos lineas paralelas myu juntas de la misma face
					#if face.classify_point(punto_medio(pt,pt1)) == Sketchup::Face::PointInside 
					ptos=tramo_comun(linea_extremos(cara1),linea_extremos(e))
						if vec3.length < gru
							gru = vec3.length
							resultado = e
							#@dar_vuelta = vec1.normalize != vec2.normalize 
							# @ptperp usado por otros procedimientos
							@ptperp = pt1
						end	if ptos[0] != ptos[1]
					#end
				end	
			end
		end	
	end
	return resultado
end	

def linea_extremos(e)
	return([e.start.position,e.end.position])
end

def tramo_comun(l1, l2)
	return[] if (l1[0]-l1[1]).length.to_f<0.000001 
	return [] if (l1[0]-l1[1]).length.to_f<0.000001
	return [] if !((l1[0]-l1[1]).parallel? (l1[0]-l1[1])) #si no son paralelas
	pt1 = l1[0]
	pt2 = l2[0].project_to_line (l1)
	pt3 = l2[1].project_to_line (l1)
	pt4 = l1[1]
	if (pt2 == pt4) or (pt3 == pt1)
		ptini = pt3
		pt3 = pt2
		pt2 = ptini
	end
	if punto_en_segmento(pt1 , pt2, pt3)
		ptini = pt1 
	elsif punto_en_segmento(pt2 , pt1, pt4)	
		ptini = pt2 	
	elsif punto_en_segmento(pt3 , pt1, pt4)
		ptini = pt3
	elsif
		punto_en_segmento(pt4 , pt2, pt3)
		ptini = pt4
	else
		return []
	end	
	if punto_en_segmento(pt4 , pt2, pt3)
		ptfin = pt4 
	elsif punto_en_segmento(pt3 , pt1, pt4)	
		ptfin = pt3 	
	else
		ptfin = pt2
	end	
	return[ptini, ptfin] 
end

def inicioundo(comando)
	Sketchup.active_model.start_operation comando, false, true, false
end

def finalundo
	Sketchup.active_model.start_operation "", false, false, false
end

def borra_coplanarias(caras)#edges
	selborrar = []
	caras.each do |e|
		if !e.deleted? 
			if (e.faces.size == 2) 
				selborrar.push e if (e.faces[0].normal.dot(e.faces[1].normal) > 0.99999999) 
			end
		end	
	end
	if 	selborrar != []
		model = selborrar[0].model
		model.active_entities.erase_entities selborrar
	end	
end 
 
 def selecciona_entidades(model) #decide si se debe usar entities o active_enities
	if model==Sketchup.active_model
		return model.entities
	else
		return model.entities
	end	
 
 end
 
def borra_coplanarias_3d (model) #borra planos verticales interiores y coplanarias en  model 
	entidades=selecciona_entidades(model)
	selborrar = []
	entidades.each do |e|
		if e.typename == "Edge"
			if (e.faces.size == 3)
				#primero las horizontales dos normales verticales
				if e.start.position.z == e.end.position.z and e.faces[0].normal.z+e.faces[1].normal.z+e.faces[2].normal.z>1.999999
					selborrar.push e# if (e.faces[0].normal.dot(e.faces[1].normal) > 0.99999999) 
				end
			end
		end
	end
	entidades.erase_entities selborrar if selborrar != []
	selborrar = []
	entidades=selecciona_entidades(model)
	entidades.each do |e|
		if e.typename == "Edge"
			if (e.faces.size == 2)
				selborrar.push e if (e.faces[0].normal.dot(e.faces[1].normal) > 0.99999999) 
			end
		end
	end
	entidades.erase_entities selborrar if selborrar != []  
end
 
def borra_muro(x, y, view, modoundo) # noundo indica si entra en revoca y si arregla los dos extremos
	cara1 = busca_cara(x, y, view)
	if cara1 
		cara2 = otra_cara_perp(cara1, (view.inputpoint x,y).position)
		if cara2
			# Quitamos las caras de la seleccion 
			Sketchup.active_model.selection.remove cara1, cara2
			ptos = tramo_comun(linea_extremos(cara1), linea_extremos(cara2))
			pt1 = ptos[0]
			pt2 = pt1.project_to_line cara2.line
			pt3 = ptos[1]
			pt4 = pt3.project_to_line cara2.line 
			lado = (pt1 - (view.inputpoint x,y).position).length - (pt3 - (view.inputpoint x,y).position).length	
			#inicioundo("borrar muro") if modoundo
			# cerramos el segmento de muro a borrar
			extremos =[]
			extremos.push(Sketchup.active_model.active_entities.add_line pt1, pt2)
			extremos.push(Sketchup.active_model.active_entities.add_line pt3, pt4)
			# borramos las caras
			borrar = Sketchup.active_model.active_entities.add_line pt1, pt3
			Sketchup.active_model.active_entities.erase_entities borrar
			borrar = Sketchup.active_model.active_entities.add_line pt2, pt4
			Sketchup.active_model.active_entities.erase_entities borrar
			# preparamos contenedor para puntos de resultado
			result = [pt1, pt2, pt3, pt4] 
			# comprobamos si los extremos pertenecen a un muro
			extremo1=false # controlamos cada extremo
			extremos.each do |e|
				# si no estan borrados es que estan sueltos o en un resto triangular 
				if !e.deleted?
					if e.faces.size == 0
						# si no tiene caras borramos 
						Sketchup.active_model.active_entities.erase_entities e
					else	
						# las dos caras en los extremos
						pt = ptt = linea1 = linea2 = vert1 = vert2 = vert3 = linea3 = nil
						e.vertices.each do |vert|
							vert.edges.each do |lin|
								# tiene que ser un muro
								if lin != e  && lin.faces.size == 1
									if e.faces.first == lin.faces.first
										# ponemos linea1 como perpendicular
										if (perpendicular(e,lin) && !linea1) || linea2
											linea1 = lin
											vert1 = vert.position
											vert3 = lin.other_vertex vert
											vert3.edges.each do |lin2|
												if lin2.faces.size == 1
													linea3 = lin2 if lin2 != lin
												end
											end
										else
											linea2 = lin
											vert2 = vert.position
										end
									end	
								end
							end
						end
						# el muro esta interrumpido en el medio por una linea	
						if !perpendicular(e,linea2)
							if otra_cara_perp(linea2,vert2) == linea3 # hay solo dos muros
								if extremo1
									result[2] = vert2
									result[3] = vert3.position
								else
									result[0] = vert2
									result[1] = vert3.position
								end				
								# ponemos el extremo ortogonal al muro	
								if !modoundo && ((lado <= 0 && extremo1) || (lado > 0 && !extremo1))
									Sketchup.active_model.active_entities.add_line vert2, vert3
									Sketchup.active_model.active_entities.erase_entities linea1, e
								else
									pon_color((Sketchup.active_model.active_entities.add_line vert2, @ptperp),linea1.material)
									linea3 = Sketchup.active_model.active_entities.add_line vert3, @ptperp
									pon_color(linea3,linea1.material)
									Sketchup.active_model.active_entities.erase_entities linea1, e, linea3
								end
							else
								ptt = Geom.intersect_line_line(linea3.line, linea2.line)
								pt = Geom.intersect_line_line(linea1.line, linea2.line) #if !ptt
								if pt # no son paralelas
									if extremo1
										result[2] = vert2
										result[3] = pt
									else
										result[0] = vert2
										result[1] = pt
									end	
									if ptt && (ptt-vert2).length < (pt-vert2).length
										face = Sketchup.active_model.active_entities.add_face ptt, vert3.position, vert1, vert2
									else	
										face = Sketchup.active_model.active_entities.add_face pt, vert1, vert2
									end
									caras = face.edges
									Sketchup.active_model.active_entities.erase_entities e
									caras.each do |l|
										if !l.deleted?
											Sketchup.active_model.active_entities.erase_entities l if l.faces.size != 1
										end	
									end if caras
								end	
							end
						end
					end	
				end
				extremo1 = true if !extremo1	
			end	
			view.invalidate
			@borrando = false
			if !(result[0]-result[2]).parallel? (result[1]-result[3]) 
				paso = result[2]
				result[2] = result[3]
				result[3] = paso
			end
			return result
		end
	end
	return false
end

def mismo_grupo (x, y)
	return true	if x.model == y.model 
end
 
def interseccion_real (pt1, pt2, pt3, pt4)
	pt1=Geom::Point3d.new(pt1)if pt1.class==Array
	pt2=Geom::Point3d.new(pt2)if pt2.class==Array
	pt3=Geom::Point3d.new(pt3)if pt3.class==Array
	pt4=Geom::Point3d.new(pt4)if pt4.class==Array
	return pt1 if pt1==pt3 || pt1==pt4
	return pt2 if pt2==pt3 || pt2==pt4
	pt = Geom.intersect_line_line ([pt1, pt2],[pt3, pt4])
	return pt if punto_en_segmento(pt, pt1, pt2) && punto_en_segmento(pt, pt3, pt4)
	return nil
end 

def interseccion_real_edges (e1,e2)
	pt1=e1.start.position
	pt2=e1.end.position
	pt3=e2.start.position
	pt4=e2.end.position
	return interseccion_real (pt1,pt2,pt3,pt4)
end	

def es_carpinteria(carp)
	# comprobamos que esta dentro de un ComponentInstance y que es una carpinteria
	return false if carp.definition.name.index('3D') 
	if carp.definition.name[0,12] == "DIBAC_PUERTA" || carp.definition.name[0,13] == "DIBAC_VENTANA" || carp.definition.name[0,13] == "DIBAC_ARMARIO"
		return true
	else
		return false
	end
end

def ancho_carpinteria(carp)
	if carp.definition.name[0,12] == "DIBAC_PUERTA"
		ancho =(carp.get_attribute "dynamic_attributes", "a01hoja1").to_l+
				(carp.get_attribute "dynamic_attributes", "a01hoja2").to_l+	
				2*(carp.get_attribute "dynamic_attributes", "anchomarco").to_l
	else
		ancho = (carp.get_attribute "dynamic_attributes", "a01ancho").to_l
		ancho = (carp.get_attribute "dynamic_attributes", "a01ancho").to_l
	end
	return ancho
end	

def muro_carpinteria(carp,ancho)
	# devuelve cuatro puntos definidos por la mocheta y el ancho de la carpinteria
	result = []
	result.push([0,0,0].transform! carp.transformation)
	result.push([0,-(carp.get_attribute "dynamic_attributes", "mocheta").to_l,0].transform! carp.transformation)
	result.push([ancho,-(carp.get_attribute "dynamic_attributes", "mocheta").to_l, 0].transform! carp.transformation)
	result.push([ancho, 0, 0].transform! carp.transformation)
	return result
end

def intermedios(linea,extremos,carpinterias) # Devuelve el primer punto de la line y las intesecciones con muros. 
	puntos = [] 
	Sketchup.active_model.active_entities.each do |e|
		if e.typename == "Edge"
			if e.faces.size == 1
				pt = interseccion_real(linea[0], linea[1], e.start.position, e.end.position)
				if extremos || (pt != linea[0] && pt != linea[1] && pt != puntos.last)
					puntos.push(pt)
				end if pt
			end	
		elsif e.typename == "ComponentInstance" && carpinterias
			if es_carpinteria(e)
				ptcarp=muro_carpinteria(e, ancho_carpinteria(e))
  				pt = interseccion_real(linea[0], linea[1], ptcarp[0], ptcarp[3])
				if extremos || (pt != linea[1] && pt != linea[2] && pt != puntos.last)
					puntos.push(pt)
				end if pt
				pt = interseccion_real(linea[0], linea[1], ptcarp[1], ptcarp[2])
				if extremos || (pt != linea[0] && pt != linea[1] && pt != puntos.last)
					puntos.push(pt)
				end if pt
			end
		end
	end
	return puntos if puntos.size < 2
	i = -1
	result=[]
	ultimadistancia=-1
	while i < puntos.size-1 do
		j = 0
		k = 0
		distancia = 1000000.0
		while j < puntos.size
			if puntos[j] 
				if (linea[0]-puntos[j]).length < distancia
					distancia = (linea[0]-puntos[j]).length
					punto = puntos[j]
					k = j
				end	
			end 
			j += 1
		end
		result.push(punto) if distancia > ultimadistancia
		ultimadistancia=distancia
		puntos[k] = nil
		i += 1
	end	
	return result
end

def onCancel(flag, view)
	reset
	view.lock_inference if ( view.inference_locked? )
	view.invalidate
	menu if flag==0 #para diferenciarlo de Ctrl-Z
end

def onRButtonDown(flags, x, y, view)
	reset
	view.invalidate
	menu
end	

def menu	
	reset #para las funciones que no tiene menu
end

def pon_cota_lineal(model, pt1, pt2)
	@componente = Sketchup.active_model.definitions.load (Sketchup.find_support_file "DIBAC_COTAL.skp","Plugins/Dibac")
	transform = Geom::Transformation.translation pt1
	transform = (Geom::Transformation.scaling pt1,(pt1-pt2).length,1,1) * transform 
	transform = (Geom::Transformation.rotation pt1, [0,0,1], angulo_recta(pt1,pt2)) * transform	
	@instance = model.entities.add_instance(@componente,transform)
	@cota=@instance.explode	
	@cota[0].set_attribute "dibaccotas", "pt1", pt1
	@cota[0].set_attribute "dibaccotas", "pt2", pt2
	return @cota
end

def pon_color(entidad,mat)
	if mat =="<Ninguno>"
		mat = nil
	end
	entidad.material=mat
	entidad.back_material = mat if entidad.typename == "Face"
end

end # de la clase Dibac 

class Dibac_Borrar < Dibac_Base
=begin
 Clase	        		:	Borrar
 Desciende de		:	Dibac
 Descripción   		:	Realiza el borrado de elementos de Dibac
 Item de Menu  	:	Dibujo->Dibac->Borrar elementos Dibac // Barra de herramientas Dibac
 Menú contextual	:	NO
 Uso         			:	Se marca lo que se quiere borrar y se reparan lo empalmes o se cierran los huecos de
								carpinterias.
								Para que funcione a borrar muros hay que marcarlos en puntos donde la ortogonal corte a 
								la otra cara.
								Si se marcan elemento que no son de Dibac se realiza el borrado normal.

Fecha        			:	14/11/2010
=end
def initialize
	reset
end

def reset
	@puntos_muro = []
	@carpinterias = []
	Sketchup::set_status_text "", SB_VCB_LABEL
	Sketchup::set_status_text "", SB_VCB_VALUE
	texto = $DibacStrings.GetString ("Select items to erase or drag across multiple items.")
	texto = texto + " Shift="+$DibacStrings.GetString ("Hide")
	texto = texto +", Ctrl="+$DibacStrings.GetString ("Soften/Smoth")
	texto = texto +", Alt="+$DibacStrings.GetString ("Dibac")+"."
	Sketchup::set_status_text  texto
	@cursor = $borrarcursor_id if !@cursor
end

def activate
	Sketchup.active_model.active_view.invalidate
	reset
end	

def onSetCursor
	UI.set_cursor(@cursor)
end

def borra_carpinteria(carp)
	# comprobamos que esta dentro de un ComponentInstance y que es una carpinteria
	return false if !es_carpinteria(carp)
	#if carp.definition.name[0,12] == "DIBAC_PUERTA"
	#	@comando_en_curso = "borrar puerta"
	#elsif carp.definition.name[0,13] == "DIBAC_VENTANA"
	#	@comando_en_curso = "borrar ventana"
	#elsif carp.definition.name[0,13] == "DIBAC_ARMARIO"
	#	@comando_en_curso = "borrar armario"
	#end
	ancho=ancho_carpinteria(carp)
	ptos = []
	# Si es una ventana utilizamos directamente la mocheta del componente
	# ptos = mocheta_puerta(carp) if carp.definition.name[0,12] == "DIBAC_PUERTA" ###################
	#si falta una alguna mocheta o si es una ventana
	ptos = muro_carpinteria(carp,ancho) if ptos.size < 4
	Sketchup.active_model.active_entities.erase_entities carp
	# sacamos las mochetas
	mocheta1 = Sketchup.active_model.active_entities.add_line ptos[0], ptos[1]
	mocheta2 = Sketchup.active_model.active_entities.add_line ptos[2], ptos[3]
	# determinamos la menor de las mochetas
	ptos = tramo_comun(linea_extremos(mocheta1),linea_extremos( mocheta2))
	# proyectamos sobre la segunda invirtiendo los puntos
	ptos.push(ptos[1].project_to_line(mocheta2.line))
	ptos.push(ptos[0].project_to_line(mocheta2.line))
	# hacemos el muro
	face = Sketchup.active_model.active_entities.add_face ptos
	face.edges.each do |e|
		pon_color(e, mocheta1.material)
	end	
	# borramos lineas sobrantes
	borra_coplanarias(face.edges)
	# para que no borre el muro inmediatamente despues de la ventana
	#@borrando = false
end

def selecciona(x, y, view)
	return if !@borrando
	ph = view.pick_helper
	ph.do_pick x, y
	e = ph.best_picked 
	if e.typename !="Face"
		Sketchup.active_model.selection.add e
		#if @pulsado_alt
			@puntos_muro.push [x,y] if e.typename == "Edge"
			@carpinterias.push e if e.typename == "ComponentInstance"
		#end
	end	
end

def onMouseMove(flags, x, y, view)
	selecciona(x, y, view)
end

def onLButtonDown(flags, x, y, view)
	@borrando = true
	selecciona(x, y, view)
end

def onLButtonUp(flags, x, y, view)
	@borrando = false
	sel = Sketchup.active_model.selection
	
	
	if @pulsado_shift && !@pulsado_ctrl
		inicioundo($DibacStrings.GetString("Hide"))
		sel.each { |e| e.hidden=true}	
		sel.clear
		finalundo
		return	
	end
	if @pulsado_ctrl && !@pulsado_shift
		inicioundo($DibacStrings.GetString("Soften edges"))
		sel.each { |e| e.soft=true }#if e.typename !="ComponentInstance"}	
		sel.clear
		finalundo
		return	
	end
	inicioundo($DibacStrings.GetString("Erase"))	
	if @pulsado_alt
		@carpinterias.each do |carp|
			borra_carpinteria(carp) if !carp.deleted?
		end
		@puntos_muro.each do |pt|
			borra_muro(pt[0], pt[1], view, true)
		end
		reset
	end
	Sketchup.active_model.active_entities.erase_entities sel
	finalundo
end

def onKeyDown(key, rpt, flags, view)
	@pulsado_shift = true if key == CONSTRAIN_MODIFIER_KEY
	@pulsado_ctrl = true if key == COPY_MODIFIER_KEY
	@pulsado_alt = true if key == ALT_MODIFIER_KEY
	#@cursor = $borrarcursordibac_id if key == ALT_MODIFIER_KEY
end

def onKeyUp(key, rpt, flags, view)
	#@cursor = $borrarcursor_id
	@pulsado_shift = false if key == CONSTRAIN_MODIFIER_KEY
	@pulsado_ctrl = false if key == COPY_MODIFIER_KEY
	@pulsado_alt = false if key == ALT_MODIFIER_KEY

end

def draw(view)
	textoevaluacion(view)
end

end # de la clase Borrar

class Dibac_Muro < Dibac_Base
=begin
 Clase	        		:	Muro
 Desciende de		:	Dibac
 Descripción   		:	Dibuja muros en planta
 Item de Menu  	:	Dibujo->Dibac->Muro // Barra de herramientas Dibac
 Menú contextual	:	NO
 Uso         			:	Para dibujar el muro primero se tiene que proporcionar el
								punto de arranque. Luego se van marcando los puntos sucesivos.
								Pulsando [Tab] se cambia la cara de enganche entre izquierda,
								centro y derecha sucesivamente.
								Si se introdue un numero positivo se toma como longitud en la direccion marcada.   
								Si se introduce un numero negativo se toma como espesor del	muro.
								Para terminar una secuencia de muro se pulsa [Esc].
								Cuando se engancha a una arista esta se marca en magenta.
								Para cambiar el angulo del de las guias se introduce el caracter "<" (menor que)
								sequido el nuevo angulo
								Si se introduce una secuencia de numeros separados por $separador_listas se interpretara que cada uno
								de ellos sera un muro girado 90 grados o -90 grados segun el signo y con la longitud del numero
								asi para introducir una planta en L de lados 5,10,5,5,10,15 introducimos lo siguiente desde el
								primer punto saliendo a la derecha 5;10;-5;5;10;15
             		   
             		  
 Fecha        			:	14/11/2010
=end

def initialize
	exit if nolicencia
	@ip = Sketchup::InputPoint.new
	@ip1 = Sketchup::InputPoint.new
end

def menu	
	prompts = 	[$DibacStrings.GetString("Thickness")	]
		defaults = [	$muro_width.to_l.to_s
						]
	list = 			[	""
						]
				
	input = UI.inputbox prompts, defaults, list, $DibacStrings.GetString("Wall")
	if input
		h1 = a_numero(input[0]).abs
		$muro_width = h1 if h1>0
		case input[1].to_s
		when $DibacStrings.GetString("Left") 
			$muro_cara=0.0
		when $DibacStrings.GetString("Center") 
			$muro_cara=0.5
		when $DibacStrings.GetString("Right")
			$muro_cara=1.0
		end
		h1 = input[2].to_s.upcase
	else	
		Sketchup.active_model.select_tool nil	
		exit
	end	
	reset
end

def reset
	borra_auxiliares
	Sketchup.active_model.commit_operation if @primer_punto
	@primer_punto = @pulsado_tab = false
	# puntos temporales para el muro enganchado al cursor
	@ptini = @ptfin = @pt1 = @pt2 = @pt3 = @pt4 = []
	# aristas a las que se engancha al principio y al final
	@arini = @arfin = @lineai = @linead = @vertice1 = @vertice2 = nil
	Sketchup::set_status_text "", SB_VCB_LABEL
	Sketchup::set_status_text "", SB_VCB_VALUE
	texto_comando
end

def activate
	Sketchup.active_model.active_view.invalidate
	menu
	@comando_en_curso = "Wall"
	reset
end

def texto_comando
	texto = $DibacStrings.GetString("Wall") +"["+ $muro_width.to_l.to_s+"]."
	if !@primer_punto
		texto = texto+$DibacStrings.GetString("Starting point")
	else	
		texto= texto+$DibacStrings.GetString("End point")
	end	
	texto = texto + ", " + $DibacStrings.GetString("or specify thickness preceded by") + " '-'."
	texto = texto + " Tab="+$DibacStrings.GetString("Change edge")+"." if @primer_punto
	Sketchup::set_status_text  texto 
end		

def deactivate(view)
	view.invalidate
	reset
end

def onSetCursor
	UI.set_cursor($murocursor_id)
end

def calcula_puntos
	return false if !@primer_punto
	if @comando_en_curso == "Wall"
		if @vertice1 && @vertice2
			vec = (@vertice1.position - @vertice2.position)
			@ptini = @vertice1.position.offset(vec, -$muro_cara*vec.length)
		end	
	end	
	i = 1
	while i < 5  
		if $muro_cara > 0 then
			vec = @ptini - [@ptini[0] + (@ptfin[1] - @ptini[1]), @ptini[1] - (@ptfin[0] - @ptini[0]),@ptini[2]]
			@pt1 = @ptini.offset(vec, $muro_cara * $muro_width)	 
			@pt2 = @ptfin.offset(vec, $muro_cara * $muro_width)
		else
			@pt1 = @ptini	 
			@pt2 = @ptfin	   
		end
		vec = @ptini - [@ptini[0] - (@ptfin[1] - @ptini[1]), @ptini[1] + (@ptfin[0] - @ptini[0]),@ptini[2]]
		@pt3 = @pt1.offset(vec, $muro_width)	 
		@pt4 = @pt2.offset(vec, $muro_width)	   
		if @arfin 
			pt0 = Geom.intersect_line_line([@pt1, @pt2], @arfin.line)
			pt1 = Geom.intersect_line_line([@pt3, @pt4], @arfin.line)
			if 	punto_en_segmento(pt0,@arfin.start.position,@arfin.end.position )
				@pt2 = pt0
				@pt4 = pt1
			end	if punto_en_segmento(pt1,@arfin.start.position,@arfin.end.position )
		end
		if @lineai && @linead
			# Si existe la interseccion movemos el extremo
			@pt1 = pt0 if pt0 = Geom.intersect_line_line([@pt1, @pt2], @lineai)
			@pt3 = pt0 if pt0 = Geom.intersect_line_line([@pt3, @pt4], @linead)
		elsif @arini
			pt0 = Geom.intersect_line_line([@pt1, @pt2], @arini.line)
			pt1 = Geom.intersect_line_line([@pt3, @pt4], @arini.line)
			if 	punto_en_segmento(pt0,@arini.start.position,@arini.end.position )
				@pt1 = pt0 
				@pt3 = pt1 
				#@pulsado_tab = true
				return true
			end if punto_en_segmento(pt1,@arini.start.position,@arini.end.position )
			if !@pulsado_tab
				i += 1 
				tabulador 
			end 
		end	
		i = 5 if !@arini || @pulsado_tab
	end
	@pulsado_tab = true
end
 
def onMouseMove(flags, x, y, view)
    return false if( !@ip.pick(view, x, y, @ip1) )
	texto_comando # por si se ha borrado con otro comando
	# pone tooltip segun el elemento al que se aproxime
	view.tooltip = @ip.tooltip
	if !@primer_punto
		view.invalidate if @arini = busca_cara(x, y, view)
    else
		@ptfin = @ip.position
		vec = @ptini - @ptfin
		Sketchup::set_status_text vec.length.to_s, SB_VCB_VALUE
		calcula_puntos
	end
	@arfin = busca_cara(x, y, view)
	view.invalidate
end
 
def haz_muro
	puntos = intermedios([@pt1,@pt2], false,false).unshift(@pt1)
	pt1 = puntos.last
	puntos = puntos + intermedios([@pt2,@pt4], false,false).unshift(@pt2)
	x = intermedios([@pt4,@pt3], false,false).unshift(@pt4)
	pt2 = @pt3
	pt2 = x[1] if x.size > 1
	puntos = puntos + x
	puntos = puntos + intermedios([@pt3,@pt1], false,false).unshift(@pt3)
	face = Sketchup.active_model.active_entities.add_face puntos 
	pon_color(face,$color_superficies)
	selborrar = []
	Sketchup.active_model.active_entities.each do |e|
		if e.typename == "Edge"
			if face.classify_point(punto_medio(e.start.position,e.end.position)) == Sketchup::Face::PointInside
				selborrar.push(e)
			end
		end
	end
	Sketchup.active_model.active_entities.erase_entities selborrar if selborrar != []
	# conservamos las lineas para interseccion en calcula puntos
	@lineai = [@pt1, @pt2]
	@linead = [@pt3, @pt4]
	# sacamos el extremo frontal
	linea_ult = Sketchup.active_model.active_entities.add_line @pt2, @pt4
	pon_color(linea_ult,$color_lineas)
	# sacamos los vertices
	@vertice1 = linea_ult.start
	@vertice2 = linea_ult.end
	# guardamos las caras
	caras = face.edges
	caras.each do |e|
		pon_color(e,$color_lineas)
	end
	# borramos aristas coincidentes
	borra_coplanarias(caras)
	@ptini = @ptfin
	# si se ha borrado la cara frontal del muro
	if linea_ult.deleted?
		reset
		# salimos sin inicioundo
		return false
	end
	return true
end

def create_muro
	finalundo
	if @lineai && @linead
		# Si existe la interseccion movemos el extremo
		vec = @pt1-@vertice1.position
		Sketchup.active_model.active_entities.transform_entities(vec, @vertice1) if vec.length > 0
		vec = @pt3-@vertice2.position
		Sketchup.active_model.active_entities.transform_entities(vec, @vertice2) if vec.length > 0 
	end
	inicioundo($DibacStrings.GetString("Wall")) if haz_muro
	@pulsado_tab = false
end

def onLButtonDown(flags, x, y, view)
	borra_auxiliares
	@ip1.copy! @ip
	if !@primer_punto
		inicioundo($DibacStrings.GetString("Wall"))
		@ptini = @ip.position
		Sketchup::set_status_text $DibacStrings.GetString("Length"), SB_VCB_LABEL
		@primer_punto = true
	else
		create_muro
		@arini = nil
		@long_usuario = false
	end
	crea_auxiliares(@ptini)
	texto_comando
	view.lock_inference
	view.invalidate
end

def longitud_usuario (valores, view) # view por si un dia funciona el posicionar el cursor
	# longitud del muro
	vec = @ptfin - @ptini
	if( vec.length > 0.0 )
		valores.each do |value|
			vec = @ptini - @ptfin if value.to_l < 0
			vec.length = value.to_l.abs
			@ptfin = @ptini.offset(vec)
			#@ip1.pick(view, view.screen_coords(@ptfin).x, view.screen_coords(@ptfin).y,@ip) 
			#@ptfin = @ip1.position
			calcula_puntos
			ptperp = @ptini.transform (Geom::Transformation.rotation @ptfin, [0,0,1], Math::PI/2)
			create_muro
			@arini = nil
			@ptfin = ptperp
			vec = @ptfin - @ptini
		end
	end
end

def onUserText(text, view)
	text=con_coma(text)
	valores = text.split("*") #muro paralelo
    value = valores[1].to_i
	if value > 0
		muro_multiplica(value)
		return
	end
	valores = text.split("/") #muro paralelo
    value = valores[1].to_i
	if value >  0
		muro_multiplica(1.0/value)
		return
	end
	valores = text.split("<")
	if valores[1]
		angulo = valores[1].to_f.degrees
		$hv = [Math.cos(angulo), Math.sin(angulo)]
		borra_auxiliares
		crea_auxiliares(@ptini) if @primer_punto
		return
	end
	# Aqui se introducen las longitudes si positivas o el grueso negativo
	valores = text.split($separador_listas)
	value=long_valida(valores[0])
    if value
		if value < 0 then
			# grueso del muro
			$muro_width = value.abs.to_l
			texto_comando
			calcula_puntos
		else
			borra_auxiliares
			longitud_usuario(valores, view)
			crea_auxiliares(@ptini)
		end
		view.invalidate
		return
	end
end

def draw(view)
	textoevaluacion(view)
    # Muestra el punto actual
    @ip.draw(view) if( @ip.valid? && @ip.display? )
	# pone en rojo las lineas a las que engancha
    if @arini
		view.line_width = 4
		view.drawing_color = "magenta"
		view.draw(GL_LINE_STRIP, @arini.start.position,@arini.end.position)
	end
    if @arfin
		view.line_width = 4
		view.drawing_color = "magenta"
		view.draw(GL_LINE_STRIP, @arfin.start.position,@arfin.end.position)
	end
    # previsualiza el muro
    view.drawing_color = "black"
    view.line_width = 1 
    inference_locked = view.inference_locked?
	view.set_color_from_line(@ip1, @ip)
	view.line_width = 4 if inference_locked
    view.draw(GL_LINE_STRIP, @pt2, @pt4)
	view.draw(GL_LINE_STRIP, @pt1, @pt2)
    view.draw(GL_LINE_STRIP, @pt3, @pt4)
	view.draw(GL_LINE_STRIP, @vertice1.position, @pt1) if @vertice1
	view.draw(GL_LINE_STRIP, @vertice2.position, @pt3) if @vertice2
    view.draw(GL_LINE_STRIP, @pt1, @pt3) if !@vertice1
end

def tabulador
	if $muro_inc then
		$muro_cara += 0.5
	elsif
		$muro_cara -= 0.5
	end	
	$muro_inc = !$muro_inc if $muro_cara != 0.5
end

def onKeyDown(key, rpt, flags, view)
	if key == 9 then
		borra_auxiliares
		tabulador
		calcula_puntos
		crea_auxiliares(@ptini) if @comando_en_curso=="Wall"
		view.invalidate
		@pulsado_tab = true if @primer_punto
	elsif key == 119 #F8
		lb = @arfin.line 
		if lb
			$hv = [lb[1][0],lb[1][1]] #coseno y seno del angulo
			borra_auxiliares
			crea_auxiliares(@ptini) if @primer_punto
		end
	elsif( key == CONSTRAIN_MODIFIER_KEY && rpt == 1 )
        # Si esta activado desactivarlo
        if( view.inference_locked? )
            view.lock_inference
        elsif !@primer_punto
            view.lock_inference @ip
        elsif
            view.lock_inference @ip, @ip1
		end
	end	
end	

def onKeyUp(key, rpt, flags, view)
	if(key == CONSTRAIN_MODIFIER_KEY && view.inference_locked?)
		view.lock_inference
    end
end

end # de la clase Muro

class Dibac_Murop < Dibac_Muro
=begin
 Clase	        		:	Murop
 Desciende de		:	Muro
 Descripción   		:	Dibuja muros paralelos a una linea cualquiera en planta
 Item de Menu  	:	Dibujo->Dibac->Muro paralelo // Barra de herramientas Dibac
 Menú contextual	:	NO
 Uso         			:	Primero se tiene que proporcionar la linea base que aparecera en magenta
								Luego se arrastra el muro hasta la posicion deseada.
								Pulsando [Tab] se cambia la cara de enganche entre izquierda,
								centro y derecha sucesivamente.
								Si se introdue un numero positivo se toma como distancia a la linea base.   
								Si se introduce un numero negativo se toma como espesor del	muro.
								Para terminar una secuencia de muro paralelo se pulsa [Esc].
             		  
 Fecha        			:	14/11/2010
=end

def reset
	@comando_en_curso = "Paralell wall"
	@primer_punto = @pulsado_tab = false
	# puntos temporales para el muro enganchado al cursor
	@ptini = @ptfin = @pt1 = @pt2 = @pt3 = @pt4 = []
	# aristas a las que se engancha al principio y al final
	@arini = @arfin = @lineai = @linead = @vertice1 = @vertice2 = nil
	Sketchup::set_status_text "", SB_VCB_LABEL
	Sketchup::set_status_text "", SB_VCB_VALUE
	texto_comando
end

def deactivate(view)
	view.invalidate
	$penultima_dist=@ultima_dist if @ultima_dist
end	

def create_muro
	inicioundo($DibacStrings.GetString("Paralell wall"))
	@ultp1=@lbase.start.position
	@ultp2=@lbase.end.position
	@ultimo_punto=@primer_punto
	$penultima_dist=@ultima_dist if @ultima_dist
	@ultima_dist=@perp.length
	haz_muro
	finalundo
	reset
end

def muro_multiplica(value)
	if( @perp.length > 0.0 )
		if !@primer_punto 
			Sketchup.undo
			inicioundo($DibacStrings.GetString("Paralell wall"))
			longitud=@perp.length
			if value>=1
				paso = longitud 
			else
				paso = longitud*value
				value=1/value
			end
			for i in 1..value
				@perp.length=paso*i
				@primer_punto=@ultimo_punto
				@lbase=Sketchup.active_model.active_entities.add_line @ultp1, @ultp2	
				@ptini = @lbase.start.position.offset(@perp)
				@ptfin = @lbase.end.position.offset(@perp)
				calcula_puntos
				haz_muro
			end
			finalundo
			@perp.length = longitud
			reset
		end
	end	
end

def texto_comando
	texto = $DibacStrings.GetString("Paralell wall")+"["+$muro_width.to_l.to_s+"]."
	if !@primer_punto
		texto = texto + $DibacStrings.GetString("Baseline")
	else
		texto = texto + $DibacStrings.GetString("Position of wall")
	end
	texto = texto + ", " + $DibacStrings.GetString("or specify thickness preceded by") + " '-'."
	texto = texto + " Tab="+$DibacStrings.GetString("Change edge")+"." if @primer_punto
	Sketchup::set_status_text texto
end		

def onSetCursor
	UI.set_cursor($muropcursor_id)
end

def onMouseMove (flags, x, y, view)
	texto_comando
    return false if !@ip.pick(view, x, y, @ip1) 
	# pone tooltip segun el elemento al que se aproxime
	view.tooltip = @ip.tooltip
	if !@primer_punto
		view.invalidate if @arini = busca_cara(x, y, view)
    else
	    @ptfin = @ip.position
        @ptini = @ptfin.project_to_line [@lbase.start,@lbase.end]
        @perp = @ptfin - @ptini
		Sketchup::set_status_text @perp.length.to_s, SB_VCB_VALUE
		@ptini = @lbase.start.position.offset(@perp)
		@ptfin = @lbase.end.position.offset(@perp)
		calcula_puntos
	end
	view.invalidate
end

def onLButtonDown(flags, x, y, view)
	if !@primer_punto
		@ip1.copy! @ip
		@lbase = busca_cara(x, y, view)
		if @lbase	
			#crea_auxiliares(@ip.position)
			@primer_punto = true
		end	
	else
		create_muro
	end
	texto_comando
	view.lock_inference
end

def onLButtonDoubleClick(flags, x, y, view)
	if $penultima_dist
		longitud_usuario ([$penultima_dist.to_s],view) if $penultima_dist>0
	end	
end

def longitud_usuario (valores, view) 
	# distancia a paralela
	if( @perp.length > 0.0 )
		if !@primer_punto 
			Sketchup.undo
			@primer_punto=@ultimo_punto
			@lbase=Sketchup.active_model.active_entities.add_line @ultp1, @ultp2
		end
		@perp.length = valores[0].to_l
		@ptini = @lbase.start.position.offset(@perp)
		@ptfin = @lbase.end.position.offset(@perp)
		calcula_puntos
		create_muro
	end	
end

end # de la clase Murop

class Dibac_Estiramuro < Dibac_Muro
=begin
 Clase	        		:	Estiramuro
 Desciende de		:	Muro
 Descripción   		:   Estira/acorta un muro existente
 Item de Menu  	:	Dibujo->Dibac->Prolongar muro // Barra de herramientas Dibac
 Menú contextual	:	NO
 Uso         			:	Se marca el muro por una de las caras en un punto proximo al extremo que queremos mover
								la linea elegida se marcara en magenta.
								Luego se arrastra el extremo hasta la posicion deseada.
             		  
 Fecha        			:	14/11/2010
=end

def menu
end

def reset
	@comando_en_curso = "Extend wall"
	Sketchup.active_model.abort_operation if @primer_punto
	@primer_punto = false
	@pt1 = @pt2 = @pt3 = @pt4 = @vertice1 = @vertice2 = nil
	@arini = @arfin = nil
end

def create_muro
	haz_muro
	finalundo
end

def texto_comando
	texto = $DibacStrings.GetString("Extend wall")+": "
	if !@primer_punto
		texto = texto+$DibacStrings.GetString("Enter end to extend")+"."
	else
		texto = texto+$DibacStrings.GetString("Enter new position")+"."
	end	
	Sketchup::set_status_text texto
end		

def onSetCursor
	UI.set_cursor($estiramurocursor_id)
end

def calcula_puntos
	if @arfin 
		pt0 = Geom.intersect_line_line([@pt1, @pt2], @arfin.line)
		@pt1 = pt0 if pt0
		@pt3 = @pt1.project_to_line [@puntos[1], @puntos[3]]
		pt0 = Geom.intersect_line_line([@pt3, @pt4], @arfin.line)
		@pt3 = pt0 if punto_en_segmento(pt0, @arfin.start.position, @arfin.end.position)	
	else
		@pt1 = @ip.position.project_to_line [@puntos[0], @puntos[2]]
		@pt3 = @pt1.project_to_line [@puntos[1], @puntos[3]]
	end
end

def onMouseMove (flags, x, y, view)
	texto_comando
    return false if !@ip.pick(view, x, y, @ip1) 
	# pone tooltip segun el elemento al que se aproxime
	view.tooltip = @ip.tooltip
	if !@primer_punto
		view.invalidate if @arini = busca_cara(x, y, view) #@arini para que se ponga roja
    else
		@arfin = busca_cara(x, y, view)
		calcula_puntos
	end
	view.invalidate
end

def onLButtonDown(flags, x, y, view)
	if !@primer_punto
		pt = @ip.position
		cara = busca_cara(x, y, view)
		if cara	
			otracara=otra_cara_perp(cara, pt)
			return false if !otracara
			inicioundo($DibacStrings.GetString("Extend wall"))
			@puntos = borra_muro(x, y, view, false)
			lado = (@puntos[0] - pt).length - (@puntos[2] - pt).length
			if lado	<= 0 
				@pt1 = @puntos[0]
				@pt2 = @puntos[2]
				@pt3 = @puntos[1]
				@pt4 = @puntos[3]
			else
				@pt1 = @puntos[2]
				@pt2 = @puntos[0]
				@pt3 = @puntos[3]
				@pt4 = @puntos[1]
			end	
			@primer_punto = true
			@arini = nil
			calcula_puntos
		end	
		@ip1.copy! @ip # si se pone al principio da error en el punto medio
	else
		@primer_punto = false # para que no haga reset
		create_muro
		reset
	end
	texto_comando
	view.lock_inference
	view.invalidate
end

end # de la clase Estiramuro

class Dibac_Carpinteria < Dibac_Base
=begin
 Clase	        		:	Carpinteria
 Desciende de		:	Dibac
 Descripción   		:	Contiene funciones comunes a Puertas, Ventanas y Armarios
 Item de Menu  	:	
 Menú contextual	:	NO
 Uso         			:	
             		  
 Fecha        			:	14/11/2010
=end

def  activate
	Sketchup.active_model.active_view.invalidate
	menu
end	

def init_carpinteria
	@ip = Sketchup::InputPoint.new
	@transform = Geom::Transformation.new
	@cara1 = nil
	@angulo1 = 0.0
	@angulo2 = Math::PI*3/2
	Sketchup::set_status_text "", SB_VCB_LABEL
	Sketchup::set_status_text "", SB_VCB_VALUE
	@simetria_hueco = 1
	@pulsado_alt = false
	texto_comando
end

def siguiente_punto (x, y)
	ult = @p_c.last
	@p_c.push [ult[0]+x, ult[1]+y]
end

def siguiente_punto_rep (x, y)
	ult = @p_c.last
	@p_c.push [ult[0], ult[1]]
	@p_c.push [ult[0]+x, ult[1]+y]
end

def siguiente_linea (x1, y1, x2, y2)
	ult = @p_c.last
	@p_c.push [ult[0]+x1, ult[1]+y1]
	@p_c.push [ult[0]+x1+x2, ult[1]+y1+y2]
end

def set_transform(enmuro)
	pi =Math::PI
	if @angulo1 < pi/2  
		if @angulo2 > pi 
			@angulo2=@angulo2-2*pi
		end
	end	
	if @angulo1 >= 3*pi/2  
		if @angulo2 < pi 
			@angulo2=@angulo2+2*pi
		end
	end	
	if !enmuro
		@transform = Geom::Transformation.translation @ph1-[@carpinteria_hueco*@ancho/2,0,0]
	else	
		@transform = Geom::Transformation.translation @ph1
	end	
	@transform = (Geom::Transformation.scaling @ph1,1,-1,1) * @transform if @angulo2 > @angulo1
	@transform = (Geom::Transformation.rotation @ph1, [0,0,1], @angulo1) * @transform 
end

def hueco_maximo(cara1, cara2)
	return tramo_comun(linea_extremos(cara1), linea_extremos(cara2))
end

def puntos_hueco(posicion)
	@cara1 = @cara_ventana if @cara_ventana
	return false if !@cara1 
	@cara2 = otra_cara_perp(@cara1, posicion)	
	return false if !@cara2
	# guardamos el ancho por si hacemos ancho maximo
	@ancho_anterior = @ancho
	#segmento util de @cara1
	ptos = hueco_maximo(@cara1, @cara2)
	ptini = ptos[0]
	ptfin = ptos[1]
	# ptref1 y ptref 2 son los extremos del segmento util
	if @simetria_hueco != 1
		ptref1 = ptfin 
		ptref2 = ptini
	else
		ptref1 = ptini
		ptref2 = ptfin
	end	
	if @maximo_hueco || @comando_en_curso == "Place cabinet"
		@ph1 = ptref1
		@ancho = (ptini - ptfin).length
		#referencia siempre desde el centro (armarios)
		#@ph1 = punto_a_distancia(punto_medio(ptref1, ptref2), posicion, @ancho/2)
	elsif $forzar_carpinteria
		if (posicion-ptini).length < (posicion-ptfin).length	
			@simetria_hueco = 1
			ptref1 = ptini
			ptref2 = ptfin
		else
			@simetria_hueco = -1
			ptref1 = ptfin
			ptref2 = ptini
		end	
		if @carpinteria_hueco != 0 # por el centro
			@ph1 = punto_a_distancia(punto_medio(ptref1, ptref2), posicion, @ancho/2)
		else # por el extremo
			@ph1 = punto_a_distancia(ptref1, posicion, @distancia_carpinteria)
		end	
	else
		@ph1 = punto_a_distancia(posicion, ptref1, @ancho*@carpinteria_hueco/2)
	end
	if !punto_en_segmento(@ph1, ptini, ptfin)
		@ancho = @ancho_anterior
		return false 		
	end
	@cara2 = otra_cara_perp(@cara1, @ph1)	
	if !@cara2
		@ancho = @ancho_anterior 
		return false 
	end
	@ph2 = @ptperp
	vuelta = 0
	while vuelta < 2 
		@ph3 = punto_a_distancia(@ph1, ptref2, @ancho) if !@primer_punto #Si @primer_punto viene calculado de puntos carpinteria
		if otra_cara_perp(@cara1, @ph3) == @cara2
			@ph4 = @ptperp
			@angulo1 = angulo_recta(@ph1, @ph3)
			@angulo2 = angulo_recta(@ph1, @ph2)
			set_transform(true)
			@grueso_muro = (@ph1-@ph2).length
			return true
		end if punto_en_segmento(@ph3, ptini, ptfin)
		return false if @pulsado_alt
		@simetria_hueco = -@simetria_hueco 
		if ptref1 == ptini
			ptref1 = ptfin
			ptref2 = ptini
		else	
			ptref1 = ptini
			ptref2 = ptfin
		end  
		vuelta += 1
	end
	@ancho = @ancho_anterior
	return false
end

def draw(view)
	textoevaluacion(view)
    # Muestra el punto actual
    if( @ip.valid? && @ip.display? )
        @ip.draw(view)
    end
    # previsualiza la carpinteria
	if @primer_punto 
		pto_carpinteria = @primer_punto
	else
		pto_carpinteria = @ip.position
	end
	if puntos_hueco(pto_carpinteria)
		puntos_carpinteria(true) if !@primer_punto
		view.drawing_color = "magenta"
		view.draw(GL_LINES, @ph1, @ph2)  
		view.draw(GL_LINES, @ph3, @ph4)
	else 
		view.drawing_color = "black"
		@ph1 = pto_carpinteria
		set_transform(false)
	end
	ptos = []
	@p_c.each do |pt|
		ptos.push pt.transform @transform
	end
	view.draw(GL_LINES, ptos)  
end

def onMouseMove(flags, x, y, view)
	#ip.pick(view, x, y)
    return false if( !@ip.pick(view, x, y) )
	# pone tooltip segun el elemento al que se aproxime
    texto_comando #por si se ha borrado
	view.tooltip = @ip.tooltip
	@cara1 = busca_cara(x, y, view)
	@ph1 = @ip.position
	puntos_carpinteria(false) if @primer_punto
	view.invalidate
end

def colocar_carpinteria
	if @cara1 && @pulsado_alt
		@carpinteria_hueco = 0
		if !@primer_punto
			@primer_punto = @ph1
			@cara_ventana = @cara1
			return
		else
			@ph1 = @primer_punto
			Sketchup::set_status_text $DibacStrings.GetString("Length"), SB_VCB_LABEL
		end
	end
	@ph1=@ip.position if !@primer_punto
	if puntos_hueco(@ph1)
		inicioundo($DibacStrings.GetString(@comando_en_curso))
		mat = @cara1.material.color.to_i if @cara1.material
		pon_color(Sketchup.active_model.active_entities.add_line (@ph1, @ph2),mat)
		pon_color(Sketchup.active_model.active_entities.add_line (@ph3, @ph4),mat)
		lborrar = Sketchup.active_model.active_entities.add_line @ph1, @ph3
		Sketchup.active_model.active_entities.erase_entities lborrar
		lborrar = Sketchup.active_model.active_entities.add_line @ph2, @ph4
		Sketchup.active_model.active_entities.erase_entities lborrar
		carp = pon_carpinteria
		pon_color(carp,$color_lineas)
		$dc_observers.get_latest_class.redraw_with_undo(carp)
		@primer_punto = @cara_ventana = false
		#@maximo_hueco = false
	else
		@simetria_hueco = -@simetria_hueco
		@angulo1 = angulo_inverso(@angulo1)
		@angulo2 = @angulo2 +2*Math::PI if @angulo2<0.0
		puntos_carpinteria(false)
		view.invalidate
	end
	reset
	#puntos_carpinteria
end

def onLButtonDown(flags, x, y, view)
		colocar_carpinteria
end

def ancho_maximo (vf)
	return if @comando_en_curso == "Place door"
	@maximo_hueco = vf 
	@pulsado_alt = false
end

def hueco_a_distancia (vf)
	$forzar_carpinteria = vf
	@maximo_hueco = false
end

def hueco_pantalla (vf)
	@pulsado_alt = vf
	@maximo_hueco = false
	reset_dibujo
	if @cara1
			@primer_punto = @ip.position
			@cara_ventana = @cara1
			@ancho=0
	end
end

def hueco_anterior
	if @ancho_anterior
		@ancho = @ancho_anterior
		puntos_carpinteria(false)
	end
end

def onKeyDown(key, rpt, flags, view)
	reset if key == 36
	if key == 9 then
		@carpinteria_hueco += 1
		@carpinteria_hueco = 0 if @carpinteria_hueco > 1
		view.invalidate
	elsif key == CONSTRAIN_MODIFIER_KEY && !@primer_punto
		ancho_maximo(!@maximo_hueco)
	elsif key == COPY_MODIFIER_KEY && !@primer_punto
		hueco_a_distancia (!$forzar_carpinteria)
	elsif key == ALT_MODIFIER_KEY
		hueco_pantalla (!@pulsado_alt)
		view.invalidate
	end	
	no_menu = true if key == ALT_MODIFIER_KEY # Para que no entre al menu (no se porque pasa esto)
	texto_comando
end	

def onKeyUp(key, rpt, flags, view)
	hueco_anterior
end

def forzar_hueco(text)
	return false if text[0].chr != "-"
	valores = text.split("-")
	if valores.size > 1
		$forzar_carpinteria = true
		@distancia_carpinteria = (valores[1].to_l).abs
	else		
		$forzar_carpinteria = !$forzar_carpinteria
	end
	return true
end

end # de la clase Carpinteria

class Dibac_Puerta < Dibac_Carpinteria
=begin
 Clase	        		:	Puerta
 Desciende de		:	Carpinteria
 Descripción   		:	Dibuja puertas en muros
 Item de Menu  	:	Dibujo->Dibac->Puerta // Barra de herramientas Dibac
 Menú contextual	:	NO
 Uso         			:	Para dibujar la puerta primero se tiene que proporcionar la cara del muro
								Cuando la puerta se puede colocar se muestra coloreada en magenta.
								Pulsando boton izquierdo fuera de un muro se cambia el sentido de apertura de la puerta.
								Pulsando [Tab] se cambia elpunto de enganche entre extremo y centro.
								Los anchos de hoja se introducen en la forma hoja1;hoja2
								Se puede omitir cualquiera los lados del ";" y se actuara solo sobre el lado introducido.
								asi, por ejemplo,para introducir solo hoja 2 y dejar hoja1 como estaba: ;hoja2
								para hacer puertas de una sola hoja: ;0
								Si despues del ; ponemos el signo = la segunda hoja seráigual a la primera.
								Introduciendo un numero negativo indicamos que queremos forzar la colocacion a una distancia.
								El signo menos sin cantidad activa/desactiva la colocacion forzada.
								Cuando esta activa la colocacion forzada, la tecla Tab cambia entre extremo y centro. 
								La posicion forzada se calcula siempre sobre el tramo comun entre la cara interior
								y exterior del muro.
             		   
             		  
 Fecha        			:	14/11/2010
=end

def initialize
	exit if nolicencia
	@distancia_carpinteria = 0.10.m if !@distancia_carpinteria
	@carpinteria_hueco = $puerta_hueco
	@comando_en_curso = "Place door"
	init_carpinteria
end

def menu
	prompts = 	[	$DibacStrings.GetString("Slab")+" 1",
							$DibacStrings.GetString("Slab")+" 2",
							$DibacStrings.GetString("Lintel"),
							$DibacStrings.GetString("Force"),
							$DibacStrings.GetString("Align")
						]
	distancia = $DibacStrings.GetString("NOT")
	if $forzar_carpinteria
		if @carpinteria_hueco == 1
			distancia = $DibacStrings.GetString("CEN")
		else
			distancia = (@distancia_carpinteria.to_l).to_s
		end	
	end		
	if $puerta_hoja2 >=0
		hoja2 = $puerta_hoja2.to_l
	else
		hoja2 = "="
	end
	case $puerta_alineacion
	when 0.0
		alineacion=$DibacStrings.GetString("Internal")
	when 0.5 
		alineacion=$DibacStrings.GetString("Center")
	when 1.0
		alineacion=$DibacStrings.GetString("External")
	end
	defaults =	[	$puerta_hoja1.to_l.to_s,
						hoja2.to_s,
						$puerta_dintel.to_l.to_s,
						distancia,
						alineacion
					]
	list = 		[	"",
						"",
						"",
						"",
						$DibacStrings.GetString("Internal")+"|"+$DibacStrings.GetString("Center")+"|"+$DibacStrings.GetString("External")
					]
	input = UI.inputbox prompts, defaults, list, $DibacStrings.GetString("Door")
	if input
		h1 = a_numero(input[0]).abs
		h1 = $puerta_hoja1 if h1 == 0
		h2 =(input[1].to_s)
		if h2 == "="
			h2 = -h1
		else
			h2 =a_numero(input[1]).abs
		end	
		
		if h1 >= h2
			$puerta_hoja1 = h1
			$puerta_hoja2 = h2
		else
			$puerta_hoja2 = h1
			$puerta_hoja1 = h2
		end
	else
		Sketchup.active_model.select_tool nil	
		exit
	end
	h1 = a_numero(input[2]).abs
	$puerta_dintel = h1 if h1 > 0
	if input[3].to_s.upcase == $DibacStrings.GetString("NOT")
		$forzar_carpinteria = false
	else	
		$forzar_carpinteria = true
		if input[3].to_s.upcase == $DibacStrings.GetString("CEN")
			@carpinteria_hueco = 1
		else
			@carpinteria_hueco = 0
			@distancia_carpinteria = a_numero(input[3]).abs
		end	
	end
	case input[4].to_s
	when $DibacStrings.GetString("Internal") 
		$puerta_alineacion=0.0
	when $DibacStrings.GetString("Center") 
		$puerta_alineacion=0.5
	when $DibacStrings.GetString("External")
		$puerta_alineacion=1.0
	end			
	reset
end

def reset
	puntos_carpinteria(false)
end 

def deactivate(view)
	$puerta_hueco = @carpinteria_hueco 
	view.invalidate
end

def texto_comando
	texto = $DibacStrings.GetString("Door")+" [" + $puerta_hoja1.to_l.to_s
	texto = texto +$separador_listas+$puerta_hoja2.abs.to_l.to_s if $puerta_hoja2 > 0
	texto = texto +$separador_listas+"=" if $puerta_hoja2 < 0
	
	texto = texto +"] ["+$DibacStrings.GetString("Force")+" "
	if $forzar_carpinteria	
		texto = texto + @distancia_carpinteria.to_l.to_s 
	else
		texto = texto + $DibacStrings.GetString("NOT") 
	end
	texto = texto +"]. "+$DibacStrings.GetString("Select a wall, new values, or distance preceded by")+" '-', Ctrl="
	texto = texto +$DibacStrings.GetString ("Force")+", Tab="+$DibacStrings.GetString("Center/End")
	Sketchup::set_status_text texto
end

def puntos_carpinteria(enmuro)
	y=0.0
	gruesomarco=$puerta_grueso_marco
	if enmuro
		gruesomarco=(@ph1 - @ph2).length if gruesomarco > (@ph1 - @ph2).length
		y=$puerta_alineacion*(gruesomarco-(@ph1 - @ph2).length)
	end	
	@p_c = []
	@ancho = $puerta_hoja1+$puerta_hoja2.abs+2*$puerta_ancho_marco
	# marco y hojas derechos
	if $puerta_hoja2.abs > 0 
		@p_c.push [$puerta_ancho_marco + $puerta_hoja1 + $puerta_hoja2.abs, $puerta_hoja2.abs+y]
		siguiente_punto(-$puerta_grueso_hoja, 0) 			
		siguiente_punto_rep(0 , -$puerta_hoja2.abs) 			
		siguiente_punto_rep($puerta_grueso_hoja, 0) 
		siguiente_punto_rep($puerta_ancho_marco,0)
	else
		@p_c.push [$puerta_ancho_marco + $puerta_hoja1, y]
		siguiente_punto($puerta_ancho_marco,0)
	end
	 
	siguiente_punto_rep(0,-gruesomarco) 
	siguiente_punto_rep(-$puerta_ancho_marco, 0)
	siguiente_punto_rep(0, gruesomarco)

	if $puerta_hoja2.abs > 0
		siguiente_punto_rep(0, $puerta_hoja2.abs)
		# arco derecho
		alfa = Math::PI/2
		while alfa < Math::PI - 0.00001 
			alfa = alfa +  Math::PI / 18 #10º
			siguiente_punto_rep(-$puerta_hoja2.abs*(Math::cos(alfa-Math::PI / 18)-Math::cos(alfa)), $puerta_hoja2.abs*(Math::sin(alfa)-Math::sin(alfa-Math::PI / 18)))
		end
	end	
	#arco izquierdo
	alfa = 0
	while alfa < Math::PI/2 -0.0001
		alfa = alfa +  Math::PI / 18 #10º
		siguiente_punto_rep(-$puerta_hoja1*(Math::cos(alfa-Math::PI / 18)-Math::cos(alfa)), $puerta_hoja1*(Math::sin(alfa)-Math::sin(alfa-Math::PI / 18)))
	end
	# hoja y marco izquierdo
	siguiente_punto_rep(0, -$puerta_hoja1 - gruesomarco)
	siguiente_punto_rep(-$puerta_ancho_marco, 0)
	siguiente_punto_rep(0, gruesomarco)
	siguiente_punto_rep($puerta_ancho_marco + $puerta_grueso_hoja, 0) 
	siguiente_punto_rep(0, $puerta_hoja1)
	siguiente_punto_rep(-$puerta_grueso_hoja, 0)
end

def pon_carpinteria
	if $puerta_hoja2.abs > 0
		@pathcarpinteria = Sketchup.find_support_file "DIBAC_PUERTA_DOBLE.skp", "Plugins/Dibac" 
	else
		@pathcarpinteria = Sketchup.find_support_file "DIBAC_PUERTA.skp", "Plugins/Dibac"
	end	
	componente = Sketchup.active_model.definitions.load @pathcarpinteria
	inicioundo($DibacStrings.GetString(@comando_en_curso))
	pu = Sketchup.active_model.active_entities.add_instance componente, @transform
	pu.set_attribute "dynamic_attributes", "mocheta", (@ph1 - @ph2).length*1.0
	pu.set_attribute "dynamic_attributes", "a01hoja1", $puerta_hoja1*1.0
	pu.set_attribute "dynamic_attributes", "a01hoja2", $puerta_hoja2.abs*1.0
	pu.set_attribute "dynamic_attributes", "a02dintel", $puerta_dintel.abs*1.0
	pu.set_attribute "dynamic_attributes", "a02gruesoh", $puerta_grueso_hoja*1.0 
	pu.set_attribute "dynamic_attributes", "anchomarco", $puerta_ancho_marco*1.0 
	pu.set_attribute "dynamic_attributes", "gruesmarco", $puerta_grueso_marco*1.0 
	pu.set_attribute "dynamic_attributes", "a02alineac", $puerta_alineacion*1.0  
	return pu

end

def onUserText(text, view)
    # Aqui se introduce el ancho de hoja si es positiva
	text=con_coma(text)
    if !forzar_hueco(text)
		valores = text.split($separador_listas)
		h1 = (valores[0].to_l).abs
		h1 = $puerta_hoja1 if h1 == 0
		if valores.size > 1
			if valores[1]=="="
				h2 = -1
			else
				h2 =(valores[1].to_l).abs
			end	
		else 
			h2 = $puerta_hoja2
		end	
		h2=-h1 if h2<0
		if h1 >= h2
			$puerta_hoja1 = h1
			$puerta_hoja2 = h2
		else
			$puerta_hoja2 = h1
			$puerta_hoja1 = h2
		end
		puntos_carpinteria(false)
	end	
	texto_comando
	view.invalidate
end

end # de la clase Puerta
 
class Dibac_Ventana < Dibac_Carpinteria
=begin
 Clase	        		:	Ventana
 Desciende de		:	Carpinteria
 Descripción   		:	Dibuja ventanas en muros
 Item de Menu  	:	Dibujo->Dibac->Ventana // Barra de herramientas Dibac
 Menú contextual	:	NO
 Uso         			:	Para dibujar el la ventana primero se tiene que proporcionar la cara del muro
								Cuando la ventana se puede colocar se muestra coloreada en magenta.
								Pulsando [Tab] se cambia el punto de enganche entre extremo y centro.
								Los datos de la ventana se introducen en la forma Ancho;Hojas
								Se puede omitir cualquiera los lados del ";" y se actuara solo sobre el lado introducido.
								asi, por ejemplo,para introducir tres hojas 2 y dejar ancho como estaba: ;3
								Si en lugar de Hojas se introduce <Valor estamos indicando el tamaño maximo de la hoja
								de modo que el programa calculara el numero en funcion del ancho de la ventana.
								Si al colocar la ventana pulsamos MAY(SHIFT) se hara de longitud máxima.
								Introduciendo un numero negativo indicamos que queremos forzar la colocacion a una distancia.
								El signo menos sin cantidad activa/desactiva la colocacion forzada.
								Cuando esta activa la colocacion forzada, la tecla Tab cambia entre extremo y centro. 
								La posicion forzada se calcula siempre sobre el tramo comun entre la cara interior
								y exterior del muro.
             		   
             		  
 Fecha        			:	14/11/2010
=end

def initialize
	exit if nolicencia
	@distancia_carpinteria = 0.10.m if !@distancia_carpinteria
	@carpinteria_hueco = $ventana_hueco
	@grueso_muro = 0.25.m if !@grueso_muro
	#@permitir_ancho_maximo = true
	@comando_en_curso = "Place window"
	init_carpinteria
end

def menu
	prompts = [	$DibacStrings.GetString("Length"),
						$DibacStrings.GetString("Height"),
						$DibacStrings.GetString("Sashes"),
						$DibacStrings.GetString("Sill"),
						$DibacStrings.GetString("Force"),
						$DibacStrings.GetString("Align")
					 ] 
	ancho = $DibacStrings.GetString("PAN")
	ancho = ($ventana_ancho.to_l).to_s if !@pulsado_alt
	ancho = $DibacStrings.GetString("MAX") if @maximo_hueco
	hojas = ($ventana_hojas.to_i).to_s
	hojas = '<'+($ventana_hojamax.to_l).to_s if $ventana_hojamax > 0 
	distancia = $DibacStrings.GetString("NOT")
	if $forzar_carpinteria
		if @carpinteria_hueco == 1
			distancia = $DibacStrings.GetString("CEN")
		else
			distancia = (@distancia_carpinteria.to_l).to_s
		end	
	end
	case $ventana_alineacion
	when 0.0
		alineacion=$DibacStrings.GetString("Internal")
	when 0.5 
		alineacion=$DibacStrings.GetString("Center")
	when 1.0
		alineacion=$DibacStrings.GetString("External")
	end
	defaults = [	ancho,
						$ventana_alto.to_l.to_s,
						hojas,
						$ventana_alfeizar.to_l.to_s,
						distancia,
						alineacion
					]
	list = 		[	"",
						"",
						"",
						"",
						"",
						$DibacStrings.GetString("Internal")+"|"+$DibacStrings.GetString("Center")+"|"+$DibacStrings.GetString("External")
					]
	input = UI.inputbox prompts, defaults, list, $DibacStrings.GetString("Window")
	if input
		@maximo_hueco=false
		ancho_ventana(input[0])
		h1 =a_numero(input[1]).abs
		
		$ventana_alto = h1 if h1>0
		h1 = con_coma(input[2])
		if h1[0].chr == "<"		
			$ventana_hojamax = h1.split("<")[1].to_l.abs 
		else
			if h1.to_i  > 0
				$ventana_hojas = h1.to_i.abs
				$ventana_hojamax = 0 
			end	
		end	
		$ventana_alfeizar = a_numero(input[3]).abs #puede ser cero
		if input[4].to_s.upcase == $DibacStrings.GetString("NOT")
			$forzar_carpinteria = false
		else	
			$forzar_carpinteria = true
			if input[4].to_s.upcase == $DibacStrings.GetString("CEN")
				@carpinteria_hueco = 1
			else
				@carpinteria_hueco = 0
				@distancia_carpinteria = a_numero(input[4]).abs
			end	
		end
		hueco_anterior
	else
		Sketchup.active_model.select_tool nil
		exit
	end	
	case input[5].to_s
	when $DibacStrings.GetString("Internal") 
		$ventana_alineacion=0.0
	when $DibacStrings.GetString("Center") 
		$ventana_alineacion=0.5
	when $DibacStrings.GetString("External")
		$ventana_alineacion=1.0
	end
	reset
end 

def reset
	@ancho = $ventana_ancho
	@primer_punto = @cara_ventana = false
	@hojamax = $ventana_hojamax
	puntos_carpinteria(false)
end	

def ancho_ventana (valor)
	@pulsado_alt = false
	if valor.to_s.upcase == "PAN"
		@pulsado_alt = true
	elsif valor.to_s.upcase == "MAX"
		@maximo_hueco = true
	else
		@maximo_hueco = false
		h1 =a_numero(valor).abs
		$ventana_ancho = h1 if h1>0
	end
end

def deactivate(view)
	$ventana_hueco = @carpinteria_hueco 
	view.invalidate
end

def texto_comando
	texto = $DibacStrings.GetString("Window")+" [" 
	if @pulsado_alt 
		texto=texto+"Pan"+$separador_listas
	elsif @maximo_hueco
		texto=texto+"Max"+$separador_listas
	else
		texto=texto+$ventana_ancho.to_l.to_s  + $separador_listas
	end
	if $ventana_hojamax == 0
		texto = texto + $ventana_hojas.to_i.to_s  
	else	
		texto = texto + "<" + $ventana_hojamax.to_l.to_s 
	end	
	texto = texto +"] ["+$DibacStrings.GetString("Force")+" "
	if $forzar_carpinteria	
		if @carpinteria_hueco == 1 
			texto = texto +$DibacStrings.GetString("CEN")
		else	
			texto = texto + @distancia_carpinteria.to_l.to_s
		end	
	else
		texto = texto +$DibacStrings.GetString ("NOT") 
	end
	texto = texto + "]. "
	if @pulsado_alt && @primer_punto
		texto=texto+$DibacStrings.GetString("End")
	else
		texto = texto +$DibacStrings.GetString("Wall")
	end
	texto = texto +", "+$DibacStrings.GetString("values or distance")+"( -), Ctrl="+$DibacStrings.GetString("Force")+", Tab="+ $DibacStrings.GetString("Cen./End")+", "
	texto = texto + $DibacStrings.GetString("Shift")+"="+$DibacStrings.GetString("Max.")+", Alt= <->"
	Sketchup::set_status_text texto;
end

def puntos_carpinteria(enmuro)
	@grueso_muro=0.25.m if !@grueso_muro
	y=$ventana_alineacion*($ventana_grueso-@grueso_muro)
	@p_c = []
	@hojamax = $ventana_hojamax if !@primer_punto
	if @pulsado_alt
		if !@primer_punto
			@ancho = 0
			return	
		else
			@ph3 = @ph1.project_to_line(@cara_ventana.line)
			@ancho =(@primer_punto - @ph3).length
			Sketchup::set_status_text @ancho.to_s, SB_VCB_VALUE
		end
	else
		@ancho = $ventana_ancho if !@maximo_hueco
	end
	if @hojamax > 0
		@hojas = (0.4999+@ancho/@hojamax).round
	else
		@hojas = $ventana_hojas if !@primer_punto
	end	
	cristal = (@ancho-2*$ventana_ancho_marco*(1+@hojas))/@hojas
	# marco
	@p_c.push [0, y]
	siguiente_punto(@ancho, 0)
	siguiente_punto_rep(0, -$ventana_grueso)
	siguiente_punto_rep(-@ancho, 0)
	siguiente_punto_rep(0, $ventana_grueso)
	@p_c.push [$ventana_ancho_marco, y]
	siguiente_punto(0, -$ventana_grueso)
	@p_c.push [2*$ventana_ancho_marco, y]
	siguiente_punto(0, -$ventana_grueso)
	# cristales y montantes
	for i in 1 .. @hojas
		siguiente_linea(0, $ventana_grueso/2, cristal, 0) 
		siguiente_linea(0, $ventana_grueso/2, 0, -$ventana_grueso) 
		siguiente_linea($ventana_ancho_marco, 0, 0, $ventana_grueso)
		siguiente_linea($ventana_ancho_marco, 0, 0, -$ventana_grueso)
	end	
	# alfeizar
	@p_c.push [-$ventana_lateral_alfeizar, 0]
	siguiente_punto(0, -@grueso_muro-$ventana_frontal_alfeizar)
	siguiente_punto_rep(@ancho+2*$ventana_lateral_alfeizar, 0)
	siguiente_punto_rep(0, @grueso_muro+$ventana_frontal_alfeizar)
	siguiente_punto_rep(-@ancho-2*$ventana_lateral_alfeizar, 0)
	@ancho = $ventana_ancho if !@pulsado_alt
end

def pon_carpinteria
	@pathcarpinteria = Sketchup.find_support_file "DIBAC_VENTANA.skp", "Plugins/Dibac"
	componente = Sketchup.active_model.definitions.load @pathcarpinteria
	inicioundo($DibacStrings.GetString(@comando_en_curso))
	ve = Sketchup.active_model.active_entities.add_instance componente, @transform
	ve.set_attribute "dynamic_attributes", "mocheta", @grueso_muro*1.0
	ve.set_attribute "dynamic_attributes", "a01ancho", @ancho*1.0
	ve.set_attribute "dynamic_attributes", "a02alto", $ventana_alto*1.0
	ve.set_attribute "dynamic_attributes", "a03alfeizar", $ventana_alfeizar*1.0
	ve.set_attribute "dynamic_attributes", "a02hojas", @hojas
	ve.set_attribute "dynamic_attributes", "a02alineac", $ventana_alineacion
	return ve
end

def onUserText(text, view)
	text=con_coma(text)
    if !forzar_hueco(text)
		# Aqui se introduce el ancho de la ventana y el numero de hojas o la hoja maxima
		valores = text.split($separador_listas)
		n1 = valores[0]
		ancho_ventana(n1) if n1 
		if valores.size > 1
			n2 =valores[1]
			if n2[0].chr == "<"		
				@hojamax = n2.split("<")[1].to_l.abs  
			else
				if n2.to_i  > 0
					@hojas = n2.to_i
					$ventana_hojas = @hojas if  !@primer_punto
					@hojamax = 0
				end	
			end	
			$ventana_hojamax = @hojamax if !@primer_punto
		end	
		puntos_carpinteria(false) if !@primer_punto
	end	
	colocar_carpinteria if @primer_punto
	texto_comando
	view.invalidate
end

end # de la clase Ventana
 
class Dibac_Armario < Dibac_Carpinteria
=begin
 Clase	        		:	Armario
 Desciende de		:	Carpinteria
 Descripción   		:	Dibuja armarios en muros
 Item de Menu  	:	Dibujo->Dibac->Armario // Barra de herramientas Dibac
 Menú contextual	:	NO
 Uso         			:	Para dibujar el armario primero se tiene que proporcionar la cara del muro
								Cuando el armario se puede colocar se muestra coloreado en magenta.
								Pulsando [Tab] se cambia el punto de enganche entre extremo y centro.
								Pulsando el boton izquierdo fuera de un muro se hace el armario simetrico,
								esto resulta util cuando el numero de hojas es impar.
								El nico dato que requiere el armario es el ancho d hoja
								Si al colocar el armario pulsamos MAY(SHIFT) se hara de longitud máxima.
								Introduciendo un numero negativo indicamos que queremos forzar la colocacion a una distancia.
								El armario siempre se calcula on el numero maximo de hojas que caben el en tramo señalado.
             		  
 Fecha        			:	14/11/2010
=end

def initialize
	exit if nolicencia
	@hoja_armario = $armario_hoja1
	@carpinteria_hueco = 1
	$forzar_carpinteria = 1
	#@maximo_hueco = true
	@comando_en_curso = "Place cabinet"
	init_carpinteria
end

def menu
	@ancho = 1.0.m if !@ancho
	prompts = 	[	$DibacStrings.GetString("Slab"),
							$DibacStrings.GetString("Threshold"),
							$DibacStrings.GetString("Lintel"),
							$DibacStrings.GetString("Fill")
						]
						
	maximo = $DibacStrings.GetString("NOT")
	maximo = $DibacStrings.GetString("YES") if @maximo_hueco

	defaults = 	[	$armario_hoja1.to_l.to_s,
							$armario_umbral.to_l.to_s,
							$armario_dintel.to_l.to_s,
							maximo
						]
						
	alto_minimo = 3*$armario_ancho_marco+0.72.m					
	list = 			[	"",
							"",
							"",
							$DibacStrings.GetString("YES")+"|"+$DibacStrings.GetString("NOT")
						]
	input = UI.inputbox prompts, defaults, list, $DibacStrings.GetString("Cabinet")
	if input
		alto_minimo = 2*$armario_ancho_marco+0.20.m
		h1 = a_numero(input[0]).abs
		$armario_hoja1 = h1 if h1>0
		h1 = a_numero(input[1]).abs
		$armario_umbral = h1 if h1>=0
		h1 = a_numero(input[2]).abs
		$armario_dintel = h1 if h1>=0
		if $armario_umbral+alto_minimo>$armario_dintel
			$armario_dintel = $armario_umbral+alto_minimo
		end
		h1 = input[3].to_s.upcase
		@maximo_hueco = true if h1== $DibacStrings.GetString("YES")
	else	
		Sketchup.active_model.select_tool nil	
		exit
	end	
	reset
end

def reset
	puntos_carpinteria(false)
end 

def deactivate(view)
	view.invalidate
end

def texto_comando
	texto = $DibacStrings.GetString("Cabinet")+" [" + $armario_hoja1.to_l.to_s  + "]. "
	texto = texto +$DibacStrings.GetString("Enter a wall, or new dimension for doors")+". " +$DibacStrings.GetString("Shift")+"="+$DibacStrings.GetString("Max. length")
	Sketchup::set_status_text texto
end

def ancho_arm(hojas)
	marcos = ((hojas+1)/2).to_i+1
	return marcos*$armario_ancho_marco+hojas*@hoja_armario
end

def hueco_maximo(cara1, cara2)
	@hoja_armario = $armario_hoja1
	ptos = tramo_comun(linea_extremos(cara1),linea_extremos(cara2))
	ptini = ptos[0]
	ptfin = ptos[1]
	anch = (ptini-ptfin).length
	maxhojas = (anch / @hoja_armario).to_i
	# poniendolo delante la hoja actua como hoja minima
	maxhojas -= 1 while ancho_arm(maxhojas) > anch
#	if @permitir_ancho_maximo && @maximo_hueco
	if @maximo_hueco
		maxhojas = 1 if maxhojas == 0
		marcos = ((maxhojas+1)/2).to_i+1
		#salimos si los marcos ocupan mas que el hueco
		return false if marcos*$armario_ancho_marco > anch
		@hoja_armario = (anch-marcos*$armario_ancho_marco)/maxhojas
	end
	return false if maxhojas == 0
	$armario_ancho = anch = ancho_arm(maxhojas)
	$armario_hojas = maxhojas
	ptini = punto_a_distancia(punto_medio(ptini, ptfin), ptini, anch/2)
	ptfin = punto_a_distancia(ptini, ptfin, anch)
	return[ptini, ptfin]
end

def marco(punto)
	@p_c.push punto
	siguiente_punto($armario_ancho_marco, 0)
	siguiente_punto_rep(0, -$armario_grueso_marco)
	siguiente_punto_rep(-$armario_ancho_marco, 0)
	siguiente_punto_rep(0, $armario_grueso_marco)
end

def hoja_izquierda # siempre relativa a ultimo marco
	cos15=Math.cos(15*Math::PI/180)
	sin15=Math.sin(15*Math::PI/180)
	siguiente_linea($armario_ancho_marco,0,@hoja_armario*cos15, @hoja_armario*sin15)
	siguiente_punto_rep($armario_grueso_hoja*sin15, -$armario_grueso_hoja*cos15)
	siguiente_punto_rep(-@hoja_armario*cos15, -@hoja_armario*sin15)
	siguiente_punto_rep(-$armario_grueso_hoja*sin15, $armario_grueso_hoja*cos15)
	#arco
	siguiente_linea(@hoja_armario*cos15, @hoja_armario*sin15,@hoja_armario*(1-cos15), -@hoja_armario*sin15)
	# marco exterior
	siguiente_punto_rep($armario_grueso_hoja/sin15-@hoja_armario, 0)
	#marco interior
	siguiente_linea(@hoja_armario-$armario_grueso_hoja/sin15,-$armario_grueso_marco,-@hoja_armario,0)	
end

def hoja_derecha # siempre relativa a ultimo marco
	cos15=Math.cos(15*Math::PI/180)
	sin15=Math.sin(15*Math::PI/180)
	#arco
	siguiente_linea(-@hoja_armario*cos15, @hoja_armario*sin15,-@hoja_armario*(1-cos15), -@hoja_armario*sin15)
	# marco exterior
	siguiente_punto_rep(@hoja_armario-$armario_grueso_hoja/sin15, 0)
	#marco interior
	siguiente_linea($armario_grueso_hoja/sin15-@hoja_armario,-$armario_grueso_marco,@hoja_armario,0)	
	#hoja
	siguiente_linea(0,$armario_grueso_marco,-@hoja_armario*cos15, @hoja_armario*sin15)
	siguiente_punto_rep(-$armario_grueso_hoja*sin15, -$armario_grueso_hoja*cos15)
	siguiente_punto_rep(@hoja_armario*cos15, -@hoja_armario*sin15)
	siguiente_punto_rep($armario_grueso_hoja*sin15, $armario_grueso_hoja*cos15)
end

def puntos_carpinteria(enmuro)
	@p_c = []
	# marcos
	for i in 0 .. (($armario_hojas+1)/2).to_i-1 #hacemos todas las copias menos la ultima
		marco([i*(2*@hoja_armario+$armario_ancho_marco), 0])
		hoja_derecha if (i != 0)
		hoja_izquierda if ($armario_hojas % 2 == 0) or (i != (($armario_hojas+1)/2).to_i-1)
	end	
	# marco derecho	
	marco([$armario_ancho-$armario_ancho_marco, 0])
	hoja_derecha
end	

def pon_carpinteria
	if $armario_hojas == 1
		@pathcarpinteria = Sketchup.find_support_file "DIBAC_ARMARIO_1.skp", "Plugins/Dibac" 
	else
		@pathcarpinteria = Sketchup.find_support_file "DIBAC_ARMARIO_2.skp", "Plugins/Dibac"
	end	
	componente = Sketchup.active_model.definitions.load @pathcarpinteria
	inicioundo($DibacStrings.GetString(@comando_en_curso))
	ar = Sketchup.active_model.active_entities.add_instance componente, @transform
	ar.set_attribute "dynamic_attributes", "mocheta", @grueso_muro*1.0
	ar.set_attribute "dynamic_attributes", "a01ancho", $armario_ancho*1.0
	ar.set_attribute "dynamic_attributes", "a01hojas", $armario_hojas
	ar.set_attribute "dynamic_attributes", "a01umbral", $armario_umbral*1.0
	ar.set_attribute "dynamic_attributes", "a02dintel", $armario_dintel*1.0
	return ar
end

def onUserText(text, view)
	text=con_coma(text)
    if !forzar_hueco(text)
		# Aqui se introduce el ancho de hoja del armario
		n1 = text.to_l
		$armario_hoja1 = n1 if n1 > 0
		$armario_ancho = ancho_arm($armario_hojas)
		puntos_carpinteria(false)
	end	
	view.invalidate
end

end # de la clase Armario

class Dibac_CotaContinua < Dibac_Base
=begin
 Clase	        		:	CotaContinua
 Desciende de		:	Dibac
 Descripción   		:	Realiza cotas continuas sobre plantas Dibac
 Item de Menu  	:	Dibujo->Dibac->Acotado continuo // Barra de herramientas Dibac
 Menú contextual	:	NO
 Uso         			:	Se indica punto inicial y final de la linea de corte seguido de la posicion de las cotas.
								El acotado solo tiene en cuenta los muros dibujados con Dibac.
								Si se introduce cualquier numero se entendera como vañor minimo por debajo del cual
								no se visualizara la cota.

Fecha        			:	8/01/2011
=end
def initialize
	exit if nolicencia
	@ip = Sketchup::InputPoint.new
	@ip1 = Sketchup::InputPoint.new
	reset
end

def reset
	if @grupo
		pt = @ptpos.project_to_line [@ptini,@ptfin]
		@grupo.transform!(Geom::Transformation.translation(pt - @ptpos))	
		@grupo.explode
		finalundo
	end	
	@ptini = @ptfin = @ptint = @ptpos = @grupo = false
	Sketchup::set_status_text "", SB_VCB_LABEL
	Sketchup::set_status_text "", SB_VCB_VALUE
	texto_comando
end

def texto_comando
	texto = $DibacStrings.GetString("Continuous dimension")+" ("+$DibacStrings.GetString("min.")+" "+$cota_minima.to_l.to_s+"): "
	if !@ptini
		texto = texto + $DibacStrings.GetString("Enter start point, or minimun value")
	elsif !@grupo
		texto = texto + $DibacStrings.GetString("Enter end point, or minimun value")
	else
		texto = texto + $DibacStrings.GetString("Specify dimension line position")
	end	
	texto = texto +"."
	Sketchup::set_status_text texto
end	

def onMouseMove(flags, x, y, view)
    return false if( !@ip.pick(view, x, y, @ip1) )
	texto_comando # por si se ha borrado con otro comando
	# pone tooltip segun el elemento al que se aproxime
	view.tooltip = @ip.tooltip
	if !@grupo
		@ptfin = @ip.position
		@ptfin.z=@ptini.z
		@ip.pick(view, view.screen_coords(@ptfin).x, view.screen_coords(@ptfin).y) 
		@ptint = @ptfin
	else	
		@ptint = @ptpos if @ptpos
		@ptpos = @ip.position
		@ptpos.z = @ptini.z
		@ip.pick(view, view.screen_coords(@ptpos).x, view.screen_coords(@ptpos).y) 
        pt = @ptpos.project_to_line [@ptini,@ptfin]
		pt = @ptint.project_to_line [pt,@ptpos]	
		@grupo.transform!(Geom::Transformation.translation(@ptpos-pt))
	end if @ptini
	view.invalidate
end

def onLButtonDown(flags, x, y, view)
	@ip1.copy! @ip
	if !@ptini
		@ptini = @ip.position
	elsif !@grupo
		puntos = intermedios([@ptini,@ptfin],true,true)
		Sketchup.active_model.definitions.load (Sketchup.find_support_file "DIBAC_COTAL.skp","Plugins/Dibac") #para que funcione el undo
		inicioundo($DibacStrings.GetString("Continuous dimension"))
		@grupo = Sketchup.active_model.active_entities.add_group
		i = 0	
		while i < puntos.size-1 do
			pon_cota_lineal(@grupo,puntos[i],puntos[i+1]) if(puntos[i]-puntos[i+1]).length >= $cota_minima
			
			i += 1
		end
	else 
		@grupo.explode
		finalundo
		@grupo = false
		reset
	end
	texto_comando
	view.lock_inference
	view.invalidate

end

def onLButtonDoubleClick(flags, x, y, view)
	onLButtonDown(flags, x, y, view)
end

def draw(view)
	textoevaluacion(view)
    # Muestra el punto actual
    if( @ip.valid? && @ip.display? )
        @ip.draw(view)
    end
    # previsualiza la linea de cota
	view.drawing_color = "black"
	view.line_width = 1 
	inference_locked = view.inference_locked?
	view.set_color_from_line(@ip1, @ip)
	if !@grupo 
		view.draw(GL_LINE_STRIP, @ptini, @ptfin)
		puntos = intermedios([@ptini,@ptfin],true,true)
		view.draw_points(puntos,6,2,"red")
		return if puntos.size < 2
		Sketchup::set_status_text  $DibacStrings.GetString("Length"), SB_VCB_LABEL
		vec=puntos.first - puntos.last
		Sketchup::set_status_text vec.length.to_s, SB_VCB_VALUE
		i = -1		
		while i < puntos.size-1 do
			vec = puntos[i]-puntos[i+1]
			view.draw_text(view.screen_coords(punto_medio(puntos[i], puntos[i+1])),vec.length.to_s) if vec.length >= $cota_minima
			i += 1
		end
	end if @ptini
end

def onUserText(text, view)
	# Aqui se introduce el espesor minimo para acotar
	text=con_coma(text)
   begin
        valor = text.to_l
    rescue
        # Error al no tratarse de un numero
        UI.beep
        valor = nil
        Sketchup::set_status_text "", SB_VCB_VALUE
    end
    return if !valor
	$cota_minima = valor
	texto_comando
	view.invalidate
end

def onKeyDown(key, rpt, flags, view)
	Sketchup::set_status_text $DibacStrings.GetString("Minimun dimension"), SB_VCB_LABEL
end

end # de la clase CotaContinua

class Dibac_ImprimeDibac < Dibac_Base
=begin
 Clase	        		:	ImprimeDibac
 Desciende de		:	Dibac
 Descripción   		:	Realiza cotas continuas sobre plantas Dibac
 Item de Menu  	:	Dibujo->Dibac->Impresion Dibac // Barra de herramientas Dibac
 Menú contextual	:	SI
 Uso         			:	Aparece un gestor de impresion similar al de DIBAC.
								Solo se puede imprimir en planta.

Fecha        			:	15/06/2011
=end

def initialize
	exit if nolicencia
	colores_aci	
    model = Sketchup.active_model
    model_filename = File.basename(model.path)
      if( model_filename == "" )
        model_filename = "model"
      end
      ss = model.selection
      @stl_conv = 0.0254 # Metros
	  dxf_option = "lines" # Exportamos lineas
      @group_count = 0
      @component_count = 0
      @face_count = 0
      @line_count = 0
      entities = model.active_entities
      if (Sketchup.version_number < 7)
        model.start_operation("export_dxf_mesh")
      else
         model.start_operation("export_dxf_mesh",true)
      end
      #if ss.empty?
      #   answer = UI.messagebox("No objects selected. Export entire model?", MB_YESNOCANCEL)
      #   if( answer == 6 )
            export_ents = model.active_entities
      #   else
      #      export_ents = ss
      #   end
      #else
      #   export_ents = Sketchup.active_model.selection
      #end
      if (export_ents.length > 0)
         #get units for export
         #dxf_dxf_units_dialog ///Quitado
         #get DXF export option
         #dxf_option = dxf_dxf_options_dialog ///Quitado
         if (dxf_option =="stl")
          file_type="stl"
         else
          file_type="dxf"
         end
         #exported file name
         #out_name = UI.savepanel( file_type+" file location", "." , "#{File.basename(model.path).split(".")[0]}." +file_type )
		 path_comando = Sketchup.find_support_file "Impresora.png", "Plugins//Dibac"
		 out_name = "#{path_comando.split(".")[0]}." +file_type
         @mesh_file = File.new(out_name , "w")  
         model_name = model_filename.split(".")[0]
         dxf_header(dxf_option,model_name)
         # Recursively export faces and edges, exploding groups as we go.
         #Count "other" objects we can't parse.
         others = dxf_find_faces(0, export_ents, Geom::Transformation.new(), model.active_layer.name,dxf_option, nil)
         dxf_end(dxf_option,model_name)
         # UI.messagebox( @face_count.to_s + " faces exported " + @line_count.to_s + " lines exported\n" + others.to_s + " objects ignored" )
      end
	  path_comando = Sketchup.find_support_file "DibacI.exe", "Plugins//Dibac"
	  UI.openURL(path_comando)
      model.commit_operation
end

def entidad_vista(entity)
	return false if entity.hidden?
	return false if !(entity.layer.visible?)
	return true
end

def dxf_find_faces(others, entities, tform, layername,dxf_option, color)
	entities.each do |entity|
	@color=color
	material=entity.material
	@color=material.color if material

	if entidad_vista(entity)
      #Face entity
	  if entity.typename == "DimensionLinear"	
		if entity.attribute_dictionary "dibaccotas"
			dxf_write_dimension(entity, tform, entity.layer.name,@color)
		end
      elsif( entity.typename == "Face")
       case dxf_option
       when "polylines"
        dxf_write_polyline(entity,tform,layername)
       when "polyface mesh"
        dxf_write_polyface(entity,tform,layername)
       when "triangular mesh"
         dxf_write_face(entity,tform,layername)
       when "stl"
         dxf_write_stl(entity,tform)     
       end
     #Edge entity
      elsif( entity.typename == "Edge") and((dxf_option=="lines")or(entity.faces.length==0 and dxf_option!="stl"))
       dxf_write_edge(entity, tform, entity.layer.name,@color)
     #Group entity
      elsif( entity.typename == "Group")
         if entity.name==""
           entity.name="GROUP"+@group_count.to_s
           @group_count+=1
         end
         others = dxf_find_faces(others, entity.active_entities, tform * entity.transformation, entity.name,dxf_option, @color)
      #Componentinstance entity
      elsif( entity.typename == "ComponentInstance")
         if entity.name==""
           entity.name="COMPONENT"+@component_count.to_s
           @component_count+=1
         end
         others = dxf_find_faces(others, entity.definition.active_entities, tform * entity.transformation, entity.name,dxf_option, @color)
      else
         others = others + 1
      end
    end
   end
   others
end

def dxf_transform_edge(edge, tform)
   points=[]
   points.push(dxf_transform_vertex(edge.start, tform))
   points.push(dxf_transform_vertex(edge.end, tform))
   points
end

def dxf_transform_vertex(vertex, tform)
   point = Geom::Point3d.new(vertex.position.x, vertex.position.y, vertex.position.z)
   point.transform! tform
   point
end

def dxf_transform_punto(pt, tform)
   point = Geom::Point3d.new(pt[0], pt[1], pt[2])
   point.transform! tform
   point
end

def color_paleta(color)
	return @paleta_ultimo if @color_ultimo == color
	sep = 255*3
	for i in 0..255 
		sep2 =	(@ca[i][0]-color.red).abs+(@ca[i][1]-color.green).abs+(@ca[i][2]-color.blue).abs
		if sep2 < sep
			sep = sep2
			@paleta_ultimo = i
			@color_ultimo = color
		end
	end
	return @paleta_ultimo
end

def dxf_write_edge(edge, tform, layername, color)
	if entidad_vista(edge)
		points = dxf_transform_edge(edge, tform)
		@mesh_file.puts( "  0\nLINE\n 8\n"+layername)
		#material=edge.material
		#color=material.color if material
		if color
			color= color_paleta(color)
			@mesh_file.puts( "62\n"+color.to_s)
		end	
		for j in 0..1 
			@mesh_file.puts((10+j).to_s+"\n"+(points[j].x.to_f * @stl_conv).to_s)#x
			@mesh_file.puts((20+j).to_s+"\n"+(points[j].y.to_f * @stl_conv).to_s)#y
			@mesh_file.puts((30+j).to_s+"\n"+(points[j].z.to_f * @stl_conv).to_s)#z
		end
		@line_count+=1
	end
end

def dxf_write_dimension(cota, tform, layername, color)
	if entidad_vista(cota)
		pt1=dxf_transform_punto((cota.get_attribute "dibaccotas","pt1"), tform)
		pt2=dxf_transform_punto((cota.get_attribute "dibaccotas","pt2"), tform)
		@mesh_file.puts( "  0\nDIMENSION\n 8\n"+layername)
		#material=edge.material
		#color=material.color if material
		if color
			color= color_paleta(color)
			@mesh_file.puts( "62\n"+color.to_s)
		end	
		points=[]
		points.push(pt1)
		points.push(punto_medio(pt1,pt2))
		for j in 0..1 
			@mesh_file.puts((10+j).to_s+"\n"+(points[j].x.to_f * @stl_conv).to_s)#x
			@mesh_file.puts((20+j).to_s+"\n"+(points[j].y.to_f * @stl_conv).to_s)#y
			@mesh_file.puts((30+j).to_s+"\n"+(points[j].z.to_f * @stl_conv).to_s)#z
		end
		@mesh_file.puts( "70\n 33\n")
		points=[]
		points.push(pt1)
		points.push(pt2)
		for j in 0..1 
			@mesh_file.puts((13+j).to_s+"\n"+(points[j].x.to_f * @stl_conv).to_s)#x
			@mesh_file.puts((23+j).to_s+"\n"+(points[j].y.to_f * @stl_conv).to_s)#y
			@mesh_file.puts((33+j).to_s+"\n"+(points[j].z.to_f * @stl_conv).to_s)#z
		end
	end
end

def dxf_write_polyline(face, tform,layername)
	if entidad_vista(face)
		face.loops.each do |aloop|
			@mesh_file.puts("  0\nPOLYLINE\n 8\n"+layername+"\n 66\n     1")
			@mesh_file.puts("70\n    8\n 10\n0.0\n 20\n 0.0\n 30\n0.0")
			for j in 0..aloop.vertices.length
				if (j==aloop.vertices.length)
					count = 0
				else
					count = j
				end
				point = dxf_transform_vertex(aloop.vertices[count],tform)
				@mesh_file.puts( "  0\nVERTEX\n  8\nMY3DLAYER")
				@mesh_file.puts("10\n"+(point.x.to_f * @stl_conv).to_s)
				@mesh_file.puts("20\n"+(point.y.to_f * @stl_conv).to_s)
				@mesh_file.puts("30\n"+(point.z.to_f * @stl_conv).to_s)
				@mesh_file.puts( " 70\n     32")
			end
			@mesh_file.puts( "  0\nSEQEND") if (aloop.vertices.length > 0)
		end
		@face_count+=1
	end
end

def dxf_write_face(face, tform, layername)
	mesh = face.mesh 0
	mesh.transform! tform
	polygons = mesh.polygons
	polygons.each do |polygon|
		if (polygon.length > 2)
			flags = 0
			@mesh_file.puts( "  0\n3DFACE\n 8\n"+layername)
			for j in 0..polygon.length
				if (j==polygon.length)
				count = polygon.length-1
				else
					count = j
				end
				#check edge visibility
				if ((polygon[count]<0))
					flags+=2**j
				end
				@mesh_file.puts((10+j).to_s+"\n"+(mesh.point_at(polygon[count].abs).x.to_f * @stl_conv).to_s)
				@mesh_file.puts((20+j).to_s+"\n"+(mesh.point_at(polygon[count].abs).y.to_f * @stl_conv).to_s)
					@mesh_file.puts((30+j).to_s+"\n"+(mesh.point_at(polygon[count].abs).z.to_f * @stl_conv).to_s)
			end
			#edge visibiliy flags
			@mesh_file.puts("70\n"+flags.to_s)  
		end
	end
	@face_count+=1
end

def dxf_write_stl (face,tform)
	mesh = face.mesh 7
	mesh.transform! tform
	polygons = mesh.polygons
	polygons.each do |polygon|
		if (polygon.length == 3)
			@mesh_file.puts( "facet normal " + mesh.normal_at(polygon[0].abs).x.to_s + " " + mesh.normal_at(polygon[0].abs).y.to_s + " " + mesh.normal_at(polygon[0].abs).z.to_s)
			@mesh_file.puts( "outer loop")
			for j in 0..2
				@mesh_file.puts("vertex " + (mesh.point_at(polygon[j].abs).x.to_f * @stl_conv).to_s + " " + (mesh.point_at(polygon[j].abs).y.to_f * @stl_conv).to_s + " " + (mesh.point_at(polygon[j].abs).z.to_f * @stl_conv).to_s)
			end
			@mesh_file.puts( "endloop\nendfacet")
		end
	end
	@face_count+=1
end

def dxf_write_polyface(face,tform,layername)
	mesh = face.mesh 0
	mesh.transform! tform
	polygons = mesh.polygons
	points = mesh.points
	@mesh_file.puts("  0\nPOLYLINE\n 8\n"+layername+"\n 66\n     1")
	@mesh_file.puts("10\n0.0\n 20\n 0.0\n 30\n0.0\n")
	@mesh_file.puts("70\n    64\n") #flag for 3D polyface
	@mesh_file.puts("71\n"+mesh.count_points.to_s)
	@mesh_file.puts("72\n   1")
	#points
	points.each do |point| 
		@mesh_file.puts( "  0\nVERTEX\n  8\n"+layername)
		@mesh_file.puts("10\n"+(point.x.to_f * @stl_conv).to_s)
		@mesh_file.puts("20\n"+(point.y.to_f * @stl_conv).to_s)
		@mesh_file.puts("30\n"+(point.z.to_f * @stl_conv).to_s)
		@mesh_file.puts( " 70\n     192")
	end
	#polygons
	polygons.each do |polygon| 
		@mesh_file.puts( "  0\nVERTEX\n  8\n"+layername)
		@mesh_file.puts("10\n0.0\n 20\n 0.0\n 30\n0.0\n")
		@mesh_file.puts( " 70\n     128")
		@mesh_file.puts( " 71\n"+polygon[0].to_s)
		@mesh_file.puts( " 72\n"+polygon[1].to_s)
		@mesh_file.puts( " 73\n"+polygon[2].to_s)
		if (polygon.length==4)
			@mesh_file.puts( " 74\n"+polygon[3]..abs.to_s)
		end
	end
	@mesh_file.puts( "  0\nSEQEND")
	@face_count+=1
end

def dxf_dxf_options_dialog
	options_list=["polyface mesh","polylines","triangular mesh","lines","stl"].join("|")
	prompts=["Export to DXF options"]
	enums=[options_list]
	values=["polyface mesh"]
	results = inputbox prompts, values, enums, "Choose which entities to export"
	return if not results
	results[0]
end

def dxf_dxf_units_dialog
	cu=Sketchup.active_model.options[0]["LengthUnit"]
	case cu
	when 4
		current_unit= "Meters"
	when 3
		current_unit= "Centimeters"
	when 2
		current_unit= "Millimeters"
	when 1
		current_unit= "Feet"
	when 0
		current_unit= "Inches"
	end
	units_list=["Meters","Centimeters","Millimeters","Inches","Feet"].join("|")
	prompts=["Export unit: "]
	enums=[units_list]
	values=[current_unit]
	results = inputbox prompts, values, enums, "Export units"
	return if not results
	case results[0]
	when "Meters"
		@stl_conv=0.0254
	when "Centimeters"
		@stl_conv=2.54
	when "Millimeters"
		@stl_conv=25.4
	when "Feet"
		@stl_conv=0.0833333333333333
	when "Inches"
		@stl_conv=1
	end
end

def dxf_header(dxf_option,model_name)
	if (dxf_option=="stl")
		@mesh_file.puts( "solid " + model_name)
	else
		@mesh_file.puts( " 0\nSECTION\n 2\nENTITIES")
	end
end

def dxf_end(dxf_option,model_name)
	if (dxf_option=="stl")
		@mesh_file.puts( "endsolid " + model_name)
	else
		@mesh_file.puts( " 0\nENDSEC\n 0\nEOF")
	end
	@mesh_file.close
end

def colores_aci
	@ca=[[0,0,0]]
	@ca.concat([[255,0,0],[255,255,0],[0,255,0],[0,255,255],[0,0,255],[255,0,255],[255,255,255],[65,65,65],[128,128,128],[255,0,0],[255,170,170],[189,0,0],[189,126,126],[129,0,0],[129,86,86],[104,0,0]])
	@ca.concat([[104,69,69],[79,0,0],[79,53,53],[255,63,0],[255,191,170],[189,46,0],[189,141,126],[129,31,0],[129,96,86],[104,25,0],[104,78,69],[79,19,0],[79,59,53],[255,127,0],[255,212,170],[189,94,0]])
	@ca.concat([[189,157,126],[129,64,0],[129,107,86],[104,52,0],[104,86,69],[79,39,0],[79,66,53],[255,191,0],[255,234,170],[189,141,0],[189,173,126],[129,96,0],[129,118,86],[104,78,0],[104,95,69],[79,59,0]])
	@ca.concat([[79,73,53],[255,255,0],[255,255,170],[189,189,0],[189,189,126],[129,129,0],[129,129,86],[104,104,0],[104,104,69],[79,79,0],[79,79,53],[191,255,0],[234,255,170],[141,189,0],[173,189,126],[96,129,0]])
	@ca.concat([[118,129,86],[78,104,0],[95,104,69],[59,79,0],[73,79,53],[127,255,0],[212,255,170],[94,189,0],[157,189,126],[64,129,0],[107,129,86],[52,104,0],[86,104,69],[39,79,0],[66,79,53],[63,255,0]])
	@ca.concat([[191,255,170],[46,189,0],[141,189,126],[31,129,0],[96,129,86],[25,104,0],[78,104,69],[19,79,0],[59,79,53],[0,255,0],[170,255,170],[0,189,0],[126,189,126],[0,129,0],[86,129,86],[0,104,0]])
	@ca.concat([[69,104,69],[0,79,0],[53,79,53],[0,255,63],[170,255,191],[0,189,46],[126,189,141],[0,129,31],[86,129,96],[0,104,25],[69,104,78],[0,79,19],[53,79,59],[0,255,127],[170,255,212],[0,189,94]])
	@ca.concat([[126,189,157],[0,129,64],[86,129,107],[0,104,52],[69,104,86],[0,79,39],[53,79,66],[0,255,191],[170,255,234],[0,189,141],[126,189,173],[0,129,96],[86,129,118],[0,104,78],[69,104,95],[0,79,59]])
	@ca.concat([[53,79,73],[0,255,255],[170,255,255],[0,189,189],[126,189,189],[0,129,129],[86,129,129],[0,104,104],[69,104,104],[0,79,79],[53,79,79],[0,191,255],[170,234,255],[0,141,189],[126,173,189],[0,96,129]])
	@ca.concat([[86,118,129],[0,78,104],[69,95,104],[0,59,79],[53,73,79],[0,127,255],[170,212,255],[0,94,189],[126,157,189],[0,64,129],[86,107,129],[0,52,104],[69,86,104],[0,39,79],[53,66,79],[0,63,255]])
	@ca.concat([[170,191,255],[0,46,189],[126,141,189],[0,31,129],[86,96,129],[0,25,104],[69,78,104],[0,19,79],[53,59,79],[0,0,255],[170,170,255],[0,0,189],[126,126,189],[0,0,129],[86,86,129],[0,0,104]])
	@ca.concat([[69,69,104],[0,0,79],[53,53,79],[63,0,255],[191,170,255],[46,0,189],[141,126,189],[31,0,129],[96,86,129],[25,0,104],[78,69,104],[19,0,79],[59,53,79],[127,0,255],[212,170,255],[94,0,189]])
	@ca.concat([[157,126,189],[64,0,129],[107,86,129],[52,0,104],[86,69,104],[39,0,79],[66,53,79],[191,0,255],[234,170,255],[141,0,189],[173,126,189],[96,0,129],[118,86,129],[78,0,104],[95,69,104],[59,0,79]])
	@ca.concat([[73,53,79],[255,0,255],[255,170,255],[189,0,189],[189,126,189],[129,0,129],[129,86,129],[104,0,104],[104,69,104],[79,0,79],[79,53,79],[255,0,191],[255,170,234],[189,0,141],[189,126,173],[129,0,96]])
	@ca.concat([[129,86,118],[104,0,78],[104,69,95],[79,0,59],[79,53,73],[255,0,127],[255,170,212],[189,0,94],[189,126,157],[129,0,64],[129,86,107],[104,0,52],[104,69,86],[79,0,39],[79,53,66],[255,0,63]])
	@ca.concat([[255,170,191],[189,0,46],[189,126,141],[129,0,31],[129,86,96],[104,0,25],[104,69,78],[79,0,19],[79,53,59],[51,51,51],[80,80,80],[105,105,105],[130,130,130],[190,190,190],[255,255,255]])
end

end # de la clase ImprimeDibac

class Dibac_TresDimensiones < Dibac_Base
=begin
 Clase	        	:	TresDimensiones
 Desciende de		:	Dibac
 Descripción   		:	Genera un modelo 3D a partir de la planta
 Item de Menu  	:	Dibujo->Dibac->Convertir en 3D // Barra de herramientas Dibac
 Menú contextual	:	NO
 Uso         			:	

Fecha        			:	10/03/2012
=end

def initialize
	exit if nolicencia
end	

def menu
	@h = false
	prompts = 	[	$DibacStrings.GetString("Height"),
							$DibacStrings.GetString("Create group")
						]
	grupo = $DibacStrings.GetString("NOT")
	grupo = $DibacStrings.GetString("YES") if $crear_grupo					

	defaults = 	[	$altura_planta.to_l,
							grupo
						]
						
	list = 			[	"",
							$DibacStrings.GetString("YES")+"|"+$DibacStrings.GetString("NOT")
						]
	input = UI.inputbox prompts, defaults, list, $DibacStrings.GetString("Convert to 3D")
	if input
		h1 = a_numero(input[0]).abs
		$altura_planta = h1 if h1>0
		h1 = input[1].to_s.upcase
		$crear_grupo =  (h1 == $DibacStrings.GetString("YES"))
	else	
		Sketchup.active_model.select_tool nil	
		exit
	end	
end

def ponz (ptos, h)
	ptos.each do |pt|		
		pt.z=pt.z+h
	end	
end	

def activate
	Sketchup.active_model.active_view.invalidate
	menu if !@h
	@h=$altura_planta if !@h
	@h = 3.m if @h<=0
	#return if modelraiz.attribute_dictionary '3D', false
	#modelraiz.attribute_dictionary '3D', true
	#modelraiz.set_attribute '3D', 'Altura', @h
	carpinterias = []
	muros = []
	escaleras=[]
	Sketchup.active_model.active_entities.each do |entidad|
		if	entidad.typename == "ComponentInstance"	
			if es_carpinteria(entidad)
				carpinterias.push(entidad)
				# dos veces la primera para hacer undo al leer archivo nuevo en el paso a 3D
				if carpinterias.size == 1
					$dc_observers.get_latest_class.redraw_with_undo(entidad) 
					#Sketchup.undo
				end	
			end
		elsif entidad.typename == "Face"
			esmuro = true
			entidad.edges.each do |e|
				esmuro = false if e.faces.size > 2
				if e.faces.size == 2
					esmuro=false if !(e.faces[0].normal.dot(e.faces[1].normal) > 0.99999999)
				end
			end
			muros.push(entidad) if esmuro
		elsif  entidad.get_attribute  "escalera","3d"	
			escaleras.push entidad
		end
	end
	if carpinterias+muros+escaleras==[]
		Sketchup.active_model.select_tool nil	
		exit	
	end

	inicioundo($DibacStrings.GetString("Convert to 3D"))
	model3d = Sketchup.active_model.active_entities.add_group(carpinterias+muros+escaleras) #lo metemos todo en un grupo
	if $crear_grupo 
		temp=model3d.copy
		temp.explode #conservamos las entidades originales
	end
	carpinterias.each do |entidad|
		if entidad.definition.name[0,12] == "DIBAC_PUERTA"
			hoja2=entidad.get_attribute "dynamic_attributes", "a01hoja2"
			if hoja2 != 0
				pathcarpinteria = Sketchup.find_support_file "DIBAC_PUERTA_DOBLE_3D.skp", "Plugins/Dibac" 
			else
				pathcarpinteria = Sketchup.find_support_file "DIBAC_PUERTA_3D.skp", "Plugins/Dibac"
			end	
			componente = Sketchup.active_model.definitions.load pathcarpinteria
			inicioundo($DibacStrings.GetString"Convert to 3D")
			carp = model3d.entities.add_instance componente, entidad.transformation
			v=entidad.get_attribute "dynamic_attributes", "mocheta"
			carp.set_attribute "dynamic_attributes", "mocheta", v
			v=entidad.get_attribute "dynamic_attributes", "a01hoja1"
			carp.set_attribute "dynamic_attributes", "a01hoja1", v
			v=entidad.get_attribute "dynamic_attributes", "a01hoja2"
			carp.set_attribute "dynamic_attributes", "a01hoja2", v
			v=entidad.get_attribute "dynamic_attributes", "a02dintel"
			carp.set_attribute "dynamic_attributes", "a02dintel", v
			v=entidad.get_attribute "dynamic_attributes", "a02gruesoh" 
			carp.set_attribute "dynamic_attributes", "a02gruesoh", v
			v=entidad.get_attribute "dynamic_attributes", "anchomarco"
			carp.set_attribute "dynamic_attributes", "anchomarco", v
			v=entidad.get_attribute "dynamic_attributes", "gruesmarco" 
			carp.set_attribute "dynamic_attributes", "gruesmarco", v
			v=entidad.get_attribute "dynamic_attributes", "a02alineac" 
			carp.set_attribute "dynamic_attributes", "a02alineac", v
			$dc_observers.get_latest_class.redraw(carp)
		elsif entidad.definition.name[0,13] == "DIBAC_VENTANA" #and @h>=1.m
			pathcarpinteria = Sketchup.find_support_file "DIBAC_VENTANA_3D.skp", "Plugins/Dibac"
			componente = Sketchup.active_model.definitions.load pathcarpinteria
			v=(entidad.get_attribute "dynamic_attributes", "a03alfeizar").to_f
			if @h>=v-0.03.m #Grueso alfeizar
				inicioundo($DibacStrings.GetString"Convert to 3D")
				carp = model3d.entities.add_instance componente, entidad.transformation
				carp.set_attribute "dynamic_attributes", "a03alfeizar", v
				v=entidad.get_attribute "dynamic_attributes", "mocheta"
				carp.set_attribute "dynamic_attributes", "mocheta", v
				v=entidad.get_attribute "dynamic_attributes", "a01ancho"
				carp.set_attribute "dynamic_attributes", "a01ancho", v
				v=entidad.get_attribute "dynamic_attributes", "a02alto"
				carp.set_attribute "dynamic_attributes", "a02alto", v
				v=entidad.get_attribute "dynamic_attributes", "a02hojas"
				carp.set_attribute "dynamic_attributes", "a02hojas", v
				v=entidad.get_attribute "dynamic_attributes", "frontalalf"
				carp.set_attribute "dynamic_attributes", "frontalalf", v
				v=entidad.get_attribute "dynamic_attributes", "carpancho"
				carp.set_attribute "dynamic_attributes", "carpancho", v
				v=entidad.get_attribute "dynamic_attributes", "carpgrueso"
				carp.set_attribute "dynamic_attributes", "carpgrueso", v
				v=entidad.get_attribute "dynamic_attributes", "a02alineac"
				carp.set_attribute "dynamic_attributes", "a02alineac", v
				$dc_observers.get_latest_class.redraw(carp)
			end	
		elsif entidad.definition.name[0,13] == "DIBAC_ARMARIO" #and @h >= 0.07.m
			hojas=entidad.get_attribute "dynamic_attributes", "a01hojas"
			if hojas == 1
				pathcarpinteria = Sketchup.find_support_file "DIBAC_ARMARIO_1_3D.skp", "Plugins/Dibac" 
			else
				pathcarpinteria = Sketchup.find_support_file "DIBAC_ARMARIO_2_3D.skp", "Plugins/Dibac"
			end	
			componente = Sketchup.active_model.definitions.load pathcarpinteria
			v=(entidad.get_attribute "dynamic_attributes", "a01umbral").to_f
			if @h>=v
				inicioundo($DibacStrings.GetString"Convert to 3D")
				carp = model3d.entities.add_instance componente, entidad.transformation
				carp.set_attribute "dynamic_attributes", "a01umbral", v
				v=entidad.get_attribute "dynamic_attributes", "mocheta"
				carp.set_attribute "dynamic_attributes", "mocheta", v
				v=entidad.get_attribute "dynamic_attributes", "a01ancho"
				carp.set_attribute "dynamic_attributes", "a01ancho", v
				v=entidad.get_attribute "dynamic_attributes", "a02dintel"
				carp.set_attribute "dynamic_attributes", "a02dintel", v
				carp.set_attribute "dynamic_attributes", "a01hojas", hojas
				$dc_observers.get_latest_class.redraw(carp)
			end	
		end
		#$dc_observers.get_latest_class.redraw(carp)
	end
	carpinterias.each do |entidad|
		ancho=ancho_carpinteria(entidad)
		ptos = []
		# Si es una ventana utilizamos directamente la mocheta del componente
		ptos = muro_carpinteria(entidad,ancho) 
		# sacamos las mochetas
		mocheta1 = model3d.entities.add_line ptos[0], ptos[1]
		mocheta2 = model3d.entities.add_line ptos[2], ptos[3]
		# determinamos la menor de las mochetas
		ptos = tramo_comun(linea_extremos(mocheta1),linea_extremos(mocheta2))
		# proyectamos sobre la segunda invirtiendo los puntos
		ptos.push(ptos[1].project_to_line(mocheta2.line))
		ptos.push(ptos[0].project_to_line(mocheta2.line))
		# hacemos el muro
		if entidad.definition.name[0,12] == "DIBAC_PUERTA"
			v=(entidad.get_attribute "dynamic_attributes", "a02dintel").to_f
			if @h > v
				ponz(ptos,v)
				face = model3d.entities.add_face ptos
				extrusiona(face,@h-v)
			end	
		else
			#face = Sketchup.active_model.active_entities.add_face ptos 
		end
		if entidad.definition.name[0,13] == "DIBAC_VENTANA"
			v=(entidad.get_attribute "dynamic_attributes", "a03alfeizar").to_f-0.03.m #Grueso alfeizar
			if v > 0
				face = model3d.entities.add_face ptos
				if @h>v
					extrusiona(face,v)
				else
					extrusiona(face,@h)
				end	
			end	
			v = v+(entidad.get_attribute "dynamic_attributes", "a02alto").to_f+0.03.m
			if @h > v
				ponz(ptos,v)
				face = model3d.entities.add_face ptos
				extrusiona(face,@h-v)
			end
		end	
		if entidad.definition.name[0,13] == "DIBAC_ARMARIO"
			v=(entidad.get_attribute "dynamic_attributes", "a01umbral").to_f
			if v>0
				face = model3d.entities.add_face ptos
				if @h>v
					extrusiona(face,v)
				else
					extrusiona(face,@h)
				end
			end
			v = (entidad.get_attribute "dynamic_attributes", "a02dintel").to_f
			if @h > v
				ponz(ptos,v)
				face = model3d.entities.add_face ptos
				extrusiona(face,@h-v)
			end
		end
	end
	model3d.entities.erase_entities carpinterias	
	muros.each do |entidad|
		face = entidad
		extrusiona(face,@h)
	end	
	borra_coplanarias_3d (model3d)
	escaleras.each do |escalera|
		escalera_3d(escalera.make_unique)
	end	
	model3d.explode if !$crear_grupo	
	finalundo
	# modelraiz.select_tool nil
end	

def onUserText(text, view)
	# Aqui se introduce la altura
	text=con_coma(text)
   begin
        valor = text.to_l
    rescue
        # Error al no tratarse de un numero
        UI.beep
        valor = nil
        Sketchup::set_status_text "", SB_VCB_VALUE
    end
    return if !valor
	@h = valor
	Sketchup.undo	
	activate
end

end # de la clase TresDimensiones

class Dibac_Colores < Dibac_Base
=begin
Clase	        		:	Colores
Desciende de		:	Dibac
Descripción   		:	Permite definir el color de linea para nuevas entidades
Item de Menu  		:	Dibujo->Dibac->Color de linea // Barra de herramientas Dibac
Menú contextual	:	NO
Uso         				:	

Fecha        			:	10/04/2012
=end

def activate 
	Sketchup.active_model.active_view.invalidate
	dialog = UI::WebDialog.new("Prueba de colores", true,"PruebaDibac",1000, 641, 150, 150, true)
	fichero =  Sketchup.get_resource_path "Dibac/colores.html"
	dialog.set_file fichero if fichero
	dialog.show
	color = dialog.get_default_dialog_color
#	colores = "<Ninguno>|"+Sketchup::Color.names.join("|")
#	if Sketchup.active_model.selection.count > 0
#		titulo = "Color de seleccion"
#		prompts = 	["Color"]
#		defaults = 	[$color_seleccion]
#		list = 		[colores]
#	else
#		titulo = "Colores de Dibac"
#		prompts = 	["Lineas", "Relleno"]
#		defaults = 	[$color_lineas, $color_superficies]
#		list = 		[colores , colores]
#	end
	input = UI.inputbox prompts, defaults, list, titulo
	if input
		if Sketchup.active_model.selection.count > 0
			$color_seleccion = input[0]
			inicioundo("Color of selection")
			Sketchup.active_model.selection.each do |e|	
				pon_color(e,$color_seleccion)
			end	
			finalundo
		else
			$color_lineas = input[0]
			$color_superficies = input[1]
		end
	end
	Sketchup.active_model.select_tool nil
end

end # de la clase Colores
 
class Dibac_Escalera < Dibac_Base

def initialize
	exit if nolicencia
    @ip = Sketchup::InputPoint.new
    @ip1 = Sketchup::InputPoint.new
	@comando_en_curso = "Stair"
end

def menu
	prompts = [	$DibacStrings.GetString("Width"),
						$DibacStrings.GetString("Height"),
						$DibacStrings.GetString("Going"),
						$DibacStrings.GetString("Rise"),
						$DibacStrings.GetString("Slope")
					 ] 
	huella = ($escalera_huella.to_l).to_s
	huella = '>'+($escalera_huellamin.to_l).to_s if $escalera_huellamin > 0
	tabica = ($escalera_tabica.to_l).to_s
	tabica = '<'+($escalera_tabicamax.to_l).to_s if $escalera_tabicamax > 0
	defaults = [	$escalera_width.to_l.to_s,
						$escalera_height.to_l.to_s,
						huella,
						tabica,
						$escalera_slope.to_l.to_s
					 ] 
	list = 		[	"",
						"",
						"",
						"",
						""
					 ]				 
	input = UI.inputbox prompts, defaults, list, $DibacStrings.GetString(@comando_en_curso)
	if input
		h1 =a_numero(input[0]).abs #ancho
		$escalera_width = h1 if h1>0
		h1 = a_numero(input[1]).abs #alto
		$escalera_height = h1
		h1 = con_coma(input[2]) #huella
		if h1[0].chr == ">"		
			$escalera_huellamin = h1.split(">")[1].to_l.abs 
		else
			h1=a_numero(h1).abs
			if h1  > 0
				$escalera_huella = h1
				$escalera_huellamin = 0 
			end	
		end	
		h1 = con_coma(input[3]) #tabica
		if h1[0].chr == "<"		
			$escalera_tabicamax = h1.split("<")[1].to_l.abs 
		else
			h1=a_numero(h1).abs
			if h1  > 0
				$escalera_tabica = h1
				$escalera_tabicamax = 0 
			end	
		end	
		h1 =a_numero(input[4]) .abs#comodidad
		$escalera_slope = h1
	else	
		Sketchup.active_model.select_tool nil	
		exit
	end	
	@huella=$escalera_huellamin
	@huella=$escalera_huella if $escalera_huellamin==0
	huella_tabica
	reset				 
end

def reset
	borra_auxiliares
	@puntos = @total_peld = 0
	@ptini = @ptfin = @pt1 = @pt2 = @pt3 = @pt4 = []
    @pts_d = [] #puntos cara derecha
	@pts_i = [] #Puntos cara izquierda
	@pts_cursor = [] #Puntos cursor
	@cara_tramo =[] #cara en que se construyo el tamo
	@arfin = nil
	@cl1=nil
	@recorrido=false
	@cancelar=false #Para distinguir entre Ctrl-Z y Esc.
    Sketchup::set_status_text "", SB_VCB_LABEL
    Sketchup::set_status_text "", SB_VCB_VALUE
    texto_comando
end

def activate
	Sketchup.active_model.active_view.invalidate
    menu
end

def texto_comando
	texto = $DibacStrings.GetString("Stair") 
	if !@recorrido
		texto= texto+"["+ $escalera_width.to_l.to_s+'].'
	else
		texto= texto+"["+ $DibacStrings.GetString("Path")+'].'
	end
	if @puntos == 0
		texto = texto+$DibacStrings.GetString("Starting point")+"("+ $DibacStrings.GetString("Dbl_Click for Path")+")"
	else	
		texto= texto+$DibacStrings.GetString("End point")
		texto = texto + ", " + $DibacStrings.GetString("or specify width preceded by") + " '-'" if !@recorrido
		end	
	texto = texto+". "
	texto = texto + "Tab="+$DibacStrings.GetString("Change edge")+"." if @primer_punto
	Sketchup::set_status_text  texto 
end		

def deactivate(view)
	view.invalidate
	reset
end

def onSetCursor
	UI.set_cursor($escaleracursor_id)
end

def auxiliares(punto)
	borra_auxiliares
	inicioundo('Tramo de escalera')
	crea_auxiliares(punto)
	finalundo
end

def borra_auxiliares
	if !@cl1.deleted?
		Sketchup.undo
	end if @cl1
end	

def calcula_puntos
	if (@puntos == 0) then 
 		@ptini = @ip.position
    else
		if @puntos > 1 
			vertice1=@ptini.project_to_line [@pts_i[@puntos-1],@pts_i[@puntos-2]]
			vertice2=@ptini.project_to_line [@pts_d[@puntos-1],@pts_d[@puntos-2]]
			vec = (vertice1 - vertice2)
			@ptini = vertice1.offset(vec, -$escalera_cara*vec.length)
		end	
 		if $escalera_cara > 0 then
			vec = @ptini - [@ptini[0] + (@ptfin[1] - @ptini[1]), @ptini[1] - (@ptfin[0] - @ptini[0]),@ptini[2]]
			@pt1 = @ptini.offset(vec, $escalera_cara * $escalera_width)	 
			@pt2 = @ptfin.offset(vec, $escalera_cara * $escalera_width)
		else
			@pt1 = @ptini	 
			@pt2 = @ptfin	   
		end
		vec = @ptini - [@ptini[0] - (@ptfin[1] - @ptini[1]), @ptini[1] + (@ptfin[0] - @ptini[0]),@ptini[2]]
		Sketchup::set_status_text vec.length.to_s, SB_VCB_VALUE
		@pt3 = @pt1.offset(vec, $escalera_width)	 
		@pt4 = @pt2.offset(vec, $escalera_width)	   
		if (@puntos > 1) 
			if !((@pt3- @pt4).parallel? (@pts_d[@puntos-2]-@pts_d[@puntos-1]))
				vec = (@pts_d[@puntos-2]-@pts_d[@puntos-1])
				vec = (@pts_i[@puntos-2]-@pts_i[@puntos-1]) if vec.length < 0.000001
				@pt3 = Geom.intersect_line_line([@pt3, @pt4], [@pts_d[@puntos-2], vec])
				@pt1 = Geom.intersect_line_line([@pt1, @pt2], [@pts_i[@puntos-2], vec])
			end
		end
	end
end

def onMouseMove(flags, x, y, view)
    return false if(!@ip.pick(view, x, y, @ip1))
	texto_comando
    # pone tooltip segun el elemento
    view.tooltip = @ip.tooltip
	@ptfin=@ip.position
    calcula_puntos
	view.invalidate
	@arfin = busca_cara(x, y, view)
end

def tramo_escalera
	@pt_final_i=@pt_rest_i
	@pt_final_d=@pt_rest_d
	@pts_cursor[@puntos] = @ptini
	@ptini = @ptfin
	@pts_i[@puntos] = @pt2
	@pts_d[@puntos-1] = @pt3
	@pts_d[@puntos] = @pt4
	@pts_i[@puntos-1] = @pt1
	@cara_tramo[@puntos] = $escalera_cara
end

def escalones(linea) # Devuelve los escalones de usuario. 
	lineas_ini = []
	puntos =[]
	Sketchup.active_model.active_entities.each do |e|
		if e.typename == "Edge"
			pt=interseccion_real(linea[0], linea[1], e.start.position, e.end.position)
			if pt
				puntos.push pt
				lineas_ini.push e
			end
		end	
	end		
	i = -1
	ultimadistancia=-1
	lineas_ordenadas=[] 
	while i < puntos.size-1 do
		j = 0
		k = 0
		distancia = 1000000.0
		while j < puntos.size
			if puntos[j] 
				if (linea[0]-puntos[j]).length < distancia
					distancia = (linea[0]-puntos[j]).length
					linea_mas_cerca = lineas_ini[j]
					k = j
				end	
			end 
			j += 1
		end
		lineas_ordenadas.push(linea_mas_cerca) if distancia > ultimadistancia
		ultimadistancia=distancia
		puntos[k] = nil
		i += 1
	end	
	caras=[]
	lineas_ordenadas.each do |e|		
		if e.faces.size == 2 || (e.faces.size ==1 && caras.size==0 && @huellas_recorrido.size==0)
			normales=0
			e.faces.each do |f|
				normales=normales+f.normal.z.abs
			end
			if normales>0.999999+e.faces.size-1
				e.faces.each do |f|
					caras.push f if f != @ultima_huella
				end
				@ultima_huella=caras[caras.size-1]
			end	
		end 
	end	
	return caras
end

def onLButtonDown(flags, x, y, view)
	@ip1.copy! @ip
	if @puntos == 0 then
		@pts_i[@puntos] = @ip.position
		@pts_cursor[@puntos] = @ip.position
	else
		@ptfin=@ptescalon if !@pulsado_control  && !@recorrido
		calcula_puntos
		tramo_escalera
	end
	@puntos +=1
	auxiliares(@ptini)
	texto_comando
end

def onRButtonDown(flags, x, y, view)
	ejecuta_escalera
end	

def onLButtonDoubleClick(flags, x, y, view)
	if @puntos==1 
		@recorrido=true
	else	
		ejecuta_escalera
	end	
	texto_comando
	view.invalidate
end	

def ejecuta_escalera
	borra_auxiliares
	inicioundo(@comando_en_curso)
	if @recorrido
		escalera_recorrido 
	else
		escalera_generada
	end	
	finalundo
	Sketchup.active_model.select_tool nil
end

def escalera_recorrido
	escalera2=Sketchup.active_model.active_entities.add_group
	huellas=@huellas_final
	peld=0
	huellas.each do |face|
		peld+=1
		face.set_attribute "escalera","escalon",peld
		face.reverse! if face.normal.z<0
	end
	escalera2=Sketchup.active_model.active_entities.add_group(huellas)
	@tabica=$escalera_height/peld if $escalera_height>0
	escalera2.set_attribute "escalera","3d",peld*@tabica
	#escalera_3d(escalera2,3.20.m)
end

def escalera_generada
	escalera = Sketchup.active_model.active_entities.add_group
	escalera2=Sketchup.active_model.active_entities.add_group
	punto=nil
	peld=0
	#Completamos el ultimo escalon
	@pts_i[@puntos-1]=@pt_final_i
	@pts_d[@puntos-1]=@pt_final_d
	for i in 1 ... @puntos
		temp=[@pts_i[i-1], @pts_i[i], @pts_d[i], @pts_d[i-1]]
		ptos=[temp[0]]
		for j in 1 ... temp.size
			ptos.push(temp[j]) if ptos[ptos.size-1]!=temp[j] #para que no haya repetidos
		end
		face=escalera.entities.add_face ptos
		#borra_coplanarias(face.edges)
		if punto
			edges=face.edges
			edges.each do |e|
				escalera.entities.erase_entities e if e.faces.size==2 && !punto_en_segmento (punto, e.start.position, e.end.position)
			end			
		end		
		ht=huellas_tramo([@pts_i[i-1],@pts_i[i]],[@pts_d[i-1],@pts_d[i]], punto)
		if ht
			1.step(ht.size-1,2) do |j|
				escalera.entities.add_line ht[j-1],ht[j]
			end	
			punto=punto_medio(ht[ht.size-2],ht[ht.size-1])
		end	if @pts_i[i-1]!=@pts_i[i] && @pts_d[i-1] != @pts_d[i]	
		escalera.entities.add_line @pts_i[i-1],@pts_i[i]
		escalera.entities.add_line @pts_d[i-1],@pts_d[i]
		huellas=[]
		escalera.entities.each do |e|
			huellas.push e if e.typename=='Face'
		end
		for j in 0..huellas.size-2
			e=huellas[j]
			vert=[]
			e.vertices.each do |v|
				vert.push v.position
			end	
			peld+=1
			face=escalera2.entities.add_face vert
			face.set_attribute "escalera","escalon",peld
			face.reverse! if face.normal.z<0
		end
		e=huellas[huellas.size-1]
		vert=[]
		e.vertices.each do |v|
			vert.push v.position
		end
		Sketchup.active_model.active_entities.erase_entities escalera
		escalera=Sketchup.active_model.active_entities.add_group
		escalera.entities.add_face vert
	end	
	peld+=1
	face=escalera2.entities.add_face vert
	face.set_attribute "escalera","escalon",peld
	face.reverse! if face.normal.z<0
	Sketchup.active_model.active_entities.erase_entities escalera
	escalera2.set_attribute "escalera","3d",peld*@tabica
	#escalera_3d(escalera2,3.20.m)
end

def onCancel(flag, view)
	@cancelar=true
	if @puntos==1
		view.lock_inference if( view.inference_locked? )
		reset
	end	
end

def longitud_usuario (value, view) # view por si un dia funciona el posicionar el cursor
	# longitud del muro
	
end

def onUserText(text, view)
	valores = text.split("<")
	if valores[1]
		angulo = valores[1].to_f.degrees
		$hv = [Math.cos(angulo), Math.sin(angulo)]
		auxiliares(@ptini) if @puntos > 0
		return
	end
	valores=valores[0].split($separador_listas)
	if valores[1] #longitud de peldaño
		valores2 = valores[1].split('>')
		if valores2[1]
			l=long_valida(valores2[1])
			$escalera_huellamin = l if l
		else
			l=long_valida(valores2[0])
			if l
				$escalera_huella=l
				$escalera_huellamin=0
			end
		end
		huella_tabica
	end
	valores = valores[0].split'*'
	if valores[1]
		l=valores[1].to_i
		value=@primer_peld+l*@huella+0.000001
	else
		value=long_valida(valores[0])
	end	
	if value
		if value < 0 then
			# grueso del muro
			$escalera_width = value.abs.to_l
			texto_comando
			calcula_puntos
		elsif @puntos > 0 && value>0
			vec = @ptfin - @ptini
			if( vec.length > 0.0 )
				vec.length = value
				@ptfin = @ptini.offset(vec)
				calcula_puntos
				tramo_escalera
				@puntos +=1
			end	
		end
	end
	auxiliares(@ptini)
	texto_comando
	view.invalidate
 end
 
def huella_tabica # @huella para el primer tramo
	@huella=0 if @huella.to_s=='NaN'
	if @huella==0
		@huella=$escalera_huellamin
		@huella=$escalera_huella if @huella==0
	end
	if $escalera_tabicamax > 0
		@tabica=1000000.0 
		@tabica=($escalera_slope-@huella)/2  if $escalera_slope>0   #calculamos la tabica en funcion de la huella
		@tabica=$escalera_tabicamax if @tabica>$escalera_tabicamax
	else
		@tabica=$escalera_tabica
	end	
	if $escalera_height>0
		n=(($escalera_height/@tabica)).to_i
		@tabica=$escalera_height/n
		tabicamax=$escalera_tabicamax
		tabicamax=$escalera_tabica if tabicamax==0
		while @tabica>tabicamax
			n+=1
			@tabica=$escalera_height/n
		end	
		@total_peld=n
	end	
	if $escalera_huellamin>0 #No hace falta comprobar $escalera_huella porque ya viene hecho
		@huella=$escalera_slope-(2*@tabica)
		while @huella<$escalera_huellamin
			n+=1
			@tabica=$escalera_height/n
			@huella=$escalera_slope-(2*@tabica)
		end if $escalera_height > 0	
	end  if $escalera_slope > 0
end

def huellas_tramo(lineai, linead, punto)
	huellas=[]
	extremos =tramo_comun(lineai, linead) #maximo tramo para peldaños
	return nil if extremos == []
	tramo = (extremos[0]-extremos[1])
	return nil if tramo.length < 0.000001
	peld1 = [extremos[0],extremos[0].project_to_line(linead)] #primer peldaño del tramo
	dist = punto.distance_to_line peld1 if punto
	
	if dist<@huella
		if punto_en_segmento(punto.project_to_line(peld1), peld1[0], peld1[1])
			extremos[0]=punto_a_distancia(extremos[0],extremos[1],@huella-dist)
		end		
	end if dist
	
	if(extremos[1]-lineai[0]).length < (extremos[0]-lineai[0]).length 
		@primer_peld=0.0 #Para sumar al numero de peldaños en longitud de usuario
		return
	end	
	tramo = (extremos[0]-extremos[1])
	if @huella==0
		@huella=tramo.length/((tramo.length/$escalera_huellamin).to_i)
		huella_tabica
	end	
	n=(tramo.length/@huella).to_i
	for i in 0 .. n
		pt1=punto_a_distancia(extremos[0],extremos[1],i*@huella) 
		huellas.push(pt1)
		huellas.push(pt1.project_to_line(linead))
	end
	return huellas
end

def texto_descansillo(view, punto, peld_tramo, peld)
	#view.draw_text(view.screen_coords (punto), peld_tramo.to_s+'/'+peld.to_s+'/'+(peld*@tabica).to_l.to_s) if peld_tramo > 0	
	view.draw_text(view.screen_coords (punto), peld.to_s+'/'+(peld*@tabica).to_l.to_s) if peld_tramo > 0	
end	

def draw(view)
	textoevaluacion(view)
	x=view.corner(0)[0]
	y=view.corner(0)[1]
	#view.draw2d GL_LINE_LOOP, [[x+1,y+20],[x+111,y+20],[x+111,y+110],[x+1,y+110]]
	if !@recorrido
		view.draw_text([x+2,y+24],$DibacStrings.GetString(@comando_en_curso))
		huella_tabica
		view.draw_text([x+2,y+38],$DibacStrings.GetString("Going")+':'+@huella.to_l.to_s)
		view.draw_text([x+2,y+50],$DibacStrings.GetString("Rise")+':'+@tabica.to_l.to_s)
		view.draw_text([x+2,y+62],$DibacStrings.GetString("Slope")+':'+(2*@tabica+@huella).to_l.to_s)
	end	
	# si no hay auxiliares tira para atras
	if @cl1.deleted? && @cancelar
		@cancelar=false if @puntos>1
		@puntos -=1
		$escalera_cara = @cara_tramo[@puntos]
		@ptini = @pts_cursor[@puntos]
		auxiliares(@ptini)
		calcula_puntos
	elsif @cancelar
		ejecuta_escalera
		return
	end if @cl1
	reset if @cancelar
	# Muestra el punto actual
    @ip.draw(view) if( @ip.valid? && @ip.display? )
    # previsualiza la escalera
    view.drawing_color = "black"
    inference_locked = view.inference_locked?
	peld=0
	if @recorrido && @puntos>0 #recorrido de usuario
		if $escalera_height>0
			if @huellas_recorrido
				@tabica=$escalera_height/@huellas_recorrido.size if @huellas_recorrido.size>0
			end	
		end
		@ultima_huella=nil
		@huellas_recorrido=[]
		if @puntos>1
			view.draw(GL_LINE_STRIP, @pts_cursor[0..@puntos-1])
			view.draw(GL_LINE_STRIP, @pts_cursor[@puntos-1],@ptini)
		end
		if @puntos > 1
			for i in 1...@puntos
				h=escalones([@pts_cursor[i-1],@pts_cursor[i]])
				@huellas_recorrido=@huellas_recorrido+h
				peld_tramo=h.size
				peld +=peld_tramo
				pt_texto=@pts_cursor[i]
				texto_descansillo(view,pt_texto, peld_tramo,peld)
			end 
			h=escalones([@pts_cursor[@puntos-1],@ptini])
			@huellas_recorrido=@huellas_recorrido+h
			peld_tramo=h.size
			peld +=peld_tramo
			pt_texto=@ptini
			texto_descansillo(view,pt_texto, peld_tramo,peld)
		end 
		@huellas_final=@huellas_recorrido
		view.draw(GL_LINE_STRIP, @ptini, @ptfin)
		h=escalones([@ptini,@ptfin])
		@huellas_recorrido=@huellas_recorrido+h
		peld_tramo=h.size
		peld+=peld_tramo
		pt_texto=@ptfin
		texto_descansillo(view,pt_texto, peld_tramo,peld)
		return
	end
	# escalera generada
	@huella=$escalera_huella
	@huella=0.0 if $escalera_huellamin > 0
	punto = nil
	peld_tramo=0
    if @puntos > 1 then
		if @puntos >2
			view.draw(GL_LINE_STRIP, @pts_i[0..@puntos-2])
			view.draw(GL_LINE_STRIP, @pts_d[0..@puntos-2])
			for i in 1..@puntos-2 
				ht=huellas_tramo([@pts_i[i-1],@pts_i[i]],[@pts_d[i-1],@pts_d[i]], punto)
				if ht
					peld_tramo=ht.size/2
					peld=peld+peld_tramo
					view.draw(GL_LINES, ht)
					punto=punto_medio(ht[ht.size-2],ht[ht.size-1])
					texto_descansillo(view,punto, peld_tramo,peld)
				end	if @pts_i[i-1]!=@pts_i[i] && @pts_d[i-1] != @pts_d[i]
			end	
		end
		if @ptini != @ptfin	
			view.draw(GL_LINE_STRIP, @pts_i[@puntos-2], @pt1)
			view.draw(GL_LINE_STRIP, @pts_d[@puntos-2], @pt3)
			ht=huellas_tramo([@pts_i[@puntos-2], @pt1],[@pts_d[@puntos-2], @pt3], punto)
			if ht
				peld_tramo=ht.size/2
				peld=peld+peld_tramo
				punto=punto_medio(ht[ht.size-2],ht[ht.size-1])
				texto_descansillo(view,punto, peld_tramo,peld)
				view.draw(GL_LINES, ht)
			end	
		end
	end	
	# Ultimo tramo
 	view.set_color_from_line(@ip1, @ip)
	ht = huellas_tramo([@pt1, @pt2],[@pt3, @pt4], punto)
	if ht.size > 0
		pt = @ptini.project_to_line [ht[0],ht[1]]
		@primer_peld=(@ptini-pt).length
		peld_tramo=ht.size/2
		peld=peld+peld_tramo
		pt_texto=punto_medio(ht[ht.size-2],ht[ht.size-1])
	end
	texto_descansillo(view,pt_texto, peld_tramo,peld)
	view.draw(GL_LINES,ht)
	view.line_width = 3 if inference_locked
	view.draw(GL_LINE_STRIP, @pt1, @pt2)
    view.draw(GL_LINE_STRIP, @pt3, @pt4)
    view.line_width = 1 if inference_locked
	#return
	pt = @ptfin.project_to_line [ht[ht.size-2],ht[ht.size-1]]
	vec=@ptfin-pt
	dist_peld=vec.length
	vec.length=0.000001
	@ptescalon=pt.offset(vec) #punto en escalon
	vec=(@ptfin-@ptini)
	value=@huella+0.000001
	vec.length = value-dist_peld
	# ultimo peldaño completo
	@pt_rest_i = @pt2.offset(vec)
	@pt_rest_d = @pt4.offset(vec)
	if peld<@total_peld+1
		# Resto de escalera si se ha indicado altura
		resto=@total_peld-peld+1
	else
		resto=1
	end
	value=resto*@huella+0.000001
	vec.length = value-dist_peld
	pt_rest_1 = @pt2.offset(vec)
	pt_rest_2 = @pt4.offset(vec)
	ht = huellas_tramo([@pt2, pt_rest_1],[@pt4, pt_rest_2], pt_texto)
	view.drawing_color = "red"
	view.draw(GL_LINES,ht)
	view.draw(GL_LINE_STRIP, @pt2, pt_rest_1)
	view.draw(GL_LINE_STRIP, @pt4, pt_rest_2)
end

def tabulador
	return if @recorrido
	if $escalera_inc then
		$escalera_cara += 0.5
	elsif
		$escalera_cara -= 0.5
	end	
	$escalera_inc = !$escalera_inc if $escalera_cara != 0.5
end

def onKeyDown(key, rpt, flags, view)
	if key == 9 then
		tabulador
		calcula_puntos
		auxiliares(@ptini)
		view.invalidate
	elsif key == 119 #F8
		lb = @arfin.line 
		if lb
			$hv = [lb[1][0],lb[1][1]] #coseno y seno del angulo
			auxiliares(@ptini) if @puntos > 0
		end
	elsif( key == CONSTRAIN_MODIFIER_KEY && rpt == 1 )
        # Si esta activado desactivarlo
        if( view.inference_locked? )
            view.lock_inference
        elsif !@primer_punto
            view.lock_inference @ip
        elsif
            view.lock_inference @ip, @ip1
		end
	elsif(key == COPY_MODIFIER_KEY)
		@pulsado_control = true
	end	
end

def onKeyUp(key, rpt, flags, view)
	if(key == CONSTRAIN_MODIFIER_KEY && view.inference_locked?)
		view.lock_inference
	elsif(key == COPY_MODIFIER_KEY)
		@pulsado_control=false
    end
end

end # de la clase Escalera

class Dibac_Licencia

def autorizar
	prompts = 	[	$DibacStrings.GetString("User")+":",
						$DibacStrings.GetString("E_mail")+":",
						$DibacStrings.GetString("Serial number")+":",
						$DibacStrings.GetString("Authorization number")+":     "
						]
						
	defaults = 	[	"",
						"",
						"",
						""
					]
						
	list = 			[	"",
							"",
							"",
							""
						]
	input = UI.inputbox prompts, defaults, list,$DibacStrings.GetString("Dibac for Sketchup")+": "+$DibacStrings.GetString("User License")
	if input
		num1=sacaclave(input[1].to_s)
		num2=sacaclave(input[2].to_s)
		if num1 != '' && num1==input[2].to_s && num2==input[3].to_s
			$usuario=input[0].to_s
			$email=input[1].to_s
			$numserie=input[2].to_s
			$clave=input[3].to_s
			texto=$DibacStrings.GetString ("Valid License")
			Sketchup.write_default "Dibac","User",$usuario
			Sketchup.write_default "Dibac","Email",$email
			Sketchup.write_default "Dibac","Serial",$numserie
			Sketchup.write_default "Dibac","Key",$clave
			Sketchup.active_model.active_view.invalidate
		else
			texto=$DibacStrings.GetString ("Invalid License")
		end	
		UI.messagebox (texto)
	end	
end
	
def sacaclave(texto)	
	return '' if (texto==nil || texto=='')
	modulo=$modulo
	aleatorio1=texto[0] % modulo
	aleatorio2=texto[texto.length-1] % modulo 
	i=0
	clave=''
	a=(aleatorio2 + modulo).chr
	while i<texto.length do
		a << (aleatorio1+texto[i] % modulo).chr
		a << (aleatorio2 + a[2*i+1] % modulo).chr
		i +=1
	end
	jj=0
	i=1
	j= (a.length)/11
	if a.length>10
		while i+j<a.length do
			for ii in 0 ... j 
				jj=jj+a[i-1]
				i+=1
			end
			jj=jj % 10
			jj +=39 if jj>9
			clave=clave+(jj+48).chr
		end	
	end 
	return clave
end

def licencia
	usuario	=Sketchup.read_default "Dibac","User",""
	email		=Sketchup.read_default "Dibac","Email",""
	numserie=Sketchup.read_default "Dibac","Serial",""
	clave		=Sketchup.read_default "Dibac","Key",""
	num1=sacaclave(email)
	num2=sacaclave(num1)
	$usuario=usuario
	$email=email
	$numserie = ''
	$clave = ''
	if ((num1==numserie) && (num2==clave))
		$numserie = numserie
		$clave = clave
	end
end

def informacion
	t=Time.now
	texto=$DibacStrings.GetString ('Dibac for Sketchup')+"\n" + Dibac.description + "\n"
	if $clave == 'promo'
		texto=texto + $DibacStrings.GetString ("Cracked by Phan Ðình Tùng |")+" Phone: 0977027772 | Site: http://kientrucdn.com"
	elsif $clave != '' 
		texto = texto + $DibacStrings.GetString ('User') + ": " + $usuario + " - " + $email + "\n"
		texto=texto + $DibacStrings.GetString('Serial number') + ": " + $numserie
	else
		texto=texto+$DibacStrings.GetString ("Sorry. Your promotional license has expired.")+"\n"
		texto=texto+$DibacStrings.GetString("Please contact your dealer.")+"\n"+"www.iscarnet.com"
	end	
	UI.messagebox(texto)
end

def desautorizar
	texto = $DibacStrings.GetString ("You are about to remove the authorization to use")+' '+$DibacStrings.GetString ('Dibac for Sketchup')
	texto=texto+'. '+$DibacStrings.GetString ("You can not run again if the product does not authorize a valid license.")+"\n"
	texto=texto+' '+$DibacStrings.GetString ("Are you sure you want to continue?")
	 if UI.messagebox(texto, MB_YESNO) == 6 then
		$usuario = $email = $numserie = $clave = ''
		Sketchup.write_default "Dibac","User",$usuario
		Sketchup.write_default "Dibac","Email",$email
		Sketchup.write_default "Dibac","Serial",$numserie
		Sketchup.write_default "Dibac","Key",$clave
		Sketchup.active_model.active_view.invalidate
	end	
end

end #de la clase Licencia

class Dibac_Preferencias < Dibac_Base

def menu
	path =(Sketchup.find_support_file "dibac_cmd.rbs",  "plugins/Dibac/").to_s
	path=path [0 .. path.length-15] #longitud de dibac_cmd.rbs
	path=path + '/resources'
	lenguajes = []
	Dir.foreach (path) { |f|
		lenguajes.push (f.to_s) if f.to_s != '.' && f.to_s !='..'
	}
	
	prompts=[]
	prompts = 	[	$DibacStrings.GetString("Language")+":"
						]
						
	defaults = 	[	$DibacStrings.GetString($DibacLenguaje)
					]
	lista=""
	lenguajes.each do |l|
		lista=lista+$DibacStrings.GetString(l)+"|"
	end	
	list=[lista]
	input = UI.inputbox prompts, defaults, list,$DibacStrings.GetString("Dibac for Sketchup")+": "+$DibacStrings.GetString("Options")
	if input
		lista=lista.split("|")
		i=0
		i += 1 while lista[i] != input[0]
		$DibacLenguaje=lenguajes[i]
		$DibacStrings = Dibac_Lenguaje.new
		Sketchup.write_default "Dibac","Language",$DibacLenguaje
	end
	Sketchup.active_model.select_tool nil	
end
	
end # de la clase preferencias

$DibacLenguaje	=Sketchup.read_default "Dibac","Language",Sketchup.get_locale[0,2]

$DibacLicencia = Dibac_Licencia.new
$modulo=128 #clave para proteccion

$DibacLicencia.licencia
t=Time.now
$clave='promo' if t.year >= 2013 && t.month >= 6 && $clave == ''
	
unless $dibac_menu_loaded
	#buscamos signo decimal
	s=0.1.m.to_s
	if (s[1].chr) ==','
		$separador_listas=';'
	else
		$separador_listas=','
	end
	#Observadores
	Sketchup.add_observer(Dibac_ObservadorApp.new)
	Sketchup.active_model.tools.add_observer(Dibac_ObservadorTools.new)
	#Muro
	$murocmd = UI::Command.new("Muro") { Sketchup.active_model.select_tool Dibac_Muro.new }
	path_comando = Sketchup.find_support_file "muro.png", "Plugins//Dibac"
	$murocmd.small_icon = path_comando if path_comando
	$murocmd.large_icon = path_comando if path_comando
	#Muro paralelo
	$muropcmd = UI::Command.new("Muro paralelo") { Sketchup.active_model.select_tool Dibac_Murop.new }
	path_comando = Sketchup.find_support_file "MuroP.png", "Plugins//Dibac"
	$muropcmd.small_icon = path_comando if path_comando
	$muropcmd.large_icon = path_comando if path_comando
	#Estirar muros
	$Estiramurocmd = UI::Command.new("Prolongar muro") { Sketchup.active_model.select_tool Dibac_Estiramuro.new }
	path_comando = Sketchup.find_support_file "Estirarmuro.png", "Plugins//Dibac"
	$Estiramurocmd.small_icon = path_comando if path_comando
	$Estiramurocmd.large_icon = path_comando if path_comando
	#Puertas
	$puertacmd = UI::Command.new("Puerta") { Sketchup.active_model.select_tool Dibac_Puerta.new }
	path_comando = Sketchup.find_support_file "Puerta.png", "Plugins//Dibac"
	$puertacmd.small_icon = path_comando if path_comando
	$puertacmd.large_icon = path_comando if path_comando
	#Ventanas
	$ventanacmd = UI::Command.new("Ventana") { Sketchup.active_model.select_tool Dibac_Ventana.new }
	path_comando = Sketchup.find_support_file "Ventana.png", "Plugins//Dibac"
	$ventanacmd.small_icon = path_comando if path_comando
	$ventanacmd.large_icon = path_comando if path_comando
	#Armarios
	$armariocmd = UI::Command.new("Armario") { Sketchup.active_model.select_tool Dibac_Armario.new }
	path_comando = Sketchup.find_support_file "Armario.png", "Plugins//Dibac"
	$armariocmd.small_icon = path_comando if path_comando
	$armariocmd.large_icon = path_comando if path_comando
	#borrarcmd = UI::Command.new("Borrar") { Sketchup.active_model.select_tool Borrar.new }
	#path_comando = Sketchup.find_support_file "Borrar.png", "Plugins//Dibac"
	#borrarcmd.small_icon = path_comando if path_comando
	#borrarcmd.large_icon = path_comando if path_comando
	#Escaleras
	$escaleracmd = UI::Command.new("Escalera") { Sketchup.active_model.select_tool Dibac_Escalera.new }
	path_comando = Sketchup.find_support_file "escalera.png", "Plugins//Dibac"
	$escaleracmd.small_icon = path_comando if path_comando
	$escaleracmd.large_icon = path_comando if path_comando
	#Acotado continuo
	$cotacontinuacmd = UI::Command.new("Acotado continuo") { Sketchup.active_model.select_tool Dibac_CotaContinua.new }
	path_comando = Sketchup.find_support_file "CotaContinua.png", "Plugins//Dibac"
	$cotacontinuacmd.small_icon = path_comando if path_comando
	$cotacontinuacmd.large_icon = path_comando if path_comando
	#Licencia
	#licenciacmd = UI::Command.new("Informacion de licencia") { Sketchup.active_model.select_tool Licencia.new }
	#path_comando = Sketchup.find_support_file "Usuario.png", "Plugins//Dibac"
	#licenciacmd.small_icon = path_comando if path_comando
	#licenciacmd.large_icon = path_comando if path_comando
	#licenciacmd.tooltip = $DibacStrings.GetString("User License")
	#Preferencias
	$preferenciascmd = UI::Command.new("Preferencias") { Sketchup.active_model.select_tool Dibac_Preferencias.new }
	path_comando = Sketchup.find_support_file "Preferencias.png", "Plugins//Dibac"
	$preferenciascmd.small_icon = path_comando if path_comando
	$preferenciascmd.large_icon = path_comando if path_comando
	#Impresion Dibac
	#imprimedibaccmd = UI::Command.new("Impresión Dibac") { Sketchup.active_model.select_tool ImprimeDibac.new }
	#path_comando = Sketchup.find_support_file "Impresora.png", "Plugins//Dibac"
	#imprimedibaccmd.small_icon = path_comando if path_comando
	#imprimedibaccmd.large_icon = path_comando if path_comando
	#imprimedibaccmd.tooltip = $DibacStrings.GetString("Print Dibac")
	$tresdcmd = UI::Command.new("Convertir en 3D") { Sketchup.active_model.select_tool Dibac_TresDimensiones.new }
	path_comando = Sketchup.find_support_file "3D.png", "Plugins//Dibac"
	$tresdcmd.small_icon = path_comando if path_comando
	$tresdcmd.large_icon = path_comando if path_comando
	#colorescmd = UI::Command.new("Color de lineas") { Sketchup.active_model.select_tool Colores.new }
	#path_comando = Sketchup.find_support_file "colores.png", "Plugins//Dibac"
	#colorescmd.small_icon = path_comando if path_comando
	#colorescmd.large_icon = path_comando if path_comando
	barradibac = UI::Toolbar.new "Dibac"
	$murocursor_id = nil
	$muropcursor_id = nil
	$estiramurocursor_id = nil
	murocursor_path = Sketchup.find_support_file "cursormuro.png", "Plugins//Dibac"
	muropcursor_path = Sketchup.find_support_file "cursormurop.png", "Plugins//Dibac"
	estiramurocursor_path = Sketchup.find_support_file "cursorestirarmuro.png", "Plugins//Dibac"
	escaleracursor_path = Sketchup.find_support_file "cursorescalera.png", "Plugins//Dibac"
	borrarcursor_path = Sketchup.find_support_file "cursorborrar.png", "Plugins//Dibac"
	borrarcursordibac_path = Sketchup.find_support_file "cursorborrardibac.png", "Plugins//Dibac"
	$murocursor_id = UI.create_cursor(murocursor_path, 4,28) if murocursor_path 
	$muropcursor_id = UI.create_cursor(muropcursor_path, 6,27) if muropcursor_path 
	$estiramurocursor_id = UI.create_cursor(estiramurocursor_path, 4,28) if estiramurocursor_path 
	$borrarcursor_id = UI.create_cursor(borrarcursor_path, 5,21) if borrarcursor_path 
	$escaleracursor_id = UI.create_cursor(escaleracursor_path, 4,28) if escaleracursor_path 
	$borrarcursordibac_id = UI.create_cursor(borrarcursordibac_path, 5,21) if borrarcursordibac_path 
	barradibac = barradibac.add_item $murocmd
	barradibac = barradibac.add_item $muropcmd
	barradibac = barradibac.add_item $Estiramurocmd
	barradibac = barradibac.add_item $puertacmd
	barradibac = barradibac.add_item $ventanacmd
	barradibac = barradibac.add_item $armariocmd
	barradibac = barradibac.add_item $escaleracmd
	#barradibac = barradibac.add_item borrarcmd
	barradibac = barradibac.add_item $cotacontinuacmd
	#barradibac = barradibac.add_item imprimedibaccmd
	barradibac = barradibac.add_item $tresdcmd
	barradibac = barradibac.add_item $preferenciascmd
	#barradibac = barradibac.add_item colorescmd
	barradibac.show
	
	$DibacStrings = Dibac_Lenguaje.new

	add_separator_to_menu("Draw")
	menu = UI.menu("Draw").add_submenu("Dibac")
	item=menu.add_item ($DibacStrings.GetString("Wall")) {Sketchup.active_model.select_tool Dibac_Muro.new}
	$DibacStrings.unchecked(menu,item)
	item=menu.add_item ($DibacStrings.GetString("Paralell wall")) {Sketchup.active_model.select_tool Dibac_Murop.new}
	$DibacStrings.unchecked(menu,item)
	item=menu.add_item ($DibacStrings.GetString("Extend wall")) {Sketchup.active_model.select_tool Dibac_Estiramuro.new}
	$DibacStrings.unchecked(menu,item)
	item=menu.add_item ($DibacStrings.GetString("Door")) {Sketchup.active_model.select_tool Dibac_Puerta.new}
	$DibacStrings.unchecked(menu,item)
	item=menu.add_item ($DibacStrings.GetString("Window")) {Sketchup.active_model.select_tool Dibac_Ventana.new}
	$DibacStrings.unchecked(menu,item)
	item=menu.add_item ($DibacStrings.GetString("Cabinet")) {Sketchup.active_model.select_tool Dibac_Armario.new}
	$DibacStrings.unchecked(menu,item)
	item=menu.add_item ($DibacStrings.GetString("Stair")) {Sketchup.active_model.select_tool Dibac_Escalera.new}
	$DibacStrings.unchecked(menu,item)
	#submenu.add_item("Borrar elentos Dibac") {Sketchup.active_model.select_tool Borrar.new}
	item=menu.add_item ($DibacStrings.GetString("Continuous dimension")) {Sketchup.active_model.select_tool Dibac_CotaContinua.new}
	$DibacStrings.unchecked(menu,item)
	#submenu.add_item("Impresion Dibac") {Sketchup.active_model.select_tool ImprimeDibac.new}
	item=menu.add_item ($DibacStrings.GetString("Convert to 3D")) {Sketchup.active_model.select_tool Dibac_TresDimensiones.new}
	$DibacStrings.unchecked(menu,item)
	#submenu.add_item("Color de linea") {Sketchup.active_model.select_tool Colores.new}
	add_separator_to_menu("Help")
	menu = UI.menu("Help").add_submenu ($DibacStrings.GetString("Dibac License"))
	item=menu.add_item ($DibacStrings.GetString("License Information")) {Sketchup.active_model.selec_tool $DibacLicencia.informacion}
	$DibacStrings.unchecked(menu,item)	
	item=menu.add_item ($DibacStrings.GetString("Authorize")+'...') {Sketchup.active_model.select_tool $DibacLicencia.autorizar}
	$DibacStrings.unchecked(menu,item)	
	item = menu.add_item ($DibacStrings.GetString("Unauthorize")) {Sketchup.active_model.selec_tool $DibacLicencia.desautorizar}
	menu.set_validation_proc(item)  {
		MF_UNCHECKED
		if $clave == '' or $clave == 'promo'
			MF_GRAYED
		else
			MF_ENABLED
		end	
	}
	$hv = [1,0]
	$muro_width  = 0.25.m
	$muro_gruesos = [0.07,0.10,0.15,0.25,0.40,0.50]
	$muro_cara = 0
	$muro_inc = true
	$puerta_ancho_marco = 0.04.m
	$puerta_hoja1 = 0.72.m
	$puerta_hoja2 = 0.0.m
	$puerta_grueso_marco = 0.12.m
	$puerta_grueso_hoja = 0.04.m
	$puerta_hueco = 0
	$puerta_dintel = 2.1.m
	$puerta_alineacion=0.0
	$puerta_hojas = [0.60,0.625,0.70,0.725,0.80,0.825,0.90]
	$ventana_ancho = 1.20.m
	$ventana_hojas = 2
	$ventana_ancho_marco = 0.025.m
	$ventana_grueso = 0.06.m
	$ventana_hueco = 0
	$ventana_hojamax = 1.0.m
	$ventana_frontal_alfeizar = 0.03.m
	$ventana_lateral_alfeizar = 0.00.m
	$ventana_alto = 1.20.m
	$ventana_alfeizar = 1.0.m
	$ventana_alineacion = 0.0
	$armario_ancho = 1.0.m
	$armario_hoja1 = 0.45.m
	$armario_ancho_marco = 0.05.m
	$armario_grueso_marco = 0.05.m
	$armario_grueso_hoja = 0.025.m
	$armario_umbral = 0.07.m
	$armario_dintel = 2.40.m
	$armario_hojas = 2
	$escalera_width = 1.0.m
	$escalera_height = 3.3.m
	$escalera_cara = 0
	$escalera_inc = true
	$escalera_huella = 0.30.m
	$escalera_huellamin = 0.27.m
	$escalera_tabica = 0.18.m
	$escalera_tabicamax= 0.20.m
	$escalera_slope= 0.63.m
	$dibac_menu_loaded = true
	$cota_minima = 0.25.m
	$altura_planta = 3.00.m
	$crear_grupo = true
	$color_lineas =  "<Ninguno>"
	$color_superficies =  "<Ninguno>"
	$color_seleccion =  "<Ninguno>"
end

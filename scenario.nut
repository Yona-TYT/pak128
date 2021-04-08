/*
 *  Tutorial Scenario
 *
 * 
 *  Can NOT be used in network game !
 */
const version = 1550
map.file = "tutorial.sve"
scenario_name             <- "Tutorial Scenario"
scenario.short_description = scenario_name
scenario.author            = "Yona-TYT"
scenario.version           = (version / 1000) + "." + ((version % 1000) / 100) + "." + ((version % 100) / 10) + (version % 10) +" Beta"
scenario.translation      <- ttext("Translator")

const nut_path      = "class/"		// path to folder with *.nut files
persistent.version <- version		// stores version of script
persistent.select  <- null			// stores user selection
persistent.chapter <-	1			// stores chapter number
persistent.step    <-	1			// stores step number of chapter

persistent.status <- {chapter=1, step=1} // save step y chapter

script_test <- true

persistent.st_nr <- array(30)			//Numero de estaciones/paradas

scr_jump <- true 

gl_percentage <- 0
persistent.gl_percentage <- 0

//----------------------------------------------------------------
gl_tool_delay <- 0
gl_time <- 10

cov_save <- array(100)						//Guarda los convoys en lista
id_save <- array(100)						//Guarda id de los convoys en lista
ignore_save <- array(600)					//Marca convoys ingnorados

persistent.ignore_save <- array(600)
persistent.id_save <- array(100)

//-------------Guarda el estado del script------------------------
persistent.pot <- [0,0,0,0,0,0,0,0,0,0,0]

persistent.glsw <- [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
pglsw <- [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]

pot0 <- 0
pot1 <- 0
pot2 <- 0
pot3 <- 0
pot4 <- 0
pot5 <- 0
pot6 <- 0
pot7 <- 0
pot8 <- 0
pot9 <- 0
pot10 <- 0
glsw <- [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]

//---------------------Contador global de vehiculos----------------------------
persistent.gcov_nr <- 0	
gcov_nr <- 0
persistent.gcov_id <- 1
gcov_id <- 0
persistent.gall_cov <- 0	
gall_cov <-0
persistent.current_cov <- 0
current_cov <- 0
cov_sw <- true
correct_cov <- true
//----------------------------------------------------------------

sch_flag <- false 						//Bandera para schedule
lin_flag <- false 						//Bandera para line

tile_delay <- 2						//delay for mark tiles
tile_delay_list <- 2
gui_delay <- true					//delay for open win

fail_num <- 5						//numr for the count of try
fail_num2 <- 20						//numr for the count of try
fail_count <- fail_num              //if tool fail more of 10 try
fail_count2 <- 0

//Schedule activate
active_sch_check <- false

// placeholder for tools names in simutrans
tool_alias  <-	{	inspe = translate("Abfrage"), road= translate("ROADTOOLS"), rail = translate("RAILTOOLS"),
					ship = translate("SHIPTOOLS"), land = translate("SLOPETOOLS"), spec = translate("SPECIALTOOLS")
				}

// placeholder for good names in pak128
good_alias  <-	{	mail = "Post", passa= "Passagiere", goods = "goods_", grain = "grain", coal = "Kohle",
					flour = "flour", deliv = "Crates Deliverables", oel = "Oel", gas = "Gasoline"
				}
// table containing all system_types
all_systemtypes <- [st_flat, st_elevated, st_runway, st_tram]

chapter            <- null			// used later for class
chapter_max        <- 7				// amount of chapter
select_option      <- { x = 0, y = 0, z = 1 }	// place of station to control name
select_option_halt <- null			// placeholder for halt_x
tutorial		  <- {}				// placeholder for all chapter CLASS

include(nut_path+"class_basic_chapter") 		// include class for basic chapter structure
for (local i = 1; i <= chapter_max; i++)		// include amount of chapter classes
	include(nut_path+"class_chapter_"+(i < 10 ? "0"+i:i) )
chapter            <- tutorial.chapter_02      	// must be placed here !!!

function script_text()
{	
	if(!correct_cov){
		gui.add_message(""+translate("Advance not allowed"))
		return null
	}
	if(true/*scr_jump*/){
		local result = null
		scr_jump = false
		result = chapter.script_text()
		if(result == 0) gui.add_message(""+translate("Advance not allowed")+"")
		return result
	}
	else gui.add_message(""+translate("Updating text ... Waiting ...")+"")
	return null
}


function sum(a,b)
{
	return a+b
}

function my_chapter()
{
	return "chapter_"+(persistent.chapter < 10 ? "0":"")+persistent.chapter+"/"
}

function scenario_percentage(percentage)
{
	return min( ((persistent.chapter - 1) * 100 + percentage) / tutorial.len(), 100 )
}

function load_chapter(number,pl)
{
    rules.clear()
	if (number <= tutorial.len() )		// replace the class
		chapter = tutorial["chapter_"+(number < 10 ? "0":"")+number](pl)
	else    persistent.chapter--
	if ( (number == persistent.chapter) && (chapter.startcash > 0) )  // set cash money here
		player_x(0).book_cash( (chapter.startcash - player_x(0).get_cash()[0]) * 100)

	persistent.step = persistent.status.step
}

function load_chapter2(number,pl)
{
    rules.clear()

	chapter = tutorial["chapter_"+(number < 10 ? "0":"")+number](pl)

	if ( (number == persistent.chapter) && (chapter.startcash > 0) )  // set cash money here
		player_x(0).book_cash( (chapter.startcash - player_x(0).get_cash()[0]) * 100)
	persistent.chapter = number
}

function set_city_names()
{
	foreach ( city in city_list_x() )
	{
		local name = ttext( city.get_name() )
		if (name.tostring() != "") city.set_name( name.tostring() )
	}
}

function get_info_text(pl)
{
    local info = ttextfile("info.txt")
	local help = ""
	local i = 0
	//foreach (chap in tutorial)
	for (i=1;i<=chapter_max;i++)
		help+= "<em>"+translate("Chapter")+" "+(i)+"</em> - "+translate(tutorial["chapter_"+(i<10?"0":"")+i].chapter_name)+"<br>"
	info.list_of_chapters = help

	info.first_link = "<a href=\"goal\">"+(persistent.chapter <= 1 ? translate("Let's start!"):translate("Let's go on!") )+"  >></a>"
    return info
}

function get_rule_text(pl)
{
	/*local cov_nr_debug = "All convoys-> "+gall_cov+":: Convoys count-> "+gcov_nr+":: current covoy-> "+current_cov+":: Correct cov-> "+correct_cov+":: Convoy id-> "+gcov_id+"<br><br>"
	local tx = ""
	local j=0
	for(j;j<gcov_nr;j++){
		local result = true
		// cnv - convoy_x instance saved somewhat earlier
		try {
			 cov_save[j].get_pos() // will fail if cnv is no longer existent
			 // do your checks
		}
		catch(ev) {
			result = false
		}
		if (result){
			if (cov_save[j].is_in_depot()){
				result = false
			}
		}

		if (result) {
			tx += "<em>["+j+"]</em> id cov save: "+id_save[j]+" :: id conv: "+cov_save[j].id+" <a href=\"("+cov_save[j].get_pos().tostring()+")\"> ("+cov_save[j].get_pos().tostring()+")</a> "+cov_save[j].get_name()+"<br>"
		}
		else
			tx += "<st>["+j+"]</st> "+id_save[j]+"::"+cov_save[j]+"<br>"
	}
	return cov_nr_debug + tx */
	return chapter.give_title() + chapter.get_rule_text( pl, my_chapter() )
}

function get_goal_text(pl)
{
	scr_jump = true
	return chapter.give_title() + chapter.get_goal_text( pl, my_chapter() )
}

function get_result_text(pl)
{
	local text = ttextfile("result.txt")
	//local percentage = chapter.is_chapter_completed(pl)
	text.ratio_chapter = gl_percentage
	text.ratio_scenario = scenario_percentage(gl_percentage)
         return chapter.give_title() + text.tostring()
}

function get_about_text(pl)
{
	local about = ttextfile("about.txt")
	about.short_description = scenario_name
	about.version = scenario.version
	about.author = scenario.author
	about.translation = scenario.translation
	
	return about
}

function start()
{
	gui_delay = false
	set_city_names()
    resume_game()
}

function is_scenario_completed(pl)
{
	//gui.add_message(""+glsw[0]+"")
	//gui.add_message("Persis Step:"+persistent.step+" Status Step:"+persistent.status.step+"  Step:"+chapter.step+"")				
	if (pl != 0) return 0			// other player get only 0%
	if(fail_count==0){
		if (fail_count2 == fail_num2){
			gui.open_info_win_at("goal")
			fail_count2 = 0
			fail_count = fail_num
		}
		else
			fail_count2++
	}
	if(gui_delay){
		gui.open_info_win_at("goal")
		gui_delay = false
	}

	//gui.add_message(""+current_cov+"  "+gall_cov+"")
	//Para los convoys ---------------------
	if (gall_cov != current_cov) chapter.checks_convoy_removed(pl)
	gall_cov = checks_all_convoys()
	correct_cov = chapter.correct_cov_list()
	persistent.gall_cov = gall_cov

//gui.add_message("gall_cov-> "+gall_cov+":: gcov_nr-> "+gcov_nr+":: current_cov-> "+current_cov+":: correct_cov-> "+correct_cov+"::gcov_id-> "+gcov_id+"::"+cov_sw+"")
	if (correct_cov) {
		if (persistent.status.chapter > persistent.chapter){
			load_chapter2(persistent.status.chapter,pl)
		}
		if (persistent.status.step != persistent.step){
			chapter.step_nr(persistent.status.step)
		}
	}
	else{
		chapter.start_chapter()
		return 0
	}


	//if(cov_delay>0) cov_delay--
	chapter.step = persistent.step
	local percentage = chapter.is_chapter_completed(pl)
	gl_percentage = percentage
	persistent.gl_percentage = gl_percentage

	if (percentage >= 100){	// give message , be sure to have 100% or more
		local text = ttext("Chapter {number} - {cname} complete, next Chapter {nextcname} start here: ({coord}).")
		text.number = persistent.chapter
		text.cname = translate(""+chapter.chapter_name+"")

		persistent.chapter++
		load_chapter(persistent.chapter, pl)
		percentage = chapter.is_chapter_completed(pl)
		 // ############## need update of scenario window

		text.nextcname = translate(""+chapter.chapter_name+"")
		text.coord = chapter.chapter_coord.tostring()
		chapter.start_chapter()  //Para iniciar variables en los capitulos
		gui.add_message(text.tostring()) //test
	}
	percentage = scenario_percentage(percentage)
	if ( percentage >= 100 ) {		// scenario complete
		local text = translate("Tutorial Scenario complete.")
		gui.add_message( text.tostring() )
	}
	return percentage
}


function is_work_allowed_here(pl, tool_id, pos)
{	
	local pause = debug.is_paused()
	if (pause) return translate("Advance is not allowed with the game paused.")

	gl_tool_delay = gl_time
	//return tile_x(pos.x,pos.y,pos.z).find_object(mo_way).get_dirs()
	if (pl != 0) return null
	if (correct_cov){
		local result = chapter.is_work_allowed_here(pl, tool_id, pos)
		if (result != null && fail_count > 0){
			fail_count--
			if (fail_count == 0){
				return translate("Are you lost ?, see the instructions shown below.")
			}
		}
        else if (result == null)
            fail_count = fail_num
		return result
	}
	else {
		local result = translate("Action not allowed")
		if (tool_id==4108 || tool_id==4096)
			result = null

		if (result != null && fail_count > 0){
			fail_count--
			if (fail_count == 0){
				return translate("Are you lost ?, see the instructions shown below.")
			}
		}
        else if (result == null)
            fail_count = fail_num
		return result
	}
}


function is_schedule_allowed(pl, schedule)
{
	local pause = debug.is_paused()
	if (pause) return translate("Advance is not allowed with the game paused.")

    local result = null

	if (pl != 0) return null
	result = chapter.is_schedule_allowed(pl, schedule)
    if (result != null)
         active_sch_check = true
    else
         active_sch_check = false

    return result
}

function is_convoy_allowed(pl, convoy, depot)
{
	local pause = debug.is_paused()
	if (pause) return translate("Advance is not allowed with the game paused.")

	local result = null
	chapter.checks_convoy_removed(pl)
	//gui.add_message("Run ->"+current_cov+","+correct_cov+" - "+gall_cov+"")
	if (pl != 0) return null
	result = chapter.is_convoy_allowed(pl, convoy, depot)
	//gui.add_message(""+result+"")
	return result
}

function is_tool_allowed(pl, tool_id, wt)
{
	//if (tool_id == 0x2000) return false // prevent players toggling pause mode
	if (tool_id == 0x2005) return false 
	else if (tool_id == 0x4006) return false 
	else if (tool_id == 0x4029) return false 
	else if (tool_id == 0x401c) return false 

    return true
}
//--------------------------------------------------------
datasave <- {cov = cov_save}

class data_save {	
	// Convoys
	function convoys_save() {return datasave.cov;}
	function _save() { return "data_save()"; }
}

persistent.datasave <- datasave

convoy_x._save <- function()
{
	return "convoy_x(" + id + ")"
}
//-----------------------------------------------------------

function resume_game()
{	
	// Datos guardados
	//-----------------------------------------------------	
	// copy it piece by piece otherwise the reference 
	foreach(key,value in persistent.datasave)
	{
		datasave.rawset(key,value)
	}
	persistent.datasave = datasave

	// Se obtienen los datos guardados
	cov_save  = data_save().convoys_save()

//-------------------------------------------------------

	point = persistent.point
	gcov_nr = persistent.gcov_nr
	gall_cov = persistent.gall_cov
	current_cov = persistent.current_cov
	gcov_id = persistent.gcov_id
	gsignal = persistent.signal
	sigcoord = persistent.sigcoord
	id_save = persistent.id_save
	ignore_save = persistent.ignore_save
	
	pot0=persistent.pot[0]
	pot1=persistent.pot[1]
	pot2=persistent.pot[2]
	pot3=persistent.pot[3]	
	pot4=persistent.pot[4]
	pot5=persistent.pot[5]	
	pot6=persistent.pot[6]	
	pot7=persistent.pot[7]	
	pot8=persistent.pot[8]
	pot9=persistent.pot[9]

	gl_percentage = persistent.gl_percentage

	for(local j=0;j<20;j++){
		if (persistent.glsw[j]!=0)
			glsw[j]=persistent.glsw[j]
		persistent.glsw[j]=glsw[j]
	}

	load_chapter(persistent.chapter,0)      // load correct chapter for player=0

	chapter.step = persistent.step		// set chapter step from persistent

	select_option_halt = tile_x( 0, 0, select_option.z ).find_object(mo_label)

    chapter.start_chapter()
}

function checks_all_convoys()
{
	local cov_list = world.get_convoy_list()
	local cov_nr = 0
	foreach(cov in cov_list) {
		local id = cov.id
		if (id>gcov_id)
			gcov_id = id

		if (!cov.is_in_depot() && !ignore_save[id])
			cov_nr++	
	}	
	return cov_nr
}

function checks_current_line(pl, schedule)
{
	local list = player_x(pl).get_line_list()
	local l_nr = list.get_count()
	local line = null
	for(local j=0;j<l_nr;j++){
		line = list[j]
		if (line && line.is_valid()){
			local sch = line.get_schedule()
			local cov_list = line.get_convoy_list()

			local cov_nr = 0
			foreach(cov in cov_list) {
				cov_nr++
			}
			if (sch && cov_nr==0){
				local entrie = sch.entries
				local sch1_nr = entrie.len()
				local sch2_nr = schedule.entries.len()
				local result = 0
			
				if (sch1_nr>0 && sch1_nr==sch2_nr){
					for(local i=0;i<sch1_nr;i++){
						result = is_waystop_correct(pl, schedule, i, entrie[i].load, entrie[i].wait, coord(entrie[i].x, entrie[i].y))
						if (result != null){
							break
						}
					}
				}
				if (result != null)
					continue
				else {
					sch_flag = true
					return null
				}				
			}	
		}
	}
	return null
}

function checks_all_line(pl)
{
	local list = player_x(pl).get_line_list()
	local l_nr = list.get_count()
	local line = null
	for(local j=0;j<l_nr;j++){
		line = list[j]
		if (line){
			local cov_nr = 0
			local cov_list = line.get_convoy_list()

			if (cov_list.get_count()!=0)
				continue

			local sch = line.get_schedule()
			local sch_nr = sch.entries.len()
			if (sch && sch_nr==0){
				line.destroy(player_x(pl))
			}
		
		}	
	}
	return null
}

function get_line_name(halt)
{
	local lin_list = halt.get_line_list()
	
	foreach(line in lin_list) {
		return "<em>"+line.get_name()+"</em>"
	}
	return "<s>not line</s>"
}

// END OF FILE

#' Run a simulation for calculating water values for a specific area
#'
#' @param area The area concerned by the simulation.
#' @param simulation_name The name of the simulation, \code{s} is a placeholder for the constraint value defined by \code{nb_disc_stock}.
#' @param nb_disc_stock Number of simulation to launch, a vector of energy constraint
#'  will be created from maximum pumping power to the hydro storage maximum and of length this parameter.
#' @param nb_mcyears Number of Monte Carlo years to simulate or a vector of years indexes to launch.
#' @param binding_constraint Name of the binding constraint.
#  constraint_values Vector of energy constraints on the link between the area and the fictive area.
#' @param fictive_area Name of the fictive area to create, argument passed to \code{\link{setupWaterValuesSimulation}}.
#' @param thermal_cluster Name of the thermal cluster to create, argument passed to \code{\link{setupWaterValuesSimulation}}.
#' @param path_solver Character containing the Antares Solver path, argument passed to \code{\link[antaresEditObject]{runSimulation}}.
#' @param wait Argument passed to \code{\link[antaresEditObject]{runSimulation}}.
#' @param show_output_on_console Argument passed to \code{\link[antaresEditObject]{runSimulation}}.
#' @param overwrite If area or cluster already exists, should they be overwritten?
#' @param link_from area that will be linked to the created fictive area. If it's
#' \code{NULL} it will takes the area concerned by the simulation.
#' @param otp_dest the path in which the script save Rdata file.
#' @param file_name the Rdata file name.
#' @param remove_areas 	Character vector of area(s) to remove from the created district.
#' @param shiny Boolean. True to run the script in shiny mod.
#' @param pumping Boolean. True to take into account the pumping.
#' @param efficiency in [0,1]. efficient ratio of pumping.
#' @param launch_simulations Boolean. True to to run the simulations.
#' @param reset_hydro Boolean. True to reset hydro inflow to 0 before the simulation.
#' @param opts
#'   List of simulation parameters returned by the function
#'   \code{antaresRead::setSimulationPath}
#' @param ... further arguments passed to or from other methods.
#'
#' @note This function have side effects on the Antares study used, a fictive area is created and a new district as well.
#'
#' @export
#' @importFrom assertthat assert_that
#' @importFrom antaresEditObject createBindingConstraint updateGeneralSettings
#' removeBindingConstraint writeInputTS readIniFile filteringOptions
#' writeIni runSimulation removeArea editArea
#' @importFrom antaresRead readClusterDesc readInputTS
#' @importFrom stats setNames
#'

runWaterValuesSimulation <- function(area,
                                     simulation_name = "weekly_water_amount_%s",
                                     nb_disc_stock = 10,
                                     nb_mcyears = NULL,
                                     binding_constraint = "WeeklyWaterAmount",
                                     fictive_area = NULL,
                                     thermal_cluster = NULL,
                                     path_solver=NULL,
                                     wait = TRUE,
                                     show_output_on_console = FALSE,
                                     overwrite = FALSE,
                                     link_from=NULL,
                                     remove_areas=NULL,
                                     opts = antaresRead::simOptions(),
                                     shiny=F,otp_dest=NULL,file_name=NULL,
                                     pumping=F,
                                     efficiency=NULL,
                                     launch_simulations=T,
                                     reset_hydro=T,...){






  #check the study is well selected
  assertthat::assert_that(class(opts) == "simOptions")

  fictive_areas <- area

  # check the name format

  if(!endsWith(simulation_name,"_%s")){
    simulation_name <- paste0(simulation_name,"_%s")
  }


  # restore hydro inflow if there is a previous intercepted simulation.
  restoreHydroStorage(area = area, opts = opts,silent = T)
  # restore Pump power if there is a previous intercepted simulation.
  restorePumpPower(area = area, opts = opts,silent = T)

  # MC years
  assertthat::assert_that(is.numeric(nb_mcyears)==TRUE)

  if(length(nb_mcyears)==1){
    play_years <- seq(1,nb_mcyears)
  }else{
    play_years <- nb_mcyears
  }

  antaresEditObject::setPlaylist(playlist = play_years,opts = opts)


  #assert the weekly output of the area:

  antaresEditObject::editArea(name = area,
                              filtering =
                                filteringOptions(filter_synthesis = c("hourly" , "weekly", "annual"),
                                                 filter_year_by_year = c("hourly", "weekly", "annual"))
                              ,opts = opts)

  #generating the fictive area parameters

  fictive_area <- if (!is.null(fictive_area)) fictive_area else paste0("watervalue_", area)
  thermal_cluster <- if (!is.null(thermal_cluster)) thermal_cluster else "WaterValueCluster"

  # Get max hydro power that can be generated in a week

  constraint_values <- constraint_generator(area=area,nb_disc_stock=nb_disc_stock,
                                            pumping=pumping,
                                            pumping_efficiency = efficiency,
                                            opts=opts)

  # Get efficiency

  if (is.null(efficiency)){
    efficiency <- getPumpEfficiency(area = area)

  }


  #create the fictive areas

  opts <- setupWaterValuesSimulation(
    area = area,
    fictive_area_name = fictive_area,
    thermal_cluster = thermal_cluster,
    overwrite = overwrite,
    remove_areas=remove_areas,
    reset_hydro=reset_hydro,
    opts = opts,
    link_from = link_from,
    pumping=pumping,
    max_load=max(abs(constraint_values))*10
  )






  #generate the flow sens
  if(pumping){
    fictive_areas <- c(paste0(fictive_area,"_turb"),paste0(fictive_area,"_pump"))
    coeff_turb <- generate_link_coeff(area,fictive_areas[1])
    coeff_pump <- generate_link_coeff(area,fictive_areas[2])
    coeff <- c(coeff_turb,coeff_pump)

  }else{
    fictive_areas <- fictive_area
    coeff <- generate_link_coeff(area,fictive_area)
  }

  # Start the simulations

  simulation_names <- vector(mode = "character", length = length(constraint_values))



  for (i in constraint_values) {

    # Prepare simulation parameters
    name_bc <- paste0(binding_constraint, format(i, decimal.mark = ","))
    constraint_value <- round(i  / 7)


    # Implement binding constraint

    generate_constraints(constraint_value,coeff,name_bc,efficiency,opts)




    iii <- which(num_equal(i, constraint_values))
    ii <- round(i/1000)

    message("#  ------------------------------------------------------------------------")
    message(paste0("Running simulation: ", iii, " - ", sprintf(simulation_name, format(ii, decimal.mark = ","))))
    message("#  ------------------------------------------------------------------------")
    # run the simulation
    if(launch_simulations){
      antaresEditObject::runSimulation(
        name = sprintf(simulation_name, format(ii, decimal.mark = ",")),
        mode = "economy",
        wait = wait,
        path_solver = path_solver,
        show_output_on_console = show_output_on_console,
        opts = opts
      )}
    simulation_names[which(constraint_values == i)] <- sprintf(simulation_name, format(ii, decimal.mark = ","))

    #remove the Binding Constraints

    disable_constraint(constraint_value,name_bc,pumping,opts)

    #Simulation Control
    sim_name <-  sprintf(simulation_name, format(ii, decimal.mark = ","))
    sim_name <- getSimulationNames(pattern =sim_name , opts = opts)[1]
    sim_check <- paste0(opts$studyPath,"/output")
    sim_check <- paste(sim_check,sim_name,sep="/")

    if(launch_simulations){
      if(!dir.exists(paste0(sim_check,"/economy/mc-all"))) {
        stop("Simulation Error. Please check simulation log.")
        # remove the fictive area
        if(launch_simulations){
          for (fictive_area in fictive_areas){
            antaresEditObject::removeArea(fictive_area,opts = opts)
          }        }

        # restore hydrostorage
        restoreHydroStorage(area = area, opts = opts)
        restorePumpPower(area = area, opts = opts)
      }
    }
  }

  # remove the fictive area
  if(launch_simulations){
    for (fictive_area in fictive_areas){
    antaresEditObject::removeArea(fictive_area,opts = opts)
  }}

  # restore hydrostorage
  restoreHydroStorage(area = area, opts = opts)
  restorePumpPower(area = area, opts = opts)

  simulation_res <- list(
    simulation_names = simulation_names,
    simulation_values = constraint_values
  )

  if(!is.null(otp_dest))
  { main_path <- getwd()

  setwd(otp_dest)

  save(simulation_res,file=paste0(file_name,".RData"))


  setwd(main_path)}

  return(simulation_res)

}



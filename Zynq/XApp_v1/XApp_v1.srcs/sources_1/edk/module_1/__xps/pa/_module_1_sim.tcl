######################################################
#
# XPS Tcl API script generated by PlanAhead
#
######################################################

proc _main_ {} {
  cd "C:/Users/rchil/Desktop/Artemis/Software_desarrollado/Zynq/ADC_Read4/ADC_Read4.srcs/sources_1/edk/module_1"
  if { [ catch {xload xmp module_1.xmp} result ] } {
    exit 10
  }

  # Set host application type
  xset intstyle PA

  # Set design flow type
  xset flow ise

  # Set language type
  xset hdl vhdl

  # Set target simulator
  xset simulator isim

  # Set simulation flow
  xset sim_model behavioral

  # Clean Simulation Models
  if { [catch {run simclean} result] } {
    return -1
  }

  # Launch Simulation Models generation
  if { [catch {run simmodel} result] } {
    return -1
  }
  return $result
}

# Generate Simulation Models
if { [catch {_main_} result] } {
  exit -1
}

# Check return status and exit
if { [string length $result] == 0 } {
  exit 0
} else {
  exit $result
}

# Tcl script generated by PlanAhead

set reloadAllCoreGenRepositories false

set tclUtilsPath "c:/Xilinx/14.5/ISE_DS/PlanAhead/scripts/pa_cg_utils.tcl"

set repoPaths ""

set cgIndexMapPath "C:/Users/rchil/Desktop/Artemis/Software_desarrollado/Zynq/XApp_v1/XApp_v1.srcs/sources_1/ip/cg_nt_index_map.xml"

set cgProjectPath "c:/Users/rchil/Desktop/Artemis/Software_desarrollado/Zynq/XApp_v1/XApp_v1.srcs/sources_1/ip/selectio_wiz_v4_1_0/coregen.cgc"

set ipFile "c:/Users/rchil/Desktop/Artemis/Software_desarrollado/Zynq/XApp_v1/XApp_v1.srcs/sources_1/ip/selectio_wiz_v4_1_0/selectio_wiz_v4_1_0.xco"

set ipName "selectio_wiz_v4_1_0"

set hdlType "VHDL"

set cgPartSpec "xc7z020-1clg484"

set chains "GENERATE_CURRENT_CHAIN"

set params ""

set bomFilePath "c:/Users/rchil/Desktop/Artemis/Software_desarrollado/Zynq/XApp_v1/XApp_v1.srcs/sources_1/ip/selectio_wiz_v4_1_0/pa_cg_bom.xml"

# generate the IP
set result [source "c:/Xilinx/14.5/ISE_DS/PlanAhead/scripts/pa_cg_gen_out_prods.tcl"]

exit $result

# 
#  Copyright 2006 - 2010 Unified EFI, Inc.<BR> 
#  Copyright (c) 2010, Intel Corporation. All rights reserved.<BR>
# 
#  This program and the accompanying materials
#  are licensed and made available under the terms and conditions of the BSD License
#  which accompanies this distribution.  The full text of the license may be found at 
#  http://opensource.org/licenses/bsd-license.php
# 
#  THE PROGRAM IS DISTRIBUTED UNDER THE BSD LICENSE ON AN "AS IS" BASIS,
#  WITHOUT WARRANTIES OR REPRESENTATIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED.
# 
################################################################################
CaseLevel         FUNCTION
CaseAttribute     AUTO
CaseVerboseLevel  DEFAULT
set reportfile    report.csv

#
# test case Name, category, description, GUID...
#
CaseGuid        2A5DD079-8947-4ea2-801C-FDB41A62C033
CaseName        Configure.Func1.Case1
CaseCategory    TCP6
CaseDescription { Configure must succeed with valid parameters.}
################################################################################
Include TCP6/include/Tcp6.inc.tcl
# Procedure Name
#   ValidateModeData
# Procedure Description:
#   Validate mode data to be the same with the configuration
# Arguments:
#   L_Proc_CheckState
#       Whether to check the connection state
#   L_Proc_CheckConfigure
#       Whether to check the configure data
# Returns:
#    None
#
proc CheckModeData { L_Proc_CheckState L_Proc_CheckConfigure } {
  global TCS DEF_EUT_IP_ADDR DEF_EUT_MAC_ADDR DEF_EUT_PRT DEF_ENTS_IP_ADDR DEF_ENTS_MAC_ADDR DEF_ENTS_PRT
  global assert
  global R_Configure_Tcp6ConnectionState
  global R_Configure_Tcp6ConfigData
  global {R_Configure_Tcp6ConfigData.TrafficClass}
  global {R_Configure_Tcp6ConfigData.HopLimit}
  global {R_Configure_Tcp6ConfigData.ControlOption}
  global {R_Configure_Tcp6ConfigData.AccessPoint}
  global {R_Proc_AccessPoint.StationPort}
  global {R_Proc_AccessPoint.RemotePort}
  global {R_Proc_AccessPoint.ActiveFlag}
  global {R_Proc_AccessPoint.StationAddress}
  global {R_Proc_AccessPoint.RemoteAddress}

  
  if { $L_Proc_CheckState == 1} {
    GetVar  R_Configure_Tcp6ConnectionState 
    if { [expr $R_Configure_Tcp6ConnectionState] != $TCS(Listen) } {
      set assert fail
      return
    }
  }
  
  if { $L_Proc_CheckConfigure == 1} {
    GetVar  R_Configure_Tcp6ConfigData
    if { ${R_Configure_Tcp6ConfigData.TrafficClass} != 0 } {
      set assert fail
      return
    }
    if { ${R_Configure_Tcp6ConfigData.HopLimit} != 128 } {
      set assert fail
      return
    }
    if { ${R_Configure_Tcp6ConfigData.ControlOption} != 0 } {
      set assert fail
      return
    }
    EFI_TCP6_ACCESS_POINT R_Proc_AccessPoint
    UINTN R_Proc_MemSize
    UINTN R_Proc_Status
    SetVar R_Proc_MemSize  [Sizeof R_Proc_AccessPoint]
    BS->CopyMem " &@R_Proc_AccessPoint, &@R_Configure_Tcp6ConfigData.AccessPoint, @R_Proc_MemSize, &@R_Proc_Status"
    GetAck
    GetVar R_Proc_AccessPoint
    if { ${R_Proc_AccessPoint.RemotePort} != $DEF_ENTS_PRT } {
      set assert fail
      DelVar R_Proc_AccessPoint
      DelVar R_Proc_MemSize
      DelVar R_Proc_Status
      return
    }
    if { ${R_Proc_AccessPoint.StationPort} != 6666 } {
      set assert fail
      DelVar R_Proc_AccessPoint
      DelVar R_Proc_MemSize
      DelVar R_Proc_Status
      return
    }
    if { [string compare ${R_Proc_AccessPoint.ActiveFlag} true] != 0 } {
      set assert fail
      DelVar R_Proc_AccessPoint
      DelVar R_Proc_MemSize
      DelVar R_Proc_Status
      return
    }
    set L_Proc_Ipv6Address [GetIpv6Address {R_Proc_AccessPoint.StationAddress}]
    if { [string compare $L_Proc_Ipv6Address $DEF_EUT_IP_ADDR] != 0} {
      set assert fail
      DelVar R_Proc_AccessPoint
      DelVar R_Proc_MemSize
      DelVar R_Proc_Status
      return
    }
    set L_Proc_Ipv6Address [GetIpv6Address {R_Proc_AccessPoint.RemoteAddress}]
    if { [string compare $L_Proc_Ipv6Address $DEF_ENTS_IP_ADDR] != 0} {
      set assert fail
      DelVar R_Proc_AccessPoint
      DelVar R_Proc_MemSize
      DelVar R_Proc_Status
      return
    }
    DelVar R_Proc_AccessPoint
    DelVar R_Proc_MemSize
    DelVar R_Proc_Status
  }
  return
}

#
# Begin log ...
#
BeginLog

#
# BeginScope
#
BeginScope  _TCP6_CONFIGURE_FUNC1_CASE1_

EUTSetup

#
# Parameter Definition
# R_ represents "Remote EFI Side Parameter"
# L_ represents "Local OS Side Parameter"
#
UINTN    R_Status
UINTN    R_Handle

#
# Create Child for TCP6 protocol
#
Tcp6ServiceBinding->CreateChild "&@R_Handle, &@R_Status"
GetAck
SetVar [subst $ENTS_CUR_CHILD]    @R_Handle
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Tcp6SBP.CreateChild - Create Child"                         \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

#
# Configure the instance with valid parameters
#
EFI_TCP6_ACCESS_POINT    R_Configure_AccessPoint
SetIpv6Address  R_Configure_AccessPoint.StationAddress    $DEF_EUT_IP_ADDR
SetVar          R_Configure_AccessPoint.StationPort       6666
SetIpv6Address  R_Configure_AccessPoint.RemoteAddress     $DEF_ENTS_IP_ADDR
SetVar          R_Configure_AccessPoint.RemotePort        $DEF_ENTS_PRT
SetVar          R_Configure_AccessPoint.ActiveFlag        TRUE

EFI_TCP6_CONFIG_DATA    R_Configure_Tcp6ConfigData
SetVar R_Configure_Tcp6ConfigData.TrafficClass     0
SetVar R_Configure_Tcp6ConfigData.HopLimit         128
SetVar R_Configure_Tcp6ConfigData.AccessPoint      @R_Configure_AccessPoint
SetVar R_Configure_Tcp6ConfigData.ControlOption    0

Tcp6->Configure {&@R_Configure_Tcp6ConfigData, &@R_Status}
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $Tcp6ConfigureFunc1AssertionGuid001                \
                "Tcp6.Configure - Call Configure() with valid config data"         \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

#
# Check Point: Call Get Mode Data with validate parameters
#
UINT32                             R_Configure_Tcp6ConnectionState
EFI_IP6_MODE_DATA                  R_Configure_Ip6ModeData
EFI_MANAGED_NETWORK_CONFIG_DATA    R_Configure_MnpConfigData
EFI_SIMPLE_NETWORK_MODE            R_Configure_SnpModeData
Tcp6->GetModeData {&@R_Configure_Tcp6ConnectionState, &@R_Configure_Tcp6ConfigData,     \
                   &@R_Configure_Ip6ModeData,&@R_Configure_MnpConfigData,      \
                   &@R_Configure_SnpModeData, &@R_Status}
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
CheckModeData 0 1
RecordAssertion $assert $Tcp6ConfigureFunc1AssertionGuid002         \
                "Tcp6 - Configure with validate parameters"                         \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS and parameters are the same as the setting value"

#
# Destroy Child for Tcp6
#
Tcp6ServiceBinding->DestroyChild "@R_Handle,&@R_Status"
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Tcp6SBP.DestroyChild - Destroy Child"                         \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"
                
EUTClose

#
# EndScope
#
EndScope  _TCP6_CONFIGURE_FUNC1_CASE1_

#
# End log
#
EndLog

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

#
# test case Name, category, description, GUID...
#
CaseGuid          3F73C84F-0A23-39a7-2584-1C5BC4ED2C28
CaseName          Others.Func5.Case2
CaseCategory      TCP
CaseDescription   {This case is to test the Functionality.                     \
                  -- Configure EUT to send data in CLOSE_WAIT state.}
################################################################################

Include TCP4/include/Tcp4.inc.tcl

proc CleanUpEutEnvironmentBegin {} {
  global RST
  UpdateTcpSendBuffer TCB -c $RST
  SendTcpPacket TCB

  DestroyTcb
  DelEntryInArpCache

  Tcp4ServiceBinding->DestroyChild "@R_Handle, &@R_Status"
  GetAck

  Tcp4ServiceBinding->DestroyChild "@R_Accept_NewChildHandle, &@R_Status"
  GetAck
}

proc CleanUpEutEnvironmentEnd {} {
  EndLogPacket
  EndScope _TCP4_SPEC_CONFORMANCE_
  EndLog
}

#
# Begin log ...
#
BeginLog

#
# BeginScope
#
BeginScope _TCP4_SPEC_CONFORMANCE_

BeginLogPacket Others.Func5.Case2 "host $DEF_EUT_IP_ADDR and host              \
                                             $DEF_ENTS_IP_ADDR"
#
# Parameter Definition
# R_ represents "Remote EFI Side Parameter"
# L_ represents "Local OS Side Parameter"
#
set    L_FragmentLength          16

UINTN                            R_Status
UINTN                            R_Handle
UINTN                            R_Context
UINTN                            R_Tcp4State

EFI_TCP4_CONFIG_DATA             R_Tcp4ConfigData
EFI_IP4_MODE_DATA                R_Ip4ModeData
EFI_MANAGED_NETWORK_CONFIG_DATA  R_MnpConfigData
EFI_SIMPLE_NETWORK_MODE          R_SnpModeData

EFI_TCP4_ACCESS_POINT            R_Configure_AccessPoint
EFI_TCP4_CONFIG_DATA             R_Configure_Tcp4ConfigData

EFI_TCP4_COMPLETION_TOKEN        R_Connect_CompletionToken
EFI_TCP4_CONNECTION_TOKEN        R_Connect_ConnectionToken

EFI_TCP4_LISTEN_TOKEN            R_Accept_ListenToken
EFI_TCP4_COMPLETION_TOKEN        R_Accept_CompletionToken
UINTN                            R_Accept_NewChildHandle

EFI_TCP4_IO_TOKEN                R_Transmit_IOToken
EFI_TCP4_COMPLETION_TOKEN        R_Transmit_CompletionToken

Packet                           R_Packet_Buffer
EFI_TCP4_TRANSMIT_DATA           R_TxData
EFI_TCP4_FRAGMENT_DATA           R_FragmentTable
CHAR8                            R_FragmentBuffer($L_FragmentLength)

SetVar R_FragmentBuffer          "0123456789ABCDEF"

BuildTcpOptions MssOption -m 536

#
# Initialization of TCB related on OS side.
#
CreateTcb TCB $DEF_ENTS_IP_ADDR $DEF_ENTS_PRT $DEF_EUT_IP_ADDR $DEF_EUT_PRT

LocalEther  $DEF_ENTS_MAC_ADDR
RemoteEther $DEF_EUT_MAC_ADDR
LocalIp     $DEF_ENTS_IP_ADDR
RemoteIp    $DEF_EUT_IP_ADDR

#
# Add an entry in ARP cache.
#
AddEntryInArpCache

#
# Create Tcp4 Child.
#
Tcp4ServiceBinding->CreateChild "&@R_Handle, &@R_Status"
GetAck
SetVar     [subst $ENTS_CUR_CHILD]  @R_Handle
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Tcp4SBP.CreateChild - Create Child 1"                         \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

#
# Configure TCP instance
#
SetVar          R_Configure_AccessPoint.UseDefaultAddress  FALSE
SetIpv4Address  R_Configure_AccessPoint.StationAddress     $DEF_EUT_IP_ADDR
SetIpv4Address  R_Configure_AccessPoint.SubnetMask         $DEF_EUT_MASK
SetVar          R_Configure_AccessPoint.StationPort        $DEF_EUT_PRT
SetIpv4Address  R_Configure_AccessPoint.RemoteAddress      $DEF_ENTS_IP_ADDR
SetVar          R_Configure_AccessPoint.RemotePort         $DEF_ENTS_PRT
SetVar          R_Configure_AccessPoint.ActiveFlag         FALSE

SetVar R_Configure_Tcp4ConfigData.TypeOfService       1
SetVar R_Configure_Tcp4ConfigData.TimeToLive          128
SetVar R_Configure_Tcp4ConfigData.AccessPoint         @R_Configure_AccessPoint
SetVar R_Configure_Tcp4ConfigData.ControlOption       0

Tcp4->Configure {&@R_Configure_Tcp4ConfigData, &@R_Status}
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Tcp4.Configure - Configure Child 1."                          \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

#
#Call Tcp4.Accept()
#
BS->CreateEvent "$EVT_NOTIFY_SIGNAL, $EFI_TPL_CALLBACK, 1, &@R_Context,        \
                 &@R_Accept_CompletionToken.Event, &@R_Status"
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid   "BS.CreateEvent."              \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

SetVar R_Accept_ListenToken.CompletionToken @R_Accept_CompletionToken
SetVar R_Accept_ListenToken.CompletionToken.Status $EFI_INCOMPATIBLE_VERSION

Tcp4->Accept {&@R_Accept_ListenToken, &@R_Status}
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Tcp4.Accept - Accept a connection."                           \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

UpdateTcpSendBuffer TCB -c $SYN -o MssOption
SendTcpPacket TCB

#
# OS get <SYN, ACK> segment
#
ReceiveTcpPacket TCB 5

if { ${TCB.received} == 1 } {
  if { ${TCB.r_f_syn} != 1 && ${TCB.r_f_ack} != 1 } {
    set assert fail
    RecordAssertion $assert $GenericAssertionGuid                              \
                    "EUT doesn't send out SYN & ACK segment correctly."

    CleanUpEutEnvironmentBegin
    BS->CloseEvent "@R_Accept_CompletionToken.Event, &@R_Status"
    GetAck
    CleanUpEutEnvironmentEnd
    return
  }
} else {
  set assert fail
  RecordAssertion $assert $GenericAssertionGuid                                \
                  "EUT doesn't send out any segment."

  CleanUpEutEnvironmentBegin
  BS->CloseEvent "@R_Accept_CompletionToken.Event, &@R_Status"
  GetAck
  CleanUpEutEnvironmentEnd
  return
}

#
# OS send <ACK> segment
#
UpdateTcpSendBuffer TCB -c $ACK
SendTcpPacket TCB

#
# Check the Token.Status to verify the Tcp4->Accept() has completed.
#
while {1} {
  Stall 1
  GetVar R_Accept_ListenToken.CompletionToken.Status

  if { ${R_Accept_ListenToken.CompletionToken.Status} != $EFI_INCOMPATIBLE_VERSION} {
    if { ${R_Accept_ListenToken.CompletionToken.Status} != $EFI_SUCCESS} {
      set assert fail
      RecordAssertion $assert $GenericAssertionGuid                            \
                      "Transmission failed."                                   \
                      "ReturnStatus - ${R_Accept_ListenToken.CompletionToken.Status},\
                       ExpectedStatus - $EFI_SUCCESS"

      CleanUpEutEnvironmentBegin
      BS->CloseEvent "@R_Accept_CompletionToken.Event, &@R_Status"
      GetAck
      CleanUpEutEnvironmentEnd
      return
    } else {
      break
    }
  }
}

SetVar R_Accept_NewChildHandle 0

#
# Get the NewChildHandle value.
#
GetVar R_Accept_ListenToken.NewChildHandle
SetVar R_Accept_NewChildHandle ${R_Accept_ListenToken.NewChildHandle}

SetVar     [subst $ENTS_CUR_CHILD]  @R_Accept_NewChildHandle

#
# OS sends <FIN, ACK> segment
#
set L_TcpFlag [ expr $FIN | $ACK ]
UpdateTcpSendBuffer TCB -c $L_TcpFlag
SendTcpPacket TCB

#
# OS receives <ACK> segment
#
ReceiveTcpPacket TCB 5

#
# Calling Tcp4.GetModeData(), Now EUT in CLOSE_WAIT state.
#
Tcp4->GetModeData {&@R_Tcp4State, &@R_Configure_Tcp4ConfigData, &@R_Ip4ModeData,
                   &@R_MnpConfigData, &@R_SnpModeData, &@R_Status}
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Tcp4.GetModeData - Calling GetModeData."                      \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

GetVar R_Tcp4State

#
# Call Tcp4.Transmit to transmit a packet.
#
BS->CreateEvent "$EVT_NOTIFY_SIGNAL, $EFI_TPL_CALLBACK, 1, &@R_Context,        \
                 &@R_Transmit_CompletionToken.Event, &@R_Status"
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "BS.CreateEvent."                                              \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

SetVar R_TxData.Push                      TRUE
SetVar R_TxData.Urgent                    FALSE
SetVar R_TxData.DataLength                $L_FragmentLength
SetVar R_TxData.FragmentCount             1

SetVar R_FragmentTable.FragmentLength     $L_FragmentLength
SetVar R_FragmentTable.FragmentBuffer     &@R_FragmentBuffer
SetVar R_TxData.FragmentTable(0)          @R_FragmentTable

SetVar R_Packet_Buffer.TxData  &@R_TxData

SetVar R_Transmit_IOToken.CompletionToken @R_Transmit_CompletionToken
SetVar R_Transmit_IOToken.Packet_Buffer   @R_Packet_Buffer
SetVar R_Transmit_IOToken.CompletionToken.Status  $EFI_INCOMPATIBLE_VERSION

Tcp4->Transmit {&@R_Transmit_IOToken, &@R_Status}
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $Tcp4OthersFunc5AssertionGuid002                       \
                "Tcp4.Transmit - transmit a packet."                           \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"
 
Stall 3
#
# Clean up the environment on EUT side.
#
CleanUpEutEnvironmentBegin
BS->CloseEvent "@R_Accept_CompletionToken.Event, &@R_Status"
GetAck
BS->CloseEvent "@R_Transmit_CompletionToken.Event, &@R_Status"
GetAck
CleanUpEutEnvironmentEnd
